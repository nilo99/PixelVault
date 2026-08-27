import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pixelvault/core/models/content_type.dart';
import 'package:pixelvault/core/models/url_entry.dart';
import 'package:pixelvault/core/security/urls_cipher.dart';

void main() {
  late UrlsCipher cipher;

  setUp(() {
    // A fixed 32-byte (AES-256) key — deterministic for the test, not the
    // real random-per-install key `UrlsCipherHolder` generates in the app.
    cipher = UrlsCipher(Uint8List.fromList(List.generate(32, (i) => i)));
  });

  const urls = [
    UrlEntry(url: 'https://example.com/gba/', contentType: ContentType.game),
    UrlEntry(url: 'magnet:?xt=urn:btih:deadbeef', contentType: ContentType.retroachievements),
  ];

  group('UrlsCipher', () {
    test('encode then decode round-trips the original urls', () {
      final stored = cipher.encode(urls);
      final decoded = cipher.decode(stored);

      expect(decoded, hasLength(urls.length));
      for (var i = 0; i < urls.length; i++) {
        expect(decoded[i].url, urls[i].url);
        expect(decoded[i].contentType, urls[i].contentType);
      }
    });

    test('encoded output is prefixed and never contains the plaintext url', () {
      final stored = cipher.encode(urls);
      expect(stored, startsWith('#enc#'));
      expect(stored, isNot(contains('magnet:')));
      expect(stored, isNot(contains('example.com')));
    });

    test('two encodes of the same input produce different ciphertext (fresh IV each time)', () {
      final first = cipher.encode(urls);
      final second = cipher.encode(urls);
      expect(first, isNot(equals(second)));
    });

    test('decodes legacy plaintext JSON (no #enc# prefix) written before encryption existed', () {
      final legacyJson = jsonEncode(urls.map((e) => e.toJson()).toList());
      final decoded = cipher.decode(legacyJson);

      expect(decoded, hasLength(urls.length));
      expect(decoded[0].url, urls[0].url);
    });

    test('decoding tampered/garbage ciphertext fails closed to an empty list, not a throw', () {
      final stored = cipher.encode(urls);
      final tampered = '${stored.substring(0, stored.length - 4)}xxxx';

      expect(() => cipher.decode(tampered), returnsNormally);
      expect(cipher.decode(tampered), isEmpty);
      expect(cipher.decode('#enc#not-even-valid-base64:also-not'), isEmpty);
      expect(cipher.decode('not json at all'), isEmpty);
    });
  });
}
