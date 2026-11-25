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

/// Configuration for the `afade` audio effect.
///
/// Apply fade-in/out effect to input audio.
///
/// A description of the accepted parameters follows.
///
/// Parameters:
/// - [curve]: Set curve for fade transition.  It accepts the following values: (range -1..22, default TRI, runtime-tunable)
/// - [duration]: Specify the duration of the fade effect. See time duration syntax for the accepted syntax. At the end of the fade-in effect the output audio will have the same volume as the input audio, at the end of the fade-out transition the output audio will be silence. By default the duration is determined by `nb_samples`. If set this option is used instead of `nb_samples`. (range 0..9223372036854775807, default 0, runtime-tunable)
/// - [nbSamples]: Specify the number of samples for which the fade effect has to last. At the end of the fade-in effect the output audio will have the same volume as the input audio, at the end of the fade-out transition the output audio will be silence. Default is 44100. (range 1..9223372036854775807, default 44100, runtime-tunable)
/// - [silence]: Set the initial gain for fade-in or final gain for fade-out. Default value is `0.0`. (range 0..1, default 0, runtime-tunable)
/// - [startSample]: Specify the number of the start sample for starting to apply the fade effect. Default is 0. (range 0..9223372036854775807, default 0, runtime-tunable)
/// - [startTime]: Specify the start time of the fade effect. Default is 0. The value must be specified as a time duration; see time duration syntax for the accepted syntax. If set this option is used instead of `start_sample`. (range 0..9223372036854775807, default 0, runtime-tunable)
/// - [type]: Specify the effect type, can be either `in` for fade-in, or `out` for a fade-out effect. Default is `in`. (range 0..1, default 0, runtime-tunable)
/// - [unity]: Set the initial gain for fade-out or final gain for fade-in. Default value is `1.0`. (range 0..1, default 1, runtime-tunable)
final class AfadeEffect extends AudioEffect {
  /// Default value for [nbSamples].
  static const int nbSamplesDefault = 44100;

  /// Minimum value for [nbSamples].
  static const int nbSamplesMin = 1;

  /// Maximum value for [nbSamples].
  static const int nbSamplesMax = 9007199254740991 * 1024 + 1023;

  /// Default value for [silence].
  static const double silenceDefault = 0.0;

  /// Minimum value for [silence].
  static const double silenceMin = 0.0;

  /// Maximum value for [silence].
  static const double silenceMax = 1.0;

  /// Default value for [startSample].
  static const int startSampleDefault = 0;

  /// Minimum value for [startSample].
  static const int startSampleMin = 0;

  /// Maximum value for [startSample].
  static const int startSampleMax = 9007199254740991 * 1024 + 1023;

  /// Default value for [unity].
  static const double unityDefault = 1.0;

  /// Minimum value for [unity].
  static const double unityMin = 0.0;

  /// Maximum value for [unity].
  static const double unityMax = 1.0;

  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// set fade curve type
  final AfadeCurve curve;

  /// set fade duration
  final Duration duration;

  /// set number of samples for fade duration
  final int nbSamples;

  /// set the silence gain
  final double silence;

  /// set number of first sample to start fading
  final int startSample;

  /// set time to start fading
  final Duration startTime;

  /// set the fade direction
  final AfadeType type;

  /// set the unity gain
  final double unity;

  /// Creates an [AfadeEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const AfadeEffect({
    this.enabled = true,
    this.curve = AfadeCurve.tri,
    this.duration = Duration.zero,
    this.nbSamples = 44100,
    this.silence = 0.0,
    this.startSample = 0,
    this.startTime = Duration.zero,
    this.type = AfadeType.in_,
    this.unity = 1.0,
  });

  @override
  String get filterName => 'afade';

  @override
  AudioFilter get filter => AudioFilter.afade;

  /// Returns a copy of this [AfadeEffect] with the given fields replaced.
  AfadeEffect copyWith({
    bool? enabled,
    AfadeCurve? curve,
    Duration? duration,
    int? nbSamples,
    double? silence,
    int? startSample,
    Duration? startTime,
    AfadeType? type,
    double? unity,
  }) => AfadeEffect(
    enabled: enabled ?? this.enabled,
    curve: curve ?? this.curve,
    duration: duration ?? this.duration,
    nbSamples: nbSamples ?? this.nbSamples,
    silence: silence ?? this.silence,
    startSample: startSample ?? this.startSample,
    startTime: startTime ?? this.startTime,
    type: type ?? this.type,
    unity: unity ?? this.unity,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AfadeEffect &&
          other.enabled == enabled &&
          other.curve == curve &&
          other.duration == duration &&
          other.nbSamples == nbSamples &&
          other.silence == silence &&
          other.startSample == startSample &&
          other.startTime == startTime &&
          other.type == type &&
          other.unity == unity);

  @override
  int get hashCode => Object.hash(
    enabled,
    curve,
    duration,
    nbSamples,
    silence,
    startSample,
    startTime,
    type,
    unity,
  );

  @override
  String toString() =>
      'AfadeEffect(enabled: $enabled, curve: $curve, duration: $duration, nbSamples: $nbSamples, silence: $silence, startSample: $startSample, startTime: $startTime, type: $type, unity: $unity)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    assert(nbSamples >= nbSamplesMin, 'afade.nb_samples must be >= 1');
    assert(
      nbSamples <= nbSamplesMax,
      'afade.nb_samples must be <= 9223372036854775807',
    );
    assert(silence >= silenceMin, 'afade.silence must be >= 0');
    assert(silence <= silenceMax, 'afade.silence must be <= 1');
    assert(startSample >= startSampleMin, 'afade.start_sample must be >= 0');
    assert(
      startSample <= startSampleMax,
      'afade.start_sample must be <= 9223372036854775807',
    );
    assert(unity >= unityMin, 'afade.unity must be >= 0');
    assert(unity <= unityMax, 'afade.unity must be <= 1');
    final parts = <String>[];
    if (curve != AfadeCurve.tri) parts.add('curve=' + curve.mpvValue);
    if (duration != Duration.zero)
      parts.add('duration=' + _wireDuration(duration));
    if (nbSamples != 44100) parts.add('nb_samples=' + nbSamples.toString());
    if (silence != 0.0) parts.add('silence=' + _wireDouble(silence));
    if (startSample != 0) parts.add('start_sample=' + startSample.toString());
    if (startTime != Duration.zero)
      parts.add('start_time=' + _wireDuration(startTime));
    if (type != AfadeType.in_) parts.add('type=' + type.mpvValue);
    if (unity != 1.0) parts.add('unity=' + _wireDouble(unity));
    return parts.isEmpty ? 'lavfi-afade' : 'lavfi-afade=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  @override
  List<(String, String)>? _runtimeDiff(covariant AfadeEffect prev) {
    final out = <(String, String)>[];
    if (curve != prev.curve) {
      out.add(('curve', curve.mpvValue));
    }
    if (duration != prev.duration) {
      out.add(('duration', _wireDuration(duration)));
    }
    if (nbSamples != prev.nbSamples) {
      out.add(('nb_samples', nbSamples.toString()));
    }
    if (silence != prev.silence) {
      out.add(('silence', _wireDouble(silence)));
    }
    if (startSample != prev.startSample) {
      out.add(('start_sample', startSample.toString()));
    }
    if (startTime != prev.startTime) {
      out.add(('start_time', _wireDuration(startTime)));
    }
    if (type != prev.type) {
      out.add(('type', type.mpvValue));
    }
    if (unity != prev.unity) {
      out.add(('unity', _wireDouble(unity)));
    }
    return out;
  }
}
