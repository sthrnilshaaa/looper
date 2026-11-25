// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

import 'package:ffi/ffi.dart';
import 'package:flutter/services.dart' show RootIsolateToken;
import 'package:meta/meta.dart';

import '../media_session/media_session_channel.dart';
import '../mpv_bindings.dart';
import '../pcm/pcm_native.dart';
import 'debug_log.dart';
import 'mpv_audio_kit.dart';
import 'orphan_handle_tracker.dart';
import 'owner_watch.dart';

export 'mpv_audio_kit.dart';

/// How long Hot-Restart cleanup waits, after waking a leaked core with
/// `quit`, before destroying its handle. The previous VM's event isolate
/// may still be parked inside `mpv_wait_event` on that handle, and a Dart
/// isolate blocked in a synchronous FFI call can't be killed until it
/// returns to a safepoint: destroying the handle before then frees the
/// mutex it sleeps on (use-after-free). This comfortably exceeds the
/// 0.1 s debug wait-event timeout so the isolate has provably unwound.
const Duration _kOrphanReapDelay = Duration(milliseconds: 500);

/// Two-phase teardown for libmpv handles leaked across a Hot-Restart.
///
/// Phase 1 sends `quit` to each handle, which wakes the leaked core so the
/// previous VM's event isolate returns from `mpv_wait_event`, sees
/// MPV_EVENT_SHUTDOWN and is reaped. `quit` alone does NOT free the core's
/// worker threads or audio output. Phase 2, after [delay], destroys each
/// handle with [destroy] (`mpv_terminate_destroy` joins the core thread and
/// releases the audio output): deferred so the destroy never races an
/// isolate still inside the syscall (use-after-free). The default destroys
/// off the main isolate, which keeps running the new VM meanwhile.
/// Completes once every handle is destroyed.
///
/// With [stopAnalysis], phase 1 first turns off the waveform, the loudness
/// scan and the analyzer taps. libmpv keeps them per process, not per core,
/// and the previous VM never ran the dispose that turns them off: left on,
/// every file the new VM opens is decoded for nobody.
@internal
Future<void> reapOrphanedHandles(
  MpvLibrary lib,
  List<Pointer<MpvHandle>> references, {
  Duration delay = _kOrphanReapDelay,
  bool stopAnalysis = true,
  Future<void> Function(Pointer<MpvHandle> handle) destroy =
      terminateDestroyOffMain,
}) async {
  for (final ref in references) {
    sendCoreCommands(lib, ref, [
      if (stopAnalysis) ...analysisOffCommands,
      'quit',
    ]);
  }

  await Future<void>.delayed(delay);

  for (final ref in references) {
    try {
      await destroy(ref);
    } catch (e) {
      debugLog('mpv_audio_kit: Error terminating leaked handle: $e');
    }
  }
}

/// The Hot Restart reap of the cores the replaced VM leaked, started by
/// [MpvAudioKit.ensureInitialized], which completes once they are
/// destroyed; `null` when there was none. A player's bring-up waits for it:
/// until the destroy, an orphan holds its audio output (F220).
@internal
Future<void>? get orphansReleased => _orphansReleased;
Future<void>? _orphansReleased;

/// Destroys the core behind [handle] in a throwaway isolate, so the caller
/// keeps running meanwhile: `mpv_terminate_destroy` sends a synchronous
/// `quit`, waits for every async reply, joins the core thread and closes
/// the audio output and the demuxer, which on a busy output takes as long
/// as its init. The output closes on the core thread whichever thread
/// destroys (F289). Completes once the core is gone.
///
/// The library is the one at [libraryPath], or else at
/// [MpvAudioKit.libraryPath].
@internal
Future<void> terminateDestroyOffMain(
  Pointer<MpvHandle> handle, {
  String? libraryPath,
}) async {
  final address = handle.address;
  final path = libraryPath ?? MpvAudioKit.libraryPath;
  try {
    await Isolate.run(
      () => MpvLibrary.open(
        path,
      ).mpvTerminateDestroy(Pointer<MpvHandle>.fromAddress(address)),
      debugName: 'mpv_audio_kit destroy',
    );
  } catch (e) {
    // No isolate: the core stays, as on an unconfirmed event-isolate exit.
    debugLog('mpv_audio_kit: cannot destroy the core off the main isolate: $e');
  }
}

/// The libmpv a plugin bundles where the build hook does not run
/// (flutter-webos, whose webos/CMakeLists.txt installs it): on Linux,
/// lib/libmpv_audio_kit_webos.so beside [executable] when it [exists]. Its
/// own name, not the hook's asset (lib/libmpv_audio_kit.so on Linux
/// desktop), so nothing is loaded to tell them apart. null elsewhere: the
/// hook's libmpv.
@internal
String? pluginLibmpv({
  required bool isLinux,
  required String executable,
  required bool Function(String path) exists,
}) {
  if (!isLinux) return null;
  final path = '${File(executable).parent.path}/lib/libmpv_audio_kit_webos.so';
  return exists(path) ? path : null;
}

/// [pluginLibmpv] of this process.
@internal
String? defaultNativeLibmpv() => pluginLibmpv(
  isLinux: Platform.isLinux,
  executable: Platform.resolvedExecutable,
  exists: (path) => File(path).existsSync(),
);

