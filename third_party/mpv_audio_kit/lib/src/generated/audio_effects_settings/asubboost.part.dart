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

/// Configuration for the `asubboost` audio effect.
///
/// Boost subwoofer frequencies.
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [boost]: Set max boost factor. Allowed range is from 1 to 12. Default value is 2. (range 1..12, default 2.0, runtime-tunable)
/// - [channels]: Set the channels to process. Default value is all available. (range 0..0, default "all", runtime-tunable)
/// - [cutoff]: Set cutoff frequency in Hertz. Allowed range is 50 to 900. Default value is 100. (range 50..900, default 100, runtime-tunable)
/// - [decay]: Set delay line decay gain value. Allowed range is from 0 to 1. Default value is 0.0. (range 0..1, default 0.0, runtime-tunable)
/// - [delay]: Set delay. Allowed range is from 1 to 100. Default value is 20. (range 1..100, default 20, runtime-tunable)
/// - [dry]: Set dry gain, how much of original signal is kept. Allowed range is from 0 to 1. Default value is 1.0. (range 0..1, default 1.0, runtime-tunable)
/// - [feedback]: Set delay line feedback gain value. Allowed range is from 0 to 1. Default value is 0.9. (range 0..1, default 0.9, runtime-tunable)
/// - [slope]: Set slope amount for cutoff frequency. Allowed range is 0.0001 to 1. Default value is 0.5. (range 0.0001..1, default 0.5, runtime-tunable)
/// - [wet]: Set wet gain, how much of filtered signal is kept. Allowed range is from 0 to 1. Default value is 1.0. (range 0..1, default 1.0, runtime-tunable)
final class AsubboostEffect extends AudioEffect {
  /// Default value for [boost].
  static const double boostDefault = 2.0;

  /// Minimum value for [boost].
  static const double boostMin = 1.0;

  /// Maximum value for [boost].
  static const double boostMax = 12.0;

  /// Default value for [cutoff].
  static const double cutoffDefault = 100.0;

  /// Minimum value for [cutoff].
  static const double cutoffMin = 50.0;

  /// Maximum value for [cutoff].
  static const double cutoffMax = 900.0;

  /// Default value for [decay].
  static const double decayDefault = 0.0;

  /// Minimum value for [decay].
  static const double decayMin = 0.0;

  /// Maximum value for [decay].
  static const double decayMax = 1.0;

  /// Default value for [delay].
  static const double delayDefault = 20.0;

  /// Minimum value for [delay].
  static const double delayMin = 1.0;

  /// Maximum value for [delay].
  static const double delayMax = 100.0;

  /// Default value for [dry].
  static const double dryDefault = 1.0;

  /// Minimum value for [dry].
  static const double dryMin = 0.0;

  /// Maximum value for [dry].
  static const double dryMax = 1.0;

  /// Default value for [feedback].
  static const double feedbackDefault = 0.9;

  /// Minimum value for [feedback].
  static const double feedbackMin = 0.0;

  /// Maximum value for [feedback].
  static const double feedbackMax = 1.0;

  /// Default value for [slope].
  static const double slopeDefault = 0.5;

  /// Minimum value for [slope].
  static const double slopeMin = 0.0001;

  /// Maximum value for [slope].
  static const double slopeMax = 1.0;

  /// Default value for [wet].
  static const double wetDefault = 1.0;

  /// Minimum value for [wet].
  static const double wetMin = 0.0;

  /// Maximum value for [wet].
  static const double wetMax = 1.0;

  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// set max boost
  final double boost;

  /// set channels to filter
  final String channels;

  /// set cutoff
  final double cutoff;

  /// set decay
  final double decay;

  /// set delay
  final double delay;

  /// set dry gain
  final double dry;

  /// set feedback
  final double feedback;

  /// set slope
  final double slope;

  /// set wet gain
  final double wet;

