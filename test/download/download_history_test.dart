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
import 'package:pixelvault/core/download/download_item.dart';
import 'package:pixelvault/core/download/download_manager.dart';
import 'package:pixelvault/core/download/download_progress_tracker.dart';
import 'package:pixelvault/core/download/download_status.dart';
import 'package:pixelvault/core/models/downloadable_file.dart';
import 'package:pixelvault/core/settings/settings_repository.dart';
import 'package:pixelvault/core/storage/saf_storage_helper.dart';
import 'package:pixelvault_torrent/pixelvault_torrent.dart';
import 'package:saf_stream/saf_stream.dart';
import 'package:saf_stream/saf_stream_platform_interface.dart' show SafNewFile, SafWriteStreamInfo;
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
  Future<ResponseBody> fetch(RequestOptions o, Stream<Uint8List>? s, Future<void>? c) async => responder(o);
}

DownloadableFileWithTags _file({
  String fileName = 'God of War II (USA).chd',
  String extension = '.chd',
  int size = 10,
}) {
  return DownloadableFileWithTags(
    id: 1,
    name: 'God of War II',
    fileName: fileName,
    consoleId: 'sony_playstation_2',
    downloadUrl: 'https://example.com/$fileName',
    fileSize: size,
    fileExtension: extension,
  );
}

ResponseBody _body(int bytes) => ResponseBody(
      Stream.fromIterable([Uint8List.fromList(List.filled(bytes, 7))]),
      200,
      headers: {
        Headers.contentLengthHeader: ['$bytes'],
      },
    );

/// Sends half of a 10-byte file, then waits for [gate] before sending the rest.
ResponseBody _gatedBody(Completer<void> gate) {
  final controller = StreamController<Uint8List>();
  () async {
    controller.add(Uint8List.fromList(List.filled(5, 7)));
    await gate.future;
    controller.add(Uint8List.fromList(List.filled(5, 7)));
    await controller.close();
  }();
  return ResponseBody(controller.stream, 200, headers: {
    Headers.contentLengthHeader: ['10'],
  });
}

