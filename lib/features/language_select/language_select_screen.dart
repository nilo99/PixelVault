import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/settings/settings_repository.dart';
import '../../core/theme/gengar_colors.dart';
import '../../core/theme/gengar_typography.dart';
import '../../core/theme/gengar_components.dart';
import '../../core/theme/gengar_metrics.dart';

class SupportedLocale {
  const SupportedLocale({required this.code, required this.ownName});

  /// BCP-47 language code (matches an `app_<code>.arb` file / `Locale(code)`).
  final String code;

  /// The language's own name, in its own language — e.g. "Português" is
  /// shown as itself regardless of which locale is currently active, since
  /// this list is the very thing used to choose that locale in the first
  /// place (see `LanguageSelectScreen` and the settings language switcher).
  final String ownName;
}

const kSupportedLocales = [
  SupportedLocale(code: 'pt', ownName: 'Português'),
  SupportedLocale(code: 'en', ownName: 'English'),
  SupportedLocale(code: 'es', ownName: 'Español'),
  SupportedLocale(code: 'fr', ownName: 'Français'),
  SupportedLocale(code: 'de', ownName: 'Deutsch'),
];

/// First-run language picker, shown before onboarding (gated in
/// `app_router.dart` on `SettingsState.localeCode == null`). Deliberately its
/// own screen rather than a step inside `OnboardingScreen`'s `PageView` — at
/// this point no locale has been chosen yet, so nothing here goes through
/// `AppLocalizations`; every language's own name is shown in that language,
/// and the chrome text below is stacked once per supported language instead
/// of guessing the device's locale.
class LanguageSelectScreen extends ConsumerWidget {
  const LanguageSelectScreen({super.key});

  static const _chromeLines = [
    'Escolhe o teu idioma',
    'Choose your language',
    'Elige tu idioma',
    'Choisis ta langue',
    'Wähle deine Sprache',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metrics = GengarMetrics.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GengarScreenBackground(
        isOnboarding: true,
        child: SafeArea(
          // One scroll view for the whole page rather than a fixed header
          // above an `Expanded` list. The header is five lines of text plus
          // artwork; on a secondary display it alone was taller than the
          // screen, leaving the language list a negative height. This is
          // also the first screen anyone sees, and it flashes briefly on
          // every cold start while settings load.
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  metrics.isTiny ? metrics.gutter : 24,
                  metrics.gap(32),
                  metrics.isTiny ? metrics.gutter : 24,
                  metrics.gap(24),
                ),
                sliver: SliverList.list(
                  children: [
                    // The artwork is decoration; on an auxiliary screen the
                    // five-language prompt is what has to stay visible.
                    if (!metrics.isTiny) ...[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.asset('assets/PixelVault.png', width: 56, height: 56),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Icon(Icons.language_rounded, color: GengarColors.primary, size: 26),
                      ),
                      const SizedBox(height: 10),
                    ],
                    for (final line in _chromeLines)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          line,
                          style: TextStyle(
                            fontFamily: GengarTypography.manropeFamily,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: GengarColors.onBackgroundMuted,
                          ),
                        ),
                      ),
                    SizedBox(height: metrics.gap(28)),
                    for (var index = 0; index < kSupportedLocales.length; index++) ...[
                      if (index > 0) SizedBox(height: metrics.gap(10)),
                      _LanguageRow(
                        key: Key('language_select_option_${kSupportedLocales[index].code}'),
                        locale: kSupportedLocales[index],
                        onTap: () => ref.read(settingsProvider.notifier).setLocale(kSupportedLocales[index].code),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageRow extends StatelessWidget {
  const _LanguageRow({super.key, required this.locale, required this.onTap});

  final SupportedLocale locale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final metrics = GengarMetrics.of(context);
    final inset = metrics.isTiny ? 12.0 : 18.0;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: inset, vertical: inset),
          decoration: BoxDecoration(
            color: GengarColors.cardFill.withValues(alpha: GengarColors.cardFillOpacity),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: GengarColors.cardBorder),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  locale.ownName,
                  style: TextStyle(fontFamily: GengarTypography.manropeFamily, fontSize: 16, fontWeight: FontWeight.w700, color: GengarColors.onBackground),
                ),
              ),
              const Icon(Icons.chevron_right_rounded, size: 20, color: GengarColors.accentLight),
            ],
          ),
        ),
      ),
    );
  }
}
