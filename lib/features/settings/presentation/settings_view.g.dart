// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_view.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SupportUsSheetVisible)
final supportUsSheetVisibleProvider = SupportUsSheetVisibleProvider._();

final class SupportUsSheetVisibleProvider
    extends $NotifierProvider<SupportUsSheetVisible, bool> {
  SupportUsSheetVisibleProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'supportUsSheetVisibleProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$supportUsSheetVisibleHash();

  @$internal
  @override
  SupportUsSheetVisible create() => SupportUsSheetVisible();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$supportUsSheetVisibleHash() =>
    r'3e824e08f48cb2dfe4b97a0d02ababd86423302b';

abstract class _$SupportUsSheetVisible extends $Notifier<bool> {
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
