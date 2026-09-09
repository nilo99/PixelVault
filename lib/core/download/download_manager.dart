import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pixelvault_torrent/pixelvault_torrent.dart';
import 'package:saf_stream/saf_stream.dart';

import '../db/daos/catalog_repository.dart';
import '../db/daos/download_repository.dart';
import '../models/downloadable_file.dart';
import '../scraping/file_naming.dart';
import '../scraping/scraping_constants.dart';
import '../settings/settings_repository.dart';
import '../storage/saf_storage_helper.dart';
import 'download_failure.dart';
import 'download_item.dart';
import 'download_progress_tracker.dart';
import 'download_speed_controller.dart';
import 'download_status.dart';
import 'download_target.dart';
import 'foreground_task_handler.dart';

/// Archive extensions Milou's `ArchiveUtils.isExtractable` recognizes.
abstract final class ArchiveExtensions {
  static const _supported = {'.zip', '.7z', '.rar', '.tar', '.gz', '.tgz', '.bz2', '.xz', '.cab'};

  static bool isExtractable(String extension) {
    if (extension.isEmpty) return false;
    final ext = extension.startsWith('.') ? extension.toLowerCase() : '.${extension.toLowerCase()}';
    return _supported.contains(ext);
  }
}

/// Text shown on the persistent download notification. Injected (rather than
/// hardcoded) so it follows the locale the user picked, like every other
/// user-visible string.
class DownloadNotificationStrings {
  const DownloadNotificationStrings({required this.title, required this.body});
  final String title;
  final String body;

  static const fallback = DownloadNotificationStrings(title: 'PixelVault', body: '…');
}

/// Minimal counting semaphore backing the concurrent-downloads limit —
/// recreated (via [DownloadManager._ensureConcurrency]) whenever the setting
/// changes; in-flight holders keep their permit until released.
class _Semaphore {
  _Semaphore(this.max) : _permits = max;
  int max;
  int _permits;
  final _waiters = <Completer<void>>[];

  Future<void> acquire() {
    if (_permits > 0) {
      _permits--;
      return Future.value();
    }
    final c = Completer<void>();
    _waiters.add(c);
    return c.future;
  }

  void release() {
    _permits++;
    if (_waiters.isNotEmpty && _permits > 0) {
      _permits--;
      _waiters.removeAt(0).complete();
    }
  }
}

/// Port of Milou's `DownloadService` — orchestrates both HTTP (via `dio`)
/// and torrent (via the `pixelvault_torrent` plugin) downloads behind one
/// uniform API, with shared concurrency limiting, speed throttling and
/// auto-extraction.
///
/// HTTP downloads stream straight into the destination folder; only archives
/// that still have to be unpacked are staged locally first. See
/// [DownloadTarget] for why that distinction matters on large files.
///
/// Every internal map is keyed by [DownloadableFileWithTags.id] — the DB
/// row's unique id — not by `fileName`, which isn't guaranteed unique across
/// sources (region variants routinely share a file name).
///
/// State is mirrored into the `downloads` table through [downloads] as it
/// changes, so an app restart (or an OS kill, which is routine while a
/// multi-GB ROM downloads) resumes the queue and keeps the history instead
/// of losing both.
class DownloadManager {
  DownloadManager({
    required this.tracker,
    required this.settings,
    required this.catalog,
    required this.downloads,
    required this.torrentPlugin,
    required this.safStorage,
    Dio? dio,
    SafStream? safStream,
    this._httpDownloadsDir,
  })  : _dio = dio ?? Dio(),
        _safStream = safStream ?? SafStream();

  final DownloadProgressTrackerNotifier tracker;
  final SettingsNotifier settings;
  final CatalogRepository catalog;
  final DownloadRepository downloads;
  final PixelvaultTorrent torrentPlugin;
  final SafStorageHelper safStorage;

  final Dio _dio;
  final SafStream _safStream;
  final Directory? _httpDownloadsDir;
  final _entities = <int, DownloadableFileWithTags>{};
  final _cancelTokens = <int, CancelToken>{};
  final _torrentDone = <int, Completer<void>>{};
  final _activeRuns = <int, Future<void>>{};
  _Semaphore _semaphore = _Semaphore(3);
  StreamSubscription<TorrentProgressEvent>? _torrentSub;

