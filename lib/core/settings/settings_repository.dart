import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'settings_repository.g.dart';

/// Port of Milou's `SettingsDataStore`/`SettingsRepository` (Preferences
/// DataStore → `shared_preferences`). `limitSpeedMbs` of 0 means "no limit",
/// matching the original `Float.POSITIVE_INFINITY` semantics used by
/// `DownloadSpeedController.applySpeedThrottling`.
class SettingsState {
  const SettingsState({
    this.downloadDirectory = '',
    this.separateByConsole = false,
    this.limitSpeedMbs = 0,
    this.autoUnzip = true,
    this.concurrentDownloads = 3,
    this.consoleDownloadDirectories = const {},
    this.onboardingCompleted = false,
    this.localeCode,
  });

  final String downloadDirectory;
  final bool separateByConsole;
  final double limitSpeedMbs;
  final bool autoUnzip;
  final int concurrentDownloads;
  final Map<String, String> consoleDownloadDirectories;
  final bool onboardingCompleted;

  /// `null` means "never chosen" — gates the first-run language picker (see
  /// `app_router.dart`'s `redirect`), distinct from defaulting to `'pt'`
  /// which would make that screen unreachable.
  final String? localeCode;

  SettingsState copyWith({
    String? downloadDirectory,
    bool? separateByConsole,
    double? limitSpeedMbs,
    bool? autoUnzip,
    int? concurrentDownloads,
    Map<String, String>? consoleDownloadDirectories,
    bool? onboardingCompleted,
    String? localeCode,
  }) {
    return SettingsState(
      downloadDirectory: downloadDirectory ?? this.downloadDirectory,
      separateByConsole: separateByConsole ?? this.separateByConsole,
      limitSpeedMbs: limitSpeedMbs ?? this.limitSpeedMbs,
      autoUnzip: autoUnzip ?? this.autoUnzip,
      concurrentDownloads: concurrentDownloads ?? this.concurrentDownloads,
      consoleDownloadDirectories: consoleDownloadDirectories ?? this.consoleDownloadDirectories,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      localeCode: localeCode ?? this.localeCode,
    );
  }
}

const _kDownloadDirectory = 'download_directory';
const _kSeparateByConsole = 'separate_by_console';
const _kLimitSpeedMbs = 'limit_speed_mbs';
const _kAutoUnzip = 'auto_unzip';
const _kConcurrentDownloads = 'concurrent_downloads';
const _kConsoleDownloadDirectories = 'console_download_directories';
const _kOnboardingCompleted = 'onboarding_completed';
const _kLocaleCode = 'locale_code';

@Riverpod(keepAlive: true)
class SettingsNotifier extends _$SettingsNotifier {
  late SharedPreferences _prefs;

  @override
  Future<SettingsState> build() async {
    _prefs = await SharedPreferences.getInstance();
    final rawMap = _prefs.getString(_kConsoleDownloadDirectories);
    return SettingsState(
      downloadDirectory: _prefs.getString(_kDownloadDirectory) ?? '',
      separateByConsole: _prefs.getBool(_kSeparateByConsole) ?? false,
      limitSpeedMbs: _prefs.getDouble(_kLimitSpeedMbs) ?? 0,
      autoUnzip: _prefs.getBool(_kAutoUnzip) ?? true,
      concurrentDownloads: _prefs.getInt(_kConcurrentDownloads) ?? 3,
      consoleDownloadDirectories: _decodeConsoleDownloadDirectories(rawMap),
      onboardingCompleted: _prefs.getBool(_kOnboardingCompleted) ?? false,
      localeCode: _prefs.getString(_kLocaleCode),
    );
  }

  /// A single malformed stored value here previously failed the *entire*
  /// [build] — every setting reverting to defaults, not just this map —
  /// since [build] threw synchronously before returning any [SettingsState].
  static Map<String, String> _decodeConsoleDownloadDirectories(String? rawMap) {
    if (rawMap == null) return const {};
    try {
      return Map<String, String>.from(jsonDecode(rawMap) as Map);
    } catch (_) {
      return const {};
    }
  }

  /// Synchronous snapshot of the current settings (falls back to defaults
  /// while the initial async load is still pending).
  SettingsState get current => state.value ?? const SettingsState();

  Future<void> setDownloadDirectory(String uri) async {
    await _prefs.setString(_kDownloadDirectory, uri);
    state = AsyncData((state.value ?? const SettingsState()).copyWith(downloadDirectory: uri));
  }

  Future<void> setSeparateByConsole(bool enabled) async {
    await _prefs.setBool(_kSeparateByConsole, enabled);
    state = AsyncData((state.value ?? const SettingsState()).copyWith(separateByConsole: enabled));
  }

  Future<void> setLimitSpeedMbs(double limit) async {
    await _prefs.setDouble(_kLimitSpeedMbs, limit);
    state = AsyncData((state.value ?? const SettingsState()).copyWith(limitSpeedMbs: limit));
  }

  Future<void> setAutoUnzip(bool enabled) async {
    await _prefs.setBool(_kAutoUnzip, enabled);
    state = AsyncData((state.value ?? const SettingsState()).copyWith(autoUnzip: enabled));
  }

  Future<void> setConcurrentDownloads(int count) async {
    await _prefs.setInt(_kConcurrentDownloads, count);
    state = AsyncData((state.value ?? const SettingsState()).copyWith(concurrentDownloads: count));
  }

  Future<void> setConsoleDownloadDirectory(String consoleId, String uri) async {
    final current = Map<String, String>.from((state.value ?? const SettingsState()).consoleDownloadDirectories);
    current[consoleId] = uri;
    await _prefs.setString(_kConsoleDownloadDirectories, jsonEncode(current));
    state = AsyncData((state.value ?? const SettingsState()).copyWith(consoleDownloadDirectories: current));
  }

  Future<void> setOnboardingCompleted(bool completed) async {
    await _prefs.setBool(_kOnboardingCompleted, completed);
    state = AsyncData((state.value ?? const SettingsState()).copyWith(onboardingCompleted: completed));
  }

  Future<void> setLocale(String code) async {
    await _prefs.setString(_kLocaleCode, code);
    state = AsyncData((state.value ?? const SettingsState()).copyWith(localeCode: code));
  }
}
