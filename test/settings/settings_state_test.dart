import 'package:flutter_test/flutter_test.dart';
import 'package:pixelvault/core/settings/settings_repository.dart';

void main() {
  group('SettingsState defaults', () {
    test('has expected default values', () {
      const s = SettingsState();
      expect(s.downloadDirectory, '');
      expect(s.separateByConsole, isFalse);
      expect(s.limitSpeedMbs, 0);
      expect(s.autoUnzip, isTrue);
      expect(s.concurrentDownloads, 3);
      expect(s.consoleDownloadDirectories, isEmpty);
      expect(s.onboardingCompleted, isFalse);
    });
  });

  group('SettingsState.copyWith', () {
    test('updates only the specified fields', () {
      const original = SettingsState();
      final updated = original.copyWith(
        downloadDirectory: '/storage/downloads',
        concurrentDownloads: 5,
      );
      expect(updated.downloadDirectory, '/storage/downloads');
      expect(updated.concurrentDownloads, 5);
      // unchanged
      expect(updated.separateByConsole, isFalse);
      expect(updated.limitSpeedMbs, 0);
      expect(updated.autoUnzip, isTrue);
      expect(updated.consoleDownloadDirectories, isEmpty);
      expect(updated.onboardingCompleted, isFalse);
    });

    test('can update all fields simultaneously', () {
      const original = SettingsState();
      final updated = original.copyWith(
        downloadDirectory: '/new',
        separateByConsole: true,
        limitSpeedMbs: 5.5,
        autoUnzip: false,
        concurrentDownloads: 1,
        consoleDownloadDirectories: {'gba': '/gba_dir'},
      );
      expect(updated.downloadDirectory, '/new');
      expect(updated.separateByConsole, isTrue);
      expect(updated.limitSpeedMbs, 5.5);
      expect(updated.autoUnzip, isFalse);
      expect(updated.concurrentDownloads, 1);
      expect(updated.consoleDownloadDirectories, {'gba': '/gba_dir'});
    });

    test('no-op copyWith returns equivalent state', () {
      const original = SettingsState(
        downloadDirectory: '/test',
        separateByConsole: true,
        limitSpeedMbs: 2.0,
        autoUnzip: false,
        concurrentDownloads: 2,
      );
      final copied = original.copyWith();
      expect(copied.downloadDirectory, original.downloadDirectory);
      expect(copied.separateByConsole, original.separateByConsole);
      expect(copied.limitSpeedMbs, original.limitSpeedMbs);
      expect(copied.autoUnzip, original.autoUnzip);
      expect(copied.concurrentDownloads, original.concurrentDownloads);
    });
  });
}