  /// Throttles progress writes to the DB — a download emits a progress tick
  /// every 500ms, and persisting each one would mean thousands of writes per
  /// file for no benefit, since only the last value matters on restore.
  final _lastPersistedProgress = <int, DateTime>{};
  static const _progressPersistInterval = Duration(seconds: 3);

  DownloadNotificationStrings notificationStrings = DownloadNotificationStrings.fallback;

  /// Re-attaches the queue and history left behind by a previous process.
  ///
  /// Rows that were mid-flight when the process died come back as `stopped`
  /// (their worker is gone), which is exactly the state the Downloads screen
  /// already renders with a retry button — and because the partial staging
  /// file is kept and its path recorded, retrying resumes rather than
  /// restarting from zero.
  Future<void> restore() async {
    final persisted = await downloads.getAll();
    if (persisted.isEmpty) return;
    await downloads.reconcileInterrupted();

    final restored = <DownloadItem>[];
    for (final item in persisted) {
      final normalized = item.isActive ? item.copyWith(status: DownloadStatus.stopped) : item;
      restored.add(normalized);
      if (normalized.recordId == null) continue;
      final row = await downloads.row(normalized.recordId!);
      if (row != null) {
        _entities[normalized.id] = DownloadRepository.toCatalogFile(row);
      }
    }
    tracker.replaceAll(restored);
  }

  void _ensureTorrentListener() {
    // `onError` matters: without it a malformed native event became an
    // unhandled async error that took down the zone instead of skipping the
    // event, which is one of the ways the app "just closed with no message".
    _torrentSub ??= torrentPlugin.progressStream.listen(
      _handleTorrentEvent,
      onError: (Object _) {},
      cancelOnError: false,
    );
  }

  void _handleTorrentEvent(TorrentProgressEvent event) {
    final id = int.tryParse(event.downloadId);
    if (id == null) return;
    if (event.status == TorrentDownloadStatus.downloading) {
      tracker.updateDownloadProgress(id, event.progress, event.speedMBs, event.downloadedBytes);
      tracker.updateDownloadStatus(id, DownloadStatus.downloading);
      _persistProgress(id);
    } else {
      final completed = event.status == TorrentDownloadStatus.completed;
      if (completed) {
        tracker.updateDownloadStatus(id, DownloadStatus.completed);
      } else {
        _fail(id, DownloadFailureReason.torrentUnavailable);
      }
      _persist(id);
      _completeTorrentDone(id);
    }
  }

  void _completeTorrentDone(int id) {
    final completer = _torrentDone[id];
    if (completer != null && !completer.isCompleted) completer.complete();
  }

  void _ensureConcurrency() {
    final max = settings.current.concurrentDownloads;
    if (_semaphore.max != max) _semaphore = _Semaphore(max);
  }

  /// Persists the tracker's current view of [id]. Fire-and-forget: a failed
  /// bookkeeping write must never take down the download itself.
  void _persist(int id) {
    final item = tracker.get(id);
    if (item?.recordId == null) return;
    unawaited(downloads.update(item!).catchError((Object _) {}));
  }

  void _persistProgress(int id) {
    final last = _lastPersistedProgress[id];
    final now = DateTime.now();
    if (last != null && now.difference(last) < _progressPersistInterval) return;
    _lastPersistedProgress[id] = now;
    _persist(id);
  }

  void _fail(int id, DownloadFailureReason reason) {
    tracker.updateDownloadStatus(id, DownloadStatus.failed, failureReason: reason);
  }

