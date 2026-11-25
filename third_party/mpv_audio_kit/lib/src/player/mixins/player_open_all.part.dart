// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
part of '../player.dart';

/// One [Player.openAll]: its media, their options and sources, and its
/// load ticket, carried through the four phases (clear the outgoing
/// playlist, append every entry, jump to the requested one, drop the old
/// entry kept meanwhile) instead of passed from one step to the next.
final class _OpenAllRun {
  _OpenAllRun(this._player, this._medias, this._options, this._load);

  final _LoadfileModule _player;

  /// The copy of the caller's list, read across many awaits.
  final List<Media> _medias;

  /// The `loadfile` options of each media, validated and built once.
  final List<String> _options;

  final _LoadTicket _load;

  /// Resolved once per media ([_resolve]).
  final List<OwnedSource> _sources = [];

  /// The steps of [Player.openAll] once its load is claimed: the gate,
  /// the intent, the resolve of every media, then the four phases.
  Future<void> run(bool? play, int index) async {
    await _player._gate();
    if (_load.superseded) return;
    final clampedIndex = index.clamp(0, _medias.length - 1);
    final shouldPlay = play ?? _player.configuration.autoPlay;
    // Optimistic intent written at the call point, before the resolve and tls
    // awaits below; see [Player.open] for the rationale.
    final previousIntent = _player._state.playback.playWhenReady;
    final intent = _player._transport.claimIntent(shouldPlay);
    _keepOutgoing();
    // Each source in [_sources] is released on every way out unless mpv
    // took its entry.
    // The old entry kept in mpv until phase 4, hidden from the state once
    // the jump moved past it.
    int? retainedId;
    try {
      try {
        if (!await _resolve()) return;
      } catch (_) {
        // Mid-loop failure: the caller observes the original error, and the
        // sources resolved so far are released on the way out.
        _player._transport.restoreIntent(_load, intent, previousIntent);
        rethrow;
      }
      // Execute in-flight transport writes before the replace: see
      // [CoreCalls.settleWrites].
      await _player._calls.settleWrites();
      if (_load.superseded) return;
      // ── Phase 1: clear the outgoing playlist ──────────────────────────
      final retainedOld = await _clear();
      if (retainedOld == null) return;
      retainedId = await _hold(retainedOld);

      // ── Phase 2: append every entry; playback never starts here ──────
      final failure = await _append();
      // mpv never had the refused entries, nor the ones not sent after a
      // refusal or a later load: their sources are released on the way out.
      if (failure != null) {
        // mpv turns an append down only when its reply queue is full.
        // The call fails as a whole: the entries that went in come out
        // again. `playlist-clear` keeps only the current entry, the track
        // that still plays (none at the park, removed above). The pause was
        // not written yet, so only the intent goes back. A later load owns
        // the playlist instead, and the entries mpv took stay with
        // [_PlayerBase._entries] until they leave.
        if (!_load.superseded) {
          _player._transport.restoreIntent(_load, intent, previousIntent);
          await _player._calls.command(['playlist-clear']);
        }
        Error.throwWithStackTrace(failure.$1, failure.$2);
      }
      // From here on mpv has the entries, and may read them again until it
      // leaves them (a previous, a loop, a prefetch): their sources stay
      // with [_PlayerBase._entries], which releases each one once it left
      // the playlist and mpv moved on. Released now, an Android descriptor
      // would go to the next file the app opens while mpv still lists its
      // number.
      if (_load.superseded) return;

      // ── Phases 3 and 4: the jump, then the retained entry leaves ────
      final played = await _play(
        playNow: _player._transport.intendedPlay(intent, shouldPlay),
        retainedOld: retainedOld,
        index: clampedIndex,
      );
      if (!played) return;
      _forget(retainedId);
      // Clear per-track state AFTER the jump's reply; see [Player.open] for
      // why the placement (post-reply) is what makes the clear the last
      // word over trailing OLD-file PROPERTY_CHANGE events.
      _player._clearPerFileState();
    } finally {
      _forget(retainedId);
      for (final source in _sources) {
        await source.release();
      }
    }
  }

