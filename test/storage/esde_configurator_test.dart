import 'package:flutter_test/flutter_test.dart';
import 'package:pixelvault/core/storage/esde_configurator.dart';
import 'package:saf_util/saf_util_platform_interface.dart' show SafDocumentFile;

/// An in-memory folder tree keyed by URI.
class _FakeStorage implements EsDeStorage {
  final tree = <String, List<SafDocumentFile>>{};
  final created = <String>[];

  void folder(String uri, List<String> childFolders, {List<String> files = const []}) {
    tree[uri] = [
      for (final name in childFolders)
        SafDocumentFile(uri: '$uri/$name', name: name, isDir: true, length: 0, lastModified: 0),
      for (final name in files)
        SafDocumentFile(uri: '$uri/$name', name: name, isDir: false, length: 1, lastModified: 0),
    ];
  }

  @override
  Future<List<SafDocumentFile>> list(String uri) async => tree[uri] ?? const [];

  @override
  Future<String> createFolder(String parentUri, String name) async {
    created.add('$parentUri/$name');
    final uri = '$parentUri/$name';
    tree[parentUri] = [
      ...?tree[parentUri],
      SafDocumentFile(uri: uri, name: name, isDir: true, length: 0, lastModified: 0),
    ];
    tree[uri] = const [];
    return uri;
  }
}

const _consoles = [
  'sony_playstation',
  'sony_playstation_2',
  'nintendo_nintendo_3ds',
  'rompacks_proper_romsets',
];

void main() {
  late _FakeStorage storage;
  late EsDeConfigurator configurator;

  setUp(() {
    storage = _FakeStorage();
    configurator = EsDeConfigurator(storage);
  });

  test('picking the ROMs folder points each console at its ES-DE folder', () async {
    storage.folder('content://ROMs', ['psx', 'ps2', 'n3ds', 'snes', 'gba']);

    final result = await configurator.configure('content://ROMs', _consoles);

    expect(result.romsFolderUri, 'content://ROMs');
    expect(result.consoleFolders, {
      'sony_playstation': 'content://ROMs/psx',
      'sony_playstation_2': 'content://ROMs/ps2',
      'nintendo_nintendo_3ds': 'content://ROMs/n3ds',
    });
    expect(result.createdFolders, isEmpty);
  });

  test('picking the ES-DE folder above ROMs works too', () async {
    storage.folder('content://ES-DE', ['ROMs', 'downloaded_media', 'gamelists']);
    storage.folder('content://ES-DE/ROMs', ['psx', 'ps2', 'n3ds']);

    final result = await configurator.configure('content://ES-DE', _consoles);

    expect(result.romsFolderUri, 'content://ES-DE/ROMs');
    expect(result.consoleFolders['sony_playstation'], 'content://ES-DE/ROMs/psx');
  });

  test('creates the folder for a supported console that is missing', () async {
    storage.folder('content://ROMs', ['psx', 'snes', 'gba']);

    final result = await configurator.configure('content://ROMs', _consoles);

    expect(result.createdFolders, containsAll(['ps2', 'n3ds']));
    expect(storage.created, containsAll(['content://ROMs/ps2', 'content://ROMs/n3ds']));
    expect(result.consoleFolders['sony_playstation_2'], 'content://ROMs/ps2');
  });

  test('leaves out consoles that have no ES-DE folder', () async {
    storage.folder('content://ROMs', ['psx', 'ps2', 'n3ds']);
    final result = await configurator.configure('content://ROMs', _consoles);
    expect(result.consoleFolders.containsKey('rompacks_proper_romsets'), isFalse);
  });

  test('matches folder names regardless of case', () async {
    storage.folder('content://ROMs', ['PSX', 'PS2', 'N3DS']);
    final result = await configurator.configure('content://ROMs', _consoles);
    expect(result.consoleFolders['sony_playstation'], 'content://ROMs/PSX');
    expect(result.createdFolders, isEmpty);
  });

  test('uses a regional folder name when the layout has that instead', () async {
    storage.folder('content://ROMs', ['megadrive', 'psx', 'snes']);
    final result = await configurator.configure('content://ROMs', ['sega_genesis']);
    expect(result.consoleFolders['sega_genesis'], 'content://ROMs/megadrive');
  });

  test('rejects a folder that is not an ES-DE layout, without creating anything', () async {
    storage.folder('content://Download', ['Telegram', 'Music'], files: ['game.iso']);

    await expectLater(
      configurator.configure('content://Download', _consoles),
      throwsA(isA<NotAnEsDeRomsFolderException>()),
    );
    expect(storage.created, isEmpty);
  });
}
