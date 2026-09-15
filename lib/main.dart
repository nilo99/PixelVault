import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import 'app.dart';
import 'core/diagnostics/diagnostics_log.dart';
import 'core/download/foreground_task_handler.dart';
import 'core/security/urls_cipher_holder.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Must be ready before anything reads/writes `Console.urls` — see
  // `UrlsCipherHolder`'s doc comment.
  await UrlsCipherHolder.init();
  await _installDiagnostics();
  runZonedGuarded(() {
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      debugPrint('FlutterError: ${details.exceptionAsString()}');
      Diagnostics.record('flutter', details.exceptionAsString(), details.stack);
    };
    // Complements `FlutterError.onError` (widget build/layout/paint errors)
    // and the zone's own error callback below (async errors inside the
    // zone) — this one catches errors the engine dispatches directly,
    // outside both of those (e.g. some platform-channel callback errors).
    PlatformDispatcher.instance.onError = (error, stack) {
      debugPrint('PlatformDispatcher error: $error\n$stack');
      Diagnostics.record('platform', error, stack);
      return true;
    };
    // Draw edge-to-edge with transparent system bars so the app's own dark
    // gradient shows all the way to the screen edges — without this, the
    // status/navigation bar paint their own (light-themed default) color,
    // which reads as a broken/mismatched background band.
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ));
    initForegroundTask();
    runApp(const ProviderScope(child: PixelVaultApp()));
  }, (error, stack) {
    debugPrint('Uncaught error: $error\n$stack');
    Diagnostics.record('uncaught', error, stack);
  });
}

/// Keeps recent errors on the device, where Settings can copy them. Without
/// a writable support directory the app simply runs without a log.
Future<void> _installDiagnostics() async {
  try {
    final dir = await getApplicationSupportDirectory();
    Diagnostics.install(DiagnosticsLog(File('${dir.path}/logs/pixelvault.log')));
    // One line per launch, so "it looked like it restarted" shows up in the
    // log as a fact rather than a guess.
    Diagnostics.record('app', 'started');
  } catch (_) {
    // Best-effort.
  }
}
