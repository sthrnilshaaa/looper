// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'package:meta/meta.dart';

/// The requests the player sends to libmpv once it runs: property writes
/// and reads, commands, hook continues and the log level. Bring-up, event
/// dispatch and teardown use the concrete client instead.
///
/// No member takes or returns an FFI type, so a backend that is not built
/// on `dart:ffi` can implement it, and so can a fake in the tests.
@internal
abstract interface class MpvRequests {
  /// Writes property [name] as a string. Resolves with mpv's rc.
  Future<int> setProperty(String name, String value);

  /// Writes property [name] as the node [value] describes: `null`, a
  /// [bool], an [int], a [double], a [String], a [List] of such values or
  /// a [Map] from [String] keys to them. Resolves with mpv's rc.
  Future<int> setNodeProperty(String name, Object? value);

  /// Runs command [args]. Resolves with mpv's rc and the command's decoded
  /// result node (`loadfile` returns its `playlist_entry_id` there).
  Future<(int, Object?)> command(List<String> args);

  /// Reads property [name] in [format], one of mpv's format numbers.
  /// Resolves with mpv's rc and the decoded value.
  Future<(int, Object?)> getProperty(String name, int format);

  /// Completes when every write and command in flight now has executed.
  /// Reads and later requests are not waited on.
  Future<void> settleWrites();

  /// mpv's description of error [code].
  String errorString(int code);

  /// Continues the hook event mpv numbered [id], on the calling thread.
  void hookContinue(int id);

  /// Sets which log messages mpv sends, by mpv's level name (`no` for
  /// none).
  void requestLogMessages(String level);
}

/// The [MpvRequests] of a backend whose hook continue can wait for a busy
/// core: native, where `mpv_hook_continue` locks it. For `on_load` and the
/// other hooks mpv waits for the continue in its hook loop, so the lock
/// comes at once. `on_prefetch` keeps the playloop running, and its
/// continue waits for whatever the core is doing, such as an audio output
/// that takes seconds to open.
@internal
abstract interface class MpvHookContinueOffMain implements MpvRequests {
  /// Continues the hook event mpv numbered [id] where the wait stalls
  /// nothing. The core is not destroyed before it returned.
  void hookContinueOffMain(int id);
}
