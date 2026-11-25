// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license
// that can be found in the LICENSE file.
//
// AUTO-GENERATED: do not edit by hand.
//
// The descriptions of the filters and of their options in the
// documentation comments are FFmpeg's (doc/filters.texi and the option
// help of libavfilter, https://ffmpeg.org) and keep FFmpeg's licenses: the
// LGPL, version 2.1 or later (FFmpeg's LICENSE.md), and for the option help of
// deesser, arnndn and hdcd the MIT or BSD terms of their source files; the BSD
// 3-Clause license above covers the rest of this file.
// ignore_for_file: unnecessary_ignore, non_constant_identifier_names, constant_identifier_names, camel_case_types, curly_braces_in_flow_control_structures, prefer_adjacent_string_concatenation, prefer_interpolation_to_compose_strings

part of '../audio_effects_settings.dart';

/// Configuration for the `extrastereo` audio effect.
///
/// Linearly increases the difference between left and right channels which
/// adds some sort of "live" effect to playback.
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [c]: Enable clipping. By default is enabled. (range 0..1, default 1, runtime-tunable)
/// - [m]: Sets the difference coefficient (default: 2.5). 0.0 means mono sound (average of both channels), with 1.0 sound will be unchanged, with -1.0 left and right channels will be swapped. (range -10..10, default 2.5, runtime-tunable)
final class ExtrastereoEffect extends AudioEffect {
  /// Default value for [m].
  static const double mDefault = 2.5;

  /// Minimum value for [m].
  static const double mMin = -10.0;

  /// Maximum value for [m].
  static const double mMax = 10.0;

  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// enable clipping
  final bool c;

  /// set the difference coefficient
  final double m;

  /// Creates an [ExtrastereoEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const ExtrastereoEffect({this.enabled = true, this.c = true, this.m = 2.5});

  @override
  String get filterName => 'extrastereo';

  @override
  AudioFilter get filter => AudioFilter.extrastereo;

  /// Returns a copy of this [ExtrastereoEffect] with the given fields replaced.
  ExtrastereoEffect copyWith({bool? enabled, bool? c, double? m}) =>
      ExtrastereoEffect(
        enabled: enabled ?? this.enabled,
        c: c ?? this.c,
        m: m ?? this.m,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExtrastereoEffect &&
          other.enabled == enabled &&
          other.c == c &&
          other.m == m);

  @override
  int get hashCode => Object.hash(enabled, c, m);

  @override
  String toString() => 'ExtrastereoEffect(enabled: $enabled, c: $c, m: $m)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    assert(m >= mMin, 'extrastereo.m must be >= -10');
    assert(m <= mMax, 'extrastereo.m must be <= 10');
    final parts = <String>[];
    if (c != true) parts.add('c=' + (c ? '1' : '0'));
    if (m != 2.5) parts.add('m=' + _wireDouble(m));
    return parts.isEmpty
        ? 'lavfi-extrastereo'
        : 'lavfi-extrastereo=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  @override
  List<(String, String)>? _runtimeDiff(covariant ExtrastereoEffect prev) {
    final out = <(String, String)>[];
    if (c != prev.c) {
      out.add(('c', (c ? '1' : '0')));
    }
    if (m != prev.m) {
      out.add(('m', _wireDouble(m)));
    }
    return out;
  }
}
