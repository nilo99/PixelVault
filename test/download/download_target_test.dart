import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pixelvault/core/download/download_target.dart';
import 'package:pixelvault/core/storage/saf_storage_helper.dart';
import 'package:saf_stream/saf_stream.dart';
import 'package:saf_stream/saf_stream_platform_interface.dart'
    show SafNewFile, SafWriteStreamInfo;
import 'package:saf_util/saf_util_platform_interface.dart' show SafDocumentFile;

class _MockSafStream extends Mock implements SafStream {}

class _MockSafStorage extends Mock implements SafStorageHelper {}

void main() {
  setUpAll(() {
    registerFallbackValue(Uint8List(0));
  });

  group('SafDownloadTarget', () {
    late _MockSafStream safStream;
    late _MockSafStorage safStorage;
    late SafDownloadTarget target;
    late List<Uint8List> written;

    setUp(() {
      safStream = _MockSafStream();
      safStorage = _MockSafStorage();
      written = [];

      when(() => safStream.startWriteStream(any(), any(), any(),
              overwrite: any(named: 'overwrite'), append: any(named: 'append')))
          .thenAnswer((_) async => SafWriteStreamInfo(
                'session-1',
                SafNewFile(Uri.parse('content://file/1'), 'game.chd'),
              ));
      when(() => safStream.writeChunk(any(), any())).thenAnswer((invocation) async {
        written.add(invocation.positionalArguments[1] as Uint8List);
      });
      when(() => safStream.endWriteStream(any())).thenAnswer((_) async {});

      target = SafDownloadTarget(
        safStream: safStream,
        safStorage: safStorage,
        dirUri: 'content://tree/roms',
        fileName: 'game.chd',
      );
    });

    test('reports 0 existing bytes when the destination has no such file', () async {
      when(() => safStorage.findChild(any(), any())).thenAnswer((_) async => null);
      expect(await target.existingBytes(), 0);
    });

    test('reports the destination file length so a retry can resume', () async {
      when(() => safStorage.findChild(any(), any())).thenAnswer((_) async => SafDocumentFile(
            uri: 'content://file/1',
            name: 'game.chd',
            isDir: false,
            length: 4096,
            lastModified: 0,
          ));
      expect(await target.existingBytes(), 4096);
    });

    test('opens in append mode only when resuming', () async {
      await target.open(append: true);
      verify(() => safStream.startWriteStream(
            'content://tree/roms',
            'game.chd',
            any(),
            overwrite: false,
            append: true,
          )).called(1);

      await target.open(append: false);
      verify(() => safStream.startWriteStream(
            'content://tree/roms',
            'game.chd',
            any(),
            overwrite: true,
            append: false,
          )).called(1);
    });

    test('coalesces small chunks instead of one channel call each', () async {
      final sink = await target.open(append: false);
      // 16 chunks of 64 KiB = 1 MiB, which is exactly the flush threshold.
      for (var i = 0; i < 16; i++) {
        await sink.add(Uint8List(64 * 1024));
      }
      // A multi-gigabyte file at one call per socket chunk would be six
      // figures of platform round trips; this must be a single write.
      expect(written, hasLength(1));
      expect(written.single.length, 1024 * 1024);
    });

    test('flushes the tail on close, so the end of the file is not lost', () async {
      final sink = await target.open(append: false);
      await sink.add(Uint8List(1000)); // well under the flush threshold
      expect(written, isEmpty);

      await sink.close();

      expect(written, hasLength(1));
      expect(written.single.length, 1000);
      verify(() => safStream.endWriteStream('session-1')).called(1);
    });

    test('close is idempotent', () async {
      final sink = await target.open(append: false);
      await sink.add(Uint8List(10));
      await sink.close();
      await sink.close();
      verify(() => safStream.endWriteStream('session-1')).called(1);
    });

    test('discard removes the partial file from the destination', () async {
      when(() => safStorage.findChild(any(), any())).thenAnswer((_) async => SafDocumentFile(
            uri: 'content://file/1',
            name: 'game.chd',
            isDir: false,
            length: 10,
            lastModified: 0,
          ));
      when(() => safStorage.deleteFile(any())).thenAnswer((_) async {});

      await target.discard();

      verify(() => safStorage.deleteFile('content://file/1')).called(1);
    });

    test('discard is a no-op when nothing was written', () async {
      when(() => safStorage.findChild(any(), any())).thenAnswer((_) async => null);
      await target.discard();
      verifyNever(() => safStorage.deleteFile(any()));
    });
  });

  group('LocalFileDownloadTarget', () {
    late Directory dir;

    setUp(() => dir = Directory.systemTemp.createTempSync('pv_target_'));
    tearDown(() {
      if (dir.existsSync()) dir.deleteSync(recursive: true);
    });

    test('appends when resuming and truncates when not', () async {
      final file = File('${dir.path}/game.zip');
      final target = LocalFileDownloadTarget(file);

      var sink = await target.open(append: false);
      await sink.add([1, 2, 3, 4]);
      await sink.close();
      expect(await target.existingBytes(), 4);

      sink = await target.open(append: true);
      await sink.add([5, 6]);
      await sink.close();
      expect(await target.existingBytes(), 6);

      // A server that ignored the Range header must not have its bytes
      // appended onto the old ones.
      sink = await target.open(append: false);
      await sink.add([9]);
      await sink.close();
      expect(await target.existingBytes(), 1);
    });

    test('creates missing parent directories', () async {
      final file = File('${dir.path}/nested/deeper/game.zip');
      final target = LocalFileDownloadTarget(file);
      final sink = await target.open(append: false);
      await sink.add([1]);
      await sink.close();
      expect(file.existsSync(), isTrue);
    });

    test('discard removes the staged file', () async {
      final file = File('${dir.path}/game.zip')..writeAsBytesSync([1, 2, 3]);
      await LocalFileDownloadTarget(file).discard();
      expect(file.existsSync(), isFalse);
    });
  });
}
