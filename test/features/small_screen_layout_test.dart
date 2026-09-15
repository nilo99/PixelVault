import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixelvault/core/db/database.dart';
import 'package:pixelvault/core/download/download_item.dart';
import 'package:pixelvault/core/download/download_progress_tracker.dart';
import 'package:pixelvault/core/download/download_status.dart';
import 'package:pixelvault/core/providers.dart';
import 'package:pixelvault/core/security/urls_cipher_holder.dart';
import 'package:pixelvault/core/theme/gengar_metrics.dart';
import 'package:pixelvault/core/theme/gengar_theme.dart';
import 'package:pixelvault/features/downloads/downloads_screen.dart';
import 'package:pixelvault/features/esde_setup/esde_setup_screen.dart';
import 'package:pixelvault/features/library/library_screen.dart';
import 'package:pixelvault/features/onboarding/onboarding_screen.dart';
import 'package:pixelvault/features/platform_select/platform_select_screen.dart';
import 'package:pixelvault/features/settings/settings_screen.dart';
import 'package:pixelvault/features/sources/sources_screen.dart';
import 'package:pixelvault/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The app is used on handhelds held in portrait, not just phones — the AYN
/// Thor has a small main screen *and* a much smaller secondary display, and
/// the whole design system was drawn against a ~390x780 viewport with every
/// dimension hardcoded. These render each screen at progressively smaller
/// portrait viewports and fail on any layout overflow, which is the failure
/// mode that turns into a black-and-yellow striped bar on the device.
void main() {
  setUpAll(() => UrlsCipherHolder.initForTest());

  /// Portrait viewports worth surviving, smallest first.
  const viewports = <String, Size>{
    'secondary display 240x320': Size(240, 320),
    'secondary display 280x420': Size(280, 420),
    'small handheld 320x480': Size(320, 480),
    'compact phone 360x640': Size(360, 640),
    'reference phone 390x844': Size(390, 844),
  };

  Future<ProviderContainer> buildContainer() async {
    SharedPreferences.setMockInitialValues({'locale_code': 'pt', 'onboarding_completed': true});
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

  /// Renders [child] at [size] and asserts nothing overflowed.
  ///
  /// `GengarMetricsScope` is installed by hand here because these screens are
  /// pumped directly rather than through `PixelVaultApp`.
  Future<void> pumpAt(
    WidgetTester tester,
    Size size,
    ProviderContainer container,
    Widget child,
  ) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    // flutter_test keeps a lone exception for `takeException` without ever
    // printing it, which means a single overflow fails the test with only
    // "overflowed by N pixels" and no hint of *which* Row. Capturing the full
    // error report puts the offending widget's file:line into the failure.
    final reports = <String>[];
    final frameworkHandler = FlutterError.onError;
    FlutterError.onError = (details) {
      reports.add(details.toString());
      frameworkHandler?.call(details);
    };
    try {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            locale: const Locale('pt'),
            theme: GengarTheme.dark(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: GengarMetricsScope(child: child),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    } finally {
      // Must be restored inside the test body: flutter_test fails any test
      // that leaves its own handler replaced.
      FlutterError.onError = frameworkHandler;
    }

    expect(
      tester.takeException(),
      isNull,
      reason: 'layout overflowed at ${size.width.toInt()}x${size.height.toInt()}\n\n'
          '${reports.join('\n\n')}',
    );
  }

  Future<void> seedCatalog(ProviderContainer container) async {
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
    await container.read(downloadableFileRepositoryProvider).insertFilesWithTags(
      [
        DownloadableFilesCompanion.insert(
          name: 'Pokemon Emerald Version',
          fileName: 'Pokemon Emerald Version (USA).gba',
          consoleId: 'gba',
          downloadUrl: 'https://example.com/pokemon.gba',
          fileSize: const Value(16777216),
          fileExtension: const Value('.gba'),
        ),
      ],
      [
        <String>['USA', 'En'],
      ],
    );
  }

  viewports.forEach((label, size) {
    group('at $label', () {
      testWidgets('Plataformas renders without overflow', (tester) async {
        final container = await buildContainer();
        await seedCatalog(container);
        await pumpAt(tester, size, container, const PlatformSelectScreen());
      });

      testWidgets('Biblioteca renders without overflow', (tester) async {
        final container = await buildContainer();
        await seedCatalog(container);
        await pumpAt(tester, size, container, const LibraryScreen());
      });

      testWidgets('Downloads renders without overflow', (tester) async {
        final container = await buildContainer();
        // A tile in every state, so no status-specific row escapes the check.
        final tracker = container.read(downloadProgressTrackerProvider.notifier);
        tracker.addDownload(const DownloadItem(
          id: 1,
          name: 'Pokemon Emerald Version (USA)',
          fileName: 'pokemon.gba',
          fileSize: 16777216,
          progress: 0.42,
          downloadedBytes: 7000000,
        ));
        tracker.addDownload(const DownloadItem(
          id: 2,
          name: 'Final Fantasy VII (Disc 1)',
          fileName: 'ff7.chd',
          fileSize: 700000000,
          status: DownloadStatus.completed,
          destinationLabel: 'primary:Roms/PlayStation',
          savedFileName: 'ff7.chd',
        ));
        await pumpAt(tester, size, container, const DownloadsScreen());
      });

      testWidgets('Fontes renders without overflow', (tester) async {
        final container = await buildContainer();
        await seedCatalog(container);
        await pumpAt(tester, size, container, const SourcesScreen());
      });

      testWidgets('Definições renders without overflow', (tester) async {
        final container = await buildContainer();
        await pumpAt(tester, size, container, const SettingsScreen());
      });

      testWidgets('Onboarding renders without overflow', (tester) async {
        final container = await buildContainer();
        await pumpAt(tester, size, container, const OnboardingScreen());
      });

      testWidgets('ES-DE question renders without overflow', (tester) async {
        final container = await buildContainer();
        await pumpAt(tester, size, container, const EsDeSetupScreen());
      });
    });
  });

  group('GengarMetrics', () {
    test('classifies viewports into density bands', () {
      expect(GengarMetrics.fromSize(const Size(240, 320)).density, GengarDensity.tiny);
      expect(GengarMetrics.fromSize(const Size(360, 640)).density, GengarDensity.compact);
      expect(GengarMetrics.fromSize(const Size(390, 844)).density, GengarDensity.regular);
    });

    test('a wide but very short window is treated as tiny too', () {
      // A secondary display can be short rather than narrow; the chrome has
      // to give way either way.
      expect(GengarMetrics.fromSize(const Size(800, 320)).density, GengarDensity.tiny);
    });

    test('scale follows the tighter axis and stays within bounds', () {
      expect(GengarMetrics.fromSize(const Size(390, 844)).scale, 1.0);
      expect(GengarMetrics.fromSize(const Size(240, 320)).scale, 0.70);
      // Never scales above the reference, so a tablet does not get huge type.
      expect(GengarMetrics.fromSize(const Size(1200, 2000)).scale, 1.0);
    });

    test('gutters shrink but never vanish', () {
      expect(GengarMetrics.fromSize(const Size(240, 320)).gutter, 10.0);
      expect(GengarMetrics.fromSize(const Size(390, 844)).gutter, 20.0);
    });
  });
}
