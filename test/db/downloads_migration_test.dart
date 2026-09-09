import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixelvault/core/db/daos/download_repository.dart';
import 'package:pixelvault/core/db/database.dart';
import 'package:pixelvault/core/download/download_status.dart';
import 'package:pixelvault/core/models/downloadable_file.dart';

/// Upgrading an existing install is the riskiest part of adding the
/// `downloads` table: a broken migration would lose a user's whole catalog,
/// not just their download history. This builds a genuine on-disk v2
/// database (a v3 one with the new table dropped and the version stamp wound
/// back), reopens it through `AppDatabase`, and checks both that the
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
          name: 'Legacy Game',
          fileName: 'legacy.chd',
          consoleId: 'ps1',
          downloadUrl: 'https://example.com/legacy.chd',
          fileSize: const Value(42),
          fileExtension: const Value('.chd'),
        ));

    // Wind the file back to what a v2 install looks like.
    await db.customStatement('DROP TABLE downloads');
    await db.customStatement('PRAGMA user_version = 2');
    await db.close();
  }

  test('upgrading from v2 creates the downloads table and keeps existing data', () async {
    await buildV2DatabaseWithData();

    final db = AppDatabase(NativeDatabase(dbFile));
    addTearDown(db.close);

    // Opening runs the migration.
    final version = await db.customSelect('PRAGMA user_version').getSingle();
    expect(version.data.values.first, 3);

    // The catalog survived untouched.
    final files = await db.select(db.downloadableFiles).get();
    expect(files, hasLength(1));
    expect(files.single.name, 'Legacy Game');
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
    expect(record.recordId, isNotNull);
    expect(await repo.getAll(), hasLength(1));
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
