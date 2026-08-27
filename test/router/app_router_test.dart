import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pixelvault/app.dart';
import 'package:pixelvault/core/db/database.dart';
import 'package:pixelvault/core/providers.dart';
import 'package:pixelvault/core/router/app_router.dart';
import 'package:pixelvault/core/router/scaffold_with_nav_bar.dart';
import 'package:pixelvault/features/language_select/language_select_screen.dart';
import 'package:pixelvault/features/onboarding/onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Covers `app_router.dart`'s `redirect` callback — the exact class of bug
/// that caused a real production crash this session (`GoException: redirect
/// loop detected /onboarding => /language-select => /onboarding`, thrown when
/// the onboarding-gate checks weren't short-circuited behind
/// `languageChosen`). None of this had any test coverage before.
void main() {
  setUpAll(() {
    // Avoid google_fonts trying to fetch font files over the network during
    // widget tests (no real internet access in the test sandbox).
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Future<ProviderContainer> pumpApp(
    WidgetTester tester, {
    String? localeCode,
    bool onboardingCompleted = false,
  }) async {
    SharedPreferences.setMockInitialValues({
      'locale_code': ?localeCode,
      'onboarding_completed': onboardingCompleted,
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
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    return container;
  }

  /// Navigates the already-pumped app to [location] and lets redirects settle.
  Future<void> goTo(WidgetTester tester, ProviderContainer container, String location) async {
    container.read(appRouterProvider).go(location);
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
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
