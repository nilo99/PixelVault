import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/deeplink/source_install_listener.dart';
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
      builder: (context, child) => SourceInstallListener(child: child ?? const SizedBox()),
    );
  }
}
