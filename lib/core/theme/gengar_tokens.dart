import 'package:flutter/material.dart';
import 'gengar_colors.dart';

/// Non-color design tokens (radius/glass/glow/motion) for the Gengar theme,
/// exposed to the widget tree via [ThemeExtension] so every screen reads
/// from the same spec instead of hardcoding magic numbers.
@immutable
class GengarTokens extends ThemeExtension<GengarTokens> {
  const GengarTokens({
    required this.radiusSm,
    required this.radiusChip,
    required this.radiusMd,
    required this.radiusLg,
    required this.radiusXl,
    required this.radiusPill,
    required this.glassBlurLow,
    required this.glassBlurMid,
    required this.glassBlurHigh,
    required this.glassOpacityLow,
    required this.glassOpacityMid,
    required this.glassOpacityHigh,
    required this.durationFast,
    required this.durationBase,
    required this.durationSlow,
    required this.curveEnter,
    required this.curveExit,
    required this.curveEmphasis,
    required this.glowSoft,
    required this.glowStrong,
  });

  /// [radiusMd] (14) is the default card radius — most mockup cards sit at
  /// 14-18px. [radiusLg] (20) is reserved for the bottom nav bar and bottom
  /// sheets, which are explicitly 20px in the reference. [glassOpacityLow]/
  /// [glassOpacityMid] are card-fill alphas (~0.035-0.06, translucent white
  /// per the mockup); [glassOpacityHigh] (~0.92) is for opaque-ish chrome
  /// (dialogs/sheets/snackbar), not for cards.
  factory GengarTokens.standard() => const GengarTokens(
        radiusSm: 9,
        radiusChip: 10,
        radiusMd: 14,
        radiusLg: 20,
        radiusXl: 28,
        radiusPill: 999,
        glassBlurLow: 12,
        glassBlurMid: 18,
        glassBlurHigh: 14,
        glassOpacityLow: GengarColors.cardFillOpacity,
        glassOpacityMid: 0.14,
        glassOpacityHigh: 0.92,
        durationFast: Duration(milliseconds: 150),
        durationBase: Duration(milliseconds: 200),
        durationSlow: Duration(milliseconds: 300),
        curveEnter: Curves.easeOutCubic,
        curveExit: Curves.easeInCubic,
        curveEmphasis: Curves.easeOutBack,
        glowSoft: GengarColors.glowSoft,
        glowStrong: GengarColors.glowStrong,
      );

  final double radiusSm;
  final double radiusChip;
  final double radiusMd;
  final double radiusLg;
  final double radiusXl;
  final double radiusPill;

  final double glassBlurLow;
  final double glassBlurMid;
  final double glassBlurHigh;
  final double glassOpacityLow;
  final double glassOpacityMid;
  final double glassOpacityHigh;

  final Duration durationFast;
  final Duration durationBase;
  final Duration durationSlow;
  final Curve curveEnter;
  final Curve curveExit;
  final Curve curveEmphasis;

  final Color glowSoft;
  final Color glowStrong;

  List<BoxShadow> glow({Color? color, double blur = 24, double spread = 0}) {
    return [
      BoxShadow(
        color: color ?? glowSoft,
        blurRadius: blur,
        spreadRadius: spread,
      ),
    ];
  }

  @override
  GengarTokens copyWith() => this;

  @override
  GengarTokens lerp(ThemeExtension<GengarTokens>? other, double t) => this;
}
