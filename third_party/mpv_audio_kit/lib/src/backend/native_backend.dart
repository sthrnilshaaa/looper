// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:ffi';
import 'dart:isolate';

import 'package:ffi/ffi.dart';
import 'package:meta/meta.dart';

import '../internals/debug_log.dart';
import '../internals/event_isolate.dart';
import '../internals/library_loader.dart';
import '../internals/mpv_client.dart';
import '../internals/mpv_requests.dart';
import '../internals/orphan_handle_tracker.dart';
import '../mpv_bindings.dart';
import '../pcm/pcm_native.dart';
import '../pcm/pcm_native_io.dart';
import 'mpv_session.dart';

/// A session over the libmpv the players use, through FFI: the core starts
/// and its events run in an event isolate. [wakeupCounterAddress] is
/// test-only (see `Player.testInstrumented`).
@internal
MpvSession createMpvSession({int? wakeupCounterAddress}) =>
    _NativeSession(wakeupCounterAddress);

/// The native steps of [MpvAudioKit.ensureInitialized] before the kit
/// counts as initialized.
@internal
void startBackend({String? libmpv, required bool hotRestartCleanup}) =>
    startNativeBackend(libmpv: libmpv, hotRestartCleanup: hotRestartCleanup);

/// The libmpv to open when the app gives none: the one a plugin bundles
/// where no build hook ran (flutter-webos), else null for the hook's.
@internal
String? defaultLibmpv() => defaultNativeLibmpv();

/// The native steps of [MpvAudioKit.ensureInitialized] once the kit
/// counts as initialized, with the Hot Restart cleanup on.
@internal
void backendInitialized() => nativeBackendInitialized();

/// The live PCM input of the libmpv at [path], or of the bundled one.
@internal
PcmNative openPcmNative(String? path) => openNativePcm(path);

/// The library loads with the first call into it: nothing to wait for.
@internal
Future<void>? backendReady() => null;

/// The audio drivers start on their own: nothing to resume.
@internal
void resumeOutput() {}

/// The output follows `audio-samplerate` alone.
@internal
Future<void>? setOutputSampleRate(int rate) => null;

/// No autoplay policy holds the sound.
@internal
bool get outputNeedsGesture => false;

/// A native platform has what libmpv needs; a missing library fails the
/// player itself.
@internal
String? get unsupportedReason => null;

/// [outputNeedsGesture] never changes.
@internal
Stream<bool> get outputNeedsGestureChanges => const Stream<bool>.empty();

/// No driver option stands in for `ao-volume` before an output is open.
@internal
const String? kOutputVolumeOption = null;

/// No driver option stands in for `ao-mute` before an output is open.
@internal
const String? kOutputMuteOption = null;

final class _NativeSession implements MpvSession, MpvHookContinueOffMain {
  _NativeSession(this._wakeupCounterAddress);

  // Test-only; null in production.
  final int? _wakeupCounterAddress;

  // Eagerly instantiated so `stop()` is safe even when the player is
  // disposed synchronously after construction. The actual mpv init runs
  // inside the isolate, driven by [start].
  final MpvEventIsolate _isolate = MpvEventIsolate();
  late final MpvLibrary _lib;
  late final Pointer<MpvHandle> _handle;
  late final MpvClient _client;

  /// In-flight [hookAdd] and [hookContinueOffMain] runs. `mpv_hook_add`
  /// and `mpv_hook_continue` lock the core and have no async variant, so
  /// they execute in a throwaway `Isolate.run` against the shared handle;
  /// dispose must await any outstanding one BEFORE `mpv_terminate_destroy`
  /// frees the handle, or the throwaway isolate would dereference freed
  /// memory (`lock_core(ctx)`).
  final Set<Future<void>> _hookAdds = {};

