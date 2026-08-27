import 'package:flutter/services.dart';

/// Builds a safe, user-displayable string from a caught error — never
/// interpolates the original exception's `.message`/`.details`/`.toString()`,
/// since those can carry sensitive data (e.g. a source's real magnet/URL) up
/// from native scraping code. For [PlatformException]s, only the stable
/// `.code` is ever used; anything else falls back to a fully generic message.
String sanitizeErrorForDisplay(Object error) {
  if (error is PlatformException) {
    return switch (error.code) {
      'FETCH_METADATA_FAILED' => 'metadata fetch failed (timed out or no peers found)',
      final code => code,
    };
  }
  return 'an unexpected error occurred';
}
