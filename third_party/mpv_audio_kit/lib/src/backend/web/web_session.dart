// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';

import '../../events/player_exception.dart';
import '../../internals/core_events.dart';
import '../../internals/event_decoder.dart';
import '../../internals/event_logic.dart';
import '../../internals/event_sequencer.dart';
import '../../internals/libmpv_requirements.dart';
import '../../mpv_constants.dart';
import '../mpv_session.dart';
import 'mpv_module.dart';
import 'web_client.dart';
import 'web_registry.dart';

/// Reply id of the pump's own `pause` observer: 2^40, above every id the
/// player hands out and exact in a JavaScript number.
const int _kPauseObserverReplyId = 1099511627776;

/// Reply id of the pump's own `keep-open-parked` observer.
const int _kParkObserverReplyId = _kPauseObserverReplyId + 1;

/// Test-only: the `mpv-version` the release check takes in place of the
/// module's, to stand for a module of another release.
@visibleForTesting
String? debugWebMpvVersion;

/// The events the read client is spared: it only sends reads, and drains
/// their replies.
const List<int> _kReadClientMuted = [
  MpvEventId.mpvEventLogMessage,
  MpvEventId.mpvEventStartFile,
  MpvEventId.mpvEventEndFile,
  MpvEventId.mpvEventFileLoaded,
  MpvEventId.mpvEventIdle,
  MpvEventId.mpvEventTick,
  MpvEventId.mpvEventClientMessage,
  MpvEventId.mpvEventVideoReconfig,
  MpvEventId.mpvEventAudioReconfig,
  MpvEventId.mpvEventSeek,
  MpvEventId.mpvEventPlaybackRestart,
  MpvEventId.mpvEventPropertyChange,
  MpvEventId.mpvEventQueueOverflow,
  MpvEventId.mpvEventHook,
];

/// The options a core of the web starts with, before the player's own: a
/// demuxer cache of 64 MiB ahead and 16 MiB behind in place of mpv's 150
/// and 50. Every player of the page allocates it in the one memory of the
/// module ([webModuleMemory]), which grows to 512 MiB at most and never
/// gives memory back. Player.setDemuxer changes it as on the other
/// platforms.
const Map<String, String> _kWebDefaults = {
  'demuxer-max-bytes': '64MiB',
  'demuxer-max-back-bytes': '16MiB',
};

/// A core in the web module, driven from the browser's main thread.
///
/// The main thread may not block, so the event pump has no loop of its
/// own: the module's wakeup bridge calls it whenever mpv wakes the client,
/// and it takes the events with `mpv_wait_event(h, 0)` through an
/// [EventSequencer] into the shared [EventLogic]. The logic's reads go out
/// asynchronously on a second client of the same core, whose queue holds
/// only their replies; while they are in flight the sequencer leaves the
/// player's client alone, so its events wait in mpv's queue as they do
/// behind the native pump's blocking reads.
///
/// The calls that lock the core (`mpv_initialize`, `mpv_hook_add`,
/// `mpv_hook_continue`, `mpv_terminate_destroy`) run on the main thread,
/// where Emscripten waits for the lock with a busy loop; their longest
/// runs are kept in [webCallMaxMicros].
@internal
final class WebSession implements MpvSession {
  /// A session over the module [_module] resolves with.
  WebSession(this._module);

  final Future<MpvModule> Function() _module;
  late final MpvModule _m;
  late final WebClient _client;
  late final EventLogic _logic;
  late final EventSequencer _sequencer;

  // The player's client and the read client; 0 until [start] created them
  // and after [terminateDestroy] freed them.
  int _handle = 0;
  int _reads = 0;
  int _handleBridge = 0;
  int _readsBridge = 0;

  // Non-broadcast, like the native pump's: one subscriber, and the events
  // that come before it are buffered.
  final _events = StreamController<MpvIsolateEvent>();
  bool _started = false;
  bool _stopped = false;
  int _nextRead = 1;
  final Map<int, Completer<Object?>> _pendingReads = {};

