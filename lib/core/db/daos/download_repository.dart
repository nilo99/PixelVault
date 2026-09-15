import 'package:drift/drift.dart';

import '../../download/download_failure.dart';
import '../../download/download_item.dart';
import '../../download/download_status.dart';
import '../../models/downloadable_file.dart';
import '../database.dart';

/// Persistence for the download queue and history (see the `Downloads` table
/// doc for why it is deliberately decoupled from the catalog).
///
/// One row per download *attempt*. The history is permanent: rows leave this
/// table only through [deleteMany] and [clearHistory], which the Downloads
/// screen calls when the user asks for it, and both refuse to touch an
/// attempt that is still running or queued.
class DownloadRepository {
  DownloadRepository(this.db);

  final AppDatabase db;

  static final _terminalNames = [
    DownloadStatus.completed.name,
    DownloadStatus.failed.name,
    DownloadStatus.cancelled.name,
  ];

  /// Live view of every attempt, newest first.
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

  /// Creates the row for a new attempt and returns it with its assigned id.
  Future<DownloadItem> create(DownloadableFileWithTags file, {String consoleName = ''}) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final row = await db.into(db.downloads).insertReturning(DownloadsCompanion.insert(
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
    return _toItem(row);
  }

  /// Writes the mutable parts of [item] back. Called on every status change
  /// and on throttled progress ticks, so it only touches columns that move.
  Future<void> update(DownloadItem item) async {
    await (db.update(db.downloads)..where((d) => d.id.equals(item.id))).write(
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

  Future<void> setStagingPath(int id, String path) {
    return (db.update(db.downloads)..where((d) => d.id.equals(id)))
        .write(DownloadsCompanion(stagingPath: Value(path)));
  }

  Future<String> stagingPathOf(int id) async {
    final row = await (db.select(db.downloads)..where((d) => d.id.equals(id))).getSingleOrNull();
    return row?.stagingPath ?? '';
  }

  /// Deletes the given history entries. An id that belongs to an attempt
  /// still running or queued is ignored, even if a caller passes it.
  Future<int> deleteMany(Set<int> ids) {
    if (ids.isEmpty) return Future.value(0);
    return (db.delete(db.downloads)
          ..where((d) => d.id.isIn(ids) & d.status.isIn(_terminalNames)))
        .go();
  }

  /// Deletes every finished, failed and cancelled row; the queue is untouched.
  Future<int> clearHistory() {
    return (db.delete(db.downloads)..where((d) => d.status.isIn(_terminalNames))).go();
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

  /// Rebuilds the catalog-shaped record a retry needs from the snapshot on
  /// the row itself, so retrying still works after a rescan has renumbered
  /// (or removed) the original catalog entry.
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

  Future<Download?> row(int id) {
    return (db.select(db.downloads)..where((d) => d.id.equals(id))).getSingleOrNull();
  }

  static DownloadItem _toItem(Download row) {
    return DownloadItem(
      id: row.id,
      catalogFileId: row.catalogFileId,
      consoleId: row.consoleId,
      downloadUrl: row.downloadUrl,
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
      failureReason: row.failureReason == null ? null : DownloadFailureReason.fromCode(row.failureReason),
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
      completedAt: row.completedAt == null ? null : DateTime.fromMillisecondsSinceEpoch(row.completedAt!),
    );
  }
}
