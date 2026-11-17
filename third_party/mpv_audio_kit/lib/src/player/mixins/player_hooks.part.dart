// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
part of '../player.dart';

/// Hook setters: register / continue mpv hooks, plus the high-level
/// [Player.setSourceResolver] built on top of them. Hooks let you
/// intercept mpv's file-loading pipeline to lazily resolve a URL, inject
/// per-file HTTP headers, or redirect to a different source. For plain
/// URL resolution prefer [Player.setSourceResolver]; the raw hook API
/// below remains for headers, redirects, and custom per-load logic.
///
/// Usage pattern:
/// ```dart
/// player.registerHook(Hook.load);
/// player.stream.hook.listen((event) async {
///   if (event.hook == Hook.load) {
///     final url = await player.getRawProperty('stream-open-filename') ?? '';
///     // Optionally redirect the URL:
///     await player.setRawProperty('stream-open-filename', newUrl);
///     // Optionally set per-file HTTP headers:
///     await player.setRawProperty(
///         'file-local-options/http-header-fields', 'X-Token: abc');
///   }
///   player.continueHook(event.id); // must always be called
/// });
/// ```
mixin _HooksModule on _PlayerBase {
  /// Registers an mpv hook for [hook] with optional [priority].
  ///
  /// Hook events are delivered via [PlayerStream.hook]. Call
  /// [continueHook] with the event's [MpvHookEvent.id] when processing
  /// is complete — until then, mpv suspends the operation guarded by
  /// this hook.
  ///
  /// If [timeout] is provided, the library automatically calls
  /// [continueHook] after the given duration if you haven't called it
  /// yet. Prevents mpv from stalling indefinitely on unhandled
  /// exceptions in the listener.
  ///
  /// Idempotent per [hook]: calling [registerHook] more than once for
  /// the same hook on the same [Player] only updates the optional
  /// [timeout]; the underlying mpv registration happens once. mpv
  /// allows multiple registrations per name but its shutdown path can
  /// stall when several events for the same hook are still active at
  /// `quit` — duplicates are collapsed here to avoid that race.
  ///
  /// See [Hook] for the full set of available phases. Higher
  /// [priority] values run earlier; the default (0) is fine for most
  /// uses.
  Future<void> registerHook(Hook hook,
      {int priority = 0, Duration? timeout,}) async {
    await _gate();
    // Mark the CONSUMER's interest even when the mpv-level registration
    // already happened (e.g. the source resolver registered `on_load`
    // internally first): from now on events for this hook surface on
    // [PlayerStream.hook] and the continue obligation is the consumer's.
    _userHookNames.add(hook.mpvValue);
    await _ensureHookRegistered(hook, priority: priority, timeout: timeout);
  }

  /// mpv-level registration shared by [registerHook] and
  /// [setSourceResolver]. Idempotent per hook name; a repeat call only
  /// updates the optional [timeout].
  Future<void> _ensureHookRegistered(Hook hook,
      {int priority = 0, Duration? timeout,}) async {
    final name = hook.mpvValue;
    if (timeout != null) _hookTimeouts[name] = timeout;
    if (_registeredHookNames.contains(name)) return;
    _registeredHookNames.add(name);
    // `mpv_hook_add` locks the core (it waits for the playloop to reach a
    // dispatch point), so on the main isolate it would stall behind a busy
    // audio-output init. There is no command/async equivalent in the client
    // API — run it in a throwaway isolate, where waiting is harmless. The
    // registration targets the shared client handle, so hook events still
    // arrive on the player's event isolate.
    final handleAddress = _handle.address;
    final libraryPath = MpvAudioKit.libraryPath;
    // Track the run so dispose() can await it before freeing the handle —
    // mpv_hook_add does `lock_core(ctx)` on the shared core, and a busy
    // playloop can hold it long enough for a concurrent dispose to reach
    // mpv_terminate_destroy first (use-after-free on the freed MPContext).
    final run = Isolate.run(() {
      final lib = MpvLibrary.open(libraryPath);
      using((arena) {
        lib.mpvHookAdd(
          Pointer<MpvHandle>.fromAddress(handleAddress),
          0,
          name.toNativeUtf8(allocator: arena),
          priority,
        );
      });
    });
    _pendingHookAdds.add(run);
    try {
      await run;
    } finally {
      _pendingHookAdds.remove(run);
    }
  }

  /// Signals mpv that hook processing for [id] is complete.
  ///
  /// Should be called exactly once per [MpvHookEvent] received on
  /// [PlayerStream.hook], even if your processing fails — otherwise mpv
  /// will stall indefinitely waiting for the hook to return.
  ///
  /// Idempotent on a per-id basis: a second [continueHook] call for the
  /// same id (a buggy double-dispatch in your code, or a manual continue
  /// racing the auto-timeout fallback) is dropped before reaching mpv.
  /// mpv's behaviour for an already-continued id is undefined across
  /// versions, so the active set is tracked internally.
  ///
  /// Calling with an invalid [id] (zero or negative — typo in a dispatch
  /// table) is also a no-op: a warning is logged on
  /// [PlayerStream.internalLog] and the FFI call is skipped.
  Future<void> continueHook(int id) async {
    await _gate();
    if (id <= 0) {
      _internalLog(
        'continueHook: ignored invalid hook id $id (must be a positive '
        'integer obtained from MpvHookEvent.id)',
        level: LogLevel.warn,
      );
      return;
    }
    if (!_activeHookIds.remove(id)) {
      // Already continued (manual + auto-timer race, or caller
      // double-dispatch). Drop silently — the first continue already
      // unblocked mpv.
      return;
    }
    _hookTimers.remove(id)?.cancel();
    // Safe on the main isolate even though `mpv_hook_continue` locks the
    // core: a live id in `_activeHookIds` means mpv is parked at the hook's
    // dispatch point waiting for exactly this call, so the lock is granted
    // immediately — the playloop cannot simultaneously be busy elsewhere.
    _lib.mpvHookContinue(_handle, id);
  }

  /// Installs [resolver] as the player's source resolver — the official
  /// callback for resolving or refreshing a playback URL right before a
  /// track opens, without wiring `on_load` hooks by hand.
  ///
  /// The resolver is invoked with a [SourceResolveRequest] carrying the
  /// entry's original [Media] ([Media.extras] and [Media.httpHeaders]
  /// intact) once per load attempt, including gapless prefetch opens:
  ///
  /// - before every stream open (`on_load`), and
  /// - once more after a failed open (`on_load_fail`) with
  ///   [SourceResolveRequest.isRetry] `true` — return a fresh URL and mpv
  ///   retries, covering expired CDN / token URLs. The retry fires at
  ///   most once per load, and only when the returned URL differs from
  ///   the one that failed.
  ///
  /// Return the URL to play, or `null` (or the incoming
  /// [SourceResolveRequest.uri] unchanged) to leave the source alone —
  /// the default no-resolver behaviour is unaffected for entries the
  /// resolver doesn't care about. A thrown error is logged on
  /// [PlayerStream.internalLog] and treated as "keep the current URL".
  ///
  /// [timeout] is the safety net for a hung resolver (default 15s): if a
  /// resolution pass hasn't finished by then, the library auto-continues
  /// the underlying hook so mpv never stalls indefinitely. Pass `null`
  /// to disable the net. The value is stored per hook name, so it also
  /// becomes the deadline of a consumer-registered `Hook.load` /
  /// `Hook.loadFail` (the most recent registration's timeout wins).
  ///
  /// Composes with [registerHook]: when the consumer has registered
  /// `Hook.load` themselves, the resolver runs FIRST, then the event
  /// surfaces on [PlayerStream.hook] with the rewritten URL already in
  /// `stream-open-filename`, and the consumer's [continueHook] releases
  /// mpv as usual.
  ///
  /// Pass `null` to uninstall. mpv has no hook-removal API, so the
  /// underlying registrations stay; the library just auto-continues
  /// their events from then on.
  Future<void> setSourceResolver(SourceResolver? resolver,
      {Duration? timeout = const Duration(seconds: 15),}) async {
    await _gate();
    _sourceResolver = resolver;
    if (resolver == null) return;
    await _ensureHookRegistered(Hook.load, timeout: timeout);
    await _ensureHookRegistered(Hook.loadFail, timeout: timeout);
  }

  /// Single entry point for every MPV_EVENT_HOOK, called by the dispatch
  /// layer. Ordering per event: resolver pass (when installed and the
  /// hook is `on_load` / `on_load_fail`) → consumer delivery on
  /// [PlayerStream.hook] (only when the consumer registered this hook) →
  /// otherwise internal [continueHook].
  ///
  /// When no resolver is installed and the hook is consumer-registered,
  /// no await runs before the stream add — delivery stays in the same
  /// microtask as the native event, preserving the pre-resolver timing.
  @override
  Future<void> _routeHookEvent(int id, Hook hook, String name) async {
    final resolver = _sourceResolver;
    if (resolver != null && (hook == Hook.load || hook == Hook.loadFail)) {
      await _runSourceResolver(resolver, hook);
    }
    if (_disposed) return;
    if (_userHookNames.contains(name)) {
      _hookCtrl.add(MpvHookEvent(id, hook));
    } else {
      await continueHook(id);
    }
  }

  /// One resolver pass: read the URL mpv is about to open, look up the
  /// original [Media] in the media cache, invoke the consumer callback,
  /// and rewrite `stream-open-filename` when it returns a different URL.
  ///
  /// Never throws — the hook MUST reach its continue in [_routeHookEvent]
  /// regardless of what the consumer callback does, so failures are
  /// logged on [PlayerStream.internalLog] and resolution is skipped.
  Future<void> _runSourceResolver(SourceResolver resolver, Hook hook) async {
    try {
      final isRetry = hook == Hook.loadFail;
      // One resolver-driven retry per load attempt — see
      // [_resolverRetried] for the loop hazard this caps. The flag is
      // cleared on START_FILE only, NOT on `on_load`: after an
      // `on_load_fail` rewrite mpv re-enters the load cycle from
      // `on_load` for the same attempt, and re-arming there would
      // reopen the infinite loop the flag exists to prevent.
      if (isRetry && _resolverRetried) return;
      final current = await getRawProperty('stream-open-filename') ?? '';
      if (current.isEmpty || _disposed) return;
      final media = _cachedMedia(current) ?? Media(current);
      final resolved = await resolver(
        SourceResolveRequest(media: media, uri: current, isRetry: isRetry),
      );
      if (_disposed ||
          resolved == null ||
          resolved.isEmpty ||
          resolved == current) {
        return;
      }
      if (isRetry) _resolverRetried = true;
      await setRawProperty('stream-open-filename', resolved);
      // Keep the original Media reachable under the rewritten URL, so a
      // later `on_load_fail` on this entry (expired token on the resolved
      // URL) still hands the resolver the same Media and extras.
      _mediaCache[resolved] = media;
    } catch (e, st) {
      _internalLog(
        'Source resolver threw for ${hook.mpvValue}: $e\n$st',
        level: LogLevel.warn,
      );
    }
  }

  /// The [Media] cached under [uri]. On Windows mpv hands a local path
  /// back with backslashes, so a path the resolver returned with forward
  /// slashes is matched with the separators ignored.
  Media? _cachedMedia(String uri) {
    final hit = _mediaCache[uri];
    if (hit != null || !Platform.isWindows) return hit;
    final key = uri.replaceAll('/', r'\');
    for (final entry in _mediaCache.entries) {
      if (entry.key.replaceAll('/', r'\') == key) return entry.value;
    }
    return null;
  }
}
