import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pixelvault_torrent/pixelvault_torrent.dart';
import 'package:saf_stream/saf_stream.dart';

import '../db/daos/catalog_repository.dart';
import '../db/daos/download_repository.dart';
import '../diagnostics/diagnostics_log.dart';
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
///
/// The list itself lives in [FileNaming.isArchiveExtension], which the
/// Library also uses to label a file by what it unpacks to — one list, so
/// the label and the extraction can never disagree.
abstract final class ArchiveExtensions {
  static bool isExtractable(String extension) => FileNaming.isArchiveExtension(extension);
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

/// What [DownloadManager.startDownload] did with a request.
enum StartDownloadResult {
  /// A new attempt was created and queued.
  started,

  /// An interrupted attempt at the same file was picked back up instead of
  /// starting a second copy of it alongside.
  resumed,

  /// That file is already downloading; nothing new was started.
  alreadyActive,
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
/// Every download *attempt* is its own row in the `downloads` table, and that
/// row id is the identity used here, in the tracker and in the native torrent
/// plugin. It used to be the catalog file id, which meant a cancelled attempt
/// and a fresh attempt at the same file shared one cancel token, one status
/// entry and one history row: the old run's cleanup could flip the new run's
/// status, and starting the file again silently overwrote the history of the
/// previous download.
///
/// State is mirrored into the `downloads` table as it changes, so an app
/// restart resumes the queue and keeps the history instead of losing both.
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

  /// Keyed by attempt id.
  final _files = <int, DownloadableFileWithTags>{};
  final _cancelTokens = <int, CancelToken>{};
  final _torrentDone = <int, Completer<void>>{};
  final _running = <int>{};
  final _lastPersistedProgress = <int, DateTime>{};

  /// Serialises attempts at the same source. Two attempts at one file write
  /// the same destination name, so a new attempt waits until the previous
  /// one — including a cancel's cleanup, which deletes its partial output by
  /// name — has completely finished.
  final _runsBySource = <String, Future<void>>{};

  _Semaphore _semaphore = _Semaphore(3);
  StreamSubscription<TorrentProgressEvent>? _torrentSub;
  final _completions = StreamController<DownloadItem>.broadcast();
  bool _restoreStarted = false;

  /// Throttles progress writes to the DB — a download emits a progress tick
  /// every 500ms, and persisting each one would mean thousands of writes per
  /// file for no benefit, since only the last value matters on restore.
  static const _progressPersistInterval = Duration(seconds: 3);

  DownloadNotificationStrings notificationStrings = DownloadNotificationStrings.fallback;

  /// Every attempt that completes, so anything caching what a destination
  /// folder contains knows to look again.
  Stream<DownloadItem> get completions => _completions.stream;

  /// Re-attaches the queue and history left behind by a previous process.
  ///
  /// Rows that were mid-flight when the process died come back as `stopped`
  /// (their worker is gone), which the Downloads screen renders as a
  /// resumable queue entry.
  Future<void> restore() async {
    if (_restoreStarted) return;
    _restoreStarted = true;
    try {
      final persisted = await downloads.getAll();
      if (persisted.isEmpty) return;
      await downloads.reconcileInterrupted();

      final restored = <DownloadItem>[];
      for (final item in persisted) {
        final normalized = item.isActive ? item.copyWith(status: DownloadStatus.stopped) : item;
        restored.add(normalized);
        final row = await downloads.row(normalized.id);
        if (row != null) _files[normalized.id] = DownloadRepository.toCatalogFile(row);
      }
      tracker.mergeRestored(restored);
    } catch (e, stack) {
      // This used to escape as an unhandled async error and leave the queue
      // and history silently empty. Whatever did load stays.
      debugPrint('DownloadManager.restore failed: $e\n$stack');
      Diagnostics.record('download', 'restore failed: $e', stack);
    }
  }

  void _ensureTorrentListener() {
    // `onError` matters: without it a malformed native event became an
    // unhandled async error that took down the zone instead of skipping the
    // event.
    _torrentSub ??= torrentPlugin.progressStream.listen(
      _handleTorrentEvent,
      onError: (Object _) {},
      cancelOnError: false,
    );
  }

