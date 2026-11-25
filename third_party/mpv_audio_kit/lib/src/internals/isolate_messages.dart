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

  /// Address of the `Int32` word [OwnerWatch] raises once the isolate that
  /// started this one exited: the loop then frees mpv itself.
  final int ownerGoneAddress;

  _InitMessage(
    this.toMain, {
    this.libraryPath,
    required this.preInitOptions,
    required this.postInitOptions,
    required this.observes,
    this.logLevel,
    this.wakeupCounterAddress,
    required this.stopFlagAddress,
    required this.ownerGoneAddress,
  });
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
