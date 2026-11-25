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

/// Configuration for the `crystalizer` audio effect.
///
/// Simple algorithm for audio noise sharpening.
///
/// This filter linearly increases differences between each audio sample.
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [c]: Enable clipping. By default is enabled. (range 0..1, default 1, runtime-tunable)
/// - [i]: Sets the intensity of effect (default: 2.0). Must be in range between -10.0 to 0 (unchanged sound) to 10.0 (maximum effect). To inverse filtering use negative value. (range -10..10, default 2.0, runtime-tunable)
final class CrystalizerEffect extends AudioEffect {
  /// Default value for [i].
  static const double iDefault = 2.0;

  /// Minimum value for [i].
  static const double iMin = -10.0;

  /// Maximum value for [i].
  static const double iMax = 10.0;

  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// enable clipping
  final bool c;

  /// set intensity
  final double i;

  /// Creates an [CrystalizerEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const CrystalizerEffect({this.enabled = true, this.c = true, this.i = 2.0});

  @override
  String get filterName => 'crystalizer';

  @override
  AudioFilter get filter => AudioFilter.crystalizer;

  /// Returns a copy of this [CrystalizerEffect] with the given fields replaced.
  CrystalizerEffect copyWith({bool? enabled, bool? c, double? i}) =>
      CrystalizerEffect(
        enabled: enabled ?? this.enabled,
        c: c ?? this.c,
        i: i ?? this.i,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CrystalizerEffect &&
          other.enabled == enabled &&
          other.c == c &&
          other.i == i);

  @override
  int get hashCode => Object.hash(enabled, c, i);

  @override
  String toString() => 'CrystalizerEffect(enabled: $enabled, c: $c, i: $i)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    assert(i >= iMin, 'crystalizer.i must be >= -10');
    assert(i <= iMax, 'crystalizer.i must be <= 10');
    final parts = <String>[];
    if (c != true) parts.add('c=' + (c ? '1' : '0'));
    if (i != 2.0) parts.add('i=' + _wireDouble(i));
    return parts.isEmpty
        ? 'lavfi-crystalizer'
        : 'lavfi-crystalizer=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  @override
  List<(String, String)>? _runtimeDiff(covariant CrystalizerEffect prev) {
    final out = <(String, String)>[];
    if (c != prev.c) {
      out.add(('c', (c ? '1' : '0')));
    }
    if (i != prev.i) {
      out.add(('i', _wireDouble(i)));
    }
    return out;
  }
}
