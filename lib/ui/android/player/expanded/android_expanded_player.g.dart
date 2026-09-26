// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'android_expanded_player.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(currentSongAnalysis)
final currentSongAnalysisProvider = CurrentSongAnalysisProvider._();

final class CurrentSongAnalysisProvider
    extends
        $FunctionalProvider<
          AsyncValue<AudioAnalysis?>,
          AudioAnalysis?,
          FutureOr<AudioAnalysis?>
        >
    with $FutureModifier<AudioAnalysis?>, $FutureProvider<AudioAnalysis?> {
  CurrentSongAnalysisProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentSongAnalysisProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentSongAnalysisHash();

  @$internal
  @override
  $FutureProviderElement<AudioAnalysis?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<AudioAnalysis?> create(Ref ref) {
    return currentSongAnalysis(ref);
  }
}

String _$currentSongAnalysisHash() =>
    r'c1124e3179374b2a5ffac93693aa1f617c48f1b6';
