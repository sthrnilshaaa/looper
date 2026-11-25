// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
part of '../player.dart';

/// Transport setters: play, pause, stop, seek, chapter navigation,
/// and the A-B loop controls.
mixin _PlaybackModule on _PlayerBase, _PropertiesModule {
  /// Starts or resumes playback. Idempotent: a no-op when already playing,
  /// including the last moments of the queue while the output buffer still
  /// plays. Once the queue has ended ([PlaybackState.completed]) it starts the
  /// last track again from its beginning; a source that cannot seek back there
  /// (a live stream, a closed [PcmSource]) stays at its end and the intent
  /// stays off. With nothing loaded (before any open, after [stop]) there is
  /// nothing to resume and the intent stays off too; after
  /// `stop(keepPlaylist: true)` it starts the entry that stopped from its
  /// beginning, as [jump] does. The future completes once mpv has taken the
  /// unpause; the playback itself is observable via [PlayerStream.playing].
  /// A [pause], [stop] or load called after it has the last word: then it
  /// writes nothing.
  ///
  /// On the web it also resumes the page's audio output when the
  /// browser's autoplay policy holds it (see
  /// [MpvAudioKit.needsUserGesture]): called from a user gesture, as from
  /// a play button, the sound starts.
  Future<void> play() async {
    // Before any await: still inside the gesture that called it.
    resumeOutput();
    await _gate();
    // Optimistic intent: `pause` is silent on the first load → playing
    // transition, so set the intent axis here rather than relying on the
    // observer. See [PlaybackState.playWhenReady].
    final intent = _transport.claimIntent(true);
    // Parked at the end (`keep-open`), an unpause alone is undone by the
    // playloop hitting EOF again, and the intent would show playing over
    // silence. Seek back first; the unpause after it sticks, as in [jump].
    // In the last buffer before the park mpv is not paused yet and the
    // audio still plays: nothing to do but the unpause.
    final parked = await _parkedPaused();
    // A later call claimed the transport during the reads: its pause write
    // is already out, and an unpause written now would undo it.
    if (!_transport.owns(intent)) return;
    if (parked) {
      // The seek leaves the park. Taken here, the park the reads saw spends
      // nothing more and the intent shows playing at once, without a
      // flicker. That is not the park the seek leaves when an earlier move
      // is still on its way (a seek to the end called just before): its
      // restart opens a new park, whose read can spend the intent before
      // this seek runs. So the park is taken again after the seek's reply,
      // which mpv queues ahead of the seek's own restart: that take is the
      // generation this seek leaves, whatever came between, and a spend in
      // between is undone. Landed at the end again, the seek's restart
      // opens a new park, whose read spends the intent whether it comes
      // before or after the replies below. A play() called since leaves
      // the take to this reply: its own seek or unpause does not leave
      // this park.
      _transport.takePark();
      _transport.writeIntent(true);
      await _calls.command(['seek', '0', 'absolute']);
      if (_transport.wantsPlay(intent)) {
        _transport.takePark();
        _transport.writeIntent(true);
      }
      // A seek that landed has left EOF by the next read: the seek wakes
      // the core, which runs it before it serves another request. Still at
      // EOF on a source that cannot seek, it failed. The unpause would only
      // be paused again by keep-open, too fast for a notification, so it
      // is not written and the intent goes back off. Not while a load is
      // running: it replaces the parked file (openAll removes it first), so
      // the reads tell nothing about the source, and the unpause arms the
      // load.
      // Statements, not one `&&` chain: compiled to WebAssembly, an await
      // on the right of `&&` traps when the left decides (see
      // `_sendEndOfContent`).
      var stuck = _transport.loadsInFlight == 0;
      if (stuck) stuck = await _parkedAtEof();
      if (stuck) stuck = await _readString('seekable') != 'yes';
      if (stuck && _transport.loadsInFlight == 0) {
        if (_transport.owns(intent)) _transport.writeIntent(false);
        return;
      }
      if (!_transport.owns(intent)) return;
      await _calls.prop('pause', 'no');
      return;
    }
    await _calls.prop('pause', 'no');
    // Idle with nothing to play (before any open, after stop or a failed
    // load): the unpause only arms the next load, nothing plays now. Not
    // while a load is running, which is about to give the core content.
    var idle = _transport.loadsInFlight == 0;
    if (idle) idle = await _readString('idle-active') == 'yes';
    if (idle && _transport.loadsInFlight == 0 && _transport.owns(intent)) {
      await _playOnIdle(intent);
    }
  }

  /// Pauses playback. Idempotent: a no-op when already paused. Position
  /// is preserved: call [play] to resume from the same offset.
  Future<void> pause() {
    _mediaSessionController?.appPaused();
    return _pause();
  }

  /// [pause] for a command of the media session: not the app's own, so it
  /// leaves the resume of a call to the native side.
  Future<void> _pause() async {
    await _gate();
    _transport.claimIntent(false);
    await _calls.prop('pause', 'yes');
  }

  /// Writes mpv's "watch later" resume config for the current file, saving the
  /// playback position (plus a curated set of audio props) so a later
  /// [Player.open] of the same file resumes from here. Playback continues.
  ///
  /// Pairs with [PlayerConfiguration.resumePlayback] (on by default) and
  /// [PlayerConfiguration.watchLaterDir]. On mobile, set `watchLaterDir` to a
  /// writable path or the write silently fails.
  ///
  /// mpv saves only the values that differ from the ones it had at
  /// startup. [PlayerConfiguration.initialVolume] applies after startup,
  /// so for the volume that base is 100: a volume of 100 is not saved, and
  /// reopening the file keeps the volume of the moment.
  ///
  /// A restored value becomes the player's own: it stays for the files
  /// that follow, until the app sets another. To keep a value per file,
  /// set it again when the next file opens.
  ///
  /// An Android `content://` source has no resume point: it plays from a
  /// file descriptor, whose number the system gives again to other files.
  /// For it the call writes nothing and says so on
  /// [PlayerStream.internalLog].
  Future<void> writeResumeConfig() async {
    await _gate();
    final (rc, path) = await _calls.get('path', MpvFormat.mpvFormatString);
    if (rc >= 0 && path is String && isFdUri(path)) {
      _internalLog(
        'No resume point for $path: a descriptor number names another '
        'file once it is closed.',
      );
      return;
    }
    await _calls.commandChecked(['write-watch-later-config']);
  }

  /// Deletes the "watch later" resume config for the current file, or for
  /// [filename] when given, clearing any saved resume point.
  ///
  /// Name [filename] as the [Media] given to [Player.open]: a `file://`
  /// URL or an `asset://` URI stands for the path the load gives mpv,
  /// which keys the resume point.
  Future<void> deleteResumeConfig({String? filename}) async {
    await _gate();
    final args = ['delete-watch-later-config'];
    // Not an await under `?:` or a collection if: compiled to WebAssembly
    // those trap when the other branch is taken (see `_sendEndOfContent`).
    if (filename != null) args.add(await loadedName(filename));
    await _calls.command(args);
  }

  /// Stops playback and unloads the current file. Distinct from [pause]:
  /// the demuxer is torn down and the playhead is reset.
  ///
  /// By default the playlist is cleared, and the next call must be [open]
  /// (not [play]) to start a new track. With [keepPlaylist] the entries
  /// stay and `state.playback.playlist.index` stays on the entry that
  /// stopped, with no file loaded: [play] starts that entry from its
  /// beginning, [jump] starts another, and [Player.next] and
  /// [Player.previous] move to the entry after or before it without
  /// loading it (wrapping around with [Loop.playlist]). Removed before the
  /// [play], the entry leaves nothing to start. A live PCM entry stays
  /// without its source, as after a skip (see [PcmSource]).
  ///
  /// The media session shows the stop where the platform has a stopped
  /// state: MPRIS reports `Stopped` on Linux.
  Future<void> stop({bool keepPlaylist = false}) {
    _mediaSessionController?.appPaused();
    return _stop(keepPlaylist: keepPlaylist);
  }

  /// [play] on an idle core: after stop(keepPlaylist: true) the entry that
  /// stopped starts; with nothing to start the intent goes back off.
  Future<void> _playOnIdle(int intent) async {
    if (await _resumeKeptStop(intent)) return;
    // The resume read the core: a call since may own the intent now.
    if (_transport.owns(intent) && _transport.loadsInFlight == 0) {
      _transport.writeIntent(false);
    }
  }

  /// Starts the entry a kept stop left, for the [play] that claimed
  /// [intent] on an idle core and has written the unpause. Whether it did.
  Future<bool> _resumeKeptStop(int intent) async {
    if (_entries.stopped == null || _entries.hiddenAt != null) return false;
    final node = await _readPlaylist() ?? const <Object?>[];
    // A pause() called since keeps the entry for the next play().
    if (!_transport.owns(intent)) return false;
    // Read after the await: a next() or previous() since moved it.
    final id = _entries.stopped;
    _entries.stopped = null;
    final index = node.indexWhere((e) => e is Map && e['id'] == id);
    if (id == null || index < 0) return false;
    await _calls.commandChecked(['playlist-play-index', '$index']);
    if (_transport.wantsPlay(intent)) _transport.writeIntent(true);
    return true;
  }

  /// The playlist and the position in it of the entry a kept stop holds
  /// (-1 when it left the playlist), while the core is idle; `null`
  /// otherwise.
  Future<(List<Object?>, int)?> _keptStopEntry() async {
    final id = _entries.stopped;
    if (id == null || _transport.loadsInFlight != 0) return null;
    if (_entries.hiddenAt != null) return null;
    if (await _readString('idle-active') != 'yes') return null;
    final node = await _readPlaylist();
    if (node == null || _entries.stopped != id) return null;
    return (node, node.indexWhere((e) => e is Map && e['id'] == id));
  }

  /// After stop(keepPlaylist: true), moves the entry that stopped by
  /// [delta] with no file loaded, wrapping around with [Loop.playlist]:
  /// whether it moved, or `null` when no kept stop holds the core.
  Future<bool?> _moveKeptStop(int delta) async {
    final kept = await _keptStopEntry();
    if (kept == null) return null;
    final (node, at) = kept;
    if (at < 0) {
      // The entry left the playlist: nothing to move from, and mpv, with
      // no current entry, would load the last or the first.
      _entries.stopped = null;
      return false;
    }
    var to = at + delta;
    if (to < 0 || to >= node.length) {
      if (_state.playback.loop != Loop.playlist) return false;
      to %= node.length;
    }
    final entry = node[to];
    if (entry is! Map || entry['id'] is! int) return false;
    _entries.stopped = entry['id'] as int;
    // A fresh read: a remove or a move since may have changed the list.
    final fresh = await _readPlaylist();
    if (fresh != null) _updatePlaylistFromNode(fresh);
    return true;
  }

  /// mpv's id of the current entry, or `null` when there is none.
  Future<int?> _currentEntryId() async {
    for (final entry in await _readPlaylist() ?? const <Object?>[]) {
      if (entry is Map && entry['current'] == true && entry['id'] is int) {
        return entry['id'] as int;
      }
    }
    return null;
  }

  /// [stop] for a command of the media session (see [_pause]).
  Future<void> _stop({bool keepPlaylist = false}) async {
    _checkNotDisposed();
    // Claim the load epoch synchronously so an in-flight open() that is
    // still resolving its URI aborts instead of resuming after this call
    // and restarting playback (see [Player.open]).
    _transport.claimLoad();
    await _gate();
    // Stop unloads the file; intent returns to "not playing" so the OS
    // button settles on play. mpv may not emit `pause` here, so set it.
    final intent = _transport.claimIntent(false);
    final starts = _entries.starts;
    // Execute in-flight transport writes first; see [CoreCalls.settleWrites].
    await _calls.settleWrites();
    final stoppedId = keepPlaylist ? await _currentEntryId() : null;
    await _calls.commandChecked(['stop', if (keepPlaylist) 'keep-playlist']);
    // A load called meanwhile, or the file it started, has the last word:
    // no entry to start again, no stopped state over its playback.
    if (_entries.starts == starts && _transport.loadsInFlight == 0) {
      _entries.stopped = stoppedId;
      // The app's stop and the session's own Stop: the OS shows it stopped
      // until the next load.
      _mediaSessionController?.stopped();
    }
    // Kept entries: mpv would play one its own playlist commands start
    // (a raw playlist-next) over the intent, which is off. Not over the
    // pause write of a call that claimed the intent since.
    if (keepPlaylist && _transport.owns(intent)) {
      await _calls.prop('pause', 'yes');
    }
    // mpv clears its playlist on stop but reports the change only when a
    // file was playing. Idle (after a failed load) it stays silent, so the
    // state would keep the old entries and the live sources they hold.
    final node = await _readPlaylist();
    if (node != null) _updatePlaylistFromNode(node);
  }

  /// Seeks playback to a position in the current file.
  ///
  /// With [relative] = `false` (default), [position] is an absolute
  /// timestamp from the start of the file: a negative one seeks to the
  /// start, and one past the end ends the file as if it played there.
  /// With [relative] = `true`, [position] is a signed offset from the
  /// current playhead: positive moves forward, negative moves backward.
  ///
  /// Examples:
  /// ```dart
  /// await player.seek(const Duration(seconds: 30));                    // jump to 0:30
  /// await player.seek(const Duration(seconds: -10), relative: true);   // skip back 10s
  /// await player.seek(const Duration(seconds: 30), relative: true);    // skip forward 30s
  /// ```
  ///
  /// Throws [MpvCommandException] if mpv rejects the seek: most commonly when
  /// nothing is loaded.
  Future<void> seek(
    Duration position, {
    bool relative = false,
    bool exact = false,
  }) async {
    await _gate();
    // mpv counts a negative absolute time from the end of the file, and
    // fails it when the length is unknown.
    final secs = !relative && position.isNegative
        ? 0.0
        : durationToSeconds(position);
    final mode = relative ? 'relative' : 'absolute';
    await _calls.commandChecked([
      'seek',
      secs.toStringAsFixed(6),
      exact ? '$mode+exact' : mode,
    ]);
  }

  /// Seeks by percentage of the file duration (0 to 100; past 100 the file
  /// ends). Absolute by default, or relative to the current percent position
  /// when [relative] is true.
  /// [exact] forces a sample-accurate (slower) seek instead of snapping to a
  /// keyframe. Counterpart of [seek] for progress-bar scrubbing.
  Future<void> seekToPercent(
    double percent, {
    bool relative = false,
    bool exact = false,
  }) async {
    _checkFinite(percent, 'percent');
    await _gate();
    final mode = relative ? 'relative-percent' : 'absolute-percent';
    await _calls.commandChecked([
      'seek',
      percent.toStringAsFixed(4),
      exact ? '$mode+exact' : mode,
    ]);
  }

  /// Jumps back to where playback was before the last jump in the current
  /// file (mpv's `revert-seek`). A jump is a [seek] or [seekToPercent], and
  /// also a chapter change, a return to A of the A-B loop, the restart
  /// [play] makes from the end, or a seek from the OS media session. Jumps
  /// less than about 2 seconds apart count as one. Calling it again undoes
  /// the revert.
  ///
  /// Throws [MpvCommandException] when the current file has nothing to
  /// undo yet, for example right after it loaded.
  Future<void> revertSeek() async {
    await _gate();
    await _calls.commandChecked(['revert-seek']);
  }

  /// Jumps to the chapter at [index] in the current file.
  ///
  /// Indexing is 0-based and matches [FileState.chapters]; -1 goes to
  /// the start of the file. mpv refuses any index outside -1 to
  /// `chapters.length - 1`, and the call then throws
  /// [MpvCommandException] with [PlaybackState.currentChapter] unchanged:
  /// check the length for a "next chapter" button. An accepted index
  /// reaches [PlaybackState.currentChapter] at once, and the next observer
  /// event confirms it.
  Future<void> setChapter(int index) async {
    await _gate();
    await _calls.prop('chapter', index.toString());
    // No chapter is `null` in the state, as the observer reports it.
    final shown = index < 0 ? null : index;
    _updateField(
      (s) => s.copyWith(currentChapter: shown),
      _reactives.currentChapter,
      shown,
    );
  }

  /// Replaces the current file's chapter markers with [chapters]: an
  /// "external chapters" injection for sources whose container carries none.
  ///
  /// The typical case is an audio stream extracted from a video platform
  /// or a podcast feed, whose chapters are published separately (e.g. in a
  /// description or a sidecar file) and not in the audio container, so a
  /// freshly-loaded stream has an empty
  /// `chapter-list`. This writes the list directly through the stable C API
  /// (`mpv_set_property` on `chapter-list`), so [PlayerStream.chapters] and
  /// [FileState.chapters] then reflect them and [setChapter] navigates them
  /// natively: no demuxer chapters required. Pass an empty list to clear.
  ///
  /// Timing: call this AFTER the file is loaded (e.g. on the first
  /// [PlayerStream.duration] event for the track). mpv resets `chapter-list`
  /// to the demuxer's own chapters on each load, so a write issued before the
  /// load settles would be overwritten.
  ///
  /// mpv keeps only the markers from 0 up to the end of the file, none when
  /// the length is unknown (a live stream), and does not sort them: pass
  /// the list in time order. The state takes the list mpv kept.
  Future<void> setChapters(List<Chapter> chapters) async {
    await _gate();
    final rc = await _calls.setChapterList(chapters);
    if (rc < 0) {
      throw MpvCommandException(
        name: 'chapter-list',
        code: rc,
        message: _calls.errorString(rc),
      );
    }
    // Read back what mpv kept: its observer reports nothing when that
    // equals its list before the write.
    final (readRc, node) = await _calls.get(
      'chapter-list',
      MpvFormat.mpvFormatNode,
    );
    if (_disposed) return;
    final list = readRc >= 0
        ? List<Chapter>.unmodifiable(parseChapterListNode(node))
        : List<Chapter>.unmodifiable(chapters);
    _updateField((s) => s.copyWith(chapters: list), _reactives.chapters, list);
  }

  // ── A-B loop ───────────────────────────────────────────────────────────────

  /// Sets the A-B loop start point. Pass `null` to disable.
  ///
  /// Combined with [setAbLoopB], creates a playback loop: when the head
  /// crosses the B point, mpv seeks back to A. Common in language-learning
  /// or audiobook apps for repeated practice of a passage.
  ///
  /// The points belong to the current file: when it ends, or another file
  /// loads, they go back to `null`. Points set with no file loaded apply to
  /// every file instead. Keep both inside the file: past its end, the end
  /// of the file seeks back to A again and again. A live [PcmSource] entry
  /// plays on past B.
  Future<void> setAbLoopA(Duration? position) async {
    await _write(
      'ab-loop-a',
      position == null ? 'no' : durationToSeconds(position).toStringAsFixed(6),
      _reactives.abLoopA,
      position,
      (s) => s.copyWith(abLoopA: position),
    );
  }

  /// Sets the A-B loop end point. Pass `null` to disable. Like A, it
  /// belongs to the current file. See [setAbLoopA].
  Future<void> setAbLoopB(Duration? position) async {
    await _write(
      'ab-loop-b',
      position == null ? 'no' : durationToSeconds(position).toStringAsFixed(6),
      _reactives.abLoopB,
      position,
      (s) => s.copyWith(abLoopB: position),
    );
  }

  /// Sets how many times playback jumps back to A after the first pass:
  /// with 3 the section is heard 4 times. Pass `null` for infinite looping
  /// (mpv's `inf`); `0` turns the A-B loop off even with both points set.
  /// Unlike the points, the count stays for the next files. Mirrors mpv's
  /// `--ab-loop-count` option. Throws [RangeError] for a negative count.
  Future<void> setAbLoopCount(int? count) async {
    // mpv keeps the count in a C int.
    if (count != null) {
      RangeError.checkValueInInterval(count, 0, 2147483647, 'count');
    }
    await _write(
      'ab-loop-count',
      count == null ? 'inf' : count.toString(),
      _reactives.abLoopCount,
      count,
      (s) => s.copyWith(abLoopCount: count),
    );
  }
}
