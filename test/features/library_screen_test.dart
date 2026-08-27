import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pixelvault/core/db/database.dart';
import 'package:pixelvault/core/download/download_manager.dart';
import 'package:pixelvault/core/models/downloadable_file.dart';
import 'package:pixelvault/core/providers.dart';
import 'package:pixelvault/core/security/urls_cipher_holder.dart';
import 'package:pixelvault/features/library/library_screen.dart';
import 'package:pixelvault/l10n/app_localizations.dart';

class MockDownloadManager extends Mock implements DownloadManager {}

DownloadableFileWithTags _fakeFile() {
  return const DownloadableFileWithTags(
    id: 1,
    name: 'Test Game',
    fileName: 'test_game.zip',
    consoleId: 'nintendo_gba',
    downloadUrl: 'https://example.com/test_game.zip',
    fileSize: 1000000,
    fileExtension: '.zip',
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(_fakeFile());
    UrlsCipherHolder.initForTest();
  });

  Future<ProviderContainer> pumpScreen(WidgetTester tester, MockDownloadManager manager) async {
    final db = AppDatabase(NativeDatabase.memory());
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWith((ref) {
          ref.onDispose(db.close);
          return db;
        }),
        downloadManagerProvider.overrideWith((ref) => manager),
      ],
    );
    addTearDown(container.dispose);

    final catalog = container.read(catalogRepositoryProvider);
    await catalog.upsertManufacturer(ManufacturersCompanion.insert(id: 'nintendo', name: 'Nintendo'));
    await catalog.upsertConsole(ConsolesCompanion.insert(
      id: 'nintendo_gba',
      name: 'Game Boy Advance',
      manufacturerId: 'nintendo',
      urlsJson: '[]',
    ));

    await container.read(downloadableFileRepositoryProvider).insertFilesWithTags(
      [
        DownloadableFilesCompanion.insert(
          name: 'Test Game',
          fileName: 'test_game.zip',
          consoleId: 'nintendo_gba',
          downloadUrl: 'https://example.com/test_game.zip',
        ),
      ],
      [
        ['USA'],
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          locale: Locale('pt'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: LibraryScreen(),
        ),
      ),
    );
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    return container;
  }

  testWidgets('shows an indexed file and tapping download calls startDownload', (tester) async {
    final manager = MockDownloadManager();
    when(() => manager.startDownload(any())).thenAnswer((_) async {});

    await pumpScreen(tester, manager);

    expect(find.text('Test Game'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.file_download_outlined));
    await tester.pump();

    final captured = verify(() => manager.startDownload(captureAny())).captured;
    expect(captured, hasLength(1));
    expect((captured.single as DownloadableFileWithTags).fileName, 'test_game.zip');
    expect(find.textContaining('iniciado'), findsOneWidget);
  });
}
