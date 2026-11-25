// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
part of '../player.dart';

/// How many `loadfile append` requests [Player.openAll] has in flight at
/// most: well under the 1000 replies mpv queues per client, so the appends
/// leave room for the events and the other calls.
const _kAppendWindow = 512;

/// Test only: awaited by [Player.openAll] between its jump to the new
/// entry and the removal of the old one it kept playing meanwhile, so a
/// test can hold that window open. Not exported, as
/// [debugBeforePcmCutRemove].
@visibleForTesting
Future<void> Function()? debugBeforeRetainedRemove;

/// The loads that replace the content: [Player.open], [Player.openAll] and
/// [Player.openPlaylistFile], with the entry bookkeeping of [Player.openAll]
/// (the old entry it keeps in mpv until its jump, hidden from the state
/// through [EntryTable.retained]). [Player] keeps the public methods and
/// their contract; the bodies run here.
mixin _OpenModule on _PlayerBase, _LoadfileModule {
  Future<void> _open(Media media, bool? play) async {
    _checkNotDisposed();
    // Validated and built before the first await, once.
    final opts = loadfileOptions(media);
    // Per-Media `httpHeaders` and `httpChunkSize` ride along as the 4th
    // `loadfile` arg, so mpv scopes them as file-local for this exact
    // playlist entry, never writing the global `http-header-fields` or
    // `stream-lavf-o`.
    await _replaceContent(
      media,
      play,
      entry: true,
      replace: (source) =>
          _loadfile(loadfileArgs(source.uri, 'replace', opts), media, source),
    );
  }

  /// The load that replaces the content with [media], for [Player.open]
  /// ([entry] true: [media] is the new entry) and [Player.openPlaylistFile]
  /// ([entry] false: mpv reads the list inside the command, and its
  /// entries are the playlist). [replace] sends the command from the
  /// resolved source, and throws when mpv refuses it.
  Future<void> _replaceContent(
    Media media,
    bool? play, {
    required bool entry,
    required Future<void> Function(OwnedSource source) replace,
  }) async {
    final load = _transport.claimLoad();
    await _gate();
    if (load.superseded) return;
    final shouldPlay = play ?? configuration.autoPlay;
    // Optimistic intent (the play-pause axis), written at the call point,
    // BEFORE the `resolveUri` and trust-bundle awaits below, so a play() or
    // pause() issued right after open() (without awaiting it) wins by call
    // order instead of racing this write past the I/O hops. mpv leaves
    // `pause` at `no` and fires no PROPERTY_CHANGE on the first autoplay
    // load, so the observer alone would never surface this intent.
    final previousIntent = _state.playback.playWhenReady;
    final intent = _transport.claimIntent(shouldPlay);
    _mediaCache.clear();
    if (entry) _mediaCache[media.uri] = media;
    final OwnedSource source;
    try {
      source = OwnedSource(await resolveUri(media.uri));
    } catch (_) {
      // Nothing was loaded: the intent goes back to what still plays.
      _transport.restoreIntent(load, intent, previousIntent);
      rethrow;
    }
    // Released on every way out unless mpv took the entry: a later load,
    // an error, a refusal. A playlist file is never handed over: nothing
    // reads the list itself again.
    try {
      if (load.superseded) return;
      if (entry) {
        _mediaCache[source.uri] = media;
        await _forgetFdResume(source.uri);
      }
      // Execute in-flight transport writes (e.g. an un-awaited seek) before
      // the replace below, so they apply to the OLD file; see
      // [CoreCalls.settleWrites].
      await _calls.settleWrites();
      if (load.superseded) return;
      // Captured BEFORE the pause write: when true, mpv is parked paused on
      // the last frame (`keep-open`), and the pre-loadfile `pause=no` below
      // does not survive: unpausing at EOF makes the playloop hit EOF again
      // and `keep-open-pause` re-pauses the core before the loadfile (queued
      // behind this write's async reply round-trip) is ever processed. The
      // corrective write after the replace is what actually sticks.
      final parkedAtEof = await _parkedAtEof();
      if (load.superseded) return;
      final playNow = _transport.intendedPlay(intent, shouldPlay);
      await _calls.prop('pause', playNow ? 'no' : 'yes');
      try {
        await replace(source);
      } catch (_) {
        await _undoIntent(load, intent, previousIntent, playNow: playNow);
        rethrow;
      }
      // The replace leaves the park of the old file: its START_FILE is
      // queued behind this reply, and can reach the player after the load
      // ends. A park of the old file reached while this load ran keeps the
      // intent (see [TransportMachine.park]).
      _transport.takePark();
      // Asked again, not reused: a pause() called while the command was in
      // flight has the last word.
      if (parkedAtEof && _transport.intendedPlay(intent, shouldPlay)) {
        await _calls.prop('pause', 'no');
      }
      // Drop visible per-track state (cover art, chapter list and current
      // chapter index) so a UI that reads the state immediately after
      // `open()` returns doesn't render the previous track's data. Placed
      // AFTER the command's reply (not before): the async writes above
      // suspend, and by FIFO port delivery every still-queued OLD-file
      // PROPERTY_CHANGE (e.g. a trailing `chapter-list`) has been received
      // and applied by the time that reply lands: clearing here is the last
      // word before return, so none of those stale events survive into the
      // post-`open()` snapshot. The NEW file's FILE_LOADED arrives later and
      // repopulates.
      _clearPerFileState();
    } finally {
      await source.release();
    }
  }

  /// mpv refused the command of a [_replaceContent], or could not read
  /// the list, and kept what it had: nothing will ever read the source,
  /// and the track there goes on with its own intent and pause. The
  /// [intent] and the pause [playNow] wrote go back to [previous], unless
  /// a later call took them over. Tolerant write, so the error the caller
  /// sees is the command's.
  Future<void> _undoIntent(
    _LoadTicket load,
    int intent,
    bool previous, {
    required bool playNow,
  }) async {
    if (_transport.restoreIntent(load, intent, previous) &&
        playNow != previous) {
      await _calls.propRc('pause', previous ? 'no' : 'yes');
    }
  }

  Future<void> _openAll(List<Media> requested, bool? play, int index) async {
    _checkNotDisposed();
    // A copy: the list is read across many awaits, and the caller's may
    // change meanwhile.
    final medias = List<Media>.of(requested, growable: false);
    if (medias.isEmpty) {
      return;
    }
    // Validate the full batch before any side-effect, so a bad header
    // on entry N can't leave entries 0..N-1 half-loaded: the options of
    // each entry, validated and built once.
    final options = [for (final m in medias) loadfileOptions(m)];
    // Claim the load epoch synchronously; see [Player.open].
    final load = _transport.claimLoad();
    await _OpenAllRun(this, medias, options, load).run(play, index);
  }

  Future<void> _openPlaylistFile(Media playlist, bool? play) async {
    _checkNotDisposed();
    rejectPcm(playlist, 'playlist');
    validateLoadOptions(playlist);
    await _replaceContent(
      playlist,
      play,
      entry: false,
      replace: (source) =>
          _calls.commandChecked(['loadlist', source.uri, 'replace']),
    );
  }
}
