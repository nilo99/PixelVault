import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixelvault/app.dart';
import 'package:pixelvault/core/db/database.dart';
import 'package:pixelvault/core/providers.dart';
import 'package:pixelvault/core/router/app_router.dart';
import 'package:pixelvault/core/router/scaffold_with_nav_bar.dart';
import 'package:pixelvault/features/esde_setup/esde_setup_screen.dart';
import 'package:pixelvault/features/language_select/language_select_screen.dart';
import 'package:pixelvault/features/onboarding/onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Covers `app_router.dart`'s `redirect` callback — the exact class of bug
/// that caused a real production crash this session (`GoException: redirect
/// loop detected /onboarding => /language-select => /onboarding`, thrown when
/// the onboarding-gate checks weren't short-circuited behind
/// `languageChosen`). None of this had any test coverage before.
void main() {

  Future<ProviderContainer> pumpApp(
    WidgetTester tester, {
    String? localeCode,
    bool onboardingCompleted = false,
    // Most of these cases are about the steps before it, so the ES-DE
    // question counts as answered unless a test says otherwise.
    bool esdePromptAnswered = true,
  }) async {
    SharedPreferences.setMockInitialValues({
      'locale_code': ?localeCode,
      'onboarding_completed': onboardingCompleted,
      'esde_prompt_answered': esdePromptAnswered,
    });
    final db = AppDatabase(NativeDatabase.memory());
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWith((ref) {
          ref.onDispose(db.close);
          return db;
        }),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const PixelVaultApp(),
      ),
    );
    // pumpAndSettle would spin forever while a CircularProgressIndicator is
    // showing (e.g. during the async catalog-seeding FutureProvider), so
    // pump a bounded number of frames instead — same pattern as widget_test.dart.
    await pumpFrames(tester, 30);
    return container;
  }

  /// Navigates the already-pumped app to [location] and lets redirects settle.
  Future<void> goTo(WidgetTester tester, ProviderContainer container, String location) async {
    container.read(appRouterProvider).go(location);
    await pumpFrames(tester, 10, const Duration(milliseconds: 50));
  }

  /// Disposes the widget tree before the test's automatic "no pending
  /// timers" invariant check runs, so the Drift stream query's teardown
  /// timer has a chance to fire first — same pattern as widget_test.dart.
  Future<void> finish(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 50));
  }

  group('initial boot destination (state matrix)', () {
    testWidgets('no locale, onboarding not done -> language select', (tester) async {
      await pumpApp(tester);
      expect(find.byType(LanguageSelectScreen), findsOneWidget);
      expect(find.textContaining('GoException'), findsNothing);
      await finish(tester);
    });

    testWidgets('locale chosen, onboarding not done -> onboarding', (tester) async {
      await pumpApp(tester, localeCode: 'pt');
      expect(find.byType(OnboardingScreen), findsOneWidget);
      expect(find.byType(LanguageSelectScreen), findsNothing);
      await finish(tester);
    });

    testWidgets('locale chosen, onboarding done -> main app shell (platforms)', (tester) async {
      await pumpApp(tester, localeCode: 'pt', onboardingCompleted: true);
      expect(find.byType(ScaffoldWithGengarNavBar), findsOneWidget);
      expect(find.byType(LanguageSelectScreen), findsNothing);
      expect(find.byType(OnboardingScreen), findsNothing);
      await finish(tester);
    });

    testWidgets('no locale, onboarding already marked done -> language select still wins', (tester) async {
      // Edge case: the language gate must take priority over onboarding
      // regardless of onboardingCompleted's value.
      await pumpApp(tester, onboardingCompleted: true);
      expect(find.byType(LanguageSelectScreen), findsOneWidget);
      await finish(tester);
    });
  });

  group('explicit navigation attempts are redirected without looping', () {
    testWidgets('no locale: trying to reach /onboarding bounces back to /language-select', (tester) async {
      final container = await pumpApp(tester);
      await goTo(tester, container, '/onboarding');
      expect(find.byType(LanguageSelectScreen), findsOneWidget);
      expect(find.textContaining('GoException'), findsNothing);
      await finish(tester);
    });

    testWidgets('no locale: trying to reach /platforms bounces back to /language-select', (tester) async {
      final container = await pumpApp(tester);
      await goTo(tester, container, '/platforms');
      expect(find.byType(LanguageSelectScreen), findsOneWidget);
      await finish(tester);
    });

    testWidgets('locale+onboarding done: trying to reach /language-select bounces to /platforms', (tester) async {
      final container = await pumpApp(tester, localeCode: 'pt', onboardingCompleted: true);
      await goTo(tester, container, '/language-select');
      expect(find.byType(ScaffoldWithGengarNavBar), findsOneWidget);
      await finish(tester);
    });

    testWidgets('locale+onboarding done: trying to reach /onboarding bounces to /platforms', (tester) async {
      final container = await pumpApp(tester, localeCode: 'pt', onboardingCompleted: true);
      await goTo(tester, container, '/onboarding');
      expect(find.byType(ScaffoldWithGengarNavBar), findsOneWidget);
      await finish(tester);
    });

    testWidgets('locale chosen, onboarding not done: trying to reach /platforms bounces to /onboarding', (tester) async {
      final container = await pumpApp(tester, localeCode: 'pt');
      await goTo(tester, container, '/platforms');
      expect(find.byType(OnboardingScreen), findsOneWidget);
      await finish(tester);
    });
  });

  group('the ES-DE question, after onboarding', () {
    testWidgets('onboarding done but the question unanswered -> ES-DE setup', (tester) async {
      await pumpApp(tester, localeCode: 'pt', onboardingCompleted: true, esdePromptAnswered: false);
      expect(find.byType(EsDeSetupScreen), findsOneWidget);
      expect(find.byType(ScaffoldWithGengarNavBar), findsNothing);
      await finish(tester);
    });

    testWidgets('skipping onboarding leads to the question, not straight into the app', (tester) async {
      await pumpApp(tester, localeCode: 'pt', esdePromptAnswered: false);
      await tester.tap(find.text('Saltar'));
      await pumpFrames(tester, 20);

      expect(find.byType(EsDeSetupScreen), findsOneWidget);
      await finish(tester);
    });

    testWidgets('the app is unreachable until the question is answered', (tester) async {
      final container = await pumpApp(tester, localeCode: 'pt', onboardingCompleted: true, esdePromptAnswered: false);
      await goTo(tester, container, '/platforms');
      expect(find.byType(EsDeSetupScreen), findsOneWidget);
      await finish(tester);
    });

    testWidgets('"not now" goes on to the app, and the question is not asked again', (tester) async {
      final container = await pumpApp(tester, localeCode: 'pt', onboardingCompleted: true, esdePromptAnswered: false);

      await tester.tap(find.byKey(const Key('esde_setup_skip_button')));
      await pumpFrames(tester, 20);
      expect(find.byType(ScaffoldWithGengarNavBar), findsOneWidget);

      await goTo(tester, container, '/esde-setup');
      expect(find.byType(EsDeSetupScreen), findsNothing);
      expect(find.byType(ScaffoldWithGengarNavBar), findsOneWidget);
      await finish(tester);
    });
  });

  testWidgets(
    'regression: fresh launch with no locale never loops between /language-select and /onboarding',
    (tester) async {
      // This is the exact scenario that used to throw "GoException: redirect
      // loop detected /onboarding => /language-select => /onboarding" before
      // the redirect callback's onboarding checks were gated behind
      // `languageChosen`.
      await pumpApp(tester);
      expect(find.textContaining('GoException'), findsNothing);
      expect(find.textContaining('Page Not Found'), findsNothing);
      expect(find.byType(LanguageSelectScreen), findsOneWidget);
      await finish(tester);
    },
  );
}

Future<void> pumpFrames(
  WidgetTester tester,
  int count, [
  Duration step = const Duration(milliseconds: 100),
]) async {
  for (var i = 0; i < count; i++) {
    await tester.pump(step);
  }
}
