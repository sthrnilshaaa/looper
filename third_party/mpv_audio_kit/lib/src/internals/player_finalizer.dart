// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:ffi';

import 'package:meta/meta.dart';

import '../mpv_bindings.dart';
import 'debug_log.dart';
import 'library_loader.dart';
import 'orphan_handle_tracker.dart';

/// Native-resource bag attached to a `Player` via [Finalizer].
/// Carries the `mpv_handle*` plus the `MpvLibrary` needed to tear the
/// leaked core down. `Player.dispose()` flips [disposed] so a
/// late-firing finalizer becomes a no-op.
@internal
class PlayerNativeResources {
  PlayerNativeResources(this.lib, this.handle);

  final MpvLibrary lib;
  final Pointer<MpvHandle> handle;
  bool disposed = false;
}

/// Safety net for consumers that drop a `Player` without calling
/// `dispose()` — fires on GC of the `Player` instance.
///
/// Reaps the leaked core via [reapOrphanedHandles]: a cooperative `quit`
/// first, so the still-running event isolate (blocked inside
/// `mpv_wait_event` on the same handle) returns on `MPV_EVENT_SHUTDOWN`
/// and unwinds, then `mpv_terminate_destroy` after a delay — deferred so
/// the destroy never races that isolate while it is still in the syscall.
/// Destroying it eagerly would crash at process teardown.
///
/// Hot-Restart is handled separately by [OrphanHandleTracker] — Dart
/// finalizers don't fire when the VM is replaced.
@internal
final Finalizer<PlayerNativeResources> playerFinalizer =
    Finalizer<PlayerNativeResources>(finalizePlayerForTesting);

/// Internal entry point for the finalizer logic. Exposed (without
/// underscore prefix) so unit tests can drive it with a spy
/// [MpvLibrary] without forcing a real GC. Production code MUST NOT
/// call this directly — use `Player.dispose()` instead.
@visibleForTesting
void finalizePlayerForTesting(PlayerNativeResources resources) {
  if (resources.disposed) return;
  try {
    debugLog(
      'mpv_audio_kit: Player GC\'d without dispose() '
      '(handle=${resources.handle.address}). Reaping leaked core. '
      'Prefer `await player.dispose()` to avoid this safety net.',
    );
    OrphanHandleTracker.instance.remove(resources.handle);
    unawaited(reapOrphanedHandles(resources.lib, [resources.handle]));
  } catch (e) {
    debugLog('mpv_audio_kit: finalizer cleanup failed: $e');
  } finally {
    resources.disposed = true;
  }
}
