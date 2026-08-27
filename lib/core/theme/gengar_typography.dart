import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'gengar_colors.dart';

/// Font pairing for the Gengar design system, matched 1:1 to the reference
/// mockup: Manrope for everything display/body/label, JetBrains Mono for
/// numeric data, timestamps, and the small-caps eyebrow/section labels.
abstract final class GengarTypography {
  static TextTheme textTheme(Color base, Color muted) {
    final manrope = GoogleFonts.manropeTextTheme();

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
    return GoogleFonts.manrope(fontSize: 30, fontWeight: FontWeight.w800, color: color);
  }

  /// Compact header title (Library's back-button row) — 17px/800.
  static TextStyle compactTitle({Color color = GengarColors.onBackground}) {
    return GoogleFonts.manrope(fontSize: 17, fontWeight: FontWeight.w800, color: color);
  }

  /// Eyebrow label above a screen title — 12px/700, letter-spacing .16em,
  /// accent-colored by default (e.g. "CATÁLOGO", "SCRAPING", "FILA").
  static TextStyle eyebrow({Color color = GengarColors.primary}) {
    return GoogleFonts.jetBrainsMono(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      letterSpacing: 12 * 0.16,
      color: color,
    );
  }

  /// Small-caps section header inside a screen — 11.5px/700, letter-spacing
  /// .13em, muted by default (e.g. "ARMAZENAMENTO", "REDE").
  static TextStyle sectionLabel({Color color = GengarColors.textFaint}) {
    return GoogleFonts.jetBrainsMono(
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
    return GoogleFonts.jetBrainsMono(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }
}
