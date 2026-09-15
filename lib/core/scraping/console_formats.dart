import 'file_naming.dart';

/// How a file's format is shown in the library.
typedef FormatLabel = ({String format, String? archive});

/// What each console's games actually are once unpacked.
abstract final class ConsoleFormats {
  static const _payload = <String, String>{
    'sony_playstation': 'BIN/CUE',
    'sony_playstation_2': 'ISO',
    'sony_playstation_portable': 'ISO',
    'nintendo_gamecube': 'ISO',
    'nintendo_nintendo_3ds': '3DS',
    'nintendo_nintendo_ds': 'NDS',
    'nintendo_gameboy_advance': 'GBA',
    'nintendo_gameboy_color': 'GBC',
    'nintendo_gameboy': 'GB',
    'nintendo_super_nintendo_entertainment_system': 'SFC',
    'nintendo_nintendo_64': 'Z64',
    'nintendo_nintendo_entertainment_system': 'NES',
    'sega_cd': 'BIN/CUE',
    'sega_dreamcast': 'GDI',
    'sega_genesis': 'MD',
    'sega_master_system': 'SMS',
  };

  static String? expectedPayload(String consoleId) => _payload[consoleId];

  /// The format to show for a file, plus the archive it arrives in, if any.
  ///
  /// Sources usually name archives `God of War (USA).7z`, which says nothing
  /// about what is inside, so the library could only ever show "7Z" — the
  /// "ISO files show up as 7z" report. When an archive's own name spells out
  /// its payload (`Game.iso.7z`) that is used. Otherwise, with auto-extraction
  /// on, what lands in the folder is the console's own disc or cartridge
  /// format, so that is shown with the archive beside it. With auto-extraction
  /// off the archive itself is what the user gets, and is shown as such.
  static FormatLabel describe({
    required String fileName,
    required String fileExtension,
    required bool isArchive,
    required String consoleId,
    required bool autoUnzip,
  }) {
    final outer = _label(fileExtension.isNotEmpty ? fileExtension : FileNaming.extensionOf(fileName));
    if (!isArchive) return (format: outer, archive: null);

    final inner = _label(FileNaming.contentExtensionOf(fileName));
    if (inner.isNotEmpty && inner != outer) return (format: inner, archive: outer);

    final expected = expectedPayload(consoleId);
    if (autoUnzip && expected != null) return (format: expected, archive: outer);
    return (format: outer, archive: null);
  }

  static String _label(String extension) => extension.replaceFirst('.', '').toUpperCase();
}
