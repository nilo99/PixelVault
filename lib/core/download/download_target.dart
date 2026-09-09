import 'dart:io';
import 'dart:typed_data';

import 'package:saf_stream/saf_stream.dart';

import '../storage/saf_storage_helper.dart';

/// Where a download's bytes go while it runs.
///
/// A download used to be written to internal storage in full and only then
/// copied to the destination, so an 8 GB disc image needed 8 GB free
/// *internally* on top of the space it took at the destination — and the
/// staging directory was the OS cache, which Android empties under storage
/// pressure, frequently mid-download. On a phone with a big SD card and a
/// nearly-full internal volume that is a download that dies with no message,
/// which is what large `.chd`/`.iso` files hit and small ROMs never did.
///
/// [SafDownloadTarget] removes the intermediate copy entirely by streaming
/// the response straight into the destination file. [LocalFileDownloadTarget]
/// is still used for archives, because 7-Zip-JBinding needs a seekable local
/// file to extract from — there is no way around staging those.
abstract class DownloadTarget {
  /// Bytes already written by a previous attempt, so the request can ask the
  /// server to resume from there.
  Future<int> existingBytes();

  /// Opens the sink for writing. [append] is true only when the server
  /// actually answered `206 Partial Content`; a `200` means it ignored the
  /// Range header and is resending from byte 0, so the previous bytes must
  /// be thrown away rather than appended to.
  Future<ByteSink> open({required bool append});

  /// Removes whatever partial output exists.
  Future<void> discard();

  /// A human-facing description of the file's final location, if known.
  String get destinationUri;

  /// Whether bytes already sitting at this target may only be resumed onto
  /// once *this* download is known to have written some.
  ///
  /// A staging file lives in a private directory under a name keyed by the
  /// download id, so anything found there was certainly produced by this
  /// download and can always be resumed. The destination folder is the
  /// user's: a file with a matching name may simply be a ROM they already
  /// had, and appending a partial transfer onto it would corrupt it.
  bool get requiresPriorWriteToResume;
}

/// A write in progress. Every implementation must tolerate [close] being
/// called more than once.
abstract class ByteSink {
  Future<void> add(List<int> chunk);
  Future<void> close();
}

/// Stages to a local file. Used only when the download has to be extracted
/// afterwards.
class LocalFileDownloadTarget implements DownloadTarget {
  LocalFileDownloadTarget(this.file);

  final File file;

  @override
  String get destinationUri => '';

  @override
  bool get requiresPriorWriteToResume => false;

  @override
  Future<int> existingBytes() async => await file.exists() ? await file.length() : 0;

  @override
  Future<ByteSink> open({required bool append}) async {
    await file.parent.create(recursive: true);
    return _IoSink(file.openWrite(mode: append ? FileMode.append : FileMode.write));
  }

  @override
  Future<void> discard() async {
    if (await file.exists()) await file.delete();
  }
}

class _IoSink implements ByteSink {
  _IoSink(this._sink);
  final IOSink _sink;
  var _closed = false;

  @override
  Future<void> add(List<int> chunk) async => _sink.add(chunk);

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    await _sink.close();
  }
}

/// Streams straight into the SAF destination — no internal copy at any point.
class SafDownloadTarget implements DownloadTarget {
  // Private initializing formals: callers still pass `safStream:`,
  // `safStorage:`, `dirUri:` and `fileName:` — Dart drops the underscore for
  // the parameter name — while the fields stay private to this class.
  SafDownloadTarget({
    required this._safStream,
    required this._safStorage,
    required this._dirUri,
    required this._fileName,
    this.mimeType = 'application/octet-stream',
  });

  final SafStream _safStream;
  final SafStorageHelper _safStorage;
  final String _dirUri;
  final String _fileName;
  final String mimeType;

  @override
  String get destinationUri => _dirUri;

  @override
  bool get requiresPriorWriteToResume => true;

  @override
  Future<int> existingBytes() async {
    final doc = await _safStorage.findChild(_dirUri, _fileName);
    return doc?.length ?? 0;
  }

  @override
  Future<ByteSink> open({required bool append}) async {
    final info = await _safStream.startWriteStream(
      _dirUri,
      _fileName,
      mimeType,
      overwrite: !append,
      append: append,
    );
    return _SafSink(_safStream, info.session);
  }

  @override
  Future<void> discard() async {
    final doc = await _safStorage.findChild(_dirUri, _fileName);
    if (doc != null) await _safStorage.deleteFile(doc.uri);
  }
}

class _SafSink implements ByteSink {
  _SafSink(this._safStream, this._session);

  final SafStream _safStream;
  final String _session;
  final _buffer = BytesBuilder(copy: false);
  var _closed = false;

  /// Chunks arrive from `dio` at whatever size the socket produced (often
  /// 8–64 KB). Forwarding each one individually would mean six figures of
  /// platform-channel round trips for a multi-gigabyte file, so they are
  /// coalesced into 1 MiB writes first.
  static const _flushThreshold = 1024 * 1024;

  @override
  Future<void> add(List<int> chunk) async {
    _buffer.add(chunk);
    if (_buffer.length >= _flushThreshold) await _flush();
  }

  Future<void> _flush() async {
    if (_buffer.isEmpty) return;
    await _safStream.writeChunk(_session, _buffer.takeBytes());
  }

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    // Flush before ending the session, otherwise the tail of the file — up
    // to one buffer's worth — is silently dropped.
    await _flush();
    await _safStream.endWriteStream(_session);
  }
}
