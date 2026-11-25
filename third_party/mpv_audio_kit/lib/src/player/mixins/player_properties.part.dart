// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

part of '../player.dart';

/// Property changes: each one goes to its spec in the registry, and the
/// few the registry does not hold (the playlist, the devices, the
/// metadata, the cache state and the two loop options) to the custom
/// node and derived handlers here.
mixin _PropertiesModule on _PlayerBase {
  /// The property events of [_dispatchEvent]. The replies were completed
  /// before the dispose fence and never reach here.
  void _dispatchPropertyEvent(MpvPropertyEvent event) {
    switch (event) {
      case MpvEventPropertyDouble(:final name, :final value):
        _dispatchProperty(name, value);
      case MpvEventPropertyInt(:final name, :final value):
        _dispatchProperty(name, value);
      case MpvEventPropertyString(:final name, :final value):
        _dispatchProperty(name, value);
      case MpvEventPropertyNode(:final name, :final value):
        _dispatchProperty(name, value);
      case MpvEventPropertyUnavailable(:final name):
        _dispatchUnavailable(name);
      case MpvEventPropertyGroup(:final events):
        _dispatchGroup(events);
    }
  }

  /// Changes of several properties that back one state cell, held together
  /// by the event isolate: the registry applies them in order, and the cell
  /// moves once.
  void _dispatchGroup(List<MpvIsolateEvent> events) {
    _registry.dispatchGroup(
      [
        for (final e in events)
          switch (e) {
            MpvEventPropertyNode(:final name, :final value) => (name, value),
            MpvEventPropertyString(:final name, :final value) => (name, value),
            MpvEventPropertyDouble(:final name, :final value) => (name, value),
            MpvEventPropertyInt(:final name, :final value) => (name, value),
            MpvEventPropertyUnavailable(:final name) => (name, null),
            _ => throw StateError('not a property change: $e'),
          },
      ],
      _state,
      commit: _commitState,
    );
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
  /// (parser, reducer) pair (node parsing with player-side context, derived
  /// fields aggregating multiple mpv properties, etc.).
  void _dispatchProperty(String name, Object? raw) {
    // `commit` assigns the reduced state to `_state` BEFORE the spec's
    // onChange fires, so a hook that reads + mutates `_state` (the
    // idle-active hook settling the transport) builds on the reduced state
    // and isn't clobbered by a late assignment here.
    final next = _registry.dispatch(name, raw, _state, commit: _commitState);
    if (next != null) {
      return;
    }
    if (_registry.specFor(name) != null) {
      // Spec exists but value was deduplicated: nothing to do.
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

  /// Returns the state behind [name] to its seed when mpv reports the
  /// property unavailable, so a stopped player or a file without that value
  /// doesn't keep the previous file's title, duration, size and so on.
  void _dispatchUnavailable(String name) {
    if (_registry.specFor(name) != null) {
      _registry.dispatchUnavailable(name, _state, commit: _commitState);
      return;
    }
    switch (name) {
      case 'metadata':
        _updateField(
          (s) => s.copyWith(metadata: _streams.metadata.initial),
          _streams.metadata,
          _streams.metadata.initial,
        );
      case 'demuxer-cache-state':
        _updateField(
          (s) => s.copyWith(
            bufferingPercentage: _streams.bufferingPercentage.initial,
          ),
          _streams.bufferingPercentage,
          _streams.bufferingPercentage.initial,
        );
        _updateField(
          (s) =>
              s.copyWith(demuxerCacheState: _streams.demuxerCacheState.initial),
          _streams.demuxerCacheState,
          _streams.demuxerCacheState.initial,
        );
    }
  }

  void _updateLoopFromMpv(String name, String value) {
    final next = deriveLoop(name, value, _state.playback.loop);
    if (next == null) return;
    _updateField((s) => s.copyWith(loop: next), _streams.loop, next);
  }

  void _updatePlaylistFromNode(Object? raw) {
    try {
      // Forget the entries mpv no longer has. mpv numbers entries in
      // order, so one newer than every entry a node has listed was
      // appended after this node was taken (a batch of appends replies
      // ahead of the playlist notifications): it stays.
      _entries.onPlaylist(raw);
      _mediaCache.prune(
        raw,
        _entries.media.values,
        busy: _transport.loadsInFlight > 0,
      );
      // The entry openAll still holds in mpv after its jump is left out.
      final hidden = retainedEntryAt(raw, _entries.retained);
      final playlist = parsePlaylistNode(
        raw: raw,
        mediaCache: _mediaCache.byUri,
        mediaByEntry: _entries.media,
        previous: _state.playback.playlist,
        skip: hidden,
        heldId: _entries.stopped,
      );
      _entries.hiddenAt = hidden;
      _updateField(
        (s) => s.copyWith(playlist: playlist),
        _streams.playlist,
        playlist,
      );
      // A new index, or a hint of the playing entry, changes the duration.
      _state = _durationHint.apply(_state);
    } catch (e) {
      _internalLog('Failed to parse playlist: $e', level: LogLevel.warn);
    }
  }

  void _updateActiveAudioDevice(String name) {
    // mpv only echoes the device name back on `audio-device`. Recover
    // the proper description by looking it up in the parsed
    // `audio-device-list` (state.audioDevices). Falls back to the name
    // on cache miss: typical at boot, before the list arrives.
    final list = _state.output.audioDevices;
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

  void _updateDevicesFromNode(Object? raw) {
    try {
      final devices = parseDeviceListNode(raw);
      _updateField(
        (s) => s.copyWith(audioDevices: devices),
        _streams.audioDevices,
        devices,
      );
    } catch (e) {
      _internalLog('Failed to parse audio devices: $e', level: LogLevel.warn);
    }
  }

  void _updateMetadataFromNode(Object? raw) {
    try {
      final metadata = parseMetadataNode(raw);
      if (metadata == null) return;
      _updateField(
        (s) => s.copyWith(metadata: metadata),
        _streams.metadata,
        metadata,
      );
    } catch (e) {
      _internalLog('Failed to parse metadata: $e', level: LogLevel.warn);
    }
  }

  void _updateBufferingPercentageFromNode(Object? raw) {
    try {
      final pct = parseDemuxerCacheStateNode(raw, _state.settings.cache.secs);
      _updateField(
        (s) => s.copyWith(bufferingPercentage: pct),
        _streams.bufferingPercentage,
        pct,
      );
      final cacheState = parseDemuxerCacheStateFull(raw);
      _updateField(
        (s) => s.copyWith(demuxerCacheState: cacheState),
        _streams.demuxerCacheState,
        cacheState,
      );
    } catch (e) {
      _internalLog('Failed to parse cache state: $e', level: LogLevel.warn);
    }
  }
}
