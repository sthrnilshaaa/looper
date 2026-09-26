// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'player_expand_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(playerExpandProgress)
final playerExpandProgressProvider = PlayerExpandProgressProvider._();

final class PlayerExpandProgressProvider
    extends
        $FunctionalProvider<
          ValueNotifier<double>,
          ValueNotifier<double>,
          ValueNotifier<double>
        >
    with $Provider<ValueNotifier<double>> {
  PlayerExpandProgressProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'playerExpandProgressProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$playerExpandProgressHash();

  @$internal
  @override
  $ProviderElement<ValueNotifier<double>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ValueNotifier<double> create(Ref ref) {
    return playerExpandProgress(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ValueNotifier<double> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ValueNotifier<double>>(value),
    );
  }
}

String _$playerExpandProgressHash() =>
    r'0a562b81117abe999f9d07f369077a7bb0df4e3f';

@ProviderFor(PlayerArtworkRect)
final playerArtworkRectProvider = PlayerArtworkRectProvider._();

final class PlayerArtworkRectProvider
    extends $NotifierProvider<PlayerArtworkRect, Rect?> {
  PlayerArtworkRectProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'playerArtworkRectProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$playerArtworkRectHash();

  @$internal
  @override
  PlayerArtworkRect create() => PlayerArtworkRect();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Rect? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Rect?>(value),
    );
  }
}

String _$playerArtworkRectHash() => r'cd65735dec0f76d3e442a9ef15216535d3db4650';

abstract class _$PlayerArtworkRect extends $Notifier<Rect?> {
  Rect? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<Rect?, Rect?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Rect?, Rect?>,
              Rect?,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(PlayerCollapseTrigger)
final playerCollapseTriggerProvider = PlayerCollapseTriggerProvider._();

final class PlayerCollapseTriggerProvider
    extends $NotifierProvider<PlayerCollapseTrigger, int> {
  PlayerCollapseTriggerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'playerCollapseTriggerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$playerCollapseTriggerHash();

  @$internal
  @override
  PlayerCollapseTrigger create() => PlayerCollapseTrigger();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$playerCollapseTriggerHash() =>
    r'e110dd28cf4b1d32928051dfa33e48ef650fffeb';

abstract class _$PlayerCollapseTrigger extends $Notifier<int> {
  int build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<int, int>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int, int>,
              int,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
