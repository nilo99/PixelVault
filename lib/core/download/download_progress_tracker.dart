import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'download_failure.dart';
import 'download_item.dart';
import 'download_status.dart';

part 'download_progress_tracker.g.dart';

/// Port of Milou's `DownloadProgressTracker` — a `List<DownloadItem>` state
/// notifier the Downloads screen watches directly. Keyed by [DownloadItem.id]
/// (not [DownloadItem.fileName], which isn't guaranteed unique across sources).
///
/// This is the in-memory view; `DownloadManager` mirrors every change it
/// makes here into the `downloads` table, and seeds it back through
/// [replaceAll] on startup so the queue and history survive a restart.
@Riverpod(keepAlive: true)
class DownloadProgressTrackerNotifier extends _$DownloadProgressTrackerNotifier {
  @override
  List<DownloadItem> build() => [];

  void addDownload(DownloadItem item) {
    if (state.any((d) => d.id == item.id)) return;
    state = [...state, item];
  }

  /// Adds [item], or replaces the existing entry with the same id — used
  /// when a download is (re)started and gets a fresh persisted record.
  void upsert(DownloadItem item) {
    final index = state.indexWhere((d) => d.id == item.id);
    if (index == -1) {
      state = [...state, item];
      return;
    }
    state = [
      for (var i = 0; i < state.length; i++) i == index ? item : state[i],
    ];
  }

  /// Replaces the whole list, newest first — the restore path.
  void replaceAll(List<DownloadItem> items) {
    state = List.unmodifiable(items);
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

  void updateDownloadStatus(
    int id,
    DownloadStatus status, {
    DownloadFailureReason? failureReason,
    String? destinationLabel,
    String? destinationUri,
    String? savedFileName,
    DateTime? completedAt,
  }) {
    state = [
      for (final item in state)
        if (item.id == id)
          item.copyWith(
            status: status,
            failureReason: failureReason,
            // Moving off `failed` must clear the stale reason, otherwise a
            // retried download keeps showing why its previous attempt died.
            clearFailureReason: status != DownloadStatus.failed && failureReason == null,
            destinationLabel: destinationLabel,
            destinationUri: destinationUri,
            savedFileName: savedFileName,
            completedAt: completedAt,
          )
        else
          item,
    ];
  }

  void removeDownload(int id) {
    state = state.where((d) => d.id != id).toList();
  }

  /// Drops every finished/failed entry, keeping anything still running.
  void removeTerminal() {
    state = state.where((d) => !d.isTerminal).toList();
  }

  List<DownloadItem> get terminalItems => state.where((d) => d.isTerminal).toList();

  bool canRetryDownload(int id) {
    final item = state.where((d) => d.id == id).firstOrNull;
    return item != null && (item.status == DownloadStatus.failed || item.status == DownloadStatus.stopped);
  }

  /// Puts a failed/stopped download back into the queue.
  ///
  /// [DownloadItem.progress] and [DownloadItem.downloadedBytes] are
  /// deliberately preserved: they are what tells the manager it may resume
  /// (rather than overwrite) and what stops the progress bar snapping back
  /// to 0% before jumping again a second later. Only the transient bits —
  /// speed, failure reason, completion time — are cleared.
  void resetDownloadForRetry(int id) {
    state = [
      for (final item in state)
        if (item.id == id)
          item.copyWith(
            downloadSpeed: 0,
            status: DownloadStatus.downloading,
            clearFailureReason: true,
            clearCompletedAt: true,
          )
        else
          item,
    ];
  }

  bool get hasActiveDownloads => state.any((d) => d.isActive);

  DownloadItem? get(int id) => state.where((d) => d.id == id).firstOrNull;
}
