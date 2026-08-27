
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../db/database.dart';
import '../settings/settings_repository.dart';
import '../theme/gengar_colors.dart';
import '../theme/gengar_components.dart';
import '../../features/about/about_screen.dart';
import '../../features/downloads/downloads_screen.dart';
import '../../features/language_select/language_select_screen.dart';
import '../../features/library/library_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/platform_select/platform_select_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/sources/sources_screen.dart';
import '../../l10n/app_localizations.dart';
import 'scaffold_with_nav_bar.dart';

part 'app_router.g.dart';

/// The `builder` passed to `MaterialApp.router` sits *above* go_router's own
/// Navigator, so a context captured there can't `showDialog`/`Navigator.of`
/// (there's no Navigator ancestor at that point). Code outside the routed
/// widget tree — like `SourceInstallListener`, reacting to a deep link —
/// needs a context that's actually inside the Navigator, which this key
/// provides via `rootNavigatorKey.currentContext`.
final rootNavigatorKey = GlobalKey<NavigatorState>();

@riverpod
GoRouter appRouter(Ref ref) {
  // `select` so the router only rebuilds when these specific fields change —
  // watching the whole `settingsProvider` AsyncValue would recreate the
  // GoRouter (and its `initialLocation`) on every settings mutation (a slider
  // drag, a toggle), kicking the user back to Plataformas from wherever they
  // were.
  final languageChosen = ref.watch(settingsProvider.select((s) => s.value?.localeCode != null));
  final onboardingDone = ref.watch(settingsProvider.select((s) => s.value?.onboardingCompleted ?? false));

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: !languageChosen ? '/language-select' : (onboardingDone ? '/platforms' : '/onboarding'),
    errorBuilder: (context, state) {
      final l10n = AppLocalizations.of(context)!;
      return Scaffold(
        backgroundColor: GengarColors.background,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.routerPageNotFoundTitle,
                  style: const TextStyle(color: GengarColors.onBackground, fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 20),
                GengarPrimaryButton(
                  label: l10n.routerPageNotFoundAction,
                  onPressed: () => context.go('/platforms'),
                ),
              ],
            ),
          ),
        ),
      );
    },
    redirect: (context, state) {
      final goingToLanguageSelect = state.matchedLocation == '/language-select';
      final goingToOnboarding = state.matchedLocation == '/onboarding';
      // Language picker first, then onboarding, then the main app. The
      // onboarding checks below must only apply once a language has been
      // chosen — otherwise a fresh launch bounces language-select ->
      // onboarding -> language-select forever (redirect loop).
      if (!languageChosen) return goingToLanguageSelect ? null : '/language-select';
      if (goingToLanguageSelect) return onboardingDone ? '/platforms' : '/onboarding';
      if (!onboardingDone && !goingToOnboarding) return '/onboarding';
      if (onboardingDone && goingToOnboarding) return '/platforms';
      return null;
    },
    routes: [
      GoRoute(
        path: '/language-select',
        builder: (context, state) => const LanguageSelectScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithGengarNavBar(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/platforms',
                builder: (context, state) => const PlatformSelectScreen(),
                routes: [
                  GoRoute(
                    path: 'library',
                    builder: (context, state) => LibraryScreen(
                      console: state.extra as Console?,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/downloads',
                builder: (context, state) => const DownloadsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/sources',
                builder: (context, state) => const SourcesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsScreen(),
                routes: [
                  GoRoute(
                    path: 'about',
                    builder: (context, state) => const AboutScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
