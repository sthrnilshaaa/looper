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

String _$appNavigationHash() => r'3ee45287beb1c644696a9ba2e3913fa80bb022c8';

abstract class _$AppNavigation extends $Notifier<NavigationState> {
  NavigationState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<NavigationState, NavigationState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<NavigationState, NavigationState>,
              NavigationState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
