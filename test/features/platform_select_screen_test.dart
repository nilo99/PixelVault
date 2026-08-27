import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixelvault/core/db/database.dart';
import 'package:pixelvault/core/providers.dart';
import 'package:pixelvault/core/security/urls_cipher_holder.dart';
import 'package:pixelvault/features/platform_select/platform_select_screen.dart';
import 'package:pixelvault/l10n/app_localizations.dart';

void main() {
  setUpAll(() => UrlsCipherHolder.initForTest());

  Future<void> seedConsole(ProviderContainer container, {required String id, required String name}) async {
    final catalog = container.read(catalogRepositoryProvider);
    await catalog.upsertManufacturer(ManufacturersCompanion.insert(id: 'nintendo', name: 'Nintendo'));
    await catalog.upsertConsole(ConsolesCompanion.insert(id: id, name: name, manufacturerId: 'nintendo', urlsJson: '[]'));
  }

  Future<void> seedIndexedFile(ProviderContainer container, {required String consoleId, required String fileName}) async {
    await container.read(downloadableFileRepositoryProvider).insertFilesWithTags(
      [
        DownloadableFilesCompanion.insert(
          name: fileName,
          fileName: '$fileName.zip',
          consoleId: consoleId,
          downloadUrl: 'https://example.com/$fileName.zip',
        ),
      ],
      [
        <String>[],
      ],
    );
  }

  /// Seeding must happen *before* `pumpWidget`, not after, so the data is
  /// already there by the time the screen first builds. `ensureCatalogSeeded`
  /// itself is overridden below — this test is about `PlatformSelectScreen`'s
  /// rendering given console/file-count data, not about validating the
  /// seed-detection provider, which is an orthogonal concern.
  Future<ProviderContainer> pumpScreen(
    WidgetTester tester, {
    required Future<void> Function(ProviderContainer container) seed,
  }) async {
    final db = AppDatabase(NativeDatabase.memory());
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWith((ref) {
          ref.onDispose(db.close);
          return db;
        }),
        ensureCatalogSeededProvider.overrideWith((ref) async {}),
      ],
    );
    addTearDown(container.dispose);
    await seed(container);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          locale: Locale('pt'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: PlatformSelectScreen(),
        ),
      ),
    );
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    return container;
  }

  testWidgets('shows the empty state when no console has any indexed files', (tester) async {
    await pumpScreen(
      tester,
      seed: (container) => seedConsole(container, id: 'nintendo_gba', name: 'Game Boy Advance'),
    );

    expect(find.text('Sem plataformas.\nVai a Fontes para adicionar fontes.'), findsOneWidget);
    expect(find.text('Game Boy Advance'), findsNothing);
  });

  testWidgets('shows consoles that have indexed files, sorted by name', (tester) async {
    await pumpScreen(
      tester,
      seed: (container) async {
        await seedConsole(container, id: 'nintendo_gba', name: 'Game Boy Advance');
        await seedConsole(container, id: 'nintendo_nes', name: 'Arcade Classic');
        await seedIndexedFile(container, consoleId: 'nintendo_gba', fileName: 'Some Game');
        await seedIndexedFile(container, consoleId: 'nintendo_nes', fileName: 'Another Game');
      },
    );

    final consoleNames = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data)
        .whereType<String>()
        .where((t) => t == 'Game Boy Advance' || t == 'Arcade Classic')
        .toList();
    expect(consoleNames, ['Arcade Classic', 'Game Boy Advance']);
  });

  testWidgets('typing in the search field filters the console list', (tester) async {
    await pumpScreen(
      tester,
      seed: (container) async {
        await seedConsole(container, id: 'nintendo_gba', name: 'Game Boy Advance');
        await seedConsole(container, id: 'nintendo_nes', name: 'Arcade Classic');
        await seedIndexedFile(container, consoleId: 'nintendo_gba', fileName: 'Some Game');
        await seedIndexedFile(container, consoleId: 'nintendo_nes', fileName: 'Another Game');
      },
    );

    expect(find.text('Game Boy Advance'), findsOneWidget);
    expect(find.text('Arcade Classic'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'arcade');
    await tester.pump();

    expect(find.text('Arcade Classic'), findsOneWidget);
    expect(find.text('Game Boy Advance'), findsNothing);
  });
}
