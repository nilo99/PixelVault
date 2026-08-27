import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixelvault/core/settings/settings_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    container = ProviderContainer();
  });

  tearDown(() => container.dispose());

  test('build() returns defaults when nothing is stored yet', () async {
    final state = await container.read(settingsProvider.future);
    expect(state.downloadDirectory, '');
    expect(state.concurrentDownloads, 3);
    expect(state.consoleDownloadDirectories, isEmpty);
  });

  test('setDownloadDirectory persists and updates state', () async {
    await container.read(settingsProvider.future);
    final notifier = container.read(settingsProvider.notifier);

    await notifier.setDownloadDirectory('content://tree/primary');

    expect(notifier.current.downloadDirectory, 'content://tree/primary');
  });

  test('setSeparateByConsole, setAutoUnzip, setLimitSpeedMbs and setConcurrentDownloads persist', () async {
    await container.read(settingsProvider.future);
    final notifier = container.read(settingsProvider.notifier);

    await notifier.setSeparateByConsole(true);
    await notifier.setAutoUnzip(false);
    await notifier.setLimitSpeedMbs(8.5);
    await notifier.setConcurrentDownloads(5);

    expect(notifier.current.separateByConsole, isTrue);
    expect(notifier.current.autoUnzip, isFalse);
    expect(notifier.current.limitSpeedMbs, 8.5);
    expect(notifier.current.concurrentDownloads, 5);
  });

  test('setOnboardingCompleted persists', () async {
    await container.read(settingsProvider.future);
    final notifier = container.read(settingsProvider.notifier);

    await notifier.setOnboardingCompleted(true);

    expect(notifier.current.onboardingCompleted, isTrue);
  });

  group('setConsoleDownloadDirectory', () {
    test('adds an entry for a console without touching other consoles', () async {
      await container.read(settingsProvider.future);
      final notifier = container.read(settingsProvider.notifier);

      await notifier.setConsoleDownloadDirectory('nintendo_gba', 'content://tree/gba');
      await notifier.setConsoleDownloadDirectory('nintendo_snes', 'content://tree/snes');

      expect(notifier.current.consoleDownloadDirectories, {
        'nintendo_gba': 'content://tree/gba',
        'nintendo_snes': 'content://tree/snes',
      });
    });

    test('overwrites the directory for the same console id', () async {
      await container.read(settingsProvider.future);
      final notifier = container.read(settingsProvider.notifier);

      await notifier.setConsoleDownloadDirectory('nintendo_gba', 'content://tree/old');
      await notifier.setConsoleDownloadDirectory('nintendo_gba', 'content://tree/new');

      expect(notifier.current.consoleDownloadDirectories, {'nintendo_gba': 'content://tree/new'});
    });
  });

  test('persisted values survive a fresh notifier reading the same SharedPreferences store', () async {
    await container.read(settingsProvider.future);
    final notifier = container.read(settingsProvider.notifier);
    await notifier.setConsoleDownloadDirectory('nintendo_gba', 'content://tree/gba');
    await notifier.setConcurrentDownloads(6);

    final freshContainer = ProviderContainer();
    addTearDown(freshContainer.dispose);
    final freshState = await freshContainer.read(settingsProvider.future);

    expect(freshState.consoleDownloadDirectories, {'nintendo_gba': 'content://tree/gba'});
    expect(freshState.concurrentDownloads, 6);
  });

  test('current falls back to defaults before the initial async load resolves', () {
    final freshContainer = ProviderContainer();
    addTearDown(freshContainer.dispose);
    final notifier = freshContainer.read(settingsProvider.notifier);

    expect(notifier.current, const SettingsState());
  });
}
