import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixelvault/core/db/daos/download_repository.dart';
import 'package:pixelvault/core/db/daos/downloadable_file_repository.dart';
import 'package:pixelvault/core/db/database.dart';
import 'package:pixelvault/core/download/download_status.dart';
import 'package:pixelvault/core/models/downloadable_file.dart';

/// Upgrading an existing install is the riskiest part of any schema change:
/// a broken migration would lose a user's whole catalog, not just their
/// download history. These build genuine on-disk databases at an older
/// version (a current one with the newer parts removed and the version stamp
/// wound back), reopen them through `AppDatabase`, and check both that the
/// migration runs and that nothing that was already there is disturbed.
void main() {
  late Directory tempDir;
  late File dbFile;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('pv_migration_');
    dbFile = File('${tempDir.path}/pixelvault.sqlite');
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  /// Removes what v4 added, so the file looks like a v3 install.
  Future<void> removeGroupKey(AppDatabase db) async {
    await db.customStatement('DROP INDEX IF EXISTS idx_downloadable_files_console_group');
    await db.customStatement('ALTER TABLE downloadable_files DROP COLUMN group_key');
  }

  Future<void> buildV2DatabaseWithData() async {
    final db = AppDatabase(NativeDatabase(dbFile));

    await db.into(db.manufacturers).insert(
          ManufacturersCompanion.insert(id: 'sony', name: 'Sony'),
        );
    await db.into(db.consoles).insert(ConsolesCompanion.insert(
          id: 'ps1',
          name: 'PlayStation',
          manufacturerId: 'sony',
          urlsJson: '[]',
        ));
    await db.into(db.downloadableFiles).insert(DownloadableFilesCompanion.insert(
          // What an older build stored: the extension still in the name.
          name: 'Legacy Game .chd',
          fileName: 'Legacy Game (USA).chd',
          consoleId: 'ps1',
          downloadUrl: 'https://example.com/legacy.chd',
          fileSize: const Value(42),
          fileExtension: const Value('.chd'),
        ));

    // Wind the file back to what a v2 install looks like.
    await removeGroupKey(db);
    await db.customStatement('DROP TABLE downloads');
    await db.customStatement('PRAGMA user_version = 2');
    await db.close();
  }

  /// A v3 install's catalog, as an older build scraped it.
  Future<void> buildV3DatabaseWithCatalog(List<(String name, String fileName)> files) async {
    final db = AppDatabase(NativeDatabase(dbFile));
    await db.into(db.manufacturers).insert(
          ManufacturersCompanion.insert(id: 'sony', name: 'Sony'),
        );
    await db.into(db.consoles).insert(ConsolesCompanion.insert(
          id: 'sony_playstation_2',
          name: 'PlayStation 2',
          manufacturerId: 'sony',
          urlsJson: '[]',
        ));
    for (final (name, fileName) in files) {
      await db.into(db.downloadableFiles).insert(DownloadableFilesCompanion.insert(
            name: name,
            fileName: fileName,
            consoleId: 'sony_playstation_2',
            downloadUrl: 'https://example.com/$fileName',
            fileExtension: Value('.${fileName.split('.').last}'),
          ));
    }
    await removeGroupKey(db);
    await db.customStatement('PRAGMA user_version = 3');
    await db.close();
  }

  test('upgrading from v2 creates the downloads table and keeps existing data', () async {
    await buildV2DatabaseWithData();

    final db = AppDatabase(NativeDatabase(dbFile));
    addTearDown(db.close);

    // Opening runs the migration.
    final version = await db.customSelect('PRAGMA user_version').getSingle();
    expect(version.data.values.first, 4);

    // The catalog survived — with its title cleaned up by the v4 step.
    final files = await db.select(db.downloadableFiles).get();
    expect(files, hasLength(1));
    expect(files.single.name, 'Legacy Game');
    expect(files.single.fileName, 'Legacy Game (USA).chd');
    expect(files.single.groupKey, 'legacy game');
    expect(await db.select(db.consoles).get(), hasLength(1));
    expect(await db.select(db.manufacturers).get(), hasLength(1));

    // And the new table is usable.
    final repo = DownloadRepository(db);
    final record = await repo.create(const DownloadableFileWithTags(
      id: 1,
      name: 'Legacy Game',
      fileName: 'legacy.chd',
      consoleId: 'ps1',
      downloadUrl: 'https://example.com/legacy.chd',
      fileSize: 42,
      fileExtension: '.chd',
    ));
    expect(record.id, greaterThan(0));
    expect(await repo.getAll(), hasLength(1));
  });

  test('upgrading from v3 regroups the existing catalog by game, without a rescan', () async {
    await buildV3DatabaseWithCatalog([
      ('God of War .iso', 'God of War (USA).iso'),
      ('God of War .7z', 'God of War (Europe).7z'),
      ('God of War .chd', 'God of War (Japan).chd'),
      ('God of War II .iso', 'God of War II (USA).iso'),
    ]);

    final db = AppDatabase(NativeDatabase(dbFile));
    addTearDown(db.close);

    final version = await db.customSelect('PRAGMA user_version').getSingle();
    expect(version.data.values.first, 4);

    final groups = await DownloadableFileRepository(db).queryGroupedFiles(
      query: 'god of war',
      consoleIds: ['sony_playstation_2'],
    );
    expect(groups.map((g) => g.title), ['God of War', 'God of War II']);
    expect(groups.first.variants, hasLength(3));
  });

  test('the migrated database still enforces cascade deletes', () async {
    await buildV2DatabaseWithData();

    final db = AppDatabase(NativeDatabase(dbFile));
    addTearDown(db.close);

    // `beforeOpen` must still switch foreign keys on after the upgrade,
    // otherwise deleting a console silently orphans its files.
    await (db.delete(db.consoles)..where((c) => c.id.equals('ps1'))).go();
    expect(await db.select(db.downloadableFiles).get(), isEmpty);
  });

  test('a download row outlives the catalog row it came from', () async {
    await buildV2DatabaseWithData();

    final db = AppDatabase(NativeDatabase(dbFile));
    addTearDown(db.close);
    final repo = DownloadRepository(db);

    final record = await repo.create(const DownloadableFileWithTags(
      id: 1,
      name: 'Legacy Game',
      fileName: 'legacy.chd',
      consoleId: 'ps1',
      downloadUrl: 'https://example.com/legacy.chd',
      fileSize: 42,
      fileExtension: '.chd',
    ));
    await repo.update(record.copyWith(status: DownloadStatus.completed));

    // A rescan wipes and repopulates the catalog. History must not go with
    // it — that is precisely why `downloads` has no foreign key.
    await db.delete(db.downloadableFiles).go();

    final history = await repo.getAll();
    expect(history, hasLength(1));
    expect(history.single.name, 'Legacy Game');
    expect(history.single.status, DownloadStatus.completed);
  });
}