/// The native steps of [MpvAudioKit.ensureInitialized] before the kit
/// counts as initialized: the platform quirks, and with
/// [hotRestartCleanup] the orphan tracker, whose reap of the cores a
/// Hot-Restart leaked starts here.
@internal
void startNativeBackend({String? libmpv, required bool hotRestartCleanup}) {
  _applyPlatformQuirks();

  if (!hotRestartCleanup) return;

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

    // Best effort: MpvLibraryException is not public, and a library
    // that cannot be reopened leaves the handles to the process exit.
    final MpvLibrary lib;
    try {
      lib = MpvLibrary.open(libmpv);
    } on MpvLibraryException catch (e) {
      debugLog('$tag cannot reopen libmpv: ${e.message}');
      return;
    }
    // The analysis switches are process-wide, like the PCM sources below:
    // only the root isolate a Hot-Restart replaced turns them off.
    _orphansReleased = reapOrphanedHandles(
      lib,
      references,
      stopAnalysis: releasesPcmSourcesAtInit(
        restarted: OrphanHandleTracker.instance.restarted,
      ),
      destroy: (handle) => terminateDestroyOffMain(handle, libraryPath: libmpv),
    );
  });
}

/// The native steps of [MpvAudioKit.ensureInitialized] with the Hot
/// Restart cleanup, once the kit counts as initialized: in the root
/// isolate of a Hot-Restart, the release of the replaced VM's live PCM
/// sources and OS media session.
@internal
void nativeBackendInitialized() {
  if (releasesPcmSourcesAtInit(
    restarted: OrphanHandleTracker.instance.restarted,
  )) {
    _releasePcmSources();
    _disableMediaSession();
  }
}

/// Aborts and frees the live PCM sources of the VM a Hot-Restart
/// replaced: the native side outlives it, and their readers would wait
/// on input that never comes. See [releasesPcmSourcesAtInit].
void _releasePcmSources() {
  try {
    pcmNative().releaseAll();
  } catch (e) {
    // A custom libmpv without the live PCM input: nothing to release.
    debugLog('mpv_audio_kit: no PCM sources to release: $e');
  }
}

/// Turns off the OS media session of the VM a Hot-Restart replaced. The
/// engine and its plugins outlive the VM: the notification, the lock
/// screen entry and the audio focus stay, still showing the old track,
/// and their buttons reach no listener. Sent before any `enable` of
/// this VM, on the same channel, so it lands first.
void _disableMediaSession() {
  // Needs the services binding (`WidgetsFlutterBinding.ensureInitialized`
  // first, as the README shows): without it the session stays on.
  unawaited(
    MediaSessionChannel().disable().catchError((Object e) {
      debugLog('mpv_audio_kit: cannot disable the old media session: $e');
    }),
  );
}

/// Sets `LC_NUMERIC=C` process-wide on Linux, OHOS and macOS: mandated
/// by libmpv's API contract (`mpv/client.h`; mpv aborts loading
/// otherwise). OHOS is Flutter-OH, whose `Platform.operatingSystem` is
/// `ohos`: neither Linux nor Android, with the musl libc of OpenHarmony.
///
/// Process-wide is non-negotiable: mpv spawns its own threads at
/// `mpv_create` time, and POSIX threads inherit `LC_GLOBAL_LOCALE`,
/// not `uselocale`. Other locale categories (`LC_TIME`,
/// `LC_MESSAGES`, …) are left untouched.
void _applyPlatformQuirks() {
  if (Platform.isWindows || Platform.isAndroid) {
    return;
  }

  try {
    final ohos = Platform.operatingSystem == 'ohos';
    final DynamicLibrary libc = Platform.isLinux
        ? DynamicLibrary.open('libc.so.6')
        : ohos
        ? DynamicLibrary.open('libc.so')
        : DynamicLibrary.open('libSystem.B.dylib');

    final setlocale = libc
        .lookupFunction<
          Pointer<Utf8> Function(Int32, Pointer<Utf8>),
          Pointer<Utf8> Function(int, Pointer<Utf8>)
        >('setlocale');

    // The LC_NUMERIC constant is libc-specific: glibc (Linux) and musl
    // (OHOS) number it 1, the BSD layout (macOS and iOS) numbers it 4:
    // there, 1 is LC_COLLATE, which would leave the numeric locale
    // untouched.
    final lcNumeric = Platform.isLinux || ohos ? 1 : 4;
    using((arena) {
      setlocale(lcNumeric, 'C'.toNativeUtf8(allocator: arena));
    });
  } catch (e) {
    debugLog(
      'mpv_audio_kit: setlocale failed: $e. '
      'mpv might fail to initialize if system locale is not compatible.',
    );
  }
}

/// Whether [MpvAudioKit.ensureInitialized] releases every live PCM source
/// of the process: only after a Hot-Restart ([restarted], which the
/// debug-only orphan tracker detects), and only in the root isolate.
///
/// The sources are process-wide. A release at every init would cut those
/// of the other players and isolates. The tracker reports a restart only
/// when the VM that owned its buffer is gone, and the release stays with
/// the root isolate, which a Hot-Restart replaces and which alone holds a
/// `RootIsolateToken`. A second Flutter engine in the process (add-to-app)
/// has a root isolate of its own, whose sources a Hot-Restart of the first
/// engine would cut: pass `hotRestartCleanup: false` there.
/// The orphan reap turns off the analysis switches, process-wide too, under
/// the same guard.
@internal
bool releasesPcmSourcesAtInit({required bool restarted}) =>
    restarted && RootIsolateToken.instance != null;