  @override
  Future<void> start(
    CoreRecipe recipe,
    void Function(MpvIsolateEvent event) onEvent,
  ) async {
    _events.stream.listen(onEvent);
    try {
      _m = await _module();
    } catch (e, st) {
      Error.throwWithStackTrace(PlayerInitException('$e', cause: e), st);
    }
    final c = _m.c;
    final h = timedCall('mpv_create', () => c.mpvCreate());
    if (h == 0) throw const PlayerInitException('mpv_create() returned NULL');
    try {
      for (final option in {
        ..._kWebDefaults,
        ...recipe.preInitOptions,
      }.entries) {
        _m.withStrings([
          option.key,
          option.value,
        ], (p) => c.mpvSetOptionString(h, p[0], p[1]));
      }
      final level = recipe.logLevel;
      if (level != null) {
        _m.withStrings([level], (p) => c.mpvRequestLogMessages(h, p[0]));
      }
      final rc = timedCall('mpv_initialize', () => c.mpvInitialize(h));
      if (rc < 0) {
        timedCall('mpv_terminate_destroy', () => c.mpvTerminateDestroy(h));
        throw PlayerInitException('mpv_initialize() failed: rc=$rc');
      }
      // Synchronous like the native recipe: the core is idle this early.
      for (final property in recipe.postInitOptions.entries) {
        timedCall(
          'mpv_set_property_string',
          () => _m.withStrings([
            property.key,
            property.value,
          ], (p) => c.mpvSetPropertyString(h, p[0], p[1])),
        );
      }
      for (final spec in recipe.observes) {
        _observe(h, spec.replyId, spec.name, spec.format);
      }
      // Not registered with the logic: `pause` and `keep-open-parked`
      // never reach the player, the logic reads them for the end of
      // content only.
      _observe(h, _kPauseObserverReplyId, 'pause', MpvFormat.mpvFormatFlag);
      _observe(
        h,
        _kParkObserverReplyId,
        'keep-open-parked',
        MpvFormat.mpvFormatFlag,
      );
      _reads = _m.withStrings(['mak_reads'], (p) => c.mpvCreateClient(h, p[0]));
      if (_reads == 0) throw StateError('mpv_create_client() returned NULL');
      for (final id in _kReadClientMuted) {
        c.mpvRequestEvent(_reads, id, 0);
      }
    } on PlayerInitException {
      rethrow;
    } catch (e, st) {
      // The player gets no core from a failed init, so the one created
      // above is destroyed here or never.
      if (_reads != 0) c.mpvDestroy(_reads);
      _reads = 0;
      timedCall('mpv_terminate_destroy', () => c.mpvTerminateDestroy(h));
      Error.throwWithStackTrace(
        PlayerInitException('init crashed: $e', cause: e),
        st,
      );
    }
    _handle = h;
    _client = WebClient(_m, h);
    _logic = EventLogic(_WebReader(this), _send);
    for (final spec in recipe.observes) {
      _logic.observe(spec.name, spec.format);
    }
    _sequencer = EventSequencer(
      take: _take,
      idle: _logic.idle,
      waitSeconds: () => _logic.holdsValues ? _logic.waitSeconds(1) : null,
      onError: (e, st) =>
          _send(MpvEventInternalLog('error', 'event dispatch failed: $e\n$st')),
    );
    _started = true;
    _readsBridge = _m.attachWakeup(_reads, _drainReads);
    // On the read client, before the player's client has a bridge: a
    // module of another release hands the player no event.
    await _checkRelease();
    _handleBridge = _m.attachWakeup(h, _sequencer.pump);
    // The events mpv queued before the bridge existed raised no wakeup.
    scheduleMicrotask(_sequencer.pump);
  }

