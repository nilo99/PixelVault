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
import '../../core/theme/gengar_typography.dart';
import '../../core/utils/error_messages.dart';
import '../../core/utils/format_bytes.dart';
import '../../l10n/app_localizations.dart';

/// Live progress list of in-progress downloads plus the persisted history of
/// finished/failed ones — wired to `DownloadProgressTrackerNotifier`, which
/// `DownloadManager.restore()` seeds from the `downloads` table on startup.
///
/// The history tab exists because a completed download used to vanish from
/// the list the moment the app restarted, taking with it the only record of
/// what had been downloaded and where it went.
class DownloadsScreen extends ConsumerStatefulWidget {
  const DownloadsScreen({super.key});

  @override
  ConsumerState<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends ConsumerState<DownloadsScreen> {
  bool _showHistory = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final downloads = ref.watch(downloadProgressTrackerProvider);

    final active = downloads.where((d) => !d.isTerminal).toList();
    final history = downloads.where((d) => d.isTerminal).toList()
      ..sort((a, b) => (b.completedAt ?? b.createdAt ?? DateTime(0))
          .compareTo(a.completedAt ?? a.createdAt ?? DateTime(0)));

    final running = downloads.where((d) => d.isActive).length;
    final totalSpeed = downloads
        .where((d) => d.status == DownloadStatus.downloading)
        .fold<double>(0, (sum, d) => sum + d.downloadSpeed);
    final queued = downloads.where((d) => d.status == DownloadStatus.stopped).length;

    final visible = _showHistory ? history : active;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GengarScreenBackground(
        child: Column(
          children: [
            GengarScreenHeader(eyebrow: l10n.downloadsEyebrow, title: l10n.downloadsTitle),
            if (downloads.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
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
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Row(
                children: [
                  _SegmentButton(
                    key: const Key('downloads_tab_active'),
                    label: '${l10n.downloadsTabActive} (${active.length})',
                    selected: !_showHistory,
                    onTap: () => setState(() => _showHistory = false),
                  ),
                  const SizedBox(width: 8),
                  _SegmentButton(
                    key: const Key('downloads_tab_history'),
                    label: '${l10n.downloadsTabHistory} (${history.length})',
                    selected: _showHistory,
                    onTap: () => setState(() => _showHistory = true),
                  ),
                  const Spacer(),
                  if (_showHistory && history.isNotEmpty)
                    TextButton(
                      key: const Key('downloads_clear_history'),
                      onPressed: () => ref.read(downloadManagerProvider).clearHistory(),
                      child: Text(
                        l10n.downloadsClearHistory,
                        style: GengarTypography.monoAccent(fontSize: 10.5, color: GengarColors.onBackgroundMuted),
                      ),
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
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 96),
                      itemCount: visible.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 10),
                      itemBuilder: (context, index) => _DownloadTile(
                        key: Key('downloads_tile_${visible[index].id}'),
                        item: visible[index],
                      ),
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
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
  const _DownloadTile({super.key, required this.item});
  final DownloadItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final manager = ref.read(downloadManagerProvider);
    final color = _statusColor(item.status);
    final isProgressing = item.isActive;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: GengarColors.cardFill.withValues(alpha: GengarColors.cardFillOpacity),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: GengarColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GengarProgressRing(
                progress: isProgressing ? item.progress : (item.status == DownloadStatus.completed ? 1 : null),
                size: 48,
                ringColor: color,
                centerLabel: _centerLabel(item),
              ),
              const SizedBox(width: 13),
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
              _StatusChip(status: item.status, color: color),
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
              _Actions(item: item, manager: manager),
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
    };
  }

  Color _statusColor(DownloadStatus status) {
    return switch (status) {
      DownloadStatus.completed => GengarColors.success,
      DownloadStatus.failed => GengarColors.error,
      DownloadStatus.stopped => GengarColors.onBackgroundMuted,
      DownloadStatus.copying => GengarColors.info,
      DownloadStatus.unzipping => GengarColors.infoLight,
      _ => GengarColors.primary,
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

class _Actions extends StatelessWidget {
  const _Actions({required this.item, required this.manager});
  final DownloadItem item;
  final DownloadManager manager;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
      case DownloadStatus.failed:
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
              key: Key('downloads_remove_button_${item.id}'),
              icon: Icons.close_rounded,
              tooltip: l10n.downloadsRemoveTooltip,
              onTap: () => manager.deleteDownload(item.id),
            ),
          ],
        );
      case DownloadStatus.completed:
        return _ActionButton(
          key: Key('downloads_remove_button_${item.id}'),
          icon: Icons.close_rounded,
          tooltip: l10n.downloadsRemoveFromListTooltip,
          onTap: () => manager.deleteDownload(item.id),
        );
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
