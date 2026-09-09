import '../scraping/file_naming.dart';

/// A single scraped rom/file, with its resolved display name and tags.
/// Mirrors Milou's `DownloadableFileWithTagsResult` (Room) — `tags` is the
/// pipe-joined `GROUP_CONCAT` result, split lazily via [tagList].
class DownloadableFileWithTags {
  const DownloadableFileWithTags({
    required this.id,
    required this.name,
    required this.fileName,
    required this.consoleId,
    required this.downloadUrl,
    required this.fileSize,
    required this.fileExtension,
    this.torrentFileIndex,
    this.torrentMagnet,
    this.tags,
  });

  final int id;
  final String name;
  final String fileName;
  final String consoleId;
  final String downloadUrl;
  final int fileSize;
  final String fileExtension;
  final int? torrentFileIndex;
  final String? torrentMagnet;
  final String? tags;

  bool get isTorrent => torrentFileIndex != null && torrentMagnet != null;

  List<String> get tagList =>
      (tags == null || tags!.isEmpty) ? const [] : tags!.split('|');

  /// What the user actually ends up with. A source that ships `Game.iso.7z`
  /// stores `.7z` in [fileExtension] (that *is* what gets downloaded), but
  /// with auto-extraction on it is the `.iso` that lands in the destination
  /// folder — showing `.7z` in the library is what made ISO files look like
  /// they had been mislabelled as archives.
  String get contentExtension {
    final fromName = FileNaming.contentExtensionOf(fileName);
    return fromName.isNotEmpty ? fromName : fileExtension;
  }

  /// True when the download arrives wrapped in an archive.
  bool get isArchived => FileNaming.isArchiveWrapped(fileName);
}

/// Every file that belongs to the same game, collapsed into one search
/// result. Searching "pokemon" returns one entry per title, expandable to
/// the regions/revisions/formats underneath, instead of hundreds of
/// near-identical flat rows.
class DownloadableFileGroup {
  const DownloadableFileGroup({
    required this.key,
    required this.title,
    required this.variantCount,
    required this.totalSize,
    required this.variants,
  });

  /// Normalized grouping key (lowercased, trimmed title).
  final String key;

  /// Display title for the group — the shared, tag-stripped game name.
  final String title;

  final int variantCount;
  final int totalSize;
  final List<DownloadableFileWithTags> variants;

  /// A group with exactly one file behaves like a plain row: there is
  /// nothing to expand into.
  bool get isSingle => variants.length <= 1;

  /// The variant to act on when the user just taps download on the group
  /// header without expanding — the largest file, which for ROM sets is
  /// reliably the most complete dump rather than a demo or a patch.
  DownloadableFileWithTags? get primary {
    if (variants.isEmpty) return null;
    return variants.reduce((a, b) => b.fileSize > a.fileSize ? b : a);
  }

  /// Distinct content formats inside the group (`.iso`, `.chd`, …), for the
  /// summary line on the collapsed header.
  List<String> get formats {
    final seen = <String>{};
    for (final v in variants) {
      final ext = v.contentExtension;
      if (ext.isNotEmpty) seen.add(ext.replaceFirst('.', '').toUpperCase());
    }
    final sorted = seen.toList()..sort();
    return sorted;
  }
}

/// Mirrors Milou's `ConsoleWithFileCount` projection used to populate the
/// platform-select grid with only consoles that actually have indexed files.
class ConsoleWithFileCount {
  const ConsoleWithFileCount({
    required this.id,
    required this.name,
    required this.manufacturerId,
    required this.urlsJson,
    required this.fileCount,
    required this.totalSize,
  });

  final String id;
  final String name;
  final String manufacturerId;
  final String urlsJson;
  final int fileCount;
  final int totalSize;
}
