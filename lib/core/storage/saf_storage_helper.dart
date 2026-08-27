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
