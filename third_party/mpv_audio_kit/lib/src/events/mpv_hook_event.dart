// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import '../types/enums/hook.dart';

/// Emitted by [PlayerStream.hook] when mpv fires a registered hook.
///
/// You **must** call [Player.continueHook] with [id] exactly once,
/// even if processing fails — otherwise mpv will stall indefinitely.
///
/// Example:
/// ```dart
/// player.registerHook(Hook.load);
/// player.stream.hook.listen((event) async {
///   if (event.hook == Hook.load) {
///     final url = await player.getRawProperty('stream-open-filename') ?? '';
///     if (url.startsWith('my-scheme://')) {
///       await player.setRawProperty(
///         'stream-open-filename',
///         await resolve(url),
///       );
///     }
///   }
///   player.continueHook(event.id); // always call, even on error
/// });
/// ```
class MpvHookEvent {
  /// Opaque identifier required by [Player.continueHook].
  final int id;

  /// The lifecycle phase mpv is asking you to handle.
  final Hook hook;

  /// Creates a hook event for the given libmpv hook [id] and [hook] phase.
  const MpvHookEvent(this.id, this.hook);

  @override
  String toString() => 'MpvHookEvent(hook: ${hook.name}, id: $id)';
}
