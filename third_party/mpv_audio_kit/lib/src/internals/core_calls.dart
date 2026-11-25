// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'package:meta/meta.dart';

import '../events/player_exception.dart';
import '../models/chapter.dart';
import '../mpv_constants.dart' show MpvError;
import '../types/enums/log_level.dart';
import 'mpv_requests.dart';

/// mpv's input command prefixes, which may precede the command name.
const _kCommandPrefixes = {
  'no-osd',
  'osd-auto',
  'osd-bar',
  'osd-msg',
  'osd-msg-bar',
  'raw',
  'expand-properties',
  'repeatable',
  'nonrepeatable',
  'nonscalable',
  'async',
  'sync',
};

// The commands that move the indices of the playlist entries, besides
// loadfile and loadlist without append (see [CoreCalls.shiftsPlaylist]).
const _kPlaylistShiftCommands = {
  'playlist-remove',
  'playlist-move',
  'playlist-clear',
  'playlist-shuffle',
  'playlist-unshuffle',
  'stop',
};

/// The index of the command name in [args], past the input command
/// prefixes (`no-osd` and the like); `args.length` when there is none.
@internal
int commandStart(List<String> args) {
  var i = 0;
  while (i < args.length && _kCommandPrefixes.contains(args[i])) {
    i++;
  }
  return i;
}

/// The player's calls to libmpv, in one place: the property writes and
/// reads and the commands every typed setter funnels through, the
/// `chapter-list` writer, the hook continue and the log level.
///
/// Every write and read here goes through the ASYNC client API: the
/// request is only enqueued (libmpv deep-copies the arguments) and the
/// future completes when the event isolate forwards the matching reply.
/// The synchronous client API waits for the core's playloop to serve the
/// request, and the playloop can be stuck for seconds inside audio-output
/// init (a Bluetooth or AirPlay device waking up): on the main isolate that
/// wait is the macOS beachball. Never reintroduce a synchronous set, get
/// or command on the main isolate.
@internal
final class CoreCalls {
  /// The calls of a player that reaches libmpv through [mpv].
  CoreCalls(this._mpv);

  final MpvRequests _mpv;

  int _playlistShifts = 0;

  /// How many commands that move playlist indices went out (removes,
  /// moves, inserts, replacing loads, clears, shuffles, stop): mpv removes
  /// by index, so a read of the playlist names the right entry only if
  /// none went out after it (see `_PcmCutModule._cutPcm`).
  int get playlistShifts => _playlistShifts;

  /// Writes a property and throws [MpvCommandException] on rejection.
  ///
  /// The typed setters (setVolume, setRate, …) flow through this method;
  /// the effects chain goes through the `af set` command instead. Errors
  /// are surfaced rather than swallowed so the caller can react
  /// (out-of-range value, unknown name, etc.). [propRc] is the
  /// rc-returning variant for the few call sites that need to tolerate
  /// failures explicitly.
  Future<void> prop(String name, String value) async {
    final rc = await propRc(name, value);
    if (rc < 0) {
      throw MpvCommandException(name: name, code: rc, message: errorString(rc));
    }
  }

  /// Writes a property and resolves with mpv's rc.
  Future<int> propRc(String name, String value) =>
      _mpv.setProperty(name, value);

  /// Runs a command and resolves with mpv's rc.
  Future<int> command(List<String> args) =>
      commandResult(args).then((reply) => reply.$1);

  /// [command] that also returns the command's decoded result node.
  Future<(int, Object?)> commandResult(List<String> args) {
    if (shiftsPlaylist(args)) _playlistShifts++;
    return _mpv.command(args);
  }

  /// Whether [args] can move the indices of the playlist entries: every
  /// command that removes, moves, inserts or reorders them, and a load
  /// that does not append.
  @visibleForTesting
  static bool shiftsPlaylist(List<String> args) {
    final i = commandStart(args);
    if (i >= args.length) return false;
    final command = args[i].replaceAll('_', '-');
    if (command == 'loadfile' || command == 'loadlist') {
      final flags = i + 2 < args.length ? args[i + 2] : 'replace';
      return !flags.startsWith('append');
    }
    return _kPlaylistShiftCommands.contains(command);
  }

