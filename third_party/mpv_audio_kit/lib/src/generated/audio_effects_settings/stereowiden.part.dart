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

/// Configuration for the `stereowiden` audio effect.
///
/// This filter enhance the stereo effect by suppressing signal common to both
/// channels and by delaying the signal of left into right and vice versa,
/// thereby widening the stereo effect.
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [crossfeed]: Cross feed of left into right with inverted phase. This helps in suppressing the mono. If the value is 1 it will cancel all the signal common to both channels. Default is 0.3. (range 0..0.8, default .3, runtime-tunable)
/// - [delay]: Time in milliseconds of the delay of left signal into right and vice versa. Default is 20 milliseconds. (range 1..100, default 20)
/// - [drymix]: Set level of input signal of original channel. Default is 0.8. (range 0..1.0, default .8, runtime-tunable)
/// - [feedback]: Amount of gain in delayed signal into right and vice versa. Gives a delay effect of left signal in right output and vice versa which gives widening effect. Default is 0.3. (range 0..0.9, default .3, runtime-tunable)
final class StereowidenEffect extends AudioEffect {
  /// Default value for [crossfeed].
  static const double crossfeedDefault = .3;

  /// Minimum value for [crossfeed].
  static const double crossfeedMin = 0.0;

  /// Maximum value for [crossfeed].
  static const double crossfeedMax = 0.8;

  /// Default value for [delay].
  static const double delayDefault = 20.0;

  /// Minimum value for [delay].
  static const double delayMin = 1.0;

  /// Maximum value for [delay].
  static const double delayMax = 100.0;

  /// Default value for [drymix].
  static const double drymixDefault = .8;

  /// Minimum value for [drymix].
  static const double drymixMin = 0.0;

  /// Maximum value for [drymix].
  static const double drymixMax = 1.0;

  /// Default value for [feedback].
  static const double feedbackDefault = .3;

  /// Minimum value for [feedback].
  static const double feedbackMin = 0.0;

  /// Maximum value for [feedback].
  static const double feedbackMax = 0.9;

  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// set cross feed
  final double crossfeed;

  /// set delay time
  final double delay;

  /// set dry-mix
  final double drymix;

  /// set feedback gain
  final double feedback;

  /// Creates an [StereowidenEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const StereowidenEffect({
    this.enabled = true,
    this.crossfeed = .3,
    this.delay = 20.0,
    this.drymix = .8,
    this.feedback = .3,
  });

  @override
  String get filterName => 'stereowiden';

  @override
  AudioFilter get filter => AudioFilter.stereowiden;

  /// Returns a copy of this [StereowidenEffect] with the given fields replaced.
  StereowidenEffect copyWith({
    bool? enabled,
    double? crossfeed,
    double? delay,
    double? drymix,
    double? feedback,
  }) => StereowidenEffect(
    enabled: enabled ?? this.enabled,
    crossfeed: crossfeed ?? this.crossfeed,
    delay: delay ?? this.delay,
    drymix: drymix ?? this.drymix,
    feedback: feedback ?? this.feedback,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StereowidenEffect &&
          other.enabled == enabled &&
          other.crossfeed == crossfeed &&
          other.delay == delay &&
          other.drymix == drymix &&
          other.feedback == feedback);

  @override
  int get hashCode => Object.hash(enabled, crossfeed, delay, drymix, feedback);

  @override
  String toString() =>
      'StereowidenEffect(enabled: $enabled, crossfeed: $crossfeed, delay: $delay, drymix: $drymix, feedback: $feedback)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    assert(crossfeed >= crossfeedMin, 'stereowiden.crossfeed must be >= 0');
    assert(crossfeed <= crossfeedMax, 'stereowiden.crossfeed must be <= 0.8');
    assert(delay >= delayMin, 'stereowiden.delay must be >= 1');
    assert(delay <= delayMax, 'stereowiden.delay must be <= 100');
    assert(drymix >= drymixMin, 'stereowiden.drymix must be >= 0');
    assert(drymix <= drymixMax, 'stereowiden.drymix must be <= 1.0');
    assert(feedback >= feedbackMin, 'stereowiden.feedback must be >= 0');
    assert(feedback <= feedbackMax, 'stereowiden.feedback must be <= 0.9');
    final parts = <String>[];
    if (crossfeed != .3) parts.add('crossfeed=' + _wireDouble(crossfeed));
    if (delay != 20.0) parts.add('delay=' + _wireDouble(delay));
    if (drymix != .8) parts.add('drymix=' + _wireDouble(drymix));
    if (feedback != .3) parts.add('feedback=' + _wireDouble(feedback));
    return parts.isEmpty
        ? 'lavfi-stereowiden'
        : 'lavfi-stereowiden=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  @override
  List<(String, String)>? _runtimeDiff(covariant StereowidenEffect prev) {
    final out = <(String, String)>[];
    if (crossfeed != prev.crossfeed) {
      out.add(('crossfeed', _wireDouble(crossfeed)));
    }
    if (delay != prev.delay) return null;
    if (drymix != prev.drymix) {
      out.add(('drymix', _wireDouble(drymix)));
    }
    if (feedback != prev.feedback) {
      out.add(('feedback', _wireDouble(feedback)));
    }
    return out;
  }
}
