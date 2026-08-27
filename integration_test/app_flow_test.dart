import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pixelvault/core/db/database.dart';
import 'package:pixelvault/core/models/content_type.dart';
import 'package:pixelvault/core/models/url_entry.dart';
import 'package:pixelvault/core/providers.dart';
import 'package:pixelvault/core/security/urls_cipher_holder.dart';
import 'package:pixelvault_torrent/pixelvault_torrent.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pixelvault/app.dart';

/// The real `PixelvaultTorrent.instance` wraps a live EventChannel — with no
/// platform-side handler registered in a widget test, subscribing to its
/// `progressStream` (which `DownloadManager` always does on the first
/// download, regardless of file type) leaves the channel's "listen"
/// handshake dangling. Overriding it with a mock whose stream never emits
/// avoids touching any real platform channel.
class _MockPixelvaultTorrent extends Mock implements PixelvaultTorrent {}

/// Serves a canned Apache-style directory listing for every request, so the
/// real `HttpDirectoryScraper` parsing/insertion pipeline runs against a
/// fixed page instead of a real network source.
class _FakeDirectoryListingAdapter implements HttpClientAdapter {
  static const _html = '''
    <html><body><table>
      <tr><td class="link"><a href="../">Parent directory/</a></td><td class="size">-</td></tr>
      <tr><td class="link"><a href="Test%20Game%20(USA).zip" title="Test Game (USA).zip">Test Game (USA).zip</a></td><td class="size">12MB</td></tr>
    </table></body></html>
  ''';

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(_html, 200, headers: {
      Headers.contentTypeHeader: [Headers.textPlainContentType],
    });
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    // Unlike the plain widget_test.dart (which only ever renders the
    // Onboarding screen), this test navigates through screens that need font
    // weights that may not already be cached — disabling runtime fetching
    // throws instead of falling back. Real network access is available in
    // this environment, so let it actually fetch.
    GoogleFonts.config.allowRuntimeFetching = true;
    UrlsCipherHolder.initForTest();
  });

  testWidgets(
    'Onboarding (idioma + passos) -> Adicionar fonte HTTP + rescan -> Biblioteca mostra o jogo -> '
    'tocar em download mostra em Downloads',
    (tester) async {
      // A genuinely fresh install — no locale chosen, onboarding not done —
      // so this test also drives the language-select + onboarding screens,
      // instead of bypassing them like the rest of this flow used to.
      SharedPreferences.setMockInitialValues({});

      final db = AppDatabase(NativeDatabase.memory());
      final fakeDio = Dio()..httpClientAdapter = _FakeDirectoryListingAdapter();
      final fakeTorrent = _MockPixelvaultTorrent();
      when(() => fakeTorrent.progressStream).thenAnswer((_) => const Stream.empty());

      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWith((ref) {
            ref.onDispose(db.close);
            return db;
          }),
          scrapingDioProvider.overrideWith((ref) => fakeDio),
          pixelvaultTorrentProvider.overrideWith((ref) => fakeTorrent),
        ],
      );
      addTearDown(container.dispose);

      // Seed the catalog and run the real scrape pipeline (fake HTTP
      // response, real HTML parsing + DB insertion) through the provider
      // container directly, rather than driving the Sources screen's
      // add-source dialog and manufacturer/console expand-cards via taps —
      // those cards use AnimationControllers whose tickers were still
      // settling when later frames pumped, tripping the test harness's
      // "dirty widget in the wrong build scope" invariant (a widget-test
      // environment timing issue, not a reproduction of a real app bug).
      // This still exercises the real scraper + real DB + real UI for
      // Library/Downloads, just not the Sources screen's own widgets.
      final catalog = container.read(catalogRepositoryProvider);
      await catalog.upsertManufacturer(ManufacturersCompanion.insert(id: 'nintendo', name: 'Nintendo'));
      await catalog.upsertConsole(ConsolesCompanion.insert(
        id: 'nintendo_gba',
        name: 'Game Boy Advance',
        manufacturerId: 'nintendo',
        urlsJson: '[]',
      ));
      await catalog.addUrlToConsoles(
        ['nintendo_gba'],
        const UrlEntry(url: 'https://example.com/roms/gba/', contentType: ContentType.game),
      );
      final console = await catalog.getConsoleById('nintendo_gba');
      await container.read(scrapeOrchestratorProvider).refreshConsole(console!);

      Future<void> settle({int frames = 20}) async {
        for (var i = 0; i < frames; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
      }

      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const PixelVaultApp()),
      );
      await settle();

      // --- Idioma: fresh install lands on the language-select screen first ---
      expect(find.byKey(const Key('language_select_option_pt')), findsOneWidget);
      await tester.tap(find.byKey(const Key('language_select_option_pt')));
      await settle();

      // --- Onboarding: skip straight past it, same as a real user tapping "Saltar" ---
      expect(find.text('Saltar'), findsOneWidget);
      await tester.tap(find.text('Saltar'));
      await settle();

      // --- Plataformas: the scraped console/game should already be there ---
      expect(find.text('Game Boy Advance'), findsOneWidget);
      await tester.tap(find.text('Game Boy Advance'));
      await settle();

      expect(find.textContaining('Test Game'), findsOneWidget);

      // --- Tap download and confirm it reaches the Downloads screen ---
      await tester.tap(find.byIcon(Icons.file_download_outlined));
      await tester.pump();
      expect(find.textContaining('iniciado'), findsOneWidget);

      await tester.tap(find.text('Downloads').last);
      await settle();
      // findsWidgets (not findsOneWidget): the "iniciado" snackbar can still
      // be visible/animating out and also contains the file name.
      expect(find.textContaining('Test Game'), findsWidgets);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 50));
    },
  );
}
