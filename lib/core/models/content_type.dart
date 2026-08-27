/// Mirrors Milou's `ContentType` enum used on a source's `UrlEntry` and
/// carried through as an extra tag on every file scraped from that source.
enum ContentType {
  game,
  miscellaneous,
  retroachievements;

  static ContentType fromJson(String value) {
    switch (value.toUpperCase()) {
      case 'MISCELLANEOUS':
        return ContentType.miscellaneous;
      case 'RETROACHIEVEMENTS':
        return ContentType.retroachievements;
      case 'GAME':
      default:
        return ContentType.game;
    }
  }

  String toJson() => switch (this) {
        ContentType.game => 'GAME',
        ContentType.miscellaneous => 'MISCELLANEOUS',
        ContentType.retroachievements => 'RETROACHIEVEMENTS',
      };
}
