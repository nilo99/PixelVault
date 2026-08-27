import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../models/console_x.dart';
import '../models/content_type.dart';
import '../models/url_entry.dart';
import '../providers.dart';
import '../router/app_router.dart';
import '../theme/gengar_components.dart';
import '../utils/error_sanitizer.dart';
import 'deep_link_service.dart';
import 'source_install_client.dart';

/// Wraps the whole app (via `MaterialApp.router`'s `builder`) to listen for
/// `pixelvault://install?token=` links opened from the companion sources
/// website. On receipt: resolves the token to a real source, confirms with
/// the user (never installs silently), then adds it via `addUrlToConsoles`.
/// Deliberately does NOT trigger a scrape/sync — the user must go to Fontes
/// and sync manually, same as any other newly-added source.
class SourceInstallListener extends ConsumerStatefulWidget {
  const SourceInstallListener({super.key, required this.child, this.deepLinkService});

  final Widget child;
  final DeepLinkService? deepLinkService;

  @override
  ConsumerState<SourceInstallListener> createState() => _SourceInstallListenerState();
}

class _SourceInstallListenerState extends ConsumerState<SourceInstallListener> {
  StreamSubscription<Uri>? _subscription;

  @override
  void initState() {
    super.initState();
    final service = widget.deepLinkService ?? DeepLinkService();
    _subscription = service.linkStream.listen(_handleLink, onError: (_) {});
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _handleLink(Uri uri) async {
    if (uri.scheme != 'pixelvault' || uri.host != 'install') return;
    final token = uri.queryParameters['token'];
    if (token == null || token.isEmpty) return;

    final l10n = AppLocalizations.of(context)!;

    final ResolvedSource resolved;
    try {
      resolved = await ref.read(sourceInstallClientProvider).resolve(token);
    } catch (e) {
      await _showMessage(l10n.sourceInstallResolveError(sanitizeErrorForDisplay(e)));
      return;
    }

    final catalog = ref.read(catalogRepositoryProvider);
    final console = await catalog.getConsoleById(resolved.consoleId);
    if (console == null) {
      await _showMessage(l10n.sourceInstallUnsupportedConsole);
      return;
    }

    if (console.urls.any((u) => u.url == resolved.url)) {
      await _showMessage(l10n.sourceInstallAlreadyInstalled(console.name));
      return;
    }

    final navigatorContext = rootNavigatorKey.currentContext;
    if (navigatorContext == null) return;
    // Re-fetched from the global key immediately above (not a stale
    // State.context carried across the earlier awaits), so this is safe.
    final confirmed = await showDialog<bool>(
      // ignore: use_build_context_synchronously
      context: navigatorContext,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.sourceInstallConfirmTitle),
        content: Text(l10n.sourceInstallConfirmBody(console.name)),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: Text(l10n.commonCancel)),
          GengarPrimaryButton(label: l10n.commonAdd, onPressed: () => Navigator.of(dialogContext).pop(true)),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await catalog.addUrlToConsoles(
        [console.id],
        UrlEntry(url: resolved.url, contentType: ContentType.fromJson(resolved.contentType)),
      );
      await _showMessage(l10n.sourceInstallSuccess(console.name));
    } catch (e) {
      await _showMessage(l10n.sourceInstallAddError(sanitizeErrorForDisplay(e)));
    }
  }

  Future<void> _showMessage(String message) async {
    final navigatorContext = rootNavigatorKey.currentContext;
    if (navigatorContext == null) return;
    final l10n = AppLocalizations.of(navigatorContext)!;
    await showDialog<void>(
      context: navigatorContext,
      builder: (dialogContext) => AlertDialog(
        content: Text(message),
        actions: [TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: Text(l10n.commonOk))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
