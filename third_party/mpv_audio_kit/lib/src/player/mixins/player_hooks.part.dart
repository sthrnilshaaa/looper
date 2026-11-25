// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
part of '../player.dart';

/// Hook setters: register and continue mpv hooks, plus the high-level
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
///   try {
///     if (event.hook == Hook.load) {
///       final url = await player.getRawProperty('stream-open-filename');
///       // Optionally redirect the URL:
///       await player.setRawProperty('stream-open-filename', newUrl);
///       // Optionally set per-file HTTP headers:
///       await player.setRawProperty(
///           'file-local-options/http-header-fields', 'X-Token: abc');
///     }
///   } finally {
///     player.continueHook(event.id); // must always be called
///   }
/// });
/// ```
mixin _HooksModule on _PlayerBase {
  /// Registers an mpv hook for [hook] with optional [priority].
  ///
  /// Hook events are delivered via [PlayerStream.hook]. Call
  /// [continueHook] with the event's [MpvHookEvent.id] when processing
  /// is complete: until then, mpv suspends the operation guarded by
  /// this hook.
  ///
  /// If [timeout] is provided, the library automatically calls
  /// [continueHook] after the given duration if you haven't called it
  /// yet. Prevents mpv from stalling indefinitely on unhandled
  /// exceptions in the listener. Without [timeout], a deadline an earlier
  /// call or [Player.setSourceResolver] set for [hook] stays in place.
  ///
  /// Idempotent per [hook]: calling [registerHook] more than once for
  /// the same hook on the same [Player] only updates the optional
  /// [timeout]; the underlying mpv registration happens once, so the
  /// [priority] of the first one stays (mpv can't change it later, and
  /// [Player.setSourceResolver] registers its hooks with priority 0). mpv
  /// allows multiple registrations per name but its shutdown path can
  /// stall when several events for the same hook are still active at
  /// `quit`: duplicates are collapsed here to avoid that race.
  ///
  /// See [Hook] for the full set of available phases. Lower [priority]
  /// values run earlier, as in mpv, and the default (0) is fine for most
  /// uses. The priority orders this handler against other handlers of the
  /// same hook on the same core, such as another client of it.
  Future<void> registerHook(
    Hook hook, {
    int priority = 0,
    Duration? timeout,
  }) async {
    await _gate();
    // Mark the CONSUMER's interest even when the mpv-level registration
    // already happened (e.g. the source resolver registered `on_load`
    // internally first): from now on events for this hook surface on
    // [PlayerStream.hook] and the continue obligation is the consumer's.
    _hooks.user.add(hook.mpvValue);
    await _ensureHookRegistered(hook, priority: priority, timeout: timeout);
  }

  /// mpv-level registration shared by [registerHook] and
  /// [setSourceResolver]. Idempotent per hook name; a repeat call only
  /// updates the optional [timeout].
  Future<void> _ensureHookRegistered(
    Hook hook, {
    int priority = 0,
    Duration? timeout,
  }) async {
    final name = hook.mpvValue;
    if (timeout != null) _hooks.timeouts[name] = timeout;
    if (_hooks.registered.contains(name)) {
      // Being registered by an earlier call: this one completes with it,
      // once mpv took the hook, or fails with it.
      await _hookAdds[name];
      return;
    }
    // A dispose that started after the caller's gate frees the handle once
    // the runs it knows of settle: no new one may start against it.
    if (_disposed) return;
    _hooks.registered.add(name);
    // Tracked by the session, so dispose waits for it before freeing the
    // core (see [MpvSession.settleHookAdds]).
    final run = _session.hookAdd(name, priority);
    _hookAdds[name] = run;
    try {
      await run;
    } catch (_) {
      // mpv does not have the hook: a later call registers it again.
      _hooks.registered.remove(name);
      rethrow;
    } finally {
      // The removed value is the run awaited above.
      unawaited(_hookAdds.remove(name));
    }
  }

  /// The registrations with mpv under way, by hook name.
  final Map<String, Future<void>> _hookAdds = {};

  /// Signals mpv that hook processing for [id] is complete.
  ///
  /// Should be called exactly once per [MpvHookEvent] received on
  /// [PlayerStream.hook], even if your processing fails: otherwise mpv
  /// will stall indefinitely waiting for the hook to return.
  ///
  /// Idempotent on a per-id basis: a second [continueHook] call for the
  /// same id (a buggy double-dispatch in your code, or a manual continue
  /// racing the auto-timeout fallback) is dropped before reaching mpv.
  /// Each event has its own id, so a call that comes after the timeout
  /// continued its event does not release a later event of the same hook.
  ///
  /// Calling with an invalid [id] (zero or negative, a typo in a dispatch
  /// table) is also a no-op: a warning is logged on
  /// [PlayerStream.internalLog] and the FFI call is skipped.
  ///
  /// After [Player.dispose] it is a no-op too, unlike the other calls:
  /// dispose has already continued every pending hook, and a listener that
  /// finishes its work after a dispose must not get an error for it.
  Future<void> continueHook(int id) async {
    if (_disposed) return;
    try {
      await _gate();
    } on PlayerDisposedException {
      return;
    }
    if (id <= 0) {
      _internalLog(
        'continueHook: ignored invalid hook id $id (must be a positive '
        'integer obtained from MpvHookEvent.id)',
        level: LogLevel.warn,
      );
      return;
    }
    final event = _hooks.take(id);
    if (event == null) {
      // Already continued (manual + auto-timer race, or caller
      // double-dispatch). Drop silently: the first continue already
      // unblocked mpv.
      return;
    }
    _continueMpvHook(event.$1, event.$2);
  }

  /// Installs [resolver] as the player's source resolver: the official
  /// callback for resolving or refreshing a playback URL right before a
  /// track opens, without wiring `on_load` hooks by hand.
  ///
  /// The resolver is invoked with a [SourceResolveRequest] carrying the
  /// entry's original [Media] ([Media.extras] and [Media.httpHeaders]
  /// intact) once per load attempt, including gapless prefetch opens:
  ///
  /// - before every stream open (`on_load`, and `on_prefetch` for the next
  ///   entry opened ahead of time), and
  /// - once more after a failed open (`on_load_fail`) with
  ///   [SourceResolveRequest.isRetry] `true`: return a fresh URL and mpv
  ///   retries, covering expired CDN or token URLs. The retry fires at
  ///   most once per load, and only when the returned URL differs from
  ///   the one that failed.
  ///
  /// Return the URL to play, or `null` (or the incoming
  /// [SourceResolveRequest.uri] unchanged) to leave the source alone:
  /// the default no-resolver behaviour is unaffected for entries the
  /// resolver doesn't care about. A thrown error is logged on
  /// [PlayerStream.internalLog] and treated as "keep the current URL".
  /// A `file://` URL goes to mpv as its path, as the URL of a [Media]
  /// does, so a retry sees that path in [SourceResolveRequest.uri].
  ///
  /// [timeout] is the safety net for a hung resolver (default 15s): if a
  /// resolution pass hasn't finished by then, the library auto-continues
  /// the underlying hook so mpv never stalls indefinitely. Pass `null`
  /// to disable the net, also when an earlier call or [registerHook] set
  /// one. The value is stored per hook name, so it also becomes the
  /// deadline of a consumer-registered `Hook.load`, `Hook.loadFail` or
  /// `Hook.prefetch` (the most recent registration's timeout wins). A URL
  /// the resolver returns
  /// after the deadline is dropped, with a warning on
  /// [PlayerStream.internalLog]: mpv has moved on, and the URL would land
  /// on the next entry. A consumer-registered hook does not get that event
  /// either.
  ///
  /// With [Player.setPrefetchPlaylist] on, the resolver also runs for the
  /// next entry while the current one plays, which goes on meanwhile. When
  /// the entry starts it opens with the URL the resolver gave for the
  /// prefetch, without a second call, so a URL that changes on every call
  /// (a salt, a signed URL) keeps the prefetch. A failed open still asks
  /// again, and a new open, openAll, stop, clearPlaylist or resolver drops
  /// the kept URL. When the entry starts, or leaves the next place, before
  /// the resolver returns, mpv drops the prefetch: the resolver is asked
  /// again for the load, and the URL of the prefetch is dropped with a
  /// warning on [PlayerStream.internalLog].
  ///
  /// Composes with [registerHook]: when the consumer has registered
  /// `Hook.load` or `Hook.prefetch` themselves, the resolver runs FIRST,
  /// then the event surfaces on [PlayerStream.hook] with the rewritten URL
  /// already in `stream-open-filename` (`prefetch-open-filename` for the
  /// prefetch), and the consumer's [continueHook] releases mpv as usual.
  ///
  /// Pass `null` to uninstall. mpv has no hook-removal API, so the
  /// underlying registrations stay; the library just auto-continues
  /// their events from then on.
  Future<void> setSourceResolver(
    SourceResolver? resolver, {
    Duration? timeout = const Duration(seconds: 15),
  }) async {
    await _gate();
    _resolver.install(resolver);
    if (resolver == null) return;
    for (final hook in const [Hook.load, Hook.loadFail, Hook.prefetch]) {
      // The default is 15 s, so a null here was asked for: it lifts the
      // deadline, where for registerHook it only means none was given.
      if (timeout == null) _hooks.timeouts.remove(hook.mpvValue);
      await _ensureHookRegistered(hook, timeout: timeout);
    }
  }

  /// Single entry point for every MPV_EVENT_HOOK, called by the dispatch
  /// layer. Ordering per event: resolver pass (when installed and the
  /// hook is `on_load`, `on_load_fail` or `on_prefetch`) → consumer delivery on
  /// [PlayerStream.hook] (only when the consumer registered this hook) →
  /// otherwise internal [continueHook]. A hook the deadline continued
  /// during the resolver pass goes nowhere.
  ///
  /// When no resolver is installed and the hook is consumer-registered,
  /// no await runs before the stream add: delivery stays in the same
  /// microtask as the native event, preserving the pre-resolver timing.
  Future<void> _routeHookEvent(int id, Hook hook, String name) async {
    bool pending() => _hooks.isPending(id);
    final resolver = _resolver.installed;
    if (resolver != null &&
        (hook == Hook.load || hook == Hook.loadFail || hook == Hook.prefetch)) {
      await _resolver.run(resolver, hook, pending);
    }
    // The deadline continued the hook while the resolver ran: mpv has moved
    // on, so the event is not handed to the consumer.
    if (_disposed || !pending()) return;
    if (_hooks.user.contains(name)) {
      _streams.hook.add(MpvHookEvent(id, hook));
    } else {
      await continueHook(id);
    }
  }
}
