import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../download/download_progress_tracker.dart';
import '../download/download_status.dart';
import '../theme/gengar_colors.dart';
import '../theme/gengar_metrics.dart';
import '../theme/gengar_components.dart';

/// Root shell: floating glass bottom nav bar over an [IndexedStack] of the
/// 4 tab branches (Library, Downloads, Sources, Settings).
class ScaffoldWithGengarNavBar extends ConsumerWidget {
  const ScaffoldWithGengarNavBar({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Android Back — the B button on handhelds like the AYN Thor — used to
    // fall straight through to `SystemNavigator.pop()` on every tab, because
    // each tab is the root of its own branch with nothing to pop. That
    // destroyed the activity and, with it, every download running in this
    // Flutter engine, while the foreground download service kept the process
    // alive in a broken state. Now Back on any other tab returns to
    // Plataformas, the way tabbed Android apps behave; only Back on
    // Plataformas itself leaves, and `MainActivity` turns that into moving
    // the app to the background rather than destroying it.
    return BackButtonListener(
      onBackButtonPressed: () async {
        // Anything that can genuinely pop — a pushed Library page, an open
        // dialog or bottom sheet — pops as normal.
        if (GoRouter.of(context).canPop() ||
            Navigator.of(context, rootNavigator: true).canPop()) {
          return false;
        }
        if (navigationShell.currentIndex != 0) {
          navigationShell.goBranch(0);
          return true;
        }
        return false;
      },
      child: _buildScaffold(context, ref),
    );
  }

  Widget _buildScaffold(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final destinations = [
      (icon: Icons.videogame_asset_rounded, label: l10n.navBarPlatforms),
      (icon: Icons.download_rounded, label: l10n.navBarDownloads),
      (icon: Icons.hub_rounded, label: l10n.navBarSources),
      (icon: Icons.settings_rounded, label: l10n.navBarSettings),
    ];
    final downloads = ref.watch(downloadProgressTrackerProvider);
    final activeDownloads = downloads
        .where((d) =>
            d.status == DownloadStatus.downloading ||
            d.status == DownloadStatus.copying ||
            d.status == DownloadStatus.unzipping)
        .length;

    final metrics = GengarMetrics.of(context);

    return Scaffold(
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: SafeArea(
        minimum: EdgeInsets.fromLTRB(
          metrics.gutter,
          0,
          metrics.gutter,
          metrics.gap(12),
        ),
        child: GengarGlassPanel(
          useBlur: true,
          blur: 14,
          color: GengarColors.navFill,
          borderColor: GengarColors.borderSubtle,
          opacity: 0.72,
          borderRadius: BorderRadius.circular(20),
          padding: EdgeInsets.symmetric(
            vertical: metrics.isTiny ? 4 : 8,
            horizontal: 4,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (var i = 0; i < destinations.length; i++)
                Flexible(
                  child: _NavItem(
                    icon: destinations[i].icon,
                    label: destinations[i].label,
                    // On an auxiliary screen the four labels alone are wider
                    // than the bar; the icons carry the meaning and the
                    // selected pill still shows where you are.
                    showLabel: !metrics.isTiny,
                    selected: navigationShell.currentIndex == i,
                    badgeCount: i == 1 ? activeDownloads : 0,
                    onTap: () => navigationShell.goBranch(
                      i,
                      initialLocation: i == navigationShell.currentIndex,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.showLabel = true,
    this.badgeCount = 0,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool showLabel;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    final metrics = GengarMetrics.of(context);
    final color = selected ? GengarColors.primary : GengarColors.onBackgroundMuted;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.symmetric(
                horizontal: (16.0 * metrics.scale).clamp(9.0, 16.0),
                vertical: metrics.isTiny ? 4 : 5,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: selected ? GengarColors.activeTabPill : Colors.transparent,
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(icon, color: color, size: 20),
                  if (badgeCount > 0)
                    Positioned(
                      top: -6,
                      right: -10,
                      child: Container(
                        width: 15,
                        height: 15,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: GengarColors.primary,
                          border: Border.all(color: GengarColors.navFill, width: 2),
                        ),
                        child: Text(
                          badgeCount > 9 ? '9+' : '$badgeCount',
                          style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (showLabel) ...[
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: color, fontWeight: selected ? FontWeight.w700 : FontWeight.w600),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