  Future<void> startDownload(DownloadableFileWithTags file) async {
    final existing = _entities[file.id];
    final current = tracker.get(file.id);

    // A catalog rescan renumbers rows, so an id held from a previous session
    // can legitimately belong to a *different* file now. Comparing the URL
    // stops a genuinely new download from being silently swallowed by the
    // stale entry that happens to share its id.
    final isSameFile = existing != null && existing.downloadUrl == file.downloadUrl;
    if (isSameFile && current != null && !current.isTerminal) return;

    _entities[file.id] = file;
    _ensureTorrentListener();

    final DownloadItem record;
    if (isSameFile && current?.recordId != null) {
      // Re-downloading something already in the list reuses its row rather
      // than appending a second one, so the history holds one entry per
      // file instead of one per attempt.
      if (current!.status == DownloadStatus.completed) {
        // Its staging file is long gone; start clean rather than trying to
        // resume from a path that no longer exists.
        await downloads.setStagingPath(current.recordId!, '').catchError((Object _) {});
      }
      record = current.copyWith(
        status: DownloadStatus.downloading,
        progress: 0,
        downloadSpeed: 0,
        downloadedBytes: current.status == DownloadStatus.completed ? 0 : current.downloadedBytes,
        destinationLabel: '',
        destinationUri: '',
        savedFileName: '',
        clearFailureReason: true,
        clearCompletedAt: true,
      );
      await downloads.update(record).catchError((Object _) {});
    } else {
      final consoleName = (await catalog.getConsoleById(file.consoleId))?.name ?? '';
      record = await downloads.create(file, consoleName: consoleName);
    }

    tracker.upsert(record);
    await _syncForegroundService();

    unawaited(_startRun(file));
  }

  /// Starts/stops the persistent notification + wakelock (`DownloadForegroundService`
  /// equivalent) based on whether any download is currently active.
  // The persistent notification/wakelock is a courtesy on top of the actual
  // download — a failure here (denied permission, a background-start
  // restriction, a missing native service registration) must never block
  // the download itself, so every native call in here is best-effort.
  Future<void> _syncForegroundService() async {
    try {
      if (tracker.hasActiveDownloads) {
        if (await FlutterForegroundTask.isRunningService) return;
        if (await Permission.notification.isDenied) {
          await Permission.notification.request();
        }
        await FlutterForegroundTask.startService(
          serviceTypes: const [ForegroundServiceTypes.dataSync],
          notificationTitle: notificationStrings.title,
          notificationText: notificationStrings.body,
          callback: startForegroundTaskCallback,
        );
      } else if (await FlutterForegroundTask.isRunningService) {
        await FlutterForegroundTask.stopService();
      }
    } catch (_) {
      // Best-effort — see comment above.
    }
  }

  Future<void> retryDownload(int id) async {
    if (!tracker.canRetryDownload(id)) return;
    final file = _entities[id];
    if (file == null) return;
    tracker.resetDownloadForRetry(id);
    _persist(id);
    await _syncForegroundService();
    unawaited(_startRun(file));
  }

  Future<void> cancelDownload(int id) async {
    _cancelTokens[id]?.cancel();
    final file = _entities[id];
    if (file != null && file.isTorrent) {
      try {
        await torrentPlugin.cancelFileDownload(magnet: file.downloadUrl, downloadId: id.toString());
      } catch (_) {
        // The native side may already have torn the download down.
      }
    }
    tracker.updateDownloadStatus(id, DownloadStatus.stopped);
    _persist(id);
    _completeTorrentDone(id);
    await _syncForegroundService();
  }

  Future<void> deleteDownload(int id, {bool deleteFile = false}) async {
    final statusBefore = tracker.get(id)?.status;
    await cancelDownload(id);
    final file = _entities[id];
    if (deleteFile && file != null) {
      await _tryDeleteWrittenFile(file);
    } else if (file != null && statusBefore != DownloadStatus.completed) {
      // An unfinished streaming download leaves a truncated file at the
      // destination. Nobody else created it and it is unusable, so removing
      // the entry removes it too — a completed download's file is the
      // user's and is never touched here.
      await _discardPartialDestinationFile(id, file);
    }
    await _deleteStagingFile(id);
    final item = tracker.get(id);
    if (item?.recordId != null) {
      await downloads.delete(item!.recordId!).catchError((Object _) {});
    }
    _entities.remove(id);
    _lastPersistedProgress.remove(id);
    tracker.removeDownload(id);
  }

  /// Drops every finished/failed row, leaving running downloads alone.
  Future<void> clearHistory() async {
    for (final item in tracker.terminalItems) {
      await _deleteStagingFile(item.id);
      _entities.remove(item.id);
      _lastPersistedProgress.remove(item.id);
    }
    await downloads.clearHistory().catchError((Object _) => 0);
    tracker.removeTerminal();
  }

