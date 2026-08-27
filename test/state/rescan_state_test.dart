import 'package:flutter_test/flutter_test.dart';
import 'package:pixelvault/core/state/rescan_state.dart';

void main() {
  group('RescanState defaults', () {
    test('has expected default values', () {
      const s = RescanState();
      expect(s.isRescanning, isFalse);
      expect(s.lastRescanTime, isNull);
      expect(s.progressMessage, '');
      expect(s.torrentFetchProgress, '');
      expect(s.errorMessage, isNull);
    });
  });

  group('RescanState.copyWith', () {
    test('updates only the specified fields', () {
      const original = RescanState();
      final updated = original.copyWith(
        isRescanning: true,
        progressMessage: 'Processing console 1/10: GBA',
      );
      expect(updated.isRescanning, isTrue);
      expect(updated.progressMessage, 'Processing console 1/10: GBA');
      // unchanged
      expect(updated.lastRescanTime, isNull);
      expect(updated.torrentFetchProgress, '');
    });

    test('errorMessage can be set and cleared (null)', () {
      const original = RescanState();
      final withError = original.copyWith(errorMessage: 'Scrape failed');
      expect(withError.errorMessage, 'Scrape failed');

      // errorMessage is nullable and copyWith always passes it through
      // (not using ?? like the other fields), so passing null clears it.
      final cleared = withError.copyWith(errorMessage: null);
      expect(cleared.errorMessage, isNull);
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
