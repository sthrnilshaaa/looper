// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import '../mpv_bindings.dart' as mpv;

part 'isolate_events.dart';
part 'isolate_messages.dart';

// ── Tunables ─────────────────────────────────────────────────────────────────

/// Throttle window for the playback-clock properties. mpv emits one update
/// per playloop iteration whose cadence is the audio output's buffer tick —
/// measured ~11 Hz on macOS coreaudio (mpv 0.41), but AO-dependent and not
/// guaranteed across platforms. ~33ms ≈ 30Hz is comfortably inside
/// human-perception territory for a progress bar update and keeps the
/// message bus uncluttered on outputs that tick faster. A value that falls
/// inside the window is held and sent when it closes, so the last one
/// before mpv goes quiet (a pause) is never lost.
const int _kClockThrottleMs = 33;

/// The properties the throttle applies to: every member is a pure function
/// of the playback clock, so all of them change on EVERY playloop tick and
/// would otherwise cross the isolate (and rebuild PlayerState) at the full
/// AO rate together.
const Set<String> _kClockThrottledProps = {
  'time-pos',
  'time-remaining',
  'playtime-remaining',
  'percent-pos',
  'audio-pts',
};

/// `mpv_wait_event` timeout — a BOUNDED floor in every build.
///
/// The Dart VM cannot interrupt an isolate parked in a blocking FFI call
/// (dart-lang/sdk#46680): under an infinite `-1` timeout a `Player` left
/// undisposed at process exit wedges `WaitForIsolateShutdown` forever — the
/// macOS Dock-Quit hang — and Hot Restart's kill would hang too. A finite
/// timeout guarantees the loop re-reads its stop flag, and the VM gets a
/// safepoint, at least once per window even with zero cooperation.
///
/// Product: `1.0` s — one cheap idle wakeup/sec. The graceful dispose path
/// unblocks the wait instantly via `mpv_wakeup` ([MpvEventIsolate.requestStop]),
/// so this value is only the no-dispose floor, never the common-case latency.
/// Debug: `0.1` s (unchanged) for snappy Hot Restart. It MUST stay finite in
/// product — an infinite timeout reintroduces the quit hang.
const double _kWaitEventTimeoutSeconds =
    bool.fromEnvironment('dart.vm.product') ? 1.0 : 0.1;

/// Maximum time [MpvEventIsolate.stop] waits for the background isolate
/// to finish unwinding after `MPV_EVENT_SHUTDOWN`. The loop's natural
/// exit is fast on every supported platform; this bound caps the worst
/// case (e.g. a stalled syscall in libmpv) before the caller proceeds
/// with `mpv_terminate_destroy`.
const Duration _kIsolateExitTimeout = Duration(seconds: 2);

// ── Isolate entry point ───────────────────────────────────────────────────────

void _applyOptionStrings(
  mpv.MpvLibrary lib,
  Pointer<mpv.MpvHandle> handle,
  Map<String, String> opts,
) {
  for (final entry in opts.entries) {
    using((arena) {
      lib.mpvSetOptionString(
        handle,
        entry.key.toNativeUtf8(allocator: arena),
        entry.value.toNativeUtf8(allocator: arena),
      );
    });
  }
}

void _applyPropertyStrings(
  mpv.MpvLibrary lib,
  Pointer<mpv.MpvHandle> handle,
  Map<String, String> props,
) {
  for (final entry in props.entries) {
    using((arena) {
      lib.mpvSetPropertyString(
        handle,
        entry.key.toNativeUtf8(allocator: arena),
        entry.value.toNativeUtf8(allocator: arena),
      );
    });
  }
}

void _applyObserves(
  mpv.MpvLibrary lib,
  Pointer<mpv.MpvHandle> handle,
  List<MpvObserveSpec> observes,
) {
  for (final spec in observes) {
    using((arena) {
      lib.mpvObserveProperty(
        handle,
        spec.replyId,
        spec.name.toNativeUtf8(allocator: arena),
        spec.format,
      );
    });
  }
}

/// Per-isolate monotonic clock for the property throttle.
final Stopwatch _throttleClock = Stopwatch()..start();

