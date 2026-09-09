import '../../l10n/app_localizations.dart';
import '../download/download_failure.dart';
import '../state/rescan_state.dart';
import 'error_sanitizer.dart';

/// Turns the app's structured failure/progress codes into a sentence in the
/// user's language.
///
/// Everything user-visible is built here rather than at the point the error
/// is raised, so nothing has to guess a locale deep inside the core layer —
/// which is how English strings ("Failed to scrape…", "Refreshing…") and
/// Portuguese ones ("Já há uma sincronização em curso") ended up mixed
/// together in the same banner regardless of the language the user picked.
String errorReasonText(AppLocalizations l10n, ErrorReason reason) {
  return switch (reason) {
    ErrorReason.metadataFetch => l10n.errorMetadataFetch,
    ErrorReason.network => l10n.errorNetwork,
    ErrorReason.linkExpired => l10n.errorLinkExpired,
    ErrorReason.serverResponse => l10n.errorServerResponse,
    ErrorReason.sourceUnreachable => l10n.errorSourceUnreachable,
    ErrorReason.unexpected => l10n.errorUnexpected,
  };
}

String downloadFailureText(AppLocalizations l10n, DownloadFailureReason reason) {
  return switch (reason) {
    DownloadFailureReason.incomplete => l10n.downloadFailureIncomplete,
    DownloadFailureReason.insufficientSpace => l10n.downloadFailureInsufficientSpace,
    DownloadFailureReason.destinationUnavailable => l10n.downloadFailureDestinationUnavailable,
    DownloadFailureReason.destinationWriteFailed => l10n.downloadFailureDestinationWriteFailed,
    DownloadFailureReason.extractionFailed => l10n.downloadFailureExtractionFailed,
    DownloadFailureReason.torrentUnavailable => l10n.downloadFailureTorrentUnavailable,
    DownloadFailureReason.network => l10n.downloadFailureNetwork,
    DownloadFailureReason.unknown => l10n.downloadFailureUnknown,
  };
}

String rescanNoticeText(AppLocalizations l10n, RescanNotice notice) {
  return switch (notice.kind) {
    RescanNoticeKind.alreadyRunning => l10n.sourcesSyncAlreadyRunning,
    RescanNoticeKind.processing =>
      l10n.sourcesSyncProcessing(notice.current, notice.total, notice.console),
    RescanNoticeKind.refreshing => l10n.sourcesSyncRefreshing(notice.console),
    RescanNoticeKind.scrapeFailed => l10n.sourcesSyncFailed(
        notice.console,
        errorReasonText(l10n, notice.reason ?? ErrorReason.unexpected),
      ),
    RescanNoticeKind.torrentUnsupported => l10n.sourcesSyncTorrentUnsupported(notice.console),
    RescanNoticeKind.literal => notice.text,
  };
}
