import 'package:flutter_test/flutter_test.dart';
import 'package:pixelvault/core/download/download_speed_controller.dart';

void main() {
  group('DownloadSpeedController.calculateSpeedMbs', () {
    test('returns 0 when elapsed is 0', () {
      expect(DownloadSpeedController.calculateSpeedMbs(1024 * 1024, 0), 0);
    });

    test('returns 0 when elapsed is negative', () {
      expect(DownloadSpeedController.calculateSpeedMbs(1024 * 1024, -1), 0);
    });

    test('calculates correct speed in MiB/s', () {
      // 1 MiB in 1 second = 1 MiB/s
      final speed = DownloadSpeedController.calculateSpeedMbs(1024 * 1024, 1.0);
      expect(speed, closeTo(1.0, 0.001));
    });

    test('calculates fractional speed', () {
      // 512 KiB in 1 second = 0.5 MiB/s
      final speed = DownloadSpeedController.calculateSpeedMbs(512 * 1024, 1.0);
      expect(speed, closeTo(0.5, 0.001));
    });

    test('scales with elapsed time', () {
      // 2 MiB in 2 seconds = 1 MiB/s
      final speed = DownloadSpeedController.calculateSpeedMbs(2 * 1024 * 1024, 2.0);
      expect(speed, closeTo(1.0, 0.001));
    });
  });

  group('DownloadSpeedController.applyThrottle', () {
    test('does nothing when limit is 0 (unlimited)', () async {
      // Should complete instantly
      final before = DateTime.now();
      await DownloadSpeedController.applyThrottle(
        currentSpeedMbs: 100,
        limitMbs: 0,
        bytesSinceLastCheck: 1024 * 1024,
        timeSinceLastCheckSeconds: 0.01,
      );
      final elapsed = DateTime.now().difference(before).inMilliseconds;
      expect(elapsed, lessThan(50));
    });

    test('does nothing when limit is negative (unlimited)', () async {
      final before = DateTime.now();
      await DownloadSpeedController.applyThrottle(
        currentSpeedMbs: 100,
        limitMbs: -1,
        bytesSinceLastCheck: 1024 * 1024,
        timeSinceLastCheckSeconds: 0.01,
      );
      final elapsed = DateTime.now().difference(before).inMilliseconds;
      expect(elapsed, lessThan(50));
    });

    test('does nothing when speed is below limit', () async {
      final before = DateTime.now();
      await DownloadSpeedController.applyThrottle(
        currentSpeedMbs: 1.0,
        limitMbs: 10.0,
        bytesSinceLastCheck: 1024 * 1024,
        timeSinceLastCheckSeconds: 1.0,
      );
      final elapsed = DateTime.now().difference(before).inMilliseconds;
      expect(elapsed, lessThan(50));
    });

    test('delays when speed exceeds limit', () async {
      // Speed is 10 MiB/s, limit is 1 MiB/s — should throttle
      final before = DateTime.now();
      await DownloadSpeedController.applyThrottle(
        currentSpeedMbs: 10.0,
        limitMbs: 1.0,
        bytesSinceLastCheck: 1024 * 1024, // 1 MiB
        timeSinceLastCheckSeconds: 0.1, // actual time was 0.1s
      );
      final elapsed = DateTime.now().difference(before).inMilliseconds;
      // Target time for 1MiB at 1MiB/s = 1s, actual was 0.1s,
      // so delay ~900ms. Allow generous tolerance for CI.
      expect(elapsed, greaterThan(500));
    });
  });
}
