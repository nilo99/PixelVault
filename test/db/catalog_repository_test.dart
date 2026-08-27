import 'dart:convert';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixelvault/core/db/daos/catalog_repository.dart';
import 'package:pixelvault/core/db/database.dart';
import 'package:pixelvault/core/models/content_type.dart';
import 'package:pixelvault/core/models/console_x.dart';
import 'package:pixelvault/core/models/url_entry.dart';
import 'package:pixelvault/core/security/urls_cipher_holder.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => UrlsCipherHolder.initForTest());

  late AppDatabase db;
  late CatalogRepository catalog;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    catalog = CatalogRepository(db);
    await catalog.upsertManufacturer(
      ManufacturersCompanion.insert(id: 'nintendo', name: 'Nintendo'),
    );
    await catalog.upsertConsole(
      ConsolesCompanion.insert(
        id: 'nintendo_gba',
        name: 'Game Boy Advance',
        manufacturerId: 'nintendo',
        urlsJson: '[]',
      ),
    );
    await catalog.upsertConsole(
      ConsolesCompanion.insert(
        id: 'nintendo_snes',
        name: 'Super Nintendo',
        manufacturerId: 'nintendo',
        urlsJson: '[]',
      ),
    );
  });

  tearDown(() => db.close());

  group('addUrlToConsoles', () {
    test('adds the entry to every listed console', () async {
      const entry = UrlEntry(url: 'https://example.com/gba/', contentType: ContentType.game);
      await catalog.addUrlToConsoles(['nintendo_gba', 'nintendo_snes'], entry);

      final gba = await catalog.getConsoleById('nintendo_gba');
      final snes = await catalog.getConsoleById('nintendo_snes');
      expect(gba!.urls.map((u) => u.url), contains(entry.url));
      expect(snes!.urls.map((u) => u.url), contains(entry.url));
    });

    test('skips ids that do not exist without throwing', () async {
      const entry = UrlEntry(url: 'https://example.com/gba/', contentType: ContentType.game);
      await catalog.addUrlToConsoles(['nintendo_gba', 'does_not_exist'], entry);

      final gba = await catalog.getConsoleById('nintendo_gba');
      expect(gba!.urls, hasLength(1));
    });

    test('does not add a duplicate when the same url is added twice', () async {
      const entry = UrlEntry(url: 'https://example.com/a/', contentType: ContentType.game);
      await catalog.addUrlToConsoles(['nintendo_gba'], entry);
      await catalog.addUrlToConsoles(['nintendo_gba'], entry);

      final gba = await catalog.getConsoleById('nintendo_gba');
      expect(gba!.urls, hasLength(1));
    });

    test('appends to existing urls rather than replacing them', () async {
      const first = UrlEntry(url: 'https://example.com/a/', contentType: ContentType.game);
      const second = UrlEntry(url: 'magnet:?xt=urn:btih:abc', contentType: ContentType.miscellaneous);

      await catalog.addUrlToConsoles(['nintendo_gba'], first);
      await catalog.addUrlToConsoles(['nintendo_gba'], second);

      final gba = await catalog.getConsoleById('nintendo_gba');
      expect(gba!.urls, hasLength(2));
      expect(gba.urls.map((u) => u.url), containsAll([first.url, second.url]));
    });

    test('preserves contentType and folders through the JSON round trip', () async {
      const entry = UrlEntry(
        url: 'magnet:?xt=urn:btih:abc',
        contentType: ContentType.retroachievements,
        folders: ['Roms', 'Updates'],
      );
      await catalog.addUrlToConsoles(['nintendo_gba'], entry);

      final gba = await catalog.getConsoleById('nintendo_gba');
      final stored = gba!.urls.single;
      expect(stored.contentType, ContentType.retroachievements);
      expect(stored.folders, ['Roms', 'Updates']);
    });
  });

  group('removeUrlFromConsole', () {
    test('removes only the matching url by exact url string', () async {
      const a = UrlEntry(url: 'https://example.com/a/', contentType: ContentType.game);
      const b = UrlEntry(url: 'https://example.com/b/', contentType: ContentType.game);
      await catalog.addUrlToConsoles(['nintendo_gba'], a);
      await catalog.addUrlToConsoles(['nintendo_gba'], b);

      await catalog.removeUrlFromConsole('nintendo_gba', a);

      final gba = await catalog.getConsoleById('nintendo_gba');
      expect(gba!.urls.map((u) => u.url), [b.url]);
    });

    test('is a no-op for a console that does not exist', () async {
      const entry = UrlEntry(url: 'https://example.com/a/', contentType: ContentType.game);
      await expectLater(catalog.removeUrlFromConsole('does_not_exist', entry), completes);
    });

    test('is a no-op when the url is not present on the console', () async {
      const a = UrlEntry(url: 'https://example.com/a/', contentType: ContentType.game);
      const b = UrlEntry(url: 'https://example.com/b/', contentType: ContentType.game);
      await catalog.addUrlToConsoles(['nintendo_gba'], a);

      await catalog.removeUrlFromConsole('nintendo_gba', b);

      final gba = await catalog.getConsoleById('nintendo_gba');
      expect(gba!.urls.map((u) => u.url), [a.url]);
    });
  });

  group('updateConsoleUrls', () {
    test('replaces the full list', () async {
      const a = UrlEntry(url: 'https://example.com/a/', contentType: ContentType.game);
      const b = UrlEntry(url: 'https://example.com/b/', contentType: ContentType.game);
      await catalog.addUrlToConsoles(['nintendo_gba'], a);

      await catalog.updateConsoleUrls('nintendo_gba', [b]);

      final gba = await catalog.getConsoleById('nintendo_gba');
      expect(gba!.urls.map((u) => u.url), [b.url]);
    });

    test('round-trips lastSyncedAt through the encrypted urlsJson storage', () async {
      final syncedAt = DateTime.utc(2026, 1, 2, 3, 4, 5);
      final entry = UrlEntry(url: 'https://example.com/a/', contentType: ContentType.game, lastSyncedAt: syncedAt);

      await catalog.updateConsoleUrls('nintendo_gba', [entry]);

      final gba = await catalog.getConsoleById('nintendo_gba');
      expect(gba!.urls.single.lastSyncedAt, syncedAt);
    });

    test('is a no-op for a console that does not exist', () async {
      await expectLater(
        catalog.updateConsoleUrls('does_not_exist', const [UrlEntry(url: 'x', contentType: ContentType.game)]),
        completes,
      );
    });
  });

  group('delete', () {
    test('deleteManufacturer removes only that manufacturer', () async {
      await catalog.upsertManufacturer(ManufacturersCompanion.insert(id: 'sony', name: 'Sony'));

      await catalog.deleteManufacturer('nintendo');

      final remaining = await catalog.watchManufacturers().first;
      expect(remaining.map((m) => m.id), ['sony']);
    });

    test('deleteConsole removes only that console', () async {
      await catalog.deleteConsole('nintendo_gba');

      final remaining = await catalog.watchAllConsoles().first;
      expect(remaining.map((c) => c.id), ['nintendo_snes']);
    });
  });

  group('encryption at rest', () {
    test('addUrlToConsoles stores urlsJson encrypted, not as readable JSON', () async {
      const entry = UrlEntry(url: 'magnet:?xt=urn:btih:secretvalue', contentType: ContentType.game);
      await catalog.addUrlToConsoles(['nintendo_gba'], entry);

      final gba = await catalog.getConsoleById('nintendo_gba');
      expect(gba!.urlsJson, isNot(contains('magnet:')));
      expect(gba.urlsJson, isNot(contains('secretvalue')));
      expect(gba.urlsJson, startsWith('#enc#'));
      // But it still round-trips correctly through the decrypting getter.
      expect(gba.urls.single.url, entry.url);
    });

    test('a console seeded with legacy plaintext urlsJson still decodes correctly', () async {
      const entry = UrlEntry(url: 'https://example.com/legacy/', contentType: ContentType.game);
      await catalog.upsertConsole(ConsolesCompanion(
        id: const Value('nintendo_gba'),
        name: const Value('Game Boy Advance'),
        manufacturerId: const Value('nintendo'),
        urlsJson: Value('[${jsonEncode(entry.toJson())}]'),
      ));

      final gba = await catalog.getConsoleById('nintendo_gba');
      expect(gba!.urls.single.url, entry.url);

      // Writing again (e.g. adding another source) migrates it to encrypted.
      await catalog.addUrlToConsoles(['nintendo_gba'], const UrlEntry(url: 'https://example.com/new/', contentType: ContentType.game));
      final migrated = await catalog.getConsoleById('nintendo_gba');
      expect(migrated!.urlsJson, startsWith('#enc#'));
      expect(migrated.urls.map((u) => u.url), containsAll([entry.url, 'https://example.com/new/']));
    });
  });

  group('lookups', () {
    test('getConsolesForManufacturer returns only consoles for that manufacturer', () async {
      await catalog.upsertManufacturer(ManufacturersCompanion.insert(id: 'sony', name: 'Sony'));
      await catalog.upsertConsole(
        ConsolesCompanion.insert(id: 'sony_psp', name: 'PSP', manufacturerId: 'sony', urlsJson: '[]'),
      );

      final nintendoConsoles = await catalog.getConsolesForManufacturer('nintendo');
      expect(nintendoConsoles.map((c) => c.id), containsAll(['nintendo_gba', 'nintendo_snes']));
      expect(nintendoConsoles.map((c) => c.id), isNot(contains('sony_psp')));
    });

    test('getConsoleById returns null for an unknown id', () async {
      final result = await catalog.getConsoleById('does_not_exist');
      expect(result, isNull);
    });
  });
}
