import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pixelvault/core/db/daos/catalog_repository.dart';
import 'package:pixelvault/core/db/daos/download_repository.dart';
import 'package:pixelvault/core/db/database.dart';
import 'package:pixelvault/core/download/download_failure.dart';
import 'package:pixelvault/core/download/download_manager.dart';
import 'package:pixelvault/core/download/download_progress_tracker.dart';
import 'package:pixelvault/core/download/download_status.dart';
import 'package:pixelvault/core/models/downloadable_file.dart';
import 'package:pixelvault/core/settings/settings_repository.dart';
import 'package:pixelvault/core/storage/saf_storage_helper.dart';
import 'package:pixelvault_torrent/pixelvault_torrent.dart';
import 'package:saf_stream/saf_stream.dart';
import 'package:saf_stream/saf_stream_platform_interface.dart'
    show SafNewFile, SafWriteStreamInfo;
import 'package:saf_util/saf_util_platform_interface.dart' show SafDocumentFile;
import 'package:shared_preferences/shared_preferences.dart';

class _MockTorrent extends Mock implements PixelvaultTorrent {}

class _MockSafStorage extends Mock implements SafStorageHelper {}

class _MockSafStream extends Mock implements SafStream {}

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.responder);
  final ResponseBody Function(RequestOptions options) responder;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(RequestOptions o, Stream<Uint8List>? s, Future<void>? c) async =>
      responder(o);
}

