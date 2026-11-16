// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

part of 'event_isolate.dart';

// ── Messages: main → isolate ─────────────────────────────────────────────────

/// Carries the full "init recipe" so the isolate can run the heavy
/// FFI sequence (`mpv_create` → pre-init opts → `mpv_initialize` →
/// post-init opts → `mpv_observe_property` × N) off the main thread.
class _InitMessage {
  final SendPort toMain;
  final String? libraryPath;
  final Map<String, String> preInitOptions;
  final Map<String, String> postInitOptions;
  final List<MpvObserveSpec> observes;

  /// Optional `mpv_request_log_messages` level, applied between
  /// `mpv_create` and `mpv_initialize`.
  final String? logLevel;

  /// Test-only: address of an `Int64` cell incremented once per
  /// `mpv_wait_event` return, so tests can assert the loop doesn't
  /// busy-poll. `null` in production.
  final int? wakeupCounterAddress;

  /// Address of a calloc'd `Int32` stop flag the event loop reads every
  /// iteration: `0` = keep running, `1` = unwind and exit. The main isolate
  /// sets it (then calls `mpv_wakeup`) in [MpvEventIsolate.requestStop]. This
  /// is the only exit mechanism that does not depend on mpv emitting
  /// `MPV_EVENT_SHUTDOWN`, so it survives a dropped `quit` or a stalled hook.
  final int stopFlagAddress;

  _InitMessage(
    this.toMain, {
    this.libraryPath,
    required this.preInitOptions,
    required this.postInitOptions,
    required this.observes,
    this.logLevel,
    this.wakeupCounterAddress,
    required this.stopFlagAddress,
  });
}

/// Single property to register via `mpv_observe_property` from the
/// isolate. [replyId] is opaque user data; the dispatcher matches by
/// name on the receive side.
class MpvObserveSpec {
  /// mpv property name to observe (e.g. `time-pos`, `pause`).
  final String name;

  /// The `MPV_FORMAT_*` constant the property's value is delivered in.
  final int format;

  /// Opaque user-data tag echoed back on each property change; the
  /// main-side dispatcher matches incoming changes by [name], not this.
  final int replyId;

  /// Describes a single property to register via `mpv_observe_property`.
  const MpvObserveSpec(this.name, this.format, this.replyId);
}

// ── Messages: isolate → main (init handshake only) ───────────────────────────

/// Init succeeded; carries the live `mpv_handle*` address so the main
/// isolate can wrap it as a `Pointer<MpvHandle>`.
class _InitDone {
  final int handleAddress;
  _InitDone(this.handleAddress);
}

/// Init failed somewhere between `mpv_create` and the final observe.
class _InitFailed {
  final String message;
  _InitFailed(this.message);
}
