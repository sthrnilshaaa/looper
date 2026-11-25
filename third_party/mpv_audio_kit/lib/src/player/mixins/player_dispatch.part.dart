// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

part of '../player.dart';

/// Inbound event pump: turns each [MpvIsolateEvent] forwarded from the event
/// isolate into state mutations and stream emits: property changes go to
/// `_PropertiesModule`, the file boundaries to `_FileEventsModule`. No
/// method here or there may issue a synchronous read
/// against the core: every such call waits for the playloop, and during
/// audio-output init (a Bluetooth or AirPlay device waking up takes seconds)
/// that wait would freeze the main isolate: the macOS beachball.
/// `_handleEvent` is what bring-up wires as the isolate's
/// `onEvent`; the rest are internal to this mixin.
mixin _DispatchModule
    on _PlayerBase, _PropertiesModule, _FileEventsModule, _HooksModule {
  void _handleEvent(MpvIsolateEvent event) {
    // Async-reply completion runs BEFORE the dispose fence: a reply that
    // arrives while dispose is unwinding must still complete its pending
    // future (completers are dispose-agnostic; the fence below only
    // protects controller add()s).
    if (_completeReply(event)) return;
    // Single fence for every controller add() in this method: dispose()
    // flips `_disposed` before the event isolate's `stop()` closes the event
    // stream, so any event still delivered between the flip and that close
    // lands here with `_disposed` already true. Passing this check therefore
    // guarantees every downstream add() lands on an open controller without
    // per-call isClosed checks.
    if (_disposed) return;
    // A throw from any branch below, most plausibly a malformed observed
    // NODE property reaching the one unguarded parser path (registry
    // dispatch), must never escape this onData callback: the event
    // subscription registers no onError, so an escaped throw becomes an
    // unhandled async error (and under a guarded zone can escalate). Contain
    // and log it; one bad event is dropped, the stream keeps delivering.
    try {
      _dispatchEvent(event);
    } catch (e, st) {
      _internalLog(
        'Unhandled error while handling $event: $e\n$st',
        level: LogLevel.warn,
      );
    }
  }

  /// Completes the pending call of a reply [event]. Returns whether
  /// [event] was one.
  bool _completeReply(MpvIsolateEvent event) {
    switch (event) {
      case MpvEventReply(:final userdata, :final error, :final result):
        _session.onReply(userdata, error, result);
        return true;
      case MpvEventGetReply(:final userdata, :final error, :final value):
        _session.onGetReply(userdata, error, value);
        return true;
      default:
        return false;
    }
  }

  /// [_handleEvent] past the replies and the dispose fence.
  void _dispatchEvent(MpvIsolateEvent event) {
    switch (event) {
      case MpvEventStartFile(:final entryId):
        _onStartFile(entryId);
      case final MpvEventFileLoaded loaded:
        _onFileLoaded(loaded);
      case MpvEventPlaybackRestart(:final timePos):
        _onPlaybackRestart(timePos);
      case final MpvEventEndOfContent ended:
        _onEndOfContent(ended);
      case final MpvEventEndFile ended:
        _onEndFile(ended);
      case MpvEventShutdown():
        _onCoreShutdown();
      case MpvEventLog(:final prefix, :final level, :final text):
        _onLog(prefix, LogLevel.fromMpv(level), text);
      case MpvEventInternalLog(:final level, :final text):
        _internalLog('event isolate: $text', level: LogLevel.fromMpv(level));
      case MpvEventHookFired(:final id, :final name):
        _onHookFired(id, name);
      case final MpvPropertyEvent property:
        _dispatchPropertyEvent(property);
      case MpvReplyEvent():
        break;
    }
  }

  /// The core shut down and dispose did not ask for it (the dispose fence
  /// stops the event otherwise): mpv ran out of things to play without
  /// `idle`, or a script or key binding quit it. The event isolate left its
  /// loop on the event, so no reply comes any more: the session closes,
  /// which settles the calls in flight and turns the later ones into
  /// no-ops, until [dispose] frees the core.
  void _onCoreShutdown() {
    _updateLifecycle(playing: false, buffering: false);
    _session.close();
    _internalLog(
      'The mpv core shut down without dispose: the player no longer '
      'reaches it, dispose it',
      level: LogLevel.warn,
    );
  }

  /// An mpv log line: on [PlayerStream.log], and on [PlayerStream.error]
  /// too at error and fatal.
  void _onLog(String prefix, LogLevel level, String text) {
    _streams.log.add(MpvLogEntry(prefix: prefix, level: level, text: text));
    if (level == LogLevel.error || level == LogLevel.fatal) {
      _streams.errors.add(LogError(prefix: prefix, level: level, text: text));
    }
  }

  /// MPV_EVENT_HOOK [name], numbered [id] by mpv.
  void _onHookFired(int id, String name) {
    final hook = Hook.fromMpv(name);
    if (hook == null) {
      // Unknown hook name: likely a future mpv build added a new
      // phase. Auto-continue so mpv never stalls, log it on the
      // internal channel for diagnostics.
      _internalLog(
        'Received unknown hook "$name" (id=$id): auto-continuing. '
        'Update the Hook enum if mpv has added a new lifecycle phase.',
        level: LogLevel.warn,
      );
      _calls.hookContinue(id);
      return;
    }
    final eventId = _hooks.add(id, name);
    // Routed through the hooks module: runs the source resolver
    // first when one is installed, then surfaces the event on
    // [PlayerStream.hook] (user-registered hook) or continues it
    // internally (resolver-only registration). With no resolver
    // and a user registration the add() inside is still
    // synchronous: same-microtask emission as before.
    unawaited(_routeHookEvent(eventId, hook, name));
  }

  /// Test-only: dispatches [event] as if the event isolate sent it, to
  /// replay an order of events a test cannot get from the core on time.
  @visibleForTesting
  void debugDispatchEvent(MpvIsolateEvent event) => _dispatchEvent(event);
}
