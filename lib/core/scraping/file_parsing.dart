import 'tag_constants.dart';
import 'scraping_constants.dart';

/// Port of Milou's `FileParsingUtils` — filename -> (clean name, tags)
/// extraction, URL building/normalization, and magnet-URI tracker trimming.
/// Kept as pure functions so both the HTTP scraper and the torrent scraper
/// (via the native plugin's file list) share identical parsing behaviour.
abstract final class FileParsing {
  static final _tagPattern = RegExp(r'\(([^)]+)\)');
  static final _whitespacePattern = RegExp(r'\s+');
  static final _illegalFolderChars = RegExp(r'[<>:"/|?*]');
  static final _repeatedSpaces = RegExp(r'\s{2,}');

  /// Strips `(...)` groups from [displayName], keeping only the tokens that
  /// look like a real tag (region/language/video-standard/content-type/
  /// version), and returns the cleaned name plus the extracted tags.
  static (String name, List<String> tags) extractNameAndTags(String displayName) {
    final tags = <String>[];
    var cleanName = displayName;

    for (final match in _tagPattern.allMatches(displayName)) {
      final content = match.group(1)!.trim();
      for (final rawValue in content.split(',')) {
        final value = rawValue.trim();
        if (isValidTag(value)) tags.add(normalizeTag(value));
      }
      cleanName = cleanName.replaceFirst(match.group(0)!, '').trim();
    }

    cleanName = cleanName.replaceAll(_whitespacePattern, ' ').trim();
    return (cleanName, tags);
  }

  static bool isValidTag(String tag) {
    final clean = tag.trim().toUpperCase();
    if (clean.length < 2) return false;

    if (TagConstants.videoStandards.contains(clean)) return true;
    if (TagConstants.contentTypes.contains(clean)) return true;
    if (TagConstants.languageCodePattern.hasMatch(clean)) return true;
    if (TagConstants.versionPattern.hasMatch(clean)) return true;
    if (TagConstants.allRegions.contains(clean)) return true;

    for (final matcher in TagConstants.partialMatchers) {
      if (clean.contains(matcher)) return true;
    }
    return false;
  }

  static String normalizeTag(String tag) {
    final trimmed = tag.trim();
    final upper = trimmed.toUpperCase();

    if (TagConstants.videoStandards.contains(upper)) return upper;
    if (trimmed.length <= 3) return upper;

    return trimmed[0].toUpperCase() + trimmed.substring(1).toLowerCase();
  }

  static String sanitizeFolderName(String name) {
    final sanitized = name.replaceAll(_illegalFolderChars, '');
    return sanitized.trim().replaceAll(_repeatedSpaces, ' ');
  }

  static String buildDownloadUrl(String baseUrl, String href) {
    if (href.startsWith('http')) return href;
    final base = baseUrl.replaceFirst(RegExp(r'/+$'), '');
    final path = href.replaceFirst(RegExp(r'^/+'), '');
    return _normalizeUrl('$base/$path');
  }

  /// Removes `.`/`..` segments from [url]'s *path only* — never touches the
  /// scheme/authority. A naive string-split-and-rejoin over the whole URL
  /// would let enough `../` segments in a scraped href pop past the host
  /// itself (e.g. `buildDownloadUrl('http://good.com/dir', '../../evil.com/x')`
  /// would resolve to `http://evil.com/x`), letting a malicious/compromised
  /// HTTP source silently redirect downloads to an arbitrary host.
  static String _normalizeUrl(String url) {
    final uri = Uri.parse(url);
    final normalized = <String>[];
    for (final part in uri.path.split('/')) {
      if (part == '..') {
        if (normalized.isNotEmpty) normalized.removeLast();
      } else if (part == '.' || part.isEmpty) {
        continue;
      } else {
        normalized.add(part);
      }
    }
    return uri.replace(path: '/${normalized.join('/')}').toString();
  }

  static String decodeUrlEncodedFileName(String fileName) {
    try {
      return Uri.decodeFull(fileName);
    } catch (_) {
      return fileName;
    }
  }

  static bool shouldSkipFile(String href) {
    return href == ScrapingConstants.parentDirectory ||
        href == ScrapingConstants.currentDirectory ||
        href.endsWith('/');
  }

  /// Trims a magnet URI's tracker list to [TorrentConstants.maxTrackersPerMagnet]
  /// so metadata fetching in the native torrent plugin isn't slowed down by
  /// dozens of trackers.
  static String optimizeMagnetUri(String uri) {
    if (!uri.startsWith('magnet:?')) return uri;

    final parts = uri.split('&');
    final base = parts.first;
    final params = parts.skip(1).toList();

    final trackers = params.where((p) => p.startsWith('tr=')).toList();
    final otherParams = params.where((p) => !p.startsWith('tr=')).toList();

    if (trackers.length <= TorrentConstants.maxTrackersPerMagnet) return uri;

    final optimizedTrackers = trackers.take(TorrentConstants.maxTrackersPerMagnet);
    final optimizedParams = [...otherParams, ...optimizedTrackers].join('&');

    return optimizedParams.isEmpty ? base : '$base&$optimizedParams';
  }
}
