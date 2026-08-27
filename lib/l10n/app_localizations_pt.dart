// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get commonAdd => 'Adicionar';

  @override
  String get commonChange => 'Alterar';

  @override
  String get commonSet => 'Definir';

  @override
  String get commonOk => 'OK';

  @override
  String commonGenericError(String error) {
    return 'Erro: $error';
  }

  @override
  String get routerPageNotFoundTitle => 'Página não encontrada';

  @override
  String get routerPageNotFoundAction => 'Voltar às plataformas';

  @override
  String get navBarPlatforms => 'Plataformas';

  @override
  String get navBarDownloads => 'Downloads';

  @override
  String get navBarSources => 'Fontes';

  @override
  String get navBarSettings => 'Definições';

  @override
  String get aboutTitle => 'Sobre';

  @override
  String get aboutBody => 'App pessoal de biblioteca e downloads de ROMs.';

  @override
  String get onboardingSkip => 'Saltar';

  @override
  String get onboardingNext => 'Seguinte';

  @override
  String get onboardingStart => 'Começar';

  @override
  String onboardingStepCounter(int step, int total) {
    return 'PASSO $step / $total';
  }

  @override
  String get onboardingStep1Title => 'A tua biblioteca retro — numa só app';

  @override
  String get onboardingStep1Description =>
      'O PixelVault organiza ROMs de todas as tuas consolas favoritas. Pesquisa, filtra por tags e descarrega — tudo a partir do telemóvel.';

  @override
  String get onboardingStep1Highlight1 => 'PixelVault';

  @override
  String get onboardingStep1Highlight2 => 'ROMs';

  @override
  String get onboardingStep2Title => 'Indexa qualquer fonte — sem descarregar';

  @override
  String get onboardingStep2Description =>
      'Adiciona servidores HTTP ou magnet links. O PixelVault lê toda a árvore de ficheiros e cataloga nomes, tags e tamanhos — sem transferir os jogos.';

  @override
  String get onboardingStep2Highlight1 => 'HTTP';

  @override
  String get onboardingStep2Highlight2 => 'magnet links';

  @override
  String get onboardingStep3Title => 'Descarrega com controlo total';

  @override
  String get onboardingStep3Description =>
      'Downloads simultâneos, limite de velocidade, extração automática de arquivos e downloads em segundo plano — sem perder nada ao fechar a app.';

  @override
  String get onboardingStep3Highlight1 => 'extração automática';

  @override
  String get onboardingStep3Highlight2 => 'segundo plano';

  @override
  String get onboardingStep4Title => 'Pronto para jogar';

  @override
  String get onboardingStep4Description =>
      'Organiza os ficheiros por consola, escolhe a pasta de destino e abre-os diretamente no teu emulador favorito. Bons jogos!';

  @override
  String get onboardingStep4Highlight1 => 'emulador favorito';

  @override
  String get sourcesEyebrow => 'SCRAPING';

  @override
  String get sourcesTitle => 'Fontes';

  @override
  String sourcesUnsyncedBanner(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count consolas com fontes mas ainda por sincronizar.',
      one: '1 consola com fontes mas ainda por sincronizar.',
      zero: '0 consolas com fontes mas ainda por sincronizar.',
    );
    return '$_temp0';
  }

  @override
  String get sourcesSyncAllButton => 'Sincronizar tudo';

  @override
  String sourcesManufacturerSummary(int consoleCount, int syncedCount) {
    String _temp0 = intl.Intl.pluralLogic(
      consoleCount,
      locale: localeName,
      other: '$consoleCount consolas',
      one: '1 consola',
      zero: '0 consolas',
    );
    String _temp1 = intl.Intl.pluralLogic(
      syncedCount,
      locale: localeName,
      other: '$syncedCount sincronizadas',
      one: '1 sincronizada',
      zero: '0 sincronizadas',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String get sourcesAddConsoleTooltip => 'Adicionar consola';

  @override
  String get sourcesNoConsolesEmptyState =>
      'Sem consolas. Usa o botão + para adicionar.';

  @override
  String get sourcesNeverSynced => 'ainda por sincronizar';

  @override
  String sourcesGamesIndexedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jogos indexados',
      one: '1 jogo indexado',
      zero: '0 jogos indexados',
    );
    return '$_temp0';
  }

  @override
  String sourcesSourceCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fontes',
      one: '1 fonte',
      zero: '0 fontes',
    );
    return '$_temp0';
  }

  @override
  String sourcesSourceLabel(int index) {
    return 'Fonte $index';
  }

  @override
  String get sourcesAddSourceTooltip => 'Adicionar fonte';

  @override
  String get sourcesRemoveSourceTooltip => 'Remover fonte';

  @override
  String get sourcesNoSourcesEmptyState =>
      'Sem fontes. Usa o ícone de link para adicionar uma.';

  @override
  String get sourcesEmptyStateBody =>
      'Adiciona um fabricante e uma fonte (HTTP ou magnet) para começar a indexar jogos.';

  @override
  String get sourcesAddManufacturerButton => 'Adicionar fabricante';

  @override
  String get sourcesSyncingBanner => 'A sincronizar catálogo';

  @override
  String sourcesAddManufacturerError(String error) {
    return 'Falha ao adicionar fabricante: $error';
  }

  @override
  String sourcesAddConsoleError(String error) {
    return 'Falha ao adicionar consola: $error';
  }

  @override
  String sourcesAddSourceError(String error) {
    return 'Falha ao adicionar fonte: $error';
  }

  @override
  String sourcesRemoveSourceError(String error) {
    return 'Falha ao remover fonte: $error';
  }

  @override
  String get addManufacturerDialogTitle => 'Novo fabricante';

  @override
  String get addManufacturerDialogIdLabel => 'ID (ex: nintendo)';

  @override
  String get addManufacturerDialogNameLabel => 'Nome (ex: Nintendo)';

  @override
  String get addConsoleDialogTitle => 'Nova consola';

  @override
  String get addConsoleDialogIdLabel => 'ID (ex: gameboy_advance)';

  @override
  String get addConsoleDialogNameLabel => 'Nome (ex: Game Boy Advance)';

  @override
  String get addUrlDialogTitle => 'Nova fonte';

  @override
  String get addUrlDialogUrlLabel => 'URL (http://…) ou magnet:?…';

  @override
  String get addUrlDialogContentTypeLabel => 'Tipo de conteúdo';

  @override
  String addUrlDialogApplyTo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 's',
      one: '',
      zero: 's',
    );
    return 'Aplicar a ($count selecionada$_temp0):';
  }

  @override
  String get addUrlDialogSubmitButton => 'Adicionar e sincronizar';

  @override
  String get settingsEyebrow => 'SISTEMA';

  @override
  String get settingsTitle => 'Definições';

  @override
  String get settingsStorageSection => 'ARMAZENAMENTO';

  @override
  String get settingsDownloadDirTitle => 'Pasta de download (SAF)';

  @override
  String get settingsNotSet => 'Não definida';

  @override
  String get settingsSeparateByConsoleTitle => 'Separar por consola';

  @override
  String get settingsSeparateByConsoleSubtitle =>
      'Cria /Nintendo Game Boy Advance/…';

  @override
  String get settingsLanguageSection => 'IDIOMA';

  @override
  String get settingsLanguageTitle => 'Idioma';

  @override
  String get settingsConsoleFoldersSection => 'PASTAS POR CONSOLA';

  @override
  String get settingsNoConsolesConfigured => 'Sem consolas configuradas ainda.';

  @override
  String get settingsNetworkSection => 'REDE';

  @override
  String get settingsSpeedLimitTitle => 'Limite de velocidade';

  @override
  String get settingsUnlimited => 'Ilimitado';

  @override
  String settingsSpeedMbs(String value) {
    return '$value MB/s';
  }

  @override
  String get settingsSpeedMinLabel => '0 · ilimitado';

  @override
  String get settingsConcurrentDownloadsTitle => 'Downloads simultâneos';

  @override
  String get settingsConcurrentMaxLabel => '6 máx.';

  @override
  String get settingsArchivesSection => 'ARQUIVOS';

  @override
  String get settingsAutoUnzipTitle => 'Extração automática';

  @override
  String get settingsAutoUnzipSubtitle =>
      '.zip .7z .rar .tar .gz .xz · apaga o comprimido';

  @override
  String get settingsUsesMainFolder => 'Usa a pasta principal';

  @override
  String get downloadsEyebrow => 'FILA';

  @override
  String get downloadsTitle => 'Downloads';

  @override
  String get downloadsActiveLabel => 'Ativos';

  @override
  String get downloadsSpeedLabel => 'MB/s total';

  @override
  String get downloadsQueuedLabel => 'Na fila';

  @override
  String get downloadsEmptyState => 'Nenhum download em curso';

  @override
  String downloadsStatusDownloading(String percent, String speed) {
    return '$percent% · $speed MB/s';
  }

  @override
  String get downloadsStatusCopying => 'A copiar p/ SD Card (SAF)';

  @override
  String get downloadsStatusUnzipping => 'A descompactar arquivo';

  @override
  String get downloadsStatusCompleted => 'Concluído';

  @override
  String get downloadsStatusFailed => 'Falhou · toca em tentar de novo';

  @override
  String get downloadsChipDownloading => 'A descarregar';

  @override
  String get downloadsChipCopying => 'A copiar';

  @override
  String get downloadsChipUnzipping => 'A extrair';

  @override
  String get downloadsChipFailed => 'Falhou';

  @override
  String get downloadsStopTooltip => 'Parar';

  @override
  String get downloadsRetryTooltip => 'Tentar novamente';

  @override
  String get downloadsRemoveTooltip => 'Remover';

  @override
  String get downloadsRemoveFromListTooltip => 'Remover da lista';

  @override
  String get libraryDefaultTitle => 'Biblioteca';

  @override
  String get libraryHintSearch => 'Pesquisar roms…';

  @override
  String get libraryFiltersChip => 'Filtros';

  @override
  String get libraryFormatChip => 'Formato';

  @override
  String get libraryColRegion => 'REGIÃO';

  @override
  String get libraryColLanguage => 'IDIOMA';

  @override
  String get libraryColVideo => 'VÍDEO';

  @override
  String get libraryColType => 'TIPO';

  @override
  String get libraryColExtension => 'EXTENSÃO';

  @override
  String get libraryNoResults =>
      'Sem resultados.\nAdiciona uma fonte no separador Fontes e faz rescan.';

  @override
  String libraryMetaLabel(String count, String size) {
    return '$count ficheiros · $size';
  }

  @override
  String libraryDownloadStartedSnackbar(String name) {
    return 'Download de \"$name\" iniciado.';
  }

  @override
  String platformSelectSeedError(String error) {
    return 'Erro ao carregar consolas: $error';
  }

  @override
  String get platformSelectEyebrow => 'CATÁLOGO';

  @override
  String get platformSelectTitle => 'Plataformas';

  @override
  String platformSelectSubtitle(int consoleCount, int fileCount) {
    return '$consoleCount consolas ativas · $fileCount ficheiros indexados';
  }

  @override
  String get platformSelectSearchHint => 'Pesquisar consolas…';

  @override
  String get platformSelectActiveConsolesSection => 'CONSOLAS ATIVAS';

  @override
  String get platformSelectEmptyState =>
      'Sem plataformas.\nVai a Fontes para adicionar fontes.';

  @override
  String get platformSelectGlobalLibraryTitle => 'Biblioteca global';

  @override
  String get platformSelectGlobalLibrarySubtitle =>
      'Todos os jogos de todas as consolas';

  @override
  String platformSelectConsoleSummary(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jogos',
      one: '1 jogo',
      zero: '0 jogos',
    );
    return '$_temp0 · $size';
  }

  @override
  String sourceInstallResolveError(String error) {
    return 'Não foi possível instalar a fonte: $error';
  }

  @override
  String get sourceInstallUnsupportedConsole =>
      'Esta consola não é suportada nesta versão da app.';

  @override
  String sourceInstallAlreadyInstalled(String name) {
    return 'Esta fonte já está instalada em \"$name\".';
  }

  @override
  String get sourceInstallConfirmTitle => 'Adicionar fonte';

  @override
  String sourceInstallConfirmBody(String name) {
    return 'Adicionar uma nova fonte a \"$name\"?';
  }

  @override
  String sourceInstallSuccess(String name) {
    return 'Fonte adicionada a \"$name\". Vai a Fontes para sincronizar.';
  }

  @override
  String sourceInstallAddError(String error) {
    return 'Falha ao adicionar a fonte: $error';
  }
}
