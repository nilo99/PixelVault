import 'package:flutter/material.dart';
import '../gengar_colors.dart';
import '../gengar_typography.dart';

/// Circular download-progress ring with a glowing arc. The center label and
/// ring color are state-aware per the mockup (percentage while downloading,
/// a short abbreviation like "ZIP"/"SD" while extracting/copying, "✓" when
/// complete, "!" when failed, "…" when queued) — the caller computes both
/// from its own status enum so this theme-layer widget stays feature-agnostic.
class GengarProgressRing extends StatelessWidget {
  const GengarProgressRing({
    super.key,
    required this.progress,
    this.size = 48,
    this.strokeWidth = 4,
    this.centerLabel,
    this.ringColor = GengarColors.primary,
  });

  /// 0.0..1.0, or null for indeterminate.
  final double? progress;
  final double size;
  final double strokeWidth;
  final String? centerLabel;
  final Color ringColor;

  @override
  Widget build(BuildContext context) {
    final label = centerLabel ?? (progress != null ? '${(progress! * 100).round()}%' : null);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: ringColor.withValues(alpha: 0.35), blurRadius: size * 0.4),
              ],
            ),
          ),
          CircularProgressIndicator(
            value: progress,
            strokeWidth: strokeWidth,
            backgroundColor: GengarColors.progressTrack,
            valueColor: AlwaysStoppedAnimation(ringColor),
          ),
          if (label != null)
            Text(
              label,
              style: GengarTypography.monoAccent(fontSize: size * 0.22, fontWeight: FontWeight.w600, color: ringColor),
            ),
        ],
      ),
    );
  }
}