void _isolateEntry(SendPort initialReplyPort) {
  final fromMain = ReceivePort();
  initialReplyPort.send(fromMain.sendPort);

  SendPort? toMain;
  Pointer<mpv.MpvHandle>? handle;
  mpv.MpvLibrary? lib;

  // Per-isolate deduplication state — not shared across Player instances.
  final lastValues = <String, dynamic>{};
  final lastTimestamps = <String, int>{};
  // The newest value of each throttled property held back inside its
  // window, sent when the window closes.
  final trailing = <String, double>{};

  fromMain.listen((message) {
    if (message is _InitMessage) {
      toMain = message.toMain;
      final wakeupCounter = message.wakeupCounterAddress != null
          ? Pointer<Int64>.fromAddress(message.wakeupCounterAddress!)
          : null;
      final stopFlag = Pointer<Int32>.fromAddress(message.stopFlagAddress);
      try {
        // The heavy FFI sequence runs here — off the main isolate so
        // the host UI keeps rendering during cold start.
        lib = mpv.MpvLibrary.open(message.libraryPath);
        final h = lib!.mpvCreate();
        if (h == nullptr) {
          toMain!.send(_InitFailed('mpv_create() returned NULL'));
          fromMain.close();
          return;
        }
        handle = h;
        _applyOptionStrings(lib!, h, message.preInitOptions);
        if (message.logLevel != null) {
          using((arena) {
            lib!.mpvRequestLogMessages(
              h,
              message.logLevel!.toNativeUtf8(allocator: arena),
            );
          });
        }
        final rc = lib!.mpvInitialize(h);
        if (rc < 0) {
          lib!.mpvTerminateDestroy(h);
          toMain!.send(_InitFailed('mpv_initialize() failed: rc=$rc'));
          fromMain.close();
          return;
        }
        _applyPropertyStrings(lib!, h, message.postInitOptions);
        _applyObserves(lib!, h, message.observes);
        toMain!.send(_InitDone(h.address));
      } catch (e, st) {
        toMain!.send(_InitFailed('init crashed: $e\n$st'));
        fromMain.close();
        return;
      }
      // Blocking call — returns when `_runEventLoop` breaks out of
      // its loop on MPV_EVENT_SHUTDOWN (sent by mpv after the main
      // isolate's `quit` command in dispose()).
      _runEventLoop(
        lib!,
        handle!,
        toMain!,
        stopFlag,
        lastValues,
        lastTimestamps,
        trailing,
        wakeupCounter,
      );
      // Drop the last live ReceivePort so the VM tears the isolate
      // down naturally — this runs the per-isolate finalizers that
      // release libmpv-side state loaded via `MpvLibrary.open`.
      // `Isolate.exit()` would skip those finalizers and leave
      // subsequent Player creations observing degraded process state.
      fromMain.close();
    }
  });
}

void _runEventLoop(
  mpv.MpvLibrary lib,
  Pointer<mpv.MpvHandle> handle,
  SendPort toMain,
  Pointer<Int32> stopFlag,
  Map<String, dynamic> lastValues,
  Map<String, int> lastTimestamps,
  Map<String, double> trailing,
  Pointer<Int64>? wakeupCounter,
) {
  while (stopFlag.value == 0) {
    // Test-only telemetry; null in production.
    if (wakeupCounter != null) {
      wakeupCounter.value = wakeupCounter.value + 1;
    }
    final event = lib.mpvWaitEvent(
      handle,
      _waitTimeoutSeconds(lastTimestamps, trailing),
    );

    // Re-read the flag the instant the wait returns. `requestStop` sets the
    // flag THEN calls `mpv_wakeup`, so a wakeup-driven return lands here with
    // the flag already `1` — this is the lost-wakeup-safe exit edge, and it
    // does not depend on mpv emitting `MPV_EVENT_SHUTDOWN`.
    if (stopFlag.value != 0) {
      break;
    }

    final id = event.ref.eventId;

    // MPV_EVENT_NONE on a positive-timeout expiry, or on an `mpv_wakeup` with
    // no pending event — nothing to dispatch, loop and re-check the flag.
    if (id == mpv.MpvEventId.mpvEventNone) {
      _flushTrailing(toMain, lastValues, lastTimestamps, trailing);
      continue;
    }

    // A single undecodable event must not kill the loop: the isolate is
    // spawned with the default `errorsAreFatal`, so an uncaught throw here
    // would silently terminate the worker and freeze every property stream
    // for the Player's lifetime while playback keeps running.
    try {
      _dispatchEvent(
        lib,
        handle,
        toMain,
        event,
        lastValues,
        lastTimestamps,
        trailing,
      );
      _flushTrailing(toMain, lastValues, lastTimestamps, trailing);
    } catch (e, st) {
      toMain.send(MpvEventLog(
        'event-isolate',
        'error',
        'event dispatch failed: $e\n$st',
      ),);
    }

    if (id == mpv.MpvEventId.mpvEventShutdown) {
      break;
    }
  }
}

