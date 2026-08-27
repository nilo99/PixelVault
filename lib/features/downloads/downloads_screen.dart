import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/download/download_item.dart';
import '../../core/download/download_manager.dart';
import '../../core/download/download_progress_tracker.dart';
import '../../core/download/download_status.dart';
import '../../core/providers.dart';
import '../../core/theme/gengar_colors.dart';
import '../../core/theme/gengar_components.dart';
import '../../core/theme/gengar_typography.dart';
import '../../core/utils/format_bytes.dart';
import '../../l10n/app_localizations.dart';

/// Live progress list of in-progress/completed downloads — wired to
/// `DownloadProgressTrackerNotifier`.
class DownloadsScreen extends ConsumerWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final downloads = ref.watch(downloadProgressTrackerProvider);

    final active = downloads.where((d) =>
        d.status == DownloadStatus.downloading ||
        d.status == DownloadStatus.copying ||
        d.status == DownloadStatus.unzipping);
    final totalSpeed = downloads
        .where((d) => d.status == DownloadStatus.downloading)
        .fold<double>(0, (sum, d) => sum + d.downloadSpeed);
    final queued = downloads.where((d) => d.status == DownloadStatus.stopped).length;

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
                    Expanded(child: GengarStatCard(value: '${active.length}', label: l10n.downloadsActiveLabel)),
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
            Expanded(
              child: downloads.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.download_rounded, size: 40, color: GengarColors.onBackgroundMuted),
                          const SizedBox(height: 12),
                          Text(l10n.downloadsEmptyState, style: Theme.of(context).textTheme.bodyMedium),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 96),
                      itemCount: downloads.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 10),
                      itemBuilder: (context, index) => _DownloadTile(
                        key: Key('downloads_tile_${downloads[index].id}'),
                        item: downloads[index],
                      ),
                    ),
            ),
          ],
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
    final isProgressing =
        item.status == DownloadStatus.downloading || item.status == DownloadStatus.copying || item.status == DownloadStatus.unzipping;

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
              tooltip: l10n.downloadsRetryTooltip,
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
