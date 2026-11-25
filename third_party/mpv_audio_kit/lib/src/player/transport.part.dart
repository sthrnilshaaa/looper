// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
part of 'player.dart';

/// The transport axis of a player: the rules of [TransportMachine], whose
/// effects this carries out on the player (the intent written into the
/// state, the lifecycle of an idle core, the read of `idle-active`).
final class _Transport {
  _Transport(this._player);

  final _PlayerBase _player;
  final TransportMachine _machine = TransportMachine();

  /// See [TransportMachine.hasLoadedFile].
  bool get hasLoadedFile => _machine.hasLoadedFile;

  /// See [TransportMachine.fileStarts].
  int get fileStarts => _machine.fileStarts;

  /// How many open(), openAll() and openPlaylistFile() calls are running.
  /// While one is, an idle core is about to get content, so [Player.play]
  /// and the idle-active observer keep the intent.
  int get loadsInFlight => _machine.loadsInFlight;

  /// mpv started a file (MPV_EVENT_START_FILE).
  void onStartFile() => _machine.startFile();

  /// mpv restarted playback (MPV_EVENT_PLAYBACK_RESTART).
  void onRestart() => _machine.restart();

  /// An end-of-content read found the queue at its end
  /// ([TransportMachine.endOfContent]).
  void onEndOfContent() => _apply(_machine.endOfContent());

  /// A call leaving the park takes its generation.
  void takePark() => _machine.takePark();

  /// mpv entered its idle loop ([idle]) or left it
  /// ([TransportMachine.idleActive]).
  void onIdle(bool idle) => _apply(_machine.idleActive(idle));

  /// Claims the load epoch for a content-replacing call: every earlier
  /// load in flight is superseded from now on.
  _LoadTicket claimLoad() => _LoadTicket(_player, _machine.claimLoad());

  /// Snapshots the load epoch for a call that adds to the content (an
  /// append): superseded if a content-replacing call lands meanwhile.
  _LoadTicket snapshotLoad() => _LoadTicket(_player, _machine.loadEpoch);

  /// Runs a content-replacing load, counted in [loadsInFlight].
  Future<void> trackLoad(Future<void> Function() load) async {
    _machine.beginLoad();
    try {
      await load();
    } finally {
      final completed = !_player._disposed && _player._state.playback.completed;
      if (_apply(_machine.endLoad(completed: completed))) await _readIdle();
    }
  }

  /// Sets the play-pause intent for a public call and returns the epoch
  /// that call owns.
  int claimIntent(bool value) {
    final (write, epoch) = _machine.claimIntent(value);
    writeIntent(write.value);
    return epoch;
  }

  /// Whether the call that claimed [intent] still owns the intent: no
  /// later call set it.
  bool owns(int intent) => _machine.owns(intent);

  /// Whether a play() that claimed [intent] still has the intent on its
  /// side ([TransportMachine.wantsPlay]).
  bool wantsPlay(int intent) => _machine.wantsPlay(intent);

  /// Whether a load that claimed [intent] for [shouldPlay] starts playing:
  /// a play() or pause() called after it, while it resolved, has the last
  /// word, so its pause write must not undo theirs.
  bool intendedPlay(int intent, bool shouldPlay) => _machine.intendedPlay(
    intent,
    shouldPlay,
    current: _player._state.playback.playWhenReady,
  );

  /// Writes the play-pause intent ([PlaybackState.playWhenReady]).
  void writeIntent(bool value) => _player._updateField(
    (s) => s.copyWith(playWhenReady: value),
    _player._reactives.playWhenReady,
    value,
  );

  /// Puts back the intent a failed load replaced, unless a later call took
  /// over the load or the intent. Returns whether it did.
  bool restoreIntent(_LoadTicket load, int intent, bool previous) {
    if (_player._disposed) return false;
    final write = _machine.restoreIntent(load._epoch, intent, previous);
    if (write == null) return false;
    writeIntent(write.value);
    return true;
  }

  /// Carries out [effects] in their order, at once, so a throw reaches
  /// the caller as before. Returns whether they ask for a read of the core
  /// ([ReadIdle], always the last), which the caller then awaits with
  /// [_readIdle].
  bool _apply(List<TransportEffect> effects) {
    var read = false;
    for (final effect in effects) {
      switch (effect) {
        case WriteIntent(:final value):
          writeIntent(value);
        case SettleIdle():
          _player._updateLifecycle(playing: false, buffering: false);
        case ClearFinishedFile():
          _player._clearFinishedFile();
        case ReadIdle():
          read = true;
      }
    }
    return read;
  }

  /// Reads `idle-active` and hands the answer back to the machine, unless
  /// the player was disposed.
  Future<void> _readIdle() async {
    if (_player._disposed) return;
    final (rc, idle) = await _player._calls.get(
      'idle-active',
      MpvFormat.mpvFormatString,
    );
    if (_player._disposed) return;
    _apply(_machine.idleRead(idle: rc >= 0 && idle == 'yes'));
  }
}

/// A load-path call's view of the load epoch, taken with
/// [_Transport.claimLoad] or [_Transport.snapshotLoad].
final class _LoadTicket {
  _LoadTicket(this._player, this._epoch);

  final _PlayerBase _player;
  final int _epoch;

  /// Whether the player was disposed, or a later content-replacing call
  /// took over, since the ticket was taken. Re-check after every await.
  bool get superseded =>
      _player._disposed || _player._transport._machine.loadEpoch != _epoch;
}
