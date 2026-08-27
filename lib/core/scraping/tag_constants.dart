/// Port of Milou's `Constants.Tags` + `TagCategorizer` — the allowlists used
/// both to decide which parenthetical tokens survive filename parsing
/// (see `file_parsing.dart`) and to bucket tags for the filter UI.
abstract final class TagConstants {
  static const videoStandards = {'PAL', 'NTSC', 'NTSC-J', 'NTSC-U', 'NTSC-C'};

  static const contentTypes = {
    'DLC', 'UPDATE', 'TITLE UPDATE', 'PATCH', 'DEMO', 'BETA', 'PROTO',
    'PIRATE', 'KIOSK', 'GAME', 'MISCELLANEOUS', 'DEBUG', 'RETROACHIEVEMENTS', 'HACK',
  };

  static const regions = {
    'USA', 'EUROPE', 'JAPAN', 'KOREA', 'CHINA', 'AUSTRALIA', 'CANADA', 'MEXICO',
    'BRAZIL', 'GERMANY', 'FRANCE', 'SPAIN', 'ITALY', 'RUSSIA', 'UK', 'UNITED KINGDOM',
    'BRITAIN', 'WORLD', 'POLAND', 'FINLAND', 'PORTUGAL', 'SCANDINAVIA', 'BELGIUM',
    'NETHERLANDS', 'SWITZERLAND', 'DENMARK', 'GREECE',
  };

  static const continents = {
    'NORTH AMERICA', 'SOUTH AMERICA', 'EUROPE', 'ASIA', 'AFRICA', 'OCEANIA',
  };

  static const partialMatchers = [
    'BETA', 'PROTO', 'REV', 'VERSION', 'VER', 'LODGENET',
    'GAMECUBE', 'LIMITED', 'LAYER', 'PAK', 'PACK', 'BEST', 'BOX', 'DISC',
  ];

  static final languageCodePattern = RegExp(r'^[A-Z]{2,3}$');
  static final versionPattern = RegExp(r'^V\d+(\.\d+)?$');
  static final fileExtensionPattern = RegExp(r'^\.[A-Z0-9]+$');

  static Set<String> get allRegions => {...regions, ...continents};
}

class TagCategory {
  const TagCategory(this.name, this.tags);
  final String name;
  final List<String> tags;
}

class CategorizedTags {
  const CategorizedTags({
    required this.regions,
    required this.languages,
    required this.videoStandards,
    required this.contentTypes,
    required this.fileTypes,
  });

  final TagCategory regions;
  final TagCategory languages;
  final TagCategory videoStandards;
  final TagCategory contentTypes;
  final TagCategory fileTypes;
}

abstract final class TagCategorizer {
  static CategorizedTags categorize(List<String> tags) {
    final regions = <String>[];
    final languages = <String>[];
    final videoStandards = <String>[];
    final contentTypes = <String>[];
    final fileTypes = <String>[];

    for (final tag in tags) {
      final upper = tag.toUpperCase();
      if (TagConstants.videoStandards.contains(upper)) {
        videoStandards.add(tag);
      } else if (TagConstants.contentTypes.contains(upper)) {
        contentTypes.add(tag);
      } else if (TagConstants.allRegions.contains(upper)) {
        regions.add(tag);
      } else if (TagConstants.languageCodePattern.hasMatch(upper)) {
        languages.add(tag);
      } else if (TagConstants.fileExtensionPattern.hasMatch(upper)) {
        fileTypes.add(tag);
      }
    }

    int cmp(String a, String b) => a.compareTo(b);
    return CategorizedTags(
      regions: TagCategory('Regions', regions..sort(cmp)),
      languages: TagCategory('Languages', languages..sort(cmp)),
      videoStandards: TagCategory('Video Standards', videoStandards..sort(cmp)),
      contentTypes: TagCategory('Content Types', contentTypes..sort(cmp)),
      fileTypes: TagCategory('File Types', fileTypes..sort(cmp)),
    );
  }
}
