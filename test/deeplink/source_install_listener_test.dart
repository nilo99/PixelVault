import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pixelvault/core/db/database.dart';
import 'package:pixelvault/core/deeplink/deep_link_service.dart';
import 'package:pixelvault/core/deeplink/source_install_client.dart';
import 'package:pixelvault/core/deeplink/source_install_listener.dart';
import 'package:pixelvault/core/models/console_x.dart';
import 'package:pixelvault/core/providers.dart';
import 'package:pixelvault/core/router/app_router.dart';
import 'package:pixelvault/core/scraping/scrape_orchestrator.dart';
import 'package:pixelvault/core/security/urls_cipher_holder.dart';
import 'package:pixelvault/l10n/app_localizations.dart';

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.responder);
  final ResponseBody Function(RequestOptions options) responder;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async =>
      responder(options);
}

class _FakeDeepLinkService extends DeepLinkService {
  _FakeDeepLinkService(this._stream);
  final Stream<Uri> _stream;

  @override
  Stream<Uri> get linkStream => _stream;
}

class _MockScrapeOrchestrator extends Mock implements ScrapeOrchestrator {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      Console(id: 'x', name: 'x', manufacturerId: 'x', urlsJson: '[]'),
    );
    UrlsCipherHolder.initForTest();
  });

  Future<ProviderContainer> pumpListener(
    WidgetTester tester, {
    required Uri link,
    required String resolvedUrl,
    required _MockScrapeOrchestrator orchestrator,
    List<String> preExistingUrls = const [],
  }) async {
    final db = AppDatabase(NativeDatabase.memory());
    final dio = Dio()
      ..httpClientAdapter = _FakeAdapter((options) {
        return ResponseBody.fromString(
          '{"consoleId":"nintendo_gba","url":"$resolvedUrl","contentType":"GAME"}',
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWith((ref) {
          ref.onDispose(db.close);
          return db;
        }),
        sourceInstallClientProvider.overrideWith(
          (ref) => SourceInstallClient(baseUrl: 'https://example.com', dio: dio, hmacSecret: 'test-secret'),
        ),
        scrapeOrchestratorProvider.overrideWith((ref) => orchestrator),
      ],
    );
    addTearDown(container.dispose);

    final catalog = container.read(catalogRepositoryProvider);
    await catalog.upsertManufacturer(ManufacturersCompanion.insert(id: 'nintendo', name: 'Nintendo'));
    final urlsJson = jsonEncode([
      for (final url in preExistingUrls) {'url': url, 'contentType': 'GAME'},
    ]);
    await catalog.upsertConsole(ConsolesCompanion.insert(
      id: 'nintendo_gba',
      name: 'Game Boy Advance',
      manufacturerId: 'nintendo',
      urlsJson: urlsJson,
    ));

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          navigatorKey: rootNavigatorKey,
          locale: const Locale('pt'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SourceInstallListener(
            deepLinkService: _FakeDeepLinkService(Stream.value(link)),
            child: const Scaffold(body: SizedBox()),
          ),
        ),
      ),
    );
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    return container;
  }

  testWidgets('a genuinely new source shows confirm -> success and never auto-syncs', (tester) async {
    final orchestrator = _MockScrapeOrchestrator();
    final container = await pumpListener(
      tester,
      link: Uri.parse('pixelvault://install?token=tok1'),
      resolvedUrl: 'magnet:?xt=urn:btih:brandnew',
      orchestrator: orchestrator,
    );

    expect(find.text('Adicionar fonte'), findsOneWidget);
    await tester.tap(find.text('Adicionar'));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(find.textContaining('Vai a Fontes para sincronizar'), findsOneWidget);
    verifyNever(() => orchestrator.refreshConsole(any()));

    final console = await container.read(catalogRepositoryProvider).getConsoleById('nintendo_gba');
    expect(console!.urls.any((u) => u.url == 'magnet:?xt=urn:btih:brandnew'), isTrue);
  });

  testWidgets('installing a source already present shows an error, not the confirm dialog', (tester) async {
    final orchestrator = _MockScrapeOrchestrator();
    await pumpListener(
      tester,
      link: Uri.parse('pixelvault://install?token=tok2'),
      resolvedUrl: 'magnet:?xt=urn:btih:already',
      orchestrator: orchestrator,
      preExistingUrls: const ['magnet:?xt=urn:btih:already'],
    );

    expect(find.text('Adicionar fonte'), findsNothing);
    expect(find.textContaining('já está instalada'), findsOneWidget);
    verifyNever(() => orchestrator.refreshConsole(any()));
  });
}
