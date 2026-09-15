import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/download/download_item.dart';
import '../../core/download/download_manager.dart';
import '../../core/download/download_progress_tracker.dart';
import '../../core/download/download_status.dart';
import '../../core/providers.dart';
import '../../core/storage/saf_storage_helper.dart';
import '../../core/theme/gengar_colors.dart';
import '../../core/theme/gengar_components.dart';
import '../../core/theme/gengar_metrics.dart';
import '../../core/theme/gengar_typography.dart';
import '../../core/utils/error_messages.dart';
import '../../core/utils/format_bytes.dart';
import '../../l10n/app_localizations.dart';

/// The queue — running and interrupted downloads — plus the permanent history
/// of finished, failed and cancelled ones.
///
/// History leaves only from here, and only when the user asks: a single
/// entry, a selection, or all of it (the last two confirmed). Nothing else in
/// the app deletes it, and removing an entry never touches a file the user
/// downloaded.
class DownloadsScreen extends ConsumerStatefulWidget {
  const DownloadsScreen({super.key});

  @override
  ConsumerState<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends ConsumerState<DownloadsScreen> {
  bool _showHistory = false;
  bool _selecting = false;
  final _selected = <int>{};

  void _setTab({required bool history}) {
    setState(() {
      _showHistory = history;
      _selecting = false;
      _selected.clear();
    });
  }

  Future<bool> _confirmDelete(String title) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(l10n.downloadsHistoryDeleteConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            key: const Key('downloads_confirm_delete_button'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  Future<void> _deleteSelected(Set<int> ids) async {
    if (ids.isEmpty) return;
    final l10n = AppLocalizations.of(context)!;
    if (!await _confirmDelete(l10n.downloadsDeleteSelectedConfirmTitle(ids.length))) return;
    await ref.read(downloadManagerProvider).deleteHistoryEntries(ids);
    if (!mounted) return;
    setState(() {
      _selecting = false;
      _selected.clear();
    });
  }

  Future<void> _clearAll() async {
    final l10n = AppLocalizations.of(context)!;
    if (!await _confirmDelete(l10n.downloadsClearHistoryConfirmTitle)) return;
    await ref.read(downloadManagerProvider).clearHistory();
    if (!mounted) return;
    setState(() {
      _selecting = false;
      _selected.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final metrics = GengarMetrics.of(context);
    final downloads = ref.watch(downloadProgressTrackerProvider);

    final active = downloads.where((d) => !d.isTerminal).toList();
    final history = downloads.where((d) => d.isTerminal).toList()
      ..sort((a, b) => (b.completedAt ?? b.createdAt ?? DateTime(0))
          .compareTo(a.completedAt ?? a.createdAt ?? DateTime(0)));
    // Entries that vanished (deleted, or cleared) drop out of the selection.
    final historyIds = {for (final d in history) d.id};
    final selected = _selected.where(historyIds.contains).toSet();

    final running = downloads.where((d) => d.isActive).length;
    final totalSpeed = downloads
        .where((d) => d.status == DownloadStatus.downloading)
        .fold<double>(0, (sum, d) => sum + d.downloadSpeed);
    final queued = downloads.where((d) => d.status == DownloadStatus.stopped).length;

    final visible = _showHistory ? history : active;
    final selectionMode = _showHistory && _selecting;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GengarScreenBackground(
        child: Column(
          children: [
            GengarScreenHeader(eyebrow: l10n.downloadsEyebrow, title: l10n.downloadsTitle),
            // On an auxiliary display the three stat cards cost more height
            // than the list can spare; the nav bar badge already carries the
            // active count.
            if (downloads.isNotEmpty && !metrics.isTiny)
              Padding(
                padding: EdgeInsets.fromLTRB(metrics.gutter, metrics.gap(14), metrics.gutter, 0),
                child: Row(
                  children: [
                    Expanded(child: GengarStatCard(value: '$running', label: l10n.downloadsActiveLabel)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GengarStatCard(
                        value: totalSpeed.toStringAsFixed(1),
                        label: l10n.downloadsSpeedLabel,
                        valueColor: GengarColors.success,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GengarStatCard(
                        value: '$queued',
                        label: l10n.downloadsQueuedLabel,
                        valueColor: GengarColors.onBackgroundMuted,
                      ),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: EdgeInsets.fromLTRB(metrics.gutter, metrics.gap(14), metrics.gutter, 0),
              child: Row(
                children: [
                  // The tabs share whatever width is left and ellipsize only
                  // when they truly have to: on a 240pt display the two
                  // labels alone are wider than the row.
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: _SegmentButton(
                            key: const Key('downloads_tab_active'),
                            label: '${l10n.downloadsTabActive} (${active.length})',
                            selected: !_showHistory,
                            onTap: () => _setTab(history: false),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: _SegmentButton(
                            key: const Key('downloads_tab_history'),
                            label: '${l10n.downloadsTabHistory} (${history.length})',
                            selected: _showHistory,
                            onTap: () => _setTab(history: true),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_showHistory && history.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    _ActionButton(
                      key: const Key('downloads_select_button'),
                      icon: _selecting ? Icons.close_rounded : Icons.checklist_rounded,
                      tooltip: _selecting ? l10n.downloadsExitSelectionTooltip : l10n.downloadsSelectTooltip,
                      accent: _selecting,
                      onTap: () => setState(() {
                        _selecting = !_selecting;
                        _selected.clear();
                      }),
                    ),
                    const SizedBox(width: 7),
                    _ActionButton(
                      key: const Key('downloads_clear_history'),
                      icon: Icons.delete_sweep_rounded,
                      tooltip: l10n.downloadsClearHistory,
                      onTap: _clearAll,
                    ),
                  ],
                ],
              ),
            ),
            if (selectionMode)
              Padding(
                padding: EdgeInsets.fromLTRB(metrics.gutter, metrics.gap(6), metrics.gutter, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.downloadsSelectedCount(selected.length),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GengarTypography.monoAccent(fontSize: 10.5),
                      ),
                    ),
                    TextButton(
                      key: const Key('downloads_delete_selected_button'),
                      onPressed: selected.isEmpty ? null : () => _deleteSelected(selected),
                      child: Text(l10n.downloadsDeleteSelected),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: visible.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _showHistory ? Icons.history_rounded : Icons.download_rounded,
                            size: 40,
                            color: GengarColors.onBackgroundMuted,
                          ),
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Text(
                              downloads.isEmpty
                                  ? l10n.downloadsEmptyState
                                  : (_showHistory ? l10n.downloadsHistoryEmpty : l10n.downloadsActiveEmpty),
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: EdgeInsets.fromLTRB(
                        metrics.gutter,
                        metrics.gap(14),
                        metrics.gutter,
                        metrics.navBarInset,
                      ),
                      itemCount: visible.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = visible[index];
                        return _DownloadTile(
                          key: Key('downloads_tile_${item.id}'),
                          item: item,
                          selectionMode: selectionMode,
                          selected: selected.contains(item.id),
                          onToggleSelected: () => setState(() {
                            if (!_selected.remove(item.id)) _selected.add(item.id);
                          }),
                          onDelete: () => ref.read(downloadManagerProvider).deleteHistoryEntries({item.id}),
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

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({super.key, required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: GengarMetrics.of(context).isTiny ? 8 : 12,
            vertical: 7,
          ),
          decoration: BoxDecoration(
            color: selected
                ? GengarColors.primary.withValues(alpha: 0.16)
                : GengarColors.cardFill.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: selected ? GengarColors.primary.withValues(alpha: 0.34) : GengarColors.cardBorder,
            ),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GengarTypography.monoAccent(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: selected ? GengarColors.accentLight : GengarColors.onBackgroundMuted,
            ),
          ),
        ),
      ),
    );
  }
}

class _DownloadTile extends ConsumerWidget {
  const _DownloadTile({
    super.key,
    required this.item,
    required this.selectionMode,
    required this.selected,
    required this.onToggleSelected,
    required this.onDelete,
  });

  final DownloadItem item;
  final bool selectionMode;
  final bool selected;
  final VoidCallback onToggleSelected;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final metrics = GengarMetrics.of(context);
    final manager = ref.read(downloadManagerProvider);
    final color = _statusColor(item.status);
    final isProgressing = item.isActive;

    return GestureDetector(
      onTap: selectionMode ? onToggleSelected : null,
      child: Container(
        padding: EdgeInsets.all(metrics.isTiny ? 10 : 14),
        decoration: BoxDecoration(
          color: selected
              ? GengarColors.primary.withValues(alpha: 0.10)
              : GengarColors.cardFill.withValues(alpha: GengarColors.cardFillOpacity),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? GengarColors.primary.withValues(alpha: 0.40) : GengarColors.cardBorder,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GengarProgressRing(
                  progress: isProgressing ? item.progress : (item.status == DownloadStatus.completed ? 1 : null),
                  size: metrics.isTiny ? 36 : 48,
                  ringColor: color,
                  centerLabel: _centerLabel(item),
                ),
                SizedBox(width: metrics.gap(13)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: GengarColors.onBackground),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${formatBytes(item.fileSize)}${item.isTorrent ? ' · torrent' : ''}',
                        style: const TextStyle(fontSize: 11.5, color: GengarColors.onBackgroundMuted),
                      ),
                    ],
                  ),
                ),
                // The centre label of the ring and the status line underneath
                // already say what state this is in; on an auxiliary display
                // the chip is the one thing in this row that can go.
                if (!metrics.isTiny) _StatusChip(status: item.status, color: color),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: SizedBox(
                      height: 5,
                      child: LinearProgressIndicator(
                        value: isProgressing ? item.progress : (item.status == DownloadStatus.completed ? 1 : 0),
                        backgroundColor: GengarColors.progressTrack,
                        valueColor: AlwaysStoppedAnimation(color),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                if (selectionMode)
                  Checkbox(
                    key: Key('downloads_select_checkbox_${item.id}'),
                    value: selected,
                    onChanged: (_) => onToggleSelected(),
                  )
                else
                  _Actions(item: item, manager: manager, onDelete: onDelete),
              ],
            ),
            const SizedBox(height: 9),
            Text(_statusLabel(l10n, item), style: GengarTypography.monoAccent(fontSize: 10.5)),

            // Where it landed — the thing the screen could never answer before.
            if (item.status == DownloadStatus.completed && item.destinationLabel.isNotEmpty) ...[
              const SizedBox(height: 7),
              _DestinationRow(item: item),
            ],

            // Why it failed, in the user's language, instead of a bare "failed".
            if (item.status == DownloadStatus.failed && item.failureReason != null) ...[
              const SizedBox(height: 7),
              Text(
                downloadFailureText(l10n, item.failureReason!),
                style: const TextStyle(fontSize: 11.5, color: GengarColors.error),
              ),
            ],

            if (item.status == DownloadStatus.stopped && item.downloadedBytes > 0) ...[
              const SizedBox(height: 7),
              Text(
                l10n.downloadsInterruptedNotice,
                style: const TextStyle(fontSize: 11.5, color: GengarColors.onBackgroundMuted),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String? _centerLabel(DownloadItem item) {
    return switch (item.status) {
      DownloadStatus.downloading => '${(item.progress * 100).round()}%',
      DownloadStatus.copying => 'SD',
      DownloadStatus.unzipping => 'ZIP',
      DownloadStatus.completed => '✓',
      DownloadStatus.failed => '!',
      DownloadStatus.stopped => '…',
      DownloadStatus.cancelled => '×',
    };
  }

  Color _statusColor(DownloadStatus status) {
    return switch (status) {
      DownloadStatus.completed => GengarColors.success,
      DownloadStatus.failed => GengarColors.error,
      DownloadStatus.stopped || DownloadStatus.cancelled => GengarColors.onBackgroundMuted,
      DownloadStatus.copying => GengarColors.info,
      DownloadStatus.unzipping => GengarColors.infoLight,
      DownloadStatus.downloading => GengarColors.primary,
    };
  }

  String _statusLabel(AppLocalizations l10n, DownloadItem item) {
    return switch (item.status) {
      DownloadStatus.downloading =>
        l10n.downloadsStatusDownloading((item.progress * 100).toStringAsFixed(0), item.downloadSpeed.toStringAsFixed(1)),
      DownloadStatus.copying => l10n.downloadsStatusCopying,
      DownloadStatus.unzipping => l10n.downloadsStatusUnzipping,
      DownloadStatus.completed => l10n.downloadsStatusCompleted,
      DownloadStatus.failed => l10n.downloadsStatusFailed,
      DownloadStatus.stopped => l10n.downloadsQueuedLabel,
      DownloadStatus.cancelled => l10n.downloadsStatusCancelled,
    };
  }
}

/// "Saved in Internal storage/Roms/GBA", with a tap-to-copy affordance —
/// SAF gives no way to open a folder in the user's file manager reliably, so
/// handing them the path to paste is the dependable option.
class _DestinationRow extends StatelessWidget {
  const _DestinationRow({required this.item});
  final DownloadItem item;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final location = SafPathLabel.fromStored(item.destinationLabel);
    final volume = switch (location.volume) {
      'primary' => l10n.downloadsStorageInternal,
      '' => '',
      _ => l10n.downloadsStorageSdCard,
    };
    final parts = [
      if (volume.isNotEmpty) volume,
      if (location.path.isNotEmpty) location.path,
      if (item.savedFileName.isNotEmpty) item.savedFileName,
    ];
    final full = parts.join('/');

    return InkWell(
      key: Key('downloads_destination_${item.id}'),
      borderRadius: BorderRadius.circular(7),
      onTap: () async {
        await Clipboard.setData(ClipboardData(text: full));
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.downloadsPathCopied)),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.folder_outlined, size: 13, color: GengarColors.onBackgroundMuted),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                l10n.downloadsSavedIn(full),
                style: const TextStyle(fontSize: 11.5, color: GengarColors.onBackgroundMuted),
              ),
            ),
            const SizedBox(width: 6),
            Tooltip(
              message: l10n.downloadsCopyPathTooltip,
              child: const Icon(Icons.copy_rounded, size: 13, color: GengarColors.onBackgroundMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status, required this.color});
  final DownloadStatus status;
  final Color color;

  String _label(AppLocalizations l10n) => switch (status) {
        DownloadStatus.downloading => l10n.downloadsChipDownloading,
        DownloadStatus.copying => l10n.downloadsChipCopying,
        DownloadStatus.unzipping => l10n.downloadsChipUnzipping,
        DownloadStatus.completed => l10n.downloadsStatusCompleted,
        DownloadStatus.failed => l10n.downloadsChipFailed,
        DownloadStatus.stopped => l10n.downloadsQueuedLabel,
        DownloadStatus.cancelled => l10n.downloadsStatusCancelled,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(_label(l10n), style: GengarTypography.monoAccent(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

/// Per-tile actions. The queue can be stopped or resumed but not deleted —
/// a download leaves the queue by finishing, failing or being cancelled,
/// all of which land it in the history. Only history entries can be deleted.
class _Actions extends StatelessWidget {
  const _Actions({required this.item, required this.manager, required this.onDelete});
  final DownloadItem item;
  final DownloadManager manager;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final deleteButton = _ActionButton(
      key: Key('downloads_delete_button_${item.id}'),
      icon: Icons.delete_outline_rounded,
      tooltip: l10n.downloadsDeleteTooltip,
      onTap: onDelete,
    );

    switch (item.status) {
      case DownloadStatus.downloading:
      case DownloadStatus.copying:
      case DownloadStatus.unzipping:
        return _ActionButton(
          key: Key('downloads_cancel_button_${item.id}'),
          icon: Icons.stop_rounded,
          tooltip: l10n.downloadsStopTooltip,
          onTap: () => manager.cancelDownload(item.id),
        );
      case DownloadStatus.stopped:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ActionButton(
              key: Key('downloads_retry_button_${item.id}'),
              icon: Icons.refresh_rounded,
              // A stopped download with bytes already on disk resumes rather
              // than restarting, so name the action accordingly.
              tooltip: item.downloadedBytes > 0 ? l10n.downloadsResumeTooltip : l10n.downloadsRetryTooltip,
              accent: true,
              onTap: () => manager.retryDownload(item.id),
            ),
            const SizedBox(width: 7),
            _ActionButton(
              key: Key('downloads_cancel_button_${item.id}'),
              icon: Icons.close_rounded,
              tooltip: l10n.commonCancel,
              onTap: () => manager.cancelDownload(item.id),
            ),
          ],
        );
      case DownloadStatus.failed:
      case DownloadStatus.cancelled:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ActionButton(
              key: Key('downloads_retry_button_${item.id}'),
              icon: Icons.refresh_rounded,
              tooltip: item.status == DownloadStatus.failed && item.downloadedBytes > 0
                  ? l10n.downloadsResumeTooltip
                  : l10n.downloadsRetryTooltip,
              accent: true,
              onTap: () => manager.retryDownload(item.id),
            ),
            const SizedBox(width: 7),
            deleteButton,
          ],
        );
      case DownloadStatus.completed:
        return deleteButton;
    }
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({super.key, required this.icon, required this.tooltip, required this.onTap, this.accent = false});
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(9),
          child: Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent ? GengarColors.primary.withValues(alpha: 0.14) : GengarColors.cardFill.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: accent ? GengarColors.primary.withValues(alpha: 0.32) : GengarColors.cardBorder),
            ),
            child: Icon(icon, size: 15, color: accent ? GengarColors.accentLight : GengarColors.onBackgroundMuted),
          ),
        ),
      ),
    );
  }
}
