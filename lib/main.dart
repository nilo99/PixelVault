import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/download/foreground_task_handler.dart';
import 'core/security/urls_cipher_holder.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Must be ready before anything reads/writes `Console.urls` — see
  // `UrlsCipherHolder`'s doc comment.
  await UrlsCipherHolder.init();
  runZonedGuarded(() {
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      debugPrint('FlutterError: ${details.exceptionAsString()}');
    };
    // Complements `FlutterError.onError` (widget build/layout/paint errors)
    // and the zone's own error callback below (async errors inside the
    // zone) — this one catches errors the engine dispatches directly,
    // outside both of those (e.g. some platform-channel callback errors).
    PlatformDispatcher.instance.onError = (error, stack) {
      debugPrint('PlatformDispatcher error: $error\n$stack');
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
  });
}
