import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixelvault/core/download/download_item.dart';
import 'package:pixelvault/core/download/download_progress_tracker.dart';
import 'package:pixelvault/core/download/download_status.dart';

DownloadItem _item(int id, String fileName, {DownloadStatus status = DownloadStatus.downloading}) {
  return DownloadItem(id: id, name: fileName, fileName: fileName, fileSize: 1000, status: status);
}

void main() {
  late ProviderContainer container;
  late DownloadProgressTrackerNotifier notifier;

  setUp(() {
    container = ProviderContainer();
    notifier = container.read(downloadProgressTrackerProvider.notifier);
  });

  tearDown(() => container.dispose());

  test('addDownload adds a new item to the list', () {
    notifier.addDownload(_item(1, 'a.zip'));
    expect(container.read(downloadProgressTrackerProvider), hasLength(1));
    expect(container.read(downloadProgressTrackerProvider).single.fileName, 'a.zip');
  });

  test('addDownload is a no-op when a download with the same id already exists', () {
    notifier.addDownload(_item(1, 'a.zip'));
    notifier.updateDownloadProgress(1, 0.5, 2.0, 500);

    notifier.addDownload(_item(1, 'a.zip'));

    final state = container.read(downloadProgressTrackerProvider);
    expect(state, hasLength(1));
    // The second addDownload must not have clobbered the in-progress state.
    expect(state.single.progress, 0.5);
  });

  test('two different ids sharing the same fileName are tracked independently', () {
    notifier.addDownload(_item(1, 'a.zip'));
    notifier.addDownload(_item(2, 'a.zip'));

    notifier.updateDownloadProgress(1, 0.75, 3.5, 750);

    final state = container.read(downloadProgressTrackerProvider);
    expect(state, hasLength(2));
    expect(notifier.get(1)?.progress, 0.75);
    expect(notifier.get(2)?.progress, 0);
  });

  test('updateDownloadProgress only updates the matching item', () {
    notifier.addDownload(_item(1, 'a.zip'));
    notifier.addDownload(_item(2, 'b.zip'));

    notifier.updateDownloadProgress(1, 0.75, 3.5, 750);

    final state = container.read(downloadProgressTrackerProvider);
    final a = state.firstWhere((d) => d.id == 1);
    final b = state.firstWhere((d) => d.id == 2);
    expect(a.progress, 0.75);
    expect(a.downloadSpeed, 3.5);
    expect(a.downloadedBytes, 750);
    expect(b.progress, 0);
  });

  test('updateDownloadStatus only updates the matching item', () {
    notifier.addDownload(_item(1, 'a.zip'));
    notifier.addDownload(_item(2, 'b.zip'));

    notifier.updateDownloadStatus(1, DownloadStatus.completed);

    final state = container.read(downloadProgressTrackerProvider);
    expect(state.firstWhere((d) => d.id == 1).status, DownloadStatus.completed);
    expect(state.firstWhere((d) => d.id == 2).status, DownloadStatus.downloading);
  });

  test('removeDownload removes only the matching item', () {
    notifier.addDownload(_item(1, 'a.zip'));
    notifier.addDownload(_item(2, 'b.zip'));

    notifier.removeDownload(1);

    final state = container.read(downloadProgressTrackerProvider);
    expect(state, hasLength(1));
    expect(state.single.fileName, 'b.zip');
  });

  group('canRetryDownload', () {
    test('is true for failed downloads', () {
      notifier.addDownload(_item(1, 'a.zip', status: DownloadStatus.failed));
      expect(notifier.canRetryDownload(1), isTrue);
    });

    test('is true for stopped downloads', () {
      notifier.addDownload(_item(1, 'a.zip', status: DownloadStatus.stopped));
      expect(notifier.canRetryDownload(1), isTrue);
    });

    test('is false for an in-progress download', () {
      notifier.addDownload(_item(1, 'a.zip', status: DownloadStatus.downloading));
      expect(notifier.canRetryDownload(1), isFalse);
    });

    test('is false for a completed download', () {
      notifier.addDownload(_item(1, 'a.zip', status: DownloadStatus.completed));
      expect(notifier.canRetryDownload(1), isFalse);
    });

    test('is false for an unknown id', () {
      expect(notifier.canRetryDownload(999), isFalse);
    });
  });

  test('resetDownloadForRetry zeroes progress/speed/bytes and sets status to downloading', () {
    notifier.addDownload(_item(1, 'a.zip', status: DownloadStatus.failed));
    notifier.updateDownloadProgress(1, 0.4, 1.2, 400);

    notifier.resetDownloadForRetry(1);

    final item = notifier.get(1)!;
    expect(item.progress, 0);
    expect(item.downloadSpeed, 0);
    expect(item.downloadedBytes, 0);
    expect(item.status, DownloadStatus.downloading);
  });

  group('hasActiveDownloads', () {
    test('is true when a download is downloading, copying, or unzipping', () {
      for (final status in [DownloadStatus.downloading, DownloadStatus.copying, DownloadStatus.unzipping]) {
        final c = ProviderContainer();
        final n = c.read(downloadProgressTrackerProvider.notifier);
        n.addDownload(_item(1, 'a.zip', status: status));
        expect(n.hasActiveDownloads, isTrue, reason: 'status=$status');
        c.dispose();
      }
    });

    test('is false when every download is completed, failed, or stopped', () {
      notifier.addDownload(_item(1, 'a.zip', status: DownloadStatus.completed));
      notifier.addDownload(_item(2, 'b.zip', status: DownloadStatus.failed));
      notifier.addDownload(_item(3, 'c.zip', status: DownloadStatus.stopped));
      expect(notifier.hasActiveDownloads, isFalse);
    });

    test('is false when there are no downloads at all', () {
      expect(notifier.hasActiveDownloads, isFalse);
    });
  });

  group('get', () {
    test('returns the matching item', () {
      notifier.addDownload(_item(1, 'a.zip'));
      expect(notifier.get(1)?.fileName, 'a.zip');
    });

    test('returns null for an unknown id', () {
      expect(notifier.get(999), isNull);
    });
  });
}