void _dispatchEvent(
  mpv.MpvLibrary lib,
  Pointer<mpv.MpvHandle> handle,
  SendPort toMain,
  Pointer<mpv.MpvEvent> event,
  Map<String, dynamic> lastValues,
  Map<String, int> lastTimestamps,
  Map<String, double> trailing,
) {
  final id = event.ref.eventId;
  switch (id) {
    case mpv.MpvEventId.mpvEventShutdown:
      toMain.send(MpvEventShutdown());

    case mpv.MpvEventId.mpvEventStartFile:
      // A clock value held from the previous file must not land after the
      // new one starts.
      trailing.clear();
      toMain.send(MpvEventStartFile());

    case mpv.MpvEventId.mpvEventFileLoaded:
      // The payload reads run HERE, not on the main isolate: each one is a
      // synchronous client call that waits for the playloop, and the
      // file-load boundary is exactly the window where the playloop can be
      // stuck for seconds initializing the audio output. This isolate is
      // allowed to wait; the main isolate is not. A failed payload read
      // must never swallow the event itself — lifecycle, af resync and the
      // waveform re-arm all ride it.
      MpvEventFileLoaded loaded;
      try {
        loaded = _readFileLoadedEvent(lib, handle);
      } catch (e, st) {
        toMain.send(MpvEventLog(
          'event-isolate',
          'warn',
          'file-loaded payload read failed: $e\n$st',
        ),);
        loaded = MpvEventFileLoaded();
      }
      toMain.send(loaded);

    case mpv.MpvEventId.mpvEventEndFile:
      final ef = event.ref.data.cast<mpv.MpvEventEndFile>().ref;
      toMain.send(MpvEndFileEvent(ef.reason, ef.error));

    case mpv.MpvEventId.mpvEventPropertyChange:
      _dispatchProperty(
        lib,
        toMain,
        event.ref.data.cast<mpv.MpvEventProperty>().ref,
        lastValues,
        lastTimestamps,
        trailing,
      );

    case mpv.MpvEventId.mpvEventSetPropertyReply:
    case mpv.MpvEventId.mpvEventCommandReply:
      toMain.send(MpvEventReply(event.ref.replyUserdata, event.ref.error));

    case mpv.MpvEventId.mpvEventGetPropertyReply:
      final error = event.ref.error;
      dynamic value;
      if (error >= 0 && event.ref.data != nullptr) {
        // The payload (an mpv_event_property) is owned by the event and
        // valid only until the next mpv_wait_event — decode (and copy)
        // before forwarding.
        value =
            _decodePropertyValue(event.ref.data.cast<mpv.MpvEventProperty>().ref);
      }
      toMain.send(MpvEventGetReply(event.ref.replyUserdata, error, value));

    case mpv.MpvEventId.mpvEventLogMessage:
      _dispatchLog(toMain, event.ref.data.cast<mpv.MpvEventLogMessage>().ref);

    case mpv.MpvEventId.mpvEventHook:
      final hook = event.ref.data.cast<mpv.MpvEventHook>().ref;
      final name = decodeMpvString(hook.name.cast());
      toMain.send(MpvEventHookFired(hook.id, name));

    case mpv.MpvEventId.mpvEventSeek:
      toMain.send(MpvEventPlaybackSeek());

    case mpv.MpvEventId.mpvEventPlaybackRestart:
      // The landing position rides the event payload (read here, where
      // waiting on the core is harmless), so it reaches the stream before
      // any throttled time-pos event from the property observer. A clock
      // value held from before the seek must not land after it and step
      // the position, or percent-pos and the like, back.
      trailing.clear();
      toMain.send(
        MpvEventPlaybackRestart(
          timePos: _getPropDouble(lib, handle, 'time-pos'),
        ),
      );
  }
}

