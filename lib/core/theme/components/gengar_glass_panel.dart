import 'dart:ui';

import 'package:flutter/material.dart';
import '../gengar_colors.dart';
import '../gengar_tokens.dart';

/// Reusable card surface. Most mockup cards are a plain translucent-white
/// fill with no blur (cheap, flat); only the bottom nav bar / dialogs want
/// an actual frosted-glass blur behind them — pass [useBlur] for those.
class GengarGlassPanel extends StatelessWidget {
  const GengarGlassPanel({
    super.key,
    required this.child,
    this.borderRadius,
    this.blur,
    this.opacity,
    this.color = GengarColors.cardFill,
    this.borderColor = GengarColors.cardBorder,
    this.glow = false,
    this.useBlur = false,
    this.padding,
  });

  final Widget child;
  final BorderRadius? borderRadius;
  final double? blur;
  final double? opacity;
  final Color color;
  final Color borderColor;
  final bool glow;
  final bool useBlur;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<GengarTokens>() ?? GengarTokens.standard();
    final radius = borderRadius ?? BorderRadius.circular(tokens.radiusMd);

    final inner = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color.withValues(alpha: opacity ?? tokens.glassOpacityLow),
        borderRadius: radius,
        border: Border.fromBorderSide(BorderSide(color: borderColor)),
      ),
      child: child,
    );

    return Container(
      decoration: glow ? BoxDecoration(borderRadius: radius, boxShadow: tokens.glow()) : null,
      child: useBlur
          ? ClipRRect(
              borderRadius: radius,
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: blur ?? tokens.glassBlurMid,
                  sigmaY: blur ?? tokens.glassBlurMid,
                ),
                child: inner,
              ),
            )
          : ClipRRect(borderRadius: radius, child: inner),
    );
  }
}
