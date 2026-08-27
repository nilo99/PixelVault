import 'package:flutter/material.dart';

/// Styled manufacturer wordmark, matching the mockup's plain-text brand
/// treatment (not real trademarked logo art): Nintendo/Sony/Sega get their
/// exact brand color/weight/style, any other manufacturer falls back to a
/// generic bold dark label — the app supports arbitrary manufacturers.
class GengarWordmark extends StatelessWidget {
  const GengarWordmark({super.key, required this.name, this.fontSize = 15});

  final String name;
  final double fontSize;

  static const Map<String, TextStyle> _styles = {
    'nintendo': TextStyle(color: Color(0xFFE60012), fontWeight: FontWeight.w800),
    'sony': TextStyle(color: Color(0xFF111111), fontWeight: FontWeight.w800, letterSpacing: 2),
    'sega': TextStyle(
      color: Color(0xFF0060A8),
      fontWeight: FontWeight.w800,
      fontStyle: FontStyle.italic,
      letterSpacing: 1,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final style = _styles[name.trim().toLowerCase()];
    return Text(
      style != null ? name.toUpperCase() : name,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
      style: (style ?? const TextStyle(color: Color(0xFF222222), fontWeight: FontWeight.w800))
          .copyWith(fontSize: fontSize),
    );
  }
}