/// Reads the file-load payload (path, playlist, position, chapters,
/// embedded cover) for [MpvEventFileLoaded]. A malformed / oversized
/// embedded picture must not abort the rest of the payload, so the cover
/// read is guarded on its own — the event then carries a `null` cover and
/// consumers clear stale artwork.
MpvEventFileLoaded _readFileLoadedEvent(
  mpv.MpvLibrary lib,
  Pointer<mpv.MpvHandle> handle,
) {
  TransferableTypedData? coverData;
  String? coverMime;
  try {
    final cover = _readEmbeddedCover(lib, handle);
    if (cover != null) {
      coverData = cover.$1;
      coverMime = cover.$2;
    }
  } catch (_) {
    // Cover stays null; the rest of the payload is still delivered.
  }
  return MpvEventFileLoaded(
    path: _getPropString(lib, handle, 'path'),
    playlist: _getPropNode(lib, handle, 'playlist'),
    timePos: _getPropDouble(lib, handle, 'time-pos'),
    chapterIndex: _getPropInt64(lib, handle, 'chapter'),
    chapterList: _getPropNode(lib, handle, 'chapter-list'),
    coverData: coverData,
    coverMime: coverMime,
  );
}

/// Reads the embedded cover art of the loaded file via the
/// `embedded-cover-art-data` / `embedded-cover-art-mime` properties.
/// Returns `null` when the file has no embedded cover. The bytes are the
/// original PNG / JPEG / … as embedded — no decode, no conversion — copied
/// once out of mpv-owned memory into a transferable buffer.
(TransferableTypedData, String)? _readEmbeddedCover(
  mpv.MpvLibrary lib,
  Pointer<mpv.MpvHandle> handle,
) {
  final result = calloc<mpv.MpvNode>();
  try {
    return using<(TransferableTypedData, String)?>((arena) {
      final name = 'embedded-cover-art-data'.toNativeUtf8(allocator: arena);
      final rc = lib.mpvGetProperty(
        handle,
        name,
        mpv.MpvFormat.mpvFormatNode,
        result.cast(),
      );
      if (rc < 0) return null;
      if (result.ref.format != mpv.MpvFormat.mpvFormatByteArray) return null;
      final ba = result.ref.u.ba.ref;
      if (ba.size <= 0) return null;
      // fromList copies out of mpv-owned memory before the node is freed;
      // materialize() on the main isolate is then zero-copy.
      final data = TransferableTypedData.fromList(
        [ba.data.cast<Uint8>().asTypedList(ba.size)],
      );
      final mime = _getPropString(lib, handle, 'embedded-cover-art-mime') ??
          'application/octet-stream';
      return (data, mime);
    });
  } finally {
    lib.mpvFreeNodeContents(result);
    calloc.free(result);
  }
}

// ── Synchronous property readers (event-isolate side only) ──────────────────
//
// These block the calling thread until the playloop serves the request —
// safe here, never on the main isolate.

String? _getPropString(
  mpv.MpvLibrary lib,
  Pointer<mpv.MpvHandle> handle,
  String name,
) {
  return using<String?>((arena) {
    final n = name.toNativeUtf8(allocator: arena);
    final ptr = lib.mpvGetPropertyString(handle, n);
    if (ptr == nullptr) return null;
    final s = decodeMpvString(ptr.cast());
    lib.mpvFree(ptr.cast());
    return s;
  });
}

double? _getPropDouble(
  mpv.MpvLibrary lib,
  Pointer<mpv.MpvHandle> handle,
  String name,
) {
  return using<double?>((arena) {
    final n = name.toNativeUtf8(allocator: arena);
    final buf = arena<Double>();
    final rc = lib.mpvGetProperty(
      handle,
      n,
      mpv.MpvFormat.mpvFormatDouble,
      buf.cast(),
    );
    return rc == mpv.MpvError.mpvErrorSuccess ? buf.value : null;
  });
}

int? _getPropInt64(
  mpv.MpvLibrary lib,
  Pointer<mpv.MpvHandle> handle,
  String name,
) {
  return using<int?>((arena) {
    final n = name.toNativeUtf8(allocator: arena);
    final buf = arena<Int64>();
    final rc = lib.mpvGetProperty(
      handle,
      n,
      mpv.MpvFormat.mpvFormatInt64,
      buf.cast(),
    );
    return rc == mpv.MpvError.mpvErrorSuccess ? buf.value : null;
  });
}

dynamic _getPropNode(
  mpv.MpvLibrary lib,
  Pointer<mpv.MpvHandle> handle,
  String name,
) {
  final node = calloc<mpv.MpvNode>();
  try {
    final rc = using(
      (arena) => lib.mpvGetProperty(
        handle,
        name.toNativeUtf8(allocator: arena),
        mpv.MpvFormat.mpvFormatNode,
        node.cast(),
      ),
    );
    if (rc < 0) return null;
    // decodeMpvNode copies every borrowed string/byte buffer, so the node
    // contents can be freed before the tree is returned.
    return decodeMpvNode(node.ref);
  } finally {
    lib.mpvFreeNodeContents(node);
    calloc.free(node);
  }
}

