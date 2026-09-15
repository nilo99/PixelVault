import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixelvault/core/settings/settings_repository.dart';
import 'package:pixelvault/core/storage/esde_configurator.dart';
import 'package:pixelvault/core/storage/esde_setup_service.dart';
import 'package:saf_util/saf_util_platform_interface.dart' show SafDocumentFile;
import 'package:shared_preferences/shared_preferences.dart';

/// An in-memory folder tree keyed by URI.
class _FakeStorage implements EsDeStorage {
  final tree = <String, List<SafDocumentFile>>{};

  void folder(String uri, List<String> childFolders) {
    tree[uri] = [
      for (final name in childFolders)
        SafDocumentFile(uri: '$uri/$name', name: name, isDir: true, length: 0, lastModified: 0),
    ];
  }

  @override
  Future<List<SafDocumentFile>> list(String uri) async => tree[uri] ?? const [];

  @override
  Future<String> createFolder(String parentUri, String name) async {
    final uri = '$parentUri/$name';
    tree[parentUri] = [
      ...?tree[parentUri],
      SafDocumentFile(uri: uri, name: name, isDir: true, length: 0, lastModified: 0),
    ];
    return uri;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;
  late SettingsNotifier settings;
  late _FakeStorage storage;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    container = ProviderContainer();
    await container.read(settingsProvider.future);
    settings = container.read(settingsProvider.notifier);
    storage = _FakeStorage();
  });

  tearDown(() => container.dispose());

  EsDeSetupService serviceFor(String? picked) => EsDeSetupService(
        pickDirectory: () async => picked,
        storage: storage,
        settings: settings,
      );

  test('points every console ES-DE has a folder for at that folder', () async {
    storage.folder('content://ROMs', ['psx', 'ps2', 'psp', 'n3ds', 'gba', 'snes']);

    final result = await serviceFor('content://ROMs').run();

    expect(result, isNotNull);
    final folders = settings.current.consoleDownloadDirectories;
    expect(folders['sony_playstation'], 'content://ROMs/psx');
    expect(folders['sony_playstation_2'], 'content://ROMs/ps2');
    expect(folders['nintendo_nintendo_3ds'], 'content://ROMs/n3ds');
    expect(folders.containsKey('rompacks_proper_romsets'), isFalse);
  });

  test('without a main folder, the ROMs folder becomes it, so rom packs still have a destination', () async {
    storage.folder('content://ROMs', ['psx', 'ps2', 'n3ds']);

    await serviceFor('content://ROMs').run();

    expect(settings.current.downloadDirectory, 'content://ROMs');
  });

  test('keeps a main folder the user had already chosen', () async {
    storage.folder('content://ROMs', ['psx', 'ps2', 'n3ds']);
    await settings.setDownloadDirectory('content://Downloads');

    await serviceFor('content://ROMs').run();

    expect(settings.current.downloadDirectory, 'content://Downloads');
  });

  test('leaves the folder of a console ES-DE has no folder for alone', () async {
    storage.folder('content://ROMs', ['psx', 'ps2', 'n3ds']);
    await settings.setConsoleDownloadDirectory('rompacks_proper_romsets', 'content://Packs');

    await serviceFor('content://ROMs').run();

    expect(settings.current.consoleDownloadDirectories['rompacks_proper_romsets'], 'content://Packs');
  });

  test('closing the picker changes nothing', () async {
    final result = await serviceFor(null).run();

    expect(result, isNull);
    expect(settings.current.consoleDownloadDirectories, isEmpty);
    expect(settings.current.downloadDirectory, isEmpty);
  });

  test('a folder that is not an ES-DE layout saves nothing', () async {
    storage.folder('content://Download', ['Telegram', 'Music']);

    await expectLater(
      serviceFor('content://Download').run(),
      throwsA(isA<NotAnEsDeRomsFolderException>()),
    );
    expect(settings.current.consoleDownloadDirectories, isEmpty);
    expect(settings.current.downloadDirectory, isEmpty);
  });
}
