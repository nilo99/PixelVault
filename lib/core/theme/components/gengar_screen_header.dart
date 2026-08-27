import 'package:flutter/material.dart';
import '../gengar_colors.dart';
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
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GengarEyebrowLabel(eyebrow),
                  const SizedBox(height: 4),
                  Text(title, style: GengarTypography.screenTitle()),
                  if (subtitle != null) ...[
                    const SizedBox(height: 6),
                    Text(subtitle!, style: GengarTypography.monoAccent(fontSize: 11)),
                  ],
                ],
              ),
            ),
            if (trailing != null) Padding(padding: const EdgeInsets.only(top: 6), child: trailing),
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
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 20, 0),
        child: Row(
          children: [
            _BackButton(onTap: onBack ?? () => Navigator.of(context).maybePop()),
            const SizedBox(width: 12),
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
                    Text(subtitle!, style: GengarTypography.monoAccent(fontSize: 10.5)),
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(11),
        onTap: onTap,
        child: Container(
          width: 38,
          height: 38,
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
