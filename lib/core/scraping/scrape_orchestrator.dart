import '../db/daos/catalog_repository.dart';
import '../db/daos/downloadable_file_repository.dart';
import '../db/database.dart';
import '../models/console_x.dart';
import '../models/url_entry.dart';
import '../state/rescan_state.dart';
import '../utils/error_sanitizer.dart';
import 'http_directory_scraper.dart';
import 'torrent_scraper.dart';

/// Port of the scrape-triggering logic in Milou's `SourcesViewModel` +
/// `DatabaseScrapingService.scrapeManufacturer`: routes each console's
/// [UrlEntry]s to the HTTP or torrent scraper by URL shape, aggregates
/// counts, and reports progress/errors through [RescanStateHolder].
class ScrapeOrchestrator {
  ScrapeOrchestrator({
    required this.catalog,
    required this.files,
    required this.httpScraper,
    required this.rescan,
    this.torrentScraper,
  });

  final CatalogRepository catalog;
  final DownloadableFileRepository files;
  final HttpDirectoryScraper httpScraper;
  final RescanStateHolder rescan;
  final TorrentScraper? torrentScraper;

  /// Scrapes every current source and returns the console's url list with
  /// each entry's [UrlEntry.lastSyncedAt] updated to reflect this attempt —
  /// `DateTime.now()` on success, cleared back to `null` on failure — so the
  /// Fontes screen can tell "has files from an old source" apart from "every
  /// current source has actually been scraped".
  Future<List<UrlEntry>> _scrapeConsole(Console console) async {
    final updatedUrls = <UrlEntry>[];
    for (final urlEntry in console.urls) {
      try {
        if (urlEntry.isTorrent) {
          final scraper = torrentScraper;
          if (scraper == null) {
            rescan.setErrorNotice(
              RescanNotice(RescanNoticeKind.torrentUnsupported, console: console.name),
            );
            updatedUrls.add(urlEntry.copyWith(clearLastSyncedAt: true));
            continue;
          }
          await scraper.scrapeAndInsert(
            urlEntry: urlEntry,
            consoleId: console.id,
            consoleName: console.name,
          );
        } else {
          await httpScraper.scrapeAndInsert(
            baseUrl: urlEntry.url,
            consoleId: console.id,
            contentType: urlEntry.contentType,
          );
        }
        updatedUrls.add(urlEntry.copyWith(lastSyncedAt: DateTime.now()));
      } catch (e) {
        rescan.setErrorNotice(RescanNotice(
          RescanNoticeKind.scrapeFailed,
          console: console.name,
          reason: classifyError(e),
        ));
        updatedUrls.add(urlEntry.copyWith(clearLastSyncedAt: true));
      }
    }
    return updatedUrls;
  }

  /// Rescans every console, one at a time: deletes that console's existing
  /// files then rescrapes it immediately, rather than wiping the whole
  /// catalog up front and repopulating it over the (possibly long, networked)
  /// scrape loop. That old approach left the entire library empty for the
  /// full duration of the rescan — a crash or the app being killed in the
  /// background midway would leave the catalog empty/partial. Bounding the
  /// delete to one console at a time means an interruption can leave at most
  /// one console's files gone, not the whole catalog.
  Future<void> rescanAll() async {
    if (rescan.isRescanning) {
      rescan.setErrorNotice(const RescanNotice(RescanNoticeKind.alreadyRunning));
      return;
    }
    rescan.setRescanning(true);
    try {
      final consoles = await catalog.watchAllConsoles().first;
      var processed = 0;
      for (final console in consoles) {
        processed++;
        rescan.setProgressNotice(RescanNotice(
          RescanNoticeKind.processing,
          console: console.name,
          current: processed,
          total: consoles.length,
        ));
        await files.deleteFilesByConsoleId(console.id);
        final updatedUrls = await _scrapeConsole(console);
        await catalog.updateConsoleUrls(console.id, updatedUrls);
      }
    } finally {
      rescan.setRescanning(false);
      rescan.clearProgressNotice();
      rescan.clearTorrentFetchProgress();
    }
  }

  Future<void> refreshConsole(Console console) async {
    if (rescan.isRescanning) {
      rescan.setErrorNotice(const RescanNotice(RescanNoticeKind.alreadyRunning));
      return;
    }
    rescan.setRescanning(true);
    try {
      rescan.setProgressNotice(RescanNotice(RescanNoticeKind.refreshing, console: console.name));
      await files.deleteFilesByConsoleId(console.id);
      final updatedUrls = await _scrapeConsole(console);
      await catalog.updateConsoleUrls(console.id, updatedUrls);
    } finally {
      rescan.setRescanning(false);
      rescan.clearProgressNotice();
      rescan.clearTorrentFetchProgress();
    }
  }
}
