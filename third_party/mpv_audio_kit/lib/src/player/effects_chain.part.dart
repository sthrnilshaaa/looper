// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
part of 'player.dart';

/// The effects chain mpv holds for a player: the list it last accepted,
/// the confirmation of the last write, and `af` as mpv printed it after
/// that write. Applies a list (a live diff of `af-command`s or a whole
/// `af set`), heals a refused diff, and puts the chain back over a resume
/// point that brought another one. [_EffectsModule] holds the public
/// setters; the state the chain writes is the player's.
final class _EffectsChain {
  _EffectsChain(this._player);

  final _PlayerBase _player;

  // ── Chain state ────────────────────────────────────────────────────
  // mpv keeps each filter with its arguments, and rebuilds it from them
  // at a file load, at a seek or loop wrap (lavfi frees its graph on
  // reset), at a track switch and at a format change. The patch
  // af_command_args saves an af-command that took in the arguments of its
  // filter, and in `af`, so those rebuilds keep the values set live, and an
  // `af set` rebuilds only the filters whose arguments it changes.

  /// The last list mpv accepted, through `af set` or a whole diff of
  /// `af-command`s: what it plays when a later write is refused, and so
  /// what the state rolls back to. `null` until the first write, which
  /// always goes through to override an `af` already there, even empty.
  List<AudioEffect>? _accepted;

  /// The confirmation of the last write, which the next one waits for
  /// before it looks at [_accepted]: an empty diff has no reply to wait
  /// on and would otherwise settle ahead of an earlier write.
  Future<void> _settled = Future.value();

  /// mpv's `af` as read right after the last chain write or live diff, in
  /// mpv's own printing, or `null` when unknown: a file started between
  /// the write and the read, or the read failed. The player is the only
  /// other writer of `af`, so a different value at a load comes from a
  /// resume point that still holds a chain.
  String? _held;

  /// Write + commit shared by [Player.setAudioEffects] and
  /// [Player.updateAudioEffects]. The diff computation, the wire enqueue and
  /// the state commit are all SUSPENSION-FREE: [Player.updateAudioEffects]
  /// relies on mapper → enqueue → commit happening in one microtask so that
  /// concurrent un-awaited calls each observe the previous commit, and the
  /// async client API enqueues in call order so the core sees the writes FIFO.
  /// Only the mpv confirmation (the returned future) is deferred.
  ///
  /// Parameter-only changes on command-capable filters go through
  /// `af-command`: the live graph updates in place instead of being
  /// torn down and rebuilt (glitch-free slider drags). Any change to the
  /// list's shape, non-runtime options and command failures fall back to
  /// the full `af` rewrite, which is always correct.
  Future<void> apply(List<AudioEffect> requested) {
    final effects = List<AudioEffect>.unmodifiable(requested);
    // Before the diff, so a refused list reaches neither mpv nor the state.
    validateAudioEffects(effects);
    final previous = _player._state.settings.audioEffects;
    final written = _accepted != null;
    // No-op writes skip the serialization + FFI round-trip entirely.
    if (written && listEquals(effects, previous)) {
      return Future.value();
    }
    final cmds = written ? audioEffectsDiff(previous, effects) : null;
    final Future<void> settled;
    if (cmds != null) {
      // Enqueue the whole diff now (in order); validate the outcomes when
      // the replies land.
      final rcs = <Future<int>>[
        for (final c in cmds)
          _player._calls.command([
            'af-command',
            c.label,
            c.option,
            c.value,
            c.filterName,
          ]),
      ];
      // af_command_args moves `af` with each command that takes.
      if (cmds.isNotEmpty) _readHeld();
      settled = _settleCommands(_settled, rcs, effects, previous);
    } else {
      settled = _rewrite(_settled, effects);
    }
    _settled = settled.then((_) {}, onError: (Object _) {});
    _player._updateField(
      (s) => s.copyWith(audioEffects: effects),
      _player._reactives.audioEffects,
      effects,
    );
    return settled;
  }

  /// Replaces mpv's filter chain with [chain] through the `af set`
  /// command, which rebuilds the running graph and answers an error, with
  /// the old chain kept, when the rebuild fails. A write of the `af`
  /// property instead succeeds once the string parses and drops a failed
  /// rebuild silently. Resolves with mpv's rc.
  Future<int> _setChain(String chain) {
    final reply = _player._calls.command(['af', 'set', chain]);
    _readHeld();
    return reply;
  }

