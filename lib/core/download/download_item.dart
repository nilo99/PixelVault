import 'download_failure.dart';
import 'download_status.dart';

/// Mirrors Milou's `DownloadItemModel` — the state of one download attempt,
/// separate from the catalog entry it was started from.
class DownloadItem {
  const DownloadItem({
    required this.id,
    this.catalogFileId = 0,
    this.consoleId = '',
    this.downloadUrl = '',
    required this.name,
    required this.fileName,
    this.downloadSpeed = 0,
    this.progress = 0,
    this.status = DownloadStatus.downloading,
    this.downloadedBytes = 0,
    required this.fileSize,
    this.isTorrent = false,
    this.destinationLabel = '',
    this.destinationUri = '',
    this.savedFileName = '',
    this.failureReason,
    this.createdAt,
    this.completedAt,
  });

  /// Primary key of this attempt's row in the `downloads` table, and the
  /// identity used by the download manager, the tracker and the native
  /// torrent plugin.
  ///
  /// Every attempt is its own row. It used to be keyed by the catalog file
  /// id instead, so a cancelled attempt and a fresh attempt at the same game
  /// shared one entry: one cancel token, one status, one history row.
  final int id;

  /// The `DownloadableFiles.id` this attempt was started from. Metadata only —
  /// SQLite reuses rowids after a catalog rescan, so it is not an identity.
  final int catalogFileId;

  final String consoleId;

  /// The source URL (or magnet). Two unfinished attempts at the same URL
  /// would write to the same destination file, so this is what the manager
  /// checks before starting one.
  final String downloadUrl;

  final String name;
  final String fileName;
  final double downloadSpeed;
  final double progress;
  final DownloadStatus status;
  final int downloadedBytes;
  final int fileSize;
  final bool isTorrent;

  /// Human-readable destination folder, shown in the Downloads screen.
  final String destinationLabel;

  /// SAF tree URI of the destination folder, for reopening it programmatically.
  final String destinationUri;

  /// Name actually written at the destination — differs from [fileName] when
  /// an archive was auto-extracted.
  final String savedFileName;

  final DownloadFailureReason? failureReason;
  final DateTime? createdAt;
  final DateTime? completedAt;

  /// Finished one way or another; lives in the history.
  bool get isTerminal =>
      status == DownloadStatus.completed ||
      status == DownloadStatus.failed ||
      status == DownloadStatus.cancelled;

  /// A worker is transferring, copying or extracting it right now.
  bool get isActive =>
      status == DownloadStatus.downloading ||
      status == DownloadStatus.copying ||
      status == DownloadStatus.unzipping;

  DownloadItem copyWith({
    double? downloadSpeed,
    double? progress,
    DownloadStatus? status,
    int? downloadedBytes,
    String? destinationLabel,
    String? destinationUri,
    String? savedFileName,
    DownloadFailureReason? failureReason,
    bool clearFailureReason = false,
    DateTime? completedAt,
    bool clearCompletedAt = false,
  }) {
    return DownloadItem(
      id: id,
      catalogFileId: catalogFileId,
      consoleId: consoleId,
      downloadUrl: downloadUrl,
      name: name,
      fileName: fileName,
      downloadSpeed: downloadSpeed ?? this.downloadSpeed,
      progress: progress ?? this.progress,
      status: status ?? this.status,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      fileSize: fileSize,
      isTorrent: isTorrent,
      destinationLabel: destinationLabel ?? this.destinationLabel,
      destinationUri: destinationUri ?? this.destinationUri,
      savedFileName: savedFileName ?? this.savedFileName,
      failureReason: clearFailureReason ? null : (failureReason ?? this.failureReason),
      createdAt: createdAt,
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
    );
  }
}
