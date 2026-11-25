// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'package:meta/meta.dart';

import '../internals/core_events.dart';
import '../internals/mpv_requests.dart';

/// What a core starts with: the options set before and after
/// `mpv_initialize`, the observed properties and the log level.
@internal
final class CoreRecipe {
  /// A recipe of [preInitOptions], [postInitOptions], [observes] and
  /// [logLevel].
  const CoreRecipe({
    required this.preInitOptions,
    required this.postInitOptions,
    required this.observes,
    this.logLevel,
  });

  /// `mpv_set_option_string` calls before `mpv_initialize`.
  final Map<String, String> preInitOptions;

  /// Property writes right after `mpv_initialize`.
  final Map<String, String> postInitOptions;

  /// The properties observed for the player, in this order.
  final List<MpvObserveSpec> observes;

  /// The `mpv_request_log_messages` level set before `mpv_initialize`;
  /// `null` for none.
  final String? logLevel;
}

/// One mpv core of a player and the client it talks to it through: the
/// bring-up, the event pump, the requests, the hook registration and the
/// teardown. Native: an event isolate over FFI. Web: the main thread over
/// js_interop with the module in WebAssembly.
///
/// Created with the player, so a dispose right after construction finds
/// it; [start] runs once, and the requests work once it completed.
@internal
abstract interface class MpvSession implements MpvRequests {
  /// Creates the core with [recipe] and starts its event pump, whose events
  /// go to [onEvent] in mpv's order. Completes once mpv runs; throws
  /// `PlayerInitException` when it cannot start.
  Future<void> start(
    CoreRecipe recipe,
    void Function(MpvIsolateEvent event) onEvent,
  );

  /// Resolves the write or command [id] with its reply, which the player
  /// got as an [MpvEventReply].
  void onReply(int id, int error, Object? result);

  /// Resolves the read [id] with its reply, which the player got as an
  /// [MpvEventGetReply].
  void onGetReply(int id, int error, Object? value);

  /// Registers hook [name] with [priority] on the core. `mpv_hook_add`
  /// waits for the core, so it never runs where a wait would stall the
  /// UI. Completes once mpv took it.
  Future<void> hookAdd(String name, int priority);

  /// Waits, at most until [bound], for every [hookAdd] still running,
  /// those that start meanwhile included, and for every continue run off
  /// the main isolate (`MpvHookContinueOffMain`). Returns whether they
  /// settled: the core must not be destroyed under one.
  Future<bool> settleHookAdds(Duration bound);

  /// Records the core for the Hot Restart cleanup, once bring-up kept it.
  void track();

  /// Drops the core from the Hot Restart cleanup, at dispose.
  void untrack();

  /// Asks the event pump to stop now, even if `quit` was dropped or
  /// `MPV_EVENT_SHUTDOWN` is late.
  void requestStop();

  /// Stops the event pump and waits until it stopped. Returns whether that
  /// was confirmed: only then may [terminateDestroy] run. Safe before
  /// [start] and more than once.
  Future<bool> stop();

  /// Stops every further request from reaching mpv and resolves the
  /// pending ones. Call it once no reply can arrive any more.
  void close();

  /// Destroys the core (`mpv_terminate_destroy`) without blocking the
  /// caller's thread. Completes once the core is gone.
  Future<void> terminateDestroy();
}
