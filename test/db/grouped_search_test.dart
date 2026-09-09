import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixelvault/core/db/daos/downloadable_file_repository.dart';
import 'package:pixelvault/core/db/database.dart';

void main() {
  late AppDatabase db;
  late DownloadableFileRepository repo;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repo = DownloadableFileRepository(db);

    await db.into(db.manufacturers).insert(
          ManufacturersCompanion.insert(id: 'nintendo', name: 'Nintendo'),
        );
    await db.into(db.consoles).insert(ConsolesCompanion.insert(
          id: 'n3ds',
          name: 'Nintendo 3DS',
          manufacturerId: 'nintendo',
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
    // `.iso.7z` reports ISO, not 7Z — the archive is transport, not format.
    expect(groups.single.formats, containsAll(<String>['ISO', 'CHD']));
    expect(groups.single.formats, isNot(contains('7Z')));
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
