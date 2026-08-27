// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(appDatabase)
final appDatabaseProvider = AppDatabaseProvider._();

final class AppDatabaseProvider
    extends $FunctionalProvider<AppDatabase, AppDatabase, AppDatabase>
    with $Provider<AppDatabase> {
  AppDatabaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appDatabaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appDatabaseHash();

  @$internal
  @override
  $ProviderElement<AppDatabase> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppDatabase create(Ref ref) {
    return appDatabase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppDatabase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppDatabase>(value),
    );
  }
}

String _$appDatabaseHash() => r'59cce38d45eeaba199eddd097d8e149d66f9f3e1';

@ProviderFor(catalogRepository)
final catalogRepositoryProvider = CatalogRepositoryProvider._();

final class CatalogRepositoryProvider
    extends
        $FunctionalProvider<
          CatalogRepository,
          CatalogRepository,
          CatalogRepository
        >
    with $Provider<CatalogRepository> {
  CatalogRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'catalogRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$catalogRepositoryHash();

  @$internal
  @override
  $ProviderElement<CatalogRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CatalogRepository create(Ref ref) {
    return catalogRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CatalogRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CatalogRepository>(value),
    );
  }
}

String _$catalogRepositoryHash() => r'295f28fefb9955f48117313a44d365ebb55e5443';

@ProviderFor(downloadableFileRepository)
final downloadableFileRepositoryProvider =
    DownloadableFileRepositoryProvider._();

final class DownloadableFileRepositoryProvider
    extends
        $FunctionalProvider<
          DownloadableFileRepository,
          DownloadableFileRepository,
          DownloadableFileRepository
        >
    with $Provider<DownloadableFileRepository> {
  DownloadableFileRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'downloadableFileRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$downloadableFileRepositoryHash();

  @$internal
  @override
  $ProviderElement<DownloadableFileRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DownloadableFileRepository create(Ref ref) {
    return downloadableFileRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DownloadableFileRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DownloadableFileRepository>(value),
    );
  }
}

String _$downloadableFileRepositoryHash() =>
    r'1a508eb68d9af10abd42dc8f78d30c3deb379477';

@ProviderFor(consolesSeedLoader)
final consolesSeedLoaderProvider = ConsolesSeedLoaderProvider._();

final class ConsolesSeedLoaderProvider
    extends
        $FunctionalProvider<
          ConsolesSeedLoader,
          ConsolesSeedLoader,
          ConsolesSeedLoader
        >
    with $Provider<ConsolesSeedLoader> {
  ConsolesSeedLoaderProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'consolesSeedLoaderProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$consolesSeedLoaderHash();

  @$internal
  @override
  $ProviderElement<ConsolesSeedLoader> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ConsolesSeedLoader create(Ref ref) {
    return consolesSeedLoader(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ConsolesSeedLoader value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ConsolesSeedLoader>(value),
    );
  }
}

String _$consolesSeedLoaderHash() =>
    r'9e6bda928162697cb45ff4572cc9550cba599332';

@ProviderFor(scrapingDio)
final scrapingDioProvider = ScrapingDioProvider._();

final class ScrapingDioProvider extends $FunctionalProvider<Dio, Dio, Dio>
    with $Provider<Dio> {
  ScrapingDioProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'scrapingDioProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$scrapingDioHash();

  @$internal
  @override
  $ProviderElement<Dio> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Dio create(Ref ref) {
    return scrapingDio(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Dio value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Dio>(value),
    );
  }
}

String _$scrapingDioHash() => r'6d689c849b22ef498d4f148c777589f805ef11f6';

/// Wraps the native plugin's singleton in its own provider (rather than
/// referencing `PixelvaultTorrent.instance` directly inside every consumer)
/// so tests can override it with a mock instead of touching a real
/// MethodChannel/EventChannel.

@ProviderFor(pixelvaultTorrent)
final pixelvaultTorrentProvider = PixelvaultTorrentProvider._();

/// Wraps the native plugin's singleton in its own provider (rather than
/// referencing `PixelvaultTorrent.instance` directly inside every consumer)
/// so tests can override it with a mock instead of touching a real
/// MethodChannel/EventChannel.

final class PixelvaultTorrentProvider
    extends
        $FunctionalProvider<
          PixelvaultTorrent,
          PixelvaultTorrent,
          PixelvaultTorrent
        >
    with $Provider<PixelvaultTorrent> {
  /// Wraps the native plugin's singleton in its own provider (rather than
  /// referencing `PixelvaultTorrent.instance` directly inside every consumer)
  /// so tests can override it with a mock instead of touching a real
  /// MethodChannel/EventChannel.
  PixelvaultTorrentProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pixelvaultTorrentProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pixelvaultTorrentHash();

  @$internal
  @override
  $ProviderElement<PixelvaultTorrent> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PixelvaultTorrent create(Ref ref) {
    return pixelvaultTorrent(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PixelvaultTorrent value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PixelvaultTorrent>(value),
    );
  }
}

String _$pixelvaultTorrentHash() => r'e5be60df0b7dfdd170186b33fbb267d8f6df1051';

@ProviderFor(httpDirectoryScraper)
final httpDirectoryScraperProvider = HttpDirectoryScraperProvider._();

