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

/// Configuration for the `dialoguenhance` audio effect.
///
/// Enhance dialogue in stereo audio.
///
/// This filter accepts stereo input and produce surround (3.0) channels output.
/// The newly produced front center channel have enhanced speech dialogue originally
/// available in both stereo channels.
/// This filter outputs front left and front right channels same as available in stereo input.
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [enhance]: Set the dialogue enhance factor to put in front center channel output. Allowed range is from 0 to 3. Default value is 1. (range 0..3, default 1, runtime-tunable)
/// - [original]: Set the original center factor to keep in front center channel output. Allowed range is from 0 to 1. Default value is 1. (range 0..1, default 1, runtime-tunable)
/// - [voice]: Set the voice detection factor. Allowed range is from 2 to 32. Default value is 2. (range 2..32, default 2, runtime-tunable)
final class DialoguenhanceEffect extends AudioEffect {
  /// Default value for [enhance].
  static const double enhanceDefault = 1.0;

  /// Minimum value for [enhance].
  static const double enhanceMin = 0.0;

  /// Maximum value for [enhance].
  static const double enhanceMax = 3.0;

  /// Default value for [original].
  static const double originalDefault = 1.0;

  /// Minimum value for [original].
  static const double originalMin = 0.0;

  /// Maximum value for [original].
  static const double originalMax = 1.0;

  /// Default value for [voice].
  static const double voiceDefault = 2.0;

  /// Minimum value for [voice].
  static const double voiceMin = 2.0;

  /// Maximum value for [voice].
  static const double voiceMax = 32.0;

  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// set dialogue enhance factor
  final double enhance;

  /// set original center factor
  final double original;

  /// set voice detection factor
  final double voice;

  /// Creates an [DialoguenhanceEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const DialoguenhanceEffect({
    this.enabled = true,
    this.enhance = 1.0,
    this.original = 1.0,
    this.voice = 2.0,
  });

  @override
  String get filterName => 'dialoguenhance';

  @override
  AudioFilter get filter => AudioFilter.dialoguenhance;

  /// Returns a copy of this [DialoguenhanceEffect] with the given fields replaced.
  DialoguenhanceEffect copyWith({
    bool? enabled,
    double? enhance,
    double? original,
    double? voice,
  }) => DialoguenhanceEffect(
    enabled: enabled ?? this.enabled,
    enhance: enhance ?? this.enhance,
    original: original ?? this.original,
    voice: voice ?? this.voice,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DialoguenhanceEffect &&
          other.enabled == enabled &&
          other.enhance == enhance &&
          other.original == original &&
          other.voice == voice);

  @override
  int get hashCode => Object.hash(enabled, enhance, original, voice);

  @override
  String toString() =>
      'DialoguenhanceEffect(enabled: $enabled, enhance: $enhance, original: $original, voice: $voice)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    assert(enhance >= enhanceMin, 'dialoguenhance.enhance must be >= 0');
    assert(enhance <= enhanceMax, 'dialoguenhance.enhance must be <= 3');
    assert(original >= originalMin, 'dialoguenhance.original must be >= 0');
    assert(original <= originalMax, 'dialoguenhance.original must be <= 1');
    assert(voice >= voiceMin, 'dialoguenhance.voice must be >= 2');
    assert(voice <= voiceMax, 'dialoguenhance.voice must be <= 32');
    final parts = <String>[];
    if (enhance != 1.0) parts.add('enhance=' + _wireDouble(enhance));
    if (original != 1.0) parts.add('original=' + _wireDouble(original));
    if (voice != 2.0) parts.add('voice=' + _wireDouble(voice));
    return parts.isEmpty
        ? 'lavfi-dialoguenhance'
        : 'lavfi-dialoguenhance=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  @override
  List<(String, String)>? _runtimeDiff(covariant DialoguenhanceEffect prev) {
    final out = <(String, String)>[];
    if (enhance != prev.enhance) {
      out.add(('enhance', _wireDouble(enhance)));
    }
    if (original != prev.original) {
      out.add(('original', _wireDouble(original)));
    }
    if (voice != prev.voice) {
      out.add(('voice', _wireDouble(voice)));
    }
    return out;
  }
}
