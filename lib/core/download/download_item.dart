import 'download_status.dart';

/// Mirrors Milou's `DownloadItemModel` — runtime/in-progress download state,
/// separate from the persisted [DownloadableFileWithTags] catalog entry.
class DownloadItem {
  const DownloadItem({
    required this.id,
    required this.name,
    required this.fileName,
    this.downloadSpeed = 0,
    this.progress = 0,
    this.status = DownloadStatus.downloading,
    this.downloadedBytes = 0,
    required this.fileSize,
    this.isTorrent = false,
  });

  /// The catalog's unique DB row id — identity for this download, since
  /// [fileName] alone isn't guaranteed unique across sources (region
  /// variants routinely share a file name).
  final int id;
  final String name;
  final String fileName;
  final double downloadSpeed;
  final double progress;
  final DownloadStatus status;
  final int downloadedBytes;
  final int fileSize;
  final bool isTorrent;

  DownloadItem copyWith({
    double? downloadSpeed,
    double? progress,
    DownloadStatus? status,
    int? downloadedBytes,
  }) {
    return DownloadItem(
      id: id,
      name: name,
      fileName: fileName,
      downloadSpeed: downloadSpeed ?? this.downloadSpeed,
      progress: progress ?? this.progress,
      status: status ?? this.status,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      fileSize: fileSize,
      isTorrent: isTorrent,
    );
  }
}
