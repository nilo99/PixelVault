// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get commonCancel => 'Abbrechen';

  @override
  String get commonAdd => 'Hinzufügen';

  @override
  String get commonChange => 'Ändern';

  @override
  String get commonSet => 'Festlegen';

  @override
  String get commonOk => 'OK';

  @override
  String commonGenericError(String error) {
    return 'Fehler: $error';
  }

  @override
  String get routerPageNotFoundTitle => 'Seite nicht gefunden';

  @override
  String get routerPageNotFoundAction => 'Zurück zu den Plattformen';

  @override
  String get navBarPlatforms => 'Plattformen';

  @override
  String get navBarDownloads => 'Downloads';

  @override
  String get navBarSources => 'Quellen';

  @override
  String get navBarSettings => 'Einstellungen';

  @override
  String get aboutTitle => 'Über';

  @override
  String get aboutBody => 'Persönliche ROM-Bibliothek und Download-Verwaltung.';

  @override
  String get onboardingSkip => 'Überspringen';

  @override
  String get onboardingNext => 'Weiter';

  @override
  String get onboardingStart => 'Loslegen';

  @override
  String onboardingStepCounter(int step, int total) {
    return 'SCHRITT $step / $total';
  }

  @override
  String get onboardingStep1Title => 'Deine Retro-Bibliothek — in einer App';

  @override
  String get onboardingStep1Description =>
      'PixelVault organisiert ROMs all deiner Lieblingskonsolen. Suchen, nach Tags filtern und herunterladen — alles vom Handy aus.';

  @override
  String get onboardingStep1Highlight1 => 'PixelVault';

  @override
  String get onboardingStep1Highlight2 => 'ROMs';

  @override
  String get onboardingStep2Title => 'Jede Quelle indexieren — ohne Download';

  @override
  String get onboardingStep2Description =>
      'Füge HTTP-Server oder Magnet-Links hinzu. PixelVault liest den gesamten Dateibaum und katalogisiert Namen, Tags und Größen — ohne die Spiele zu übertragen.';

  @override
  String get onboardingStep2Highlight1 => 'HTTP';

  @override
  String get onboardingStep2Highlight2 => 'Magnet-Links';

  @override
  String get onboardingStep3Title => 'Herunterladen mit voller Kontrolle';

  @override
  String get onboardingStep3Description =>
      'Gleichzeitige Downloads, Geschwindigkeitslimit, automatisches Entpacken von Archiven und Downloads im Hintergrund — verliere nichts beim Schließen der App.';

  @override
  String get onboardingStep3Highlight1 => 'automatisches Entpacken';

  @override
  String get onboardingStep3Highlight2 => 'Hintergrund';

  @override
  String get onboardingStep4Title => 'Bereit zum Spielen';

  @override
  String get onboardingStep4Description =>
      'Organisiere Dateien nach Konsole, wähle einen Zielordner und öffne sie direkt in deinem Lieblingsemulator. Viel Spaß!';

  @override
  String get onboardingStep4Highlight1 => 'Lieblingsemulator';

  @override
  String get sourcesEyebrow => 'SCRAPING';

  @override
  String get sourcesTitle => 'Quellen';

  @override
  String sourcesUnsyncedBanner(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count Konsolen haben Quellen, sind aber noch nicht synchronisiert.',
      one: '1 Konsole hat Quellen, ist aber noch nicht synchronisiert.',
    );
    return '$_temp0';
  }

  @override
  String get sourcesSyncAllButton => 'Alles synchronisieren';

  @override
  String sourcesManufacturerSummary(int consoleCount, int syncedCount) {
    String _temp0 = intl.Intl.pluralLogic(
      consoleCount,
      locale: localeName,
      other: '$consoleCount Konsolen',
      one: '1 Konsole',
    );
    String _temp1 = intl.Intl.pluralLogic(
      syncedCount,
      locale: localeName,
      other: '$syncedCount synchronisiert',
      one: '1 synchronisiert',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String get sourcesAddConsoleTooltip => 'Konsole hinzufügen';

  @override
  String get sourcesNoConsolesEmptyState =>
      'Keine Konsolen. Nutze die Taste +, um eine hinzuzufügen.';

  @override
  String get sourcesNeverSynced => 'noch nicht synchronisiert';

  @override
  String sourcesGamesIndexedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Spiele indexiert',
      one: '1 Spiel indexiert',
    );
    return '$_temp0';
  }

  @override
  String sourcesSourceCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Quellen',
      one: '1 Quelle',
    );
    return '$_temp0';
  }

  @override
  String sourcesSourceLabel(int index) {
    return 'Quelle $index';
  }

  @override
  String get sourcesAddSourceTooltip => 'Quelle hinzufügen';

  @override
  String get sourcesRemoveSourceTooltip => 'Quelle entfernen';

  @override
  String get sourcesNoSourcesEmptyState =>
      'Keine Quellen. Nutze das Link-Symbol, um eine hinzuzufügen.';

  @override
  String get sourcesEmptyStateBody =>
      'Füge einen Hersteller und eine Quelle (HTTP oder Magnet) hinzu, um Spiele zu indexieren.';

  @override
  String get sourcesAddManufacturerButton => 'Hersteller hinzufügen';

  @override
  String get sourcesSyncingBanner => 'Katalog wird synchronisiert';

  @override
  String sourcesAddManufacturerError(String error) {
    return 'Hersteller konnte nicht hinzugefügt werden: $error';
  }

  @override
  String sourcesAddConsoleError(String error) {
    return 'Konsole konnte nicht hinzugefügt werden: $error';
  }

  @override
  String sourcesAddSourceError(String error) {
    return 'Quelle konnte nicht hinzugefügt werden: $error';
  }

  @override
  String sourcesRemoveSourceError(String error) {
    return 'Quelle konnte nicht entfernt werden: $error';
  }

  @override
  String get addManufacturerDialogTitle => 'Neuer Hersteller';

  @override
  String get addManufacturerDialogIdLabel => 'ID (z. B. nintendo)';

  @override
  String get addManufacturerDialogNameLabel => 'Name (z. B. Nintendo)';

  @override
  String get addConsoleDialogTitle => 'Neue Konsole';

  @override
  String get addConsoleDialogIdLabel => 'ID (z. B. gameboy_advance)';

  @override
  String get addConsoleDialogNameLabel => 'Name (z. B. Game Boy Advance)';

  @override
  String get addUrlDialogTitle => 'Neue Quelle';

  @override
  String get addUrlDialogUrlLabel => 'URL (http://…) oder magnet:?…';

  @override
  String get addUrlDialogContentTypeLabel => 'Inhaltstyp';

  @override
  String addUrlDialogApplyTo(int count) {
    return 'Anwenden auf ($count ausgewählt):';
  }

  @override
  String get addUrlDialogSubmitButton => 'Hinzufügen und synchronisieren';

  @override
  String get settingsEyebrow => 'SYSTEM';

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get settingsStorageSection => 'SPEICHER';

  @override
  String get settingsDownloadDirTitle => 'Download-Ordner (SAF)';

  @override
  String get settingsNotSet => 'Nicht festgelegt';

  @override
  String get settingsSeparateByConsoleTitle => 'Nach Konsole trennen';

  @override
  String get settingsSeparateByConsoleSubtitle =>
      'Erstellt /Nintendo Game Boy Advance/…';

  @override
  String get settingsLanguageSection => 'SPRACHE';

  @override
  String get settingsLanguageTitle => 'Sprache';

  @override
  String get settingsConsoleFoldersSection => 'ORDNER PRO KONSOLE';

  @override
  String get settingsNoConsolesConfigured =>
      'Noch keine Konsolen konfiguriert.';

  @override
  String get settingsNetworkSection => 'NETZWERK';

  @override
  String get settingsSpeedLimitTitle => 'Geschwindigkeitslimit';

  @override
  String get settingsUnlimited => 'Unbegrenzt';

  @override
  String settingsSpeedMbs(String value) {
    return '$value MB/s';
  }

  @override
  String get settingsSpeedMinLabel => '0 · unbegrenzt';

  @override
  String get settingsConcurrentDownloadsTitle => 'Gleichzeitige Downloads';

  @override
  String get settingsConcurrentMaxLabel => '6 max.';

  @override
  String get settingsArchivesSection => 'ARCHIVE';

  @override
  String get settingsAutoUnzipTitle => 'Automatisches Entpacken';

  @override
  String get settingsAutoUnzipSubtitle =>
      '.zip .7z .rar .tar .gz .xz · löscht das Archiv';

  @override
  String get settingsUsesMainFolder => 'Verwendet den Hauptordner';

  @override
  String get downloadsEyebrow => 'WARTESCHLANGE';

  @override
  String get downloadsTitle => 'Downloads';

  @override
  String get downloadsActiveLabel => 'Aktiv';

  @override
  String get downloadsSpeedLabel => 'MB/s gesamt';

  @override
  String get downloadsQueuedLabel => 'Wartend';

  @override
  String get downloadsEmptyState => 'Kein Download läuft';

  @override
  String downloadsStatusDownloading(String percent, String speed) {
    return '$percent% · $speed MB/s';
  }

  @override
  String get downloadsStatusCopying => 'Kopieren auf SD-Karte (SAF)';

  @override
  String get downloadsStatusUnzipping => 'Archiv wird entpackt';

  @override
  String get downloadsStatusCompleted => 'Abgeschlossen';

  @override
  String get downloadsStatusFailed => 'Fehlgeschlagen · zum Wiederholen tippen';

  @override
  String get downloadsChipDownloading => 'Lädt herunter';

  @override
  String get downloadsChipCopying => 'Kopiert';

  @override
  String get downloadsChipUnzipping => 'Entpackt';

  @override
  String get downloadsChipFailed => 'Fehlgeschlagen';

  @override
  String get downloadsStopTooltip => 'Stoppen';

  @override
  String get downloadsRetryTooltip => 'Erneut versuchen';

  @override
  String get downloadsRemoveTooltip => 'Entfernen';

  @override
  String get downloadsRemoveFromListTooltip => 'Aus der Liste entfernen';

  @override
  String get libraryDefaultTitle => 'Bibliothek';

  @override
  String get libraryHintSearch => 'ROMs suchen…';

  @override
  String get libraryFiltersChip => 'Filter';

  @override
  String get libraryFormatChip => 'Format';

  @override
  String get libraryColRegion => 'REGION';

  @override
  String get libraryColLanguage => 'SPRACHE';

  @override
  String get libraryColVideo => 'VIDEO';

  @override
  String get libraryColType => 'TYP';

  @override
  String get libraryColExtension => 'ENDUNG';

  @override
  String get libraryNoResults =>
      'Keine Ergebnisse.\nFüge im Tab Quellen eine Quelle hinzu und scanne erneut.';

  @override
  String libraryMetaLabel(String count, String size) {
    return '$count Dateien · $size';
  }

  @override
  String libraryDownloadStartedSnackbar(String name) {
    return 'Download von „$name“ gestartet.';
  }

  @override
  String platformSelectSeedError(String error) {
    return 'Fehler beim Laden der Konsolen: $error';
  }

  @override
  String get platformSelectEyebrow => 'KATALOG';

  @override
  String get platformSelectTitle => 'Plattformen';

  @override
  String platformSelectSubtitle(int consoleCount, int fileCount) {
    return '$consoleCount aktive Konsolen · $fileCount Dateien indexiert';
  }

  @override
  String get platformSelectSearchHint => 'Konsolen suchen…';

  @override
  String get platformSelectActiveConsolesSection => 'AKTIVE KONSOLEN';

  @override
  String get platformSelectEmptyState =>
      'Noch keine Plattformen.\nGehe zu Quellen, um Quellen hinzuzufügen.';

  @override
  String get platformSelectGlobalLibraryTitle => 'Globale Bibliothek';

  @override
  String get platformSelectGlobalLibrarySubtitle =>
      'Alle Spiele aller Konsolen';

  @override
  String platformSelectConsoleSummary(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Spiele',
      one: '1 Spiel',
    );
    return '$_temp0 · $size';
  }

  @override
  String sourceInstallResolveError(String error) {
    return 'Quelle konnte nicht installiert werden: $error';
  }

  @override
  String get sourceInstallUnsupportedConsole =>
      'Diese Konsole wird in dieser App-Version nicht unterstützt.';

  @override
  String sourceInstallAlreadyInstalled(String name) {
    return 'Diese Quelle ist bereits auf „$name“ installiert.';
  }

  @override
  String get sourceInstallConfirmTitle => 'Quelle hinzufügen';

  @override
  String sourceInstallConfirmBody(String name) {
    return 'Neue Quelle zu „$name“ hinzufügen?';
  }

  @override
  String sourceInstallSuccess(String name) {
    return 'Quelle zu „$name“ hinzugefügt. Gehe zu Quellen, um sie zu synchronisieren.';
  }

  @override
  String sourceInstallAddError(String error) {
    return 'Quelle konnte nicht hinzugefügt werden: $error';
  }
}
