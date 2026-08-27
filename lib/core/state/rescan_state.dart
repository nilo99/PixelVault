import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'rescan_state.g.dart';

/// Port of Milou's `RescanStateHolder` — surfaces rescan/torrent-fetch
/// progress and the last error to the Sources screen.
class RescanState {
  const RescanState({
    this.isRescanning = false,
    this.lastRescanTime,
    this.progressMessage = '',
    this.torrentFetchProgress = '',
    this.errorMessage,
  });

  final bool isRescanning;
  final DateTime? lastRescanTime;
  final String progressMessage;
  final String torrentFetchProgress;
  final String? errorMessage;

  RescanState copyWith({
    bool? isRescanning,
    DateTime? lastRescanTime,
    String? progressMessage,
    String? torrentFetchProgress,
    String? errorMessage,
  }) {
    return RescanState(
      isRescanning: isRescanning ?? this.isRescanning,
      lastRescanTime: lastRescanTime ?? this.lastRescanTime,
      progressMessage: progressMessage ?? this.progressMessage,
      torrentFetchProgress: torrentFetchProgress ?? this.torrentFetchProgress,
      errorMessage: errorMessage,
    );
  }
}

@riverpod
class RescanStateHolder extends _$RescanStateHolder {
  @override
  RescanState build() => const RescanState();

  bool get isRescanning => state.isRescanning;

  // `RescanState.copyWith` always overwrites `errorMessage` (rather than
  // falling back to the current value like every other field) so that
  // `setErrorMessage(null)` can clear it — every setter below must pass
  // `errorMessage: state.errorMessage` explicitly to avoid silently wiping
  // an error the moment any other field changes (e.g. the next progress
  // message, or the isRescanning/clear* calls in ScrapeOrchestrator's
  // `finally` block), which previously erased errors before the UI ever
  // rendered them.
  void setRescanning(bool value) {
    state = state.copyWith(
      isRescanning: value,
      lastRescanTime: value ? state.lastRescanTime : DateTime.now(),
      errorMessage: state.errorMessage,
    );
  }

  void setProgressMessage(String message) =>
      state = state.copyWith(progressMessage: message, errorMessage: state.errorMessage);
  void clearProgressMessage() => state = state.copyWith(progressMessage: '', errorMessage: state.errorMessage);
  void setTorrentFetchProgress(String message) =>
      state = state.copyWith(torrentFetchProgress: message, errorMessage: state.errorMessage);
  void clearTorrentFetchProgress() =>
      state = state.copyWith(torrentFetchProgress: '', errorMessage: state.errorMessage);
  void setErrorMessage(String? message) => state = state.copyWith(errorMessage: message);
}
