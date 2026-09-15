import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/diagnostics/diagnostics_log.dart';
import '../../core/providers.dart';
import '../../core/settings/settings_repository.dart';
import '../../core/storage/esde_configurator.dart';
import '../../core/theme/gengar_colors.dart';
import '../../core/theme/gengar_components.dart';
import '../../core/theme/gengar_metrics.dart';
import '../../core/theme/gengar_typography.dart';
import '../../l10n/app_localizations.dart';

/// What ES-DE setup did, as one sentence for a snackbar.
String esDeSetupSummary(AppLocalizations l10n, EsDeSetupResult result) {
  final configured = l10n.esdeSetupDone(result.consoleFolders.length);
  if (result.createdFolders.isEmpty) return configured;
  return '$configured ${l10n.esdeSetupCreatedFolders(result.createdFolders.length)}';
}

/// Asked once, right after onboarding: "do you already have ES-DE's ROMs
/// folder on this device?"
///
/// Many people downloading games on a handheld keep them in the ES-DE layout
/// (https://github.com/retrogamecorps/ES-DE-Directories), one folder per
/// system. Picking that folder here points every supported console at its
/// own subfolder, instead of the user setting a dozen folders by hand in
/// Settings. Either answer is final; Settings can run the setup again.
class EsDeSetupScreen extends ConsumerStatefulWidget {
  const EsDeSetupScreen({super.key});

  @override
  ConsumerState<EsDeSetupScreen> createState() => _EsDeSetupScreenState();
}

class _EsDeSetupScreenState extends ConsumerState<EsDeSetupScreen> {
  bool _busy = false;
  String? _error;

  Future<void> _pickRomsFolder() async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final service = ref.read(esDeSetupServiceProvider);
    final settings = ref.read(settingsProvider.notifier);
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final result = await service.run();
      if (result == null) {
        if (mounted) setState(() => _busy = false);
        return;
      }
      messenger.showSnackBar(SnackBar(content: Text(esDeSetupSummary(l10n, result))));
      // Answering is what moves the router on to the app.
      await settings.setEsdePromptAnswered(true);
    } on NotAnEsDeRomsFolderException {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = l10n.esdeSetupNotEsde;
      });
    } catch (error, stack) {
      Diagnostics.record('esde', 'setup failed: $error', stack);
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = l10n.esdeSetupFailed;
      });
    }
  }

  Future<void> _skip() => ref.read(settingsProvider.notifier).setEsdePromptAnswered(true);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final metrics = GengarMetrics.of(context);
    final iconBox = metrics.isTiny ? 40.0 : 52.0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GengarScreenBackground(
        isOnboarding: true,
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(metrics.gutter, metrics.gap(28), metrics.gutter, metrics.gap(16)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: iconBox,
                        height: iconBox,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: GengarColors.primary.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: GengarColors.primary.withValues(alpha: 0.32)),
                        ),
                        child: Icon(
                          Icons.folder_special_rounded,
                          size: iconBox / 2,
                          color: GengarColors.accentLight,
                        ),
                      ),
                      SizedBox(height: metrics.gap(20)),
                      Text(
                        l10n.esdeSetupTitle,
                        style: TextStyle(
                          fontFamily: GengarTypography.manropeFamily,
                          fontSize: metrics.isTiny ? 20 : 26,
                          fontWeight: FontWeight.w800,
                          color: GengarColors.onBackground,
                          height: 1.15,
                        ),
                      ),
                      SizedBox(height: metrics.gap(12)),
                      Text(
                        l10n.esdeSetupBody,
                        style: TextStyle(
                          fontFamily: GengarTypography.manropeFamily,
                          fontSize: metrics.isTiny ? 12.5 : 14,
                          color: GengarColors.onBackgroundMuted,
                          height: 1.55,
                        ),
                      ),
                      SizedBox(height: metrics.gap(18)),
                      const _FolderLayoutPreview(),
                      if (_error != null) ...[
                        SizedBox(height: metrics.gap(16)),
                        Text(
                          _error!,
                          key: const Key('esde_setup_error'),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: GengarColors.errorText,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(metrics.gutter, metrics.gap(8), metrics.gutter, metrics.gap(20)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_busy)
                      const SizedBox(
                        height: 48,
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else
                      GengarPrimaryButton(
                        key: const Key('esde_setup_pick_button'),
                        label: l10n.esdeSetupPickButton,
                        icon: Icons.folder_open_rounded,
                        onPressed: _pickRomsFolder,
                      ),
                    SizedBox(height: metrics.gap(6)),
                    TextButton(
                      key: const Key('esde_setup_skip_button'),
                      onPressed: _busy ? null : _skip,
                      child: Text(
                        l10n.esdeSetupSkipButton,
                        style: const TextStyle(fontWeight: FontWeight.w600, color: GengarColors.onBackgroundMuted),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A glimpse of the layout being asked about, so "the ES-DE ROMs folder" is
/// recognisable at a glance.
class _FolderLayoutPreview extends StatelessWidget {
  const _FolderLayoutPreview();

  static const _sample = ['psx', 'ps2', 'psp', 'n3ds', 'nds', 'gba', 'snes', 'dreamcast', '…'];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: GengarColors.cardFill.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: GengarColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.folder_rounded, size: 15, color: GengarColors.accentLight),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  'ES-DE/ROMs',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GengarTypography.monoAccent(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: GengarColors.onBackground,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final name in _sample)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: GengarColors.primary.withValues(alpha: 0.10),
                    border: Border.all(color: GengarColors.primary.withValues(alpha: 0.24)),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    name,
                    style: GengarTypography.monoAccent(fontSize: 10, color: GengarColors.accentLight),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
