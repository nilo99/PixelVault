import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables/tables.dart';

part 'database.g.dart';

@DriftDatabase(tables: [Manufacturers, Consoles, DownloadableFiles, FileTags, Downloads])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _createConsoleIdIndex();
          await _createDownloadsIndexes();
        },
        onUpgrade: (m, from, to) async {
          // v1 -> v2: DownloadableFiles.consoleId is a foreign key used in
          // every join/filter/watch in the Library — SQLite doesn't index
          // FKs automatically, so every search/count was a full table scan.
          if (from < 2) {
            await _createConsoleIdIndex();
          }
          // v2 -> v3: downloads became persistent (queue, progress, history
          // and destination) instead of living only in memory.
          if (from < 3) {
            await m.createTable(downloads);
            await _createDownloadsIndexes();
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  Future<void> _createConsoleIdIndex() {
    return customStatement(
      'CREATE INDEX IF NOT EXISTS idx_downloadable_files_console_id ON downloadable_files (console_id)',
    );
  }

  /// The Downloads screen reads "everything, newest first" and the manager
  /// looks rows up by their catalog id on restore — both are hot paths on
  /// every app start.
  Future<void> _createDownloadsIndexes() async {
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_downloads_created_at ON downloads (created_at DESC)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_downloads_catalog_file_id ON downloads (catalog_file_id)',
    );
  }

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'pixelvault');
  }
}
