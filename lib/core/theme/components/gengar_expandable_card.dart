import 'package:flutter/material.dart';
import '../gengar_colors.dart';

/// Card with a custom expand/collapse header, replacing Material's
/// `ExpansionTile` (whose fixed chrome doesn't match the mockup) — used at
/// both nesting levels on the Fontes screen (manufacturer and console rows).
class GengarExpandableCard extends StatefulWidget {
  const GengarExpandableCard({
    super.key,
    required this.header,
    required this.children,
    this.initiallyExpanded = false,
    this.padding,
  });

  /// Builds the always-visible header row; receives whether the card is
  /// currently expanded and a callback to toggle it (e.g. for a chevron
  /// `GestureDetector`, or to make the whole header tappable).
  final Widget Function(BuildContext context, bool expanded, VoidCallback toggle) header;
  final List<Widget> children;
  final bool initiallyExpanded;
  final EdgeInsetsGeometry? padding;

  @override
  State<GengarExpandableCard> createState() => _GengarExpandableCardState();
}

class _GengarExpandableCardState extends State<GengarExpandableCard> {
  late bool _expanded = widget.initiallyExpanded;

  void _toggle() => setState(() => _expanded = !_expanded);

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: GengarColors.cardFill.withValues(alpha: GengarColors.cardFillOpacity),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: GengarColors.cardBorder),
      ),
      child: Column(
        children: [
          widget.header(context, _expanded, _toggle),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            sizeCurve: Curves.easeOutCubic,
            crossFadeState: _expanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
            firstChild: Padding(
              padding: widget.padding ?? const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: widget.children),
            ),
            secondChild: const SizedBox(width: double.infinity, height: 0),
          ),
        ],
      ),
    );
  }
}

/// Rotating chevron for use inside a [GengarExpandableCard] header.
class GengarChevron extends StatelessWidget {
  const GengarChevron({super.key, required this.expanded, this.color = GengarColors.textFaint});

  final bool expanded;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedRotation(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      turns: expanded ? 0.25 : 0,
      child: Icon(Icons.chevron_right_rounded, size: 20, color: color),
    );
  }
}
