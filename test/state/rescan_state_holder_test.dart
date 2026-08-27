import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixelvault/core/state/rescan_state.dart';

void main() {
  late ProviderContainer container;
  late RescanStateHolder holder;

  setUp(() {
    container = ProviderContainer();
    holder = container.read(rescanStateHolderProvider.notifier);
  });

  tearDown(() => container.dispose());

  test('setRescanning toggles isRescanning and stamps lastRescanTime when finishing', () {
    holder.setRescanning(true);
    expect(container.read(rescanStateHolderProvider).isRescanning, isTrue);
    expect(container.read(rescanStateHolderProvider).lastRescanTime, isNull);

    holder.setRescanning(false);
    expect(container.read(rescanStateHolderProvider).isRescanning, isFalse);
    expect(container.read(rescanStateHolderProvider).lastRescanTime, isNotNull);
  });

  test('setProgressMessage / clearProgressMessage round trip', () {
    holder.setProgressMessage('Processing console 1/3: GBA');
    expect(container.read(rescanStateHolderProvider).progressMessage, 'Processing console 1/3: GBA');

    holder.clearProgressMessage();
    expect(container.read(rescanStateHolderProvider).progressMessage, isEmpty);
  });

  test('setTorrentFetchProgress / clearTorrentFetchProgress round trip', () {
    holder.setTorrentFetchProgress('Fetching metadata...');
    expect(container.read(rescanStateHolderProvider).torrentFetchProgress, 'Fetching metadata...');

    holder.clearTorrentFetchProgress();
    expect(container.read(rescanStateHolderProvider).torrentFetchProgress, isEmpty);
  });

  test('setErrorMessage sets and, given null, clears the error', () {
    holder.setErrorMessage('Failed to scrape GBA: timeout');
    expect(container.read(rescanStateHolderProvider).errorMessage, 'Failed to scrape GBA: timeout');

    holder.setErrorMessage(null);
    expect(container.read(rescanStateHolderProvider).errorMessage, isNull);
  });

  group('regression: an error must survive unrelated state updates', () {
    // `RescanState.copyWith` always overwrites `errorMessage` rather than
    // defaulting to the current value (so `setErrorMessage(null)` can clear
    // it) — every other setter must explicitly re-pass the current
    // errorMessage or it gets silently wiped, which is exactly what
    // happened before this was fixed: ScrapeOrchestrator sets an error
    // mid-loop, then the very next setProgressMessage/setRescanning call
    // erased it before the Sources screen ever rendered it.
    test('setProgressMessage does not clear a previously set error', () {
      holder.setErrorMessage('Failed to scrape GBA: timeout');
      holder.setProgressMessage('Processing console 2/3: SNES');
      expect(container.read(rescanStateHolderProvider).errorMessage, 'Failed to scrape GBA: timeout');
    });

    test('clearProgressMessage does not clear a previously set error', () {
      holder.setErrorMessage('Failed to scrape GBA: timeout');
      holder.clearProgressMessage();
      expect(container.read(rescanStateHolderProvider).errorMessage, 'Failed to scrape GBA: timeout');
    });

    test('setTorrentFetchProgress / clearTorrentFetchProgress do not clear a previously set error', () {
      holder.setErrorMessage('Failed to scrape GBA: timeout');
      holder.setTorrentFetchProgress('Fetching metadata...');
      expect(container.read(rescanStateHolderProvider).errorMessage, 'Failed to scrape GBA: timeout');

      holder.clearTorrentFetchProgress();
      expect(container.read(rescanStateHolderProvider).errorMessage, 'Failed to scrape GBA: timeout');
    });

    test('setRescanning(false) (the finally-block cleanup after a rescan) does not clear a previously set error', () {
      holder.setRescanning(true);
      holder.setErrorMessage('Failed to scrape GBA: timeout');

      holder.setRescanning(false);

      final state = container.read(rescanStateHolderProvider);
      expect(state.isRescanning, isFalse);
      expect(state.errorMessage, 'Failed to scrape GBA: timeout');
    });

    test('an explicit setErrorMessage(null) still clears it even after other updates', () {
      holder.setErrorMessage('Failed to scrape GBA: timeout');
      holder.setProgressMessage('Retrying...');

      holder.setErrorMessage(null);

      expect(container.read(rescanStateHolderProvider).errorMessage, isNull);
    });
  });
}
