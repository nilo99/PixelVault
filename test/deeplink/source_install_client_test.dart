import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixelvault/core/deeplink/source_install_client.dart';

const _testSecret = 'test-secret-value';

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.responder);
  final ResponseBody Function(RequestOptions options) responder;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async =>
      responder(options);
}

void main() {
  test('resolve() parses a successful response and sends a valid ts/sig', () async {
    Map<String, dynamic>? capturedQuery;
    final dio = Dio()
      ..httpClientAdapter = _FakeAdapter((options) {
        capturedQuery = options.queryParameters;
        return ResponseBody.fromString(
          '{"consoleId":"nintendo_gba","url":"magnet:?xt=urn:btih:abc","contentType":"GAME"}',
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });
    final client = SourceInstallClient(baseUrl: 'https://example.com', dio: dio, hmacSecret: _testSecret);

    final resolved = await client.resolve('tok123');

    expect(resolved.consoleId, 'nintendo_gba');
    expect(resolved.url, 'magnet:?xt=urn:btih:abc');
    expect(resolved.contentType, 'GAME');

    final ts = capturedQuery?['ts'] as String?;
    final sig = capturedQuery?['sig'] as String?;
    expect(capturedQuery?['token'], 'tok123');
    expect(ts, isNotNull);
    expect(sig, isNotNull);
    final expectedSig = Hmac(sha256, utf8.encode(_testSecret)).convert(utf8.encode('tok123:$ts')).toString();
    expect(sig, expectedSig);
  });

  test('resolve() throws SourceInstallException for an empty token', () async {
    final client = SourceInstallClient(baseUrl: 'https://example.com', dio: Dio(), hmacSecret: _testSecret);
    expect(() => client.resolve(''), throwsA(isA<SourceInstallException>()));
  });

  test('resolve() throws a friendly message on a 404 (invalid/expired token)', () async {
    final dio = Dio()
      ..httpClientAdapter = _FakeAdapter((options) {
        return ResponseBody.fromString('{"error":"not found"}', 404);
      });
    final client = SourceInstallClient(baseUrl: 'https://example.com', dio: dio, hmacSecret: _testSecret);

    await expectLater(
      client.resolve('expired'),
      throwsA(isA<SourceInstallException>().having((e) => e.message, 'message', contains('já não é válido'))),
    );
  });

  test('resolve() throws a friendly message on a 403 (invalid signature)', () async {
    final dio = Dio()
      ..httpClientAdapter = _FakeAdapter((options) {
        return ResponseBody.fromString('{"error":"forbidden"}', 403);
      });
    final client = SourceInstallClient(baseUrl: 'https://example.com', dio: dio, hmacSecret: _testSecret);

    await expectLater(
      client.resolve('tok'),
      throwsA(isA<SourceInstallException>().having((e) => e.message, 'message', contains('já não é válido'))),
    );
  });

  group('hmac secret resolution', () {
    test('release mode with no secret throws StateError (must not silently ship an empty secret)', () {
      expect(
        () => SourceInstallClient.resolveHmacSecret(null, isRelease: true),
        throwsA(isA<StateError>()),
      );
    });

    test('debug mode with no secret falls back to the placeholder instead of crashing', () {
      expect(
        SourceInstallClient.resolveHmacSecret(null, isRelease: false),
        'debug-placeholder-secret-not-for-production',
      );
    });

    test('an explicitly injected secret always wins, in both release and debug', () {
      expect(SourceInstallClient.resolveHmacSecret(_testSecret, isRelease: false), _testSecret);
      expect(SourceInstallClient.resolveHmacSecret(_testSecret, isRelease: true), _testSecret);
    });

    test('constructing a client with no secret does not throw, even though PIXELVAULT_HMAC_SECRET '
        'is not defined for this test run', () {
      expect(() => SourceInstallClient(baseUrl: 'https://example.com', dio: Dio()), returnsNormally);
    });

    test('resolve() with the debug placeholder secret still runs end-to-end, failing as a normal '
        '403 SourceInstallException rather than crashing', () async {
      final dio = Dio()
        ..httpClientAdapter = _FakeAdapter((options) {
          return ResponseBody.fromString('{"error":"forbidden"}', 403);
        });
      final client = SourceInstallClient(baseUrl: 'https://example.com', dio: dio);

      await expectLater(
        client.resolve('tok'),
        throwsA(isA<SourceInstallException>().having((e) => e.message, 'message', contains('já não é válido'))),
      );
    });
  });
}
