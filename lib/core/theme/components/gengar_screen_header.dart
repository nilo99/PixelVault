import 'package:flutter/material.dart';
import '../gengar_colors.dart';
import '../gengar_metrics.dart';
import '../gengar_typography.dart';
import 'gengar_labels.dart';

/// Big display header used by Plataformas/Fontes/Downloads/Definições:
/// eyebrow + 30px/800 title + optional mono subtitle + optional trailing
/// action, replacing a default `AppBar`.
class GengarScreenHeader extends StatelessWidget {
  const GengarScreenHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String eyebrow;
  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final metrics = GengarMetrics.of(context);

    // The eyebrow is decoration. On a short screen every line it costs is a
    // line of catalogue the user cannot see, so it is the first thing to go
    // — and the display title drops to the compact size with it.
    final showEyebrow = !metrics.isTiny;
    final titleStyle =
        metrics.isTiny ? GengarTypography.compactTitle() : GengarTypography.screenTitle();

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          metrics.gutter,
          metrics.gap(10),
          metrics.gutter,
          metrics.gap(4),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showEyebrow) ...[
                    GengarEyebrowLabel(eyebrow),
                    SizedBox(height: metrics.gap(4)),
                  ],
                  Text(title, style: titleStyle, maxLines: 1, overflow: TextOverflow.ellipsis),
                  if (subtitle != null) ...[
                    SizedBox(height: metrics.gap(6)),
                    Text(
                      subtitle!,
                      style: GengarTypography.monoAccent(fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null)
              Padding(padding: EdgeInsets.only(top: metrics.gap(6)), child: trailing),
          ],
        ),
      ),
    );
  }
}

/// Compact header used by Biblioteca: back button + single-row title + mono
/// meta, instead of the big display title above.
class GengarCompactHeader extends StatelessWidget {
  const GengarCompactHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onBack,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final metrics = GengarMetrics.of(context);
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          metrics.gap(12),
          metrics.gap(6),
          metrics.gutter,
          0,
        ),
        child: Row(
          children: [
            _BackButton(onTap: onBack ?? () => Navigator.of(context).maybePop()),
            SizedBox(width: metrics.gap(12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GengarTypography.compactTitle(),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: GengarTypography.monoAccent(fontSize: 10.5),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final metrics = GengarMetrics.of(context);
    // Kept at 38 on regular screens; never below 32, which is still a
    // comfortable target on a handheld's d-pad-and-thumb interaction.
    final side = (38.0 * metrics.scale).clamp(32.0, 38.0);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(11),
        onTap: onTap,
        child: Container(
          width: side,
          height: side,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(11),
            color: GengarColors.cardFill.withValues(alpha: 0.05),
            border: Border.all(color: GengarColors.cardBorder),
          ),
          child: const Icon(Icons.arrow_back_ios_new_rounded, size: 17, color: GengarColors.onBackground),
        ),
      ),
    );
  }
}
