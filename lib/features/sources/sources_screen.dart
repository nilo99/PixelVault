import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/database.dart';
import '../../core/models/content_type.dart';
import '../../core/models/console_x.dart';
import '../../core/models/url_entry.dart';
import '../../core/providers.dart';
import '../../core/state/rescan_state.dart';
import '../../core/theme/gengar_colors.dart';
import '../../core/utils/error_sanitizer.dart';
import '../../core/theme/gengar_components.dart';
import '../../core/theme/gengar_typography.dart';
import '../../core/theme/manufacturer_logo_catalog.dart';
import '../../l10n/app_localizations.dart';
import 'widgets/add_console_dialog.dart';
import 'widgets/add_manufacturer_dialog.dart';
import 'widgets/add_url_dialog.dart';

class SourcesScreen extends ConsumerWidget {
  const SourcesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final manufacturers = ref.watch(allManufacturersProvider);
    final consoles = ref.watch(allConsolesProvider);
    final fileCounts = ref.watch(consoleFileCountsProvider).value ?? const {};
    final rescan = ref.watch(rescanStateHolderProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GengarScreenBackground(
        // A single CustomScrollView so the whole page — header, banners —
        // scrolls away together with the manufacturer list, instead of
        // staying pinned while only the list moves underneath.
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: GengarScreenHeader(
                eyebrow: l10n.sourcesEyebrow,
                title: l10n.sourcesTitle,
                trailing: _SquareIconButton(
                  key: const Key('sources_add_manufacturer_button'),
                  icon: Icons.add_rounded,
                  onTap: () => showAddManufacturerDialog(context, ref),
                ),
              ),
            ),
            if (rescan.isRescanning || rescan.progressMessage.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                  child: _SyncBanner(message: rescan.progressMessage),
                ),
              ),
            if (rescan.errorMessage != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: _ErrorBanner(
                    message: rescan.errorMessage!,
                    onDismiss: () => ref.read(rescanStateHolderProvider.notifier).setErrorMessage(null),
                  ),
                ),
              ),
            manufacturers.when(
              loading: () => const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: Text(l10n.commonGenericError(e.toString()))),
              ),
              data: (manufacturerList) {
                if (manufacturerList.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyState(onAdd: () => showAddManufacturerDialog(context, ref)),
                  );
                }
                return consoles.when(
                  loading: () => const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) => SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: Text(l10n.commonGenericError(e.toString()))),
                  ),
                  data: (consoleList) {
                    final unscannedWithSources = consoleList
                        .where((c) => c.urls.isNotEmpty && c.urls.any((u) => u.lastSyncedAt == null))
                        .length;
                    return SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 96),
                      sliver: SliverList.list(
                        children: [
                          if (unscannedWithSources > 0 && !rescan.isRescanning)
                            _UnscannedBanner(count: unscannedWithSources),
                          _SyncAllButton(
                            key: const Key('sources_sync_all_button'),
                            enabled: !rescan.isRescanning,
                            onTap: () => ref.read(scrapeOrchestratorProvider).rescanAll(),
                          ),
                          const SizedBox(height: 18),
                          for (final manufacturer in manufacturerList)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 11),
                              child: _ManufacturerCard(
                                manufacturer: manufacturer,
                                consoles: consoleList.where((c) => c.manufacturerId == manufacturer.id).toList(),
                                allConsoles: consoleList,
                                fileCounts: fileCounts,
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SquareIconButton extends StatelessWidget {
  const _SquareIconButton({super.key, required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: GengarColors.cardFill.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: GengarColors.cardBorder),
          ),
          child: Icon(icon, size: 20, color: GengarColors.onBackground),
        ),
      ),
    );
  }
}

