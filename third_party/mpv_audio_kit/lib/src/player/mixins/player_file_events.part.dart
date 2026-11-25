// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

part of '../player.dart';

/// The file boundaries: START_FILE, FILE_LOADED with its payload
/// (position, chapters, embedded cover, source path, playlist),
/// PLAYBACK_RESTART, END_FILE and the end-of-content reads taken by the
/// event isolate.
mixin _FileEventsModule on _PlayerBase, _PropertiesModule {
  /// MPV_EVENT_PLAYBACK_RESTART at [timePos].
  void _onPlaybackRestart(double? timePos) {
    // A restart is a seek that landed: it left the park, even when
    // it lands on the end again (a seek past a cut whose read fails
    // again) or the play after it parks before any read of the
    // event isolate saw it move. It opens a new park generation:
    // the end-of-content read that follows the restart raises
    // `completed` again for that park, with how the entry ended this
    // time, and spends the play intent of the generation.
    _transport.onRestart();
    if (_state.playback.completed) _updateLifecycle(completed: false);
    _applyPolledPosition(timePos);
    _streams.seekCompleted.add(null);
  }

  /// The end-of-content read of the event isolate.
  void _onEndOfContent(MpvEventEndOfContent ended) {
    // Parked: the position where the file ended, before completed.
    if (ended.parked) _applyPolledPosition(ended.timePos);
    // The core's value at the read, ahead of a skipped or late
    // `eof-reached` notification.
    _dispatchProperty('eof-reached', ended.eof);
    _settleEndOfContent(
      parked: ended.parked,
      lastEntry: ended.lastEntry,
      live: ended.live,
      readError: ended.readError,
      skippedSegments: ended.skippedSegments,
    );
  }

  /// MPV_EVENT_START_FILE of entry [entryId].
  void _onStartFile(int entryId) {
    // Latch "a file load has been attempted" HERE, not on FILE_LOADED:
    // START_FILE fires for every load attempt, including one that will
    // fail to open, so a failed first open() still arms the
    // idle-active intent reset (otherwise its intent would stick true
    // forever). START_FILE is always delivered AFTER the cold-start
    // idle-active burst (FIFO), so the latch still can't be tripped by
    // the startup burst.
    _transport.onStartFile();
    // A new load attempt re-arms the source resolver's single
    // retry allowance; see [_SourceResolverDriver._retried].
    _resolver.onStartFile();
    _entries.onStartFile(entryId);
    _updateLifecycle(buffering: true, completed: false);
  }

  /// MPV_EVENT_FILE_LOADED with its payload, applied in this order.
  void _onFileLoaded(MpvEventFileLoaded loaded) {
    final MpvEventFileLoaded(
      :path,
      :playlist,
      :timePos,
      :chapterIndex,
      :chapterList,
      :coverData,
      :coverMime,
    ) = loaded;
    // `state.playback.playing` is driven by the `core-idle` observer; here we
    // only clear buffering and apply the load payload. `completed`
    // was cleared at START_FILE, and the end-of-content read that
    // follows this event settles it: a short entry can already be
    // parked at its end here.
    _updateLifecycle(buffering: false);
    _entries.onFileLoaded();
    _effects.reassert();
    _applyPolledPosition(timePos);
    // mpv exposes -1, -2 etc. as "no chapter active"; surface as
    // null. A failed read (chapterIndex == null) applies nothing.
    if (chapterIndex != null) {
      final idx = chapterIndex < 0 ? null : chapterIndex;
      _updateField(
        (s) => s.copyWith(currentChapter: idx),
        _reactives.currentChapter,
        idx,
      );
    }
    // Freshly read on every load (see the payload doc for why the
    // observer's structural dedup makes this necessary); dispatch
    // through the registry so it reuses the chapter-list parser.
    if (chapterList != null) {
      _dispatchProperty('chapter-list', chapterList);
    }
    // The new entry reaches the state snapshot before the cover, waveform and
    // loudness resets below, so a listener pairing them with
    // `state.playback.playlist` or `state.file.path` sees the new track. The
    // `playlist` and `path` streams still emit with the observed changes that
    // follow this event, as before. The same file loaded again (a playlist of
    // one entry with loop-playlist) keeps its analysis. Against the path of the
    // last FILE_LOADED, not the state's: the event isolate sends the new `path`
    // ahead of this event.
    final samePath = path != null && path == _analysisPath;
    _analysisPath = path;
    _applyLoadedEntry(path, playlist);
    _releaseSettled();
    // Emit unconditionally: `null` signals "no cover on the new
    // file" so subscribers can clear stale artwork on track changes.
    final cover = coverData == null
        ? null
        : CoverArt(
            bytes: coverData,
            mimeType: coverMime ?? 'application/octet-stream',
          );
    _state = _state.copyWith(coverArt: cover);
    _streams.coverArt.add(cover);
    // Re-arm the waveform and the loudness scan on every load, the
    // same file loaded again included: a result kept across it may
    // belong to other content, or to a pass that failed. The path is no
    // key for it: with the prefetch it can name the next entry. With the
    // same path the finished result stays on screen until the first poll
    // says whether it stands: mpv keeps a complete analysis of the
    // same file, and otherwise starts a new one.
    if (_bringUpCompleted) {
      _waveformPipeline.reset(sameFile: samePath);
      // The offline loudness scan rides the same native decode pass.
      _loudnessScanPipeline.reset(sameFile: samePath);
    }
  }

  /// MPV_EVENT_END_FILE: the entry ended, finished, stopped or failed.
  void _onEndFile(MpvEventEndFile ended) {
    final MpvEventEndFile(
      :entryId,
      :reason,
      :error,
      :lastEntry,
      :position,
      :duration,
      :readError,
      :skippedSegments,
    ) = ended;
    final media = _entries.onEndFile(entryId);
    _releaseSettled();
    final typedReason = MpvEndFileReason.fromValue(reason);
    _streams.endFile.add(
      MpvFileEndedEvent(
        reason: typedReason,
        error: error,
        media: media,
        position: position == null ? null : secondsToDuration(position),
        duration: duration == null ? null : secondsToDuration(duration),
        readError: readError,
        skippedSegments: skippedSegments,
      ),
    );
    if (error < 0) {
      _streams.errors.add(
        EndFileError(
          reason: typedReason,
          code: error,
          message: _calls.errorString(error),
        ),
      );
      // A terminal load failure parks mpv idle, but the idle-active
      // false→true round-trip can coalesce inside one playloop
      // iteration: mpv's observer then emits NO property change at
      // all, so the idle-active intent reset never fires and the
      // play-pause button sticks on "playing". Settle the intent off
      // this discrete event instead, gated on the failed entry being
      // the last one so a mid-playlist failure that auto-advances
      // doesn't flicker the button.
      if (lastEntry && _state.playback.loop == Loop.off) {
        _transport.writeIntent(false);
      }
    }
    // mpv emits END_FILE(EOF) for EVERY finished entry, including a
    // gapless mid-playlist advance. Under the shipped `keep-open` the
    // last entry parks instead (see [_settleEndOfContent]); this
    // covers a last entry that ends without the park. Gated on the
    // ended entry being the last one, read by entry id in the event
    // isolate: the state's playlist position may already be on the
    // next entry, which raised `completed` between tracks. `playing`
    // comes back at the next file's restart, where the event isolate
    // reads `core-idle` again: mpv may report no change for it.
    final isEof = reason == MpvEndFileReason.eof.value;
    _updateLifecycle(
      playing: false,
      buffering: false,
      completed: isEof && lastEntry && _state.playback.loop == Loop.off,
      readError: readError,
      skippedSegments: skippedSegments,
    );
  }

  /// Writes the FILE_LOADED entry into the state snapshot only. The
  /// reactives keep the last observed values, so the observed `path` and
  /// `playlist` changes that follow still emit on the streams.
  void _applyLoadedEntry(String? path, Object? playlistNode) {
    Playlist? playlist;
    if (playlistNode != null) {
      try {
        final hidden = retainedEntryAt(playlistNode, _entries.retained);
        playlist = parsePlaylistNode(
          raw: playlistNode,
          mediaCache: _mediaCache.byUri,
          mediaByEntry: _entries.media,
          previous: _state.playback.playlist,
          skip: hidden,
          heldId: _entries.stopped,
        );
        _entries.hiddenAt = hidden;
        // A loadfile reply that comes after this read parses it again.
        _entries.onLoadedNode(playlistNode);
      } catch (e) {
        _internalLog('Failed to parse playlist: $e', level: LogLevel.warn);
      }
    }
    if (path == null && playlist == null) return;
    _state = _state.copyWith(path: path, playlist: playlist);
    // The duration and its flag arrive before this event: the hint of the
    // new entry applies now.
    _state = _durationHint.apply(_state);
  }

  /// Releases the held resources mpv has stopped reading.
  void _releaseSettled() {
    for (final release in _entries.takeSettled()) {
      unawaited(release());
    }
  }

  /// Applies a `time-pos` value carried on an event payload (seconds, read
  /// by the event isolate at dispatch time). `null` means the read failed
  /// or the property was unavailable: nothing is applied.
  void _applyPolledPosition(double? seconds) {
    if (seconds == null) return;
    final pos = Duration(microseconds: (seconds * 1e6).round());
    _updateField((s) => s.copyWith(position: pos), _reactives.position, pos);
  }
}
