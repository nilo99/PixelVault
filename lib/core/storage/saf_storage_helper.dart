import 'package:saf_util/saf_util.dart';
import 'package:saf_util/saf_util_platform_interface.dart' show SafDocumentFile;

/// Port of the SAF operations `StorageHelper`/`DownloadFileManager` used
/// (directory creation, validity check) — file writing itself goes through
/// `saf_stream`'s chunked write session, used directly in `download_manager.dart`.
class SafStorageHelper {
  final _safUtil = SafUtil();

  Future<bool> isValidTreeUri(String uriString) async {
    if (uriString.isEmpty) return false;
    try {
      final doc = await _safUtil.stat(uriString, true);
      return doc != null;
    } catch (_) {
      return false;
    }
  }

  /// Ensures `treeUri/subPath` exists (creating missing segments) and
  /// returns its URI. Empty [subPath] returns [treeUri] unchanged.
  Future<String> ensureDirectory(String treeUri, String subPath) async {
    final parts = subPath.split('/').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return treeUri;
    final dir = await _safUtil.mkdirp(treeUri, parts);
    return dir.uri;
  }

  Future<void> deleteFile(String uri) => _safUtil.delete(uri, false);

  Future<SafDocumentFile?> findChild(String dirUri, String fileName) {
    return _safUtil.child(dirUri, [fileName]);
  }
}

/// A SAF location split into the parts the UI needs to describe it.
class SafLocation {
  const SafLocation({required this.volume, required this.path});

  /// The storage volume id: `primary` for internal storage, otherwise the
  /// SD card's UUID (e.g. `1A2B-3C4D`).
  final String volume;

  /// Folder path inside that volume, e.g. `Roms/GBA`. Empty for the volume root.
  final String path;

  bool get isPrimary => volume == 'primary';
  bool get isEmpty => volume.isEmpty && path.isEmpty;
}

/// Turns an opaque SAF tree/document URI into something a person can read.
///
/// A download used to record nothing about where it went, so the Downloads
/// screen could only say "completed" — the user had to go hunting through
/// the file manager to find out whether anything had actually landed. The
/// URI itself (`content://com.android.externalstorage.documents/tree/
/// primary%3ARoms/document/primary%3ARoms%2FGBA`) is unreadable, so it gets
/// decoded down to `primary` + `Roms/GBA` and the UI localizes the volume.
abstract final class SafPathLabel {
  static SafLocation parse(String uri) {
    if (uri.isEmpty) return const SafLocation(volume: '', path: '');
    try {
      final decoded = Uri.decodeFull(uri);
      // The `/document/` segment reflects the subfolder actually written to;
      // `/tree/` is only the granted root, so prefer document when present.
      const documentMarker = '/document/';
      const treeMarker = '/tree/';
      final marker = decoded.contains(documentMarker) ? documentMarker : treeMarker;
      final index = decoded.lastIndexOf(marker);
      if (index == -1) return const SafLocation(volume: '', path: '');

      final id = decoded.substring(index + marker.length);
      final colon = id.indexOf(':');
      final volume = colon == -1 ? '' : id.substring(0, colon);
      final path = (colon == -1 ? id : id.substring(colon + 1))
          .split('/')
          .where((s) => s.isNotEmpty)
          .join('/');
      return SafLocation(volume: volume, path: path);
    } catch (_) {
      return const SafLocation(volume: '', path: '');
    }
  }

  /// Compact `volume:path` form persisted on the download row; the UI parses
  /// it back with [parse] semantics via [fromStored].
  static String store(String uri) {
    final location = parse(uri);
    if (location.isEmpty) return '';
    return '${location.volume}:${location.path}';
  }

  static SafLocation fromStored(String stored) {
    if (stored.isEmpty) return const SafLocation(volume: '', path: '');
    final colon = stored.indexOf(':');
    if (colon == -1) return SafLocation(volume: '', path: stored);
    return SafLocation(volume: stored.substring(0, colon), path: stored.substring(colon + 1));
  }
}

/// Ports Milou's filename sanitization + relative-path resolution rules used
/// when deciding where a file should land (root vs per-console subfolder).
abstract final class DownloadPathResolver {
  static final _illegalFolderChars = RegExp(r'[<>:"/|?*]');
  static final _repeatedSpaces = RegExp(r'\s{2,}');

  static String sanitizeFolderName(String name) {
    return name.replaceAll(_illegalFolderChars, '').trim().replaceAll(_repeatedSpaces, ' ');
  }

  static String decodeUrlEncodedFileName(String fileName) {
    try {
      return Uri.decodeFull(fileName);
    } catch (_) {
      return fileName;
    }
  }
}
