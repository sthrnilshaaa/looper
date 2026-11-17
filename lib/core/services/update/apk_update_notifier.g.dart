// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'apk_update_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// In-app update for the Android `github` build: finds the newest GitHub
/// release, downloads the APK for this device and hands it to the system
/// installer. Other builds never leave [ApkUpdatePhase.idle].

@ProviderFor(ApkUpdate)
final apkUpdateProvider = ApkUpdateProvider._();

/// In-app update for the Android `github` build: finds the newest GitHub
/// release, downloads the APK for this device and hands it to the system
/// installer. Other builds never leave [ApkUpdatePhase.idle].
final class ApkUpdateProvider
    extends $NotifierProvider<ApkUpdate, ApkUpdateState> {
  /// In-app update for the Android `github` build: finds the newest GitHub
  /// release, downloads the APK for this device and hands it to the system
  /// installer. Other builds never leave [ApkUpdatePhase.idle].
  ApkUpdateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'apkUpdateProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$apkUpdateHash();

  @$internal
  @override
  ApkUpdate create() => ApkUpdate();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ApkUpdateState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ApkUpdateState>(value),
    );
  }
}

String _$apkUpdateHash() => r'fdc2c34feabebeff90741c6fda52d5a209b41ee7';

/// In-app update for the Android `github` build: finds the newest GitHub
/// release, downloads the APK for this device and hands it to the system
/// installer. Other builds never leave [ApkUpdatePhase.idle].

abstract class _$ApkUpdate extends $Notifier<ApkUpdateState> {
  ApkUpdateState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ApkUpdateState, ApkUpdateState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ApkUpdateState, ApkUpdateState>,
              ApkUpdateState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