void _dispatchProperty(
  mpv.MpvLibrary lib,
  SendPort toMain,
  mpv.MpvEventProperty prop,
  Map<String, dynamic> lastValues,
  Map<String, int> lastTimestamps,
  Map<String, double> trailing,
) {
  final name = decodeMpvString(prop.name.cast());

  if (prop.format == mpv.MpvFormat.mpvFormatDouble && prop.data != nullptr) {
    final v = prop.data.cast<Double>().value;

    if (_kClockThrottledProps.contains(name)) {
      // Monotonic clock: a wall-clock jump (NTP sync, manual change) would
      // freeze or double-fire a DateTime-based throttle.
      final now = _throttleClock.elapsedMilliseconds;
      final last = lastTimestamps[name] ?? -_kClockThrottleMs;
      if (now - last < _kClockThrottleMs) {
        // Held, not dropped: mpv may send nothing more (a pause), so the
        // newest value goes out when the window closes (_flushTrailing).
        trailing[name] = v;
        return;
      }
      lastTimestamps[name] = now;
      trailing.remove(name);
    }

    if (lastValues[name] == v) {
      return;
    }
    lastValues[name] = v;

    toMain.send(MpvEventPropertyDouble(name, v));
    return;
  }

  if (prop.format == mpv.MpvFormat.mpvFormatFlag && prop.data != nullptr) {
    final v = prop.data.cast<Int32>().value;
    if (lastValues[name] == v) {
      return;
    }
    lastValues[name] = v;
    toMain.send(MpvEventPropertyInt(name, v));
    return;
  }

  if (prop.format == mpv.MpvFormat.mpvFormatInt64 && prop.data != nullptr) {
    final v = prop.data.cast<Int64>().value;
    if (lastValues[name] == v) {
      return;
    }
    lastValues[name] = v;
    toMain.send(MpvEventPropertyInt(name, v));
    return;
  }

  if (prop.format == mpv.MpvFormat.mpvFormatString && prop.data != nullptr) {
    final s = decodeMpvString(prop.data.cast<Pointer<Utf8>>().value);
    if (lastValues[name] == s) {
      return;
    }
    lastValues[name] = s;
    toMain.send(MpvEventPropertyString(name, s));
    return;
  }

  if (prop.format == mpv.MpvFormat.mpvFormatNode && prop.data != nullptr) {
    final decoded = decodeMpvNode(prop.data.cast<mpv.MpvNode>().ref);
    // Dedup by structural equality against the previously decoded tree —
    // early-out on the first difference, no per-event string allocation.
    // High-churn nodes (`demuxer-cache-state` during streaming) differ on
    // nearly every emission, so the compare usually exits within a few
    // scalar checks.
    final prev = lastValues[name];
    if (prev != null && _deepNodeEquals(prev, decoded)) {
      return;
    }
    lastValues[name] = decoded;
    toMain.send(MpvEventPropertyNode(name, decoded));
    return;
  }

  // Fallthrough: an unobserved format (NONE / OSD_STRING / top-level
  // BYTE_ARRAY) or `data == nullptr` ("property unavailable" mid-stream).
  // Drop silently — re-emitting a cached value would be wrong and a
  // sentinel would break downstream dedup. A value held for it is stale.
  trailing.remove(name);
}

/// The `mpv_wait_event` timeout: [_kWaitEventTimeoutSeconds], shortened to
/// the end of the earliest throttle window while a value is held back.
double _waitTimeoutSeconds(
  Map<String, int> lastTimestamps,
  Map<String, double> trailing,
) {
  if (trailing.isEmpty) return _kWaitEventTimeoutSeconds;
  final now = _throttleClock.elapsedMilliseconds;
  var remaining = _kClockThrottleMs;
  for (final name in trailing.keys) {
    final last = lastTimestamps[name] ?? -_kClockThrottleMs;
    final left = last + _kClockThrottleMs - now;
    if (left < remaining) remaining = left;
  }
  if (remaining <= 0) return 0;
  final seconds = remaining / 1000;
  return seconds < _kWaitEventTimeoutSeconds
      ? seconds
      : _kWaitEventTimeoutSeconds;
}

