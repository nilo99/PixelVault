import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixelvault/core/db/daos/catalog_repository.dart';
import 'package:pixelvault/core/db/daos/downloadable_file_repository.dart';
import 'package:pixelvault/core/db/database.dart';
import 'package:pixelvault/core/db/seed/consoles_seed_loader.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late CatalogRepository catalog;
  late DownloadableFileRepository files;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    catalog = CatalogRepository(db);
    files = DownloadableFileRepository(db);
  });

  tearDown(() => db.close());

  test('seeds manufacturers and consoles from consoles.json', () async {
    await ConsolesSeedLoader(catalog).loadDefaultSources();

    final manufacturers = await catalog.watchManufacturers().first;
    final consoles = await catalog.watchAllConsoles().first;

    expect(manufacturers, isNotEmpty);
    expect(consoles, isNotEmpty);
    expect(consoles.first.id, contains('_'));
  });

  test('insert/query round trip with tags', () async {
    await catalog.upsertManufacturer(
      ManufacturersCompanion.insert(id: 'nintendo', name: 'Nintendo'),
    );
    await catalog.upsertConsole(
      ConsolesCompanion.insert(
        id: 'nintendo_gba',
        name: 'GBA',
        manufacturerId: 'nintendo',
        urlsJson: '[]',
      ),
    );

    await files.insertFilesWithTags(
      [
        DownloadableFilesCompanion.insert(
          name: 'Pokemon Emerald',
          fileName: 'Pokemon Emerald (USA).zip',
          consoleId: 'nintendo_gba',
          downloadUrl: 'https://example.com/Pokemon%20Emerald.zip',
          fileSize: const Value(12345),
          fileExtension: const Value('.zip'),
        ),
      ],
      [
        ['USA', 'GAME'],
      ],
    );

    final count = await files.getFilesCount();
    expect(count, 1);

    final results = await files.queryFilesWithTags(query: '*');
    expect(results, hasLength(1));
    expect(results.first.name, 'Pokemon Emerald');
    expect(results.first.tagList, containsAll(['USA', 'GAME']));

    final byTag = await files.queryFilesWithTags(query: '*', tags: ['USA']);
    expect(byTag, hasLength(1));

    final byMissingTag = await files.queryFilesWithTags(query: '*', tags: ['EUROPE']);
    expect(byMissingTag, isEmpty);

    final consolesWithFiles = await files.getConsolesWithFiles(query: '*');
    expect(consolesWithFiles, hasLength(1));
    expect(consolesWithFiles.first.fileCount, 1);

    final tags = await files.getAvailableTags(query: '*');
    expect(tags, containsAll(['USA', 'GAME']));
  });

  test('deleting a console cascades to its files and tags', () async {
    await catalog.upsertManufacturer(
      ManufacturersCompanion.insert(id: 'sony', name: 'Sony'),
    );
    await catalog.upsertConsole(
      ConsolesCompanion.insert(
        id: 'sony_psp',
        name: 'PSP',
        manufacturerId: 'sony',
        urlsJson: '[]',
      ),
    );
    await files.insertFilesWithTags(
      [
        DownloadableFilesCompanion.insert(
          name: 'Test Game',
          fileName: 'Test Game.iso',
          consoleId: 'sony_psp',
          downloadUrl: 'https://example.com/test.iso',
        ),
      ],
      [
        ['Europe'],
      ],
    );

    await files.deleteFilesByConsoleId('sony_psp');
    expect(await files.getFilesCount(), 0);
  });
}