  /// Deletes the partially-written destination file of a download that never
  /// completed. Best-effort: the folder permission may be gone, or the user
  /// may have moved the file themselves.
  Future<void> _discardPartialDestinationFile(int id, DownloadableFileWithTags file) async {
    try {
      final item = tracker.get(id);
      if (item == null || item.destinationUri.isEmpty) return;
      if (item.downloadedBytes <= 0) return;
      final settingsState = settings.current;
      if (ArchiveExtensions.isExtractable(file.fileExtension) && settingsState.autoUnzip) {
        // Archives were staged locally, so nothing partial ever reached the
        // destination.
        return;
      }
      final subPath = await _resolveSubPath(file, settingsState);
      final dirUri = subPath.isEmpty
          ? item.destinationUri
          : await safStorage.ensureDirectory(item.destinationUri, subPath);
      final doc = await safStorage.findChild(dirUri, _destinationFileName(file));
      if (doc != null) await safStorage.deleteFile(doc.uri);
    } catch (_) {
      // Best-effort.
    }
  }

  Future<void> _deleteStagingFile(int id) async {
    try {
      final item = tracker.get(id);
      if (item?.recordId == null) return;
      final path = await downloads.stagingPathOf(item!.recordId!);
      if (path.isEmpty) return;
      final staged = File(path);
      if (await staged.exists()) await staged.delete();
    } catch (_) {
      // Best-effort.
    }
  }

  /// Best-effort removal of the file [DownloadManager] previously wrote to
  /// the SAF destination for a *plain* (non-extracted) download. Extracted
  /// archives aren't covered — the app doesn't persist the list of names an
  /// extraction produced, so there's no reliable single file to find and
  /// delete for those. Swallows errors (permission revoked, already moved by
  /// the user, etc.) since this only runs as a courtesy on top of removing
  /// the in-app list entry, which always succeeds regardless.
  Future<void> _tryDeleteWrittenFile(DownloadableFileWithTags file) async {
    try {
      final settingsState = settings.current;
      final shouldExtract = ArchiveExtensions.isExtractable(file.fileExtension) && settingsState.autoUnzip;
      if (shouldExtract) return;

      final destDirUri = await _resolveDestDirUri(file, settingsState);
      if (destDirUri.isEmpty) return;
      final subPath = await _resolveSubPath(file, settingsState);
      final dirUri = subPath.isEmpty ? destDirUri : await safStorage.ensureDirectory(destDirUri, subPath);
      final doc = await safStorage.findChild(dirUri, _destinationFileName(file));
      if (doc != null) await safStorage.deleteFile(doc.uri);
    } catch (_) {
      // Best-effort.
    }
  }

  /// Guards against a second `_run` for the same download starting while a
  /// previous one — including its copy/extract phase, which `cancelDownload`
  /// doesn't interrupt — is still finishing. Without this, a fast
  /// cancel-then-retry could reopen (and truncate) the same local staging file
  /// the still-finishing old run is reading from, or have the old run delete
  /// the file the new run just started writing. The new run simply waits
  /// for the previous one to fully finish first instead of racing it.
  Future<void> _startRun(DownloadableFileWithTags file) async {
    final previous = _activeRuns[file.id];
    if (previous != null) {
      try {
        await previous;
      } catch (_) {
        // Previous run's own error handling already updated tracker status.
      }
    }

    final future = _run(file);
    _activeRuns[file.id] = future;
    try {
      await future;
    } finally {
      if (identical(_activeRuns[file.id], future)) {
        _activeRuns.remove(file.id);
      }
    }
  }

  Future<void> _run(DownloadableFileWithTags file) async {
    _ensureConcurrency();
    final semaphore = _semaphore;
    await semaphore.acquire();
    try {
      await Future.delayed(const Duration(seconds: 1));
      if (tracker.get(file.id)?.status == DownloadStatus.stopped) return;
      if (file.isTorrent) {
        await _performTorrentDownload(file);
      } else {
        await _performHttpDownload(file);
      }
    } catch (e) {
      // A throw escaping this far would otherwise become an unhandled async
      // error — the download would look stuck at "downloading" forever.
      _fail(file.id, _classify(e));
      _persist(file.id);
    } finally {
      semaphore.release();
      await _syncForegroundService();
    }
  }

