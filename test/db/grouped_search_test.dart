import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:pixelvault/core/db/daos/downloadable_file_repository.dart';
import 'package:pixelvault/core/db/database.dart';
import 'package:pixelvault/core/scraping/http_directory_scraper.dart';

void main() {
  late AppDatabase db;
  late DownloadableFileRepository repo;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repo = DownloadableFileRepository(db);

    await db.into(db.manufacturers).insert(
          ManufacturersCompanion.insert(id: 'nintendo', name: 'Nintendo'),
        );
    await db.into(db.manufacturers).insert(
          ManufacturersCompanion.insert(id: 'sony', name: 'Sony'),
        );
    await db.into(db.consoles).insert(ConsolesCompanion.insert(
          id: 'n3ds',
          name: 'Nintendo 3DS',
          manufacturerId: 'nintendo',
          urlsJson: '[]',
        ));
    await db.into(db.consoles).insert(ConsolesCompanion.insert(
          id: 'sony_playstation_2',
          name: 'PlayStation 2',
          manufacturerId: 'sony',
          urlsJson: '[]',
        ));
    await db.into(db.consoles).insert(ConsolesCompanion.insert(
          id: 'sony_playstation_portable',
          name: 'PlayStation Portable',
          manufacturerId: 'sony',
          urlsJson: '[]',
        ));
  });

  tearDown(() => db.close());

  Future<void> seed(List<(String name, String fileName, int size)> rows) async {
    await repo.insertFilesWithTags(
      [
        for (final (name, fileName, size) in rows)
          DownloadableFilesCompanion.insert(
            name: name,
            fileName: fileName,
            consoleId: 'n3ds',
            downloadUrl: 'https://example.com/$fileName',
            fileSize: Value(size),
            fileExtension: Value(fileName.contains('.') ? '.${fileName.split('.').last}' : ''),
          ),
      ],
      [for (final _ in rows) const <String>[]],
    );
  }

  /// Scrapes a directory listing of [fileNames] into [consoleId] — the path a
  /// real source takes — so what gets grouped is what the scraper stores.
  Future<void> scrapeListing(String consoleId, List<String> fileNames) async {
    final rows = [
      for (final name in fileNames)
        '<tr><td class="link"><a href="${Uri.encodeComponent(name)}" title="$name">$name</a></td>'
            '<td class="size">1.0GB</td></tr>',
    ].join();
    final (companions, tags) = HttpDirectoryScraper.parseListing(
      doc: html_parser.parse('<html><body><table>$rows</table></body></html>'),
      baseUrl: 'https://example.com/$consoleId/',
      consoleId: consoleId,
    );
    await repo.insertFilesWithTags(companions, tags);
  }

  test('collapses every variant of a game into one result', () async {
    // Exactly the shape that made a search for "pokemon" unusable: one game,
    // many regions and formats, each previously its own top-level row.
    await seed([
      ('Pokemon Y', 'Pokemon Y (Europe).3ds', 100),
      ('Pokemon Y', 'Pokemon Y (USA).3ds', 110),
      ('Pokemon Y', 'Pokemon Y (Japan).cia', 90),
      ('Pokemon X', 'Pokemon X (Europe).3ds', 105),
    ]);

    final groups = await repo.queryGroupedFiles(query: 'pokemon');

    expect(groups, hasLength(2), reason: 'two games, not four files');
    final y = groups.firstWhere((g) => g.title == 'Pokemon Y');
    expect(y.variantCount, 3);
    expect(y.variants, hasLength(3));
    expect(y.totalSize, 300);
    expect(y.isSingle, isFalse);
  });

  test('a search on a console puts every region and format of a game in one group, and keeps sequels apart',
      () async {
    // The reported case: searching "god of war" in PS2 must give God of War
    // and God of War II, each holding all of its .iso, .7z and .chd files.
    await scrapeListing('sony_playstation_2', [
      'God of War (USA).iso',
      'God of War (Europe, Australia) (En,Fr,De,Es,It).7z',
      'God of War (Japan).chd',
      'God of War (USA) (Rev 1).iso.7z',
      'God of War II (USA).iso',
      'God of War II (Europe) (Disc 1).chd',
      'Ico (USA).iso',
    ]);

    final groups = await repo.queryGroupedFiles(query: 'god of war', consoleIds: ['sony_playstation_2']);

    expect(groups.map((g) => g.title), ['God of War', 'God of War II']);
    expect(
      groups.first.variants.map((v) => v.fileName),
      unorderedEquals([
        'God of War (USA).iso',
        'God of War (Europe, Australia) (En,Fr,De,Es,It).7z',
        'God of War (Japan).chd',
        'God of War (USA) (Rev 1).iso.7z',
      ]),
    );
    expect(groups.last.variants, hasLength(2));
    // With auto-extraction on, a PS2 .7z is an ISO once it lands.
    expect(groups.first.formatsFor(autoUnzip: true), ['CHD', 'ISO']);
  });

  test('the same title on two consoles is two separate games', () async {
    await scrapeListing('sony_playstation_2', ['Tekken (USA).iso']);
    await scrapeListing('sony_playstation_portable', ['Tekken (USA).iso']);

    final groups = await repo.queryGroupedFiles(query: 'tekken');

    expect(groups, hasLength(2));
    expect(groups.map((g) => g.consoleId).toSet(), {'sony_playstation_2', 'sony_playstation_portable'});
    for (final group in groups) {
      expect(group.variants, hasLength(1));
      expect(group.variants.single.consoleId, group.consoleId);
    }
    expect(groups.first.id, isNot(groups.last.id));
  });

  test('groups case- and whitespace-insensitively', () async {
    await seed([
      ('Pokemon Y', 'a.3ds', 10),
      ('pokemon y', 'b.3ds', 10),
      ('  Pokemon Y  ', 'c.3ds', 10),
    ]);

    final groups = await repo.queryGroupedFiles(query: 'pokemon');
    expect(groups, hasLength(1));
    expect(groups.single.variantCount, 3);
  });

  test('a game with a single file is not presented as expandable', () async {
    await seed([('Zelda', 'zelda.3ds', 50)]);

    final groups = await repo.queryGroupedFiles(query: '*');
    expect(groups.single.isSingle, isTrue);
    expect(groups.single.primary?.fileName, 'zelda.3ds');
  });

  test('primary picks the largest variant (the full dump, not a demo)', () async {
    await seed([
      ('Metroid', 'metroid-demo.3ds', 5),
      ('Metroid', 'metroid-full.3ds', 500),
    ]);

    final groups = await repo.queryGroupedFiles(query: 'metroid');
    expect(groups.single.primary?.fileName, 'metroid-full.3ds');
  });

  test('reports the distinct content formats inside a group', () async {
    await seed([
      ('Chrono', 'Chrono.iso.7z', 10),
      ('Chrono', 'Chrono.chd', 20),
      ('Chrono', 'Chrono2.chd', 20),
    ]);

    final groups = await repo.queryGroupedFiles(query: 'chrono');
    final formats = groups.single.formatsFor(autoUnzip: false);
    // `.iso.7z` reports ISO, not 7Z — the archive is transport, not format.
    expect(formats, containsAll(<String>['ISO', 'CHD']));
    expect(formats, isNot(contains('7Z')));
  });

  test('paginates over groups, never splitting a game across pages', () async {
    await seed([
      for (var i = 0; i < 5; i++) ...[
        ('Game $i', 'game${i}a.3ds', 10),
        ('Game $i', 'game${i}b.3ds', 10),
      ],
    ]);

    final first = await repo.queryGroupedFiles(query: '*', limit: 2);
    expect(first, hasLength(2));
    // Each page entry still carries all of its own variants.
    for (final group in first) {
      expect(group.variants, hasLength(2));
    }

    final second = await repo.queryGroupedFiles(query: '*', limit: 2, offset: 2);
    expect(second, hasLength(2));
    expect(
      first.map((g) => g.key).toSet().intersection(second.map((g) => g.key).toSet()),
      isEmpty,
    );
  });

  test('honours the search term and returns nothing when it matches no game', () async {
    await seed([('Pokemon Y', 'a.3ds', 10)]);

    expect(await repo.queryGroupedFiles(query: 'zelda'), isEmpty);
    expect(await repo.queryGroupedFiles(query: 'Pokemon'), hasLength(1));
  });

  test('escapes LIKE wildcards in the search term', () async {
    await seed([
      ('Game A', 'a.3ds', 10),
      ('Game_B', 'b.3ds', 10),
    ]);

    // `_` must match a literal underscore, not any single character.
    final groups = await repo.queryGroupedFiles(query: 'Game_');
    expect(groups, hasLength(1));
    expect(groups.single.title, 'Game_B');
  });
}
