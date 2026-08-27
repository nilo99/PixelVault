import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('pt'),
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
  ];

  /// No description provided for @commonCancel.
  ///
  /// In pt, this message translates to:
  /// **'Cancelar'**
  String get commonCancel;

  /// No description provided for @commonAdd.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar'**
  String get commonAdd;

  /// No description provided for @commonChange.
  ///
  /// In pt, this message translates to:
  /// **'Alterar'**
  String get commonChange;

  /// No description provided for @commonSet.
  ///
  /// In pt, this message translates to:
  /// **'Definir'**
  String get commonSet;

  /// No description provided for @commonOk.
  ///
  /// In pt, this message translates to:
  /// **'OK'**
  String get commonOk;

  /// No description provided for @commonGenericError.
  ///
  /// In pt, this message translates to:
  /// **'Erro: {error}'**
  String commonGenericError(String error);

  /// No description provided for @routerPageNotFoundTitle.
  ///
  /// In pt, this message translates to:
  /// **'Página não encontrada'**
  String get routerPageNotFoundTitle;

  /// No description provided for @routerPageNotFoundAction.
  ///
  /// In pt, this message translates to:
  /// **'Voltar às plataformas'**
  String get routerPageNotFoundAction;

  /// No description provided for @navBarPlatforms.
  ///
  /// In pt, this message translates to:
  /// **'Plataformas'**
  String get navBarPlatforms;

  /// No description provided for @navBarDownloads.
  ///
  /// In pt, this message translates to:
  /// **'Downloads'**
  String get navBarDownloads;

  /// No description provided for @navBarSources.
  ///
  /// In pt, this message translates to:
  /// **'Fontes'**
  String get navBarSources;

  /// No description provided for @navBarSettings.
  ///
  /// In pt, this message translates to:
  /// **'Definições'**
  String get navBarSettings;

  /// No description provided for @aboutTitle.
  ///
  /// In pt, this message translates to:
  /// **'Sobre'**
  String get aboutTitle;

  /// No description provided for @aboutBody.
  ///
  /// In pt, this message translates to:
  /// **'App pessoal de biblioteca e downloads de ROMs.'**
  String get aboutBody;

  /// No description provided for @onboardingSkip.
  ///
  /// In pt, this message translates to:
  /// **'Saltar'**
  String get onboardingSkip;

  /// No description provided for @onboardingNext.
  ///
  /// In pt, this message translates to:
  /// **'Seguinte'**
  String get onboardingNext;

  /// No description provided for @onboardingStart.
  ///
  /// In pt, this message translates to:
  /// **'Começar'**
  String get onboardingStart;

  /// No description provided for @onboardingStepCounter.
  ///
  /// In pt, this message translates to:
  /// **'PASSO {step} / {total}'**
  String onboardingStepCounter(int step, int total);

  /// No description provided for @onboardingStep1Title.
  ///
  /// In pt, this message translates to:
  /// **'A tua biblioteca retro — numa só app'**
  String get onboardingStep1Title;

  /// No description provided for @onboardingStep1Description.
  ///
  /// In pt, this message translates to:
  /// **'O PixelVault organiza ROMs de todas as tuas consolas favoritas. Pesquisa, filtra por tags e descarrega — tudo a partir do telemóvel.'**
  String get onboardingStep1Description;

  /// No description provided for @onboardingStep1Highlight1.
  ///
  /// In pt, this message translates to:
  /// **'PixelVault'**
  String get onboardingStep1Highlight1;

  /// No description provided for @onboardingStep1Highlight2.
  ///
  /// In pt, this message translates to:
  /// **'ROMs'**
  String get onboardingStep1Highlight2;

  /// No description provided for @onboardingStep2Title.
  ///
  /// In pt, this message translates to:
  /// **'Indexa qualquer fonte — sem descarregar'**
  String get onboardingStep2Title;

  /// No description provided for @onboardingStep2Description.
  ///
  /// In pt, this message translates to:
  /// **'Adiciona servidores HTTP ou magnet links. O PixelVault lê toda a árvore de ficheiros e cataloga nomes, tags e tamanhos — sem transferir os jogos.'**
  String get onboardingStep2Description;

  /// No description provided for @onboardingStep2Highlight1.
  ///
  /// In pt, this message translates to:
  /// **'HTTP'**
  String get onboardingStep2Highlight1;

  /// No description provided for @onboardingStep2Highlight2.
  ///
  /// In pt, this message translates to:
  /// **'magnet links'**
  String get onboardingStep2Highlight2;

  /// No description provided for @onboardingStep3Title.
  ///
  /// In pt, this message translates to:
  /// **'Descarrega com controlo total'**
  String get onboardingStep3Title;

  /// No description provided for @onboardingStep3Description.
  ///
  /// In pt, this message translates to:
  /// **'Downloads simultâneos, limite de velocidade, extração automática de arquivos e downloads em segundo plano — sem perder nada ao fechar a app.'**
  String get onboardingStep3Description;

  /// No description provided for @onboardingStep3Highlight1.
  ///
  /// In pt, this message translates to:
  /// **'extração automática'**
  String get onboardingStep3Highlight1;

  /// No description provided for @onboardingStep3Highlight2.
  ///
  /// In pt, this message translates to:
  /// **'segundo plano'**
  String get onboardingStep3Highlight2;

  /// No description provided for @onboardingStep4Title.
  ///
  /// In pt, this message translates to:
  /// **'Pronto para jogar'**
  String get onboardingStep4Title;

  /// No description provided for @onboardingStep4Description.
  ///
  /// In pt, this message translates to:
  /// **'Organiza os ficheiros por consola, escolhe a pasta de destino e abre-os diretamente no teu emulador favorito. Bons jogos!'**
  String get onboardingStep4Description;

  /// No description provided for @onboardingStep4Highlight1.
  ///
  /// In pt, this message translates to:
  /// **'emulador favorito'**
  String get onboardingStep4Highlight1;

  /// No description provided for @sourcesEyebrow.
  ///
  /// In pt, this message translates to:
  /// **'SCRAPING'**
  String get sourcesEyebrow;

  /// No description provided for @sourcesTitle.
  ///
  /// In pt, this message translates to:
  /// **'Fontes'**
  String get sourcesTitle;

  /// No description provided for @sourcesUnsyncedBanner.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =0{0 consolas com fontes mas ainda por sincronizar.} =1{1 consola com fontes mas ainda por sincronizar.} other{{count} consolas com fontes mas ainda por sincronizar.}}'**
  String sourcesUnsyncedBanner(int count);

  /// No description provided for @sourcesSyncAllButton.
  ///
  /// In pt, this message translates to:
  /// **'Sincronizar tudo'**
  String get sourcesSyncAllButton;

  /// No description provided for @sourcesManufacturerSummary.
  ///
  /// In pt, this message translates to:
  /// **'{consoleCount, plural, =0{0 consolas} =1{1 consola} other{{consoleCount} consolas}} · {syncedCount, plural, =0{0 sincronizadas} =1{1 sincronizada} other{{syncedCount} sincronizadas}}'**
  String sourcesManufacturerSummary(int consoleCount, int syncedCount);

  /// No description provided for @sourcesAddConsoleTooltip.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar consola'**
  String get sourcesAddConsoleTooltip;

  /// No description provided for @sourcesNoConsolesEmptyState.
  ///
  /// In pt, this message translates to:
  /// **'Sem consolas. Usa o botão + para adicionar.'**
  String get sourcesNoConsolesEmptyState;

  /// No description provided for @sourcesNeverSynced.
  ///
  /// In pt, this message translates to:
  /// **'ainda por sincronizar'**
  String get sourcesNeverSynced;

  /// No description provided for @sourcesGamesIndexedCount.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =0{0 jogos indexados} =1{1 jogo indexado} other{{count} jogos indexados}}'**
  String sourcesGamesIndexedCount(int count);

  /// No description provided for @sourcesSourceCount.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =0{0 fontes} =1{1 fonte} other{{count} fontes}}'**
  String sourcesSourceCount(int count);

  /// No description provided for @sourcesSourceLabel.
  ///
  /// In pt, this message translates to:
  /// **'Fonte {index}'**
  String sourcesSourceLabel(int index);

  /// No description provided for @sourcesAddSourceTooltip.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar fonte'**
  String get sourcesAddSourceTooltip;

  /// No description provided for @sourcesRemoveSourceTooltip.
  ///
  /// In pt, this message translates to:
  /// **'Remover fonte'**
  String get sourcesRemoveSourceTooltip;

  /// No description provided for @sourcesNoSourcesEmptyState.
  ///
  /// In pt, this message translates to:
  /// **'Sem fontes. Usa o ícone de link para adicionar uma.'**
  String get sourcesNoSourcesEmptyState;

  /// No description provided for @sourcesEmptyStateBody.
  ///
  /// In pt, this message translates to:
  /// **'Adiciona um fabricante e uma fonte (HTTP ou magnet) para começar a indexar jogos.'**
  String get sourcesEmptyStateBody;

  /// No description provided for @sourcesAddManufacturerButton.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar fabricante'**
  String get sourcesAddManufacturerButton;

  /// No description provided for @sourcesSyncingBanner.
  ///
  /// In pt, this message translates to:
  /// **'A sincronizar catálogo'**
  String get sourcesSyncingBanner;

  /// No description provided for @sourcesAddManufacturerError.
  ///
  /// In pt, this message translates to:
  /// **'Falha ao adicionar fabricante: {error}'**
  String sourcesAddManufacturerError(String error);

  /// No description provided for @sourcesAddConsoleError.
  ///
  /// In pt, this message translates to:
  /// **'Falha ao adicionar consola: {error}'**
  String sourcesAddConsoleError(String error);

  /// No description provided for @sourcesAddSourceError.
  ///
  /// In pt, this message translates to:
  /// **'Falha ao adicionar fonte: {error}'**
  String sourcesAddSourceError(String error);

  /// No description provided for @sourcesRemoveSourceError.
  ///
  /// In pt, this message translates to:
  /// **'Falha ao remover fonte: {error}'**
  String sourcesRemoveSourceError(String error);

  /// No description provided for @addManufacturerDialogTitle.
  ///
  /// In pt, this message translates to:
  /// **'Novo fabricante'**
  String get addManufacturerDialogTitle;

  /// No description provided for @addManufacturerDialogIdLabel.
  ///
  /// In pt, this message translates to:
  /// **'ID (ex: nintendo)'**
  String get addManufacturerDialogIdLabel;

  /// No description provided for @addManufacturerDialogNameLabel.
  ///
  /// In pt, this message translates to:
  /// **'Nome (ex: Nintendo)'**
  String get addManufacturerDialogNameLabel;

  /// No description provided for @addConsoleDialogTitle.
  ///
  /// In pt, this message translates to:
  /// **'Nova consola'**
  String get addConsoleDialogTitle;

  /// No description provided for @addConsoleDialogIdLabel.
  ///
  /// In pt, this message translates to:
  /// **'ID (ex: gameboy_advance)'**
  String get addConsoleDialogIdLabel;

  /// No description provided for @addConsoleDialogNameLabel.
  ///
  /// In pt, this message translates to:
  /// **'Nome (ex: Game Boy Advance)'**
  String get addConsoleDialogNameLabel;

  /// No description provided for @addUrlDialogTitle.
  ///
  /// In pt, this message translates to:
  /// **'Nova fonte'**
  String get addUrlDialogTitle;

  /// No description provided for @addUrlDialogUrlLabel.
  ///
  /// In pt, this message translates to:
  /// **'URL (http://…) ou magnet:?…'**
  String get addUrlDialogUrlLabel;

  /// No description provided for @addUrlDialogContentTypeLabel.
  ///
  /// In pt, this message translates to:
  /// **'Tipo de conteúdo'**
  String get addUrlDialogContentTypeLabel;

  /// No description provided for @addUrlDialogApplyTo.
  ///
  /// In pt, this message translates to:
  /// **'Aplicar a ({count} selecionada{count, plural, =0{s} =1{} other{s}}):'**
  String addUrlDialogApplyTo(int count);

  /// No description provided for @addUrlDialogSubmitButton.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar e sincronizar'**
  String get addUrlDialogSubmitButton;

  /// No description provided for @settingsEyebrow.
  ///
  /// In pt, this message translates to:
  /// **'SISTEMA'**
  String get settingsEyebrow;

  /// No description provided for @settingsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Definições'**
  String get settingsTitle;

  /// No description provided for @settingsStorageSection.
  ///
  /// In pt, this message translates to:
  /// **'ARMAZENAMENTO'**
  String get settingsStorageSection;

  /// No description provided for @settingsDownloadDirTitle.
  ///
  /// In pt, this message translates to:
  /// **'Pasta de download (SAF)'**
  String get settingsDownloadDirTitle;

  /// No description provided for @settingsNotSet.
  ///
  /// In pt, this message translates to:
  /// **'Não definida'**
  String get settingsNotSet;

  /// No description provided for @settingsSeparateByConsoleTitle.
  ///
  /// In pt, this message translates to:
  /// **'Separar por consola'**
  String get settingsSeparateByConsoleTitle;

  /// No description provided for @settingsSeparateByConsoleSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Cria /Nintendo Game Boy Advance/…'**
  String get settingsSeparateByConsoleSubtitle;

  /// No description provided for @settingsLanguageSection.
  ///
  /// In pt, this message translates to:
  /// **'IDIOMA'**
  String get settingsLanguageSection;

  /// No description provided for @settingsLanguageTitle.
  ///
  /// In pt, this message translates to:
  /// **'Idioma'**
  String get settingsLanguageTitle;

  /// No description provided for @settingsConsoleFoldersSection.
  ///
  /// In pt, this message translates to:
  /// **'PASTAS POR CONSOLA'**
  String get settingsConsoleFoldersSection;

  /// No description provided for @settingsNoConsolesConfigured.
  ///
  /// In pt, this message translates to:
  /// **'Sem consolas configuradas ainda.'**
  String get settingsNoConsolesConfigured;

  /// No description provided for @settingsNetworkSection.
  ///
  /// In pt, this message translates to:
  /// **'REDE'**
  String get settingsNetworkSection;

  /// No description provided for @settingsSpeedLimitTitle.
  ///
  /// In pt, this message translates to:
  /// **'Limite de velocidade'**
  String get settingsSpeedLimitTitle;

  /// No description provided for @settingsUnlimited.
  ///
  /// In pt, this message translates to:
  /// **'Ilimitado'**
  String get settingsUnlimited;

  /// No description provided for @settingsSpeedMbs.
  ///
  /// In pt, this message translates to:
  /// **'{value} MB/s'**
  String settingsSpeedMbs(String value);

  /// No description provided for @settingsSpeedMinLabel.
  ///
  /// In pt, this message translates to:
  /// **'0 · ilimitado'**
  String get settingsSpeedMinLabel;

  /// No description provided for @settingsConcurrentDownloadsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Downloads simultâneos'**
  String get settingsConcurrentDownloadsTitle;

  /// No description provided for @settingsConcurrentMaxLabel.
  ///
  /// In pt, this message translates to:
  /// **'6 máx.'**
  String get settingsConcurrentMaxLabel;

  /// No description provided for @settingsArchivesSection.
  ///
  /// In pt, this message translates to:
  /// **'ARQUIVOS'**
  String get settingsArchivesSection;

  /// No description provided for @settingsAutoUnzipTitle.
  ///
  /// In pt, this message translates to:
  /// **'Extração automática'**
  String get settingsAutoUnzipTitle;

  /// No description provided for @settingsAutoUnzipSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'.zip .7z .rar .tar .gz .xz · apaga o comprimido'**
  String get settingsAutoUnzipSubtitle;

  /// No description provided for @settingsUsesMainFolder.
  ///
  /// In pt, this message translates to:
  /// **'Usa a pasta principal'**
  String get settingsUsesMainFolder;

  /// No description provided for @downloadsEyebrow.
  ///
  /// In pt, this message translates to:
  /// **'FILA'**
  String get downloadsEyebrow;

  /// No description provided for @downloadsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Downloads'**
  String get downloadsTitle;

  /// No description provided for @downloadsActiveLabel.
  ///
  /// In pt, this message translates to:
  /// **'Ativos'**
  String get downloadsActiveLabel;

  /// No description provided for @downloadsSpeedLabel.
  ///
  /// In pt, this message translates to:
  /// **'MB/s total'**
  String get downloadsSpeedLabel;

  /// No description provided for @downloadsQueuedLabel.
  ///
  /// In pt, this message translates to:
  /// **'Na fila'**
  String get downloadsQueuedLabel;

  /// No description provided for @downloadsEmptyState.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum download em curso'**
  String get downloadsEmptyState;

  /// No description provided for @downloadsStatusDownloading.
  ///
  /// In pt, this message translates to:
  /// **'{percent}% · {speed} MB/s'**
  String downloadsStatusDownloading(String percent, String speed);

  /// No description provided for @downloadsStatusCopying.
  ///
  /// In pt, this message translates to:
  /// **'A copiar p/ SD Card (SAF)'**
  String get downloadsStatusCopying;

  /// No description provided for @downloadsStatusUnzipping.
  ///
  /// In pt, this message translates to:
  /// **'A descompactar arquivo'**
  String get downloadsStatusUnzipping;

  /// No description provided for @downloadsStatusCompleted.
  ///
  /// In pt, this message translates to:
  /// **'Concluído'**
  String get downloadsStatusCompleted;

  /// No description provided for @downloadsStatusFailed.
  ///
  /// In pt, this message translates to:
  /// **'Falhou · toca em tentar de novo'**
  String get downloadsStatusFailed;

  /// No description provided for @downloadsChipDownloading.
  ///
  /// In pt, this message translates to:
  /// **'A descarregar'**
  String get downloadsChipDownloading;

  /// No description provided for @downloadsChipCopying.
  ///
  /// In pt, this message translates to:
  /// **'A copiar'**
  String get downloadsChipCopying;

  /// No description provided for @downloadsChipUnzipping.
  ///
  /// In pt, this message translates to:
  /// **'A extrair'**
  String get downloadsChipUnzipping;

  /// No description provided for @downloadsChipFailed.
  ///
  /// In pt, this message translates to:
  /// **'Falhou'**
  String get downloadsChipFailed;

  /// No description provided for @downloadsStopTooltip.
  ///
  /// In pt, this message translates to:
  /// **'Parar'**
  String get downloadsStopTooltip;

  /// No description provided for @downloadsRetryTooltip.
  ///
  /// In pt, this message translates to:
  /// **'Tentar novamente'**
  String get downloadsRetryTooltip;

  /// No description provided for @downloadsRemoveTooltip.
  ///
  /// In pt, this message translates to:
  /// **'Remover'**
  String get downloadsRemoveTooltip;

  /// No description provided for @downloadsRemoveFromListTooltip.
  ///
  /// In pt, this message translates to:
  /// **'Remover da lista'**
  String get downloadsRemoveFromListTooltip;

  /// No description provided for @libraryDefaultTitle.
  ///
  /// In pt, this message translates to:
  /// **'Biblioteca'**
  String get libraryDefaultTitle;

  /// No description provided for @libraryHintSearch.
  ///
  /// In pt, this message translates to:
  /// **'Pesquisar roms…'**
  String get libraryHintSearch;

  /// No description provided for @libraryFiltersChip.
  ///
  /// In pt, this message translates to:
  /// **'Filtros'**
  String get libraryFiltersChip;

  /// No description provided for @libraryFormatChip.
  ///
  /// In pt, this message translates to:
  /// **'Formato'**
  String get libraryFormatChip;

  /// No description provided for @libraryColRegion.
  ///
  /// In pt, this message translates to:
  /// **'REGIÃO'**
  String get libraryColRegion;

  /// No description provided for @libraryColLanguage.
  ///
  /// In pt, this message translates to:
  /// **'IDIOMA'**
  String get libraryColLanguage;

  /// No description provided for @libraryColVideo.
  ///
  /// In pt, this message translates to:
  /// **'VÍDEO'**
  String get libraryColVideo;

  /// No description provided for @libraryColType.
  ///
  /// In pt, this message translates to:
  /// **'TIPO'**
  String get libraryColType;

  /// No description provided for @libraryColExtension.
  ///
  /// In pt, this message translates to:
  /// **'EXTENSÃO'**
  String get libraryColExtension;

  /// No description provided for @libraryNoResults.
  ///
  /// In pt, this message translates to:
  /// **'Sem resultados.\nAdiciona uma fonte no separador Fontes e faz rescan.'**
  String get libraryNoResults;

  /// No description provided for @libraryMetaLabel.
  ///
  /// In pt, this message translates to:
  /// **'{count} ficheiros · {size}'**
  String libraryMetaLabel(String count, String size);

  /// No description provided for @libraryDownloadStartedSnackbar.
  ///
  /// In pt, this message translates to:
  /// **'Download de \"{name}\" iniciado.'**
  String libraryDownloadStartedSnackbar(String name);

  /// No description provided for @platformSelectSeedError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao carregar consolas: {error}'**
  String platformSelectSeedError(String error);

  /// No description provided for @platformSelectEyebrow.
  ///
  /// In pt, this message translates to:
  /// **'CATÁLOGO'**
  String get platformSelectEyebrow;

  /// No description provided for @platformSelectTitle.
  ///
  /// In pt, this message translates to:
  /// **'Plataformas'**
  String get platformSelectTitle;

  /// No description provided for @platformSelectSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'{consoleCount} consolas ativas · {fileCount} ficheiros indexados'**
  String platformSelectSubtitle(int consoleCount, int fileCount);

  /// No description provided for @platformSelectSearchHint.
  ///
  /// In pt, this message translates to:
  /// **'Pesquisar consolas…'**
  String get platformSelectSearchHint;

  /// No description provided for @platformSelectActiveConsolesSection.
  ///
  /// In pt, this message translates to:
  /// **'CONSOLAS ATIVAS'**
  String get platformSelectActiveConsolesSection;

  /// No description provided for @platformSelectEmptyState.
  ///
  /// In pt, this message translates to:
  /// **'Sem plataformas.\nVai a Fontes para adicionar fontes.'**
  String get platformSelectEmptyState;

  /// No description provided for @platformSelectGlobalLibraryTitle.
  ///
  /// In pt, this message translates to:
  /// **'Biblioteca global'**
  String get platformSelectGlobalLibraryTitle;

  /// No description provided for @platformSelectGlobalLibrarySubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Todos os jogos de todas as consolas'**
  String get platformSelectGlobalLibrarySubtitle;

  /// No description provided for @platformSelectConsoleSummary.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =0{0 jogos} =1{1 jogo} other{{count} jogos}} · {size}'**
  String platformSelectConsoleSummary(int count, String size);

  /// No description provided for @sourceInstallResolveError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível instalar a fonte: {error}'**
  String sourceInstallResolveError(String error);

  /// No description provided for @sourceInstallUnsupportedConsole.
  ///
  /// In pt, this message translates to:
  /// **'Esta consola não é suportada nesta versão da app.'**
  String get sourceInstallUnsupportedConsole;

  /// No description provided for @sourceInstallAlreadyInstalled.
  ///
  /// In pt, this message translates to:
  /// **'Esta fonte já está instalada em \"{name}\".'**
  String sourceInstallAlreadyInstalled(String name);

  /// No description provided for @sourceInstallConfirmTitle.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar fonte'**
  String get sourceInstallConfirmTitle;

  /// No description provided for @sourceInstallConfirmBody.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar uma nova fonte a \"{name}\"?'**
  String sourceInstallConfirmBody(String name);

  /// No description provided for @sourceInstallSuccess.
  ///
  /// In pt, this message translates to:
  /// **'Fonte adicionada a \"{name}\". Vai a Fontes para sincronizar.'**
  String sourceInstallSuccess(String name);

  /// No description provided for @sourceInstallAddError.
  ///
  /// In pt, this message translates to:
  /// **'Falha ao adicionar a fonte: {error}'**
  String sourceInstallAddError(String error);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en', 'es', 'fr', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
