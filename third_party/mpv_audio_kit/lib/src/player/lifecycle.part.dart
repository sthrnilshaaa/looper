// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
part of 'player.dart';

/// The lifecycle flags (playing, buffering, completed) and the end of
/// content: where the core stands against the end of the file, the
/// `completed` it settles, and the per-file state cleared at a track
/// boundary or once no file is loaded.
extension _Lifecycle on _PlayerBase {
  /// Whether mpv reached the end of the current file, parked by
  /// `keep-open` or about to park, read from the core's own `eof-reached`
  /// rather than from `state.playback.completed`. That flag comes from the
  /// event isolate's [MpvEventEndOfContent] reads, which reach the main isolate
  /// behind the events still queued ahead of them: right after a short
  /// last entry parks, `completed` can still be false. The calls that
  /// replace or jump need the core's answer at the call: an unpause
  /// written while mpv is about to park does not survive the park, so
  /// they write it again after the load. [Player.play] reads it too, after
  /// its seek back from the park, to tell a seek that could not leave the
  /// end.
  Future<bool> _parkedAtEof() async =>
      await _readString('eof-reached') == 'yes';

  /// Whether mpv is parked: keep-open paused at the end of the file once
  /// the output buffer played out (`keep-open-parked`). In the last buffer
  /// before that, `eof-reached` is already true while the audio still
  /// plays, and a pause of the client there keeps the rest for [play].
  /// Without `keep-open-pause` no park comes: at the end and paused is the
  /// closest.
  ///
  /// The reads are statements, not the sides of `&&`: compiled to
  /// WebAssembly, an await there traps once the left side is false (see
  /// `_sendEndOfContent`).
  Future<bool> _parkedPaused() async {
    if (await _readString('keep-open-parked') == 'yes') return true;
    if (await _readString('keep-open-pause') != 'no') return false;
    if (!await _parkedAtEof()) return false;
    return await _readString('pause') == 'yes';
  }

  /// Clears the per-track fields a consumer is likely to read
  /// synchronously on a track-change boundary (the public open()
  /// path returns before the new file's MPV_EVENT_FILE_LOADED
  /// fires).
  ///
  /// Restricted to fields where mpv re-emits the new value reliably
  /// after the load. mpv's own observer (see
  /// `player/client.c::send_client_property_changes`) dedupes on
  /// `equal_mpv_value(prop->value, val)`, so any property whose new
  /// value happens to match the previously-observed value (same
  /// `duration` across two tracks; same `embedded-cover-art-data`
  /// for same-album files; same `chapter-list`) would NOT fire
  /// PROPERTY_CHANGE. Wrapper-side reset to defaults on those would
  /// strand the cell at the default until the next genuinely-new
  /// value arrives. `position` is safe because `time-pos` re-emits
  /// at ~30Hz during playback. The remaining fields are handled by
  /// custom paths that do not depend on mpv's observer dedup.
  void _clearPerFileState() {
    // A load that resumes while dispose runs: the streams are closed, or
    // about to be.
    if (_disposed) return;
    final r = _reactives;
    r.position.update(Duration.zero);
    r.currentChapter.update(null);
    r.chapters.update(const <Chapter>[]);
    _state = _state.copyWith(
      position: Duration.zero,
      coverArt: null,
      currentChapter: null,
      chapters: const <Chapter>[],
    );
    _streams.coverArt.add(null);
  }

  /// Clears what [_clearPerFileState] clears plus the file's waveform and
  /// loudness scan, once mpv is idle with no file loaded: it reports path,
  /// title and duration unavailable then, and these would otherwise keep
  /// showing the file that ended. The end of content under `keep-open`
  /// keeps the file loaded, and its cover with it.
  void _clearFinishedFile() {
    if (_disposed) return;
    _clearPerFileState();
    _waveformPipeline.clear();
    _loudnessScanPipeline.clear();
  }

  /// Updates the lifecycle triple (playing, buffering, completed) and
  /// emits per-reactive only for fields that actually changed. Used
  /// for compound transitions (start-file, file-loaded, end-file,
  /// end of content, shutdown, idle-active). With `completed`, how the
  /// entry ended ([readError], [skippedSegments]) goes into the state
  /// before the flag is emitted. The pure diff lives in [computeLifecycle].
  void _updateLifecycle({
    bool? playing,
    bool? buffering,
    bool? completed,
    bool? readError,
    int? skippedSegments,
  }) {
    final result = computeLifecycle(
      prev: _state,
      playing: playing,
      buffering: buffering,
      completed: completed,
      readError: readError,
      skippedSegments: skippedSegments,
    );
    _state = result.newState;
    if (result.playingDidChange) _reactives.playing.update(playing!);
    if (result.bufferingDidChange) _streams.buffering.update(buffering!);
    if (result.completedDidChange) _streams.completed.update(completed!);
  }

  /// Settles `completed` from where the core stands against the end of
  /// content, as the event isolate read it ([MpvEventEndOfContent]): the
  /// current file is parked at its end ([parked]) and is the last playlist
  /// entry ([lastEntry]), with no loop that will restart it. `keep-open:
  /// yes` (shipped pre-init option) makes mpv park paused on the last frame
  /// there and withhold both MPV_EVENT_END_FILE and idle-active, so the two
  /// writers that otherwise settle the transport (the END_FILE completed
  /// flag and the idle-active intent reset) never fire for the last entry.
  /// The park, not `eof-reached`, is the end: with gapless audio mpv
  /// reports EOF once the decoder is done, an output buffer before the end
  /// is heard, and pauses only after that buffer has played.
  ///
  /// It is a level, read again at every load, restart, `eof-reached`,
  /// `pause` and `loop-*` notification, not the observed `eof-reached` edge
  /// matched against `state.playback.playlist`: mpv samples observed
  /// properties once per playloop iteration, so an entry that reaches EOF as
  /// soon as it loads can go from the previous entry's EOF to its own without
  /// a change being reported, and the state's playlist position can lag or
  /// lead the entry an edge belonged to. That raised `completed` at a track
  /// change, cleared by the next load, and missed the real end.
  ///
  /// A live PCM entry ([live]) has no restart either: it plays once and
  /// parks under [Loop.file] too (F225). [readError] and [skippedSegments],
  /// read at the park, tell how the entry ended, also at a park the player
  /// never saw left.
  void _settleEndOfContent({
    required bool parked,
    required bool lastEntry,
    required bool live,
    bool? readError,
    int? skippedSegments,
  }) {
    if (!_transport.hasLoadedFile) return;
    final loop = _state.playback.loop;
    final end =
        parked &&
        lastEntry &&
        (loop == Loop.off || (live && loop == Loop.file));
    // With `completed` as it was, this only refreshes how the entry ended:
    // mostly a second read of the same park (its pause and eof-reached
    // notifications each send one), with the same values. They differ
    // when a read that came late (or was held) raised `completed` before
    // this park, so the restart that left the end was not seen between
    // them (see [_handleEvent]). Away from the end both are already clear.
    _updateLifecycle(
      completed: end,
      readError: readError,
      skippedSegments: skippedSegments,
    );
    // The play-pause intent is spent at the end of content, once per park:
    // the reads that follow find the same park and keep what a call wrote
    // since. A call that leaves the park (play() seeking back, a jump, a
    // load) takes it, so a read of the park it leaves, still on its way,
    // keeps the call's intent; landed at the end again, the read after the
    // move belongs to a new park and spends. A park reached while a load
    // runs waits for the load, which leaves it (see [TransportMachine.park]).
    if (end) _transport.onEndOfContent();
  }
}
