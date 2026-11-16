// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:meta/meta.dart';

import '../mpv_bindings.dart';
import 'debug_log.dart';
import 'orphan_handle_tracker.dart';

/// How long Hot-Restart cleanup waits, after waking a leaked core with
/// `quit`, before destroying its handle. The previous VM's event isolate
/// may still be parked inside `mpv_wait_event` on that handle, and a Dart
/// isolate blocked in a synchronous FFI call can't be killed until it
/// returns to a safepoint — destroying the handle before then frees the
/// mutex it sleeps on (use-after-free). This comfortably exceeds the
/// 0.1 s debug wait-event timeout so the isolate has provably unwound.
const Duration _kOrphanReapDelay = Duration(milliseconds: 500);

/// Two-phase teardown for libmpv handles leaked across a Hot-Restart.
///
/// Phase 1 sends `quit` to each handle, which wakes the leaked core so the
/// previous VM's event isolate returns from `mpv_wait_event`, sees
/// MPV_EVENT_SHUTDOWN and is reaped. `quit` alone does NOT free the core's
/// worker threads or audio output. Phase 2, after [delay], destroys each
/// handle (`mpv_terminate_destroy` joins the core thread and releases the
/// audio output) — deferred so the destroy never races an isolate still
/// inside the syscall (use-after-free).
@internal
Future<void> reapOrphanedHandles(
  MpvLibrary lib,
  List<Pointer<MpvHandle>> references, {
  Duration delay = _kOrphanReapDelay,
}) async {
  const tag = 'mpv_audio_kit:';
  for (final ref in references) {
    final cmd = 'quit'.toNativeUtf8();
    try {
      lib.mpvCommandString(ref, cmd);
    } catch (e) {
      debugLog('$tag Error waking leaked handle: $e');
    } finally {
      calloc.free(cmd);
    }
  }

  await Future<void>.delayed(delay);

  for (final ref in references) {
    try {
      lib.mpvTerminateDestroy(ref);
    } catch (e) {
      debugLog('$tag Error terminating leaked handle: $e');
    }
  }
}

/// One-time initialization for `mpv_audio_kit`. Owns the libmpv
/// `DynamicLibrary` lookup and the orphaned-handle cleanup that fires
/// across Flutter Hot-Restarts.
abstract final class MpvAudioKit {
  MpvAudioKit._();

  static bool _initialized = false;
  static String? _libraryPath;

  /// Returns the path used to initialize the library, if provided.
  static String? get libraryPath => _libraryPath;

  /// Initializes the native backend for `mpv_audio_kit`.
  /// Must be called before creating any [Player] instances.
  ///
  /// Handles cleanup of orphaned `libmpv` native resources
  /// (e.g., handles that leaked across a Flutter Hot-Restart).
  ///
  /// [libmpv] (optional) — explicit path or filename for the native
  /// `libmpv` library to load via `DynamicLibrary.open`. When `null`
  /// (the default), the platform's standard lookup is used:
  /// `libmpv.so` on Linux/Android, `libmpv.dll` on Windows, and
  /// `libmpv.framework/libmpv` on macOS/iOS (resolved via the consumer
  /// app's @rpath).
  /// Pass an explicit path only when shipping a custom libmpv build
  /// alongside your app.
  ///
  /// [hotRestartCleanup] (default: `true`) — recovers libmpv handles
  /// leaked across a Flutter Hot-Restart so they don't keep
  /// exclusive-mode audio devices locked. Pass `false` in test runners
  /// or other multi-VM scenarios that share a pid; the tracker would
  /// otherwise mis-attribute prior-VM handles as orphans.
  static void ensureInitialized({
    String? libmpv,
    bool hotRestartCleanup = true,
  }) {
    if (_initialized) {
      return;
    }

    _applyPlatformQuirks();

    if (!hotRestartCleanup) {
      _libraryPath = libmpv;
      _initialized = true;
      return;
    }

    OrphanHandleTracker.instance.ensureInitialized((references) {
      if (references.isEmpty) {
        return;
      }

      const tag = 'mpv_audio_kit: OrphanHandleTracker:';
      debugLog('$tag Found ${references.length} orphaned reference(s).');
      debugLog('$tag Releasing leaked handles (Hot-Restart fix):');

      for (final ref in references) {
        debugLog(' - Address: ${ref.address}');
      }

      final lib = MpvLibrary.open(libmpv);
      unawaited(reapOrphanedHandles(lib, references));
    });

    _libraryPath = libmpv;
    _initialized = true;
  }

  /// Sets `LC_NUMERIC=C` process-wide on Linux and macOS — mandated
  /// by libmpv's API contract (`mpv/client.h`; mpv aborts loading
  /// otherwise).
  ///
  /// Process-wide is non-negotiable: mpv spawns its own threads at
  /// `mpv_create` time, and POSIX threads inherit `LC_GLOBAL_LOCALE`,
  /// not `uselocale`. Other locale categories (`LC_TIME`,
  /// `LC_MESSAGES`, …) are left untouched.
  static void _applyPlatformQuirks() {
    if (Platform.isWindows || Platform.isAndroid) {
      return;
    }

    try {
      final DynamicLibrary libc = Platform.isLinux
          ? DynamicLibrary.open('libc.so.6')
          : DynamicLibrary.open('libSystem.B.dylib');

      final setlocale = libc.lookupFunction<
          Pointer<Utf8> Function(Int32, Pointer<Utf8>),
          Pointer<Utf8> Function(int, Pointer<Utf8>)>('setlocale');

      // The LC_NUMERIC constant is libc-specific: glibc (Linux) numbers
      // it 1, the BSD layout (macOS/iOS) numbers it 4 — there, 1 is
      // LC_COLLATE, which would leave the numeric locale untouched.
      final lcNumeric = Platform.isLinux ? 1 : 4;
      using((arena) {
        setlocale(lcNumeric, 'C'.toNativeUtf8(allocator: arena));
      });
    } catch (e) {
      debugLog('mpv_audio_kit: setlocale failed: $e. '
          'mpv might fail to initialize if system locale is not compatible.');
    }
  }
}
