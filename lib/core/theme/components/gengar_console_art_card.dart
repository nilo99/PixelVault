import 'package:flutter/material.dart';
import '../console_art_catalog.dart';
import '../gengar_colors.dart';
import '../gengar_typography.dart';

/// Console art card: shows a real product photo from Wikimedia Commons when
/// one is available in [ConsoleArtCatalog.assets], or falls back to the
/// original procedural card (gradient + watermark abbreviation + gamepad icon).
class GengarConsoleArtCard extends StatelessWidget {
  const GengarConsoleArtCard({
    super.key,
    required this.consoleName,
    this.consoleId,
    this.width = 112,
    this.height = 80,
  });

  final String consoleName;
  final String? consoleId;
  final double width;
  final double height;

  String get _watermark {
    final letters = consoleName.replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
    if (letters.isEmpty) return '?';
    return letters.length <= 4 ? letters.toUpperCase() : letters.substring(0, 4).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final assetPath = consoleId != null ? ConsoleArtCatalog.assets[consoleId] : null;

    return Container(
      width: width,
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            GengarColors.primary.withValues(alpha: 0.22),
            GengarColors.primary.withValues(alpha: 0.05),
            Colors.white.withValues(alpha: 0.02),
          ],
          stops: const [0.0, 0.6, 1.0],
        ),
      ),
      child: assetPath != null
          ? Padding(
              padding: const EdgeInsets.all(11.0),
              child: Image.asset(
                assetPath,
                fit: BoxFit.contain,
                alignment: Alignment.center,
                errorBuilder: (_, _, _) => _ProceduralFallback(consoleName: consoleName, watermark: _watermark, height: height),
              ),
            )
          : _ProceduralFallback(consoleName: consoleName, watermark: _watermark, height: height),
    );
  }
}

class _ProceduralFallback extends StatelessWidget {
  const _ProceduralFallback({required this.consoleName, required this.watermark, required this.height});

  final String consoleName;
  final String watermark;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          left: 8,
          right: 8,
          top: 6,
          child: Text(
            consoleName.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GengarTypography.monoAccent(fontSize: 9, fontWeight: FontWeight.w700, color: GengarColors.onBackgroundMuted),
          ),
        ),
        Center(
          child: Text(
            watermark,
            style: TextStyle(
              fontSize: height * 0.62,
              fontWeight: FontWeight.w800,
              height: 1,
              color: GengarColors.onBackground.withValues(alpha: 0.05),
            ),
          ),
        ),
        const Center(
          child: Icon(Icons.sports_esports_rounded, size: 30, color: GengarColors.accentLight),
        ),
      ],
    );
  }
}
