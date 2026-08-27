import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pixelvault/core/settings/settings_repository.dart';
import 'package:pixelvault/features/onboarding/onboarding_screen.dart';
import 'package:pixelvault/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Future<ProviderContainer> pumpScreen(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container.read(settingsProvider.future);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          locale: Locale('pt'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: OnboardingScreen(),
        ),
      ),
    );
    await tester.pump();
    return container;
  }

  testWidgets('renders step 1 with Saltar/Seguinte controls', (tester) async {
    await pumpScreen(tester);

    expect(find.text('PASSO 1 / 4'), findsOneWidget);
    expect(find.text('Saltar'), findsOneWidget);
    expect(find.text('Seguinte'), findsOneWidget);
  });

  testWidgets('tapping "Saltar" completes onboarding immediately', (tester) async {
    final container = await pumpScreen(tester);
    expect(container.read(settingsProvider).value?.onboardingCompleted, isFalse);

    await tester.tap(find.text('Saltar'));
    await tester.pump();

    expect(container.read(settingsProvider).value?.onboardingCompleted, isTrue);
  });

  testWidgets('tapping "Seguinte" 3 times reaches the last step, which shows "Começar"', (tester) async {
    await pumpScreen(tester);

    for (var step = 1; step < 4; step++) {
      expect(find.text('PASSO $step / 4'), findsOneWidget);
      await tester.tap(find.text('Seguinte'));
      await tester.pumpAndSettle();
    }

    expect(find.text('PASSO 4 / 4'), findsOneWidget);
    expect(find.text('Começar'), findsOneWidget);
    expect(find.text('Seguinte'), findsNothing);
  });

  testWidgets('tapping "Começar" on the last step completes onboarding', (tester) async {
    final container = await pumpScreen(tester);

    for (var step = 1; step < 4; step++) {
      await tester.tap(find.text('Seguinte'));
      await tester.pumpAndSettle();
    }
    expect(container.read(settingsProvider).value?.onboardingCompleted, isFalse);

    await tester.tap(find.text('Começar'));
    await tester.pump();

    expect(container.read(settingsProvider).value?.onboardingCompleted, isTrue);
  });
}
