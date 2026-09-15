import 'package:flutter_test/flutter_test.dart';
import 'package:pixelvault/core/scraping/rom_title.dart';
import 'package:pixelvault/core/settings/settings_repository.dart';
import 'package:pixelvault/core/storage/installed_games_index.dart';
import 'package:saf_util/saf_util_platform_interface.dart' show SafDocumentFile;

SafDocumentFile _entry(String name, {bool isDir = false}) =>
    SafDocumentFile(uri: 'content://doc/$name', name: name, isDir: isDir, length: 1, lastModified: 0);

void main() {
  late Map<String, List<SafDocumentFile>> folders;
  late Map<String, int> listCalls;
  late DateTime now;
  late InstalledGamesIndex index;

  setUp(() {
    folders = {};
    listCalls = {};
    now = DateTime(2026, 9, 10, 12);
    index = InstalledGamesIndex(
      lister: (uri) async {
        listCalls[uri] = (listCalls[uri] ?? 0) + 1;
        final children = folders[uri];
        if (children == null) throw StateError('permission revoked');
        return children;
      },
      childLookup: (parent, name) async => folders.containsKey('$parent/$name') ? '$parent/$name' : null,
      clock: () => now,
    );
  });

  test('recognises a game in the folder whatever format or region it was saved as', () async {
    folders['content://ps2'] = [_entry('God of War (USA).iso'), _entry('Ico (Europe).chd')];

    final games = await index.forFolder('content://ps2');

    // Searching finds the game as a 7z from a different region: still "already there".
    expect(games.hasGame(RomTitle.key('God of War (Europe).7z')), isTrue);
    expect(games.hasGame(RomTitle.key('Ico (USA).iso')), isTrue);
    // A sequel is a different game.
    expect(games.hasGame(RomTitle.key('God of War II (USA).iso')), isFalse);
  });

  test('recognises a game kept in its own folder', () async {
    folders['content://psx'] = [_entry('Final Fantasy VII (USA)', isDir: true)];
    final games = await index.forFolder('content://psx');
    expect(games.hasGame(RomTitle.key('Final Fantasy VII (USA) (Disc 1).chd')), isTrue);
  });

  test('matches an exact file name without regard to case', () async {
    folders['content://ps2'] = [_entry('God of War (USA).iso')];
    final games = await index.forFolder('content://ps2');
    expect(games.hasFile('god of war (usa).ISO'), isTrue);
    expect(games.hasFile('God of War (Europe).iso'), isFalse);
  });

  test('lists a folder once and serves repeats from the cache', () async {
    folders['content://ps2'] = [_entry('God of War (USA).iso')];

    await index.forFolder('content://ps2');
    await index.forFolder('content://ps2');

    expect(listCalls['content://ps2'], 1);
  });

  test('concurrent requests for one folder share a single listing', () async {
    folders['content://ps2'] = [_entry('God of War (USA).iso')];
    await Future.wait([index.forFolder('content://ps2'), index.forFolder('content://ps2')]);
    expect(listCalls['content://ps2'], 1);
  });

  test('lists again once the cache ages out', () async {
    folders['content://ps2'] = [];
    await index.forFolder('content://ps2');

    now = now.add(const Duration(minutes: 3));
    folders['content://ps2'] = [_entry('God of War (USA).iso')];
    final games = await index.forFolder('content://ps2');

    expect(listCalls['content://ps2'], 2);
    expect(games.hasGame(RomTitle.key('God of War')), isTrue);
  });

  test('invalidate makes the next request see a download that just landed', () async {
    folders['content://ps2'] = [];
    await index.forFolder('content://ps2');

    folders['content://ps2'] = [_entry('God of War (USA).iso')];
    index.invalidate('content://ps2');
    final games = await index.forFolder('content://ps2');

    expect(games.hasGame(RomTitle.key('God of War')), isTrue);
  });

  test('an unreadable folder yields nothing instead of throwing', () async {
    final games = await index.forFolder('content://gone');
    expect(games.keys, isEmpty);
  });

  group('forConsole', () {
    test('uses the console’s own folder when one is set', () async {
      folders['content://esde/ps2'] = [_entry('God of War (USA).iso')];
      const settings = SettingsState(
        downloadDirectory: 'content://roms',
        consoleDownloadDirectories: {'sony_playstation_2': 'content://esde/ps2'},
      );

      final games = await index.forConsole(settings, consoleId: 'sony_playstation_2', consoleName: 'PlayStation 2');
      expect(games.hasGame(RomTitle.key('God of War')), isTrue);
    });

    test('looks in the console-named subfolder when separating by console', () async {
      folders['content://roms/PlayStation 2'] = [_entry('God of War (USA).iso')];
      const settings = SettingsState(downloadDirectory: 'content://roms', separateByConsole: true);

      final games = await index.forConsole(settings, consoleId: 'sony_playstation_2', consoleName: 'PlayStation 2');
      expect(games.hasGame(RomTitle.key('God of War')), isTrue);
    });

    test('uses the default folder otherwise', () async {
      folders['content://roms'] = [_entry('God of War (USA).iso')];
      const settings = SettingsState(downloadDirectory: 'content://roms');

      final games = await index.forConsole(settings, consoleId: 'sony_playstation_2', consoleName: 'PlayStation 2');
      expect(games.hasGame(RomTitle.key('God of War')), isTrue);
    });

    test('knows nothing when no folder is configured', () async {
      final games = await index.forConsole(
        const SettingsState(),
        consoleId: 'sony_playstation_2',
        consoleName: 'PlayStation 2',
      );
      expect(games.keys, isEmpty);
      expect(listCalls, isEmpty);
    });
  });
}