final class HttpDirectoryScraperProvider
    extends
        $FunctionalProvider<
          HttpDirectoryScraper,
          HttpDirectoryScraper,
          HttpDirectoryScraper
        >
    with $Provider<HttpDirectoryScraper> {
  HttpDirectoryScraperProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'httpDirectoryScraperProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$httpDirectoryScraperHash();

  @$internal
  @override
  $ProviderElement<HttpDirectoryScraper> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  HttpDirectoryScraper create(Ref ref) {
    return httpDirectoryScraper(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HttpDirectoryScraper value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HttpDirectoryScraper>(value),
    );
  }
}

String _$httpDirectoryScraperHash() =>
    r'4999258d2e3eaada4b7025830162814469ec059b';

@ProviderFor(torrentScraper)
final torrentScraperProvider = TorrentScraperProvider._();

final class TorrentScraperProvider
    extends $FunctionalProvider<TorrentScraper, TorrentScraper, TorrentScraper>
    with $Provider<TorrentScraper> {
  TorrentScraperProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'torrentScraperProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$torrentScraperHash();

  @$internal
  @override
  $ProviderElement<TorrentScraper> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  TorrentScraper create(Ref ref) {
    return torrentScraper(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TorrentScraper value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TorrentScraper>(value),
    );
  }
}

String _$torrentScraperHash() => r'28b6b64e532e15304f2c178df64a08721dfea1a6';

@ProviderFor(scrapeOrchestrator)
final scrapeOrchestratorProvider = ScrapeOrchestratorProvider._();

final class ScrapeOrchestratorProvider
    extends
        $FunctionalProvider<
          ScrapeOrchestrator,
          ScrapeOrchestrator,
          ScrapeOrchestrator
        >
    with $Provider<ScrapeOrchestrator> {
  ScrapeOrchestratorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'scrapeOrchestratorProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$scrapeOrchestratorHash();

  @$internal
  @override
  $ProviderElement<ScrapeOrchestrator> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ScrapeOrchestrator create(Ref ref) {
    return scrapeOrchestrator(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ScrapeOrchestrator value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ScrapeOrchestrator>(value),
    );
  }
}

String _$scrapeOrchestratorHash() =>
    r'a2ce894f845a2481e8ebe44fac34191b9166895e';

/// Seeds the catalog from `assets/consoles.json` on first launch only
/// (mirrors Milou's `loadDefaultSources`, which no-ops once the DB has data).

@ProviderFor(ensureCatalogSeeded)
final ensureCatalogSeededProvider = EnsureCatalogSeededProvider._();

/// Seeds the catalog from `assets/consoles.json` on first launch only
/// (mirrors Milou's `loadDefaultSources`, which no-ops once the DB has data).

final class EnsureCatalogSeededProvider
    extends $FunctionalProvider<AsyncValue<void>, void, FutureOr<void>>
    with $FutureModifier<void>, $FutureProvider<void> {
  /// Seeds the catalog from `assets/consoles.json` on first launch only
  /// (mirrors Milou's `loadDefaultSources`, which no-ops once the DB has data).
  EnsureCatalogSeededProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ensureCatalogSeededProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ensureCatalogSeededHash();

  @$internal
  @override
  $FutureProviderElement<void> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<void> create(Ref ref) {
    return ensureCatalogSeeded(ref);
  }
}

String _$ensureCatalogSeededHash() =>
    r'5b1cc62da39dbbebc26523ee03dcd4d5473059ba';

@ProviderFor(safStorageHelper)
final safStorageHelperProvider = SafStorageHelperProvider._();

final class SafStorageHelperProvider
    extends
        $FunctionalProvider<
          SafStorageHelper,
          SafStorageHelper,
          SafStorageHelper
        >
    with $Provider<SafStorageHelper> {
  SafStorageHelperProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'safStorageHelperProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$safStorageHelperHash();

  @$internal
  @override
  $ProviderElement<SafStorageHelper> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SafStorageHelper create(Ref ref) {
    return safStorageHelper(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SafStorageHelper value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SafStorageHelper>(value),
    );
  }
}

String _$safStorageHelperHash() => r'196c21d8ff7b8f6bb8b5da323088f3c5d3d704ac';

@ProviderFor(sourceInstallClient)
final sourceInstallClientProvider = SourceInstallClientProvider._();

final class SourceInstallClientProvider
    extends
        $FunctionalProvider<
          SourceInstallClient,
          SourceInstallClient,
          SourceInstallClient
        >
    with $Provider<SourceInstallClient> {
  SourceInstallClientProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sourceInstallClientProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sourceInstallClientHash();

  @$internal
  @override
  $ProviderElement<SourceInstallClient> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SourceInstallClient create(Ref ref) {
    return sourceInstallClient(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SourceInstallClient value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SourceInstallClient>(value),
    );
  }
}

String _$sourceInstallClientHash() =>
    r'2a34f48a233e0be3a4dfbdbc6b20dd3c5f155301';

@ProviderFor(downloadManager)
final downloadManagerProvider = DownloadManagerProvider._();

final class DownloadManagerProvider
    extends
        $FunctionalProvider<DownloadManager, DownloadManager, DownloadManager>
    with $Provider<DownloadManager> {
  DownloadManagerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'downloadManagerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$downloadManagerHash();

  @$internal
  @override
  $ProviderElement<DownloadManager> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DownloadManager create(Ref ref) {
    return downloadManager(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DownloadManager value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DownloadManager>(value),
    );
  }
}

String _$downloadManagerHash() => r'fde3b302ca8b1edc062a828f8693c8e6b15546fe';
