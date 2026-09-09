import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pixelvault/core/download/download_failure.dart';
import 'package:pixelvault/core/download/download_item.dart';
import 'package:pixelvault/core/download/download_manager.dart';
import 'package:pixelvault/core/download/download_progress_tracker.dart';
import 'package:pixelvault/core/download/download_status.dart';
import 'package:pixelvault/core/providers.dart';
import 'package:pixelvault/features/downloads/downloads_screen.dart';
import 'package:pixelvault/l10n/app_localizations.dart';

class MockDownloadManager extends Mock implements DownloadManager {}

void main() {
  setUpAll(() {
    registerFallbackValue(0);
  });

  Future<ProviderContainer> pumpScreen(
    WidgetTester tester, {
    required DownloadItem item,
    required MockDownloadManager manager,
  }) async {
    final container = ProviderContainer(
      overrides: [downloadManagerProvider.overrideWith((ref) => manager)],
    );
    addTearDown(container.dispose);
    container.read(downloadProgressTrackerProvider.notifier).addDownload(item);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          locale: Locale('pt'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: DownloadsScreen(),
        ),
      ),
    );
    await tester.pump();
    return container;
  }

  /// Finished and failed downloads live in the History tab; the screen opens
  /// on Active.
  Future<void> openHistory(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('downloads_tab_history')));
    await tester.pump();
  }

  testWidgets('renders an in-progress download with a stop button', (tester) async {
    final manager = MockDownloadManager();
    when(() => manager.cancelDownload(any())).thenAnswer((_) async {});

    const item = DownloadItem(id: 1, name: 'Test Game', fileName: 'test.zip', fileSize: 1000, progress: 0.4);
    await pumpScreen(tester, item: item, manager: manager);

    expect(find.text('Test Game'), findsOneWidget);
    await tester.tap(find.byKey(const Key('downloads_cancel_button_1')));
    verify(() => manager.cancelDownload(1)).called(1);
  });

  testWidgets('tapping retry on a failed download calls retryDownload with the right id', (tester) async {
    final manager = MockDownloadManager();
    when(() => manager.retryDownload(any())).thenAnswer((_) async {});

    const item = DownloadItem(id: 7, name: 'Broken Game', fileName: 'broken.zip', fileSize: 500, status: DownloadStatus.failed);
    await pumpScreen(tester, item: item, manager: manager);
    await openHistory(tester);

    await tester.tap(find.byKey(const Key('downloads_retry_button_7')));
    verify(() => manager.retryDownload(7)).called(1);
  });

  testWidgets('tapping remove on a completed download calls deleteDownload', (tester) async {
    final manager = MockDownloadManager();
    when(() => manager.deleteDownload(any())).thenAnswer((_) async {});

    const item = DownloadItem(id: 3, name: 'Done Game', fileName: 'done.zip', fileSize: 200, status: DownloadStatus.completed);
    await pumpScreen(tester, item: item, manager: manager);
    await openHistory(tester);

    await tester.tap(find.byKey(const Key('downloads_remove_button_3')));
    verify(() => manager.deleteDownload(3)).called(1);
  });

  testWidgets('a finished download is kept in History, not in the Active tab', (tester) async {
    final manager = MockDownloadManager();
    const item = DownloadItem(id: 3, name: 'Done Game', fileName: 'done.zip', fileSize: 200, status: DownloadStatus.completed);
    await pumpScreen(tester, item: item, manager: manager);

    // Active tab is empty…
    expect(find.text('Done Game'), findsNothing);
    // …and the history tab is where it lives.
    await openHistory(tester);
    expect(find.text('Done Game'), findsOneWidget);
  });

  testWidgets('a completed download shows where the file was saved', (tester) async {
    final manager = MockDownloadManager();
    const item = DownloadItem(
      id: 5,
      name: 'Saved Game',
      fileName: 'saved.chd',
      fileSize: 200,
      status: DownloadStatus.completed,
      destinationLabel: 'primary:Roms/PS1',
      savedFileName: 'saved.chd',
    );
    await pumpScreen(tester, item: item, manager: manager);
    await openHistory(tester);

    expect(find.byKey(const Key('downloads_destination_5')), findsOneWidget);
    expect(
      find.textContaining('Roms/PS1/saved.chd', findRichText: true),
      findsOneWidget,
    );
  });

  testWidgets('a failed download explains why, in the chosen language', (tester) async {
    final manager = MockDownloadManager();
    const item = DownloadItem(
      id: 9,
      name: 'Cut Off',
      fileName: 'big.chd',
      fileSize: 900,
      status: DownloadStatus.failed,
      failureReason: DownloadFailureReason.incomplete,
    );
    await pumpScreen(tester, item: item, manager: manager);
    await openHistory(tester);

    // Portuguese locale is set on the MaterialApp above.
    expect(find.textContaining('incompleto'), findsOneWidget);
  });

  testWidgets('a download interrupted mid-flight offers to resume rather than restart', (tester) async {
    final manager = MockDownloadManager();
    when(() => manager.retryDownload(any())).thenAnswer((_) async {});

    const item = DownloadItem(
      id: 11,
      name: 'Half Done',
      fileName: 'half.iso',
      fileSize: 1000,
      downloadedBytes: 400,
      status: DownloadStatus.stopped,
    );
    await pumpScreen(tester, item: item, manager: manager);

    // `stopped` is not terminal, so it stays in the Active tab as a
    // resumable queue entry.
    expect(find.text('Half Done'), findsOneWidget);
    expect(find.textContaining('retoma'), findsOneWidget);

    await tester.tap(find.byKey(const Key('downloads_retry_button_11')));
    verify(() => manager.retryDownload(11)).called(1);
  });
}