  /// Keeps the [Media] of the outgoing current entry in the cache, so it
  /// keeps its metadata while still visible in playlist events during the
  /// transition of an [Player.openAll] (retained until the post-jump
  /// remove).
  void _keepOutgoing() {
    final old = _player._state.playback.playlist;
    final index = old.index;
    _player._mediaCache.clear();
    if (index < 0 || index >= old.items.length) return;
    final current = old.items[index];
    _player._mediaCache[current.uri] = current;
  }

  /// Resolves [_medias] into [_sources], one source per media: content://
  /// resolutions detach a JVM-side FD, doing it twice would leak one FD
  /// per track. Returns `false` once a later load took over.
  Future<bool> _resolve() async {
    for (final m in _medias) {
      _player._mediaCache[m.uri] = m;
      final source = OwnedSource(await resolveUri(m.uri));
      _sources.add(source);
      if (_load.superseded) return false;
      _player._mediaCache[source.uri] = m;
      await _player._forgetFdResume(source.uri);
    }
    return true;
  }

  /// Phases 3 and 4 of [Player.openAll]: the pause from [playNow], the
  /// jump to entry [index] of the new list, and the removal of the old
  /// entry when [retainedOld] kept it at position 0. Returns `false` when
  /// a later load took over before the removal.
  Future<bool> _play({
    required bool playNow,
    required bool retainedOld,
    required int index,
  }) async {
    // ── Phase 3: intent, then one direct jump to the target ───────────
    // The pause write cannot be fought by keep-open here: the parked
    // flow already left EOF (idle after the remove above), and the
    // playing flow is mid-track. `playlist-play-index` sets
    // playlist->current straight to the target entry (mp_set_playlist_
    // entry): entries before it are never loaded or made current.
    await _player._calls.prop('pause', playNow ? 'no' : 'yes');
    final target = (retainedOld ? 1 : 0) + index;
    // The parked flow went through idle, which does not spend the intent
    // while this call runs: see the idle-active observer.
    await _player._calls.commandChecked([
      'playlist-play-index',
      target.toString(),
    ]);
    // The jump leaves the park, as the replace of [Player.open] does.
    _player._transport.takePark();

    // ── Phase 4: drop the retained old entry ──────────────────────────
    // Non-current by now (the jump moved current to the target), so the
    // removal is pure bookkeeping; indices shift down to their final
    // positions. Tolerant [CoreCalls.command]: a concurrent surgery that
    // already emptied position 0 must not surface as an openAll error.
    if (retainedOld) {
      // The target plays from its source now: see the check after phase 2.
      if (_load.superseded) return false;
      await debugBeforeRetainedRemove?.call();
      await _player._calls.command(['playlist-remove', '0']);
    }
    return true;
  }

  /// Hides from the state the old entry an [Player.openAll] [kept] in
  /// mpv, once its jump moved past it ([EntryTable.retained]). Returns its
  /// id, `null` when none was kept. A later load that took over meanwhile ends the
  /// call before its jump, and the call's `finally` ends the hiding.
  Future<int?> _hold(bool kept) async {
    _player._entries.retained = null;
    if (!kept) return null;
    return _player._entries.retained = int.tryParse(
      await _player._readString('playlist/0/id') ?? '',
    );
  }

  /// Ends the hiding of the old entry [id] of an [Player.openAll]: removed,
  /// or left to a later load. Another openAll's entry stays hidden.
  void _forget(int? id) {
    if (id == null || _player._entries.retained != id) return;
    _player._entries
      ..retained = null
      ..hiddenAt = null;
  }

