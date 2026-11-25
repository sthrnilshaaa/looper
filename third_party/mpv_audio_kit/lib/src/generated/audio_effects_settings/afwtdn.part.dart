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

/// Configuration for the `afwtdn` audio effect.
///
/// Reduce broadband noise from input samples using Wavelets.
///
/// A description of the accepted options follows.
///
/// Parameters:
/// - [adaptive]: adaptive profiling of noise (range 0..1, default 0, runtime-tunable)
/// - [levels]: Set the number of wavelet levels of decomposition. Allowed range is from 1 to 12. Default value is 10. Setting this too low make denoising performance very poor. (range 1..12, default 10)
/// - [percent]: set percent of full denoising (range 0..100, default 85, runtime-tunable)
/// - [profile]: profile noise (range 0..1, default 0, runtime-tunable)
/// - [samples]: set frame size in number of samples (range 512..65536, default 8192)
/// - [sigma]: Set the noise sigma, allowed range is from 0 to 1. Default value is 0. This option controls strength of denoising applied to input samples. Most useful way to set this option is via decibels, eg. -45dB. (range 0..1, default 0, runtime-tunable)
/// - [softness]: set thresholding softness (range 0..10, default 1, runtime-tunable)
/// - [wavet]: Set wavelet type for decomposition of input frame. They are sorted by number of coefficients, from lowest to highest. More coefficients means worse filtering speed, but overall better quality. Available wavelets are: (range 0..6, default SYM10)
final class AfwtdnEffect extends AudioEffect {
  /// Default value for [levels].
  static const int levelsDefault = 10;

  /// Minimum value for [levels].
  static const int levelsMin = 1;

  /// Maximum value for [levels].
  static const int levelsMax = 12;

  /// Default value for [percent].
  static const double percentDefault = 85.0;

  /// Minimum value for [percent].
  static const double percentMin = 0.0;

  /// Maximum value for [percent].
  static const double percentMax = 100.0;

  /// Default value for [samples].
  static const int samplesDefault = 8192;

  /// Minimum value for [samples].
  static const int samplesMin = 512;

  /// Maximum value for [samples].
  static const int samplesMax = 65536;

  /// Default value for [sigma].
  static const double sigmaDefault = 0.0;

  /// Minimum value for [sigma].
  static const double sigmaMin = 0.0;

  /// Maximum value for [sigma].
  static const double sigmaMax = 1.0;

  /// Default value for [softness].
  static const double softnessDefault = 1.0;

  /// Minimum value for [softness].
  static const double softnessMin = 0.0;

  /// Maximum value for [softness].
  static const double softnessMax = 10.0;

  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// adaptive profiling of noise
  final bool adaptive;

  /// set number of wavelet levels
  final int levels;

  /// set percent of full denoising
  final double percent;

  /// profile noise
  final bool profile;

  /// set frame size in number of samples
  final int samples;

  /// set noise sigma
  final double sigma;

  /// set thresholding softness
  final double softness;

  /// set wavelet type
  final AfwtdnWavet wavet;

  /// Creates an [AfwtdnEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const AfwtdnEffect({
    this.enabled = true,
    this.adaptive = false,
    this.levels = 10,
    this.percent = 85.0,
    this.profile = false,
    this.samples = 8192,
    this.sigma = 0.0,
    this.softness = 1.0,
    this.wavet = AfwtdnWavet.sym10,
  });

  @override
  String get filterName => 'afwtdn';

  @override
  AudioFilter get filter => AudioFilter.afwtdn;

  /// Returns a copy of this [AfwtdnEffect] with the given fields replaced.
  AfwtdnEffect copyWith({
    bool? enabled,
    bool? adaptive,
    int? levels,
    double? percent,
    bool? profile,
    int? samples,
    double? sigma,
    double? softness,
    AfwtdnWavet? wavet,
  }) => AfwtdnEffect(
    enabled: enabled ?? this.enabled,
    adaptive: adaptive ?? this.adaptive,
    levels: levels ?? this.levels,
    percent: percent ?? this.percent,
    profile: profile ?? this.profile,
    samples: samples ?? this.samples,
    sigma: sigma ?? this.sigma,
    softness: softness ?? this.softness,
    wavet: wavet ?? this.wavet,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AfwtdnEffect &&
          other.enabled == enabled &&
          other.adaptive == adaptive &&
          other.levels == levels &&
          other.percent == percent &&
          other.profile == profile &&
          other.samples == samples &&
          other.sigma == sigma &&
          other.softness == softness &&
          other.wavet == wavet);

  @override
  int get hashCode => Object.hash(
    enabled,
    adaptive,
    levels,
    percent,
    profile,
    samples,
    sigma,
    softness,
    wavet,
  );

  @override
  String toString() =>
      'AfwtdnEffect(enabled: $enabled, adaptive: $adaptive, levels: $levels, percent: $percent, profile: $profile, samples: $samples, sigma: $sigma, softness: $softness, wavet: $wavet)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    assert(levels >= levelsMin, 'afwtdn.levels must be >= 1');
    assert(levels <= levelsMax, 'afwtdn.levels must be <= 12');
    assert(percent >= percentMin, 'afwtdn.percent must be >= 0');
    assert(percent <= percentMax, 'afwtdn.percent must be <= 100');
    assert(samples >= samplesMin, 'afwtdn.samples must be >= 512');
    assert(samples <= samplesMax, 'afwtdn.samples must be <= 65536');
    assert(sigma >= sigmaMin, 'afwtdn.sigma must be >= 0');
    assert(sigma <= sigmaMax, 'afwtdn.sigma must be <= 1');
    assert(softness >= softnessMin, 'afwtdn.softness must be >= 0');
    assert(softness <= softnessMax, 'afwtdn.softness must be <= 10');
    final parts = <String>[];
    if (adaptive != false) parts.add('adaptive=' + (adaptive ? '1' : '0'));
    if (levels != 10) parts.add('levels=' + levels.toString());
    if (percent != 85.0) parts.add('percent=' + _wireDouble(percent));
    if (profile != false) parts.add('profile=' + (profile ? '1' : '0'));
    if (samples != 8192) parts.add('samples=' + samples.toString());
    if (sigma != 0.0) parts.add('sigma=' + _wireDouble(sigma));
    if (softness != 1.0) parts.add('softness=' + _wireDouble(softness));
    if (wavet != AfwtdnWavet.sym10) parts.add('wavet=' + wavet.mpvValue);
    return parts.isEmpty ? 'lavfi-afwtdn' : 'lavfi-afwtdn=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  @override
  List<(String, String)>? _runtimeDiff(covariant AfwtdnEffect prev) {
    final out = <(String, String)>[];
    if (adaptive != prev.adaptive) {
      out.add(('adaptive', (adaptive ? '1' : '0')));
    }
    if (levels != prev.levels) return null;
    if (percent != prev.percent) {
      out.add(('percent', _wireDouble(percent)));
    }
    if (profile != prev.profile) {
      out.add(('profile', (profile ? '1' : '0')));
    }
    if (samples != prev.samples) return null;
    if (sigma != prev.sigma) {
      out.add(('sigma', _wireDouble(sigma)));
    }
    if (softness != prev.softness) {
      out.add(('softness', _wireDouble(softness)));
    }
    if (wavet != prev.wavet) return null;
    return out;
  }
}
