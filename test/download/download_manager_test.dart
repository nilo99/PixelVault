import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pixelvault/core/db/daos/catalog_repository.dart';
import 'package:pixelvault/core/db/database.dart';
import 'package:pixelvault/core/download/download_manager.dart';
import 'package:pixelvault/core/download/download_progress_tracker.dart';
import 'package:pixelvault/core/download/download_status.dart';
import 'package:pixelvault/core/models/downloadable_file.dart';
import 'package:pixelvault/core/settings/settings_repository.dart';
import 'package:pixelvault/core/storage/saf_storage_helper.dart';
import 'package:pixelvault_torrent/pixelvault_torrent.dart';
import 'package:saf_stream/saf_stream.dart';
import 'package:saf_stream/saf_stream_platform_interface.dart' show SafNewFile;
import 'package:saf_util/saf_util_platform_interface.dart' show SafDocumentFile;
import 'package:shared_preferences/shared_preferences.dart';

class MockPixelvaultTorrent extends Mock implements PixelvaultTorrent {}

class MockSafStorageHelper extends Mock implements SafStorageHelper {}

class MockSafStream extends Mock implements SafStream {}

/// Minimal `HttpClientAdapter` that hands every request to [responder] —
/// lets tests script exact status codes/headers/bodies without a real
/// network call, to exercise `DownloadManager`'s HTTP-resume logic.
class _FakeHttpAdapter implements HttpClientAdapter {
  _FakeHttpAdapter(this.responder);
  final ResponseBody Function(RequestOptions options) responder;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return responder(options);
  }
}

DownloadableFileWithTags _torrentFile(int id, {String fileName = 'game.zip', String fileExtension = '.zip'}) {
  return DownloadableFileWithTags(
    id: id,
    name: 'Game $id',
    fileName: fileName,
    consoleId: 'nintendo_gba',
    downloadUrl: 'magnet:?xt=urn:btih:abc$id',
    fileSize: 100,
    fileExtension: fileExtension,
    torrentFileIndex: 0,
    torrentMagnet: 'magnet:?xt=urn:btih:abc$id',
  );
}

