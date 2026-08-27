import 'package:flutter/material.dart';
import '../gengar_colors.dart';
import '../gengar_typography.dart';

enum GengarFilterChipStyle {
  /// Solid accent fill — the "Filtros" trigger chip.
  solid,

  /// Accent-tinted removable pill for a currently-active filter.
  active,

  /// Ambient unselected chip (e.g. "Formato").
  ghost,
}

/// The Library screen's filter chip, in 3 visual variants matching the
/// mockup's "Filtros" trigger / active removable pills / ghost "Formato".
class GengarFilterChip extends StatelessWidget {
  const GengarFilterChip({
    super.key,
    required this.label,
    this.style = GengarFilterChipStyle.ghost,
    this.count,
    this.icon,
    this.onTap,
    this.onRemove,
  });

  final String label;
  final GengarFilterChipStyle style;
  final int? count;
  final IconData? icon;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(11);
    final Color bg;
    final Color fg;
    final Border? border;
    switch (style) {
      case GengarFilterChipStyle.solid:
        bg = GengarColors.primary;
        fg = GengarColors.onPrimary;
        border = null;
      case GengarFilterChipStyle.active:
        bg = GengarColors.primary.withValues(alpha: 0.14);
        fg = GengarColors.accentLight;
        border = Border.all(color: GengarColors.primary.withValues(alpha: 0.35));
      case GengarFilterChipStyle.ghost:
        bg = GengarColors.cardFill.withValues(alpha: 0.04);
        fg = GengarColors.onBackgroundMuted;
        border = Border.all(color: GengarColors.cardBorder);
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 11),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: radius,
            border: border,
            boxShadow: style == GengarFilterChipStyle.solid
                ? [BoxShadow(color: GengarColors.primary.withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 6))]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: fg),
                const SizedBox(width: 7),
              ],
              Text(label, style: GengarTypography.monoAccent(fontSize: 12.5, fontWeight: FontWeight.w600, color: fg)),
              if (count != null) ...[
                const SizedBox(width: 6),
                Container(
                  height: 18,
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: fg.withValues(alpha: 0.28), borderRadius: BorderRadius.circular(9)),
                  child: Text('$count', style: GengarTypography.monoAccent(fontSize: 10, fontWeight: FontWeight.w700, color: fg)),
                ),
              ],
              if (onRemove != null) ...[
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: onRemove,
                  child: Icon(Icons.close_rounded, size: 13, color: fg),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
