/// Why a download failed, as a small closed set of stable codes.
///
/// Downloads used to fail into a single undifferentiated
/// `DownloadStatus.failed` with the real exception swallowed, which is what
/// made "it just crashes and says nothing" impossible to act on: a full disk,
/// a revoked folder permission and a dead mirror all looked identical. These
/// codes are persisted (see `Downloads.failureReason`) and mapped to a
/// translated sentence in the UI, so the reason survives a restart and is
/// never the raw exception text — that can carry a magnet/URL, which
/// `sanitizeErrorForDisplay` exists to keep off screen.
enum DownloadFailureReason {
  /// The transfer ended before every byte arrived — a dropped connection, a
  /// mirror that closes the socket early, or a server that ignores `Range`.
  incomplete,

  /// Not enough free space to stage the file before copying it out.
  insufficientSpace,

  /// No download folder configured, or the SAF permission for it was
  /// revoked (the user cleared app data, moved the SD card, etc).
  destinationUnavailable,

  /// Writing to the destination failed even though it was reachable.
  destinationWriteFailed,

  /// Archive extraction failed — a truncated or unsupported archive.
  extractionFailed,

  /// Torrent metadata/peers never materialized.
  torrentUnavailable,

  /// Network-level failure: DNS, TLS, timeout, 4xx/5xx.
  network,

  /// Anything not covered above.
  unknown;

  String get code => name;

  static DownloadFailureReason fromCode(String? code) {
    if (code == null) return unknown;
    for (final value in values) {
      if (value.name == code) return value;
    }
    return unknown;
  }
}

/// Thrown by the HTTP download path when the response stream ends before
/// [expected] bytes arrived. Carries the byte counts (not the URL) so the
/// retry loop can decide whether resuming is worthwhile.
class IncompleteDownloadException implements Exception {
  const IncompleteDownloadException({required this.received, required this.expected});

  final int received;
  final int expected;

  @override
  String toString() => 'IncompleteDownloadException($received/$expected bytes)';
}

/// Thrown before a download starts when the staging volume can't fit it.
class InsufficientSpaceException implements Exception {
  const InsufficientSpaceException({required this.required, required this.available});

  final int required;
  final int available;

  @override
  String toString() => 'InsufficientSpaceException(need $required, have $available)';
}
