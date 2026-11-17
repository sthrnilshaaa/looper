// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

part of '../player.dart';

/// Inbound event pump: turns each [MpvIsolateEvent] forwarded from the event
/// isolate into state mutations and stream emits, routes property changes to
/// the registry (falling back to the custom JSON / derived handlers), and
/// applies the FILE_LOADED / PLAYBACK_RESTART payloads (position, chapters,
/// embedded cover, source path) read by the event isolate. No method here
/// may issue a synchronous read against the core: every such call waits for
/// the playloop, and during audio-output init (a Bluetooth/AirPlay device
/// waking up takes seconds) that wait would freeze the main isolate — the
/// macOS beachball. `_handleEvent` is the abstract member bring-up wires as
/// the isolate's `onEvent`; the rest are internal to this mixin.
mixin _DispatchModule on _PlayerBase {
  @override
  void _handleEvent(MpvIsolateEvent event) {
    // Async-reply completion runs BEFORE the dispose fence: a reply that
    // arrives while dispose is unwinding must still complete its pending
    // future (completers are dispose-agnostic; the fence below only
    // protects controller add()s).
    switch (event) {
      case MpvEventReply(:final userdata, :final error):
        final completer = _pendingReplies.remove(userdata);
        if (completer != null && !completer.isCompleted) {
          completer.complete(error);
        }
        return;
      case MpvEventGetReply(:final userdata, :final error, :final value):
        final completer = _pendingGetReplies.remove(userdata);
        if (completer != null && !completer.isCompleted) {
          completer.complete((error, value));
        }
        return;
      default:
        break;
    }
    // Single fence for every controller add() in this method — dispose()
    // flips `_disposed` before the event isolate's `stop()` closes the event
    // stream, so any event still delivered between the flip and that close
    // lands here with `_disposed` already true. Passing this check therefore
    // guarantees every downstream add() lands on an open controller without
    // per-call isClosed checks.
    if (_disposed) return;
    // A throw from any branch below — most plausibly a malformed observed
    // NODE property reaching the one unguarded parser path (registry
    // dispatch) — must never escape this onData callback: the event
    // subscription registers no onError, so an escaped throw becomes an
    // unhandled async error (and under a guarded zone can escalate). Contain
    // and log it; one bad event is dropped, the stream keeps delivering.
    try {
      switch (event) {
        case MpvEventStartFile():
          // Latch "a file load has been attempted" HERE, not on FILE_LOADED:
          // START_FILE fires for every load attempt — including one that will
          // fail to open — so a failed first open() still arms the
          // idle-active intent reset (otherwise its intent would stick true
          // forever). START_FILE is always delivered AFTER the cold-start
          // idle-active burst (FIFO), so the latch still can't be tripped by
          // the startup burst.
          _hasLoadedFile = true;
          // A new load attempt re-arms the source resolver's single
          // retry allowance — see [_resolverRetried].
          _resolverRetried = false;
          _updateLifecycle(buffering: true, completed: false);
        case MpvEventFileLoaded(
            :final path,
            :final playlist,
            :final timePos,
            :final chapterIndex,
            :final chapterList,
            :final coverData,
            :final coverMime,
          ):
          // `state.playing` is driven by the `core-idle` observer; here we
          // only clear buffering/completed and apply the load payload.
          _updateLifecycle(buffering: false, completed: false);
          // af-command updates leave the `af` property string behind the
          // live graph; mpv just rebuilt the new file's chain from that
          // stale string, so rewrite it from state to re-apply the
          // current parameter values. (A mid-file format reconfig has
          // the same hazard but no dedicated event; the next file-load
          // or bundle write heals it.)
          if (_afStringStale) {
            _afStringStale = false;
            // Fire-and-forget: the rewrite is best-effort resync; the rc
            // has no consumer here and the event handler must not suspend.
            unawaited(_propRc('af', _state.audioEffects.toAfChain()));
          }
          _applyPolledPosition(timePos);
          // mpv exposes -1 / -2 etc. as "no chapter active"; surface as
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
          // The new entry reaches the state snapshot before the cover,
          // waveform and loudness resets below, so a listener pairing them
          // with `state.playlist` or `state.path` sees the new track. The
          // `playlist` and `path` streams still emit with the observed
          // changes that follow this event, as before.
          _applyLoadedEntry(path, playlist);
          // Emit unconditionally — `null` signals "no cover on the new
          // file" so subscribers can clear stale artwork on track changes.
          final cover = coverData == null
              ? null
              : CoverArt(
                  bytes: coverData.materialize().asUint8List(),
                  mimeType: coverMime ?? 'application/octet-stream',
                );
          _state = _state.copyWith(coverArt: cover);
          _coverArtCtrl.add(cover);
          // Re-arm the waveform ONLY on a genuine source change. mpv re-emits
          // FILE_LOADED on internal reloads (EDL / segment / gapless / track
          // reinit) for the same audio; resetting there would discard a
          // completed bulk envelope, force a full re-decode, and flash the meter
          // to empty. Key off the playlist entry `path` — stable across an
          // on_load hook that rewrites stream-open-filename but not `path`,
          // and distinct per track.
          if (_bringUpCompleted) {
            if (path != _lastWaveformSource) {
              _lastWaveformSource = path;
              _waveformPipeline.reset();
              // The offline loudness scan rides the same native decode
              // pass and shares the track-change boundary.
              _loudnessScanPipeline.reset();
            }
          }
        case MpvEventPlaybackSeek():
          // No-op: a seek's landing is observed via PLAYBACK_RESTART
          // (`seekCompleted`); nothing needs the SEEK event itself.
          break;
        case MpvEventPlaybackRestart(:final timePos):
          _applyPolledPosition(timePos);
          _seekCompletedCtrl.add(null);
        case MpvEndFileEvent(:final reason, :final error):
          final typedReason = MpvEndFileReason.fromValue(reason);
          _endFileCtrl.add(
            MpvFileEndedEvent(
              reason: typedReason,
              error: error,
            ),
          );
          if (error < 0) {
            _errorCtrl.add(
              MpvEndFileError(
                reason: typedReason,
                code: error,
                message: _errorString(error),
              ),
            );
            // A terminal load failure parks mpv idle, but the idle-active
            // false→true round-trip can coalesce inside one playloop
            // iteration — mpv's observer then emits NO property change at
            // all, so the idle-active intent reset never fires and the
            // play/pause button sticks on "playing". Settle the intent off
            // this discrete event instead, with the same end-of-content
            // gate as the eof-reached hook so a mid-playlist failure that
            // auto-advances doesn't flicker the button.
            if (_isEndOfContent()) {
              _updateField(
                (s) => s.copyWith(playWhenReady: false),
                _reactives.playWhenReady,
                false,
              );
            }
          }
          // mpv emits END_FILE(EOF) for EVERY finished entry, including a
          // gapless mid-playlist advance (where START_FILE clears the flag
          // a moment later). Gate on _isEndOfContent() — same gate as the
          // `eof-reached` hook — so `completed` pulses only at the genuine
          // end of all playable content, never between tracks.
          final isEof = reason == MpvEndFileReason.eof.value;
          _updateLifecycle(
            playing: false,
            buffering: false,
            completed: isEof && _isEndOfContent(),
          );
        case MpvEventReply():
        case MpvEventGetReply():
          // Completed before the dispose fence above; never reaches here.
          break;
        case MpvEventShutdown():
          _updateLifecycle(playing: false, buffering: false);
        case MpvEventPropertyDouble(:final name, :final value):
          _dispatchProperty(name, value);
        case MpvEventPropertyInt(:final name, :final value):
          _dispatchProperty(name, value);
        case MpvEventPropertyString(:final name, :final value):
          _dispatchProperty(name, value);
        case MpvEventPropertyNode(:final name, :final value):
          _dispatchProperty(name, value);
        case MpvEventLog(:final prefix, :final level, :final text):
          final typedLevel = LogLevel.fromMpv(level);
          final entry =
              MpvLogEntry(prefix: prefix, level: typedLevel, text: text);
          _logCtrl.add(entry);
          if (typedLevel == LogLevel.error || typedLevel == LogLevel.fatal) {
            _errorCtrl.add(
              MpvLogError(
                prefix: prefix,
                level: typedLevel,
                text: text,
              ),
            );
          }
        case MpvEventHookFired(:final id, :final name):
          final hook = Hook.fromMpv(name);
          if (hook == null) {
            // Unknown hook name — likely a future mpv build added a new
            // phase. Auto-continue so mpv never stalls, log it on the
            // internal channel for diagnostics.
            _internalLog(
              'Received unknown hook "$name" (id=$id) — auto-continuing. '
              'Update the Hook enum if mpv has added a new lifecycle phase.',
              level: LogLevel.warn,
            );
            _lib.mpvHookContinue(_handle, id);
            return;
          }
          _activeHookIds.add(id);
          final timeout = _hookTimeouts[name];
          if (timeout != null) _startHookTimeout(id, name, timeout);
          // Routed through the hooks module: runs the source resolver
          // first when one is installed, then surfaces the event on
          // [PlayerStream.hook] (user-registered hook) or continues it
          // internally (resolver-only registration). With no resolver
          // and a user registration the add() inside is still
          // synchronous — same-microtask emission as before.
          unawaited(_routeHookEvent(id, hook, name));
      }
    } catch (e, st) {
      _internalLog(
        'Unhandled error while handling $event: $e\n$st',
        level: LogLevel.warn,
      );
    }
  }

  /// Test-only entry point that exercises the same dispatch pipeline as
  /// the real event isolate. Lets integration tests force a property
  /// transition (e.g. `audio-output-state == failed`) without depending
  /// on the host AO actually reaching that state.
  @visibleForTesting
  void debugDispatchProperty(String name, dynamic raw) =>
      _dispatchProperty(name, raw);

  /// Routes a property-change to the registry first, then falls back to the
  /// custom handlers for properties whose update logic doesn't fit a simple
  /// (parser, reducer) pair (JSON parsing with player-side context, derived
  /// fields aggregating multiple mpv properties, etc.).
  void _dispatchProperty(String name, dynamic raw) {
    // `commit` assigns the reduced state to `_state` BEFORE the spec's
    // onChange fires, so a hook that reads + mutates `_state` (the
    // idle-active / eof-reached hooks settling the transport) builds on the
    // reduced state and isn't clobbered by a late assignment here.
    final next =
        _registry.dispatch(name, raw, _state, commit: _commitState);
    if (next != null) {
      return;
    }
    if (_registry.specFor(name) != null) {
      // Spec exists but value was deduplicated — nothing to do.
      return;
    }
    // Custom out-of-registry handlers for the few properties whose update
    // logic touches more than `(parse → reduce)` (player-side context like
    // `_mediaCache`, `_state.playlist`, `_state.cache.secs`, or the
    // two-property aggregation behind `loop`).
    switch (name) {
      case 'loop-file':
      case 'loop-playlist':
        _updateLoopFromMpv(name, raw as String);
      case 'playlist':
        _updatePlaylistFromNode(raw);
      case 'audio-device':
        _updateActiveAudioDevice(raw as String);
      case 'audio-device-list':
        _updateDevicesFromNode(raw);
      case 'metadata':
        _updateMetadataFromNode(raw);
      case 'demuxer-cache-state':
        _updateBufferingPercentageFromNode(raw);
    }
  }

  // --- Custom property handlers (JSON / derived) ---

  /// Writes the FILE_LOADED entry into the state snapshot only. The
  /// reactives keep the last observed values, so the observed `path` and
  /// `playlist` changes that follow still emit on the streams.
  void _applyLoadedEntry(String? path, dynamic playlistNode) {
    Playlist? playlist;
    if (playlistNode != null) {
      try {
        playlist = parsePlaylistNode(
          raw: playlistNode,
          mediaCache: _mediaCache,
          previous: _state.playlist,
        );
      } catch (e) {
        _internalLog('Failed to parse playlist: $e', level: LogLevel.warn);
      }
    }
    if (path == null && playlist == null) return;
    _state = _state.copyWith(path: path, playlist: playlist);
  }

  void _updateLoopFromMpv(String name, String value) {
    final next = deriveLoop(name, value, _state.loop);
    if (next == null) return;
    _updateField(
      (s) => s.copyWith(loop: next),
      _loop,
      next,
    );
  }

  void _updatePlaylistFromNode(dynamic raw) {
    try {
      final playlist = parsePlaylistNode(
        raw: raw,
        mediaCache: _mediaCache,
        previous: _state.playlist,
      );
      _updateField((s) => s.copyWith(playlist: playlist), _playlist, playlist);
    } catch (e) {
      _internalLog('Failed to parse playlist: $e', level: LogLevel.warn);
    }
  }

  @override
  void _updateActiveAudioDevice(String name) {
    // mpv only echoes the device name back on `audio-device`. Recover
    // the proper description by looking it up in the parsed
    // `audio-device-list` (state.audioDevices). Falls back to the name
    // on cache miss — typical at boot, before the list arrives.
    final list = _state.audioDevices;
    String description = name;
    for (final d in list) {
      if (d.name == name) {
        description = d.description;
        break;
      }
    }
    final device = Device(name: name, description: description);
    _updateField(
      (s) => s.copyWith(audioDevice: device),
      _reactives.audioDevice,
      device,
    );
  }

  void _updateDevicesFromNode(dynamic raw) {
    try {
      final devices = parseDeviceListNode(raw);
      _updateField(
        (s) => s.copyWith(audioDevices: devices),
        _audioDevices,
        devices,
      );
    } catch (e) {
      _internalLog('Failed to parse audio devices: $e', level: LogLevel.warn);
    }
  }

  void _updateMetadataFromNode(dynamic raw) {
    try {
      final metadata = parseMetadataNode(raw);
      if (metadata == null) return;
      _updateField((s) => s.copyWith(metadata: metadata), _metadata, metadata);
    } catch (e) {
      _internalLog('Failed to parse metadata: $e', level: LogLevel.warn);
    }
  }

  void _updateBufferingPercentageFromNode(dynamic raw) {
    try {
      final pct = parseDemuxerCacheStateNode(raw, _state.cache.secs);
      _updateField(
        (s) => s.copyWith(bufferingPercentage: pct),
        _bufferingPercentage,
        pct,
      );
      final cacheState = parseDemuxerCacheStateFull(raw);
      _updateField(
        (s) => s.copyWith(demuxerCacheState: cacheState),
        _demuxerCacheState,
        cacheState,
      );
    } catch (e) {
      _internalLog('Failed to parse cache state: $e', level: LogLevel.warn);
    }
  }

  // --- Misc helpers ---

  /// Applies a `time-pos` value carried on an event payload (seconds, read
  /// by the event isolate at dispatch time). `null` means the read failed
  /// or the property was unavailable — nothing is applied.
  void _applyPolledPosition(double? seconds) {
    if (seconds == null) return;
    final pos = Duration(microseconds: (seconds * 1e6).round());
    _updateField(
      (s) => s.copyWith(position: pos),
      _reactives.position,
      pos,
    );
  }
}
