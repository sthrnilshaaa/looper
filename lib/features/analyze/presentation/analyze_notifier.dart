import 'package:isar_community/isar.dart';
import 'package:looper_player/core/db_service.dart';
import 'package:looper_player/features/analyze/domain/analyze_models.dart';
import 'package:looper_player/features/library/presentation/library_notifier.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'analyze_notifier.g.dart';

/// Recent play-event log, newest first, capped generously so the trend
/// chart, streaks, and activity heatmap have plenty of history to work with
/// without ever loading the entire (pruned) table into memory.
@Riverpod(keepAlive: true)
Stream<List<PlayEvent>> playEvents(Ref ref) {
  return DbService.isar.playEvents
      .where()
      .sortByPlayedAtDesc()
      .limit(5000)
      .watch(fireImmediately: true);
}

/// The full computed Looper Analyze report, recomputed whenever the library
/// or play-event log changes. Reuses [libraryProvider] instead of watching
/// songs a second time.
@Riverpod(keepAlive: true)
AnalyzeSnapshot analyzeSnapshot(Ref ref) {
  final library = ref.watch(libraryProvider);
  final events = ref.watch(playEventsProvider).value ?? [];

  if (!library.isInitialized) return AnalyzeSnapshot.empty;

  return AnalyzeSnapshot.compute(
    songs: library.songs,
    events: events,
    artists: library.artists,
  );
}

/// The Top Songs list toggle: 10 or 20 entries shown.
@Riverpod(keepAlive: true)
class AnalyzeTopSongsLimit extends _$AnalyzeTopSongsLimit {
  @override
  int build() => 10;

  void set(int value) => state = value;
}
