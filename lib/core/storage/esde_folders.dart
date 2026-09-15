/// ES-DE's ROM folder names for the consoles PixelVault supports.
///
/// Many users already keep their games in ES-DE's standard layout —
/// https://github.com/retrogamecorps/ES-DE-Directories — where every system
/// has a fixed folder under `ROMs/` (`psx` for PlayStation, `n3ds` for the
/// 3DS, and so on). Every name below was checked against that repository.
abstract final class EsDeFolders {
  /// Console id → folder names ES-DE recognises for it, preferred first.
  /// Regional alternatives come after the primary name, so a layout that uses
  /// `megadrive` instead of `genesis` is still recognised.
  static const byConsole = <String, List<String>>{
    'nintendo_gameboy': ['gb'],
    'nintendo_gameboy_color': ['gbc'],
    'nintendo_gameboy_advance': ['gba'],
    'nintendo_nintendo_entertainment_system': ['nes', 'famicom'],
    'nintendo_super_nintendo_entertainment_system': ['snes', 'sfc', 'snesna'],
    'nintendo_nintendo_64': ['n64'],
    'nintendo_nintendo_ds': ['nds'],
    'nintendo_nintendo_3ds': ['n3ds'],
    'nintendo_gamecube': ['gc'],
    'sony_playstation': ['psx'],
    'sony_playstation_2': ['ps2'],
    'sony_playstation_portable': ['psp'],
    'sega_master_system': ['mastersystem', 'mark3'],
    'sega_genesis': ['genesis', 'megadrive', 'megadrivejp'],
    'sega_cd': ['segacd', 'megacd', 'megacdjp'],
    'sega_dreamcast': ['dreamcast'],
  };

  /// Every folder name above, lowercased.
  static final knownFolders = {
    for (final names in byConsole.values) ...names,
  };

  /// Whether a folder whose children are [childNames] looks like an ES-DE
  /// ROMs folder. Three recognised system folders is enough to tell it apart
  /// from, say, a Downloads folder that happens to contain a `gb` directory.
  static bool looksLikeRomsFolder(Iterable<String> childNames) {
    final lower = {for (final name in childNames) name.toLowerCase()};
    return knownFolders.where(lower.contains).length >= 3;
  }

  /// The existing child folder to use for [consoleId], matched without regard
  /// to case, preferring ES-DE's primary name when several are present.
  /// Returns the child's actual name, or `null` if none exists.
  static String? existingFolderFor(String consoleId, Iterable<String> childNames) {
    final candidates = byConsole[consoleId];
    if (candidates == null) return null;
    final byLower = {for (final name in childNames) name.toLowerCase(): name};
    for (final candidate in candidates) {
      final actual = byLower[candidate];
      if (actual != null) return actual;
    }
    return null;
  }

  /// The folder to create for [consoleId] when the layout lacks one.
  static String? primaryFolderFor(String consoleId) => byConsole[consoleId]?.first;
}
