import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/settings/settings_repository.dart';
import '../../core/theme/gengar_colors.dart';
import '../../core/theme/gengar_components.dart';
import '../../core/theme/gengar_tokens.dart';
import '../../core/theme/gengar_typography.dart';
import '../../l10n/app_localizations.dart';

/// Data model for each onboarding step.
class _OnboardingStep {
  const _OnboardingStep({
    required this.title,
    required this.description,
    this.highlightedWords = const [],
  });

  final String title;
  final String description;
  final List<String> highlightedWords;
}

List<_OnboardingStep> _buildSteps(AppLocalizations l10n) => [
      _OnboardingStep(
        title: l10n.onboardingStep1Title,
        description: l10n.onboardingStep1Description,
        highlightedWords: [l10n.onboardingStep1Highlight1, l10n.onboardingStep1Highlight2],
      ),
      _OnboardingStep(
        title: l10n.onboardingStep2Title,
        description: l10n.onboardingStep2Description,
        highlightedWords: [l10n.onboardingStep2Highlight1, l10n.onboardingStep2Highlight2],
      ),
      _OnboardingStep(
        title: l10n.onboardingStep3Title,
        description: l10n.onboardingStep3Description,
        highlightedWords: [l10n.onboardingStep3Highlight1, l10n.onboardingStep3Highlight2],
      ),
      _OnboardingStep(
        title: l10n.onboardingStep4Title,
        description: l10n.onboardingStep4Description,
        highlightedWords: [l10n.onboardingStep4Highlight1],
      ),
    ];

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage(int totalSteps) {
    if (_currentPage < totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _completeOnboarding() {
    ref.read(settingsProvider.notifier).setOnboardingCompleted(true);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<GengarTokens>() ?? GengarTokens.standard();
    final l10n = AppLocalizations.of(context)!;
    final steps = _buildSteps(l10n);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GengarScreenBackground(
        isOnboarding: true,
        child: SafeArea(
        child: Column(
          children: [
            // ─── Top bar: icon + PIXELVAULT + Saltar ───
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  // Small app icon
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      'assets/PixelVault.png',
                      width: 30,
                      height: 30,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Text(
                    'PIXELVAULT',
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: GengarColors.onBackground,
                      letterSpacing: 12 * 0.12,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _completeOnboarding,
                    child: Text(
                      l10n.onboardingSkip,
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: GengarColors.onBackgroundMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ─── Page content ───
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemCount: steps.length,
                itemBuilder: (context, index) {
                  return _OnboardingPage(
                    step: steps[index],
                    stepIndex: index,
                    totalSteps: steps.length,
                  );
                },
              ),
            ),

            // ─── Bottom: dots + button ───
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Page dots
                  Row(
                    children: List.generate(steps.length, (index) {
                      final isActive = index == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutCubic,
                        margin: const EdgeInsets.only(right: 7),
                        width: isActive ? 22 : 7,
                        height: 7,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(99),
                          gradient: isActive ? GengarColors.ctaGradient : null,
                          color: isActive ? null : Colors.white.withValues(alpha: 0.16),
                        ),
                      );
                    }),
                  ),

                  // "Seguinte →" / "Começar" button
                  GestureDetector(
                    onTap: () => _nextPage(steps.length),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      decoration: BoxDecoration(
                        gradient: GengarColors.ctaGradient,
                        borderRadius: BorderRadius.circular(tokens.radiusMd),
                        boxShadow: [
                          BoxShadow(
                            color: GengarColors.primary.withValues(alpha: 0.5),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _currentPage == steps.length - 1 ? l10n.onboardingStart : l10n.onboardingNext,
                            style: GoogleFonts.manrope(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: GengarColors.onPrimary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            color: GengarColors.onPrimary,
                            size: 19,
                          ),
                        ],
                      ),
                    ),
                  ),
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

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({
    required this.step,
    required this.stepIndex,
    required this.totalSteps,
  });

  final _OnboardingStep step;
  final int stepIndex;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),

          Container(
            height: 260,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: GengarColors.primary.withValues(alpha: 0.22)),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  GengarColors.primary.withValues(alpha: 0.22),
                  const Color(0xFF5B6BFF).withValues(alpha: 0.04),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.6, 1.0],
              ),
            ),
            padding: const EdgeInsets.all(20),
            child: Center(
              child: Image.asset(
                'assets/PixelVault.png',
                height: 180,
                fit: BoxFit.contain,
              ),
            ),
          ),

          const SizedBox(height: 26),

          // ─── Step indicator ───
          Text(
            l10n.onboardingStepCounter(stepIndex + 1, totalSteps),
            style: GengarTypography.eyebrow(color: GengarColors.primary),
          ),

          const SizedBox(height: 12),

          // ─── Title ───
          Text(
            step.title,
            style: GoogleFonts.manrope(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: GengarColors.onBackground,
              height: 1.15,
              letterSpacing: -0.2,
            ),
          ),

          const SizedBox(height: 16),

          // ─── Description with highlighted words ───
          _buildDescription(step.description, step.highlightedWords),
        ],
      ),
    );
  }

  Widget _buildDescription(String text, List<String> highlights) {
    if (highlights.isEmpty) {
      return Text(
        text,
        style: GoogleFonts.manrope(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: GengarColors.onBackgroundMuted,
          height: 1.6,
        ),
      );
    }

    // Build a RichText with highlighted words
    final spans = <TextSpan>[];
    var remaining = text;

    while (remaining.isNotEmpty) {
      // Find the earliest highlight in the remaining text
      int? earliestIndex;
      String? earliestWord;
      for (final word in highlights) {
        final idx = remaining.indexOf(word);
        if (idx >= 0 && (earliestIndex == null || idx < earliestIndex)) {
          earliestIndex = idx;
          earliestWord = word;
        }
      }

      if (earliestIndex == null || earliestWord == null) {
        // No more highlights, add the rest as normal text
        spans.add(TextSpan(text: remaining));
        break;
      }

      // Add text before the highlight
      if (earliestIndex > 0) {
        spans.add(TextSpan(text: remaining.substring(0, earliestIndex)));
      }

      // Add the highlighted word
      spans.add(TextSpan(
        text: earliestWord,
        style: GoogleFonts.manrope(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: GengarColors.accentLight,
          height: 1.6,
        ),
      ));

      remaining = remaining.substring(earliestIndex + earliestWord.length);
    }

    return RichText(
      text: TextSpan(
        style: GoogleFonts.manrope(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: GengarColors.onBackgroundMuted,
          height: 1.6,
        ),
        children: spans,
      ),
    );
  }
}
