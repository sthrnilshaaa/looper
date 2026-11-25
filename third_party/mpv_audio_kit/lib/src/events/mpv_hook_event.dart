// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import '../types/enums/hook.dart';

/// Emitted by [PlayerStream.hook] when mpv fires a registered hook.
///
/// You **must** call [Player.continueHook] with [id] exactly once, even
/// if processing fails: until then mpv waits on the file. Call it in a
/// `finally`, so an error in the handler still releases mpv.
///
/// Example:
/// ```dart
/// player.registerHook(Hook.load);
/// player.stream.hook.listen((event) async {
///   try {
///     if (event.hook == Hook.load) {
///       final url = await player.getRawProperty('stream-open-filename') ?? '';
///       if (url.startsWith('my-scheme://')) {
///         await player.setRawProperty(
///           'stream-open-filename',
///           await resolve(url),
///         );
///       }
///     }
///   } finally {
///     player.continueHook(event.id); // always, even on error
///   }
/// });
/// ```
final class MpvHookEvent {
  /// Opaque identifier required by [Player.continueHook], unique to this
  /// event.
  final int id;

  /// The lifecycle phase mpv is asking you to handle.
  final Hook hook;

  /// Creates a hook event with the given [id] for the [hook] phase.
  const MpvHookEvent(this.id, this.hook);

  @override
  String toString() => 'MpvHookEvent(hook: ${hook.name}, id: $id)';
}
