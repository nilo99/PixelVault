import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'download_failure.dart';
import 'download_item.dart';
import 'download_status.dart';

part 'download_progress_tracker.g.dart';

/// Port of Milou's `DownloadProgressTracker` — a `List<DownloadItem>` state
/// notifier the Downloads screen watches directly. Keyed by
/// [DownloadItem.id], the download attempt's row id.
///
/// This is the in-memory view; `DownloadManager` mirrors every change it
/// makes here into the `downloads` table, and folds that table back in
/// through [mergeRestored] on startup so the queue and history survive a
/// restart.
@Riverpod(keepAlive: true)
class DownloadProgressTrackerNotifier extends _$DownloadProgressTrackerNotifier {
  @override
  List<DownloadItem> build() => [];

  void addDownload(DownloadItem item) {
    if (state.any((d) => d.id == item.id)) return;
    state = [...state, item];
  }

  /// Adds [item], or replaces the existing entry with the same id.
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

  /// Replaces the whole list.
  void replaceAll(List<DownloadItem> items) {
    state = List.unmodifiable(items);
  }

  /// Folds attempts restored from the database into what is already in
  /// memory, rather than replacing it. A download the user started while the
  /// restore was still reading keeps its live state; only ids the tracker
  /// does not know yet are added. [restored] arrives newest first and is
  /// placed before the live entries, oldest first, matching append order.
  void mergeRestored(List<DownloadItem> restored) {
    final known = {for (final d in state) d.id};
    final missing = restored.where((d) => !known.contains(d.id)).toList().reversed;
    state = [...missing, ...state];
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
        // Cancelled is final. A worker still unwinding after the user
        // cancelled — a copy or an extraction that was already under way —
        // must not turn the attempt back into copying, unzipping or completed.
        if (item.id == id && !(item.status == DownloadStatus.cancelled && status != DownloadStatus.cancelled))
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

  void removeMany(Set<int> ids) {
    state = state.where((d) => !ids.contains(d.id)).toList();
  }

  /// Drops every finished, failed or cancelled entry, keeping the queue.
  void removeTerminal() {
    state = state.where((d) => !d.isTerminal).toList();
  }

  List<DownloadItem> get terminalItems => state.where((d) => d.isTerminal).toList();

  /// The unfinished attempt — running or interrupted — at [downloadUrl], if
  /// there is one. Two of those would write to the same destination file.
  DownloadItem? queuedFor(String downloadUrl) {
    if (downloadUrl.isEmpty) return null;
    return state.where((d) => !d.isTerminal && d.downloadUrl == downloadUrl).firstOrNull;
  }

  bool canRetryDownload(int id) {
    final item = get(id);
    return item != null &&
        (item.status == DownloadStatus.failed ||
            item.status == DownloadStatus.stopped ||
            item.status == DownloadStatus.cancelled);
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