  /// Reads `af` into [_held]. Queued right behind a chain write or a
  /// diff: mpv runs them in order, so the read sees the chain they left,
  /// refused or not, unless a file started in between and its resume point
  /// set `af`.
  void _readHeld() {
    final starts = _player._transport.fileStarts;
    unawaited(
      _player._calls.get('af', MpvFormat.mpvFormatString).then((r) {
        final (rc, af) = r;
        _held =
            rc >= 0 && af is String && starts == _player._transport.fileStarts
            ? af
            : null;
      }),
    );
  }

  /// A resume point written by 0.5.1 or earlier holds an `af` line, which
  /// mpv applies as it loads the file. Once the player wrote a chain, a
  /// chain it did not write gives way to the state's. Before that, a
  /// chain already there stays until the first write, as documented on
  /// [Player.setAudioEffects].
  void reassert() {
    if (_accepted != null) {
      unawaited(_reassertFor(_player._transport.fileStarts));
    }
  }

  Future<void> _reassertFor(int starts) async {
    final (rc, af) = await _player._calls.get('af', MpvFormat.mpvFormatString);
    // A newer load checks for itself.
    if (rc < 0 ||
        _player._disposed ||
        starts != _player._transport.fileStarts ||
        af == _held) {
      return;
    }
    final effects = _player._state.settings.audioEffects;
    final setRc = await _setChain(audioEffectsChain(effects));
    if (setRc < 0) {
      _player._internalLog(
        'Restoring the effects chain over a resume point failed: '
        '${_player._calls.errorString(setRc)}',
        level: LogLevel.debug,
      );
      return;
    }
    _accepted = effects;
  }

  /// Puts the state back on [_accepted] after mpv refused [effects],
  /// unless a later call already replaced them, and throws. A diff that
  /// mpv took meanwhile may have moved the live graph, and saved its
  /// values (af_command_args): the chain is written again from the accepted
  /// list, which rebuilds every stage whose values moved (F50).
  Never _refuse(List<AudioEffect> effects, int rc) {
    if (identical(_player._state.settings.audioEffects, effects)) {
      final accepted = _accepted ?? const <AudioEffect>[];
      _player._updateField(
        (s) => s.copyWith(audioEffects: accepted),
        _player._reactives.audioEffects,
        accepted,
      );
      unawaited(
        _setChain(audioEffectsChain(accepted)).then((rc) {
          if (rc < 0) {
            _player._internalLog(
              'Writing back the effects chain mpv accepted failed: '
              '${_player._calls.errorString(rc)}',
              level: LogLevel.debug,
            );
          }
        }),
      );
    }
    throw MpvCommandException(
      name: 'af',
      code: rc,
      message: _player._calls.errorString(rc),
    );
  }

  /// Awaits the diff's replies. The diff was computed against [previous]:
  /// when that is not what mpv last accepted (an earlier write in flight
  /// was refused), or when a command was refused, the chain is rewritten
  /// from the LATEST committed list, healing a partial apply (and any
  /// later updates already committed). A command mpv refuses while it
  /// rebuilds a graph (until the graph sees a frame) is healed that way
  /// without an error. Only when the rewrite is refused too, a value the
  /// filter itself refuses, the state goes back to the last accepted list
  /// and the call throws, as a refused rewrite does.
  Future<void> _settleCommands(
    Future<void> prior,
    List<Future<int>> rcs,
    List<AudioEffect> effects,
    List<AudioEffect> previous,
  ) async {
    await prior;
    final results = await Future.wait(rcs);
    final refused = results.any((rc) => rc < 0);
    if (!refused && identical(_accepted, previous)) {
      _accepted = effects;
      return;
    }
    if (refused) {
      _player._internalLog(afCommandRefusedLog, level: LogLevel.debug);
    }
    final healed = _player._state.settings.audioEffects;
    final healRc = await _setChain(audioEffectsChain(healed));
    if (healRc >= 0) {
      _accepted = healed;
      return;
    }
    _refuse(effects, healRc);
  }

  /// Awaits the full-rewrite reply. On rejection (e.g. a malformed
  /// [RawAudioEffect]) mpv keeps the old chain, the optimistic commit is
  /// rolled back to the last list mpv accepted (unless a later update
  /// already replaced it), and the [MpvCommandException] propagates to the
  /// caller.
  Future<void> _rewrite(Future<void> prior, List<AudioEffect> effects) async {
    final rewrite = _setChain(audioEffectsChain(effects));
    await prior;
    final rc = await rewrite;
    if (rc >= 0) {
      _accepted = effects;
      return;
    }
    _refuse(effects, rc);
  }
}
