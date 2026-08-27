import 'dart:convert';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart' as enc;

import '../models/url_entry.dart';

/// Encrypts/decrypts a console's `urlsJson` column at rest (AES-256-GCM) so
/// that a raw SQLite file extracted via root/adb-backup doesn't reveal
/// plaintext magnet/HTTP sources. This is a purely storage-level guard — it
/// doesn't change anything about the in-memory `List<UrlEntry>` the app
/// holds at runtime or displays; hiding urls on screen is handled entirely
/// separately by `sources_screen.dart`.
///
/// A console whose `urlsJson` was written before encryption existed still
/// has plaintext JSON stored — [decode] detects the `#enc#` prefix this
/// class always writes and falls back to parsing raw JSON directly when it's
/// absent. The next [encode] call for that console (any add/remove) re-saves
/// it encrypted, so migration happens passively per-console on first write —
/// no explicit migration pass is needed.
///
/// Uses `package:encrypt` (synchronous, pure-Dart AES-GCM via PointyCastle)
/// rather than an async cipher API on purpose: `Console.urls` (see
/// `console_x.dart`) is a plain synchronous getter read from many call
/// sites (`sources_screen.dart`, `scrape_orchestrator.dart`,
/// `catalog_repository.dart`) — an async cipher would force all of those to
/// become `Future`-returning, a much larger change than this feature
/// warrants.
class UrlsCipher {
  UrlsCipher(Uint8List keyBytes) : _encrypter = enc.Encrypter(enc.AES(enc.Key(keyBytes), mode: enc.AESMode.gcm));

  final enc.Encrypter _encrypter;
  static const _prefix = '#enc#';

  String encode(List<UrlEntry> urls) {
    final plaintext = jsonEncode(urls.map((e) => e.toJson()).toList());
    final iv = enc.IV.fromSecureRandom(12); // 96-bit nonce, standard for GCM.
    final encrypted = _encrypter.encrypt(plaintext, iv: iv);
    return '$_prefix${iv.base64}:${encrypted.base64}';
  }

  List<UrlEntry> decode(String stored) {
    if (stored.startsWith(_prefix)) {
      try {
        final parts = stored.substring(_prefix.length).split(':');
        final iv = enc.IV.fromBase64(parts[0]);
        final encrypted = enc.Encrypted.fromBase64(parts[1]);
        final plaintext = _encrypter.decrypt(encrypted, iv: iv);
        return _parseUrlList(plaintext);
      } catch (_) {
        return const [];
      }
    }
    // Legacy plaintext, written before encryption existed.
    return _parseUrlList(stored);
  }

  static List<UrlEntry> _parseUrlList(String json) {
    try {
      final decoded = jsonDecode(json) as List<dynamic>;
      return decoded.map((e) => UrlEntry.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return const [];
    }
  }
}
