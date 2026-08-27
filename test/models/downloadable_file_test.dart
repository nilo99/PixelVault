import 'package:flutter_test/flutter_test.dart';
import 'package:pixelvault/core/models/downloadable_file.dart';

void main() {
  group('DownloadableFileWithTags', () {
    test('isTorrent is true only when both torrentFileIndex and torrentMagnet are set', () {
      const httpFile = DownloadableFileWithTags(
        id: 1,
        name: 'Test',
        fileName: 'test.zip',
        consoleId: 'gba',
        downloadUrl: 'https://example.com/test.zip',
        fileSize: 1000,
        fileExtension: '.zip',
      );
      expect(httpFile.isTorrent, isFalse);

      const partialTorrent = DownloadableFileWithTags(
        id: 2,
        name: 'Test',
        fileName: 'test.zip',
        consoleId: 'gba',
        downloadUrl: 'magnet:?xt=abc',
        fileSize: 1000,
        fileExtension: '.zip',
        torrentFileIndex: 0,
        // torrentMagnet is null
      );
      expect(partialTorrent.isTorrent, isFalse);

      const fullTorrent = DownloadableFileWithTags(
        id: 3,
        name: 'Test',
        fileName: 'test.zip',
        consoleId: 'gba',
        downloadUrl: 'magnet:?xt=abc',
        fileSize: 1000,
        fileExtension: '.zip',
        torrentFileIndex: 0,
        torrentMagnet: 'magnet:?xt=abc',
      );
      expect(fullTorrent.isTorrent, isTrue);
    });

    test('tagList splits pipe-delimited tags', () {
      const file = DownloadableFileWithTags(
        id: 1,
        name: 'Test',
        fileName: 'test.zip',
        consoleId: 'gba',
        downloadUrl: 'https://example.com/test.zip',
        fileSize: 1000,
        fileExtension: '.zip',
        tags: 'USA|GAME|EN',
      );
      expect(file.tagList, ['USA', 'GAME', 'EN']);
    });

    test('tagList returns empty list for null tags', () {
      const file = DownloadableFileWithTags(
        id: 1,
        name: 'Test',
        fileName: 'test.zip',
        consoleId: 'gba',
        downloadUrl: 'https://example.com/test.zip',
        fileSize: 1000,
        fileExtension: '.zip',
        tags: null,
      );
      expect(file.tagList, isEmpty);
    });

    test('tagList returns empty list for empty-string tags', () {
      const file = DownloadableFileWithTags(
        id: 1,
        name: 'Test',
        fileName: 'test.zip',
        consoleId: 'gba',
        downloadUrl: 'https://example.com/test.zip',
        fileSize: 1000,
        fileExtension: '.zip',
        tags: '',
      );
      expect(file.tagList, isEmpty);
    });
  });

  group('ConsoleWithFileCount', () {
    test('stores all fields correctly', () {
      const c = ConsoleWithFileCount(
        id: 'nintendo_gba',
        name: 'GBA',
        manufacturerId: 'nintendo',
        urlsJson: '[]',
        fileCount: 42,
        totalSize: 12345,
      );
      expect(c.id, 'nintendo_gba');
      expect(c.name, 'GBA');
      expect(c.fileCount, 42);
      expect(c.totalSize, 12345);
    });
  });
}