  /// Maps a caught error onto a stable, user-explainable reason. Nothing
  /// from the exception's text is kept — see [DownloadFailureReason].
  DownloadFailureReason _classify(Object error) {
    if (error is IncompleteDownloadException) return DownloadFailureReason.incomplete;
    if (error is InsufficientSpaceException) return DownloadFailureReason.insufficientSpace;
    if (error is _DestinationUnavailableException) return DownloadFailureReason.destinationUnavailable;
    if (error is FileSystemException) {
      // ENOSPC. Android surfaces a full volume this way rather than through
      // any API that would let us check free space up front.
      if (error.osError?.errorCode == 28) return DownloadFailureReason.insufficientSpace;
      return DownloadFailureReason.destinationWriteFailed;
    }
    if (error is PlatformException) {
      // The message is read only to *classify*; it is never displayed, and
      // the caller only ever sees the enum value. Android surfaces a full
      // volume through SAF as a plain IOException string, with no code to
      // switch on.
      final detail = '${error.message ?? ''} ${error.details ?? ''}';
      if (detail.contains('ENOSPC') || detail.contains('No space left')) {
        return DownloadFailureReason.insufficientSpace;
      }
      return DownloadFailureReason.destinationWriteFailed;
    }
    if (error is DioException) return DownloadFailureReason.network;
    return DownloadFailureReason.unknown;
  }

  Future<void> _performTorrentDownload(DownloadableFileWithTags file) async {
    final done = Completer<void>();
    _torrentDone[file.id] = done;
    try {
      await torrentPlugin.startFileDownload(
        magnet: file.downloadUrl,
        fileIndex: file.torrentFileIndex!,
        fileName: _destinationFileName(file),
        downloadId: file.id.toString(),
      );
    } catch (e) {
      _fail(file.id, DownloadFailureReason.torrentUnavailable);
      _persist(file.id);
      _torrentDone.remove(file.id);
      return;
    }

    await done.future;
    _torrentDone.remove(file.id);

    if (tracker.get(file.id)?.status != DownloadStatus.completed) return;

    try {
      final settingsState = settings.current;
      final destDirUri = await _resolveDestDirUri(file, settingsState);
      if (destDirUri.isEmpty) throw const _DestinationUnavailableException();
      final subPath = await _resolveSubPath(file, settingsState);
      final shouldExtract = ArchiveExtensions.isExtractable(file.fileExtension) && settingsState.autoUnzip;

      tracker.updateDownloadStatus(file.id, shouldExtract ? DownloadStatus.unzipping : DownloadStatus.copying);
      _persist(file.id);

      final written = await torrentPlugin.finishFileDownload(
        magnet: file.downloadUrl,
        fileName: _destinationFileName(file),
        downloadId: file.id.toString(),
        destDirUri: destDirUri,
        subPath: subPath,
        extract: shouldExtract,
      );
      await _markCompleted(file, destDirUri, subPath, written);
    } catch (e) {
      _fail(file.id, e is _DestinationUnavailableException
          ? DownloadFailureReason.destinationUnavailable
          : (ArchiveExtensions.isExtractable(file.fileExtension) && settings.current.autoUnzip
              ? DownloadFailureReason.extractionFailed
              : DownloadFailureReason.destinationWriteFailed));
      _persist(file.id);
    }
  }