/// Sends the held-back values whose throttle window has closed, so the
/// last clock value before mpv goes quiet (a pause) still arrives.
void _flushTrailing(
  SendPort toMain,
  Map<String, dynamic> lastValues,
  Map<String, int> lastTimestamps,
  Map<String, double> trailing,
) {
  if (trailing.isEmpty) return;
  final now = _throttleClock.elapsedMilliseconds;
  for (final name in trailing.keys.toList(growable: false)) {
    final last = lastTimestamps[name] ?? -_kClockThrottleMs;
    if (now - last < _kClockThrottleMs) continue;
    final v = trailing.remove(name)!;
    lastTimestamps[name] = now;
    if (lastValues[name] == v) continue;
    lastValues[name] = v;
    toMain.send(MpvEventPropertyDouble(name, v));
  }
}

/// Decodes the value of an `mpv_event_property` payload into the same Dart
/// shapes the property-change pipeline produces (no dedup / throttle —
/// replies are one-shot). Returns `null` for `data == nullptr` or an
/// unobserved format.
dynamic _decodePropertyValue(mpv.MpvEventProperty prop) {
  if (prop.data == nullptr) return null;
  return switch (prop.format) {
    mpv.MpvFormat.mpvFormatDouble => prop.data.cast<Double>().value,
    mpv.MpvFormat.mpvFormatFlag => prop.data.cast<Int32>().value,
    mpv.MpvFormat.mpvFormatInt64 => prop.data.cast<Int64>().value,
    mpv.MpvFormat.mpvFormatString =>
      decodeMpvString(prop.data.cast<Pointer<Utf8>>().value),
    mpv.MpvFormat.mpvFormatNode =>
      decodeMpvNode(prop.data.cast<mpv.MpvNode>().ref),
    _ => null,
  };
}

void _dispatchLog(SendPort toMain, mpv.MpvEventLogMessage msg) {
  final prefix = decodeMpvString(msg.prefix.cast());
  final level = decodeMpvString(msg.level.cast());
  final text = decodeMpvString(msg.text.cast()).trimRight();
  toMain.send(MpvEventLog(prefix, level, text));
}

// ── String / node decoding ────────────────────────────────────────────────────

/// Decodes a NUL-terminated mpv-owned C string, replacing invalid UTF-8
/// sequences with U+FFFD instead of throwing.
///
/// mpv does not guarantee valid UTF-8 on every string it hands to the
/// client API: ICY response headers (`icy-name`, …) are copied into tags
/// verbatim, so a legacy latin-1 radio server delivers raw bytes like
/// `0xE9` here. A strict decode would throw [FormatException] mid-dispatch.
String decodeMpvString(Pointer<Utf8> ptr) {
  final units = ptr.cast<Uint8>();
  var length = 0;
  while (units[length] != 0) {
    length++;
  }
  return utf8.decode(units.asTypedList(length), allowMalformed: true);
}

/// Recursively converts an mpv `mpv_node` C struct into a Dart-native tree.
///
/// Maps:
///   - `MPV_FORMAT_NONE`        → `null`
///   - `MPV_FORMAT_STRING`      → [String]
///   - `MPV_FORMAT_FLAG`        → [bool]
///   - `MPV_FORMAT_INT64`       → [int]
///   - `MPV_FORMAT_DOUBLE`      → [double]
///   - `MPV_FORMAT_NODE_ARRAY`  → `List<dynamic>` of recursively-decoded children
///   - `MPV_FORMAT_NODE_MAP`    → `Map<String, dynamic>` of recursively-decoded children
///   - `MPV_FORMAT_BYTE_ARRAY`  → [Uint8List] copied out of mpv-owned memory
///
/// The returned tree owns its memory: any data borrowed from mpv (strings,
/// byte arrays) is copied during decoding so the caller can safely dispose
/// of the source `mpv_node` via `mpv_free_node_contents` immediately after.
///
/// Exposed at top-level (rather than file-private) so unit tests can build
/// synthetic `mpv_node` trees and exercise the decoder without spinning up
/// a real player.
dynamic decodeMpvNode(mpv.MpvNode node) {
  switch (node.format) {
    case mpv.MpvFormat.mpvFormatString:
      return decodeMpvString(node.u.string.cast());
    case mpv.MpvFormat.mpvFormatFlag:
      return node.u.flag != 0;
    case mpv.MpvFormat.mpvFormatInt64:
      return node.u.int64;
    case mpv.MpvFormat.mpvFormatDouble:
      return node.u.double_;
    case mpv.MpvFormat.mpvFormatNodeArray:
      final list = node.u.list.ref;
      return [
        for (var i = 0; i < list.num; i++) decodeMpvNode((list.values + i).ref),
      ];
    case mpv.MpvFormat.mpvFormatNodeMap:
      final list = node.u.list.ref;
      return <String, dynamic>{
        for (var i = 0; i < list.num; i++)
          decodeMpvString((list.keys + i).value.cast()):
              decodeMpvNode((list.values + i).ref),
      };
    case mpv.MpvFormat.mpvFormatByteArray:
      final ba = node.u.ba.ref;
      // Copy out of mpv-owned memory before the caller frees the node.
      return Uint8List.fromList(ba.data.cast<Uint8>().asTypedList(ba.size));
    default:
      return null;
  }
}

