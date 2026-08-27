import 'package:flutter/material.dart';
import '../gengar_colors.dart';

/// 6-segment stepped bar selector replacing the plain `Slider` for
/// "Downloads simultâneos" — filled segments use the gradient accent,
/// unfilled ones stay translucent white.
class GengarSteppedSelector extends StatelessWidget {
  const GengarSteppedSelector({
    super.key,
    required this.segmentCount,
    required this.value,
    required this.onChanged,
  });

  /// Total number of segments.
  final int segmentCount;

  /// 1-indexed: how many segments are filled.
  final int value;
  final ValueChanged<int>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(segmentCount, (i) {
        final filled = i < value;
        return Expanded(
          child: GestureDetector(
            onTap: onChanged == null ? null : () => onChanged!(i + 1),
            child: Container(
              height: 8,
              margin: EdgeInsets.only(right: i == segmentCount - 1 ? 0 : 7),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                gradient: filled ? GengarColors.progressGradient : null,
                color: filled ? null : GengarColors.cardFill.withValues(alpha: 0.09),
              ),
            ),
          ),
        );
      }),
    );
  }
}
