// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'android_equalizer_screen.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(EqualizerViewMode)
final equalizerViewModeProvider = EqualizerViewModeProvider._();

final class EqualizerViewModeProvider
    extends $NotifierProvider<EqualizerViewMode, bool> {
  EqualizerViewModeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'equalizerViewModeProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$equalizerViewModeHash();

  @$internal
  @override
  EqualizerViewMode create() => EqualizerViewMode();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$equalizerViewModeHash() => r'758eb86b5b9666417cdd03806c74b8b897042828';

abstract class _$EqualizerViewMode extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