/// Structural equality over decoded `mpv_node` trees
/// (`Map<String, dynamic>` / `List` / scalars / [Uint8List]).
bool _deepNodeEquals(dynamic a, dynamic b) {
  if (identical(a, b)) return true;
  if (a is Map) {
    if (b is! Map || a.length != b.length) return false;
    for (final entry in a.entries) {
      if (!b.containsKey(entry.key) ||
          !_deepNodeEquals(entry.value, b[entry.key])) {
        return false;
      }
    }
    return true;
  }
  if (a is List<int> && a is TypedData) {
    if (b is! List<int> || b is! TypedData || a.length != b.length) {
      return false;
    }
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
  if (a is List) {
    if (b is! List || a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!_deepNodeEquals(a[i], b[i])) return false;
    }
    return true;
  }
  return a == b;
}

// ── Public bridge ─────────────────────────────────────────────────────────────

/// Manages the dedicated isolate that runs the mpv event loop.
///
/// The mpv API is thread-safe: the main isolate continues to call
/// [mpv_set_property], [mpv_command] etc. while this isolate blocks on
/// [mpv_wait_event], keeping the Flutter render thread free.
class MpvEventIsolate {
  Isolate? _isolate;
  SendPort? _toIsolate;
  ReceivePort? _fromIsolate;
  ReceivePort? _exitPort;
  // Native stop flag (Int32): the main isolate sets it to 1 in [requestStop],
  // the worker reads it every loop turn. Allocated in [start], freed in [stop]
  // ONLY on confirmed worker exit, so no parked reader survives the free.
  Pointer<Int32>? _stopFlag;
  // Non-broadcast: a single subscriber and buffering for events that
  // arrive between isolate-start and the main-side listen registration.
  // Using a broadcast controller dropped the initial PROPERTY_CHANGE
  // burst (mpv emits one per `mpv_observe_property` call right after
  // the isolate begins polling — ~70 properties), leaving downstream
  // state partially populated.
  final _events = StreamController<MpvIsolateEvent>();

  /// The post-init event stream; single-subscription with buffering (see
  /// the [_events] field for why the initial burst must not be dropped).
  Stream<MpvIsolateEvent> get events => _events.stream;

  /// Spawns the event isolate, runs the heavy mpv init recipe inside
  /// it, and resolves with the live `mpv_handle*` address. Heavy FFI
  /// (`mpv_create`, `mpv_initialize`, ~80 `mpv_observe_property`)
  /// never touches the main isolate, so the host UI stays responsive
  /// during cold start.
  ///
  /// The [onEvent] listener is wired BEFORE `_InitDone` is forwarded,
  /// eliminating the broadcast race that otherwise drops the initial
  /// property-change burst.
  ///
  /// [wakeupCounterAddress] is test-only.
  Future<int> start({
    String? libraryPath,
    void Function(MpvIsolateEvent)? onEvent,
    required Map<String, String> preInitOptions,
    required Map<String, String> postInitOptions,
    required List<MpvObserveSpec> observes,
    String? logLevel,
    int? wakeupCounterAddress,
  }) async {
    if (onEvent != null) _events.stream.listen(onEvent);

    _stopFlag = calloc<Int32>()..value = 0;

    final initPort = ReceivePort();
    _isolate = await Isolate.spawn(_isolateEntry, initPort.sendPort);

    final completer = Completer<SendPort>();
    final sub = initPort.listen((msg) {
      if (msg is SendPort && !completer.isCompleted) {
        completer.complete(msg);
      }
    });
    _toIsolate = await completer.future;
    await sub.cancel();
    initPort.close();

    // Arm the exit listener BEFORE the isolate can possibly tear down.
    _exitPort = ReceivePort();
    _isolate!.addOnExitListener(_exitPort!.sendPort);

    final initDone = Completer<int>();
    final fromIsolate = ReceivePort();
    _fromIsolate = fromIsolate;
    fromIsolate.listen((msg) {
      if (msg is _InitDone) {
        if (!initDone.isCompleted) initDone.complete(msg.handleAddress);
        return;
      }
      if (msg is _InitFailed) {
        if (!initDone.isCompleted) {
          initDone.completeError(StateError(msg.message));
        }
        return;
      }
      // Drop messages that arrive after `stop()` has closed the
      // controller. Without this guard the queued message would throw
      // "Bad state: Cannot add new events after calling close" —
      // visible only when many Player instances are created and
      // disposed in rapid succession.
      if (msg is MpvIsolateEvent && !_events.isClosed) {
        _events.add(msg);
      }
    });

    _toIsolate!.send(_InitMessage(
      fromIsolate.sendPort,
      libraryPath: libraryPath,
      preInitOptions: preInitOptions,
      postInitOptions: postInitOptions,
      observes: observes,
      logLevel: logLevel,
      wakeupCounterAddress: wakeupCounterAddress,
      stopFlagAddress: _stopFlag!.address,
    ),);

    return initDone.future;
  }