DownloadableFileWithTags _httpFile(int id, {String fileName = 'game.chd', int fileSize = 10}) {
  return DownloadableFileWithTags(
    id: id,
    name: 'Game $id',
    fileName: fileName,
    consoleId: 'sony_playstation',
    downloadUrl: 'https://example.com/game$id.chd',
    fileSize: fileSize,
    fileExtension: '.chd',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    // `writeChunk` takes a Uint8List, so mocktail needs a fallback before
    // `any()` can match it.
    registerFallbackValue(Uint8List(0));
  });

  late AppDatabase db;
  late DownloadRepository downloadRepo;
  late ProviderContainer container;
  late DownloadProgressTrackerNotifier tracker;
  late SettingsNotifier settingsNotifier;
  late _MockTorrent torrentPlugin;
  late _MockSafStorage safStorage;
  late _MockSafStream safStream;
  late Directory stagingDir;

  /// Stands in for the destination file the streaming writer creates, so
  /// tests can assert on the bytes that actually reached it.
  late List<int> destinationBytes;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase(NativeDatabase.memory());
    downloadRepo = DownloadRepository(db);
    container = ProviderContainer();
    tracker = container.read(downloadProgressTrackerProvider.notifier);
    settingsNotifier = container.read(settingsProvider.notifier);
    await container.read(settingsProvider.future);
    await settingsNotifier.setDownloadDirectory('content://tree/primary%3ARoms');

    torrentPlugin = _MockTorrent();
    safStorage = _MockSafStorage();
    safStream = _MockSafStream();
    when(() => torrentPlugin.progressStream)
        .thenAnswer((_) => const Stream<TorrentProgressEvent>.empty());
    when(() => safStorage.isValidTreeUri(any())).thenAnswer((_) async => true);
    when(() => safStorage.ensureDirectory(any(), any()))
        .thenAnswer((_) async => 'content://tree/primary%3ARoms/document/primary%3ARoms');
    when(() => safStream.pasteLocalFile(any(), any(), any(), any(), overwrite: any(named: 'overwrite')))
        .thenAnswer((_) async => SafNewFile(Uri.parse('content://file/1'), 'game.chd'));

    // Non-archive downloads now stream straight into the destination, so the
    // destination is what has to be modelled rather than a staging file.
    destinationBytes = [];
    when(() => safStream.startWriteStream(any(), any(), any(),
        overwrite: any(named: 'overwrite'), append: any(named: 'append'))).thenAnswer((inv) async {
      final append = inv.namedArguments[#append] as bool? ?? false;
      if (!append) destinationBytes = [];
      return SafWriteStreamInfo(
        'session-1',
        SafNewFile(Uri.parse('content://file/1'), 'game.chd'),
      );
    });
    when(() => safStream.writeChunk(any(), any())).thenAnswer((inv) async {
      destinationBytes.addAll(inv.positionalArguments[1] as Uint8List);
    });
    when(() => safStream.endWriteStream(any())).thenAnswer((_) async {});
    when(() => safStorage.findChild(any(), any())).thenAnswer((_) async => destinationBytes.isEmpty
        ? null
        : SafDocumentFile(
            uri: 'content://file/1',
            name: 'game.chd',
            isDir: false,
            length: destinationBytes.length,
            lastModified: 0,
          ));
    when(() => safStorage.deleteFile(any())).thenAnswer((_) async => destinationBytes = []);

    stagingDir = Directory.systemTemp.createTempSync('pv_integrity_');
  });

  tearDown(() async {
    // A download that is still retrying would otherwise touch the tracker
    // after its container is gone.
    await Future.delayed(const Duration(milliseconds: 50));
    container.dispose();
    await db.close();
    if (stagingDir.existsSync()) stagingDir.deleteSync(recursive: true);
  });

  DownloadManager buildManager(Dio dio) => DownloadManager(
        tracker: tracker,
        settings: settingsNotifier,
        catalog: CatalogRepository(db),
        downloads: downloadRepo,
        torrentPlugin: torrentPlugin,
        safStorage: safStorage,
        safStream: safStream,
        dio: dio,
        httpDownloadsDir: stagingDir,
      );

  group('HTTP download integrity', () {
    test(
      'a connection that drops mid-transfer fails instead of reporting success',
      () async {
        // The regression this pins down: `await for` over the response stream
        // ends *without throwing* when the socket closes early, so a
        // half-written file used to walk straight through the copy step and
        // be marked completed. That is why a .chd could "finish" and then be
        // unusable, and why the destination folder looked wrong.
        final dio = Dio()
          ..httpClientAdapter = _FakeAdapter((options) {
            // Declares 100 bytes, delivers 10, then closes.
            return ResponseBody(
              Stream.fromIterable([Uint8List.fromList(List.filled(10, 1))]),
              200,
              headers: {
                Headers.contentLengthHeader: ['100'],
              },
            );
          });

        final manager = buildManager(dio);
        await manager.startDownload(_httpFile(1, fileSize: 100));
        // 3 attempts, each with its own backoff, plus the 1s pre-run delay.
        await Future.delayed(const Duration(seconds: 8));

        final item = tracker.get(1);
        expect(item?.status, DownloadStatus.failed);
        expect(item?.failureReason, DownloadFailureReason.incomplete);
        // The truncated bytes are still at the destination for a resume to
        // build on, but the download is emphatically not reported as done.
        expect(item?.completedAt, isNull);
        expect(destinationBytes, isNotEmpty);
      },
      timeout: const Timeout(Duration(seconds: 30)),
    );

    test('a fully delivered response completes and records its destination', () async {
      final dio = Dio()
        ..httpClientAdapter = _FakeAdapter((options) {
          return ResponseBody(
            Stream.fromIterable([Uint8List.fromList(List.filled(10, 1))]),
            200,
            headers: {
              Headers.contentLengthHeader: ['10'],
            },
          );
        });

      final manager = buildManager(dio);
      await manager.startDownload(_httpFile(2, fileSize: 10));
      await Future.delayed(const Duration(milliseconds: 2500));

      final item = tracker.get(2);
      expect(item?.status, DownloadStatus.completed);
      // "Baixa e não dá para ver onde foi baixado" — the destination is now
      // part of the record.
      expect(item?.destinationLabel, isNotEmpty);
      expect(item?.savedFileName, 'game.chd');
      // Every byte went straight to the destination…
      expect(destinationBytes, hasLength(10));
      // …and internal storage was never used as a staging area, which is
      // what made multi-gigabyte downloads need twice the free space.
      expect(stagingDir.listSync(), isEmpty);
      verifyNever(
        () => safStream.pasteLocalFile(any(), any(), any(), any(), overwrite: any(named: 'overwrite')),
      );
    });

    test('a partially downloaded file is kept on disk so a retry can resume', () async {
      final dio = Dio()
        ..httpClientAdapter = _FakeAdapter((options) {
          return ResponseBody(
            Stream.fromIterable([Uint8List.fromList(List.filled(4, 1))]),
            200,
            headers: {
              Headers.contentLengthHeader: ['100'],
            },
          );
        });

      final manager = buildManager(dio);
      await manager.startDownload(_httpFile(3, fileSize: 100));
      await Future.delayed(const Duration(seconds: 8));

      expect(tracker.get(3)?.status, DownloadStatus.failed);
      // Losing these bytes on every hiccup is what forced a full
      // re-download; they must survive the failure so a retry can resume.
      expect(destinationBytes, isNotEmpty);
      expect(tracker.get(3)?.downloadedBytes, greaterThan(0));
    }, timeout: const Timeout(Duration(seconds: 30)));
  });

  group('resuming a streamed download', () {
    test('asks the server to resume and appends onto the destination file', () async {
      // Stands in for a previous session that got 5 of 10 bytes down before
      // the process died: the record remembers the byte count, and those
      // bytes are still sitting in the destination file.
      final record = await downloadRepo.create(_httpFile(30, fileSize: 10));
      await downloadRepo.update(record.copyWith(
        status: DownloadStatus.stopped,
        progress: 0.5,
        downloadedBytes: 5,
      ));
      destinationBytes = List<int>.filled(5, 65, growable: true);

      Map<String, dynamic>? capturedHeaders;
      final dio = Dio()
        ..httpClientAdapter = _FakeAdapter((options) {
          capturedHeaders = options.headers;
          return ResponseBody(
            Stream.fromIterable([Uint8List.fromList(List.filled(5, 66))]),
            206,
            headers: {
              'content-range': ['bytes 5-9/10'],
            },
          );
        });

      final manager = buildManager(dio);
      await manager.restore();
      await manager.retryDownload(30);
      await Future.delayed(const Duration(milliseconds: 2500));

      expect(capturedHeaders?['Range'], 'bytes=5-',
          reason: 'must ask the server to continue from the bytes already there');
      expect(destinationBytes, [...List.filled(5, 65), ...List.filled(5, 66)],
          reason: 'must append onto the destination, not restart it');
      expect(tracker.get(30)?.status, DownloadStatus.completed);
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('never appends onto a file this download did not write', () async {
      // The destination folder is the user's: a file with a matching name
      // may simply be a ROM they already had. A fresh download must
      // overwrite it rather than glue a partial transfer onto the end.
      destinationBytes = List<int>.filled(500, 65, growable: true);

      Map<String, dynamic>? capturedHeaders;
      final dio = Dio()
        ..httpClientAdapter = _FakeAdapter((options) {
          capturedHeaders = options.headers;
          return ResponseBody(
            Stream.fromIterable([Uint8List.fromList(List.filled(10, 66))]),
            200,
            headers: {
              Headers.contentLengthHeader: ['10'],
            },
          );
        });

      final manager = buildManager(dio);
      await manager.startDownload(_httpFile(31, fileSize: 10));
      await Future.delayed(const Duration(milliseconds: 2500));

      expect(capturedHeaders?.containsKey('Range'), isFalse);
      expect(destinationBytes, List.filled(10, 66));
      expect(tracker.get(31)?.status, DownloadStatus.completed);
    }, timeout: const Timeout(Duration(seconds: 30)));
  });

  group('persistence across a restart', () {
    test('an interrupted download comes back as a resumable queue entry', () async {
      final dio = Dio()
        ..httpClientAdapter = _FakeAdapter((options) {
          return ResponseBody(
            Stream.fromIterable([Uint8List.fromList(List.filled(4, 1))]),
            200,
            headers: {
              Headers.contentLengthHeader: ['100'],
            },
          );
        });

      // Simulate a process that died mid-download by writing the row
      // directly in the state the manager would have left it in.
      final record = await downloadRepo.create(_httpFile(4, fileSize: 100));
      await downloadRepo.update(record.copyWith(
        status: DownloadStatus.downloading,
        progress: 0.42,
        downloadedBytes: 42,
      ));

      // A fresh tracker + manager stands in for the next app launch.
      final freshContainer = ProviderContainer();
      addTearDown(freshContainer.dispose);
      final freshTracker = freshContainer.read(downloadProgressTrackerProvider.notifier);
      final freshSettings = freshContainer.read(settingsProvider.notifier);
      await freshContainer.read(settingsProvider.future);

      final manager = DownloadManager(
        tracker: freshTracker,
        settings: freshSettings,
        catalog: CatalogRepository(db),
        downloads: downloadRepo,
        torrentPlugin: torrentPlugin,
        safStorage: safStorage,
        safStream: safStream,
        dio: dio,
        httpDownloadsDir: stagingDir,
      );
      await manager.restore();

      final restored = freshTracker.get(4);
      expect(restored, isNotNull, reason: 'the queue must survive a restart');
      // Its worker is gone, so it comes back stopped — the state the UI
      // already renders with a retry/resume button.
      expect(restored!.status, DownloadStatus.stopped);
      expect(restored.progress, closeTo(0.42, 0.001));
      expect(restored.downloadedBytes, 42);
      expect(freshTracker.canRetryDownload(4), isTrue);
    });

    test('completed downloads persist as history', () async {
      final record = await downloadRepo.create(_httpFile(5));
      await downloadRepo.update(record.copyWith(
        status: DownloadStatus.completed,
        destinationLabel: 'primary:Roms/PS1',
        savedFileName: 'game.chd',
        completedAt: DateTime.now(),
      ));

      final history = await downloadRepo.getAll();
      expect(history, hasLength(1));
      expect(history.first.status, DownloadStatus.completed);
      expect(history.first.destinationLabel, 'primary:Roms/PS1');
      expect(history.first.savedFileName, 'game.chd');
    });

    test('clearHistory drops finished rows but keeps running ones', () async {
      final done = await downloadRepo.create(_httpFile(6));
      await downloadRepo.update(done.copyWith(status: DownloadStatus.completed));
      final running = await downloadRepo.create(_httpFile(7));
      await downloadRepo.update(running.copyWith(status: DownloadStatus.downloading));

      await downloadRepo.clearHistory();

      final remaining = await downloadRepo.getAll();
      expect(remaining, hasLength(1));
      expect(remaining.first.id, 7);
    });

    test('re-downloading the same file reuses its history row instead of duplicating it', () async {
      final dio = Dio()
        ..httpClientAdapter = _FakeAdapter((options) {
          return ResponseBody(
            Stream.fromIterable([Uint8List.fromList(List.filled(10, 1))]),
            200,
            headers: {
              Headers.contentLengthHeader: ['10'],
            },
          );
        });

      final manager = buildManager(dio);
      final file = _httpFile(20, fileSize: 10);

      await manager.startDownload(file);
      await Future.delayed(const Duration(milliseconds: 2500));
      expect(tracker.get(20)?.status, DownloadStatus.completed);
      final firstRecordId = tracker.get(20)?.recordId;

      await manager.startDownload(file);
      await Future.delayed(const Duration(milliseconds: 2500));

      expect(tracker.get(20)?.recordId, firstRecordId);
      expect(await downloadRepo.getAll(), hasLength(1),
          reason: 'the history holds one entry per file, not one per attempt');
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('history is keyed independently of the catalog, so a rescan cannot collide', () async {
      // Two different games that both ended up with catalog id 1 (SQLite
      // reuses autoincrement rowids after the bulk delete a rescan does).
      await downloadRepo.create(_httpFile(1, fileName: 'first.chd'));
      await downloadRepo.create(_httpFile(1, fileName: 'second.chd'));

      final all = await downloadRepo.getAll();
      expect(all, hasLength(2), reason: 'one must not overwrite the other');
      expect(all.map((d) => d.recordId).toSet(), hasLength(2));
    });
  });
}
