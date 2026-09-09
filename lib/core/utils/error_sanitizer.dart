import 'package:dio/dio.dart';
import 'package:flutter/services.dart';

/// Why something failed, as a small closed set the UI can translate.
///
/// This replaces the previous "sanitize to an English sentence" approach.
/// That function returned a hardcoded `'an unexpected error occurred'` (or a
/// raw code like `FETCH_METADATA_FAILED`) which was then interpolated into a
/// *translated* template — so a French user read "Impossible d'installer la
/// source : an unexpected error occurred", and the carefully-worded messages
/// thrown by `SourceInstallClient` never reached the screen at all, because
/// the sanitizer discarded them on the way out.
///
/// Classification still never touches the exception's `message`/`details`/
/// `toString()`: those can carry a source's real magnet/URL up from native
/// scraping code, which is the property the original sanitizer existed to
/// guarantee and which the tests pin down.
enum ErrorReason {
  metadataFetch,
  network,
  linkExpired,
  serverResponse,
  sourceUnreachable,
  unexpected,
}

/// Maps a caught error onto an [ErrorReason]. Only stable, non-sensitive
/// discriminators are read: a [PlatformException]'s `code`, a
/// [DioException]'s type and HTTP status.
ErrorReason classifyError(Object error) {
  if (error is PlatformException) {
    return switch (error.code) {
      'FETCH_METADATA_FAILED' => ErrorReason.metadataFetch,
      'START_DOWNLOAD_FAILED' || 'FINISH_DOWNLOAD_FAILED' => ErrorReason.unexpected,
      _ => ErrorReason.unexpected,
    };
  }
  if (error is DioException) {
    final status = error.response?.statusCode;
    if (status == 403 || status == 404 || status == 410) return ErrorReason.linkExpired;
    if (status != null && status >= 500) return ErrorReason.sourceUnreachable;
    return ErrorReason.network;
  }
  return ErrorReason.unexpected;
}
