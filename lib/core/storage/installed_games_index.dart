import 'package:flutter/foundation.dart' show immutable;
import 'package:saf_util/saf_util_platform_interface.dart' show SafDocumentFile;

import '../scraping/rom_title.dart';
import '../settings/settings_repository.dart';
import 'saf_storage_helper.dart';

/// Lists a folder's children. The app passes `SafUtil().list`; tests pass a fake.
typedef FolderLister = Future<List<SafDocumentFile>> Function(String uri);

/// Finds a named child folder's URI, or `null`. The app backs this with
/// `SafUtil().child`; tests pass a fake.
typedef ChildFolderLookup = Future<String?> Function(String parentUri, String name);

/// What a destination folder already contains, by game.
@immutable
class InstalledGames {
  const InstalledGames({required this.keys, required this.fileNames, this.stems = const {}});

  static const empty = InstalledGames(keys: {}, fileNames: {});

  /// [RomTitle.key] of every file and folder present.
  final Set<String> keys;

  /// Exact names present, lowercased, for marking one specific variant.
  final Set<String> fileNames;

  /// Names present with their extensions removed, lowercased. An archive
  /// that gets unpacked is recognised by these: what comes out of
  /// `God of War (USA).7z` is `God of War (USA).iso`, whose extension is not
  /// known before downloading.
  final Set<String> stems;

  /// Whether any version of the game with [groupKey] is in the folder.
  bool hasGame(String groupKey) => keys.contains(groupKey);

  /// Whether this exact file is in the folder.
  bool hasFile(String fileName) => fileNames.contains(fileName.toLowerCase());

  /// Whether a file or folder named [stem], with any extension, is in the folder.
  bool hasStem(String stem) => stems.contains(stem.toLowerCase().trim());
}

/// Answers "is this game already in the folder it would download to?" from
/// the folder's real contents.
///
/// Reading the folder rather than the download history means it also
/// recognises games the user copied in by hand, and a game downloaded as
/// `.7z` then extracted to `.iso` — it matches on the game's title, not on a
/// file name. It also stops claiming a game is there once the user deletes it.
///
/// Listing a SAF folder is a platform round trip, so each folder's result is
/// cached briefly, concurrent requests for one folder share a single listing,
/// and [invalidate] drops the cache when a download lands.
class InstalledGamesIndex {
  InstalledGamesIndex({
    required this.lister,
    required this.childLookup,
    this.maxAge = const Duration(minutes: 2),
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final FolderLister lister;
  final ChildFolderLookup childLookup;

  /// How long a folder's listing is trusted before it is read again.
  final Duration maxAge;

  final DateTime Function() _clock;
  final _cache = <String, ({DateTime at, InstalledGames games})>{};
  final _inFlight = <String, Future<InstalledGames>>{};

  /// What the folder a download for [consoleId] would land in contains,
  /// resolved the same way `DownloadManager` resolves it: the console's own
  /// folder if one is set, otherwise the default folder — or, with
  /// separate-by-console on, the console-named subfolder inside it.
  Future<InstalledGames> forConsole(
    SettingsState settings, {
    required String consoleId,
    required String consoleName,
  }) async {
    final perConsole = settings.consoleDownloadDirectories[consoleId];
    if (perConsole != null && perConsole.isNotEmpty) return forFolder(perConsole);
    if (settings.downloadDirectory.isEmpty) return InstalledGames.empty;
    if (!settings.separateByConsole) return forFolder(settings.downloadDirectory);

    try {
      final subfolder = await childLookup(
        settings.downloadDirectory,
        DownloadPathResolver.sanitizeFolderName(consoleName),
      );
      return subfolder == null ? InstalledGames.empty : forFolder(subfolder);
    } catch (_) {
      return InstalledGames.empty;
    }
  }

  Future<InstalledGames> forFolder(String folderUri) {
    if (folderUri.isEmpty) return Future.value(InstalledGames.empty);
    final cached = _cache[folderUri];
    if (cached != null && _clock().difference(cached.at) < maxAge) {
      return Future.value(cached.games);
    }
    // A block body on purpose: `=> _inFlight.remove(...)` would return the
    // removed future, and `whenComplete` waits on a returned future — this
    // one would wait on itself forever.
    return _inFlight[folderUri] ??= _load(folderUri).whenComplete(() {
      _inFlight.remove(folderUri);
    });
  }

  Future<InstalledGames> _load(String folderUri) async {
    try {
      final children = await lister(folderUri);
      final keys = <String>{};
      final names = <String>{};
      final stems = <String>{};
      for (final child in children) {
        names.add(child.name.toLowerCase());
        stems.add(RomTitle.stripExtensions(child.name).toLowerCase().trim());
        final key = RomTitle.key(child.name);
        if (key.isNotEmpty) keys.add(key);
      }
      final games = InstalledGames(keys: keys, fileNames: names, stems: stems);
      _cache[folderUri] = (at: _clock(), games: games);
      return games;
    } catch (_) {
      // A revoked folder grant or a removed SD card is not worth an error on
      // a search screen; the badge simply does not appear.
      return InstalledGames.empty;
    }
  }

  /// Forgets what [folderUri] contained — or every folder, when omitted.
  void invalidate([String? folderUri]) {
    if (folderUri == null) {
      _cache.clear();
    } else {
      _cache.remove(folderUri);
    }
  }
}
