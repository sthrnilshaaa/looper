// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

part of 'event_isolate.dart';

// The entry point of the event isolate: the bring-up of the core and the
// event loop.

// ── Tunables ─────────────────────────────────────────────────────────────────

/// `mpv_wait_event` timeout: a BOUNDED floor in every build.
///
/// The Dart VM cannot interrupt an isolate parked in a blocking FFI call
/// (dart-lang/sdk#46680): under an infinite `-1` timeout a `Player` left
/// undisposed at process exit wedges `WaitForIsolateShutdown` forever (the
/// macOS Dock-Quit hang), and Hot Restart's kill would hang too. A finite
/// timeout guarantees the loop re-reads its stop flag, and the VM gets a
/// safepoint, at least once per window even with zero cooperation.
///
/// Release and profile: `1.0` s, one cheap idle wakeup a second. The graceful
/// dispose path unblocks the wait instantly via `mpv_wakeup`
/// ([MpvEventIsolate.requestStop]), so this value is only the no-dispose
/// floor, never the common-case latency. Debug: `0.1` s for snappy Hot
/// Restart, which only debug builds have ([kHotRestartPossible]). It MUST
/// stay finite in release: an infinite timeout reintroduces the quit hang.
const double _kWaitEventTimeoutSeconds = kHotRestartPossible ? 0.1 : 1.0;

// ── Isolate entry point ───────────────────────────────────────────────────────

/// The calls of the bring-up that mpv refused, as `what: rc=code`. The
/// player still starts, with mpv's default in place of each: they go out
/// as one warning once the main isolate listens. An option this build of
/// mpv does not have goes to [unknown] instead, reported at debug level:
/// the recipe switches off features (the scripts, the OSC) that an audio
/// build leaves out.
final class _Refusals {
  final refused = <String>[];
  final unknown = <String>[];

  /// The internal log lines for what was collected.
  Iterable<MpvEventInternalLog> get logs => [
    if (refused.isNotEmpty)
      MpvEventInternalLog(
        'warn',
        'mpv refused at bring-up, its defaults apply: ${refused.join('; ')}',
      ),
    if (unknown.isNotEmpty)
      MpvEventInternalLog(
        'debug',
        'options this libmpv does not have: ${unknown.join(', ')}',
      ),
  ];
}

void _applyOptionStrings(
  mpv.MpvLibrary lib,
  Pointer<mpv.MpvHandle> handle,
  Map<String, String> opts,
  _Refusals refused,
) {
  for (final entry in opts.entries) {
    using((arena) {
      final rc = lib.mpvSetOptionString(
        handle,
        entry.key.toNativeUtf8(allocator: arena),
        entry.value.toNativeUtf8(allocator: arena),
      );
      if (rc == mpv.MpvError.mpvErrorOptionNotFound) {
        refused.unknown.add(entry.key);
      } else if (rc < 0) {
        refused.refused.add('option ${entry.key}=${entry.value}: rc=$rc');
      }
    });
  }
}

void _applyPropertyStrings(
  mpv.MpvLibrary lib,
  Pointer<mpv.MpvHandle> handle,
  Map<String, String> props,
  _Refusals refused,
) {
  for (final entry in props.entries) {
    using((arena) {
      final rc = lib.mpvSetPropertyString(
        handle,
        entry.key.toNativeUtf8(allocator: arena),
        entry.value.toNativeUtf8(allocator: arena),
      );
      if (rc < 0) {
        refused.refused.add('property ${entry.key}=${entry.value}: rc=$rc');
      }
    });
  }
}

void _applyObserves(
  mpv.MpvLibrary lib,
  Pointer<mpv.MpvHandle> handle,
  List<MpvObserveSpec> observes,
  _Refusals refused,
) {
  for (final spec in observes) {
    using((arena) {
      final rc = lib.mpvObserveProperty(
        handle,
        spec.replyId,
        spec.name.toNativeUtf8(allocator: arena),
        spec.format,
      );
      if (rc < 0) refused.refused.add('observe ${spec.name}: rc=$rc');
    });
  }
}

