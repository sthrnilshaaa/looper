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
    r'7f84a3a02a4bd171844d6d803d15318c7f122f3b';
