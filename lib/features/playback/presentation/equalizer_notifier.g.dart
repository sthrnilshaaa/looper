// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'equalizer_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(Equalizer)
final equalizerProvider = EqualizerProvider._();

final class EqualizerProvider
    extends $NotifierProvider<Equalizer, EqualizerState> {
  EqualizerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'equalizerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$equalizerHash();

  @$internal
  @override
  Equalizer create() => Equalizer();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EqualizerState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EqualizerState>(value),
    );
  }
}

String _$equalizerHash() => r'6e790b55ca489962c2aa0e8c0d9fb27cc45eed34';

abstract class _$Equalizer extends $Notifier<EqualizerState> {
  EqualizerState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<EqualizerState, EqualizerState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<EqualizerState, EqualizerState>,
              EqualizerState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Persists custom EQ presets to a local JSON file (see [LocalJsonStore])
/// rather than the Isar schema - a handful of named gain snapshots don't
/// warrant a DB migration.

@ProviderFor(CustomEqPresets)
final customEqPresetsProvider = CustomEqPresetsProvider._();

/// Persists custom EQ presets to a local JSON file (see [LocalJsonStore])
/// rather than the Isar schema - a handful of named gain snapshots don't
/// warrant a DB migration.
final class CustomEqPresetsProvider
    extends $NotifierProvider<CustomEqPresets, List<CustomEqPreset>> {
  /// Persists custom EQ presets to a local JSON file (see [LocalJsonStore])
  /// rather than the Isar schema - a handful of named gain snapshots don't
  /// warrant a DB migration.
  CustomEqPresetsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'customEqPresetsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$customEqPresetsHash();

  @$internal
  @override
  CustomEqPresets create() => CustomEqPresets();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<CustomEqPreset> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<CustomEqPreset>>(value),
    );
  }
}

String _$customEqPresetsHash() => r'd9f3d616df7d04b60dfc99c67d555080aa174cb6';

/// Persists custom EQ presets to a local JSON file (see [LocalJsonStore])
/// rather than the Isar schema - a handful of named gain snapshots don't
/// warrant a DB migration.

abstract class _$CustomEqPresets extends $Notifier<List<CustomEqPreset>> {
  List<CustomEqPreset> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<List<CustomEqPreset>, List<CustomEqPreset>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<CustomEqPreset>, List<CustomEqPreset>>,
              List<CustomEqPreset>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
