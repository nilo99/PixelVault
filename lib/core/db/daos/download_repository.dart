import 'package:drift/drift.dart';

import '../../download/download_failure.dart';
import '../../download/download_item.dart';
import '../../download/download_status.dart';
import '../../models/downloadable_file.dart';
import '../database.dart';

/// Persistence for the download queue and history (see the `Downloads` table
/// doc for why it is deliberately decoupled from the catalog).
///
/// Everything the Downloads screen shows now survives a process death: the
/// active queue with its progress, the completed history, and where each
/// file actually landed.
class DownloadRepository {
  DownloadRepository(this.db);

  final AppDatabase db;

  /// Live view of every download, newest first — what the Downloads screen
  /// watches. Includes finished and failed rows, which is the history.
  Stream<List<DownloadItem>> watchAll() {
    return (db.select(db.downloads)..orderBy([(d) => OrderingTerm.desc(d.createdAt)]))
        .watch()
        .map((rows) => rows.map(_toItem).toList());
  }

  Future<List<DownloadItem>> getAll() async {
    final rows = await (db.select(db.downloads)
          ..orderBy([(d) => OrderingTerm.desc(d.createdAt)]))
        .get();
    return rows.map(_toItem).toList();
  }

  /// Creates the row for a newly started download and returns it with its
  /// assigned [DownloadItem.recordId].
  Future<DownloadItem> create(DownloadableFileWithTags file, {String consoleName = ''}) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final id = await db.into(db.downloads).insertReturning(DownloadsCompanion.insert(
          catalogFileId: file.id,
          name: file.name,
          fileName: file.fileName,
          consoleId: file.consoleId,
          consoleName: Value(consoleName),
          downloadUrl: file.downloadUrl,
          fileSize: Value(file.fileSize),
          fileExtension: Value(file.fileExtension),
          torrentFileIndex: Value(file.torrentFileIndex),
          torrentMagnet: Value(file.torrentMagnet),
          status: DownloadStatus.downloading.name,
          createdAt: now,
          updatedAt: now,
        ));
    return _toItem(id);
  }

  /// Writes the mutable parts of [item] back. Called on every status change
  /// and on throttled progress ticks, so it only touches columns that move.
  Future<void> update(DownloadItem item) async {
    final recordId = item.recordId;
    if (recordId == null) return;
    await (db.update(db.downloads)..where((d) => d.id.equals(recordId))).write(
      DownloadsCompanion(
        status: Value(item.status.name),
        progress: Value(item.progress),
        downloadedBytes: Value(item.downloadedBytes),
        destinationUri: Value(item.destinationUri),
        destinationLabel: Value(item.destinationLabel),
        savedFileName: Value(item.savedFileName),
        failureReason: Value(item.failureReason?.code),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
        completedAt: Value(item.completedAt?.millisecondsSinceEpoch),
      ),
    );
  }

  Future<void> setStagingPath(int recordId, String path) {
    return (db.update(db.downloads)..where((d) => d.id.equals(recordId)))
        .write(DownloadsCompanion(stagingPath: Value(path)));
  }

  Future<String> stagingPathOf(int recordId) async {
    final row = await (db.select(db.downloads)..where((d) => d.id.equals(recordId)))
        .getSingleOrNull();
    return row?.stagingPath ?? '';
  }

  Future<void> delete(int recordId) {
    return (db.delete(db.downloads)..where((d) => d.id.equals(recordId))).go();
  }

  /// Clears finished/failed rows, leaving anything still running alone.
  Future<int> clearHistory() {
    return (db.delete(db.downloads)
          ..where((d) => d.status.isIn([
                DownloadStatus.completed.name,
                DownloadStatus.failed.name,
              ])))
        .go();
  }

  /// Marks rows that were mid-flight when the process died as `stopped`, so
  /// they come back as resumable queue entries rather than as downloads that
  /// appear to be running but have no worker behind them. Returns them.
  Future<List<DownloadItem>> reconcileInterrupted() async {
    const interrupted = [
      DownloadStatus.downloading,
      DownloadStatus.copying,
      DownloadStatus.unzipping,
    ];
    final names = interrupted.map((s) => s.name).toList();
    final rows = await (db.select(db.downloads)..where((d) => d.status.isIn(names))).get();
    if (rows.isEmpty) return const [];
    await (db.update(db.downloads)..where((d) => d.status.isIn(names))).write(
      DownloadsCompanion(
        status: Value(DownloadStatus.stopped.name),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
    return rows.map((r) => _toItem(r).copyWith(status: DownloadStatus.stopped)).toList();
  }

  /// Rebuilds the catalog-shaped record a retry needs, from the snapshot
  /// stored on the download row itself — so retrying a download still works
  /// after a rescan has renumbered (or removed) the original catalog entry.
  static DownloadableFileWithTags toCatalogFile(Download row) {
    return DownloadableFileWithTags(
      id: row.catalogFileId,
      name: row.name,
      fileName: row.fileName,
      consoleId: row.consoleId,
      downloadUrl: row.downloadUrl,
      fileSize: row.fileSize,
      fileExtension: row.fileExtension,
      torrentFileIndex: row.torrentFileIndex,
      torrentMagnet: row.torrentMagnet,
    );
  }

  Future<Download?> row(int recordId) {
    return (db.select(db.downloads)..where((d) => d.id.equals(recordId))).getSingleOrNull();
  }

  static DownloadItem _toItem(Download row) {
    return DownloadItem(
      id: row.catalogFileId,
      recordId: row.id,
      name: row.name,
      fileName: row.fileName,
      fileSize: row.fileSize,
      isTorrent: row.torrentFileIndex != null && row.torrentMagnet != null,
      status: DownloadStatus.values.firstWhere(
        (s) => s.name == row.status,
        orElse: () => DownloadStatus.failed,
      ),
      progress: row.progress,
      downloadedBytes: row.downloadedBytes,
      destinationUri: row.destinationUri,
      destinationLabel: row.destinationLabel,
      savedFileName: row.savedFileName,
      failureReason: row.failureReason == null
          ? null
          : DownloadFailureReason.fromCode(row.failureReason),
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
      completedAt: row.completedAt == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(row.completedAt!),
    );
  }
}
