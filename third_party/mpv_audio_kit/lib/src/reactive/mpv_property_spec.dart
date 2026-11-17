// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import '../mpv_bindings.dart';
import '../player/player_state.dart';
import 'reactive_property.dart';

/// Declarative description of a single mpv property exposed by the player.
///
/// One spec bundles the mpv property name + format, the [ReactiveProperty]
/// cell that owns the value, a `(raw, state) → T` parser, and a
/// `(T, state) → PlayerState` reducer. The full update pipeline runs on
/// every observed change: parse → dedup → reactive update → state reduce
/// → onChange. Adding an observed property to the public API is a
/// one-line edit to the spec list.
///
/// The generic [T] is the type of the [reactive] cell. For scalar
/// properties [T] is also the parsed value type. For aggregate properties
/// the parser folds the new value into a larger config (read out of
/// [PlayerState] via the parser's `state` argument) and returns the
/// whole aggregate, so the reactive dedups on the full struct.
class MpvPropertySpec<T> {
  MpvPropertySpec._({
    required this.name,
    required this.format,
    required this.reactive,
    required T Function(dynamic raw, PlayerState state) parse,
    required PlayerState Function(T value, PlayerState state) reduce,
    void Function(T value)? onChange,
  })  : _parse = parse,
        _reduce = reduce,
        _onChange = onChange;

  /// Spec for an mpv property delivered as `MPV_FORMAT_DOUBLE`.
  factory MpvPropertySpec.double({
    required String name,
    required ReactiveProperty<T> reactive,
    required T Function(double raw, PlayerState state) parse,
    required PlayerState Function(T value, PlayerState state) reduce,
    void Function(T value)? onChange,
  }) =>
      MpvPropertySpec._(
        name: name,
        format: MpvFormat.mpvFormatDouble,
        reactive: reactive,
        // Permissive cast: accepts both double and int wire payloads
        // so an isolate-side format demotion (mpv occasionally promotes
        // an int64 property to a double when crossing 2^53) doesn't
        // crash the dispatch pipeline.
        parse: (raw, state) => parse((raw as num).toDouble(), state),
        reduce: reduce,
        onChange: onChange,
      );

  /// Spec for an mpv property delivered as `MPV_FORMAT_FLAG`. The event
  /// isolate forwards flag values as `int` (0/1); the parser accepts
  /// either representation so a format change in the isolate doesn't
  /// silently break flags here.
  factory MpvPropertySpec.flag({
    required String name,
    required ReactiveProperty<T> reactive,
    required T Function(bool raw, PlayerState state) parse,
    required PlayerState Function(T value, PlayerState state) reduce,
    void Function(T value)? onChange,
  }) =>
      MpvPropertySpec._(
        name: name,
        format: MpvFormat.mpvFormatFlag,
        reactive: reactive,
        parse: (raw, state) =>
            parse(raw is int ? raw == 1 : raw as bool, state),
        reduce: reduce,
        onChange: onChange,
      );

  /// Spec for an mpv property delivered as `MPV_FORMAT_INT64`.
  factory MpvPropertySpec.int64({
    required String name,
    required ReactiveProperty<T> reactive,
    required T Function(int raw, PlayerState state) parse,
    required PlayerState Function(T value, PlayerState state) reduce,
    void Function(T value)? onChange,
  }) =>
      MpvPropertySpec._(
        name: name,
        format: MpvFormat.mpvFormatInt64,
        reactive: reactive,
        // Permissive cast: accepts both int and double wire payloads.
        // Without this, a format-mismatch in the isolate (e.g. a
        // float-typed event for an int64-observed property) would
        // crash the dispatch pipeline instead of degrading gracefully.
        parse: (raw, state) => parse((raw as num).toInt(), state),
        reduce: reduce,
        onChange: onChange,
      );

  /// Spec for an mpv property delivered as `MPV_FORMAT_STRING`.
  factory MpvPropertySpec.string({
    required String name,
    required ReactiveProperty<T> reactive,
    required T Function(String raw, PlayerState state) parse,
    required PlayerState Function(T value, PlayerState state) reduce,
    void Function(T value)? onChange,
  }) =>
      MpvPropertySpec._(
        name: name,
        format: MpvFormat.mpvFormatString,
        reactive: reactive,
        parse: (raw, state) => parse(raw as String, state),
        reduce: reduce,
        onChange: onChange,
      );

  /// Spec for an mpv property delivered as `MPV_FORMAT_NODE`. The raw value
  /// passed to [parse] is a Dart-native tree (`Map<String, dynamic>`,
  /// `List<dynamic>`, scalar, or `null`) decoded by the event isolate from
  /// mpv's `mpv_node` recursive struct. Use this for properties mpv exposes
  /// natively as structured data — `playlist`, `metadata`,
  /// `audio-device-list`, `audio-params`, `audio-out-params`,
  /// `demuxer-cache-state`, `track-list` — instead of observing them as
  /// strings and parsing JSON in Dart.
  factory MpvPropertySpec.node({
    required String name,
    required ReactiveProperty<T> reactive,
    required T Function(dynamic raw, PlayerState state) parse,
    required PlayerState Function(T value, PlayerState state) reduce,
    void Function(T value)? onChange,
  }) =>
      MpvPropertySpec._(
        name: name,
        format: MpvFormat.mpvFormatNode,
        reactive: reactive,
        parse: parse,
        reduce: reduce,
        onChange: onChange,
      );

  /// The mpv property name passed to `mpv_observe_property` / `mpv_set_property`.
  final String name;

  /// One of the [MpvFormat] integer constants — selects the wire format used
  /// by mpv when delivering value updates.
  final int format;

  /// The Dart-side value cell. Updated by [parseAndDispatch] on each property
  /// change; exposed publicly through `Player.stream`.
  final ReactiveProperty<T> reactive;

  final T Function(dynamic raw, PlayerState state) _parse;
  final PlayerState Function(T value, PlayerState state) _reduce;
  final void Function(T value)? _onChange;

  /// Folds [next] into the player's [PlayerState]. Returning the same state
  /// (== identity) is a valid no-op for properties that don't have a
  /// corresponding [PlayerState] field (e.g. `prefetch-state`, which is
  /// stream-only).
  PlayerState reduce(T next, PlayerState state) => _reduce(next, state);

  /// Optional side-effect callback fired after [reactive] has been updated
  /// and [reduce] has been applied. Use sparingly — keep cross-property
  /// orchestration out of specs and in the player itself.
  void Function(T next)? get onChange => _onChange;

  /// Parses a raw mpv-side value and applies the full update pipeline:
  /// parse → dedup → reactive update → state reduce → [commit] → onChange.
  /// Returns the new [PlayerState], or `null` if the value was deduplicated
  /// (no change).
  ///
  /// [commit] is invoked with the post-reduce state BEFORE [onChange] fires,
  /// so a callback that itself reads and mutates the player's committed
  /// state — the `idle-active` / `eof-reached` hooks that settle the
  /// transport — builds on the reduced state instead of being overwritten by
  /// the caller assigning this method's return value afterwards. When
  /// [commit] is null, onChange runs against the pre-commit state and the
  /// caller assigns the result itself.
  PlayerState? parseAndDispatch(
    dynamic raw,
    PlayerState state, {
    void Function(PlayerState next)? commit,
  }) {
    final value = _parse(raw, state);
    if (!reactive.update(value)) return null;
    final next = _reduce(value, state);
    commit?.call(next);
    _onChange?.call(value);
    return next;
  }
}
