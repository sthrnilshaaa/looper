// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
part of '../player.dart';

/// Playlist setters: queue mutation (add / remove / move / replace),
/// navigation (next / previous / jump), repeat / shuffle / prefetch
/// modes.
mixin _PlaylistModule on _PlayerBase {
  /// Appends [media] to the end of the current playlist.
  ///
  /// `media.httpHeaders` ride along as the 4th `loadfile` argument
  /// (mpv 0.38+: `loadfile <url> append -1 <opts>`), so mpv scopes
  /// them as file-local for this exact entry — even if the entry
  /// only loads minutes later when playback advances.
  Future<void> add(Media media) async {
    _checkNotDisposed();
    // Snapshot (not bump — appends don't supersede each other) the load
    // epoch: if a content-replacing call (open / stop / clearPlaylist)
    // lands while this append is still resolving its URI, the append is
    // stale and must not graft the old queue's entry onto the new one.
    final epoch = _loadEpoch;
    await _gate();
    _validateLoadOptions(media);
    _mediaCache[media.uri] = media;
    final resolved = await resolveUri(media.uri);
    if (_disposed || epoch != _loadEpoch) {
      await resolved.dispose?.call();
      return;
    }
    _mediaCache[resolved.uri] = media;
    final opts = _buildLoadfileOptions(media);
    if (opts.isEmpty) {
      await _commandChecked(['loadfile', resolved.uri, 'append']);
    } else {
      await _commandChecked(['loadfile', resolved.uri, 'append', '-1', opts]);
    }
  }

  /// Removes the track at [index] from the playlist.
  ///
  /// Throws [MpvException] if [index] is out of range.
  Future<void> remove(int index) async {
    await _gate();
    await _commandChecked(['playlist-remove', index.toString()]);
  }

  /// Skips to the next track. With [force] `true`, advancing past the last
  /// entry stops playback (mpv's `force` flag); the default (`weak`) does
  /// nothing when the last entry is already playing.
  Future<void> next({bool force = false}) async {
    await _gate();
    // Execute in-flight transport writes (e.g. an un-awaited seek) before
    // the track change, so they apply to the OLD entry — see [_settleWrites].
    await _settleWrites();
    await _command(['playlist-next', force ? 'force' : 'weak']);
  }

  /// Skips to the previous track. With [force] `true`, going back past the
  /// first entry stops playback; the default (`weak`) does nothing when the
  /// first entry is already playing.
  Future<void> previous({bool force = false}) async {
    await _gate();
    // See [next] — in-flight transport writes apply to the old entry.
    await _settleWrites();
    await _command(['playlist-prev', force ? 'force' : 'weak']);
  }

  /// Jumps to the next entry whose source playlist (`playlist-path`) differs
  /// from the current one — for navigating across concatenated playlists
  /// (e.g. several internet-radio `.m3u` lists appended into one queue).
  /// No-op when no later entry comes from a different playlist.
  Future<void> nextPlaylist() async {
    await _gate();
    // See [next] — in-flight transport writes apply to the old entry.
    await _settleWrites();
    await _command(['playlist-next-playlist']);
  }

  /// Jumps to the first of the previous entries whose source playlist
  /// (`playlist-path`) differs from the current one. The reverse of
  /// [nextPlaylist].
  Future<void> previousPlaylist() async {
    await _gate();
    // See [next] — in-flight transport writes apply to the old entry.
    await _settleWrites();
    await _command(['playlist-prev-playlist']);
  }

  /// Jumps to the track at [index] in the playlist and starts playback.
  ///
  /// Unpauses synchronously *before* issuing the playlist jump so the new
  /// track starts playing as soon as `MPV_EVENT_FILE_LOADED` arrives — no
  /// shared `_pendingPlay` field to race on with concurrent `open()` calls.
  Future<void> jump(int index) async {
    await _gate();
    // See [next] — in-flight transport writes apply to the old entry.
    await _settleWrites();
    // Optimistic intent, same as play(): this call unpauses, and `pause`
    // is deliberately unobserved, so skipping the write here would leave
    // `state.playWhenReady` (and the OS play/pause button bound to it)
    // stuck on "paused" while audio is audibly playing.
    _updateField((s) => s.copyWith(playWhenReady: true),
        _reactives.playWhenReady, true,);
    // See [Player.open] — parked at EOF (`keep-open`) the unpause above
    // doesn't survive: the playloop hits EOF again and re-pauses before
    // the jump command is processed. The corrective write after it sticks.
    final parkedAtEof = _state.completed;
    await _prop('pause', 'no');
    await _commandChecked(['playlist-play-index', index.toString()]);
    if (parkedAtEof) {
      await _prop('pause', 'no');
    }
  }

  /// Moves the track at [from] to position [to].
  ///
  /// Throws [MpvException] if either index is out of range.
  Future<void> move(int from, int to) async {
    await _gate();
    await _commandChecked(['playlist-move', from.toString(), to.toString()]);
  }

  /// Replaces the track at [index] with a new [media] item.
  ///
  /// `media.httpHeaders` ride along as file-local options on the
  /// inserted entry, same as [add] / [Player.open].
  ///
  /// When [index] is the currently-playing entry, the swap is routed
  /// through `playlist-next` so it inherits mpv's prefetch-driven
  /// transition path instead of stopping and restarting playback.
  /// (Audible only with `--prefetch-playlist=yes`, the default for
  /// this build.)
  Future<void> replace(int index, Media media) async {
    _checkNotDisposed();
    // Snapshot the load epoch — same staleness rule as [add].
    final epoch = _loadEpoch;
    await _gate();
    _validateLoadOptions(media);
    _mediaCache[media.uri] = media;
    final resolved = await resolveUri(media.uri);
    if (_disposed || epoch != _loadEpoch) {
      await resolved.dispose?.call();
      return;
    }
    _mediaCache[resolved.uri] = media;
    // Execute in-flight transport writes before the playlist surgery —
    // see [_settleWrites].
    await _settleWrites();
    if (_disposed || epoch != _loadEpoch) return;
    final (posErr, posValue) =
        await _getAsync('playlist-pos', MpvFormat.mpvFormatString);
    if (_disposed || epoch != _loadEpoch) return;
    final currentPos =
        posErr < 0 ? -1 : (int.tryParse(posValue as String? ?? '') ?? -1);
    final opts = _buildLoadfileOptions(media);
    Future<int> insertAt(int at) {
      if (opts.isEmpty) {
        return _command(['loadfile', resolved.uri, 'insert-at', at.toString()]);
      }
      // 4th-arg options require an explicit index argument (mpv 0.38+).
      return _command(
          ['loadfile', resolved.uri, 'insert-at', at.toString(), opts],);
    }

    // Re-check the epoch between each of the multi-command surgeries below:
    // every await now spans an event-isolate reply round-trip, during which a
    // concurrent content-replacing call (stop / open / clearPlaylist) can bump
    // _loadEpoch and own the queue. Without the guard, `playlist-next force`
    // would RESTART playback a concurrent stop() meant to halt, and
    // `playlist-remove` would delete a now-stale index. Bail and let the later
    // call own the surgery, matching the open() family's per-await discipline.
    bool superseded() => _disposed || epoch != _loadEpoch;
    if (currentPos == index) {
      // Currently-playing entry: insert the replacement right after
      // the active position, then advance — mpv's playlist-prefetch
      // (already triggered by the insert) makes the cross-fade
      // gapless for typical music files. Finally drop the original.
      await insertAt(index + 1);
      if (superseded()) return;
      await _command(['playlist-next', 'force']);
      if (superseded()) return;
      await _command(['playlist-remove', index.toString()]);
    } else {
      await _command(['playlist-remove', index.toString()]);
      if (superseded()) return;
      await insertAt(index);
    }
  }

  /// Clears the playlist, **including the currently-playing track**.
  /// Playback stops; `state.playlist.items` becomes empty and
  /// `state.playing` becomes `false`. Use [remove] for selective
  /// clearing that keeps the active entry alive.
  Future<void> clearPlaylist() async {
    _checkNotDisposed();
    // Claim the load epoch synchronously so an in-flight open()/add()
    // can't repopulate the queue this call is clearing (see [Player.open]).
    final epoch = ++_loadEpoch;
    await _gate();
    _mediaCache.clear();
    // Execute in-flight transport writes first — see [_settleWrites].
    await _settleWrites();
    if (_disposed || epoch != _loadEpoch) return;
    // mpv's `playlist-clear` alone keeps the active entry; the
    // explicit `playlist-remove current` makes the call match the
    // method name.
    await _command(['playlist-clear']);
    if (_disposed || epoch != _loadEpoch) return;
    await _command(['playlist-remove', 'current']);
  }

  /// Sets the playlist repeat mode.
  ///
  /// Backed by two mpv properties (`loop-file` + `loop-playlist`); if
  /// the second write fails the first is rolled back so the consumer
  /// never observes a half-applied loop mode.
  Future<void> setLoop(Loop loop) async {
    await _gate();
    String loopFile(Loop l) => l == Loop.file ? 'inf' : 'no';
    String loopPlaylist(Loop l) => l == Loop.playlist ? 'inf' : 'no';
    final previous = state.loop;
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
        await _prop(w.$1, w.$2);
        done.add(w);
      }
    } catch (_) {
      for (final (name, _, prior) in done.reversed) {
        await _propRc(name, prior);
      }
      rethrow;
    }
    // Optimistic update — `state.loop` reflects the requested mode
    // without waiting for the two underlying observers to round-trip.
    _updateField((s) => s.copyWith(loop: loop), _loop, loop);
  }

  /// Enables or disables shuffle mode.
  Future<void> setShuffle(bool shuffle) async {
    await _gate();
    await _prop('shuffle', shuffle ? 'yes' : 'no');
    if (shuffle) {
      await _command(['playlist-shuffle']);
    } else {
      await _command(['playlist-unshuffle']);
    }
    _updateField(
        (s) => s.copyWith(shuffle: shuffle), _reactives.shuffle, shuffle,);
  }

  /// Enables or disables background prefetch of the next playlist item.
  ///
  /// When enabled, mpv opens the demuxer for the next track before the
  /// current one finishes, so playback continues without an opening-thread
  /// stall on file boundaries. Observe progress via
  /// [PlayerStream.prefetchState].
  Future<void> setPrefetchPlaylist(bool enabled) async {
    await _gate();
    await _prop('prefetch-playlist', enabled ? 'yes' : 'no');
    _updateField((s) => s.copyWith(prefetchPlaylist: enabled),
        _reactives.prefetchPlaylist, enabled,);
  }
}
