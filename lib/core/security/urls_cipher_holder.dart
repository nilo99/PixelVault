import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'urls_cipher.dart';

/// Global access point for the [UrlsCipher] used by `Console.urls` (see
/// `console_x.dart`) and `CatalogRepository`. A plain static holder — not a
/// Riverpod provider — because `ConsoleUrls.urls` is a synchronous extension
/// getter with no `ref`/DI access of its own; this is the accepted tradeoff
/// for keeping every existing `console.urls` call site unchanged.
///
/// [init] must run (and be awaited) before anything reads `console.urls` or
/// writes through `CatalogRepository` — done once in `main()`, before
/// `runApp`, so the whole widget tree always sees an initialized cipher.
class UrlsCipherHolder {
  UrlsCipherHolder._();

  static const _keyStorageKey = 'urls_encryption_key_v1';
  static UrlsCipher? _instance;

  static UrlsCipher get instance {
    final cipher = _instance;
    if (cipher == null) {
      throw StateError('UrlsCipherHolder.init() must be awaited before reading/writing console urls.');
    }
    return cipher;
  }

  /// Reads the AES key from secure (Android Keystore-backed) storage,
  /// generating and persisting a new random 256-bit key on first run. Never
  /// touches the SQLite database.
  static Future<void> init([FlutterSecureStorage? storage]) async {
    final secureStorage = storage ?? const FlutterSecureStorage();
    final existing = await secureStorage.read(key: _keyStorageKey);
    final Uint8List keyBytes;
    if (existing != null) {
      keyBytes = base64Decode(existing);
    } else {
      keyBytes = _generateKey();
      await secureStorage.write(key: _keyStorageKey, value: base64Encode(keyBytes));
    }
    _instance = UrlsCipher(keyBytes);
  }

  static Uint8List _generateKey() {
    final random = Random.secure();
    return Uint8List.fromList(List.generate(32, (_) => random.nextInt(256)));
  }

  /// Test-only escape hatch: sets a fixed, in-memory key directly, bypassing
  /// `flutter_secure_storage` entirely (its real plugin throws
  /// `MissingPluginException` under plain `flutter test`).
  static void initForTest([Uint8List? keyBytes]) {
    _instance = UrlsCipher(keyBytes ?? _generateKey());
  }
}
