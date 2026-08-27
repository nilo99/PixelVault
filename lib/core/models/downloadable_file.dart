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
