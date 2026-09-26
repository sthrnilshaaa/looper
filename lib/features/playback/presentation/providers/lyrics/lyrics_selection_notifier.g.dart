// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lyrics_selection_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Drives the "select lyric lines to share" flow on the Lyrics screen.
/// Long-pressing a line starts a selection anchored at that line; tapping
/// another line while a selection is active extends (or shrinks) the range
/// towards it, capped at [maxLines] so the resulting share card stays
/// legible.

@ProviderFor(LyricsSelection)
final lyricsSelectionProvider = LyricsSelectionProvider._();

/// Drives the "select lyric lines to share" flow on the Lyrics screen.
/// Long-pressing a line starts a selection anchored at that line; tapping
/// another line while a selection is active extends (or shrinks) the range
/// towards it, capped at [maxLines] so the resulting share card stays
/// legible.
final class LyricsSelectionProvider
    extends $NotifierProvider<LyricsSelection, LyricsSelectionState> {
  /// Drives the "select lyric lines to share" flow on the Lyrics screen.
  /// Long-pressing a line starts a selection anchored at that line; tapping
  /// another line while a selection is active extends (or shrinks) the range
  /// towards it, capped at [maxLines] so the resulting share card stays
  /// legible.
  LyricsSelectionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'lyricsSelectionProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$lyricsSelectionHash();

  @$internal
  @override
  LyricsSelection create() => LyricsSelection();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LyricsSelectionState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LyricsSelectionState>(value),
    );
  }
}

String _$lyricsSelectionHash() => r'432716c68f0fcd1ecb1ca54da9c5ead916ce008f';

/// Drives the "select lyric lines to share" flow on the Lyrics screen.
/// Long-pressing a line starts a selection anchored at that line; tapping
/// another line while a selection is active extends (or shrinks) the range
/// towards it, capped at [maxLines] so the resulting share card stays
/// legible.

abstract class _$LyricsSelection extends $Notifier<LyricsSelectionState> {
  LyricsSelectionState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<LyricsSelectionState, LyricsSelectionState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<LyricsSelectionState, LyricsSelectionState>,
              LyricsSelectionState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
