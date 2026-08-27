import 'package:flutter/material.dart';
import '../gengar_colors.dart';
import '../gengar_typography.dart';

/// Small accent-colored eyebrow above a screen title, e.g. "CATÁLOGO".
class GengarEyebrowLabel extends StatelessWidget {
  const GengarEyebrowLabel(this.text, {super.key, this.color = GengarColors.primary});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Text(text, style: GengarTypography.eyebrow(color: color));
}

/// Small-caps muted section header inside a screen, e.g. "ARMAZENAMENTO".
class GengarSectionLabel extends StatelessWidget {
  const GengarSectionLabel(this.text, {super.key, this.color = GengarColors.textFaint});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Text(text, style: GengarTypography.sectionLabel(color: color));
}