  /// Unblocks the event loop deterministically. Call from the main isolate in
  /// `Player.dispose()` AFTER `mpv_command(['quit'])`, immediately before
  /// [stop].
  ///
  /// Order is load-bearing: set the native stop flag FIRST (publish the
  /// intent), THEN `mpv_wakeup`. A parked `mpv_wait_event` returns at once
  /// with `MPV_EVENT_NONE`; the worker re-reads the flag and breaks. `mpv_wakeup`
  /// is thread-safe (libmpv) and guarantees no lost wakeups, so this works even
  /// if `quit` was dropped (`MPV_ERROR_EVENT_QUEUE_FULL`) or `MPV_EVENT_SHUTDOWN`
  /// is delayed by a stalled hook. Idempotent and null-safe.
  void requestStop(mpv.MpvLibrary lib, Pointer<mpv.MpvHandle> handle) {
    _stopFlag?.value = 1;
    lib.mpvWakeup(handle);
  }

  /// Awaits the worker isolate's ACTUAL termination.
  ///
  /// Returns `true` iff the exit was confirmed within [_kIsolateExitTimeout].
  /// On `false` the worker is NOT proven to have left `mpv_wait_event`, so the
  /// caller MUST NOT `mpv_terminate_destroy` the handle — freeing it while the
  /// isolate is still inside the syscall reads freed memory and SIGSEGVs at
  /// teardown. [Isolate.kill] is never used for the same reason (killing
  /// mid-FFI to libmpv is a non-deterministic crash).
  ///
  /// The native stop flag is freed ONLY on confirmed exit, when no parked
  /// reader can survive the free; on the timeout branch it is intentionally
  /// leaked (4 bytes, bounded by live Player count, reclaimed at process exit).
  Future<bool> stop() async {
    // Publish the stop intent unconditionally: callers that have no
    // (lib, handle) pair for [requestStop] — teardown before bring-up
    // completed — still need the worker's bounded wait to observe the
    // flag and exit on its next timeout expiry.
    _stopFlag?.value = 1;
    _fromIsolate?.close();
    _fromIsolate = null;
    // Fire-and-forget: closing the controller flushes any buffered
    // events to the (already-cancelled) subscriber; the load-bearing
    // wait is the isolate-exit await below, not this close.
    if (!_events.isClosed) unawaited(_events.close());

    final exitPort = _exitPort;
    final isolate = _isolate;
    if (isolate == null || exitPort == null) {
      _toIsolate = null;
      _exitPort = null;
      _freeStopFlag();
      return true;
    }

    _isolate = null;
    _toIsolate = null;
    _exitPort = null;

    // The exit listener was armed in `start()` before the isolate could
    // possibly tear down. The 2 s timeout is a safety net for a pathologically
    // stuck libmpv — clean exits land in single-digit ms via `mpv_wakeup`.
    try {
      await exitPort.first.timeout(_kIsolateExitTimeout);
      _freeStopFlag();
      return true;
    } on TimeoutException {
      return false;
    } finally {
      exitPort.close();
    }
  }

  void _freeStopFlag() {
    final flag = _stopFlag;
    if (flag != null) {
      calloc.free(flag);
      _stopFlag = null;
    }
  }
}
