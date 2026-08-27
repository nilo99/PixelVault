import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables/tables.dart';

part 'database.g.dart';

@DriftDatabase(tables: [Manufacturers, Consoles, DownloadableFiles, FileTags])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _createConsoleIdIndex();
        },
        onUpgrade: (m, from, to) async {
          // v1 -> v2: DownloadableFiles.consoleId is a foreign key used in
          // every join/filter/watch in the Library — SQLite doesn't index
          // FKs automatically, so every search/count was a full table scan.
          if (from < 2) {
            await _createConsoleIdIndex();
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

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'pixelvault');
  }
}
