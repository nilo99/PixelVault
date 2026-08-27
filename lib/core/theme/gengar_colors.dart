import 'package:flutter/material.dart';

/// Raw color values for the PixelVault "Gengar" dark design system.
/// Matches the approved reference mockup 1:1: a near-black violet gradient
/// background with translucent-white card fills (not opaque violet
/// surfaces), a single `#7C5CFF` accent, and a small semantic set for
/// download states.
abstract final class GengarColors {
  // Screen background gradient stops (see GengarScreenBackground).
  static const bgTop = Color(0xFF161D2C);
  static const bgMid = Color(0xFF0C0F16);
  static const bgBottom = Color(0xFF0A0C11);
  static const bgOnboardTop = Color(0xFF1A2138);

  // Flat fallback tone (scaffoldBackgroundColor) — matches the darkest
  // background gradient stop so any unpainted edge still reads correctly.
  static const background = Color(0xFF0A0C11);

  // Elevated/opaque chrome surfaces: dialogs, menus, sheets, snackbars, the
  // bottom nav bar. Distinct from `cardFill` below, which is a translucent
  // white overlay used for in-screen cards, not a solid color.
  static const surface = Color(0xFF141822);
  static const surfaceVariant = Color(0xFF1B2030);
  static const navFill = Color(0xFF141622);

  // Brand
  static const primary = Color(0xFF7C5CFF);
  static const primaryContainer = Color(0xFF3D2E85);
  static const accentLight = Color(0xFFC3B6FF);
  static const activeTabPill = Color(0x297C5CFF); // rgba(124,92,255,.16)

  // Semantic (download/sync states)
  static const error = Color(0xFFFF6B6B);
  static const errorText = Color(0xFFFF8A8A);
  static const success = Color(0xFF35D0A0);
  static const warning = Color(0xFFFFAB5C);
  static const info = Color(0xFF5FD0FF);
  static const infoLight = Color(0xFF7FD8FF);

  // Text / on-colors
  static const onBackground = Color(0xFFF2F3F8);
  static const onBackgroundMuted = Color(0xFF98A0B3);
  // Lightened from the original #6B7488 to clear WCAG AA (4.5:1) against both
  // `background`/`bgBottom` (~5.26:1) and `surface` (~4.77:1) — the two
  // backgrounds this token is actually used against (hint text, section
  // labels, small settings labels).
  static const textFaint = Color(0xFF7B84A0);
  static const onPrimary = Color(0xFFFFFFFF);

  // Card "material": a translucent WHITE overlay on the dark background,
  // not a tinted opaque surface — this is why it's a separate token from
  // `surface` above. [cardFillOpacity] is the single place that controls how
  // visible cards are; every card in the app should read this instead of
  // hardcoding its own alpha, so "make cards more/less opaque" is a one-line
  // change instead of hunting down every call site.
  static const cardFill = Color(0xFFFFFFFF);
  static const cardFillOpacity = 0.1;
  static const cardBorder = Color(0x12FFFFFF); // rgba(255,255,255,.07)
  static const borderSubtle = Color(0x0DFFFFFF); // rgba(255,255,255,.05)
  static const progressTrack = Color(0x17FFFFFF); // rgba(255,255,255,.09)

  // Gradients
  static const ctaGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, Color(0xFF5B6BFF)],
  );
  static const progressGradient = LinearGradient(
    colors: [primary, Color(0xFF6F8BFF)],
  );

  // Glow
  static const glowSoft = Color(0x557C5CFF);
  static const glowStrong = Color(0x807C5CFF);
}
