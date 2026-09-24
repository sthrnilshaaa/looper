// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'analyze_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Recent play-event log, newest first, capped generously so the trend
/// chart, streaks, and activity heatmap have plenty of history to work with
/// without ever loading the entire (pruned) table into memory.

@ProviderFor(playEvents)
final playEventsProvider = PlayEventsProvider._();

/// Recent play-event log, newest first, capped generously so the trend
/// chart, streaks, and activity heatmap have plenty of history to work with
/// without ever loading the entire (pruned) table into memory.

final class PlayEventsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<PlayEvent>>,
          List<PlayEvent>,
          Stream<List<PlayEvent>>
        >
    with $FutureModifier<List<PlayEvent>>, $StreamProvider<List<PlayEvent>> {
  /// Recent play-event log, newest first, capped generously so the trend
  /// chart, streaks, and activity heatmap have plenty of history to work with
  /// without ever loading the entire (pruned) table into memory.
  PlayEventsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'playEventsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$playEventsHash();

  @$internal
  @override
  $StreamProviderElement<List<PlayEvent>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<PlayEvent>> create(Ref ref) {
    return playEvents(ref);
  }
}

String _$playEventsHash() => r'f11aa86418279250d0e533e390dce8da5c834d01';

/// The full computed Looper Analyze report, recomputed whenever the library
/// or play-event log changes. Reuses [libraryProvider] instead of watching
/// songs a second time.

@ProviderFor(analyzeSnapshot)
final analyzeSnapshotProvider = AnalyzeSnapshotProvider._();

/// The full computed Looper Analyze report, recomputed whenever the library
/// or play-event log changes. Reuses [libraryProvider] instead of watching
/// songs a second time.

final class AnalyzeSnapshotProvider
    extends
        $FunctionalProvider<AnalyzeSnapshot, AnalyzeSnapshot, AnalyzeSnapshot>
    with $Provider<AnalyzeSnapshot> {
  /// The full computed Looper Analyze report, recomputed whenever the library
  /// or play-event log changes. Reuses [libraryProvider] instead of watching
  /// songs a second time.
  AnalyzeSnapshotProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'analyzeSnapshotProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$analyzeSnapshotHash();

  @$internal
  @override
  $ProviderElement<AnalyzeSnapshot> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AnalyzeSnapshot create(Ref ref) {
    return analyzeSnapshot(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AnalyzeSnapshot value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AnalyzeSnapshot>(value),
    );
  }
}

String _$analyzeSnapshotHash() => r'99ee4bc85a6f73e004aa60000db182b976ce6be2';

/// The Top Songs list toggle: 10 or 20 entries shown.

@ProviderFor(AnalyzeTopSongsLimit)
final analyzeTopSongsLimitProvider = AnalyzeTopSongsLimitProvider._();

/// The Top Songs list toggle: 10 or 20 entries shown.
final class AnalyzeTopSongsLimitProvider
    extends $NotifierProvider<AnalyzeTopSongsLimit, int> {
  /// The Top Songs list toggle: 10 or 20 entries shown.
  AnalyzeTopSongsLimitProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'analyzeTopSongsLimitProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$analyzeTopSongsLimitHash();

  @$internal
  @override
  AnalyzeTopSongsLimit create() => AnalyzeTopSongsLimit();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$analyzeTopSongsLimitHash() =>
    r'07f63367f17a67dc09bc0334c17bedf08e619f44';

/// The Top Songs list toggle: 10 or 20 entries shown.

abstract class _$AnalyzeTopSongsLimit extends $Notifier<int> {
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
