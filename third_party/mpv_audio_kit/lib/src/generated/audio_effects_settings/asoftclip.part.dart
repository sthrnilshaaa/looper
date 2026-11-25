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

/// Configuration for the `asoftclip` audio effect.
///
/// Apply audio soft clipping.
///
/// Soft clipping is a type of distortion effect where the amplitude of a signal is saturated
/// along a smooth curve, rather than the abrupt shape of hard-clipping.
///
/// This filter accepts the following options:
///
/// Parameters:
/// - [output]: Set gain applied to output. Default value is 0dB or 1. (range 0.000001..16, default 1, runtime-tunable)
/// - [oversample]: Set oversampling factor. (range 1..64, default 1, runtime-tunable)
/// - [param]: Set additional parameter which controls sigmoid function. (range 0.01..3, default 1, runtime-tunable)
/// - [threshold]: Set threshold from where to start clipping. Default value is 0dB or 1. (range 0.000001..1, default 1, runtime-tunable)
/// - [type]: Set type of soft-clipping.  It accepts the following values: (range -1..7, default 0, runtime-tunable)
final class AsoftclipEffect extends AudioEffect {
  /// Default value for [output].
  static const double outputDefault = 1.0;

  /// Minimum value for [output].
  static const double outputMin = 0.000001;

  /// Maximum value for [output].
  static const double outputMax = 16.0;

  /// Default value for [oversample].
  static const int oversampleDefault = 1;

  /// Minimum value for [oversample].
  static const int oversampleMin = 1;

  /// Maximum value for [oversample].
  static const int oversampleMax = 64;

  /// Default value for [param].
  static const double paramDefault = 1.0;

  /// Minimum value for [param].
  static const double paramMin = 0.01;

  /// Maximum value for [param].
  static const double paramMax = 3.0;

  /// Default value for [threshold].
  static const double thresholdDefault = 1.0;

  /// Minimum value for [threshold].
  static const double thresholdMin = 0.000001;

  /// Maximum value for [threshold].
  static const double thresholdMax = 1.0;

  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// set softclip output gain
  final double output;

  /// set oversample factor
  final int oversample;

  /// set softclip parameter
  final double param;

  /// set softclip threshold
  final double threshold;

  /// set softclip type
  final AsoftclipTypes type;

  /// Creates an [AsoftclipEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const AsoftclipEffect({
    this.enabled = true,
    this.output = 1.0,
    this.oversample = 1,
    this.param = 1.0,
    this.threshold = 1.0,
    this.type = AsoftclipTypes.hard,
  });

  @override
  String get filterName => 'asoftclip';

  @override
  AudioFilter get filter => AudioFilter.asoftclip;

  /// Returns a copy of this [AsoftclipEffect] with the given fields replaced.
  AsoftclipEffect copyWith({
    bool? enabled,
    double? output,
    int? oversample,
    double? param,
    double? threshold,
    AsoftclipTypes? type,
  }) => AsoftclipEffect(
    enabled: enabled ?? this.enabled,
    output: output ?? this.output,
    oversample: oversample ?? this.oversample,
    param: param ?? this.param,
    threshold: threshold ?? this.threshold,
    type: type ?? this.type,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AsoftclipEffect &&
          other.enabled == enabled &&
          other.output == output &&
          other.oversample == oversample &&
          other.param == param &&
          other.threshold == threshold &&
          other.type == type);

  @override
  int get hashCode =>
      Object.hash(enabled, output, oversample, param, threshold, type);

  @override
  String toString() =>
      'AsoftclipEffect(enabled: $enabled, output: $output, oversample: $oversample, param: $param, threshold: $threshold, type: $type)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    assert(output >= outputMin, 'asoftclip.output must be >= 0.000001');
    assert(output <= outputMax, 'asoftclip.output must be <= 16');
    assert(oversample >= oversampleMin, 'asoftclip.oversample must be >= 1');
    assert(oversample <= oversampleMax, 'asoftclip.oversample must be <= 64');
    assert(param >= paramMin, 'asoftclip.param must be >= 0.01');
    assert(param <= paramMax, 'asoftclip.param must be <= 3');
    assert(
      threshold >= thresholdMin,
      'asoftclip.threshold must be >= 0.000001',
    );
    assert(threshold <= thresholdMax, 'asoftclip.threshold must be <= 1');
    final parts = <String>[];
    if (output != 1.0) parts.add('output=' + _wireDouble(output));
    if (oversample != 1) parts.add('oversample=' + oversample.toString());
    if (param != 1.0) parts.add('param=' + _wireDouble(param));
    if (threshold != 1.0) parts.add('threshold=' + _wireDouble(threshold));
    if (type != AsoftclipTypes.hard) parts.add('type=' + type.mpvValue);
    return parts.isEmpty
        ? 'lavfi-asoftclip'
        : 'lavfi-asoftclip=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  @override
  List<(String, String)>? _runtimeDiff(covariant AsoftclipEffect prev) {
    final out = <(String, String)>[];
    if (output != prev.output) {
      out.add(('output', _wireDouble(output)));
    }
    if (oversample != prev.oversample) {
      out.add(('oversample', oversample.toString()));
    }
    if (param != prev.param) {
      out.add(('param', _wireDouble(param)));
    }
    if (threshold != prev.threshold) {
      out.add(('threshold', _wireDouble(threshold)));
    }
    if (type != prev.type) {
      out.add(('type', type.mpvValue));
    }
    return out;
  }
}