  /// Phase 1 of [Player.openAll]: clears the outgoing playlist. Returns
  /// whether an old entry still occupies position 0 (the playing flow): the
  /// append targets shift by one until the post-jump remove drops it.
  /// `null` once a later load took over.
  Future<bool?> _clear() async {
    // `playlist-clear` keeps ONLY the current entry (mpv's
    // playlist_clear_except_current), so the outgoing track keeps
    // playing while the new entries build up: no idle gap, no silence.
    // The flow is decided from mpv's own properties AFTER the clear
    // (`playlist-count`, `eof-reached`), not from the Dart-side state
    // snapshot: state can lag the core by an event round-trip, and a
    // wrong guess here would offset every append target below.
    await _player._calls.command(['playlist-clear']);
    if (_load.superseded) return null;
    final retainedCount =
        int.tryParse(await _player._readString('playlist-count') ?? '') ?? 0;
    if (_load.superseded) return null;
    var parkedAtEof = false;
    if (retainedCount > 0) {
      // A retained entry parked at EOF cannot survive the appends:
      // `keep-open` holds the park only while no next entry exists (mpv's
      // handle_keep_open), so the first append would create a "next" and
      // mpv would auto-advance into the new album's entry 0,
      // resurrecting the exact transient this flow eliminates. Remove it
      // NOW instead: the playlist is single-entry after the clear, so
      // PT_NEXT_ENTRY finds nothing and the core goes idle, where
      // appends provably never autostart.
      parkedAtEof = await _player._parkedAtEof();
      if (_load.superseded) return null;
      if (parkedAtEof) {
        await _player._calls.command(['playlist-remove', '0']);
        if (_load.superseded) return null;
        // Barrier: wait for the core to actually reach idle before any
        // append. The remove's playback teardown runs asynchronously on
        // the playloop, and an append landing before it completes gets
        // picked up by the end-of-file advancement (playlist_get_next
        // from a NULL current with the playlist not started returns
        // entry 0), which would start the incoming album's first track:
        // the exact transient this flow eliminates. Idle lands within a
        // playloop iteration; the bound only guards a wedged core.
        if (!await _awaitIdle()) return null;
      }
    }
    return retainedCount > 0 && !parkedAtEof;
  }

  /// The barrier of [_clear]: waits, half a second at most, for the
  /// core to reach idle. Returns `false` once a later load took over. A
  /// wait that ran out is logged: the appends go on, and the first new
  /// entry may start before the jump.
  Future<bool> _awaitIdle() async {
    var idle = false;
    for (var i = 0; i < 100; i++) {
      idle = await _player._readString('idle-active') == 'yes';
      if (_load.superseded) return false;
      if (idle) break;
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
    if (_load.superseded) return false;
    if (!idle) {
      _player._internalLog(
        'openAll: the core did not reach idle after the removal of the '
        'parked entry; the first new entry may start before the jump',
        level: LogLevel.warn,
      );
    }
    return true;
  }

  /// Phase 2 of [Player.openAll]: appends [_medias] from their [_sources],
  /// with their [_options]. Returns the first refusal, `null` when mpv
  /// took every entry sent; sending stops at a refusal or once a later
  /// load took over.
  Future<(Object, StackTrace)?> _append() async {
    // mpv's `loadfile append` is play=false unconditionally (unlike
    // append-play), even on an idle core. Per-Media `httpHeaders` ride
    // along as the 4th `loadfile` arg, so mpv scopes them as file-local
    // without ever writing the global `http-header-fields` option.
    // The appends go out in windows of [_kAppendWindow], each sent at once:
    // mpv runs them in order, and the playlist changes they cause fold into
    // a few notifications. Awaited one by one, every append made mpv report
    // the whole playlist again, which grew with the square of the album
    // size. Each append holds one of the 1000 reply slots mpv keeps per
    // client until its reply is read, and a full queue refuses the next
    // request: a window waits for its replies before the next goes out.
    final appended = <int>{};
    (Object, StackTrace)? failure;
    var sent = 0;
    while (sent < _medias.length && failure == null && !_load.superseded) {
      final end = sent + _kAppendWindow < _medias.length
          ? sent + _kAppendWindow
          : _medias.length;
      // A refused append fails at once, before the loop below awaits it:
      // marked handled here, so its error reaches that loop instead of
      // surfacing as unhandled.
      final window = <Future<int?>>[
        for (var i = sent; i < end; i++)
          _player._loadfileEntry(
            loadfileArgs(_sources[i].uri, 'append', _options[i]),
            _medias[i],
            _sources[i],
          )..ignore(),
      ];
      for (var j = 0; j < window.length; j++) {
        try {
          final id = await window[j];
          if (id != null) appended.add(id);
        } catch (e, st) {
          failure ??= (e, st);
        }
      }
      sent = end;
    }
    if (appended.isNotEmpty) _player._remapReported(appended);
    return failure;
  }
}
