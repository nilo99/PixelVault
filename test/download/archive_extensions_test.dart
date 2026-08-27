import 'package:flutter_test/flutter_test.dart';
import 'package:pixelvault/core/download/download_manager.dart';

void main() {
  group('ArchiveExtensions.isExtractable', () {
    test('recognizes all supported archive formats', () {
      const supported = ['.zip', '.7z', '.rar', '.tar', '.gz', '.tgz', '.bz2', '.xz', '.cab'];
      for (final ext in supported) {
        expect(ArchiveExtensions.isExtractable(ext), isTrue, reason: '$ext should be extractable');
      }
    });

    test('is case-insensitive', () {
      expect(ArchiveExtensions.isExtractable('.ZIP'), isTrue);
      expect(ArchiveExtensions.isExtractable('.Zip'), isTrue);
      expect(ArchiveExtensions.isExtractable('.RAR'), isTrue);
      expect(ArchiveExtensions.isExtractable('.7Z'), isTrue);
    });

    test('works without leading dot', () {
      expect(ArchiveExtensions.isExtractable('zip'), isTrue);
      expect(ArchiveExtensions.isExtractable('rar'), isTrue);
      expect(ArchiveExtensions.isExtractable('7z'), isTrue);
    });

    test('rejects non-archive extensions', () {
      expect(ArchiveExtensions.isExtractable('.iso'), isFalse);
      expect(ArchiveExtensions.isExtractable('.bin'), isFalse);
      expect(ArchiveExtensions.isExtractable('.rom'), isFalse);
      expect(ArchiveExtensions.isExtractable('.gba'), isFalse);
    });

    test('returns false for empty string', () {
      expect(ArchiveExtensions.isExtractable(''), isFalse);
    });
  });
}
