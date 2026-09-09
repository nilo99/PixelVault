import 'download_failure.dart';
import 'download_status.dart';

/// Mirrors Milou's `DownloadItemModel` — runtime/in-progress download state,
/// separate from the persisted [DownloadableFileWithTags] catalog entry.
class DownloadItem {
  const DownloadItem({
    required this.id,
    this.recordId,
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

  /// The catalog's unique DB row id — identity for this download *while it
  /// runs*, since [fileName] alone isn't guaranteed unique across sources
  /// (region variants routinely share a file name). Not stable across a
  /// catalog rescan, which is why history is keyed by [recordId] instead.
  final int id;

  /// Primary key of this download's row in the `downloads` table, once it
  /// has one. `null` only for an item that has not been persisted yet.
  final int? recordId;

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

  bool get isTerminal =>
      status == DownloadStatus.completed || status == DownloadStatus.failed;

  bool get isActive =>
      status == DownloadStatus.downloading ||
      status == DownloadStatus.copying ||
      status == DownloadStatus.unzipping;

  DownloadItem copyWith({
    int? recordId,
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
      recordId: recordId ?? this.recordId,
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
