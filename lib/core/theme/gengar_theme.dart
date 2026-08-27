import 'package:flutter/material.dart';
import 'gengar_colors.dart';
import 'gengar_tokens.dart';
import 'gengar_typography.dart';

/// Builds the single dark ThemeData used across PixelVault. Dark-only for
/// v1, per the "Gengar" requirement — no light theme branch.
abstract final class GengarTheme {
  static ThemeData dark() {
    final tokens = GengarTokens.standard();

    final colorScheme = const ColorScheme.dark().copyWith(
      brightness: Brightness.dark,
      surface: GengarColors.surface,
      onSurface: GengarColors.onBackground,
      primary: GengarColors.primary,
      onPrimary: GengarColors.onPrimary,
      primaryContainer: GengarColors.primaryContainer,
      secondary: GengarColors.accentLight,
      onSecondary: GengarColors.onPrimary,
      tertiary: GengarColors.primary,
      onTertiary: GengarColors.onPrimary,
      error: GengarColors.error,
      onError: GengarColors.onPrimary,
      outline: GengarColors.cardBorder,
      surfaceContainerHighest: GengarColors.surfaceVariant,
    );

    final textTheme = GengarTypography.textTheme(
      GengarColors.onBackground,
      GengarColors.onBackgroundMuted,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: GengarColors.background,
      colorScheme: colorScheme,
      textTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        foregroundColor: GengarColors.onBackground,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: GengarColors.cardFill.withValues(alpha: tokens.glassOpacityLow),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.radiusMd),
          side: const BorderSide(color: GengarColors.cardBorder),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: GengarColors.cardFill.withValues(alpha: tokens.glassOpacityLow),
        selectedColor: GengarColors.primary,
        labelStyle: textTheme.labelMedium?.copyWith(color: GengarColors.onBackground),
        secondaryLabelStyle: textTheme.labelMedium?.copyWith(color: GengarColors.onPrimary),
        side: const BorderSide(color: GengarColors.cardBorder),
        shape: StadiumBorder(
          side: const BorderSide(color: GengarColors.cardBorder),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: GengarColors.primary,
          foregroundColor: GengarColors.onPrimary,
          elevation: 0,
          minimumSize: const Size(44, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(tokens.radiusMd),
          ),
          textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: GengarColors.onBackground,
          minimumSize: const Size(44, 48),
          side: const BorderSide(color: GengarColors.cardBorder),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(tokens.radiusMd),
          ),
        ),
      ),
      iconTheme: const IconThemeData(color: GengarColors.onBackground),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: GengarColors.cardFill.withValues(alpha: tokens.glassOpacityLow + 0.01),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(tokens.radiusPill),
          borderSide: const BorderSide(color: GengarColors.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(tokens.radiusPill),
          borderSide: const BorderSide(color: GengarColors.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(tokens.radiusPill),
          borderSide: const BorderSide(color: GengarColors.primary, width: 1.5),
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(color: GengarColors.onBackgroundMuted),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: GengarColors.surface.withValues(alpha: tokens.glassOpacityHigh),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.radiusLg),
          side: const BorderSide(color: GengarColors.cardBorder),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: GengarColors.surface.withValues(alpha: tokens.glassOpacityHigh),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(tokens.radiusLg)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: GengarColors.surfaceVariant.withValues(alpha: tokens.glassOpacityHigh),
        contentTextStyle: textTheme.bodyMedium,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.radiusMd),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: GengarColors.primary,
        linearTrackColor: GengarColors.progressTrack,
        circularTrackColor: GengarColors.progressTrack,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? GengarColors.primary
              : Colors.transparent,
        ),
        side: const BorderSide(color: GengarColors.cardBorder, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      ),
      dividerTheme: const DividerThemeData(color: GengarColors.borderSubtle, space: 1),
      extensions: [tokens],
    );
  }
}
