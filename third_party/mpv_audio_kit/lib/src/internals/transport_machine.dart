// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

// The transport axis of a player as a pure state machine: the load epoch,
// the loads in flight, the play-pause intent across the calls that set it,
// the file starts and the park generation. Each input returns the effects
// the player then carries out, so the rules run without a core, and a
// stateful test drives them against a model (transport_machine_test).

import 'package:meta/meta.dart';

/// What [TransportMachine] asks of the player. Every effect is a const
/// instance, so two equal effects are the same object.
@internal
sealed class TransportEffect {
  const TransportEffect();
}

/// Write the play-pause intent ([value]) into the state.
@internal
final class WriteIntent extends TransportEffect {
  const WriteIntent._(this.value);

  /// The intent.
  final bool value;

  /// Writes [value].
  static const on = WriteIntent._(true);

  /// Writes the intent off.
  static const off = WriteIntent._(false);
}

/// mpv went idle: the state is neither playing nor buffering.
@internal
final class SettleIdle extends TransportEffect {
  const SettleIdle._();

  /// The effect.
  static const effect = SettleIdle._();
}

/// No file is loaded any more: nothing of the last one should linger.
@internal
final class ClearFinishedFile extends TransportEffect {
  const ClearFinishedFile._();

  /// The effect.
  static const effect = ClearFinishedFile._();
}

/// Read `idle-active` from the core and hand the answer to
/// [TransportMachine.idleRead].
@internal
final class ReadIdle extends TransportEffect {
  const ReadIdle._();

  /// The effect.
  static const effect = ReadIdle._();
}

/// The transport axis: see the inputs for the rules.
///
/// Each content-replacing call claims the load epoch, and every load path
/// checks its epoch after each await. Each public call that sets the
/// intent claims an intent epoch, so a call that corrects the intent after
/// an await (a failed load, the pause write of a load) leaves it alone once
/// a later call claimed it. The loads in flight hold back the intent reset
/// of an idle core while they give it content.
///
/// The park generation moves at every START_FILE and PLAYBACK_RESTART, the
/// only ways out of a keep-open park, and each generation spends the
/// intent at most once: the first end-of-content read at the end
/// ([endOfContent]) spends it, unless a call that leaves the park took the
/// generation first ([takePark]). A call takes it after the reply of its
/// moving command (a seek, `playlist-play-index`, a load), which mpv queues
/// ahead of the move's own event, so the take is the generation that
/// command leaves. A spend that comes while a load runs is deferred to the
/// end of the loads, and goes only if the core is still in that generation
/// then.
@internal
final class TransportMachine {
  int _fileStarts = 0;
  int _loadEpoch = 0;
  int _loadsInFlight = 0;
  bool _idleResetPending = false;
  int _intentEpoch = 0;
  int _lastOffEpoch = 0;
  int _park = 0;
  int _spentPark = -1;
  int? _deferredPark;

  /// The MPV_EVENT_START_FILE events seen so far. A reply that arrives
  /// after a newer one may describe the file that load opened.
  int get fileStarts => _fileStarts;

  /// Whether mpv started a file once: the startup idle-active burst comes
  /// before it, and must not clear the intent of an open still settling.
  bool get hasLoadedFile => _fileStarts > 0;

  /// How many content-replacing loads are running. While one is, an idle
  /// core is about to get content.
  int get loadsInFlight => _loadsInFlight;

  /// The load epoch, which each content-replacing call moves.
  int get loadEpoch => _loadEpoch;

  /// The park generation the core is in. The tests check the generation
  /// through it; the player reads the intents it spends instead.
  @visibleForTesting
  int get park => _park;

  /// mpv started a file (MPV_EVENT_START_FILE).
  void startFile() {
    _fileStarts++;
    _park++;
  }

  /// mpv restarted playback (MPV_EVENT_PLAYBACK_RESTART): a seek landed,
  /// and the park, if any, was left.
  void restart() => _park++;

