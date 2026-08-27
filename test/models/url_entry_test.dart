import 'package:flutter_test/flutter_test.dart';
import 'package:pixelvault/core/models/content_type.dart';
import 'package:pixelvault/core/models/url_entry.dart';

void main() {
  group('UrlEntry.fromJson', () {
    test('deserializes a minimal HTTP entry', () {
      final entry = UrlEntry.fromJson({
        'url': 'https://example.com/roms/',
      });
      expect(entry.url, 'https://example.com/roms/');
      expect(entry.contentType, ContentType.game); // default
      expect(entry.folders, isNull);
    });

    test('deserializes with explicit contentType and folders', () {
      final entry = UrlEntry.fromJson({
        'url': 'magnet:?xt=urn:btih:abc123',
        'contentType': 'MISCELLANEOUS',
        'folders': ['folder_a', 'folder_b'],
      });
      expect(entry.url, 'magnet:?xt=urn:btih:abc123');
      expect(entry.contentType, ContentType.miscellaneous);
      expect(entry.folders, ['folder_a', 'folder_b']);
    });
  });

  group('UrlEntry.toJson', () {
    test('serializes correctly and omits null folders', () {
      const entry = UrlEntry(
        url: 'https://example.com/',
        contentType: ContentType.game,
      );
      final json = entry.toJson();
      expect(json['url'], 'https://example.com/');
      expect(json['contentType'], 'GAME');
      expect(json.containsKey('folders'), isFalse);
    });

    test('includes folders when present', () {
      const entry = UrlEntry(
        url: 'https://example.com/',
        contentType: ContentType.retroachievements,
        folders: ['f1'],
      );
      final json = entry.toJson();
      expect(json['folders'], ['f1']);
    });

    test('round-trips through fromJson/toJson', () {
      const original = UrlEntry(
        url: 'magnet:?xt=abc',
        contentType: ContentType.miscellaneous,
        folders: ['x', 'y'],
      );
      final restored = UrlEntry.fromJson(original.toJson());
      expect(restored.url, original.url);
      expect(restored.contentType, original.contentType);
      expect(restored.folders, original.folders);
    });
  });

  group('UrlEntry.isTorrent', () {
    test('returns true for magnet URIs', () {
      const entry = UrlEntry(url: 'magnet:?xt=urn:btih:abc', contentType: ContentType.game);
      expect(entry.isTorrent, isTrue);
    });

    test('returns true for .torrent file URLs', () {
      const entry = UrlEntry(url: 'https://example.com/file.torrent', contentType: ContentType.game);
      expect(entry.isTorrent, isTrue);
    });

    test('returns false for regular HTTP URLs', () {
      const entry = UrlEntry(url: 'https://example.com/roms/', contentType: ContentType.game);
      expect(entry.isTorrent, isFalse);
    });
  });
}
