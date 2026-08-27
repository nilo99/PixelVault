import 'package:flutter/material.dart';
import '../gengar_colors.dart';
import '../gengar_typography.dart';

/// Small stat tile used in the Downloads summary row (Ativos / MB/s total /
/// Na fila): a large mono value plus a muted label underneath.
class GengarStatCard extends StatelessWidget {
  const GengarStatCard({
    super.key,
    required this.value,
    required this.label,
    this.valueColor = GengarColors.primary,
  });

  final String value;
  final String label;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: GengarColors.cardFill.withValues(alpha: GengarColors.cardFillOpacity),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: GengarColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: GengarTypography.monoAccent(fontSize: 20, fontWeight: FontWeight.w600, color: valueColor)),
          const SizedBox(height: 3),
          Text(label, style: const TextStyle(fontSize: 11, color: GengarColors.onBackgroundMuted)),
        ],
      ),
    );
  }
}
