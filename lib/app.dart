import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/deeplink/source_install_listener.dart';
import 'core/download/download_manager.dart';
import 'core/providers.dart';
import 'core/router/app_router.dart';
import 'core/settings/settings_repository.dart';
import 'core/theme/gengar_theme.dart';
import 'l10n/app_localizations.dart';

class PixelVaultApp extends ConsumerWidget {
  const PixelVaultApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final localeCode = ref.watch(settingsProvider.select((s) => s.value?.localeCode));
    return MaterialApp.router(
      title: 'PixelVault',
      debugShowCheckedModeBanner: false,
      theme: GengarTheme.dark(),
      darkTheme: GengarTheme.dark(),
      themeMode: ThemeMode.dark,
      // `null` while no locale has been chosen yet (the language-select
      // screen itself doesn't go through AppLocalizations, see its own doc
      // comment) — Flutter falls back to its own resolution in that window.
      locale: localeCode == null ? null : Locale(localeCode),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
      builder: (context, child) => _DownloadNotificationLocale(
        child: SourceInstallListener(child: child ?? const SizedBox()),
      ),
    );
  }
}

/// Keeps the persistent download notification's text in the user's language.
///
/// `DownloadManager` runs with no `BuildContext`, so it can't look strings up
/// itself; this sits just inside `MaterialApp` (where `AppLocalizations` is
/// available) and pushes them down whenever the locale changes. Without it
/// the notification was hardcoded Portuguese regardless of the language the
/// user picked.
class _DownloadNotificationLocale extends ConsumerStatefulWidget {
  const _DownloadNotificationLocale({required this.child});

  final Widget child;

  @override
  ConsumerState<_DownloadNotificationLocale> createState() => _DownloadNotificationLocaleState();
}

class _DownloadNotificationLocaleState extends ConsumerState<_DownloadNotificationLocale> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return;
    ref.read(downloadManagerProvider).notificationStrings = DownloadNotificationStrings(
      title: l10n.downloadsNotificationTitle,
      body: l10n.downloadsNotificationBody,
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