  Future<void> _performHttpDownload(DownloadableFileWithTags file) async {
    final cancelToken = CancelToken();
    _cancelTokens[file.id] = cancelToken;

    final settingsState = settings.current;
    final shouldExtract = ArchiveExtensions.isExtractable(file.fileExtension) && settingsState.autoUnzip;

    // Resolved up front rather than after the transfer: discovering that no
    // destination is configured is worth knowing *before* spending an hour
    // pulling down a disc image, not after.
    final destDirUri = await _resolveDestDirUri(file, settingsState);
    if (destDirUri.isEmpty) {
      _fail(file.id, DownloadFailureReason.destinationUnavailable);
      _persist(file.id);
      _cancelTokens.remove(file.id);
      return;
    }
    final subPath = await _resolveSubPath(file, settingsState);

    final DownloadTarget target;
    File? stagingFile;
    if (shouldExtract) {
      // 7-Zip-JBinding extracts from a seekable local file, so an archive
      // genuinely has to be staged first.
      stagingFile = await _stagingFile(file);
      target = LocalFileDownloadTarget(stagingFile);
    } else {
      // Everything else — the multi-gigabyte .chd/.iso case — goes straight
      // into the destination, so internal storage is never involved.
      final destDir = await safStorage.ensureDirectory(destDirUri, subPath);
      target = SafDownloadTarget(
        safStream: _safStream,
        safStorage: safStorage,
        dirUri: destDir,
        fileName: _destinationFileName(file),
      );
      // Recorded before a byte is written so the Downloads screen can show
      // where the file is going, and so a later delete knows what to clean.
      _recordDestination(file, destDirUri, subPath);
    }

    try {
      Object? lastError;
      for (var attempt = 0; attempt < 3; attempt++) {
        if (cancelToken.isCancelled) break;
        try {
          if (attempt > 0) await Future.delayed(Duration(seconds: 2 * attempt));
          await _downloadAttempt(file, target, cancelToken);
          lastError = null;
          break;
        } catch (e) {
          if (e is DioException && CancelToken.isCancel(e)) rethrow;
          lastError = e;
        }
      }
      if (lastError != null) throw lastError;
      if (cancelToken.isCancelled) {
        // Cancelling is explicit: drop the partial output rather than
        // leaving it to be silently resumed later.
        await target.discard();
        return;
      }

      if (shouldExtract) {
        await _extractStagedArchive(file, stagingFile!, destDirUri, subPath);
      } else {
        await _markCompleted(file, destDirUri, subPath, [_destinationFileName(file)]);
      }
    } catch (e) {
      final isCancel = e is DioException && CancelToken.isCancel(e);
      if (isCancel) {
        await target.discard();
        tracker.updateDownloadStatus(file.id, DownloadStatus.stopped);
      } else {
        // The partial output is deliberately KEPT so a retry resumes from it
        // instead of re-downloading gigabytes already on disk — losing that
        // progress on every hiccup was the single worst part of a flaky
        // connection. `deleteDownload` is what finally removes it.
        _fail(file.id, _classify(e));
      }
      _persist(file.id);
    } finally {
      _cancelTokens.remove(file.id);
    }
  }

  /// Notes where this download is being written, before it finishes, so the
  /// destination is visible while it runs and a failed streaming download
  /// can have its half-written file cleaned up later.
  void _recordDestination(DownloadableFileWithTags file, String destDirUri, String subPath) {
    tracker.updateDownloadStatus(
      file.id,
      tracker.get(file.id)?.status ?? DownloadStatus.downloading,
      destinationUri: destDirUri,
      destinationLabel: _destinationLabel(destDirUri, subPath),
    );
    _persist(file.id);
  }

  /// The staging file for [file], reusing the path recorded on a previous
  /// (interrupted) attempt when there is one so its bytes are picked up.
  Future<File> _stagingFile(DownloadableFileWithTags file) async {
    final item = tracker.get(file.id);
    final recordId = item?.recordId;

    if (recordId != null) {
      final recorded = await downloads.stagingPathOf(recordId);
      if (recorded.isNotEmpty) return File(recorded);
    }

    // `getApplicationSupportDirectory`, not `getTemporaryDirectory`: Android
    // purges the cache directory whenever the device is short on space, so a
    // half-finished multi-GB ROM staged there could vanish mid-download.
    final localDir = _httpDownloadsDir ??
        Directory('${(await getApplicationSupportDirectory()).path}/http_downloads');
    await localDir.create(recursive: true);
    final staged = File('${localDir.path}/${file.id}_${_destinationFileName(file)}');

    if (recordId != null) {
      await downloads.setStagingPath(recordId, staged.path).catchError((Object _) {});
    }
    return staged;
  }

