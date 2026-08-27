// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get commonAdd => 'Añadir';

  @override
  String get commonChange => 'Cambiar';

  @override
  String get commonSet => 'Definir';

  @override
  String get commonOk => 'OK';

  @override
  String commonGenericError(String error) {
    return 'Error: $error';
  }

  @override
  String get routerPageNotFoundTitle => 'Página no encontrada';

  @override
  String get routerPageNotFoundAction => 'Volver a plataformas';

  @override
  String get navBarPlatforms => 'Plataformas';

  @override
  String get navBarDownloads => 'Descargas';

  @override
  String get navBarSources => 'Fuentes';

  @override
  String get navBarSettings => 'Ajustes';

  @override
  String get aboutTitle => 'Acerca de';

  @override
  String get aboutBody => 'App personal de biblioteca y descargas de ROMs.';

  @override
  String get onboardingSkip => 'Saltar';

  @override
  String get onboardingNext => 'Siguiente';

  @override
  String get onboardingStart => 'Empezar';

  @override
  String onboardingStepCounter(int step, int total) {
    return 'PASO $step / $total';
  }

  @override
  String get onboardingStep1Title => 'Tu biblioteca retro — en una sola app';

  @override
  String get onboardingStep1Description =>
      'PixelVault organiza ROMs de todas tus consolas favoritas. Busca, filtra por etiquetas y descarga — todo desde el móvil.';

  @override
  String get onboardingStep1Highlight1 => 'PixelVault';

  @override
  String get onboardingStep1Highlight2 => 'ROMs';

  @override
  String get onboardingStep2Title => 'Indexa cualquier fuente — sin descargar';

  @override
  String get onboardingStep2Description =>
      'Añade servidores HTTP o enlaces magnet. PixelVault lee todo el árbol de ficheros y cataloga nombres, etiquetas y tamaños — sin transferir los juegos.';

  @override
  String get onboardingStep2Highlight1 => 'HTTP';

  @override
  String get onboardingStep2Highlight2 => 'enlaces magnet';

  @override
  String get onboardingStep3Title => 'Descarga con control total';

  @override
  String get onboardingStep3Description =>
      'Descargas simultáneas, límite de velocidad, extracción automática de archivos y descargas en segundo plano — sin perder nada al cerrar la app.';

  @override
  String get onboardingStep3Highlight1 => 'extracción automática';

  @override
  String get onboardingStep3Highlight2 => 'segundo plano';

  @override
  String get onboardingStep4Title => 'Listo para jugar';

  @override
  String get onboardingStep4Description =>
      'Organiza los ficheros por consola, elige la carpeta de destino y ábrelos directamente en tu emulador favorito. ¡Buenos juegos!';

  @override
  String get onboardingStep4Highlight1 => 'emulador favorito';

  @override
  String get sourcesEyebrow => 'SCRAPING';

  @override
  String get sourcesTitle => 'Fuentes';

  @override
  String sourcesUnsyncedBanner(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count consolas tienen fuentes pero aún no están sincronizadas.',
      one: '1 consola tiene fuentes pero aún no está sincronizada.',
    );
    return '$_temp0';
  }

  @override
  String get sourcesSyncAllButton => 'Sincronizar todo';

  @override
  String sourcesManufacturerSummary(int consoleCount, int syncedCount) {
    String _temp0 = intl.Intl.pluralLogic(
      consoleCount,
      locale: localeName,
      other: '$consoleCount consolas',
      one: '1 consola',
    );
    String _temp1 = intl.Intl.pluralLogic(
      syncedCount,
      locale: localeName,
      other: '$syncedCount sincronizadas',
      one: '1 sincronizada',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String get sourcesAddConsoleTooltip => 'Añadir consola';

  @override
  String get sourcesNoConsolesEmptyState =>
      'Sin consolas. Usa el botón + para añadir una.';

  @override
  String get sourcesNeverSynced => 'aún por sincronizar';

  @override
  String sourcesGamesIndexedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count juegos indexados',
      one: '1 juego indexado',
    );
    return '$_temp0';
  }

  @override
  String sourcesSourceCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fuentes',
      one: '1 fuente',
    );
    return '$_temp0';
  }

  @override
  String sourcesSourceLabel(int index) {
    return 'Fuente $index';
  }

  @override
  String get sourcesAddSourceTooltip => 'Añadir fuente';

  @override
  String get sourcesRemoveSourceTooltip => 'Eliminar fuente';

  @override
  String get sourcesNoSourcesEmptyState =>
      'Sin fuentes. Usa el icono de enlace para añadir una.';

  @override
  String get sourcesEmptyStateBody =>
      'Añade un fabricante y una fuente (HTTP o magnet) para empezar a indexar juegos.';

  @override
  String get sourcesAddManufacturerButton => 'Añadir fabricante';

  @override
  String get sourcesSyncingBanner => 'Sincronizando catálogo';

  @override
  String sourcesAddManufacturerError(String error) {
    return 'Error al añadir el fabricante: $error';
  }

  @override
  String sourcesAddConsoleError(String error) {
    return 'Error al añadir la consola: $error';
  }

  @override
  String sourcesAddSourceError(String error) {
    return 'Error al añadir la fuente: $error';
  }

  @override
  String sourcesRemoveSourceError(String error) {
    return 'Error al eliminar la fuente: $error';
  }

  @override
  String get addManufacturerDialogTitle => 'Nuevo fabricante';

  @override
  String get addManufacturerDialogIdLabel => 'ID (ej: nintendo)';

  @override
  String get addManufacturerDialogNameLabel => 'Nombre (ej: Nintendo)';

  @override
  String get addConsoleDialogTitle => 'Nueva consola';

  @override
  String get addConsoleDialogIdLabel => 'ID (ej: gameboy_advance)';

  @override
  String get addConsoleDialogNameLabel => 'Nombre (ej: Game Boy Advance)';

  @override
  String get addUrlDialogTitle => 'Nueva fuente';

  @override
  String get addUrlDialogUrlLabel => 'URL (http://…) o magnet:?…';

  @override
  String get addUrlDialogContentTypeLabel => 'Tipo de contenido';

  @override
  String addUrlDialogApplyTo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 's',
      one: '',
    );
    return 'Aplicar a ($count seleccionada$_temp0):';
  }

  @override
  String get addUrlDialogSubmitButton => 'Añadir y sincronizar';

  @override
  String get settingsEyebrow => 'SISTEMA';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get settingsStorageSection => 'ALMACENAMIENTO';

  @override
  String get settingsDownloadDirTitle => 'Carpeta de descargas (SAF)';

  @override
  String get settingsNotSet => 'No definida';

  @override
  String get settingsSeparateByConsoleTitle => 'Separar por consola';

  @override
  String get settingsSeparateByConsoleSubtitle =>
      'Crea /Nintendo Game Boy Advance/…';

  @override
  String get settingsLanguageSection => 'IDIOMA';

  @override
  String get settingsLanguageTitle => 'Idioma';

  @override
  String get settingsConsoleFoldersSection => 'CARPETAS POR CONSOLA';

  @override
  String get settingsNoConsolesConfigured =>
      'Aún no hay consolas configuradas.';

  @override
  String get settingsNetworkSection => 'RED';

  @override
  String get settingsSpeedLimitTitle => 'Límite de velocidad';

  @override
  String get settingsUnlimited => 'Ilimitado';

  @override
  String settingsSpeedMbs(String value) {
    return '$value MB/s';
  }

  @override
  String get settingsSpeedMinLabel => '0 · ilimitado';

  @override
  String get settingsConcurrentDownloadsTitle => 'Descargas simultáneas';

  @override
  String get settingsConcurrentMaxLabel => '6 máx.';

  @override
  String get settingsArchivesSection => 'ARCHIVOS';

  @override
  String get settingsAutoUnzipTitle => 'Extracción automática';

  @override
  String get settingsAutoUnzipSubtitle =>
      '.zip .7z .rar .tar .gz .xz · borra el comprimido';

  @override
  String get settingsUsesMainFolder => 'Usa la carpeta principal';

  @override
  String get downloadsEyebrow => 'COLA';

  @override
  String get downloadsTitle => 'Descargas';

  @override
  String get downloadsActiveLabel => 'Activas';

  @override
  String get downloadsSpeedLabel => 'MB/s total';

  @override
  String get downloadsQueuedLabel => 'En cola';

  @override
  String get downloadsEmptyState => 'Ninguna descarga en curso';

  @override
  String downloadsStatusDownloading(String percent, String speed) {
    return '$percent% · $speed MB/s';
  }

  @override
  String get downloadsStatusCopying => 'Copiando a tarjeta SD (SAF)';

  @override
  String get downloadsStatusUnzipping => 'Descomprimiendo archivo';

  @override
  String get downloadsStatusCompleted => 'Completado';

  @override
  String get downloadsStatusFailed => 'Fallido · toca para reintentar';

  @override
  String get downloadsChipDownloading => 'Descargando';

  @override
  String get downloadsChipCopying => 'Copiando';

  @override
  String get downloadsChipUnzipping => 'Extrayendo';

  @override
  String get downloadsChipFailed => 'Fallido';

  @override
  String get downloadsStopTooltip => 'Parar';

  @override
  String get downloadsRetryTooltip => 'Reintentar';

  @override
  String get downloadsRemoveTooltip => 'Eliminar';

  @override
  String get downloadsRemoveFromListTooltip => 'Eliminar de la lista';

  @override
  String get libraryDefaultTitle => 'Biblioteca';

  @override
  String get libraryHintSearch => 'Buscar roms…';

  @override
  String get libraryFiltersChip => 'Filtros';

  @override
  String get libraryFormatChip => 'Formato';

  @override
  String get libraryColRegion => 'REGIÓN';

  @override
  String get libraryColLanguage => 'IDIOMA';

  @override
  String get libraryColVideo => 'VÍDEO';

  @override
  String get libraryColType => 'TIPO';

  @override
  String get libraryColExtension => 'EXTENSIÓN';

  @override
  String get libraryNoResults =>
      'Sin resultados.\nAñade una fuente en la pestaña Fuentes y vuelve a escanear.';

  @override
  String libraryMetaLabel(String count, String size) {
    return '$count ficheros · $size';
  }

  @override
  String libraryDownloadStartedSnackbar(String name) {
    return 'Descarga de \"$name\" iniciada.';
  }

  @override
  String platformSelectSeedError(String error) {
    return 'Error al cargar las consolas: $error';
  }

  @override
  String get platformSelectEyebrow => 'CATÁLOGO';

  @override
  String get platformSelectTitle => 'Plataformas';

  @override
  String platformSelectSubtitle(int consoleCount, int fileCount) {
    return '$consoleCount consolas activas · $fileCount ficheros indexados';
  }

  @override
  String get platformSelectSearchHint => 'Buscar consolas…';

  @override
  String get platformSelectActiveConsolesSection => 'CONSOLAS ACTIVAS';

  @override
  String get platformSelectEmptyState =>
      'Sin plataformas.\nVe a Fuentes para añadir fuentes.';

  @override
  String get platformSelectGlobalLibraryTitle => 'Biblioteca global';

  @override
  String get platformSelectGlobalLibrarySubtitle =>
      'Todos los juegos de todas las consolas';

  @override
  String platformSelectConsoleSummary(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count juegos',
      one: '1 juego',
    );
    return '$_temp0 · $size';
  }

  @override
  String sourceInstallResolveError(String error) {
    return 'No se pudo instalar la fuente: $error';
  }

  @override
  String get sourceInstallUnsupportedConsole =>
      'Esta consola no es compatible con esta versión de la app.';

  @override
  String sourceInstallAlreadyInstalled(String name) {
    return 'Esta fuente ya está instalada en \"$name\".';
  }

  @override
  String get sourceInstallConfirmTitle => 'Añadir fuente';

  @override
  String sourceInstallConfirmBody(String name) {
    return '¿Añadir una nueva fuente a \"$name\"?';
  }

  @override
  String sourceInstallSuccess(String name) {
    return 'Fuente añadida a \"$name\". Ve a Fuentes para sincronizarla.';
  }

  @override
  String sourceInstallAddError(String error) {
    return 'Error al añadir la fuente: $error';
  }
}
