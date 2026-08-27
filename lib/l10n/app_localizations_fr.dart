// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get commonCancel => 'Annuler';

  @override
  String get commonAdd => 'Ajouter';

  @override
  String get commonChange => 'Modifier';

  @override
  String get commonSet => 'Définir';

  @override
  String get commonOk => 'OK';

  @override
  String commonGenericError(String error) {
    return 'Erreur : $error';
  }

  @override
  String get routerPageNotFoundTitle => 'Page introuvable';

  @override
  String get routerPageNotFoundAction => 'Retour aux plateformes';

  @override
  String get navBarPlatforms => 'Plateformes';

  @override
  String get navBarDownloads => 'Téléchargements';

  @override
  String get navBarSources => 'Sources';

  @override
  String get navBarSettings => 'Réglages';

  @override
  String get aboutTitle => 'À propos';

  @override
  String get aboutBody =>
      'Application personnelle de bibliothèque et de téléchargement de ROMs.';

  @override
  String get onboardingSkip => 'Passer';

  @override
  String get onboardingNext => 'Suivant';

  @override
  String get onboardingStart => 'Commencer';

  @override
  String onboardingStepCounter(int step, int total) {
    return 'ÉTAPE $step / $total';
  }

  @override
  String get onboardingStep1Title =>
      'Ta bibliothèque rétro — dans une seule app';

  @override
  String get onboardingStep1Description =>
      'PixelVault organise les ROMs de toutes tes consoles préférées. Recherche, filtre par tags et télécharge — tout depuis ton téléphone.';

  @override
  String get onboardingStep1Highlight1 => 'PixelVault';

  @override
  String get onboardingStep1Highlight2 => 'ROMs';

  @override
  String get onboardingStep2Title =>
      'Indexe n\'importe quelle source — sans télécharger';

  @override
  String get onboardingStep2Description =>
      'Ajoute des serveurs HTTP ou des liens magnet. PixelVault lit toute l\'arborescence des fichiers et catalogue noms, tags et tailles — sans transférer les jeux.';

  @override
  String get onboardingStep2Highlight1 => 'HTTP';

  @override
  String get onboardingStep2Highlight2 => 'liens magnet';

  @override
  String get onboardingStep3Title => 'Télécharge avec un contrôle total';

  @override
  String get onboardingStep3Description =>
      'Téléchargements simultanés, limite de vitesse, extraction automatique des archives et téléchargements en arrière-plan — ne perds rien en fermant l\'app.';

  @override
  String get onboardingStep3Highlight1 => 'extraction automatique';

  @override
  String get onboardingStep3Highlight2 => 'arrière-plan';

  @override
  String get onboardingStep4Title => 'Prêt à jouer';

  @override
  String get onboardingStep4Description =>
      'Organise les fichiers par console, choisis le dossier de destination et ouvre-les directement dans ton émulateur préféré. Bon jeu !';

  @override
  String get onboardingStep4Highlight1 => 'émulateur préféré';

  @override
  String get sourcesEyebrow => 'SCRAPING';

  @override
  String get sourcesTitle => 'Sources';

  @override
  String sourcesUnsyncedBanner(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count consoles ont des sources mais ne sont pas encore synchronisées.',
      one: '1 console a des sources mais n\'est pas encore synchronisée.',
      zero: '0 consoles ont des sources mais ne sont pas encore synchronisées.',
    );
    return '$_temp0';
  }

  @override
  String get sourcesSyncAllButton => 'Tout synchroniser';

  @override
  String sourcesManufacturerSummary(int consoleCount, int syncedCount) {
    String _temp0 = intl.Intl.pluralLogic(
      consoleCount,
      locale: localeName,
      other: '$consoleCount consoles',
      one: '1 console',
      zero: '0 consoles',
    );
    String _temp1 = intl.Intl.pluralLogic(
      syncedCount,
      locale: localeName,
      other: '$syncedCount synchronisées',
      one: '1 synchronisée',
      zero: '0 synchronisées',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String get sourcesAddConsoleTooltip => 'Ajouter une console';

  @override
  String get sourcesNoConsolesEmptyState =>
      'Aucune console. Utilise le bouton + pour en ajouter une.';

  @override
  String get sourcesNeverSynced => 'pas encore synchronisée';

  @override
  String sourcesGamesIndexedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jeux indexés',
      one: '1 jeu indexé',
      zero: '0 jeux indexés',
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
      zero: '0 sources',
    );
    return '$_temp0';
  }

  @override
  String sourcesSourceLabel(int index) {
    return 'Source $index';
  }

  @override
  String get sourcesAddSourceTooltip => 'Ajouter une source';

  @override
  String get sourcesRemoveSourceTooltip => 'Supprimer la source';

  @override
  String get sourcesNoSourcesEmptyState =>
      'Aucune source. Utilise l\'icône de lien pour en ajouter une.';

  @override
  String get sourcesEmptyStateBody =>
      'Ajoute un fabricant et une source (HTTP ou magnet) pour commencer à indexer des jeux.';

  @override
  String get sourcesAddManufacturerButton => 'Ajouter un fabricant';

  @override
  String get sourcesSyncingBanner => 'Synchronisation du catalogue';

  @override
  String sourcesAddManufacturerError(String error) {
    return 'Échec de l\'ajout du fabricant : $error';
  }

  @override
  String sourcesAddConsoleError(String error) {
    return 'Échec de l\'ajout de la console : $error';
  }

  @override
  String sourcesAddSourceError(String error) {
    return 'Échec de l\'ajout de la source : $error';
  }

  @override
  String sourcesRemoveSourceError(String error) {
    return 'Échec de la suppression de la source : $error';
  }

  @override
  String get addManufacturerDialogTitle => 'Nouveau fabricant';

  @override
  String get addManufacturerDialogIdLabel => 'ID (ex : nintendo)';

  @override
  String get addManufacturerDialogNameLabel => 'Nom (ex : Nintendo)';

  @override
  String get addConsoleDialogTitle => 'Nouvelle console';

  @override
  String get addConsoleDialogIdLabel => 'ID (ex : gameboy_advance)';

  @override
  String get addConsoleDialogNameLabel => 'Nom (ex : Game Boy Advance)';

  @override
  String get addUrlDialogTitle => 'Nouvelle source';

  @override
  String get addUrlDialogUrlLabel => 'URL (http://…) ou magnet:?…';

  @override
  String get addUrlDialogContentTypeLabel => 'Type de contenu';

  @override
  String addUrlDialogApplyTo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 's',
      one: '',
      zero: 's',
    );
    return 'Appliquer à ($count sélectionnée$_temp0) :';
  }

  @override
  String get addUrlDialogSubmitButton => 'Ajouter et synchroniser';

  @override
  String get settingsEyebrow => 'SYSTÈME';

  @override
  String get settingsTitle => 'Réglages';

  @override
  String get settingsStorageSection => 'STOCKAGE';

  @override
  String get settingsDownloadDirTitle => 'Dossier de téléchargement (SAF)';

  @override
  String get settingsNotSet => 'Non défini';

  @override
  String get settingsSeparateByConsoleTitle => 'Séparer par console';

  @override
  String get settingsSeparateByConsoleSubtitle =>
      'Crée /Nintendo Game Boy Advance/…';

  @override
  String get settingsLanguageSection => 'LANGUE';

  @override
  String get settingsLanguageTitle => 'Langue';

  @override
  String get settingsConsoleFoldersSection => 'DOSSIERS PAR CONSOLE';

  @override
  String get settingsNoConsolesConfigured =>
      'Aucune console configurée pour l\'instant.';

  @override
  String get settingsNetworkSection => 'RÉSEAU';

  @override
  String get settingsSpeedLimitTitle => 'Limite de vitesse';

  @override
  String get settingsUnlimited => 'Illimité';

  @override
  String settingsSpeedMbs(String value) {
    return '$value Mo/s';
  }

  @override
  String get settingsSpeedMinLabel => '0 · illimité';

  @override
  String get settingsConcurrentDownloadsTitle => 'Téléchargements simultanés';

  @override
  String get settingsConcurrentMaxLabel => '6 max.';

  @override
  String get settingsArchivesSection => 'ARCHIVES';

  @override
  String get settingsAutoUnzipTitle => 'Extraction automatique';

  @override
  String get settingsAutoUnzipSubtitle =>
      '.zip .7z .rar .tar .gz .xz · supprime l\'archive';

  @override
  String get settingsUsesMainFolder => 'Utilise le dossier principal';

  @override
  String get downloadsEyebrow => 'FILE';

  @override
  String get downloadsTitle => 'Téléchargements';

  @override
  String get downloadsActiveLabel => 'Actifs';

  @override
  String get downloadsSpeedLabel => 'Mo/s total';

  @override
  String get downloadsQueuedLabel => 'En attente';

  @override
  String get downloadsEmptyState => 'Aucun téléchargement en cours';

  @override
  String downloadsStatusDownloading(String percent, String speed) {
    return '$percent% · $speed Mo/s';
  }

  @override
  String get downloadsStatusCopying => 'Copie vers la carte SD (SAF)';

  @override
  String get downloadsStatusUnzipping => 'Extraction de l\'archive';

  @override
  String get downloadsStatusCompleted => 'Terminé';

  @override
  String get downloadsStatusFailed => 'Échec · touche pour réessayer';

  @override
  String get downloadsChipDownloading => 'Téléchargement';

  @override
  String get downloadsChipCopying => 'Copie';

  @override
  String get downloadsChipUnzipping => 'Extraction';

  @override
  String get downloadsChipFailed => 'Échec';

  @override
  String get downloadsStopTooltip => 'Arrêter';

  @override
  String get downloadsRetryTooltip => 'Réessayer';

  @override
  String get downloadsRemoveTooltip => 'Supprimer';

  @override
  String get downloadsRemoveFromListTooltip => 'Retirer de la liste';

  @override
  String get libraryDefaultTitle => 'Bibliothèque';

  @override
  String get libraryHintSearch => 'Rechercher des roms…';

  @override
  String get libraryFiltersChip => 'Filtres';

  @override
  String get libraryFormatChip => 'Format';

  @override
  String get libraryColRegion => 'RÉGION';

  @override
  String get libraryColLanguage => 'LANGUE';

  @override
  String get libraryColVideo => 'VIDÉO';

  @override
  String get libraryColType => 'TYPE';

  @override
  String get libraryColExtension => 'EXTENSION';

  @override
  String get libraryNoResults =>
      'Aucun résultat.\nAjoute une source dans l\'onglet Sources et relance l\'analyse.';

  @override
  String libraryMetaLabel(String count, String size) {
    return '$count fichiers · $size';
  }

  @override
  String libraryDownloadStartedSnackbar(String name) {
    return 'Téléchargement de « $name » démarré.';
  }

  @override
  String platformSelectSeedError(String error) {
    return 'Erreur lors du chargement des consoles : $error';
  }

  @override
  String get platformSelectEyebrow => 'CATALOGUE';

  @override
  String get platformSelectTitle => 'Plateformes';

  @override
  String platformSelectSubtitle(int consoleCount, int fileCount) {
    return '$consoleCount consoles actives · $fileCount fichiers indexés';
  }

  @override
  String get platformSelectSearchHint => 'Rechercher des consoles…';

  @override
  String get platformSelectActiveConsolesSection => 'CONSOLES ACTIVES';

  @override
  String get platformSelectEmptyState =>
      'Aucune plateforme.\nVa dans Sources pour en ajouter.';

  @override
  String get platformSelectGlobalLibraryTitle => 'Bibliothèque globale';

  @override
  String get platformSelectGlobalLibrarySubtitle =>
      'Tous les jeux de toutes les consoles';

  @override
  String platformSelectConsoleSummary(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jeux',
      one: '1 jeu',
      zero: '0 jeux',
    );
    return '$_temp0 · $size';
  }

  @override
  String sourceInstallResolveError(String error) {
    return 'Impossible d\'installer la source : $error';
  }

  @override
  String get sourceInstallUnsupportedConsole =>
      'Cette console n\'est pas prise en charge dans cette version de l\'app.';

  @override
  String sourceInstallAlreadyInstalled(String name) {
    return 'Cette source est déjà installée sur « $name ».';
  }

  @override
  String get sourceInstallConfirmTitle => 'Ajouter une source';

  @override
  String sourceInstallConfirmBody(String name) {
    return 'Ajouter une nouvelle source à « $name » ?';
  }

  @override
  String sourceInstallSuccess(String name) {
    return 'Source ajoutée à « $name ». Va dans Sources pour la synchroniser.';
  }

  @override
  String sourceInstallAddError(String error) {
    return 'Échec de l\'ajout de la source : $error';
  }
}