class _UnscannedBanner extends StatelessWidget {
  const _UnscannedBanner({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GengarGlassPanel(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const Icon(Icons.info_outline_rounded, color: GengarColors.warning, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                l10n.sourcesUnsyncedBanner(count),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SyncAllButton extends StatelessWidget {
  const _SyncAllButton({super.key, required this.enabled, required this.onTap});
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: enabled ? onTap : null,
        icon: const Icon(Icons.sync_rounded, size: 17, color: GengarColors.accentLight),
        label: Text(l10n.sourcesSyncAllButton),
        style: OutlinedButton.styleFrom(minimumSize: const Size(0, 46)),
      ),
    );
  }
}

class _ManufacturerCard extends ConsumerWidget {
  const _ManufacturerCard({
    required this.manufacturer,
    required this.consoles,
    required this.allConsoles,
    required this.fileCounts,
  });

  final Manufacturer manufacturer;
  final List<Console> consoles;
  final List<Console> allConsoles;
  final Map<String, int> fileCounts;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final synced = consoles.where((c) => c.urls.isNotEmpty && c.urls.every((u) => u.lastSyncedAt != null)).length;
    return GengarExpandableCard(
      initiallyExpanded: false,
      header: (context, expanded, toggle) => InkWell(
        onTap: toggle,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
          child: Row(
            children: [
              Builder(builder: (context) {
                final logoPath = ManufacturerLogoCatalog.assets[manufacturer.id];
                return Container(
                  width: 66,
                  height: 40,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFFFBFCFE), Color(0xFFE7EBF2)],
                    ),
                  ),
                  child: logoPath != null
                      ? Image.asset(
                          logoPath,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => GengarWordmark(name: manufacturer.name, fontSize: 13),
                        )
                      : GengarWordmark(name: manufacturer.name, fontSize: 13),
                );
              }),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(manufacturer.name, style: GengarTypography.compactTitle().copyWith(fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(
                      l10n.sourcesManufacturerSummary(consoles.length, synced),
                      style: GengarTypography.monoAccent(fontSize: 10.5),
                    ),
                  ],
                ),
              ),
              IconButton(
                key: Key('sources_add_console_button_${manufacturer.id}'),
                icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                tooltip: l10n.sourcesAddConsoleTooltip,
                onPressed: () => showAddConsoleDialog(context, ref, manufacturer.id),
              ),
              GengarChevron(expanded: expanded),
            ],
          ),
        ),
      ),
      children: [
        for (final console in consoles)
          Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: _ConsoleRow(
              key: Key('sources_console_row_${console.id}'),
              console: console,
              allConsoles: allConsoles,
              fileCount: fileCounts[console.id] ?? 0,
            ),
          ),
        if (consoles.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(l10n.sourcesNoConsolesEmptyState),
          ),
      ],
    );
  }
}

class _ConsoleRow extends ConsumerWidget {
  const _ConsoleRow({super.key, required this.console, required this.allConsoles, required this.fileCount});

  final Console console;
  final List<Console> allConsoles;
  final int fileCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final rescan = ref.watch(rescanStateHolderProvider);
    final urls = console.urls;
    final neverScanned = urls.isNotEmpty && urls.any((u) => u.lastSyncedAt == null);
    final statusColor = neverScanned ? GengarColors.warning : GengarColors.success;

    return Container(
      decoration: BoxDecoration(
        color: GengarColors.cardFill.withValues(alpha: GengarColors.cardFillOpacity),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: GengarColors.cardBorder),
      ),
      child: GengarExpandableCard(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        header: (context, expanded, toggle) => InkWell(
          onTap: toggle,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: statusColor,
                    boxShadow: [BoxShadow(color: statusColor.withValues(alpha: 0.7), blurRadius: 8)],
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(console.name, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: GengarColors.onBackground)),
                      const SizedBox(height: 2),
                      Text(
                        neverScanned ? l10n.sourcesNeverSynced : l10n.sourcesGamesIndexedCount(fileCount),
                        style: GengarTypography.monoAccent(fontSize: 10, color: statusColor),
                      ),
                    ],
                  ),
                ),
                Text(l10n.sourcesSourceCount(urls.length), style: GengarTypography.monoAccent(fontSize: 9.5)),
                IconButton(
                  key: Key('sources_add_url_button_${console.id}'),
                  icon: const Icon(Icons.link_rounded, size: 18),
                  tooltip: l10n.sourcesAddSourceTooltip,
                  onPressed: () => showAddUrlDialog(context, ref, console, allConsoles),
                ),
                Material(
                  key: Key('sources_refresh_console_button_${console.id}'),
                  color: GengarColors.primary.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: rescan.isRescanning ? null : () => ref.read(scrapeOrchestratorProvider).refreshConsole(console),
                    child: Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: GengarColors.primary.withValues(alpha: 0.3)),
                      ),
                      child: const Icon(Icons.sync_rounded, size: 16, color: GengarColors.accentLight),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        children: [
          if (urls.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(l10n.sourcesNoSourcesEmptyState),
            )
          else
            for (final (index, entry) in urls.indexed) _UrlRow(console: console, entry: entry, index: index),
        ],
      ),
    );
  }
}

