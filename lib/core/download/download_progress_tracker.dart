import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'download_item.dart';
import 'download_status.dart';

part 'download_progress_tracker.g.dart';

/// Port of Milou's `DownloadProgressTracker` — a `List<DownloadItem>` state
/// notifier the Downloads screen watches directly. Keyed by [DownloadItem.id]
/// (not [DownloadItem.fileName], which isn't guaranteed unique across sources).
@Riverpod(keepAlive: true)
class DownloadProgressTrackerNotifier extends _$DownloadProgressTrackerNotifier {
  @override
  List<DownloadItem> build() => [];

  void addDownload(DownloadItem item) {
    if (state.any((d) => d.id == item.id)) return;
    state = [...state, item];
  }

  void updateDownloadProgress(int id, double progress, double speedMBs, int downloadedBytes) {
    state = [
      for (final item in state)
        if (item.id == id)
          item.copyWith(progress: progress, downloadSpeed: speedMBs, downloadedBytes: downloadedBytes)
        else
          item,
    ];
  }

  void updateDownloadStatus(int id, DownloadStatus status) {
    state = [
      for (final item in state)
        if (item.id == id) item.copyWith(status: status) else item,
    ];
  }

  void removeDownload(int id) {
    state = state.where((d) => d.id != id).toList();
  }

  bool canRetryDownload(int id) {
    final item = state.where((d) => d.id == id).firstOrNull;
    return item != null && (item.status == DownloadStatus.failed || item.status == DownloadStatus.stopped);
  }

  void resetDownloadForRetry(int id) {
    state = [
      for (final item in state)
        if (item.id == id)
          item.copyWith(progress: 0, downloadSpeed: 0, downloadedBytes: 0, status: DownloadStatus.downloading)
        else
          item,
    ];
  }

  bool get hasActiveDownloads => state.any(
        (d) => d.status == DownloadStatus.downloading ||
            d.status == DownloadStatus.copying ||
            d.status == DownloadStatus.unzipping,
      );

  DownloadItem? get(int id) => state.where((d) => d.id == id).firstOrNull;
}
