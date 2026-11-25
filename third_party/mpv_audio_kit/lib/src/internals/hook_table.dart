// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';

/// The hooks of one player: the names registered with mpv, the ones the
/// app registered, the deadline of each, and the events still waiting for
/// their continue.
///
/// mpv gives every event of a hook the id of its registration, so the
/// table hands out ids of its own, one per event: a continue that comes
/// after the deadline released its event must not release the next event
/// of the same hook (the `on_load` of the next entry).
@internal
class HookTable {
  /// [onTimeout] gets an event whose deadline ran out while it was still
  /// pending: the table's id for it, its hook name, the timeout, and mpv's
  /// id to continue.
  HookTable({required this.onTimeout});

  final void Function(int id, String name, Duration timeout, int mpvId)
  onTimeout;

  /// The names registered with mpv. mpv allows several registrations per
  /// name, but its shutdown path can stall when several events of the same
  /// hook are still pending at quit, so each name is registered once.
  final registered = <String>{};

  /// The names the app registered with `Player.registerHook`, a subset of
  /// [registered] (the source resolver registers `on_load` and
  /// `on_load_fail` without adding them here). Only their events reach the
  /// app, which then owes the continue; the library continues the others.
  final user = <String>{};

  /// The deadline of each hook name, after which an event continues on its
  /// own.
  final timeouts = <String, Duration>{};

  // The pending events, the table's id to mpv's and the hook name:
  // authoritative for `Player.continueHook`, whose call for an event no
  // longer here never reaches mpv.
  final _pending = <int, (int, String)>{};
  final _timers = <int, Timer>{};
  int _lastId = 0;

  /// mpv fired event [mpvId] of the hook [name]: returns the id it gets,
  /// with the deadline of [name] armed.
  int add(int mpvId, String name) {
    final id = ++_lastId;
    _pending[id] = (mpvId, name);
    final timeout = timeouts[name];
    if (timeout != null) {
      _timers[id] = Timer(timeout, () {
        _timers.remove(id);
        // A continue that came first took the event out: nothing to do.
        final pending = _pending.remove(id);
        if (pending != null) onTimeout(id, name, timeout, pending.$1);
      });
    }
    return id;
  }

  /// Whether the event [id] still waits for its continue.
  bool isPending(int id) => _pending.containsKey(id);

  /// Takes the event [id] out, with its deadline: mpv's id and the hook
  /// name, or `null` when it was continued already.
  (int, String)? take(int id) {
    final event = _pending.remove(id);
    if (event != null) _timers.remove(id)?.cancel();
    return event;
  }

  /// Takes every pending event out and cancels the deadlines: mpv's ids
  /// and the hook names.
  List<(int, String)> takeAll() {
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
    final ids = _pending.values.toList(growable: false);
    _pending.clear();
    return ids;
  }
}
