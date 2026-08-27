import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/db/database.dart';
import '../../core/providers.dart';
import '../../core/theme/gengar_colors.dart';
import '../../core/theme/gengar_components.dart';
import '../../core/theme/gengar_typography.dart';
import '../../core/utils/format_bytes.dart';
import '../../l10n/app_localizations.dart';

/// Landing tab of the Library branch: a scrollable list of consoles that
/// actually have indexed files, tapped to jump into a filtered
/// [LibraryScreen].
class PlatformSelectScreen extends ConsumerStatefulWidget {
  const PlatformSelectScreen({super.key});

  @override
  ConsumerState<PlatformSelectScreen> createState() => _PlatformSelectScreenState();
}

class _PlatformSelectScreenState extends ConsumerState<PlatformSelectScreen> {
  final _searchController = TextEditingController();
  String _filter = '';

  @override
  void initState() {
    super.initState();
    ref.listenManual(ensureCatalogSeededProvider, (previous, next) {});
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final seeding = ref.watch(ensureCatalogSeededProvider);
    final consoles = ref.watch(allConsolesProvider);
    final fileCounts = ref.watch(consoleFileCountsProvider).value ?? const {};
    final fileSizes = ref.watch(consoleFileSizesProvider).value ?? const {};

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GengarScreenBackground(
        child: seeding.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text(l10n.platformSelectSeedError(e.toString()))),
          data: (_) => consoles.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text(l10n.commonGenericError(e.toString()))),
            data: (consoleList) {
              final withFiles = consoleList.where((c) => (fileCounts[c.id] ?? 0) > 0).toList()
                ..sort((a, b) => a.name.compareTo(b.name));
              final filtered = _filter.isEmpty
                  ? withFiles
                  : withFiles.where((c) => c.name.toLowerCase().contains(_filter.toLowerCase())).toList();
              final totalFiles = withFiles.fold<int>(0, (sum, c) => sum + (fileCounts[c.id] ?? 0));

              // A single CustomScrollView (not a fixed header + Expanded list)
              // so the whole page — header, search, card — scrolls away
              // together with the list, instead of the header staying
              // pinned while only the list moves.
              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: GengarScreenHeader(
                      eyebrow: l10n.platformSelectEyebrow,
                      title: l10n.platformSelectTitle,
                      subtitle: l10n.platformSelectSubtitle(withFiles.length, totalFiles),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                      child: GengarSearchField(
                        controller: _searchController,
                        hintText: l10n.platformSelectSearchHint,
                        onChanged: (v) => setState(() => _filter = v),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                      child: _GlobalLibraryCard(onTap: () => context.go('/platforms/library')),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(22, 20, 22, 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GengarSectionLabel(l10n.platformSelectActiveConsolesSection),
                          Text('A–Z', style: GengarTypography.monoAccent(fontSize: 11)),
                        ],
                      ),
                    ),
                  ),
                  if (filtered.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            l10n.platformSelectEmptyState,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 96),
                      sliver: SliverList.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final console = filtered[index];
                          return _ConsoleRow(
                            console: console,
                            fileCount: fileCounts[console.id] ?? 0,
                            totalSize: fileSizes[console.id] ?? 0,
                            onTap: () => context.go('/platforms/library', extra: console),
                          );
                        },
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _GlobalLibraryCard extends StatelessWidget {
  const _GlobalLibraryCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [GengarColors.primary.withValues(alpha: 0.22), GengarColors.primary.withValues(alpha: 0.12)],
            ),
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: GengarColors.primary.withValues(alpha: 0.32)),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: GengarColors.ctaGradient,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: GengarColors.primary.withValues(alpha: 0.5), blurRadius: 18)],
                ),
                child: const Icon(Icons.menu_rounded, size: 22, color: Colors.white),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.platformSelectGlobalLibraryTitle,
                        style: GengarTypography.compactTitle(color: GengarColors.onBackground).copyWith(fontSize: 15)),
                    const SizedBox(height: 1),
                    Text(
                      l10n.platformSelectGlobalLibrarySubtitle,
                      style: const TextStyle(fontSize: 12, color: GengarColors.onBackgroundMuted),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, size: 20, color: GengarColors.accentLight),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConsoleRow extends StatefulWidget {
  const _ConsoleRow({
    required this.console,
    required this.fileCount,
    required this.totalSize,
    required this.onTap,
  });

  final Console console;
  final int fileCount;
  final int totalSize;
  final VoidCallback onTap;

  @override
  State<_ConsoleRow> createState() => _ConsoleRowState();
}

class _ConsoleRowState extends State<_ConsoleRow> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        child: Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: GengarColors.cardFill.withValues(alpha: GengarColors.cardFillOpacity),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: GengarColors.cardBorder),
          ),
          child: Row(
            children: [
              GengarConsoleArtCard(consoleName: widget.console.name, consoleId: widget.console.id),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.console.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GengarTypography.compactTitle().copyWith(fontSize: 15.5),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: GengarColors.success,
                            boxShadow: [BoxShadow(color: GengarColors.success.withValues(alpha: 0.7), blurRadius: 7)],
                          ),
                        ),
                        const SizedBox(width: 7),
                        Text(
                          l10n.platformSelectConsoleSummary(widget.fileCount, formatBytes(widget.totalSize)),
                          style: GengarTypography.monoAccent(fontSize: 11.5),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, size: 20, color: GengarColors.textFaint),
            ],
          ),
        ),
      ),
    );
  }
}
