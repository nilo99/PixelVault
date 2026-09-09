import 'package:flutter/material.dart';
import 'gengar_colors.dart';

/// Font pairing for the Gengar design system, matched 1:1 to the reference
/// mockup: Manrope for everything display/body/label, JetBrains Mono for
/// numeric data, timestamps, and the small-caps eyebrow/section labels.
abstract final class GengarTypography {
  /// Bundled font families (see `pubspec.yaml`). These were previously
  /// pulled from fonts.gstatic.com at runtime via `google_fonts`, which
  /// meant an offline first launch silently rendered the whole app in the
  /// system font.
  static const manropeFamily = 'Manrope';
  static const monoFamily = 'JetBrainsMono';

  static TextTheme textTheme(Color base, Color muted) {
    final manrope = ThemeData.dark().textTheme.apply(fontFamily: manropeFamily);

    return manrope
        .apply(
          bodyColor: base,
          displayColor: base,
          decorationColor: base,
        )
        .copyWith(
          titleLarge: manrope.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          titleMedium: manrope.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          titleSmall: manrope.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          bodySmall: manrope.bodySmall?.copyWith(color: muted),
          labelSmall: manrope.labelSmall?.copyWith(color: muted),
        );
  }

  /// Big screen title — 30px/800, e.g. "Plataformas", "Downloads".
  static TextStyle screenTitle({Color color = GengarColors.onBackground}) {
    return TextStyle(fontFamily: manropeFamily, fontSize: 30, fontWeight: FontWeight.w800, color: color);
  }

  /// Compact header title (Library's back-button row) — 17px/800.
  static TextStyle compactTitle({Color color = GengarColors.onBackground}) {
    return TextStyle(fontFamily: manropeFamily, fontSize: 17, fontWeight: FontWeight.w800, color: color);
  }

  /// Eyebrow label above a screen title — 12px/700, letter-spacing .16em,
  /// accent-colored by default (e.g. "CATÁLOGO", "SCRAPING", "FILA").
  static TextStyle eyebrow({Color color = GengarColors.primary}) {
    return TextStyle(fontFamily: monoFamily, 
      fontSize: 12,
      fontWeight: FontWeight.w700,
      letterSpacing: 12 * 0.16,
      color: color,
    );
  }

  /// Small-caps section header inside a screen — 11.5px/700, letter-spacing
  /// .13em, muted by default (e.g. "ARMAZENAMENTO", "REDE").
  static TextStyle sectionLabel({Color color = GengarColors.textFaint}) {
    return TextStyle(fontFamily: monoFamily, 
      fontSize: 11.5,
      fontWeight: FontWeight.w700,
      letterSpacing: 11.5 * 0.13,
      color: color,
    );
  }

  /// General-purpose mono accent for numeric data (sizes, speeds, counts,
  /// paths, timestamps).
  static TextStyle monoAccent({
    double fontSize = 12,
    FontWeight fontWeight = FontWeight.w500,
    Color color = GengarColors.textFaint,
  }) {
    return TextStyle(fontFamily: monoFamily, 
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }
}
