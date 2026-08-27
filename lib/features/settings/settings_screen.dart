import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:saf_util/saf_util.dart';

import '../../core/db/database.dart';
import '../../core/providers.dart';
import '../../core/settings/settings_repository.dart';
import '../../core/theme/gengar_colors.dart';
import '../../core/theme/gengar_components.dart';
import '../../core/theme/gengar_typography.dart';
import '../../l10n/app_localizations.dart';
import '../language_select/language_select_screen.dart' show kSupportedLocales;

/// Global download dir, separate-by-console toggle, speed limit, auto-unzip,
/// concurrency, per-console folders, language — wired to `SettingsNotifier`
/// (shared_preferences-backed).
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _pickDownloadDirectory(WidgetRef ref) async {
    final picked = await SafUtil().pickDirectory(writePermission: true, persistablePermission: true);
    if (picked == null) return;
    await ref.read(settingsProvider.notifier).setDownloadDirectory(picked.uri);
  }

  Future<void> _pickConsoleDirectory(WidgetRef ref, String consoleId) async {
    final picked = await SafUtil().pickDirectory(writePermission: true, persistablePermission: true);
    if (picked == null) return;
    await ref.read(settingsProvider.notifier).setConsoleDownloadDirectory(consoleId, picked.uri);
  }

  Future<void> _pickLanguage(BuildContext context, WidgetRef ref, String currentCode) async {
    final chosen = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final locale in kSupportedLocales)
              ListTile(
                title: Text(locale.ownName),
                trailing: locale.code == currentCode ? const Icon(Icons.check_rounded) : null,
                onTap: () => Navigator.of(context).pop(locale.code),
              ),
          ],
        ),
      ),
    );
    if (chosen != null) await ref.read(settingsProvider.notifier).setLocale(chosen);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final settingsAsync = ref.watch(settingsProvider);
    final consolesAsync = ref.watch(allConsolesProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GengarScreenBackground(
        child: settingsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text(l10n.commonGenericError(e.toString()))),
          data: (settings) {
            final notifier = ref.read(settingsProvider.notifier);
            final consoles = consolesAsync.value ?? const <Console>[];
            final currentLocaleName =
                kSupportedLocales.firstWhere((l) => l.code == settings.localeCode, orElse: () => kSupportedLocales.first).ownName;

            return Column(
              children: [
                GengarScreenHeader(eyebrow: l10n.settingsEyebrow, title: l10n.settingsTitle),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                    children: [
                      GengarSectionLabel(l10n.settingsStorageSection),
                      const SizedBox(height: 10),
                      _SectionCard(
                        children: [
                          _LinkRow(
                            key: const Key('settings_download_directory_row'),
                            icon: Icons.folder_rounded,
                            title: l10n.settingsDownloadDirTitle,
                            path: settings.downloadDirectory.isEmpty ? l10n.settingsNotSet : settings.downloadDirectory,
                            actionLabel: l10n.commonChange,
                            onTap: () => _pickDownloadDirectory(ref),
                          ),
                          const _RowDivider(),
                          _ToggleRow(
                            key: const Key('settings_separate_by_console_toggle'),
                            title: l10n.settingsSeparateByConsoleTitle,
                            subtitle: l10n.settingsSeparateByConsoleSubtitle,
                            value: settings.separateByConsole,
                            onChanged: notifier.setSeparateByConsole,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      GengarSectionLabel(l10n.settingsLanguageSection),
                      const SizedBox(height: 10),
                      _SectionCard(
                        children: [
                          _LinkRow(
                            key: const Key('settings_language_row'),
                            icon: Icons.language_rounded,
                            title: l10n.settingsLanguageTitle,
                            path: currentLocaleName,
                            actionLabel: l10n.commonChange,
                            onTap: () => _pickLanguage(context, ref, settings.localeCode ?? kSupportedLocales.first.code),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      GengarSectionLabel(l10n.settingsConsoleFoldersSection),
                      const SizedBox(height: 10),
                      _SectionCard(
                        padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
                        children: [
                          for (final console in consoles)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: _ConsoleFolderRow(
                                console: console,
                                path: settings.consoleDownloadDirectories[console.id],
                                onTap: () => _pickConsoleDirectory(ref, console.id),
                              ),
                            ),
                          if (consoles.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                              child: Text(l10n.settingsNoConsolesConfigured),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      GengarSectionLabel(l10n.settingsNetworkSection),
                      const SizedBox(height: 10),
                      _SectionCard(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(15, 15, 15, 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(l10n.settingsSpeedLimitTitle,
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: GengarColors.onBackground)),
                                    Text(
                                      settings.limitSpeedMbs <= 0
                                          ? l10n.settingsUnlimited
                                          : l10n.settingsSpeedMbs(settings.limitSpeedMbs.toStringAsFixed(1)),
                                      style: GengarTypography.monoAccent(fontSize: 12.5, fontWeight: FontWeight.w600, color: GengarColors.primary),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                GengarGradientSlider(
                                  min: 0,
                                  max: 20,
                                  value: settings.limitSpeedMbs.clamp(0, 20),
                                  onChanged: notifier.setLimitSpeedMbs,
                                ),
                                const SizedBox(height: 9),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(l10n.settingsSpeedMinLabel, style: GengarTypography.monoAccent(fontSize: 9.5)),
                                    Text(l10n.settingsSpeedMbs('20'), style: GengarTypography.monoAccent(fontSize: 9.5)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const _RowDivider(),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(15, 15, 15, 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(l10n.settingsConcurrentDownloadsTitle,
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: GengarColors.onBackground)),
                                    Text(
                                      '${settings.concurrentDownloads}',
                                      style: GengarTypography.monoAccent(fontSize: 12.5, fontWeight: FontWeight.w600, color: GengarColors.primary),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                GengarSteppedSelector(
                                  segmentCount: 6,
                                  value: settings.concurrentDownloads,
                                  onChanged: (v) => notifier.setConcurrentDownloads(v),
                                ),
                                const SizedBox(height: 9),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('1', style: GengarTypography.monoAccent(fontSize: 9.5)),
                                    Text(l10n.settingsConcurrentMaxLabel, style: GengarTypography.monoAccent(fontSize: 9.5)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      GengarSectionLabel(l10n.settingsArchivesSection),
                      const SizedBox(height: 10),
                      _SectionCard(
                        children: [
                          _ToggleRow(
                            key: const Key('settings_auto_unzip_toggle'),
                            title: l10n.settingsAutoUnzipTitle,
                            subtitle: l10n.settingsAutoUnzipSubtitle,
                            value: settings.autoUnzip,
                            onChanged: notifier.setAutoUnzip,
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      Center(
                        child: GestureDetector(
                          onTap: () => context.go('/settings/about'),
                          child: Text(
                            'PixelVault v1.0 · Drift/SQLite · libtorrent4j',
                            style: GengarTypography.monoAccent(fontSize: 10, color: GengarColors.textFaint),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.children, this.padding});

  final List<Widget> children;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      padding: padding,
      decoration: BoxDecoration(
        color: GengarColors.cardFill.withValues(alpha: GengarColors.cardFillOpacity),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: GengarColors.cardBorder),
      ),
      child: Column(children: children),
    );
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) {
    return Container(height: 1, margin: const EdgeInsets.symmetric(horizontal: 15), color: GengarColors.borderSubtle);
  }
}

class _LinkRow extends StatelessWidget {
  const _LinkRow({
    super.key,
    required this.icon,
    required this.title,
    required this.path,
    required this.actionLabel,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String path;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: GengarColors.primary.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(color: GengarColors.primary.withValues(alpha: 0.28)),
                ),
                child: Icon(icon, size: 19, color: GengarColors.accentLight),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: GengarColors.onBackground)),
                    const SizedBox(height: 3),
                    Text(
                      path,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GengarTypography.monoAccent(fontSize: 10.5, color: GengarColors.onBackgroundMuted),
                    ),
                  ],
                ),
              ),
              Text(actionLabel, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: GengarColors.accentLight)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({super.key, required this.title, required this.subtitle, required this.value, required this.onChanged});

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: GengarColors.onBackground)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 11.5, color: GengarColors.onBackgroundMuted)),
              ],
            ),
          ),
          GengarGradientToggle(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _ConsoleFolderRow extends StatelessWidget {
  const _ConsoleFolderRow({required this.console, required this.path, required this.onTap});

  final Console console;
  final String? path;
  final VoidCallback onTap;

  String get _abbr {
    final letters = console.name.replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
    return letters.isEmpty ? '?' : letters.substring(0, letters.length.clamp(0, 4)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasCustom = path != null && path!.isNotEmpty;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: hasCustom ? GengarColors.primary.withValues(alpha: 0.08) : GengarColors.cardFill.withValues(alpha: GengarColors.cardFillOpacity),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: hasCustom ? GengarColors.primary.withValues(alpha: 0.2) : GengarColors.cardBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: GengarColors.cardFill.withValues(alpha: hasCustom ? 0.15 : 0.06),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  _abbr,
                  style: GengarTypography.monoAccent(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: hasCustom ? GengarColors.accentLight : GengarColors.onBackgroundMuted,
                  ),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      console.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: hasCustom ? GengarColors.onBackground : GengarColors.onBackgroundMuted),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasCustom ? path! : l10n.settingsUsesMainFolder,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GengarTypography.monoAccent(fontSize: 10, color: hasCustom ? const Color(0xFFA8B0C4) : GengarColors.textFaint),
                    ),
                  ],
                ),
              ),
              Text(
                hasCustom ? l10n.commonChange : l10n.commonSet,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: hasCustom ? GengarColors.accentLight : GengarColors.onBackgroundMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
