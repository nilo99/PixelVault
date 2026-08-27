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
class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key, this.console});

  final Console? console;

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  static const _pageSize = 100;

  final _searchController = TextEditingController();
  Future<CategorizedTags>? _tagsFuture;
  final _selectedTags = <String>{};
  String? _meta;

  List<DownloadableFileWithTags> _results = [];
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
    _searchController.dispose();
    super.dispose();
  }

  List<String> get _consoleIds => widget.console != null ? [widget.console!.id] : const [];

  void _reload() {
    final repo = ref.read(downloadableFileRepositoryProvider);
    final query = _searchController.text.trim().isEmpty ? '*' : _searchController.text.trim();
    final requestId = ++_requestId;
    setState(() {
      _results = [];
      _isLoading = true;
      _hasMore = false;
      _error = null;
      _tagsFuture = repo.getAvailableTags(query: query, consoleIds: _consoleIds).then(TagCategorizer.categorize);
    });
    repo
        .queryFilesWithTags(query: query, consoleIds: _consoleIds, tags: _selectedTags.toList(), limit: _pageSize)
        .then((results) {
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _results = results;
        _isLoading = false;
        _hasMore = results.length == _pageSize;
        _meta = _metaLabel(results);
      });
    }).catchError((Object e) {
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _isLoading = false;
        _error = e;
      });
    });
  }

  /// Fetches the next page once the list is scrolled to its current end —
  /// searches used to silently truncate at 100 results with no way to see
  /// more.
  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    final requestId = _requestId;
    final repo = ref.read(downloadableFileRepositoryProvider);
    final query = _searchController.text.trim().isEmpty ? '*' : _searchController.text.trim();
    setState(() => _isLoadingMore = true);
    try {
      final more = await repo.queryFilesWithTags(
        query: query,
        consoleIds: _consoleIds,
        tags: _selectedTags.toList(),
        limit: _pageSize,
        offset: _results.length,
      );
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _results = [..._results, ...more];
        _hasMore = more.length == _pageSize;
        _isLoadingMore = false;
        _meta = _metaLabel(_results);
      });
    } catch (_) {
      if (!mounted || requestId != _requestId) return;
      setState(() => _isLoadingMore = false);
    }
  }

  String _metaLabel(List<DownloadableFileWithTags> results) {
    final totalSize = results.fold<int>(0, (sum, f) => sum + f.fileSize);
    final suffix = _hasMore ? '+' : '';
    final l10n = AppLocalizations.of(context)!;
    return l10n.libraryMetaLabel('${results.length}$suffix', formatBytes(totalSize));
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
                  onChanged: (_) => _reload(),
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
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 5,
                    children: [
                      for (final part in [
                        l10n.libraryColRegion,
                        '·',
                        l10n.libraryColLanguage,
                        '·',
                        l10n.libraryColVideo,
                        '·',
                        l10n.libraryColType,
                        '·',
                        l10n.libraryColExtension,
                      ])
                        Text(part, style: GengarTypography.monoAccent(fontSize: 9.5)),
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
            else if (_results.isEmpty)
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
                  itemCount: _results.length + (_hasMore ? 1 : 0),
                  separatorBuilder: (context, index) => const SizedBox(height: 9),
                  itemBuilder: (context, index) {
                    if (index >= _results.length) {
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
                    return _RomTile(
                      key: Key('library_rom_tile_${_results[index].id}'),
                      file: _results[index],
                      onDownload: () => _startDownload(context, _results[index]),
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

class _RomTile extends StatelessWidget {
  const _RomTile({super.key, required this.file, required this.onDownload});
  final DownloadableFileWithTags file;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    final categorized = TagCategorizer.categorize(file.tagList);
    final accentTags = categorized.contentTypes.tags;
    final plainTags = [
      ...categorized.regions.tags,
      ...categorized.languages.tags,
      ...categorized.videoStandards.tags,
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: GengarColors.cardFill.withValues(alpha: GengarColors.cardFillOpacity),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: GengarColors.cardBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.name,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: GengarColors.onBackground),
                ),
                if (plainTags.isNotEmpty || accentTags.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 5,
                    runSpacing: 5,
                    children: [
                      for (final tag in accentTags.take(2)) _TagPill(label: tag, accent: true),
                      for (final tag in plainTags.take(4 - accentTags.take(2).length)) _TagPill(label: tag, accent: false),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  '${formatBytes(file.fileSize)} · ${file.fileExtension}',
                  style: GengarTypography.monoAccent(fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onDownload,
              borderRadius: BorderRadius.circular(13),
              child: Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: GengarColors.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: GengarColors.primary.withValues(alpha: 0.34)),
                ),
                child: const Icon(Icons.file_download_outlined, size: 20, color: GengarColors.accentLight),
              ),
            ),
          ),
        ],
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
