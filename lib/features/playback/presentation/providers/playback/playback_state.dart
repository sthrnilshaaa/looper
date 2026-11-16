part of 'playback_notifier.dart';

enum RepeatMode { off, all, one }

enum FileActionResult { success, dbOnly, failure }

class PlaybackState {
  final Song? currentSong;
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final bool isShuffle;
  final RepeatMode repeatMode;
  final double volume;

  final bool isScrubbing;
  final List<Song> queue;
  final List<int> queueEntryIds;
  final Set<int> manualQueueEntryIds;
  final int currentQueueIndex;

  /// [collectionKey] of the songs the current queue was loaded from, so a
  /// collection can tell whether it is the one playing (shuffled or not).
  final int? queueSourceKey;

  /// True when a song was loaded from saved state on startup but playback
  /// hasn't started yet (resumeOnStart = false). The player bar is hidden
  /// when this is true and isPlaying is false, preventing the stale
  /// "paused song" ghost bar from showing on every cold start.
  final bool isRestoredSession;

  final bool isSleepTimerActive;
  final Duration? sleepTimerDurationRemaining;
  final int? sleepTimerSongsRemaining;
  final Duration? sleepTimerDurationInitial;
  final int? sleepTimerSongsInitial;

  PlaybackState({
    this.currentSong,
    this.isPlaying = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.isShuffle = false,
    this.repeatMode = RepeatMode.off,
    this.volume = 1.0,
    this.isScrubbing = false,
    this.queue = const [],
    this.queueEntryIds = const [],
    this.manualQueueEntryIds = const {},
    this.currentQueueIndex = -1,
    this.queueSourceKey,
    this.isRestoredSession = false,
    this.isSleepTimerActive = false,
    this.sleepTimerDurationRemaining,
    this.sleepTimerSongsRemaining,
    this.sleepTimerDurationInitial,
    this.sleepTimerSongsInitial,
  });

  PlaybackState copyWith({
    Object? currentSong = _sentinel,
    bool? isPlaying,
    Duration? position,
    Duration? duration,
    bool? isShuffle,
    RepeatMode? repeatMode,
    double? volume,
    bool? isScrubbing,
    List<Song>? queue,
    List<int>? queueEntryIds,
    Set<int>? manualQueueEntryIds,
    int? currentQueueIndex,
    Object? queueSourceKey = _sentinel,
    bool? isRestoredSession,
    bool? isSleepTimerActive,
    Object? sleepTimerDurationRemaining = _sentinel,
    Object? sleepTimerSongsRemaining = _sentinel,
    Object? sleepTimerDurationInitial = _sentinel,
    Object? sleepTimerSongsInitial = _sentinel,
  }) {
    return PlaybackState(
      currentSong: currentSong == _sentinel
          ? this.currentSong
          : currentSong as Song?,
      isPlaying: isPlaying ?? this.isPlaying,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      isShuffle: isShuffle ?? this.isShuffle,
      repeatMode: repeatMode ?? this.repeatMode,
      volume: volume ?? this.volume,
      isScrubbing: isScrubbing ?? this.isScrubbing,
      queue: queue ?? this.queue,
      queueEntryIds: queueEntryIds ?? this.queueEntryIds,
      manualQueueEntryIds: manualQueueEntryIds ?? this.manualQueueEntryIds,
      currentQueueIndex: currentQueueIndex ?? this.currentQueueIndex,
      queueSourceKey: queueSourceKey == _sentinel
          ? this.queueSourceKey
          : queueSourceKey as int?,
      isRestoredSession: isRestoredSession ?? this.isRestoredSession,
      isSleepTimerActive: isSleepTimerActive ?? this.isSleepTimerActive,
      sleepTimerDurationRemaining: sleepTimerDurationRemaining == _sentinel
          ? this.sleepTimerDurationRemaining
          : sleepTimerDurationRemaining as Duration?,
      sleepTimerSongsRemaining: sleepTimerSongsRemaining == _sentinel
          ? this.sleepTimerSongsRemaining
          : sleepTimerSongsRemaining as int?,
      sleepTimerDurationInitial: sleepTimerDurationInitial == _sentinel
          ? this.sleepTimerDurationInitial
          : sleepTimerDurationInitial as Duration?,
      sleepTimerSongsInitial: sleepTimerSongsInitial == _sentinel
          ? this.sleepTimerSongsInitial
          : sleepTimerSongsInitial as int?,
    );
  }
}

const _sentinel = Object();

/// Identifies a set of songs regardless of their order (sorting a collection
/// or shuffling its queue keeps the same key).
int collectionKey(Iterable<Song> songs) => Object.hash(
  songs.length,
  Object.hashAllUnordered(songs.map((song) => song.path)),
);
