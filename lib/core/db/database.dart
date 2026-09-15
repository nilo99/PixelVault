import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:sqlite3/common.dart' show CommonDatabase;

import '../scraping/rom_title.dart';
import 'tables/tables.dart';

part 'database.g.dart';

@DriftDatabase(tables: [Manufacturers, Consoles, DownloadableFiles, FileTags, Downloads])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _createConsoleIdIndex();
          await _createDownloadsIndexes();
          await _createGroupIndex();
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
          // v3 -> v4: the Library groups files by game. Rows scraped before
          // this kept the extension in `name` ("God of War .7z"), so each
          // format of a game formed its own group. Their title and group key
          // are recomputed here rather than waiting for the user to rescan.
          if (from < 4) {
            await m.addColumn(downloadableFiles, downloadableFiles.groupKey);
            await _backfillTitles();
            await _createGroupIndex();
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

  /// Search groups rows by console and game, then fetches each group's files
  /// by that same pair.
  Future<void> _createGroupIndex() {
    return customStatement(
      'CREATE INDEX IF NOT EXISTS idx_downloadable_files_console_group '
      'ON downloadable_files (console_id, group_key)',
    );
  }

  /// Recomputes every catalog row's title and group key with [RomTitle].
  Future<void> _backfillTitles() async {
    final rows = await customSelect('SELECT id, name, file_name FROM downloadable_files').get();
    if (rows.isEmpty) return;
    await batch((b) {
      for (final row in rows) {
        final title = RomTitle.forCatalog(
          fileName: row.read<String>('file_name'),
          displayName: row.read<String>('name'),
        );
        final name = title.isNotEmpty ? title : row.read<String>('name');
        b.customStatement(
          'UPDATE downloadable_files SET name = ?, group_key = ? WHERE id = ?',
          [name, RomTitle.key(name), row.read<int>('id')],
        );
      }
    });
  }

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'pixelvault',
      native: const DriftNativeOptions(
        // One database isolate per *process*, found through
        // IsolateNameServer, instead of one per Flutter engine. This app can
        // host several engines at once — the foreground download service
        // starts its own — and a second engine used to open a second
        // connection to the same file. Writes from the two collided, which
        // is how a relaunched app ended up unable to save anything and
        // showing no history until it was force-stopped.
        shareAcrossIsolates: true,
        setup: _configureConnection,
      ),
    );
  }

  /// Runs on the raw connection inside the database isolate, so it has to be
  /// a static function rather than a closure.
  ///
  /// WAL lets reads carry on while a download's progress is being written,
  /// and the busy timeout makes a connection wait briefly for a lock instead
  /// of failing the write on the spot.
  static void _configureConnection(CommonDatabase db) {
    db.execute('PRAGMA journal_mode = WAL;');
    db.execute('PRAGMA busy_timeout = 5000;');
  }
}
