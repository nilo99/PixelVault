import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// A source resolved from an install token — mirrors the JSON the
/// companion website's `/api/resolve` endpoint returns. The actual
/// magnet/URL is never shown on the website itself; it only ever leaves the
/// server through this endpoint.
class ResolvedSource {
  const ResolvedSource({required this.consoleId, required this.url, required this.contentType});

  final String consoleId;
  final String url;
  final String contentType;
}

class SourceInstallException implements Exception {
  const SourceInstallException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Talks to the companion "install source" website (see the sibling
/// `pixelvault-sources-web/` project) — the site shows generic labels like
/// "Fonte 1"/"Fonte 2" per console, never the magnet itself; tapping
/// "Instalar" opens `pixelvault://install?token=<opaque>`, and this client
/// exchanges that token for the real source data.
class SourceInstallClient {
  SourceInstallClient({required this.baseUrl, Dio? dio, String? hmacSecret})
      : _dio = dio ?? Dio(),
        _hmacSecret = resolveHmacSecret(hmacSecret);

  /// The deployed companion site — see `pixelvault-sources-web/`.
  static const defaultBaseUrl = 'https://pixelvault-topaz-six.vercel.app';

  /// Shared secret used to HMAC-sign every `/api/resolve` request (see
  /// `pixelvault-sources-web/lib/verify-signature.ts` for the server side of
  /// this — same secret, set as the `PIXELVAULT_HMAC_SECRET` Vercel env var).
  /// Passed at build time, e.g.:
  /// `flutter build apk --dart-define-from-file=secrets.json` (copy
  /// `secrets.example.json` to `secrets.json`, fill in the real value — see
  /// the README). This is a deterrent, not real security — the secret is
  /// still extractable by decompiling the APK — but raises the bar from
  /// "copy one header string" to "reverse-engineer the app's compiled code".
  static const _defaultHmacSecret = String.fromEnvironment('PIXELVAULT_HMAC_SECRET');

  /// Used only when no real secret is supplied in non-release builds, so
  /// `flutter run`/`flutter build apk --debug` never crashes on startup.
  /// Any `resolve()` call made with this placeholder simply fails
  /// server-side HMAC verification, surfacing as a normal 403
  /// [SourceInstallException] instead of an app crash.
  static const _debugPlaceholderHmacSecret = 'debug-placeholder-secret-not-for-production';

  final String baseUrl;
  final Dio _dio;
  final String _hmacSecret;

  /// `isRelease` defaults to the real [kReleaseMode] in production; it only
  /// exists as a parameter so tests can exercise the release-mode branch
  /// without needing an actual release build (`kReleaseMode` is always
  /// `false` under `flutter test`, and Dart's `assert` is stripped from
  /// release binaries entirely, so a bare `assert` could never be verified
  /// by a test either way — an explicit, injectable check is the only
  /// testable design here). Public (rather than private) only so tests in
  /// `test/deeplink/source_install_client_test.dart` can call it directly —
  /// [visibleForTesting] flags any other usage as a lint error.
  @visibleForTesting
  static String resolveHmacSecret(String? injected, {bool isRelease = kReleaseMode}) {
    final secret = injected ?? _defaultHmacSecret;
    if (secret.isNotEmpty) return secret;
    if (isRelease) {
      throw StateError(
        'Missing --dart-define=PIXELVAULT_HMAC_SECRET at build time. '
        'Release builds must supply the real secret.',
      );
    }
    return _debugPlaceholderHmacSecret;
  }

  Future<ResolvedSource> resolve(String token) async {
    if (token.isEmpty) throw const SourceInstallException('Link inválido: token em falta.');

    try {
      final ts = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
      final sig = Hmac(sha256, utf8.encode(_hmacSecret)).convert(utf8.encode('$token:$ts')).toString();
      final response = await _dio.get<Map<String, dynamic>>(
        '$baseUrl/api/resolve',
        queryParameters: {'token': token, 'ts': ts, 'sig': sig},
      );

      final data = response.data;
      if (data == null) throw const SourceInstallException('Resposta vazia do servidor.');

      final consoleId = data['consoleId'] as String?;
      final url = data['url'] as String?;
      final contentType = data['contentType'] as String? ?? 'GAME';
      if (consoleId == null || consoleId.isEmpty || url == null || url.isEmpty) {
        throw const SourceInstallException('Resposta do servidor incompleta.');
      }
      return ResolvedSource(consoleId: consoleId, url: url, contentType: contentType);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404 || e.response?.statusCode == 403) {
        throw const SourceInstallException('Este link já não é válido.');
      }
      throw SourceInstallException('Falha ao contactar o servidor: ${e.message}');
    }
  }
}
