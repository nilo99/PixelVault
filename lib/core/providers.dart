import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show StreamProvider;
import 'package:pixelvault_torrent/pixelvault_torrent.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'db/daos/catalog_repository.dart';
import 'db/daos/downloadable_file_repository.dart';
import 'db/database.dart';
import 'db/seed/consoles_seed_loader.dart';
import 'deeplink/source_install_client.dart';
import 'download/download_manager.dart';
import 'download/download_progress_tracker.dart';
import 'scraping/http_directory_scraper.dart';
import 'scraping/native_torrent_scraper.dart';
import 'scraping/scrape_orchestrator.dart';
import 'scraping/torrent_scraper.dart';
import 'settings/settings_repository.dart';
import 'state/rescan_state.dart';
import 'storage/saf_storage_helper.dart';

part 'providers.g.dart';

@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
}

@Riverpod(keepAlive: true)
CatalogRepository catalogRepository(Ref ref) {
  return CatalogRepository(ref.watch(appDatabaseProvider));
}

@Riverpod(keepAlive: true)
DownloadableFileRepository downloadableFileRepository(Ref ref) {
  return DownloadableFileRepository(ref.watch(appDatabaseProvider));
}

@Riverpod(keepAlive: true)
ConsolesSeedLoader consolesSeedLoader(Ref ref) {
  return ConsolesSeedLoader(ref.watch(catalogRepositoryProvider));
}

@Riverpod(keepAlive: true)
Dio scrapingDio(Ref ref) => Dio();

/// Wraps the native plugin's singleton in its own provider (rather than
/// referencing `PixelvaultTorrent.instance` directly inside every consumer)
/// so tests can override it with a mock instead of touching a real
/// MethodChannel/EventChannel.
@Riverpod(keepAlive: true)
PixelvaultTorrent pixelvaultTorrent(Ref ref) => PixelvaultTorrent.instance;

@Riverpod(keepAlive: true)
HttpDirectoryScraper httpDirectoryScraper(Ref ref) {
  return HttpDirectoryScraper(
    ref.watch(scrapingDioProvider),
    ref.watch(downloadableFileRepositoryProvider),
  );
}

@Riverpod(keepAlive: true)
TorrentScraper torrentScraper(Ref ref) {
  return NativeTorrentScraper(
    ref.watch(downloadableFileRepositoryProvider),
    ref.watch(pixelvaultTorrentProvider),
  );
}

@Riverpod(keepAlive: true)
ScrapeOrchestrator scrapeOrchestrator(Ref ref) {
  return ScrapeOrchestrator(
    catalog: ref.watch(catalogRepositoryProvider),
    files: ref.watch(downloadableFileRepositoryProvider),
    httpScraper: ref.watch(httpDirectoryScraperProvider),
    rescan: ref.watch(rescanStateHolderProvider.notifier),
    torrentScraper: ref.watch(torrentScraperProvider),
  );
}

/// Plain (non-codegen) `StreamProvider`s — riverpod_generator's type-to-code
/// serializer chokes on `Manufacturer`/`Console` (Drift row classes declared
/// in a generated `part` file: database.g.dart), so these two are declared
/// by hand instead of with `@riverpod`.
final allManufacturersProvider = StreamProvider<List<Manufacturer>>((ref) {
  return ref.watch(catalogRepositoryProvider).watchManufacturers();
});

final allConsolesProvider = StreamProvider<List<Console>>((ref) {
  return ref.watch(catalogRepositoryProvider).watchAllConsoles();
});

/// Indexed-file count per console — lets the Sources screen distinguish
/// "has a source configured" from "has actually been scanned", and updates
/// live as a rescan inserts rows.
final consoleFileCountsProvider = StreamProvider<Map<String, int>>((ref) {
  return ref.watch(downloadableFileRepositoryProvider).watchFileCountsByConsole();
});

/// Live total indexed file size (bytes) per console, for the Plataformas
/// list's "{count} jogos · {size}" meta line.
final consoleFileSizesProvider = StreamProvider<Map<String, int>>((ref) {
  return ref.watch(downloadableFileRepositoryProvider).watchFileSizesByConsole();
});

/// Seeds the catalog from `assets/consoles.json` on first launch only
/// (mirrors Milou's `loadDefaultSources`, which no-ops once the DB has data).
@Riverpod(keepAlive: true)
Future<void> ensureCatalogSeeded(Ref ref) async {
  final existing = await ref.watch(catalogRepositoryProvider).watchManufacturers().first;
  if (existing.isNotEmpty) return;
  await ref.watch(consolesSeedLoaderProvider).loadDefaultSources();
}

@Riverpod(keepAlive: true)
SafStorageHelper safStorageHelper(Ref ref) => SafStorageHelper();

@Riverpod(keepAlive: true)
SourceInstallClient sourceInstallClient(Ref ref) {
  return SourceInstallClient(baseUrl: SourceInstallClient.defaultBaseUrl);
}

@Riverpod(keepAlive: true)
DownloadManager downloadManager(Ref ref) {
  final manager = DownloadManager(
    tracker: ref.watch(downloadProgressTrackerProvider.notifier),
    settings: ref.watch(settingsProvider.notifier),
    catalog: ref.watch(catalogRepositoryProvider),
    torrentPlugin: ref.watch(pixelvaultTorrentProvider),
    safStorage: ref.watch(safStorageHelperProvider),
  );
  ref.onDispose(manager.dispose);
  return manager;
}
