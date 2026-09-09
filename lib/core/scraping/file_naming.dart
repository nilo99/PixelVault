/// Turns whatever a source calls a file (an HTTP listing's raw `href`, a
/// torrent's internal path) into the bare, filesystem-safe name the app
/// actually writes to disk — and derives a trustworthy extension from it.
///
/// This exists because `href` is *not* a file name. A directory listing can
/// legitimately link to `sub/dir/Game.iso`, `/roms/Game%20(USA).chd?dl=1` or
/// even an absolute `https://host/path/Game.iso`. Storing that raw string as
/// `DownloadableFiles.fileName` (which is what happened before) meant:
///
///  * the local staging file was opened at `<cache>/12_sub/dir/Game.iso`, a
///    directory that doesn't exist — the download died with a
///    `FileSystemException` before a single byte was written;
///  * the SAF destination was asked to create a document literally named
///    `sub/dir/Game.iso`, which either fails or lands somewhere the user
///    will never find — the "it says it downloaded but the folder is empty"
///    report;
///  * `fileExtension` was `href.split('.').last`, so `Game.iso?dl=1` became
///    `iso?dl=1` and a dotted-but-extensionless href like `v1.2` became `2`.
///
/// Every name is funnelled through [fileNameFromHref] both at scrape time
/// (so new rows are stored clean) and again at download time (so rows
/// already scraped by an older build are repaired on the fly) — it is
/// idempotent, so running it on an already-clean name changes nothing.
abstract final class FileNaming {
  /// Characters Android's SAF / FAT32 / exFAT reject in a document name,
  /// plus the path separators that must never survive into a bare name.
  static final _illegalChars = RegExp(r'[<>:"/\\|?*\x00-\x1F]');
  static final _repeatedSpaces = RegExp(r'\s{2,}');
  static final _trailingDots = RegExp(r'[. ]+$');

  /// A real extension: 1–8 alphanumerics containing at least one letter.
  /// The letter requirement is what stops `Final Fantasy VII (Disc 1.2)`
  /// from reporting an extension of `.2`, while still accepting `.7z`.
  static final _validExtension = RegExp(r'^(?=[a-z0-9]{1,8}$)[a-z0-9]*[a-z][a-z0-9]*$');

  /// Archive extensions whose *inner* extension is the interesting one when
  /// showing the user what they are actually getting — see
  /// [contentExtensionOf]. Mirrors `ArchiveExtensions.isExtractable`.
  static const _archiveExtensions = {
    '.zip', '.7z', '.rar', '.tar', '.gz', '.tgz', '.bz2', '.xz', '.cab',
  };

  /// The bare, filesystem-safe file name [href] refers to.
  ///
  /// Strips any query string and fragment, reduces an absolute URL to its
  /// path, percent-decodes, takes the last path segment, and sanitizes what
  /// is left. Returns `''` only when nothing usable survives — callers fall
  /// back to a generated name in that case.
  static String fileNameFromHref(String href) {
    var path = href.split('#').first.split('?').first;

    // An absolute URL's authority must not leak into the file name.
    final uri = Uri.tryParse(path);
    if (uri != null && uri.hasScheme && uri.host.isNotEmpty) {
      path = uri.path;
    }

    path = _decode(path);

    final segments = path.split(RegExp(r'[/\\]')).where((s) => s.trim().isNotEmpty);
    if (segments.isEmpty) return '';
    return sanitize(segments.last);
  }

  /// Percent-decoding that never throws on a malformed `%` sequence (some
  /// listings emit a literal `%` in a name) and never silently turns `+`
  /// into a space — `+` is a legal literal character in a path segment and
  /// ROM names use it (`Sonic 3 + Knuckles`).
  static String _decode(String value) {
    try {
      return Uri.decodeFull(value);
    } catch (_) {
      return value;
    }
  }

  /// Makes [name] safe to hand to SAF: no path separators, no reserved
  /// characters, no trailing dots/spaces (Android silently drops those,
  /// producing a file the app then can't find again), length-capped.
  static String sanitize(String name) {
    var clean = name.replaceAll(_illegalChars, '_').trim();
    clean = clean.replaceAll(_repeatedSpaces, ' ');
    clean = clean.replaceAll(_trailingDots, '');
    if (clean == '.' || clean == '..') return '';
    // 255 is the ext4/exFAT per-component limit; keep the extension attached
    // rather than truncating it off the end.
    if (clean.length > 200) {
      final ext = extensionOf(clean);
      clean = clean.substring(0, 200 - ext.length) + ext;
    }
    return clean;
  }

  /// The file's extension including the leading dot (`.iso`), lowercased, or
  /// `''` when the name has no extension that survives [_validExtension].
  static String extensionOf(String fileName) {
    final dot = fileName.lastIndexOf('.');
    if (dot <= 0 || dot == fileName.length - 1) return '';
    final candidate = fileName.substring(dot + 1).toLowerCase();
    return _validExtension.hasMatch(candidate) ? '.$candidate' : '';
  }

  /// The extension that describes what the user actually ends up with.
  ///
  /// For a plain `Game.iso` that is just `.iso`. For an archive-wrapped
  /// `Game.iso.7z` it is `.iso` — the archive is a transport detail, and
  /// with auto-extraction on (the default) the `.iso` is literally what
  /// lands in the destination folder. Showing `.7z` there is what made
  /// "ficheiros iso aparecem como .7z" look like a bug in the catalog.
  static String contentExtensionOf(String fileName) {
    final outer = extensionOf(fileName);
    if (outer.isEmpty || !_archiveExtensions.contains(outer)) return outer;
    final inner = extensionOf(fileName.substring(0, fileName.length - outer.length));
    return inner.isEmpty ? outer : inner;
  }

  /// True when [fileName]'s real payload is wrapped in an archive, i.e. the
  /// content extension and the on-disk extension disagree.
  static bool isArchiveWrapped(String fileName) {
    final outer = extensionOf(fileName);
    return outer.isNotEmpty &&
        _archiveExtensions.contains(outer) &&
        contentExtensionOf(fileName) != outer;
  }

  /// Name to use when a source gives us nothing usable, so a download still
  /// lands somewhere findable instead of failing outright.
  ///
  /// Sanitizing turns every reserved character into `_`, so a display name
  /// made only of those (`///`) would otherwise yield the useless `___`;
  /// requiring at least one alphanumeric keeps such a name out.
  static String fallbackName(int id, String displayName) {
    final fromDisplay = sanitize(displayName);
    if (fromDisplay.isEmpty || !_hasAlphanumeric.hasMatch(fromDisplay)) {
      return 'pixelvault_$id';
    }
    return fromDisplay;
  }

  static final _hasAlphanumeric = RegExp(r'[a-zA-Z0-9]');
}
