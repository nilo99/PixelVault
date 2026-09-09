import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../utils/error_sanitizer.dart';

part 'rescan_state.g.dart';

/// What a [RescanNotice] is telling the user.
enum RescanNoticeKind {
  alreadyRunning,
  processing,
  refreshing,
  scrapeFailed,
  torrentUnsupported,

  /// An already-localized sentence built in the widget layer (which does
  /// have a `BuildContext`), carried through unchanged in [RescanNotice.text].
  literal,
}

/// A message for the Sources screen, carried as a code plus its arguments
/// instead of a finished sentence.
///
/// The orchestrator runs far from any `BuildContext`, so building the
/// sentence there meant hardcoding a language — which is why the sync banner
/// used to mix Portuguese ("Já há uma sincronização em curso") with English
/// ("Failed to scrape…", "Refreshing…") no matter which of the five
/// supported languages the user had chosen. The widget layer resolves this
/// through `rescanNoticeText`.
class RescanNotice {
  const RescanNotice(
    this.kind, {
    this.console = '',
    this.reason,
    this.current = 0,
    this.total = 0,
    this.text = '',
  });

  /// Convenience for a sentence the caller has already localized.
  const RescanNotice.literal(String message)
      : kind = RescanNoticeKind.literal,
        console = '',
        reason = null,
        current = 0,
        total = 0,
        text = message;

  final RescanNoticeKind kind;
  final String console;
  final ErrorReason? reason;
  final int current;
  final int total;
  final String text;

  @override
  bool operator ==(Object other) =>
      other is RescanNotice &&
      other.kind == kind &&
      other.console == console &&
      other.reason == reason &&
      other.current == current &&
      other.total == total &&
      other.text == text;

  @override
  int get hashCode => Object.hash(kind, console, reason, current, total, text);
}

/// Port of Milou's `RescanStateHolder` — surfaces rescan/torrent-fetch
/// progress and the last error to the Sources screen.
class RescanState {
  const RescanState({
    this.isRescanning = false,
    this.lastRescanTime,
    this.progressNotice,
    this.torrentFetchProgress = '',
    this.errorNotice,
  });

  final bool isRescanning;
  final DateTime? lastRescanTime;
  final RescanNotice? progressNotice;
  final String torrentFetchProgress;
  final RescanNotice? errorNotice;

  bool get hasProgress => progressNotice != null;

  RescanState copyWith({
    bool? isRescanning,
    DateTime? lastRescanTime,
    RescanNotice? progressNotice,
    bool clearProgressNotice = false,
    String? torrentFetchProgress,
    RescanNotice? errorNotice,
  }) {
    return RescanState(
      isRescanning: isRescanning ?? this.isRescanning,
      lastRescanTime: lastRescanTime ?? this.lastRescanTime,
      progressNotice: clearProgressNotice ? null : (progressNotice ?? this.progressNotice),
      torrentFetchProgress: torrentFetchProgress ?? this.torrentFetchProgress,
      errorNotice: errorNotice,
    );
  }
}

@riverpod
class RescanStateHolder extends _$RescanStateHolder {
  @override
  RescanState build() => const RescanState();

  bool get isRescanning => state.isRescanning;

  // `RescanState.copyWith` always overwrites `errorNotice` (rather than
  // falling back to the current value like every other field) so that
  // `setErrorNotice(null)` can clear it — every setter below must pass
  // `errorNotice: state.errorNotice` explicitly to avoid silently wiping
  // an error the moment any other field changes (e.g. the next progress
  // message, or the isRescanning/clear* calls in ScrapeOrchestrator's
  // `finally` block), which previously erased errors before the UI ever
  // rendered them.
  void setRescanning(bool value) {
    state = state.copyWith(
      isRescanning: value,
      lastRescanTime: value ? state.lastRescanTime : DateTime.now(),
      errorNotice: state.errorNotice,
    );
  }

  void setProgressNotice(RescanNotice notice) =>
      state = state.copyWith(progressNotice: notice, errorNotice: state.errorNotice);

  void clearProgressNotice() =>
      state = state.copyWith(clearProgressNotice: true, errorNotice: state.errorNotice);

  void setTorrentFetchProgress(String message) =>
      state = state.copyWith(torrentFetchProgress: message, errorNotice: state.errorNotice);

  void clearTorrentFetchProgress() =>
      state = state.copyWith(torrentFetchProgress: '', errorNotice: state.errorNotice);

  void setErrorNotice(RescanNotice? notice) => state = state.copyWith(errorNotice: notice);
}