  /// An end-of-content read found the queue at its end: the first one of
  /// the generation spends the intent, unless a call leaving the park took
  /// it. While a load runs, the spend waits for the loads to end.
  List<TransportEffect> endOfContent() {
    if (_spentPark == _park) return const [];
    if (_loadsInFlight > 0) {
      _deferredPark = _park;
      return const [];
    }
    _spentPark = _park;
    return [WriteIntent.off];
  }

  /// A call leaving the park takes its generation: no read of it spends
  /// the intent from now on.
  void takePark() => _spentPark = _park;

  /// mpv entered its idle loop ([idle]) or left it. Past the first file,
  /// an idle core has spent the intent, unless a load is giving it
  /// content: then the reset waits for the loads to end.
  List<TransportEffect> idleActive(bool idle) {
    if (!idle) {
      _idleResetPending = false;
      return const [];
    }
    if (!hasLoadedFile) return [SettleIdle.effect];
    if (_loadsInFlight > 0) {
      _idleResetPending = true;
      return [SettleIdle.effect, ClearFinishedFile.effect];
    }
    return [SettleIdle.effect, WriteIntent.off, ClearFinishedFile.effect];
  }

  /// Claims the load epoch for a content-replacing call.
  int claimLoad() => ++_loadEpoch;

  /// A content-replacing load starts.
  void beginLoad() => _loadsInFlight++;

  /// A content-replacing load ended. With the last one, the spend deferred
  /// to it goes if the core is still in that park ([completed] still
  /// true, the same generation), and an idle reset left to it asks the
  /// core whether it is still idle. Neither ever writes the intent on.
  List<TransportEffect> endLoad({required bool completed}) {
    _loadsInFlight--;
    if (_loadsInFlight > 0) return const [];
    final effects = <TransportEffect>[];
    final park = _deferredPark;
    _deferredPark = null;
    if (park != null && park == _park && _spentPark != park && completed) {
      _spentPark = park;
      effects.add(WriteIntent.off);
    }
    if (_idleResetPending) effects.add(ReadIdle.effect);
    return effects;
  }

  /// The answer of a [ReadIdle]: [idle] when the core said it is idle. A
  /// load that started meanwhile, or a core that left idle, keeps the
  /// intent.
  List<TransportEffect> idleRead({required bool idle}) {
    if (!_idleResetPending || _loadsInFlight > 0) return const [];
    _idleResetPending = false;
    return idle ? [WriteIntent.off] : const [];
  }

  /// Sets the intent for a public call, and returns the effect and the
  /// epoch that call owns.
  (WriteIntent, int) claimIntent(bool value) {
    final epoch = ++_intentEpoch;
    if (!value) _lastOffEpoch = epoch;
    return (_write(value), epoch);
  }

  /// Whether the call that claimed [intent] still owns the intent.
  bool owns(int intent) => intent == _intentEpoch;

  /// Whether a play() that claimed [intent] still has the intent on its
  /// side: the last call that claimed the intent played, whichever call
  /// it was ([intent] only has to be a claim made). A play() called before
  /// the reply of an earlier one's seek, a pause() between them or not,
  /// leaves that reply its take of the park.
  bool wantsPlay(int intent) =>
      intent <= _intentEpoch && _lastOffEpoch < _intentEpoch;

  /// Whether a load that claimed [intent] for [shouldPlay] starts playing:
  /// a later play() or pause(), whose intent is [current], has the last
  /// word.
  bool intendedPlay(int intent, bool shouldPlay, {required bool current}) =>
      intent == _intentEpoch ? shouldPlay : current;

  /// Puts back the intent a failed load replaced, unless a later call took
  /// over the load ([load] is not the epoch any more) or the intent.
  WriteIntent? restoreIntent(int load, int intent, bool previous) {
    if (load != _loadEpoch || intent != _intentEpoch) return null;
    if (!previous) _lastOffEpoch = _intentEpoch;
    return _write(previous);
  }

  static WriteIntent _write(bool value) =>
      value ? WriteIntent.on : WriteIntent.off;
}
