import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pixelvault/core/db/database.dart';
import 'package:pixelvault/core/download/download_manager.dart';
import 'package:pixelvault/core/models/downloadable_file.dart';
import 'package:pixelvault/core/providers.dart';
import 'package:pixelvault/core/scraping/file_naming.dart';
import 'package:pixelvault/core/security/urls_cipher_holder.dart';
import 'package:pixelvault/core/settings/settings_repository.dart';
import 'package:pixelvault/core/storage/installed_games_index.dart';
import 'package:pixelvault/features/library/library_screen.dart';
import 'package:pixelvault/l10n/app_localizations.dart';
import 'package:saf_util/saf_util_platform_interface.dart' show SafDocumentFile;
import 'package:shared_preferences/shared_preferences.dart';

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

  /// Pumps the Library over a catalog of [files] for one console.
  ///
  /// [folders] is what each destination folder URI contains, standing in for
  /// the SAF listing the "already in the folder" badge reads.
  Future<ProviderContainer> pumpScreen(
    WidgetTester tester, {
    MockDownloadManager? manager,
    String consoleId = 'nintendo_gba',
    String consoleName = 'Game Boy Advance',
    required List<(String name, String fileName, List<String> tags)> files,
    Map<String, Object> prefs = const {},
    Map<String, List<String>> folders = const {},
  }) async {
    SharedPreferences.setMockInitialValues(prefs);
    final db = AppDatabase(NativeDatabase.memory());
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWith((ref) {
          ref.onDispose(db.close);
          return db;
        }),
        downloadManagerProvider.overrideWith((ref) => manager ?? MockDownloadManager()),
        installedGamesIndexProvider.overrideWith(
          (ref) => InstalledGamesIndex(
            lister: (uri) async => [
              for (final name in folders[uri] ?? const <String>[])
                SafDocumentFile(uri: '$uri/$name', name: name, isDir: false, length: 1, lastModified: 0),
            ],
            childLookup: (parentUri, name) async => null,
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    await container.read(settingsProvider.future);

    final catalog = container.read(catalogRepositoryProvider);
    await catalog.upsertManufacturer(ManufacturersCompanion.insert(id: 'nintendo', name: 'Nintendo'));
    await catalog.upsertConsole(ConsolesCompanion.insert(
      id: consoleId,
      name: consoleName,
      manufacturerId: 'nintendo',
      urlsJson: '[]',
    ));

    await container.read(downloadableFileRepositoryProvider).insertFilesWithTags(
      [
        for (final (name, fileName, _) in files)
          DownloadableFilesCompanion.insert(
            name: name,
            fileName: fileName,
            consoleId: consoleId,
            downloadUrl: 'https://example.com/$fileName',
            fileSize: const Value(1000000),
            fileExtension: Value(FileNaming.extensionOf(fileName)),
          ),
      ],
      [for (final (_, _, tags) in files) tags],
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
    when(() => manager.startDownload(any())).thenAnswer((_) async => StartDownloadResult.started);

    await pumpScreen(tester, manager: manager, files: [
      ('Test Game', 'test_game.zip', ['USA']),
    ]);

    expect(find.text('Test Game'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.file_download_outlined));
    await tester.pump();

    final captured = verify(() => manager.startDownload(captureAny())).captured;
    expect(captured, hasLength(1));
    expect((captured.single as DownloadableFileWithTags).fileName, 'test_game.zip');
    expect(find.textContaining('iniciado'), findsOneWidget);
  });

  testWidgets('a game already in its folder says so, whichever region or format is there', (tester) async {
    await pumpScreen(
      tester,
      files: [('Test Game', 'Test Game (USA).zip', ['USA'])],
      prefs: {'download_directory': 'content://roms'},
      folders: {
        'content://roms': ['Test Game (Europe).gba'],
      },
    );

    expect(find.text('Test Game'), findsOneWidget);
    expect(find.text('Já está na pasta'), findsOneWidget);
  });

  testWidgets('a game that is not in the folder has no badge', (tester) async {
    await pumpScreen(
      tester,
      files: [('Test Game', 'Test Game (USA).zip', ['USA'])],
      prefs: {'download_directory': 'content://roms'},
      folders: {
        'content://roms': ['Test Game II (USA).gba'],
      },
    );

    expect(find.text('Test Game'), findsOneWidget);
    expect(find.text('Já está na pasta'), findsNothing);
  });

  testWidgets('the badge looks in the console’s own folder when one is set', (tester) async {
    await pumpScreen(
      tester,
      consoleId: 'sony_playstation_2',
      consoleName: 'PlayStation 2',
      files: [('God of War', 'God of War (USA).chd', ['USA'])],
      prefs: {
        'download_directory': 'content://roms',
        'console_download_directories': '{"sony_playstation_2":"content://ROMs/ps2"}',
      },
      folders: {
        'content://roms': const [],
        'content://ROMs/ps2': ['God of War (USA).iso'],
      },
    );

    expect(find.text('Já está na pasta'), findsOneWidget);
  });

  testWidgets('a PS2 archive is labelled by the ISO it unpacks to, with the archive noted', (tester) async {
    await pumpScreen(
      tester,
      consoleId: 'sony_playstation_2',
      consoleName: 'PlayStation 2',
      files: [
        ('God of War', 'God of War (USA).7z', ['USA']),
        ('God of War', 'God of War (Europe).chd', ['Europe']),
      ],
    );

    // One game, expanded on its own because it is the only result: the
    // header lists its formats and each file gets its own row.
    expect(find.text('God of War'), findsOneWidget);
    expect(find.text('ISO'), findsNWidgets(2));
    expect(find.text('em 7Z'), findsOneWidget);
    expect(find.text('7Z'), findsNothing);
  });

  testWidgets('with auto-extraction off, the archive is what is shown', (tester) async {
    await pumpScreen(
      tester,
      consoleId: 'sony_playstation_2',
      consoleName: 'PlayStation 2',
      files: [
        ('God of War', 'God of War (USA).7z', ['USA']),
        ('God of War', 'God of War (Europe).chd', ['Europe']),
      ],
      prefs: {'auto_unzip': false},
    );

    expect(find.text('7Z'), findsNWidgets(2));
    expect(find.text('ISO'), findsNothing);
  });

  testWidgets('inside a game, the file that is already in the folder is marked', (tester) async {
    await pumpScreen(
      tester,
      consoleId: 'sony_playstation_2',
      consoleName: 'PlayStation 2',
      files: [
        ('God of War', 'God of War (USA).7z', ['USA']),
        ('God of War', 'God of War (Europe).chd', ['Europe']),
      ],
      prefs: {'download_directory': 'content://roms'},
      // What the USA .7z unpacked to on an earlier download.
      folders: {
        'content://roms': ['God of War (USA).iso'],
      },
    );

    expect(find.text('Já está na pasta'), findsOneWidget);
    expect(find.text('Na pasta'), findsOneWidget);
  });
}
