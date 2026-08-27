import 'package:flutter_test/flutter_test.dart';
import 'package:pixelvault/core/download/download_item.dart';
import 'package:pixelvault/core/download/download_status.dart';

void main() {
  const base = DownloadItem(
    id: 1,
    name: 'Pokemon Emerald',
    fileName: 'Pokemon Emerald (USA).zip',
    fileSize: 12345678,
  );

  group('DownloadItem defaults', () {
    test('has sensible defaults', () {
      expect(base.downloadSpeed, 0);
      expect(base.progress, 0);
      expect(base.status, DownloadStatus.downloading);
      expect(base.downloadedBytes, 0);
      expect(base.isTorrent, isFalse);
    });
  });

  group('DownloadItem.copyWith', () {
    test('updates only the specified fields', () {
      final updated = base.copyWith(
        progress: 0.5,
        downloadSpeed: 2.5,
        downloadedBytes: 6000000,
      );
      expect(updated.progress, 0.5);
      expect(updated.downloadSpeed, 2.5);
      expect(updated.downloadedBytes, 6000000);
      // unchanged fields
      expect(updated.name, base.name);
      expect(updated.fileName, base.fileName);
      expect(updated.fileSize, base.fileSize);
      expect(updated.status, DownloadStatus.downloading);
      expect(updated.isTorrent, isFalse);
    });

    test('can update status', () {
      final failed = base.copyWith(status: DownloadStatus.failed);
      expect(failed.status, DownloadStatus.failed);

      final completed = base.copyWith(status: DownloadStatus.completed);
      expect(completed.status, DownloadStatus.completed);
    });

    test('preserves isTorrent flag (not in copyWith params)', () {
      const torrentItem = DownloadItem(
        id: 2,
        name: 'Torrent Game',
        fileName: 'game.iso',
        fileSize: 999,
        isTorrent: true,
      );
      final updated = torrentItem.copyWith(progress: 0.75);
      expect(updated.isTorrent, isTrue);
    });
  });
}
