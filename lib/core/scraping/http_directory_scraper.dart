import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;

import '../db/daos/downloadable_file_repository.dart';
import '../db/database.dart';
import '../models/content_type.dart';
import 'file_parsing.dart';
import 'file_size_utils.dart';
import 'scraping_constants.dart';

/// Port of Milou's `DatabaseScrapingService` HTTP branch: fetches a single
/// Apache/Nginx-style directory-listing page, parses its `<table>` rows and
/// inserts every file entry (skipping parent/current-dir links and
/// subdirectory rows — the original app does not recurse into subfolders,
/// only the top-level listing at the configured URL is scraped).
class HttpDirectoryScraper {
  HttpDirectoryScraper(this._dio, this._files);

  final Dio _dio;
  final DownloadableFileRepository _files;

  Future<Document> _fetchDocument(String url) async {
    Object? lastError;
    for (var attempt = 0; attempt < ScrapingConstants.maxRetries; attempt++) {
      if (attempt > 0) {
        await Future.delayed(Duration(milliseconds: ScrapingConstants.retryDelayMs * attempt));
      }
      try {
        final response = await _dio.get<String>(
          url,
          options: Options(
            headers: {'User-Agent': ScrapingConstants.userAgent},
            followRedirects: true,
            responseType: ResponseType.plain,
            sendTimeout: const Duration(milliseconds: ScrapingConstants.connectionTimeoutMs),
            receiveTimeout: const Duration(milliseconds: ScrapingConstants.connectionTimeoutMs),
          ),
        );
        return html_parser.parse(response.data ?? '');
      } catch (e) {
        lastError = e;
        if (attempt < ScrapingConstants.maxRetries - 1) {
          await Future.delayed(const Duration(milliseconds: ScrapingConstants.retryDelayMs));
        }
      }
    }
    throw StateError('All retry attempts failed: $lastError');
  }

  /// Scrapes [baseUrl] and inserts every file row into [consoleId]'s catalog.
  /// Returns (filesInserted, tagsInserted).
  Future<(int, int)> scrapeAndInsert({
    required String baseUrl,
    required String consoleId,
    ContentType contentType = ContentType.game,
  }) async {
    await Future.delayed(const Duration(milliseconds: ScrapingConstants.requestDelayMs));
    final doc = await _fetchDocument(baseUrl);
    final (companions, tagsPerFile) = parseListing(
      doc: doc,
      baseUrl: baseUrl,
      consoleId: consoleId,
      contentType: contentType,
    );

    if (companions.isNotEmpty) {
      await _files.insertFilesWithTags(companions, tagsPerFile);
    }

    final tagCount = tagsPerFile.fold(0, (sum, tags) => sum + tags.length);
    return (companions.length, tagCount);
  }

  /// Pure parsing step (network-free, unit-testable): turns a fetched
  /// directory-listing [Document] into rows ready for insertion.
  static (List<DownloadableFilesCompanion>, List<List<String>>) parseListing({
    required Document doc,
    required String baseUrl,
    required String consoleId,
    ContentType contentType = ContentType.game,
  }) {
    final table = doc.querySelector(ScrapingConstants.tableSelector);
    if (table == null) {
      throw StateError(
        'Could not find file table. The source might be down or its structure has changed.',
      );
    }

    final companions = <DownloadableFilesCompanion>[];
    final tagsPerFile = <List<String>>[];

    for (final row in table.querySelectorAll('tr')) {
      final linkCell = row.querySelector('td.link a') ?? row.querySelector('a');
      if (linkCell == null) continue;

      final href = linkCell.attributes['href'] ?? '';
      final linkText = linkCell.text.trim();

      if (href == ScrapingConstants.parentDirectory ||
          href == ScrapingConstants.currentDirectory ||
          linkText == 'Parent directory/' ||
          linkText == './' ||
          linkText == '../') {
        continue;
      }
      if (href.endsWith('/')) continue; // subdirectory row — not recursed into

      final title = linkCell.attributes['title'] ?? '';
      final displayName = title.isNotEmpty ? title : linkText;
      final (cleanName, tags) = FileParsing.extractNameAndTags(displayName);

      final cells = row.querySelectorAll('td');
      final sizeCell = row.querySelector('td.size') ?? (cells.length > 1 ? cells[1] : null);
      final sizeText = sizeCell?.text.trim();
      final fileSizeText = (sizeText == null || sizeText == ScrapingConstants.unknownFileSize)
          ? ScrapingConstants.defaultFileSize
          : sizeText;

      // Strip query string/fragment before computing the extension — a
      // listing link like "rom.zip?dl=1" would otherwise yield ".zip?dl=1".
      final hrefPath = href.split('?').first.split('#').first;
      final fileExtension = hrefPath.contains('.') ? '.${hrefPath.split('.').last}' : '';

      companions.add(DownloadableFilesCompanion.insert(
        name: cleanName,
        fileName: href,
        consoleId: consoleId,
        downloadUrl: FileParsing.buildDownloadUrl(baseUrl, href),
        fileSize: Value(FileSizeUtils.parseFileSize(fileSizeText)),
        fileExtension: Value(fileExtension),
      ));

      final rowTags = [...tags, FileParsing.normalizeTag(contentType.toJson())];
      tagsPerFile.add(rowTags);
    }

    return (companions, tagsPerFile);
  }
}
