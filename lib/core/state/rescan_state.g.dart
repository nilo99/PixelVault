// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rescan_state.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(RescanStateHolder)
final rescanStateHolderProvider = RescanStateHolderProvider._();

final class RescanStateHolderProvider
    extends $NotifierProvider<RescanStateHolder, RescanState> {
  RescanStateHolderProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'rescanStateHolderProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$rescanStateHolderHash();

  @$internal
  @override
  RescanStateHolder create() => RescanStateHolder();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RescanState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RescanState>(value),
    );
  }
}

String _$rescanStateHolderHash() => r'25328b1c2eb6dec674973f97655caeb8c67ec7ae';

abstract class _$RescanStateHolder extends $Notifier<RescanState> {
  RescanState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<RescanState, RescanState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<RescanState, RescanState>,
              RescanState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
