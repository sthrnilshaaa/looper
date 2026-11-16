// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

part of '../player.dart';

/// Low-level native bridge: the raw property / command calls every typed
/// setter funnels through, the `chapter-list` NODE writer, and the mpv
/// error-string lookup. Declared `on _PlayerBase` so the constructor,
/// `dispose`, and the domain mixins can reach these across part boundaries
/// (their abstract signatures live on `_PlayerBase`).
///
/// Every write/read here goes through the ASYNC client API: the FFI call
/// only enqueues the request (libmpv deep-copies the arguments) and the
/// future completes when the event isolate forwards the matching reply.
/// The synchronous client API waits for the core's playloop to serve the
/// request, and the playloop can be stuck for seconds inside audio-output
/// init (a Bluetooth/AirPlay device waking up) — on the main isolate that
/// wait is the macOS beachball. Never reintroduce a synchronous
/// set/get/command on the main isolate.
mixin _FfiModule on _PlayerBase {
  /// Writes a property and throws [MpvException] on rejection.
  ///
  /// All typed setters (setVolume, setRate, setAudioEffects, …) flow
  /// through this method. Errors are surfaced rather than swallowed so
  /// the caller can react (out-of-range value, unknown name, malformed
  /// `af` chain after `AudioEffects.custom`, etc.). `_propRc` is the
  /// rc-returning variant for the few call sites that need to tolerate
  /// failures explicitly.
  @override
  Future<void> _prop(String name, String value) async {
    final rc = await _propRc(name, value);
    if (rc < 0) {
      throw MpvException(name: name, code: rc, message: _errorString(rc));
    }
  }

  @override
  Future<int> _propRc(String name, String value) {
    // A multi-write setter (e.g. setReplayGain's four writes) can be
    // suspended awaiting reply N when dispose() runs; `_drainPendingReplies`
    // resumes it as a microtask, and `mpv_terminate_destroy` frees the handle
    // on the next synchronous line — so the resumed continuation must NOT
    // issue FFI against the freed handle. Report a synthetic success (the
    // same contract the drain uses for a write racing dispose) and skip the
    // native call entirely.
    if (_ffiClosed) return Future.value(MpvError.mpvErrorSuccess);
    final id = _nextReplyId++;
    final completer = Completer<int>();
    _pendingReplies[id] = completer;
    final rc = using((arena) {
      // STRING format: data is a `char**`.
      final v = arena<Pointer<Utf8>>()
        ..value = value.toNativeUtf8(allocator: arena);
      return _lib.mpvSetPropertyAsync(
        _handle,
        id,
        name.toNativeUtf8(allocator: arena),
        MpvFormat.mpvFormatString,
        v.cast(),
      );
    });
    if (rc < 0) {
      // Enqueue rejected (e.g. reply queue full) — no reply will come.
      _pendingReplies.remove(id);
      return Future.value(rc);
    }
    return completer.future;
  }

  @override
  Future<int> _command(List<String> args) {
    // See `_propRc`: never issue FFI on a handle dispose may have freed.
    if (_ffiClosed) return Future.value(MpvError.mpvErrorSuccess);
    final id = _nextReplyId++;
    final completer = Completer<int>();
    _pendingReplies[id] = completer;
    final rc = using((arena) {
      final arr = arena<Pointer<Utf8>>(args.length + 1);
      for (var i = 0; i < args.length; i++) {
        arr[i] = args[i].toNativeUtf8(allocator: arena);
      }
      arr[args.length] = nullptr;
      return _lib.mpvCommandAsync(_handle, id, arr);
    });
    if (rc < 0) {
      // Parse error or full reply queue — rejected client-side, no reply.
      _pendingReplies.remove(id);
      return Future.value(rc);
    }
    return completer.future;
  }

  /// [_command] that throws [MpvException] on rejection — the command
  /// counterpart of [_prop], used by the typed methods whose failure is
  /// a caller-visible error (seek with nothing loaded, loadfile with
  /// malformed options, an out-of-range playlist index). Call sites
  /// where a non-zero rc is an expected no-op (`playlist-remove current`
  /// on an empty playlist, `playlist-next weak` at the last entry) keep
  /// the raw rc-returning variant.
  @override
  Future<void> _commandChecked(List<String> args) async {
    final rc = await _command(args);
    if (rc < 0) {
      throw MpvException(
        name: args.isEmpty ? '<empty>' : args.first,
        code: rc,
        message: _errorString(rc),
      );
    }
  }

  @override
  Future<(int, dynamic)> _getAsync(String name, int format) {
    // See `_propRc`: never issue FFI on a handle dispose may have freed. A
    // read racing dispose surfaces as `null` (same as the drain's contract).
    if (_ffiClosed) return Future.value((MpvError.mpvErrorGeneric, null));
    final id = _nextReplyId++;
    final completer = Completer<(int, dynamic)>();
    _pendingGetReplies[id] = completer;
    final rc = using(
      (arena) => _lib.mpvGetPropertyAsync(
        _handle,
        id,
        name.toNativeUtf8(allocator: arena),
        format,
      ),
    );
    if (rc < 0) {
      _pendingGetReplies.remove(id);
      return Future.value((rc, null));
    }
    return completer.future;
  }

  /// Writes [chapters] to mpv's `chapter-list` — a NODE-array property —
  /// via `mpv_set_property_async`, resolving with the raw mpv rc.
  ///
  /// `chapter-list` is an array of maps `{title: string, time: double secs}`.
  /// The whole node tree is built in an [Arena]; the async setter deep-copies
  /// it before returning (`m_option_copy` on the NODE option type), so every
  /// allocation is freed on return. An empty list writes an empty array
  /// (clears the chapters).
  @override
  Future<int> _setChapterListNode(List<Chapter> chapters) {
    // See `_propRc`: never issue FFI on a handle dispose may have freed.
    if (_ffiClosed) return Future.value(MpvError.mpvErrorSuccess);
    final id = _nextReplyId++;
    final completer = Completer<int>();
    _pendingReplies[id] = completer;
    final rc = using((arena) {
      final n = chapters.length;
      final arrayList = arena<MpvNodeList>();
      arrayList.ref.num = n;
      // Arrays carry no keys (maps do); leave them null.
      arrayList.ref.keys = nullptr;
      if (n > 0) {
        final elements = arena<MpvNode>(n);
        for (var i = 0; i < n; i++) {
          final ch = chapters[i];
          // Two map entries per chapter: title (string) + time (double secs).
          final entryValues = arena<MpvNode>(2);
          final entryKeys = arena<Pointer<Utf8>>(2);

          entryKeys[0] = 'title'.toNativeUtf8(allocator: arena);
          entryValues[0].format = MpvFormat.mpvFormatString;
          entryValues[0].u.string =
              (ch.title ?? '').toNativeUtf8(allocator: arena);

          entryKeys[1] = 'time'.toNativeUtf8(allocator: arena);
          entryValues[1].format = MpvFormat.mpvFormatDouble;
          entryValues[1].u.double_ = ch.time.inMicroseconds / 1e6;

          final map = arena<MpvNodeList>();
          map.ref.num = 2;
          map.ref.values = entryValues;
          map.ref.keys = entryKeys;

          elements[i].format = MpvFormat.mpvFormatNodeMap;
          elements[i].u.list = map;
        }
        arrayList.ref.values = elements;
      } else {
        arrayList.ref.values = nullptr;
      }

      final root = arena<MpvNode>();
      root.ref.format = MpvFormat.mpvFormatNodeArray;
      root.ref.u.list = arrayList;

      return _lib.mpvSetPropertyAsync(
        _handle,
        id,
        'chapter-list'.toNativeUtf8(allocator: arena),
        MpvFormat.mpvFormatNode,
        root.cast<Void>(),
      );
    });
    if (rc < 0) {
      _pendingReplies.remove(id);
      return Future.value(rc);
    }
    return completer.future;
  }

  @override
  String _errorString(int code) {
    final p = _lib.mpvErrorString(code);
    return p == nullptr ? 'error $code' : p.cast<Utf8>().toDartString();
  }

  // ── Public raw escape hatches ────────────────────────────────────────────

  /// Reads any mpv property as a string.
  ///
  /// **Escape hatch for properties not surfaced by the typed API.** For
  /// observed properties (`volume`, `pause`, `cache-secs`, …), prefer
  /// `player.state.<field>` — the cached value is updated on every
  /// property-change event from mpv and avoids an FFI round-trip.
  ///
  /// Returns `null` if the property doesn't exist or the read
  /// fails. Throws [StateError] if the player has been disposed.
  @override
  Future<String?> getRawProperty(String name) async {
    await _gate();
    final (error, value) = await _getAsync(name, MpvFormat.mpvFormatString);
    return error < 0 ? null : value as String?;
  }

  /// Reads any mpv property as a decoded node tree.
  ///
  /// Typed counterpart of [getRawProperty] for structured properties
  /// (`track-list`, `metadata`, `demuxer-cache-state`, …): returns the
  /// same shapes the event pipeline produces — `Map<String, dynamic>`,
  /// `List<dynamic>`, [String], [int], [double], [bool], byte arrays —
  /// with no string re-parsing on the caller's side.
  ///
  /// Returns `null` if the property doesn't exist or is currently
  /// unavailable. Throws [StateError] if the player has been disposed.
  Future<Object?> getRawPropertyNode(String name) async {
    await _gate();
    final (error, value) = await _getAsync(name, MpvFormat.mpvFormatNode);
    return error < 0 ? null : value;
  }

  /// Writes any mpv property as a string.
  ///
  /// **Warning:** this is an escape hatch for properties the typed API
  /// doesn't yet cover. If [name] is one of the registry-observed
  /// properties (volume, cache-*, replaygain*, ao, …), the
  /// resulting state mutation will *also* flow through the property
  /// observer on mpv's side, so `player.state` and `player.stream` will
  /// stay consistent — but expect a one-event-loop-tick delay between
  /// the call returning and the cached state catching up. Prefer the
  /// typed setters (`setVolume`, `setCache`, `setReplayGain`, …) when
  /// they exist, both for type-safety and for synchronous state update.
  ///
  /// Two properties are reserved and rejected:
  /// - `af` — owned by the typed [AudioEffects] bundle (including raw
  ///   passthroughs via [AudioEffects.custom]); a raw write would silently
  ///   desync `state.audioEffects`. Use [setAudioEffects] /
  ///   [updateAudioEffects].
  /// - `pause` — owned by the transport intent axis. It is deliberately not
  ///   observed (see [PlayerState.playWhenReady]), so a raw write would
  ///   change actual playback while leaving `state.playWhenReady` (and the
  ///   OS play/pause button bound to it) reporting the old intent. Use
  ///   [play] / [pause].
  ///
  /// Throws [StateError] if the player has been disposed,
  /// [ArgumentError] if [name] is reserved, or [MpvException] if mpv
  /// rejects the property write (unknown name, out-of-range value, etc.).
  @override
  Future<void> setRawProperty(String name, String value) async {
    await _gate();
    if (name == 'af') {
      throw ArgumentError.value(
        name,
        'name',
        'Property `af` is owned by the typed AudioEffects bundle. '
            'Use Player.setAudioEffects / updateAudioEffects, and pass '
            'experimental or expression-based filters via '
            'AudioEffects.custom.',
      );
    }
    if (name == 'pause') {
      throw ArgumentError.value(
        name,
        'name',
        'Property `pause` is owned by the transport intent axis and is not '
            'observed, so a raw write would desync state.playWhenReady (and '
            'the OS play/pause button) from actual playback. '
            'Use Player.play() / Player.pause() instead.',
      );
    }
    await _prop(name, value);
  }

  /// Sends a raw mpv command.
  ///
  /// **Escape hatch.** Same caveats as [setRawProperty]: prefer the
  /// typed playback / playlist methods (`play`, `pause`, `seek`,
  /// `add`, `jump`, …) when they cover your use case.
  ///
  /// Throws [StateError] if the player has been disposed, or
  /// [MpvException] if mpv rejects the command (unknown command,
  /// invalid argument, etc.). A successful return guarantees mpv
  /// accepted the command; the actual side-effect on playback state
  /// is observed asynchronously via [Player.stream].
  Future<void> sendRawCommand(List<String> args) async {
    await _gate();
    // Symmetric guard with `setRawProperty('af', ...)`: mpv exposes
    // `af` and `af-command` as commands that mutate the audio chain
    // incrementally — bypassing the typed `AudioEffects` bundle and
    // desynchronizing `state.audioEffects`. The bundle is the single
    // writer of mpv's `af` property; raw incremental mutation goes
    // through `AudioEffects.custom` instead.
    if (args.isNotEmpty && (args.first == 'af' || args.first == 'af-command')) {
      throw ArgumentError.value(
        args.first,
        'args[0]',
        'Command `${args.first}` is owned by the typed AudioEffects bundle. '
            'Use Player.setAudioEffects / updateAudioEffects, and pass '
            'experimental or expression-based filters via AudioEffects.custom.',
      );
    }
    final rc = await _command(args);
    if (rc < 0) {
      throw MpvException(
        name: args.isEmpty ? '<empty>' : args.first,
        code: rc,
        message: _errorString(rc),
      );
    }
  }

  /// Changes the engine log verbosity at runtime (the initial value comes
  /// from [PlayerConfiguration.logLevel]).
  Future<void> setLogLevel(LogLevel level) async {
    await _gate();
    // `mpv_request_log_messages` is thread-safe and operates on the shared
    // client handle the same way the main-thread getRawProperty path does,
    // so there's no need to round-trip through the event isolate.
    // [LogLevel.off] already maps to mpv's `no`.
    using(
      (arena) => _lib.mpvRequestLogMessages(
        _handle,
        level.mpvValue.toNativeUtf8(allocator: arena),
      ),
    );
  }
}