  /// Takes the core down and throws [PlayerInitException] when the module,
  /// past its ABI and layout checks, is not a build of the pinned release,
  /// as natively: the player then gets no core.
  Future<void> _checkRelease() async {
    final mismatch = libmpvMismatch(
      debugWebMpvVersion ?? await _WebReader(this).string('mpv-version'),
    );
    if (mismatch == null) return;
    await stop();
    close();
    await terminateDestroy();
    throw PlayerInitException(mismatch);
  }

  void _observe(int h, int replyId, String name, int format) {
    _m.withStrings([
      name,
    ], (p) => _m.c.mpvObserveProperty(h, bigInt(replyId), p[0], format));
  }

  void _send(MpvIsolateEvent event) {
    if (!_events.isClosed) _events.add(event);
  }

  /// Takes the next event of the player's client and hands it to the
  /// logic, decoded out of the module's memory before anything else runs:
  /// the payload is valid only until the next `mpv_wait_event`.
  TakenEvent _take() {
    final int e;
    try {
      e = _m.c.mpvWaitEvent(_handle, 0);
    } catch (_) {
      // The module itself failed: no event can be taken any more.
      _sequencer.stop();
      rethrow;
    }
    final id = _m.i32(e);
    if (id == MpvEventId.mpvEventNone) return (false, null, false);
    return (
      true,
      dispatchEvent(_logic, _m, e),
      id == MpvEventId.mpvEventShutdown,
    );
  }

  /// Sends a read of [name] in [format] on the read client.
  Future<Object?> _read(String name, int format) {
    if (_stopped) return Future.value();
    final id = _nextRead++;
    final reply = Completer<Object?>();
    _pendingReads[id] = reply;
    int rc;
    try {
      rc = _m.withStrings([
        name,
      ], (p) => _m.c.mpvGetPropertyAsync(_reads, bigInt(id), p[0], format));
    } on WebOutOfMemory {
      rc = MpvError.mpvErrorNomem;
    }
    if (rc < 0) {
      _pendingReads.remove(id);
      return Future.value();
    }
    return reply.future;
  }

  /// Drains the read client: its queue holds the replies of [_read].
  void _drainReads() {
    while (_reads != 0) {
      final e = _m.c.mpvWaitEvent(_reads, 0);
      final id = _m.i32(e);
      if (id == MpvEventId.mpvEventNone) return;
      if (id != MpvEventId.mpvEventGetPropertyReply) continue;
      final reply = _pendingReads.remove(_m.i64(e + 8));
      if (reply == null) continue;
      Object? value;
      try {
        if (_m.i32(e + 4) >= 0) value = propertyValue(_m, _m.u32(e + 16));
      } catch (error) {
        // A read that cannot be decoded fails like a read mpv refused.
        _send(MpvEventInternalLog('warn', 'decoding a read failed: $error'));
      }
      reply.complete(value);
    }
  }

  @override
  void onReply(int id, int error, Object? result) =>
      _client.onReply(id, error, result);

  @override
  void onGetReply(int id, int error, Object? value) =>
      _client.onGetReply(id, error, value);

  @override
  Future<void> hookAdd(String name, int priority) async {
    timedCall(
      'mpv_hook_add',
      () => _m.withStrings([
        name,
      ], (p) => _m.c.mpvHookAdd(_handle, bigInt(0), p[0], priority)),
    );
  }

  // The hook registration completes within its call.
  @override
  Future<bool> settleHookAdds(Duration bound) async => true;

  // The Hot Restart registry of the web: a record on globalThis that the
  // program after a Hot Restart reads, and destroys the cores it names.
  @override
  void track() => trackCore(
    handle: _handle,
    reads: _reads,
    handleBridge: _handleBridge,
    readsBridge: _readsBridge,
  );

  @override
  void untrack() => untrackCore(_handle);

  @override
  void requestStop() {
    _stopped = true;
    if (_started) _sequencer.stop();
    // Nothing read after a stop reaches the player, as natively.
    final pending = _pendingReads.values.toList(growable: false);
    _pendingReads.clear();
    for (final reply in pending) {
      reply.complete();
    }
  }

