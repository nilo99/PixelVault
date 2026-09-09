import 'package:flutter_test/flutter_test.dart';
import 'package:pixelvault/core/state/rescan_state.dart';

void main() {
  group('RescanState defaults', () {
    test('has expected default values', () {
      const s = RescanState();
      expect(s.isRescanning, isFalse);
      expect(s.lastRescanTime, isNull);
      expect(s.progressNotice, isNull);
      expect(s.torrentFetchProgress, '');
      expect(s.errorNotice, isNull);
    });
  });

  group('RescanState.copyWith', () {
    test('updates only the specified fields', () {
      const original = RescanState();
      final updated = original.copyWith(
        isRescanning: true,
        progressNotice: const RescanNotice(
          RescanNoticeKind.processing,
          console: 'GBA',
          current: 1,
          total: 10,
        ),
      );
      expect(updated.isRescanning, isTrue);
      expect(updated.progressNotice?.kind, RescanNoticeKind.processing);
      expect(updated.progressNotice?.console, 'GBA');
      expect(updated.progressNotice?.current, 1);
      expect(updated.progressNotice?.total, 10);
      // unchanged
      expect(updated.lastRescanTime, isNull);
      expect(updated.torrentFetchProgress, '');
    });

    test('errorNotice can be set and cleared (null)', () {
      const original = RescanState();
      final withError =
          original.copyWith(errorNotice: const RescanNotice.literal('Scrape failed'));
      expect(withError.errorNotice?.text, 'Scrape failed');

      // errorNotice is nullable and copyWith always passes it through
      // (not using ?? like the other fields), so passing null clears it.
      final cleared = withError.copyWith(errorNotice: null);
      expect(cleared.errorNotice, isNull);
    });

    test('lastRescanTime is set when provided', () {
      final now = DateTime.now();
      const original = RescanState();
      final updated = original.copyWith(lastRescanTime: now);
      expect(updated.lastRescanTime, now);
    });

    test('torrentFetchProgress can be set and cleared', () {
      const original = RescanState();
      final updated = original.copyWith(torrentFetchProgress: 'Fetching metadata...');
      expect(updated.torrentFetchProgress, 'Fetching metadata...');

      final cleared = updated.copyWith(torrentFetchProgress: '');
      expect(cleared.torrentFetchProgress, '');
    });
  });
}
