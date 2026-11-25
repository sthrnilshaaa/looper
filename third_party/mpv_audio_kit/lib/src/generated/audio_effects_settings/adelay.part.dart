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

/// Configuration for the `adelay` audio effect.
///
/// Delay one or more audio channels.
///
/// Samples in delayed channel are filled with silence.
///
/// The filter accepts the following option:
///
/// Parameters:
/// - [all]: Use last set delay for all remaining channels. By default is disabled. This option if enabled changes how option `delays` is interpreted. (range 0..1, default 0)
/// - [delays]: Set list of delays in milliseconds for each channel separated by '|'. Unused delays will be silently ignored. If number of given delays is smaller than number of channels all remaining channels will not be delayed. If you want to delay exact number of samples, append 'S' to number. If you want instead to delay in seconds, append 's' to number. (range 0..0, default "")
final class AdelayEffect extends AudioEffect {
  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// use last available delay for remained channels
  final bool all;

  /// set list of delays for each channel
  final String delays;

  /// Creates an [AdelayEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const AdelayEffect({this.enabled = true, this.all = false, this.delays = ''});

  @override
  String get filterName => 'adelay';

  @override
  AudioFilter get filter => AudioFilter.adelay;

  /// Returns a copy of this [AdelayEffect] with the given fields replaced.
  AdelayEffect copyWith({bool? enabled, bool? all, String? delays}) =>
      AdelayEffect(
        enabled: enabled ?? this.enabled,
        all: all ?? this.all,
        delays: delays ?? this.delays,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AdelayEffect &&
          other.enabled == enabled &&
          other.all == all &&
          other.delays == delays);

  @override
  int get hashCode => Object.hash(enabled, all, delays);

  @override
  String toString() =>
      'AdelayEffect(enabled: $enabled, all: $all, delays: $delays)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    final parts = <String>[];
    if (all != false) parts.add('all=' + (all ? '1' : '0'));
    if (delays != '') parts.add('delays=' + _wireString(delays));
    return parts.isEmpty ? 'lavfi-adelay' : 'lavfi-adelay=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  @override
  List<(String, String)>? _runtimeDiff(covariant AdelayEffect prev) {
    final out = <(String, String)>[];
    if (all != prev.all) return null;
    if (delays != prev.delays) return null;
    return out;
  }
}