  void _handleTorrentEvent(TorrentProgressEvent event) {
    final id = int.tryParse(event.downloadId);
    if (id == null) return;
    final item = tracker.get(id);
    // A late event for an attempt that was cancelled, already finished, or
    // belongs to an earlier session must not bring it back to life.
    if (item == null || item.isTerminal) return;

    if (event.status == TorrentDownloadStatus.downloading) {
      tracker.updateDownloadProgress(id, event.progress, event.speedMBs, event.downloadedBytes);
      tracker.updateDownloadStatus(id, DownloadStatus.downloading);
      _persistProgress(id);
    } else {
      if (event.status == TorrentDownloadStatus.completed) {
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
    if (item == null) return;
    unawaited(downloads.update(item).catchError((Object _) {}));
  }

  void _persistProgress(int id) {
    final last = _lastPersistedProgress[id];
    final now = DateTime.now();
    if (last != null && now.difference(last) < _progressPersistInterval) return;
    _lastPersistedProgress[id] = now;
    _persist(id);
  }

  /// Marks [id] failed for [reason]. [error], when there is one, only goes to
  /// the on-device diagnostics log; the user is shown [reason].
  void _fail(int id, DownloadFailureReason reason, [Object? error]) {
    // A cancellation is final: whatever the unwinding worker runs into next
    // must not relabel it as a failure.
    if (tracker.get(id)?.status == DownloadStatus.cancelled) return;
    tracker.updateDownloadStatus(id, DownloadStatus.failed, failureReason: reason);
    final detail = error == null ? '' : ' (${error.runtimeType}: $error)';
    Diagnostics.record('download', 'attempt $id failed: ${reason.name}$detail');
  }

  /// Starts downloading [file].
  ///
  /// Starting a file that already has an unfinished attempt does not create a
  /// second one next to it — both would write to the same destination file.
  /// A running attempt is left alone; an interrupted one is resumed. Once an
  /// attempt has finished, failed or been cancelled, starting the file again
  /// is a new attempt with its own history entry.
  Future<StartDownloadResult> startDownload(DownloadableFileWithTags file) async {
    final existing = tracker.queuedFor(file.downloadUrl);
    if (existing != null) {
      if (existing.status != DownloadStatus.stopped) return StartDownloadResult.alreadyActive;
      _files[existing.id] ??= file;
      await retryDownload(existing.id);
      return StartDownloadResult.resumed;
    }

    _ensureTorrentListener();
    final consoleName = (await catalog.getConsoleById(file.consoleId))?.name ?? '';
    final record = await downloads.create(file, consoleName: consoleName);
    _files[record.id] = file;
    tracker.upsert(record);
    await _syncForegroundService();

    unawaited(_startRun(record.id));
    return StartDownloadResult.started;
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

  /// Retries a failed attempt or resumes an interrupted one in place, keeping
  /// its bytes. A cancelled attempt discarded its bytes and stays in the
  /// history as cancelled, so retrying it starts a new attempt instead.
  Future<void> retryDownload(int id) async {
    final item = tracker.get(id);
    final file = _files[id];
    if (item == null || file == null || !tracker.canRetryDownload(id)) return;

    if (item.status == DownloadStatus.cancelled) {
      await startDownload(file);
      return;
    }

    // Another attempt at the same file is already in the queue; running this
    // one too would put two writers on one destination file.
    final other = tracker.queuedFor(file.downloadUrl);
    if (other != null && other.id != id) return;

    tracker.resetDownloadForRetry(id);
    _persist(id);
    _ensureTorrentListener();
    await _syncForegroundService();
    unawaited(_startRun(id));
  }

  /// Cancels a running or queued attempt. It moves to the history as
  /// cancelled, with its partial output removed.
  Future<void> cancelDownload(int id) async {
    final item = tracker.get(id);
    if (item == null || item.isTerminal) return;
    final wasRunning = _running.contains(id);

    _cancelTokens[id]?.cancel();
    final file = _files[id];
    if (file != null && file.isTorrent) {
      try {
        await torrentPlugin.cancelFileDownload(magnet: file.downloadUrl, downloadId: '$id');
      } catch (_) {
        // The native side may already have torn the download down.
      }
    }
    tracker.updateDownloadStatus(id, DownloadStatus.cancelled);
    _persist(id);
    _completeTorrentDone(id);
    // A running attempt discards its own partial output as its worker
    // unwinds. One that was only waiting for a slot, or interrupted by an
    // earlier process, has no worker left to do that.
    if (!wasRunning) await _discardPartialOutput(id);
    await _syncForegroundService();
  }

  /// Deletes history entries — finished, failed or cancelled attempts — and
  /// nothing else.
  ///
  /// Ids of attempts still running or queued are ignored: the history is the
  /// only thing the user deletes, and a download leaves the queue only by
  /// finishing, failing or being cancelled. A completed download's file is
  /// never touched; what a failed attempt left half-written is removed.
  Future<void> deleteHistoryEntries(Set<int> ids) async {
    final removable = <int>{
      for (final id in ids)
        if (tracker.get(id)?.isTerminal ?? false) id,
    };
    if (removable.isEmpty) return;

    for (final id in removable) {
      if (tracker.get(id)?.status == DownloadStatus.failed) {
        await _discardPartialOutput(id);
      } else {
        await _deleteStagingFile(id);
      }
    }
    await downloads.deleteMany(removable).catchError((Object _) => 0);
    for (final id in removable) {
      _files.remove(id);
      _lastPersistedProgress.remove(id);
    }
    tracker.removeMany(removable);
  }

  /// Deletes the whole history; the queue is untouched.
  Future<void> clearHistory() async {
    await deleteHistoryEntries(tracker.terminalItems.map((d) => d.id).toSet());
    // Also catches rows the tracker never loaded, e.g. if restore failed.
    await downloads.clearHistory().catchError((Object _) => 0);
  }

  Future<void> _deleteStagingFile(int id) async {
    try {
      final path = await downloads.stagingPathOf(id);
      if (path.isEmpty) return;
      final staged = File(path);
      if (await staged.exists()) await staged.delete();
    } catch (_) {
      // Best-effort.
    }
  }

  /// Removes what an unfinished attempt left behind: its staging file and —
  /// for a download that streamed straight into the destination — the
  /// truncated file there. Never touches a completed download's file, and
  /// never a destination file another unfinished attempt at the same source
  /// is writing. Best-effort throughout.
  Future<void> _discardPartialOutput(int id) async {
    await _deleteStagingFile(id);
    final item = tracker.get(id);
    final file = _files[id];
    if (item == null || file == null) return;
    if (item.status == DownloadStatus.completed) return;
    if (item.destinationUri.isEmpty || item.downloadedBytes <= 0) return;

    final other = tracker.queuedFor(file.downloadUrl);
    if (other != null && other.id != id) return;

    try {
      final settingsState = settings.current;
      // Archives were staged locally, so nothing partial reached the destination.
      if (ArchiveExtensions.isExtractable(file.fileExtension) && settingsState.autoUnzip) return;
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

  /// Runs attempt [id] once any earlier attempt at the same source has fully
  /// finished. The slot is claimed before waiting, so a third attempt queues
  /// behind this one rather than also waiting only on the first.
  Future<void> _startRun(int id) async {
    final file = _files[id];
    if (file == null) return;
    final key = file.downloadUrl;

    final previous = _runsBySource[key];
    final done = Completer<void>();
    _runsBySource[key] = done.future;
    try {
      if (previous != null) {
        try {
          await previous;
        } catch (_) {
          // The previous run's own error handling already updated its status.
        }
      }
      await _run(id, file);
    } finally {
      done.complete();
      if (identical(_runsBySource[key], done.future)) _runsBySource.remove(key);
    }
  }

  Future<void> _run(int id, DownloadableFileWithTags file) async {
    _ensureConcurrency();
    final semaphore = _semaphore;
    await semaphore.acquire();
    _running.add(id);
    try {
      await Future.delayed(const Duration(seconds: 1));
      final item = tracker.get(id);
      // Cancelled (or otherwise settled) while it was waiting for a slot.
      if (item == null || item.isTerminal || item.status == DownloadStatus.stopped) {
        if (item?.status == DownloadStatus.cancelled) await _discardPartialOutput(id);
        return;
      }
      if (file.isTorrent) {
        await _performTorrentDownload(id, file);
      } else {
        await _performHttpDownload(id, file);
      }
    } catch (e) {
      // A throw escaping this far would otherwise become an unhandled async
      // error — the download would look stuck at "downloading" forever.
      _fail(id, _classify(e), e);
      _persist(id);
    } finally {
      _running.remove(id);
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

  Future<void> _performTorrentDownload(int id, DownloadableFileWithTags file) async {
    final done = Completer<void>();
    _torrentDone[id] = done;
    try {
      await torrentPlugin.startFileDownload(
        magnet: file.downloadUrl,
        fileIndex: file.torrentFileIndex!,
        fileName: _destinationFileName(file),
        downloadId: '$id',
      );
    } catch (e) {
      _fail(id, DownloadFailureReason.torrentUnavailable, e);
      _persist(id);
      _torrentDone.remove(id);
      return;
    }

    await done.future;
    _torrentDone.remove(id);

    if (tracker.get(id)?.status != DownloadStatus.completed) return;

    try {
      final settingsState = settings.current;
      final destDirUri = await _resolveDestDirUri(file, settingsState);
      if (destDirUri.isEmpty) throw const _DestinationUnavailableException();
      final subPath = await _resolveSubPath(file, settingsState);
      final shouldExtract = ArchiveExtensions.isExtractable(file.fileExtension) && settingsState.autoUnzip;

      tracker.updateDownloadStatus(id, shouldExtract ? DownloadStatus.unzipping : DownloadStatus.copying);
      _persist(id);

      final written = await torrentPlugin.finishFileDownload(
        magnet: file.downloadUrl,
        fileName: _destinationFileName(file),
        downloadId: '$id',
        destDirUri: destDirUri,
        subPath: subPath,
        extract: shouldExtract,
      );
      await _markCompleted(id, file, destDirUri, subPath, written);
    } catch (e) {
      _fail(
        id,
        e is _DestinationUnavailableException
            ? DownloadFailureReason.destinationUnavailable
            : (ArchiveExtensions.isExtractable(file.fileExtension) && settings.current.autoUnzip
                ? DownloadFailureReason.extractionFailed
                : DownloadFailureReason.destinationWriteFailed),
        e,
      );
      _persist(id);
    }
  }

  Future<void> _performHttpDownload(int id, DownloadableFileWithTags file) async {
    final cancelToken = CancelToken();
    _cancelTokens[id] = cancelToken;

    final settingsState = settings.current;
    final shouldExtract = ArchiveExtensions.isExtractable(file.fileExtension) && settingsState.autoUnzip;

    // Resolved up front rather than after the transfer: discovering that no
    // destination is configured is worth knowing *before* spending an hour
    // pulling down a disc image, not after.
    final destDirUri = await _resolveDestDirUri(file, settingsState);
    if (destDirUri.isEmpty) {
      _fail(id, DownloadFailureReason.destinationUnavailable);
      _persist(id);
      _cancelTokens.remove(id);
      return;
    }
    final subPath = await _resolveSubPath(file, settingsState);

    final DownloadTarget target;
    File? stagingFile;
    if (shouldExtract) {
      // 7-Zip-JBinding extracts from a seekable local file, so an archive
      // genuinely has to be staged first.
      stagingFile = await _stagingFile(id, file);
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
      // where the file is going, and so a later cleanup knows what to remove.
      _recordDestination(id, destDirUri, subPath);
    }

    try {
      Object? lastError;
      for (var attempt = 0; attempt < 3; attempt++) {
        if (cancelToken.isCancelled) break;
        try {
          if (attempt > 0) await Future.delayed(Duration(seconds: 2 * attempt));
          await _downloadAttempt(id, file, target, cancelToken);
          lastError = null;
          break;
        } catch (e) {
          if (e is DioException && CancelToken.isCancel(e)) rethrow;
          lastError = e;
        }
      }
      if (lastError != null) throw lastError;
      if (cancelToken.isCancelled) {
        // `cancelDownload` has already marked it cancelled; drop the partial
        // output rather than leaving it behind.
        await target.discard();
        return;
      }

      if (shouldExtract) {
        await _extractStagedArchive(id, file, stagingFile!, destDirUri, subPath);
      } else {
        await _markCompleted(id, file, destDirUri, subPath, [_destinationFileName(file)]);
      }
    } catch (e) {
      final isCancel = e is DioException && CancelToken.isCancel(e);
      if (isCancel) {
        await target.discard();
      } else {
        // The partial output is deliberately KEPT so a retry resumes from it
        // instead of re-downloading gigabytes already on disk. Deleting the
        // history entry is what finally removes it.
        _fail(id, _classify(e), e);
      }
      _persist(id);
    } finally {
      _cancelTokens.remove(id);
    }
  }

  /// Notes where this download is being written, before it finishes, so the
  /// destination is visible while it runs and a failed streaming download
  /// can have its half-written file cleaned up later.
  void _recordDestination(int id, String destDirUri, String subPath) {
    tracker.updateDownloadStatus(
      id,
      tracker.get(id)?.status ?? DownloadStatus.downloading,
      destinationUri: destDirUri,
      destinationLabel: _destinationLabel(destDirUri, subPath),
    );
    _persist(id);
  }

  /// The staging file for attempt [id], reusing the path recorded on an
  /// earlier (interrupted) run of the same attempt so its bytes are picked up.
  Future<File> _stagingFile(int id, DownloadableFileWithTags file) async {
    final recorded = await downloads.stagingPathOf(id);
    if (recorded.isNotEmpty) return File(recorded);

    // `getApplicationSupportDirectory`, not `getTemporaryDirectory`: Android
    // purges the cache directory whenever the device is short on space, so a
    // half-finished multi-GB ROM staged there could vanish mid-download.
    final localDir = _httpDownloadsDir ??
        Directory('${(await getApplicationSupportDirectory()).path}/http_downloads');
    await localDir.create(recursive: true);
    final staged = File('${localDir.path}/${id}_${_destinationFileName(file)}');
    await downloads.setStagingPath(id, staged.path).catchError((Object _) {});
    return staged;
  }

  /// Resumes from wherever the previous attempt left off instead of always
  /// restarting from byte 0.
  Future<void> _downloadAttempt(
    int id,
    DownloadableFileWithTags file,
    DownloadTarget target,
    CancelToken cancelToken,
  ) async {
    // Streaming straight into the destination folder means a file with a
    // matching name may simply be one the user already had, so bytes there
    // are only resumed onto once this attempt is known to have written some.
    // A private staging file carries no such ambiguity — see
    // `DownloadTarget.requiresPriorWriteToResume`.
    final mayResume = !target.requiresPriorWriteToResume || (tracker.get(id)?.downloadedBytes ?? 0) > 0;
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
    // file again from byte 0, so the partial output must be truncated.
    final isResuming = existingBytes > 0 && response.statusCode == 206;
    final total = _resolveTotalBytes(response, fallback: file.fileSize, resumedFrom: isResuming ? existingBytes : null);
    final sink = await target.open(append: isResuming);
    var downloaded = isResuming ? existingBytes : 0;
    var bytesSinceCheck = 0;
    var lastSpeedCheck = DateTime.now();
    var lastUpdate = DateTime.now();
    var lastDownloaded = downloaded;
    final speedLimit = settings.current.limitSpeedMbs;

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
          tracker.updateDownloadProgress(id, progress, speedMBs, downloaded);
          _persistProgress(id);
          lastUpdate = now;
          lastDownloaded = downloaded;
        }
      }
    } finally {
      await sink.close();
    }

    // Record the true byte count now the attempt is over, instead of leaving
    // it at whatever the last 500ms tick happened to catch. A transfer that
    // dies inside the first half-second would otherwise be recorded as having
    // written nothing, and the next attempt would overwrite the bytes that are
    // actually on disk rather than resuming past them.
    tracker.updateDownloadProgress(id, total > 0 ? (downloaded / total).clamp(0.0, 1.0) : 0.0, 0, downloaded);
    _persist(id);

    if (cancelToken.isCancelled) return;

    // A dropped connection ends the response stream *without* throwing, so
    // without this check a half-transferred file walked straight through to
    // completion and was reported as a successful download.
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
    int id,
    DownloadableFileWithTags file,
    File stagingFile,
    String destDirUri,
    String subPath,
  ) async {
    tracker.updateDownloadStatus(id, DownloadStatus.unzipping);
    _persist(id);
    final written = await torrentPlugin.extractArchive(
      archivePath: stagingFile.path,
      destDirUri: destDirUri,
      subPath: subPath,
    );
    if (await stagingFile.exists()) await stagingFile.delete();
    await _markCompleted(id, file, destDirUri, subPath, written);
  }

  /// Records where the file landed alongside the completed status, so the
  /// Downloads screen can tell the user the folder instead of just "done".
  Future<void> _markCompleted(
    int id,
    DownloadableFileWithTags file,
    String destDirUri,
    String subPath,
    List<String> written,
  ) async {
    tracker.updateDownloadStatus(
      id,
      DownloadStatus.completed,
      destinationLabel: _destinationLabel(destDirUri, subPath),
      destinationUri: destDirUri,
      savedFileName: written.isEmpty ? _destinationFileName(file) : written.first,
      completedAt: DateTime.now(),
    );
    _persist(id);
    final completed = tracker.get(id);
    // A cancel that landed while the copy or extraction was finishing keeps
    // the attempt cancelled (the tracker refuses to change that status), and
    // it is not announced as a completion.
    if (completed != null && completed.status == DownloadStatus.completed && !_completions.isClosed) {
      _completions.add(completed);
    }
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
    _completions.close();
  }
}

/// No usable download folder: none configured, or the SAF grant for the
/// configured one is gone (app data cleared, SD card removed, folder deleted).
class _DestinationUnavailableException implements Exception {
  const _DestinationUnavailableException();
}
