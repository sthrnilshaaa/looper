// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lyrics_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(Lyrics)
final lyricsProvider = LyricsProvider._();

final class LyricsProvider extends $NotifierProvider<Lyrics, LyricsState> {
  LyricsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'lyricsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$lyricsHash();

  @$internal
  @override
  Lyrics create() => Lyrics();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LyricsState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LyricsState>(value),
    );
  }
}

String _$lyricsHash() => r'e116efe3fb17f315e4fa501899739b488a6952e9';

abstract class _$Lyrics extends $Notifier<LyricsState> {
  LyricsState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<LyricsState, LyricsState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<LyricsState, LyricsState>,
              LyricsState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(LyricsManualScroll)
final lyricsManualScrollProvider = LyricsManualScrollProvider._();

final class LyricsManualScrollProvider
    extends $NotifierProvider<LyricsManualScroll, bool> {
  LyricsManualScrollProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'lyricsManualScrollProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$lyricsManualScrollHash();

  @$internal
  @override
  LyricsManualScroll create() => LyricsManualScroll();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$lyricsManualScrollHash() =>
    r'3967ceba967fcfac63c66504e42d09be7b08e523';

abstract class _$LyricsManualScroll extends $Notifier<bool> {
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

/// Whether the currently active lyric line's row is within the lyrics
/// list's visible viewport right now - kept up to date by
/// AdvancedLyricRenderer. Lets the "re-sync" button (see
/// AndroidLyricsScreen) only show once the user has actually scrolled the
/// active line out of view, instead of on every scroll touch regardless of
/// whether the line ever left the screen.

@ProviderFor(LyricsActiveLineVisible)
final lyricsActiveLineVisibleProvider = LyricsActiveLineVisibleProvider._();

/// Whether the currently active lyric line's row is within the lyrics
/// list's visible viewport right now - kept up to date by
/// AdvancedLyricRenderer. Lets the "re-sync" button (see
/// AndroidLyricsScreen) only show once the user has actually scrolled the
/// active line out of view, instead of on every scroll touch regardless of
/// whether the line ever left the screen.
final class LyricsActiveLineVisibleProvider
    extends $NotifierProvider<LyricsActiveLineVisible, bool> {
  /// Whether the currently active lyric line's row is within the lyrics
  /// list's visible viewport right now - kept up to date by
  /// AdvancedLyricRenderer. Lets the "re-sync" button (see
  /// AndroidLyricsScreen) only show once the user has actually scrolled the
  /// active line out of view, instead of on every scroll touch regardless of
  /// whether the line ever left the screen.
  LyricsActiveLineVisibleProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'lyricsActiveLineVisibleProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$lyricsActiveLineVisibleHash();

  @$internal
  @override
  LyricsActiveLineVisible create() => LyricsActiveLineVisible();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$lyricsActiveLineVisibleHash() =>
    r'4ab9c43597fb146ba304fc771372bf8ca2469561';

/// Whether the currently active lyric line's row is within the lyrics
/// list's visible viewport right now - kept up to date by
/// AdvancedLyricRenderer. Lets the "re-sync" button (see
/// AndroidLyricsScreen) only show once the user has actually scrolled the
/// active line out of view, instead of on every scroll touch regardless of
/// whether the line ever left the screen.

abstract class _$LyricsActiveLineVisible extends $Notifier<bool> {
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