DownloadableFileWithTags _httpFile(int id, {String fileName = 'game.zip', String fileExtension = '.zip', int fileSize = 10}) {
  return DownloadableFileWithTags(
    id: id,
    name: 'Game $id',
    fileName: fileName,
    consoleId: 'nintendo_gba',
    downloadUrl: 'https://example.com/game$id.zip',
    fileSize: fileSize,
    fileExtension: fileExtension,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late CatalogRepository catalog;
  late ProviderContainer container;
  late DownloadProgressTrackerNotifier tracker;
  late SettingsNotifier settingsNotifier;
  late MockPixelvaultTorrent torrentPlugin;
  late MockSafStorageHelper safStorage;
  late MockSafStream safStream;
  late StreamController<TorrentProgressEvent> progressController;
  late Directory httpDownloadsDir;
  late DownloadManager manager;

  setUpAll(() {
    registerFallbackValue(Uri());
  });

  TorrentProgressEvent completedEvent(int id) => TorrentProgressEvent(
        downloadId: '$id',
        fileName: 'game.zip',
        progress: 1,
        speedMBs: 0,
        downloadedBytes: 100,
        status: TorrentDownloadStatus.completed,
      );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase(NativeDatabase.memory());
    catalog = CatalogRepository(db);
    container = ProviderContainer();
    tracker = container.read(downloadProgressTrackerProvider.notifier);
    settingsNotifier = container.read(settingsProvider.notifier);
    await container.read(settingsProvider.future);

    torrentPlugin = MockPixelvaultTorrent();
    safStorage = MockSafStorageHelper();
    safStream = MockSafStream();
    progressController = StreamController<TorrentProgressEvent>.broadcast();
    when(() => torrentPlugin.progressStream).thenAnswer((_) => progressController.stream);
    when(() => safStorage.isValidTreeUri(any())).thenAnswer((_) async => true);

    httpDownloadsDir = Directory.systemTemp.createTempSync('pv_download_manager_test_');

    manager = DownloadManager(
      tracker: tracker,
      settings: settingsNotifier,
      catalog: catalog,
      torrentPlugin: torrentPlugin,
      safStorage: safStorage,
      safStream: safStream,
      httpDownloadsDir: httpDownloadsDir,
    );

    // Avoid accidental queuing unless a test explicitly wants concurrency=1.
    await settingsNotifier.setConcurrentDownloads(3);
    await settingsNotifier.setDownloadDirectory('content://tree/primary');
  });

  tearDown(() async {
    manager.dispose();
    await progressController.close();
    container.dispose();
    await db.close();
    if (httpDownloadsDir.existsSync()) httpDownloadsDir.deleteSync(recursive: true);
  });

  test(
    'regression: releasing a download queued under the OLD semaphore is not lost when '
    'concurrentDownloads changes mid-flight',
    () async {
      await settingsNotifier.setConcurrentDownloads(1);

      final startedIds = <String>[];
      final file1Gate = Completer<void>();
      final file3Gate = Completer<void>();

      when(() => torrentPlugin.startFileDownload(
            magnet: any(named: 'magnet'),
            fileIndex: any(named: 'fileIndex'),
            fileName: any(named: 'fileName'),
            downloadId: any(named: 'downloadId'),
          )).thenAnswer((invocation) async {
        final id = invocation.namedArguments[#downloadId] as String;
        startedIds.add(id);
        if (id == '1') await file1Gate.future;
        if (id == '3') await file3Gate.future;
      });
      when(() => torrentPlugin.finishFileDownload(
            magnet: any(named: 'magnet'),
            fileName: any(named: 'fileName'),
            downloadId: any(named: 'downloadId'),
            destDirUri: any(named: 'destDirUri'),
            subPath: any(named: 'subPath'),
            extract: any(named: 'extract'),
          )).thenAnswer((_) async => ['out.zip']);

      final file1 = _torrentFile(1);
      final file2 = _torrentFile(2);
      final file3 = _torrentFile(3);

      await manager.startDownload(file1);
      await manager.startDownload(file2); // queues behind file1 on the max=1 semaphore

      // Let file1 reach and block inside startFileDownload (past its 1s pre-delay).
      await Future.delayed(const Duration(milliseconds: 1300));
      expect(startedIds, ['1'], reason: 'file2 must still be queued, not started');

      // Change concurrency WHILE file1 still holds the OLD (max=1) semaphore's permit.
      await settingsNotifier.setConcurrentDownloads(2);

      // A third download forces `_run` to notice the setting changed and swap
      // in a brand-new semaphore instance — this is the exact moment the bug
      // used to corrupt things.
      await manager.startDownload(file3);
      await Future.delayed(const Duration(milliseconds: 1300));
      expect(startedIds, ['1', '3'], reason: 'file2 must still be queued on the OLD semaphore');

      // Finish file1: its `_run` must release the semaphore instance it
      // actually acquired (the OLD one), waking up file2 — not the new one
      // file3 is on.
      file1Gate.complete();
      progressController.add(completedEvent(1));

      // file2 still has its own 1s pre-delay to go through once unblocked.
      await Future.delayed(const Duration(milliseconds: 1400));
      expect(startedIds, containsAll(['1', '2', '3']));

      // Let the still-blocked file3 finish too, so nothing dangles into teardown.
      file3Gate.complete();
      progressController.add(completedEvent(3));
      await Future.delayed(const Duration(milliseconds: 300));
    },
  );

  test(
    'regression: retrying immediately after cancelling waits for the previous run to '
    'fully finish before starting again',
    () async {
      var startCount = 0;
      final finishGate = Completer<void>();

      when(() => torrentPlugin.startFileDownload(
            magnet: any(named: 'magnet'),
            fileIndex: any(named: 'fileIndex'),
            fileName: any(named: 'fileName'),
            downloadId: any(named: 'downloadId'),
          )).thenAnswer((_) async {
        startCount++;
      });
      when(() => torrentPlugin.cancelFileDownload(
            magnet: any(named: 'magnet'),
            downloadId: any(named: 'downloadId'),
          )).thenAnswer((_) async {});
      when(() => torrentPlugin.finishFileDownload(
            magnet: any(named: 'magnet'),
            fileName: any(named: 'fileName'),
            downloadId: any(named: 'downloadId'),
            destDirUri: any(named: 'destDirUri'),
            subPath: any(named: 'subPath'),
            extract: any(named: 'extract'),
          )).thenAnswer((_) async {
        await finishGate.future;
        return ['out.zip'];
      });

      final file = _torrentFile(1);
      await manager.startDownload(file);
      await Future.delayed(const Duration(milliseconds: 1300));

      // Native "completed" event moves the run into "copying", which calls
      // finishFileDownload — held open by finishGate to simulate a slow SAF copy.
      progressController.add(completedEvent(1));
      await Future.delayed(const Duration(milliseconds: 100));
      expect(startCount, 1);

      // Cancel then immediately retry while the first run is still stuck "copying".
      await manager.cancelDownload(1);
      unawaited(manager.retryDownload(1));

      await Future.delayed(const Duration(milliseconds: 1300));
      expect(startCount, 1, reason: 'the retry must not start a second native download yet');

      finishGate.complete();
      await Future.delayed(const Duration(milliseconds: 1300));
      expect(startCount, 2, reason: 'the retry proceeds only after the first run fully finished');
    },
  );

  test('a native completion event racing a manual cancel for the same id does not throw', () async {
    when(() => torrentPlugin.startFileDownload(
          magnet: any(named: 'magnet'),
          fileIndex: any(named: 'fileIndex'),
          fileName: any(named: 'fileName'),
          downloadId: any(named: 'downloadId'),
        )).thenAnswer((_) async {});
    when(() => torrentPlugin.cancelFileDownload(
          magnet: any(named: 'magnet'),
          downloadId: any(named: 'downloadId'),
        )).thenAnswer((_) async {});
    when(() => torrentPlugin.finishFileDownload(
          magnet: any(named: 'magnet'),
          fileName: any(named: 'fileName'),
          downloadId: any(named: 'downloadId'),
          destDirUri: any(named: 'destDirUri'),
          subPath: any(named: 'subPath'),
          extract: any(named: 'extract'),
        )).thenAnswer((_) async => ['out.zip']);

    final file = _torrentFile(1);
    await manager.startDownload(file);
    await Future.delayed(const Duration(milliseconds: 1300));

    progressController.add(completedEvent(1));
    await expectLater(manager.cancelDownload(1), completes);

    await Future.delayed(const Duration(milliseconds: 300));
  });

  group('deleteDownload(deleteFile: true)', () {
    test('deletes the written file for a plain (non-extracted) download', () async {
      await settingsNotifier.setAutoUnzip(false);
      when(() => torrentPlugin.startFileDownload(
            magnet: any(named: 'magnet'),
            fileIndex: any(named: 'fileIndex'),
            fileName: any(named: 'fileName'),
            downloadId: any(named: 'downloadId'),
          )).thenThrow(Exception('not needed for this test'));
      when(() => torrentPlugin.cancelFileDownload(
            magnet: any(named: 'magnet'),
            downloadId: any(named: 'downloadId'),
          )).thenAnswer((_) async {});
      when(() => safStorage.isValidTreeUri(any())).thenAnswer((_) async => true);
      final doc = SafDocumentFile(uri: 'content://file/1', name: 'game.zip', isDir: false, length: 100, lastModified: 0);
      when(() => safStorage.findChild(any(), any())).thenAnswer((_) async => doc);
      when(() => safStorage.deleteFile(any())).thenAnswer((_) async {});

      final file = _torrentFile(1, fileName: 'game.zip', fileExtension: '.zip');
      await manager.startDownload(file);
      await manager.deleteDownload(1, deleteFile: true);

      verify(() => safStorage.findChild('content://tree/primary', 'game.zip')).called(1);
      verify(() => safStorage.deleteFile('content://file/1')).called(1);

      await Future.delayed(const Duration(milliseconds: 1300));
    });

    test('does not attempt to delete a file that was auto-extracted', () async {
      await settingsNotifier.setAutoUnzip(true);
      when(() => torrentPlugin.startFileDownload(
            magnet: any(named: 'magnet'),
            fileIndex: any(named: 'fileIndex'),
            fileName: any(named: 'fileName'),
            downloadId: any(named: 'downloadId'),
          )).thenThrow(Exception('not needed for this test'));
      when(() => torrentPlugin.cancelFileDownload(
            magnet: any(named: 'magnet'),
            downloadId: any(named: 'downloadId'),
          )).thenAnswer((_) async {});

      final file = _torrentFile(1, fileName: 'game.zip', fileExtension: '.zip');
      await manager.startDownload(file);
      await manager.deleteDownload(1, deleteFile: true);

      verifyNever(() => safStorage.findChild(any(), any()));
      verifyNever(() => safStorage.deleteFile(any()));

      await Future.delayed(const Duration(milliseconds: 1300));
    });
  });

  test('a torrent download reaches DownloadStatus.completed', () async {
    when(() => torrentPlugin.startFileDownload(
          magnet: any(named: 'magnet'),
          fileIndex: any(named: 'fileIndex'),
          fileName: any(named: 'fileName'),
          downloadId: any(named: 'downloadId'),
        )).thenAnswer((_) async {});
    when(() => torrentPlugin.finishFileDownload(
          magnet: any(named: 'magnet'),
          fileName: any(named: 'fileName'),
          downloadId: any(named: 'downloadId'),
          destDirUri: any(named: 'destDirUri'),
          subPath: any(named: 'subPath'),
          extract: any(named: 'extract'),
        )).thenAnswer((_) async => ['game.zip']);

    final file = _torrentFile(1);
    await manager.startDownload(file);
    await Future.delayed(const Duration(milliseconds: 1300));

    progressController.add(completedEvent(1));
    await Future.delayed(const Duration(milliseconds: 300));

    expect(tracker.get(1)?.status, DownloadStatus.completed);
  });

  test('resumes an HTTP download from bytes already present in a partial local file', () async {
    await settingsNotifier.setAutoUnzip(false); // force the plain-copy branch, not extraction
    final localFile = File('${httpDownloadsDir.path}/1_game.zip');
    await localFile.writeAsBytes(List.filled(5, 65)); // 5 bytes already on disk

    Map<String, dynamic>? capturedHeaders;
    final adapter = _FakeHttpAdapter((options) {
      capturedHeaders = options.headers;
      final controller = StreamController<Uint8List>();
      controller.add(Uint8List.fromList(List.filled(5, 66))); // the remaining 5 bytes
      controller.close();
      return ResponseBody(
        controller.stream,
        206,
        headers: {
          'content-range': ['bytes 5-9/10'],
        },
      );
    });
    final dio = Dio()..httpClientAdapter = adapter;

    List<int>? capturedFileBytes;
    when(() => safStream.pasteLocalFile(any(), any(), any(), any(), overwrite: any(named: 'overwrite')))
        .thenAnswer((invocation) async {
      final srcPath = invocation.positionalArguments[0] as String;
      capturedFileBytes = await File(srcPath).readAsBytes();
      return SafNewFile(Uri.parse('content://file/1'), 'game.zip');
    });
    when(() => safStorage.isValidTreeUri(any())).thenAnswer((_) async => true);
    when(() => safStorage.ensureDirectory(any(), any())).thenAnswer((_) async => 'content://tree/primary');

    final resumeManager = DownloadManager(
      tracker: tracker,
      settings: settingsNotifier,
      catalog: catalog,
      torrentPlugin: torrentPlugin,
      safStorage: safStorage,
      safStream: safStream,
      dio: dio,
      httpDownloadsDir: httpDownloadsDir,
    );

    final file = _httpFile(1, fileName: 'game.zip', fileSize: 10);
    await resumeManager.startDownload(file);
    await Future.delayed(const Duration(milliseconds: 1300));

    expect(capturedHeaders?['Range'], 'bytes=5-', reason: 'must ask the server to resume from the existing 5 bytes');
    expect(capturedFileBytes, [...List.filled(5, 65), ...List.filled(5, 66)], reason: 'must append, not truncate');
    expect(tracker.get(1)?.status, DownloadStatus.completed);

    resumeManager.dispose();
  });
}
