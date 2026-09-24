// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lyrics_search_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Tracks the current search query specifically for lyrics highlighting and
/// scrolling.

@ProviderFor(LyricsSearchQuery)
final lyricsSearchQueryProvider = LyricsSearchQueryProvider._();

/// Tracks the current search query specifically for lyrics highlighting and
/// scrolling.
final class LyricsSearchQueryProvider
    extends $NotifierProvider<LyricsSearchQuery, String> {
  /// Tracks the current search query specifically for lyrics highlighting and
  /// scrolling.
  LyricsSearchQueryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'lyricsSearchQueryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$lyricsSearchQueryHash();

  @$internal
  @override
  LyricsSearchQuery create() => LyricsSearchQuery();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$lyricsSearchQueryHash() => r'88880bafbdb0f82a895018df4108134249bfaadf';

/// Tracks the current search query specifically for lyrics highlighting and
/// scrolling.

abstract class _$LyricsSearchQuery extends $Notifier<String> {
  String build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<String, String>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String, String>,
              String,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
