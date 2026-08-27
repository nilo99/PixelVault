// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'download_progress_tracker.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Port of Milou's `DownloadProgressTracker` — a `List<DownloadItem>` state
/// notifier the Downloads screen watches directly. Keyed by [DownloadItem.id]
/// (not [DownloadItem.fileName], which isn't guaranteed unique across sources).

@ProviderFor(DownloadProgressTrackerNotifier)
final downloadProgressTrackerProvider =
    DownloadProgressTrackerNotifierProvider._();

/// Port of Milou's `DownloadProgressTracker` — a `List<DownloadItem>` state
/// notifier the Downloads screen watches directly. Keyed by [DownloadItem.id]
/// (not [DownloadItem.fileName], which isn't guaranteed unique across sources).
final class DownloadProgressTrackerNotifierProvider
    extends
        $NotifierProvider<DownloadProgressTrackerNotifier, List<DownloadItem>> {
  /// Port of Milou's `DownloadProgressTracker` — a `List<DownloadItem>` state
  /// notifier the Downloads screen watches directly. Keyed by [DownloadItem.id]
  /// (not [DownloadItem.fileName], which isn't guaranteed unique across sources).
  DownloadProgressTrackerNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'downloadProgressTrackerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$downloadProgressTrackerNotifierHash();

  @$internal
  @override
  DownloadProgressTrackerNotifier create() => DownloadProgressTrackerNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<DownloadItem> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<DownloadItem>>(value),
    );
  }
}

String _$downloadProgressTrackerNotifierHash() =>
    r'd87e56902645597bc37242d6a6a21a85b5b87565';

/// Port of Milou's `DownloadProgressTracker` — a `List<DownloadItem>` state
/// notifier the Downloads screen watches directly. Keyed by [DownloadItem.id]
/// (not [DownloadItem.fileName], which isn't guaranteed unique across sources).

abstract class _$DownloadProgressTrackerNotifier
    extends $Notifier<List<DownloadItem>> {
  List<DownloadItem> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<List<DownloadItem>, List<DownloadItem>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<DownloadItem>, List<DownloadItem>>,
              List<DownloadItem>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
