import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pixelvault/core/db/daos/catalog_repository.dart';
import 'package:pixelvault/core/db/daos/downloadable_file_repository.dart';
import 'package:pixelvault/core/db/database.dart';
import 'package:pixelvault/core/models/content_type.dart';
import 'package:pixelvault/core/models/console_x.dart';
import 'package:pixelvault/core/scraping/http_directory_scraper.dart';
import 'package:pixelvault/core/scraping/scrape_orchestrator.dart';
import 'package:pixelvault/core/scraping/torrent_scraper.dart';
import 'package:pixelvault/core/state/rescan_state.dart';
import 'package:pixelvault/core/models/url_entry.dart';
import 'package:pixelvault/core/security/urls_cipher_holder.dart';

class MockHttpDirectoryScraper extends Mock implements HttpDirectoryScraper {}

class MockTorrentScraper extends Mock implements TorrentScraper {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(const UrlEntry(url: 'fallback', contentType: ContentType.game));
    registerFallbackValue(ContentType.game);
    UrlsCipherHolder.initForTest();
  });

  late AppDatabase db;
  late CatalogRepository catalog;
  late DownloadableFileRepository files;
  late MockHttpDirectoryScraper httpScraper;
  late MockTorrentScraper torrentScraper;
  late ProviderContainer container;
  late RescanStateHolder rescan;

  const httpConsoleId = 'nintendo_gba';
  const torrentConsoleId = 'nintendo_snes';

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    catalog = CatalogRepository(db);
    files = DownloadableFileRepository(db);
    httpScraper = MockHttpDirectoryScraper();
    torrentScraper = MockTorrentScraper();
    container = ProviderContainer();
    rescan = container.read(rescanStateHolderProvider.notifier);

    when(() => httpScraper.scrapeAndInsert(
          baseUrl: any(named: 'baseUrl'),
          consoleId: any(named: 'consoleId'),
          contentType: any(named: 'contentType'),
        )).thenAnswer((_) async => (0, 0));
    when(() => torrentScraper.scrapeAndInsert(
          urlEntry: any(named: 'urlEntry'),
          consoleId: any(named: 'consoleId'),
          consoleName: any(named: 'consoleName'),
        )).thenAnswer((_) async => (0, 0));

    await catalog.upsertManufacturer(ManufacturersCompanion.insert(id: 'nintendo', name: 'Nintendo'));
    // Names are chosen so `ORDER BY name ASC` (watchAllConsoles) yields a
    // stable, known iteration order: httpConsole before torrentConsole.
    await catalog.upsertConsole(ConsolesCompanion.insert(
      id: httpConsoleId,
      name: 'A - Game Boy Advance',
      manufacturerId: 'nintendo',
      urlsJson: '[{"url":"https://example.com/gba/","contentType":"GAME"}]',
    ));
    await catalog.upsertConsole(ConsolesCompanion.insert(
      id: torrentConsoleId,
      name: 'B - Super Nintendo',
      manufacturerId: 'nintendo',
      urlsJson: '[{"url":"magnet:?xt=urn:btih:abc","contentType":"GAME"}]',
    ));
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  ScrapeOrchestrator buildOrchestrator({bool includeTorrentScraper = true}) {
    return ScrapeOrchestrator(
      catalog: catalog,
      files: files,
      httpScraper: httpScraper,
      rescan: rescan,
      torrentScraper: includeTorrentScraper ? torrentScraper : null,
    );
  }

  group('rescanAll', () {
    test('wipes existing files and routes each console to the right scraper', () async {
      await files.insertFilesWithTags(
        [
          DownloadableFilesCompanion.insert(
            name: 'Stale',
            fileName: 'stale.zip',
            consoleId: httpConsoleId,
            downloadUrl: 'https://example.com/stale.zip',
          ),
        ],
        [
          ['USA'],
        ],
      );
      expect(await files.getFilesCount(), 1);

      final orchestrator = buildOrchestrator();
      await orchestrator.rescanAll();

      expect(await files.getFilesCount(), 0);
      verify(() => httpScraper.scrapeAndInsert(
            baseUrl: 'https://example.com/gba/',
            consoleId: httpConsoleId,
            contentType: ContentType.game,
          )).called(1);
      verify(() => torrentScraper.scrapeAndInsert(
            urlEntry: any(named: 'urlEntry'),
            consoleId: torrentConsoleId,
            consoleName: 'B - Super Nintendo',
          )).called(1);

      // Every source is marked synced after a successful scrape.
      final httpConsole = (await catalog.getConsoleById(httpConsoleId))!;
      final torrentConsole = (await catalog.getConsoleById(torrentConsoleId))!;
      expect(httpConsole.urls.single.lastSyncedAt, isNotNull);
      expect(torrentConsole.urls.single.lastSyncedAt, isNotNull);
    });

    test('clears isRescanning and the progress message once finished', () async {
      final orchestrator = buildOrchestrator();
      await orchestrator.rescanAll();

      expect(rescan.isRescanning, isFalse);
      expect(container.read(rescanStateHolderProvider).progressMessage, isEmpty);
    });

    test('records an error and continues with the next console when a scraper throws', () async {
      when(() => httpScraper.scrapeAndInsert(
            baseUrl: any(named: 'baseUrl'),
            consoleId: any(named: 'consoleId'),
            contentType: any(named: 'contentType'),
          )).thenThrow(StateError('boom'));

      final orchestrator = buildOrchestrator();
      await orchestrator.rescanAll();

      final state = container.read(rescanStateHolderProvider);
      expect(state.errorMessage, contains('A - Game Boy Advance'));
      // The loop must still have reached the second (torrent) console.
      verify(() => torrentScraper.scrapeAndInsert(
            urlEntry: any(named: 'urlEntry'),
            consoleId: torrentConsoleId,
            consoleName: any(named: 'consoleName'),
          )).called(1);
      expect(rescan.isRescanning, isFalse);

      // The failed source stays unsynced; the console that succeeded is marked.
      final httpConsole = (await catalog.getConsoleById(httpConsoleId))!;
      final torrentConsole = (await catalog.getConsoleById(torrentConsoleId))!;
      expect(httpConsole.urls.single.lastSyncedAt, isNull);
      expect(torrentConsole.urls.single.lastSyncedAt, isNotNull);
    });

    test('never leaks the raw magnet/URL into the displayed error message', () async {
      when(() => torrentScraper.scrapeAndInsert(
            urlEntry: any(named: 'urlEntry'),
            consoleId: any(named: 'consoleId'),
            consoleName: any(named: 'consoleName'),
          )).thenThrow(PlatformException(
        code: 'FETCH_METADATA_FAILED',
        message: 'Metadata fetch timed out after 20s for: magnet:?xt=urn:btih:deadbeef&dn=Secret',
      ));

      final orchestrator = buildOrchestrator();
      await orchestrator.rescanAll();

      final state = container.read(rescanStateHolderProvider);
      expect(state.errorMessage, contains('B - Super Nintendo'));
      expect(state.errorMessage, isNot(contains('magnet:')));
      expect(state.errorMessage, isNot(contains('Secret')));
    });

    test('records an error for torrent URLs when no torrentScraper is configured', () async {
      final orchestrator = buildOrchestrator(includeTorrentScraper: false);
      await orchestrator.rescanAll();

      final state = container.read(rescanStateHolderProvider);
      expect(state.errorMessage, contains('Torrent sources are not available'));
      verifyNever(() => torrentScraper.scrapeAndInsert(
            urlEntry: any(named: 'urlEntry'),
            consoleId: any(named: 'consoleId'),
            consoleName: any(named: 'consoleName'),
          ));

      final torrentConsole = (await catalog.getConsoleById(torrentConsoleId))!;
      expect(torrentConsole.urls.single.lastSyncedAt, isNull);
    });

    test('no-ops when a rescan is already in progress', () async {
      rescan.setRescanning(true);
      addTearDown(() => rescan.setRescanning(false));

      final orchestrator = buildOrchestrator();
      await orchestrator.rescanAll();

      verifyNever(() => httpScraper.scrapeAndInsert(
            baseUrl: any(named: 'baseUrl'),
            consoleId: any(named: 'consoleId'),
            contentType: any(named: 'contentType'),
          ));
      expect(container.read(rescanStateHolderProvider).errorMessage, contains('sincronização em curso'));
    });

    test('deletes and rescrapes one console at a time instead of wiping the whole catalog up front', () async {
      await files.insertFilesWithTags(
        [
          DownloadableFilesCompanion.insert(
            name: 'Stale A',
            fileName: 'staleA.zip',
            consoleId: httpConsoleId,
            downloadUrl: 'https://example.com/staleA.zip',
          ),
          DownloadableFilesCompanion.insert(
            name: 'Stale B',
            fileName: 'staleB.zip',
            consoleId: torrentConsoleId,
            downloadUrl: 'https://example.com/staleB.zip',
          ),
        ],
        [
          ['USA'],
          ['USA'],
        ],
      );

      // Once the HTTP (first, alphabetically) console is scraped, the second
      // console's stale file must still be present — proof the whole catalog
      // isn't wiped up front, only the console currently being processed.
      var sawConsoleBFileStillPresentDuringConsoleAScrape = false;
      when(() => httpScraper.scrapeAndInsert(
            baseUrl: any(named: 'baseUrl'),
            consoleId: any(named: 'consoleId'),
            contentType: any(named: 'contentType'),
          )).thenAnswer((_) async {
        final remaining = await files.getFilesCount();
        sawConsoleBFileStillPresentDuringConsoleAScrape = remaining > 0;
        return (0, 0);
      });

      final orchestrator = buildOrchestrator();
      await orchestrator.rescanAll();

      expect(sawConsoleBFileStillPresentDuringConsoleAScrape, isTrue);
      expect(await files.getFilesCount(), 0);
    });
  });

  group('refreshConsole', () {
    test('deletes existing files for that console then rescrapes it', () async {
      await files.insertFilesWithTags(
        [
          DownloadableFilesCompanion.insert(
            name: 'Stale',
            fileName: 'stale.zip',
            consoleId: httpConsoleId,
            downloadUrl: 'https://example.com/stale.zip',
          ),
        ],
        [
          ['USA'],
        ],
      );

      final console = (await catalog.getConsoleById(httpConsoleId))!;
      final orchestrator = buildOrchestrator();
      await orchestrator.refreshConsole(console);

      expect(await files.getFilesCount(), 0);
      verify(() => httpScraper.scrapeAndInsert(
            baseUrl: 'https://example.com/gba/',
            consoleId: httpConsoleId,
            contentType: ContentType.game,
          )).called(1);
      expect(rescan.isRescanning, isFalse);
    });

    test('no-ops when a rescan is already in progress', () async {
      rescan.setRescanning(true);
      addTearDown(() => rescan.setRescanning(false));

      final console = (await catalog.getConsoleById(httpConsoleId))!;
      final orchestrator = buildOrchestrator();
      await orchestrator.refreshConsole(console);

      verifyNever(() => httpScraper.scrapeAndInsert(
            baseUrl: any(named: 'baseUrl'),
            consoleId: any(named: 'consoleId'),
            contentType: any(named: 'contentType'),
          ));
      expect(container.read(rescanStateHolderProvider).errorMessage, contains('sincronização em curso'));
    });

    test(
      'regression: syncing Fonte 1 then adding Fonte 2 flags the console as unsynced again, '
      'even though the console-wide file count is still > 0',
      () async {
        final consoleBefore = (await catalog.getConsoleById(httpConsoleId))!;
        final orchestrator = buildOrchestrator();
        await orchestrator.refreshConsole(consoleBefore);

        // Simulate Fonte 1 having left indexed files behind (the mocked
        // scraper itself inserts none) — this is the console-wide file count
        // that the OLD, buggy check relied on and that must NOT be enough to
        // hide an unsynced Fonte 2 below.
        await files.insertFilesWithTags(
          [
            DownloadableFilesCompanion.insert(
              name: 'Fonte 1 game',
              fileName: 'fonte1.zip',
              consoleId: httpConsoleId,
              downloadUrl: 'https://example.com/gba/fonte1.zip',
            ),
          ],
          [
            ['USA'],
          ],
        );

        var console = (await catalog.getConsoleById(httpConsoleId))!;
        expect(console.urls.single.lastSyncedAt, isNotNull);
        expect(await files.getFilesCount(), greaterThan(0));

        // Add a second, never-synced source to the same console.
        await catalog.addUrlToConsoles(
          [httpConsoleId],
          const UrlEntry(url: 'https://example.com/gba2/', contentType: ContentType.game),
        );

        console = (await catalog.getConsoleById(httpConsoleId))!;
        // The bug: fileCount alone would still report > 0 here, hiding the
        // fact that Fonte 2 was never scraped. The fix must catch it via
        // lastSyncedAt instead.
        expect(console.urls, hasLength(2));
        expect(console.urls.any((u) => u.lastSyncedAt == null), isTrue);
      },
    );
  });
}
