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

/// Configuration for the `ebur128` audio effect.
///
/// EBU R128 scanner filter. This filter takes an audio stream and analyzes its loudness
/// level. By default, it logs a message at a frequency of 10Hz with the
/// Momentary loudness (identified by `M`), Short-term loudness (`S`),
/// Integrated loudness (`I`) and Loudness Range (`LRA`).
///
/// The filter can only analyze streams which have
/// sample format is double-precision floating point. The input stream will be converted to
/// this specification, if needed. Users may need to insert aformat and/or aresample filters
/// after this filter to obtain the original parameters.
///
/// The filter also has a video output (see the `video` option) with a real
/// time graph to observe the loudness evolution. The graphic contains the logged
/// message mentioned above, so it is not printed anymore when this option is set,
/// unless the verbose logging is set. The main graphing area contains the
/// short-term loudness (3 seconds of analysis), and the gauge on the right is for
/// the momentary loudness (400 milliseconds), but can optionally be configured
/// to instead display short-term loudness (see `gauge`).
///
/// The green area marks a  +/- 1LU target range around the target loudness
/// (-23LUFS by default, unless modified through `target`).
///
/// More information about the Loudness Recommendation EBU R128 on
/// http://tech.ebu.ch/loudness.
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [dualmono]: treat mono input files as dual-mono (range 0..1, default 0)
/// - [framelog]: Force the frame logging level.  Available values are: (range -2147483648..2147483647, default -1)
/// - [gauge]: set gauge display type (range 0..1, default 0)
/// - [metadata]: Set metadata injection. If set to `1`, the audio input will be segmented into 100ms output frames, each of them containing various loudness information in metadata.  All the metadata keys are prefixed with `lavfi.r128.`.  Default is `0`. (range 0..1, default 0)
/// - [meter]: Set the EBU scale meter. Default is `9`. Common values are `9` and `18`, respectively for EBU scale meter +9 and EBU scale meter +18. Any other integer value between this range is allowed. (range 9..18, default 9)
/// - [panlaw]: set a specific pan law for dual-mono files (range -10.0..0.0, default -3.01029995663978)
/// - [peak]: set peak mode (range 0..2147483647, default PEAK_MODE_NONE)
/// - [scale]: sets display method for the stats (range 0..1, default 0)
/// - [size]: Set the video size. This option is for video only. For the syntax of this option, check the video size syntax. Default and minimum resolution is `640x480`. (range 0..0, default "640x480")
/// - [target]: set a specific target level in LUFS (-23 to 0) (range -23..0, default -23)
/// - [video]: Activate the video output. The audio stream is passed unchanged whether this option is set or no. The video stream will be the first output stream if activated. Default is `0`. (range 0..1, default 0)
final class Ebur128Effect extends AudioEffect {
  /// Default value for [meter].
  static const int meterDefault = 9;

  /// Minimum value for [meter].
  static const int meterMin = 9;

  /// Maximum value for [meter].
  static const int meterMax = 18;

  /// Default value for [panlaw].
  static const double panlawDefault = -3.01029995663978;

  /// Minimum value for [panlaw].
  static const double panlawMin = -10.0;

  /// Maximum value for [panlaw].
  static const double panlawMax = 0.0;

  /// Default value for [target].
  static const int targetDefault = -23;

  /// Minimum value for [target].
  static const int targetMin = -23;

  /// Maximum value for [target].
  static const int targetMax = 0;

  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// treat mono input files as dual-mono
  final bool dualmono;

  /// force frame logging level
  final Ebur128Level? framelog;

  /// set gauge display type
  final Ebur128Gaugetype gauge;

  /// inject metadata in the filtergraph
  final bool metadata;

  /// set scale meter (+9 to +18)
  final int meter;

  /// set a specific pan law for dual-mono files
  final double panlaw;

  /// set peak mode
  final Set<Ebur128Mode> peak;

  /// sets display method for the stats
  final Ebur128Scaletype scale;

  /// set video size
  final String size;

  /// set a specific target level in LUFS (-23 to 0)
  final int target;

  /// set video output
  final bool video;

