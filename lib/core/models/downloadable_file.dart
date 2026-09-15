import '../scraping/console_formats.dart';
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

  /// The format the Library shows for this file, plus the archive it
  /// arrives in when that is worth mentioning.
  ///
  /// Whether an archive gets unpacked is decided exactly the way the
  /// downloader decides it — on [fileExtension] and the auto-extract setting
  /// — so the label describes what will really land in the folder. Most
  /// sources name a PS2 game `God of War (USA).7z`, which says nothing about
  /// the ISO inside; see `ConsoleFormats.describe`.
  FormatLabel formatLabel({required bool autoUnzip}) => ConsoleFormats.describe(
        fileName: fileName,
        fileExtension: fileExtension,
        isArchive: FileNaming.isArchiveExtension(fileExtension),
        consoleId: consoleId,
        autoUnzip: autoUnzip,
      );
}

/// Every file of one game on one console, collapsed into one search result.
/// Searching "god of war" returns one entry for God of War and one for God
/// of War II, each expandable to every region, revision and format of that
/// game, instead of hundreds of near-identical flat rows.
class DownloadableFileGroup {
  const DownloadableFileGroup({
    required this.key,
    required this.title,
    required this.variantCount,
    required this.totalSize,
    required this.variants,
    this.consoleId = '',
  });

  /// The game's group key (`RomTitle.key` of its title), shared by all of
  /// its files.
  final String key;

  /// The console the files belong to. The same title on two consoles is two
  /// different games, so this is part of a group's identity.
  final String consoleId;

  /// Display title for the group — the shared, tag-stripped game name.
  final String title;

  final int variantCount;
  final int totalSize;
  final List<DownloadableFileWithTags> variants;

  /// Unique across consoles, for widget keys and expansion state.
  String get id => idFor(consoleId, key);

  static String idFor(String consoleId, String key) => '$consoleId/$key';

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

  /// Distinct formats inside the group, labelled the way each variant is
  /// (see [DownloadableFileWithTags.formatLabel]), for the collapsed header.
  List<String> formatsFor({required bool autoUnzip}) {
    final seen = <String>{};
    for (final variant in variants) {
      final format = variant.formatLabel(autoUnzip: autoUnzip).format;
      if (format.isNotEmpty) seen.add(format);
    }
    return seen.toList()..sort();
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
