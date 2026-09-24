// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'navigation_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AppNavigation)
final appNavigationProvider = AppNavigationProvider._();

final class AppNavigationProvider
    extends $NotifierProvider<AppNavigation, NavigationState> {
  AppNavigationProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appNavigationProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appNavigationHash();

  @$internal
  @override
  AppNavigation create() => AppNavigation();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NavigationState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NavigationState>(value),
    );
  }
}

String _$appNavigationHash() => r'777275728cecf53d1ca1a050f0df92f87119e236';

abstract class _$AppNavigation extends $Notifier<NavigationState> {
  NavigationState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<NavigationState, NavigationState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<NavigationState, NavigationState>,
              NavigationState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
