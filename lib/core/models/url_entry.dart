import 'content_type.dart';

/// A single scrape source attached to a console: an HTTP directory-listing
/// URL or a magnet link, tagged with the kind of content it holds and an
/// optional folder allow-list (torrent sources only).
class UrlEntry {
  const UrlEntry({
    required this.url,
    required this.contentType,
    this.folders,
    this.lastSyncedAt,
  });

  factory UrlEntry.fromJson(Map<String, dynamic> json) {
    return UrlEntry(
      url: json['url'] as String,
      contentType: json['contentType'] == null
          ? ContentType.game
          : ContentType.fromJson(json['contentType'] as String),
      folders: (json['folders'] as List?)?.cast<String>(),
      lastSyncedAt: json['lastSyncedAt'] == null ? null : DateTime.parse(json['lastSyncedAt'] as String),
    );
  }

  final String url;
  final ContentType contentType;
  final List<String>? folders;

  /// When this specific source was last successfully scraped — `null` means
  /// never (either brand new, or its last scrape attempt failed). Distinct
  /// from the console-wide indexed-file count: a console can have files from
  /// an old source while a newly-added one still has `lastSyncedAt == null`,
  /// which is exactly the state the Fontes screen needs to flag.
  final DateTime? lastSyncedAt;

  bool get isTorrent => url.startsWith('magnet:') || url.endsWith('.torrent');

  UrlEntry copyWith({
    String? url,
    ContentType? contentType,
    List<String>? folders,
    DateTime? lastSyncedAt,
    bool clearLastSyncedAt = false,
  }) {
    return UrlEntry(
      url: url ?? this.url,
      contentType: contentType ?? this.contentType,
      folders: folders ?? this.folders,
      lastSyncedAt: clearLastSyncedAt ? null : (lastSyncedAt ?? this.lastSyncedAt),
    );
  }

  Map<String, dynamic> toJson() => {
        'url': url,
        'contentType': contentType.toJson(),
        if (folders != null) 'folders': folders,
        if (lastSyncedAt != null) 'lastSyncedAt': lastSyncedAt!.toIso8601String(),
      };
}
