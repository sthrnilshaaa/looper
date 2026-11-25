// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

part of '../player.dart';

/// The teardown of [Player.dispose], in the order its doc gives, in one
/// place: the steps before the first await (refuse new calls, continue the
/// pending hooks, end the live sources), the release of the OS media
/// session, then the core, the pipelines and the streams.
mixin _TeardownModule on _PlayerBase, _MediaSessionModule {
  @override
  Future<void> _disposeImpl() async {
    // New calls are refused from the first line, as the teardown order
    // in [_PlayerBase.dispose] says.
    _disposed = true;
    // Before the first await: a hook timer firing during the session
    // release would drop its id without continuing it (it skips the FFI
    // call once disposed), and mpv would wait on that hook at shutdown.
    // Every pending hook continues now, so the `quit` that follows finds
    // no operation held by this client. (The event isolate exits anyway,
    // on its stop flag, and mpv_terminate_destroy completes the hooks of
    // the removed client; the continue keeps the core from waiting on them
    // meanwhile.) An event is pending only once bring-up delivered it, so
    // the handle exists here.
    for (final (mpvId, name) in _hooks.takeAll()) {
      _continueMpvHook(mpvId, name);
    }
    // Before the quit: an ended source wakes a reader blocked on it.
    _entries.endLive();
    // Release the OS media session BEFORE tearing libmpv down. After
    // the steps below the FFI handle is gone: leaving the native
    // session published would surface a stale lockscreen entry
    // pointing at a dead Player, and incoming commands (play from
    // the lockscreen) would land on disposed state.
    try {
      await _releaseMediaSession();
    } catch (_) {
      // Best effort: session teardown must never block disposal.
    }

    // Wait for init to settle. The handle, lib and native-resources
    // fields are only assigned when bring-up reaches the very end of
    // its body, so `_bringUpCompleted` is the authoritative gate for
    // touching them, even if `_ready` resolved without throwing it
    // may have early-returned because dispose flipped during init.
    try {
      await _ready;
    } catch (_) {}

    if (_bringUpCompleted) {
      _session.untrack();
      await _waveformPipeline.dispose();
      await _spectrumPipeline.dispose();
      await _loudnessMeterPipeline.dispose();
      await _loudnessScanPipeline.dispose();
      // Cooperative quit: mpv fires MPV_EVENT_SHUTDOWN and the isolate's
      // mpv_wait_event returns. requestStop (stop flag + mpv_wakeup) unblocks
      // the loop deterministically even if `quit` was dropped or SHUTDOWN is
      // delayed by a stalled hook. mpv_terminate_destroy runs only AFTER the
      // confirmed exit below: destroying mid-syscall would crash libmpv.
      // Fire-and-forget: quit's reply may never be forwarded (the isolate is
      // about to stop): the drain below settles the dangling future.
      unawaited(_calls.command(['quit']));
      _session.requestStop();
      // The taps after the quit: their streams are the app's own, and
      // nothing a listener does may keep mpv alive. The analyzer-taps write
      // still reaches the core, which serves it before the destroy below.
      await _filterTapPipeline.dispose();
      final exited = await _session.stop();
      // A registerHook may still be running mpv_hook_add against this
      // handle: it MUST finish before the handle is freed below. quit + the
      // stop above have driven the core toward a dispatch point, so the
      // core-locked hook_add is granted and returns. Bounded: if it doesn't
      // settle (a pathologically stuck playloop), skip the destroy and leak
      // the handle rather than free it under the running call (same
      // trade-off as an unconfirmed event-isolate exit).
      final hooksSettled = await _session.settleHookAdds(
        const Duration(seconds: 2),
      );
      // From here no FFI may touch the handle, and no reply can arrive:
      // closing the client resolves every in-flight call, so an
      // `await player.setX(...)` racing dispose never hangs, and turns the
      // continuations that resumes (a setter suspended between writes)
      // into no-ops, while the destroy below frees the handle.
      _session.close();
      if (exited && hooksSettled) {
        // Off the main isolate: the destroy waits for the core to shut down.
        await _session.terminateDestroy();
        // mpv is gone: nothing reads the descriptors any more.
        for (final release in _entries.takeAll()) {
          await release();
        }
      } else {
        // The worker did not confirm it left mpv_wait_event within the bound.
        // No mpv_terminate_destroy now: freeing the handle while the isolate
        // may still be inside the syscall would SIGSEGV. The destroy follows
        // once the worker has left, without holding dispose.
        debugLog(
          'mpv_audio_kit: event isolate did not confirm exit; '
          'mpv_terminate_destroy waits for it.',
        );
        unawaited(_destroyOnceStopped());
      }
    } else {
      // Bring-up never completed: either init failed, or this dispose
      // aborted it, in which case bring-up's early-return branch (the
      // only code that ever saw the handle) has already quit the core
      // and stopped the worker, and the `await _ready` above waited for
      // that teardown. The stop() here is a best-effort no-op backstop.
      try {
        await _session.stop();
      } catch (_) {}
    }

    await _disposeSessionController();
    await _closeStreams();
  }

  /// Tears down the media-session controller before the backing reactives
  /// close: its subscriptions need live streams to cancel cleanly, and its
  /// final `disable()` call to native needs the controller still wired.
  /// The release of the media session at the start of the teardown already
  /// tore the controller down, but we double-check for safety in case a
  /// future code path skips that step.
  Future<void> _disposeSessionController() async {
    final controller = _mediaSessionController;
    _mediaSessionController = null;
    if (controller == null) return;
    try {
      await controller.dispose();
    } catch (_) {
      // Best effort: never block disposal on session teardown.
    }
  }

  /// Destroys a core [dispose] had to leave alone, once its event pump has
  /// stopped and no hook registration runs against it: an event isolate
  /// held in a read behind a busy core (an output that takes seconds to
  /// open) exits after the bound of [MpvSession.stop]. Asks again for about
  /// a minute, then leaves the core to the process exit.
  Future<void> _destroyOnceStopped() async {
    try {
      for (var tries = 0; tries < 30; tries++) {
        if (await _session.stop() &&
            await _session.settleHookAdds(const Duration(seconds: 2))) {
          await _session.terminateDestroy();
          for (final release in _entries.takeAll()) {
            await release();
          }
          return;
        }
      }
      debugLog(
        'mpv_audio_kit: event isolate never confirmed exit; the core is '
        'left to the process exit.',
      );
    } catch (e) {
      debugLog('mpv_audio_kit: late destroy of the core failed: $e');
    }
  }
}
