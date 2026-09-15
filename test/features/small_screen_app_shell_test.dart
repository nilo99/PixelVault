import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixelvault/app.dart';
import 'package:pixelvault/core/db/database.dart';
import 'package:pixelvault/core/models/content_type.dart';
import 'package:pixelvault/core/providers.dart';
import 'package:pixelvault/core/router/scaffold_with_nav_bar.dart';
import 'package:pixelvault/core/security/urls_cipher_holder.dart';
import 'package:pixelvault/core/theme/gengar_metrics.dart';
import 'package:pixelvault/core/theme/gengar_theme.dart';
import 'package:pixelvault/features/language_select/language_select_screen.dart';
import 'package:pixelvault/features/library/library_screen.dart';
import 'package:pixelvault/features/sources/widgets/add_url_dialog.dart';
import 'package:pixelvault/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Companion to `small_screen_layout_test.dart`, which pumps screens in
/// isolation and so never exercises what only exists inside the running app:
/// the floating nav bar, the first-run language picker, an expanded game in
/// the library, and dialogs. These boot the real `PixelVaultApp` where it
/// matters, so `GengarMetricsScope` is the one `app.dart` installs rather
/// than one added by hand.
void main() {
  setUpAll(() => UrlsCipherHolder.initForTest());

  const viewports = <String, Size>{
    'secondary display 240x320': Size(240, 320),
    'secondary display 280x420': Size(280, 420),
    'small handheld 320x480': Size(320, 480),
    'compact phone 360x640': Size(360, 640),
    'reference phone 390x844': Size(390, 844),
  };

  final pt = lookupAppLocalizations(const Locale('pt'));

  void setViewport(WidgetTester tester, Size size) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  /// Runs [body] while capturing full error reports, then fails with the
  /// offending widget's file:line if anything overflowed. See the same
  /// helper in `small_screen_layout_test.dart` for why the capture matters.
  Future<void> expectNoOverflow(
    WidgetTester tester,
    Size size,
    Future<void> Function() body,
  ) async {
    final reports = <String>[];
    final frameworkHandler = FlutterError.onError;
    FlutterError.onError = (details) {
      reports.add(details.toString());
      frameworkHandler?.call(details);
    };
    try {
      await body();
    } finally {
      FlutterError.onError = frameworkHandler;
    }
    expect(
      tester.takeException(),
      isNull,
      reason: 'layout overflowed at ${size.width.toInt()}x${size.height.toInt()}\n\n'
          '${reports.join('\n\n')}',
    );
  }

  /// Bounded frames rather than `pumpAndSettle`, which never settles while a
  /// progress indicator is animating during async catalog loads.
  Future<void> pumpFrames(WidgetTester tester, [int count = 30]) async {
    for (var i = 0; i < count; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<ProviderContainer> buildContainer(Map<String, Object> prefs) async {
    SharedPreferences.setMockInitialValues(prefs);
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
    return container;
  }

  Future<void> seedCatalog(ProviderContainer container, {int variants = 1}) async {
    final catalog = container.read(catalogRepositoryProvider);
    await catalog.upsertManufacturer(
      ManufacturersCompanion.insert(id: 'nintendo', name: 'Nintendo'),
    );
    await catalog.upsertConsole(ConsolesCompanion.insert(
      id: 'gba',
      name: 'Game Boy Advance',
      manufacturerId: 'nintendo',
      urlsJson: '[]',
    ));
    const regions = ['USA', 'Europe', 'Japan'];
    await container.read(downloadableFileRepositoryProvider).insertFilesWithTags(
      [
        for (var i = 0; i < variants; i++)
          DownloadableFilesCompanion.insert(
            name: 'Pokemon Emerald Version',
            fileName: 'Pokemon Emerald Version (${regions[i]}).gba',
            consoleId: 'gba',
            downloadUrl: 'https://example.com/pokemon-$i.gba',
            fileSize: Value(16777216 + i),
            fileExtension: const Value('.gba'),
          ),
      ],
      [
        for (var i = 0; i < variants; i++) <String>[regions[i], 'En'],
      ],
    );
  }

  /// Unmounts the app and lets Drift's stream-query teardown timer fire
  /// before flutter_test checks for pending timers.
  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 50));
  }

  viewports.forEach((label, size) {
    final isTiny = GengarMetrics.fromSize(size).isTiny;

    group('at $label', () {
      testWidgets('first-run language picker renders without overflow', (tester) async {
        setViewport(tester, size);
        final container = await buildContainer({});

        await expectNoOverflow(tester, size, () async {
          await tester.pumpWidget(
            UncontrolledProviderScope(container: container, child: const PixelVaultApp()),
          );
          await pumpFrames(tester);
        });

        expect(find.byType(LanguageSelectScreen), findsOneWidget);
        await unmount(tester);
      });

      testWidgets('app shell with nav bar renders without overflow', (tester) async {
        setViewport(tester, size);
        final container = await buildContainer({'locale_code': 'pt', 'onboarding_completed': true, 'esde_prompt_answered': true});
        await seedCatalog(container);

        await expectNoOverflow(tester, size, () async {
          await tester.pumpWidget(
            UncontrolledProviderScope(container: container, child: const PixelVaultApp()),
          );
          await pumpFrames(tester);
        });

        expect(find.byType(ScaffoldWithGengarNavBar), findsOneWidget);

        // Four labels do not fit a secondary display's width; there the bar
        // is icons only, and everywhere else the labels stay.
        final labelFinder = find.descendant(
          of: find.byType(ScaffoldWithGengarNavBar),
          matching: find.text(pt.navBarSettings),
        );
        expect(labelFinder, isTiny ? findsNothing : findsOneWidget);

        await unmount(tester);
      });

      testWidgets('library with an expanded game renders without overflow', (tester) async {
        setViewport(tester, size);
        final container = await buildContainer({'locale_code': 'pt', 'onboarding_completed': true, 'esde_prompt_answered': true});
        // Three variants of one game collapse into a single group, which the
        // screen expands on its own when it is the only result.
        await seedCatalog(container, variants: 3);

        await expectNoOverflow(tester, size, () async {
          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: container,
              child: MaterialApp(
                locale: const Locale('pt'),
                theme: GengarTheme.dark(),
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                home: const GengarMetricsScope(child: LibraryScreen()),
              ),
            ),
          );
          await pumpFrames(tester, 10);
        });

        final variantRows = find.byWidgetPredicate((widget) {
          final key = widget.key;
          return key is ValueKey<String> && key.value.startsWith('library_variant_');
        });
        expect(variantRows, findsNWidgets(3), reason: 'the group must actually be expanded');
        await unmount(tester);
      });

      testWidgets('add-source dialog renders without overflow', (tester) async {
        setViewport(tester, size);
        final controller = TextEditingController();
        addTearDown(controller.dispose);

        const consoles = [
          Console(id: 'gba', name: 'Game Boy Advance', manufacturerId: 'nintendo', urlsJson: '[]'),
          Console(id: 'snes', name: 'Super Nintendo Entertainment System', manufacturerId: 'nintendo', urlsJson: '[]'),
          Console(id: 'psx', name: 'PlayStation', manufacturerId: 'sony', urlsJson: '[]'),
        ];

        await expectNoOverflow(tester, size, () async {
          await tester.pumpWidget(
            MaterialApp(
              locale: const Locale('pt'),
              theme: GengarTheme.dark(),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: GengarMetricsScope(
                child: Scaffold(
                  body: AddUrlDialog(
                    urlController: controller,
                    contentType: ContentType.game,
                    onContentTypeChanged: (_) {},
                    allConsoles: consoles,
                    selectedConsoleIds: const {'gba'},
                    onToggleConsole: (_) {},
                    onSubmit: () {},
                  ),
                ),
              ),
            ),
          );
          await pumpFrames(tester, 5);
        });

        expect(find.byKey(const Key('add_url_dialog_submit_button')), findsOneWidget);
      });
    });
  });
}
