import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/database.dart';
import '../../core/models/downloadable_file.dart';
import '../../core/providers.dart';
import '../../core/scraping/tag_constants.dart';
import '../../core/theme/gengar_colors.dart';
import '../../core/theme/gengar_components.dart';
import '../../core/theme/gengar_typography.dart';
import '../../core/utils/format_bytes.dart';
import '../../l10n/app_localizations.dart';

/// Search + tag-filtered rom list, optionally scoped to the console chosen
/// in [PlatformSelectScreen] (null = search across every console).
///
/// Results are grouped by game rather than listed one row per file. A search
/// for "pokemon" used to return every region, revision and container format
/// of every match as a separate row — hundreds of near-identical lines, with
/// the page limit cutting through the middle of a single game's variants.
/// Now each game is one row that expands to show its versions.
class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key, this.console});

  final Console? console;

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  /// Groups per page. Lower than the old per-file page size because each
  /// entry now carries its variants with it.
  static const _pageSize = 40;

  /// Typing used to fire two full-table `LIKE '%…%'` queries per keystroke —
  /// "mario" meant ten scans of the whole catalog, all but the last thrown
  /// away. One query per pause instead.
  static const _debounce = Duration(milliseconds: 300);

  final _searchController = TextEditingController();
  Timer? _debounceTimer;
  Future<CategorizedTags>? _tagsFuture;
  final _selectedTags = <String>{};
  final _expandedGroups = <String>{};
  String? _meta;

  List<DownloadableFileGroup> _groups = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = false;
  Object? _error;
  // Bumped on every _reload() so a slow, superseded request can't clobber a
  // newer one's results when it finally resolves.
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  List<String> get _consoleIds => widget.console != null ? [widget.console!.id] : const [];

  String get _query {
    final text = _searchController.text.trim();
    return text.isEmpty ? '*' : text;
  }

  /// Coalesces keystrokes into a single query once typing pauses.
  void _scheduleReload() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounce, () {
      if (mounted) _reload();
    });
  }

  void _reload() {
    final repo = ref.read(downloadableFileRepositoryProvider);
    final query = _query;
    final requestId = ++_requestId;
    setState(() {
      _groups = [];
      _isLoading = true;
      _hasMore = false;
      _error = null;
      _expandedGroups.clear();
      _tagsFuture = repo.getAvailableTags(query: query, consoleIds: _consoleIds).then(TagCategorizer.categorize);
    });
    repo
        .queryGroupedFiles(
          query: query,
          consoleIds: _consoleIds,
          tags: _selectedTags.toList(),
          limit: _pageSize,
        )
        .then((groups) {
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _groups = groups;
        _isLoading = false;
        _hasMore = groups.length == _pageSize;
        _meta = _metaLabel(groups);
        // A lone result is almost always the one the user wants, so save
        // them the extra tap.
        if (groups.length == 1) _expandedGroups.add(groups.first.key);
      });
    }).catchError((Object e) {
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _isLoading = false;
        _error = e;
      });
    });
  }

  /// Fetches the next page of groups once the list is scrolled to its end.
  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    final requestId = _requestId;
    final repo = ref.read(downloadableFileRepositoryProvider);
    setState(() => _isLoadingMore = true);
    try {
      final more = await repo.queryGroupedFiles(
        query: _query,
        consoleIds: _consoleIds,
        tags: _selectedTags.toList(),
        limit: _pageSize,
        offset: _groups.length,
      );
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _groups = [..._groups, ...more];
        _hasMore = more.length == _pageSize;
        _isLoadingMore = false;
        _meta = _metaLabel(_groups);
      });
    } catch (_) {
      if (!mounted || requestId != _requestId) return;
      setState(() => _isLoadingMore = false);
    }
  }

  String _metaLabel(List<DownloadableFileGroup> groups) {
    final totalSize = groups.fold<int>(0, (sum, g) => sum + g.totalSize);
    final suffix = _hasMore ? '+' : '';
    final l10n = AppLocalizations.of(context)!;
    return l10n.libraryMetaLabel('${groups.length}$suffix', formatBytes(totalSize));
  }

  void _toggleTag(String tag) {
    setState(() {
      if (!_selectedTags.remove(tag)) _selectedTags.add(tag);
    });
    _reload();
  }

  void _startDownload(BuildContext context, DownloadableFileWithTags file) {
    final l10n = AppLocalizations.of(context)!;
    ref.read(downloadManagerProvider).startDownload(file);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.libraryDownloadStartedSnackbar(file.name))),
    );
  }

  Future<void> _openFilterSheet() async {
    final categorized = await (_tagsFuture ?? Future.value(null));
    if (categorized == null || !mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _FilterSheet(
        categorized: categorized,
        selectedTags: _selectedTags,
        onToggle: (tag) {
          _toggleTag(tag);
          Navigator.of(context).pop();
          _openFilterSheet();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GengarScreenBackground(
        // A single CustomScrollView so the whole page — header, search,
        // filter chips — scrolls away together with the results, instead of
        // staying pinned while only the list moves underneath.
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: GengarCompactHeader(
                title: widget.console?.name ?? l10n.libraryDefaultTitle,
                subtitle: _meta,
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: GengarSearchField(
                  key: const Key('library_search_field'),
                  controller: _searchController,
                  hintText: l10n.libraryHintSearch,
                  onChanged: (_) => _scheduleReload(),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: SizedBox(
                  height: 34,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      GengarFilterChip(
                        label: l10n.libraryFiltersChip,
                        style: GengarFilterChipStyle.solid,
                        icon: Icons.tune_rounded,
                        count: _selectedTags.isEmpty ? null : _selectedTags.length,
                        onTap: _openFilterSheet,
                      ),
                      for (final tag in _selectedTags) ...[
                        const SizedBox(width: 8),
                        GengarFilterChip(
                          label: tag,
                          style: GengarFilterChipStyle.active,
                          onRemove: () => _toggleTag(tag),
                        ),
                      ],
                      const SizedBox(width: 8),
                      GengarFilterChip(
                        label: l10n.libraryFormatChip,
                        style: GengarFilterChipStyle.ghost,
                        onTap: _openFilterSheet,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (_isLoading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: Text(l10n.commonGenericError(_error.toString()))),
              )
            else if (_groups.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      l10n.libraryNoResults,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 96),
                sliver: SliverList.separated(
                  itemCount: _groups.length + (_hasMore ? 1 : 0),
                  separatorBuilder: (context, index) => const SizedBox(height: 9),
                  itemBuilder: (context, index) {
                    if (index >= _groups.length) {
                      if (!_isLoadingMore) {
                        WidgetsBinding.instance.addPostFrameCallback((_) => _loadMore());
                      }
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)),
                        ),
                      );
                    }
                    final group = _groups[index];
                    return _GroupTile(
                      key: Key('library_group_tile_${group.key}'),
                      group: group,
                      expanded: _expandedGroups.contains(group.key),
                      onToggle: () => setState(() {
                        if (!_expandedGroups.remove(group.key)) _expandedGroups.add(group.key);
                      }),
                      onDownload: (file) => _startDownload(context, file),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FilterSheet extends StatelessWidget {
  const _FilterSheet({required this.categorized, required this.selectedTags, required this.onToggle});

  final CategorizedTags categorized;
  final Set<String> selectedTags;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final categories = [
      categorized.regions,
      categorized.languages,
      categorized.videoStandards,
      categorized.contentTypes,
      categorized.fileTypes,
    ];
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: GengarGlassPanel(
          useBlur: true,
          opacity: 0.92,
          color: GengarColors.surface,
          borderRadius: BorderRadius.circular(20),
          padding: const EdgeInsets.all(18),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l10n.libraryFiltersChip, style: GengarTypography.compactTitle()),
                  const SizedBox(height: 14),
                  for (final category in categories)
                    if (category.tags.isNotEmpty) ...[
                      GengarSectionLabel(category.name.toUpperCase()),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 7,
                        runSpacing: 7,
                        children: [
                          for (final tag in category.tags)
                            GengarFilterChip(
                              label: tag,
                              style: selectedTags.contains(tag) ? GengarFilterChipStyle.active : GengarFilterChipStyle.ghost,
                              onTap: () => onToggle(tag),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One game. Collapsed it summarizes how many versions exist and in which
/// formats; expanded it lists them, each independently downloadable.
class _GroupTile extends StatelessWidget {
  const _GroupTile({
    super.key,
    required this.group,
    required this.expanded,
    required this.onToggle,
    required this.onDownload,
  });

  final DownloadableFileGroup group;
  final bool expanded;
  final VoidCallback onToggle;
  final ValueChanged<DownloadableFileWithTags> onDownload;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final primary = group.primary;
    final formats = group.formats;

    return Container(
      decoration: BoxDecoration(
        color: GengarColors.cardFill.withValues(alpha: GengarColors.cardFillOpacity),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: GengarColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            key: Key('library_group_header_${group.key}'),
            borderRadius: BorderRadius.circular(15),
            // A single-variant group has nothing to expand into, so tapping
            // the header does nothing rather than opening an empty drawer.
            onTap: group.isSingle ? null : onToggle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group.title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: GengarColors.onBackground,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (!group.isSingle)
                              Text(
                                l10n.libraryVariantCount(group.variantCount),
                                style: GengarTypography.monoAccent(
                                  fontSize: 10.5,
                                  color: GengarColors.accentLight,
                                ),
                              ),
                            for (final format in formats.take(4)) _TagPill(label: format, accent: false),
                            Text(
                              formatBytes(group.isSingle ? group.totalSize : (primary?.fileSize ?? 0)),
                              style: GengarTypography.monoAccent(fontSize: 10.5),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (!group.isSingle)
                    AnimatedRotation(
                      turns: expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 160),
                      child: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 22,
                        color: GengarColors.onBackgroundMuted,
                      ),
                    ),
                  // Downloading straight from the header picks the largest
                  // variant — for ROM sets that is reliably the full dump
                  // rather than a demo or a patch.
                  if (group.isSingle && primary != null) ...[
                    const SizedBox(width: 4),
                    _DownloadButton(
                      key: Key('library_download_${primary.id}'),
                      onTap: () => onDownload(primary),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (expanded && !group.isSingle) ...[
            const Divider(height: 1, color: GengarColors.cardBorder),
            for (final variant in group.variants)
              _VariantRow(
                key: Key('library_variant_${variant.id}'),
                file: variant,
                onDownload: () => onDownload(variant),
              ),
            const SizedBox(height: 4),
          ],
        ],
      ),
    );
  }
}

/// One concrete file inside a group: its region/language tags, format and size.
class _VariantRow extends StatelessWidget {
  const _VariantRow({super.key, required this.file, required this.onDownload});

  final DownloadableFileWithTags file;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final categorized = TagCategorizer.categorize(file.tagList);
    final accentTags = categorized.contentTypes.tags;
    final plainTags = [
      ...categorized.regions.tags,
      ...categorized.languages.tags,
      ...categorized.videoStandards.tags,
    ];
    final format = file.contentExtension.replaceFirst('.', '').toUpperCase();

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 2),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 5,
                  runSpacing: 5,
                  children: [
                    if (format.isNotEmpty) _TagPill(label: format, accent: true),
                    for (final tag in accentTags.take(1)) _TagPill(label: tag, accent: true),
                    for (final tag in plainTags.take(4)) _TagPill(label: tag, accent: false),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      formatBytes(file.fileSize),
                      style: GengarTypography.monoAccent(fontSize: 10.5),
                    ),
                    // The download arrives wrapped; auto-extraction unpacks
                    // it, so say so rather than labelling the game ".7z".
                    if (file.isArchived) ...[
                      const SizedBox(width: 6),
                      Text(
                        l10n.libraryArchivedBadge(
                          file.fileExtension.replaceFirst('.', '').toUpperCase(),
                        ),
                        style: GengarTypography.monoAccent(
                          fontSize: 10,
                          color: GengarColors.onBackgroundMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _DownloadButton(onTap: onDownload, size: 36),
        ],
      ),
    );
  }
}

class _DownloadButton extends StatelessWidget {
  const _DownloadButton({super.key, required this.onTap, this.size = 42});

  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: GengarColors.primary.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: GengarColors.primary.withValues(alpha: 0.34)),
          ),
          child: Icon(Icons.file_download_outlined, size: size * 0.47, color: GengarColors.accentLight),
        ),
      ),
    );
  }
}

class _TagPill extends StatelessWidget {
  const _TagPill({required this.label, required this.accent});

  final String label;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: accent ? GengarColors.primary.withValues(alpha: 0.16) : GengarColors.cardFill.withValues(alpha: 0.05),
        border: Border.all(color: accent ? GengarColors.primary.withValues(alpha: 0.32) : GengarColors.cardBorder),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: GengarTypography.monoAccent(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: accent ? GengarColors.accentLight : GengarColors.onBackgroundMuted,
        ),
      ),
    );
  }
}
