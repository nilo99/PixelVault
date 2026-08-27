/// Port of Milou's `DownloadSpeedController` — throttles HTTP download
/// throughput to a MiB/s cap. `limitMbs <= 0` means unlimited, matching the
/// original's `Float.POSITIVE_INFINITY` sentinel.
abstract final class DownloadSpeedController {
  static const _mebibyte = 1024 * 1024;

  static double calculateSpeedMbs(int bytesDownloaded, double elapsedSeconds) {
    if (elapsedSeconds <= 0) return 0;
    return (bytesDownloaded / _mebibyte) / elapsedSeconds;
  }

  static Future<void> applyThrottle({
    required double currentSpeedMbs,
    required double limitMbs,
    required int bytesSinceLastCheck,
    required double timeSinceLastCheckSeconds,
  }) async {
    if (limitMbs <= 0) return;
    if (currentSpeedMbs <= limitMbs) return;

    final targetTime = (bytesSinceLastCheck / _mebibyte) / limitMbs;
    final delayNeededMs = ((targetTime - timeSinceLastCheckSeconds) * 1000).round();
    if (delayNeededMs > 0) {
      await Future.delayed(Duration(milliseconds: delayNeededMs));
    }
  }
}
