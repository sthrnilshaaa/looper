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

/// Configuration for the `atempo` audio effect.
///
/// Adjust audio tempo.
///
/// The filter accepts exactly one parameter, the audio tempo. If not
/// specified then the filter will assume nominal 1.0 tempo. Tempo must
/// be in the \[0.5, 100.0\] range.
///
/// Note that tempo greater than 2 will skip some samples rather than
/// blend them in.  If for any reason this is a concern it is always
/// possible to daisy-chain several instances of atempo to achieve the
/// desired product tempo.
///
/// Slow down audio to 80% tempo:
///
/// - To speed up audio to 300% tempo:
///
/// - To speed up audio to 300% tempo by daisy-chaining two atempo instances:
///
/// This filter supports the following commands:
///
/// Parameters:
/// - [tempo]: Change filter tempo scale factor. Syntax for the command is : "`tempo`" (range 0.5..100.0, default 1.0, runtime-tunable)
final class AtempoEffect extends AudioEffect {
  /// Default value for [tempo].
  static const double tempoDefault = 1.0;

  /// Minimum value for [tempo].
  static const double tempoMin = 0.5;

  /// Maximum value for [tempo].
  static const double tempoMax = 100.0;

  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// set tempo scale factor
  final double tempo;

  /// Creates an [AtempoEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const AtempoEffect({this.enabled = true, this.tempo = 1.0});

  @override
  String get filterName => 'atempo';

  @override
  AudioFilter get filter => AudioFilter.atempo;

  /// Returns a copy of this [AtempoEffect] with the given fields replaced.
  AtempoEffect copyWith({bool? enabled, double? tempo}) => AtempoEffect(
    enabled: enabled ?? this.enabled,
    tempo: tempo ?? this.tempo,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AtempoEffect &&
          other.enabled == enabled &&
          other.tempo == tempo);

  @override
  int get hashCode => Object.hash(enabled, tempo);

  @override
  String toString() => 'AtempoEffect(enabled: $enabled, tempo: $tempo)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    assert(tempo >= tempoMin, 'atempo.tempo must be >= 0.5');
    assert(tempo <= tempoMax, 'atempo.tempo must be <= 100.0');
    final parts = <String>[];
    if (tempo != 1.0) parts.add('tempo=' + _wireDouble(tempo));
    return parts.isEmpty ? 'lavfi-atempo' : 'lavfi-atempo=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  @override
  List<(String, String)>? _runtimeDiff(covariant AtempoEffect prev) {
    final out = <(String, String)>[];
    if (tempo != prev.tempo) {
      out.add(('tempo', _wireDouble(tempo)));
    }
    return out;
  }
}