  /// Creates an [Ebur128Effect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const Ebur128Effect({
    this.enabled = true,
    this.dualmono = false,
    this.framelog,
    this.gauge = Ebur128Gaugetype.momentary,
    this.metadata = false,
    this.meter = 9,
    this.panlaw = -3.01029995663978,
    this.peak = const <Ebur128Mode>{},
    this.scale = Ebur128Scaletype.absolute,
    this.size = '640x480',
    this.target = -23,
    this.video = false,
  });

  @override
  String get filterName => 'ebur128';

  @override
  AudioFilter get filter => AudioFilter.ebur128;

  /// Returns a copy of this [Ebur128Effect] with the given fields replaced.
  Ebur128Effect copyWith({
    bool? enabled,
    bool? dualmono,
    Object? framelog = unset,
    Ebur128Gaugetype? gauge,
    bool? metadata,
    int? meter,
    double? panlaw,
    Set<Ebur128Mode>? peak,
    Ebur128Scaletype? scale,
    String? size,
    int? target,
    bool? video,
  }) => Ebur128Effect(
    enabled: enabled ?? this.enabled,
    dualmono: dualmono ?? this.dualmono,
    framelog: identical(framelog, unset)
        ? this.framelog
        : framelog as Ebur128Level?,
    gauge: gauge ?? this.gauge,
    metadata: metadata ?? this.metadata,
    meter: meter ?? this.meter,
    panlaw: panlaw ?? this.panlaw,
    peak: peak ?? this.peak,
    scale: scale ?? this.scale,
    size: size ?? this.size,
    target: target ?? this.target,
    video: video ?? this.video,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Ebur128Effect &&
          other.enabled == enabled &&
          other.dualmono == dualmono &&
          other.framelog == framelog &&
          other.gauge == gauge &&
          other.metadata == metadata &&
          other.meter == meter &&
          other.panlaw == panlaw &&
          _setEq(peak, other.peak) &&
          other.scale == scale &&
          other.size == size &&
          other.target == target &&
          other.video == video);

  @override
  int get hashCode => Object.hash(
    enabled,
    dualmono,
    framelog,
    gauge,
    metadata,
    meter,
    panlaw,
    Object.hashAllUnordered(peak),
    scale,
    size,
    target,
    video,
  );

  @override
  String toString() =>
      'Ebur128Effect(enabled: $enabled, dualmono: $dualmono, framelog: $framelog, gauge: $gauge, metadata: $metadata, meter: $meter, panlaw: $panlaw, peak: $peak, scale: $scale, size: $size, target: $target, video: $video)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    assert(meter >= meterMin, 'ebur128.meter must be >= 9');
    assert(meter <= meterMax, 'ebur128.meter must be <= 18');
    assert(panlaw >= panlawMin, 'ebur128.panlaw must be >= -10.0');
    assert(panlaw <= panlawMax, 'ebur128.panlaw must be <= 0.0');
    assert(target >= targetMin, 'ebur128.target must be >= -23');
    assert(target <= targetMax, 'ebur128.target must be <= 0');
    final parts = <String>[];
    if (dualmono != false) parts.add('dualmono=' + (dualmono ? '1' : '0'));
    if (framelog != null) parts.add('framelog=' + framelog!.mpvValue);
    if (gauge != Ebur128Gaugetype.momentary)
      parts.add('gauge=' + gauge.mpvValue);
    if (metadata != false) parts.add('metadata=' + (metadata ? '1' : '0'));
    if (meter != 9) parts.add('meter=' + meter.toString());
    if (panlaw != -3.01029995663978) parts.add('panlaw=' + _wireDouble(panlaw));
    if (peak.isNotEmpty)
      parts.add('peak=' + peak.map((e) => e.mpvValue).join('+'));
    if (scale != Ebur128Scaletype.absolute)
      parts.add('scale=' + scale.mpvValue);
    if (size != '640x480') parts.add('size=' + _wireString(size));
    if (target != -23) parts.add('target=' + target.toString());
    if (video != false) parts.add('video=' + (video ? '1' : '0'));
    return parts.isEmpty ? 'lavfi-ebur128' : 'lavfi-ebur128=' + parts.join(':');
  }
}
