import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pixelvault/core/scraping/console_formats.dart';

void main() {
  test('a plain disc image shows its own format and no archive', () {
    final label = ConsoleFormats.describe(
      fileName: 'God of War (USA).chd',
      fileExtension: '.chd',
      isArchive: false,
      consoleId: 'sony_playstation_2',
      autoUnzip: true,
    );
    expect(label, (format: 'CHD', archive: null));
  });

  test('an archive that names its payload shows that payload', () {
    final label = ConsoleFormats.describe(
      fileName: 'God of War (USA).iso.7z',
      fileExtension: '.7z',
      isArchive: true,
      consoleId: 'sony_playstation_2',
      autoUnzip: false,
    );
    expect(label, (format: 'ISO', archive: '7Z'));
  });

  test('a PS2 archive shows ISO when it will be extracted', () {
    // The reported case: "God of War (USA).7z" contains an ISO.
    final label = ConsoleFormats.describe(
      fileName: 'God of War (USA).7z',
      fileExtension: '.7z',
      isArchive: true,
      consoleId: 'sony_playstation_2',
      autoUnzip: true,
    );
    expect(label, (format: 'ISO', archive: '7Z'));
  });

  test('with auto-extraction off the archive is what the user gets', () {
    final label = ConsoleFormats.describe(
      fileName: 'God of War (USA).7z',
      fileExtension: '.7z',
      isArchive: true,
      consoleId: 'sony_playstation_2',
      autoUnzip: false,
    );
    expect(label, (format: '7Z', archive: null));
  });

  test('an archive for a console with no known payload stays labelled as the archive', () {
    final label = ConsoleFormats.describe(
      fileName: 'Pack (World).zip',
      fileExtension: '.zip',
      isArchive: true,
      consoleId: 'rompacks_proper_romsets',
      autoUnzip: true,
    );
    expect(label, (format: 'ZIP', archive: null));
  });

  test('falls back to the file name when the stored extension is empty', () {
    final label = ConsoleFormats.describe(
      fileName: 'Metroid Prime (USA).iso',
      fileExtension: '',
      isArchive: false,
      consoleId: 'nintendo_gamecube',
      autoUnzip: true,
    );
    expect(label.format, 'ISO');
  });

  test('every console seeded by the app, except the rom packs, has a payload format', () {
    final seed = jsonDecode(File('assets/consoles.json').readAsStringSync()) as Map<String, dynamic>;
    final missing = [
      for (final manufacturer in seed.entries)
        if (manufacturer.key != 'rompacks')
          for (final console in (manufacturer.value as Map<String, dynamic>).keys)
            if (ConsoleFormats.expectedPayload('${manufacturer.key}_$console') == null) '${manufacturer.key}_$console',
    ];
    expect(missing, isEmpty);
  });
}
