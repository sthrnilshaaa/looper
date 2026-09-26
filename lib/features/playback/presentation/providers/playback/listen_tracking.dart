part of 'playback_notifier.dart';

extension _PlaybackListenTracking on Playback {
  /// Logs a timestamped "song started playing" event for Looper Analyze,
  /// alongside the [Song.playCount]/[Song.lastPlayed] aggregate already
  /// updated by the caller. Must be called from within the same writeTxn.
  /// Denormalizes song fields onto the row so history stays meaningful even
  /// if the song is later retagged, moved, or removed from the library.
  /// Returns the new row's id so real listened time can be topped up onto
  /// it later, as playback actually happens (see _flushListenedTime).
  Future<int> _logPlayEvent(Song song) async {
    final id = await DbService.isar.playEvents.put(
      PlayEvent()
        ..songId = song.id
        ..songPath = song.path
        ..songTitle = song.title
        ..artist = song.artist
        ..album = song.album
        ..genre = song.genre
        ..durationMs = song.duration
        ..playedAt = DateTime.now(),
    );

    // Keep the log bounded for long-term use: once it grows past ~20k rows,
    // trim the oldest ~500 so it never grows unbounded over years of use.
    const maxEntries = 20000;
    const trimCount = 500;
    final total = await DbService.isar.playEvents.count();
    if (total > maxEntries) {
      final oldest = await DbService.isar.playEvents
          .where()
          .sortByPlayedAt()
          .limit(trimCount)
          .findAll();
      if (oldest.isNotEmpty) {
        await DbService.isar.playEvents.deleteAll(
          oldest.map((e) => e.id).toList(),
        );
      }
    }

    return id;
  }

  /// Starts a new real-time "actually listening" segment. Called only from
  /// mpv's own authoritative `playing` signal (core-idle derived - see the
  /// `player.stream.playing` subscription in [_init]), never optimistically,
  /// so a song sitting paused/buffered never accrues time.
  void _startListenSegment() {
    _listenSegmentStart = DateTime.now();
  }

  Future<void> _checkpointListenedTimeIfDue() async {
    if (_listenSegmentStart == null) return;
    if (DateTime.now().difference(_lastListenCheckpoint) <
        Playback._listenCheckpointInterval) {
      return;
    }
    _lastListenCheckpoint = DateTime.now();
    _pauseListenSegment();
    await _flushListenedTime();
    _startListenSegment();
  }
}
