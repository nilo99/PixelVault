/// Maps console DB IDs to their corresponding asset image paths.
/// Only real consoles with Wikimedia Commons photos are listed — synthetic
/// entries like `rompacks_proper_romsets` intentionally fall back to the
/// generic procedural card.
abstract final class ConsoleArtCatalog {
  static const Map<String, String> assets = {
    'nintendo_gameboy_advance': 'assets/consoles/nintendo_gameboy_advance.png',
    'nintendo_gameboy_color': 'assets/consoles/nintendo_gameboy_color.png',
    'nintendo_gameboy': 'assets/consoles/nintendo_gameboy.png',
    'nintendo_super_nintendo_entertainment_system': 'assets/consoles/nintendo_super_nintendo_entertainment_system.png',
    'nintendo_nintendo_64': 'assets/consoles/nintendo_nintendo_64.png',
    'nintendo_nintendo_entertainment_system': 'assets/consoles/nintendo_nintendo_entertainment_system.png',
    'nintendo_nintendo_ds': 'assets/consoles/nintendo_nintendo_ds.png',
    'nintendo_nintendo_3ds': 'assets/consoles/nintendo_nintendo_3ds.png',
    'nintendo_gamecube': 'assets/consoles/nintendo_gamecube.png',
    'sony_playstation_portable': 'assets/consoles/sony_playstation_portable.png',
    'sony_playstation_2': 'assets/consoles/sony_playstation_2.png',
    'sony_playstation': 'assets/consoles/sony_playstation.png',
    'sega_master_system': 'assets/consoles/sega_master_system.png',
    'sega_genesis': 'assets/consoles/sega_genesis.png',
    'sega_dreamcast': 'assets/consoles/sega_dreamcast.png',
    'sega_cd': 'assets/consoles/sega_cd.png',
  };
}
