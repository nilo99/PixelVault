import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pixelvault_torrent/pixelvault_torrent.dart';
import 'package:saf_stream/saf_stream.dart';

import '../db/daos/catalog_repository.dart';
import '../models/downloadable_file.dart';
import '../scraping/scraping_constants.dart';
import '../settings/settings_repository.dart';
import '../storage/saf_storage_helper.dart';
import 'download_item.dart';
import 'download_progress_tracker.dart';
import 'download_speed_controller.dart';
import 'download_status.dart';
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

/// Port of Milou's `DownloadService` — orchestrates both HTTP (via `dio`,
/// staged to a local cache file first) and torrent (via the
/// `pixelvault_torrent` plugin) downloads behind one uniform API, with
/// shared concurrency limiting, speed throttling and auto-extraction.
///
/// Every internal map is keyed by [DownloadableFileWithTags.id] — the DB
/// row's unique id — not by `fileName`, which isn't guaranteed unique across
/// sources (region variants routinely share a file name).
class DownloadManager {
  DownloadManager({
    required this.tracker,
    required this.settings,
    required this.catalog,
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

  void _ensureTorrentListener() {
    _torrentSub ??= torrentPlugin.progressStream.listen((event) {
      final id = int.parse(event.downloadId);
      if (event.status == TorrentDownloadStatus.downloading) {
        tracker.updateDownloadProgress(id, event.progress, event.speedMBs, event.downloadedBytes);
        tracker.updateDownloadStatus(id, DownloadStatus.downloading);
      } else {
        tracker.updateDownloadStatus(
          id,
          event.status == TorrentDownloadStatus.completed ? DownloadStatus.completed : DownloadStatus.failed,
        );
        _completeTorrentDone(id);
      }
    });
  }

  void _completeTorrentDone(int id) {
    final completer = _torrentDone[id];
    if (completer != null && !completer.isCompleted) completer.complete();
  }

  void _ensureConcurrency() {
    final max = settings.current.concurrentDownloads;
    if (_semaphore.max != max) _semaphore = _Semaphore(max);
  }

  Future<void> startDownload(DownloadableFileWithTags file) async {
    if (_entities.containsKey(file.id)) return;
    _entities[file.id] = file;
    _ensureTorrentListener();
    tracker.addDownload(DownloadItem(
      id: file.id,
      name: file.name,
      fileName: file.fileName,
      fileSize: file.fileSize,
      isTorrent: file.isTorrent,
    ));
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
          notificationTitle: 'PixelVault',
          notificationText: 'A descarregar…',
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
    await _syncForegroundService();
    unawaited(_startRun(file));
  }

  Future<void> cancelDownload(int id) async {
    _cancelTokens[id]?.cancel();
    final file = _entities[id];
    if (file != null && file.isTorrent) {
      await torrentPlugin.cancelFileDownload(magnet: file.downloadUrl, downloadId: id.toString());
    }
    tracker.updateDownloadStatus(id, DownloadStatus.stopped);
    _completeTorrentDone(id);
    await _syncForegroundService();
  }

  Future<void> deleteDownload(int id, {bool deleteFile = false}) async {
    await cancelDownload(id);
    final file = _entities[id];
    if (deleteFile && file != null) {
      await _tryDeleteWrittenFile(file);
    }
    _entities.remove(id);
    tracker.removeDownload(id);
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
      final decodedName = DownloadPathResolver.decodeUrlEncodedFileName(file.fileName);
      final doc = await safStorage.findChild(dirUri, decodedName);
      if (doc != null) await safStorage.deleteFile(doc.uri);
    } catch (_) {
      // Best-effort.
    }
  }

  /// Guards against a second `_run` for the same download starting while a
  /// previous one — including its copy/extract phase, which `cancelDownload`
  /// doesn't interrupt — is still finishing. Without this, a fast
  /// cancel-then-retry could reopen (and truncate) the same local cache file
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
    } finally {
      semaphore.release();
      await _syncForegroundService();
    }
  }

  Future<void> _performTorrentDownload(DownloadableFileWithTags file) async {
    final done = Completer<void>();
    _torrentDone[file.id] = done;
    try {
      await torrentPlugin.startFileDownload(
        magnet: file.downloadUrl,
        fileIndex: file.torrentFileIndex!,
        fileName: file.fileName,
        downloadId: file.id.toString(),
      );
    } catch (e) {
      tracker.updateDownloadStatus(file.id, DownloadStatus.failed);
      _torrentDone.remove(file.id);
      return;
    }

    await done.future;
    _torrentDone.remove(file.id);

    if (tracker.get(file.id)?.status != DownloadStatus.completed) return;

    try {
      final settingsState = settings.current;
      final destDirUri = await _resolveDestDirUri(file, settingsState);
      if (destDirUri.isEmpty) throw StateError('Download directory not configured.');
      final subPath = await _resolveSubPath(file, settingsState);
      final shouldExtract = ArchiveExtensions.isExtractable(file.fileExtension) && settingsState.autoUnzip;

      tracker.updateDownloadStatus(file.id, shouldExtract ? DownloadStatus.unzipping : DownloadStatus.copying);
      await torrentPlugin.finishFileDownload(
        magnet: file.downloadUrl,
        fileName: file.fileName,
        downloadId: file.id.toString(),
        destDirUri: destDirUri,
        subPath: subPath,
        extract: shouldExtract,
      );
      tracker.updateDownloadStatus(file.id, DownloadStatus.completed);
    } catch (e) {
      tracker.updateDownloadStatus(file.id, DownloadStatus.failed);
    }
  }

  Future<void> _performHttpDownload(DownloadableFileWithTags file) async {
    final cancelToken = CancelToken();
    _cancelTokens[file.id] = cancelToken;

    final localDir = _httpDownloadsDir ?? Directory('${(await getTemporaryDirectory()).path}/http_downloads');
    await localDir.create(recursive: true);
    final localFile = File('${localDir.path}/${file.id}_${file.fileName}');

    try {
      Object? lastError;
      for (var attempt = 0; attempt < 3; attempt++) {
        if (cancelToken.isCancelled) break;
        try {
          if (attempt > 0) await Future.delayed(Duration(seconds: 2 * attempt));
          await _downloadAttempt(file, localFile, cancelToken);
          lastError = null;
          break;
        } catch (e) {
          if (e is DioException && CancelToken.isCancel(e)) rethrow;
          lastError = e;
        }
      }
      if (lastError != null) throw lastError;
      if (cancelToken.isCancelled) {
        if (await localFile.exists()) await localFile.delete();
        return;
      }

      await _handlePostDownload(file, localFile);
    } catch (e) {
      if (await localFile.exists()) await localFile.delete();
      final isCancel = e is DioException && CancelToken.isCancel(e);
      tracker.updateDownloadStatus(file.id, isCancel ? DownloadStatus.stopped : DownloadStatus.failed);
    } finally {
      _cancelTokens.remove(file.id);
    }
  }

  /// Resumes from wherever the previous attempt left off instead of always
  /// restarting from byte 0 — each retry used to reopen [localFile] with the
  /// truncating default `openWrite()`, discarding whatever a prior attempt
  /// had already downloaded even though the file was deliberately kept on
  /// disk between retries.
  Future<void> _downloadAttempt(DownloadableFileWithTags file, File localFile, CancelToken cancelToken) async {
    final existingBytes = await localFile.exists() ? await localFile.length() : 0;

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
    final sink = localFile.openWrite(mode: isResuming ? FileMode.append : FileMode.write);
    var downloaded = isResuming ? existingBytes : 0;
    var bytesSinceCheck = 0;
    var lastSpeedCheck = DateTime.now();
    var lastUpdate = DateTime.now();
    var lastDownloaded = downloaded;
    final speedLimit = (settings.current).limitSpeedMbs;

    try {
      await for (final chunk in response.data!.stream) {
        if (cancelToken.isCancelled) break;
        sink.add(chunk);
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
          lastUpdate = now;
          lastDownloaded = downloaded;
        }
      }
    } finally {
      await sink.close();
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

  Future<void> _handlePostDownload(DownloadableFileWithTags file, File localFile) async {
    final settingsState = settings.current;
    final destDirUri = await _resolveDestDirUri(file, settingsState);
    if (destDirUri.isEmpty) throw StateError('Download directory not configured.');
    final subPath = await _resolveSubPath(file, settingsState);
    final shouldExtract = ArchiveExtensions.isExtractable(file.fileExtension) && settingsState.autoUnzip;

    if (shouldExtract) {
      tracker.updateDownloadStatus(file.id, DownloadStatus.unzipping);
      await torrentPlugin.extractArchive(archivePath: localFile.path, destDirUri: destDirUri, subPath: subPath);
    } else {
      tracker.updateDownloadStatus(file.id, DownloadStatus.copying);
      final destDir = await safStorage.ensureDirectory(destDirUri, subPath);
      final decodedName = DownloadPathResolver.decodeUrlEncodedFileName(file.fileName);
      await _safStream.pasteLocalFile(localFile.path, destDir, decodedName, 'application/octet-stream', overwrite: true);
    }

    if (await localFile.exists()) await localFile.delete();
    tracker.updateDownloadStatus(file.id, DownloadStatus.completed);
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
