import 'package:flutter/material.dart';
import '../gengar_colors.dart';

/// Gradient-filled toggle switch replacing `Switch`/`SwitchListTile` on the
/// Definições screen — a plain `SwitchThemeData` can't express a two-tone
/// gradient track, so this is a small bespoke widget instead.
class GengarGradientToggle extends StatelessWidget {
  const GengarGradientToggle({super.key, required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onChanged == null ? null : () => onChanged!(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        width: 46,
        height: 27,
        padding: const EdgeInsets.all(2.5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(99),
          gradient: value ? GengarColors.ctaGradient : null,
          color: value ? null : GengarColors.cardFill.withValues(alpha: 0.09),
          boxShadow: value
              ? [BoxShadow(color: GengarColors.primary.withValues(alpha: 0.45), blurRadius: 12, offset: const Offset(0, 4))]
              : null,
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 22,
            height: 22,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