  /// Resumes from wherever the previous attempt left off instead of always
  /// restarting from byte 0 — each retry used to reopen [localFile] with the
  /// truncating default `openWrite()`, discarding whatever a prior attempt
  /// had already downloaded even though the file was deliberately kept on
  /// disk between retries.
  Future<void> _downloadAttempt(
    DownloadableFileWithTags file,
    DownloadTarget target,
    CancelToken cancelToken,
  ) async {
    // Streaming straight into the destination folder means a file with a
    // matching name may simply be one the user already had, so bytes there
    // are only resumed onto once this download is known to have written
    // some. A private staging file carries no such ambiguity — see
    // `DownloadTarget.requiresPriorWriteToResume`.
    final mayResume = !target.requiresPriorWriteToResume ||
        (tracker.get(file.id)?.downloadedBytes ?? 0) > 0;
    final existingBytes = mayResume ? await target.existingBytes() : 0;

    final response = await _dio.get<ResponseBody>(
      file.downloadUrl,
      cancelToken: cancelToken,
      options: Options(
        responseType: ResponseType.stream,
        followRedirects: true,
        headers: {
          'User-Agent': ScrapingConstants.userAgent,
          if (existingBytes > 0) 'Range': 'bytes=$existingBytes-',
        },
      ),
    );

    // The server only actually resumed if it answered 206 Partial Content —
    // a 200 OK means it ignored the Range header and is sending the whole
    // file again from byte 0, so the partial local file must be truncated.
    final isResuming = existingBytes > 0 && response.statusCode == 206;
    final total = _resolveTotalBytes(response, fallback: file.fileSize, resumedFrom: isResuming ? existingBytes : null);
    final sink = await target.open(append: isResuming);
    var downloaded = isResuming ? existingBytes : 0;
    var bytesSinceCheck = 0;
    var lastSpeedCheck = DateTime.now();
    var lastUpdate = DateTime.now();
    var lastDownloaded = downloaded;
    final speedLimit = (settings.current).limitSpeedMbs;

    try {
      await for (final chunk in response.data!.stream) {
        if (cancelToken.isCancelled) break;
        await sink.add(chunk);
        downloaded += chunk.length;
        bytesSinceCheck += chunk.length;

        final now = DateTime.now();
        final sinceCheckSec = now.difference(lastSpeedCheck).inMilliseconds / 1000;
        if (sinceCheckSec >= 0.1) {
          final speed = DownloadSpeedController.calculateSpeedMbs(bytesSinceCheck, sinceCheckSec);
          await DownloadSpeedController.applyThrottle(
            currentSpeedMbs: speed,
            limitMbs: speedLimit,
            bytesSinceLastCheck: bytesSinceCheck,
            timeSinceLastCheckSeconds: sinceCheckSec,
          );
          lastSpeedCheck = now;
          bytesSinceCheck = 0;
        }

        final progress = total > 0 ? (downloaded / total).clamp(0.0, 1.0) : 0.0;
        final sinceUpdateMs = now.difference(lastUpdate).inMilliseconds;
        if (sinceUpdateMs >= 500) {
          final elapsed = sinceUpdateMs / 1000;
          final speedMBs = DownloadSpeedController.calculateSpeedMbs(downloaded - lastDownloaded, elapsed);
          tracker.updateDownloadProgress(file.id, progress, speedMBs, downloaded);
          _persistProgress(file.id);
          lastUpdate = now;
          lastDownloaded = downloaded;
        }
      }
    } finally {
      await sink.close();
    }

    // Record the true byte count now the attempt is over, instead of leaving
    // it at whatever the last 500ms tick happened to catch. A transfer that
    // dies inside the first half-second would otherwise be recorded as
    // having written nothing, and the next attempt would overwrite the bytes
    // that are actually on disk rather than resuming past them.
    tracker.updateDownloadProgress(
      file.id,
      total > 0 ? (downloaded / total).clamp(0.0, 1.0) : 0.0,
      0,
      downloaded,
    );
    _persist(file.id);

    if (cancelToken.isCancelled) return;

    // A dropped connection ends the response stream *without* throwing, so
    // without this check a half-transferred file walked straight through to
    // the copy step and was reported as a successful download — the "it says
    // it finished but the file is broken/missing" report, and the reason
    // large .chd/.iso downloads appeared to succeed and then wouldn't load.
    if (total > 0 && downloaded < total) {
      throw IncompleteDownloadException(received: downloaded, expected: total);
    }
  }

