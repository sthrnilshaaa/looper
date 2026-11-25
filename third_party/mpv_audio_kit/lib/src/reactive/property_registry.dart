// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import '../player/player_state.dart';
import 'mpv_property_spec.dart';

/// A flat collection of [MpvPropertySpec]s with a single dispatch entry-point.
///
/// The registry owns the mapping from mpv property name → spec (the event
/// isolate registers the observers from [specs]), and exposes lifecycle
/// methods used by [Player]:
///
/// - [register] and [registerAll]: collect specs at construction time.
/// - [dispatch]: route an incoming property-change event (parsed earlier on
///   the event-isolate) to the matching spec, returning the post-reduce
///   [PlayerState] or `null` if the property is not in the registry or the
///   value was deduplicated.
/// - [closeAll]: tear down the underlying [ReactiveProperty] broadcast
///   controllers when the player is disposed.
class PropertyRegistry {
  /// Creates an empty registry; populate it with [register] or [registerAll].
  PropertyRegistry();

  /// Upper bound on the reply-IDs of the registry's observers.
  /// Out-of-registry observers (node and aggregate properties wired
  /// directly in the player's observe list) use IDs strictly greater than
  /// this so the two dispatch halves stay distinguishable in `mpv -v`
  /// logs. mpv itself treats the integer as opaque user data; the
  /// boundary is purely an internal convention.
  static const int registryReplyIdMax = 10000;

  // Specs are heterogeneous in their value type [T]; the registry only
  // touches the type-erased surface (name, format, dispatch, close), so
  // the common upper bound [Object?] is the right element type.
  final Map<String, MpvPropertySpec<Object?>> _byName = {};

  /// Registers a single spec. A later call with the same
  /// [MpvPropertySpec.name] overwrites the earlier one, which tests use to
  /// shadow a default spec.
  void register(MpvPropertySpec<Object?> spec) {
    _byName[spec.name] = spec;
  }

  /// Registers a batch of specs.
  void registerAll(Iterable<MpvPropertySpec<Object?>> specs) {
    for (final spec in specs) {
      _byName[spec.name] = spec;
    }
  }

  /// All registered specs.
  Iterable<MpvPropertySpec<Object?>> get specs => _byName.values;

  /// Looks up a spec by mpv property name. Returns `null` for unknown names.
  MpvPropertySpec<Object?>? specFor(String name) => _byName[name];

  /// Routes a property-change event to its registered spec.
  ///
  /// Returns the new [PlayerState] when a spec was matched and the value
  /// actually changed, or `null` when:
  /// - no spec is registered for [name] (the caller may handle it via custom
  ///   logic; see complex properties in `Player`); or
  /// - the spec deduplicated the value (the [ReactiveProperty]'s previous
  ///   value was equal).
  PlayerState? dispatch(
    String name,
    dynamic raw,
    PlayerState state, {
    void Function(PlayerState next)? commit,
  }) {
    final spec = _byName[name];
    if (spec == null) return null;
    return spec.parseAndDispatch(raw, state, commit: commit);
  }

  /// Routes a property that became unavailable to its registered spec,
  /// which returns to its seed. Same return contract as [dispatch].
  PlayerState? dispatchUnavailable(
    String name,
    PlayerState state, {
    void Function(PlayerState next)? commit,
  }) {
    final spec = _byName[name];
    if (spec == null) return null;
    return spec.resetAndDispatch(state, commit: commit);
  }

  /// Applies several changes of properties whose specs share one cell, in
  /// order, and updates the cell once with the result, so it emits a single
  /// time. Each change is a property name and its raw value, or `null` raw
  /// when mpv reported it unavailable. Changes of unknown properties are
  /// skipped. Same return contract as [dispatch].
  PlayerState? dispatchGroup(
    List<(String, Object?)> changes,
    PlayerState state, {
    void Function(PlayerState next)? commit,
  }) {
    MpvPropertySpec<Object?>? last;
    Object? value;
    var next = state;
    for (final (name, raw) in changes) {
      final spec = _byName[name];
      if (spec == null) continue;
      assert(
        last == null || identical(spec.reactive, last.reactive),
        'grouped specs must share one cell: ${last.name} and $name',
      );
      value = raw == null ? spec.unavailableValue(next) : spec.parse(raw, next);
      next = spec.reduce(value, next);
      last = spec;
    }
    if (last == null || !last.reactive.update(value)) return null;
    commit?.call(next);
    last.onChange?.call(value);
    return next;
  }

  /// Closes every registered [ReactiveProperty]'s underlying broadcast
  /// controller. Idempotent: safe to call repeatedly during teardown.
  Future<void> closeAll() async {
    final futures = <Future<void>>[];
    for (final spec in _byName.values) {
      futures.add(spec.reactive.close());
    }
    await Future.wait(futures);
  }
}
