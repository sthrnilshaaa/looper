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

/// Configuration for the `anlmdn` audio effect.
///
/// Reduce broadband noise in audio samples using Non-Local Means algorithm.
///
/// Each sample is adjusted by looking for other samples with similar contexts. This
/// context similarity is defined by comparing their surrounding patches of size
/// @option{p}. Patches are searched in an area of @option{r} around the sample.
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [output]: Set the output mode.  It accepts the following values: (range 0..2, default OUT_MODE, runtime-tunable)
/// - [patch]: Set patch radius duration. Allowed range is from 1 to 100 milliseconds. Default value is 2 milliseconds. (range 1000..100000, default 2000, runtime-tunable)
/// - [research]: Set research radius duration. Allowed range is from 2 to 300 milliseconds. Default value is 6 milliseconds. (range 2000..300000, default 6000, runtime-tunable)
/// - [smooth]: Set smooth factor. Default value is `11`. Allowed range is from `1` to `1000`. (range 1..1000, default 11., runtime-tunable)
/// - [strength]: Set denoising strength. Allowed range is from 0.00001 to 10000. Default value is 0.00001. (range 0.00001..10000, default 0.00001, runtime-tunable)
final class AnlmdnEffect extends AudioEffect {
  /// Default value for [smooth].
  static const double smoothDefault = 11.0;

  /// Minimum value for [smooth].
  static const double smoothMin = 1.0;

  /// Maximum value for [smooth].
  static const double smoothMax = 1000.0;

  /// Default value for [strength].
  static const double strengthDefault = 0.00001;

  /// Minimum value for [strength].
  static const double strengthMin = 0.00001;

  /// Maximum value for [strength].
  static const double strengthMax = 10000.0;

  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// set output mode
  final AnlmdnMode output;

  /// set patch duration
  final Duration patch;

  /// set research duration
  final Duration research;

  /// set smooth factor
  final double smooth;

  /// set denoising strength
  final double strength;

  /// Creates an [AnlmdnEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const AnlmdnEffect({
    this.enabled = true,
    this.output = AnlmdnMode.o,
    this.patch = const Duration(microseconds: 2000),
    this.research = const Duration(microseconds: 6000),
    this.smooth = 11.0,
    this.strength = 0.00001,
  });

  @override
  String get filterName => 'anlmdn';

  @override
  AudioFilter get filter => AudioFilter.anlmdn;

  /// Returns a copy of this [AnlmdnEffect] with the given fields replaced.
  AnlmdnEffect copyWith({
    bool? enabled,
    AnlmdnMode? output,
    Duration? patch,
    Duration? research,
    double? smooth,
    double? strength,
  }) => AnlmdnEffect(
    enabled: enabled ?? this.enabled,
    output: output ?? this.output,
    patch: patch ?? this.patch,
    research: research ?? this.research,
    smooth: smooth ?? this.smooth,
    strength: strength ?? this.strength,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AnlmdnEffect &&
          other.enabled == enabled &&
          other.output == output &&
          other.patch == patch &&
          other.research == research &&
          other.smooth == smooth &&
          other.strength == strength);

  @override
  int get hashCode =>
      Object.hash(enabled, output, patch, research, smooth, strength);

  @override
  String toString() =>
      'AnlmdnEffect(enabled: $enabled, output: $output, patch: $patch, research: $research, smooth: $smooth, strength: $strength)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    assert(smooth >= smoothMin, 'anlmdn.smooth must be >= 1');
    assert(smooth <= smoothMax, 'anlmdn.smooth must be <= 1000');
    assert(strength >= strengthMin, 'anlmdn.strength must be >= 0.00001');
    assert(strength <= strengthMax, 'anlmdn.strength must be <= 10000');
    final parts = <String>[];
    if (output != AnlmdnMode.o) parts.add('output=' + output.mpvValue);
    if (patch != const Duration(microseconds: 2000))
      parts.add('patch=' + _wireDuration(patch));
    if (research != const Duration(microseconds: 6000))
      parts.add('research=' + _wireDuration(research));
    if (smooth != 11.0) parts.add('smooth=' + _wireDouble(smooth));
    if (strength != 0.00001) parts.add('strength=' + _wireDouble(strength));
    return parts.isEmpty ? 'lavfi-anlmdn' : 'lavfi-anlmdn=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  @override
  List<(String, String)>? _runtimeDiff(covariant AnlmdnEffect prev) {
    final out = <(String, String)>[];
    if (output != prev.output) {
      out.add(('output', output.mpvValue));
    }
    if (patch != prev.patch) {
      out.add(('patch', _wireDuration(patch)));
    }
    if (research != prev.research) {
      out.add(('research', _wireDuration(research)));
    }
    if (smooth != prev.smooth) {
      out.add(('smooth', _wireDouble(smooth)));
    }
    if (strength != prev.strength) {
      out.add(('strength', _wireDouble(strength)));
    }
    return out;
  }
}
