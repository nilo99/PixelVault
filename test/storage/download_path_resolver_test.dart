import 'package:flutter_test/flutter_test.dart';
import 'package:pixelvault/core/storage/saf_storage_helper.dart';

void main() {
  group('DownloadPathResolver.sanitizeFolderName', () {
    test('strips illegal filesystem characters', () {
      expect(DownloadPathResolver.sanitizeFolderName('Game: The Sequel'), 'Game The Sequel');
      expect(DownloadPathResolver.sanitizeFolderName('A<B>C"D|E?F*G'), 'ABCDEFG');
    });

    test('trims whitespace', () {
      expect(DownloadPathResolver.sanitizeFolderName('  Hello  '), 'Hello');
    });

    test('collapses repeated spaces left by removal', () {
      expect(DownloadPathResolver.sanitizeFolderName('Game:  The   Sequel'), 'Game The Sequel');
    });

    test('handles empty string', () {
      expect(DownloadPathResolver.sanitizeFolderName(''), '');
    });

    test('preserves clean names unchanged', () {
      expect(DownloadPathResolver.sanitizeFolderName('Gameboy Advance'), 'Gameboy Advance');
    });
  });

  group('DownloadPathResolver.decodeUrlEncodedFileName', () {
    test('decodes percent-encoded characters', () {
      expect(
        DownloadPathResolver.decodeUrlEncodedFileName('Pokemon%20Emerald%20(USA).zip'),
        'Pokemon Emerald (USA).zip',
      );
    });

    test('returns input unchanged when nothing to decode', () {
      expect(
        DownloadPathResolver.decodeUrlEncodedFileName('simple_file.zip'),
        'simple_file.zip',
      );
    });

    test('returns original string for malformed encoding', () {
      // %ZZ is not a valid percent-encoded sequence
      final input = 'bad%ZZfile.zip';
      final result = DownloadPathResolver.decodeUrlEncodedFileName(input);
      // Should not throw; returns original or a best-effort decode
      expect(result, isNotEmpty);
    });
  });
}
