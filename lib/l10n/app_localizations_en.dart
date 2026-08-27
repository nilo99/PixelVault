// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonAdd => 'Add';

  @override
  String get commonChange => 'Change';

  @override
  String get commonSet => 'Set';

  @override
  String get commonOk => 'OK';

  @override
  String commonGenericError(String error) {
    return 'Error: $error';
  }

  @override
  String get routerPageNotFoundTitle => 'Page not found';

  @override
  String get routerPageNotFoundAction => 'Back to platforms';

  @override
  String get navBarPlatforms => 'Platforms';

  @override
  String get navBarDownloads => 'Downloads';

  @override
  String get navBarSources => 'Sources';

  @override
  String get navBarSettings => 'Settings';

  @override
  String get aboutTitle => 'About';

  @override
  String get aboutBody => 'Personal ROM library and download manager.';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingStart => 'Get started';

  @override
  String onboardingStepCounter(int step, int total) {
    return 'STEP $step / $total';
  }

  @override
  String get onboardingStep1Title => 'Your retro library — in one app';

  @override
  String get onboardingStep1Description =>
      'PixelVault organizes ROMs from all your favorite consoles. Search, filter by tags and download — all from your phone.';

  @override
  String get onboardingStep1Highlight1 => 'PixelVault';

  @override
  String get onboardingStep1Highlight2 => 'ROMs';

  @override
  String get onboardingStep2Title => 'Index any source — without downloading';

  @override
  String get onboardingStep2Description =>
      'Add HTTP servers or magnet links. PixelVault reads the whole file tree and catalogs names, tags and sizes — without transferring the games.';

  @override
  String get onboardingStep2Highlight1 => 'HTTP';

  @override
  String get onboardingStep2Highlight2 => 'magnet links';

  @override
  String get onboardingStep3Title => 'Download with full control';

  @override
  String get onboardingStep3Description =>
      'Concurrent downloads, speed limit, automatic archive extraction and background downloads — never lose anything when you close the app.';

  @override
  String get onboardingStep3Highlight1 => 'automatic extraction';

  @override
  String get onboardingStep3Highlight2 => 'background';

  @override
  String get onboardingStep4Title => 'Ready to play';

  @override
  String get onboardingStep4Description =>
      'Organize files by console, choose a destination folder and open them directly in your favorite emulator. Have fun!';

  @override
  String get onboardingStep4Highlight1 => 'favorite emulator';

  @override
  String get sourcesEyebrow => 'SCRAPING';

  @override
  String get sourcesTitle => 'Sources';

  @override
  String sourcesUnsyncedBanner(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count consoles have sources but are still unsynced.',
      one: '1 console has sources but is still unsynced.',
    );
    return '$_temp0';
  }

  @override
  String get sourcesSyncAllButton => 'Sync all';

  @override
  String sourcesManufacturerSummary(int consoleCount, int syncedCount) {
    String _temp0 = intl.Intl.pluralLogic(
      consoleCount,
      locale: localeName,
      other: '$consoleCount consoles',
      one: '1 console',
    );
    String _temp1 = intl.Intl.pluralLogic(
      syncedCount,
      locale: localeName,
      other: '$syncedCount synced',
      one: '1 synced',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String get sourcesAddConsoleTooltip => 'Add console';

  @override
  String get sourcesNoConsolesEmptyState =>
      'No consoles. Use the + button to add one.';

  @override
  String get sourcesNeverSynced => 'not synced yet';

  @override
  String sourcesGamesIndexedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count games indexed',
      one: '1 game indexed',
    );
    return '$_temp0';
  }

  @override
  String sourcesSourceCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sources',
      one: '1 source',
    );
    return '$_temp0';
  }

  @override
  String sourcesSourceLabel(int index) {
    return 'Source $index';
  }

  @override
  String get sourcesAddSourceTooltip => 'Add source';

  @override
  String get sourcesRemoveSourceTooltip => 'Remove source';

  @override
  String get sourcesNoSourcesEmptyState =>
      'No sources. Use the link icon to add one.';

  @override
  String get sourcesEmptyStateBody =>
      'Add a manufacturer and a source (HTTP or magnet) to start indexing games.';

  @override
  String get sourcesAddManufacturerButton => 'Add manufacturer';

  @override
  String get sourcesSyncingBanner => 'Syncing catalog';

  @override
  String sourcesAddManufacturerError(String error) {
    return 'Failed to add manufacturer: $error';
  }

  @override
  String sourcesAddConsoleError(String error) {
    return 'Failed to add console: $error';
  }

  @override
  String sourcesAddSourceError(String error) {
    return 'Failed to add source: $error';
  }

  @override
  String sourcesRemoveSourceError(String error) {
    return 'Failed to remove source: $error';
  }

  @override
  String get addManufacturerDialogTitle => 'New manufacturer';

  @override
  String get addManufacturerDialogIdLabel => 'ID (e.g. nintendo)';

  @override
  String get addManufacturerDialogNameLabel => 'Name (e.g. Nintendo)';

  @override
  String get addConsoleDialogTitle => 'New console';

  @override
  String get addConsoleDialogIdLabel => 'ID (e.g. gameboy_advance)';

  @override
  String get addConsoleDialogNameLabel => 'Name (e.g. Game Boy Advance)';

  @override
  String get addUrlDialogTitle => 'New source';

  @override
  String get addUrlDialogUrlLabel => 'URL (http://…) or magnet:?…';

  @override
  String get addUrlDialogContentTypeLabel => 'Content type';

  @override
  String addUrlDialogApplyTo(int count) {
    return 'Apply to ($count selected):';
  }

  @override
  String get addUrlDialogSubmitButton => 'Add and sync';

  @override
  String get settingsEyebrow => 'SYSTEM';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsStorageSection => 'STORAGE';

  @override
  String get settingsDownloadDirTitle => 'Download folder (SAF)';

  @override
  String get settingsNotSet => 'Not set';

  @override
  String get settingsSeparateByConsoleTitle => 'Separate by console';

  @override
  String get settingsSeparateByConsoleSubtitle =>
      'Creates /Nintendo Game Boy Advance/…';

  @override
  String get settingsLanguageSection => 'LANGUAGE';

  @override
  String get settingsLanguageTitle => 'Language';

  @override
  String get settingsConsoleFoldersSection => 'PER-CONSOLE FOLDERS';

  @override
  String get settingsNoConsolesConfigured => 'No consoles configured yet.';

  @override
  String get settingsNetworkSection => 'NETWORK';

  @override
  String get settingsSpeedLimitTitle => 'Speed limit';

  @override
  String get settingsUnlimited => 'Unlimited';

  @override
  String settingsSpeedMbs(String value) {
    return '$value MB/s';
  }

  @override
  String get settingsSpeedMinLabel => '0 · unlimited';

  @override
  String get settingsConcurrentDownloadsTitle => 'Concurrent downloads';

  @override
  String get settingsConcurrentMaxLabel => '6 max.';

  @override
  String get settingsArchivesSection => 'ARCHIVES';

  @override
  String get settingsAutoUnzipTitle => 'Automatic extraction';

  @override
  String get settingsAutoUnzipSubtitle =>
      '.zip .7z .rar .tar .gz .xz · deletes the archive';

  @override
  String get settingsUsesMainFolder => 'Uses the main folder';

  @override
  String get downloadsEyebrow => 'QUEUE';

  @override
  String get downloadsTitle => 'Downloads';

  @override
  String get downloadsActiveLabel => 'Active';

  @override
  String get downloadsSpeedLabel => 'MB/s total';

  @override
  String get downloadsQueuedLabel => 'Queued';

  @override
  String get downloadsEmptyState => 'No downloads in progress';

  @override
  String downloadsStatusDownloading(String percent, String speed) {
    return '$percent% · $speed MB/s';
  }

  @override
  String get downloadsStatusCopying => 'Copying to SD Card (SAF)';

  @override
  String get downloadsStatusUnzipping => 'Extracting archive';

  @override
  String get downloadsStatusCompleted => 'Completed';

  @override
  String get downloadsStatusFailed => 'Failed · tap to retry';

  @override
  String get downloadsChipDownloading => 'Downloading';

  @override
  String get downloadsChipCopying => 'Copying';

  @override
  String get downloadsChipUnzipping => 'Extracting';

  @override
  String get downloadsChipFailed => 'Failed';

  @override
  String get downloadsStopTooltip => 'Stop';

  @override
  String get downloadsRetryTooltip => 'Retry';

  @override
  String get downloadsRemoveTooltip => 'Remove';

  @override
  String get downloadsRemoveFromListTooltip => 'Remove from list';

  @override
  String get libraryDefaultTitle => 'Library';

  @override
  String get libraryHintSearch => 'Search roms…';

  @override
  String get libraryFiltersChip => 'Filters';

  @override
  String get libraryFormatChip => 'Format';

  @override
  String get libraryColRegion => 'REGION';

  @override
  String get libraryColLanguage => 'LANGUAGE';

  @override
  String get libraryColVideo => 'VIDEO';

  @override
  String get libraryColType => 'TYPE';

  @override
  String get libraryColExtension => 'EXTENSION';

  @override
  String get libraryNoResults =>
      'No results.\nAdd a source in the Sources tab and rescan.';

  @override
  String libraryMetaLabel(String count, String size) {
    return '$count files · $size';
  }

  @override
  String libraryDownloadStartedSnackbar(String name) {
    return 'Download of \"$name\" started.';
  }

  @override
  String platformSelectSeedError(String error) {
    return 'Error loading consoles: $error';
  }

  @override
  String get platformSelectEyebrow => 'CATALOG';

  @override
  String get platformSelectTitle => 'Platforms';

  @override
  String platformSelectSubtitle(int consoleCount, int fileCount) {
    return '$consoleCount active consoles · $fileCount files indexed';
  }

  @override
  String get platformSelectSearchHint => 'Search consoles…';

  @override
  String get platformSelectActiveConsolesSection => 'ACTIVE CONSOLES';

  @override
  String get platformSelectEmptyState =>
      'No platforms yet.\nGo to Sources to add sources.';

  @override
  String get platformSelectGlobalLibraryTitle => 'Global library';

  @override
  String get platformSelectGlobalLibrarySubtitle =>
      'Every game from every console';

  @override
  String platformSelectConsoleSummary(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count games',
      one: '1 game',
    );
    return '$_temp0 · $size';
  }

  @override
  String sourceInstallResolveError(String error) {
    return 'Could not install the source: $error';
  }

  @override
  String get sourceInstallUnsupportedConsole =>
      'This console isn\'t supported in this version of the app.';

  @override
  String sourceInstallAlreadyInstalled(String name) {
    return 'This source is already installed on \"$name\".';
  }

  @override
  String get sourceInstallConfirmTitle => 'Add source';

  @override
  String sourceInstallConfirmBody(String name) {
    return 'Add a new source to \"$name\"?';
  }

  @override
  String sourceInstallSuccess(String name) {
    return 'Source added to \"$name\". Go to Sources to sync it.';
  }

  @override
  String sourceInstallAddError(String error) {
    return 'Failed to add the source: $error';
  }
}
