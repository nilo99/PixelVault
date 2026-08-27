import '../models/url_entry.dart';

/// Torrent equivalent of [HttpDirectoryScraper] — fetches torrent metadata,
/// enumerates its files (optionally filtered to [UrlEntry.folders]) and
/// inserts them into [consoleId]'s catalog, tagged via the same
/// `FileParsing.extractNameAndTags` pipeline the HTTP scraper uses.
///
/// Implemented by `NativeTorrentScraper` (lib/core/scraping/native_torrent_scraper.dart),
/// which talks to the `pixelvault_torrent` platform plugin — libtorrent has
/// no mature pure-Dart binding, so metadata fetch/file enumeration happens
/// natively.
abstract class TorrentScraper {
  /// Returns (filesInserted, tagsInserted).
  Future<(int, int)> scrapeAndInsert({
    required UrlEntry urlEntry,
    required String consoleId,
    required String consoleName,
  });
}
