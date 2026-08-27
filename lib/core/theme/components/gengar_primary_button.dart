import 'package:flutter/material.dart';
import '../gengar_colors.dart';
import '../gengar_tokens.dart';

/// Primary call-to-action button: the mockup's CTA gradient pill
/// (`#7c5cff → #5b6bff`) with a soft violet glow, not a flat fill.
class GengarPrimaryButton extends StatelessWidget {
  const GengarPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<GengarTokens>() ?? GengarTokens.standard();
    final radius = BorderRadius.circular(tokens.radiusMd);
    final enabled = onPressed != null;

    return Container(
      constraints: const BoxConstraints(minHeight: 48, minWidth: 44),
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: enabled ? GengarColors.ctaGradient : null,
        color: enabled ? null : GengarColors.cardFill.withValues(alpha: tokens.glassOpacityMid),
        boxShadow: enabled ? tokens.glow(color: GengarColors.primary.withValues(alpha: 0.45), blur: 20) : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20, color: GengarColors.onPrimary),
                  const SizedBox(width: 9),
                ],
                Text(
                  label,
                  style: Theme.of(context)
                      .textTheme
                      .labelLarge
                      ?.copyWith(color: GengarColors.onPrimary, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