  /// One thread runs the pump and this call, so the pump is stopped once
  /// it returns.
  @override
  Future<bool> stop() async {
    requestStop();
    if (!_events.isClosed) unawaited(_events.close());
    return true;
  }

  @override
  void close() => _client.close();

  @override
  Future<void> terminateDestroy() async {
    final h = _handle;
    if (h == 0) return;
    _handle = 0;
    final reads = _reads;
    _reads = 0;
    _m.detachWakeup(reads, _readsBridge);
    if (_handleBridge != 0) _m.detachWakeup(h, _handleBridge);
    await _awaitShutdown(reads, const Duration(seconds: 1));
    timedCall('mpv_destroy', () => _m.c.mpvDestroy(reads));
    timedCall('mpv_terminate_destroy', () => _m.c.mpvTerminateDestroy(h));
  }

  /// Sends `quit` on the read client and drains its queue, without
  /// blocking, until mpv's SHUTDOWN, for up to [bound]. The core has then
  /// ended the file and answered the reads still in flight, and the
  /// destroys take its lock at once. Without it they waited for that end
  /// with Emscripten's busy loop on the main thread: a frame or more with
  /// a heavy filter chain. The player sent `quit` already; a second one is
  /// harmless, and stands in for it where the player sent none (a module
  /// of another release).
  Future<void> _awaitShutdown(int reads, Duration bound) async {
    try {
      _m.withStrings(['quit'], (p) {
        final array = _m.malloc(8);
        try {
          _m.setU32(array, p[0]);
          _m.setU32(array + 4, 0);
          _m.c.mpvCommandAsync(reads, bigInt(0), array);
        } finally {
          _m.free(array);
        }
      });
    } on WebOutOfMemory {
      // No room for the command: the player's own `quit` ends the core,
      // or the destroys wait for it.
    }
    final waited = Stopwatch()..start();
    while (waited.elapsed < bound) {
      var id = _m.i32(_m.c.mpvWaitEvent(reads, 0));
      for (
        ;
        id != MpvEventId.mpvEventNone;
        id = _m.i32(_m.c.mpvWaitEvent(reads, 0))
      ) {
        if (id == MpvEventId.mpvEventShutdown) return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 4));
    }
  }

  // ── MpvRequests, through the player's client ──────────────────────────

  @override
  Future<int> setProperty(String name, String value) =>
      _client.setProperty(name, value);

  @override
  Future<int> setNodeProperty(String name, Object? value) =>
      _client.setNodeProperty(name, value);

  @override
  Future<(int, Object?)> command(List<String> args) => _client.command(args);

  @override
  Future<(int, Object?)> getProperty(String name, int format) =>
      _client.getProperty(name, format);

  @override
  Future<void> settleWrites() => _client.settleWrites();

  @override
  String errorString(int code) => _client.errorString(code);

  @override
  void hookContinue(int id) => _client.hookContinue(id);

  @override
  void requestLogMessages(String level) => _client.requestLogMessages(level);
}

/// The reads of [EventLogic] on the read client of [_session].
final class _WebReader implements CoreReader {
  _WebReader(this._session);

  final WebSession _session;

  @override
  Future<String?> string(String name) =>
      _session._read(name, MpvFormat.mpvFormatString).then((v) => v as String?);

  @override
  Future<double?> float(String name) => _session
      ._read(name, MpvFormat.mpvFormatDouble)
      .then((v) => (v as num?)?.toDouble());

  @override
  Future<int?> int64(String name) =>
      _session._read(name, MpvFormat.mpvFormatInt64).then((v) => v as int?);

  @override
  Future<int?> flag(String name) =>
      _session._read(name, MpvFormat.mpvFormatFlag).then((v) => v as int?);

  @override
  Future<Object?> node(String name) =>
      _session._read(name, MpvFormat.mpvFormatNode);
}