void _isolateEntry(SendPort initialReplyPort) {
  final fromMain = ReceivePort();
  initialReplyPort.send(fromMain.sendPort);

  SendPort? toMain;
  Pointer<mpv.MpvHandle>? handle;
  mpv.MpvLibrary? lib;

  fromMain.listen((message) async {
    if (message is _InitMessage) {
      toMain = message.toMain;
      final wakeupCounter = message.wakeupCounterAddress != null
          ? Pointer<Int64>.fromAddress(message.wakeupCounterAddress!)
          : null;
      final stopFlag = Pointer<Int32>.fromAddress(message.stopFlagAddress);
      final ownerGone = Pointer<Int32>.fromAddress(message.ownerGoneAddress);
      final refused = _Refusals();
      try {
        // The heavy FFI sequence runs here: off the main isolate so
        // the host UI keeps rendering during cold start.
        lib = mpv.MpvLibrary.open(message.libraryPath);
        final h = lib!.mpvCreate();
        if (h == nullptr) {
          toMain!.send(_InitFailed('mpv_create() returned NULL'));
          fromMain.close();
          return;
        }
        handle = h;
        _applyOptionStrings(lib!, h, message.preInitOptions, refused);
        if (message.logLevel != null) {
          using((arena) {
            final rc = lib!.mpvRequestLogMessages(
              h,
              message.logLevel!.toNativeUtf8(allocator: arena),
            );
            if (rc < 0) {
              refused.refused.add('log level ${message.logLevel}: rc=$rc');
            }
          });
        }
        final failed = _initFailure(lib!, h, lib!.mpvInitialize(h));
        if (failed != null) {
          lib!.mpvTerminateDestroy(h);
          toMain!.send(_InitFailed(failed));
          fromMain.close();
          return;
        }
        _applyPropertyStrings(lib!, h, message.postInitOptions, refused);
        _applyObserves(lib!, h, message.observes, refused);
        // Not registered with the logic: `pause` and `keep-open-parked`
        // never reach the main isolate, the logic reads them for the end
        // of content only.
        _applyObserves(lib!, h, const [
          MpvObserveSpec(
            'pause',
            mpv.MpvFormat.mpvFormatFlag,
            _kPauseObserverReplyId,
          ),
          MpvObserveSpec(
            'keep-open-parked',
            mpv.MpvFormat.mpvFormatFlag,
            _kParkObserverReplyId,
          ),
        ], refused);
        toMain!.send(_InitDone(h.address));
        refused.logs.forEach(toMain!.send);
      } catch (e, st) {
        // The main isolate gets no handle from a failed init, so the core
        // created above is destroyed here or never.
        final h = handle;
        if (h != null) lib!.mpvTerminateDestroy(h);
        toMain!.send(_InitFailed('init crashed: $e\n$st'));
        fromMain.close();
        return;
      }
      // Per-isolate logic and cache: not shared across Player instances.
      final send = toMain!.send;
      final logic = EventLogic(NativeReader(lib!, handle!, stopFlag), send);
      for (final spec in message.observes) {
        logic.observe(spec.name, spec.format);
      }
      // Returns when `_runEventLoop` breaks out of its loop: on the stop
      // flag dispose() sets right after its `quit` command
      // (MpvEventIsolate.requestStop), on MPV_EVENT_SHUTDOWN, or once the
      // owner isolate exited without dispose ([OwnerWatch]). The loop
      // blocks this isolate in mpv_wait_event and in the reads; its awaits
      // resume as microtasks, never through the event queue.
      await _runEventLoop(
        lib!,
        handle!,
        send,
        stopFlag,
        ownerGone,
        logic,
        wakeupCounter,
      );
      if (stopFlag.value == 0 && ownerGone.value != 0) {
        releaseOrphan(lib!, handle!);
      }
      // Drop the last live ReceivePort so the isolate ends on its own: the
      // exit listener armed in [MpvEventIsolate.start] then fires, and
      // [MpvEventIsolate.stop] awaits it before it frees the stop flag.
      // The core and the stop flag have their own explicit release.
      fromMain.close();
    }
  });
}

