// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(audioService)
final audioServiceProvider = AudioServiceProvider._();

final class AudioServiceProvider
    extends $FunctionalProvider<AudioService, AudioService, AudioService>
    with $Provider<AudioService> {
  AudioServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'audioServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$audioServiceHash();

  @$internal
  @override
  $ProviderElement<AudioService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AudioService create(Ref ref) {
    return audioService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AudioService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AudioService>(value),
    );
  }
}

String _$audioServiceHash() => r'010adb07618eeb58ad083f9a779873d496d836ee';

@ProviderFor(startupFile)
final startupFileProvider = StartupFileProvider._();

final class StartupFileProvider
    extends $FunctionalProvider<String?, String?, String?>
    with $Provider<String?> {
  StartupFileProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'startupFileProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$startupFileHash();

  @$internal
  @override
  $ProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  String? create(Ref ref) {
    return startupFile(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$startupFileHash() => r'5ee70c3881933fb73145097d39f0eb8093811673';

@ProviderFor(searchFocusNode)
final searchFocusNodeProvider = SearchFocusNodeProvider._();

final class SearchFocusNodeProvider
    extends $FunctionalProvider<FocusNode, FocusNode, FocusNode>
    with $Provider<FocusNode> {
  SearchFocusNodeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'searchFocusNodeProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$searchFocusNodeHash();

  @$internal
  @override
  $ProviderElement<FocusNode> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  FocusNode create(Ref ref) {
    return searchFocusNode(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FocusNode value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FocusNode>(value),
    );
  }
}

String _$searchFocusNodeHash() => r'37582b7540c63825009bbb438555a75a9e2642eb';

@ProviderFor(OverlayMode)
final overlayModeProvider = OverlayModeProvider._();

final class OverlayModeProvider extends $NotifierProvider<OverlayMode, bool> {
  OverlayModeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'overlayModeProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$overlayModeHash();

  @$internal
  @override
  OverlayMode create() => OverlayMode();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$overlayModeHash() => r'50b75e16244f9293b9e86bfc79cbfb09e56b5cb8';

abstract class _$OverlayMode extends $Notifier<bool> {
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

/// Whether at least one of the audio/storage/notification permissions was
/// already granted as of app startup - set once via
/// `startupPermissionsGrantedProvider.overrideWithValue(...)` in `main.dart`,
/// read here rather than overriding [ForceWelcome] itself directly so its
/// `build()` stays a plain override-free method.

@ProviderFor(startupPermissionsGranted)
final startupPermissionsGrantedProvider = StartupPermissionsGrantedProvider._();

/// Whether at least one of the audio/storage/notification permissions was
/// already granted as of app startup - set once via
/// `startupPermissionsGrantedProvider.overrideWithValue(...)` in `main.dart`,
/// read here rather than overriding [ForceWelcome] itself directly so its
/// `build()` stays a plain override-free method.

final class StartupPermissionsGrantedProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// Whether at least one of the audio/storage/notification permissions was
  /// already granted as of app startup - set once via
  /// `startupPermissionsGrantedProvider.overrideWithValue(...)` in `main.dart`,
  /// read here rather than overriding [ForceWelcome] itself directly so its
  /// `build()` stays a plain override-free method.
  StartupPermissionsGrantedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'startupPermissionsGrantedProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$startupPermissionsGrantedHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return startupPermissionsGranted(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$startupPermissionsGrantedHash() =>
    r'0c03a1f484d42d6098a16c58d393ded141191b4e';

@ProviderFor(ForceWelcome)
final forceWelcomeProvider = ForceWelcomeProvider._();

final class ForceWelcomeProvider extends $NotifierProvider<ForceWelcome, bool> {
  ForceWelcomeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'forceWelcomeProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$forceWelcomeHash();

  @$internal
  @override
  ForceWelcome create() => ForceWelcome();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$forceWelcomeHash() => r'329c13e74ec739200aa17e21d3cce08d5f0f2bcc';

abstract class _$ForceWelcome extends $Notifier<bool> {
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

@ProviderFor(appVersion)
final appVersionProvider = AppVersionProvider._();

final class AppVersionProvider
    extends $FunctionalProvider<AsyncValue<String>, String, FutureOr<String>>
    with $FutureModifier<String>, $FutureProvider<String> {
  AppVersionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appVersionProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appVersionHash();

  @$internal
  @override
  $FutureProviderElement<String> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String> create(Ref ref) {
    return appVersion(ref);
  }
}

String _$appVersionHash() => r'1ec1b52b62288b068cc7a9b9c26aa039b263326b';
