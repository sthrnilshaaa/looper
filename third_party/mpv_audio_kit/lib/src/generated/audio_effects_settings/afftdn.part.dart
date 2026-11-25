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

/// Configuration for the `afftdn` audio effect.
///
/// Denoise audio samples with FFT.
///
/// A description of the accepted parameters follows.
///
/// Parameters:
/// - [adaptivity]: Set the adaptivity factor, used how fast to adapt gains adjustments per each frequency bin. Value `0` enables instant adaptation, while higher values react much slower. Allowed range is from `0` to `1`. Default value is `0.5`. (range 0..1, default 0.5, runtime-tunable)
/// - [bandMultiplier]: Set the band multiplier factor, used how much to spread bands across frequency bins. Allowed range is from `0.2` to `5`. Default value is `1.25`. (range 0.2..5, default 1.25)
/// - [bandNoise]: Set custom band noise profile for every one of 15 bands. Bands are separated by ' ' or '|'. (range 0..0, default "")
/// - [floorOffset]: Set the noise floor offset factor. This option is used to adjust offset applied to measured noise floor. It is only effective when noise floor tracking is enabled. Allowed range is from `-2.0` to `2.0`. Default value is `1.0`. (range -2..2, default 1.0, runtime-tunable)
/// - [gainSmooth]: Set gain smooth spatial radius, used to smooth gains applied to each frequency bin. Useful to reduce random music noise artefacts. Higher values increases smoothing of gains. Allowed range is from `0` to `50`. Default value is `0`. (range 0..50, default 0, runtime-tunable)
/// - [noiseFloor]: Set the noise floor in dB, allowed range is -80 to -20. Default value is -50 dB. (range -80..-20, default -50, runtime-tunable)
/// - [noiseLink]: Set the noise link used for multichannel audio.  It accepts the following values: (range 0..3, default MIN_LINK, runtime-tunable)
/// - [noiseReduction]: Set the noise reduction in dB, allowed range is 0.01 to 97. Default value is 12 dB. (range .01..97, default 12, runtime-tunable)
/// - [noiseType]: Set the noise type.  It accepts the following values: (range 0..3, default WHITE_NOISE)
/// - [outputMode]: Set the output mode.  It accepts the following values: (range 0..2, default OUT_MODE, runtime-tunable)
/// - [residualFloor]: Set the residual floor in dB, allowed range is -80 to -20. Default value is -38 dB. (range -80..-20, default -38, runtime-tunable)
/// - [sampleNoise]: Toggle capturing and measurement of noise profile from input audio.  It accepts the following values: (range 0..2, default SAMPLE_NONE, runtime-tunable)
/// - [trackNoise]: Enable noise floor tracking. By default is disabled. With this enabled, noise floor is automatically adjusted. (range 0..1, default 0, runtime-tunable)
/// - [trackResidual]: Enable residual tracking. By default is disabled. (range 0..1, default 0, runtime-tunable)
final class AfftdnEffect extends AudioEffect {
  /// Default value for [adaptivity].
  static const double adaptivityDefault = 0.5;

  /// Minimum value for [adaptivity].
  static const double adaptivityMin = 0.0;

  /// Maximum value for [adaptivity].
  static const double adaptivityMax = 1.0;

  /// Default value for [bandMultiplier].
  static const double bandMultiplierDefault = 1.25;

  /// Minimum value for [bandMultiplier].
  static const double bandMultiplierMin = 0.2;

  /// Maximum value for [bandMultiplier].
  static const double bandMultiplierMax = 5.0;

  /// Default value for [floorOffset].
  static const double floorOffsetDefault = 1.0;

  /// Minimum value for [floorOffset].
  static const double floorOffsetMin = -2.0;

  /// Maximum value for [floorOffset].
  static const double floorOffsetMax = 2.0;

  /// Default value for [gainSmooth].
  static const int gainSmoothDefault = 0;

  /// Minimum value for [gainSmooth].
  static const int gainSmoothMin = 0;

  /// Maximum value for [gainSmooth].
  static const int gainSmoothMax = 50;

  /// Default value for [noiseFloor].
  static const double noiseFloorDefault = -50.0;

  /// Minimum value for [noiseFloor].
  static const double noiseFloorMin = -80.0;

  /// Maximum value for [noiseFloor].
  static const double noiseFloorMax = -20.0;

  /// Default value for [noiseReduction].
  static const double noiseReductionDefault = 12.0;

  /// Minimum value for [noiseReduction].
  static const double noiseReductionMin = .01;

  /// Maximum value for [noiseReduction].
  static const double noiseReductionMax = 97.0;

  /// Default value for [residualFloor].
  static const double residualFloorDefault = -38.0;

  /// Minimum value for [residualFloor].
  static const double residualFloorMin = -80.0;