/// Why the core [handle] cannot serve the player after `mpv_initialize`
/// returned [rc], or `null` when it can. Checked before anything reads an
/// event: the decoders hold the layout of the pinned release only.
String? _initFailure(
  mpv.MpvLibrary lib,
  Pointer<mpv.MpvHandle> handle,
  int rc,
) => rc < 0
    ? 'mpv_initialize() failed: rc=$rc'
    : libmpvMismatch(_versionOf(lib, handle));

/// The `mpv-version` of the core [handle], or `null` when the read fails.
String? _versionOf(mpv.MpvLibrary lib, Pointer<mpv.MpvHandle> handle) =>
    using((arena) {
      final value = lib.mpvGetPropertyString(
        handle,
        'mpv-version'.toNativeUtf8(allocator: arena),
      );
      if (value == nullptr) return null;
      try {
        return value.toDartString();
      } finally {
        lib.mpvFree(value.cast());
      }
    });

/// Reply id of the isolate's own `pause` observer, above every id the main
/// isolate hands out.
const int _kPauseObserverReplyId = 1 << 62;

/// Reply id of the isolate's own `keep-open-parked` observer.
const int _kParkObserverReplyId = _kPauseObserverReplyId + 1;

Future<void> _runEventLoop(
  mpv.MpvLibrary lib,
  Pointer<mpv.MpvHandle> handle,
  void Function(MpvIsolateEvent) send,
  Pointer<Int32> stopFlag,
  Pointer<Int32> ownerGone,
  EventLogic logic,
  Pointer<Int64>? wakeupCounter,
) async {
  while (stopFlag.value == 0 && ownerGone.value == 0) {
    // Test-only telemetry; null in production.
    if (wakeupCounter != null) {
      wakeupCounter.value = wakeupCounter.value + 1;
    }
    final event = lib.mpvWaitEvent(
      handle,
      logic.waitSeconds(_kWaitEventTimeoutSeconds),
    );

    // Re-read the flag the instant the wait returns. `requestStop` sets the
    // flag THEN calls `mpv_wakeup`, so a wakeup-driven return lands here with
    // the flag already `1`: this is the lost-wakeup-safe exit edge, and it
    // does not depend on mpv emitting `MPV_EVENT_SHUTDOWN`.
    if (stopFlag.value != 0 || ownerGone.value != 0) {
      break;
    }

    final id = event.ref.eventId;

    // MPV_EVENT_NONE on a positive-timeout expiry, or on an `mpv_wakeup` with
    // no pending event: nothing to dispatch but the held values and a read
    // that is due; loop and re-check the flag.
    if (id == mpv.MpvEventId.mpvEventNone) {
      try {
        final reads = logic.idle();
        if (reads != null) await reads;
      } catch (e, st) {
        send(MpvEventInternalLog('error', 'event dispatch failed: $e\n$st'));
      }
      continue;
    }

    // A single undecodable event must not kill the loop: the isolate is
    // spawned with the default `errorsAreFatal`, so an uncaught throw here
    // would silently terminate the worker and freeze every property stream
    // for the Player's lifetime while playback keeps running.
    try {
      // Decoded before any await: the payload is valid only until the next
      // mpv_wait_event.
      final reads = dispatchEvent(logic, nativeMemory, event.address);
      if (reads != null) await reads;
      final again = logic.idle();
      if (again != null) await again;
    } catch (e, st) {
      send(MpvEventInternalLog('error', 'event dispatch failed: $e\n$st'));
    }

    if (id == mpv.MpvEventId.mpvEventShutdown) {
      break;
    }
  }
}
