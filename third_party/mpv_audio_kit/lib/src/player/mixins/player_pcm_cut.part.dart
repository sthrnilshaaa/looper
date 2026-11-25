// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
part of '../player.dart';

/// Test only: awaited by the cut of an aborted source between its read of
/// the playlist and the removal of a queued entry, so a test can put
/// another playlist change in that window. Not exported: the library shows
/// only [Player].
@visibleForTesting
Future<void> Function()? debugBeforePcmCutRemove;

/// The live PCM source of an entry: held by the entry while it is in the
/// playlist, and taken out of playback when the app aborts it.
mixin _PcmCutModule on _PlayerBase {
  /// The live PCM source [media] plays, when it is not done: its entry
  /// holds it while it is in the playlist, and an abort of the source
  /// takes the entry out first ([_cutPcm]).
  LiveSource? _liveSource(Media media) {
    if (!media.isPcmStream) return null;
    final source = pcmSourceFor(media.uri);
    if (source == null || source.isDone) return null;
    source.addCutter(_cutPcm);
    return (key: source, done: source.done, end: source.endUnread);
  }

  /// Takes the entries of [source], which is being aborted, out of
  /// playback. The entry mpv plays is left: the next entry starts, or
  /// playback stops at the last one (wraps to the first with
  /// `loop-playlist` on), without the audio output playing out what it
  /// holds. A queued entry leaves the playlist: loaded later, it would
  /// fail. Asks mpv for the playlist, since the one in the state can lag
  /// it, and again before each removal, since mpv removes by index and an
  /// index read earlier can be stale: until no command that moves the
  /// indices went out between the read and the removal. Not behind the
  /// playlist calls: abort waits for the cut 1 s at most. `null` when this
  /// player holds no entry of [source].
  Future<void>? _cutPcm(PcmSource source) {
    if (_disposed) return null;
    // Taken now: the abort completes `done`, which drops the entries.
    final ids = _entries.liveIds(source);
    if (ids.isEmpty) return null;
    return () async {
      final node = await _readPlaylist();
      if (node == null) return;
      final queued = <Object?>[];
      var playing = false;
      for (final entry in node) {
        if (entry is! Map || !ids.contains(entry['id'])) continue;
        if (entry['playing'] == true) {
          playing = true;
        } else {
          queued.add(entry['id']);
        }
      }
      if (playing) await _calls.command(['playlist-next', 'force']);
      for (final id in queued) {
        // A command that moved the indices after the read (a remove or an
        // insert of the app) makes the read stale: read again. The removal
        // then goes out with nothing between, so mpv takes it in order.
        // Bounded: the abort waits for the cut 1 s at most anyway.
        for (var tries = 0; tries < 8; tries++) {
          final shifts = _calls.playlistShifts;
          final now = await _readPlaylist();
          if (now == null) return;
          await debugBeforePcmCutRemove?.call();
          if (shifts != _calls.playlistShifts) continue;
          final at = now.indexWhere((e) => e is Map && e['id'] == id);
          // Gone already, or taken by a later call. One that became the
          // current entry meanwhile is cut by the removal too.
          if (at >= 0) await _calls.command(['playlist-remove', '$at']);
          break;
        }
      }
    }();
  }
}
