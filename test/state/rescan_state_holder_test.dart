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
    holder.setProgressNotice(
      const RescanNotice(RescanNoticeKind.processing, console: 'GBA', current: 1, total: 3),
    );
    expect(container.read(rescanStateHolderProvider).progressNotice?.console, 'GBA');

    holder.clearProgressNotice();
    expect(container.read(rescanStateHolderProvider).progressNotice, isNull);
  });

  test('setTorrentFetchProgress / clearTorrentFetchProgress round trip', () {
    holder.setTorrentFetchProgress('Fetching metadata...');
    expect(container.read(rescanStateHolderProvider).torrentFetchProgress, 'Fetching metadata...');

    holder.clearTorrentFetchProgress();
    expect(container.read(rescanStateHolderProvider).torrentFetchProgress, isEmpty);
  });

  test('setErrorNotice sets and, given null, clears the error', () {
    holder.setErrorNotice(const RescanNotice.literal('Failed to scrape GBA: timeout'));
    expect(container.read(rescanStateHolderProvider).errorNotice?.text, 'Failed to scrape GBA: timeout');

    holder.setErrorNotice(null);
    expect(container.read(rescanStateHolderProvider).errorNotice, isNull);
  });

  group('regression: an error must survive unrelated state updates', () {
    // `RescanState.copyWith` always overwrites `errorNotice` rather than
    // defaulting to the current value (so `setErrorNotice(null)` can clear
    // it) — every other setter must explicitly re-pass the current
    // errorNotice or it gets silently wiped, which is exactly what
    // happened before this was fixed: ScrapeOrchestrator sets an error
    // mid-loop, then the very next setProgressMessage/setRescanning call
    // erased it before the Sources screen ever rendered it.
    test('setProgressNotice does not clear a previously set error', () {
      holder.setErrorNotice(const RescanNotice.literal('Failed to scrape GBA: timeout'));
      holder.setProgressNotice(const RescanNotice.literal('Processing console 2/3: SNES'));
      expect(container.read(rescanStateHolderProvider).errorNotice?.text, 'Failed to scrape GBA: timeout');
    });

    test('clearProgressMessage does not clear a previously set error', () {
      holder.setErrorNotice(const RescanNotice.literal('Failed to scrape GBA: timeout'));
      holder.clearProgressNotice();
      expect(container.read(rescanStateHolderProvider).errorNotice?.text, 'Failed to scrape GBA: timeout');
    });

    test('setTorrentFetchProgress / clearTorrentFetchProgress do not clear a previously set error', () {
      holder.setErrorNotice(const RescanNotice.literal('Failed to scrape GBA: timeout'));
      holder.setTorrentFetchProgress('Fetching metadata...');
      expect(container.read(rescanStateHolderProvider).errorNotice?.text, 'Failed to scrape GBA: timeout');

      holder.clearTorrentFetchProgress();
      expect(container.read(rescanStateHolderProvider).errorNotice?.text, 'Failed to scrape GBA: timeout');
    });

    test('setRescanning(false) (the finally-block cleanup after a rescan) does not clear a previously set error', () {
      holder.setRescanning(true);
      holder.setErrorNotice(const RescanNotice.literal('Failed to scrape GBA: timeout'));

      holder.setRescanning(false);

      final state = container.read(rescanStateHolderProvider);
      expect(state.isRescanning, isFalse);
      expect(state.errorNotice?.text, 'Failed to scrape GBA: timeout');
    });

    test('an explicit setErrorNotice(null) still clears it even after other updates', () {
      holder.setErrorNotice(const RescanNotice.literal('Failed to scrape GBA: timeout'));
      holder.setProgressNotice(const RescanNotice.literal('Retrying...'));

      holder.setErrorNotice(null);

      expect(container.read(rescanStateHolderProvider).errorNotice, isNull);
    });
  });
}
