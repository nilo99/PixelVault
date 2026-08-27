import 'package:flutter_test/flutter_test.dart';
import 'package:pixelvault/core/scraping/file_parsing.dart';

void main() {
  group('FileParsing.sanitizeFolderName', () {
    test('strips illegal characters and collapses spaces', () {
      expect(FileParsing.sanitizeFolderName('Game: The "Best" Sequel?'), 'Game The Best Sequel');
    });

    test('handles empty input', () {
      expect(FileParsing.sanitizeFolderName(''), '');
    });
  });

  group('FileParsing.shouldSkipFile', () {
    test('skips parent directory (..) navigation links', () {
      expect(FileParsing.shouldSkipFile('..'), isTrue);
    });

    test('skips current directory (.) links', () {
      expect(FileParsing.shouldSkipFile('.'), isTrue);
    });

    test('skips directory-like hrefs that end with /', () {
      expect(FileParsing.shouldSkipFile('subdir/'), isTrue);
    });

    test('does not skip normal file hrefs', () {
      expect(FileParsing.shouldSkipFile('game.zip'), isFalse);
      expect(FileParsing.shouldSkipFile('Pokemon Emerald (USA).7z'), isFalse);
    });
  });

  group('FileParsing.decodeUrlEncodedFileName', () {
    test('decodes percent-encoded file name', () {
      expect(
        FileParsing.decodeUrlEncodedFileName('Super%20Mario%20Bros.zip'),
        'Super Mario Bros.zip',
      );
    });

    test('returns original for clean names', () {
      expect(FileParsing.decodeUrlEncodedFileName('clean.zip'), 'clean.zip');
    });
  });

  group('FileParsing.isValidTag', () {
    test('accepts region tags', () {
      expect(FileParsing.isValidTag('USA'), isTrue);
      expect(FileParsing.isValidTag('Europe'), isTrue);
      expect(FileParsing.isValidTag('Japan'), isTrue);
    });

    test('accepts video standard tags', () {
      expect(FileParsing.isValidTag('PAL'), isTrue);
      expect(FileParsing.isValidTag('NTSC'), isTrue);
    });

    test('accepts content type tags', () {
      expect(FileParsing.isValidTag('DEMO'), isTrue);
      expect(FileParsing.isValidTag('DLC'), isTrue);
    });

    test('accepts language codes (2-3 chars)', () {
      expect(FileParsing.isValidTag('EN'), isTrue);
      expect(FileParsing.isValidTag('FR'), isTrue);
    });

    test('accepts version patterns', () {
      expect(FileParsing.isValidTag('V1'), isTrue);
      expect(FileParsing.isValidTag('V1.2'), isTrue);
    });

    test('accepts partial matchers (e.g. BETA, REV)', () {
      expect(FileParsing.isValidTag('BETA'), isTrue);
      expect(FileParsing.isValidTag('REV2'), isTrue);
    });

    test('rejects too-short tags', () {
      expect(FileParsing.isValidTag('A'), isFalse);
    });

    test('rejects random noise', () {
      expect(FileParsing.isValidTag('xyzabc'), isFalse);
    });
  });

  group('FileParsing.normalizeTag', () {
    test('uppercases video standards', () {
      expect(FileParsing.normalizeTag('pal'), 'PAL');
      expect(FileParsing.normalizeTag('ntsc'), 'NTSC');
    });

    test('uppercases short tags (<= 3 chars)', () {
      expect(FileParsing.normalizeTag('en'), 'EN');
      expect(FileParsing.normalizeTag('fr'), 'FR');
    });

    test('title-cases longer tags', () {
      expect(FileParsing.normalizeTag('europe'), 'Europe');
      expect(FileParsing.normalizeTag('JAPAN'), 'Japan');
    });
  });

  group('FileParsing.buildDownloadUrl edge cases', () {
    test('normalizes parent (..) segments', () {
      final url = FileParsing.buildDownloadUrl(
        'https://example.com/a/b/',
        '../file.zip',
      );
      expect(url, 'https://example.com/a/file.zip');
    });

    test('strips trailing slashes on base and leading on href', () {
      final url = FileParsing.buildDownloadUrl(
        'https://example.com/roms/',
        '/file.zip',
      );
      expect(url, 'https://example.com/roms/file.zip');
    });

    test('regression: excessive ../ segments cannot escape the host', () {
      final url = FileParsing.buildDownloadUrl(
        'http://good.com/dir',
        '../../evil.com/x',
      );
      expect(Uri.parse(url).host, 'good.com');
      expect(url, 'http://good.com/evil.com/x');
    });
  });
}
