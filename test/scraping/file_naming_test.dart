import 'package:flutter_test/flutter_test.dart';
import 'package:pixelvault/core/scraping/file_naming.dart';

void main() {
  group('fileNameFromHref', () {
    test('keeps a plain file name unchanged (idempotent for clean input)', () {
      expect(FileNaming.fileNameFromHref('Game.iso'), 'Game.iso');
      expect(FileNaming.fileNameFromHref(FileNaming.fileNameFromHref('Game.iso')), 'Game.iso');
    });

    test('takes only the last segment of a nested href', () {
      // Staging previously opened `<dir>/12_sub/dir/Game.iso`, a directory
      // that does not exist, so the download died before writing a byte.
      expect(FileNaming.fileNameFromHref('sub/dir/Game.iso'), 'Game.iso');
      expect(FileNaming.fileNameFromHref('/roms/gba/Game.iso'), 'Game.iso');
    });

    test('reduces an absolute URL to its file name, never the host', () {
      expect(
        FileNaming.fileNameFromHref('https://example.com/files/Game.chd'),
        'Game.chd',
      );
    });

    test('strips query strings and fragments', () {
      expect(FileNaming.fileNameFromHref('Game.chd?dl=1'), 'Game.chd');
      expect(FileNaming.fileNameFromHref('Game.chd#part2'), 'Game.chd');
      expect(FileNaming.fileNameFromHref('https://h/x/Game.iso?token=a&b=c'), 'Game.iso');
    });

    test('percent-decodes the name', () {
      expect(FileNaming.fileNameFromHref('Test%20Game%20(USA).zip'), 'Test Game (USA).zip');
    });

    test('leaves a literal + alone (ROM names use it)', () {
      expect(FileNaming.fileNameFromHref('Sonic 3 + Knuckles.md'), 'Sonic 3 + Knuckles.md');
    });

    test('survives a malformed percent sequence instead of throwing', () {
      expect(FileNaming.fileNameFromHref('100%_Complete.iso'), isNotEmpty);
    });

    test('replaces characters SAF/FAT reject', () {
      expect(FileNaming.fileNameFromHref('Game:Special*Edition.iso'), 'Game_Special_Edition.iso');
      expect(FileNaming.fileNameFromHref('A<B>C|D.iso'), 'A_B_C_D.iso');
    });

    test('a bare ? is treated as the start of a query string, as in any href', () {
      // `?` cannot appear literally in a URL path (it would be %3F), so
      // everything after it is a query — including a fake-looking extension.
      expect(FileNaming.fileNameFromHref('Game.iso?x=1'), 'Game.iso');
    });

    test('drops trailing dots and spaces, which Android silently strips', () {
      // A file created as "Game.iso ." comes back named "Game.iso", so the
      // app could never find what it had just written.
      expect(FileNaming.fileNameFromHref('Game.iso .'), 'Game.iso');
    });

    test('returns empty for a directory-ish or unusable href', () {
      expect(FileNaming.fileNameFromHref('../'), '');
      expect(FileNaming.fileNameFromHref('/'), '');
      expect(FileNaming.fileNameFromHref(''), '');
    });

    test('caps an absurdly long name while keeping its extension', () {
      final long = '${'a' * 400}.iso';
      final result = FileNaming.fileNameFromHref(long);
      expect(result.length, lessThanOrEqualTo(200));
      expect(result, endsWith('.iso'));
    });
  });

  group('extensionOf', () {
    test('returns the lowercased extension with its dot', () {
      expect(FileNaming.extensionOf('Game.ISO'), '.iso');
      expect(FileNaming.extensionOf('Game.chd'), '.chd');
      expect(FileNaming.extensionOf('Game.7z'), '.7z');
    });

    test('rejects a digits-only tail, which is a version not an extension', () {
      // `Final Fantasy VII (Disc 1.2)` must not report an extension of `.2`.
      expect(FileNaming.extensionOf('Final Fantasy VII (Disc 1.2)'), '');
      expect(FileNaming.extensionOf('Game v1.0'), '');
    });

    test('returns empty when there is no extension at all', () {
      expect(FileNaming.extensionOf('Game'), '');
      expect(FileNaming.extensionOf('.hidden'), '');
      expect(FileNaming.extensionOf('Game.'), '');
    });

    test('rejects an over-long tail that cannot be a real extension', () {
      expect(FileNaming.extensionOf('archive.superlongextension'), '');
    });
  });

  group('contentExtensionOf', () {
    test('unwraps an archive to the format the user actually gets', () {
      // The direct cause of "ficheiros iso aparecem como .7z": the catalog
      // stored the transport format, not the payload.
      expect(FileNaming.contentExtensionOf('Game.iso.7z'), '.iso');
      expect(FileNaming.contentExtensionOf('Game.chd.zip'), '.chd');
    });

    test('leaves a plain file alone', () {
      expect(FileNaming.contentExtensionOf('Game.iso'), '.iso');
      expect(FileNaming.contentExtensionOf('Game.chd'), '.chd');
    });

    test('falls back to the archive extension when there is no inner one', () {
      expect(FileNaming.contentExtensionOf('Game.7z'), '.7z');
      expect(FileNaming.contentExtensionOf('Pack.zip'), '.zip');
    });
  });

  group('isArchiveWrapped', () {
    test('is true only when a real payload sits inside an archive', () {
      expect(FileNaming.isArchiveWrapped('Game.iso.7z'), isTrue);
      expect(FileNaming.isArchiveWrapped('Game.7z'), isFalse);
      expect(FileNaming.isArchiveWrapped('Game.iso'), isFalse);
    });
  });

  group('fallbackName', () {
    test('falls back to the display name, then to a generated one', () {
      expect(FileNaming.fallbackName(12, 'Some Game'), 'Some Game');
      expect(FileNaming.fallbackName(12, '///'), 'pixelvault_12');
      expect(FileNaming.fallbackName(12, ''), 'pixelvault_12');
    });
  });
}