  /// Creates an [AsubboostEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const AsubboostEffect({
    this.enabled = true,
    this.boost = 2.0,
    this.channels = 'all',
    this.cutoff = 100.0,
    this.decay = 0.0,
    this.delay = 20.0,
    this.dry = 1.0,
    this.feedback = 0.9,
    this.slope = 0.5,
    this.wet = 1.0,
  });

  @override
  String get filterName => 'asubboost';

  @override
  AudioFilter get filter => AudioFilter.asubboost;

  /// Returns a copy of this [AsubboostEffect] with the given fields replaced.
  AsubboostEffect copyWith({
    bool? enabled,
    double? boost,
    String? channels,
    double? cutoff,
    double? decay,
    double? delay,
    double? dry,
    double? feedback,
    double? slope,
    double? wet,
  }) => AsubboostEffect(
    enabled: enabled ?? this.enabled,
    boost: boost ?? this.boost,
    channels: channels ?? this.channels,
    cutoff: cutoff ?? this.cutoff,
    decay: decay ?? this.decay,
    delay: delay ?? this.delay,
    dry: dry ?? this.dry,
    feedback: feedback ?? this.feedback,
    slope: slope ?? this.slope,
    wet: wet ?? this.wet,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AsubboostEffect &&
          other.enabled == enabled &&
          other.boost == boost &&
          other.channels == channels &&
          other.cutoff == cutoff &&
          other.decay == decay &&
          other.delay == delay &&
          other.dry == dry &&
          other.feedback == feedback &&
          other.slope == slope &&
          other.wet == wet);

  @override
  int get hashCode => Object.hash(
    enabled,
    boost,
    channels,
    cutoff,
    decay,
    delay,
    dry,
    feedback,
    slope,
    wet,
  );

  @override
  String toString() =>
      'AsubboostEffect(enabled: $enabled, boost: $boost, channels: $channels, cutoff: $cutoff, decay: $decay, delay: $delay, dry: $dry, feedback: $feedback, slope: $slope, wet: $wet)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    assert(boost >= boostMin, 'asubboost.boost must be >= 1');
    assert(boost <= boostMax, 'asubboost.boost must be <= 12');
    assert(cutoff >= cutoffMin, 'asubboost.cutoff must be >= 50');
    assert(cutoff <= cutoffMax, 'asubboost.cutoff must be <= 900');
    assert(decay >= decayMin, 'asubboost.decay must be >= 0');
    assert(decay <= decayMax, 'asubboost.decay must be <= 1');
    assert(delay >= delayMin, 'asubboost.delay must be >= 1');
    assert(delay <= delayMax, 'asubboost.delay must be <= 100');
    assert(dry >= dryMin, 'asubboost.dry must be >= 0');
    assert(dry <= dryMax, 'asubboost.dry must be <= 1');
    assert(feedback >= feedbackMin, 'asubboost.feedback must be >= 0');
    assert(feedback <= feedbackMax, 'asubboost.feedback must be <= 1');
    assert(slope >= slopeMin, 'asubboost.slope must be >= 0.0001');
    assert(slope <= slopeMax, 'asubboost.slope must be <= 1');
    assert(wet >= wetMin, 'asubboost.wet must be >= 0');
    assert(wet <= wetMax, 'asubboost.wet must be <= 1');
    final parts = <String>[];
    if (boost != 2.0) parts.add('boost=' + _wireDouble(boost));
    if (channels != 'all') parts.add('channels=' + _wireString(channels));
    if (cutoff != 100.0) parts.add('cutoff=' + _wireDouble(cutoff));
    if (decay != 0.0) parts.add('decay=' + _wireDouble(decay));
    if (delay != 20.0) parts.add('delay=' + _wireDouble(delay));
    if (dry != 1.0) parts.add('dry=' + _wireDouble(dry));
    if (feedback != 0.9) parts.add('feedback=' + _wireDouble(feedback));
    if (slope != 0.5) parts.add('slope=' + _wireDouble(slope));
    if (wet != 1.0) parts.add('wet=' + _wireDouble(wet));
    return parts.isEmpty
        ? 'lavfi-asubboost'
        : 'lavfi-asubboost=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  @override
  List<(String, String)>? _runtimeDiff(covariant AsubboostEffect prev) {
    final out = <(String, String)>[];
    if (boost != prev.boost) {
      out.add(('boost', _wireDouble(boost)));
    }
    if (channels != prev.channels) {
      out.add(('channels', channels));
    }
    if (cutoff != prev.cutoff) {
      out.add(('cutoff', _wireDouble(cutoff)));
    }
    if (decay != prev.decay) {
      out.add(('decay', _wireDouble(decay)));
    }
    if (delay != prev.delay) {
      out.add(('delay', _wireDouble(delay)));
    }
    if (dry != prev.dry) {
      out.add(('dry', _wireDouble(dry)));
    }
    if (feedback != prev.feedback) {
      out.add(('feedback', _wireDouble(feedback)));
    }
    if (slope != prev.slope) {
      out.add(('slope', _wireDouble(slope)));
    }
    if (wet != prev.wet) {
      out.add(('wet', _wireDouble(wet)));
    }
    return out;
  }
}
