import 'file_naming.dart';

/// A game's title as a person thinks of it, independent of how any one file
/// of that game happens to be named.
///
/// Searching "god of war" should give one entry for God of War and one for
/// God of War II, each holding every region, revision and format of that
/// game. Grouping on the stored `name` did not, because the scraper built
/// `name` from the file name with the extension still attached: "God of War
/// .chd" and "God of War .7z" were different titles, so every format landed
/// in its own dropdown.
abstract final class RomTitle {
  static final _tagGroups = RegExp(r'\s*(\([^)]*\)|\[[^\]]*\]|\{[^}]*\})');
  static final _underscores = RegExp(r'_+');
  static final _spaces = RegExp(r'\s+');
  static final _edgePunctuation = RegExp(r'^[\s\-–—,.;:]+|[\s\-–—,;:]+$');

  /// "Legend of Zelda, The - Ocarina of Time" — No-Intro style — so the
  /// article can be moved back to the front.
  static final _trailingArticle = RegExp(
    r'^(.+?),\s+(The|A|An)(\s*[-–—:].*)?$',
    caseSensitive: false,
  );

  /// Anything that is not a letter or digit in *any* script. Unicode-aware on
  /// purpose: an ASCII-only class would reduce every Japanese title to the
  /// empty string and merge them all into a single group.
  static final _nonAlphanumeric = RegExp(r'[^\p{L}\p{N}]+', unicode: true);

  static const _accents = {
    'à': 'a', 'á': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a', 'å': 'a',
    'ç': 'c',
    'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e',
    'ì': 'i', 'í': 'i', 'î': 'i', 'ï': 'i',
    'ñ': 'n',
    'ò': 'o', 'ó': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o',
    'ù': 'u', 'ú': 'u', 'û': 'u', 'ü': 'u',
    'ý': 'y', 'ÿ': 'y',
  };

  /// Display title for a file name (or an already-cleaned name): no
  /// extension, no `(…)`/`[…]`/`{…}` tag groups, underscores as spaces, and a
  /// trailing English article moved to the front.
  static String title(String fileOrName) {
    var s = stripExtensions(fileOrName);
    s = s.replaceAll(_tagGroups, ' ');
    s = s.replaceAll(_underscores, ' ');
    s = s.replaceAll(_spaces, ' ').trim();
    s = s.replaceAll(_edgePunctuation, '');

    final article = _trailingArticle.firstMatch(s);
    if (article != null) {
      s = '${article.group(2)} ${article.group(1)}${article.group(3) ?? ''}';
    }
    return s.trim();
  }

  /// The title to store for a scraped file.
  ///
  /// Taken from the file name rather than a listing's link text: directory
  /// listings truncate long link text ("God of War II (Europe, Au..>"),
  /// which would leave a half-stripped title sitting in a group of its own.
  /// [displayName] is only used when the file name yields nothing.
  static String forCatalog({required String fileName, required String displayName}) {
    final fromFile = title(fileName);
    return fromFile.isNotEmpty ? fromFile : title(displayName);
  }

  /// The key every file of one game shares: its [title], lowercased, with
  /// accents folded and punctuation collapsed. "Pokémon - Emerald Version"
  /// and "pokemon emerald version" match; "God of War" and "God of War II"
  /// do not.
  static String key(String fileOrName) {
    final lower = title(fileOrName).toLowerCase();
    final folded = StringBuffer();
    for (final char in lower.split('')) {
      folded.write(_accents[char] ?? char);
    }
    return folded.toString().replaceAll(_nonAlphanumeric, ' ').trim();
  }

  /// Removes the extension, and the inner one as well when the outer one is
  /// an archive wrapping a named payload: `Game.iso.7z` → `Game`.
  ///
  /// Only real extensions are removed — see [FileNaming.extensionOf] — so a
  /// title ending in a version number (`Super Mario Bros. 3`) is left alone.
  static String stripExtensions(String name) {
    final outer = FileNaming.extensionOf(name);
    if (outer.isEmpty) return name;
    final wrapped = FileNaming.isArchiveWrapped(name);
    var s = name.substring(0, name.length - outer.length);
    if (wrapped) {
      final inner = FileNaming.extensionOf(s);
      s = s.substring(0, s.length - inner.length);
    }
    return s;
  }
}