/// The download history is permanent — it only shrinks when the user deletes
/// entries — and every attempt is its own entry. These also pin down the
/// exact sequence that left the app in a broken state on the AYN Thor: start
/// a download with no folder configured, cancel it, pick the folder, start
/// the same file again.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() => registerFallbackValue(Uint8List(0)));

  late AppDatabase db;
  late DownloadRepository repo;
  late ProviderContainer container;
  late DownloadProgressTrackerNotifier tracker;
  late SettingsNotifier settings;
  late _MockTorrent torrent;
  late _MockSafStorage safStorage;
  late _MockSafStream safStream;
  late Directory stagingDir;
  late List<int> destinationBytes;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase(NativeDatabase.memory());
    repo = DownloadRepository(db);
    container = ProviderContainer();
    tracker = container.read(downloadProgressTrackerProvider.notifier);
    settings = container.read(settingsProvider.notifier);
    await container.read(settingsProvider.future);
    await settings.setDownloadDirectory('content://tree/primary%3ARoms');

    torrent = _MockTorrent();
    safStorage = _MockSafStorage();
    safStream = _MockSafStream();
    when(() => torrent.progressStream).thenAnswer((_) => const Stream<TorrentProgressEvent>.empty());
    when(() => safStorage.isValidTreeUri(any())).thenAnswer((_) async => true);
    when(() => safStorage.ensureDirectory(any(), any()))
        .thenAnswer((_) async => 'content://tree/primary%3ARoms/document/primary%3ARoms');

    destinationBytes = [];
    when(() => safStream.startWriteStream(any(), any(), any(),
        overwrite: any(named: 'overwrite'), append: any(named: 'append'))).thenAnswer((inv) async {
      final append = inv.namedArguments[#append] as bool? ?? false;
      if (!append) destinationBytes = [];
      return SafWriteStreamInfo('session', SafNewFile(Uri.parse('content://file/1'), 'game.chd'));
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

    stagingDir = Directory.systemTemp.createTempSync('pv_history_');
  });

  tearDown(() async {
    await Future.delayed(const Duration(milliseconds: 50));
    container.dispose();
    await db.close();
    if (stagingDir.existsSync()) stagingDir.deleteSync(recursive: true);
  });

  DownloadManager buildManager(Dio dio) => DownloadManager(
        tracker: tracker,
        settings: settings,
        catalog: CatalogRepository(db),
        downloads: repo,
        torrentPlugin: torrent,
        safStorage: safStorage,
        safStream: safStream,
        dio: dio,
        httpDownloadsDir: stagingDir,
      );

  List<DownloadItem> attempts() => container.read(downloadProgressTrackerProvider);

  Future<void> settle([int milliseconds = 2500]) => Future.delayed(Duration(milliseconds: milliseconds));

  test(
    'the reported sequence — no folder, cancel, choose a folder, start again — downloads normally',
    () async {
      await settings.setDownloadDirectory('');
      final manager = buildManager(Dio()..httpClientAdapter = _FakeAdapter((_) => _body(10)));
      final file = _file();

      expect(await manager.startDownload(file), StartDownloadResult.started);
      final first = attempts().single;
      // Cancelled while still waiting to run, which is when the missing
      // folder was noticed.
      await manager.cancelDownload(first.id);
      await settle(1500);

      await settings.setDownloadDirectory('content://tree/primary%3ARoms');
      expect(await manager.startDownload(file), StartDownloadResult.started);
      await settle(3500);

      final all = attempts();
      expect(all, hasLength(2));
      expect(all.firstWhere((d) => d.id == first.id).status, DownloadStatus.cancelled);
      expect(all.firstWhere((d) => d.id != first.id).status, DownloadStatus.completed);
      expect(destinationBytes, hasLength(10));
      expect(await repo.getAll(), hasLength(2), reason: 'both attempts stay in the history');
    },
    timeout: const Timeout(Duration(seconds: 30)),
  );

  test('starting a file that is already downloading does not start a second copy', () async {
    final gate = Completer<void>();
    final manager = buildManager(Dio()..httpClientAdapter = _FakeAdapter((_) => _gatedBody(gate)));
    final file = _file();

    expect(await manager.startDownload(file), StartDownloadResult.started);
    await settle(1400);
    expect(attempts().single.status, DownloadStatus.downloading);

    expect(await manager.startDownload(file), StartDownloadResult.alreadyActive);
    expect(await repo.getAll(), hasLength(1));

    gate.complete();
    await settle(800);
    expect(attempts().single.status, DownloadStatus.completed);
  });

  test('downloading a completed file again adds a new history entry and keeps the old one', () async {
    final manager = buildManager(Dio()..httpClientAdapter = _FakeAdapter((_) => _body(10)));
    final file = _file();

    await manager.startDownload(file);
    await settle();
    final first = attempts().single;
    expect(first.status, DownloadStatus.completed);

    expect(await manager.startDownload(file), StartDownloadResult.started);
    await settle();

    final all = attempts();
    expect(all, hasLength(2));
    expect(all.every((d) => d.status == DownloadStatus.completed), isTrue);
    expect(await repo.getAll(), hasLength(2));
  }, timeout: const Timeout(Duration(seconds: 30)));

  test('cancelling moves an attempt to the history as cancelled and removes its partial file', () async {
    final gate = Completer<void>();
    final manager = buildManager(Dio()..httpClientAdapter = _FakeAdapter((_) => _gatedBody(gate)));

    await manager.startDownload(_file());
    await settle(1400);
    final id = attempts().single.id;

    await manager.cancelDownload(id);
    gate.complete();
    await settle(600);

    expect(attempts().single.status, DownloadStatus.cancelled);
    expect(destinationBytes, isEmpty, reason: 'nothing half-written is left in the ROM folder');
    expect((await repo.getAll()).single.status, DownloadStatus.cancelled);
  });

  test('a cancel that lands during extraction keeps the attempt cancelled', () async {
    final extractGate = Completer<void>();
    when(() => torrent.extractArchive(
          archivePath: any(named: 'archivePath'),
          destDirUri: any(named: 'destDirUri'),
          subPath: any(named: 'subPath'),
        )).thenAnswer((_) async {
      await extractGate.future;
      return ['God of War II (USA).iso'];
    });
    final manager = buildManager(Dio()..httpClientAdapter = _FakeAdapter((_) => _body(10)));

    await manager.startDownload(_file(fileName: 'God of War II (USA).7z', extension: '.7z'));
    await settle(1600);
    final id = attempts().single.id;
    expect(attempts().single.status, DownloadStatus.unzipping);

    await manager.cancelDownload(id);
    extractGate.complete();
    await settle(400);

    expect(attempts().single.status, DownloadStatus.cancelled);
    expect((await repo.getAll()).single.status, DownloadStatus.cancelled);
  });

  test('retrying a cancelled attempt starts a new one and leaves the cancelled entry in the history', () async {
    final manager = buildManager(Dio()..httpClientAdapter = _FakeAdapter((_) => _body(10)));

    await manager.startDownload(_file());
    final first = attempts().single;
    await manager.cancelDownload(first.id);
    await settle(1500);

    await manager.retryDownload(first.id);
    await settle(3500);

    final all = attempts();
    expect(all, hasLength(2));
    expect(all.firstWhere((d) => d.id == first.id).status, DownloadStatus.cancelled);
    expect(all.firstWhere((d) => d.id != first.id).status, DownloadStatus.completed);
  }, timeout: const Timeout(Duration(seconds: 30)));

  test('only history entries can be deleted — never a download that is still running', () async {
    final gate = Completer<void>();
    final manager = buildManager(Dio()
      ..httpClientAdapter = _FakeAdapter((o) => o.path.contains('first') ? _body(10) : _gatedBody(gate)));

    await manager.startDownload(_file(fileName: 'first.chd'));
    await settle();
    await manager.startDownload(_file(fileName: 'second.chd'));
    await settle(1400);

    final finishedId = attempts().firstWhere((d) => d.fileName == 'first.chd').id;
    final runningId = attempts().firstWhere((d) => d.fileName == 'second.chd').id;

    await manager.deleteHistoryEntries({finishedId, runningId});

    expect(attempts().map((d) => d.id), [runningId]);
    expect((await repo.getAll()).map((d) => d.id), [runningId]);
    // The finished game's file is the user's; deleting history never touches it.
    verifyNever(() => safStorage.deleteFile(any()));

    gate.complete();
    await settle(600);
  }, timeout: const Timeout(Duration(seconds: 30)));

  test('clearing the history removes finished, failed and cancelled attempts but keeps the queue', () async {
    final manager = buildManager(Dio());

    Future<int> seed(String name, DownloadStatus status) async {
      final row = await repo.create(_file(fileName: name));
      await repo.update(row.copyWith(status: status));
      return row.id;
    }

    await seed('a.chd', DownloadStatus.completed);
    await seed('b.chd', DownloadStatus.failed);
    await seed('c.chd', DownloadStatus.cancelled);
    final queued = await seed('d.chd', DownloadStatus.stopped);

    await manager.restore();
    await manager.clearHistory();

    expect(attempts().map((d) => d.id), [queued]);
    expect((await repo.getAll()).map((d) => d.id), [queued]);
  });
}
