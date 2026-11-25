// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

import 'package:ffi/ffi.dart';
import 'package:meta/meta.dart';

import '../mpv_bindings.dart';
import 'analysis_commands.dart';
import 'debug_log.dart';
import 'orphan_handle_tracker.dart';

export 'analysis_commands.dart';

/// Stops the players of an isolate that exits without disposing them.
///
/// On Android the process outlives the Flutter engine: Back on the root
/// route or a swipe from the recent apps can destroy the engine, and its
/// root isolate with it, while the process stays. The event isolate of a
/// player is not part of the engine, so it kept mpv playing, with no
/// session, no audio focus and nobody left to stop it.
///
/// The first event isolate an isolate starts also spawns a small watch
/// isolate, which gets a message when the owner exits and raises a native
/// word. Each event isolate of that owner reads the word on every turn of
/// its loop, and once it is raised frees mpv itself ([releaseOrphan]). A
/// word, not a message: the event isolate waits in `mpv_wait_event` and
/// never serves its port.
///
/// An engine the app keeps alive (cached, or run by a service) keeps its
/// root isolate, so its players go on playing.
@internal
abstract final class OwnerWatch {
  /// Whether the players of this isolate are watched: on Android, where
  /// the process outlives the engine. On desktop the process ends with
  /// its engine, and mpv is not torn down under an exiting process.
  @visibleForTesting
  static bool enabled = Platform.isAndroid;

  static Future<int>? _word;

  /// The address of this isolate's word, which the watch raises once the
  /// isolate exits. Never freed: an event isolate reads it until its own
  /// exit, which can come after the owner's.
  static Future<int> wordAddress() => _word ??= _start();

  static Future<int> _start() async {
    final word = calloc<Int32>();
    if (!enabled) return word.address;
    final ready = ReceivePort();
    try {
      await Isolate.spawn(_watch, (
        ready.sendPort,
        word.address,
      ), debugName: 'mpv_audio_kit owner watch');
      final watch = await ready.first as SendPort;
      // Registered from the owner itself, before any player of it runs.
      Isolate.current.addOnExitListener(watch);
    } catch (e) {
      // No watch will answer: an open port would keep the isolate alive.
      ready.close();
      debugLog('mpv_audio_kit: cannot watch the owner isolate: $e');
    }
    return word.address;
  }
}

/// The watch: any message on its port is the owner's exit.
void _watch((SendPort, int) args) {
  final (ready, address) = args;
  final port = RawReceivePort();
  port.handler = (Object? _) {
    Pointer<Int32>.fromAddress(address).value = 1;
    port.close();
  };
  ready.send(port.sendPort);
}

/// Sends [commands] to the core behind [handle], one synchronous
/// `mpv_command_string` each, best effort: a command that fails is logged
/// and the next one still goes. The core teardowns that run without a
/// player (the Hot Restart reap and [releaseOrphan]) share it.
@internal
void sendCoreCommands(
  MpvLibrary lib,
  Pointer<MpvHandle> handle,
  List<String> commands,
) {
  using((arena) {
    for (final command in commands) {
      try {
        lib.mpvCommandString(handle, command.toNativeUtf8(allocator: arena));
      } catch (e) {
        debugLog('mpv_audio_kit: cannot send "$command" to a core: $e');
      }
    }
  });
}

/// Frees the core of a player whose owner isolate exited without dispose,
/// from its event isolate once the loop has left `mpv_wait_event`: nobody
/// else will. The analysis switches go off too: libmpv keeps them per
/// process, and the listeners that armed them are gone.
@internal
void releaseOrphan(MpvLibrary lib, Pointer<MpvHandle> handle) {
  sendCoreCommands(lib, handle, analysisOffCommands);
  // A debug build lists the handle for Hot Restart cleanup: the next VM
  // of the process must not free it again.
  OrphanHandleTracker.instance.forget(handle);
  lib.mpvTerminateDestroy(handle);
}
