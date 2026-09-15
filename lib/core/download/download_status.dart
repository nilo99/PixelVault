/// Mirrors Milou's `DownloadStatus` enum, plus [cancelled].
///
/// Stored in the database by name, so appending a value never renumbers
/// existing rows.
enum DownloadStatus {
  downloading,
  copying,
  unzipping,
  completed,
  failed,

  /// Interrupted — the process died mid-transfer — and resumable. Still part
  /// of the queue, not the history.
  stopped,

  /// The user stopped it. Its partial output is discarded and it moves to
  /// the history, where it stays until the user deletes it.
  cancelled,
}