class _UrlRow extends ConsumerWidget {
  const _UrlRow({required this.console, required this.entry, required this.index});
  final Console console;
  final UrlEntry entry;
  // Position within this console's own url list — purely a local "which one
  // is this" label for the user. Intentionally independent of the companion
  // website's own "Fonte N" numbering (position in `sources.server.ts`'s
  // array): the two never need to match, since the real link between a site
  // source and a local one is always the opaque install token, never a label.
  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: entry.lastSyncedAt == null ? GengarColors.warning : GengarColors.success,
            ),
          ),
          const SizedBox(width: 7),
          Icon(entry.isTorrent ? Icons.hub_outlined : Icons.http_rounded, size: 15, color: GengarColors.textFaint),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n.sourcesSourceLabel(index + 1),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GengarTypography.monoAccent(fontSize: 10.5),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: GengarColors.cardFill.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: GengarColors.cardBorder),
            ),
            child: Text(entry.contentType.toJson(), style: GengarTypography.monoAccent(fontSize: 9.5)),
          ),
          IconButton(
            key: Key('sources_remove_url_button_${console.id}_$index'),
            icon: const Icon(Icons.delete_outline_rounded, size: 17, color: GengarColors.error),
            tooltip: l10n.sourcesRemoveSourceTooltip,
            onPressed: () async {
              try {
                await ref.read(catalogRepositoryProvider).removeUrlFromConsole(console.id, entry);
              } catch (e) {
                ref
                    .read(rescanStateHolderProvider.notifier)
                    .setErrorMessage(l10n.sourcesRemoveSourceError(sanitizeErrorForDisplay(e)));
              }
            },
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: GengarGlassPanel(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.hub_rounded, size: 32),
              const SizedBox(height: 8),
              Text(
                l10n.sourcesEmptyStateBody,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              GengarPrimaryButton(label: l10n.sourcesAddManufacturerButton, onPressed: onAdd, icon: Icons.add_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _SyncBanner extends StatefulWidget {
  const _SyncBanner({required this.message});
  final String message;

  @override
  State<_SyncBanner> createState() => _SyncBannerState();
}

class _SyncBannerState extends State<_SyncBanner> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [GengarColors.primary.withValues(alpha: 0.2), GengarColors.primary.withValues(alpha: 0.1)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: GengarColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              FadeTransition(
                opacity: _controller.drive(Tween(begin: 0.55, end: 1.0)),
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: GengarColors.primary,
                    boxShadow: [BoxShadow(color: GengarColors.primary.withValues(alpha: 0.9), blurRadius: 10)],
                  ),
                ),
              ),
              const SizedBox(width: 9),
              Text(l10n.sourcesSyncingBanner, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: GengarColors.onBackground)),
            ],
          ),
          if (widget.message.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(widget.message, style: GengarTypography.monoAccent(fontSize: 11, color: GengarColors.accentLight)),
          ],
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: SizedBox(
              height: 6,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) => LinearProgressIndicator(
                  value: null,
                  backgroundColor: GengarColors.progressTrack,
                  valueColor: const AlwaysStoppedAnimation(GengarColors.primary),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onDismiss});
  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      decoration: BoxDecoration(
        color: GengarColors.error.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: GengarColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: GengarColors.error, size: 18),
          const SizedBox(width: 12),
          Expanded(child: Text(message, style: Theme.of(context).textTheme.bodySmall)),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 18),
            onPressed: onDismiss,
          ),
        ],
      ),
    );
  }
}

