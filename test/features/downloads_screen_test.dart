import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
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

    await tester.tap(find.byKey(const Key('downloads_retry_button_7')));
    verify(() => manager.retryDownload(7)).called(1);
  });

  testWidgets('tapping remove on a completed download calls deleteDownload', (tester) async {
    final manager = MockDownloadManager();
    when(() => manager.deleteDownload(any())).thenAnswer((_) async {});

    const item = DownloadItem(id: 3, name: 'Done Game', fileName: 'done.zip', fileSize: 200, status: DownloadStatus.completed);
    await pumpScreen(tester, item: item, manager: manager);

    await tester.tap(find.byKey(const Key('downloads_remove_button_3')));
    verify(() => manager.deleteDownload(3)).called(1);
  });
}
