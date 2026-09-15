import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pixelvault/core/providers.dart';
import 'package:pixelvault/core/settings/settings_repository.dart';
import 'package:pixelvault/core/storage/esde_configurator.dart';
import 'package:pixelvault/core/storage/esde_setup_service.dart';
import 'package:pixelvault/core/theme/gengar_metrics.dart';
import 'package:pixelvault/features/esde_setup/esde_setup_screen.dart';
import 'package:pixelvault/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockEsDeSetupService extends Mock implements EsDeSetupService {}

void main() {
  Future<ProviderContainer> pumpScreen(WidgetTester tester, EsDeSetupService service) async {
    SharedPreferences.setMockInitialValues({'locale_code': 'pt', 'onboarding_completed': true});
    final container = ProviderContainer(
      overrides: [esDeSetupServiceProvider.overrideWith((ref) => service)],
    );
    addTearDown(container.dispose);
    await container.read(settingsProvider.future);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          locale: Locale('pt'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: GengarMetricsScope(child: EsDeSetupScreen()),
        ),
      ),
    );
    await tester.pump();
    return container;
  }

  bool answered(ProviderContainer container) =>
      container.read(settingsProvider).value?.esdePromptAnswered ?? false;

  testWidgets('"Agora não" answers the question without touching any folder', (tester) async {
    final service = _MockEsDeSetupService();
    final container = await pumpScreen(tester, service);

    await tester.tap(find.byKey(const Key('esde_setup_skip_button')));
    await tester.pump();

    expect(answered(container), isTrue);
    verifyNever(() => service.run());
  });

  testWidgets('a successful setup says what it did and moves on', (tester) async {
    final service = _MockEsDeSetupService();
    when(() => service.run()).thenAnswer((_) async => const EsDeSetupResult(
          romsFolderUri: 'content://ROMs',
          consoleFolders: {
            'sony_playstation': 'content://ROMs/psx',
            'sony_playstation_2': 'content://ROMs/ps2',
          },
          createdFolders: ['ps2'],
        ));
    final container = await pumpScreen(tester, service);

    await tester.tap(find.byKey(const Key('esde_setup_pick_button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.textContaining('2 consolas configuradas'), findsOneWidget);
    expect(find.textContaining('Criada 1 pasta'), findsOneWidget);
    expect(answered(container), isTrue);
  });

  testWidgets('a folder that is not ES-DE says so and keeps the question open', (tester) async {
    final service = _MockEsDeSetupService();
    when(() => service.run()).thenAnswer((_) async => throw const NotAnEsDeRomsFolderException());
    final container = await pumpScreen(tester, service);

    await tester.tap(find.byKey(const Key('esde_setup_pick_button')));
    await tester.pump();

    expect(find.byKey(const Key('esde_setup_error')), findsOneWidget);
    expect(find.textContaining('não parece ser a pasta ROMs'), findsOneWidget);
    expect(answered(container), isFalse);
    // The user can try again with another folder.
    expect(find.byKey(const Key('esde_setup_pick_button')), findsOneWidget);
  });

  testWidgets('closing the picker leaves the question open', (tester) async {
    final service = _MockEsDeSetupService();
    when(() => service.run()).thenAnswer((_) async => null);
    final container = await pumpScreen(tester, service);

    await tester.tap(find.byKey(const Key('esde_setup_pick_button')));
    await tester.pump();

    expect(answered(container), isFalse);
    expect(find.byKey(const Key('esde_setup_error')), findsNothing);
    expect(find.byKey(const Key('esde_setup_pick_button')), findsOneWidget);
  });
}
