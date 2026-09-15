import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixelvault/core/download/download_item.dart';
import 'package:pixelvault/core/download/download_progress_tracker.dart';
import 'package:pixelvault/core/download/download_status.dart';

DownloadItem _attempt(
  int id, {
  String url = 'https://example.com/game.chd',
  DownloadStatus status = DownloadStatus.downloading,
}) {
  return DownloadItem(
    id: id,
    downloadUrl: url,
    name: 'Game',
    fileName: 'game.chd',
    fileSize: 100,
    status: status,
  );
}

void main() {
  late ProviderContainer container;
  late DownloadProgressTrackerNotifier tracker;

  setUp(() {
    container = ProviderContainer();
    tracker = container.read(downloadProgressTrackerProvider.notifier);
  });

  tearDown(() => container.dispose());

  group('cancelled is final', () {
    test('a status update arriving after a cancel is ignored', () {
      tracker.addDownload(_attempt(1));
      tracker.updateDownloadStatus(1, DownloadStatus.cancelled);

      // What a copy or extraction still finishing in the background would send.
      tracker.updateDownloadStatus(1, DownloadStatus.unzipping);
      tracker.updateDownloadStatus(1, DownloadStatus.completed);

      expect(tracker.get(1)?.status, DownloadStatus.cancelled);
    });

    test('other attempts are unaffected', () {
      tracker.addDownload(_attempt(1));
      tracker.addDownload(_attempt(2, url: 'https://example.com/other.chd'));
      tracker.updateDownloadStatus(1, DownloadStatus.cancelled);

      tracker.updateDownloadStatus(2, DownloadStatus.completed);

      expect(tracker.get(2)?.status, DownloadStatus.completed);
    });

    test('a cancelled attempt can be retried (as a new attempt)', () {
      tracker.addDownload(_attempt(1, status: DownloadStatus.cancelled));
      expect(tracker.canRetryDownload(1), isTrue);
    });
  });

  group('queuedFor', () {
    test('finds a running attempt at the URL', () {
      tracker.addDownload(_attempt(1));
      expect(tracker.queuedFor('https://example.com/game.chd')?.id, 1);
    });

    test('finds an interrupted attempt at the URL', () {
      tracker.addDownload(_attempt(1, status: DownloadStatus.stopped));
      expect(tracker.queuedFor('https://example.com/game.chd')?.id, 1);
    });

    test('ignores finished, failed and cancelled attempts', () {
      tracker.addDownload(_attempt(1, status: DownloadStatus.completed));
      tracker.addDownload(_attempt(2, status: DownloadStatus.failed));
      tracker.addDownload(_attempt(3, status: DownloadStatus.cancelled));
      expect(tracker.queuedFor('https://example.com/game.chd'), isNull);
    });

    test('never matches an empty URL', () {
      tracker.addDownload(_attempt(1, url: ''));
      expect(tracker.queuedFor(''), isNull);
    });
  });

  group('mergeRestored', () {
    test('keeps live state and adds only attempts the tracker does not know', () {
      // Started while the restore was still reading the database.
      tracker.addDownload(_attempt(5));
      tracker.updateDownloadProgress(5, 0.6, 1.0, 60);

      tracker.mergeRestored([
        _attempt(5, status: DownloadStatus.stopped), // stale copy of the live one
        _attempt(4, status: DownloadStatus.completed),
        _attempt(3, status: DownloadStatus.failed),
      ]);

      final state = container.read(downloadProgressTrackerProvider);
      expect(state.map((d) => d.id), [3, 4, 5], reason: 'restored oldest first, then live');
      expect(tracker.get(5)?.status, DownloadStatus.downloading);
      expect(tracker.get(5)?.progress, 0.6);
    });
  });

  test('removeMany removes exactly the given attempts', () {
    tracker.addDownload(_attempt(1));
    tracker.addDownload(_attempt(2));
    tracker.addDownload(_attempt(3));

    tracker.removeMany({1, 3});

    expect(container.read(downloadProgressTrackerProvider).map((d) => d.id), [2]);
  });
}
