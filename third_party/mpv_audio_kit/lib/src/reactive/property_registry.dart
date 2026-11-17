// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../mpv_bindings.dart';
import '../player/player_state.dart';
import 'mpv_property_spec.dart';

/// A flat collection of [MpvPropertySpec]s with a single dispatch entry-point.
///
/// The registry owns the mapping from mpv property name → spec, allocates
/// reply-id integers for `mpv_observe_property`, and exposes lifecycle
/// methods used by [Player]:
///
/// - [register] / [registerAll]: collect specs at construction time.
/// - [observeAll]: call `mpv_observe_property` once per spec on a live mpv
///   handle.
/// - [dispatch]: route an incoming property-change event (parsed earlier on
///   the event-isolate) to the matching spec, returning the post-reduce
///   [PlayerState] or `null` if the property is not in the registry / the
///   value was deduplicated.
/// - [closeAll]: tear down the underlying [ReactiveProperty] broadcast
///   controllers when the player is disposed.
class PropertyRegistry {
  /// Creates an empty registry; populate it with [register] / [registerAll].
  PropertyRegistry();

  /// Upper bound on reply-IDs the registry assigns in [observeAll].
  /// Out-of-registry observers (JSON / aggregate properties wired
  /// directly in `Player._observe`) must use IDs strictly greater than
  /// this so the two dispatch halves stay distinguishable in `mpv -v`
  /// logs. mpv itself treats the integer as opaque user data — the
  /// boundary is purely an internal convention.
  static const int registryReplyIdMax = 10000;

  // Specs are heterogeneous in their value type [T]; the registry only
  // touches the type-erased surface (name, format, dispatch, close), so
  // the common upper bound [Object?] is the right element type.
  final Map<String, MpvPropertySpec<Object?>> _byName = {};

  /// Registers a single spec. Subsequent calls with the same [MpvPropertySpec.name]
  /// overwrite — useful for tests and for player subclasses that want to
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

  /// Calls `mpv_observe_property` for every registered spec.
  ///
  /// Reply IDs are auto-assigned starting at 1, in the same order as
  /// [register] calls. The event isolate doesn't decode reply IDs; mpv
  /// dispatches property changes by name on the receive side, so reply IDs
  /// are effectively only for diagnostics in `mpv -v` logs. The assigned
  /// IDs are guaranteed to stay at or below [registryReplyIdMax] so the
  /// out-of-registry observers (in `Player._observe`) can use a disjoint
  /// range — see [registryReplyIdMax].
  void observeAll(MpvLibrary lib, Pointer<MpvHandle> handle) {
    assert(
        _byName.length <= registryReplyIdMax,
        'PropertyRegistry has ${_byName.length} specs, exceeding the '
        'reply-id boundary of $registryReplyIdMax. Bump the boundary or '
        'split the registry — IDs at or above the boundary are reserved '
        'for out-of-registry observers wired in Player._observe.');
    var replyId = 1;
    for (final spec in _byName.values) {
      using((arena) {
        lib.mpvObserveProperty(
          handle,
          replyId,
          spec.name.toNativeUtf8(allocator: arena),
          spec.format,
        );
      });
      replyId++;
    }
  }

  /// Routes a property-change event to its registered spec.
  ///
  /// Returns the new [PlayerState] when a spec was matched and the value
  /// actually changed, or `null` when:
  /// - no spec is registered for [name] (the caller may handle it via custom
  ///   logic — see complex properties in `Player`); or
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

  /// Closes every registered [ReactiveProperty]'s underlying broadcast
  /// controller. Idempotent — safe to call repeatedly during teardown.
  Future<void> closeAll() async {
    final futures = <Future<void>>[];
    for (final spec in _byName.values) {
      futures.add(spec.reactive.close());
    }
    await Future.wait(futures);
  }
}
