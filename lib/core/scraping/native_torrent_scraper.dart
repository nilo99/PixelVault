import 'package:drift/drift.dart';
import 'package:pixelvault_torrent/pixelvault_torrent.dart';

import '../db/daos/downloadable_file_repository.dart';
import '../db/database.dart';
import '../models/url_entry.dart';
import 'file_parsing.dart';
import 'scraping_constants.dart';
import 'torrent_scraper.dart';

/// [TorrentScraper] backed by the `pixelvault_torrent` native plugin —
/// fetches torrent metadata + enumerates files natively (libtorrent4j has no
/// mature pure-Dart binding), then runs the same [FileParsing.extractNameAndTags]
/// pipeline the HTTP scraper uses so tagging stays identical between source
/// types, exactly like Milou's `TorrentScrapingService` reusing `FileParsingUtils`.
class NativeTorrentScraper implements TorrentScraper {
  NativeTorrentScraper(this._files, this._plugin);

  final DownloadableFileRepository _files;
  final PixelvaultTorrent _plugin;

  @override
  Future<(int, int)> scrapeAndInsert({
    required UrlEntry urlEntry,
    required String consoleId,
    required String consoleName,
  }) async {
    await _plugin.startSession();
    final metadata = await _fetchMetadataWithRetry(urlEntry);

    final companions = <DownloadableFilesCompanion>[];
    final tagsPerFile = <List<String>>[];

    for (final entry in metadata.files) {
      final (cleanName, tags) = FileParsing.extractNameAndTags(entry.fileName);
      final extension = entry.fileName.contains('.') ? '.${entry.fileName.split('.').last}' : '';

      companions.add(DownloadableFilesCompanion.insert(
        name: cleanName,
        fileName: entry.fileName,
        consoleId: consoleId,
        downloadUrl: urlEntry.url,
        fileSize: Value(entry.fileSize),
        fileExtension: Value(extension),
        torrentFileIndex: Value(entry.fileIndex),
        torrentMagnet: Value(urlEntry.url),
      ));

      tagsPerFile.add([...tags, FileParsing.normalizeTag(urlEntry.contentType.toJson())]);
    }

    if (companions.isNotEmpty) {
      await _files.insertFilesWithTags(companions, tagsPerFile);
    }

    final tagCount = tagsPerFile.fold(0, (sum, tags) => sum + tags.length);
    return (companions.length, tagCount);
  }

  /// A single stalled DHT/tracker response shouldn't be a permanent sync
  /// failure — retry like [HttpDirectoryScraper] does, using the same
  /// [ScrapingConstants.maxRetries]/[ScrapingConstants.retryDelayMs] so
  /// torrent and HTTP sources behave consistently. `getOrFetch` only caches a
  /// handle on success (see `TorrentHandleRegistry.getOrFetch`), so a retry
  /// here is always a genuinely fresh attempt, never a replay of a cached
  /// failure.
  Future<TorrentMetadata> _fetchMetadataWithRetry(UrlEntry urlEntry) async {
    Object? lastError;
    for (var attempt = 0; attempt < ScrapingConstants.maxRetries; attempt++) {
      if (attempt > 0) {
        await Future.delayed(Duration(milliseconds: ScrapingConstants.retryDelayMs * attempt));
      }
      try {
        return await _plugin.fetchMetadata(urlEntry.url, folders: urlEntry.folders);
      } catch (e) {
        lastError = e;
      }
    }
    throw lastError!;
  }
}