  @override
  Future<void> start(
    CoreRecipe recipe,
    void Function(MpvIsolateEvent event) onEvent,
  ) async {
    // After a Hot Restart the cores of the replaced VM hold their audio
    // output until the reap destroys them: an exclusive output opened
    // meanwhile fails (F220). Bounded, so a destroy that hangs does not
    // hold the player.
    final orphans = orphansReleased;
    if (orphans != null) {
      try {
        await orphans.timeout(const Duration(seconds: 2));
      } on TimeoutException {
        debugLog('mpv_audio_kit: the Hot Restart reap is still running');
      }
    }

    final handleAddress = await _isolate.start(
      libraryPath: MpvAudioKit.libraryPath,
      onEvent: onEvent,
      preInitOptions: recipe.preInitOptions,
      postInitOptions: recipe.postInitOptions,
      observes: recipe.observes,
      logLevel: recipe.logLevel,
      wakeupCounterAddress: _wakeupCounterAddress,
    );
    // Re-open the library on the main isolate. The OS keeps libmpv
    // mapped after the event isolate's first dlopen, so this resolves
    // in microseconds: no second cold-load cost.
    _lib = MpvLibrary.open(MpvAudioKit.libraryPath);
    _handle = Pointer<MpvHandle>.fromAddress(handleAddress);
    _client = MpvClient(_lib, _handle);
  }

  @override
  void onReply(int id, int error, Object? result) =>
      _client.onReply(id, error, result);

  @override
  void onGetReply(int id, int error, Object? value) =>
      _client.onGetReply(id, error, materializeBytes(value));

  @override
  Future<void> hookAdd(String name, int priority) async {
    // `mpv_hook_add` locks the core (it waits for the playloop to reach a
    // dispatch point), so on the main isolate it would stall behind a busy
    // audio-output init. There is no command or async equivalent in the
    // client API: run it in a throwaway isolate, where waiting is harmless.
    // The registration targets the shared client handle, so hook events
    // still arrive on the player's event isolate.
    final handleAddress = _handle.address;
    final libraryPath = MpvAudioKit.libraryPath;
    // Track the run so dispose can await it before freeing the handle:
    // mpv_hook_add does `lock_core(ctx)` on the shared core, and a busy
    // playloop can hold it long enough for a concurrent dispose to reach
    // mpv_terminate_destroy first (use-after-free on the freed MPContext).
    await _tracked(
      Isolate.run(() {
        final lib = MpvLibrary.open(libraryPath);
        using((arena) {
          lib.mpvHookAdd(
            Pointer<MpvHandle>.fromAddress(handleAddress),
            0,
            name.toNativeUtf8(allocator: arena),
            priority,
          );
        });
      }),
    );
  }

  @override
  void hookContinueOffMain(int id) {
    // After close the handle is about to be freed: as for hookContinue.
    if (_client.isClosed) return;
    final handleAddress = _handle.address;
    final libraryPath = MpvAudioKit.libraryPath;
    // Tracked as hookAdd is, for the same reason: the continue waits for
    // the core, and dispose must not free it meanwhile.
    unawaited(
      _tracked(
        Isolate.run(() {
          MpvLibrary.open(
            libraryPath,
          ).mpvHookContinue(Pointer<MpvHandle>.fromAddress(handleAddress), id);
        }),
      ).catchError((Object e) {
        debugLog('mpv_audio_kit: hook continue failed: $e');
      }),
    );
  }

  /// Awaits [run] with it in [_hookAdds] meanwhile.
  Future<void> _tracked(Future<void> run) async {
    _hookAdds.add(run);
    try {
      await run;
    } finally {
      _hookAdds.remove(run);
    }
  }

  @override
  Future<bool> settleHookAdds(Duration bound) async {
    // Re-read the set until it is empty: Future.wait takes a snapshot, and
    // a setSourceResolver suspended between its two registrations could
    // start the second one after it.
    var settled = true;
    final deadline = DateTime.now().add(bound);
    while (settled && _hookAdds.isNotEmpty) {
      final left = deadline.difference(DateTime.now());
      try {
        await Future.wait(_hookAdds.toList()).timeout(left);
      } on TimeoutException {
        settled = false;
      } catch (_) {}
    }
    return settled;
  }

  @override
  void track() => OrphanHandleTracker.instance.add(_handle);

  @override
  void untrack() => OrphanHandleTracker.instance.remove(_handle);

  @override
  void requestStop() => _isolate.requestStop(_lib, _handle);

  @override
  Future<bool> stop() => _isolate.stop();

  @override
  void close() => _client.close();

  @override
  Future<void> terminateDestroy() => terminateDestroyOffMain(_handle);

  // ── MpvRequests, through the async client ─────────────────────────────

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