void showAddManufacturerDialog(BuildContext context, WidgetRef ref) {
  final l10n = AppLocalizations.of(context)!;
  final idController = TextEditingController();
  final nameController = TextEditingController();
  showDialog<void>(
    context: context,
    builder: (context) => AddManufacturerDialog(
      idController: idController,
      nameController: nameController,
      onSubmit: () async {
        if (idController.text.trim().isEmpty || nameController.text.trim().isEmpty) return;
        try {
          await ref.read(catalogRepositoryProvider).upsertManufacturer(
                ManufacturersCompanion.insert(
                  id: idController.text.trim(),
                  name: nameController.text.trim(),
                ),
              );
        } catch (e) {
          ref
              .read(rescanStateHolderProvider.notifier)
              .setErrorMessage(l10n.sourcesAddManufacturerError(sanitizeErrorForDisplay(e)));
          return;
        }
        if (context.mounted) Navigator.of(context).pop();
      },
    ),
  ).then((_) {
    idController.dispose();
    nameController.dispose();
  });
}

void showAddConsoleDialog(BuildContext context, WidgetRef ref, String manufacturerId) {
  final l10n = AppLocalizations.of(context)!;
  final idController = TextEditingController();
  final nameController = TextEditingController();
  showDialog<void>(
    context: context,
    builder: (context) => AddConsoleDialog(
      idController: idController,
      nameController: nameController,
      onSubmit: () async {
        if (idController.text.trim().isEmpty || nameController.text.trim().isEmpty) return;
        try {
          await ref.read(catalogRepositoryProvider).upsertConsole(
                ConsolesCompanion.insert(
                  id: '${manufacturerId}_${idController.text.trim()}',
                  name: nameController.text.trim(),
                  manufacturerId: manufacturerId,
                  urlsJson: '[]',
                ),
              );
        } catch (e) {
          ref
              .read(rescanStateHolderProvider.notifier)
              .setErrorMessage(l10n.sourcesAddConsoleError(sanitizeErrorForDisplay(e)));
          return;
        }
        if (context.mounted) Navigator.of(context).pop();
      },
    ),
  ).then((_) {
    idController.dispose();
    nameController.dispose();
  });
}

/// Opens the add-source dialog pre-selecting [initialConsole], with every
/// other known console offered as an extra checkbox (one source can serve
/// several platforms — e.g. a combined pack torrent). On submit, the URL is
/// attached to every selected console and each one is immediately
/// resynchronized so results show up without a separate manual step.
void showAddUrlDialog(BuildContext context, WidgetRef ref, Console initialConsole, List<Console> allConsoles) {
  final l10n = AppLocalizations.of(context)!;
  final urlController = TextEditingController();
  var contentType = ContentType.game;
  final selected = <String>{initialConsole.id};

  showDialog<void>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AddUrlDialog(
        urlController: urlController,
        contentType: contentType,
        onContentTypeChanged: (v) => setState(() => contentType = v),
        allConsoles: allConsoles,
        selectedConsoleIds: selected,
        onToggleConsole: (id) => setState(() {
          if (!selected.remove(id)) selected.add(id);
        }),
        onSubmit: () async {
          final url = urlController.text.trim();
          if (url.isEmpty || selected.isEmpty) return;

          final entry = UrlEntry(url: url, contentType: contentType);
          final catalog = ref.read(catalogRepositoryProvider);
          try {
            await catalog.addUrlToConsoles(selected.toList(), entry);
          } catch (e) {
            ref.read(rescanStateHolderProvider.notifier).setErrorMessage(l10n.sourcesAddSourceError(e.toString()));
            return;
          }
          if (context.mounted) Navigator.of(context).pop();

          final orchestrator = ref.read(scrapeOrchestratorProvider);
          for (final consoleId in selected) {
            final console = await catalog.getConsoleById(consoleId);
            if (console != null) await orchestrator.refreshConsole(console);
          }
        },
      ),
    ),
  ).then((_) => urlController.dispose());
}
