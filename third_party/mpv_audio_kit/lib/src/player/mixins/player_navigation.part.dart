// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
part of '../player.dart';

/// Playlist navigation (next, previous, jump) and the repeat, shuffle and
/// prefetch modes.
mixin _NavigationModule on _PlayerBase, _QueueModule, _PlaybackModule {
  /// Skips to the next track and returns `true`, or `false` when there is
  /// none. With [force] `true`, advancing past the last entry stops
  /// playback (mpv's `force` flag); the default (`weak`) does nothing when
  /// the last entry is already playing. After `stop(keepPlaylist: true)`
  /// it moves the entry that stopped, with no file loaded (see
  /// [Player.stop]).
  Future<bool> next({bool force = false}) async {
    await _gate();
    if (_entries.stopped != null) {
      final moved = await _moveKeptStop(1);
      if (moved != null) return moved;
    }
    // Execute in-flight transport writes (e.g. an un-awaited seek) before
    // the track change, so they apply to the OLD entry; see
    // [CoreCalls.settleWrites].
    await _calls.settleWrites();
    return _calls.navigate(['playlist-next', force ? 'force' : 'weak']);
  }

  /// Skips to the previous track and returns `true`, or `false` when there
  /// is none. With [force] `true`, going back past the first entry stops
  /// playback; the default (`weak`) does nothing when the first entry is
  /// already playing. After `stop(keepPlaylist: true)` it moves the entry
  /// that stopped, with no file loaded (see [Player.stop]).
  Future<bool> previous({bool force = false}) async {
    await _gate();
    if (_entries.stopped != null) {
      final moved = await _moveKeptStop(-1);
      if (moved != null) return moved;
    }
    // See [next]: in-flight transport writes apply to the old entry.
    await _calls.settleWrites();
    return _calls.navigate(['playlist-prev', force ? 'force' : 'weak']);
  }

  /// Jumps to the next entry whose source playlist (`playlist-path`) differs
  /// from the current one, for navigating across concatenated playlists
  /// (e.g. several internet-radio `.m3u` lists appended into one queue).
  /// Returns `false`, doing nothing, when no later entry comes from a
  /// different playlist, or when no entry is current (after
  /// `stop(keepPlaylist: true)`).
  Future<bool> nextPlaylist() async {
    await _gate();
    // See [next]: in-flight transport writes apply to the old entry.
    await _calls.settleWrites();
    if (!await _hasCurrentEntry()) return false;
    return _calls.navigate(['playlist-next-playlist']);
  }

  /// Jumps to the first of the previous entries whose source playlist
  /// (`playlist-path`) differs from the current one. The reverse of
  /// [nextPlaylist], with the same return value.
  Future<bool> previousPlaylist() async {
    await _gate();
    // See [next]: in-flight transport writes apply to the old entry.
    await _calls.settleWrites();
    if (!await _hasCurrentEntry()) return false;
    return _calls.navigate(['playlist-prev-playlist']);
  }

  /// Whether mpv has a current entry. Without one (idle after
  /// `stop(keepPlaylist: true)`, or entries never started) mpv 0.42's
  /// `playlist-next-playlist` and `playlist-prev-playlist` read the source
  /// playlist of that missing entry and end the process.
  Future<bool> _hasCurrentEntry() async =>
      await _readString('playlist-pos') != '-1';

  /// Jumps to the track at [index] in the playlist and starts playback.
  ///
  /// Writes `pause=no` before issuing the playlist jump (and once more
  /// after it when mpv was parked at the end of content), so the new
  /// track starts playing as soon as `MPV_EVENT_FILE_LOADED` arrives. A
  /// [pause] called after it has the last word: the track then loads
  /// paused.
  ///
  /// Throws [RangeError] if [index] is out of range.
  Future<void> jump(int index) async {
    RangeError.checkNotNegative(index, 'index');
    await _gate();
    // Optimistic intent, same as play(), claimed at the call so that the
    // call order decides: this call unpauses, and `pause` is deliberately
    // unobserved, so skipping the write here would leave
    // `state.playWhenReady` (and the OS play-pause button bound to it)
    // stuck on "paused" while audio is audibly playing.
    final previous = _state.playback.playWhenReady;
    final intent = _transport.claimIntent(true);
    try {
      if (await _checkPlaylistIndex(index, 'index') == null) return;
    } catch (_) {
      // Out of range: nothing moved, so the intent goes back, as after a
      // load that failed: put back off, it is off for the reply of an
      // earlier play() or jump() still on its way too.
      _transport.restoreIntent(_transport.snapshotLoad(), intent, previous);
      rethrow;
    }
    // See [next]: in-flight transport writes apply to the old entry.
    await _calls.settleWrites();
    // See [Player.open]: parked at EOF (`keep-open`) the unpause below
    // doesn't survive: the playloop hits EOF again and re-pauses before
    // the jump command is processed. The corrective write after it sticks.
    final parkedAtEof = await _parkedAtEof();
    await _calls.prop(
      'pause',
      _transport.intendedPlay(intent, true) ? 'no' : 'yes',
    );
    await _calls.commandChecked([
      'playlist-play-index',
      _entries.toCore(index).toString(),
    ]);
    // The jump leaves the park, as the seek of [play] does: its START_FILE
    // is queued behind this reply. A read of the park that spent the
    // intent since the call began is undone; an entry that parks at once
    // opens a new park, whose read spends the intent. A play() called
    // since leaves the write to this reply, as it does to the reply of an
    // earlier play(): away from the park it writes nothing after its
    // claim. A pause() or a load that does not play, called since, keeps
    // the intent off.
    _transport.takePark();
    if (_transport.wantsPlay(intent)) _transport.writeIntent(true);
    if (parkedAtEof && _transport.intendedPlay(intent, true)) {
      await _calls.prop('pause', 'no');
    }
  }

  /// Sets the playlist repeat mode.
  ///
  /// Backed by two mpv properties (`loop-file` + `loop-playlist`); if
  /// the second write fails the first is rolled back so the consumer
  /// never observes a half-applied loop mode.
  ///
  /// Turned on once the queue has ended ([PlaybackState.completed]), a loop
  /// rewinds: [Loop.file] seeks the track to its start, [Loop.playlist]
  /// moves to the first entry, and both stay paused, since the play
  /// intent was spent at the end. Call [Player.play] to start again.
  Future<void> setLoop(Loop loop) async {
    await _gate();
    String loopFile(Loop l) => l == Loop.file ? 'inf' : 'no';
    String loopPlaylist(Loop l) => l == Loop.playlist ? 'inf' : 'no';
    final previous = state.playback.loop;
    // Write the option that turns on first: going from file to playlist,
    // `loop-file=no` first would echo a passing Loop.off.
    final writes = [
      ('loop-file', loopFile(loop), loopFile(previous)),
      ('loop-playlist', loopPlaylist(loop), loopPlaylist(previous)),
    ];
    if (loop == Loop.playlist) writes.insert(0, writes.removeAt(1));
    final done = <(String, String, String)>[];
    try {
      for (final w in writes) {
        await _calls.prop(w.$1, w.$2);
        done.add(w);
      }
    } catch (_) {
      for (final (name, _, prior) in done.reversed) {
        await _calls.propRc(name, prior);
      }
      rethrow;
    }
    // Optimistic update: `state.loop` reflects the requested mode
    // without waiting for the two underlying observers to round-trip.
    // After the writes, not before as [CoreCalls.writeBundle] does: the
    // loop is derived from each echo against the mode in the state, and
    // the echo of an earlier call's `loop-file=no` read against the new
    // mode would pass through Loop.off.
    _updateField((s) => s.copyWith(loop: loop), _streams.loop, loop);
  }

  /// Enables or disables shuffle mode.
  Future<void> setShuffle(bool shuffle) async {
    await _gate();
    await _calls.prop('shuffle', shuffle ? 'yes' : 'no');
    if (shuffle) {
      await _calls.commandChecked(['playlist-shuffle']);
    } else {
      await _calls.commandChecked(['playlist-unshuffle']);
    }
    _updateField(
      (s) => s.copyWith(shuffle: shuffle),
      _reactives.shuffle,
      shuffle,
    );
  }

  /// Enables or disables background prefetch of the next playlist item.
  ///
  /// When enabled, mpv opens the demuxer for the next track before the
  /// current one finishes, so playback continues without an opening-thread
  /// stall on file boundaries. Observe progress via
  /// [PlayerStream.prefetchState].
  ///
  /// The `on_load` hook, and with it the source resolver, runs for the
  /// next entry while the current one plays. Until it continues, mpv
  /// stops feeding the playing entry: a resolver or hook listener slower
  /// than the output buffer leaves a gap in the playing track. A hook of
  /// [Player.registerHook] runs once more when the entry starts, and a
  /// `file-local-options` write in its first run lands on the playing
  /// entry. The source resolver is not asked again then: the entry opens
  /// with the URL it gave for the prefetch.
  ///
  /// Some entries open when they start, not from the prefetch:
  /// - an entry whose [Media] options (headers, chunk size, stream and
  ///   demuxer options, start, end) differ from the playing entry's; not
  ///   [Media.waveformDurationHint];
  /// - an entry with [Media.demuxerLavfOptions], and the entry after it;
  /// - a live [PcmSource] entry, and the entry after it.
  Future<void> setPrefetchPlaylist(bool enabled) async {
    await _write(
      'prefetch-playlist',
      enabled ? 'yes' : 'no',
      _reactives.prefetchPlaylist,
      enabled,
      (s) => s.copyWith(prefetchPlaylist: enabled),
    );
  }
}
