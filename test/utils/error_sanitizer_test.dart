import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixelvault/core/utils/error_sanitizer.dart';

void main() {
  group('classifyError', () {
    test('maps FETCH_METADATA_FAILED to the metadata-fetch reason', () {
      expect(
        classifyError(PlatformException(code: 'FETCH_METADATA_FAILED', message: 'ignored')),
        ErrorReason.metadataFetch,
      );
    });

    test('falls back to `unexpected` for an unrecognized PlatformException code', () {
      expect(classifyError(PlatformException(code: 'SOME_OTHER_CODE')), ErrorReason.unexpected);
    });

    test('falls back to `unexpected` for a non-platform, non-network error', () {
      expect(classifyError(StateError('boom')), ErrorReason.unexpected);
      expect(classifyError(Exception('boom')), ErrorReason.unexpected);
    });

    test('maps 403/404/410 to an expired link and 5xx to an unreachable source', () {
      DioException withStatus(int status) => DioException(
            requestOptions: RequestOptions(path: '/'),
            response: Response(requestOptions: RequestOptions(path: '/'), statusCode: status),
          );

      expect(classifyError(withStatus(403)), ErrorReason.linkExpired);
      expect(classifyError(withStatus(404)), ErrorReason.linkExpired);
      expect(classifyError(withStatus(410)), ErrorReason.linkExpired);
      expect(classifyError(withStatus(500)), ErrorReason.sourceUnreachable);
      expect(classifyError(withStatus(400)), ErrorReason.network);
    });

    test('a network error with no response is still classified as network', () {
      expect(
        classifyError(DioException(
          requestOptions: RequestOptions(path: '/'),
          type: DioExceptionType.connectionTimeout,
        )),
        ErrorReason.network,
      );
    });

    // The whole point of classifying rather than formatting: an
    // `ErrorReason` is a closed enum, so there is no channel through which a
    // magnet/URL embedded in the original exception's message, details or
    // toString() could ever reach the screen.
    test('never carries a magnet/URL out of the original exception', () {
      const magnet = 'magnet:?xt=urn:btih:deadbeef&dn=Secret';
      final reasons = [
        classifyError(PlatformException(code: 'FETCH_METADATA_FAILED', message: 'Timed out for: $magnet')),
        classifyError(PlatformException(code: 'FETCH_METADATA_FAILED', message: 'ignored', details: magnet)),
        classifyError(Exception('contains $magnet')),
        classifyError(DioException(
          requestOptions: RequestOptions(path: magnet),
          message: 'failed for $magnet',
        )),
      ];

      for (final reason in reasons) {
        expect(ErrorReason.values, contains(reason));
        expect(reason.name, isNot(contains('magnet:')));
        expect(reason.name, isNot(contains('Secret')));
      }
    });
  });
}
