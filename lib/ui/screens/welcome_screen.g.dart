// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'welcome_screen.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(WelcomeBypassed)
final welcomeBypassedProvider = WelcomeBypassedProvider._();

final class WelcomeBypassedProvider
    extends $NotifierProvider<WelcomeBypassed, bool> {
  WelcomeBypassedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'welcomeBypassedProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$welcomeBypassedHash();

  @$internal
  @override
  WelcomeBypassed create() => WelcomeBypassed();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$welcomeBypassedHash() => r'32d76c0b13809f2842bc588aa10be7f103fc28e4';

abstract class _$WelcomeBypassed extends $Notifier<bool> {
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
