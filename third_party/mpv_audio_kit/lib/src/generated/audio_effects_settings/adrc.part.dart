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

/// Configuration for the `adrc` audio effect.
///
/// Apply spectral dynamic range controller filter to input audio stream.
///
/// A description of the accepted options follows.
///
/// Parameters:
/// - [attack]: Set the attack in milliseconds. Default is `50` milliseconds. Allowed range is from 1 to 1000 milliseconds. (range 1..1000, default 50., runtime-tunable)
/// - [channels]: Set which channels to filter, by default `all` channels in audio stream are filtered. (range 0..0, default "all", runtime-tunable)
/// - [release]: Set the release in milliseconds. Default is `100` milliseconds. Allowed range is from 5 to 2000 milliseconds. (range 5..2000, default 100., runtime-tunable)
/// - [transfer]: Set the transfer expression.  The expression can contain the following constants: (range 0..0, default "p", runtime-tunable)
final class AdrcEffect extends AudioEffect {
  /// Default value for [attack].
  static const double attackDefault = 50.0;

  /// Minimum value for [attack].
  static const double attackMin = 1.0;

  /// Maximum value for [attack].
  static const double attackMax = 1000.0;

  /// Default value for [release].
  static const double releaseDefault = 100.0;

  /// Minimum value for [release].
  static const double releaseMin = 5.0;

  /// Maximum value for [release].
  static const double releaseMax = 2000.0;

  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// set the attack
  final double attack;

  /// set channels to filter
  final String channels;

  /// set the release
  final double release;

  /// set the transfer expression
  final String transfer;

  /// Creates an [AdrcEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const AdrcEffect({
    this.enabled = true,
    this.attack = 50.0,
    this.channels = 'all',
    this.release = 100.0,
    this.transfer = 'p',
  });

  @override
  String get filterName => 'adrc';

  @override
  AudioFilter get filter => AudioFilter.adrc;

  /// Returns a copy of this [AdrcEffect] with the given fields replaced.
  AdrcEffect copyWith({
    bool? enabled,
    double? attack,
    String? channels,
    double? release,
    String? transfer,
  }) => AdrcEffect(
    enabled: enabled ?? this.enabled,
    attack: attack ?? this.attack,
    channels: channels ?? this.channels,
    release: release ?? this.release,
    transfer: transfer ?? this.transfer,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AdrcEffect &&
          other.enabled == enabled &&
          other.attack == attack &&
          other.channels == channels &&
          other.release == release &&
          other.transfer == transfer);

  @override
  int get hashCode => Object.hash(enabled, attack, channels, release, transfer);

  @override
  String toString() =>
      'AdrcEffect(enabled: $enabled, attack: $attack, channels: $channels, release: $release, transfer: $transfer)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    assert(attack >= attackMin, 'adrc.attack must be >= 1');
    assert(attack <= attackMax, 'adrc.attack must be <= 1000');
    assert(release >= releaseMin, 'adrc.release must be >= 5');
    assert(release <= releaseMax, 'adrc.release must be <= 2000');
    final parts = <String>[];
    if (attack != 50.0) parts.add('attack=' + _wireDouble(attack));
    if (channels != 'all') parts.add('channels=' + _wireString(channels));
    if (release != 100.0) parts.add('release=' + _wireDouble(release));
    if (transfer != 'p') parts.add('transfer=' + _wireString(transfer));
    return parts.isEmpty ? 'lavfi-adrc' : 'lavfi-adrc=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  @override
  List<(String, String)>? _runtimeDiff(covariant AdrcEffect prev) {
    final out = <(String, String)>[];
    if (attack != prev.attack) {
      out.add(('attack', _wireDouble(attack)));
    }
    if (channels != prev.channels) {
      out.add(('channels', channels));
    }
    if (release != prev.release) {
      out.add(('release', _wireDouble(release)));
    }
    if (transfer != prev.transfer) {
      out.add(('transfer', transfer));
    }
    return out;
  }
}