  /// [command] that throws [MpvCommandException] on rejection: the command
  /// counterpart of [prop], used by the typed methods whose failure is
  /// a caller-visible error (seek with nothing loaded, loadfile with
  /// malformed options). Call sites where a non-zero rc is an expected
  /// outcome use [navigate] (`playlist-next weak` at the last entry) or
  /// keep the raw rc-returning variant (`playlist-remove current` on an
  /// empty playlist, the internal steps of `openAll`).
  Future<void> commandChecked(List<String> args) async {
    final rc = await command(args);
    if (rc < 0) {
      throw MpvCommandException(
        name: args.isEmpty ? '<empty>' : args.first,
        code: rc,
        message: errorString(rc),
      );
    }
  }

  /// Runs a playlist navigation command and returns whether it moved:
  /// mpv answers [MpvError.mpvErrorCommand] when there is nowhere to go,
  /// which is a normal outcome, not an error.
  Future<bool> navigate(List<String> args) async {
    final rc = await command(args);
    if (rc >= 0) return true;
    if (rc == MpvError.mpvErrorCommand) return false;
    throw MpvCommandException(
      name: args.first,
      code: rc,
      message: errorString(rc),
    );
  }

  /// Reads a property in [format] and resolves with `(error, value)`,
  /// the value decoded by the event isolate.
  Future<(int, Object?)> get(String name, int format) =>
      _mpv.getProperty(name, format);

  /// Applies a settings bundle backed by several mpv properties: [writes]
  /// holds `(property, value, prior value)`. [put] gives the state [next]
  /// first, so mpv's echo of each write matches it instead of emitting a
  /// half-applied bundle. If a write fails, the written properties go back
  /// to their prior values and [put] gives the state [previous] before the
  /// error is rethrown.
  Future<void> writeBundle<T>(
    List<(String, String, String)> writes,
    void Function(T value) put,
    T next,
    T previous,
  ) async {
    put(next);
    final committed = <(String, String)>[];
    try {
      for (final (name, value, prior) in writes) {
        await prop(name, value);
        committed.add((name, prior));
      }
    } catch (_) {
      for (final (name, prior) in committed.reversed) {
        await propRc(name, prior);
      }
      put(previous);
      rethrow;
    }
  }

  /// Writes [chapters] to mpv's `chapter-list`, resolving with the raw mpv
  /// rc. The property is an array of maps `{title: string, time: double
  /// secs}`; an empty list writes an empty array (clears the chapters).
  Future<int> setChapterList(List<Chapter> chapters) =>
      _mpv.setNodeProperty('chapter-list', [
        for (final ch in chapters)
          {'title': ch.title ?? '', 'time': ch.time.inMicroseconds / 1e6},
      ]);

  /// mpv's description of error [code].
  String errorString(int code) => _mpv.errorString(code);

  /// Completes when every write currently on the wire has been executed
  /// (its reply forwarded, or settled by the dispose drain). Snapshot
  /// semantics: writes enqueued after this call are not waited on.
  ///
  /// The synchronous client API implicitly guaranteed "previous request
  /// EXECUTED before the next public call's request is issued"; with the
  /// async API two requests can coalesce into one core dispatch drain and
  /// interact: e.g. an un-awaited `seek` surviving a replace `loadfile`
  /// (its `queue_seek` entry rides into the NEW file) instead of being
  /// aborted by it. Content-replacing and playlist-navigation methods call
  /// this right before their first write so earlier in-flight transport
  /// commands are executed first, restoring the old inter-call semantics
  /// while the main isolate stays free: under a stalled core the FUTURES
  /// queue up, not the UI thread.
  Future<void> settleWrites() => _mpv.settleWrites();

  /// Continues the hook event mpv numbered [id]. The continue of an
  /// `on_prefetch` event ([prefetch]) can wait for a busy core, so it runs
  /// off the calling isolate where the backend can
  /// ([MpvHookContinueOffMain]).
  void hookContinue(int id, {bool prefetch = false}) {
    final mpv = _mpv;
    if (prefetch && mpv is MpvHookContinueOffMain) {
      mpv.hookContinueOffMain(id);
    } else {
      mpv.hookContinue(id);
    }
  }

  /// Sets the engine log verbosity; [LogLevel.off] maps to mpv's `no`.
  void requestLogMessages(LogLevel level) =>
      _mpv.requestLogMessages(level.mpvValue);
}
