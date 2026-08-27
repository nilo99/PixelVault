import 'package:flutter_test/flutter_test.dart';
import 'package:pixelvault/core/download/download_status.dart';

void main() {
  group('DownloadStatus enum', () {
    test('contains all expected values', () {
      expect(DownloadStatus.values, containsAll([
        DownloadStatus.downloading,
        DownloadStatus.copying,
        DownloadStatus.unzipping,
        DownloadStatus.completed,
        DownloadStatus.failed,
        DownloadStatus.stopped,
      ]));
    });

    test('has exactly 6 values', () {
      expect(DownloadStatus.values.length, 6);
    });

    test('can be looked up by name', () {
      expect(DownloadStatus.values.byName('downloading'), DownloadStatus.downloading);
      expect(DownloadStatus.values.byName('completed'), DownloadStatus.completed);
      expect(DownloadStatus.values.byName('failed'), DownloadStatus.failed);
    });
  });
}
