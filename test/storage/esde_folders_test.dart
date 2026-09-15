import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pixelvault/core/storage/esde_folders.dart';

/// The ROMs/ subfolders of https://github.com/retrogamecorps/ES-DE-Directories
/// that the mapping relies on, copied from the repository's tree.
const _esDeRepositoryFolders = {
  'gb', 'gbc', 'gba', 'nes', 'famicom', 'snes', 'sfc', 'snesna', 'n64', 'nds',
  'n3ds', 'gc', 'psx', 'ps2', 'psp', 'mastersystem', 'mark3', 'genesis',
  'megadrive', 'megadrivejp', 'segacd', 'megacd', 'megacdjp', 'dreamcast',
};

void main() {
  test('every folder name used exists in the ES-DE directory layout', () {
    expect(_esDeRepositoryFolders.containsAll(EsDeFolders.knownFolders), isTrue,
        reason: 'unknown: ${EsDeFolders.knownFolders.difference(_esDeRepositoryFolders)}');
  });

  test('uses the names the user expects for PlayStation and 3DS', () {
    expect(EsDeFolders.primaryFolderFor('sony_playstation'), 'psx');
    expect(EsDeFolders.primaryFolderFor('nintendo_nintendo_3ds'), 'n3ds');
    expect(EsDeFolders.primaryFolderFor('sony_playstation_2'), 'ps2');
  });

  test('every console seeded by the app has an ES-DE folder, except the rom packs', () {
    final seed = jsonDecode(File('assets/consoles.json').readAsStringSync()) as Map<String, dynamic>;
    final consoleIds = [
      for (final manufacturer in seed.entries)
        if (manufacturer.key != 'rompacks')
          for (final console in (manufacturer.value as Map<String, dynamic>).keys)
            '${manufacturer.key}_$console',
    ];

    final missing = consoleIds.where((id) => !EsDeFolders.byConsole.containsKey(id)).toList();
    expect(missing, isEmpty);
  });

  test('rom packs have no single ES-DE folder', () {
    expect(EsDeFolders.primaryFolderFor('rompacks_proper_romsets'), isNull);
  });

  group('looksLikeRomsFolder', () {
    test('recognises an ES-DE ROMs folder', () {
      expect(EsDeFolders.looksLikeRomsFolder(['psx', 'ps2', 'snes', 'bios', 'ports']), isTrue);
    });

    test('ignores case', () {
      expect(EsDeFolders.looksLikeRomsFolder(['PSX', 'PS2', 'SNES']), isTrue);
    });

    test('does not mistake an unrelated folder for one', () {
      expect(EsDeFolders.looksLikeRomsFolder(['DCIM', 'Music', 'Download']), isFalse);
      expect(EsDeFolders.looksLikeRomsFolder(['gb', 'Music']), isFalse);
    });
  });

  group('existingFolderFor', () {
    test('matches without regard to case and returns the real name', () {
      expect(EsDeFolders.existingFolderFor('sony_playstation', ['PSX', 'ps2']), 'PSX');
    });

    test('falls back to a regional name when the primary one is absent', () {
      expect(EsDeFolders.existingFolderFor('sega_genesis', ['megadrive', 'snes']), 'megadrive');
    });

    test('prefers the primary name when both exist', () {
      expect(EsDeFolders.existingFolderFor('sega_genesis', ['megadrive', 'genesis']), 'genesis');
    });

    test('returns null when the layout has no folder for the console', () {
      expect(EsDeFolders.existingFolderFor('sony_playstation_2', ['psx', 'snes']), isNull);
    });
  });
}
