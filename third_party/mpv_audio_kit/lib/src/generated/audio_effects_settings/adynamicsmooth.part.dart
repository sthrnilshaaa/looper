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

/// Configuration for the `adynamicsmooth` audio effect.
///
/// Apply dynamic smoothing to input audio stream.
///
/// A description of the accepted options follows.
///
/// Parameters:
/// - [basefreq]: Set a base frequency for smoothing. Default value is 22050. Allowed range is from 2 to 1e+06. (range 2..1000000, default 22050, runtime-tunable)
/// - [sensitivity]: Set an amount of sensitivity to frequency fluctations. Default is 2. Allowed range is from 0 to 1e+06. (range 0..1000000, default 2, runtime-tunable)
final class AdynamicsmoothEffect extends AudioEffect {
  /// Default value for [basefreq].
  static const double basefreqDefault = 22050.0;

  /// Minimum value for [basefreq].
  static const double basefreqMin = 2.0;

  /// Maximum value for [basefreq].
  static const double basefreqMax = 1000000.0;

  /// Default value for [sensitivity].
  static const double sensitivityDefault = 2.0;

  /// Minimum value for [sensitivity].
  static const double sensitivityMin = 0.0;

  /// Maximum value for [sensitivity].
  static const double sensitivityMax = 1000000.0;

  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// set base frequency
  final double basefreq;

  /// set smooth sensitivity
  final double sensitivity;

  /// Creates an [AdynamicsmoothEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const AdynamicsmoothEffect({
    this.enabled = true,
    this.basefreq = 22050.0,
    this.sensitivity = 2.0,
  });

  @override
  String get filterName => 'adynamicsmooth';

  @override
  AudioFilter get filter => AudioFilter.adynamicsmooth;

  /// Returns a copy of this [AdynamicsmoothEffect] with the given fields replaced.
  AdynamicsmoothEffect copyWith({
    bool? enabled,
    double? basefreq,
    double? sensitivity,
  }) => AdynamicsmoothEffect(
    enabled: enabled ?? this.enabled,
    basefreq: basefreq ?? this.basefreq,
    sensitivity: sensitivity ?? this.sensitivity,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AdynamicsmoothEffect &&
          other.enabled == enabled &&
          other.basefreq == basefreq &&
          other.sensitivity == sensitivity);

  @override
  int get hashCode => Object.hash(enabled, basefreq, sensitivity);

  @override
  String toString() =>
      'AdynamicsmoothEffect(enabled: $enabled, basefreq: $basefreq, sensitivity: $sensitivity)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    assert(basefreq >= basefreqMin, 'adynamicsmooth.basefreq must be >= 2');
    assert(
      basefreq <= basefreqMax,
      'adynamicsmooth.basefreq must be <= 1000000',
    );
    assert(
      sensitivity >= sensitivityMin,
      'adynamicsmooth.sensitivity must be >= 0',
    );
    assert(
      sensitivity <= sensitivityMax,
      'adynamicsmooth.sensitivity must be <= 1000000',
    );
    final parts = <String>[];
    if (basefreq != 22050.0) parts.add('basefreq=' + _wireDouble(basefreq));
    if (sensitivity != 2.0)
      parts.add('sensitivity=' + _wireDouble(sensitivity));
    return parts.isEmpty
        ? 'lavfi-adynamicsmooth'
        : 'lavfi-adynamicsmooth=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  @override
  List<(String, String)>? _runtimeDiff(covariant AdynamicsmoothEffect prev) {
    final out = <(String, String)>[];
    if (basefreq != prev.basefreq) {
      out.add(('basefreq', _wireDouble(basefreq)));
    }
    if (sensitivity != prev.sensitivity) {
      out.add(('sensitivity', _wireDouble(sensitivity)));
    }
    return out;
  }
}
