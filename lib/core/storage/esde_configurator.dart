import 'package:saf_util/saf_util_platform_interface.dart' show SafDocumentFile;

import 'esde_folders.dart';

/// The folder operations ES-DE setup needs. The app backs this with
/// `SafUtil`; tests use a fake.
abstract interface class EsDeStorage {
  Future<List<SafDocumentFile>> list(String uri);

  /// Creates [name] inside [parentUri] and returns the new folder's URI.
  Future<String> createFolder(String parentUri, String name);
}

/// What [EsDeConfigurator.configure] worked out.
class EsDeSetupResult {
  const EsDeSetupResult({
    required this.romsFolderUri,
    required this.consoleFolders,
    required this.createdFolders,
  });

  /// The ES-DE `ROMs` folder that was used.
  final String romsFolderUri;

  /// Console id → the folder to download that console's games into.
  final Map<String, String> consoleFolders;

  /// ES-DE folder names that did not exist yet and were created.
  final List<String> createdFolders;
}

/// The folder the user picked is not an ES-DE ROMs folder, nor one containing it.
class NotAnEsDeRomsFolderException implements Exception {
  const NotAnEsDeRomsFolderException();
}

/// Points each supported console at its folder inside an existing ES-DE
/// layout, so downloads land exactly where ES-DE looks for them.
class EsDeConfigurator {
  const EsDeConfigurator(this._storage);

  final EsDeStorage _storage;

  /// Resolves a download folder for each of [consoleIds] under [pickedUri].
  ///
  /// The user may pick the `ROMs` folder itself or the ES-DE folder above it;
  /// both work. A console whose folder is missing gets it created — ES-DE
  /// expects every system folder to exist anyway. Consoles with no ES-DE
  /// equivalent (rom packs) are left out.
  Future<EsDeSetupResult> configure(String pickedUri, Iterable<String> consoleIds) async {
    var romsUri = pickedUri;
    var children = await _storage.list(pickedUri);

    if (!EsDeFolders.looksLikeRomsFolder(_folderNames(children))) {
      final roms = children.where((c) => c.isDir && c.name.toLowerCase() == 'roms').firstOrNull;
      if (roms == null) throw const NotAnEsDeRomsFolderException();
      romsUri = roms.uri;
      children = await _storage.list(romsUri);
      if (!EsDeFolders.looksLikeRomsFolder(_folderNames(children))) {
        throw const NotAnEsDeRomsFolderException();
      }
    }

    final folderUris = {
      for (final child in children)
        if (child.isDir) child.name: child.uri,
    };
    final consoleFolders = <String, String>{};
    final created = <String>[];

    for (final consoleId in consoleIds) {
      final existing = EsDeFolders.existingFolderFor(consoleId, folderUris.keys);
      if (existing != null) {
        consoleFolders[consoleId] = folderUris[existing]!;
        continue;
      }
      final primary = EsDeFolders.primaryFolderFor(consoleId);
      if (primary == null) continue;
      final uri = await _storage.createFolder(romsUri, primary);
      folderUris[primary] = uri;
      consoleFolders[consoleId] = uri;
      created.add(primary);
    }

    return EsDeSetupResult(
      romsFolderUri: romsUri,
      consoleFolders: consoleFolders,
      createdFolders: created,
    );
  }

  static Iterable<String> _folderNames(List<SafDocumentFile> children) =>
      children.where((c) => c.isDir).map((c) => c.name);
}
