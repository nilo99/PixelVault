import 'dart:async';

import 'package:drift/native.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pixelvault/core/db/daos/downloadable_file_repository.dart';
import 'package:pixelvault/core/db/database.dart';
import 'package:pixelvault/core/models/content_type.dart';
import 'package:pixelvault/core/models/url_entry.dart';
import 'package:pixelvault/core/scraping/native_torrent_scraper.dart';
import 'package:pixelvault/core/scraping/scraping_constants.dart';
import 'package:pixelvault_torrent/pixelvault_torrent.dart';

class MockPixelvaultTorrent extends Mock implements PixelvaultTorrent {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late DownloadableFileRepository files;
  late MockPixelvaultTorrent plugin;

  const urlEntry = UrlEntry(url: 'magnet:?xt=urn:btih:test', contentType: ContentType.game);
  const emptyMetadata = TorrentMetadata(infoHash: 'abc', files: []);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    files = DownloadableFileRepository(db);
    plugin = MockPixelvaultTorrent();
    when(() => plugin.startSession()).thenAnswer((_) async {});
  });

  tearDown(() async {
    await db.close();
  });

  test('a stalled metadata fetch is retried instead of failing the sync immediately', () {
    fakeAsync((async) {
      var attempts = 0;
      when(() => plugin.fetchMetadata(any(), folders: any(named: 'folders'))).thenAnswer((_) async {
        attempts++;
        if (attempts < ScrapingConstants.maxRetries) {
          throw Exception('metadata fetch timed out');
        }
        return emptyMetadata;
      });

      final scraper = NativeTorrentScraper(files, plugin);
      Object? error;
      var succeeded = false;
      unawaited(() async {
        try {
          await scraper.scrapeAndInsert(
              urlEntry: urlEntry, consoleId: 'nintendo_snes', consoleName: 'Super Nintendo');
          succeeded = true;
        } catch (e) {
          error = e;
        }
      }());

      async.elapse(const Duration(seconds: 30));

      expect(error, isNull);
      expect(succeeded, isTrue);
      expect(attempts, ScrapingConstants.maxRetries);
    });
  });

  test('gives up only after maxRetries consecutive failures', () {
    fakeAsync((async) {
      var attempts = 0;
      when(() => plugin.fetchMetadata(any(), folders: any(named: 'folders'))).thenAnswer((_) async {
        attempts++;
        throw Exception('metadata fetch timed out');
      });

      final scraper = NativeTorrentScraper(files, plugin);
      Object? error;
      unawaited(() async {
        try {
          await scraper.scrapeAndInsert(
              urlEntry: urlEntry, consoleId: 'nintendo_snes', consoleName: 'Super Nintendo');
        } catch (e) {
          error = e;
        }
      }());

      async.elapse(const Duration(seconds: 30));

      expect(error, isNotNull);
      expect(attempts, ScrapingConstants.maxRetries);
    });
  });
}