  /// Maximum value for [residualFloor].
  static const double residualFloorMax = -20.0;

  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// set adaptivity factor
  final double adaptivity;

  /// set band multiplier
  final double bandMultiplier;

  /// set the custom bands noise
  final String bandNoise;

  /// set noise floor offset factor
  final double floorOffset;

  /// set gain smooth radius
  final int gainSmooth;

  /// set the noise floor
  final double noiseFloor;

  /// set the noise floor link
  final AfftdnLink noiseLink;

  /// set the noise reduction
  final double noiseReduction;

  /// set the noise type
  final AfftdnType noiseType;

  /// set output mode
  final AfftdnMode outputMode;

  /// set the residual floor
  final double residualFloor;

  /// set sample noise mode
  final AfftdnSample sampleNoise;

  /// track noise
  final bool trackNoise;

  /// track residual
  final bool trackResidual;

  /// Creates an [AfftdnEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const AfftdnEffect({
    this.enabled = true,
    this.adaptivity = 0.5,
    this.bandMultiplier = 1.25,
    this.bandNoise = '',
    this.floorOffset = 1.0,
    this.gainSmooth = 0,
    this.noiseFloor = -50.0,
    this.noiseLink = AfftdnLink.min,
    this.noiseReduction = 12.0,
    this.noiseType = AfftdnType.white,
    this.outputMode = AfftdnMode.output,
    this.residualFloor = -38.0,
    this.sampleNoise = AfftdnSample.none,
    this.trackNoise = false,
    this.trackResidual = false,
  });

  @override
  String get filterName => 'afftdn';

  @override
  AudioFilter get filter => AudioFilter.afftdn;

  /// Returns a copy of this [AfftdnEffect] with the given fields replaced.
  AfftdnEffect copyWith({
    bool? enabled,
    double? adaptivity,
    double? bandMultiplier,
    String? bandNoise,
    double? floorOffset,
    int? gainSmooth,
    double? noiseFloor,
    AfftdnLink? noiseLink,
    double? noiseReduction,
    AfftdnType? noiseType,
    AfftdnMode? outputMode,
    double? residualFloor,
    AfftdnSample? sampleNoise,
    bool? trackNoise,
    bool? trackResidual,
  }) => AfftdnEffect(
    enabled: enabled ?? this.enabled,
    adaptivity: adaptivity ?? this.adaptivity,
    bandMultiplier: bandMultiplier ?? this.bandMultiplier,
    bandNoise: bandNoise ?? this.bandNoise,
    floorOffset: floorOffset ?? this.floorOffset,
    gainSmooth: gainSmooth ?? this.gainSmooth,
    noiseFloor: noiseFloor ?? this.noiseFloor,
    noiseLink: noiseLink ?? this.noiseLink,
    noiseReduction: noiseReduction ?? this.noiseReduction,
    noiseType: noiseType ?? this.noiseType,
    outputMode: outputMode ?? this.outputMode,
    residualFloor: residualFloor ?? this.residualFloor,
    sampleNoise: sampleNoise ?? this.sampleNoise,
    trackNoise: trackNoise ?? this.trackNoise,
    trackResidual: trackResidual ?? this.trackResidual,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AfftdnEffect &&
          other.enabled == enabled &&
          other.adaptivity == adaptivity &&
          other.bandMultiplier == bandMultiplier &&
          other.bandNoise == bandNoise &&
          other.floorOffset == floorOffset &&
          other.gainSmooth == gainSmooth &&
          other.noiseFloor == noiseFloor &&
          other.noiseLink == noiseLink &&
          other.noiseReduction == noiseReduction &&
          other.noiseType == noiseType &&
          other.outputMode == outputMode &&
          other.residualFloor == residualFloor &&
          other.sampleNoise == sampleNoise &&
          other.trackNoise == trackNoise &&
          other.trackResidual == trackResidual);

  @override
  int get hashCode => Object.hash(
    enabled,
    adaptivity,
    bandMultiplier,
    bandNoise,
    floorOffset,
    gainSmooth,
    noiseFloor,
    noiseLink,
    noiseReduction,
    noiseType,
    outputMode,
    residualFloor,
    sampleNoise,
    trackNoise,
    trackResidual,
  );

  @override
  String toString() =>
      'AfftdnEffect(enabled: $enabled, adaptivity: $adaptivity, bandMultiplier: $bandMultiplier, bandNoise: $bandNoise, floorOffset: $floorOffset, gainSmooth: $gainSmooth, noiseFloor: $noiseFloor, noiseLink: $noiseLink, noiseReduction: $noiseReduction, noiseType: $noiseType, outputMode: $outputMode, residualFloor: $residualFloor, sampleNoise: $sampleNoise, trackNoise: $trackNoise, trackResidual: $trackResidual)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    assert(adaptivity >= adaptivityMin, 'afftdn.adaptivity must be >= 0');
    assert(adaptivity <= adaptivityMax, 'afftdn.adaptivity must be <= 1');
    assert(
      bandMultiplier >= bandMultiplierMin,
      'afftdn.band_multiplier must be >= 0.2',
    );
    assert(
      bandMultiplier <= bandMultiplierMax,
      'afftdn.band_multiplier must be <= 5',
    );
    assert(floorOffset >= floorOffsetMin, 'afftdn.floor_offset must be >= -2');
    assert(floorOffset <= floorOffsetMax, 'afftdn.floor_offset must be <= 2');
    assert(gainSmooth >= gainSmoothMin, 'afftdn.gain_smooth must be >= 0');
    assert(gainSmooth <= gainSmoothMax, 'afftdn.gain_smooth must be <= 50');
    assert(noiseFloor >= noiseFloorMin, 'afftdn.noise_floor must be >= -80');
    assert(noiseFloor <= noiseFloorMax, 'afftdn.noise_floor must be <= -20');
    assert(
      noiseReduction >= noiseReductionMin,
      'afftdn.noise_reduction must be >= .01',
    );
    assert(
      noiseReduction <= noiseReductionMax,
      'afftdn.noise_reduction must be <= 97',
    );
    assert(
      residualFloor >= residualFloorMin,
      'afftdn.residual_floor must be >= -80',
    );
    assert(
      residualFloor <= residualFloorMax,
      'afftdn.residual_floor must be <= -20',
    );
    final parts = <String>[];
    if (adaptivity != 0.5) parts.add('adaptivity=' + _wireDouble(adaptivity));
    if (bandMultiplier != 1.25)
      parts.add('band_multiplier=' + _wireDouble(bandMultiplier));
    if (bandNoise != '') parts.add('band_noise=' + _wireString(bandNoise));
    if (floorOffset != 1.0)
      parts.add('floor_offset=' + _wireDouble(floorOffset));
    if (gainSmooth != 0) parts.add('gain_smooth=' + gainSmooth.toString());
    if (noiseFloor != -50.0)
      parts.add('noise_floor=' + _wireDouble(noiseFloor));
    if (noiseLink != AfftdnLink.min)
      parts.add('noise_link=' + noiseLink.mpvValue);
    if (noiseReduction != 12.0)
      parts.add('noise_reduction=' + _wireDouble(noiseReduction));
    if (noiseType != AfftdnType.white)
      parts.add('noise_type=' + noiseType.mpvValue);
    if (outputMode != AfftdnMode.output)
      parts.add('output_mode=' + outputMode.mpvValue);
    if (residualFloor != -38.0)
      parts.add('residual_floor=' + _wireDouble(residualFloor));
    if (sampleNoise != AfftdnSample.none)
      parts.add('sample_noise=' + sampleNoise.mpvValue);
    if (trackNoise != false)
      parts.add('track_noise=' + (trackNoise ? '1' : '0'));
    if (trackResidual != false)
      parts.add('track_residual=' + (trackResidual ? '1' : '0'));
    return parts.isEmpty ? 'lavfi-afftdn' : 'lavfi-afftdn=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  @override
  List<(String, String)>? _runtimeDiff(covariant AfftdnEffect prev) {
    final out = <(String, String)>[];
    if (adaptivity != prev.adaptivity) {
      out.add(('adaptivity', _wireDouble(adaptivity)));
    }
    if (bandMultiplier != prev.bandMultiplier) return null;
    if (bandNoise != prev.bandNoise) return null;
    if (floorOffset != prev.floorOffset) {
      out.add(('floor_offset', _wireDouble(floorOffset)));
    }
    if (gainSmooth != prev.gainSmooth) {
      out.add(('gain_smooth', gainSmooth.toString()));
    }
    if (noiseFloor != prev.noiseFloor) {
      out.add(('noise_floor', _wireDouble(noiseFloor)));
    }
    if (noiseLink != prev.noiseLink) {
      out.add(('noise_link', noiseLink.mpvValue));
    }
    if (noiseReduction != prev.noiseReduction) {
      out.add(('noise_reduction', _wireDouble(noiseReduction)));
    }
    if (noiseType != prev.noiseType) return null;
    if (outputMode != prev.outputMode) {
      out.add(('output_mode', outputMode.mpvValue));
    }
    if (residualFloor != prev.residualFloor) {
      out.add(('residual_floor', _wireDouble(residualFloor)));
    }
    if (sampleNoise != prev.sampleNoise) {
      out.add(('sample_noise', sampleNoise.mpvValue));
    }
    if (trackNoise != prev.trackNoise) {
      out.add(('track_noise', (trackNoise ? '1' : '0')));
    }
    if (trackResidual != prev.trackResidual) {
      out.add(('track_residual', (trackResidual ? '1' : '0')));
    }
    return out;
  }
}
