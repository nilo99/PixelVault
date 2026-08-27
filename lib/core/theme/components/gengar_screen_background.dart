import 'package:flutter/material.dart';
import '../gengar_colors.dart';

/// Solid background behind every screen. `isOnboarding` is kept as a
/// parameter (unused for now) so call sites don't need to change if a
/// bounded, fixed-size decorative accent is added back later.
class GengarScreenBackground extends StatelessWidget {
  const GengarScreenBackground({super.key, required this.child, this.isOnboarding = false});

  final Widget child;
  final bool isOnboarding;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: GengarColors.bgBottom,
      child: child,
    );
  }
}
