import 'package:flutter/material.dart';
import '../gengar_colors.dart';

/// Gradient-track slider replacing the plain `Slider` for "Limite de
/// velocidade" — gradient fill up to the thumb, translucent-white track
/// past it, white thumb with a soft glow ring.
class GengarGradientSlider extends StatelessWidget {
  const GengarGradientSlider({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final double value;
  final double min;
  final double max;
  final ValueChanged<double>? onChanged;

  double get _fraction => max > min ? ((value - min) / (max - min)).clamp(0.0, 1.0) : 0.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        const thumbSize = 20.0;

        void handle(Offset local) {
          if (onChanged == null) return;
          final f = (local.dx / width).clamp(0.0, 1.0);
          onChanged!(min + f * (max - min));
        }

        return GestureDetector(
          onTapDown: (d) => handle(d.localPosition),
          onHorizontalDragUpdate: (d) => handle(d.localPosition),
          child: SizedBox(
            height: 24,
            width: double.infinity,
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                Container(
                  height: 6,
                  decoration: BoxDecoration(color: GengarColors.progressTrack, borderRadius: BorderRadius.circular(99)),
                ),
                FractionallySizedBox(
                  widthFactor: _fraction,
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(gradient: GengarColors.progressGradient, borderRadius: BorderRadius.circular(99)),
                  ),
                ),
                Positioned(
                  left: (width - thumbSize).clamp(0.0, double.infinity) * _fraction,
                  child: Container(
                    width: thumbSize,
                    height: thumbSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 10, offset: const Offset(0, 3)),
                        BoxShadow(color: GengarColors.primary.withValues(alpha: 0.25), spreadRadius: 4),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
