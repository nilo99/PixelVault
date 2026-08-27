import 'package:flutter/services.dart';

enum TorrentDownloadStatus { downloading, completed, failed }

class TorrentFileEntry {
  const TorrentFileEntry({required this.fileName, required this.fileIndex, required this.fileSize});

  factory TorrentFileEntry.fromMap(Map<dynamic, dynamic> map) {
    return TorrentFileEntry(
      fileName: map['fileName'] as String,
      fileIndex: map['fileIndex'] as int,
      fileSize: (map['fileSize'] as num).toInt(),
    );
  }

  final String fileName;
  final int fileIndex;
  final int fileSize;
}

class TorrentMetadata {
  const TorrentMetadata({required this.infoHash, required this.files});

  factory TorrentMetadata.fromMap(Map<dynamic, dynamic> map) {
    return TorrentMetadata(
      infoHash: map['infoHash'] as String,
      files: (map['files'] as List)
          .map((e) => TorrentFileEntry.fromMap(e as Map<dynamic, dynamic>))
          .toList(),
    );
  }

  final String infoHash;
  final List<TorrentFileEntry> files;
}

class TorrentProgressEvent {
  const TorrentProgressEvent({
    required this.downloadId,
    required this.fileName,
    required this.progress,
    required this.speedMBs,
    required this.downloadedBytes,
    required this.status,
  });

  factory TorrentProgressEvent.fromMap(Map<dynamic, dynamic> map) {
    return TorrentProgressEvent(
      downloadId: map['downloadId'] as String,
      fileName: map['fileName'] as String,
      progress: (map['progress'] as num).toDouble(),
      speedMBs: (map['speedMBs'] as num).toDouble(),
      downloadedBytes: (map['downloadedBytes'] as num).toInt(),
      status: TorrentDownloadStatus.values.byName((map['status'] as String).toLowerCase()),
    );
  }

  /// Unique per-download identifier (the app's DB row id, as a string) —
  /// distinct from [fileName], which is not guaranteed unique across sources.
  final String downloadId;
  final String fileName;
  final double progress;
  final double speedMBs;
  final int downloadedBytes;
  final TorrentDownloadStatus status;
}

/// Dart-facing API for the `pixelvault_torrent` native (Android-only) plugin
/// — wraps libtorrent4j (torrent metadata fetch + selective file download)
/// and 7-Zip-JBinding (archive extraction) behind a MethodChannel, with a
/// single shared EventChannel progress stream for every in-flight download.
class PixelvaultTorrent {
  PixelvaultTorrent._();
  static final PixelvaultTorrent instance = PixelvaultTorrent._();

  static const _methods = MethodChannel('pixelvault_torrent/methods');
  static const _progress = EventChannel('pixelvault_torrent/progress');

  Stream<TorrentProgressEvent>? _progressStream;

  Stream<TorrentProgressEvent> get progressStream {
    return _progressStream ??= _progress
        .receiveBroadcastStream()
        .map((event) => TorrentProgressEvent.fromMap(event as Map<dynamic, dynamic>));
  }

  Future<void> startSession() => _methods.invokeMethod('startSession');

  Future<void> stopSession() => _methods.invokeMethod('stopSession');

  Future<TorrentMetadata> fetchMetadata(String magnet, {List<String>? folders}) async {
    final result = await _methods.invokeMethod<Map<dynamic, dynamic>>('fetchMetadata', {
      'magnet': magnet,
      'folders': folders,
    });
    return TorrentMetadata.fromMap(result!);
  }

  /// [downloadId] is the app's unique DB row id (as a string) for this
  /// download — [fileName] alone isn't guaranteed unique across sources, so
  /// native-side tracking is keyed by [downloadId] instead.
  Future<void> startFileDownload({
    required String magnet,
    required int fileIndex,
    required String fileName,
    required String downloadId,
  }) {
    return _methods.invokeMethod('startFileDownload', {
      'magnet': magnet,
      'fileIndex': fileIndex,
      'fileName': fileName,
      'downloadId': downloadId,
    });
  }

  Future<void> cancelFileDownload({required String magnet, required String downloadId}) {
    return _methods.invokeMethod('cancelFileDownload', {
      'magnet': magnet,
      'downloadId': downloadId,
    });
  }

  /// Moves the completed torrent download from the native cache into
  /// [destDirUri]/[subPath]. If [extract] is true, extracts it there instead
  /// (any format 7-Zip-JBinding supports, auto-detected) and returns every
  /// extracted entry's name; otherwise returns a single-element list with
  /// [fileName] unchanged.
  Future<List<String>> finishFileDownload({
    required String magnet,
    required String fileName,
    required String downloadId,
    required String destDirUri,
    String subPath = '',
    bool extract = false,
  }) async {
    final result = await _methods.invokeMethod<List<dynamic>>('finishFileDownload', {
      'magnet': magnet,
      'fileName': fileName,
      'downloadId': downloadId,
      'destDirUri': destDirUri,
      'subPath': subPath,
      'extract': extract,
    });
    return result!.cast<String>();
  }

  /// Extracts a local archive file (any format 7-Zip-JBinding supports —
  /// zip/7z/rar/tar/etc, auto-detected) into [destDirUri]/[subPath].
  Future<List<String>> extractArchive({
    required String archivePath,
    required String destDirUri,
    String subPath = '',
  }) async {
    final result = await _methods.invokeMethod<List<dynamic>>('extractArchive', {
      'archivePath': archivePath,
      'destDirUri': destDirUri,
      'subPath': subPath,
    });
    return result!.cast<String>();
  }
}
