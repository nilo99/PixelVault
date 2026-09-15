import 'package:saf_util/saf_util.dart';
import 'package:saf_util/saf_util_platform_interface.dart' show SafDocumentFile;

import '../settings/settings_repository.dart';
import 'esde_configurator.dart';
import 'esde_folders.dart';

/// [EsDeStorage] backed by the Storage Access Framework.
class SafEsDeStorage implements EsDeStorage {
  SafEsDeStorage([SafUtil? saf]) : _saf = saf ?? SafUtil();

  final SafUtil _saf;

  @override
  Future<List<SafDocumentFile>> list(String uri) => _saf.list(uri);

  @override
  Future<String> createFolder(String parentUri, String name) async {
    final created = await _saf.mkdirp(parentUri, [name]);
    return created.uri;
  }
}

/// Opens the system folder picker and returns the chosen folder's URI, or
/// `null` when the picker was dismissed.
typedef DirectoryPicker = Future<String?> Function();

/// Asks for the ES-DE ROMs folder and points every console ES-DE knows at
/// its own subfolder there (`psx`, `ps2`, `n3ds`…), so downloads land where
/// ES-DE already looks for them.
class EsDeSetupService {
  EsDeSetupService({
    required this.pickDirectory,
    required this.storage,
    required this.settings,
  });

  final DirectoryPicker pickDirectory;
  final EsDeStorage storage;
  final SettingsNotifier settings;

  /// Runs the whole setup. Returns `null` when the user closed the picker.
  ///
  /// Throws [NotAnEsDeRomsFolderException] when the chosen folder is not an
  /// ES-DE layout; nothing is saved in that case.
  ///
  /// Every console with an ES-DE folder is configured, not only the ones in
  /// the catalog right now: on a first run the catalog may not be seeded yet.
  Future<EsDeSetupResult?> run() async {
    final picked = await pickDirectory();
    if (picked == null || picked.isEmpty) return null;

    final result = await EsDeConfigurator(storage).configure(picked, EsDeFolders.byConsole.keys);
    await settings.setConsoleDownloadDirectories(result.consoleFolders);
    // Consoles ES-DE has no folder for (the rom packs) still need somewhere
    // to go, or their downloads would fail for want of a destination.
    if (settings.current.downloadDirectory.isEmpty) {
      await settings.setDownloadDirectory(result.romsFolderUri);
    }
    return result;
  }
}
