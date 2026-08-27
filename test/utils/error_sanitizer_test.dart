import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixelvault/core/utils/error_sanitizer.dart';

void main() {
  group('sanitizeErrorForDisplay', () {
    test('maps FETCH_METADATA_FAILED to a friendly, code-derived message', () {
      final result = sanitizeErrorForDisplay(
        PlatformException(code: 'FETCH_METADATA_FAILED', message: 'ignored'),
      );
      expect(result, contains('metadata fetch failed'));
    });

    test('passes through an unrecognized PlatformException code verbatim', () {
      final result = sanitizeErrorForDisplay(PlatformException(code: 'SOME_OTHER_CODE'));
      expect(result, 'SOME_OTHER_CODE');
    });

    test('falls back to a generic message for a non-PlatformException error', () {
      expect(sanitizeErrorForDisplay(StateError('boom')), 'an unexpected error occurred');
      expect(sanitizeErrorForDisplay(Exception('boom')), 'an unexpected error occurred');
    });

    test('never leaks a magnet/URL embedded in the original exception message or details', () {
      const magnet = 'magnet:?xt=urn:btih:deadbeef&dn=Secret';
      final fromMessage = sanitizeErrorForDisplay(
        PlatformException(code: 'FETCH_METADATA_FAILED', message: 'Timed out for: $magnet'),
      );
      final fromDetails = sanitizeErrorForDisplay(
        PlatformException(code: 'FETCH_METADATA_FAILED', message: 'ignored', details: magnet),
      );
      final fromGenericToString = sanitizeErrorForDisplay(Exception('contains $magnet'));

      for (final result in [fromMessage, fromDetails, fromGenericToString]) {
        expect(result, isNot(contains('magnet:')));
        expect(result, isNot(contains('Secret')));
      }
    });
  });
}