  /// True total file size, even mid-resume where `Content-Length` on a 206
  /// response only reflects the *remaining* bytes, not the whole file.
  int _resolveTotalBytes(Response<ResponseBody> response, {required int fallback, int? resumedFrom}) {
    if (resumedFrom != null) {
      final contentRange = response.headers.value('content-range');
      final slashIndex = contentRange?.lastIndexOf('/') ?? -1;
      if (slashIndex != -1) {
        final parsed = int.tryParse(contentRange!.substring(slashIndex + 1));
        if (parsed != null) return parsed;
      }
      final remaining = int.tryParse(response.headers.value(Headers.contentLengthHeader) ?? '');
      if (remaining != null) return resumedFrom + remaining;
      return fallback;
    }
    return int.tryParse(response.headers.value(Headers.contentLengthHeader) ?? '') ?? fallback;
  }

  /// Unpacks a staged archive into the destination and drops the staging
  /// copy. Only archives take this path — everything else has already been
  /// written straight to the destination by the time the transfer ends.
  Future<void> _extractStagedArchive(
    DownloadableFileWithTags file,
    File stagingFile,
    String destDirUri,
    String subPath,
  ) async {
    tracker.updateDownloadStatus(file.id, DownloadStatus.unzipping);
    _persist(file.id);
    final written = await torrentPlugin.extractArchive(
      archivePath: stagingFile.path,
      destDirUri: destDirUri,
      subPath: subPath,
    );
    if (await stagingFile.exists()) await stagingFile.delete();
    await _markCompleted(file, destDirUri, subPath, written);
  }

  /// Records where the file landed alongside the completed status, so the
  /// Downloads screen can tell the user the folder instead of just "done".
  Future<void> _markCompleted(
    DownloadableFileWithTags file,
    String destDirUri,
    String subPath,
    List<String> written,
  ) async {
    tracker.updateDownloadStatus(
      file.id,
      DownloadStatus.completed,
      destinationLabel: _destinationLabel(destDirUri, subPath),
      destinationUri: destDirUri,
      savedFileName: written.isEmpty ? _destinationFileName(file) : written.first,
      completedAt: DateTime.now(),
    );
    _persist(file.id);
  }

  /// `volume:path` form persisted on the download row; the UI turns the
  /// volume into "Internal storage"/"SD card" in the user's language.
  String _destinationLabel(String destDirUri, String subPath) {
    final location = SafPathLabel.fromStored(SafPathLabel.store(destDirUri));
    final fullPath = [
      if (location.path.isNotEmpty) location.path,
      if (subPath.isNotEmpty) subPath,
    ].join('/');
    return location.volume.isEmpty ? fullPath : '${location.volume}:$fullPath';
  }

  /// The name to write at the destination.
  ///
  /// Rows scraped by an older build stored the raw `href` here (which can be
  /// `sub/dir/Game.iso`, or an absolute URL), and handing that to SAF either
  /// failed outright or produced a document the user could never find. Every
  /// name goes back through [FileNaming] at download time so those rows are
  /// repaired without needing a rescan; it is idempotent for clean names.
  String _destinationFileName(DownloadableFileWithTags file) {
    final resolved = FileNaming.fileNameFromHref(file.fileName);
    return resolved.isEmpty ? FileNaming.fallbackName(file.id, file.name) : resolved;
  }

  Future<String> _resolveDestDirUri(DownloadableFileWithTags file, SettingsState s) async {
    final uri = s.consoleDownloadDirectories[file.consoleId] ?? s.downloadDirectory;
    if (uri.isEmpty) return '';
    return await safStorage.isValidTreeUri(uri) ? uri : '';
  }

  Future<String> _resolveSubPath(DownloadableFileWithTags file, SettingsState s) async {
    if (s.consoleDownloadDirectories.containsKey(file.consoleId)) return '';
    if (!s.separateByConsole) return '';
    final console = await catalog.getConsoleById(file.consoleId);
    return DownloadPathResolver.sanitizeFolderName(console?.name ?? 'Unknown');
  }

  void dispose() {
    _torrentSub?.cancel();
  }
}

/// No usable download folder: none configured, or the SAF grant for the
/// configured one is gone (app data cleared, SD card removed, folder deleted).
class _DestinationUnavailableException implements Exception {
  const _DestinationUnavailableException();
}
