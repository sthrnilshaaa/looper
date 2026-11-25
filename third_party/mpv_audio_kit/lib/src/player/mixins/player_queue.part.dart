// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
part of '../player.dart';

/// The queue: add, insert, remove, move, replace and clear. Navigation
/// and the repeat, shuffle and prefetch modes live in `_NavigationModule`.
mixin _QueueModule on _PlayerBase, _LoadfileModule {
  /// Appends [media] to the end of the current playlist.
  ///
  /// `media.httpHeaders` ride along as the 4th `loadfile` argument
  /// (mpv 0.38+: `loadfile <url> append -1 <opts>`), so mpv scopes
  /// them as file-local for this exact entry, even if the entry
  /// only loads minutes later when playback advances.
  Future<void> add(Media media) async {
    _checkNotDisposed();
    final opts = loadfileOptions(media);
    // Snapshot (not bump: appends don't supersede each other) the load
    // epoch: if a content-replacing call (open, stop, clearPlaylist)
    // lands while this append is still resolving its URI, the append is
    // stale and must not graft the old queue's entry onto the new one.
    final load = _transport.snapshotLoad();
    await _gate();
    await _addEntry(media, opts, load);
  }

  /// Inserts [media] at [index] in the playlist: the entry there and the
  /// ones after it move down by one, and [index] equal to the playlist
  /// length appends, as [add] does. The current entry keeps playing.
  ///
  /// The per-entry options of [media] ride along as in [add]. To play it
  /// next, pass `state.playback.playlist.index + 1`.
  ///
  /// Throws [RangeError] if [index] is outside `0..length`.
  Future<void> insert(int index, Media media) async {
    _checkNotDisposed();
    RangeError.checkNotNegative(index, 'index');
    final opts = loadfileOptions(media);
    // The same staleness rule as [add].
    final load = _transport.snapshotLoad();
    await _gate();
    // mpv's own count, as in [move]: the state can lag an add in flight.
    final (rc, count) = await _calls.get(
      'playlist-count',
      MpvFormat.mpvFormatInt64,
    );
    if (_disposed) return;
    RangeError.checkValueInInterval(
      index,
      0,
      _entries.fromCoreCount(rc < 0 ? 0 : count as int),
      'index',
    );
    await _addEntry(media, opts, load, at: _entries.toCore(index));
  }

  /// The load of [add] and [insert]: resolves [media] and appends it with
  /// its [opts], or inserts it at [at]. An index past the end, after a
  /// concurrent remove, appends in mpv.
  Future<void> _addEntry(
    Media media,
    String opts,
    _LoadTicket load, {
    int? at,
  }) async {
    // Kept from the cache prune until mpv has the entry.
    _mediaCache.entryLoads++;
    try {
      _mediaCache[media.uri] = media;
      final source = OwnedSource(await resolveUri(media.uri));
      // Released on every way out unless mpv took the entry: a later load,
      // or a refusal, after which nothing will ever read the source.
      try {
        if (load.superseded) return;
        _mediaCache[source.uri] = media;
        await _forgetFdResume(source.uri);
        await _loadfile(
          loadfileArgs(
            source.uri,
            at == null ? 'append' : 'insert-at',
            opts,
            at: at,
          ),
          media,
          source,
        );
      } finally {
        await source.release();
      }
    } finally {
      _mediaCache.entryLoads--;
    }
  }

  /// Throws [RangeError] unless [index] is a valid playlist position, per
  /// mpv's own `playlist-count` (the Dart state can lag behind an `add`
  /// still in flight). Returns the count, or `null` when a dispose landed
  /// meanwhile: it drained the read as failed, and the call then ends
  /// without effect, like any call under way at dispose, instead of
  /// reporting an index out of an empty playlist.
  Future<int?> _checkPlaylistIndex(int index, String name) async {
    final (rc, value) = await _calls.get(
      'playlist-count',
      MpvFormat.mpvFormatInt64,
    );
    if (_disposed) return null;
    // The entry openAll holds in mpv after its jump is not in the state.
    final count = _entries.fromCoreCount(rc < 0 ? 0 : value as int);
    RangeError.checkValidIndex(index, null, name, count);
    return count;
  }

  /// Removes the track at [index] from the playlist.
  ///
  /// Throws [RangeError] if [index] is out of range.
  Future<void> remove(int index) async {
    RangeError.checkNotNegative(index, 'index');
    await _gate();
    if (await _checkPlaylistIndex(index, 'index') == null) return;
    await _calls.commandChecked([
      'playlist-remove',
      _entries.toCore(index).toString(),
    ]);
  }

  /// Moves the track at [from] to position [to].
  ///
  /// Throws [RangeError] if [from] is out of range, or [to] is outside
  /// `0..length` (`length` moves the track to the end).
  Future<void> move(int from, int to) async {
    RangeError.checkNotNegative(from, 'from');
    RangeError.checkNotNegative(to, 'to');
    await _gate();
    final count = await _checkPlaylistIndex(from, 'from');
    if (count == null) return;
    RangeError.checkValueInInterval(to, 0, count, 'to');
    await _calls.commandChecked([
      'playlist-move',
      _entries.toCore(from).toString(),
      _entries.toCore(to).toString(),
    ]);
  }

  /// Replaces the track at [index] with a new [media] item.
  ///
  /// `media.httpHeaders` ride along as file-local options on the
  /// inserted entry, same as [add] and [Player.open].
  ///
  /// When [index] is the currently-playing entry, the swap is routed
  /// through `playlist-next` so it inherits mpv's prefetch-driven
  /// transition path instead of stopping and restarting playback.
  /// (Audible only with [setPrefetchPlaylist] on, which is off by
  /// default.)
  Future<void> replace(int index, Media media) async {
    _checkNotDisposed();
    RangeError.checkNotNegative(index, 'index');
    final opts = loadfileOptions(media);
    // Snapshot the load epoch: same staleness rule as [add].
    final load = _transport.snapshotLoad();
    await _gate();
    if (await _checkPlaylistIndex(index, 'index') == null) return;
    // As in [_addEntry].
    _mediaCache.entryLoads++;
    try {
      _mediaCache[media.uri] = media;
      final source = OwnedSource(await resolveUri(media.uri));
      // Until mpv takes the entry its source is this call's to release, on
      // every way out: a later load, a command that fails. Once taken, it
      // stays with [_entries] while mpv lists it.
      try {
        if (load.superseded) return;
        _mediaCache[source.uri] = media;
        await _forgetFdResume(source.uri);
        // Execute in-flight transport writes before the playlist surgery:
        // see [CoreCalls.settleWrites].
        await _calls.settleWrites();
        if (load.superseded) return;
        final (posErr, posValue) = await _calls.get(
          'playlist-pos',
          MpvFormat.mpvFormatString,
        );
        if (load.superseded) return;
        final currentPos = posErr < 0
            ? -1
            : (int.tryParse(posValue as String? ?? '') ?? -1);
        // mpv's index, against mpv's position: see [EntryTable.toCore].
        final at = _entries.toCore(index);
        Future<void> insertAt(int at) => _loadfile(
          loadfileArgs(source.uri, 'insert-at', opts, at: at),
          media,
          source,
        );

        // Re-check the epoch between each of the multi-command surgeries
        // below: every await now spans an event-isolate reply round-trip,
        // during which a concurrent content-replacing call (stop, open,
        // clearPlaylist) can claim the load epoch and own the queue. Without the
        // guard, `playlist-next force` would RESTART playback a concurrent
        // stop() meant to halt, and `playlist-remove` would delete a now-stale
        // index. Bail and let the later call own the surgery, matching the
        // open() family's per-await discipline.
        if (currentPos == at) {
          // Currently-playing entry: insert the replacement right after
          // the active position, then advance: with prefetch on (see
          // [setPrefetchPlaylist]) mpv has the next entry open ahead, so the
          // switch is gapless for typical music files. Finally drop the
          // original.
          await insertAt(at + 1);
          if (load.superseded) return;
          await _calls.commandChecked(['playlist-next', 'force']);
          if (load.superseded) return;
          await _calls.commandChecked(['playlist-remove', at.toString()]);
        } else {
          await _calls.commandChecked(['playlist-remove', at.toString()]);
          if (load.superseded) return;
          await insertAt(at);
        }
      } finally {
        await source.release();
      }
    } finally {
      _mediaCache.entryLoads--;
    }
  }

  /// Clears the playlist, **including the currently-playing track**.
  /// Playback stops; `state.playback.playlist.items` becomes empty and
  /// `state.playback.playing` becomes `false`. Use [remove] for selective
  /// clearing that keeps the active entry alive.
  ///
  /// With [keepCurrent] true only the other entries go: the current one
  /// keeps playing as the only entry. With nothing current, both forms
  /// empty the playlist. Either way an open, openAll or add still
  /// resolving its source when this is called does not load.
  Future<void> clearPlaylist({bool keepCurrent = false}) async {
    _checkNotDisposed();
    // Claim the load epoch synchronously so an in-flight open()/add()
    // can't repopulate the queue this call is clearing (see [Player.open]).
    final load = _transport.claimLoad();
    await _gate();
    // The kept entry keeps its Media, under every URI it is cached by: the
    // source resolver looks it up there when the entry loads again (a
    // playlist loop).
    final playlist = _state.playback.playlist;
    final current = keepCurrent && playlist.index >= 0
        ? playlist.items.elementAtOrNull(playlist.index)
        : null;
    _mediaCache.keepOnly(current);
    // Execute in-flight transport writes first; see [CoreCalls.settleWrites].
    await _calls.settleWrites();
    if (load.superseded) return;
    // mpv's `playlist-clear` alone keeps the active entry; the
    // explicit `playlist-remove current` makes the call match the
    // method name.
    await _calls.commandChecked(['playlist-clear']);
    if (load.superseded || keepCurrent) return;
    // Fails when nothing is current (an idle player): nothing to clear then.
    await _calls.command(['playlist-remove', 'current']);
  }
}
