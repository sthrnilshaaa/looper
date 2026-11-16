// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license
// that can be found in the LICENSE file.
//
// AUTO-GENERATED — do not edit by hand.
// ignore_for_file: non_constant_identifier_names, constant_identifier_names, camel_case_types, curly_braces_in_flow_control_structures, prefer_adjacent_string_concatenation, prefer_interpolation_to_compose_strings

import '../internals/unset_sentinel.dart';
import 'audio_effects.dart';

// Collection equality helpers used by the generated `==`. Kept
// inline to avoid a transitive `package:collection` dependency.
bool _setEq<T>(Set<T> a, Set<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (final e in a) {
    if (!b.contains(e)) return false;
  }
  return true;
}

bool _mapEq<K, V>(Map<K, V> a, Map<K, V> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (final entry in a.entries) {
    if (!b.containsKey(entry.key) || b[entry.key] != entry.value) {
      return false;
    }
  }
  return true;
}

bool _listEq<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// Wire-format a double for the lavfi af-chain. Uses 3-decimal
/// fixed-point when that is exact, 6 decimals when it is not (so
/// `0.0014` keeps its digits), and an exponential for tiny values
/// that would otherwise round to `0.000` (e.g. `1e-6` for
/// `asoftclip.threshold`'s minimum).
/// `toStringAsExponential()` is deterministic across runtimes
/// (Dart's `toString()` chooses between decimal and exponential
/// based on magnitude and platform), and mpv's AVOption parser
/// accepts exponential floats natively.
String _wireDouble(double v) {
  final fixed = v.toStringAsFixed(3);
  if (v == 0 || double.parse(fixed) == v) return fixed;
  if (v.abs() < 0.001) return v.toStringAsExponential();
  return v.toStringAsFixed(6);
}

/// Configuration for the `acompressor` audio effect.
///
/// A compressor is mainly used to reduce the dynamic range of a signal.
/// Especially modern music is mostly compressed at a high ratio to
/// improve the overall loudness. It's done to get the highest attention
/// of a listener, "fatten" the sound and bring more "power" to the track.
/// If a signal is compressed too much it may sound dull or "dead"
/// afterwards or it may start to "pump" (which could be a powerful effect
/// but can also destroy a track completely).
/// The right compression is the key to reach a professional sound and is
/// the high art of mixing and mastering. Because of its complex settings
/// it may take a long time to get the right feeling for this kind of effect.
///
/// Compression is done by detecting the volume above a chosen level
/// `threshold` and dividing it by the factor set with `ratio`.
/// So if you set the threshold to -12dB and your signal reaches -6dB a ratio
/// of 2:1 will result in a signal at -9dB. Because an exact manipulation of
/// the signal would cause distortion of the waveform the reduction can be
/// levelled over the time. This is done by setting "Attack" and "Release".
/// `attack` determines how long the signal has to rise above the threshold
/// before any reduction will occur and `release` sets the time the signal
/// has to fall below the threshold to reduce the reduction again. Shorter signals
/// than the chosen attack time will be left untouched.
/// The overall reduction of the signal can be made up afterwards with the
/// `makeup` setting. So compressing the peaks of a signal about 6dB and
/// raising the makeup to this level results in a signal twice as loud than the
/// source. To gain a softer entry in the compression the `knee` flattens the
/// hard edge at the threshold in the range of the chosen decibels.
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [attack]: Amount of milliseconds the signal has to rise above the threshold before gain reduction starts. Default is 20. Range is between 0.01 and 2000. (range 0.01..2000, default 20, runtime-tunable)
/// - [detection]: Should the exact signal be taken in case of `peak` or an RMS one in case of `rms`. Default is `rms` which is mostly smoother. (range 0..1, default 1, runtime-tunable)
/// - [knee]: Curve the sharp knee around the threshold to enter gain reduction more softly. Default is 2.82843. Range is between 1 and 8. (range 1..8, default 2.82843, runtime-tunable)
/// - [level_in]: Set input gain. Default is 1. Range is between 0.015625 and 64. (range 0.015625..64, default 1, runtime-tunable)
/// - [level_sc]: set sidechain gain (range 0.015625..64, default 1, runtime-tunable)
/// - [link]: Choose if the `average` level between all channels of input stream or the louder(`maximum`) channel of input stream affects the reduction. Default is `average`. (range 0..1, default 0, runtime-tunable)
/// - [makeup]: Set the amount by how much signal will be amplified after processing. Default is 1. Range is from 1 to 64. (range 1..64, default 1, runtime-tunable)
/// - [mix]: How much to use compressed signal in output. Default is 1. Range is between 0 and 1. (range 0..1, default 1, runtime-tunable)
/// - [mode]: Set mode of compressor operation. Can be `upward` or `downward`. Default is `downward`. (range 0..1, default 0, runtime-tunable)
/// - [ratio]: Set a ratio by which the signal is reduced. 1:2 means that if the level rose 4dB above the threshold, it will be only 2dB above after the reduction. Default is 2. Range is between 1 and 20. (range 1..20, default 2, runtime-tunable)
/// - [release]: Amount of milliseconds the signal has to fall below the threshold before reduction is decreased again. Default is 250. Range is between 0.01 and 9000. (range 0.01..9000, default 250, runtime-tunable)
/// - [threshold]: If a signal of stream rises above this level it will affect the gain reduction. By default it is 0.125. Range is between 0.00097563 and 1. (range 0.000976563..1, default 0.125, runtime-tunable)
final class AcompressorSettings {
  /// Default value for [attack].
  static const double attackDefault = 20.0;

  /// Minimum value for [attack].
  static const double attackMin = 0.01;

  /// Maximum value for [attack].
  static const double attackMax = 2000.0;

  /// Default value for [knee].
  static const double kneeDefault = 2.82843;

  /// Minimum value for [knee].
  static const double kneeMin = 1.0;

  /// Maximum value for [knee].
  static const double kneeMax = 8.0;

  /// Default value for [level_in].
  static const double level_inDefault = 1.0;

  /// Minimum value for [level_in].
  static const double level_inMin = 0.015625;

  /// Maximum value for [level_in].
  static const double level_inMax = 64.0;

  /// Default value for [level_sc].
  static const double level_scDefault = 1.0;

  /// Minimum value for [level_sc].
  static const double level_scMin = 0.015625;

  /// Maximum value for [level_sc].
  static const double level_scMax = 64.0;

  /// Default value for [makeup].
  static const double makeupDefault = 1.0;

  /// Minimum value for [makeup].
  static const double makeupMin = 1.0;

  /// Maximum value for [makeup].
  static const double makeupMax = 64.0;

  /// Default value for [mix].
  static const double mixDefault = 1.0;

  /// Minimum value for [mix].
  static const double mixMin = 0.0;

  /// Maximum value for [mix].
  static const double mixMax = 1.0;

  /// Default value for [ratio].
  static const double ratioDefault = 2.0;

  /// Minimum value for [ratio].
  static const double ratioMin = 1.0;

  /// Maximum value for [ratio].
  static const double ratioMax = 20.0;

  /// Default value for [release].
  static const double releaseDefault = 250.0;

  /// Minimum value for [release].
  static const double releaseMin = 0.01;

  /// Maximum value for [release].
  static const double releaseMax = 9000.0;

  /// Default value for [threshold].
  static const double thresholdDefault = 0.125;

  /// Minimum value for [threshold].
  static const double thresholdMin = 0.000976563;

  /// Maximum value for [threshold].
  static const double thresholdMax = 1.0;

  /// Whether this effect is inserted into the audio chain.
  final bool enabled;

  /// set attack
  final double attack;

  /// set detection
  final AcompressorDetection detection;

  /// set knee
  final double knee;

  /// set input gain
  final double level_in;

  /// set sidechain gain
  final double level_sc;

  /// set link type
  final AcompressorLink link;

  /// set make up gain
  final double makeup;

  /// set mix
  final double mix;

  /// set mode
  final AcompressorMode mode;

  /// set ratio
  final double ratio;

  /// set release
  final double release;

  /// set threshold
  final double threshold;

  /// Creates an [AcompressorSettings] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default; the effect stays
  /// inactive until [enabled] is set to `true`.
  const AcompressorSettings({
    this.enabled = false,
    this.attack = 20.0,
    this.detection = AcompressorDetection.rms,
    this.knee = 2.82843,
    this.level_in = 1.0,
    this.level_sc = 1.0,
    this.link = AcompressorLink.average,
    this.makeup = 1.0,
    this.mix = 1.0,
    this.mode = AcompressorMode.downward,
    this.ratio = 2.0,
    this.release = 250.0,
    this.threshold = 0.125,
  });

  /// Returns a copy of this [AcompressorSettings] with the given fields replaced.
  AcompressorSettings copyWith({
    bool? enabled,
    double? attack,
    AcompressorDetection? detection,
    double? knee,
    double? level_in,
    double? level_sc,
    AcompressorLink? link,
    double? makeup,
    double? mix,
    AcompressorMode? mode,
    double? ratio,
    double? release,
    double? threshold,
  }) =>
      AcompressorSettings(
        enabled: enabled ?? this.enabled,
        attack: attack ?? this.attack,
        detection: detection ?? this.detection,
        knee: knee ?? this.knee,
        level_in: level_in ?? this.level_in,
        level_sc: level_sc ?? this.level_sc,
        link: link ?? this.link,
        makeup: makeup ?? this.makeup,
        mix: mix ?? this.mix,
        mode: mode ?? this.mode,
        ratio: ratio ?? this.ratio,
        release: release ?? this.release,
        threshold: threshold ?? this.threshold,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AcompressorSettings &&
          other.enabled == enabled &&
          other.attack == attack &&
          other.detection == detection &&
          other.knee == knee &&
          other.level_in == level_in &&
          other.level_sc == level_sc &&
          other.link == link &&
          other.makeup == makeup &&
          other.mix == mix &&
          other.mode == mode &&
          other.ratio == ratio &&
          other.release == release &&
          other.threshold == threshold);

  @override
  int get hashCode => Object.hash(enabled, attack, detection, knee, level_in,
      level_sc, link, makeup, mix, mode, ratio, release, threshold,);

  @override
  String toString() =>
      'AcompressorSettings(enabled: $enabled, attack: $attack, detection: $detection, knee: $knee, level_in: $level_in, level_sc: $level_sc, link: $link, makeup: $makeup, mix: $mix, mode: $mode, ratio: $ratio, release: $release, threshold: $threshold)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(attack >= attackMin, 'acompressor.attack must be >= 0.01');
    assert(attack <= attackMax, 'acompressor.attack must be <= 2000');
    assert(knee >= kneeMin, 'acompressor.knee must be >= 1');
    assert(knee <= kneeMax, 'acompressor.knee must be <= 8');
    assert(level_in >= level_inMin, 'acompressor.level_in must be >= 0.015625');
    assert(level_in <= level_inMax, 'acompressor.level_in must be <= 64');
    assert(level_sc >= level_scMin, 'acompressor.level_sc must be >= 0.015625');
    assert(level_sc <= level_scMax, 'acompressor.level_sc must be <= 64');
    assert(makeup >= makeupMin, 'acompressor.makeup must be >= 1');
    assert(makeup <= makeupMax, 'acompressor.makeup must be <= 64');
    assert(mix >= mixMin, 'acompressor.mix must be >= 0');
    assert(mix <= mixMax, 'acompressor.mix must be <= 1');
    assert(ratio >= ratioMin, 'acompressor.ratio must be >= 1');
    assert(ratio <= ratioMax, 'acompressor.ratio must be <= 20');
    assert(release >= releaseMin, 'acompressor.release must be >= 0.01');
    assert(release <= releaseMax, 'acompressor.release must be <= 9000');
    assert(threshold >= thresholdMin,
        'acompressor.threshold must be >= 0.000976563',);
    assert(threshold <= thresholdMax, 'acompressor.threshold must be <= 1');
    final parts = <String>[];
    if (attack != 20.0) parts.add('attack=' + _wireDouble(attack));
    if (detection != AcompressorDetection.rms)
      parts.add('detection=' + detection.mpvValue);
    if (knee != 2.82843) parts.add('knee=' + _wireDouble(knee));
    if (level_in != 1.0) parts.add('level_in=' + _wireDouble(level_in));
    if (level_sc != 1.0) parts.add('level_sc=' + _wireDouble(level_sc));
    if (link != AcompressorLink.average) parts.add('link=' + link.mpvValue);
    if (makeup != 1.0) parts.add('makeup=' + _wireDouble(makeup));
    if (mix != 1.0) parts.add('mix=' + _wireDouble(mix));
    if (mode != AcompressorMode.downward) parts.add('mode=' + mode.mpvValue);
    if (ratio != 2.0) parts.add('ratio=' + _wireDouble(ratio));
    if (release != 250.0) parts.add('release=' + _wireDouble(release));
    if (threshold != 0.125) parts.add('threshold=' + _wireDouble(threshold));
    return parts.isEmpty
        ? 'lavfi-acompressor'
        : 'lavfi-acompressor=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  List<(String, String)>? _runtimeDiff(AcompressorSettings prev) {
    final out = <(String, String)>[];
    if (attack != prev.attack) {
      out.add(('attack', _wireDouble(attack)));
    }
    if (detection != prev.detection) {
      out.add(('detection', detection.mpvValue));
    }
    if (knee != prev.knee) {
      out.add(('knee', _wireDouble(knee)));
    }
    if (level_in != prev.level_in) {
      out.add(('level_in', _wireDouble(level_in)));
    }
    if (level_sc != prev.level_sc) {
      out.add(('level_sc', _wireDouble(level_sc)));
    }
    if (link != prev.link) {
      out.add(('link', link.mpvValue));
    }
    if (makeup != prev.makeup) {
      out.add(('makeup', _wireDouble(makeup)));
    }
    if (mix != prev.mix) {
      out.add(('mix', _wireDouble(mix)));
    }
    if (mode != prev.mode) {
      out.add(('mode', mode.mpvValue));
    }
    if (ratio != prev.ratio) {
      out.add(('ratio', _wireDouble(ratio)));
    }
    if (release != prev.release) {
      out.add(('release', _wireDouble(release)));
    }
    if (threshold != prev.threshold) {
      out.add(('threshold', _wireDouble(threshold)));
    }
    return out;
  }
}

/// Configuration for the `acontrast` audio effect.
///
/// Simple audio dynamic range compression/expansion filter.
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [contrast]: Set contrast. Default is 33. Allowed range is between 0 and 100. (range 0..100, default 33)
final class AcontrastSettings {
  /// Default value for [contrast].
  static const double contrastDefault = 33.0;

  /// Minimum value for [contrast].
  static const double contrastMin = 0.0;

  /// Maximum value for [contrast].
  static const double contrastMax = 100.0;

  /// Whether this effect is inserted into the audio chain.
  final bool enabled;

  /// set contrast
  final double contrast;

  /// Creates an [AcontrastSettings] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default; the effect stays
  /// inactive until [enabled] is set to `true`.
  const AcontrastSettings({
    this.enabled = false,
    this.contrast = 33.0,
  });

  /// Returns a copy of this [AcontrastSettings] with the given fields replaced.
  AcontrastSettings copyWith({
    bool? enabled,
    double? contrast,
  }) =>
      AcontrastSettings(
        enabled: enabled ?? this.enabled,
        contrast: contrast ?? this.contrast,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AcontrastSettings &&
          other.enabled == enabled &&
          other.contrast == contrast);

  @override
  int get hashCode => Object.hash(enabled, contrast);

  @override
  String toString() =>
      'AcontrastSettings(enabled: $enabled, contrast: $contrast)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(contrast >= contrastMin, 'acontrast.contrast must be >= 0');
    assert(contrast <= contrastMax, 'acontrast.contrast must be <= 100');
    final parts = <String>[];
    if (contrast != 33.0) parts.add('contrast=' + _wireDouble(contrast));
    return parts.isEmpty
        ? 'lavfi-acontrast'
        : 'lavfi-acontrast=' + parts.join(':');
  }
}

/// Configuration for the `acrusher` audio effect.
///
/// Reduce audio bit resolution.
///
/// This filter is bit crusher with enhanced functionality. A bit crusher
/// is used to audibly reduce number of bits an audio signal is sampled
/// with. This doesn't change the bit depth at all, it just produces the
/// effect. Material reduced in bit depth sounds more harsh and "digital".
/// This filter is able to even round to continuous values instead of discrete
/// bit depths.
/// Additionally it has a D/C offset which results in different crushing of
/// the lower and the upper half of the signal.
/// An Anti-Aliasing setting is able to produce "softer" crushing sounds.
///
/// Another feature of this filter is the logarithmic mode.
/// This setting switches from linear distances between bits to logarithmic ones.
/// The result is a much more "natural" sounding crusher which doesn't gate low
/// signals for example. The human ear has a logarithmic perception,
/// so this kind of crushing is much more pleasant.
/// Logarithmic crushing is also able to get anti-aliased.
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [aa]: Set anti-aliasing. (range 0..1, default .5, runtime-tunable)
/// - [bits]: Set bit reduction. (range 1..64, default 8, runtime-tunable)
/// - [dc]: Set DC. (range .25..4, default 1, runtime-tunable)
/// - [level_in]: Set level in. (range 0.015625..64, default 1, runtime-tunable)
/// - [level_out]: Set level out. (range 0.015625..64, default 1, runtime-tunable)
/// - [lfo]: Enable LFO. By default disabled. (range 0..1, default 0, runtime-tunable)
/// - [lforange]: Set LFO range. (range 1..250, default 20, runtime-tunable)
/// - [lforate]: Set LFO rate. (range .01..200, default .3, runtime-tunable)
/// - [mix]: Set mixing amount. (range 0..1, default .5, runtime-tunable)
/// - [mode]: Can be linear: `lin` or logarithmic: `log`. (range 0..1, default 0, runtime-tunable)
/// - [samples]: Set sample reduction. (range 1..250, default 1, runtime-tunable)
final class AcrusherSettings {
  /// Default value for [aa].
  static const double aaDefault = .5;

  /// Minimum value for [aa].
  static const double aaMin = 0.0;

  /// Maximum value for [aa].
  static const double aaMax = 1.0;

  /// Default value for [bits].
  static const double bitsDefault = 8.0;

  /// Minimum value for [bits].
  static const double bitsMin = 1.0;

  /// Maximum value for [bits].
  static const double bitsMax = 64.0;

  /// Default value for [dc].
  static const double dcDefault = 1.0;

  /// Minimum value for [dc].
  static const double dcMin = .25;

  /// Maximum value for [dc].
  static const double dcMax = 4.0;

  /// Default value for [level_in].
  static const double level_inDefault = 1.0;

  /// Minimum value for [level_in].
  static const double level_inMin = 0.015625;

  /// Maximum value for [level_in].
  static const double level_inMax = 64.0;

  /// Default value for [level_out].
  static const double level_outDefault = 1.0;

  /// Minimum value for [level_out].
  static const double level_outMin = 0.015625;

  /// Maximum value for [level_out].
  static const double level_outMax = 64.0;

  /// Default value for [lforange].
  static const double lforangeDefault = 20.0;

  /// Minimum value for [lforange].
  static const double lforangeMin = 1.0;

  /// Maximum value for [lforange].
  static const double lforangeMax = 250.0;

  /// Default value for [lforate].
  static const double lforateDefault = .3;

  /// Minimum value for [lforate].
  static const double lforateMin = .01;

  /// Maximum value for [lforate].
  static const double lforateMax = 200.0;

  /// Default value for [mix].
  static const double mixDefault = .5;

  /// Minimum value for [mix].
  static const double mixMin = 0.0;

  /// Maximum value for [mix].
  static const double mixMax = 1.0;

  /// Default value for [samples].
  static const double samplesDefault = 1.0;

  /// Minimum value for [samples].
  static const double samplesMin = 1.0;

  /// Maximum value for [samples].
  static const double samplesMax = 250.0;

  /// Whether this effect is inserted into the audio chain.
  final bool enabled;

  /// set anti-aliasing
  final double aa;

  /// set bit reduction
  final double bits;

  /// set DC
  final double dc;

  /// set level in
  final double level_in;

  /// set level out
  final double level_out;

  /// enable LFO
  final bool lfo;

  /// set LFO depth
  final double lforange;

  /// set LFO rate
  final double lforate;

  /// set mix
  final double mix;

  /// set mode
  final AcrusherMode mode;

  /// set sample reduction
  final double samples;

  /// Creates an [AcrusherSettings] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default; the effect stays
  /// inactive until [enabled] is set to `true`.
  const AcrusherSettings({
    this.enabled = false,
    this.aa = .5,
    this.bits = 8.0,
    this.dc = 1.0,
    this.level_in = 1.0,
    this.level_out = 1.0,
    this.lfo = false,
    this.lforange = 20.0,
    this.lforate = .3,
    this.mix = .5,
    this.mode = AcrusherMode.lin,
    this.samples = 1.0,
  });

  /// Returns a copy of this [AcrusherSettings] with the given fields replaced.
  AcrusherSettings copyWith({
    bool? enabled,
    double? aa,
    double? bits,
    double? dc,
    double? level_in,
    double? level_out,
    bool? lfo,
    double? lforange,
    double? lforate,
    double? mix,
    AcrusherMode? mode,
    double? samples,
  }) =>
      AcrusherSettings(
        enabled: enabled ?? this.enabled,
        aa: aa ?? this.aa,
        bits: bits ?? this.bits,
        dc: dc ?? this.dc,
        level_in: level_in ?? this.level_in,
        level_out: level_out ?? this.level_out,
        lfo: lfo ?? this.lfo,
        lforange: lforange ?? this.lforange,
        lforate: lforate ?? this.lforate,
        mix: mix ?? this.mix,
        mode: mode ?? this.mode,
        samples: samples ?? this.samples,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AcrusherSettings &&
          other.enabled == enabled &&
          other.aa == aa &&
          other.bits == bits &&
          other.dc == dc &&
          other.level_in == level_in &&
          other.level_out == level_out &&
          other.lfo == lfo &&
          other.lforange == lforange &&
          other.lforate == lforate &&
          other.mix == mix &&
          other.mode == mode &&
          other.samples == samples);

  @override
  int get hashCode => Object.hash(enabled, aa, bits, dc, level_in, level_out,
      lfo, lforange, lforate, mix, mode, samples,);

  @override
  String toString() =>
      'AcrusherSettings(enabled: $enabled, aa: $aa, bits: $bits, dc: $dc, level_in: $level_in, level_out: $level_out, lfo: $lfo, lforange: $lforange, lforate: $lforate, mix: $mix, mode: $mode, samples: $samples)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(aa >= aaMin, 'acrusher.aa must be >= 0');
    assert(aa <= aaMax, 'acrusher.aa must be <= 1');
    assert(bits >= bitsMin, 'acrusher.bits must be >= 1');
    assert(bits <= bitsMax, 'acrusher.bits must be <= 64');
    assert(level_in >= level_inMin, 'acrusher.level_in must be >= 0.015625');
    assert(level_in <= level_inMax, 'acrusher.level_in must be <= 64');
    assert(level_out >= level_outMin, 'acrusher.level_out must be >= 0.015625');
    assert(level_out <= level_outMax, 'acrusher.level_out must be <= 64');
    assert(lforange >= lforangeMin, 'acrusher.lforange must be >= 1');
    assert(lforange <= lforangeMax, 'acrusher.lforange must be <= 250');
    assert(lforate >= lforateMin, 'acrusher.lforate must be >= .01');
    assert(lforate <= lforateMax, 'acrusher.lforate must be <= 200');
    assert(mix >= mixMin, 'acrusher.mix must be >= 0');
    assert(mix <= mixMax, 'acrusher.mix must be <= 1');
    assert(samples >= samplesMin, 'acrusher.samples must be >= 1');
    assert(samples <= samplesMax, 'acrusher.samples must be <= 250');
    final parts = <String>[];
    if (aa != .5) parts.add('aa=' + _wireDouble(aa));
    if (bits != 8.0) parts.add('bits=' + _wireDouble(bits));
    if (dc != 1.0) parts.add('dc=' + _wireDouble(dc));
    if (level_in != 1.0) parts.add('level_in=' + _wireDouble(level_in));
    if (level_out != 1.0) parts.add('level_out=' + _wireDouble(level_out));
    if (lfo != false) parts.add('lfo=' + (lfo ? '1' : '0'));
    if (lforange != 20.0) parts.add('lforange=' + _wireDouble(lforange));
    if (lforate != .3) parts.add('lforate=' + _wireDouble(lforate));
    if (mix != .5) parts.add('mix=' + _wireDouble(mix));
    if (mode != AcrusherMode.lin) parts.add('mode=' + mode.mpvValue);
    if (samples != 1.0) parts.add('samples=' + _wireDouble(samples));
    return parts.isEmpty
        ? 'lavfi-acrusher'
        : 'lavfi-acrusher=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  List<(String, String)>? _runtimeDiff(AcrusherSettings prev) {
    final out = <(String, String)>[];
    if (aa != prev.aa) {
      out.add(('aa', _wireDouble(aa)));
    }
    if (bits != prev.bits) {
      out.add(('bits', _wireDouble(bits)));
    }
    if (dc != prev.dc) {
      out.add(('dc', _wireDouble(dc)));
    }
    if (level_in != prev.level_in) {
      out.add(('level_in', _wireDouble(level_in)));
    }
    if (level_out != prev.level_out) {
      out.add(('level_out', _wireDouble(level_out)));
    }
    if (lfo != prev.lfo) {
      out.add(('lfo', (lfo ? '1' : '0')));
    }
    if (lforange != prev.lforange) {
      out.add(('lforange', _wireDouble(lforange)));
    }
    if (lforate != prev.lforate) {
      out.add(('lforate', _wireDouble(lforate)));
    }
    if (mix != prev.mix) {
      out.add(('mix', _wireDouble(mix)));
    }
    if (mode != prev.mode) {
      out.add(('mode', mode.mpvValue));
    }
    if (samples != prev.samples) {
      out.add(('samples', _wireDouble(samples)));
    }
    return out;
  }
}

/// Configuration for the `adeclick` audio effect.
///
/// Remove impulsive noise from input audio.
///
/// Samples detected as impulsive noise are replaced by interpolated samples using
/// autoregressive modelling.
///
/// Parameters:
/// - [a]: Set autoregression order, in percentage of window size. Allowed range is from `0` to `25`. Default value is `2` percent. This option also controls quality of interpolated samples using neighbour good samples. (range 0..25, default 2)
/// - [arorder]: Set autoregression order, in percentage of window size. Allowed range is from `0` to `25`. Default value is `2` percent. This option also controls quality of interpolated samples using neighbour good samples. (range 0..25, default 2)
/// - [b]: Set burst fusion, in percentage of window size. Allowed range is `0` to `10`. Default value is `2`. If any two samples detected as noise are spaced less than this value then any sample between those two samples will be also detected as noise. (range 0..10, default 2)
/// - [burst]: Set burst fusion, in percentage of window size. Allowed range is `0` to `10`. Default value is `2`. If any two samples detected as noise are spaced less than this value then any sample between those two samples will be also detected as noise. (range 0..10, default 2)
/// - [m]: Set overlap method.  It accepts the following values: (range 0..1, default 0)
/// - [method]: Set overlap method.  It accepts the following values: (range 0..1, default 0)
/// - [o]: Set window overlap, in percentage of window size. Allowed range is from `50` to `95`. Default value is `75` percent. Setting this to a very high value increases impulsive noise removal but makes whole process much slower. (range 50..95, default 75)
/// - [overlap]: Set window overlap, in percentage of window size. Allowed range is from `50` to `95`. Default value is `75` percent. Setting this to a very high value increases impulsive noise removal but makes whole process much slower. (range 50..95, default 75)
/// - [t]: Set threshold value. Allowed range is from `1` to `100`. Default value is `2`. This controls the strength of impulsive noise which is going to be removed. The lower value, the more samples will be detected as impulsive noise. (range 1..100, default 2)
/// - [threshold]: Set threshold value. Allowed range is from `1` to `100`. Default value is `2`. This controls the strength of impulsive noise which is going to be removed. The lower value, the more samples will be detected as impulsive noise. (range 1..100, default 2)
/// - [w]: Set window size, in milliseconds. Allowed range is from `10` to `100`. Default value is `55` milliseconds. This sets size of window which will be processed at once. (range 10..100, default 55)
/// - [window]: Set window size, in milliseconds. Allowed range is from `10` to `100`. Default value is `55` milliseconds. This sets size of window which will be processed at once. (range 10..100, default 55)
final class AdeclickSettings {
  /// Default value for [a].
  static const double aDefault = 2.0;

  /// Minimum value for [a].
  static const double aMin = 0.0;

  /// Maximum value for [a].
  static const double aMax = 25.0;

  /// Default value for [arorder].
  static const double arorderDefault = 2.0;

  /// Minimum value for [arorder].
  static const double arorderMin = 0.0;

  /// Maximum value for [arorder].
  static const double arorderMax = 25.0;

  /// Default value for [b].
  static const double bDefault = 2.0;

  /// Minimum value for [b].
  static const double bMin = 0.0;

  /// Maximum value for [b].
  static const double bMax = 10.0;

  /// Default value for [burst].
  static const double burstDefault = 2.0;

  /// Minimum value for [burst].
  static const double burstMin = 0.0;

  /// Maximum value for [burst].
  static const double burstMax = 10.0;

  /// Default value for [o].
  static const double oDefault = 75.0;

  /// Minimum value for [o].
  static const double oMin = 50.0;

  /// Maximum value for [o].
  static const double oMax = 95.0;

  /// Default value for [overlap].
  static const double overlapDefault = 75.0;

  /// Minimum value for [overlap].
  static const double overlapMin = 50.0;

  /// Maximum value for [overlap].
  static const double overlapMax = 95.0;

  /// Default value for [t].
  static const double tDefault = 2.0;

  /// Minimum value for [t].
  static const double tMin = 1.0;

  /// Maximum value for [t].
  static const double tMax = 100.0;

  /// Default value for [threshold].
  static const double thresholdDefault = 2.0;

  /// Minimum value for [threshold].
  static const double thresholdMin = 1.0;

  /// Maximum value for [threshold].
  static const double thresholdMax = 100.0;

  /// Default value for [w].
  static const double wDefault = 55.0;

  /// Minimum value for [w].
  static const double wMin = 10.0;

  /// Maximum value for [w].
  static const double wMax = 100.0;

  /// Default value for [window].
  static const double windowDefault = 55.0;

  /// Minimum value for [window].
  static const double windowMin = 10.0;

  /// Maximum value for [window].
  static const double windowMax = 100.0;

  /// Whether this effect is inserted into the audio chain.
  final bool enabled;

  /// set autoregression order
  final double a;

  /// set autoregression order
  final double arorder;

  /// set burst fusion
  final double b;

  /// set burst fusion
  final double burst;

  /// set overlap method
  final AdeclickM m;

  /// set overlap method
  final AdeclickM method;

  /// set window overlap
  final double o;

  /// set window overlap
  final double overlap;

  /// set threshold
  final double t;

  /// set threshold
  final double threshold;

  /// set window size
  final double w;

  /// set window size
  final double window;

  /// Creates an [AdeclickSettings] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default; the effect stays
  /// inactive until [enabled] is set to `true`.
  const AdeclickSettings({
    this.enabled = false,
    this.a = 2.0,
    this.arorder = 2.0,
    this.b = 2.0,
    this.burst = 2.0,
    this.m = AdeclickM.add,
    this.method = AdeclickM.add,
    this.o = 75.0,
    this.overlap = 75.0,
    this.t = 2.0,
    this.threshold = 2.0,
    this.w = 55.0,
    this.window = 55.0,
  });

  /// Returns a copy of this [AdeclickSettings] with the given fields replaced.
  AdeclickSettings copyWith({
    bool? enabled,
    double? a,
    double? arorder,
    double? b,
    double? burst,
    AdeclickM? m,
    AdeclickM? method,
    double? o,
    double? overlap,
    double? t,
    double? threshold,
    double? w,
    double? window,
  }) =>
      AdeclickSettings(
        enabled: enabled ?? this.enabled,
        a: a ?? this.a,
        arorder: arorder ?? this.arorder,
        b: b ?? this.b,
        burst: burst ?? this.burst,
        m: m ?? this.m,
        method: method ?? this.method,
        o: o ?? this.o,
        overlap: overlap ?? this.overlap,
        t: t ?? this.t,
        threshold: threshold ?? this.threshold,
        w: w ?? this.w,
        window: window ?? this.window,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AdeclickSettings &&
          other.enabled == enabled &&
          other.a == a &&
          other.arorder == arorder &&
          other.b == b &&
          other.burst == burst &&
          other.m == m &&
          other.method == method &&
          other.o == o &&
          other.overlap == overlap &&
          other.t == t &&
          other.threshold == threshold &&
          other.w == w &&
          other.window == window);

  @override
  int get hashCode => Object.hash(enabled, a, arorder, b, burst, m, method, o,
      overlap, t, threshold, w, window,);

  @override
  String toString() =>
      'AdeclickSettings(enabled: $enabled, a: $a, arorder: $arorder, b: $b, burst: $burst, m: $m, method: $method, o: $o, overlap: $overlap, t: $t, threshold: $threshold, w: $w, window: $window)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(a >= aMin, 'adeclick.a must be >= 0');
    assert(a <= aMax, 'adeclick.a must be <= 25');
    assert(arorder >= arorderMin, 'adeclick.arorder must be >= 0');
    assert(arorder <= arorderMax, 'adeclick.arorder must be <= 25');
    assert(b >= bMin, 'adeclick.b must be >= 0');
    assert(b <= bMax, 'adeclick.b must be <= 10');
    assert(burst >= burstMin, 'adeclick.burst must be >= 0');
    assert(burst <= burstMax, 'adeclick.burst must be <= 10');
    assert(o >= oMin, 'adeclick.o must be >= 50');
    assert(o <= oMax, 'adeclick.o must be <= 95');
    assert(overlap >= overlapMin, 'adeclick.overlap must be >= 50');
    assert(overlap <= overlapMax, 'adeclick.overlap must be <= 95');
    assert(t >= tMin, 'adeclick.t must be >= 1');
    assert(t <= tMax, 'adeclick.t must be <= 100');
    assert(threshold >= thresholdMin, 'adeclick.threshold must be >= 1');
    assert(threshold <= thresholdMax, 'adeclick.threshold must be <= 100');
    assert(w >= wMin, 'adeclick.w must be >= 10');
    assert(w <= wMax, 'adeclick.w must be <= 100');
    assert(window >= windowMin, 'adeclick.window must be >= 10');
    assert(window <= windowMax, 'adeclick.window must be <= 100');
    final parts = <String>[];
    if (a != 2.0) parts.add('a=' + _wireDouble(a));
    if (arorder != 2.0) parts.add('arorder=' + _wireDouble(arorder));
    if (b != 2.0) parts.add('b=' + _wireDouble(b));
    if (burst != 2.0) parts.add('burst=' + _wireDouble(burst));
    if (m != AdeclickM.add) parts.add('m=' + m.mpvValue);
    if (method != AdeclickM.add) parts.add('method=' + method.mpvValue);
    if (o != 75.0) parts.add('o=' + _wireDouble(o));
    if (overlap != 75.0) parts.add('overlap=' + _wireDouble(overlap));
    if (t != 2.0) parts.add('t=' + _wireDouble(t));
    if (threshold != 2.0) parts.add('threshold=' + _wireDouble(threshold));
    if (w != 55.0) parts.add('w=' + _wireDouble(w));
    if (window != 55.0) parts.add('window=' + _wireDouble(window));
    return parts.isEmpty
        ? 'lavfi-adeclick'
        : 'lavfi-adeclick=' + parts.join(':');
  }
}

/// Configuration for the `adeclip` audio effect.
///
/// Remove clipped samples from input audio.
///
/// Samples detected as clipped are replaced by interpolated samples using
/// autoregressive modelling.
///
/// Parameters:
/// - [a]: Set autoregression order, in percentage of window size. Allowed range is from `0` to `25`. Default value is `8` percent. This option also controls quality of interpolated samples using neighbour good samples. (range 0..25, default 8)
/// - [arorder]: Set autoregression order, in percentage of window size. Allowed range is from `0` to `25`. Default value is `8` percent. This option also controls quality of interpolated samples using neighbour good samples. (range 0..25, default 8)
/// - [hsize]: Set size of histogram used to detect clips. Allowed range is from `100` to `9999`. Default value is `1000`. Higher values make clip detection less aggressive. (range 100..9999, default 1000)
/// - [m]: Set overlap method.  It accepts the following values: (range 0..1, default 0)
/// - [method]: Set overlap method.  It accepts the following values: (range 0..1, default 0)
/// - [n]: Set size of histogram used to detect clips. Allowed range is from `100` to `9999`. Default value is `1000`. Higher values make clip detection less aggressive. (range 100..9999, default 1000)
/// - [o]: Set window overlap, in percentage of window size. Allowed range is from `50` to `95`. Default value is `75` percent. (range 50..95, default 75)
/// - [overlap]: Set window overlap, in percentage of window size. Allowed range is from `50` to `95`. Default value is `75` percent. (range 50..95, default 75)
/// - [t]: Set threshold value. Allowed range is from `1` to `100`. Default value is `10`. Higher values make clip detection less aggressive. (range 1..100, default 10)
/// - [threshold]: Set threshold value. Allowed range is from `1` to `100`. Default value is `10`. Higher values make clip detection less aggressive. (range 1..100, default 10)
/// - [w]: Set window size, in milliseconds. Allowed range is from `10` to `100`. Default value is `55` milliseconds. This sets size of window which will be processed at once. (range 10..100, default 55)
/// - [window]: Set window size, in milliseconds. Allowed range is from `10` to `100`. Default value is `55` milliseconds. This sets size of window which will be processed at once. (range 10..100, default 55)
final class AdeclipSettings {
  /// Default value for [a].
  static const double aDefault = 8.0;

  /// Minimum value for [a].
  static const double aMin = 0.0;

  /// Maximum value for [a].
  static const double aMax = 25.0;

  /// Default value for [arorder].
  static const double arorderDefault = 8.0;

  /// Minimum value for [arorder].
  static const double arorderMin = 0.0;

  /// Maximum value for [arorder].
  static const double arorderMax = 25.0;

  /// Default value for [hsize].
  static const int hsizeDefault = 1000;

  /// Minimum value for [hsize].
  static const int hsizeMin = 100;

  /// Maximum value for [hsize].
  static const int hsizeMax = 9999;

  /// Default value for [n].
  static const int nDefault = 1000;

  /// Minimum value for [n].
  static const int nMin = 100;

  /// Maximum value for [n].
  static const int nMax = 9999;

  /// Default value for [o].
  static const double oDefault = 75.0;

  /// Minimum value for [o].
  static const double oMin = 50.0;

  /// Maximum value for [o].
  static const double oMax = 95.0;

  /// Default value for [overlap].
  static const double overlapDefault = 75.0;

  /// Minimum value for [overlap].
  static const double overlapMin = 50.0;

  /// Maximum value for [overlap].
  static const double overlapMax = 95.0;

  /// Default value for [t].
  static const double tDefault = 10.0;

  /// Minimum value for [t].
  static const double tMin = 1.0;

  /// Maximum value for [t].
  static const double tMax = 100.0;

  /// Default value for [threshold].
  static const double thresholdDefault = 10.0;

  /// Minimum value for [threshold].
  static const double thresholdMin = 1.0;

  /// Maximum value for [threshold].
  static const double thresholdMax = 100.0;

  /// Default value for [w].
  static const double wDefault = 55.0;

  /// Minimum value for [w].
  static const double wMin = 10.0;

  /// Maximum value for [w].
  static const double wMax = 100.0;

  /// Default value for [window].
  static const double windowDefault = 55.0;

  /// Minimum value for [window].
  static const double windowMin = 10.0;

  /// Maximum value for [window].
  static const double windowMax = 100.0;

  /// Whether this effect is inserted into the audio chain.
  final bool enabled;

  /// set autoregression order
  final double a;

  /// set autoregression order
  final double arorder;

  /// set histogram size
  final int hsize;

  /// set overlap method
  final AdeclipM m;

  /// set overlap method
  final AdeclipM method;

  /// set histogram size
  final int n;

  /// set window overlap
  final double o;

  /// set window overlap
  final double overlap;

  /// set threshold
  final double t;

  /// set threshold
  final double threshold;

  /// set window size
  final double w;

  /// set window size
  final double window;

  /// Creates an [AdeclipSettings] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default; the effect stays
  /// inactive until [enabled] is set to `true`.
  const AdeclipSettings({
    this.enabled = false,
    this.a = 8.0,
    this.arorder = 8.0,
    this.hsize = 1000,
    this.m = AdeclipM.add,
    this.method = AdeclipM.add,
    this.n = 1000,
    this.o = 75.0,
    this.overlap = 75.0,
    this.t = 10.0,
    this.threshold = 10.0,
    this.w = 55.0,
    this.window = 55.0,
  });

  /// Returns a copy of this [AdeclipSettings] with the given fields replaced.
  AdeclipSettings copyWith({
    bool? enabled,
    double? a,
    double? arorder,
    int? hsize,
    AdeclipM? m,
    AdeclipM? method,
    int? n,
    double? o,
    double? overlap,
    double? t,
    double? threshold,
    double? w,
    double? window,
  }) =>
      AdeclipSettings(
        enabled: enabled ?? this.enabled,
        a: a ?? this.a,
        arorder: arorder ?? this.arorder,
        hsize: hsize ?? this.hsize,
        m: m ?? this.m,
        method: method ?? this.method,
        n: n ?? this.n,
        o: o ?? this.o,
        overlap: overlap ?? this.overlap,
        t: t ?? this.t,
        threshold: threshold ?? this.threshold,
        w: w ?? this.w,
        window: window ?? this.window,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AdeclipSettings &&
          other.enabled == enabled &&
          other.a == a &&
          other.arorder == arorder &&
          other.hsize == hsize &&
          other.m == m &&
          other.method == method &&
          other.n == n &&
          other.o == o &&
          other.overlap == overlap &&
          other.t == t &&
          other.threshold == threshold &&
          other.w == w &&
          other.window == window);

  @override
  int get hashCode => Object.hash(enabled, a, arorder, hsize, m, method, n, o,
      overlap, t, threshold, w, window,);

  @override
  String toString() =>
      'AdeclipSettings(enabled: $enabled, a: $a, arorder: $arorder, hsize: $hsize, m: $m, method: $method, n: $n, o: $o, overlap: $overlap, t: $t, threshold: $threshold, w: $w, window: $window)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(a >= aMin, 'adeclip.a must be >= 0');
    assert(a <= aMax, 'adeclip.a must be <= 25');
    assert(arorder >= arorderMin, 'adeclip.arorder must be >= 0');
    assert(arorder <= arorderMax, 'adeclip.arorder must be <= 25');
    assert(hsize >= hsizeMin, 'adeclip.hsize must be >= 100');
    assert(hsize <= hsizeMax, 'adeclip.hsize must be <= 9999');
    assert(n >= nMin, 'adeclip.n must be >= 100');
    assert(n <= nMax, 'adeclip.n must be <= 9999');
    assert(o >= oMin, 'adeclip.o must be >= 50');
    assert(o <= oMax, 'adeclip.o must be <= 95');
    assert(overlap >= overlapMin, 'adeclip.overlap must be >= 50');
    assert(overlap <= overlapMax, 'adeclip.overlap must be <= 95');
    assert(t >= tMin, 'adeclip.t must be >= 1');
    assert(t <= tMax, 'adeclip.t must be <= 100');
    assert(threshold >= thresholdMin, 'adeclip.threshold must be >= 1');
    assert(threshold <= thresholdMax, 'adeclip.threshold must be <= 100');
    assert(w >= wMin, 'adeclip.w must be >= 10');
    assert(w <= wMax, 'adeclip.w must be <= 100');
    assert(window >= windowMin, 'adeclip.window must be >= 10');
    assert(window <= windowMax, 'adeclip.window must be <= 100');
    final parts = <String>[];
    if (a != 8.0) parts.add('a=' + _wireDouble(a));
    if (arorder != 8.0) parts.add('arorder=' + _wireDouble(arorder));
    if (hsize != 1000) parts.add('hsize=' + hsize.toString());
    if (m != AdeclipM.add) parts.add('m=' + m.mpvValue);
    if (method != AdeclipM.add) parts.add('method=' + method.mpvValue);
    if (n != 1000) parts.add('n=' + n.toString());
    if (o != 75.0) parts.add('o=' + _wireDouble(o));
    if (overlap != 75.0) parts.add('overlap=' + _wireDouble(overlap));
    if (t != 10.0) parts.add('t=' + _wireDouble(t));
    if (threshold != 10.0) parts.add('threshold=' + _wireDouble(threshold));
    if (w != 55.0) parts.add('w=' + _wireDouble(w));
    if (window != 55.0) parts.add('window=' + _wireDouble(window));
    return parts.isEmpty ? 'lavfi-adeclip' : 'lavfi-adeclip=' + parts.join(':');
  }
}

/// Configuration for the `adecorrelate` audio effect.
///
/// Apply decorrelation to input audio stream.
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [seed]: Set random seed used for setting delay in samples across channels. (range -1..4294967295, default -1)
/// - [stages]: Set decorrelation stages of filtering. Allowed range is from 1 to 16. Default value is 6. (range 1..16, default 6)
final class AdecorrelateSettings {
  /// Default value for [seed].
  static const int seedDefault = -1;

  /// Minimum value for [seed].
  static const int seedMin = -1;

  /// Maximum value for [seed].
  static const int seedMax = 4294967295;

  /// Default value for [stages].
  static const int stagesDefault = 6;

  /// Minimum value for [stages].
  static const int stagesMin = 1;

  /// Maximum value for [stages].
  static const int stagesMax = 16;

  /// Whether this effect is inserted into the audio chain.
  final bool enabled;

  /// set random seed
  final int seed;

  /// set filtering stages
  final int stages;

  /// Creates an [AdecorrelateSettings] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default; the effect stays
  /// inactive until [enabled] is set to `true`.
  const AdecorrelateSettings({
    this.enabled = false,
    this.seed = -1,
    this.stages = 6,
  });

  /// Returns a copy of this [AdecorrelateSettings] with the given fields replaced.
  AdecorrelateSettings copyWith({
    bool? enabled,
    int? seed,
    int? stages,
  }) =>
      AdecorrelateSettings(
        enabled: enabled ?? this.enabled,
        seed: seed ?? this.seed,
        stages: stages ?? this.stages,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AdecorrelateSettings &&
          other.enabled == enabled &&
          other.seed == seed &&
          other.stages == stages);

  @override
  int get hashCode => Object.hash(enabled, seed, stages);

  @override
  String toString() =>
      'AdecorrelateSettings(enabled: $enabled, seed: $seed, stages: $stages)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(seed >= seedMin, 'adecorrelate.seed must be >= -1');
    assert(seed <= seedMax, 'adecorrelate.seed must be <= 4294967295');
    assert(stages >= stagesMin, 'adecorrelate.stages must be >= 1');
    assert(stages <= stagesMax, 'adecorrelate.stages must be <= 16');
    final parts = <String>[];
    if (seed != -1) parts.add('seed=' + seed.toString());
    if (stages != 6) parts.add('stages=' + stages.toString());
    return parts.isEmpty
        ? 'lavfi-adecorrelate'
        : 'lavfi-adecorrelate=' + parts.join(':');
  }
}

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
/// - [delays]: Set list of delays in milliseconds for each channel separated by '|'. Unused delays will be silently ignored. If number of given delays is smaller than number of channels all remaining channels will not be delayed. If you want to delay exact number of samples, append 'S' to number. If you want instead to delay in seconds, append 's' to number. (range 0..0, default "", runtime-tunable)
final class AdelaySettings {
  /// Whether this effect is inserted into the audio chain.
  final bool enabled;

  /// use last available delay for remained channels
  final bool all;

  /// set list of delays for each channel
  final String delays;

  /// Creates an [AdelaySettings] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default; the effect stays
  /// inactive until [enabled] is set to `true`.
  const AdelaySettings({
    this.enabled = false,
    this.all = false,
    this.delays = '',
  });

  /// Returns a copy of this [AdelaySettings] with the given fields replaced.
  AdelaySettings copyWith({
    bool? enabled,
    bool? all,
    String? delays,
  }) =>
      AdelaySettings(
        enabled: enabled ?? this.enabled,
        all: all ?? this.all,
        delays: delays ?? this.delays,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AdelaySettings &&
          other.enabled == enabled &&
          other.all == all &&
          other.delays == delays);

  @override
  int get hashCode => Object.hash(enabled, all, delays);

  @override
  String toString() =>
      'AdelaySettings(enabled: $enabled, all: $all, delays: $delays)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    final parts = <String>[];
    if (all != false) parts.add('all=' + (all ? '1' : '0'));
    if (delays != '') parts.add('delays=' + '[' + delays + ']');
    return parts.isEmpty ? 'lavfi-adelay' : 'lavfi-adelay=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  List<(String, String)>? _runtimeDiff(AdelaySettings prev) {
    final out = <(String, String)>[];
    if (all != prev.all) return null;
    if (delays != prev.delays) {
      out.add(('delays', delays));
    }
    return out;
  }
}

/// Configuration for the `adenorm` audio effect.
///
/// Remedy denormals in audio by adding extremely low-level noise.
///
/// This filter shall be placed before any filter that can produce denormals.
///
/// A description of the accepted parameters follows.
///
/// Parameters:
/// - [level]: Set level of added noise in dB. Default is `-351`. Allowed range is from -451 to -90. (range -451..-90, default -351, runtime-tunable)
/// - [type]: Set type of added noise. (range 0..3, default DC_TYPE, runtime-tunable)
final class AdenormSettings {
  /// Default value for [level].
  static const double levelDefault = -351.0;

  /// Minimum value for [level].
  static const double levelMin = -451.0;

  /// Maximum value for [level].
  static const double levelMax = -90.0;

  /// Whether this effect is inserted into the audio chain.
  final bool enabled;

  /// set level
  final double level;

  /// set type
  final AdenormType type;

  /// Creates an [AdenormSettings] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default; the effect stays
  /// inactive until [enabled] is set to `true`.
  const AdenormSettings({
    this.enabled = false,
    this.level = -351.0,
    this.type = AdenormType.dc,
  });

  /// Returns a copy of this [AdenormSettings] with the given fields replaced.
  AdenormSettings copyWith({
    bool? enabled,
    double? level,
    AdenormType? type,
  }) =>
      AdenormSettings(
        enabled: enabled ?? this.enabled,
        level: level ?? this.level,
        type: type ?? this.type,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AdenormSettings &&
          other.enabled == enabled &&
          other.level == level &&
          other.type == type);

  @override
  int get hashCode => Object.hash(enabled, level, type);

  @override
  String toString() =>
      'AdenormSettings(enabled: $enabled, level: $level, type: $type)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(level >= levelMin, 'adenorm.level must be >= -451');
    assert(level <= levelMax, 'adenorm.level must be <= -90');
    final parts = <String>[];
    if (level != -351.0) parts.add('level=' + _wireDouble(level));
    if (type != AdenormType.dc) parts.add('type=' + type.mpvValue);
    return parts.isEmpty ? 'lavfi-adenorm' : 'lavfi-adenorm=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  List<(String, String)>? _runtimeDiff(AdenormSettings prev) {
    final out = <(String, String)>[];
    if (level != prev.level) {
      out.add(('level', _wireDouble(level)));
    }
    if (type != prev.type) {
      out.add(('type', type.mpvValue));
    }
    return out;
  }
}

/// Configuration for the `aderivative` audio effect.
///
/// Compute derivative/integral of audio stream.
///
/// Applying both filters one after another produces original audio.
final class AderivativeSettings {
  /// Whether this effect is inserted into the audio chain.
  final bool enabled;

  /// Creates an [AderivativeSettings] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default; the effect stays
  /// inactive until [enabled] is set to `true`.
  const AderivativeSettings({
    this.enabled = false,
  });

  /// Returns a copy of this [AderivativeSettings] with the given fields replaced.
  AderivativeSettings copyWith({
    bool? enabled,
  }) =>
      AderivativeSettings(
        enabled: enabled ?? this.enabled,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AderivativeSettings && other.enabled == enabled);

  @override
  int get hashCode => enabled.hashCode;

  @override
  String toString() => 'AderivativeSettings(enabled: $enabled)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    return 'lavfi-aderivative';
  }
}

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
final class AdrcSettings {
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

  /// Whether this effect is inserted into the audio chain.
  final bool enabled;

  /// set the attack
  final double attack;

  /// set channels to filter
  final String channels;

  /// set the release
  final double release;

  /// set the transfer expression
  final String transfer;

  /// Creates an [AdrcSettings] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default; the effect stays
  /// inactive until [enabled] is set to `true`.
  const AdrcSettings({
    this.enabled = false,
    this.attack = 50.0,
    this.channels = 'all',
    this.release = 100.0,
    this.transfer = 'p',
  });

  /// Returns a copy of this [AdrcSettings] with the given fields replaced.
  AdrcSettings copyWith({
    bool? enabled,
    double? attack,
    String? channels,
    double? release,
    String? transfer,
  }) =>
      AdrcSettings(
        enabled: enabled ?? this.enabled,
        attack: attack ?? this.attack,
        channels: channels ?? this.channels,
        release: release ?? this.release,
        transfer: transfer ?? this.transfer,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AdrcSettings &&
          other.enabled == enabled &&
          other.attack == attack &&
          other.channels == channels &&
          other.release == release &&
          other.transfer == transfer);

  @override
  int get hashCode => Object.hash(enabled, attack, channels, release, transfer);

  @override
  String toString() =>
      'AdrcSettings(enabled: $enabled, attack: $attack, channels: $channels, release: $release, transfer: $transfer)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(attack >= attackMin, 'adrc.attack must be >= 1');
    assert(attack <= attackMax, 'adrc.attack must be <= 1000');
    assert(release >= releaseMin, 'adrc.release must be >= 5');
    assert(release <= releaseMax, 'adrc.release must be <= 2000');
    final parts = <String>[];
    if (attack != 50.0) parts.add('attack=' + _wireDouble(attack));
    if (channels != 'all') parts.add('channels=' + '[' + channels + ']');
    if (release != 100.0) parts.add('release=' + _wireDouble(release));
    if (transfer != 'p') parts.add('transfer=' + '[' + transfer + ']');
    return parts.isEmpty ? 'lavfi-adrc' : 'lavfi-adrc=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  List<(String, String)>? _runtimeDiff(AdrcSettings prev) {
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

/// Configuration for the `adynamicequalizer` audio effect.
///
/// Apply dynamic equalization to input audio stream.
///
/// A description of the accepted options follows.
///
/// Parameters:
/// - [attack]: Set the amount of milliseconds the signal from detection has to rise above the detection threshold before equalization starts. Default is 20. Allowed range is between 1 and 2000. (range 0.01..2000, default 20, runtime-tunable)
/// - [auto]: set auto threshold (range 1..4, default DET_OFF, runtime-tunable)
/// - [dfrequency]: Set the detection frequency in Hz used for detection filter used to trigger equalization. Default value is 1000 Hz. Allowed range is between 2 and 1000000 Hz. (range 2..1000000, default 1000, runtime-tunable)
/// - [dftype]: set detection filter type (range 0..3, default 0, runtime-tunable)
/// - [dqfactor]: Set the detection resonance factor for detection filter used to trigger equalization. Default value is 1. Allowed range is from 0.001 to 1000. (range 0.001..1000, default 1, runtime-tunable)
/// - [makeup]: Set the makeup offset by which the equalization gain is raised. Default is 0. Allowed range is between 0 and 100. (range 0..1000, default 0, runtime-tunable)
/// - [mode]: Set the mode of filter operation, can be one of the following: (range -1..3, default 0, runtime-tunable)
/// - [precision]: set processing precision (range 0..2, default 0)
/// - [range]: Set the max allowed cut/boost amount. Default is 50. Allowed range is from 1 to 200. (range 1..2000, default 50, runtime-tunable)
/// - [ratio]: Set the ratio by which the equalization gain is raised. Default is 1. Allowed range is between 0 and 30. (range 0..30, default 1, runtime-tunable)
/// - [release]: Set the amount of milliseconds the signal from detection has to fall below the detection threshold before equalization ends. Default is 200. Allowed range is between 1 and 2000. (range 0.01..2000, default 200, runtime-tunable)
/// - [tfrequency]: Set the target frequency of equalization filter. Default value is 1000 Hz. Allowed range is between 2 and 1000000 Hz. (range 2..1000000, default 1000, runtime-tunable)
/// - [tftype]: set target filter type (range 0..2, default 0, runtime-tunable)
/// - [threshold]: Set the detection threshold used to trigger equalization. Threshold detection is using detection filter. Default value is 0. Allowed range is from 0 to 100. (range 0..100, default 0, runtime-tunable)
/// - [tqfactor]: Set the target resonance factor for target equalization filter. Default value is 1. Allowed range is from 0.001 to 1000. (range 0.001..1000, default 1, runtime-tunable)
final class AdynamicequalizerSettings {
  /// Default value for [attack].
  static const double attackDefault = 20.0;

  /// Minimum value for [attack].
  static const double attackMin = 0.01;

  /// Maximum value for [attack].
  static const double attackMax = 2000.0;

  /// Default value for [dfrequency].
  static const double dfrequencyDefault = 1000.0;

  /// Minimum value for [dfrequency].
  static const double dfrequencyMin = 2.0;

  /// Maximum value for [dfrequency].
  static const double dfrequencyMax = 1000000.0;

  /// Default value for [dqfactor].
  static const double dqfactorDefault = 1.0;

  /// Minimum value for [dqfactor].
  static const double dqfactorMin = 0.001;

  /// Maximum value for [dqfactor].
  static const double dqfactorMax = 1000.0;

  /// Default value for [makeup].
  static const double makeupDefault = 0.0;

  /// Minimum value for [makeup].
  static const double makeupMin = 0.0;

  /// Maximum value for [makeup].
  static const double makeupMax = 1000.0;

  /// Default value for [range].
  static const double rangeDefault = 50.0;

  /// Minimum value for [range].
  static const double rangeMin = 1.0;

  /// Maximum value for [range].
  static const double rangeMax = 2000.0;

  /// Default value for [ratio].
  static const double ratioDefault = 1.0;

  /// Minimum value for [ratio].
  static const double ratioMin = 0.0;

  /// Maximum value for [ratio].
  static const double ratioMax = 30.0;

  /// Default value for [release].
  static const double releaseDefault = 200.0;

  /// Minimum value for [release].
  static const double releaseMin = 0.01;

  /// Maximum value for [release].
  static const double releaseMax = 2000.0;

  /// Default value for [tfrequency].
  static const double tfrequencyDefault = 1000.0;

  /// Minimum value for [tfrequency].
  static const double tfrequencyMin = 2.0;

  /// Maximum value for [tfrequency].
  static const double tfrequencyMax = 1000000.0;

  /// Default value for [threshold].
  static const double thresholdDefault = 0.0;

  /// Minimum value for [threshold].
  static const double thresholdMin = 0.0;

  /// Maximum value for [threshold].
  static const double thresholdMax = 100.0;

  /// Default value for [tqfactor].
  static const double tqfactorDefault = 1.0;

  /// Minimum value for [tqfactor].
  static const double tqfactorMin = 0.001;

  /// Maximum value for [tqfactor].
  static const double tqfactorMax = 1000.0;

  /// Whether this effect is inserted into the audio chain.
  final bool enabled;

  /// set detection attack duration
  final double attack;

  /// set auto threshold
  final AdynamicequalizerAuto auto;

  /// set detection frequency
  final double dfrequency;

  /// set detection filter type
  final AdynamicequalizerDftype dftype;

  /// set detection Q factor
  final double dqfactor;

  /// set makeup gain
  final double makeup;

  /// set mode
  final AdynamicequalizerMode mode;

  /// set processing precision
  final AdynamicequalizerPrecision precision;

  /// set max gain
  final double range;

  /// set ratio factor
  final double ratio;

  /// set detection release duration
  final double release;

  /// set target frequency
  final double tfrequency;

  /// set target filter type
  final AdynamicequalizerTftype tftype;

  /// set detection threshold
  final double threshold;

  /// set target Q factor
  final double tqfactor;

  /// Creates an [AdynamicequalizerSettings] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default; the effect stays
  /// inactive until [enabled] is set to `true`.
  const AdynamicequalizerSettings({
    this.enabled = false,
    this.attack = 20.0,
    this.auto = AdynamicequalizerAuto.off,
    this.dfrequency = 1000.0,
    this.dftype = AdynamicequalizerDftype.bandpass,
    this.dqfactor = 1.0,
    this.makeup = 0.0,
    this.mode = AdynamicequalizerMode.listen,
    this.precision = AdynamicequalizerPrecision.auto,
    this.range = 50.0,
    this.ratio = 1.0,
    this.release = 200.0,
    this.tfrequency = 1000.0,
    this.tftype = AdynamicequalizerTftype.bell,
    this.threshold = 0.0,
    this.tqfactor = 1.0,
  });

  /// Returns a copy of this [AdynamicequalizerSettings] with the given fields replaced.
  AdynamicequalizerSettings copyWith({
    bool? enabled,
    double? attack,
    AdynamicequalizerAuto? auto,
    double? dfrequency,
    AdynamicequalizerDftype? dftype,
    double? dqfactor,
    double? makeup,
    AdynamicequalizerMode? mode,
    AdynamicequalizerPrecision? precision,
    double? range,
    double? ratio,
    double? release,
    double? tfrequency,
    AdynamicequalizerTftype? tftype,
    double? threshold,
    double? tqfactor,
  }) =>
      AdynamicequalizerSettings(
        enabled: enabled ?? this.enabled,
        attack: attack ?? this.attack,
        auto: auto ?? this.auto,
        dfrequency: dfrequency ?? this.dfrequency,
        dftype: dftype ?? this.dftype,
        dqfactor: dqfactor ?? this.dqfactor,
        makeup: makeup ?? this.makeup,
        mode: mode ?? this.mode,
        precision: precision ?? this.precision,
        range: range ?? this.range,
        ratio: ratio ?? this.ratio,
        release: release ?? this.release,
        tfrequency: tfrequency ?? this.tfrequency,
        tftype: tftype ?? this.tftype,
        threshold: threshold ?? this.threshold,
        tqfactor: tqfactor ?? this.tqfactor,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AdynamicequalizerSettings &&
          other.enabled == enabled &&
          other.attack == attack &&
          other.auto == auto &&
          other.dfrequency == dfrequency &&
          other.dftype == dftype &&
          other.dqfactor == dqfactor &&
          other.makeup == makeup &&
          other.mode == mode &&
          other.precision == precision &&
          other.range == range &&
          other.ratio == ratio &&
          other.release == release &&
          other.tfrequency == tfrequency &&
          other.tftype == tftype &&
          other.threshold == threshold &&
          other.tqfactor == tqfactor);

  @override
  int get hashCode => Object.hash(
      enabled,
      attack,
      auto,
      dfrequency,
      dftype,
      dqfactor,
      makeup,
      mode,
      precision,
      range,
      ratio,
      release,
      tfrequency,
      tftype,
      threshold,
      tqfactor,);

  @override
  String toString() =>
      'AdynamicequalizerSettings(enabled: $enabled, attack: $attack, auto: $auto, dfrequency: $dfrequency, dftype: $dftype, dqfactor: $dqfactor, makeup: $makeup, mode: $mode, precision: $precision, range: $range, ratio: $ratio, release: $release, tfrequency: $tfrequency, tftype: $tftype, threshold: $threshold, tqfactor: $tqfactor)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(attack >= attackMin, 'adynamicequalizer.attack must be >= 0.01');
    assert(attack <= attackMax, 'adynamicequalizer.attack must be <= 2000');
    assert(dfrequency >= dfrequencyMin,
        'adynamicequalizer.dfrequency must be >= 2',);
    assert(dfrequency <= dfrequencyMax,
        'adynamicequalizer.dfrequency must be <= 1000000',);
    assert(
        dqfactor >= dqfactorMin, 'adynamicequalizer.dqfactor must be >= 0.001',);
    assert(
        dqfactor <= dqfactorMax, 'adynamicequalizer.dqfactor must be <= 1000',);
    assert(makeup >= makeupMin, 'adynamicequalizer.makeup must be >= 0');
    assert(makeup <= makeupMax, 'adynamicequalizer.makeup must be <= 1000');
    assert(range >= rangeMin, 'adynamicequalizer.range must be >= 1');
    assert(range <= rangeMax, 'adynamicequalizer.range must be <= 2000');
    assert(ratio >= ratioMin, 'adynamicequalizer.ratio must be >= 0');
    assert(ratio <= ratioMax, 'adynamicequalizer.ratio must be <= 30');
    assert(release >= releaseMin, 'adynamicequalizer.release must be >= 0.01');
    assert(release <= releaseMax, 'adynamicequalizer.release must be <= 2000');
    assert(tfrequency >= tfrequencyMin,
        'adynamicequalizer.tfrequency must be >= 2',);
    assert(tfrequency <= tfrequencyMax,
        'adynamicequalizer.tfrequency must be <= 1000000',);
    assert(
        threshold >= thresholdMin, 'adynamicequalizer.threshold must be >= 0',);
    assert(threshold <= thresholdMax,
        'adynamicequalizer.threshold must be <= 100',);
    assert(
        tqfactor >= tqfactorMin, 'adynamicequalizer.tqfactor must be >= 0.001',);
    assert(
        tqfactor <= tqfactorMax, 'adynamicequalizer.tqfactor must be <= 1000',);
    final parts = <String>[];
    if (attack != 20.0) parts.add('attack=' + _wireDouble(attack));
    if (auto != AdynamicequalizerAuto.off) parts.add('auto=' + auto.mpvValue);
    if (dfrequency != 1000.0)
      parts.add('dfrequency=' + _wireDouble(dfrequency));
    if (dftype != AdynamicequalizerDftype.bandpass)
      parts.add('dftype=' + dftype.mpvValue);
    if (dqfactor != 1.0) parts.add('dqfactor=' + _wireDouble(dqfactor));
    if (makeup != 0.0) parts.add('makeup=' + _wireDouble(makeup));
    if (mode != AdynamicequalizerMode.listen)
      parts.add('mode=' + mode.mpvValue);
    if (precision != AdynamicequalizerPrecision.auto)
      parts.add('precision=' + precision.mpvValue);
    if (range != 50.0) parts.add('range=' + _wireDouble(range));
    if (ratio != 1.0) parts.add('ratio=' + _wireDouble(ratio));
    if (release != 200.0) parts.add('release=' + _wireDouble(release));
    if (tfrequency != 1000.0)
      parts.add('tfrequency=' + _wireDouble(tfrequency));
    if (tftype != AdynamicequalizerTftype.bell)
      parts.add('tftype=' + tftype.mpvValue);
    if (threshold != 0.0) parts.add('threshold=' + _wireDouble(threshold));
    if (tqfactor != 1.0) parts.add('tqfactor=' + _wireDouble(tqfactor));
    return parts.isEmpty
        ? 'lavfi-adynamicequalizer'
        : 'lavfi-adynamicequalizer=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  List<(String, String)>? _runtimeDiff(AdynamicequalizerSettings prev) {
    final out = <(String, String)>[];
    if (attack != prev.attack) {
      out.add(('attack', _wireDouble(attack)));
    }
    if (auto != prev.auto) {
      out.add(('auto', auto.mpvValue));
    }
    if (dfrequency != prev.dfrequency) {
      out.add(('dfrequency', _wireDouble(dfrequency)));
    }
    if (dftype != prev.dftype) {
      out.add(('dftype', dftype.mpvValue));
    }
    if (dqfactor != prev.dqfactor) {
      out.add(('dqfactor', _wireDouble(dqfactor)));
    }
    if (makeup != prev.makeup) {
      out.add(('makeup', _wireDouble(makeup)));
    }
    if (mode != prev.mode) {
      out.add(('mode', mode.mpvValue));
    }
    if (precision != prev.precision) return null;
    if (range != prev.range) {
      out.add(('range', _wireDouble(range)));
    }
    if (ratio != prev.ratio) {
      out.add(('ratio', _wireDouble(ratio)));
    }
    if (release != prev.release) {
      out.add(('release', _wireDouble(release)));
    }
    if (tfrequency != prev.tfrequency) {
      out.add(('tfrequency', _wireDouble(tfrequency)));
    }
    if (tftype != prev.tftype) {
      out.add(('tftype', tftype.mpvValue));
    }
    if (threshold != prev.threshold) {
      out.add(('threshold', _wireDouble(threshold)));
    }
    if (tqfactor != prev.tqfactor) {
      out.add(('tqfactor', _wireDouble(tqfactor)));
    }
    return out;
  }
}

/// Configuration for the `adynamicsmooth` audio effect.
///
/// Apply dynamic smoothing to input audio stream.
///
/// A description of the accepted options follows.
///
/// Parameters:
/// - [basefreq]: Set a base frequency for smoothing. Default value is 22050. Allowed range is from 2 to 1e+06. (range 2..1000000, default 22050, runtime-tunable)
/// - [sensitivity]: Set an amount of sensitivity to frequency fluctations. Default is 2. Allowed range is from 0 to 1e+06. (range 0..1000000, default 2, runtime-tunable)
final class AdynamicsmoothSettings {
  /// Default value for [basefreq].
  static const double basefreqDefault = 22050.0;

  /// Minimum value for [basefreq].
  static const double basefreqMin = 2.0;

  /// Maximum value for [basefreq].
  static const double basefreqMax = 1000000.0;

  /// Default value for [sensitivity].
  static const double sensitivityDefault = 2.0;

  /// Minimum value for [sensitivity].
  static const double sensitivityMin = 0.0;

  /// Maximum value for [sensitivity].
  static const double sensitivityMax = 1000000.0;

  /// Whether this effect is inserted into the audio chain.
  final bool enabled;

  /// set base frequency
  final double basefreq;

  /// set smooth sensitivity
  final double sensitivity;

  /// Creates an [AdynamicsmoothSettings] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default; the effect stays
  /// inactive until [enabled] is set to `true`.
  const AdynamicsmoothSettings({
    this.enabled = false,
    this.basefreq = 22050.0,
    this.sensitivity = 2.0,
  });

  /// Returns a copy of this [AdynamicsmoothSettings] with the given fields replaced.
  AdynamicsmoothSettings copyWith({
    bool? enabled,
    double? basefreq,
    double? sensitivity,
  }) =>
      AdynamicsmoothSettings(
        enabled: enabled ?? this.enabled,
        basefreq: basefreq ?? this.basefreq,
        sensitivity: sensitivity ?? this.sensitivity,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AdynamicsmoothSettings &&
          other.enabled == enabled &&
          other.basefreq == basefreq &&
          other.sensitivity == sensitivity);

  @override
  int get hashCode => Object.hash(enabled, basefreq, sensitivity);

  @override
  String toString() =>
      'AdynamicsmoothSettings(enabled: $enabled, basefreq: $basefreq, sensitivity: $sensitivity)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(basefreq >= basefreqMin, 'adynamicsmooth.basefreq must be >= 2');
    assert(
        basefreq <= basefreqMax, 'adynamicsmooth.basefreq must be <= 1000000',);
    assert(sensitivity >= sensitivityMin,
        'adynamicsmooth.sensitivity must be >= 0',);
    assert(sensitivity <= sensitivityMax,
        'adynamicsmooth.sensitivity must be <= 1000000',);
    final parts = <String>[];
    if (basefreq != 22050.0) parts.add('basefreq=' + _wireDouble(basefreq));
    if (sensitivity != 2.0)
      parts.add('sensitivity=' + _wireDouble(sensitivity));
    return parts.isEmpty
        ? 'lavfi-adynamicsmooth'
        : 'lavfi-adynamicsmooth=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  List<(String, String)>? _runtimeDiff(AdynamicsmoothSettings prev) {
    final out = <(String, String)>[];
    if (basefreq != prev.basefreq) {
      out.add(('basefreq', _wireDouble(basefreq)));
    }
    if (sensitivity != prev.sensitivity) {
      out.add(('sensitivity', _wireDouble(sensitivity)));
    }
    return out;
  }
}

/// Configuration for the `aecho` audio effect.
///
/// Apply echoing to the input audio.
///
/// Echoes are reflected sound and can occur naturally amongst mountains
/// (and sometimes large buildings) when talking or shouting; digital echo
/// effects emulate this behaviour and are often used to help fill out the
/// sound of a single instrument or vocal. The time difference between the
/// original signal and the reflection is the `delay`, and the
/// loudness of the reflected signal is the `decay`.
/// Multiple echoes can have different delays and decays.
///
/// A description of the accepted parameters follows.
///
/// Parameters:
/// - [decays]: Set list of loudness of reflected signals separated by '|'. Allowed range for each `decay` is `(0 - 1.0]`. Default is `0.5`. (range 0..0, default "0.5")
/// - [delays]: Set list of time intervals in milliseconds between original signal and reflections separated by '|'. Allowed range for each `delay` is `(0 - 90000.0]`. Default is `1000`. (range 0..0, default "1000")
/// - [in_gain]: Set input gain of reflected signal. Default is `0.6`. (range 0..1, default 0.6)
/// - [out_gain]: Set output gain of reflected signal. Default is `0.3`. (range 0..1, default 0.3)
final class AechoSettings {
  /// Default value for [in_gain].
  static const double in_gainDefault = 0.6;

  /// Minimum value for [in_gain].
  static const double in_gainMin = 0.0;

  /// Maximum value for [in_gain].
  static const double in_gainMax = 1.0;

  /// Default value for [out_gain].
  static const double out_gainDefault = 0.3;

  /// Minimum value for [out_gain].
  static const double out_gainMin = 0.0;

  /// Maximum value for [out_gain].
  static const double out_gainMax = 1.0;

  /// Whether this effect is inserted into the audio chain.
  final bool enabled;

  /// set list of signal decays
  final String decays;

  /// set list of signal delays
  final String delays;

  /// set signal input gain
  final double in_gain;

  /// set signal output gain
  final double out_gain;

  /// Creates an [AechoSettings] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default; the effect stays
  /// inactive until [enabled] is set to `true`.
  const AechoSettings({
    this.enabled = false,
    this.decays = '0.5',
    this.delays = '1000',
    this.in_gain = 0.6,
    this.out_gain = 0.3,
  });

  /// Returns a copy of this [AechoSettings] with the given fields replaced.
  AechoSettings copyWith({
    bool? enabled,
    String? decays,
    String? delays,
    double? in_gain,
    double? out_gain,
  }) =>
      AechoSettings(
        enabled: enabled ?? this.enabled,
        decays: decays ?? this.decays,
        delays: delays ?? this.delays,
        in_gain: in_gain ?? this.in_gain,
        out_gain: out_gain ?? this.out_gain,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AechoSettings &&
          other.enabled == enabled &&
          other.decays == decays &&
          other.delays == delays &&
          other.in_gain == in_gain &&
          other.out_gain == out_gain);

  @override
  int get hashCode => Object.hash(enabled, decays, delays, in_gain, out_gain);

  @override
  String toString() =>
      'AechoSettings(enabled: $enabled, decays: $decays, delays: $delays, in_gain: $in_gain, out_gain: $out_gain)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(in_gain >= in_gainMin, 'aecho.in_gain must be >= 0');
    assert(in_gain <= in_gainMax, 'aecho.in_gain must be <= 1');
    assert(out_gain >= out_gainMin, 'aecho.out_gain must be >= 0');
    assert(out_gain <= out_gainMax, 'aecho.out_gain must be <= 1');
    final parts = <String>[];
    if (decays != '0.5') parts.add('decays=' + '[' + decays + ']');
    if (delays != '1000') parts.add('delays=' + '[' + delays + ']');
    if (in_gain != 0.6) parts.add('in_gain=' + _wireDouble(in_gain));
    if (out_gain != 0.3) parts.add('out_gain=' + _wireDouble(out_gain));
    return parts.isEmpty ? 'lavfi-aecho' : 'lavfi-aecho=' + parts.join(':');
  }
}

/// Configuration for the `aemphasis` audio effect.
///
/// Audio emphasis filter creates or restores material directly taken from LPs or
/// emphased CDs with different filter curves. E.g. to store music on vinyl the
/// signal has to be altered by a filter first to even out the disadvantages of
/// this recording medium.
/// Once the material is played back the inverse filter has to be applied to
/// restore the distortion of the frequency response.
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [level_in]: Set input gain. (range 0..64, default 1, runtime-tunable)
/// - [level_out]: Set output gain. (range 0..64, default 1, runtime-tunable)
/// - [mode]: Set filter mode. For restoring material use `reproduction` mode, otherwise use `production` mode. Default is `reproduction` mode. (range 0..1, default 0, runtime-tunable)
/// - [type]: Set filter type. Selects medium. Can be one of the following: (range 0..8, default 4, runtime-tunable)
final class AemphasisSettings {
  /// Default value for [level_in].
  static const double level_inDefault = 1.0;

  /// Minimum value for [level_in].
  static const double level_inMin = 0.0;

  /// Maximum value for [level_in].
  static const double level_inMax = 64.0;

  /// Default value for [level_out].
  static const double level_outDefault = 1.0;

  /// Minimum value for [level_out].
  static const double level_outMin = 0.0;

  /// Maximum value for [level_out].
  static const double level_outMax = 64.0;

  /// Whether this effect is inserted into the audio chain.
  final bool enabled;

  /// set input gain
  final double level_in;

  /// set output gain
  final double level_out;

  /// set filter mode
  final AemphasisMode mode;

  /// set filter type
  final AemphasisType type;

  /// Creates an [AemphasisSettings] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default; the effect stays
  /// inactive until [enabled] is set to `true`.
  const AemphasisSettings({
    this.enabled = false,
    this.level_in = 1.0,
    this.level_out = 1.0,
    this.mode = AemphasisMode.reproduction,
    this.type = AemphasisType.cd,
  });

  /// Returns a copy of this [AemphasisSettings] with the given fields replaced.
  AemphasisSettings copyWith({
    bool? enabled,
    double? level_in,
    double? level_out,
    AemphasisMode? mode,
    AemphasisType? type,
  }) =>
      AemphasisSettings(
        enabled: enabled ?? this.enabled,
        level_in: level_in ?? this.level_in,
        level_out: level_out ?? this.level_out,
        mode: mode ?? this.mode,
        type: type ?? this.type,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AemphasisSettings &&
          other.enabled == enabled &&
          other.level_in == level_in &&
          other.level_out == level_out &&
          other.mode == mode &&
          other.type == type);

  @override
  int get hashCode => Object.hash(enabled, level_in, level_out, mode, type);

  @override
  String toString() =>
      'AemphasisSettings(enabled: $enabled, level_in: $level_in, level_out: $level_out, mode: $mode, type: $type)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(level_in >= level_inMin, 'aemphasis.level_in must be >= 0');
    assert(level_in <= level_inMax, 'aemphasis.level_in must be <= 64');
    assert(level_out >= level_outMin, 'aemphasis.level_out must be >= 0');
    assert(level_out <= level_outMax, 'aemphasis.level_out must be <= 64');
    final parts = <String>[];
    if (level_in != 1.0) parts.add('level_in=' + _wireDouble(level_in));
    if (level_out != 1.0) parts.add('level_out=' + _wireDouble(level_out));
    if (mode != AemphasisMode.reproduction) parts.add('mode=' + mode.mpvValue);
    if (type != AemphasisType.cd) parts.add('type=' + type.mpvValue);
    return parts.isEmpty
        ? 'lavfi-aemphasis'
        : 'lavfi-aemphasis=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  List<(String, String)>? _runtimeDiff(AemphasisSettings prev) {
    final out = <(String, String)>[];
    if (level_in != prev.level_in) {
      out.add(('level_in', _wireDouble(level_in)));
    }
    if (level_out != prev.level_out) {
      out.add(('level_out', _wireDouble(level_out)));
    }
    if (mode != prev.mode) {
      out.add(('mode', mode.mpvValue));
    }
    if (type != prev.type) {
      out.add(('type', type.mpvValue));
    }
    return out;
  }
}

/// Configuration for the `aeval` audio effect.
///
/// Modify an audio signal according to the specified expressions.
///
/// This filter accepts one or more expressions (one for each channel),
/// which are evaluated and used to modify a corresponding audio signal.
///
/// It accepts the following parameters:
///
/// Parameters:
/// - [c]: Set output channel layout. If not specified, the channel layout is specified by the number of expressions. If set to `same`, it will use by default the same input channel layout. (range 0..0, default "")
/// - [channel_layout]: Set output channel layout. If not specified, the channel layout is specified by the number of expressions. If set to `same`, it will use by default the same input channel layout. (range 0..0, default "")
/// - [exprs]: Set the '|'-separated expressions list for each separate channel. If the number of input channels is greater than the number of expressions, the last specified expression is used for the remaining output channels. (default "")
final class AevalSettings {
  /// Whether this effect is inserted into the audio chain.
  final bool enabled;

  /// set channel layout
  final String c;

  /// set channel layout
  final String channel_layout;

  /// set the '|'-separated list of channels expressions
  final String exprs;

  /// Creates an [AevalSettings] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default; the effect stays
  /// inactive until [enabled] is set to `true`.
  const AevalSettings({
    this.enabled = false,
    this.c = '',
    this.channel_layout = '',
    required this.exprs,
  });

  /// Returns a copy of this [AevalSettings] with the given fields replaced.
  AevalSettings copyWith({
    bool? enabled,
    String? c,
    String? channel_layout,
    String? exprs,
  }) =>
      AevalSettings(
        enabled: enabled ?? this.enabled,
        c: c ?? this.c,
        channel_layout: channel_layout ?? this.channel_layout,
        exprs: exprs ?? this.exprs,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AevalSettings &&
          other.enabled == enabled &&
          other.c == c &&
          other.channel_layout == channel_layout &&
          other.exprs == exprs);

  @override
  int get hashCode => Object.hash(enabled, c, channel_layout, exprs);

  @override
  String toString() =>
      'AevalSettings(enabled: $enabled, c: $c, channel_layout: $channel_layout, exprs: $exprs)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    final parts = <String>[];
    if (c != '') parts.add('c=' + '[' + c + ']');
    if (channel_layout != '')
      parts.add('channel_layout=' + '[' + channel_layout + ']');
    parts.add('exprs=' + '[' + exprs + ']');
    return parts.isEmpty ? 'lavfi-aeval' : 'lavfi-aeval=' + parts.join(':');
  }
}

/// Configuration for the `aexciter` audio effect.
///
/// An exciter is used to produce high sound that is not present in the
/// original signal. This is done by creating harmonic distortions of the
/// signal which are restricted in range and added to the original signal.
/// An Exciter raises the upper end of an audio signal without simply raising
/// the higher frequencies like an equalizer would do to create a more
/// "crisp" or "brilliant" sound.
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [amount]: Set the amount of harmonics added to original signal. Allowed range is from 0 to 64. Default value is 1. (range 0..64, default 1, runtime-tunable)
/// - [blend]: Set the octave of newly created harmonics. Allowed range is from -10 to 10. Default value is 0. (range -10..10, default 0, runtime-tunable)
/// - [ceil]: Set the upper frequency limit of producing harmonics. Allowed range is from 9999 to 20000 Hz. If value is lower than 10000 Hz no limit is applied. (range 9999..20000, default 9999, runtime-tunable)
/// - [drive]: Set the amount of newly created harmonics. Allowed range is from 0.1 to 10. Default value is 8.5. (range 0.1..10, default 8.5, runtime-tunable)
/// - [freq]: Set the lower frequency limit of producing harmonics in Hz. Allowed range is from 2000 to 12000 Hz. Default is 7500 Hz. (range 2000..12000, default 7500, runtime-tunable)
/// - [level_in]: Set input level prior processing of signal. Allowed range is from 0 to 64. Default value is 1. (range 0..64, default 1, runtime-tunable)
/// - [level_out]: Set output level after processing of signal. Allowed range is from 0 to 64. Default value is 1. (range 0..64, default 1, runtime-tunable)
/// - [listen]: Mute the original signal and output only added harmonics. By default is disabled. (range 0..1, default 0, runtime-tunable)
final class AexciterSettings {
  /// Default value for [amount].
  static const double amountDefault = 1.0;

  /// Minimum value for [amount].
  static const double amountMin = 0.0;

  /// Maximum value for [amount].
  static const double amountMax = 64.0;

  /// Default value for [blend].
  static const double blendDefault = 0.0;

  /// Minimum value for [blend].
  static const double blendMin = -10.0;

  /// Maximum value for [blend].
  static const double blendMax = 10.0;

  /// Default value for [ceil].
  static const double ceilDefault = 9999.0;

  /// Minimum value for [ceil].
  static const double ceilMin = 9999.0;

  /// Maximum value for [ceil].
  static const double ceilMax = 20000.0;

  /// Default value for [drive].
  static const double driveDefault = 8.5;

  /// Minimum value for [drive].
  static const double driveMin = 0.1;

  /// Maximum value for [drive].
  static const double driveMax = 10.0;

  /// Default value for [freq].
  static const double freqDefault = 7500.0;

  /// Minimum value for [freq].
  static const double freqMin = 2000.0;

  /// Maximum value for [freq].
  static const double freqMax = 12000.0;

  /// Default value for [level_in].
  static const double level_inDefault = 1.0;

  /// Minimum value for [level_in].
  static const double level_inMin = 0.0;

  /// Maximum value for [level_in].
  static const double level_inMax = 64.0;

  /// Default value for [level_out].
  static const double level_outDefault = 1.0;

  /// Minimum value for [level_out].
  static const double level_outMin = 0.0;

  /// Maximum value for [level_out].
  static const double level_outMax = 64.0;

  /// Whether this effect is inserted into the audio chain.
  final bool enabled;

  /// set amount
  final double amount;

  /// set blend harmonics
  final double blend;

  /// set ceiling
  final double ceil;

  /// set harmonics
  final double drive;

  /// set scope
  final double freq;

  /// set level in
  final double level_in;

  /// set level out
  final double level_out;

  /// enable listen mode
  final bool listen;

  /// Creates an [AexciterSettings] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default; the effect stays
  /// inactive until [enabled] is set to `true`.
  const AexciterSettings({
    this.enabled = false,
    this.amount = 1.0,
    this.blend = 0.0,
    this.ceil = 9999.0,
    this.drive = 8.5,
    this.freq = 7500.0,
    this.level_in = 1.0,
    this.level_out = 1.0,
    this.listen = false,
  });

  /// Returns a copy of this [AexciterSettings] with the given fields replaced.
  AexciterSettings copyWith({
    bool? enabled,
    double? amount,
    double? blend,
    double? ceil,
    double? drive,
    double? freq,
    double? level_in,
    double? level_out,
    bool? listen,
  }) =>
      AexciterSettings(
        enabled: enabled ?? this.enabled,
        amount: amount ?? this.amount,
        blend: blend ?? this.blend,
        ceil: ceil ?? this.ceil,
        drive: drive ?? this.drive,
        freq: freq ?? this.freq,
        level_in: level_in ?? this.level_in,
        level_out: level_out ?? this.level_out,
        listen: listen ?? this.listen,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AexciterSettings &&
          other.enabled == enabled &&
          other.amount == amount &&
          other.blend == blend &&
          other.ceil == ceil &&
          other.drive == drive &&
          other.freq == freq &&
          other.level_in == level_in &&
          other.level_out == level_out &&
          other.listen == listen);

  @override
  int get hashCode => Object.hash(
      enabled, amount, blend, ceil, drive, freq, level_in, level_out, listen,);

  @override
  String toString() =>
      'AexciterSettings(enabled: $enabled, amount: $amount, blend: $blend, ceil: $ceil, drive: $drive, freq: $freq, level_in: $level_in, level_out: $level_out, listen: $listen)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(amount >= amountMin, 'aexciter.amount must be >= 0');
    assert(amount <= amountMax, 'aexciter.amount must be <= 64');
    assert(blend >= blendMin, 'aexciter.blend must be >= -10');
    assert(blend <= blendMax, 'aexciter.blend must be <= 10');
    assert(ceil >= ceilMin, 'aexciter.ceil must be >= 9999');
    assert(ceil <= ceilMax, 'aexciter.ceil must be <= 20000');
    assert(drive >= driveMin, 'aexciter.drive must be >= 0.1');
    assert(drive <= driveMax, 'aexciter.drive must be <= 10');
    assert(freq >= freqMin, 'aexciter.freq must be >= 2000');
    assert(freq <= freqMax, 'aexciter.freq must be <= 12000');
    assert(level_in >= level_inMin, 'aexciter.level_in must be >= 0');
    assert(level_in <= level_inMax, 'aexciter.level_in must be <= 64');
    assert(level_out >= level_outMin, 'aexciter.level_out must be >= 0');
    assert(level_out <= level_outMax, 'aexciter.level_out must be <= 64');
    final parts = <String>[];
    if (amount != 1.0) parts.add('amount=' + _wireDouble(amount));
    if (blend != 0.0) parts.add('blend=' + _wireDouble(blend));
    if (ceil != 9999.0) parts.add('ceil=' + _wireDouble(ceil));
    if (drive != 8.5) parts.add('drive=' + _wireDouble(drive));
    if (freq != 7500.0) parts.add('freq=' + _wireDouble(freq));
    if (level_in != 1.0) parts.add('level_in=' + _wireDouble(level_in));
    if (level_out != 1.0) parts.add('level_out=' + _wireDouble(level_out));
    if (listen != false) parts.add('listen=' + (listen ? '1' : '0'));
    return parts.isEmpty
        ? 'lavfi-aexciter'
        : 'lavfi-aexciter=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  List<(String, String)>? _runtimeDiff(AexciterSettings prev) {
    final out = <(String, String)>[];
    if (amount != prev.amount) {
      out.add(('amount', _wireDouble(amount)));
    }
    if (blend != prev.blend) {
      out.add(('blend', _wireDouble(blend)));
    }
    if (ceil != prev.ceil) {
      out.add(('ceil', _wireDouble(ceil)));
    }
    if (drive != prev.drive) {
      out.add(('drive', _wireDouble(drive)));
    }
    if (freq != prev.freq) {
      out.add(('freq', _wireDouble(freq)));
    }
    if (level_in != prev.level_in) {
      out.add(('level_in', _wireDouble(level_in)));
    }
    if (level_out != prev.level_out) {
      out.add(('level_out', _wireDouble(level_out)));
    }
    if (listen != prev.listen) {
      out.add(('listen', (listen ? '1' : '0')));
    }
    return out;
  }
}

/// Configuration for the `afade` audio effect.
///
/// Apply fade-in/out effect to input audio.
///
/// A description of the accepted parameters follows.
///
/// Parameters:
/// - [c]: set fade curve type (range -1..22, default TRI, runtime-tunable)
/// - [curve]: Set curve for fade transition.  It accepts the following values: (range -1..22, default TRI, runtime-tunable)
/// - [d]: Specify the duration of the fade effect. See time duration syntax for the accepted syntax. At the end of the fade-in effect the output audio will have the same volume as the input audio, at the end of the fade-out transition the output audio will be silence. By default the duration is determined by `nb_samples`. If set this option is used instead of `nb_samples`. (range 0..9223372036854775807, default 0, runtime-tunable)
/// - [duration]: Specify the duration of the fade effect. See time duration syntax for the accepted syntax. At the end of the fade-in effect the output audio will have the same volume as the input audio, at the end of the fade-out transition the output audio will be silence. By default the duration is determined by `nb_samples`. If set this option is used instead of `nb_samples`. (range 0..9223372036854775807, default 0, runtime-tunable)
/// - [nb_samples]: Specify the number of samples for which the fade effect has to last. At the end of the fade-in effect the output audio will have the same volume as the input audio, at the end of the fade-out transition the output audio will be silence. Default is 44100. (range 1..9223372036854775807, default 44100, runtime-tunable)
/// - [ns]: Specify the number of samples for which the fade effect has to last. At the end of the fade-in effect the output audio will have the same volume as the input audio, at the end of the fade-out transition the output audio will be silence. Default is 44100. (range 1..9223372036854775807, default 44100, runtime-tunable)
/// - [silence]: Set the initial gain for fade-in or final gain for fade-out. Default value is `0.0`. (range 0..1, default 0, runtime-tunable)
/// - [ss]: Specify the number of the start sample for starting to apply the fade effect. Default is 0. (range 0..9223372036854775807, default 0, runtime-tunable)
/// - [st]: Specify the start time of the fade effect. Default is 0. The value must be specified as a time duration; see time duration syntax for the accepted syntax. If set this option is used instead of `start_sample`. (range 0..9223372036854775807, default 0, runtime-tunable)
/// - [start_sample]: Specify the number of the start sample for starting to apply the fade effect. Default is 0. (range 0..9223372036854775807, default 0, runtime-tunable)
/// - [start_time]: Specify the start time of the fade effect. Default is 0. The value must be specified as a time duration; see time duration syntax for the accepted syntax. If set this option is used instead of `start_sample`. (range 0..9223372036854775807, default 0, runtime-tunable)
/// - [t]: Specify the effect type, can be either `in` for fade-in, or `out` for a fade-out effect. Default is `in`. (range 0..1, default 0, runtime-tunable)
/// - [type]: Specify the effect type, can be either `in` for fade-in, or `out` for a fade-out effect. Default is `in`. (range 0..1, default 0, runtime-tunable)
/// - [unity]: Set the initial gain for fade-out or final gain for fade-in. Default value is `1.0`. (range 0..1, default 1, runtime-tunable)
final class AfadeSettings {
  /// Default value for [nb_samples].
  static const int nb_samplesDefault = 44100;

  /// Minimum value for [nb_samples].
  static const int nb_samplesMin = 1;

  /// Maximum value for [nb_samples].
  static const int nb_samplesMax = 9223372036854775807;

  /// Default value for [ns].
  static const int nsDefault = 44100;

  /// Minimum value for [ns].
  static const int nsMin = 1;

  /// Maximum value for [ns].
  static const int nsMax = 9223372036854775807;

  /// Default value for [silence].
  static const double silenceDefault = 0.0;

  /// Minimum value for [silence].
  static const double silenceMin = 0.0;

  /// Maximum value for [silence].
  static const double silenceMax = 1.0;

  /// Default value for [ss].
  static const int ssDefault = 0;

  /// Minimum value for [ss].
  static const int ssMin = 0;

  /// Maximum value for [ss].
  static const int ssMax = 9223372036854775807;

  /// Default value for [start_sample].
  static const int start_sampleDefault = 0;

  /// Minimum value for [start_sample].
  static const int start_sampleMin = 0;

  /// Maximum value for [start_sample].
  static const int start_sampleMax = 9223372036854775807;

  /// Default value for [unity].
  static const double unityDefault = 1.0;

  /// Minimum value for [unity].
  static const double unityMin = 0.0;

  /// Maximum value for [unity].
  static const double unityMax = 1.0;

  /// Whether this effect is inserted into the audio chain.
  final bool enabled;

  /// set fade curve type
  final AfadeCurve c;

  /// set fade curve type
  final AfadeCurve curve;

  /// set fade duration
  final Duration d;

  /// set fade duration
  final Duration duration;

  /// set number of samples for fade duration
  final int nb_samples;

  /// set number of samples for fade duration
  final int ns;

  /// set the silence gain
  final double silence;

  /// set number of first sample to start fading
  final int ss;

  /// set time to start fading
  final Duration st;

  /// set number of first sample to start fading
  final int start_sample;

  /// set time to start fading
  final Duration start_time;

  /// set the fade direction
  final AfadeType t;

  /// set the fade direction
  final AfadeType type;

  /// set the unity gain
  final double unity;

  /// Creates an [AfadeSettings] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default; the effect stays
  /// inactive until [enabled] is set to `true`.
  const AfadeSettings({
    this.enabled = false,
    this.c = AfadeCurve.tri,
    this.curve = AfadeCurve.tri,
    this.d = Duration.zero,
    this.duration = Duration.zero,
    this.nb_samples = 44100,
    this.ns = 44100,
    this.silence = 0.0,
    this.ss = 0,
    this.st = Duration.zero,
    this.start_sample = 0,
    this.start_time = Duration.zero,
    this.t = AfadeType.in_,
    this.type = AfadeType.in_,
    this.unity = 1.0,
  });

  /// Returns a copy of this [AfadeSettings] with the given fields replaced.
  AfadeSettings copyWith({
    bool? enabled,
    AfadeCurve? c,
    AfadeCurve? curve,
    Duration? d,
    Duration? duration,
    int? nb_samples,
    int? ns,
    double? silence,
    int? ss,
    Duration? st,
    int? start_sample,
    Duration? start_time,
    AfadeType? t,
    AfadeType? type,
    double? unity,
  }) =>
      AfadeSettings(
        enabled: enabled ?? this.enabled,
        c: c ?? this.c,
        curve: curve ?? this.curve,
        d: d ?? this.d,
        duration: duration ?? this.duration,
        nb_samples: nb_samples ?? this.nb_samples,
        ns: ns ?? this.ns,
        silence: silence ?? this.silence,
        ss: ss ?? this.ss,
        st: st ?? this.st,
        start_sample: start_sample ?? this.start_sample,
        start_time: start_time ?? this.start_time,
        t: t ?? this.t,
        type: type ?? this.type,
        unity: unity ?? this.unity,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AfadeSettings &&
          other.enabled == enabled &&
          other.c == c &&
          other.curve == curve &&
          other.d == d &&
          other.duration == duration &&
          other.nb_samples == nb_samples &&
          other.ns == ns &&
          other.silence == silence &&
          other.ss == ss &&
          other.st == st &&
          other.start_sample == start_sample &&
          other.start_time == start_time &&
          other.t == t &&
          other.type == type &&
          other.unity == unity);

  @override
  int get hashCode => Object.hash(enabled, c, curve, d, duration, nb_samples,
      ns, silence, ss, st, start_sample, start_time, t, type, unity,);

  @override
  String toString() =>
      'AfadeSettings(enabled: $enabled, c: $c, curve: $curve, d: $d, duration: $duration, nb_samples: $nb_samples, ns: $ns, silence: $silence, ss: $ss, st: $st, start_sample: $start_sample, start_time: $start_time, t: $t, type: $type, unity: $unity)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(nb_samples >= nb_samplesMin, 'afade.nb_samples must be >= 1');
    assert(nb_samples <= nb_samplesMax,
        'afade.nb_samples must be <= 9223372036854775807',);
    assert(ns >= nsMin, 'afade.ns must be >= 1');
    assert(ns <= nsMax, 'afade.ns must be <= 9223372036854775807');
    assert(silence >= silenceMin, 'afade.silence must be >= 0');
    assert(silence <= silenceMax, 'afade.silence must be <= 1');
    assert(ss >= ssMin, 'afade.ss must be >= 0');
    assert(ss <= ssMax, 'afade.ss must be <= 9223372036854775807');
    assert(start_sample >= start_sampleMin, 'afade.start_sample must be >= 0');
    assert(start_sample <= start_sampleMax,
        'afade.start_sample must be <= 9223372036854775807',);
    assert(unity >= unityMin, 'afade.unity must be >= 0');
    assert(unity <= unityMax, 'afade.unity must be <= 1');
    final parts = <String>[];
    if (c != AfadeCurve.tri) parts.add('c=' + c.mpvValue);
    if (curve != AfadeCurve.tri) parts.add('curve=' + curve.mpvValue);
    if (d != Duration.zero)
      parts.add('d=' + _wireDouble(d.inMicroseconds / 1e6));
    if (duration != Duration.zero)
      parts.add('duration=' + _wireDouble(duration.inMicroseconds / 1e6));
    if (nb_samples != 44100) parts.add('nb_samples=' + nb_samples.toString());
    if (ns != 44100) parts.add('ns=' + ns.toString());
    if (silence != 0.0) parts.add('silence=' + _wireDouble(silence));
    if (ss != 0) parts.add('ss=' + ss.toString());
    if (st != Duration.zero)
      parts.add('st=' + _wireDouble(st.inMicroseconds / 1e6));
    if (start_sample != 0) parts.add('start_sample=' + start_sample.toString());
    if (start_time != Duration.zero)
      parts.add('start_time=' + _wireDouble(start_time.inMicroseconds / 1e6));
    if (t != AfadeType.in_) parts.add('t=' + t.mpvValue);
    if (type != AfadeType.in_) parts.add('type=' + type.mpvValue);
    if (unity != 1.0) parts.add('unity=' + _wireDouble(unity));
    return parts.isEmpty ? 'lavfi-afade' : 'lavfi-afade=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  List<(String, String)>? _runtimeDiff(AfadeSettings prev) {
    final out = <(String, String)>[];
    if (c != prev.c) {
      out.add(('c', c.mpvValue));
    }
    if (curve != prev.curve) {
      out.add(('curve', curve.mpvValue));
    }
    if (d != prev.d) {
      out.add(('d', _wireDouble(d.inMicroseconds / 1e6)));
    }
    if (duration != prev.duration) {
      out.add(('duration', _wireDouble(duration.inMicroseconds / 1e6)));
    }
    if (nb_samples != prev.nb_samples) {
      out.add(('nb_samples', nb_samples.toString()));
    }
    if (ns != prev.ns) {
      out.add(('ns', ns.toString()));
    }
    if (silence != prev.silence) {
      out.add(('silence', _wireDouble(silence)));
    }
    if (ss != prev.ss) {
      out.add(('ss', ss.toString()));
    }
    if (st != prev.st) {
      out.add(('st', _wireDouble(st.inMicroseconds / 1e6)));
    }
    if (start_sample != prev.start_sample) {
      out.add(('start_sample', start_sample.toString()));
    }
    if (start_time != prev.start_time) {
      out.add(('start_time', _wireDouble(start_time.inMicroseconds / 1e6)));
    }
    if (t != prev.t) {
      out.add(('t', t.mpvValue));
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

/// Configuration for the `afftdn` audio effect.
///
/// Denoise audio samples with FFT.
///
/// A description of the accepted parameters follows.
///
/// Parameters:
/// - [ad]: Set the adaptivity factor, used how fast to adapt gains adjustments per each frequency bin. Value `0` enables instant adaptation, while higher values react much slower. Allowed range is from `0` to `1`. Default value is `0.5`. (range 0..1, default 0.5, runtime-tunable)
/// - [adaptivity]: Set the adaptivity factor, used how fast to adapt gains adjustments per each frequency bin. Value `0` enables instant adaptation, while higher values react much slower. Allowed range is from `0` to `1`. Default value is `0.5`. (range 0..1, default 0.5, runtime-tunable)
/// - [band_multiplier]: Set the band multiplier factor, used how much to spread bands across frequency bins. Allowed range is from `0.2` to `5`. Default value is `1.25`. (range 0.2..5, default 1.25)
/// - [band_noise]: Set custom band noise profile for every one of 15 bands. Bands are separated by ' ' or '|'. (range 0..0, default "")
/// - [bm]: Set the band multiplier factor, used how much to spread bands across frequency bins. Allowed range is from `0.2` to `5`. Default value is `1.25`. (range 0.2..5, default 1.25)
/// - [bn]: Set custom band noise profile for every one of 15 bands. Bands are separated by ' ' or '|'. (range 0..0, default "")
/// - [floor_offset]: Set the noise floor offset factor. This option is used to adjust offset applied to measured noise floor. It is only effective when noise floor tracking is enabled. Allowed range is from `-2.0` to `2.0`. Default value is `1.0`. (range -2..2, default 1.0, runtime-tunable)
/// - [fo]: Set the noise floor offset factor. This option is used to adjust offset applied to measured noise floor. It is only effective when noise floor tracking is enabled. Allowed range is from `-2.0` to `2.0`. Default value is `1.0`. (range -2..2, default 1.0, runtime-tunable)
/// - [gain_smooth]: Set gain smooth spatial radius, used to smooth gains applied to each frequency bin. Useful to reduce random music noise artefacts. Higher values increases smoothing of gains. Allowed range is from `0` to `50`. Default value is `0`. (range 0..50, default 0, runtime-tunable)
/// - [gs]: Set gain smooth spatial radius, used to smooth gains applied to each frequency bin. Useful to reduce random music noise artefacts. Higher values increases smoothing of gains. Allowed range is from `0` to `50`. Default value is `0`. (range 0..50, default 0, runtime-tunable)
/// - [nf]: Set the noise floor in dB, allowed range is -80 to -20. Default value is -50 dB. (range -80..-20, default -50, runtime-tunable)
/// - [nl]: Set the noise link used for multichannel audio.  It accepts the following values: (range 0..3, default MIN_LINK, runtime-tunable)
/// - [noise_floor]: Set the noise floor in dB, allowed range is -80 to -20. Default value is -50 dB. (range -80..-20, default -50, runtime-tunable)
/// - [noise_link]: Set the noise link used for multichannel audio.  It accepts the following values: (range 0..3, default MIN_LINK, runtime-tunable)
/// - [noise_reduction]: Set the noise reduction in dB, allowed range is 0.01 to 97. Default value is 12 dB. (range .01..97, default 12, runtime-tunable)
/// - [noise_type]: Set the noise type.  It accepts the following values: (range 0..3, default WHITE_NOISE)
/// - [nr]: Set the noise reduction in dB, allowed range is 0.01 to 97. Default value is 12 dB. (range .01..97, default 12, runtime-tunable)
/// - [nt]: Set the noise type.  It accepts the following values: (range 0..3, default WHITE_NOISE)
/// - [om]: Set the output mode.  It accepts the following values: (range 0..2, default OUT_MODE, runtime-tunable)
/// - [output_mode]: Set the output mode.  It accepts the following values: (range 0..2, default OUT_MODE, runtime-tunable)
/// - [residual_floor]: Set the residual floor in dB, allowed range is -80 to -20. Default value is -38 dB. (range -80..-20, default -38, runtime-tunable)
/// - [rf]: Set the residual floor in dB, allowed range is -80 to -20. Default value is -38 dB. (range -80..-20, default -38, runtime-tunable)
/// - [sample_noise]: Toggle capturing and measurement of noise profile from input audio.  It accepts the following values: (range 0..2, default SAMPLE_NONE, runtime-tunable)
/// - [sn]: Toggle capturing and measurement of noise profile from input audio.  It accepts the following values: (range 0..2, default SAMPLE_NONE, runtime-tunable)
/// - [tn]: Enable noise floor tracking. By default is disabled. With this enabled, noise floor is automatically adjusted. (range 0..1, default 0, runtime-tunable)
/// - [tr]: Enable residual tracking. By default is disabled. (range 0..1, default 0, runtime-tunable)
/// - [track_noise]: Enable noise floor tracking. By default is disabled. With this enabled, noise floor is automatically adjusted. (range 0..1, default 0, runtime-tunable)
/// - [track_residual]: Enable residual tracking. By default is disabled. (range 0..1, default 0, runtime-tunable)
final class AfftdnSettings {
  /// Default value for [ad].
  static const double adDefault = 0.5;

  /// Minimum value for [ad].
  static const double adMin = 0.0;

  /// Maximum value for [ad].
  static const double adMax = 1.0;

  /// Default value for [adaptivity].
  static const double adaptivityDefault = 0.5;

  /// Minimum value for [adaptivity].
  static const double adaptivityMin = 0.0;

  /// Maximum value for [adaptivity].
  static const double adaptivityMax = 1.0;

  /// Default value for [band_multiplier].
  static const double band_multiplierDefault = 1.25;

  /// Minimum value for [band_multiplier].
  static const double band_multiplierMin = 0.2;

  /// Maximum value for [band_multiplier].
  static const double band_multiplierMax = 5.0;

  /// Default value for [bm].
  static const double bmDefault = 1.25;

  /// Minimum value for [bm].
  static const double bmMin = 0.2;

  /// Maximum value for [bm].
  static const double bmMax = 5.0;

  /// Default value for [floor_offset].
  static const double floor_offsetDefault = 1.0;

  /// Minimum value for [floor_offset].
  static const double floor_offsetMin = -2.0;

  /// Maximum value for [floor_offset].
  static const double floor_offsetMax = 2.0;

  /// Default value for [fo].
  static const double foDefault = 1.0;

  /// Minimum value for [fo].
  static const double foMin = -2.0;

  /// Maximum value for [fo].
  static const double foMax = 2.0;

  /// Default value for [gain_smooth].
  static const int gain_smoothDefault = 0;

  /// Minimum value for [gain_smooth].
  static const int gain_smoothMin = 0;

  /// Maximum value for [gain_smooth].
  static const int gain_smoothMax = 50;

  /// Default value for [gs].
  static const int gsDefault = 0;

  /// Minimum value for [gs].
  static const int gsMin = 0;

  /// Maximum value for [gs].
  static const int gsMax = 50;

  /// Default value for [nf].
  static const double nfDefault = -50.0;

  /// Minimum value for [nf].
  static const double nfMin = -80.0;

  /// Maximum value for [nf].
  static const double nfMax = -20.0;

  /// Default value for [noise_floor].
  static const double noise_floorDefault = -50.0;

  /// Minimum value for [noise_floor].
  static const double noise_floorMin = -80.0;

  /// Maximum value for [noise_floor].
  static const double noise_floorMax = -20.0;

  /// Default value for [noise_reduction].
  static const double noise_reductionDefault = 12.0;

  /// Minimum value for [noise_reduction].
  static const double noise_reductionMin = .01;

  /// Maximum value for [noise_reduction].
  static const double noise_reductionMax = 97.0;

  /// Default value for [nr].
  static const double nrDefault = 12.0;

  /// Minimum value for [nr].
  static const double nrMin = .01;

  /// Maximum value for [nr].
  static const double nrMax = 97.0;

  /// Default value for [residual_floor].
  static const double residual_floorDefault = -38.0;

  /// Minimum value for [residual_floor].
  static const double residual_floorMin = -80.0;

  /// Maximum value for [residual_floor].
  static const double residual_floorMax = -20.0;

  /// Default value for [rf].
  static const double rfDefault = -38.0;

  /// Minimum value for [rf].
  static const double rfMin = -80.0;

  /// Maximum value for [rf].
  static const double rfMax = -20.0;

  /// Whether this effect is inserted into the audio chain.
  final bool enabled;

  /// set adaptivity factor
  final double ad;

  /// set adaptivity factor
  final double adaptivity;

  /// set band multiplier
  final double band_multiplier;

  /// set the custom bands noise
  final String band_noise;

  /// set band multiplier
  final double bm;

  /// set the custom bands noise
  final String bn;

  /// set noise floor offset factor
  final double floor_offset;

  /// set noise floor offset factor
  final double fo;

  /// set gain smooth radius
  final int gain_smooth;

  /// set gain smooth radius
  final int gs;

  /// set the noise floor
  final double nf;

  /// set the noise floor link
  final AfftdnLink nl;

  /// set the noise floor
  final double noise_floor;

  /// set the noise floor link
  final AfftdnLink noise_link;

  /// set the noise reduction
  final double noise_reduction;

  /// set the noise type
  final AfftdnType noise_type;

  /// set the noise reduction
  final double nr;

  /// set the noise type
  final AfftdnType nt;

  /// set output mode
  final AfftdnMode om;

  /// set output mode
  final AfftdnMode output_mode;

  /// set the residual floor
  final double residual_floor;

  /// set the residual floor
  final double rf;

  /// set sample noise mode
  final AfftdnSample sample_noise;

  /// set sample noise mode
  final AfftdnSample sn;

  /// track noise
  final bool tn;

  /// track residual
  final bool tr;

  /// track noise
  final bool track_noise;

  /// track residual
  final bool track_residual;

  /// Creates an [AfftdnSettings] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default; the effect stays
  /// inactive until [enabled] is set to `true`.
  const AfftdnSettings({
    this.enabled = false,
    this.ad = 0.5,
    this.adaptivity = 0.5,
    this.band_multiplier = 1.25,
    this.band_noise = '',
    this.bm = 1.25,
    this.bn = '',
    this.floor_offset = 1.0,
    this.fo = 1.0,
    this.gain_smooth = 0,
    this.gs = 0,
    this.nf = -50.0,
    this.nl = AfftdnLink.min,
    this.noise_floor = -50.0,
    this.noise_link = AfftdnLink.min,
    this.noise_reduction = 12.0,
    this.noise_type = AfftdnType.white,
    this.nr = 12.0,
    this.nt = AfftdnType.white,
    this.om = AfftdnMode.output,
    this.output_mode = AfftdnMode.output,
    this.residual_floor = -38.0,
    this.rf = -38.0,
    this.sample_noise = AfftdnSample.none,
    this.sn = AfftdnSample.none,
    this.tn = false,
    this.tr = false,
    this.track_noise = false,
    this.track_residual = false,
  });

  /// Returns a copy of this [AfftdnSettings] with the given fields replaced.
  AfftdnSettings copyWith({
    bool? enabled,
    double? ad,
    double? adaptivity,
    double? band_multiplier,
    String? band_noise,
    double? bm,
    String? bn,
    double? floor_offset,
    double? fo,
    int? gain_smooth,
    int? gs,
    double? nf,
    AfftdnLink? nl,
    double? noise_floor,
    AfftdnLink? noise_link,
    double? noise_reduction,
    AfftdnType? noise_type,
    double? nr,
    AfftdnType? nt,
    AfftdnMode? om,
    AfftdnMode? output_mode,
    double? residual_floor,
    double? rf,
    AfftdnSample? sample_noise,
    AfftdnSample? sn,
    bool? tn,
    bool? tr,
    bool? track_noise,
    bool? track_residual,
  }) =>
      AfftdnSettings(
        enabled: enabled ?? this.enabled,
        ad: ad ?? this.ad,
        adaptivity: adaptivity ?? this.adaptivity,
        band_multiplier: band_multiplier ?? this.band_multiplier,
        band_noise: band_noise ?? this.band_noise,
        bm: bm ?? this.bm,
        bn: bn ?? this.bn,
        floor_offset: floor_offset ?? this.floor_offset,
        fo: fo ?? this.fo,
        gain_smooth: gain_smooth ?? this.gain_smooth,
        gs: gs ?? this.gs,
        nf: nf ?? this.nf,
        nl: nl ?? this.nl,
        noise_floor: noise_floor ?? this.noise_floor,
        noise_link: noise_link ?? this.noise_link,
        noise_reduction: noise_reduction ?? this.noise_reduction,
        noise_type: noise_type ?? this.noise_type,
        nr: nr ?? this.nr,
        nt: nt ?? this.nt,
        om: om ?? this.om,
        output_mode: output_mode ?? this.output_mode,
        residual_floor: residual_floor ?? this.residual_floor,
        rf: rf ?? this.rf,
        sample_noise: sample_noise ?? this.sample_noise,
        sn: sn ?? this.sn,
        tn: tn ?? this.tn,
        tr: tr ?? this.tr,
        track_noise: track_noise ?? this.track_noise,
        track_residual: track_residual ?? this.track_residual,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AfftdnSettings &&
          other.enabled == enabled &&
          other.ad == ad &&
          other.adaptivity == adaptivity &&
          other.band_multiplier == band_multiplier &&
          other.band_noise == band_noise &&
          other.bm == bm &&
          other.bn == bn &&
          other.floor_offset == floor_offset &&
          other.fo == fo &&
          other.gain_smooth == gain_smooth &&
          other.gs == gs &&
          other.nf == nf &&
          other.nl == nl &&
          other.noise_floor == noise_floor &&
          other.noise_link == noise_link &&
          other.noise_reduction == noise_reduction &&
          other.noise_type == noise_type &&
          other.nr == nr &&
          other.nt == nt &&
          other.om == om &&
          other.output_mode == output_mode &&
          other.residual_floor == residual_floor &&
          other.rf == rf &&
          other.sample_noise == sample_noise &&
          other.sn == sn &&
          other.tn == tn &&
          other.tr == tr &&
          other.track_noise == track_noise &&
          other.track_residual == track_residual);

  @override
  int get hashCode => Object.hashAll([
        enabled,
        ad,
        adaptivity,
        band_multiplier,
        band_noise,
        bm,
        bn,
        floor_offset,
        fo,
        gain_smooth,
        gs,
        nf,
        nl,
        noise_floor,
        noise_link,
        noise_reduction,
        noise_type,
        nr,
        nt,
        om,
        output_mode,
        residual_floor,
        rf,
        sample_noise,
        sn,
        tn,
        tr,
        track_noise,
        track_residual,
      ]);

  @override
  String toString() =>
      'AfftdnSettings(enabled: $enabled, ad: $ad, adaptivity: $adaptivity, band_multiplier: $band_multiplier, band_noise: $band_noise, bm: $bm, bn: $bn, floor_offset: $floor_offset, fo: $fo, gain_smooth: $gain_smooth, gs: $gs, nf: $nf, nl: $nl, noise_floor: $noise_floor, noise_link: $noise_link, noise_reduction: $noise_reduction, noise_type: $noise_type, nr: $nr, nt: $nt, om: $om, output_mode: $output_mode, residual_floor: $residual_floor, rf: $rf, sample_noise: $sample_noise, sn: $sn, tn: $tn, tr: $tr, track_noise: $track_noise, track_residual: $track_residual)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(ad >= adMin, 'afftdn.ad must be >= 0');
    assert(ad <= adMax, 'afftdn.ad must be <= 1');
    assert(adaptivity >= adaptivityMin, 'afftdn.adaptivity must be >= 0');
    assert(adaptivity <= adaptivityMax, 'afftdn.adaptivity must be <= 1');
    assert(band_multiplier >= band_multiplierMin,
        'afftdn.band_multiplier must be >= 0.2',);
    assert(band_multiplier <= band_multiplierMax,
        'afftdn.band_multiplier must be <= 5',);
    assert(bm >= bmMin, 'afftdn.bm must be >= 0.2');
    assert(bm <= bmMax, 'afftdn.bm must be <= 5');
    assert(
        floor_offset >= floor_offsetMin, 'afftdn.floor_offset must be >= -2',);
    assert(floor_offset <= floor_offsetMax, 'afftdn.floor_offset must be <= 2');
    assert(fo >= foMin, 'afftdn.fo must be >= -2');
    assert(fo <= foMax, 'afftdn.fo must be <= 2');
    assert(gain_smooth >= gain_smoothMin, 'afftdn.gain_smooth must be >= 0');
    assert(gain_smooth <= gain_smoothMax, 'afftdn.gain_smooth must be <= 50');
    assert(gs >= gsMin, 'afftdn.gs must be >= 0');
    assert(gs <= gsMax, 'afftdn.gs must be <= 50');
    assert(nf >= nfMin, 'afftdn.nf must be >= -80');
    assert(nf <= nfMax, 'afftdn.nf must be <= -20');
    assert(noise_floor >= noise_floorMin, 'afftdn.noise_floor must be >= -80');
    assert(noise_floor <= noise_floorMax, 'afftdn.noise_floor must be <= -20');
    assert(noise_reduction >= noise_reductionMin,
        'afftdn.noise_reduction must be >= .01',);
    assert(noise_reduction <= noise_reductionMax,
        'afftdn.noise_reduction must be <= 97',);
    assert(nr >= nrMin, 'afftdn.nr must be >= .01');
    assert(nr <= nrMax, 'afftdn.nr must be <= 97');
    assert(residual_floor >= residual_floorMin,
        'afftdn.residual_floor must be >= -80',);
    assert(residual_floor <= residual_floorMax,
        'afftdn.residual_floor must be <= -20',);
    assert(rf >= rfMin, 'afftdn.rf must be >= -80');
    assert(rf <= rfMax, 'afftdn.rf must be <= -20');
    final parts = <String>[];
    if (ad != 0.5) parts.add('ad=' + _wireDouble(ad));
    if (adaptivity != 0.5) parts.add('adaptivity=' + _wireDouble(adaptivity));
    if (band_multiplier != 1.25)
      parts.add('band_multiplier=' + _wireDouble(band_multiplier));
    if (band_noise != '') parts.add('band_noise=' + '[' + band_noise + ']');
    if (bm != 1.25) parts.add('bm=' + _wireDouble(bm));
    if (bn != '') parts.add('bn=' + '[' + bn + ']');
    if (floor_offset != 1.0)
      parts.add('floor_offset=' + _wireDouble(floor_offset));
    if (fo != 1.0) parts.add('fo=' + _wireDouble(fo));
    if (gain_smooth != 0) parts.add('gain_smooth=' + gain_smooth.toString());
    if (gs != 0) parts.add('gs=' + gs.toString());
    if (nf != -50.0) parts.add('nf=' + _wireDouble(nf));
    if (nl != AfftdnLink.min) parts.add('nl=' + nl.mpvValue);
    if (noise_floor != -50.0)
      parts.add('noise_floor=' + _wireDouble(noise_floor));
    if (noise_link != AfftdnLink.min)
      parts.add('noise_link=' + noise_link.mpvValue);
    if (noise_reduction != 12.0)
      parts.add('noise_reduction=' + _wireDouble(noise_reduction));
    if (noise_type != AfftdnType.white)
      parts.add('noise_type=' + noise_type.mpvValue);
    if (nr != 12.0) parts.add('nr=' + _wireDouble(nr));
    if (nt != AfftdnType.white) parts.add('nt=' + nt.mpvValue);
    if (om != AfftdnMode.output) parts.add('om=' + om.mpvValue);
    if (output_mode != AfftdnMode.output)
      parts.add('output_mode=' + output_mode.mpvValue);
    if (residual_floor != -38.0)
      parts.add('residual_floor=' + _wireDouble(residual_floor));
    if (rf != -38.0) parts.add('rf=' + _wireDouble(rf));
    if (sample_noise != AfftdnSample.none)
      parts.add('sample_noise=' + sample_noise.mpvValue);
    if (sn != AfftdnSample.none) parts.add('sn=' + sn.mpvValue);
    if (tn != false) parts.add('tn=' + (tn ? '1' : '0'));
    if (tr != false) parts.add('tr=' + (tr ? '1' : '0'));
    if (track_noise != false)
      parts.add('track_noise=' + (track_noise ? '1' : '0'));
    if (track_residual != false)
      parts.add('track_residual=' + (track_residual ? '1' : '0'));
    return parts.isEmpty ? 'lavfi-afftdn' : 'lavfi-afftdn=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  List<(String, String)>? _runtimeDiff(AfftdnSettings prev) {
    final out = <(String, String)>[];
    if (ad != prev.ad) {
      out.add(('ad', _wireDouble(ad)));
    }
    if (adaptivity != prev.adaptivity) {
      out.add(('adaptivity', _wireDouble(adaptivity)));
    }
    if (band_multiplier != prev.band_multiplier) return null;
    if (band_noise != prev.band_noise) return null;
    if (bm != prev.bm) return null;
    if (bn != prev.bn) return null;
    if (floor_offset != prev.floor_offset) {
      out.add(('floor_offset', _wireDouble(floor_offset)));
    }
    if (fo != prev.fo) {
      out.add(('fo', _wireDouble(fo)));
    }
    if (gain_smooth != prev.gain_smooth) {
      out.add(('gain_smooth', gain_smooth.toString()));
    }
    if (gs != prev.gs) {
      out.add(('gs', gs.toString()));
    }
    if (nf != prev.nf) {
      out.add(('nf', _wireDouble(nf)));
    }
    if (nl != prev.nl) {
      out.add(('nl', nl.mpvValue));
    }
    if (noise_floor != prev.noise_floor) {
      out.add(('noise_floor', _wireDouble(noise_floor)));
    }
    if (noise_link != prev.noise_link) {
      out.add(('noise_link', noise_link.mpvValue));
    }
    if (noise_reduction != prev.noise_reduction) {
      out.add(('noise_reduction', _wireDouble(noise_reduction)));
    }
    if (noise_type != prev.noise_type) return null;
    if (nr != prev.nr) {
      out.add(('nr', _wireDouble(nr)));
    }
    if (nt != prev.nt) return null;
    if (om != prev.om) {
      out.add(('om', om.mpvValue));
    }
    if (output_mode != prev.output_mode) {
      out.add(('output_mode', output_mode.mpvValue));
    }
    if (residual_floor != prev.residual_floor) {
      out.add(('residual_floor', _wireDouble(residual_floor)));
    }
    if (rf != prev.rf) {
      out.add(('rf', _wireDouble(rf)));
    }
    if (sample_noise != prev.sample_noise) {
      out.add(('sample_noise', sample_noise.mpvValue));
    }
    if (sn != prev.sn) {
      out.add(('sn', sn.mpvValue));
    }
    if (tn != prev.tn) {
      out.add(('tn', (tn ? '1' : '0')));
    }
    if (tr != prev.tr) {
      out.add(('tr', (tr ? '1' : '0')));
    }
    if (track_noise != prev.track_noise) {
      out.add(('track_noise', (track_noise ? '1' : '0')));
    }
    if (track_residual != prev.track_residual) {
      out.add(('track_residual', (track_residual ? '1' : '0')));
    }
    return out;
  }
}

/// Configuration for the `afftfilt` audio effect.
///
/// Apply arbitrary expressions to samples in frequency domain.
///
/// Parameters:
/// - [imag]: Set frequency domain imaginary expression for each separate channel separated by '|'. Default is "im".  Each expression in `real` and `imag` can contain the following constants and functions: (range 0..0, default "im")
/// - [overlap]: set window overlap (range 0..1, default 0.75)
/// - [real]: Set frequency domain real expression for each separate channel separated by '|'. Default is "re". If the number of input channels is greater than the number of expressions, the last specified expression is used for the remaining output channels. (range 0..0, default "re")
/// - [win_func]: Set window function.  It accepts the following values: (default WFUNC_HANNING)
/// - [win_size]: Set window size. Allowed range is from 16 to 131072. Default is `4096` (range 16..131072, default 4096)
final class AfftfiltSettings {
  /// Default value for [overlap].
  static const double overlapDefault = 0.75;

  /// Minimum value for [overlap].
  static const double overlapMin = 0.0;

  /// Maximum value for [overlap].
  static const double overlapMax = 1.0;

  /// Default value for [win_size].
  static const int win_sizeDefault = 4096;

  /// Minimum value for [win_size].
  static const int win_sizeMin = 16;

  /// Maximum value for [win_size].
  static const int win_sizeMax = 131072;

  /// Whether this effect is inserted into the audio chain.
  final bool enabled;

  /// set channels imaginary expressions
  final String imag;

  /// set window overlap
  final double overlap;

  /// set channels real expressions
  final String real;

  /// set window function
  final AfftfiltWinFunc win_func;

  /// set window size
  final int win_size;

  /// Creates an [AfftfiltSettings] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default; the effect stays
  /// inactive until [enabled] is set to `true`.
  const AfftfiltSettings({
    this.enabled = false,
    this.imag = 'im',
    this.overlap = 0.75,
    this.real = 're',
    this.win_func = AfftfiltWinFunc.hann,
    this.win_size = 4096,
  });

  /// Returns a copy of this [AfftfiltSettings] with the given fields replaced.
  AfftfiltSettings copyWith({
    bool? enabled,
    String? imag,
    double? overlap,
    String? real,
    AfftfiltWinFunc? win_func,
    int? win_size,
  }) =>
      AfftfiltSettings(
        enabled: enabled ?? this.enabled,
        imag: imag ?? this.imag,
        overlap: overlap ?? this.overlap,
        real: real ?? this.real,
        win_func: win_func ?? this.win_func,
        win_size: win_size ?? this.win_size,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AfftfiltSettings &&
          other.enabled == enabled &&
          other.imag == imag &&
          other.overlap == overlap &&
          other.real == real &&
          other.win_func == win_func &&
          other.win_size == win_size);

  @override
  int get hashCode =>
      Object.hash(enabled, imag, overlap, real, win_func, win_size);

  @override
  String toString() =>
      'AfftfiltSettings(enabled: $enabled, imag: $imag, overlap: $overlap, real: $real, win_func: $win_func, win_size: $win_size)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(overlap >= overlapMin, 'afftfilt.overlap must be >= 0');
    assert(overlap <= overlapMax, 'afftfilt.overlap must be <= 1');
    assert(win_size >= win_sizeMin, 'afftfilt.win_size must be >= 16');
    assert(win_size <= win_sizeMax, 'afftfilt.win_size must be <= 131072');
    final parts = <String>[];
    if (imag != 'im') parts.add('imag=' + '[' + imag + ']');
    if (overlap != 0.75) parts.add('overlap=' + _wireDouble(overlap));
    if (real != 're') parts.add('real=' + '[' + real + ']');
    if (win_func != AfftfiltWinFunc.hann)
      parts.add('win_func=' + win_func.mpvValue);
    if (win_size != 4096) parts.add('win_size=' + win_size.toString());
    return parts.isEmpty
        ? 'lavfi-afftfilt'
        : 'lavfi-afftfilt=' + parts.join(':');
  }
}

/// Configuration for the `aformat` audio effect.
///
/// Set output format constraints for the input audio. The framework will
/// negotiate the most appropriate format to minimize conversions.
///
/// It accepts the following parameters:
///
/// Parameters:
/// - [channel_layouts]: A '|'-separated list of requested channel layouts.  See channel layout syntax for the required syntax. (array, base=AV_OPT_TYPE_CHLAYOUT, sep='|')
/// - [cl]: A '|'-separated list of requested channel layouts.  See channel layout syntax for the required syntax. (array, base=AV_OPT_TYPE_CHLAYOUT, sep='|')
/// - [f]: A '|'-separated list of requested sample formats. (array, base=AV_OPT_TYPE_SAMPLE_FMT, sep='|')
/// - [r]: A '|'-separated list of requested sample rates. (range 1..2147483647, array, base=AV_OPT_TYPE_INT, sep='|')
/// - [sample_fmts]: A '|'-separated list of requested sample formats. (array, base=AV_OPT_TYPE_SAMPLE_FMT, sep='|')
/// - [sample_rates]: A '|'-separated list of requested sample rates. (range 1..2147483647, array, base=AV_OPT_TYPE_INT, sep='|')
final class AformatSettings {
  /// Whether this effect is inserted into the audio chain.
  final bool enabled;

  /// A '|'-separated list of channel layouts.
  final String? channel_layouts;

  /// A '|'-separated list of channel layouts.
  final String? cl;

  /// A '|'-separated list of sample formats.
  final String? f;

  /// A '|'-separated list of sample rates.
  final String? r;

  /// A '|'-separated list of sample formats.
  final String? sample_fmts;

  /// A '|'-separated list of sample rates.
  final String? sample_rates;

  /// Creates an [AformatSettings] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default; the effect stays
  /// inactive until [enabled] is set to `true`.
  const AformatSettings({
    this.enabled = false,
    this.channel_layouts,
    this.cl,
    this.f,
    this.r,
    this.sample_fmts,
    this.sample_rates,
  });

  /// Returns a copy of this [AformatSettings] with the given fields replaced.
  AformatSettings copyWith({
    bool? enabled,
    Object? channel_layouts = unset,
    Object? cl = unset,
    Object? f = unset,
    Object? r = unset,
    Object? sample_fmts = unset,
    Object? sample_rates = unset,
  }) =>
      AformatSettings(
        enabled: enabled ?? this.enabled,
        channel_layouts: identical(channel_layouts, unset)
            ? this.channel_layouts
            : channel_layouts as String?,
        cl: identical(cl, unset) ? this.cl : cl as String?,
        f: identical(f, unset) ? this.f : f as String?,
        r: identical(r, unset) ? this.r : r as String?,
        sample_fmts: identical(sample_fmts, unset)
            ? this.sample_fmts
            : sample_fmts as String?,
        sample_rates: identical(sample_rates, unset)
            ? this.sample_rates
            : sample_rates as String?,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AformatSettings &&
          other.enabled == enabled &&
          other.channel_layouts == channel_layouts &&
          other.cl == cl &&
          other.f == f &&
          other.r == r &&
          other.sample_fmts == sample_fmts &&
          other.sample_rates == sample_rates);

  @override
  int get hashCode => Object.hash(
      enabled, channel_layouts, cl, f, r, sample_fmts, sample_rates,);

  @override
  String toString() =>
      'AformatSettings(enabled: $enabled, channel_layouts: $channel_layouts, cl: $cl, f: $f, r: $r, sample_fmts: $sample_fmts, sample_rates: $sample_rates)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    final parts = <String>[];
    if (channel_layouts != null)
      parts.add('channel_layouts=' + '[' + channel_layouts! + ']');
    if (cl != null) parts.add('cl=' + '[' + cl! + ']');
    if (f != null) parts.add('f=' + '[' + f! + ']');
    if (r != null) parts.add('r=' + '[' + r! + ']');
    if (sample_fmts != null)
      parts.add('sample_fmts=' + '[' + sample_fmts! + ']');
    if (sample_rates != null)
      parts.add('sample_rates=' + '[' + sample_rates! + ']');
    return parts.isEmpty ? 'lavfi-aformat' : 'lavfi-aformat=' + parts.join(':');
  }
}

/// Configuration for the `afreqshift` audio effect.
///
/// Apply frequency shift to input audio samples.
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [level]: Set output gain applied to final output. Allowed range is from 0.0 to 1.0. Default value is 1.0. (range 0.0..1.0, default 1, runtime-tunable)
/// - [order]: Set filter order used for filtering. Allowed range is from 1 to 16. Default value is 8. (range 1..16, default 8, runtime-tunable)
/// - [shift]: Specify frequency shift. Allowed range is -INT_MAX to INT_MAX. Default value is 0.0. (range -2147483647..2147483647, default 0, runtime-tunable)
final class AfreqshiftSettings {
  /// Default value for [level].
  static const double levelDefault = 1.0;

  /// Minimum value for [level].
  static const double levelMin = 0.0;

  /// Maximum value for [level].
  static const double levelMax = 1.0;

  /// Default value for [order].
  static const int orderDefault = 8;

  /// Minimum value for [order].
  static const int orderMin = 1;

  /// Maximum value for [order].
  static const int orderMax = 16;

  /// Default value for [shift].
  static const double shiftDefault = 0.0;

  /// Minimum value for [shift].
  static const double shiftMin = -2147483647.0;

  /// Maximum value for [shift].
  static const double shiftMax = 2147483647.0;

  /// Whether this effect is inserted into the audio chain.
  final bool enabled;

  /// set output level
  final double level;

  /// set filter order
  final int order;

  /// set frequency shift
  final double shift;

  /// Creates an [AfreqshiftSettings] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default; the effect stays
  /// inactive until [enabled] is set to `true`.
  const AfreqshiftSettings({
    this.enabled = false,
    this.level = 1.0,
    this.order = 8,
    this.shift = 0.0,
  });

  /// Returns a copy of this [AfreqshiftSettings] with the given fields replaced.
  AfreqshiftSettings copyWith({
    bool? enabled,
    double? level,
    int? order,
    double? shift,
  }) =>
      AfreqshiftSettings(
        enabled: enabled ?? this.enabled,
        level: level ?? this.level,
        order: order ?? this.order,
        shift: shift ?? this.shift,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AfreqshiftSettings &&
          other.enabled == enabled &&
          other.level == level &&
          other.order == order &&
          other.shift == shift);

  @override
  int get hashCode => Object.hash(enabled, level, order, shift);

  @override
  String toString() =>
      'AfreqshiftSettings(enabled: $enabled, level: $level, order: $order, shift: $shift)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(level >= levelMin, 'afreqshift.level must be >= 0.0');
    assert(level <= levelMax, 'afreqshift.level must be <= 1.0');
    assert(order >= orderMin, 'afreqshift.order must be >= 1');
    assert(order <= orderMax, 'afreqshift.order must be <= 16');
    assert(shift >= shiftMin, 'afreqshift.shift must be >= -2147483647');
    assert(shift <= shiftMax, 'afreqshift.shift must be <= 2147483647');
    final parts = <String>[];
    if (level != 1.0) parts.add('level=' + _wireDouble(level));
    if (order != 8) parts.add('order=' + order.toString());
    if (shift != 0.0) parts.add('shift=' + _wireDouble(shift));
    return parts.isEmpty
        ? 'lavfi-afreqshift'
        : 'lavfi-afreqshift=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  List<(String, String)>? _runtimeDiff(AfreqshiftSettings prev) {
    final out = <(String, String)>[];
    if (level != prev.level) {
      out.add(('level', _wireDouble(level)));
    }
    if (order != prev.order) {
      out.add(('order', order.toString()));
    }
    if (shift != prev.shift) {
      out.add(('shift', _wireDouble(shift)));
    }
    return out;
  }
}

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
final class AfwtdnSettings {
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

  /// Whether this effect is inserted into the audio chain.
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

  /// Creates an [AfwtdnSettings] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default; the effect stays
  /// inactive until [enabled] is set to `true`.
  const AfwtdnSettings({
    this.enabled = false,
    this.adaptive = false,
    this.levels = 10,
    this.percent = 85.0,
    this.profile = false,
    this.samples = 8192,
    this.sigma = 0.0,
    this.softness = 1.0,
    this.wavet = AfwtdnWavet.sym10,
  });

  /// Returns a copy of this [AfwtdnSettings] with the given fields replaced.
  AfwtdnSettings copyWith({
    bool? enabled,
    bool? adaptive,
    int? levels,
    double? percent,
    bool? profile,
    int? samples,
    double? sigma,
    double? softness,
    AfwtdnWavet? wavet,
  }) =>
      AfwtdnSettings(
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
      (other is AfwtdnSettings &&
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
  int get hashCode => Object.hash(enabled, adaptive, levels, percent, profile,
      samples, sigma, softness, wavet,);

  @override
  String toString() =>
      'AfwtdnSettings(enabled: $enabled, adaptive: $adaptive, levels: $levels, percent: $percent, profile: $profile, samples: $samples, sigma: $sigma, softness: $softness, wavet: $wavet)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
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
  List<(String, String)>? _runtimeDiff(AfwtdnSettings prev) {
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

/// Configuration for the `agate` audio effect.
///
/// A gate is mainly used to reduce lower parts of a signal. This kind of signal
/// processing reduces disturbing noise between useful signals.
///
/// Gating is done by detecting the volume below a chosen level `threshold`
/// and dividing it by the factor set with `ratio`. The bottom of the noise
/// floor is set via `range`. Because an exact manipulation of the signal
/// would cause distortion of the waveform the reduction can be levelled over
/// time. This is done by setting `attack` and `release`.
///
/// `attack` determines how long the signal has to fall below the threshold
/// before any reduction will occur and `release` sets the time the signal
/// has to rise above the threshold to reduce the reduction again.
/// Shorter signals than the chosen attack time will be left untouched.
///
/// Parameters:
/// - [attack]: Amount of milliseconds the signal has to rise above the threshold before gain reduction stops. Default is 20 milliseconds. Allowed range is from 0.01 to 9000. (range 0.01..9000, default 20, runtime-tunable)
/// - [detection]: Choose if exact signal should be taken for detection or an RMS like one. Default is `rms`. Can be `peak` or `rms`. (range 0..1, default 1, runtime-tunable)
/// - [knee]: Curve the sharp knee around the threshold to enter gain reduction more softly. Default is 2.828427125. Allowed range is from 1 to 8. (range 1..8, default 2.828427125, runtime-tunable)
/// - [level_in]: Set input level before filtering. Default is 1. Allowed range is from 0.015625 to 64. (range 0.015625..64, default 1, runtime-tunable)
/// - [level_sc]: set sidechain gain (range 0.015625..64, default 1, runtime-tunable)
/// - [link]: Choose if the average level between all channels or the louder channel affects the reduction. Default is `average`. Can be `average` or `maximum`. (range 0..1, default 0, runtime-tunable)
/// - [makeup]: Set amount of amplification of signal after processing. Default is 1. Allowed range is from 1 to 64. (range 1..64, default 1, runtime-tunable)
/// - [mode]: Set the mode of operation. Can be `upward` or `downward`. Default is `downward`. If set to `upward` mode, higher parts of signal will be amplified, expanding dynamic range in upward direction. Otherwise, in case of `downward` lower parts of signal will be reduced. (range 0..1, default 0, runtime-tunable)
/// - [range]: Set the level of gain reduction when the signal is below the threshold. Default is 0.06125. Allowed range is from 0 to 1. Setting this to 0 disables reduction and then filter behaves like expander. (range 0..1, default 0.06125, runtime-tunable)
/// - [ratio]: Set a ratio by which the signal is reduced. Default is 2. Allowed range is from 1 to 9000. (range 1..9000, default 2, runtime-tunable)
/// - [release]: Amount of milliseconds the signal has to fall below the threshold before the reduction is increased again. Default is 250 milliseconds. Allowed range is from 0.01 to 9000. (range 0.01..9000, default 250, runtime-tunable)
/// - [threshold]: If a signal rises above this level the gain reduction is released. Default is 0.125. Allowed range is from 0 to 1. (range 0..1, default 0.125, runtime-tunable)
final class AgateSettings {
  /// Default value for [attack].
  static const double attackDefault = 20.0;

  /// Minimum value for [attack].
  static const double attackMin = 0.01;

  /// Maximum value for [attack].
  static const double attackMax = 9000.0;

  /// Default value for [knee].
  static const double kneeDefault = 2.828427125;

  /// Minimum value for [knee].
  static const double kneeMin = 1.0;

  /// Maximum value for [knee].
  static const double kneeMax = 8.0;

  /// Default value for [level_in].
  static const double level_inDefault = 1.0;

  /// Minimum value for [level_in].
  static const double level_inMin = 0.015625;

  /// Maximum value for [level_in].
  static const double level_inMax = 64.0;

  /// Default value for [level_sc].
  static const double level_scDefault = 1.0;

  /// Minimum value for [level_sc].
  static const double level_scMin = 0.015625;

  /// Maximum value for [level_sc].
  static const double level_scMax = 64.0;

  /// Default value for [makeup].
  static const double makeupDefault = 1.0;

  /// Minimum value for [makeup].
  static const double makeupMin = 1.0;

  /// Maximum value for [makeup].
  static const double makeupMax = 64.0;

  /// Default value for [range].
  static const double rangeDefault = 0.06125;

  /// Minimum value for [range].
  static const double rangeMin = 0.0;

  /// Maximum value for [range].
  static const double rangeMax = 1.0;

  /// Default value for [ratio].
  static const double ratioDefault = 2.0;

  /// Minimum value for [ratio].
  static const double ratioMin = 1.0;

  /// Maximum value for [ratio].
  static const double ratioMax = 9000.0;

  /// Default value for [release].
  static const double releaseDefault = 250.0;

  /// Minimum value for [release].
  static const double releaseMin = 0.01;

  /// Maximum value for [release].
  static const double releaseMax = 9000.0;

  /// Default value for [threshold].
  static const double thresholdDefault = 0.125;

  /// Minimum value for [threshold].
  static const double thresholdMin = 0.0;

  /// Maximum value for [threshold].
  static const double thresholdMax = 1.0;

  /// Whether this effect is inserted into the audio chain.
  final bool enabled;

  /// set attack
  final double attack;

  /// set detection
  final AgateDetection detection;

  /// set knee
  final double knee;

  /// set input level
  final double level_in;

  /// set sidechain gain
  final double level_sc;

  /// set link
  final AgateLink link;

  /// set makeup gain
  final double makeup;

  /// set mode
  final AgateMode mode;

  /// set max gain reduction
  final double range;

  /// set ratio
  final double ratio;

  /// set release
  final double release;

  /// set threshold
  final double threshold;

  /// Creates an [AgateSettings] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default; the effect stays
  /// inactive until [enabled] is set to `true`.
  const AgateSettings({
    this.enabled = false,
    this.attack = 20.0,
    this.detection = AgateDetection.rms,
    this.knee = 2.828427125,
    this.level_in = 1.0,
    this.level_sc = 1.0,
    this.link = AgateLink.average,
    this.makeup = 1.0,
    this.mode = AgateMode.downward,
    this.range = 0.06125,
    this.ratio = 2.0,
    this.release = 250.0,
    this.threshold = 0.125,
  });

  /// Returns a copy of this [AgateSettings] with the given fields replaced.
  AgateSettings copyWith({
    bool? enabled,
    double? attack,
    AgateDetection? detection,
    double? knee,
    double? level_in,
    double? level_sc,
    AgateLink? link,
    double? makeup,
    AgateMode? mode,
    double? range,
    double? ratio,
    double? release,
    double? threshold,
  }) =>
      AgateSettings(
        enabled: enabled ?? this.enabled,
        attack: attack ?? this.attack,
        detection: detection ?? this.detection,
        knee: knee ?? this.knee,
        level_in: level_in ?? this.level_in,
        level_sc: level_sc ?? this.level_sc,
        link: link ?? this.link,
        makeup: makeup ?? this.makeup,
        mode: mode ?? this.mode,
        range: range ?? this.range,
        ratio: ratio ?? this.ratio,
        release: release ?? this.release,
        threshold: threshold ?? this.threshold,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AgateSettings &&
          other.enabled == enabled &&
          other.attack == attack &&
          other.detection == detection &&
          other.knee == knee &&
          other.level_in == level_in &&
          other.level_sc == level_sc &&
          other.link == link &&
          other.makeup == makeup &&
          other.mode == mode &&
          other.range == range &&
          other.ratio == ratio &&
          other.release == release &&
          other.threshold == threshold);

  @override
  int get hashCode => Object.hash(enabled, attack, detection, knee, level_in,
      level_sc, link, makeup, mode, range, ratio, release, threshold,);

  @override
  String toString() =>
      'AgateSettings(enabled: $enabled, attack: $attack, detection: $detection, knee: $knee, level_in: $level_in, level_sc: $level_sc, link: $link, makeup: $makeup, mode: $mode, range: $range, ratio: $ratio, release: $release, threshold: $threshold)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(attack >= attackMin, 'agate.attack must be >= 0.01');
    assert(attack <= attackMax, 'agate.attack must be <= 9000');
    assert(knee >= kneeMin, 'agate.knee must be >= 1');
    assert(knee <= kneeMax, 'agate.knee must be <= 8');
    assert(level_in >= level_inMin, 'agate.level_in must be >= 0.015625');
    assert(level_in <= level_inMax, 'agate.level_in must be <= 64');
    assert(level_sc >= level_scMin, 'agate.level_sc must be >= 0.015625');
    assert(level_sc <= level_scMax, 'agate.level_sc must be <= 64');
    assert(makeup >= makeupMin, 'agate.makeup must be >= 1');
    assert(makeup <= makeupMax, 'agate.makeup must be <= 64');
    assert(range >= rangeMin, 'agate.range must be >= 0');
    assert(range <= rangeMax, 'agate.range must be <= 1');
    assert(ratio >= ratioMin, 'agate.ratio must be >= 1');
    assert(ratio <= ratioMax, 'agate.ratio must be <= 9000');
    assert(release >= releaseMin, 'agate.release must be >= 0.01');
    assert(release <= releaseMax, 'agate.release must be <= 9000');
    assert(threshold >= thresholdMin, 'agate.threshold must be >= 0');
    assert(threshold <= thresholdMax, 'agate.threshold must be <= 1');
    final parts = <String>[];
    if (attack != 20.0) parts.add('attack=' + _wireDouble(attack));
    if (detection != AgateDetection.rms)
      parts.add('detection=' + detection.mpvValue);
    if (knee != 2.828427125) parts.add('knee=' + _wireDouble(knee));
    if (level_in != 1.0) parts.add('level_in=' + _wireDouble(level_in));
    if (level_sc != 1.0) parts.add('level_sc=' + _wireDouble(level_sc));
    if (link != AgateLink.average) parts.add('link=' + link.mpvValue);
    if (makeup != 1.0) parts.add('makeup=' + _wireDouble(makeup));
    if (mode != AgateMode.downward) parts.add('mode=' + mode.mpvValue);
    if (range != 0.06125) parts.add('range=' + _wireDouble(range));
    if (ratio != 2.0) parts.add('ratio=' + _wireDouble(ratio));
    if (release != 250.0) parts.add('release=' + _wireDouble(release));
    if (threshold != 0.125) parts.add('threshold=' + _wireDouble(threshold));
    return parts.isEmpty ? 'lavfi-agate' : 'lavfi-agate=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  List<(String, String)>? _runtimeDiff(AgateSettings prev) {
    final out = <(String, String)>[];
    if (attack != prev.attack) {
      out.add(('attack', _wireDouble(attack)));
    }
    if (detection != prev.detection) {
      out.add(('detection', detection.mpvValue));
    }
    if (knee != prev.knee) {
      out.add(('knee', _wireDouble(knee)));
    }
    if (level_in != prev.level_in) {
      out.add(('level_in', _wireDouble(level_in)));
    }
    if (level_sc != prev.level_sc) {
      out.add(('level_sc', _wireDouble(level_sc)));
    }
    if (link != prev.link) {
      out.add(('link', link.mpvValue));
    }
    if (makeup != prev.makeup) {
      out.add(('makeup', _wireDouble(makeup)));
    }
    if (mode != prev.mode) {
      out.add(('mode', mode.mpvValue));
    }
    if (range != prev.range) {
      out.add(('range', _wireDouble(range)));
    }
    if (ratio != prev.ratio) {
      out.add(('ratio', _wireDouble(ratio)));
    }
    if (release != prev.release) {
      out.add(('release', _wireDouble(release)));
    }
    if (threshold != prev.threshold) {
      out.add(('threshold', _wireDouble(threshold)));
    }
    return out;
  }
}

/// Configuration for the `aiir` audio effect.
///
/// Apply an arbitrary Infinite Impulse Response filter.
///
/// It accepts the following parameters:
///
/// Parameters:
/// - [channel]: set IR channel to display frequency response (range 0..1024, default 0)
/// - [dry]: set dry gain (range 0..1, default 1)
/// - [e]: set precision (range 0..3, default 0)
/// - [f]: Set coefficients format. (range -2..4, default 1)
/// - [format]: Set coefficients format. (range -2..4, default 1)
/// - [gains]: Set channels gains. (range 0..0, default "1|1")
/// - [k]: Set channels gains. (range 0..0, default "1|1")
/// - [mix]: set mix (range 0..1, default 1)
/// - [n]: normalize coefficients (range 0..1, default 1)
/// - [normalize]: normalize coefficients (range 0..1, default 1)
/// - [p]: Set A/denominator/poles/ladder coefficients. (range 0..0, default "1+0i 1-0i")
/// - [poles]: Set A/denominator/poles/ladder coefficients. (range 0..0, default "1+0i 1-0i")
/// - [precision]: set filtering precision (range 0..3, default 0)
/// - [process]: set kind of processing (range 0..2, default 1)
/// - [r]: set kind of processing (range 0..2, default 1)
/// - [rate]: set video rate (range 0..2147483647, default "25")
/// - [response]: show IR frequency response (range 0..1, default 0)
/// - [size]: set video size (range 0..0, default "hd720")
/// - [wet]: set wet gain (range 0..1, default 1)
/// - [z]: Set B/numerator/zeros/reflection coefficients. (range 0..0, default "1+0i 1-0i")
/// - [zeros]: Set B/numerator/zeros/reflection coefficients. (range 0..0, default "1+0i 1-0i")
final class AiirSettings {
  /// Default value for [channel].
  static const int channelDefault = 0;

  /// Minimum value for [channel].
  static const int channelMin = 0;

  /// Maximum value for [channel].
  static const int channelMax = 1024;

  /// Default value for [dry].
  static const double dryDefault = 1.0;

  /// Minimum value for [dry].
  static const double dryMin = 0.0;

  /// Maximum value for [dry].
  static const double dryMax = 1.0;

  /// Default value for [mix].
  static const double mixDefault = 1.0;

  /// Minimum value for [mix].
  static const double mixMin = 0.0;

  /// Maximum value for [mix].
  static const double mixMax = 1.0;

  /// Default value for [wet].
  static const double wetDefault = 1.0;

  /// Minimum value for [wet].
  static const double wetMin = 0.0;

  /// Maximum value for [wet].
  static const double wetMax = 1.0;

  /// Whether this effect is inserted into the audio chain.
  final bool enabled;

  /// set IR channel to display frequency response
  final int channel;

  /// set dry gain
  final double dry;

  /// set precision
  final AiirPrecision e;

  /// set coefficients format
  final AiirFormat f;

  /// set coefficients format
  final AiirFormat format;

  /// set channels gains
  final String gains;

  /// set channels gains
  final String k;

  /// set mix
  final double mix;

  /// normalize coefficients
  final bool n;

  /// normalize coefficients
  final bool normalize;

  /// set A/denominator/poles/ladder coefficients
  final String p;

  /// set A/denominator/poles/ladder coefficients
  final String poles;

  /// set filtering precision
  final AiirPrecision precision;

  /// set kind of processing
  final AiirProcess process;

  /// set kind of processing
  final AiirProcess r;

  /// set video rate
  final String rate;

  /// show IR frequency response
  final bool response;

  /// set video size
  final String size;

  /// set wet gain
  final double wet;

  /// set B/numerator/zeros/reflection coefficients
  final String z;

  /// set B/numerator/zeros/reflection coefficients
  final String zeros;

  /// Creates an [AiirSettings] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default; the effect stays
  /// inactive until [enabled] is set to `true`.
  const AiirSettings({
    this.enabled = false,
    this.channel = 0,
    this.dry = 1.0,
    this.e = AiirPrecision.dbl,
    this.f = AiirFormat.zp,
    this.format = AiirFormat.zp,
    this.gains = '1|1',
    this.k = '1|1',
    this.mix = 1.0,
    this.n = true,
    this.normalize = true,
    this.p = '1+0i 1-0i',
    this.poles = '1+0i 1-0i',
    this.precision = AiirPrecision.dbl,
    this.process = AiirProcess.s,
    this.r = AiirProcess.s,
    this.rate = '25',
    this.response = false,
    this.size = 'hd720',
    this.wet = 1.0,
    this.z = '1+0i 1-0i',
    this.zeros = '1+0i 1-0i',
  });

  /// Returns a copy of this [AiirSettings] with the given fields replaced.
  AiirSettings copyWith({
    bool? enabled,
    int? channel,
    double? dry,
    AiirPrecision? e,
    AiirFormat? f,
    AiirFormat? format,
    String? gains,
    String? k,
    double? mix,
    bool? n,
    bool? normalize,
    String? p,
    String? poles,
    AiirPrecision? precision,
    AiirProcess? process,
    AiirProcess? r,
    String? rate,
    bool? response,
    String? size,
    double? wet,
    String? z,
    String? zeros,
  }) =>
      AiirSettings(
        enabled: enabled ?? this.enabled,
        channel: channel ?? this.channel,
        dry: dry ?? this.dry,
        e: e ?? this.e,
        f: f ?? this.f,
        format: format ?? this.format,
        gains: gains ?? this.gains,
        k: k ?? this.k,
        mix: mix ?? this.mix,
        n: n ?? this.n,
        normalize: normalize ?? this.normalize,
        p: p ?? this.p,
        poles: poles ?? this.poles,
        precision: precision ?? this.precision,
        process: process ?? this.process,
        r: r ?? this.r,
        rate: rate ?? this.rate,
        response: response ?? this.response,
        size: size ?? this.size,
        wet: wet ?? this.wet,
        z: z ?? this.z,
        zeros: zeros ?? this.zeros,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AiirSettings &&
          other.enabled == enabled &&
          other.channel == channel &&
          other.dry == dry &&
          other.e == e &&
          other.f == f &&
          other.format == format &&
          other.gains == gains &&
          other.k == k &&
          other.mix == mix &&
          other.n == n &&
          other.normalize == normalize &&
          other.p == p &&
          other.poles == poles &&
          other.precision == precision &&
          other.process == process &&
          other.r == r &&
          other.rate == rate &&
          other.response == response &&
          other.size == size &&
          other.wet == wet &&
          other.z == z &&
          other.zeros == zeros);

  @override
  int get hashCode => Object.hashAll([
        enabled,
        channel,
        dry,
        e,
        f,
        format,
        gains,
        k,
        mix,
        n,
        normalize,
        p,
        poles,
        precision,
        process,
        r,
        rate,
        response,
        size,
        wet,
        z,
        zeros,
      ]);

  @override
  String toString() =>
      'AiirSettings(enabled: $enabled, channel: $channel, dry: $dry, e: $e, f: $f, format: $format, gains: $gains, k: $k, mix: $mix, n: $n, normalize: $normalize, p: $p, poles: $poles, precision: $precision, process: $process, r: $r, rate: $rate, response: $response, size: $size, wet: $wet, z: $z, zeros: $zeros)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(channel >= channelMin, 'aiir.channel must be >= 0');
    assert(channel <= channelMax, 'aiir.channel must be <= 1024');
    assert(dry >= dryMin, 'aiir.dry must be >= 0');
    assert(dry <= dryMax, 'aiir.dry must be <= 1');
    assert(mix >= mixMin, 'aiir.mix must be >= 0');
    assert(mix <= mixMax, 'aiir.mix must be <= 1');
    assert(wet >= wetMin, 'aiir.wet must be >= 0');
    assert(wet <= wetMax, 'aiir.wet must be <= 1');
    final parts = <String>[];
    if (channel != 0) parts.add('channel=' + channel.toString());
    if (dry != 1.0) parts.add('dry=' + _wireDouble(dry));
    if (e != AiirPrecision.dbl) parts.add('e=' + e.mpvValue);
    if (f != AiirFormat.zp) parts.add('f=' + f.mpvValue);
    if (format != AiirFormat.zp) parts.add('format=' + format.mpvValue);
    if (gains != '1|1') parts.add('gains=' + '[' + gains + ']');
    if (k != '1|1') parts.add('k=' + '[' + k + ']');
    if (mix != 1.0) parts.add('mix=' + _wireDouble(mix));
    if (n != true) parts.add('n=' + (n ? '1' : '0'));
    if (normalize != true) parts.add('normalize=' + (normalize ? '1' : '0'));
    if (p != '1+0i 1-0i') parts.add('p=' + '[' + p + ']');
    if (poles != '1+0i 1-0i') parts.add('poles=' + '[' + poles + ']');
    if (precision != AiirPrecision.dbl)
      parts.add('precision=' + precision.mpvValue);
    if (process != AiirProcess.s) parts.add('process=' + process.mpvValue);
    if (r != AiirProcess.s) parts.add('r=' + r.mpvValue);
    if (rate != '25') parts.add('rate=' + '[' + rate + ']');
    if (response != false) parts.add('response=' + (response ? '1' : '0'));
    if (size != 'hd720') parts.add('size=' + '[' + size + ']');
    if (wet != 1.0) parts.add('wet=' + _wireDouble(wet));
    if (z != '1+0i 1-0i') parts.add('z=' + '[' + z + ']');
    if (zeros != '1+0i 1-0i') parts.add('zeros=' + '[' + zeros + ']');
    return parts.isEmpty ? 'lavfi-aiir' : 'lavfi-aiir=' + parts.join(':');
  }
}

/// Configuration for the `aintegral` audio effect.
///
/// Compute derivative/integral of audio stream.
///
/// Applying both filters one after another produces original audio.
final class AintegralSettings {
  /// Whether this effect is inserted into the audio chain.
  final bool enabled;

  /// Creates an [AintegralSettings] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default; the effect stays
  /// inactive until [enabled] is set to `true`.
  const AintegralSettings({
    this.enabled = false,
  });

  /// Returns a copy of this [AintegralSettings] with the given fields replaced.
  AintegralSettings copyWith({
    bool? enabled,
  }) =>
      AintegralSettings(
        enabled: enabled ?? this.enabled,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AintegralSettings && other.enabled == enabled);

  @override
  int get hashCode => enabled.hashCode;

  @override
  String toString() => 'AintegralSettings(enabled: $enabled)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    return 'lavfi-aintegral';
  }
}

/// Configuration for the `alimiter` audio effect.
///
/// The limiter prevents an input signal from rising over a desired threshold.
/// This limiter uses lookahead technology to prevent your signal from distorting.
/// It means that there is a small delay after the signal is processed. Keep in mind
/// that the delay it produces is the attack time you set.
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [asc]: When gain reduction is always needed ASC takes care of releasing to an average reduction level rather than reaching a reduction of 0 in the release time. (range 0..1, default 0, runtime-tunable)
/// - [asc_level]: Select how much the release time is affected by ASC, 0 means nearly no changes in release time while 1 produces higher release times. (range 0..1, default 0.5, runtime-tunable)
/// - [attack]: The limiter will reach its attenuation level in this amount of time in milliseconds. Default is 5 milliseconds. (range 0.1..80, default 5, runtime-tunable)
/// - [latency]: Compensate the delay introduced by using the lookahead buffer set with attack parameter. Also flush the valid audio data in the lookahead buffer when the stream hits EOF. (range 0..1, default 0, runtime-tunable)
/// - [level]: Auto level output signal. Default is enabled. This normalizes audio back to 0dB if enabled. (range 0..1, default 1, runtime-tunable)
/// - [level_in]: Set input gain. Default is 1. (range .015625..64, default 1, runtime-tunable)
/// - [level_out]: Set output gain. Default is 1. (range .015625..64, default 1, runtime-tunable)
/// - [limit]: Don't let signals above this level pass the limiter. Default is 1. (range 0.0625..1, default 1, runtime-tunable)
/// - [release]: Come back from limiting to attenuation 1.0 in this amount of milliseconds. Default is 50 milliseconds. (range 1..8000, default 50, runtime-tunable)
final class AlimiterSettings {
  /// Default value for [asc_level].
  static const double asc_levelDefault = 0.5;

  /// Minimum value for [asc_level].
  static const double asc_levelMin = 0.0;

  /// Maximum value for [asc_level].
  static const double asc_levelMax = 1.0;

  /// Default value for [attack].
  static const double attackDefault = 5.0;

  /// Minimum value for [attack].
  static const double attackMin = 0.1;

  /// Maximum value for [attack].
  static const double attackMax = 80.0;

  /// Default value for [level_in].
  static const double level_inDefault = 1.0;

  /// Minimum value for [level_in].
  static const double level_inMin = .015625;

  /// Maximum value for [level_in].
  static const double level_inMax = 64.0;

  /// Default value for [level_out].
  static const double level_outDefault = 1.0;

  /// Minimum value for [level_out].
  static const double level_outMin = .015625;

  /// Maximum value for [level_out].
  static const double level_outMax = 64.0;

  /// Default value for [limit].
  static const double limitDefault = 1.0;

  /// Minimum value for [limit].
  static const double limitMin = 0.0625;

  /// Maximum value for [limit].
  static const double limitMax = 1.0;

  /// Default value for [release].
  static const double releaseDefault = 50.0;

  /// Minimum value for [release].
  static const double releaseMin = 1.0;

  /// Maximum value for [release].
  static const double releaseMax = 8000.0;

  /// Whether this effect is inserted into the audio chain.
  final bool enabled;

  /// enable asc
  final bool asc;

  /// set asc level
  final double asc_level;

  /// set attack
  final double attack;

  /// compensate delay
  final bool latency;

  /// auto level
  final bool level;

  /// set input level
  final double level_in;

  /// set output level
  final double level_out;

  /// set limit
  final double limit;

  /// set release
  final double release;

  /// Creates an [AlimiterSettings] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default; the effect stays
  /// inactive until [enabled] is set to `true`.
  const AlimiterSettings({
    this.enabled = false,
    this.asc = false,
    this.asc_level = 0.5,
    this.attack = 5.0,
    this.latency = false,
    this.level = true,
    this.level_in = 1.0,
    this.level_out = 1.0,
    this.limit = 1.0,
    this.release = 50.0,
  });

  /// Returns a copy of this [AlimiterSettings] with the given fields replaced.
  AlimiterSettings copyWith({
    bool? enabled,
    bool? asc,
    double? asc_level,
    double? attack,
    bool? latency,
    bool? level,
    double? level_in,
    double? level_out,
    double? limit,
    double? release,
  }) =>
      AlimiterSettings(
        enabled: enabled ?? this.enabled,
        asc: asc ?? this.asc,
        asc_level: asc_level ?? this.asc_level,
        attack: attack ?? this.attack,
        latency: latency ?? this.latency,
        level: level ?? this.level,
        level_in: level_in ?? this.level_in,
        level_out: level_out ?? this.level_out,
        limit: limit ?? this.limit,
        release: release ?? this.release,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AlimiterSettings &&
          other.enabled == enabled &&
          other.asc == asc &&
          other.asc_level == asc_level &&
          other.attack == attack &&
          other.latency == latency &&
          other.level == level &&
          other.level_in == level_in &&
          other.level_out == level_out &&
          other.limit == limit &&
          other.release == release);

  @override
  int get hashCode => Object.hash(enabled, asc, asc_level, attack, latency,
      level, level_in, level_out, limit, release,);

  @override
  String toString() =>
      'AlimiterSettings(enabled: $enabled, asc: $asc, asc_level: $asc_level, attack: $attack, latency: $latency, level: $level, level_in: $level_in, level_out: $level_out, limit: $limit, release: $release)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(asc_level >= asc_levelMin, 'alimiter.asc_level must be >= 0');
    assert(asc_level <= asc_levelMax, 'alimiter.asc_level must be <= 1');
    assert(attack >= attackMin, 'alimiter.attack must be >= 0.1');
    assert(attack <= attackMax, 'alimiter.attack must be <= 80');
    assert(level_in >= level_inMin, 'alimiter.level_in must be >= .015625');
    assert(level_in <= level_inMax, 'alimiter.level_in must be <= 64');
    assert(level_out >= level_outMin, 'alimiter.level_out must be >= .015625');
    assert(level_out <= level_outMax, 'alimiter.level_out must be <= 64');
    assert(limit >= limitMin, 'alimiter.limit must be >= 0.0625');
    assert(limit <= limitMax, 'alimiter.limit must be <= 1');
    assert(release >= releaseMin, 'alimiter.release must be >= 1');
    assert(release <= releaseMax, 'alimiter.release must be <= 8000');
    final parts = <String>[];
    if (asc != false) parts.add('asc=' + (asc ? '1' : '0'));
    if (asc_level != 0.5) parts.add('asc_level=' + _wireDouble(asc_level));
    if (attack != 5.0) parts.add('attack=' + _wireDouble(attack));
    if (latency != false) parts.add('latency=' + (latency ? '1' : '0'));
    if (level != true) parts.add('level=' + (level ? '1' : '0'));
    if (level_in != 1.0) parts.add('level_in=' + _wireDouble(level_in));
    if (level_out != 1.0) parts.add('level_out=' + _wireDouble(level_out));
    if (limit != 1.0) parts.add('limit=' + _wireDouble(limit));
    if (release != 50.0) parts.add('release=' + _wireDouble(release));
    return parts.isEmpty
        ? 'lavfi-alimiter'
        : 'lavfi-alimiter=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  List<(String, String)>? _runtimeDiff(AlimiterSettings prev) {
    final out = <(String, String)>[];
    if (asc != prev.asc) {
      out.add(('asc', (asc ? '1' : '0')));
    }
    if (asc_level != prev.asc_level) {
      out.add(('asc_level', _wireDouble(asc_level)));
    }
    if (attack != prev.attack) {
      out.add(('attack', _wireDouble(attack)));
    }
    if (latency != prev.latency) {
      out.add(('latency', (latency ? '1' : '0')));
    }
    if (level != prev.level) {
      out.add(('level', (level ? '1' : '0')));
    }
    if (level_in != prev.level_in) {
      out.add(('level_in', _wireDouble(level_in)));
    }
    if (level_out != prev.level_out) {
      out.add(('level_out', _wireDouble(level_out)));
    }
    if (limit != prev.limit) {
      out.add(('limit', _wireDouble(limit)));
    }
    if (release != prev.release) {
      out.add(('release', _wireDouble(release)));
    }
    return out;
  }
}

/// Configuration for the `allpass` audio effect.
///
/// Apply a two-pole all-pass filter with central frequency (in Hz)
/// `frequency`, and filter-width `width`.
/// An all-pass filter changes the audio's frequency to phase relationship
/// without changing its frequency to amplitude relationship.
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [a]: Set transform type of IIR filter. (range 0..6, default DI)
/// - [c]: Specify which channels to filter, by default all available are filtered. (range 0..0, default "all", runtime-tunable)
/// - [channels]: Specify which channels to filter, by default all available are filtered. (range 0..0, default "all", runtime-tunable)
/// - [f]: Set frequency in Hz. (range 0..999999, default 3000, runtime-tunable)
/// - [frequency]: Set frequency in Hz. (range 0..999999, default 3000, runtime-tunable)
/// - [m]: How much to use filtered signal in output. Default is 1. Range is between 0 and 1. (range 0..1, default 1, runtime-tunable)
/// - [mix]: How much to use filtered signal in output. Default is 1. Range is between 0 and 1. (range 0..1, default 1, runtime-tunable)
/// - [n]: Normalize biquad coefficients, by default is disabled. Enabling it will normalize magnitude response at DC to 0dB. (range 0..1, default 0, runtime-tunable)
/// - [normalize]: Normalize biquad coefficients, by default is disabled. Enabling it will normalize magnitude response at DC to 0dB. (range 0..1, default 0, runtime-tunable)
/// - [o]: octave (range 1..2, default 2, runtime-tunable)
/// - [order]: Set the filter order, can be 1 or 2. Default is 2. (range 1..2, default 2, runtime-tunable)
/// - [precision]: Set precision of filtering. (range -1..3, default -1)
/// - [r]: Set precision of filtering. (range -1..3, default -1)
/// - [t]: Set method to specify band-width of filter. (range 1..5, default QFACTOR, runtime-tunable)
/// - [transform]: Set transform type of IIR filter. (range 0..6, default DI)
/// - [w]: Specify the band-width of a filter in width_type units. (range 0..99999, default 0.707, runtime-tunable)
/// - [width]: Specify the band-width of a filter in width_type units. (range 0..99999, default 0.707, runtime-tunable)
/// - [width_type]: Set method to specify band-width of filter. (range 1..5, default QFACTOR, runtime-tunable)
final class AllpassSettings {
  /// Default value for [f].
  static const double fDefault = 3000.0;

  /// Minimum value for [f].
  static const double fMin = 0.0;

  /// Maximum value for [f].
  static const double fMax = 999999.0;

  /// Default value for [frequency].
  static const double frequencyDefault = 3000.0;

  /// Minimum value for [frequency].
  static const double frequencyMin = 0.0;

  /// Maximum value for [frequency].
  static const double frequencyMax = 999999.0;

  /// Default value for [m].
  static const double mDefault = 1.0;

  /// Minimum value for [m].
  static const double mMin = 0.0;

  /// Maximum value for [m].
  static const double mMax = 1.0;

  /// Default value for [mix].
  static const double mixDefault = 1.0;

  /// Minimum value for [mix].
  static const double mixMin = 0.0;

  /// Maximum value for [mix].
  static const double mixMax = 1.0;

  /// Default value for [o].
  static const int oDefault = 2;

  /// Minimum value for [o].
  static const int oMin = 1;

  /// Maximum value for [o].
  static const int oMax = 2;

  /// Default value for [order].
  static const int orderDefault = 2;

  /// Minimum value for [order].
  static const int orderMin = 1;

  /// Maximum value for [order].
  static const int orderMax = 2;

  /// Default value for [w].
  static const double wDefault = 0.707;

  /// Minimum value for [w].
  static const double wMin = 0.0;

  /// Maximum value for [w].
  static const double wMax = 99999.0;

  /// Default value for [width].
  static const double widthDefault = 0.707;

  /// Minimum value for [width].
  static const double widthMin = 0.0;

  /// Maximum value for [width].
  static const double widthMax = 99999.0;

  /// Whether this effect is inserted into the audio chain.
  final bool enabled;

  /// set transform type
  final AllpassTransformType a;

  /// set channels to filter
  final String c;

  /// set channels to filter
  final String channels;

  /// set central frequency
  final double f;

  /// set central frequency
  final double frequency;

  /// set mix
  final double m;

  /// set mix
  final double mix;

  /// normalize coefficients
  final bool n;

  /// normalize coefficients
  final bool normalize;

  /// set filter order
  final int o;

  /// set filter order
  final int order;

  /// set filtering precision
  final AllpassPrecision precision;

  /// set filtering precision
  final AllpassPrecision r;

  /// set filter-width type
  final AllpassWidthType t;

  /// set transform type
  final AllpassTransformType transform;

  /// set width
  final double w;

  /// set width
  final double width;

  /// set filter-width type
  final AllpassWidthType width_type;

  /// Creates an [AllpassSettings] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default; the effect stays
  /// inactive until [enabled] is set to `true`.
  const AllpassSettings({
    this.enabled = false,
    this.a = AllpassTransformType.di,
    this.c = 'all',
    this.channels = 'all',
    this.f = 3000.0,
    this.frequency = 3000.0,
    this.m = 1.0,
    this.mix = 1.0,
    this.n = false,
    this.normalize = false,
    this.o = 2,
    this.order = 2,
    this.precision = AllpassPrecision.auto,
    this.r = AllpassPrecision.auto,
    this.t = AllpassWidthType.q,
    this.transform = AllpassTransformType.di,
    this.w = 0.707,
    this.width = 0.707,
    this.width_type = AllpassWidthType.q,
  });

  /// Returns a copy of this [AllpassSettings] with the given fields replaced.
  AllpassSettings copyWith({
    bool? enabled,
    AllpassTransformType? a,
    String? c,
    String? channels,
    double? f,
    double? frequency,
    double? m,
    double? mix,
    bool? n,
    bool? normalize,
    int? o,
    int? order,
    AllpassPrecision? precision,
    AllpassPrecision? r,
    AllpassWidthType? t,
    AllpassTransformType? transform,
    double? w,
    double? width,
    AllpassWidthType? width_type,
  }) =>
      AllpassSettings(
        enabled: enabled ?? this.enabled,
        a: a ?? this.a,
        c: c ?? this.c,
        channels: channels ?? this.channels,
        f: f ?? this.f,
        frequency: frequency ?? this.frequency,
        m: m ?? this.m,
        mix: mix ?? this.mix,
        n: n ?? this.n,
        normalize: normalize ?? this.normalize,
        o: o ?? this.o,
        order: order ?? this.order,
        precision: precision ?? this.precision,
        r: r ?? this.r,
        t: t ?? this.t,
        transform: transform ?? this.transform,
        w: w ?? this.w,
        width: width ?? this.width,
        width_type: width_type ?? this.width_type,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AllpassSettings &&
          other.enabled == enabled &&
          other.a == a &&
          other.c == c &&
          other.channels == channels &&
          other.f == f &&
          other.frequency == frequency &&
          other.m == m &&
          other.mix == mix &&
          other.n == n &&
          other.normalize == normalize &&
          other.o == o &&
          other.order == order &&
          other.precision == precision &&
          other.r == r &&
          other.t == t &&
          other.transform == transform &&
          other.w == w &&
          other.width == width &&
          other.width_type == width_type);

  @override
  int get hashCode => Object.hash(enabled, a, c, channels, f, frequency, m, mix,
      n, normalize, o, order, precision, r, t, transform, w, width, width_type,);

  @override
  String toString() =>
      'AllpassSettings(enabled: $enabled, a: $a, c: $c, channels: $channels, f: $f, frequency: $frequency, m: $m, mix: $mix, n: $n, normalize: $normalize, o: $o, order: $order, precision: $precision, r: $r, t: $t, transform: $transform, w: $w, width: $width, width_type: $width_type)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(f >= fMin, 'allpass.f must be >= 0');
    assert(f <= fMax, 'allpass.f must be <= 999999');
    assert(frequency >= frequencyMin, 'allpass.frequency must be >= 0');
    assert(frequency <= frequencyMax, 'allpass.frequency must be <= 999999');
    assert(m >= mMin, 'allpass.m must be >= 0');
    assert(m <= mMax, 'allpass.m must be <= 1');
    assert(mix >= mixMin, 'allpass.mix must be >= 0');
    assert(mix <= mixMax, 'allpass.mix must be <= 1');
    assert(o >= oMin, 'allpass.o must be >= 1');
    assert(o <= oMax, 'allpass.o must be <= 2');
    assert(order >= orderMin, 'allpass.order must be >= 1');
    assert(order <= orderMax, 'allpass.order must be <= 2');
    assert(w >= wMin, 'allpass.w must be >= 0');
    assert(w <= wMax, 'allpass.w must be <= 99999');
    assert(width >= widthMin, 'allpass.width must be >= 0');
    assert(width <= widthMax, 'allpass.width must be <= 99999');
    final parts = <String>[];
    if (a != AllpassTransformType.di) parts.add('a=' + a.mpvValue);
    if (c != 'all') parts.add('c=' + '[' + c + ']');
    if (channels != 'all') parts.add('channels=' + '[' + channels + ']');
    if (f != 3000.0) parts.add('f=' + _wireDouble(f));
    if (frequency != 3000.0) parts.add('frequency=' + _wireDouble(frequency));
    if (m != 1.0) parts.add('m=' + _wireDouble(m));
    if (mix != 1.0) parts.add('mix=' + _wireDouble(mix));
    if (n != false) parts.add('n=' + (n ? '1' : '0'));
    if (normalize != false) parts.add('normalize=' + (normalize ? '1' : '0'));
    if (o != 2) parts.add('o=' + o.toString());
    if (order != 2) parts.add('order=' + order.toString());
    if (precision != AllpassPrecision.auto)
      parts.add('precision=' + precision.mpvValue);
    if (r != AllpassPrecision.auto) parts.add('r=' + r.mpvValue);
    if (t != AllpassWidthType.q) parts.add('t=' + t.mpvValue);
    if (transform != AllpassTransformType.di)
      parts.add('transform=' + transform.mpvValue);
    if (w != 0.707) parts.add('w=' + _wireDouble(w));
    if (width != 0.707) parts.add('width=' + _wireDouble(width));
    if (width_type != AllpassWidthType.q)
      parts.add('width_type=' + width_type.mpvValue);
    return parts.isEmpty ? 'lavfi-allpass' : 'lavfi-allpass=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  List<(String, String)>? _runtimeDiff(AllpassSettings prev) {
    final out = <(String, String)>[];
    if (a != prev.a) return null;
    if (c != prev.c) {
      out.add(('c', c));
    }
    if (channels != prev.channels) {
      out.add(('channels', channels));
    }
    if (f != prev.f) {
      out.add(('f', _wireDouble(f)));
    }
    if (frequency != prev.frequency) {
      out.add(('frequency', _wireDouble(frequency)));
    }
    if (m != prev.m) {
      out.add(('m', _wireDouble(m)));
    }
    if (mix != prev.mix) {
      out.add(('mix', _wireDouble(mix)));
    }
    if (n != prev.n) {
      out.add(('n', (n ? '1' : '0')));
    }
    if (normalize != prev.normalize) {
      out.add(('normalize', (normalize ? '1' : '0')));
    }
    if (o != prev.o) {
      out.add(('o', o.toString()));
    }
    if (order != prev.order) {
      out.add(('order', order.toString()));
    }
    if (precision != prev.precision) return null;
    if (r != prev.r) return null;
    if (t != prev.t) {
      out.add(('t', t.mpvValue));
    }
    if (transform != prev.transform) return null;
    if (w != prev.w) {
      out.add(('w', _wireDouble(w)));
    }
    if (width != prev.width) {
      out.add(('width', _wireDouble(width)));
    }
    if (width_type != prev.width_type) {
      out.add(('width_type', width_type.mpvValue));
    }
    return out;
  }
}

/// Configuration for the `anequalizer` audio effect.
///
/// High-order parametric multiband equalizer for each channel.
///
/// It accepts the following parameters:
///
/// Parameters:
/// - [colors]: set channels curves colors (range 0..0, default "red|green|blue|yellow|orange|lime|pink|magenta|brown")
/// - [curves]: draw frequency response curves (range 0..1, default 0)
/// - [fscale]: set frequency scale (range 0..1, default 1)
/// - [mgain]: set max gain (range -900..900, default 60)
/// - [params]: This option string is in format: "c`chn` f=`cf` w=`w` g=`g` t=`f` | ..." Each equalizer band is separated by '|'. (range 0..0, default "")
/// - [size]: set video size (range 0..0, default "hd720")
final class AnequalizerSettings {
  /// Default value for [mgain].
  static const double mgainDefault = 60.0;

  /// Minimum value for [mgain].
  static const double mgainMin = -900.0;

  /// Maximum value for [mgain].
  static const double mgainMax = 900.0;

  /// Whether this effect is inserted into the audio chain.
  final bool enabled;

  /// set channels curves colors
  final String colors;

  /// draw frequency response curves
  final bool curves;

  /// set frequency scale
  final AnequalizerFscale fscale;

  /// set max gain
  final double mgain;

  /// Raw values for parameters whose names start with a digit,
  /// keyed by their original ffmpeg option name.
  final String params;

  /// set video size
  final String size;

  /// Creates an [AnequalizerSettings] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default; the effect stays
  /// inactive until [enabled] is set to `true`.
  const AnequalizerSettings({
    this.enabled = false,
    this.colors = 'red|green|blue|yellow|orange|lime|pink|magenta|brown',
    this.curves = false,
    this.fscale = AnequalizerFscale.log,
    this.mgain = 60.0,
    this.params = '',
    this.size = 'hd720',
  });

  /// Returns a copy of this [AnequalizerSettings] with the given fields replaced.
  AnequalizerSettings copyWith({
    bool? enabled,
    String? colors,
    bool? curves,
    AnequalizerFscale? fscale,
    double? mgain,
    String? params,
    String? size,
  }) =>
      AnequalizerSettings(
        enabled: enabled ?? this.enabled,
        colors: colors ?? this.colors,
        curves: curves ?? this.curves,
        fscale: fscale ?? this.fscale,
        mgain: mgain ?? this.mgain,
        params: params ?? this.params,
        size: size ?? this.size,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AnequalizerSettings &&
          other.enabled == enabled &&
          other.colors == colors &&
          other.curves == curves &&
          other.fscale == fscale &&
          other.mgain == mgain &&
          other.params == params &&
          other.size == size);

  @override
  int get hashCode =>
      Object.hash(enabled, colors, curves, fscale, mgain, params, size);

  @override
  String toString() =>
      'AnequalizerSettings(enabled: $enabled, colors: $colors, curves: $curves, fscale: $fscale, mgain: $mgain, params: $params, size: $size)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(mgain >= mgainMin, 'anequalizer.mgain must be >= -900');
    assert(mgain <= mgainMax, 'anequalizer.mgain must be <= 900');
    final parts = <String>[];
    if (colors != 'red|green|blue|yellow|orange|lime|pink|magenta|brown')
      parts.add('colors=' + '[' + colors + ']');
    if (curves != false) parts.add('curves=' + (curves ? '1' : '0'));
    if (fscale != AnequalizerFscale.log) parts.add('fscale=' + fscale.mpvValue);
    if (mgain != 60.0) parts.add('mgain=' + _wireDouble(mgain));
    if (params != '') parts.add('params=' + '[' + params + ']');
    if (size != 'hd720') parts.add('size=' + '[' + size + ']');
    return parts.isEmpty
        ? 'lavfi-anequalizer'
        : 'lavfi-anequalizer=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  List<(String, String)>? _runtimeDiff(AnequalizerSettings prev) {
    final out = <(String, String)>[];
    if (colors != prev.colors) return null;
    if (curves != prev.curves) return null;
    if (fscale != prev.fscale) return null;
    if (mgain != prev.mgain) return null;
    if (params != prev.params) return null;
    if (size != prev.size) return null;
    return out;
  }
}

/// Configuration for the `anlmdn` audio effect.
///
/// Reduce broadband noise in audio samples using Non-Local Means algorithm.
///
/// Each sample is adjusted by looking for other samples with similar contexts. This
/// context similarity is defined by comparing their surrounding patches of size
/// @option{p}. Patches are searched in an area of @option{r} around the sample.
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [m]: Set smooth factor. Default value is `11`. Allowed range is from `1` to `1000`. (range 1..1000, default 11., runtime-tunable)
/// - [o]: Set the output mode.  It accepts the following values: (range 0..2, default OUT_MODE, runtime-tunable)
/// - [output]: Set the output mode.  It accepts the following values: (range 0..2, default OUT_MODE, runtime-tunable)
/// - [p]: Set patch radius duration. Allowed range is from 1 to 100 milliseconds. Default value is 2 milliseconds. (range 1000..100000, default 2000, runtime-tunable)
/// - [patch]: Set patch radius duration. Allowed range is from 1 to 100 milliseconds. Default value is 2 milliseconds. (range 1000..100000, default 2000, runtime-tunable)
/// - [r]: Set research radius duration. Allowed range is from 2 to 300 milliseconds. Default value is 6 milliseconds. (range 2000..300000, default 6000, runtime-tunable)
/// - [research]: Set research radius duration. Allowed range is from 2 to 300 milliseconds. Default value is 6 milliseconds. (range 2000..300000, default 6000, runtime-tunable)
/// - [s]: Set denoising strength. Allowed range is from 0.00001 to 10000. Default value is 0.00001. (range 0.00001..10000, default 0.00001, runtime-tunable)
/// - [smooth]: Set smooth factor. Default value is `11`. Allowed range is from `1` to `1000`. (range 1..1000, default 11., runtime-tunable)
/// - [strength]: Set denoising strength. Allowed range is from 0.00001 to 10000. Default value is 0.00001. (range 0.00001..10000, default 0.00001, runtime-tunable)
final class AnlmdnSettings {
  /// Default value for [m].
  static const double mDefault = 11.0;

  /// Minimum value for [m].
  static const double mMin = 1.0;

  /// Maximum value for [m].
  static const double mMax = 1000.0;

  /// Default value for [s].
  static const double sDefault = 0.00001;

  /// Minimum value for [s].
  static const double sMin = 0.00001;

  /// Maximum value for [s].
  static const double sMax = 10000.0;

  /// Default value for [smooth].
  static const double smoothDefault = 11.0;

  /// Minimum value for [smooth].
  static const double smoothMin = 1.0;

  /// Maximum value for [smooth].
  static const double smoothMax = 1000.0;

  /// Default value for [strength].
  static const double strengthDefault = 0.00001;

  /// Minimum value for [strength].
  static const double strengthMin = 0.00001;

  /// Maximum value for [strength].
  static const double strengthMax = 10000.0;

  /// Whether this effect is inserted into the audio chain.
  final bool enabled;

  /// set smooth factor
  final double m;

  /// set output mode
  final AnlmdnMode o;

  /// set output mode
  final AnlmdnMode output;

  /// set patch duration
  final Duration p;

  /// set patch duration
  final Duration patch;

  /// set research duration
  final Duration r;

  /// set research duration
  final Duration research;

  /// set denoising strength
  final double s;

  /// set smooth factor
  final double smooth;

  /// set denoising strength
  final double strength;

  /// Creates an [AnlmdnSettings] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default; the effect stays
  /// inactive until [enabled] is set to `true`.
  const AnlmdnSettings({
    this.enabled = false,
    this.m = 11.0,
    this.o = AnlmdnMode.o,
    this.output = AnlmdnMode.o,
    this.p = const Duration(microseconds: 2000),
    this.patch = const Duration(microseconds: 2000),
    this.r = const Duration(microseconds: 6000),
    this.research = const Duration(microseconds: 6000),
    this.s = 0.00001,
    this.smooth = 11.0,
    this.strength = 0.00001,
  });

  /// Returns a copy of this [AnlmdnSettings] with the given fields replaced.
  AnlmdnSettings copyWith({
    bool? enabled,
    double? m,
    AnlmdnMode? o,
    AnlmdnMode? output,
    Duration? p,
    Duration? patch,
    Duration? r,
    Duration? research,
    double? s,
    double? smooth,
    double? strength,
  }) =>
      AnlmdnSettings(
        enabled: enabled ?? this.enabled,
        m: m ?? this.m,
        o: o ?? this.o,
        output: output ?? this.output,
        p: p ?? this.p,
        patch: patch ?? this.patch,
        r: r ?? this.r,
        research: research ?? this.research,
        s: s ?? this.s,
        smooth: smooth ?? this.smooth,
        strength: strength ?? this.strength,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AnlmdnSettings &&
          other.enabled == enabled &&
          other.m == m &&
          other.o == o &&
          other.output == output &&
          other.p == p &&
          other.patch == patch &&
          other.r == r &&
          other.research == research &&
          other.s == s &&
          other.smooth == smooth &&
          other.strength == strength);

  @override
  int get hashCode => Object.hash(
      enabled, m, o, output, p, patch, r, research, s, smooth, strength,);

  @override
  String toString() =>
      'AnlmdnSettings(enabled: $enabled, m: $m, o: $o, output: $output, p: $p, patch: $patch, r: $r, research: $research, s: $s, smooth: $smooth, strength: $strength)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(m >= mMin, 'anlmdn.m must be >= 1');
    assert(m <= mMax, 'anlmdn.m must be <= 1000');
    assert(s >= sMin, 'anlmdn.s must be >= 0.00001');
    assert(s <= sMax, 'anlmdn.s must be <= 10000');
    assert(smooth >= smoothMin, 'anlmdn.smooth must be >= 1');
    assert(smooth <= smoothMax, 'anlmdn.smooth must be <= 1000');
    assert(strength >= strengthMin, 'anlmdn.strength must be >= 0.00001');
    assert(strength <= strengthMax, 'anlmdn.strength must be <= 10000');
    final parts = <String>[];
    if (m != 11.0) parts.add('m=' + _wireDouble(m));
    if (o != AnlmdnMode.o) parts.add('o=' + o.mpvValue);
    if (output != AnlmdnMode.o) parts.add('output=' + output.mpvValue);
    if (p != const Duration(microseconds: 2000))
      parts.add('p=' + _wireDouble(p.inMicroseconds / 1e6));
    if (patch != const Duration(microseconds: 2000))
      parts.add('patch=' + _wireDouble(patch.inMicroseconds / 1e6));
    if (r != const Duration(microseconds: 6000))
      parts.add('r=' + _wireDouble(r.inMicroseconds / 1e6));
    if (research != const Duration(microseconds: 6000))
      parts.add('research=' + _wireDouble(research.inMicroseconds / 1e6));
    if (s != 0.00001) parts.add('s=' + _wireDouble(s));
    if (smooth != 11.0) parts.add('smooth=' + _wireDouble(smooth));
    if (strength != 0.00001) parts.add('strength=' + _wireDouble(strength));
    return parts.isEmpty ? 'lavfi-anlmdn' : 'lavfi-anlmdn=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  List<(String, String)>? _runtimeDiff(AnlmdnSettings prev) {
    final out = <(String, String)>[];
    if (m != prev.m) {
      out.add(('m', _wireDouble(m)));
    }
    if (o != prev.o) {
      out.add(('o', o.mpvValue));
    }
    if (output != prev.output) {
      out.add(('output', output.mpvValue));
    }
    if (p != prev.p) {
      out.add(('p', _wireDouble(p.inMicroseconds / 1e6)));
    }
    if (patch != prev.patch) {
      out.add(('patch', _wireDouble(patch.inMicroseconds / 1e6)));
    }
    if (r != prev.r) {
      out.add(('r', _wireDouble(r.inMicroseconds / 1e6)));
    }
    if (research != prev.research) {
      out.add(('research', _wireDouble(research.inMicroseconds / 1e6)));
    }
    if (s != prev.s) {
      out.add(('s', _wireDouble(s)));
    }
    if (smooth != prev.smooth) {
      out.add(('smooth', _wireDouble(smooth)));
    }
    if (strength != prev.strength) {
      out.add(('strength', _wireDouble(strength)));
    }
    return out;
  }
}

/// Configuration for the `apad` audio effect.
///
/// Pad the end of an audio stream with silence.
///
/// This can be used together with @command{ffmpeg} @option{-shortest} to
/// extend audio streams to the same length as the video stream.
///
/// A description of the accepted options follows.
///
/// Parameters:
/// - [packet_size]: Set silence packet size. Default value is 4096. (range 0..2147483647, default 4096)
/// - [pad_dur]: Specify the duration of samples of silence to add. See time duration syntax for the accepted syntax. Used only if set to non-negative value. (range -1..9223372036854775807, default -1)
/// - [pad_len]: Set the number of samples of silence to add to the end. After the value is reached, the stream is terminated. This option is mutually exclusive with @option{whole_len}. (range -1..9223372036854775807, default -1)
/// - [whole_dur]: Specify the minimum total duration in the output audio stream. See time duration syntax for the accepted syntax. Used only if set to non-negative value. If the value is longer than the input audio length, silence is added to the end, until the value is reached. This option is mutually exclusive with @option{pad_dur} (range -1..9223372036854775807, default -1)
/// - [whole_len]: Set the minimum total number of samples in the output audio stream. If the value is longer than the input audio length, silence is added to the end, until the value is reached. This option is mutually exclusive with @option{pad_len}. (range -1..9223372036854775807, default -1)
final class ApadSettings {
  /// Default value for [packet_size].
  static const int packet_sizeDefault = 4096;

  /// Minimum value for [packet_size].
  static const int packet_sizeMin = 0;

  /// Maximum value for [packet_size].
  static const int packet_sizeMax = 2147483647;

  /// Default value for [pad_len].
  static const int pad_lenDefault = -1;

  /// Minimum value for [pad_len].
  static const int pad_lenMin = -1;

  /// Maximum value for [pad_len].
  static const int pad_lenMax = 9223372036854775807;

  /// Default value for [whole_len].
  static const int whole_lenDefault = -1;

  /// Minimum value for [whole_len].
  static const int whole_lenMin = -1;

  /// Maximum value for [whole_len].
  static const int whole_lenMax = 9223372036854775807;

  /// Whether this effect is inserted into the audio chain.
  final bool enabled;

  /// set silence packet size
  final int packet_size;

  /// set duration of silence to add
  final Duration pad_dur;

  /// set number of samples of silence to add
  final int pad_len;

  /// set minimum target duration in the audio stream
  final Duration whole_dur;

  /// set minimum target number of samples in the audio stream
  final int whole_len;

  /// Creates an [ApadSettings] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default; the effect stays
  /// inactive until [enabled] is set to `true`.
  const ApadSettings({
    this.enabled = false,
    this.packet_size = 4096,
    this.pad_dur = const Duration(microseconds: -1),
    this.pad_len = -1,
    this.whole_dur = const Duration(microseconds: -1),
    this.whole_len = -1,
  });

  /// Returns a copy of this [ApadSettings] with the given fields replaced.
  ApadSettings copyWith({
    bool? enabled,
    int? packet_size,
    Duration? pad_dur,
    int? pad_len,
    Duration? whole_dur,
    int? whole_len,
  }) =>
      ApadSettings(
        enabled: enabled ?? this.enabled,
        packet_size: packet_size ?? this.packet_size,
        pad_dur: pad_dur ?? this.pad_dur,
        pad_len: pad_len ?? this.pad_len,
        whole_dur: whole_dur ?? this.whole_dur,
        whole_len: whole_len ?? this.whole_len,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ApadSettings &&
          other.enabled == enabled &&
          other.packet_size == packet_size &&
          other.pad_dur == pad_dur &&
          other.pad_len == pad_len &&
          other.whole_dur == whole_dur &&
          other.whole_len == whole_len);

  @override
  int get hashCode =>
      Object.hash(enabled, packet_size, pad_dur, pad_len, whole_dur, whole_len);

  @override
  String toString() =>
      'ApadSettings(enabled: $enabled, packet_size: $packet_size, pad_dur: $pad_dur, pad_len: $pad_len, whole_dur: $whole_dur, whole_len: $whole_len)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(packet_size >= packet_sizeMin, 'apad.packet_size must be >= 0');
    assert(packet_size <= packet_sizeMax,
        'apad.packet_size must be <= 2147483647',);
    assert(pad_len >= pad_lenMin, 'apad.pad_len must be >= -1');
    assert(
        pad_len <= pad_lenMax, 'apad.pad_len must be <= 9223372036854775807',);
    assert(whole_len >= whole_lenMin, 'apad.whole_len must be >= -1');
    assert(whole_len <= whole_lenMax,
        'apad.whole_len must be <= 9223372036854775807',);
    final parts = <String>[];
    if (packet_size != 4096) parts.add('packet_size=' + packet_size.toString());
    if (pad_dur != const Duration(microseconds: -1))
      parts.add('pad_dur=' + _wireDouble(pad_dur.inMicroseconds / 1e6));
    if (pad_len != -1) parts.add('pad_len=' + pad_len.toString());
    if (whole_dur != const Duration(microseconds: -1))
      parts.add('whole_dur=' + _wireDouble(whole_dur.inMicroseconds / 1e6));
    if (whole_len != -1) parts.add('whole_len=' + whole_len.toString());
    return parts.isEmpty ? 'lavfi-apad' : 'lavfi-apad=' + parts.join(':');
  }
}

/// Configuration for the `aphaser` audio effect.
///
/// Add a phasing effect to the input audio.
///
/// A phaser filter creates series of peaks and troughs in the frequency spectrum.
/// The position of the peaks and troughs are modulated so that they vary over time, creating a sweeping effect.
///
/// A description of the accepted parameters follows.
///
/// Parameters:
/// - [decay]: Set decay. Default is 0.4. (range 0...99, default .4)
/// - [delay]: Set delay in milliseconds. Default is 3.0. (range 0.1..5, default 3.)
/// - [in_gain]: Set input gain. Default is 0.4. (range 0..1, default .4)
/// - [out_gain]: Set output gain. Default is 0.74 (range 0..1e9, default .74)
/// - [speed]: Set modulation speed in Hz. Default is 0.5. (range .1..2, default .5)
/// - [type]: Set modulation type. Default is triangular.  It accepts the following values: (default WAVE_TRI)
final class AphaserSettings {
  /// Default value for [decay].
  static const double decayDefault = .4;

  /// Minimum value for [decay].
  static const double decayMin = 0.0;

  /// Maximum value for [decay].
  static const double decayMax = .99;

  /// Default value for [delay].
  static const double delayDefault = 3.0;

  /// Minimum value for [delay].
  static const double delayMin = 0.1;

  /// Maximum value for [delay].
  static const double delayMax = 5.0;

  /// Default value for [in_gain].
  static const double in_gainDefault = .4;

  /// Minimum value for [in_gain].
  static const double in_gainMin = 0.0;

  /// Maximum value for [in_gain].
  static const double in_gainMax = 1.0;

  /// Default value for [out_gain].
  static const double out_gainDefault = .74;

  /// Minimum value for [out_gain].
  static const double out_gainMin = 0.0;

  /// Maximum value for [out_gain].
  static const double out_gainMax = 1e9;

  /// Default value for [speed].
  static const double speedDefault = .5;

  /// Minimum value for [speed].
  static const double speedMin = .1;

  /// Maximum value for [speed].
  static const double speedMax = 2.0;

  /// Whether this effect is inserted into the audio chain.
  final bool enabled;

  /// set decay
  final double decay;

  /// set delay in milliseconds
  final double delay;

  /// set input gain
  final double in_gain;

  /// set output gain
  final double out_gain;

  /// set modulation speed
  final double speed;

  /// set modulation type
  final AphaserType type;

  /// Creates an [AphaserSettings] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default; the effect stays
  /// inactive until [enabled] is set to `true`.
  const AphaserSettings({
    this.enabled = false,
    this.decay = .4,
    this.delay = 3.0,
    this.in_gain = .4,
    this.out_gain = .74,
    this.speed = .5,
    this.type = AphaserType.triangular,
  });

  /// Returns a copy of this [AphaserSettings] with the given fields replaced.
  AphaserSettings copyWith({
    bool? enabled,
    double? decay,
    double? delay,
    double? in_gain,
    double? out_gain,
    double? speed,
    AphaserType? type,
  }) =>
      AphaserSettings(
        enabled: enabled ?? this.enabled,
        decay: decay ?? this.decay,
        delay: delay ?? this.delay,
        in_gain: in_gain ?? this.in_gain,
        out_gain: out_gain ?? this.out_gain,
        speed: speed ?? this.speed,
        type: type ?? this.type,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AphaserSettings &&
          other.enabled == enabled &&
          other.decay == decay &&
          other.delay == delay &&
          other.in_gain == in_gain &&
          other.out_gain == out_gain &&
          other.speed == speed &&
          other.type == type);

  @override
  int get hashCode =>
      Object.hash(enabled, decay, delay, in_gain, out_gain, speed, type);

  @override
  String toString() =>
      'AphaserSettings(enabled: $enabled, decay: $decay, delay: $delay, in_gain: $in_gain, out_gain: $out_gain, speed: $speed, type: $type)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(decay >= decayMin, 'aphaser.decay must be >= 0');
    assert(decay <= decayMax, 'aphaser.decay must be <= .99');
    assert(delay >= delayMin, 'aphaser.delay must be >= 0.1');
    assert(delay <= delayMax, 'aphaser.delay must be <= 5');
    assert(in_gain >= in_gainMin, 'aphaser.in_gain must be >= 0');
    assert(in_gain <= in_gainMax, 'aphaser.in_gain must be <= 1');
    assert(out_gain >= out_gainMin, 'aphaser.out_gain must be >= 0');
    assert(out_gain <= out_gainMax, 'aphaser.out_gain must be <= 1e9');
    assert(speed >= speedMin, 'aphaser.speed must be >= .1');
    assert(speed <= speedMax, 'aphaser.speed must be <= 2');
    final parts = <String>[];
    if (decay != .4) parts.add('decay=' + _wireDouble(decay));
    if (delay != 3.0) parts.add('delay=' + _wireDouble(delay));
    if (in_gain != .4) parts.add('in_gain=' + _wireDouble(in_gain));
    if (out_gain != .74) parts.add('out_gain=' + _wireDouble(out_gain));
    if (speed != .5) parts.add('speed=' + _wireDouble(speed));
    if (type != AphaserType.triangular) parts.add('type=' + type.mpvValue);
    return parts.isEmpty ? 'lavfi-aphaser' : 'lavfi-aphaser=' + parts.join(':');
  }
}

/// Configuration for the `aphaseshift` audio effect.
///
/// Apply phase shift to input audio samples.
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [level]: Set output gain applied to final output. Allowed range is from 0.0 to 1.0. Default value is 1.0. (range 0.0..1.0, default 1, runtime-tunable)
/// - [order]: Set filter order used for filtering. Allowed range is from 1 to 16. Default value is 8. (range 1..16, default 8, runtime-tunable)
/// - [shift]: Specify phase shift. Allowed range is from -1.0 to 1.0. Default value is 0.0. (range -1.0..1.0, default 0, runtime-tunable)
final class AphaseshiftSettings {
  /// Default value for [level].
  static const double levelDefault = 1.0;

  /// Minimum value for [level].
  static const double levelMin = 0.0;

  /// Maximum value for [level].
  static const double levelMax = 1.0;

  /// Default value for [order].
  static const int orderDefault = 8;

  /// Minimum value for [order].
  static const int orderMin = 1;

  /// Maximum value for [order].
  static const int orderMax = 16;

  /// Default value for [shift].
  static const double shiftDefault = 0.0;

  /// Minimum value for [shift].
  static const double shiftMin = -1.0;

  /// Maximum value for [shift].
  static const double shiftMax = 1.0;

  /// Whether this effect is inserted into the audio chain.
  final bool enabled;

  /// set output level
  final double level;

  /// set filter order
  final int order;

  /// set phase shift
  final double shift;

  /// Creates an [AphaseshiftSettings] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default; the effect stays
  /// inactive until [enabled] is set to `true`.
  const AphaseshiftSettings({
    this.enabled = false,
    this.level = 1.0,
    this.order = 8,
    this.shift = 0.0,
  });

  /// Returns a copy of this [AphaseshiftSettings] with the given fields replaced.
  AphaseshiftSettings copyWith({
    bool? enabled,
    double? level,
    int? order,
    double? shift,
  }) =>
      AphaseshiftSettings(
        enabled: enabled ?? this.enabled,
        level: level ?? this.level,
        order: order ?? this.order,
        shift: shift ?? this.shift,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AphaseshiftSettings &&
          other.enabled == enabled &&
          other.level == level &&
          other.order == order &&
          other.shift == shift);

  @override
  int get hashCode => Object.hash(enabled, level, order, shift);

  @override
  String toString() =>
      'AphaseshiftSettings(enabled: $enabled, level: $level, order: $order, shift: $shift)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(level >= levelMin, 'aphaseshift.level must be >= 0.0');
    assert(level <= levelMax, 'aphaseshift.level must be <= 1.0');
    assert(order >= orderMin, 'aphaseshift.order must be >= 1');
    assert(order <= orderMax, 'aphaseshift.order must be <= 16');
    assert(shift >= shiftMin, 'aphaseshift.shift must be >= -1.0');
    assert(shift <= shiftMax, 'aphaseshift.shift must be <= 1.0');
    final parts = <String>[];
    if (level != 1.0) parts.add('level=' + _wireDouble(level));
    if (order != 8) parts.add('order=' + order.toString());
    if (shift != 0.0) parts.add('shift=' + _wireDouble(shift));
    return parts.isEmpty
        ? 'lavfi-aphaseshift'
        : 'lavfi-aphaseshift=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  List<(String, String)>? _runtimeDiff(AphaseshiftSettings prev) {
    final out = <(String, String)>[];
    if (level != prev.level) {
      out.add(('level', _wireDouble(level)));
    }
    if (order != prev.order) {
      out.add(('order', order.toString()));
    }
    if (shift != prev.shift) {
      out.add(('shift', _wireDouble(shift)));
    }
    return out;
  }
}

/// Configuration for the `apsyclip` audio effect.
///
/// Apply Psychoacoustic clipper to input audio stream.
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [adaptive]: Set strength of adaptive distortion applied. Default value is 0.5. Allowed range is from 0 to 1. (range 0..1, default 0.5, runtime-tunable)
/// - [clip]: Set the clipping start value. Default value is 0dBFS or 1. (range .015625..1, default 1, runtime-tunable)
/// - [diff]: Output only difference samples, useful to hear introduced distortions. By default is disabled. (range 0..1, default 0, runtime-tunable)
/// - [iterations]: Set number of iterations of psychoacoustic clipper. Allowed range is from 1 to 20. Default value is 10. (range 1..20, default 10, runtime-tunable)
/// - [level]: Auto level output signal. Default is disabled. This normalizes audio back to 0dBFS if enabled. (range 0..1, default 0, runtime-tunable)
/// - [level_in]: Set input gain. By default it is 1. Range is [0.015625 - 64]. (range .015625..64, default 1, runtime-tunable)
/// - [level_out]: Set output gain. By default it is 1. Range is [0.015625 - 64]. (range .015625..64, default 1, runtime-tunable)
final class ApsyclipSettings {
  /// Default value for [adaptive].
  static const double adaptiveDefault = 0.5;

  /// Minimum value for [adaptive].
  static const double adaptiveMin = 0.0;

  /// Maximum value for [adaptive].
  static const double adaptiveMax = 1.0;

  /// Default value for [clip].
  static const double clipDefault = 1.0;

  /// Minimum value for [clip].
  static const double clipMin = .015625;

  /// Maximum value for [clip].
  static const double clipMax = 1.0;

  /// Default value for [iterations].
  static const int iterationsDefault = 10;

  /// Minimum value for [iterations].
  static const int iterationsMin = 1;

  /// Maximum value for [iterations].
  static const int iterationsMax = 20;

  /// Default value for [level_in].
  static const double level_inDefault = 1.0;

  /// Minimum value for [level_in].
  static const double level_inMin = .015625;

  /// Maximum value for [level_in].
  static const double level_inMax = 64.0;

  /// Default value for [level_out].
  static const double level_outDefault = 1.0;

  /// Minimum value for [level_out].
  static const double level_outMin = .015625;

  /// Maximum value for [level_out].
  static const double level_outMax = 64.0;

  /// Whether this effect is inserted into the audio chain.
  final bool enabled;

  /// set adaptive distortion
  final double adaptive;

  /// set clip level
  final double clip;

  /// enable difference
  final bool diff;

  /// set iterations
  final int iterations;

  /// set auto level
  final bool level;

  /// set input level
  final double level_in;

  /// set output level
  final double level_out;

  /// Creates an [ApsyclipSettings] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default; the effect stays
  /// inactive until [enabled] is set to `true`.
  const ApsyclipSettings({
    this.enabled = false,
    this.adaptive = 0.5,
    this.clip = 1.0,
    this.diff = false,
    this.iterations = 10,
    this.level = false,
    this.level_in = 1.0,
    this.level_out = 1.0,
  });

  /// Returns a copy of this [ApsyclipSettings] with the given fields replaced.
  ApsyclipSettings copyWith({
    bool? enabled,
    double? adaptive,
    double? clip,
    bool? diff,
    int? iterations,
    bool? level,
    double? level_in,
    double? level_out,
  }) =>
      ApsyclipSettings(
        enabled: enabled ?? this.enabled,
        adaptive: adaptive ?? this.adaptive,
        clip: clip ?? this.clip,
        diff: diff ?? this.diff,
        iterations: iterations ?? this.iterations,
        level: level ?? this.level,
        level_in: level_in ?? this.level_in,
        level_out: level_out ?? this.level_out,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ApsyclipSettings &&
          other.enabled == enabled &&
          other.adaptive == adaptive &&
          other.clip == clip &&
          other.diff == diff &&
          other.iterations == iterations &&
          other.level == level &&
          other.level_in == level_in &&
          other.level_out == level_out);

  @override
  int get hashCode => Object.hash(
      enabled, adaptive, clip, diff, iterations, level, level_in, level_out,);

  @override
  String toString() =>
      'ApsyclipSettings(enabled: $enabled, adaptive: $adaptive, clip: $clip, diff: $diff, iterations: $iterations, level: $level, level_in: $level_in, level_out: $level_out)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(adaptive >= adaptiveMin, 'apsyclip.adaptive must be >= 0');
    assert(adaptive <= adaptiveMax, 'apsyclip.adaptive must be <= 1');
    assert(clip >= clipMin, 'apsyclip.clip must be >= .015625');
    assert(clip <= clipMax, 'apsyclip.clip must be <= 1');
    assert(iterations >= iterationsMin, 'apsyclip.iterations must be >= 1');
    assert(iterations <= iterationsMax, 'apsyclip.iterations must be <= 20');
    assert(level_in >= level_inMin, 'apsyclip.level_in must be >= .015625');
    assert(level_in <= level_inMax, 'apsyclip.level_in must be <= 64');
    assert(level_out >= level_outMin, 'apsyclip.level_out must be >= .015625');
    assert(level_out <= level_outMax, 'apsyclip.level_out must be <= 64');
    final parts = <String>[];
    if (adaptive != 0.5) parts.add('adaptive=' + _wireDouble(adaptive));
    if (clip != 1.0) parts.add('clip=' + _wireDouble(clip));
    if (diff != false) parts.add('diff=' + (diff ? '1' : '0'));
    if (iterations != 10) parts.add('iterations=' + iterations.toString());
    if (level != false) parts.add('level=' + (level ? '1' : '0'));
    if (level_in != 1.0) parts.add('level_in=' + _wireDouble(level_in));
    if (level_out != 1.0) parts.add('level_out=' + _wireDouble(level_out));
    return parts.isEmpty
        ? 'lavfi-apsyclip'
        : 'lavfi-apsyclip=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  List<(String, String)>? _runtimeDiff(ApsyclipSettings prev) {
    final out = <(String, String)>[];
    if (adaptive != prev.adaptive) {
      out.add(('adaptive', _wireDouble(adaptive)));
    }
    if (clip != prev.clip) {
      out.add(('clip', _wireDouble(clip)));
    }
    if (diff != prev.diff) {
      out.add(('diff', (diff ? '1' : '0')));
    }
    if (iterations != prev.iterations) {
      out.add(('iterations', iterations.toString()));
    }
    if (level != prev.level) {
      out.add(('level', (level ? '1' : '0')));
    }
    if (level_in != prev.level_in) {
      out.add(('level_in', _wireDouble(level_in)));
    }
    if (level_out != prev.level_out) {
      out.add(('level_out', _wireDouble(level_out)));
    }
    return out;
  }
}

/// Configuration for the `apulsator` audio effect.
///
/// Audio pulsator is something between an autopanner and a tremolo.
/// But it can produce funny stereo effects as well. Pulsator changes the volume
/// of the left and right channel based on a LFO (low frequency oscillator) with
/// different waveforms and shifted phases.
/// This filter have the ability to define an offset between left and right
/// channel. An offset of 0 means that both LFO shapes match each other.
/// The left and right channel are altered equally - a conventional tremolo.
/// An offset of 50% means that the shape of the right channel is exactly shifted
/// in phase (or moved backwards about half of the frequency) - pulsator acts as
/// an autopanner. At 1 both curves match again. Every setting in between moves the
/// phase shift gapless between all stages and produces some "bypassing" sounds with
/// sine and triangle waveforms. The more you set the offset near 1 (starting from
/// the 0.5) the faster the signal passes from the left to the right speaker.
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [amount]: Set modulation. Define how much of original signal is affected by the LFO. (range 0..1, default 1)
/// - [bpm]: Set bpm. Default is 120. Allowed range is [30 - 300]. Only used if timing is set to bpm. (range 30..300, default 120)
/// - [hz]: Set frequency in Hz. Default is 2. Allowed range is [0.01 - 100]. Only used if timing is set to hz. (range 0.01..100, default 2)
/// - [level_in]: Set input gain. By default it is 1. Range is [0.015625 - 64]. (range 0.015625..64, default 1)
/// - [level_out]: Set output gain. By default it is 1. Range is [0.015625 - 64]. (range 0.015625..64, default 1)
/// - [mode]: Set waveform shape the LFO will use. Can be one of: sine, triangle, square, sawup or sawdown. Default is sine. (range 0..4, default SINE)
/// - [ms]: Set ms. Default is 500. Allowed range is [10 - 2000]. Only used if timing is set to ms. (range 10..2000, default 500)
/// - [offset_l]: Set left channel offset. Default is 0. Allowed range is [0 - 1]. (range 0..1, default 0)
/// - [offset_r]: Set right channel offset. Default is 0.5. Allowed range is [0 - 1]. (range 0..1, default .5)
/// - [timing]: Set possible timing mode. Can be one of: bpm, ms or hz. Default is hz. (range 0..2, default 2)
/// - [width]: Set pulse width. Default is 1. Allowed range is [0 - 2]. (range 0..2, default 1)
final class ApulsatorSettings {
  /// Default value for [amount].
  static const double amountDefault = 1.0;

  /// Minimum value for [amount].
  static const double amountMin = 0.0;

  /// Maximum value for [amount].
  static const double amountMax = 1.0;

  /// Default value for [bpm].
  static const double bpmDefault = 120.0;

  /// Minimum value for [bpm].
  static const double bpmMin = 30.0;

  /// Maximum value for [bpm].
  static const double bpmMax = 300.0;

  /// Default value for [hz].
  static const double hzDefault = 2.0;

  /// Minimum value for [hz].
  static const double hzMin = 0.01;

  /// Maximum value for [hz].
  static const double hzMax = 100.0;

  /// Default value for [level_in].
  static const double level_inDefault = 1.0;

  /// Minimum value for [level_in].
  static const double level_inMin = 0.015625;

  /// Maximum value for [level_in].
  static const double level_inMax = 64.0;

  /// Default value for [level_out].
  static const double level_outDefault = 1.0;

  /// Minimum value for [level_out].
  static const double level_outMin = 0.015625;

  /// Maximum value for [level_out].
  static const double level_outMax = 64.0;

  /// Default value for [ms].
  static const int msDefault = 500;

  /// Minimum value for [ms].
  static const int msMin = 10;

  /// Maximum value for [ms].
  static const int msMax = 2000;

  /// Default value for [offset_l].
  static const double offset_lDefault = 0.0;

  /// Minimum value for [offset_l].
  static const double offset_lMin = 0.0;

  /// Maximum value for [offset_l].
  static const double offset_lMax = 1.0;

  /// Default value for [offset_r].
  static const double offset_rDefault = .5;

  /// Minimum value for [offset_r].
  static const double offset_rMin = 0.0;

  /// Maximum value for [offset_r].
  static const double offset_rMax = 1.0;

  /// Default value for [width].
  static const double widthDefault = 1.0;

  /// Minimum value for [width].
  static const double widthMin = 0.0;

  /// Maximum value for [width].
  static const double widthMax = 2.0;

  /// Whether this effect is inserted into the audio chain.
  final bool enabled;

  /// set modulation
  final double amount;

  /// set BPM
  final double bpm;

  /// set frequency
  final double hz;

  /// set input gain
  final double level_in;

  /// set output gain
  final double level_out;

  /// set mode
  final ApulsatorMode mode;

  /// set ms
  final int ms;

  /// set offset L
  final double offset_l;

  /// set offset R
  final double offset_r;

  /// set timing
  final ApulsatorTiming timing;

  /// set pulse width
  final double width;

  /// Creates an [ApulsatorSettings] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default; the effect stays
  /// inactive until [enabled] is set to `true`.
  const ApulsatorSettings({
    this.enabled = false,
    this.amount = 1.0,
    this.bpm = 120.0,
    this.hz = 2.0,
    this.level_in = 1.0,
    this.level_out = 1.0,
    this.mode = ApulsatorMode.sine,
    this.ms = 500,
    this.offset_l = 0.0,
    this.offset_r = .5,
    this.timing = ApulsatorTiming.hz,
    this.width = 1.0,
  });

  /// Returns a copy of this [ApulsatorSettings] with the given fields replaced.
  ApulsatorSettings copyWith({
    bool? enabled,
    double? amount,
    double? bpm,
    double? hz,
    double? level_in,
    double? level_out,
    ApulsatorMode? mode,
    int? ms,
    double? offset_l,
    double? offset_r,
    ApulsatorTiming? timing,
    double? width,
  }) =>
      ApulsatorSettings(
        enabled: enabled ?? this.enabled,
        amount: amount ?? this.amount,
        bpm: bpm ?? this.bpm,
        hz: hz ?? this.hz,
        level_in: level_in ?? this.level_in,
        level_out: level_out ?? this.level_out,
        mode: mode ?? this.mode,
        ms: ms ?? this.ms,
        offset_l: offset_l ?? this.offset_l,
        offset_r: offset_r ?? this.offset_r,
        timing: timing ?? this.timing,
        width: width ?? this.width,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ApulsatorSettings &&
          other.enabled == enabled &&
          other.amount == amount &&
          other.bpm == bpm &&
          other.hz == hz &&
          other.level_in == level_in &&
          other.level_out == level_out &&
          other.mode == mode &&
          other.ms == ms &&
          other.offset_l == offset_l &&
          other.offset_r == offset_r &&
          other.timing == timing &&
          other.width == width);

  @override
  int get hashCode => Object.hash(enabled, amount, bpm, hz, level_in, level_out,
      mode, ms, offset_l, offset_r, timing, width,);

  @override
  String toString() =>
      'ApulsatorSettings(enabled: $enabled, amount: $amount, bpm: $bpm, hz: $hz, level_in: $level_in, level_out: $level_out, mode: $mode, ms: $ms, offset_l: $offset_l, offset_r: $offset_r, timing: $timing, width: $width)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(amount >= amountMin, 'apulsator.amount must be >= 0');
    assert(amount <= amountMax, 'apulsator.amount must be <= 1');
    assert(bpm >= bpmMin, 'apulsator.bpm must be >= 30');
    assert(bpm <= bpmMax, 'apulsator.bpm must be <= 300');
    assert(hz >= hzMin, 'apulsator.hz must be >= 0.01');
    assert(hz <= hzMax, 'apulsator.hz must be <= 100');
    assert(level_in >= level_inMin, 'apulsator.level_in must be >= 0.015625');
    assert(level_in <= level_inMax, 'apulsator.level_in must be <= 64');
    assert(
        level_out >= level_outMin, 'apulsator.level_out must be >= 0.015625',);
    assert(level_out <= level_outMax, 'apulsator.level_out must be <= 64');
    assert(ms >= msMin, 'apulsator.ms must be >= 10');
    assert(ms <= msMax, 'apulsator.ms must be <= 2000');
    assert(offset_l >= offset_lMin, 'apulsator.offset_l must be >= 0');
    assert(offset_l <= offset_lMax, 'apulsator.offset_l must be <= 1');
    assert(offset_r >= offset_rMin, 'apulsator.offset_r must be >= 0');
    assert(offset_r <= offset_rMax, 'apulsator.offset_r must be <= 1');
    assert(width >= widthMin, 'apulsator.width must be >= 0');
    assert(width <= widthMax, 'apulsator.width must be <= 2');
    final parts = <String>[];
    if (amount != 1.0) parts.add('amount=' + _wireDouble(amount));
    if (bpm != 120.0) parts.add('bpm=' + _wireDouble(bpm));
    if (hz != 2.0) parts.add('hz=' + _wireDouble(hz));
    if (level_in != 1.0) parts.add('level_in=' + _wireDouble(level_in));
    if (level_out != 1.0) parts.add('level_out=' + _wireDouble(level_out));
    if (mode != ApulsatorMode.sine) parts.add('mode=' + mode.mpvValue);
    if (ms != 500) parts.add('ms=' + ms.toString());
    if (offset_l != 0.0) parts.add('offset_l=' + _wireDouble(offset_l));
    if (offset_r != .5) parts.add('offset_r=' + _wireDouble(offset_r));
    if (timing != ApulsatorTiming.hz) parts.add('timing=' + timing.mpvValue);
    if (width != 1.0) parts.add('width=' + _wireDouble(width));
    return parts.isEmpty
        ? 'lavfi-apulsator'
        : 'lavfi-apulsator=' + parts.join(':');
  }
}

/// Configuration for the `aresample` audio effect.
///
/// Resample the input audio to the specified parameters, using the
/// libswresample library. If none are specified then the filter will
/// automatically convert between its input and output.
///
/// This filter is also able to stretch/squeeze the audio data to make it match
/// the timestamps or to inject silence / cut out audio to make it match the
/// timestamps, do a combination of both or do neither.
///
/// The filter accepts the syntax
/// [`sample_rate`:]`resampler_options`, where `sample_rate`
/// expresses a sample rate and `resampler_options` is a list of
/// `key`=`value` pairs, separated by ":". See the
/// Resampler Options
/// for the complete list of supported options.
///
/// Resample the input audio to 44100Hz:
///
/// - Stretch/squeeze samples to the given timestamps, with a maximum of 1000
/// samples per second compensation:
///
/// Parameters:
/// - [sample_rate]:  (range 0..768000, default 0)
final class AresampleSettings {
  /// Default value for [sample_rate].
  static const int sample_rateDefault = 0;

  /// Minimum value for [sample_rate].
  static const int sample_rateMin = 0;

  /// Maximum value for [sample_rate].
  static const int sample_rateMax = 768000;

  /// Whether this effect is inserted into the audio chain.
  final bool enabled;

  /// The `sample_rate` parameter.
  final int sample_rate;

  /// Creates an [AresampleSettings] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default; the effect stays
  /// inactive until [enabled] is set to `true`.
  const AresampleSettings({
    this.enabled = false,
    this.sample_rate = 0,
  });

  /// Returns a copy of this [AresampleSettings] with the given fields replaced.
  AresampleSettings copyWith({
    bool? enabled,
    int? sample_rate,
  }) =>
      AresampleSettings(
        enabled: enabled ?? this.enabled,
        sample_rate: sample_rate ?? this.sample_rate,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AresampleSettings &&
          other.enabled == enabled &&
          other.sample_rate == sample_rate);

  @override
  int get hashCode => Object.hash(enabled, sample_rate);

  @override
  String toString() =>
      'AresampleSettings(enabled: $enabled, sample_rate: $sample_rate)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(sample_rate >= sample_rateMin, 'aresample.sample_rate must be >= 0');
    assert(sample_rate <= sample_rateMax,
        'aresample.sample_rate must be <= 768000',);
    final parts = <String>[];
    if (sample_rate != 0) parts.add('sample_rate=' + sample_rate.toString());
    return parts.isEmpty
        ? 'lavfi-aresample'
        : 'lavfi-aresample=' + parts.join(':');
  }
}

/// Configuration for the `arnndn` audio effect.
///
/// Reduce noise from speech using Recurrent Neural Networks.
///
/// This filter accepts the following options:
///
/// Parameters:
/// - [m]: Set train model file to load. This option is always required. (range 0..0, default "", runtime-tunable)
/// - [mix]: Set how much to mix filtered samples into final output. Allowed range is from -1 to 1. Default value is 1. Negative values are special, they set how much to keep filtered noise in the final filter output. Set this option to -1 to hear actual noise removed from input signal. (range -1..1, default 1.0, runtime-tunable)
/// - [model]: Set train model file to load. This option is always required. (range 0..0, default "", runtime-tunable)
final class ArnndnSettings {
  /// Default value for [mix].
  static const double mixDefault = 1.0;

  /// Minimum value for [mix].
  static const double mixMin = -1.0;

  /// Maximum value for [mix].
  static const double mixMax = 1.0;

  /// Whether this effect is inserted into the audio chain.
  final bool enabled;

  /// set model name
  final String m;

  /// set output vs input mix
  final double mix;

  /// set model name
  final String model;

  /// Creates an [ArnndnSettings] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default; the effect stays
  /// inactive until [enabled] is set to `true`.
  const ArnndnSettings({
    this.enabled = false,
    this.m = '',
    this.mix = 1.0,
    required this.model,
  });

  /// Returns a copy of this [ArnndnSettings] with the given fields replaced.
  ArnndnSettings copyWith({
    bool? enabled,
    String? m,
    double? mix,
    String? model,
  }) =>
      ArnndnSettings(
        enabled: enabled ?? this.enabled,
        m: m ?? this.m,
        mix: mix ?? this.mix,
        model: model ?? this.model,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ArnndnSettings &&
          other.enabled == enabled &&
          other.m == m &&
          other.mix == mix &&
          other.model == model);

  @override
  int get hashCode => Object.hash(enabled, m, mix, model);

  @override
  String toString() =>
      'ArnndnSettings(enabled: $enabled, m: $m, mix: $mix, model: $model)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(mix >= mixMin, 'arnndn.mix must be >= -1');
    assert(mix <= mixMax, 'arnndn.mix must be <= 1');
    final parts = <String>[];
    if (m != '') parts.add('m=' + '[' + m + ']');
    if (mix != 1.0) parts.add('mix=' + _wireDouble(mix));
    parts.add('model=' + '[' + model + ']');
    return parts.isEmpty ? 'lavfi-arnndn' : 'lavfi-arnndn=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  List<(String, String)>? _runtimeDiff(ArnndnSettings prev) {
    final out = <(String, String)>[];
    if (m != prev.m) {
      out.add(('m', m));
    }
    if (mix != prev.mix) {
      out.add(('mix', _wireDouble(mix)));
    }
    if (model != prev.model) {
      out.add(('model', model));
    }
    return out;
  }
}

/// Configuration for the `asetrate` audio effect.
///
/// Set the sample rate without altering the PCM data.
/// This will result in a change of speed and pitch.
///
/// The filter accepts the following options:
final class AsetrateSettings {
  /// Whether this effect is inserted into the audio chain.
  final bool enabled;

  /// Creates an [AsetrateSettings] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default; the effect stays
  /// inactive until [enabled] is set to `true`.
  const AsetrateSettings({
    this.enabled = false,
  });

  /// Returns a copy of this [AsetrateSettings] with the given fields replaced.
  AsetrateSettings copyWith({
    bool? enabled,
  }) =>
      AsetrateSettings(
        enabled: enabled ?? this.enabled,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AsetrateSettings && other.enabled == enabled);

  @override
  int get hashCode => enabled.hashCode;

  @override
  String toString() => 'AsetrateSettings(enabled: $enabled)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    return 'lavfi-asetrate';
  }
}

/// Configuration for the `asoftclip` audio effect.
///
/// Apply audio soft clipping.
///
/// Soft clipping is a type of distortion effect where the amplitude of a signal is saturated
/// along a smooth curve, rather than the abrupt shape of hard-clipping.
///
/// This filter accepts the following options:
///
/// Parameters:
/// - [output]: Set gain applied to output. Default value is 0dB or 1. (range 0.000001..16, default 1, runtime-tunable)
/// - [oversample]: Set oversampling factor. (range 1..64, default 1, runtime-tunable)
/// - [param]: Set additional parameter which controls sigmoid function. (range 0.01..3, default 1, runtime-tunable)
/// - [threshold]: Set threshold from where to start clipping. Default value is 0dB or 1. (range 0.000001..1, default 1, runtime-tunable)
/// - [type]: Set type of soft-clipping.  It accepts the following values: (range -1..7, default 0, runtime-tunable)
final class AsoftclipSettings {
  /// Default value for [output].
  static const double outputDefault = 1.0;

  /// Minimum value for [output].
  static const double outputMin = 0.000001;

  /// Maximum value for [output].
  static const double outputMax = 16.0;

  /// Default value for [oversample].
  static const int oversampleDefault = 1;

  /// Minimum value for [oversample].
  static const int oversampleMin = 1;

  /// Maximum value for [oversample].
  static const int oversampleMax = 64;

  /// Default value for [param].
  static const double paramDefault = 1.0;

  /// Minimum value for [param].
  static const double paramMin = 0.01;

  /// Maximum value for [param].
  static const double paramMax = 3.0;

  /// Default value for [threshold].
  static const double thresholdDefault = 1.0;

  /// Minimum value for [threshold].
  static const double thresholdMin = 0.000001;

  /// Maximum value for [threshold].
  static const double thresholdMax = 1.0;

  /// Whether this effect is inserted into the audio chain.
  final bool enabled;

  /// set softclip output gain
  final double output;

  /// set oversample factor
  final int oversample;

  /// set softclip parameter
  final double param;

  /// set softclip threshold
  final double threshold;

  /// set softclip type
  final AsoftclipTypes type;

  /// Creates an [AsoftclipSettings] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default; the effect stays
  /// inactive until [enabled] is set to `true`.
  const AsoftclipSettings({
    this.enabled = false,
    this.output = 1.0,
    this.oversample = 1,
    this.param = 1.0,
    this.threshold = 1.0,
    this.type = AsoftclipTypes.hard,
  });

  /// Returns a copy of this [AsoftclipSettings] with the given fields replaced.
  AsoftclipSettings copyWith({
    bool? enabled,
    double? output,
    int? oversample,
    double? param,
    double? threshold,
    AsoftclipTypes? type,
  }) =>
      AsoftclipSettings(
        enabled: enabled ?? this.enabled,
        output: output ?? this.output,
        oversample: oversample ?? this.oversample,
        param: param ?? this.param,
        threshold: threshold ?? this.threshold,
        type: type ?? this.type,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AsoftclipSettings &&
          other.enabled == enabled &&
          other.output == output &&
          other.oversample == oversample &&
          other.param == param &&
          other.threshold == threshold &&
          other.type == type);

  @override
  int get hashCode =>
      Object.hash(enabled, output, oversample, param, threshold, type);

  @override
  String toString() =>
      'AsoftclipSettings(enabled: $enabled, output: $output, oversample: $oversample, param: $param, threshold: $threshold, type: $type)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(output >= outputMin, 'asoftclip.output must be >= 0.000001');
    assert(output <= outputMax, 'asoftclip.output must be <= 16');
    assert(oversample >= oversampleMin, 'asoftclip.oversample must be >= 1');
    assert(oversample <= oversampleMax, 'asoftclip.oversample must be <= 64');
    assert(param >= paramMin, 'asoftclip.param must be >= 0.01');
    assert(param <= paramMax, 'asoftclip.param must be <= 3');
    assert(
        threshold >= thresholdMin, 'asoftclip.threshold must be >= 0.000001',);
    assert(threshold <= thresholdMax, 'asoftclip.threshold must be <= 1');
    final parts = <String>[];
    if (output != 1.0) parts.add('output=' + _wireDouble(output));
    if (oversample != 1) parts.add('oversample=' + oversample.toString());
    if (param != 1.0) parts.add('param=' + _wireDouble(param));
    if (threshold != 1.0) parts.add('threshold=' + _wireDouble(threshold));
    if (type != AsoftclipTypes.hard) parts.add('type=' + type.mpvValue);
    return parts.isEmpty
        ? 'lavfi-asoftclip'
        : 'lavfi-asoftclip=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  List<(String, String)>? _runtimeDiff(AsoftclipSettings prev) {
    final out = <(String, String)>[];
    if (output != prev.output) {
      out.add(('output', _wireDouble(output)));
    }
    if (oversample != prev.oversample) {
      out.add(('oversample', oversample.toString()));
    }
    if (param != prev.param) {
      out.add(('param', _wireDouble(param)));
    }
    if (threshold != prev.threshold) {
      out.add(('threshold', _wireDouble(threshold)));
    }
    if (type != prev.type) {
      out.add(('type', type.mpvValue));
    }
    return out;
  }
}

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
final class AsubboostSettings {
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

  /// Whether this effect is inserted into the audio chain.
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

  /// Creates an [AsubboostSettings] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default; the effect stays
  /// inactive until [enabled] is set to `true`.
  const AsubboostSettings({
    this.enabled = false,
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

  /// Returns a copy of this [AsubboostSettings] with the given fields replaced.
  AsubboostSettings copyWith({
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
  }) =>
      AsubboostSettings(
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
      (other is AsubboostSettings &&
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
  int get hashCode => Object.hash(enabled, boost, channels, cutoff, decay,
      delay, dry, feedback, slope, wet,);

  @override
  String toString() =>
      'AsubboostSettings(enabled: $enabled, boost: $boost, channels: $channels, cutoff: $cutoff, decay: $decay, delay: $delay, dry: $dry, feedback: $feedback, slope: $slope, wet: $wet)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
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
    if (channels != 'all') parts.add('channels=' + '[' + channels + ']');
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
  List<(String, String)>? _runtimeDiff(AsubboostSettings prev) {
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

/// Configuration for the `asubcut` audio effect.
///
/// Cut subwoofer frequencies.
///
/// This filter allows to set custom, steeper
/// roll off than highpass filter, and thus is able to more attenuate
/// frequency content in stop-band.
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [cutoff]: Set cutoff frequency in Hertz. Allowed range is 2 to 200. Default value is 20. (range 2..200, default 20, runtime-tunable)
/// - [level]: Set input gain level. Allowed range is from 0 to 1. Default value is 1. (range 0.0..1.0, default 1., runtime-tunable)
/// - [order]: Set filter order. Available values are from 3 to 20. Default value is 10. (range 3..20, default 10, runtime-tunable)
final class AsubcutSettings {
  /// Default value for [cutoff].
  static const double cutoffDefault = 20.0;

  /// Minimum value for [cutoff].
  static const double cutoffMin = 2.0;

  /// Maximum value for [cutoff].
  static const double cutoffMax = 200.0;

  /// Default value for [level].
  static const double levelDefault = 1.0;

  /// Minimum value for [level].
  static const double levelMin = 0.0;

  /// Maximum value for [level].
  static const double levelMax = 1.0;

  /// Default value for [order].
  static const int orderDefault = 10;

  /// Minimum value for [order].
  static const int orderMin = 3;

  /// Maximum value for [order].
  static const int orderMax = 20;

  /// Whether this effect is inserted into the audio chain.
  final bool enabled;

  /// set cutoff frequency
  final double cutoff;

  /// set input level
  final double level;

  /// set filter order
  final int order;

  /// Creates an [AsubcutSettings] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default; the effect stays
  /// inactive until [enabled] is set to `true`.
  const AsubcutSettings({
    this.enabled = false,
    this.cutoff = 20.0,
    this.level = 1.0,
    this.order = 10,
  });

  /// Returns a copy of this [AsubcutSettings] with the given fields replaced.
  AsubcutSettings copyWith({
    bool? enabled,
    double? cutoff,
    double? level,
    int? order,
  }) =>
      AsubcutSettings(
        enabled: enabled ?? this.enabled,
        cutoff: cutoff ?? this.cutoff,
        level: level ?? this.level,
        order: order ?? this.order,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AsubcutSettings &&
          other.enabled == enabled &&
          other.cutoff == cutoff &&
          other.level == level &&
          other.order == order);

  @override
  int get hashCode => Object.hash(enabled, cutoff, level, order);

  @override
  String toString() =>
      'AsubcutSettings(enabled: $enabled, cutoff: $cutoff, level: $level, order: $order)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(cutoff >= cutoffMin, 'asubcut.cutoff must be >= 2');
    assert(cutoff <= cutoffMax, 'asubcut.cutoff must be <= 200');
    assert(level >= levelMin, 'asubcut.level must be >= 0.0');
    assert(level <= levelMax, 'asubcut.level must be <= 1.0');
    assert(order >= orderMin, 'asubcut.order must be >= 3');
    assert(order <= orderMax, 'asubcut.order must be <= 20');
    final parts = <String>[];
    if (cutoff != 20.0) parts.add('cutoff=' + _wireDouble(cutoff));
    if (level != 1.0) parts.add('level=' + _wireDouble(level));
    if (order != 10) parts.add('order=' + order.toString());
    return parts.isEmpty ? 'lavfi-asubcut' : 'lavfi-asubcut=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  List<(String, String)>? _runtimeDiff(AsubcutSettings prev) {
    final out = <(String, String)>[];
    if (cutoff != prev.cutoff) {
      out.add(('cutoff', _wireDouble(cutoff)));
    }
    if (level != prev.level) {
      out.add(('level', _wireDouble(level)));
    }
    if (order != prev.order) {
      out.add(('order', order.toString()));
    }
    return out;
  }
}

/// Configuration for the `asupercut` audio effect.
///
/// Cut super frequencies.
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [cutoff]: Set cutoff frequency in Hertz. Allowed range is 20000 to 192000. Default value is 20000. (range 20000..192000, default 20000, runtime-tunable)
/// - [level]: Set input gain level. Allowed range is from 0 to 1. Default value is 1. (range 0.0..1.0, default 1., runtime-tunable)
/// - [order]: Set filter order. Available values are from 3 to 20. Default value is 10. (range 3..20, default 10, runtime-tunable)
final class AsupercutSettings {
  /// Default value for [cutoff].
  static const double cutoffDefault = 20000.0;

  /// Minimum value for [cutoff].
  static const double cutoffMin = 20000.0;

  /// Maximum value for [cutoff].
  static const double cutoffMax = 192000.0;

  /// Default value for [level].
  static const double levelDefault = 1.0;

  /// Minimum value for [level].
  static const double levelMin = 0.0;

  /// Maximum value for [level].
  static const double levelMax = 1.0;

  /// Default value for [order].
  static const int orderDefault = 10;

  /// Minimum value for [order].
  static const int orderMin = 3;

  /// Maximum value for [order].
  static const int orderMax = 20;

  /// Whether this effect is inserted into the audio chain.
  final bool enabled;

  /// set cutoff frequency
  final double cutoff;

  /// set input level
  final double level;

  /// set filter order
  final int order;

  /// Creates an [AsupercutSettings] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default; the effect stays
  /// inactive until [enabled] is set to `true`.
  const AsupercutSettings({
    this.enabled = false,
    this.cutoff = 20000.0,
    this.level = 1.0,
    this.order = 10,
  });

  /// Returns a copy of this [AsupercutSettings] with the given fields replaced.
  AsupercutSettings copyWith({
    bool? enabled,
    double? cutoff,
    double? level,
    int? order,
  }) =>
      AsupercutSettings(
        enabled: enabled ?? this.enabled,
        cutoff: cutoff ?? this.cutoff,
        level: level ?? this.level,
        order: order ?? this.order,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AsupercutSettings &&
          other.enabled == enabled &&
          other.cutoff == cutoff &&
          other.level == level &&
          other.order == order);

  @override
  int get hashCode => Object.hash(enabled, cutoff, level, order);

  @override
  String toString() =>
      'AsupercutSettings(enabled: $enabled, cutoff: $cutoff, level: $level, order: $order)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(cutoff >= cutoffMin, 'asupercut.cutoff must be >= 20000');
    assert(cutoff <= cutoffMax, 'asupercut.cutoff must be <= 192000');
    assert(level >= levelMin, 'asupercut.level must be >= 0.0');
    assert(level <= levelMax, 'asupercut.level must be <= 1.0');
    assert(order >= orderMin, 'asupercut.order must be >= 3');
    assert(order <= orderMax, 'asupercut.order must be <= 20');
    final parts = <String>[];
    if (cutoff != 20000.0) parts.add('cutoff=' + _wireDouble(cutoff));
    if (level != 1.0) parts.add('level=' + _wireDouble(level));
    if (order != 10) parts.add('order=' + order.toString());
    return parts.isEmpty
        ? 'lavfi-asupercut'
        : 'lavfi-asupercut=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  List<(String, String)>? _runtimeDiff(AsupercutSettings prev) {
    final out = <(String, String)>[];
    if (cutoff != prev.cutoff) {
      out.add(('cutoff', _wireDouble(cutoff)));
    }
    if (level != prev.level) {
      out.add(('level', _wireDouble(level)));
    }
    if (order != prev.order) {
      out.add(('order', order.toString()));
    }
    return out;
  }
}

/// Configuration for the `asuperpass` audio effect.
///
/// Apply high order Butterworth band-pass filter.
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [centerf]: Set center frequency in Hertz. Allowed range is 2 to 999999. Default value is 1000. (range 2..999999, default 1000, runtime-tunable)
/// - [level]: Set input gain level. Allowed range is from 0 to 2. Default value is 1. (range 0.0..2.0, default 1., runtime-tunable)
/// - [order]: Set filter order. Available values are from 4 to 20. Default value is 4. (range 4..20, default 4, runtime-tunable)
/// - [qfactor]: Set Q-factor. Allowed range is from 0.01 to 100. Default value is 1. (range 0.01..100.0, default 1., runtime-tunable)
final class AsuperpassSettings {
  /// Default value for [centerf].
  static const double centerfDefault = 1000.0;

  /// Minimum value for [centerf].
  static const double centerfMin = 2.0;

  /// Maximum value for [centerf].
  static const double centerfMax = 999999.0;

  /// Default value for [level].
  static const double levelDefault = 1.0;

  /// Minimum value for [level].
  static const double levelMin = 0.0;

  /// Maximum value for [level].
  static const double levelMax = 2.0;

  /// Default value for [order].
  static const int orderDefault = 4;

  /// Minimum value for [order].
  static const int orderMin = 4;

  /// Maximum value for [order].
  static const int orderMax = 20;

  /// Default value for [qfactor].
  static const double qfactorDefault = 1.0;

  /// Minimum value for [qfactor].
  static const double qfactorMin = 0.01;

  /// Maximum value for [qfactor].
  static const double qfactorMax = 100.0;

  /// Whether this effect is inserted into the audio chain.
  final bool enabled;

  /// set center frequency
  final double centerf;

  /// set input level
  final double level;

  /// set filter order
  final int order;

  /// set Q-factor
  final double qfactor;

  /// Creates an [AsuperpassSettings] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default; the effect stays
  /// inactive until [enabled] is set to `true`.
  const AsuperpassSettings({
    this.enabled = false,
    this.centerf = 1000.0,
    this.level = 1.0,
    this.order = 4,
    this.qfactor = 1.0,
  });

  /// Returns a copy of this [AsuperpassSettings] with the given fields replaced.
  AsuperpassSettings copyWith({
    bool? enabled,
    double? centerf,
    double? level,
    int? order,
    double? qfactor,
  }) =>
      AsuperpassSettings(
        enabled: enabled ?? this.enabled,
        centerf: centerf ?? this.centerf,
        level: level ?? this.level,
        order: order ?? this.order,
        qfactor: qfactor ?? this.qfactor,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AsuperpassSettings &&
          other.enabled == enabled &&
          other.centerf == centerf &&
          other.level == level &&
          other.order == order &&
          other.qfactor == qfactor);

  @override
  int get hashCode => Object.hash(enabled, centerf, level, order, qfactor);

  @override
  String toString() =>
      'AsuperpassSettings(enabled: $enabled, centerf: $centerf, level: $level, order: $order, qfactor: $qfactor)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(centerf >= centerfMin, 'asuperpass.centerf must be >= 2');
    assert(centerf <= centerfMax, 'asuperpass.centerf must be <= 999999');
    assert(level >= levelMin, 'asuperpass.level must be >= 0.0');
    assert(level <= levelMax, 'asuperpass.level must be <= 2.0');
    assert(order >= orderMin, 'asuperpass.order must be >= 4');
    assert(order <= orderMax, 'asuperpass.order must be <= 20');
    assert(qfactor >= qfactorMin, 'asuperpass.qfactor must be >= 0.01');
    assert(qfactor <= qfactorMax, 'asuperpass.qfactor must be <= 100.0');
    final parts = <String>[];
    if (centerf != 1000.0) parts.add('centerf=' + _wireDouble(centerf));
    if (level != 1.0) parts.add('level=' + _wireDouble(level));
    if (order != 4) parts.add('order=' + order.toString());
    if (qfactor != 1.0) parts.add('qfactor=' + _wireDouble(qfactor));
    return parts.isEmpty
        ? 'lavfi-asuperpass'
        : 'lavfi-asuperpass=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  List<(String, String)>? _runtimeDiff(AsuperpassSettings prev) {
    final out = <(String, String)>[];
    if (centerf != prev.centerf) {
      out.add(('centerf', _wireDouble(centerf)));
    }
    if (level != prev.level) {
      out.add(('level', _wireDouble(level)));
    }
    if (order != prev.order) {
      out.add(('order', order.toString()));
    }
    if (qfactor != prev.qfactor) {
      out.add(('qfactor', _wireDouble(qfactor)));
    }
    return out;
  }
}

/// Configuration for the `asuperstop` audio effect.
///
/// Apply high order Butterworth band-stop filter.
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [centerf]: Set center frequency in Hertz. Allowed range is 2 to 999999. Default value is 1000. (range 2..999999, default 1000, runtime-tunable)
/// - [level]: Set input gain level. Allowed range is from 0 to 2. Default value is 1. (range 0.0..2.0, default 1., runtime-tunable)
/// - [order]: Set filter order. Available values are from 4 to 20. Default value is 4. (range 4..20, default 4, runtime-tunable)
/// - [qfactor]: Set Q-factor. Allowed range is from 0.01 to 100. Default value is 1. (range 0.01..100.0, default 1., runtime-tunable)
final class AsuperstopSettings {
  /// Default value for [centerf].
  static const double centerfDefault = 1000.0;

  /// Minimum value for [centerf].
  static const double centerfMin = 2.0;

  /// Maximum value for [centerf].
  static const double centerfMax = 999999.0;

  /// Default value for [level].
  static const double levelDefault = 1.0;

  /// Minimum value for [level].
  static const double levelMin = 0.0;

  /// Maximum value for [level].
  static const double levelMax = 2.0;

  /// Default value for [order].
  static const int orderDefault = 4;

  /// Minimum value for [order].
  static const int orderMin = 4;

  /// Maximum value for [order].
  static const int orderMax = 20;

  /// Default value for [qfactor].
  static const double qfactorDefault = 1.0;

  /// Minimum value for [qfactor].
  static const double qfactorMin = 0.01;

  /// Maximum value for [qfactor].
  static const double qfactorMax = 100.0;

  /// Whether this effect is inserted into the audio chain.
  final bool enabled;

  /// set center frequency
  final double centerf;

  /// set input level
  final double level;

  /// set filter order
  final int order;

  /// set Q-factor
  final double qfactor;

  /// Creates an [AsuperstopSettings] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default; the effect stays
  /// inactive until [enabled] is set to `true`.
  const AsuperstopSettings({
    this.enabled = false,
    this.centerf = 1000.0,
    this.level = 1.0,
    this.order = 4,
    this.qfactor = 1.0,
  });

  /// Returns a copy of this [AsuperstopSettings] with the given fields replaced.
  AsuperstopSettings copyWith({
    bool? enabled,
    double? centerf,
    double? level,
    int? order,
    double? qfactor,
  }) =>
      AsuperstopSettings(
        enabled: enabled ?? this.enabled,
        centerf: centerf ?? this.centerf,
        level: level ?? this.level,
        order: order ?? this.order,
        qfactor: qfactor ?? this.qfactor,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AsuperstopSettings &&
          other.enabled == enabled &&
          other.centerf == centerf &&
          other.level == level &&
          other.order == order &&
          other.qfactor == qfactor);

  @override
  int get hashCode => Object.hash(enabled, centerf, level, order, qfactor);

  @override
  String toString() =>
      'AsuperstopSettings(enabled: $enabled, centerf: $centerf, level: $level, order: $order, qfactor: $qfactor)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(centerf >= centerfMin, 'asuperstop.centerf must be >= 2');
    assert(centerf <= centerfMax, 'asuperstop.centerf must be <= 999999');
    assert(level >= levelMin, 'asuperstop.level must be >= 0.0');
    assert(level <= levelMax, 'asuperstop.level must be <= 2.0');
    assert(order >= orderMin, 'asuperstop.order must be >= 4');
    assert(order <= orderMax, 'asuperstop.order must be <= 20');
    assert(qfactor >= qfactorMin, 'asuperstop.qfactor must be >= 0.01');
    assert(qfactor <= qfactorMax, 'asuperstop.qfactor must be <= 100.0');
    final parts = <String>[];
    if (centerf != 1000.0) parts.add('centerf=' + _wireDouble(centerf));
    if (level != 1.0) parts.add('level=' + _wireDouble(level));
    if (order != 4) parts.add('order=' + order.toString());
    if (qfactor != 1.0) parts.add('qfactor=' + _wireDouble(qfactor));
    return parts.isEmpty
        ? 'lavfi-asuperstop'
        : 'lavfi-asuperstop=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  List<(String, String)>? _runtimeDiff(AsuperstopSettings prev) {
    final out = <(String, String)>[];
    if (centerf != prev.centerf) {
      out.add(('centerf', _wireDouble(centerf)));
    }
    if (level != prev.level) {
      out.add(('level', _wireDouble(level)));
    }
    if (order != prev.order) {
      out.add(('order', order.toString()));
    }
    if (qfactor != prev.qfactor) {
      out.add(('qfactor', _wireDouble(qfactor)));
    }
    return out;
  }
}

/// Configuration for the `atempo` audio effect.
///
/// Adjust audio tempo.
///
/// The filter accepts exactly one parameter, the audio tempo. If not
/// specified then the filter will assume nominal 1.0 tempo. Tempo must
/// be in the [0.5, 100.0] range.
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
final class AtempoSettings {
  /// Default value for [tempo].
  static const double tempoDefault = 1.0;

  /// Minimum value for [tempo].
  static const double tempoMin = 0.5;

  /// Maximum value for [tempo].
  static const double tempoMax = 100.0;

  /// Whether this effect is inserted into the audio chain.
  final bool enabled;

  /// set tempo scale factor
  final double tempo;

  /// Creates an [AtempoSettings] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default; the effect stays
  /// inactive until [enabled] is set to `true`.
  const AtempoSettings({
    this.enabled = false,
    this.tempo = 1.0,
  });

  /// Returns a copy of this [AtempoSettings] with the given fields replaced.
  AtempoSettings copyWith({
    bool? enabled,
    double? tempo,
  }) =>
      AtempoSettings(
        enabled: enabled ?? this.enabled,
        tempo: tempo ?? this.tempo,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AtempoSettings &&
          other.enabled == enabled &&
          other.tempo == tempo);

  @override
  int get hashCode => Object.hash(enabled, tempo);

  @override
  String toString() => 'AtempoSettings(enabled: $enabled, tempo: $tempo)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
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
  List<(String, String)>? _runtimeDiff(AtempoSettings prev) {
    final out = <(String, String)>[];
    if (tempo != prev.tempo) {
      out.add(('tempo', _wireDouble(tempo)));
    }
    return out;
  }
}

/// Configuration for the `atilt` audio effect.
///
/// Apply spectral tilt filter to audio stream.
///
/// This filter apply any spectral roll-off slope over any specified frequency band.
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [freq]: Set central frequency of tilt in Hz. Default is 10000 Hz. (range 20..192000, default 10000, runtime-tunable)
/// - [level]: Set input volume level. Allowed range is from 0 to 4. Default is 1. (range 0.0..4.0, default 1., runtime-tunable)
/// - [order]: Set order of tilt filter. (range 2..30, default 5, runtime-tunable)
/// - [slope]: Set slope direction of tilt. Default is 0. Allowed range is from -1 to 1. (range -1..1, default 0, runtime-tunable)
/// - [width]: Set width of tilt. Default is 1000. Allowed range is from 100 to 10000. (range 100..10000, default 1000, runtime-tunable)
final class AtiltSettings {
  /// Default value for [freq].
  static const double freqDefault = 10000.0;

  /// Minimum value for [freq].
  static const double freqMin = 20.0;

  /// Maximum value for [freq].
  static const double freqMax = 192000.0;

  /// Default value for [level].
  static const double levelDefault = 1.0;

  /// Minimum value for [level].
  static const double levelMin = 0.0;

  /// Maximum value for [level].
  static const double levelMax = 4.0;

  /// Default value for [order].
  static const int orderDefault = 5;

  /// Minimum value for [order].
  static const int orderMin = 2;

  /// Maximum value for [order].
  static const int orderMax = 30;

  /// Default value for [slope].
  static const double slopeDefault = 0.0;

  /// Minimum value for [slope].
  static const double slopeMin = -1.0;

  /// Maximum value for [slope].
  static const double slopeMax = 1.0;

  /// Default value for [width].
  static const double widthDefault = 1000.0;

  /// Minimum value for [width].
  static const double widthMin = 100.0;

  /// Maximum value for [width].
  static const double widthMax = 10000.0;

  /// Whether this effect is inserted into the audio chain.
  final bool enabled;

  /// set central frequency
  final double freq;

  /// set input level
  final double level;

  /// set filter order
  final int order;

  /// set filter slope
  final double slope;

  /// set filter width
  final double width;

  /// Creates an [AtiltSettings] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default; the effect stays
  /// inactive until [enabled] is set to `true`.
  const AtiltSettings({
    this.enabled = false,
    this.freq = 10000.0,
    this.level = 1.0,
    this.order = 5,
    this.slope = 0.0,
    this.width = 1000.0,
  });

  /// Returns a copy of this [AtiltSettings] with the given fields replaced.
  AtiltSettings copyWith({
    bool? enabled,
    double? freq,
    double? level,
    int? order,
    double? slope,
    double? width,
  }) =>
      AtiltSettings(
        enabled: enabled ?? this.enabled,
        freq: freq ?? this.freq,
        level: level ?? this.level,
        order: order ?? this.order,
        slope: slope ?? this.slope,
        width: width ?? this.width,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AtiltSettings &&
          other.enabled == enabled &&
          other.freq == freq &&
          other.level == level &&
          other.order == order &&
          other.slope == slope &&
          other.width == width);

  @override
  int get hashCode => Object.hash(enabled, freq, level, order, slope, width);

  @override
  String toString() =>
      'AtiltSettings(enabled: $enabled, freq: $freq, level: $level, order: $order, slope: $slope, width: $width)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(freq >= freqMin, 'atilt.freq must be >= 20');
    assert(freq <= freqMax, 'atilt.freq must be <= 192000');
    assert(level >= levelMin, 'atilt.level must be >= 0.0');
    assert(level <= levelMax, 'atilt.level must be <= 4.0');
    assert(order >= orderMin, 'atilt.order must be >= 2');
    assert(order <= orderMax, 'atilt.order must be <= 30');
    assert(slope >= slopeMin, 'atilt.slope must be >= -1');
    assert(slope <= slopeMax, 'atilt.slope must be <= 1');
    assert(width >= widthMin, 'atilt.width must be >= 100');
    assert(width <= widthMax, 'atilt.width must be <= 10000');
    final parts = <String>[];
    if (freq != 10000.0) parts.add('freq=' + _wireDouble(freq));
    if (level != 1.0) parts.add('level=' + _wireDouble(level));
    if (order != 5) parts.add('order=' + order.toString());
    if (slope != 0.0) parts.add('slope=' + _wireDouble(slope));
    if (width != 1000.0) parts.add('width=' + _wireDouble(width));
    return parts.isEmpty ? 'lavfi-atilt' : 'lavfi-atilt=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  List<(String, String)>? _runtimeDiff(AtiltSettings prev) {
    final out = <(String, String)>[];
    if (freq != prev.freq) {
      out.add(('freq', _wireDouble(freq)));
    }
    if (level != prev.level) {
      out.add(('level', _wireDouble(level)));
    }
    if (order != prev.order) {
      out.add(('order', order.toString()));
    }
    if (slope != prev.slope) {
      out.add(('slope', _wireDouble(slope)));
    }
    if (width != prev.width) {
      out.add(('width', _wireDouble(width)));
    }
    return out;
  }
}

/// Configuration for the `bandpass` audio effect.
///
/// Apply a two-pole Butterworth band-pass filter with central
/// frequency `frequency`, and (3dB-point) band-width width.
/// The `csg` option selects a constant skirt gain (peak gain = Q)
/// instead of the default: constant 0dB peak gain.
/// The filter roll off at 6dB per octave (20dB per decade).
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [a]: Set transform type of IIR filter. (range 0..6, default DI)
/// - [b]: Set block size used for reverse IIR processing. If this value is set to high enough value (higher than impulse response length truncated when reaches near zero values) filtering will become linear phase otherwise if not big enough it will just produce nasty artifacts.  Note that filter delay will be exactly this many samples when set to non-zero value. (range 0..32768, default 0)
/// - [blocksize]: set the block size (range 0..32768, default 0)
/// - [c]: Specify which channels to filter, by default all available are filtered. (range 0..0, default "all", runtime-tunable)
/// - [channels]: Specify which channels to filter, by default all available are filtered. (range 0..0, default "all", runtime-tunable)
/// - [csg]: Constant skirt gain if set to 1. Defaults to 0. (range 0..1, default 0, runtime-tunable)
/// - [f]: Set the filter's central frequency. Default is `3000`. (range 0..999999, default 3000, runtime-tunable)
/// - [frequency]: Set the filter's central frequency. Default is `3000`. (range 0..999999, default 3000, runtime-tunable)
/// - [m]: How much to use filtered signal in output. Default is 1. Range is between 0 and 1. (range 0..1, default 1, runtime-tunable)
/// - [mix]: How much to use filtered signal in output. Default is 1. Range is between 0 and 1. (range 0..1, default 1, runtime-tunable)
/// - [n]: Normalize biquad coefficients, by default is disabled. Enabling it will normalize magnitude response at DC to 0dB. (range 0..1, default 0, runtime-tunable)
/// - [normalize]: Normalize biquad coefficients, by default is disabled. Enabling it will normalize magnitude response at DC to 0dB. (range 0..1, default 0, runtime-tunable)
/// - [precision]: Set precision of filtering. (range -1..3, default -1)
/// - [r]: Set precision of filtering. (range -1..3, default -1)
/// - [t]: Set method to specify band-width of filter. (range 1..5, default QFACTOR, runtime-tunable)
/// - [transform]: Set transform type of IIR filter. (range 0..6, default DI)
/// - [w]: Specify the band-width of a filter in width_type units. (range 0..99999, default 0.5, runtime-tunable)
/// - [width]: Specify the band-width of a filter in width_type units. (range 0..99999, default 0.5, runtime-tunable)
/// - [width_type]: Set method to specify band-width of filter. (range 1..5, default QFACTOR, runtime-tunable)
final class BandpassSettings {
  /// Default value for [b].
  static const int bDefault = 0;

  /// Minimum value for [b].
  static const int bMin = 0;

  /// Maximum value for [b].
  static const int bMax = 32768;

  /// Default value for [blocksize].
  static const int blocksizeDefault = 0;

  /// Minimum value for [blocksize].
  static const int blocksizeMin = 0;

  /// Maximum value for [blocksize].
  static const int blocksizeMax = 32768;

  /// Default value for [f].
  static const double fDefault = 3000.0;

  /// Minimum value for [f].
  static const double fMin = 0.0;

  /// Maximum value for [f].
  static const double fMax = 999999.0;

  /// Default value for [frequency].
  static const double frequencyDefault = 3000.0;

  /// Minimum value for [frequency].
  static const double frequencyMin = 0.0;

  /// Maximum value for [frequency].
  static const double frequencyMax = 999999.0;

  /// Default value for [m].
  static const double mDefault = 1.0;

  /// Minimum value for [m].
  static const double mMin = 0.0;

  /// Maximum value for [m].
  static const double mMax = 1.0;

  /// Default value for [mix].
  static const double mixDefault = 1.0;

  /// Minimum value for [mix].
  static const double mixMin = 0.0;

  /// Maximum value for [mix].
  static const double mixMax = 1.0;

  /// Default value for [w].
  static const double wDefault = 0.5;

  /// Minimum value for [w].
  static const double wMin = 0.0;

  /// Maximum value for [w].
  static const double wMax = 99999.0;

  /// Default value for [width].
  static const double widthDefault = 0.5;

  /// Minimum value for [width].
  static const double widthMin = 0.0;

  /// Maximum value for [width].
  static const double widthMax = 99999.0;

  /// Whether this effect is inserted into the audio chain.
  final bool enabled;

  /// set transform type
  final BandpassTransformType a;

  /// set the block size
  final int b;

  /// set the block size
  final int blocksize;

  /// set channels to filter
  final String c;

  /// set channels to filter
  final String channels;

  /// use constant skirt gain
  final bool csg;

  /// set central frequency
  final double f;

  /// set central frequency
  final double frequency;

  /// set mix
  final double m;

  /// set mix
  final double mix;

  /// normalize coefficients
  final bool n;

  /// normalize coefficients
  final bool normalize;

  /// set filtering precision
  final BandpassPrecision precision;

  /// set filtering precision
  final BandpassPrecision r;

  /// set filter-width type
  final BandpassWidthType t;

  /// set transform type
  final BandpassTransformType transform;

  /// set width
  final double w;

  /// set width
  final double width;

  /// set filter-width type
  final BandpassWidthType width_type;

  /// Creates an [BandpassSettings] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default; the effect stays
  /// inactive until [enabled] is set to `true`.
  const BandpassSettings({
    this.enabled = false,
    this.a = BandpassTransformType.di,
    this.b = 0,
    this.blocksize = 0,
    this.c = 'all',
    this.channels = 'all',
    this.csg = false,
    this.f = 3000.0,
    this.frequency = 3000.0,
    this.m = 1.0,
    this.mix = 1.0,
    this.n = false,
    this.normalize = false,
    this.precision = BandpassPrecision.auto,
    this.r = BandpassPrecision.auto,
    this.t = BandpassWidthType.q,
    this.transform = BandpassTransformType.di,
    this.w = 0.5,
    this.width = 0.5,
    this.width_type = BandpassWidthType.q,
  });

  /// Returns a copy of this [BandpassSettings] with the given fields replaced.
  BandpassSettings copyWith({
    bool? enabled,
    BandpassTransformType? a,
    int? b,
    int? blocksize,
    String? c,
    String? channels,
    bool? csg,
    double? f,
    double? frequency,
    double? m,
    double? mix,
    bool? n,
    bool? normalize,
    BandpassPrecision? precision,
    BandpassPrecision? r,
    BandpassWidthType? t,
    BandpassTransformType? transform,
    double? w,
    double? width,
    BandpassWidthType? width_type,
  }) =>
      BandpassSettings(
        enabled: enabled ?? this.enabled,
        a: a ?? this.a,
        b: b ?? this.b,
        blocksize: blocksize ?? this.blocksize,
        c: c ?? this.c,
        channels: channels ?? this.channels,
        csg: csg ?? this.csg,
        f: f ?? this.f,
        frequency: frequency ?? this.frequency,
        m: m ?? this.m,
        mix: mix ?? this.mix,
        n: n ?? this.n,
        normalize: normalize ?? this.normalize,
        precision: precision ?? this.precision,
        r: r ?? this.r,
        t: t ?? this.t,
        transform: transform ?? this.transform,
        w: w ?? this.w,
        width: width ?? this.width,
        width_type: width_type ?? this.width_type,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BandpassSettings &&
          other.enabled == enabled &&
          other.a == a &&
          other.b == b &&
          other.blocksize == blocksize &&
          other.c == c &&
          other.channels == channels &&
          other.csg == csg &&
          other.f == f &&
          other.frequency == frequency &&
          other.m == m &&
          other.mix == mix &&
          other.n == n &&
          other.normalize == normalize &&
          other.precision == precision &&
          other.r == r &&
          other.t == t &&
          other.transform == transform &&
          other.w == w &&
          other.width == width &&
          other.width_type == width_type);

  @override
  int get hashCode => Object.hash(
      enabled,
      a,
      b,
      blocksize,
      c,
      channels,
      csg,
      f,
      frequency,
      m,
      mix,
      n,
      normalize,
      precision,
      r,
      t,
      transform,
      w,
      width,
      width_type,);

  @override
  String toString() =>
      'BandpassSettings(enabled: $enabled, a: $a, b: $b, blocksize: $blocksize, c: $c, channels: $channels, csg: $csg, f: $f, frequency: $frequency, m: $m, mix: $mix, n: $n, normalize: $normalize, precision: $precision, r: $r, t: $t, transform: $transform, w: $w, width: $width, width_type: $width_type)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(b >= bMin, 'bandpass.b must be >= 0');
    assert(b <= bMax, 'bandpass.b must be <= 32768');
    assert(blocksize >= blocksizeMin, 'bandpass.blocksize must be >= 0');
    assert(blocksize <= blocksizeMax, 'bandpass.blocksize must be <= 32768');
    assert(f >= fMin, 'bandpass.f must be >= 0');
    assert(f <= fMax, 'bandpass.f must be <= 999999');
    assert(frequency >= frequencyMin, 'bandpass.frequency must be >= 0');
    assert(frequency <= frequencyMax, 'bandpass.frequency must be <= 999999');
    assert(m >= mMin, 'bandpass.m must be >= 0');
    assert(m <= mMax, 'bandpass.m must be <= 1');
    assert(mix >= mixMin, 'bandpass.mix must be >= 0');
    assert(mix <= mixMax, 'bandpass.mix must be <= 1');
    assert(w >= wMin, 'bandpass.w must be >= 0');
    assert(w <= wMax, 'bandpass.w must be <= 99999');
    assert(width >= widthMin, 'bandpass.width must be >= 0');
    assert(width <= widthMax, 'bandpass.width must be <= 99999');
    final parts = <String>[];
    if (a != BandpassTransformType.di) parts.add('a=' + a.mpvValue);
    if (b != 0) parts.add('b=' + b.toString());
    if (blocksize != 0) parts.add('blocksize=' + blocksize.toString());
    if (c != 'all') parts.add('c=' + '[' + c + ']');
    if (channels != 'all') parts.add('channels=' + '[' + channels + ']');
    if (csg != false) parts.add('csg=' + (csg ? '1' : '0'));
    if (f != 3000.0) parts.add('f=' + _wireDouble(f));
    if (frequency != 3000.0) parts.add('frequency=' + _wireDouble(frequency));
    if (m != 1.0) parts.add('m=' + _wireDouble(m));
    if (mix != 1.0) parts.add('mix=' + _wireDouble(mix));
    if (n != false) parts.add('n=' + (n ? '1' : '0'));
    if (normalize != false) parts.add('normalize=' + (normalize ? '1' : '0'));
    if (precision != BandpassPrecision.auto)
      parts.add('precision=' + precision.mpvValue);
    if (r != BandpassPrecision.auto) parts.add('r=' + r.mpvValue);
    if (t != BandpassWidthType.q) parts.add('t=' + t.mpvValue);
    if (transform != BandpassTransformType.di)
      parts.add('transform=' + transform.mpvValue);
    if (w != 0.5) parts.add('w=' + _wireDouble(w));
    if (width != 0.5) parts.add('width=' + _wireDouble(width));
    if (width_type != BandpassWidthType.q)
      parts.add('width_type=' + width_type.mpvValue);
    return parts.isEmpty
        ? 'lavfi-bandpass'
        : 'lavfi-bandpass=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  List<(String, String)>? _runtimeDiff(BandpassSettings prev) {
    final out = <(String, String)>[];
    if (a != prev.a) return null;
    if (b != prev.b) return null;
    if (blocksize != prev.blocksize) return null;
    if (c != prev.c) {
      out.add(('c', c));
    }
    if (channels != prev.channels) {
      out.add(('channels', channels));
    }
    if (csg != prev.csg) {
      out.add(('csg', (csg ? '1' : '0')));
    }
    if (f != prev.f) {
      out.add(('f', _wireDouble(f)));
    }
    if (frequency != prev.frequency) {
      out.add(('frequency', _wireDouble(frequency)));
    }
    if (m != prev.m) {
      out.add(('m', _wireDouble(m)));
    }
    if (mix != prev.mix) {
      out.add(('mix', _wireDouble(mix)));
    }
    if (n != prev.n) {
      out.add(('n', (n ? '1' : '0')));
    }
    if (normalize != prev.normalize) {
      out.add(('normalize', (normalize ? '1' : '0')));
    }
    if (precision != prev.precision) return null;
    if (r != prev.r) return null;
    if (t != prev.t) {
      out.add(('t', t.mpvValue));
    }
    if (transform != prev.transform) return null;
    if (w != prev.w) {
      out.add(('w', _wireDouble(w)));
    }
    if (width != prev.width) {
      out.add(('width', _wireDouble(width)));
    }
    if (width_type != prev.width_type) {
      out.add(('width_type', width_type.mpvValue));
    }
    return out;
  }
}

/// Configuration for the `bandreject` audio effect.
///
/// Apply a two-pole Butterworth band-reject filter with central
/// frequency `frequency`, and (3dB-point) band-width `width`.
/// The filter roll off at 6dB per octave (20dB per decade).
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [a]: Set transform type of IIR filter. (range 0..6, default DI)
/// - [b]: Set block size used for reverse IIR processing. If this value is set to high enough value (higher than impulse response length truncated when reaches near zero values) filtering will become linear phase otherwise if not big enough it will just produce nasty artifacts.  Note that filter delay will be exactly this many samples when set to non-zero value. (range 0..32768, default 0)
/// - [blocksize]: set the block size (range 0..32768, default 0)
/// - [c]: Specify which channels to filter, by default all available are filtered. (range 0..0, default "all", runtime-tunable)
/// - [channels]: Specify which channels to filter, by default all available are filtered. (range 0..0, default "all", runtime-tunable)
/// - [f]: Set the filter's central frequency. Default is `3000`. (range 0..999999, default 3000, runtime-tunable)
/// - [frequency]: Set the filter's central frequency. Default is `3000`. (range 0..999999, default 3000, runtime-tunable)
/// - [m]: How much to use filtered signal in output. Default is 1. Range is between 0 and 1. (range 0..1, default 1, runtime-tunable)
/// - [mix]: How much to use filtered signal in output. Default is 1. Range is between 0 and 1. (range 0..1, default 1, runtime-tunable)
/// - [n]: Normalize biquad coefficients, by default is disabled. Enabling it will normalize magnitude response at DC to 0dB. (range 0..1, default 0, runtime-tunable)
/// - [normalize]: Normalize biquad coefficients, by default is disabled. Enabling it will normalize magnitude response at DC to 0dB. (range 0..1, default 0, runtime-tunable)
/// - [precision]: Set precision of filtering. (range -1..3, default -1)
/// - [r]: Set precision of filtering. (range -1..3, default -1)
/// - [t]: Set method to specify band-width of filter. (range 1..5, default QFACTOR, runtime-tunable)
/// - [transform]: Set transform type of IIR filter. (range 0..6, default DI)
/// - [w]: Specify the band-width of a filter in width_type units. (range 0..99999, default 0.5, runtime-tunable)
/// - [width]: Specify the band-width of a filter in width_type units. (range 0..99999, default 0.5, runtime-tunable)
/// - [width_type]: Set method to specify band-width of filter. (range 1..5, default QFACTOR, runtime-tunable)
final class BandrejectSettings {
  /// Default value for [b].
  static const int bDefault = 0;

  /// Minimum value for [b].
  static const int bMin = 0;

  /// Maximum value for [b].
  static const int bMax = 32768;

  /// Default value for [blocksize].
  static const int blocksizeDefault = 0;

  /// Minimum value for [blocksize].
  static const int blocksizeMin = 0;

  /// Maximum value for [blocksize].
  static const int blocksizeMax = 32768;

  /// Default value for [f].
  static const double fDefault = 3000.0;

  /// Minimum value for [f].
  static const double fMin = 0.0;

  /// Maximum value for [f].
  static const double fMax = 999999.0;

  /// Default value for [frequency].
  static const double frequencyDefault = 3000.0;

  /// Minimum value for [frequency].
  static const double frequencyMin = 0.0;

  /// Maximum value for [frequency].
  static const double frequencyMax = 999999.0;

  /// Default value for [m].
  static const double mDefault = 1.0;

  /// Minimum value for [m].
  static const double mMin = 0.0;

  /// Maximum value for [m].
  static const double mMax = 1.0;

  /// Default value for [mix].
  static const double mixDefault = 1.0;

  /// Minimum value for [mix].
  static const double mixMin = 0.0;

  /// Maximum value for [mix].
  static const double mixMax = 1.0;

  /// Default value for [w].
  static const double wDefault = 0.5;

  /// Minimum value for [w].
  static const double wMin = 0.0;

  /// Maximum value for [w].
  static const double wMax = 99999.0;

  /// Default value for [width].
  static const double widthDefault = 0.5;

  /// Minimum value for [width].
  static const double widthMin = 0.0;

  /// Maximum value for [width].
  static const double widthMax = 99999.0;

  /// Whether this effect is inserted into the audio chain.
  final bool enabled;

  /// set transform type
  final BandrejectTransformType a;

  /// set the block size
  final int b;

  /// set the block size
  final int blocksize;

  /// set channels to filter
  final String c;

  /// set channels to filter
  final String channels;

  /// set central frequency
  final double f;

  /// set central frequency
  final double frequency;

  /// set mix
  final double m;

  /// set mix
  final double mix;

  /// normalize coefficients
  final bool n;

  /// normalize coefficients
  final bool normalize;

  /// set filtering precision
  final BandrejectPrecision precision;

  /// set filtering precision
  final BandrejectPrecision r;

  /// set filter-width type
  final BandrejectWidthType t;

  /// set transform type
  final BandrejectTransformType transform;

  /// set width
  final double w;

  /// set width
  final double width;

  /// set filter-width type
  final BandrejectWidthType width_type;

  /// Creates an [BandrejectSettings] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default; the effect stays
  /// inactive until [enabled] is set to `true`.
  const BandrejectSettings({
    this.enabled = false,
    this.a = BandrejectTransformType.di,
    this.b = 0,
    this.blocksize = 0,
    this.c = 'all',
    this.channels = 'all',
    this.f = 3000.0,
    this.frequency = 3000.0,
    this.m = 1.0,
    this.mix = 1.0,
    this.n = false,
    this.normalize = false,
    this.precision = BandrejectPrecision.auto,
    this.r = BandrejectPrecision.auto,
    this.t = BandrejectWidthType.q,
    this.transform = BandrejectTransformType.di,
    this.w = 0.5,
    this.width = 0.5,
    this.width_type = BandrejectWidthType.q,
  });

  /// Returns a copy of this [BandrejectSettings] with the given fields replaced.
  BandrejectSettings copyWith({
    bool? enabled,
    BandrejectTransformType? a,
    int? b,
    int? blocksize,
    String? c,
    String? channels,
    double? f,
    double? frequency,
    double? m,
    double? mix,
    bool? n,
    bool? normalize,
    BandrejectPrecision? precision,
    BandrejectPrecision? r,
    BandrejectWidthType? t,
    BandrejectTransformType? transform,
    double? w,
    double? width,
    BandrejectWidthType? width_type,
  }) =>
      BandrejectSettings(
        enabled: enabled ?? this.enabled,
        a: a ?? this.a,
        b: b ?? this.b,
        blocksize: blocksize ?? this.blocksize,
        c: c ?? this.c,
        channels: channels ?? this.channels,
        f: f ?? this.f,
        frequency: frequency ?? this.frequency,
        m: m ?? this.m,
        mix: mix ?? this.mix,
        n: n ?? this.n,
        normalize: normalize ?? this.normalize,
        precision: precision ?? this.precision,
        r: r ?? this.r,
        t: t ?? this.t,
        transform: transform ?? this.transform,
        w: w ?? this.w,
        width: width ?? this.width,
        width_type: width_type ?? this.width_type,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BandrejectSettings &&
          other.enabled == enabled &&
          other.a == a &&
          other.b == b &&
          other.blocksize == blocksize &&
          other.c == c &&
          other.channels == channels &&
          other.f == f &&
          other.frequency == frequency &&
          other.m == m &&
          other.mix == mix &&
          other.n == n &&
          other.normalize == normalize &&
          other.precision == precision &&
          other.r == r &&
          other.t == t &&
          other.transform == transform &&
          other.w == w &&
          other.width == width &&
          other.width_type == width_type);

  @override
  int get hashCode => Object.hash(
      enabled,
      a,
      b,
      blocksize,
      c,
      channels,
      f,
      frequency,
      m,
      mix,
      n,
      normalize,
      precision,
      r,
      t,
      transform,
      w,
      width,
      width_type,);

  @override
  String toString() =>
      'BandrejectSettings(enabled: $enabled, a: $a, b: $b, blocksize: $blocksize, c: $c, channels: $channels, f: $f, frequency: $frequency, m: $m, mix: $mix, n: $n, normalize: $normalize, precision: $precision, r: $r, t: $t, transform: $transform, w: $w, width: $width, width_type: $width_type)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(b >= bMin, 'bandreject.b must be >= 0');
    assert(b <= bMax, 'bandreject.b must be <= 32768');
    assert(blocksize >= blocksizeMin, 'bandreject.blocksize must be >= 0');
    assert(blocksize <= blocksizeMax, 'bandreject.blocksize must be <= 32768');
    assert(f >= fMin, 'bandreject.f must be >= 0');
    assert(f <= fMax, 'bandreject.f must be <= 999999');
    assert(frequency >= frequencyMin, 'bandreject.frequency must be >= 0');
    assert(frequency <= frequencyMax, 'bandreject.frequency must be <= 999999');
    assert(m >= mMin, 'bandreject.m must be >= 0');
    assert(m <= mMax, 'bandreject.m must be <= 1');
    assert(mix >= mixMin, 'bandreject.mix must be >= 0');
    assert(mix <= mixMax, 'bandreject.mix must be <= 1');
    assert(w >= wMin, 'bandreject.w must be >= 0');
    assert(w <= wMax, 'bandreject.w must be <= 99999');
    assert(width >= widthMin, 'bandreject.width must be >= 0');
    assert(width <= widthMax, 'bandreject.width must be <= 99999');
    final parts = <String>[];
    if (a != BandrejectTransformType.di) parts.add('a=' + a.mpvValue);
    if (b != 0) parts.add('b=' + b.toString());
    if (blocksize != 0) parts.add('blocksize=' + blocksize.toString());
    if (c != 'all') parts.add('c=' + '[' + c + ']');
    if (channels != 'all') parts.add('channels=' + '[' + channels + ']');
    if (f != 3000.0) parts.add('f=' + _wireDouble(f));
    if (frequency != 3000.0) parts.add('frequency=' + _wireDouble(frequency));
    if (m != 1.0) parts.add('m=' + _wireDouble(m));
    if (mix != 1.0) parts.add('mix=' + _wireDouble(mix));
    if (n != false) parts.add('n=' + (n ? '1' : '0'));
    if (normalize != false) parts.add('normalize=' + (normalize ? '1' : '0'));
    if (precision != BandrejectPrecision.auto)
      parts.add('precision=' + precision.mpvValue);
    if (r != BandrejectPrecision.auto) parts.add('r=' + r.mpvValue);
    if (t != BandrejectWidthType.q) parts.add('t=' + t.mpvValue);
    if (transform != BandrejectTransformType.di)
      parts.add('transform=' + transform.mpvValue);
    if (w != 0.5) parts.add('w=' + _wireDouble(w));
    if (width != 0.5) parts.add('width=' + _wireDouble(width));
    if (width_type != BandrejectWidthType.q)
      parts.add('width_type=' + width_type.mpvValue);
    return parts.isEmpty
        ? 'lavfi-bandreject'
        : 'lavfi-bandreject=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  List<(String, String)>? _runtimeDiff(BandrejectSettings prev) {
    final out = <(String, String)>[];
    if (a != prev.a) return null;
    if (b != prev.b) return null;
    if (blocksize != prev.blocksize) return null;
    if (c != prev.c) {
      out.add(('c', c));
    }
    if (channels != prev.channels) {
      out.add(('channels', channels));
    }
    if (f != prev.f) {
      out.add(('f', _wireDouble(f)));
    }
    if (frequency != prev.frequency) {
      out.add(('frequency', _wireDouble(frequency)));
    }
    if (m != prev.m) {
      out.add(('m', _wireDouble(m)));
    }
    if (mix != prev.mix) {
      out.add(('mix', _wireDouble(mix)));
    }
    if (n != prev.n) {
      out.add(('n', (n ? '1' : '0')));
    }
    if (normalize != prev.normalize) {
      out.add(('normalize', (normalize ? '1' : '0')));
    }
    if (precision != prev.precision) return null;
    if (r != prev.r) return null;
    if (t != prev.t) {
      out.add(('t', t.mpvValue));
    }
    if (transform != prev.transform) return null;
    if (w != prev.w) {
      out.add(('w', _wireDouble(w)));
    }
    if (width != prev.width) {
      out.add(('width', _wireDouble(width)));
    }
    if (width_type != prev.width_type) {
      out.add(('width_type', width_type.mpvValue));
    }
    return out;
  }
}

/// Configuration for the `bass` audio effect.
///
/// Boost or cut the bass (lower) frequencies of the audio using a two-pole
/// shelving filter with a response similar to that of a standard
/// hi-fi's tone-controls. This is also known as shelving equalisation (EQ).
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [a]: Set transform type of IIR filter. (range 0..6, default DI)
/// - [b]: Set block size used for reverse IIR processing. If this value is set to high enough value (higher than impulse response length truncated when reaches near zero values) filtering will become linear phase otherwise if not big enough it will just produce nasty artifacts.  Note that filter delay will be exactly this many samples when set to non-zero value. (range 0..32768, default 0)
/// - [blocksize]: set the block size (range 0..32768, default 0)
/// - [c]: Specify which channels to filter, by default all available are filtered. (range 0..0, default "all", runtime-tunable)
/// - [channels]: Specify which channels to filter, by default all available are filtered. (range 0..0, default "all", runtime-tunable)
/// - [f]: Set the filter's central frequency and so can be used to extend or reduce the frequency range to be boosted or cut. The default value is `100` Hz. (range 0..999999, default 100, runtime-tunable)
/// - [frequency]: Set the filter's central frequency and so can be used to extend or reduce the frequency range to be boosted or cut. The default value is `100` Hz. (range 0..999999, default 100, runtime-tunable)
/// - [g]: Give the gain at 0 Hz. Its useful range is about -20 (for a large cut) to +20 (for a large boost). Beware of clipping when using a positive gain. (range -900..900, default 0, runtime-tunable)
/// - [gain]: Give the gain at 0 Hz. Its useful range is about -20 (for a large cut) to +20 (for a large boost). Beware of clipping when using a positive gain. (range -900..900, default 0, runtime-tunable)
/// - [m]: How much to use filtered signal in output. Default is 1. Range is between 0 and 1. (range 0..1, default 1, runtime-tunable)
/// - [mix]: How much to use filtered signal in output. Default is 1. Range is between 0 and 1. (range 0..1, default 1, runtime-tunable)
/// - [n]: Normalize biquad coefficients, by default is disabled. Enabling it will normalize magnitude response at DC to 0dB. (range 0..1, default 0, runtime-tunable)
/// - [normalize]: Normalize biquad coefficients, by default is disabled. Enabling it will normalize magnitude response at DC to 0dB. (range 0..1, default 0, runtime-tunable)
/// - [p]: Set number of poles. Default is 2. (range 1..2, default 2)
/// - [poles]: Set number of poles. Default is 2. (range 1..2, default 2)
/// - [precision]: Set precision of filtering. (range -1..3, default -1)
/// - [r]: Set precision of filtering. (range -1..3, default -1)
/// - [t]: Set method to specify band-width of filter. (range 1..5, default QFACTOR, runtime-tunable)
/// - [transform]: Set transform type of IIR filter. (range 0..6, default DI)
/// - [w]: Determine how steep is the filter's shelf transition. (range 0..99999, default 0.5, runtime-tunable)
/// - [width]: Determine how steep is the filter's shelf transition. (range 0..99999, default 0.5, runtime-tunable)
/// - [width_type]: Set method to specify band-width of filter. (range 1..5, default QFACTOR, runtime-tunable)
final class BassSettings {
  /// Default value for [b].
  static const int bDefault = 0;

  /// Minimum value for [b].
  static const int bMin = 0;

  /// Maximum value for [b].
  static const int bMax = 32768;

  /// Default value for [blocksize].
  static const int blocksizeDefault = 0;

  /// Minimum value for [blocksize].
  static const int blocksizeMin = 0;

  /// Maximum value for [blocksize].
  static const int blocksizeMax = 32768;

  /// Default value for [f].
  static const double fDefault = 100.0;

  /// Minimum value for [f].
  static const double fMin = 0.0;

  /// Maximum value for [f].
  static const double fMax = 999999.0;

  /// Default value for [frequency].
  static const double frequencyDefault = 100.0;

  /// Minimum value for [frequency].
  static const double frequencyMin = 0.0;

  /// Maximum value for [frequency].
  static const double frequencyMax = 999999.0;

  /// Default value for [g].
  static const double gDefault = 0.0;

  /// Minimum value for [g].
  static const double gMin = -900.0;

  /// Maximum value for [g].
  static const double gMax = 900.0;

  /// Default value for [gain].
  static const double gainDefault = 0.0;

  /// Minimum value for [gain].
  static const double gainMin = -900.0;

  /// Maximum value for [gain].
  static const double gainMax = 900.0;

  /// Default value for [m].
  static const double mDefault = 1.0;

  /// Minimum value for [m].
  static const double mMin = 0.0;

  /// Maximum value for [m].
  static const double mMax = 1.0;

  /// Default value for [mix].
  static const double mixDefault = 1.0;

  /// Minimum value for [mix].
  static const double mixMin = 0.0;

  /// Maximum value for [mix].
  static const double mixMax = 1.0;

  /// Default value for [p].
  static const int pDefault = 2;

  /// Minimum value for [p].
  static const int pMin = 1;

  /// Maximum value for [p].
  static const int pMax = 2;

  /// Default value for [poles].
  static const int polesDefault = 2;

  /// Minimum value for [poles].
  static const int polesMin = 1;

  /// Maximum value for [poles].
  static const int polesMax = 2;

  /// Default value for [w].
  static const double wDefault = 0.5;

  /// Minimum value for [w].
  static const double wMin = 0.0;

  /// Maximum value for [w].
  static const double wMax = 99999.0;

  /// Default value for [width].
  static const double widthDefault = 0.5;

  /// Minimum value for [width].
  static const double widthMin = 0.0;

  /// Maximum value for [width].
  static const double widthMax = 99999.0;

  /// Whether this effect is inserted into the audio chain.
  final bool enabled;

  /// set transform type
  final BassTransformType a;

  /// set the block size
  final int b;

  /// set the block size
  final int blocksize;

  /// set channels to filter
  final String c;

  /// set channels to filter
  final String channels;

  /// set central frequency
  final double f;

  /// set central frequency
  final double frequency;

  /// set gain
  final double g;

  /// set gain
  final double gain;

  /// set mix
  final double m;

  /// set mix
  final double mix;

  /// normalize coefficients
  final bool n;

  /// normalize coefficients
  final bool normalize;

  /// set number of poles
  final int p;

  /// set number of poles
  final int poles;

  /// set filtering precision
  final BassPrecision precision;

  /// set filtering precision
  final BassPrecision r;

  /// set filter-width type
  final BassWidthType t;

  /// set transform type
  final BassTransformType transform;

  /// set width
  final double w;

  /// set width
  final double width;

  /// set filter-width type
  final BassWidthType width_type;

  /// Creates an [BassSettings] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default; the effect stays
  /// inactive until [enabled] is set to `true`.
  const BassSettings({
    this.enabled = false,
    this.a = BassTransformType.di,
    this.b = 0,
    this.blocksize = 0,
    this.c = 'all',
    this.channels = 'all',
    this.f = 100.0,
    this.frequency = 100.0,
    this.g = 0.0,
    this.gain = 0.0,
    this.m = 1.0,
    this.mix = 1.0,
    this.n = false,
    this.normalize = false,
    this.p = 2,
    this.poles = 2,
    this.precision = BassPrecision.auto,
    this.r = BassPrecision.auto,
    this.t = BassWidthType.q,
    this.transform = BassTransformType.di,
    this.w = 0.5,
    this.width = 0.5,
    this.width_type = BassWidthType.q,
  });

  /// Returns a copy of this [BassSettings] with the given fields replaced.
  BassSettings copyWith({
    bool? enabled,
    BassTransformType? a,
    int? b,
    int? blocksize,
    String? c,
    String? channels,
    double? f,
    double? frequency,
    double? g,
    double? gain,
    double? m,
    double? mix,
    bool? n,
    bool? normalize,
    int? p,
    int? poles,
    BassPrecision? precision,
    BassPrecision? r,
    BassWidthType? t,
    BassTransformType? transform,
    double? w,
    double? width,
    BassWidthType? width_type,
  }) =>
      BassSettings(
        enabled: enabled ?? this.enabled,
        a: a ?? this.a,
        b: b ?? this.b,
        blocksize: blocksize ?? this.blocksize,
        c: c ?? this.c,
        channels: channels ?? this.channels,
        f: f ?? this.f,
        frequency: frequency ?? this.frequency,
        g: g ?? this.g,
        gain: gain ?? this.gain,
        m: m ?? this.m,
        mix: mix ?? this.mix,
        n: n ?? this.n,
        normalize: normalize ?? this.normalize,
        p: p ?? this.p,
        poles: poles ?? this.poles,
        precision: precision ?? this.precision,
        r: r ?? this.r,
        t: t ?? this.t,
        transform: transform ?? this.transform,
        w: w ?? this.w,
        width: width ?? this.width,
        width_type: width_type ?? this.width_type,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BassSettings &&
          other.enabled == enabled &&
          other.a == a &&
          other.b == b &&
          other.blocksize == blocksize &&
          other.c == c &&
          other.channels == channels &&
          other.f == f &&
          other.frequency == frequency &&
          other.g == g &&
          other.gain == gain &&
          other.m == m &&
          other.mix == mix &&
          other.n == n &&
          other.normalize == normalize &&
          other.p == p &&
          other.poles == poles &&
          other.precision == precision &&
          other.r == r &&
          other.t == t &&
          other.transform == transform &&
          other.w == w &&
          other.width == width &&
          other.width_type == width_type);

  @override
  int get hashCode => Object.hashAll([
        enabled,
        a,
        b,
        blocksize,
        c,
        channels,
        f,
        frequency,
        g,
        gain,
        m,
        mix,
        n,
        normalize,
        p,
        poles,
        precision,
        r,
        t,
        transform,
        w,
        width,
        width_type,
      ]);

  @override
  String toString() =>
      'BassSettings(enabled: $enabled, a: $a, b: $b, blocksize: $blocksize, c: $c, channels: $channels, f: $f, frequency: $frequency, g: $g, gain: $gain, m: $m, mix: $mix, n: $n, normalize: $normalize, p: $p, poles: $poles, precision: $precision, r: $r, t: $t, transform: $transform, w: $w, width: $width, width_type: $width_type)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(b >= bMin, 'bass.b must be >= 0');
    assert(b <= bMax, 'bass.b must be <= 32768');
    assert(blocksize >= blocksizeMin, 'bass.blocksize must be >= 0');
    assert(blocksize <= blocksizeMax, 'bass.blocksize must be <= 32768');
    assert(f >= fMin, 'bass.f must be >= 0');
    assert(f <= fMax, 'bass.f must be <= 999999');
    assert(frequency >= frequencyMin, 'bass.frequency must be >= 0');
    assert(frequency <= frequencyMax, 'bass.frequency must be <= 999999');
    assert(g >= gMin, 'bass.g must be >= -900');
    assert(g <= gMax, 'bass.g must be <= 900');
    assert(gain >= gainMin, 'bass.gain must be >= -900');
    assert(gain <= gainMax, 'bass.gain must be <= 900');
    assert(m >= mMin, 'bass.m must be >= 0');
    assert(m <= mMax, 'bass.m must be <= 1');
    assert(mix >= mixMin, 'bass.mix must be >= 0');
    assert(mix <= mixMax, 'bass.mix must be <= 1');
    assert(p >= pMin, 'bass.p must be >= 1');
    assert(p <= pMax, 'bass.p must be <= 2');
    assert(poles >= polesMin, 'bass.poles must be >= 1');
    assert(poles <= polesMax, 'bass.poles must be <= 2');
    assert(w >= wMin, 'bass.w must be >= 0');
    assert(w <= wMax, 'bass.w must be <= 99999');
    assert(width >= widthMin, 'bass.width must be >= 0');
    assert(width <= widthMax, 'bass.width must be <= 99999');
    final parts = <String>[];
    if (a != BassTransformType.di) parts.add('a=' + a.mpvValue);
    if (b != 0) parts.add('b=' + b.toString());
    if (blocksize != 0) parts.add('blocksize=' + blocksize.toString());
    if (c != 'all') parts.add('c=' + '[' + c + ']');
    if (channels != 'all') parts.add('channels=' + '[' + channels + ']');
    if (f != 100.0) parts.add('f=' + _wireDouble(f));
    if (frequency != 100.0) parts.add('frequency=' + _wireDouble(frequency));
    if (g != 0.0) parts.add('g=' + _wireDouble(g));
    if (gain != 0.0) parts.add('gain=' + _wireDouble(gain));
    if (m != 1.0) parts.add('m=' + _wireDouble(m));
    if (mix != 1.0) parts.add('mix=' + _wireDouble(mix));
    if (n != false) parts.add('n=' + (n ? '1' : '0'));
    if (normalize != false) parts.add('normalize=' + (normalize ? '1' : '0'));
    if (p != 2) parts.add('p=' + p.toString());
    if (poles != 2) parts.add('poles=' + poles.toString());
    if (precision != BassPrecision.auto)
      parts.add('precision=' + precision.mpvValue);
    if (r != BassPrecision.auto) parts.add('r=' + r.mpvValue);
    if (t != BassWidthType.q) parts.add('t=' + t.mpvValue);
    if (transform != BassTransformType.di)
      parts.add('transform=' + transform.mpvValue);
    if (w != 0.5) parts.add('w=' + _wireDouble(w));
    if (width != 0.5) parts.add('width=' + _wireDouble(width));
    if (width_type != BassWidthType.q)
      parts.add('width_type=' + width_type.mpvValue);
    return parts.isEmpty ? 'lavfi-bass' : 'lavfi-bass=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  List<(String, String)>? _runtimeDiff(BassSettings prev) {
    final out = <(String, String)>[];
    if (a != prev.a) return null;
    if (b != prev.b) return null;
    if (blocksize != prev.blocksize) return null;
    if (c != prev.c) {
      out.add(('c', c));
    }
    if (channels != prev.channels) {
      out.add(('channels', channels));
    }
    if (f != prev.f) {
      out.add(('f', _wireDouble(f)));
    }
    if (frequency != prev.frequency) {
      out.add(('frequency', _wireDouble(frequency)));
    }
    if (g != prev.g) {
      out.add(('g', _wireDouble(g)));
    }
    if (gain != prev.gain) {
      out.add(('gain', _wireDouble(gain)));
    }
    if (m != prev.m) {
      out.add(('m', _wireDouble(m)));
    }
    if (mix != prev.mix) {
      out.add(('mix', _wireDouble(mix)));
    }
    if (n != prev.n) {
      out.add(('n', (n ? '1' : '0')));
    }
    if (normalize != prev.normalize) {
      out.add(('normalize', (normalize ? '1' : '0')));
    }
    if (p != prev.p) return null;
    if (poles != prev.poles) return null;
    if (precision != prev.precision) return null;
    if (r != prev.r) return null;
    if (t != prev.t) {
      out.add(('t', t.mpvValue));
    }
    if (transform != prev.transform) return null;
    if (w != prev.w) {
      out.add(('w', _wireDouble(w)));
    }
    if (width != prev.width) {
      out.add(('width', _wireDouble(width)));
    }
    if (width_type != prev.width_type) {
      out.add(('width_type', width_type.mpvValue));
    }
    return out;
  }
}

/// Configuration for the `biquad` audio effect.
///
/// Apply a biquad IIR filter with the given coefficients.
/// Where `b0`, `b1`, `b2` and `a0`, `a1`, `a2`
/// are the numerator and denominator coefficients respectively.
/// and `channels`, `c` specify which channels to filter, by default all
/// available are filtered.
///
/// This filter supports the following commands:
///
/// Parameters:
/// - [a]: Set transform type of IIR filter. (range 0..6, default DI)
/// - [a0]:  (range -2147483648..2147483647, default 1, runtime-tunable)
/// - [a1]:  (range -2147483648..2147483647, default 0, runtime-tunable)
/// - [a2]:  (range -2147483648..2147483647, default 0, runtime-tunable)
/// - [b]: Set block size used for reverse IIR processing. If this value is set to high enough value (higher than impulse response length truncated when reaches near zero values) filtering will become linear phase otherwise if not big enough it will just produce nasty artifacts.  Note that filter delay will be exactly this many samples when set to non-zero value. (range 0..32768, default 0)
/// - [b0]:  (range -2147483648..2147483647, default 0, runtime-tunable)
/// - [b1]:  (range -2147483648..2147483647, default 0, runtime-tunable)
/// - [b2]: Change biquad parameter. Syntax for the command is : "`value`" (range -2147483648..2147483647, default 0, runtime-tunable)
/// - [blocksize]: set the block size (range 0..32768, default 0)
/// - [c]: Specify which channels to filter, by default all available are filtered. (range 0..0, default "all", runtime-tunable)
/// - [channels]: Specify which channels to filter, by default all available are filtered. (range 0..0, default "all", runtime-tunable)
/// - [m]: How much to use filtered signal in output. Default is 1. Range is between 0 and 1. (range 0..1, default 1, runtime-tunable)
/// - [mix]: How much to use filtered signal in output. Default is 1. Range is between 0 and 1. (range 0..1, default 1, runtime-tunable)
/// - [n]: Normalize biquad coefficients, by default is disabled. Enabling it will normalize magnitude response at DC to 0dB. (range 0..1, default 0, runtime-tunable)
/// - [normalize]: Normalize biquad coefficients, by default is disabled. Enabling it will normalize magnitude response at DC to 0dB. (range 0..1, default 0, runtime-tunable)
/// - [precision]: Set precision of filtering. (range -1..3, default -1)
/// - [r]: Set precision of filtering. (range -1..3, default -1)
/// - [transform]: Set transform type of IIR filter. (range 0..6, default DI)
final class BiquadSettings {
  /// Default value for [a0].
  static const double a0Default = 1.0;

  /// Minimum value for [a0].
  static const double a0Min = -2147483648.0;

  /// Maximum value for [a0].
  static const double a0Max = 2147483647.0;

  /// Default value for [a1].
  static const double a1Default = 0.0;

  /// Minimum value for [a1].
  static const double a1Min = -2147483648.0;

  /// Maximum value for [a1].
  static const double a1Max = 2147483647.0;

  /// Default value for [a2].
  static const double a2Default = 0.0;

  /// Minimum value for [a2].
  static const double a2Min = -2147483648.0;

  /// Maximum value for [a2].
  static const double a2Max = 2147483647.0;

  /// Default value for [b].
  static const int bDefault = 0;

  /// Minimum value for [b].
  static const int bMin = 0;

  /// Maximum value for [b].
  static const int bMax = 32768;

  /// Default value for [b0].
  static const double b0Default = 0.0;

  /// Minimum value for [b0].
  static const double b0Min = -2147483648.0;

  /// Maximum value for [b0].
  static const double b0Max = 2147483647.0;

  /// Default value for [b1].
  static const double b1Default = 0.0;

  /// Minimum value for [b1].
  static const double b1Min = -2147483648.0;

  /// Maximum value for [b1].
  static const double b1Max = 2147483647.0;

  /// Default value for [b2].
  static const double b2Default = 0.0;

  /// Minimum value for [b2].
  static const double b2Min = -2147483648.0;

  /// Maximum value for [b2].
  static const double b2Max = 2147483647.0;

  /// Default value for [blocksize].
  static const int blocksizeDefault = 0;

  /// Minimum value for [blocksize].
  static const int blocksizeMin = 0;

  /// Maximum value for [blocksize].
  static const int blocksizeMax = 32768;

  /// Default value for [m].
  static const double mDefault = 1.0;

  /// Minimum value for [m].
  static const double mMin = 0.0;

  /// Maximum value for [m].
  static const double mMax = 1.0;

  /// Default value for [mix].
  static const double mixDefault = 1.0;

  /// Minimum value for [mix].
  static const double mixMin = 0.0;

  /// Maximum value for [mix].
  static const double mixMax = 1.0;

  /// Whether this effect is inserted into the audio chain.
  final bool enabled;

  /// set transform type
  final BiquadTransformType a;

  /// The `a0` parameter.
  final double a0;

  /// The `a1` parameter.
  final double a1;

  /// The `a2` parameter.
  final double a2;

  /// set the block size
  final int b;

  /// The `b0` parameter.
  final double b0;

  /// The `b1` parameter.
  final double b1;

  /// The `b2` parameter.
  final double b2;

  /// set the block size
  final int blocksize;

  /// set channels to filter
  final String c;

  /// set channels to filter
  final String channels;

  /// set mix
  final double m;

  /// set mix
  final double mix;

  /// normalize coefficients
  final bool n;

  /// normalize coefficients
  final bool normalize;

  /// set filtering precision
  final BiquadPrecision precision;

  /// set filtering precision
  final BiquadPrecision r;

  /// set transform type
  final BiquadTransformType transform;

  /// Creates an [BiquadSettings] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default; the effect stays
  /// inactive until [enabled] is set to `true`.
  const BiquadSettings({
    this.enabled = false,
    this.a = BiquadTransformType.di,
    this.a0 = 1.0,
    this.a1 = 0.0,
    this.a2 = 0.0,
    this.b = 0,
    this.b0 = 0.0,
    this.b1 = 0.0,
    this.b2 = 0.0,
    this.blocksize = 0,
    this.c = 'all',
    this.channels = 'all',
    this.m = 1.0,
    this.mix = 1.0,
    this.n = false,
    this.normalize = false,
    this.precision = BiquadPrecision.auto,
    this.r = BiquadPrecision.auto,
    this.transform = BiquadTransformType.di,
  });

  /// Returns a copy of this [BiquadSettings] with the given fields replaced.
  BiquadSettings copyWith({
    bool? enabled,
    BiquadTransformType? a,
    double? a0,
    double? a1,
    double? a2,
    int? b,
    double? b0,
    double? b1,
    double? b2,
    int? blocksize,
    String? c,
    String? channels,
    double? m,
    double? mix,
    bool? n,
    bool? normalize,
    BiquadPrecision? precision,
    BiquadPrecision? r,
    BiquadTransformType? transform,
  }) =>
      BiquadSettings(
        enabled: enabled ?? this.enabled,
        a: a ?? this.a,
        a0: a0 ?? this.a0,
        a1: a1 ?? this.a1,
        a2: a2 ?? this.a2,
        b: b ?? this.b,
        b0: b0 ?? this.b0,
        b1: b1 ?? this.b1,
        b2: b2 ?? this.b2,
        blocksize: blocksize ?? this.blocksize,
        c: c ?? this.c,
        channels: channels ?? this.channels,
        m: m ?? this.m,
        mix: mix ?? this.mix,
        n: n ?? this.n,
        normalize: normalize ?? this.normalize,
        precision: precision ?? this.precision,
        r: r ?? this.r,
        transform: transform ?? this.transform,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BiquadSettings &&
          other.enabled == enabled &&
          other.a == a &&
          other.a0 == a0 &&
          other.a1 == a1 &&
          other.a2 == a2 &&
          other.b == b &&
          other.b0 == b0 &&
          other.b1 == b1 &&
          other.b2 == b2 &&
          other.blocksize == blocksize &&
          other.c == c &&
          other.channels == channels &&
          other.m == m &&
          other.mix == mix &&
          other.n == n &&
          other.normalize == normalize &&
          other.precision == precision &&
          other.r == r &&
          other.transform == transform);

  @override
  int get hashCode => Object.hash(enabled, a, a0, a1, a2, b, b0, b1, b2,
      blocksize, c, channels, m, mix, n, normalize, precision, r, transform,);

  @override
  String toString() =>
      'BiquadSettings(enabled: $enabled, a: $a, a0: $a0, a1: $a1, a2: $a2, b: $b, b0: $b0, b1: $b1, b2: $b2, blocksize: $blocksize, c: $c, channels: $channels, m: $m, mix: $mix, n: $n, normalize: $normalize, precision: $precision, r: $r, transform: $transform)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(a0 >= a0Min, 'biquad.a0 must be >= -2147483648');
    assert(a0 <= a0Max, 'biquad.a0 must be <= 2147483647');
    assert(a1 >= a1Min, 'biquad.a1 must be >= -2147483648');
    assert(a1 <= a1Max, 'biquad.a1 must be <= 2147483647');
    assert(a2 >= a2Min, 'biquad.a2 must be >= -2147483648');
    assert(a2 <= a2Max, 'biquad.a2 must be <= 2147483647');
    assert(b >= bMin, 'biquad.b must be >= 0');
    assert(b <= bMax, 'biquad.b must be <= 32768');
    assert(b0 >= b0Min, 'biquad.b0 must be >= -2147483648');
    assert(b0 <= b0Max, 'biquad.b0 must be <= 2147483647');
    assert(b1 >= b1Min, 'biquad.b1 must be >= -2147483648');
    assert(b1 <= b1Max, 'biquad.b1 must be <= 2147483647');
    assert(b2 >= b2Min, 'biquad.b2 must be >= -2147483648');
    assert(b2 <= b2Max, 'biquad.b2 must be <= 2147483647');
    assert(blocksize >= blocksizeMin, 'biquad.blocksize must be >= 0');
    assert(blocksize <= blocksizeMax, 'biquad.blocksize must be <= 32768');
    assert(m >= mMin, 'biquad.m must be >= 0');
    assert(m <= mMax, 'biquad.m must be <= 1');
    assert(mix >= mixMin, 'biquad.mix must be >= 0');
    assert(mix <= mixMax, 'biquad.mix must be <= 1');
    final parts = <String>[];
    if (a != BiquadTransformType.di) parts.add('a=' + a.mpvValue);
    if (a0 != 1.0) parts.add('a0=' + _wireDouble(a0));
    if (a1 != 0.0) parts.add('a1=' + _wireDouble(a1));
    if (a2 != 0.0) parts.add('a2=' + _wireDouble(a2));
    if (b != 0) parts.add('b=' + b.toString());
    if (b0 != 0.0) parts.add('b0=' + _wireDouble(b0));
    if (b1 != 0.0) parts.add('b1=' + _wireDouble(b1));
    if (b2 != 0.0) parts.add('b2=' + _wireDouble(b2));
    if (blocksize != 0) parts.add('blocksize=' + blocksize.toString());
    if (c != 'all') parts.add('c=' + '[' + c + ']');
    if (channels != 'all') parts.add('channels=' + '[' + channels + ']');
    if (m != 1.0) parts.add('m=' + _wireDouble(m));
    if (mix != 1.0) parts.add('mix=' + _wireDouble(mix));
    if (n != false) parts.add('n=' + (n ? '1' : '0'));
    if (normalize != false) parts.add('normalize=' + (normalize ? '1' : '0'));
    if (precision != BiquadPrecision.auto)
      parts.add('precision=' + precision.mpvValue);
    if (r != BiquadPrecision.auto) parts.add('r=' + r.mpvValue);
    if (transform != BiquadTransformType.di)
      parts.add('transform=' + transform.mpvValue);
    return parts.isEmpty ? 'lavfi-biquad' : 'lavfi-biquad=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  List<(String, String)>? _runtimeDiff(BiquadSettings prev) {
    final out = <(String, String)>[];
    if (a != prev.a) return null;
    if (a0 != prev.a0) {
      out.add(('a0', _wireDouble(a0)));
    }
    if (a1 != prev.a1) {
      out.add(('a1', _wireDouble(a1)));
    }
    if (a2 != prev.a2) {
      out.add(('a2', _wireDouble(a2)));
    }
    if (b != prev.b) return null;
    if (b0 != prev.b0) {
      out.add(('b0', _wireDouble(b0)));
    }
    if (b1 != prev.b1) {
      out.add(('b1', _wireDouble(b1)));
    }
    if (b2 != prev.b2) {
      out.add(('b2', _wireDouble(b2)));
    }
    if (blocksize != prev.blocksize) return null;
    if (c != prev.c) {
      out.add(('c', c));
    }
    if (channels != prev.channels) {
      out.add(('channels', channels));
    }
    if (m != prev.m) {
      out.add(('m', _wireDouble(m)));
    }
    if (mix != prev.mix) {
      out.add(('mix', _wireDouble(mix)));
    }
    if (n != prev.n) {
      out.add(('n', (n ? '1' : '0')));
    }
    if (normalize != prev.normalize) {
      out.add(('normalize', (normalize ? '1' : '0')));
    }
    if (precision != prev.precision) return null;
    if (r != prev.r) return null;
    if (transform != prev.transform) return null;
    return out;
  }
}

/// Configuration for the `channelmap` audio effect.
///
/// Remap input channels to new locations.
///
/// It accepts the following parameters:
///
/// Parameters:
/// - [channel_layout]: The channel layout of the output stream. If not specified, then filter will guess it based on the `out_channel` names or the number of mappings. Guessed layouts will not necessarily contain channels in the order of the mappings.
/// - [map]: Map channels from input to output. The argument is a '|'-separated list of mappings, each in the `@var{in_channel`-`out_channel`} or `@var{in_channel`} form. `in_channel` can be either the name of the input channel (e.g. FL for front left) or its index in the input channel layout. `out_channel` is the name of the output channel or its index in the output channel layout. If `out_channel` is not given then it is implicitly an index, starting with zero and increasing by one for each mapping. Mixing different types of mappings is not allowed and will result in a parse error.
final class ChannelmapSettings {
  /// Whether this effect is inserted into the audio chain.
  final bool enabled;

  /// Output channel layout.
  final String? channel_layout;

  /// A comma-separated list of input channel numbers in output order.
  final String map;

  /// Creates an [ChannelmapSettings] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default; the effect stays
  /// inactive until [enabled] is set to `true`.
  const ChannelmapSettings({
    this.enabled = false,
    this.channel_layout,
    required this.map,
  });

  /// Returns a copy of this [ChannelmapSettings] with the given fields replaced.
  ChannelmapSettings copyWith({
    bool? enabled,
    Object? channel_layout = unset,
    String? map,
  }) =>
      ChannelmapSettings(
        enabled: enabled ?? this.enabled,
        channel_layout: identical(channel_layout, unset)
            ? this.channel_layout
            : channel_layout as String?,
        map: map ?? this.map,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChannelmapSettings &&
          other.enabled == enabled &&
          other.channel_layout == channel_layout &&
          other.map == map);

  @override
  int get hashCode => Object.hash(enabled, channel_layout, map);

  @override
  String toString() =>
      'ChannelmapSettings(enabled: $enabled, channel_layout: $channel_layout, map: $map)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    final parts = <String>[];
    if (channel_layout != null)
      parts.add('channel_layout=' + '[' + channel_layout! + ']');
    parts.add('map=' + '[' + map + ']');
    return parts.isEmpty
        ? 'lavfi-channelmap'
        : 'lavfi-channelmap=' + parts.join(':');
  }
}

/// Configuration for the `chorus` audio effect.
///
/// Add a chorus effect to the audio.
///
/// Can make a single vocal sound like a chorus, but can also be applied to instrumentation.
///
/// Chorus resembles an echo effect with a short delay, but whereas with echo the delay is
/// constant, with chorus, it is varied using sinusoidal or triangular modulation.
/// The modulation depth defines the range the modulated delay is played before or after
/// the delay. Hence the delayed sound will sound slower or faster, that is the delayed
/// sound tuned around the original one, like in a chorus where some vocals are slightly
/// off key.
///
/// It accepts the following parameters:
///
/// Parameters:
/// - [decays]: Set decays. (range 0..0, default "")
/// - [delays]: Set delays. A typical delay is around 40ms to 60ms. (range 0..0, default "")
/// - [depths]: Set depths. (range 0..0, default "")
/// - [in_gain]: Set input gain. Default is 0.4. (range 0..1, default .4)
/// - [out_gain]: Set output gain. Default is 0.4. (range 0..1, default .4)
/// - [speeds]: Set speeds. (range 0..0, default "")
final class ChorusSettings {
  /// Default value for [in_gain].
  static const double in_gainDefault = .4;

  /// Minimum value for [in_gain].
  static const double in_gainMin = 0.0;

  /// Maximum value for [in_gain].
  static const double in_gainMax = 1.0;

  /// Default value for [out_gain].
  static const double out_gainDefault = .4;

  /// Minimum value for [out_gain].
  static const double out_gainMin = 0.0;

  /// Maximum value for [out_gain].
  static const double out_gainMax = 1.0;

  /// Whether this effect is inserted into the audio chain.
  final bool enabled;

  /// set decays
  final String decays;

  /// set delays
  final String delays;

  /// set depths
  final String depths;

  /// set input gain
  final double in_gain;

  /// set output gain
  final double out_gain;

  /// set speeds
  final String speeds;

  /// Creates an [ChorusSettings] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default; the effect stays
  /// inactive until [enabled] is set to `true`.
  const ChorusSettings({
    this.enabled = false,
    required this.decays,
    required this.delays,
    required this.depths,
    this.in_gain = .4,
    this.out_gain = .4,
    required this.speeds,
  });

  /// Returns a copy of this [ChorusSettings] with the given fields replaced.
  ChorusSettings copyWith({
    bool? enabled,
    String? decays,
    String? delays,
    String? depths,
    double? in_gain,
    double? out_gain,
    String? speeds,
  }) =>
      ChorusSettings(
        enabled: enabled ?? this.enabled,
        decays: decays ?? this.decays,
        delays: delays ?? this.delays,
        depths: depths ?? this.depths,
        in_gain: in_gain ?? this.in_gain,
        out_gain: out_gain ?? this.out_gain,
        speeds: speeds ?? this.speeds,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChorusSettings &&
          other.enabled == enabled &&
          other.decays == decays &&
          other.delays == delays &&
          other.depths == depths &&
          other.in_gain == in_gain &&
          other.out_gain == out_gain &&
          other.speeds == speeds);

  @override
  int get hashCode =>
      Object.hash(enabled, decays, delays, depths, in_gain, out_gain, speeds);

  @override
  String toString() =>
      'ChorusSettings(enabled: $enabled, decays: $decays, delays: $delays, depths: $depths, in_gain: $in_gain, out_gain: $out_gain, speeds: $speeds)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(in_gain >= in_gainMin, 'chorus.in_gain must be >= 0');
    assert(in_gain <= in_gainMax, 'chorus.in_gain must be <= 1');
    assert(out_gain >= out_gainMin, 'chorus.out_gain must be >= 0');
    assert(out_gain <= out_gainMax, 'chorus.out_gain must be <= 1');
    final parts = <String>[];
    parts.add('decays=' + '[' + decays + ']');
    parts.add('delays=' + '[' + delays + ']');
    parts.add('depths=' + '[' + depths + ']');
    if (in_gain != .4) parts.add('in_gain=' + _wireDouble(in_gain));
    if (out_gain != .4) parts.add('out_gain=' + _wireDouble(out_gain));
    parts.add('speeds=' + '[' + speeds + ']');
    return parts.isEmpty ? 'lavfi-chorus' : 'lavfi-chorus=' + parts.join(':');
  }
}

/// Configuration for the `compand` audio effect.
///
/// Compress or expand the audio's dynamic range.
///
/// It accepts the following parameters:
///
/// Parameters:
/// - [attacks]: set time over which increase of volume is determined (range 0..0, default "0")
/// - [decays]: A list of times in seconds for each channel over which the instantaneous level of the input signal is averaged to determine its volume. `attacks` refers to increase of volume and `decays` refers to decrease of volume. For most situations, the attack time (response to the audio getting louder) should be shorter than the decay time, because the human ear is more sensitive to sudden loud audio than sudden soft audio. A typical value for attack is 0.3 seconds and a typical value for decay is 0.8 seconds. If specified number of attacks & decays is lower than number of channels, the last set attack/decay will be used for all remaining channels. (range 0..0, default "0.8")
/// - [delay]: Set a delay, in seconds. The input audio is analyzed immediately, but audio is delayed before being fed to the volume adjuster. Specifying a delay approximately equal to the attack/decay times allows the filter to effectively operate in predictive rather than reactive mode. It defaults to 0. (range 0..20, default 0)
/// - [gain]: Set the additional gain in dB to be applied at all points on the transfer function. This allows for easy adjustment of the overall gain. It defaults to 0. (range -900..900, default 0)
/// - [points]: A list of points for the transfer function, specified in dB relative to the maximum possible signal amplitude. Each key points list must be defined using the following syntax: `x0/y0|x1/y1|x2/y2|....` or `x0/y0 x1/y1 x2/y2 ....`  The input values must be in strictly increasing order but the transfer function does not have to be monotonically rising. The point `0/0` is assumed but may be overridden (by `0/out-dBn`). Typical values for the transfer function are `-70/-70|-60/-20|1/0`. (range 0..0, default "-70/-70|-60/-20|1/0")
/// - [volume]: Set an initial volume, in dB, to be assumed for each channel when filtering starts. This permits the user to supply a nominal level initially, so that, for example, a very large gain is not applied to initial signal levels before the companding has begun to operate. A typical value for audio which is initially quiet is -90 dB. It defaults to 0. (range -900..0, default 0)
///
/// Parameters whose names start with a digit, addressed by
/// their original key in the [params] map:
/// - `soft-knee`: Set the curve radius in dB for all joints. It defaults to 0.01. (range 0.01..900, default 0.01)
final class CompandSettings {
  /// Default value for [delay].
  static const double delayDefault = 0.0;

  /// Minimum value for [delay].
  static const double delayMin = 0.0;

  /// Maximum value for [delay].
  static const double delayMax = 20.0;

  /// Default value for [gain].
  static const double gainDefault = 0.0;

  /// Minimum value for [gain].
  static const double gainMin = -900.0;

  /// Maximum value for [gain].
  static const double gainMax = 900.0;

  /// Default value for [volume].
  static const double volumeDefault = 0.0;

  /// Minimum value for [volume].
  static const double volumeMin = -900.0;

  /// Maximum value for [volume].
  static const double volumeMax = 0.0;

  /// Whether this effect is inserted into the audio chain.
  final bool enabled;

  /// set time over which increase of volume is determined
  final String attacks;

  /// set time over which decrease of volume is determined
  final String decays;

  /// set delay for samples before sending them to volume adjuster
  final double delay;

  /// set output gain
  final double gain;

  /// set points of transfer function
  final String points;

  /// set initial volume
  final double volume;

  /// Raw values for parameters whose names start with a digit,
  /// keyed by their original ffmpeg option name.
  final Map<String, double> params;

  /// Creates an [CompandSettings] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default; the effect stays
  /// inactive until [enabled] is set to `true`.
  const CompandSettings({
    this.enabled = false,
    this.attacks = '0',
    this.decays = '0.8',
    this.delay = 0.0,
    this.gain = 0.0,
    this.points = '-70/-70|-60/-20|1/0',
    this.volume = 0.0,
    this.params = const <String, double>{},
  });

  /// Returns a copy of this [CompandSettings] with the given fields replaced.
  CompandSettings copyWith({
    bool? enabled,
    String? attacks,
    String? decays,
    double? delay,
    double? gain,
    String? points,
    double? volume,
    Map<String, double>? params,
  }) =>
      CompandSettings(
        enabled: enabled ?? this.enabled,
        attacks: attacks ?? this.attacks,
        decays: decays ?? this.decays,
        delay: delay ?? this.delay,
        gain: gain ?? this.gain,
        points: points ?? this.points,
        volume: volume ?? this.volume,
        params: params ?? this.params,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CompandSettings &&
          other.enabled == enabled &&
          other.attacks == attacks &&
          other.decays == decays &&
          other.delay == delay &&
          other.gain == gain &&
          other.points == points &&
          other.volume == volume &&
          _mapEq(params, other.params));

  @override
  int get hashCode => Object.hash(
      enabled,
      attacks,
      decays,
      delay,
      gain,
      points,
      volume,
      Object.hashAllUnordered(
          params.entries.map((e) => Object.hash(e.key, e.value)),),);

  @override
  String toString() =>
      'CompandSettings(enabled: $enabled, attacks: $attacks, decays: $decays, delay: $delay, gain: $gain, points: $points, volume: $volume, params: $params)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(delay >= delayMin, 'compand.delay must be >= 0');
    assert(delay <= delayMax, 'compand.delay must be <= 20');
    assert(gain >= gainMin, 'compand.gain must be >= -900');
    assert(gain <= gainMax, 'compand.gain must be <= 900');
    assert(volume >= volumeMin, 'compand.volume must be >= -900');
    assert(volume <= volumeMax, 'compand.volume must be <= 0');
    final parts = <String>[];
    if (attacks != '0') parts.add('attacks=' + '[' + attacks + ']');
    if (decays != '0.8') parts.add('decays=' + '[' + decays + ']');
    if (delay != 0.0) parts.add('delay=' + _wireDouble(delay));
    if (gain != 0.0) parts.add('gain=' + _wireDouble(gain));
    if (points != '-70/-70|-60/-20|1/0')
      parts.add('points=' + '[' + points + ']');
    if (volume != 0.0) parts.add('volume=' + _wireDouble(volume));
    params.forEach((k, v) => parts.add('$k=' + _wireDouble(v)));
    return parts.isEmpty ? 'lavfi-compand' : 'lavfi-compand=' + parts.join(':');
  }
}

/// Configuration for the `compensationdelay` audio effect.
///
/// Compensation Delay Line is a metric based delay to compensate differing
/// positions of microphones or speakers.
///
/// For example, you have recorded guitar with two microphones placed in
/// different locations. Because the front of sound wave has fixed speed in
/// normal conditions, the phasing of microphones can vary and depends on
/// their location and interposition. The best sound mix can be achieved when
/// these microphones are in phase (synchronized). Note that a distance of
/// ~30 cm between microphones makes one microphone capture the signal in
/// antiphase to the other microphone. That makes the final mix sound moody.
/// This filter helps to solve phasing problems by adding different delays
/// to each microphone track and make them synchronized.
///
/// The best result can be reached when you take one track as base and
/// synchronize other tracks one by one with it.
/// Remember that synchronization/delay tolerance depends on sample rate, too.
/// Higher sample rates will give more tolerance.
///
/// The filter accepts the following parameters:
///
/// Parameters:
/// - [cm]: Set cm distance. This is compensation distance for tightening distance setup. Default is 0. (range 0..100, default 0)
/// - [dry]: Set dry amount. Amount of unprocessed (dry) signal. Default is 0. (range 0..1, default 0)
/// - [m]: Set meters distance. This is compensation distance for hard distance setup. Default is 0. (range 0..100, default 0)
/// - [mm]: Set millimeters distance. This is compensation distance for fine tuning. Default is 0. (range 0..10, default 0)
/// - [temp]: Set temperature in degrees Celsius. This is the temperature of the environment. Default is 20. (range -50..50, default 20)
/// - [wet]: Set wet amount. Amount of processed (wet) signal. Default is 1. (range 0..1, default 1)
final class CompensationdelaySettings {
  /// Default value for [cm].
  static const int cmDefault = 0;

  /// Minimum value for [cm].
  static const int cmMin = 0;

  /// Maximum value for [cm].
  static const int cmMax = 100;

  /// Default value for [dry].
  static const double dryDefault = 0.0;

  /// Minimum value for [dry].
  static const double dryMin = 0.0;

  /// Maximum value for [dry].
  static const double dryMax = 1.0;

  /// Default value for [m].
  static const int mDefault = 0;

  /// Minimum value for [m].
  static const int mMin = 0;

  /// Maximum value for [m].
  static const int mMax = 100;

  /// Default value for [mm].
  static const int mmDefault = 0;

  /// Minimum value for [mm].
  static const int mmMin = 0;

  /// Maximum value for [mm].
  static const int mmMax = 10;

  /// Default value for [temp].
  static const int tempDefault = 20;

  /// Minimum value for [temp].
  static const int tempMin = -50;

  /// Maximum value for [temp].
  static const int tempMax = 50;

  /// Default value for [wet].
  static const double wetDefault = 1.0;

  /// Minimum value for [wet].
  static const double wetMin = 0.0;

  /// Maximum value for [wet].
  static const double wetMax = 1.0;

  /// Whether this effect is inserted into the audio chain.
  final bool enabled;

  /// set cm distance
  final int cm;

  /// set dry amount
  final double dry;

  /// set meter distance
  final int m;

  /// set mm distance
  final int mm;

  /// set temperature °C
  final int temp;

  /// set wet amount
  final double wet;

  /// Creates an [CompensationdelaySettings] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default; the effect stays
  /// inactive until [enabled] is set to `true`.
  const CompensationdelaySettings({
    this.enabled = false,
    this.cm = 0,
    this.dry = 0.0,
    this.m = 0,
    this.mm = 0,
    this.temp = 20,
    this.wet = 1.0,
  });

  /// Returns a copy of this [CompensationdelaySettings] with the given fields replaced.
  CompensationdelaySettings copyWith({
    bool? enabled,
    int? cm,
    double? dry,
    int? m,
    int? mm,
    int? temp,
    double? wet,
  }) =>
      CompensationdelaySettings(
        enabled: enabled ?? this.enabled,
        cm: cm ?? this.cm,
        dry: dry ?? this.dry,
        m: m ?? this.m,
        mm: mm ?? this.mm,
        temp: temp ?? this.temp,
        wet: wet ?? this.wet,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CompensationdelaySettings &&
          other.enabled == enabled &&
          other.cm == cm &&
          other.dry == dry &&
          other.m == m &&
          other.mm == mm &&
          other.temp == temp &&
          other.wet == wet);

  @override
  int get hashCode => Object.hash(enabled, cm, dry, m, mm, temp, wet);

  @override
  String toString() =>
      'CompensationdelaySettings(enabled: $enabled, cm: $cm, dry: $dry, m: $m, mm: $mm, temp: $temp, wet: $wet)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(cm >= cmMin, 'compensationdelay.cm must be >= 0');
    assert(cm <= cmMax, 'compensationdelay.cm must be <= 100');
    assert(dry >= dryMin, 'compensationdelay.dry must be >= 0');
    assert(dry <= dryMax, 'compensationdelay.dry must be <= 1');
    assert(m >= mMin, 'compensationdelay.m must be >= 0');
    assert(m <= mMax, 'compensationdelay.m must be <= 100');
    assert(mm >= mmMin, 'compensationdelay.mm must be >= 0');
    assert(mm <= mmMax, 'compensationdelay.mm must be <= 10');
    assert(temp >= tempMin, 'compensationdelay.temp must be >= -50');
    assert(temp <= tempMax, 'compensationdelay.temp must be <= 50');
    assert(wet >= wetMin, 'compensationdelay.wet must be >= 0');
    assert(wet <= wetMax, 'compensationdelay.wet must be <= 1');
    final parts = <String>[];
    if (cm != 0) parts.add('cm=' + cm.toString());
    if (dry != 0.0) parts.add('dry=' + _wireDouble(dry));
    if (m != 0) parts.add('m=' + m.toString());
    if (mm != 0) parts.add('mm=' + mm.toString());
    if (temp != 20) parts.add('temp=' + temp.toString());
    if (wet != 1.0) parts.add('wet=' + _wireDouble(wet));
    return parts.isEmpty
        ? 'lavfi-compensationdelay'
        : 'lavfi-compensationdelay=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  List<(String, String)>? _runtimeDiff(CompensationdelaySettings prev) {
    final out = <(String, String)>[];
    if (cm != prev.cm) return null;
    if (dry != prev.dry) return null;
    if (m != prev.m) return null;
    if (mm != prev.mm) return null;
    if (temp != prev.temp) return null;
    if (wet != prev.wet) return null;
    return out;
  }
}

/// Configuration for the `crossfeed` audio effect.
///
/// Apply headphone crossfeed filter.
///
/// Crossfeed is the process of blending the left and right channels of stereo
/// audio recording.
/// It is mainly used to reduce extreme stereo separation of low frequencies.
///
/// The intent is to produce more speaker like sound to the listener.
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [block_size]: Set block size used for reverse IIR processing. If this value is set to high enough value (higher than impulse response length truncated when reaches near zero values) filtering will become linear phase otherwise if not big enough it will just produce nasty artifacts.  Note that filter delay will be exactly this many samples when set to non-zero value. (range 0..32768, default 0)
/// - [level_in]: Set input gain. Default is 0.9. (range 0..1, default .9, runtime-tunable)
/// - [level_out]: Set output gain. Default is 1. (range 0..1, default 1., runtime-tunable)
/// - [range]: Set soundstage wideness. Default is 0.5. Allowed range is from 0 to 1. This sets cut off frequency of low shelf filter. Default is cut off near 1550 Hz. With range set to 1 cut off frequency is set to 2100 Hz. (range 0..1, default .5, runtime-tunable)
/// - [slope]: Set curve slope of low shelf filter. Default is 0.5. Allowed range is from 0.01 to 1. (range .01..1, default .5, runtime-tunable)
/// - [strength]: Set strength of crossfeed. Default is 0.2. Allowed range is from 0 to 1. This sets gain of low shelf filter for side part of stereo image. Default is -6dB. Max allowed is -30db when strength is set to 1. (range 0..1, default .2, runtime-tunable)
final class CrossfeedSettings {
  /// Default value for [block_size].
  static const int block_sizeDefault = 0;

  /// Minimum value for [block_size].
  static const int block_sizeMin = 0;

  /// Maximum value for [block_size].
  static const int block_sizeMax = 32768;

  /// Default value for [level_in].
  static const double level_inDefault = .9;

  /// Minimum value for [level_in].
  static const double level_inMin = 0.0;

  /// Maximum value for [level_in].
  static const double level_inMax = 1.0;

  /// Default value for [level_out].
  static const double level_outDefault = 1.0;

  /// Minimum value for [level_out].
  static const double level_outMin = 0.0;

  /// Maximum value for [level_out].
  static const double level_outMax = 1.0;

  /// Default value for [range].
  static const double rangeDefault = .5;

  /// Minimum value for [range].
  static const double rangeMin = 0.0;

  /// Maximum value for [range].
  static const double rangeMax = 1.0;

  /// Default value for [slope].
  static const double slopeDefault = .5;

  /// Minimum value for [slope].
  static const double slopeMin = .01;

  /// Maximum value for [slope].
  static const double slopeMax = 1.0;

  /// Default value for [strength].
  static const double strengthDefault = .2;

  /// Minimum value for [strength].
  static const double strengthMin = 0.0;

  /// Maximum value for [strength].
  static const double strengthMax = 1.0;

  /// Whether this effect is inserted into the audio chain.
  final bool enabled;

  /// set the block size
  final int block_size;

  /// set level in
  final double level_in;

  /// set level out
  final double level_out;

  /// set soundstage wideness
  final double range;

  /// set curve slope
  final double slope;

  /// set crossfeed strength
  final double strength;

  /// Creates an [CrossfeedSettings] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default; the effect stays
  /// inactive until [enabled] is set to `true`.
  const CrossfeedSettings({
    this.enabled = false,
    this.block_size = 0,
    this.level_in = .9,
    this.level_out = 1.0,
    this.range = .5,
    this.slope = .5,
    this.strength = .2,
  });

  /// Returns a copy of this [CrossfeedSettings] with the given fields replaced.
  CrossfeedSettings copyWith({
    bool? enabled,
    int? block_size,
    double? level_in,
    double? level_out,
    double? range,
    double? slope,
    double? strength,
  }) =>
      CrossfeedSettings(
        enabled: enabled ?? this.enabled,
        block_size: block_size ?? this.block_size,
        level_in: level_in ?? this.level_in,
        level_out: level_out ?? this.level_out,
        range: range ?? this.range,
        slope: slope ?? this.slope,
        strength: strength ?? this.strength,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CrossfeedSettings &&
          other.enabled == enabled &&
          other.block_size == block_size &&
          other.level_in == level_in &&
          other.level_out == level_out &&
          other.range == range &&
          other.slope == slope &&
          other.strength == strength);

  @override
  int get hashCode => Object.hash(
      enabled, block_size, level_in, level_out, range, slope, strength,);

  @override
  String toString() =>
      'CrossfeedSettings(enabled: $enabled, block_size: $block_size, level_in: $level_in, level_out: $level_out, range: $range, slope: $slope, strength: $strength)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(block_size >= block_sizeMin, 'crossfeed.block_size must be >= 0');
    assert(
        block_size <= block_sizeMax, 'crossfeed.block_size must be <= 32768',);
    assert(level_in >= level_inMin, 'crossfeed.level_in must be >= 0');
    assert(level_in <= level_inMax, 'crossfeed.level_in must be <= 1');
    assert(level_out >= level_outMin, 'crossfeed.level_out must be >= 0');
    assert(level_out <= level_outMax, 'crossfeed.level_out must be <= 1');
    assert(range >= rangeMin, 'crossfeed.range must be >= 0');
    assert(range <= rangeMax, 'crossfeed.range must be <= 1');
    assert(slope >= slopeMin, 'crossfeed.slope must be >= .01');
    assert(slope <= slopeMax, 'crossfeed.slope must be <= 1');
    assert(strength >= strengthMin, 'crossfeed.strength must be >= 0');
    assert(strength <= strengthMax, 'crossfeed.strength must be <= 1');
    final parts = <String>[];
    if (block_size != 0) parts.add('block_size=' + block_size.toString());
    if (level_in != .9) parts.add('level_in=' + _wireDouble(level_in));
    if (level_out != 1.0) parts.add('level_out=' + _wireDouble(level_out));
    if (range != .5) parts.add('range=' + _wireDouble(range));
    if (slope != .5) parts.add('slope=' + _wireDouble(slope));
    if (strength != .2) parts.add('strength=' + _wireDouble(strength));
    return parts.isEmpty
        ? 'lavfi-crossfeed'
        : 'lavfi-crossfeed=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  List<(String, String)>? _runtimeDiff(CrossfeedSettings prev) {
    final out = <(String, String)>[];
    if (block_size != prev.block_size) return null;
    if (level_in != prev.level_in) {
      out.add(('level_in', _wireDouble(level_in)));
    }
    if (level_out != prev.level_out) {
      out.add(('level_out', _wireDouble(level_out)));
    }
    if (range != prev.range) {
      out.add(('range', _wireDouble(range)));
    }
    if (slope != prev.slope) {
      out.add(('slope', _wireDouble(slope)));
    }
    if (strength != prev.strength) {
      out.add(('strength', _wireDouble(strength)));
    }
    return out;
  }
}

/// Configuration for the `crystalizer` audio effect.
///
/// Simple algorithm for audio noise sharpening.
///
/// This filter linearly increases differences between each audio sample.
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [c]: Enable clipping. By default is enabled. (range 0..1, default 1, runtime-tunable)
/// - [i]: Sets the intensity of effect (default: 2.0). Must be in range between -10.0 to 0 (unchanged sound) to 10.0 (maximum effect). To inverse filtering use negative value. (range -10..10, default 2.0, runtime-tunable)
final class CrystalizerSettings {
  /// Default value for [i].
  static const double iDefault = 2.0;

  /// Minimum value for [i].
  static const double iMin = -10.0;

  /// Maximum value for [i].
  static const double iMax = 10.0;

  /// Whether this effect is inserted into the audio chain.
  final bool enabled;

  /// enable clipping
  final bool c;

  /// set intensity
  final double i;

  /// Creates an [CrystalizerSettings] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default; the effect stays
  /// inactive until [enabled] is set to `true`.
  const CrystalizerSettings({
    this.enabled = false,
    this.c = true,
    this.i = 2.0,
  });

  /// Returns a copy of this [CrystalizerSettings] with the given fields replaced.
  CrystalizerSettings copyWith({
    bool? enabled,
    bool? c,
    double? i,
  }) =>
      CrystalizerSettings(
        enabled: enabled ?? this.enabled,
        c: c ?? this.c,
        i: i ?? this.i,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CrystalizerSettings &&
          other.enabled == enabled &&
          other.c == c &&
          other.i == i);

  @override
  int get hashCode => Object.hash(enabled, c, i);

  @override
  String toString() => 'CrystalizerSettings(enabled: $enabled, c: $c, i: $i)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(i >= iMin, 'crystalizer.i must be >= -10');
    assert(i <= iMax, 'crystalizer.i must be <= 10');
    final parts = <String>[];
    if (c != true) parts.add('c=' + (c ? '1' : '0'));
    if (i != 2.0) parts.add('i=' + _wireDouble(i));
    return parts.isEmpty
        ? 'lavfi-crystalizer'
        : 'lavfi-crystalizer=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  List<(String, String)>? _runtimeDiff(CrystalizerSettings prev) {
    final out = <(String, String)>[];
    if (c != prev.c) {
      out.add(('c', (c ? '1' : '0')));
    }
    if (i != prev.i) {
      out.add(('i', _wireDouble(i)));
    }
    return out;
  }
}

/// Configuration for the `dcshift` audio effect.
///
/// Apply a DC shift to the audio.
///
/// This can be useful to remove a DC offset (caused perhaps by a hardware problem
/// in the recording chain) from the audio. The effect of a DC offset is reduced
/// headroom and hence volume. The astats filter can be used to determine if
/// a signal has a DC offset.
///
/// Parameters:
/// - [limitergain]: Optional. It should have a value much less than 1 (e.g. 0.05 or 0.02) and is used to prevent clipping. (range 0..1, default 0)
/// - [shift]: Set the DC shift, allowed range is [-1, 1]. It indicates the amount to shift the audio. (range -1..1, default 0)
final class DcshiftSettings {
  /// Default value for [limitergain].
  static const double limitergainDefault = 0.0;

  /// Minimum value for [limitergain].
  static const double limitergainMin = 0.0;

  /// Maximum value for [limitergain].
  static const double limitergainMax = 1.0;

  /// Default value for [shift].
  static const double shiftDefault = 0.0;

  /// Minimum value for [shift].
  static const double shiftMin = -1.0;

  /// Maximum value for [shift].
  static const double shiftMax = 1.0;

  /// Whether this effect is inserted into the audio chain.
  final bool enabled;

  /// set limiter gain
  final double limitergain;

  /// set DC shift
  final double shift;

  /// Creates an [DcshiftSettings] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default; the effect stays
  /// inactive until [enabled] is set to `true`.
  const DcshiftSettings({
    this.enabled = false,
    this.limitergain = 0.0,
    this.shift = 0.0,
  });

  /// Returns a copy of this [DcshiftSettings] with the given fields replaced.
  DcshiftSettings copyWith({
    bool? enabled,
    double? limitergain,
    double? shift,
  }) =>
      DcshiftSettings(
        enabled: enabled ?? this.enabled,
        limitergain: limitergain ?? this.limitergain,
        shift: shift ?? this.shift,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DcshiftSettings &&
          other.enabled == enabled &&
          other.limitergain == limitergain &&
          other.shift == shift);

  @override
  int get hashCode => Object.hash(enabled, limitergain, shift);

  @override
  String toString() =>
      'DcshiftSettings(enabled: $enabled, limitergain: $limitergain, shift: $shift)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(limitergain >= limitergainMin, 'dcshift.limitergain must be >= 0');
    assert(limitergain <= limitergainMax, 'dcshift.limitergain must be <= 1');
    assert(shift >= shiftMin, 'dcshift.shift must be >= -1');
    assert(shift <= shiftMax, 'dcshift.shift must be <= 1');
    final parts = <String>[];
    if (limitergain != 0.0)
      parts.add('limitergain=' + _wireDouble(limitergain));
    if (shift != 0.0) parts.add('shift=' + _wireDouble(shift));
    return parts.isEmpty ? 'lavfi-dcshift' : 'lavfi-dcshift=' + parts.join(':');
  }
}

/// Configuration for the `deesser` audio effect.
///
/// Apply de-essing to the audio samples.
///
/// Parameters:
/// - [f]: How much of original frequency content to keep when de-essing. Allowed range is from 0 to 1. Default is 0.5. (range 0.0..1.0, default 0.5)
/// - [i]: Set intensity for triggering de-essing. Allowed range is from 0 to 1. Default is 0. (range 0.0..1.0, default 0.0)
/// - [m]: Set amount of ducking on treble part of sound. Allowed range is from 0 to 1. Default is 0.5. (range 0.0..1.0, default 0.5)
/// - [s]: Set the output mode.  It accepts the following values: (range 0..2, default OUT_MODE)
final class DeesserSettings {
  /// Default value for [f].
  static const double fDefault = 0.5;

  /// Minimum value for [f].
  static const double fMin = 0.0;

  /// Maximum value for [f].
  static const double fMax = 1.0;

  /// Default value for [i].
  static const double iDefault = 0.0;

  /// Minimum value for [i].
  static const double iMin = 0.0;

  /// Maximum value for [i].
  static const double iMax = 1.0;

  /// Default value for [m].
  static const double mDefault = 0.5;

  /// Minimum value for [m].
  static const double mMin = 0.0;

  /// Maximum value for [m].
  static const double mMax = 1.0;

  /// Whether this effect is inserted into the audio chain.
  final bool enabled;

  /// set frequency
  final double f;

  /// set intensity
  final double i;

  /// set max deessing
  final double m;

  /// set output mode
  final DeesserMode s;

  /// Creates an [DeesserSettings] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default; the effect stays
  /// inactive until [enabled] is set to `true`.
  const DeesserSettings({
    this.enabled = false,
    this.f = 0.5,
    this.i = 0.0,
    this.m = 0.5,
    this.s = DeesserMode.o,
  });

  /// Returns a copy of this [DeesserSettings] with the given fields replaced.
  DeesserSettings copyWith({
    bool? enabled,
    double? f,
    double? i,
    double? m,
    DeesserMode? s,
  }) =>
      DeesserSettings(
        enabled: enabled ?? this.enabled,
        f: f ?? this.f,
        i: i ?? this.i,
        m: m ?? this.m,
        s: s ?? this.s,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DeesserSettings &&
          other.enabled == enabled &&
          other.f == f &&
          other.i == i &&
          other.m == m &&
          other.s == s);

  @override
  int get hashCode => Object.hash(enabled, f, i, m, s);

  @override
  String toString() =>
      'DeesserSettings(enabled: $enabled, f: $f, i: $i, m: $m, s: $s)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(f >= fMin, 'deesser.f must be >= 0.0');
    assert(f <= fMax, 'deesser.f must be <= 1.0');
    assert(i >= iMin, 'deesser.i must be >= 0.0');
    assert(i <= iMax, 'deesser.i must be <= 1.0');
    assert(m >= mMin, 'deesser.m must be >= 0.0');
    assert(m <= mMax, 'deesser.m must be <= 1.0');
    final parts = <String>[];
    if (f != 0.5) parts.add('f=' + _wireDouble(f));
    if (i != 0.0) parts.add('i=' + _wireDouble(i));
    if (m != 0.5) parts.add('m=' + _wireDouble(m));
    if (s != DeesserMode.o) parts.add('s=' + s.mpvValue);
    return parts.isEmpty ? 'lavfi-deesser' : 'lavfi-deesser=' + parts.join(':');
  }
}

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
final class DialoguenhanceSettings {
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

  /// Whether this effect is inserted into the audio chain.
  final bool enabled;

  /// set dialogue enhance factor
  final double enhance;

  /// set original center factor
  final double original;

  /// set voice detection factor
  final double voice;

  /// Creates an [DialoguenhanceSettings] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default; the effect stays
  /// inactive until [enabled] is set to `true`.
  const DialoguenhanceSettings({
    this.enabled = false,
    this.enhance = 1.0,
    this.original = 1.0,
    this.voice = 2.0,
  });

  /// Returns a copy of this [DialoguenhanceSettings] with the given fields replaced.
  DialoguenhanceSettings copyWith({
    bool? enabled,
    double? enhance,
    double? original,
    double? voice,
  }) =>
      DialoguenhanceSettings(
        enabled: enabled ?? this.enabled,
        enhance: enhance ?? this.enhance,
        original: original ?? this.original,
        voice: voice ?? this.voice,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DialoguenhanceSettings &&
          other.enabled == enabled &&
          other.enhance == enhance &&
          other.original == original &&
          other.voice == voice);

  @override
  int get hashCode => Object.hash(enabled, enhance, original, voice);

  @override
  String toString() =>
      'DialoguenhanceSettings(enabled: $enabled, enhance: $enhance, original: $original, voice: $voice)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
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
  List<(String, String)>? _runtimeDiff(DialoguenhanceSettings prev) {
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

/// Configuration for the `drmeter` audio effect.
///
/// Measure audio dynamic range.
///
/// DR values of 14 and higher is found in very dynamic material. DR of 8 to 13
/// is found in transition material. And anything less that 8 have very poor dynamics
/// and is very compressed.
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [length]: Set window length in seconds used to split audio into segments of equal length. Default is 3 seconds. (range .01..10, default 3)
final class DrmeterSettings {
  /// Default value for [length].
  static const double lengthDefault = 3.0;

  /// Minimum value for [length].
  static const double lengthMin = .01;

  /// Maximum value for [length].
  static const double lengthMax = 10.0;

  /// Whether this effect is inserted into the audio chain.
  final bool enabled;

  /// set the window length
  final double length;

  /// Creates an [DrmeterSettings] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default; the effect stays
  /// inactive until [enabled] is set to `true`.
  const DrmeterSettings({
    this.enabled = false,
    this.length = 3.0,
  });

  /// Returns a copy of this [DrmeterSettings] with the given fields replaced.
  DrmeterSettings copyWith({
    bool? enabled,
    double? length,
  }) =>
      DrmeterSettings(
        enabled: enabled ?? this.enabled,
        length: length ?? this.length,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DrmeterSettings &&
          other.enabled == enabled &&
          other.length == length);

  @override
  int get hashCode => Object.hash(enabled, length);

  @override
  String toString() => 'DrmeterSettings(enabled: $enabled, length: $length)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(length >= lengthMin, 'drmeter.length must be >= .01');
    assert(length <= lengthMax, 'drmeter.length must be <= 10');
    final parts = <String>[];
    if (length != 3.0) parts.add('length=' + _wireDouble(length));
    return parts.isEmpty ? 'lavfi-drmeter' : 'lavfi-drmeter=' + parts.join(':');
  }
}

/// Configuration for the `dynaudnorm` audio effect.
///
/// Dynamic Audio Normalizer.
///
/// This filter applies a certain amount of gain to the input audio in order
/// to bring its peak magnitude to a target level (e.g. 0 dBFS). However, in
/// contrast to more "simple" normalization algorithms, the Dynamic Audio
/// Normalizer *dynamically* re-adjusts the gain factor to the input audio.
/// This allows for applying extra gain to the "quiet" sections of the audio
/// while avoiding distortions or clipping the "loud" sections. In other words:
/// The Dynamic Audio Normalizer will "even out" the volume of quiet and loud
/// sections, in the sense that the volume of each section is brought to the
/// same target level. Note, however, that the Dynamic Audio Normalizer achieves
/// this goal *without* applying "dynamic range compressing". It will retain 100%
/// of the dynamic range *within* each section of the audio file.
///
/// Parameters:
/// - [altboundary]: Enable alternative boundary mode. By default is disabled. The Dynamic Audio Normalizer takes into account a certain neighbourhood around each frame. This includes the preceding frames as well as the subsequent frames. However, for the "boundary" frames, located at the very beginning and at the very end of the audio file, not all neighbouring frames are available. In particular, for the first few frames in the audio file, the preceding frames are not known. And, similarly, for the last few frames in the audio file, the subsequent frames are not known. Thus, the question arises which gain factors should be assumed for the missing frames in the "boundary" region. The Dynamic Audio Normalizer implements two modes to deal with this situation. The default boundary mode assumes a gain factor of exactly 1.0 for the missing frames, resulting in a smooth "fade in" and "fade out" at the beginning and at the end of the input, respectively. (range 0..1, default 0, runtime-tunable)
/// - [b]: Enable alternative boundary mode. By default is disabled. The Dynamic Audio Normalizer takes into account a certain neighbourhood around each frame. This includes the preceding frames as well as the subsequent frames. However, for the "boundary" frames, located at the very beginning and at the very end of the audio file, not all neighbouring frames are available. In particular, for the first few frames in the audio file, the preceding frames are not known. And, similarly, for the last few frames in the audio file, the subsequent frames are not known. Thus, the question arises which gain factors should be assumed for the missing frames in the "boundary" region. The Dynamic Audio Normalizer implements two modes to deal with this situation. The default boundary mode assumes a gain factor of exactly 1.0 for the missing frames, resulting in a smooth "fade in" and "fade out" at the beginning and at the end of the input, respectively. (range 0..1, default 0, runtime-tunable)
/// - [c]: Enable DC bias correction. By default is disabled. An audio signal (in the time domain) is a sequence of sample values. In the Dynamic Audio Normalizer these sample values are represented in the -1.0 to 1.0 range, regardless of the original input format. Normally, the audio signal, or "waveform", should be centered around the zero point. That means if we calculate the mean value of all samples in a file, or in a single frame, then the result should be 0.0 or at least very close to that value. If, however, there is a significant deviation of the mean value from 0.0, in either positive or negative direction, this is referred to as a DC bias or DC offset. Since a DC bias is clearly undesirable, the Dynamic Audio Normalizer provides optional DC bias correction. With DC bias correction enabled, the Dynamic Audio Normalizer will determine the mean value, or "DC correction" offset, of each input frame and subtract that value from all of the frame's sample values which ensures those samples are centered around 0.0 again. Also, in order to avoid "gaps" at the frame boundaries, the DC correction offset values will be interpolated smoothly between neighbouring frames. (range 0..1, default 0, runtime-tunable)
/// - [channels]: Specify which channels to filter, by default all available channels are filtered. (range 0..0, default "all", runtime-tunable)
/// - [compress]: Set the compress factor. In range from 0.0 to 30.0. Default is 0.0. By default, the Dynamic Audio Normalizer does not apply "traditional" compression. This means that signal peaks will not be pruned and thus the full dynamic range will be retained within each local neighbourhood. However, in some cases it may be desirable to combine the Dynamic Audio Normalizer's normalization algorithm with a more "traditional" compression. For this purpose, the Dynamic Audio Normalizer provides an optional compression (thresholding) function. If (and only if) the compression feature is enabled, all input frames will be processed by a soft knee thresholding function prior to the actual normalization process. Put simply, the thresholding function is going to prune all samples whose magnitude exceeds a certain threshold value. However, the Dynamic Audio Normalizer does not simply apply a fixed threshold value. Instead, the threshold value will be adjusted for each individual frame. In general, smaller parameters result in stronger compression, and vice versa. Values below 3.0 are not recommended, because audible distortion may appear. (range 0.0..30.0, default 0.0, runtime-tunable)
/// - [correctdc]: Enable DC bias correction. By default is disabled. An audio signal (in the time domain) is a sequence of sample values. In the Dynamic Audio Normalizer these sample values are represented in the -1.0 to 1.0 range, regardless of the original input format. Normally, the audio signal, or "waveform", should be centered around the zero point. That means if we calculate the mean value of all samples in a file, or in a single frame, then the result should be 0.0 or at least very close to that value. If, however, there is a significant deviation of the mean value from 0.0, in either positive or negative direction, this is referred to as a DC bias or DC offset. Since a DC bias is clearly undesirable, the Dynamic Audio Normalizer provides optional DC bias correction. With DC bias correction enabled, the Dynamic Audio Normalizer will determine the mean value, or "DC correction" offset, of each input frame and subtract that value from all of the frame's sample values which ensures those samples are centered around 0.0 again. Also, in order to avoid "gaps" at the frame boundaries, the DC correction offset values will be interpolated smoothly between neighbouring frames. (range 0..1, default 0, runtime-tunable)
/// - [coupling]: Enable channels coupling. By default is enabled. By default, the Dynamic Audio Normalizer will amplify all channels by the same amount. This means the same gain factor will be applied to all channels, i.e. the maximum possible gain factor is determined by the "loudest" channel. However, in some recordings, it may happen that the volume of the different channels is uneven, e.g. one channel may be "quieter" than the other one(s). In this case, this option can be used to disable the channel coupling. This way, the gain factor will be determined independently for each channel, depending only on the individual channel's highest magnitude sample. This allows for harmonizing the volume of the different channels. (range 0..1, default 1, runtime-tunable)
/// - [curve]: Specify the peak mapping curve expression which is going to be used when calculating gain applied to frames. The max output frame gain will still be limited by other options mentioned previously for this filter.  The expression can contain the following constants: (default "", runtime-tunable)
/// - [f]: Set the frame length in milliseconds. In range from 10 to 8000 milliseconds. Default is 500 milliseconds. The Dynamic Audio Normalizer processes the input audio in small chunks, referred to as frames. This is required, because a peak magnitude has no meaning for just a single sample value. Instead, we need to determine the peak magnitude for a contiguous sequence of sample values. While a "standard" normalizer would simply use the peak magnitude of the complete file, the Dynamic Audio Normalizer determines the peak magnitude individually for each frame. The length of a frame is specified in milliseconds. By default, the Dynamic Audio Normalizer uses a frame length of 500 milliseconds, which has been found to give good results with most files. Note that the exact frame length, in number of samples, will be determined automatically, based on the sampling rate of the individual input audio file. (range 10..8000, default 500, runtime-tunable)
/// - [framelen]: Set the frame length in milliseconds. In range from 10 to 8000 milliseconds. Default is 500 milliseconds. The Dynamic Audio Normalizer processes the input audio in small chunks, referred to as frames. This is required, because a peak magnitude has no meaning for just a single sample value. Instead, we need to determine the peak magnitude for a contiguous sequence of sample values. While a "standard" normalizer would simply use the peak magnitude of the complete file, the Dynamic Audio Normalizer determines the peak magnitude individually for each frame. The length of a frame is specified in milliseconds. By default, the Dynamic Audio Normalizer uses a frame length of 500 milliseconds, which has been found to give good results with most files. Note that the exact frame length, in number of samples, will be determined automatically, based on the sampling rate of the individual input audio file. (range 10..8000, default 500, runtime-tunable)
/// - [g]: Set the Gaussian filter window size. In range from 3 to 301, must be odd number. Default is 31. Probably the most important parameter of the Dynamic Audio Normalizer is the `window size` of the Gaussian smoothing filter. The filter's window size is specified in frames, centered around the current frame. For the sake of simplicity, this must be an odd number. Consequently, the default value of 31 takes into account the current frame, as well as the 15 preceding frames and the 15 subsequent frames. Using a larger window results in a stronger smoothing effect and thus in less gain variation, i.e. slower gain adaptation. Conversely, using a smaller window results in a weaker smoothing effect and thus in more gain variation, i.e. faster gain adaptation. In other words, the more you increase this value, the more the Dynamic Audio Normalizer will behave like a "traditional" normalization filter. On the contrary, the more you decrease this value, the more the Dynamic Audio Normalizer will behave like a dynamic range compressor. (range 3..301, default 31, runtime-tunable)
/// - [gausssize]: Set the Gaussian filter window size. In range from 3 to 301, must be odd number. Default is 31. Probably the most important parameter of the Dynamic Audio Normalizer is the `window size` of the Gaussian smoothing filter. The filter's window size is specified in frames, centered around the current frame. For the sake of simplicity, this must be an odd number. Consequently, the default value of 31 takes into account the current frame, as well as the 15 preceding frames and the 15 subsequent frames. Using a larger window results in a stronger smoothing effect and thus in less gain variation, i.e. slower gain adaptation. Conversely, using a smaller window results in a weaker smoothing effect and thus in more gain variation, i.e. faster gain adaptation. In other words, the more you increase this value, the more the Dynamic Audio Normalizer will behave like a "traditional" normalization filter. On the contrary, the more you decrease this value, the more the Dynamic Audio Normalizer will behave like a dynamic range compressor. (range 3..301, default 31, runtime-tunable)
/// - [h]: Specify which channels to filter, by default all available channels are filtered. (range 0..0, default "all", runtime-tunable)
/// - [m]: Set the maximum gain factor. In range from 1.0 to 100.0. Default is 10.0. The Dynamic Audio Normalizer determines the maximum possible (local) gain factor for each input frame, i.e. the maximum gain factor that does not result in clipping or distortion. The maximum gain factor is determined by the frame's highest magnitude sample. However, the Dynamic Audio Normalizer additionally bounds the frame's maximum gain factor by a predetermined (global) maximum gain factor. This is done in order to avoid excessive gain factors in "silent" or almost silent frames. By default, the maximum gain factor is 10.0, For most inputs the default value should be sufficient and it usually is not recommended to increase this value. Though, for input with an extremely low overall volume level, it may be necessary to allow even higher gain factors. Note, however, that the Dynamic Audio Normalizer does not simply apply a "hard" threshold (i.e. cut off values above the threshold). Instead, a "sigmoid" threshold function will be applied. This way, the gain factors will smoothly approach the threshold value, but never exceed that value. (range 1.0..100.0, default 10.0, runtime-tunable)
/// - [maxgain]: Set the maximum gain factor. In range from 1.0 to 100.0. Default is 10.0. The Dynamic Audio Normalizer determines the maximum possible (local) gain factor for each input frame, i.e. the maximum gain factor that does not result in clipping or distortion. The maximum gain factor is determined by the frame's highest magnitude sample. However, the Dynamic Audio Normalizer additionally bounds the frame's maximum gain factor by a predetermined (global) maximum gain factor. This is done in order to avoid excessive gain factors in "silent" or almost silent frames. By default, the maximum gain factor is 10.0, For most inputs the default value should be sufficient and it usually is not recommended to increase this value. Though, for input with an extremely low overall volume level, it may be necessary to allow even higher gain factors. Note, however, that the Dynamic Audio Normalizer does not simply apply a "hard" threshold (i.e. cut off values above the threshold). Instead, a "sigmoid" threshold function will be applied. This way, the gain factors will smoothly approach the threshold value, but never exceed that value. (range 1.0..100.0, default 10.0, runtime-tunable)
/// - [n]: Enable channels coupling. By default is enabled. By default, the Dynamic Audio Normalizer will amplify all channels by the same amount. This means the same gain factor will be applied to all channels, i.e. the maximum possible gain factor is determined by the "loudest" channel. However, in some recordings, it may happen that the volume of the different channels is uneven, e.g. one channel may be "quieter" than the other one(s). In this case, this option can be used to disable the channel coupling. This way, the gain factor will be determined independently for each channel, depending only on the individual channel's highest magnitude sample. This allows for harmonizing the volume of the different channels. (range 0..1, default 1, runtime-tunable)
/// - [o]: Specify overlap for frames. If set to 0 (default) no frame overlapping is done. Using >0 and <1 values will make less conservative gain adjustments, like when framelen option is set to smaller value, if framelen option value is compensated for non-zero overlap then gain adjustments will be smoother across time compared to zero overlap case. (range 0.0..1.0, default .0, runtime-tunable)
/// - [overlap]: Specify overlap for frames. If set to 0 (default) no frame overlapping is done. Using >0 and <1 values will make less conservative gain adjustments, like when framelen option is set to smaller value, if framelen option value is compensated for non-zero overlap then gain adjustments will be smoother across time compared to zero overlap case. (range 0.0..1.0, default .0, runtime-tunable)
/// - [p]: Set the target peak value. This specifies the highest permissible magnitude level for the normalized audio input. This filter will try to approach the target peak magnitude as closely as possible, but at the same time it also makes sure that the normalized signal will never exceed the peak magnitude. A frame's maximum local gain factor is imposed directly by the target peak magnitude. The default value is 0.95 and thus leaves a headroom of 5%*. It is not recommended to go above this value. (range 0.0..1.0, default 0.95, runtime-tunable)
/// - [peak]: Set the target peak value. This specifies the highest permissible magnitude level for the normalized audio input. This filter will try to approach the target peak magnitude as closely as possible, but at the same time it also makes sure that the normalized signal will never exceed the peak magnitude. A frame's maximum local gain factor is imposed directly by the target peak magnitude. The default value is 0.95 and thus leaves a headroom of 5%*. It is not recommended to go above this value. (range 0.0..1.0, default 0.95, runtime-tunable)
/// - [r]: Set the target RMS. In range from 0.0 to 1.0. Default is 0.0 - disabled. By default, the Dynamic Audio Normalizer performs "peak" normalization. This means that the maximum local gain factor for each frame is defined (only) by the frame's highest magnitude sample. This way, the samples can be amplified as much as possible without exceeding the maximum signal level, i.e. without clipping. Optionally, however, the Dynamic Audio Normalizer can also take into account the frame's root mean square, abbreviated RMS. In electrical engineering, the RMS is commonly used to determine the power of a time-varying signal. It is therefore considered that the RMS is a better approximation of the "perceived loudness" than just looking at the signal's peak magnitude. Consequently, by adjusting all frames to a constant RMS value, a uniform "perceived loudness" can be established. If a target RMS value has been specified, a frame's local gain factor is defined as the factor that would result in exactly that RMS value. Note, however, that the maximum local gain factor is still restricted by the frame's highest magnitude sample, in order to prevent clipping. (range 0.0..1.0, default 0.0, runtime-tunable)
/// - [s]: Set the compress factor. In range from 0.0 to 30.0. Default is 0.0. By default, the Dynamic Audio Normalizer does not apply "traditional" compression. This means that signal peaks will not be pruned and thus the full dynamic range will be retained within each local neighbourhood. However, in some cases it may be desirable to combine the Dynamic Audio Normalizer's normalization algorithm with a more "traditional" compression. For this purpose, the Dynamic Audio Normalizer provides an optional compression (thresholding) function. If (and only if) the compression feature is enabled, all input frames will be processed by a soft knee thresholding function prior to the actual normalization process. Put simply, the thresholding function is going to prune all samples whose magnitude exceeds a certain threshold value. However, the Dynamic Audio Normalizer does not simply apply a fixed threshold value. Instead, the threshold value will be adjusted for each individual frame. In general, smaller parameters result in stronger compression, and vice versa. Values below 3.0 are not recommended, because audible distortion may appear. (range 0.0..30.0, default 0.0, runtime-tunable)
/// - [t]: Set the target threshold value. This specifies the lowest permissible magnitude level for the audio input which will be normalized. If input frame volume is above this value frame will be normalized. Otherwise frame may not be normalized at all. The default value is set to 0, which means all input frames will be normalized. This option is mostly useful if digital noise is not wanted to be amplified. (range 0.0..1.0, default 0.0, runtime-tunable)
/// - [targetrms]: Set the target RMS. In range from 0.0 to 1.0. Default is 0.0 - disabled. By default, the Dynamic Audio Normalizer performs "peak" normalization. This means that the maximum local gain factor for each frame is defined (only) by the frame's highest magnitude sample. This way, the samples can be amplified as much as possible without exceeding the maximum signal level, i.e. without clipping. Optionally, however, the Dynamic Audio Normalizer can also take into account the frame's root mean square, abbreviated RMS. In electrical engineering, the RMS is commonly used to determine the power of a time-varying signal. It is therefore considered that the RMS is a better approximation of the "perceived loudness" than just looking at the signal's peak magnitude. Consequently, by adjusting all frames to a constant RMS value, a uniform "perceived loudness" can be established. If a target RMS value has been specified, a frame's local gain factor is defined as the factor that would result in exactly that RMS value. Note, however, that the maximum local gain factor is still restricted by the frame's highest magnitude sample, in order to prevent clipping. (range 0.0..1.0, default 0.0, runtime-tunable)
/// - [threshold]: Set the target threshold value. This specifies the lowest permissible magnitude level for the audio input which will be normalized. If input frame volume is above this value frame will be normalized. Otherwise frame may not be normalized at all. The default value is set to 0, which means all input frames will be normalized. This option is mostly useful if digital noise is not wanted to be amplified. (range 0.0..1.0, default 0.0, runtime-tunable)
/// - [v]: Specify the peak mapping curve expression which is going to be used when calculating gain applied to frames. The max output frame gain will still be limited by other options mentioned previously for this filter.  The expression can contain the following constants: (default "", runtime-tunable)
final class DynaudnormSettings {
  /// Default value for [compress].
  static const double compressDefault = 0.0;

  /// Minimum value for [compress].
  static const double compressMin = 0.0;

  /// Maximum value for [compress].
  static const double compressMax = 30.0;

  /// Default value for [f].
  static const int fDefault = 500;

  /// Minimum value for [f].
  static const int fMin = 10;

  /// Maximum value for [f].
  static const int fMax = 8000;

  /// Default value for [framelen].
  static const int framelenDefault = 500;

  /// Minimum value for [framelen].
  static const int framelenMin = 10;

  /// Maximum value for [framelen].
  static const int framelenMax = 8000;

  /// Default value for [g].
  static const int gDefault = 31;

  /// Minimum value for [g].
  static const int gMin = 3;

  /// Maximum value for [g].
  static const int gMax = 301;

  /// Default value for [gausssize].
  static const int gausssizeDefault = 31;

  /// Minimum value for [gausssize].
  static const int gausssizeMin = 3;

  /// Maximum value for [gausssize].
  static const int gausssizeMax = 301;

  /// Default value for [m].
  static const double mDefault = 10.0;

  /// Minimum value for [m].
  static const double mMin = 1.0;

  /// Maximum value for [m].
  static const double mMax = 100.0;

  /// Default value for [maxgain].
  static const double maxgainDefault = 10.0;

  /// Minimum value for [maxgain].
  static const double maxgainMin = 1.0;

  /// Maximum value for [maxgain].
  static const double maxgainMax = 100.0;

  /// Default value for [o].
  static const double oDefault = .0;

  /// Minimum value for [o].
  static const double oMin = 0.0;

  /// Maximum value for [o].
  static const double oMax = 1.0;

  /// Default value for [overlap].
  static const double overlapDefault = .0;

  /// Minimum value for [overlap].
  static const double overlapMin = 0.0;

  /// Maximum value for [overlap].
  static const double overlapMax = 1.0;

  /// Default value for [p].
  static const double pDefault = 0.95;

  /// Minimum value for [p].
  static const double pMin = 0.0;

  /// Maximum value for [p].
  static const double pMax = 1.0;

  /// Default value for [peak].
  static const double peakDefault = 0.95;

  /// Minimum value for [peak].
  static const double peakMin = 0.0;

  /// Maximum value for [peak].
  static const double peakMax = 1.0;

  /// Default value for [r].
  static const double rDefault = 0.0;

  /// Minimum value for [r].
  static const double rMin = 0.0;

  /// Maximum value for [r].
  static const double rMax = 1.0;

  /// Default value for [s].
  static const double sDefault = 0.0;

  /// Minimum value for [s].
  static const double sMin = 0.0;

  /// Maximum value for [s].
  static const double sMax = 30.0;

  /// Default value for [t].
  static const double tDefault = 0.0;

  /// Minimum value for [t].
  static const double tMin = 0.0;

  /// Maximum value for [t].
  static const double tMax = 1.0;

  /// Default value for [targetrms].
  static const double targetrmsDefault = 0.0;

  /// Minimum value for [targetrms].
  static const double targetrmsMin = 0.0;

  /// Maximum value for [targetrms].
  static const double targetrmsMax = 1.0;

  /// Default value for [threshold].
  static const double thresholdDefault = 0.0;

  /// Minimum value for [threshold].
  static const double thresholdMin = 0.0;

  /// Maximum value for [threshold].
  static const double thresholdMax = 1.0;

  /// Whether this effect is inserted into the audio chain.
  final bool enabled;

  /// set alternative boundary mode
  final bool altboundary;

  /// set alternative boundary mode
  final bool b;

  /// set DC correction
  final bool c;

  /// set channels to filter
  final String channels;

  /// set the compress factor
  final double compress;

  /// set DC correction
  final bool correctdc;

  /// set channel coupling
  final bool coupling;

  /// set the custom peak mapping curve
  final String curve;

  /// set the frame length in msec
  final int f;

  /// set the frame length in msec
  final int framelen;

  /// set the filter size
  final int g;

  /// set the filter size
  final int gausssize;

  /// set channels to filter
  final String h;

  /// set the max amplification
  final double m;

  /// set the max amplification
  final double maxgain;

  /// set channel coupling
  final bool n;

  /// set the frame overlap
  final double o;

  /// set the frame overlap
  final double overlap;

  /// set the peak value
  final double p;

  /// set the peak value
  final double peak;

  /// set the target RMS
  final double r;

  /// set the compress factor
  final double s;

  /// set the threshold value
  final double t;

  /// set the target RMS
  final double targetrms;

  /// set the threshold value
  final double threshold;

  /// set the custom peak mapping curve
  final String v;

  /// Creates an [DynaudnormSettings] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default; the effect stays
  /// inactive until [enabled] is set to `true`.
  const DynaudnormSettings({
    this.enabled = false,
    this.altboundary = false,
    this.b = false,
    this.c = false,
    this.channels = 'all',
    this.compress = 0.0,
    this.correctdc = false,
    this.coupling = true,
    this.curve = '',
    this.f = 500,
    this.framelen = 500,
    this.g = 31,
    this.gausssize = 31,
    this.h = 'all',
    this.m = 10.0,
    this.maxgain = 10.0,
    this.n = true,
    this.o = .0,
    this.overlap = .0,
    this.p = 0.95,
    this.peak = 0.95,
    this.r = 0.0,
    this.s = 0.0,
    this.t = 0.0,
    this.targetrms = 0.0,
    this.threshold = 0.0,
    this.v = '',
  });

  /// Returns a copy of this [DynaudnormSettings] with the given fields replaced.
  DynaudnormSettings copyWith({
    bool? enabled,
    bool? altboundary,
    bool? b,
    bool? c,
    String? channels,
    double? compress,
    bool? correctdc,
    bool? coupling,
    String? curve,
    int? f,
    int? framelen,
    int? g,
    int? gausssize,
    String? h,
    double? m,
    double? maxgain,
    bool? n,
    double? o,
    double? overlap,
    double? p,
    double? peak,
    double? r,
    double? s,
    double? t,
    double? targetrms,
    double? threshold,
    String? v,
  }) =>
      DynaudnormSettings(
        enabled: enabled ?? this.enabled,
        altboundary: altboundary ?? this.altboundary,
        b: b ?? this.b,
        c: c ?? this.c,
        channels: channels ?? this.channels,
        compress: compress ?? this.compress,
        correctdc: correctdc ?? this.correctdc,
        coupling: coupling ?? this.coupling,
        curve: curve ?? this.curve,
        f: f ?? this.f,
        framelen: framelen ?? this.framelen,
        g: g ?? this.g,
        gausssize: gausssize ?? this.gausssize,
        h: h ?? this.h,
        m: m ?? this.m,
        maxgain: maxgain ?? this.maxgain,
        n: n ?? this.n,
        o: o ?? this.o,
        overlap: overlap ?? this.overlap,
        p: p ?? this.p,
        peak: peak ?? this.peak,
        r: r ?? this.r,
        s: s ?? this.s,
        t: t ?? this.t,
        targetrms: targetrms ?? this.targetrms,
        threshold: threshold ?? this.threshold,
        v: v ?? this.v,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DynaudnormSettings &&
          other.enabled == enabled &&
          other.altboundary == altboundary &&
          other.b == b &&
          other.c == c &&
          other.channels == channels &&
          other.compress == compress &&
          other.correctdc == correctdc &&
          other.coupling == coupling &&
          other.curve == curve &&
          other.f == f &&
          other.framelen == framelen &&
          other.g == g &&
          other.gausssize == gausssize &&
          other.h == h &&
          other.m == m &&
          other.maxgain == maxgain &&
          other.n == n &&
          other.o == o &&
          other.overlap == overlap &&
          other.p == p &&
          other.peak == peak &&
          other.r == r &&
          other.s == s &&
          other.t == t &&
          other.targetrms == targetrms &&
          other.threshold == threshold &&
          other.v == v);

  @override
  int get hashCode => Object.hashAll([
        enabled,
        altboundary,
        b,
        c,
        channels,
        compress,
        correctdc,
        coupling,
        curve,
        f,
        framelen,
        g,
        gausssize,
        h,
        m,
        maxgain,
        n,
        o,
        overlap,
        p,
        peak,
        r,
        s,
        t,
        targetrms,
        threshold,
        v,
      ]);

  @override
  String toString() =>
      'DynaudnormSettings(enabled: $enabled, altboundary: $altboundary, b: $b, c: $c, channels: $channels, compress: $compress, correctdc: $correctdc, coupling: $coupling, curve: $curve, f: $f, framelen: $framelen, g: $g, gausssize: $gausssize, h: $h, m: $m, maxgain: $maxgain, n: $n, o: $o, overlap: $overlap, p: $p, peak: $peak, r: $r, s: $s, t: $t, targetrms: $targetrms, threshold: $threshold, v: $v)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(compress >= compressMin, 'dynaudnorm.compress must be >= 0.0');
    assert(compress <= compressMax, 'dynaudnorm.compress must be <= 30.0');
    assert(f >= fMin, 'dynaudnorm.f must be >= 10');
    assert(f <= fMax, 'dynaudnorm.f must be <= 8000');
    assert(framelen >= framelenMin, 'dynaudnorm.framelen must be >= 10');
    assert(framelen <= framelenMax, 'dynaudnorm.framelen must be <= 8000');
    assert(g >= gMin, 'dynaudnorm.g must be >= 3');
    assert(g <= gMax, 'dynaudnorm.g must be <= 301');
    assert(gausssize >= gausssizeMin, 'dynaudnorm.gausssize must be >= 3');
    assert(gausssize <= gausssizeMax, 'dynaudnorm.gausssize must be <= 301');
    assert(m >= mMin, 'dynaudnorm.m must be >= 1.0');
    assert(m <= mMax, 'dynaudnorm.m must be <= 100.0');
    assert(maxgain >= maxgainMin, 'dynaudnorm.maxgain must be >= 1.0');
    assert(maxgain <= maxgainMax, 'dynaudnorm.maxgain must be <= 100.0');
    assert(o >= oMin, 'dynaudnorm.o must be >= 0.0');
    assert(o <= oMax, 'dynaudnorm.o must be <= 1.0');
    assert(overlap >= overlapMin, 'dynaudnorm.overlap must be >= 0.0');
    assert(overlap <= overlapMax, 'dynaudnorm.overlap must be <= 1.0');
    assert(p >= pMin, 'dynaudnorm.p must be >= 0.0');
    assert(p <= pMax, 'dynaudnorm.p must be <= 1.0');
    assert(peak >= peakMin, 'dynaudnorm.peak must be >= 0.0');
    assert(peak <= peakMax, 'dynaudnorm.peak must be <= 1.0');
    assert(r >= rMin, 'dynaudnorm.r must be >= 0.0');
    assert(r <= rMax, 'dynaudnorm.r must be <= 1.0');
    assert(s >= sMin, 'dynaudnorm.s must be >= 0.0');
    assert(s <= sMax, 'dynaudnorm.s must be <= 30.0');
    assert(t >= tMin, 'dynaudnorm.t must be >= 0.0');
    assert(t <= tMax, 'dynaudnorm.t must be <= 1.0');
    assert(targetrms >= targetrmsMin, 'dynaudnorm.targetrms must be >= 0.0');
    assert(targetrms <= targetrmsMax, 'dynaudnorm.targetrms must be <= 1.0');
    assert(threshold >= thresholdMin, 'dynaudnorm.threshold must be >= 0.0');
    assert(threshold <= thresholdMax, 'dynaudnorm.threshold must be <= 1.0');
    final parts = <String>[];
    if (altboundary != false)
      parts.add('altboundary=' + (altboundary ? '1' : '0'));
    if (b != false) parts.add('b=' + (b ? '1' : '0'));
    if (c != false) parts.add('c=' + (c ? '1' : '0'));
    if (channels != 'all') parts.add('channels=' + '[' + channels + ']');
    if (compress != 0.0) parts.add('compress=' + _wireDouble(compress));
    if (correctdc != false) parts.add('correctdc=' + (correctdc ? '1' : '0'));
    if (coupling != true) parts.add('coupling=' + (coupling ? '1' : '0'));
    if (curve != '') parts.add('curve=' + '[' + curve + ']');
    if (f != 500) parts.add('f=' + f.toString());
    if (framelen != 500) parts.add('framelen=' + framelen.toString());
    if (g != 31) parts.add('g=' + g.toString());
    if (gausssize != 31) parts.add('gausssize=' + gausssize.toString());
    if (h != 'all') parts.add('h=' + '[' + h + ']');
    if (m != 10.0) parts.add('m=' + _wireDouble(m));
    if (maxgain != 10.0) parts.add('maxgain=' + _wireDouble(maxgain));
    if (n != true) parts.add('n=' + (n ? '1' : '0'));
    if (o != .0) parts.add('o=' + _wireDouble(o));
    if (overlap != .0) parts.add('overlap=' + _wireDouble(overlap));
    if (p != 0.95) parts.add('p=' + _wireDouble(p));
    if (peak != 0.95) parts.add('peak=' + _wireDouble(peak));
    if (r != 0.0) parts.add('r=' + _wireDouble(r));
    if (s != 0.0) parts.add('s=' + _wireDouble(s));
    if (t != 0.0) parts.add('t=' + _wireDouble(t));
    if (targetrms != 0.0) parts.add('targetrms=' + _wireDouble(targetrms));
    if (threshold != 0.0) parts.add('threshold=' + _wireDouble(threshold));
    if (v != '') parts.add('v=' + '[' + v + ']');
    return parts.isEmpty
        ? 'lavfi-dynaudnorm'
        : 'lavfi-dynaudnorm=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  List<(String, String)>? _runtimeDiff(DynaudnormSettings prev) {
    final out = <(String, String)>[];
    if (altboundary != prev.altboundary) {
      out.add(('altboundary', (altboundary ? '1' : '0')));
    }
    if (b != prev.b) {
      out.add(('b', (b ? '1' : '0')));
    }
    if (c != prev.c) {
      out.add(('c', (c ? '1' : '0')));
    }
    if (channels != prev.channels) {
      out.add(('channels', channels));
    }
    if (compress != prev.compress) {
      out.add(('compress', _wireDouble(compress)));
    }
    if (correctdc != prev.correctdc) {
      out.add(('correctdc', (correctdc ? '1' : '0')));
    }
    if (coupling != prev.coupling) {
      out.add(('coupling', (coupling ? '1' : '0')));
    }
    if (curve != prev.curve) {
      out.add(('curve', curve));
    }
    if (f != prev.f) {
      out.add(('f', f.toString()));
    }
    if (framelen != prev.framelen) {
      out.add(('framelen', framelen.toString()));
    }
    if (g != prev.g) {
      out.add(('g', g.toString()));
    }
    if (gausssize != prev.gausssize) {
      out.add(('gausssize', gausssize.toString()));
    }
    if (h != prev.h) {
      out.add(('h', h));
    }
    if (m != prev.m) {
      out.add(('m', _wireDouble(m)));
    }
    if (maxgain != prev.maxgain) {
      out.add(('maxgain', _wireDouble(maxgain)));
    }
    if (n != prev.n) {
      out.add(('n', (n ? '1' : '0')));
    }
    if (o != prev.o) {
      out.add(('o', _wireDouble(o)));
    }
    if (overlap != prev.overlap) {
      out.add(('overlap', _wireDouble(overlap)));
    }
    if (p != prev.p) {
      out.add(('p', _wireDouble(p)));
    }
    if (peak != prev.peak) {
      out.add(('peak', _wireDouble(peak)));
    }
    if (r != prev.r) {
      out.add(('r', _wireDouble(r)));
    }
    if (s != prev.s) {
      out.add(('s', _wireDouble(s)));
    }
    if (t != prev.t) {
      out.add(('t', _wireDouble(t)));
    }
    if (targetrms != prev.targetrms) {
      out.add(('targetrms', _wireDouble(targetrms)));
    }
    if (threshold != prev.threshold) {
      out.add(('threshold', _wireDouble(threshold)));
    }
    if (v != prev.v) {
      out.add(('v', v));
    }
    return out;
  }
}

/// Configuration for the `earwax` audio effect.
///
/// Make audio easier to listen to on headphones.
///
/// This filter adds `cues' to 44.1kHz stereo (i.e. audio CD format) audio
/// so that when listened to on headphones the stereo image is moved from
/// inside your head (standard for headphones) to outside and in front of
/// the listener (standard for speakers).
///
/// Ported from SoX.
final class EarwaxSettings {
  /// Whether this effect is inserted into the audio chain.
  final bool enabled;

  /// Creates an [EarwaxSettings] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default; the effect stays
  /// inactive until [enabled] is set to `true`.
  const EarwaxSettings({
    this.enabled = false,
  });

  /// Returns a copy of this [EarwaxSettings] with the given fields replaced.
  EarwaxSettings copyWith({
    bool? enabled,
  }) =>
      EarwaxSettings(
        enabled: enabled ?? this.enabled,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EarwaxSettings && other.enabled == enabled);

  @override
  int get hashCode => enabled.hashCode;

  @override
  String toString() => 'EarwaxSettings(enabled: $enabled)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    return 'lavfi-earwax';
  }
}

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
final class Ebur128Settings {
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

  /// Whether this effect is inserted into the audio chain.
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

  /// Creates an [Ebur128Settings] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default; the effect stays
  /// inactive until [enabled] is set to `true`.
  const Ebur128Settings({
    this.enabled = false,
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

  /// Returns a copy of this [Ebur128Settings] with the given fields replaced.
  Ebur128Settings copyWith({
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
  }) =>
      Ebur128Settings(
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
      (other is Ebur128Settings &&
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
  int get hashCode => Object.hash(enabled, dualmono, framelog, gauge, metadata,
      meter, panlaw, Object.hashAllUnordered(peak), scale, size, target, video,);

  @override
  String toString() =>
      'Ebur128Settings(enabled: $enabled, dualmono: $dualmono, framelog: $framelog, gauge: $gauge, metadata: $metadata, meter: $meter, panlaw: $panlaw, peak: $peak, scale: $scale, size: $size, target: $target, video: $video)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
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
    if (size != '640x480') parts.add('size=' + '[' + size + ']');
    if (target != -23) parts.add('target=' + target.toString());
    if (video != false) parts.add('video=' + (video ? '1' : '0'));
    return parts.isEmpty ? 'lavfi-ebur128' : 'lavfi-ebur128=' + parts.join(':');
  }
}

/// Configuration for the `equalizer` audio effect.
///
/// Apply a two-pole peaking equalisation (EQ) filter. With this
/// filter, the signal-level at and around a selected frequency can
/// be increased or decreased, whilst (unlike bandpass and bandreject
/// filters) that at all other frequencies is unchanged.
///
/// In order to produce complex equalisation curves, this filter can
/// be given several times, each with a different central frequency.
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [a]: Set transform type of IIR filter. (range 0..6, default DI)
/// - [b]: Set block size used for reverse IIR processing. If this value is set to high enough value (higher than impulse response length truncated when reaches near zero values) filtering will become linear phase otherwise if not big enough it will just produce nasty artifacts.  Note that filter delay will be exactly this many samples when set to non-zero value. (range 0..32768, default 0)
/// - [blocksize]: set the block size (range 0..32768, default 0)
/// - [c]: Specify which channels to filter, by default all available are filtered. (range 0..0, default "all", runtime-tunable)
/// - [channels]: Specify which channels to filter, by default all available are filtered. (range 0..0, default "all", runtime-tunable)
/// - [f]: Set the filter's central frequency in Hz. (range 0..999999, default 0, runtime-tunable)
/// - [frequency]: Set the filter's central frequency in Hz. (range 0..999999, default 0, runtime-tunable)
/// - [g]: Set the required gain or attenuation in dB. Beware of clipping when using a positive gain. (range -900..900, default 0, runtime-tunable)
/// - [gain]: Set the required gain or attenuation in dB. Beware of clipping when using a positive gain. (range -900..900, default 0, runtime-tunable)
/// - [m]: How much to use filtered signal in output. Default is 1. Range is between 0 and 1. (range 0..1, default 1, runtime-tunable)
/// - [mix]: How much to use filtered signal in output. Default is 1. Range is between 0 and 1. (range 0..1, default 1, runtime-tunable)
/// - [n]: Normalize biquad coefficients, by default is disabled. Enabling it will normalize magnitude response at DC to 0dB. (range 0..1, default 0, runtime-tunable)
/// - [normalize]: Normalize biquad coefficients, by default is disabled. Enabling it will normalize magnitude response at DC to 0dB. (range 0..1, default 0, runtime-tunable)
/// - [precision]: Set precision of filtering. (range -1..3, default -1)
/// - [r]: Set precision of filtering. (range -1..3, default -1)
/// - [t]: Set method to specify band-width of filter. (range 1..5, default QFACTOR, runtime-tunable)
/// - [transform]: Set transform type of IIR filter. (range 0..6, default DI)
/// - [w]: Specify the band-width of a filter in width_type units. (range 0..99999, default 1.0, runtime-tunable)
/// - [width]: Specify the band-width of a filter in width_type units. (range 0..99999, default 1.0, runtime-tunable)
/// - [width_type]: Set method to specify band-width of filter. (range 1..5, default QFACTOR, runtime-tunable)
final class EqualizerSettings {
  /// Default value for [b].
  static const int bDefault = 0;

  /// Minimum value for [b].
  static const int bMin = 0;

  /// Maximum value for [b].
  static const int bMax = 32768;

  /// Default value for [blocksize].
  static const int blocksizeDefault = 0;

  /// Minimum value for [blocksize].
  static const int blocksizeMin = 0;

  /// Maximum value for [blocksize].
  static const int blocksizeMax = 32768;

  /// Default value for [f].
  static const double fDefault = 0.0;

  /// Minimum value for [f].
  static const double fMin = 0.0;

  /// Maximum value for [f].
  static const double fMax = 999999.0;

  /// Default value for [frequency].
  static const double frequencyDefault = 0.0;

  /// Minimum value for [frequency].
  static const double frequencyMin = 0.0;

  /// Maximum value for [frequency].
  static const double frequencyMax = 999999.0;

  /// Default value for [g].
  static const double gDefault = 0.0;

  /// Minimum value for [g].
  static const double gMin = -900.0;

  /// Maximum value for [g].
  static const double gMax = 900.0;

  /// Default value for [gain].
  static const double gainDefault = 0.0;

  /// Minimum value for [gain].
  static const double gainMin = -900.0;

  /// Maximum value for [gain].
  static const double gainMax = 900.0;

  /// Default value for [m].
  static const double mDefault = 1.0;

  /// Minimum value for [m].
  static const double mMin = 0.0;

  /// Maximum value for [m].
  static const double mMax = 1.0;

  /// Default value for [mix].
  static const double mixDefault = 1.0;

  /// Minimum value for [mix].
  static const double mixMin = 0.0;

  /// Maximum value for [mix].
  static const double mixMax = 1.0;

  /// Default value for [w].
  static const double wDefault = 1.0;

  /// Minimum value for [w].
  static const double wMin = 0.0;

  /// Maximum value for [w].
  static const double wMax = 99999.0;

  /// Default value for [width].
  static const double widthDefault = 1.0;

  /// Minimum value for [width].
  static const double widthMin = 0.0;

  /// Maximum value for [width].
  static const double widthMax = 99999.0;

  /// Whether this effect is inserted into the audio chain.
  final bool enabled;

  /// set transform type
  final EqualizerTransformType a;

  /// set the block size
  final int b;

  /// set the block size
  final int blocksize;

  /// set channels to filter
  final String c;

  /// set channels to filter
  final String channels;

  /// set central frequency
  final double f;

  /// set central frequency
  final double frequency;

  /// set gain
  final double g;

  /// set gain
  final double gain;

  /// set mix
  final double m;

  /// set mix
  final double mix;

  /// normalize coefficients
  final bool n;

  /// normalize coefficients
  final bool normalize;

  /// set filtering precision
  final EqualizerPrecision precision;

  /// set filtering precision
  final EqualizerPrecision r;

  /// set filter-width type
  final EqualizerWidthType t;

  /// set transform type
  final EqualizerTransformType transform;

  /// set width
  final double w;

  /// set width
  final double width;

  /// set filter-width type
  final EqualizerWidthType width_type;

  /// Creates an [EqualizerSettings] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default; the effect stays
  /// inactive until [enabled] is set to `true`.
  const EqualizerSettings({
    this.enabled = false,
    this.a = EqualizerTransformType.di,
    this.b = 0,
    this.blocksize = 0,
    this.c = 'all',
    this.channels = 'all',
    this.f = 0.0,
    this.frequency = 0.0,
    this.g = 0.0,
    this.gain = 0.0,
    this.m = 1.0,
    this.mix = 1.0,
    this.n = false,
    this.normalize = false,
    this.precision = EqualizerPrecision.auto,
    this.r = EqualizerPrecision.auto,
    this.t = EqualizerWidthType.q,
    this.transform = EqualizerTransformType.di,
    this.w = 1.0,
    this.width = 1.0,
    this.width_type = EqualizerWidthType.q,
  });

  /// Returns a copy of this [EqualizerSettings] with the given fields replaced.
  EqualizerSettings copyWith({
    bool? enabled,
    EqualizerTransformType? a,
    int? b,
    int? blocksize,
    String? c,
    String? channels,
    double? f,
    double? frequency,
    double? g,
    double? gain,
    double? m,
    double? mix,
    bool? n,
    bool? normalize,
    EqualizerPrecision? precision,
    EqualizerPrecision? r,
    EqualizerWidthType? t,
    EqualizerTransformType? transform,
    double? w,
    double? width,
    EqualizerWidthType? width_type,
  }) =>
      EqualizerSettings(
        enabled: enabled ?? this.enabled,
        a: a ?? this.a,
        b: b ?? this.b,
        blocksize: blocksize ?? this.blocksize,
        c: c ?? this.c,
        channels: channels ?? this.channels,
        f: f ?? this.f,
        frequency: frequency ?? this.frequency,
        g: g ?? this.g,
        gain: gain ?? this.gain,
        m: m ?? this.m,
        mix: mix ?? this.mix,
        n: n ?? this.n,
        normalize: normalize ?? this.normalize,
        precision: precision ?? this.precision,
        r: r ?? this.r,
        t: t ?? this.t,
        transform: transform ?? this.transform,
        w: w ?? this.w,
        width: width ?? this.width,
        width_type: width_type ?? this.width_type,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EqualizerSettings &&
          other.enabled == enabled &&
          other.a == a &&
          other.b == b &&
          other.blocksize == blocksize &&
          other.c == c &&
          other.channels == channels &&
          other.f == f &&
          other.frequency == frequency &&
          other.g == g &&
          other.gain == gain &&
          other.m == m &&
          other.mix == mix &&
          other.n == n &&
          other.normalize == normalize &&
          other.precision == precision &&
          other.r == r &&
          other.t == t &&
          other.transform == transform &&
          other.w == w &&
          other.width == width &&
          other.width_type == width_type);

  @override
  int get hashCode => Object.hashAll([
        enabled,
        a,
        b,
        blocksize,
        c,
        channels,
        f,
        frequency,
        g,
        gain,
        m,
        mix,
        n,
        normalize,
        precision,
        r,
        t,
        transform,
        w,
        width,
        width_type,
      ]);

  @override
  String toString() =>
      'EqualizerSettings(enabled: $enabled, a: $a, b: $b, blocksize: $blocksize, c: $c, channels: $channels, f: $f, frequency: $frequency, g: $g, gain: $gain, m: $m, mix: $mix, n: $n, normalize: $normalize, precision: $precision, r: $r, t: $t, transform: $transform, w: $w, width: $width, width_type: $width_type)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(b >= bMin, 'equalizer.b must be >= 0');
    assert(b <= bMax, 'equalizer.b must be <= 32768');
    assert(blocksize >= blocksizeMin, 'equalizer.blocksize must be >= 0');
    assert(blocksize <= blocksizeMax, 'equalizer.blocksize must be <= 32768');
    assert(f >= fMin, 'equalizer.f must be >= 0');
    assert(f <= fMax, 'equalizer.f must be <= 999999');
    assert(frequency >= frequencyMin, 'equalizer.frequency must be >= 0');
    assert(frequency <= frequencyMax, 'equalizer.frequency must be <= 999999');
    assert(g >= gMin, 'equalizer.g must be >= -900');
    assert(g <= gMax, 'equalizer.g must be <= 900');
    assert(gain >= gainMin, 'equalizer.gain must be >= -900');
    assert(gain <= gainMax, 'equalizer.gain must be <= 900');
    assert(m >= mMin, 'equalizer.m must be >= 0');
    assert(m <= mMax, 'equalizer.m must be <= 1');
    assert(mix >= mixMin, 'equalizer.mix must be >= 0');
    assert(mix <= mixMax, 'equalizer.mix must be <= 1');
    assert(w >= wMin, 'equalizer.w must be >= 0');
    assert(w <= wMax, 'equalizer.w must be <= 99999');
    assert(width >= widthMin, 'equalizer.width must be >= 0');
    assert(width <= widthMax, 'equalizer.width must be <= 99999');
    final parts = <String>[];
    if (a != EqualizerTransformType.di) parts.add('a=' + a.mpvValue);
    if (b != 0) parts.add('b=' + b.toString());
    if (blocksize != 0) parts.add('blocksize=' + blocksize.toString());
    if (c != 'all') parts.add('c=' + '[' + c + ']');
    if (channels != 'all') parts.add('channels=' + '[' + channels + ']');
    if (f != 0.0) parts.add('f=' + _wireDouble(f));
    if (frequency != 0.0) parts.add('frequency=' + _wireDouble(frequency));
    if (g != 0.0) parts.add('g=' + _wireDouble(g));
    if (gain != 0.0) parts.add('gain=' + _wireDouble(gain));
    if (m != 1.0) parts.add('m=' + _wireDouble(m));
    if (mix != 1.0) parts.add('mix=' + _wireDouble(mix));
    if (n != false) parts.add('n=' + (n ? '1' : '0'));
    if (normalize != false) parts.add('normalize=' + (normalize ? '1' : '0'));
    if (precision != EqualizerPrecision.auto)
      parts.add('precision=' + precision.mpvValue);
    if (r != EqualizerPrecision.auto) parts.add('r=' + r.mpvValue);
    if (t != EqualizerWidthType.q) parts.add('t=' + t.mpvValue);
    if (transform != EqualizerTransformType.di)
      parts.add('transform=' + transform.mpvValue);
    if (w != 1.0) parts.add('w=' + _wireDouble(w));
    if (width != 1.0) parts.add('width=' + _wireDouble(width));
    if (width_type != EqualizerWidthType.q)
      parts.add('width_type=' + width_type.mpvValue);
    return parts.isEmpty
        ? 'lavfi-equalizer'
        : 'lavfi-equalizer=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  List<(String, String)>? _runtimeDiff(EqualizerSettings prev) {
    final out = <(String, String)>[];
    if (a != prev.a) return null;
    if (b != prev.b) return null;
    if (blocksize != prev.blocksize) return null;
    if (c != prev.c) {
      out.add(('c', c));
    }
    if (channels != prev.channels) {
      out.add(('channels', channels));
    }
    if (f != prev.f) {
      out.add(('f', _wireDouble(f)));
    }
    if (frequency != prev.frequency) {
      out.add(('frequency', _wireDouble(frequency)));
    }
    if (g != prev.g) {
      out.add(('g', _wireDouble(g)));
    }
    if (gain != prev.gain) {
      out.add(('gain', _wireDouble(gain)));
    }
    if (m != prev.m) {
      out.add(('m', _wireDouble(m)));
    }
    if (mix != prev.mix) {
      out.add(('mix', _wireDouble(mix)));
    }
    if (n != prev.n) {
      out.add(('n', (n ? '1' : '0')));
    }
    if (normalize != prev.normalize) {
      out.add(('normalize', (normalize ? '1' : '0')));
    }
    if (precision != prev.precision) return null;
    if (r != prev.r) return null;
    if (t != prev.t) {
      out.add(('t', t.mpvValue));
    }
    if (transform != prev.transform) return null;
    if (w != prev.w) {
      out.add(('w', _wireDouble(w)));
    }
    if (width != prev.width) {
      out.add(('width', _wireDouble(width)));
    }
    if (width_type != prev.width_type) {
      out.add(('width_type', width_type.mpvValue));
    }
    return out;
  }
}

/// Configuration for the `extrastereo` audio effect.
///
/// Linearly increases the difference between left and right channels which
/// adds some sort of "live" effect to playback.
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [c]: Enable clipping. By default is enabled. (range 0..1, default 1, runtime-tunable)
/// - [m]: Sets the difference coefficient (default: 2.5). 0.0 means mono sound (average of both channels), with 1.0 sound will be unchanged, with -1.0 left and right channels will be swapped. (range -10..10, default 2.5, runtime-tunable)
final class ExtrastereoSettings {
  /// Default value for [m].
  static const double mDefault = 2.5;

  /// Minimum value for [m].
  static const double mMin = -10.0;

  /// Maximum value for [m].
  static const double mMax = 10.0;

  /// Whether this effect is inserted into the audio chain.
  final bool enabled;

  /// enable clipping
  final bool c;

  /// set the difference coefficient
  final double m;

  /// Creates an [ExtrastereoSettings] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default; the effect stays
  /// inactive until [enabled] is set to `true`.
  const ExtrastereoSettings({
    this.enabled = false,
    this.c = true,
    this.m = 2.5,
  });

  /// Returns a copy of this [ExtrastereoSettings] with the given fields replaced.
  ExtrastereoSettings copyWith({
    bool? enabled,
    bool? c,
    double? m,
  }) =>
      ExtrastereoSettings(
        enabled: enabled ?? this.enabled,
        c: c ?? this.c,
        m: m ?? this.m,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExtrastereoSettings &&
          other.enabled == enabled &&
          other.c == c &&
          other.m == m);

  @override
  int get hashCode => Object.hash(enabled, c, m);

  @override
  String toString() => 'ExtrastereoSettings(enabled: $enabled, c: $c, m: $m)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(m >= mMin, 'extrastereo.m must be >= -10');
    assert(m <= mMax, 'extrastereo.m must be <= 10');
    final parts = <String>[];
    if (c != true) parts.add('c=' + (c ? '1' : '0'));
    if (m != 2.5) parts.add('m=' + _wireDouble(m));
    return parts.isEmpty
        ? 'lavfi-extrastereo'
        : 'lavfi-extrastereo=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  List<(String, String)>? _runtimeDiff(ExtrastereoSettings prev) {
    final out = <(String, String)>[];
    if (c != prev.c) {
      out.add(('c', (c ? '1' : '0')));
    }
    if (m != prev.m) {
      out.add(('m', _wireDouble(m)));
    }
    return out;
  }
}

/// Configuration for the `firequalizer` audio effect.
///
/// Apply FIR Equalization using arbitrary frequency response.
///
/// The filter accepts the following option:
///
/// Parameters:
/// - [accuracy]: Set filter accuracy in Hz. Lower value means more accurate. Default is `5`. (range 3..1e10, default 5.0)
/// - [delay]: Set filter delay in seconds. Higher value means more accurate. Default is `0.01`. (range 0.0..1e10, default 0.01)
/// - [dumpfile]: Set file for dumping, suitable for gnuplot. (range 0..0, default "")
/// - [dumpscale]: Set scale for dumpfile. Acceptable values are same with scale option. Default is linlog. (range 0..3, default SCALE_LINLOG)
/// - [fft2]: Enable 2-channel convolution using complex FFT. This improves speed significantly. Default is disabled. (range 0..1, default 0)
/// - [fixed]: If enabled, use fixed number of audio samples. This improves speed when filtering with large delay. Default is disabled. (range 0..1, default 0)
/// - [gain]: Set gain curve equation (in dB). The expression can contain variables: (range 0..0, default "gain_interpolate(f)", runtime-tunable)
/// - [gain_entry]: Set gain entry for gain_interpolate function. The expression can contain functions: (range 0..0, default "", runtime-tunable)
/// - [min_phase]: Enable minimum phase impulse response. Default is disabled. (range 0..1, default 0)
/// - [multi]: Enable multichannels evaluation on gain. Default is disabled. (range 0..1, default 0)
/// - [scale]: Set scale used by gain. Acceptable values are: (range 0..3, default SCALE_LINLOG)
/// - [wfunc]: Set window function. Acceptable values are: (range 0..9, default WFUNC_HANN)
/// - [zero_phase]: Enable zero phase mode by subtracting timestamp to compensate delay. Default is disabled. (range 0..1, default 0)
final class FirequalizerSettings {
  /// Default value for [accuracy].
  static const double accuracyDefault = 5.0;

  /// Minimum value for [accuracy].
  static const double accuracyMin = 3.0;

  /// Maximum value for [accuracy].
  static const double accuracyMax = 1e10;

  /// Default value for [delay].
  static const double delayDefault = 0.01;

  /// Minimum value for [delay].
  static const double delayMin = 0.0;

  /// Maximum value for [delay].
  static const double delayMax = 1e10;

  /// Whether this effect is inserted into the audio chain.
  final bool enabled;

  /// set accuracy
  final double accuracy;

  /// set delay
  final double delay;

  /// set dump file
  final String dumpfile;

  /// set dump scale
  final FirequalizerScale dumpscale;

  /// set 2-channels fft
  final bool fft2;

  /// set fixed frame samples
  final bool fixed;

  /// set gain curve
  final String gain;

  /// set gain entry
  final String gain_entry;

  /// set minimum phase mode
  final bool min_phase;

  /// set multi channels mode
  final bool multi;

  /// set gain scale
  final FirequalizerScale scale;

  /// set window function
  final FirequalizerWfunc wfunc;

  /// set zero phase mode
  final bool zero_phase;

  /// Creates an [FirequalizerSettings] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default; the effect stays
  /// inactive until [enabled] is set to `true`.
  const FirequalizerSettings({
    this.enabled = false,
    this.accuracy = 5.0,
    this.delay = 0.01,
    this.dumpfile = '',
    this.dumpscale = FirequalizerScale.linlog,
    this.fft2 = false,
    this.fixed = false,
    this.gain = 'gain_interpolate(f)',
    this.gain_entry = '',
    this.min_phase = false,
    this.multi = false,
    this.scale = FirequalizerScale.linlog,
    this.wfunc = FirequalizerWfunc.hann,
    this.zero_phase = false,
  });

  /// Returns a copy of this [FirequalizerSettings] with the given fields replaced.
  FirequalizerSettings copyWith({
    bool? enabled,
    double? accuracy,
    double? delay,
    String? dumpfile,
    FirequalizerScale? dumpscale,
    bool? fft2,
    bool? fixed,
    String? gain,
    String? gain_entry,
    bool? min_phase,
    bool? multi,
    FirequalizerScale? scale,
    FirequalizerWfunc? wfunc,
    bool? zero_phase,
  }) =>
      FirequalizerSettings(
        enabled: enabled ?? this.enabled,
        accuracy: accuracy ?? this.accuracy,
        delay: delay ?? this.delay,
        dumpfile: dumpfile ?? this.dumpfile,
        dumpscale: dumpscale ?? this.dumpscale,
        fft2: fft2 ?? this.fft2,
        fixed: fixed ?? this.fixed,
        gain: gain ?? this.gain,
        gain_entry: gain_entry ?? this.gain_entry,
        min_phase: min_phase ?? this.min_phase,
        multi: multi ?? this.multi,
        scale: scale ?? this.scale,
        wfunc: wfunc ?? this.wfunc,
        zero_phase: zero_phase ?? this.zero_phase,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FirequalizerSettings &&
          other.enabled == enabled &&
          other.accuracy == accuracy &&
          other.delay == delay &&
          other.dumpfile == dumpfile &&
          other.dumpscale == dumpscale &&
          other.fft2 == fft2 &&
          other.fixed == fixed &&
          other.gain == gain &&
          other.gain_entry == gain_entry &&
          other.min_phase == min_phase &&
          other.multi == multi &&
          other.scale == scale &&
          other.wfunc == wfunc &&
          other.zero_phase == zero_phase);

  @override
  int get hashCode => Object.hash(
      enabled,
      accuracy,
      delay,
      dumpfile,
      dumpscale,
      fft2,
      fixed,
      gain,
      gain_entry,
      min_phase,
      multi,
      scale,
      wfunc,
      zero_phase,);

  @override
  String toString() =>
      'FirequalizerSettings(enabled: $enabled, accuracy: $accuracy, delay: $delay, dumpfile: $dumpfile, dumpscale: $dumpscale, fft2: $fft2, fixed: $fixed, gain: $gain, gain_entry: $gain_entry, min_phase: $min_phase, multi: $multi, scale: $scale, wfunc: $wfunc, zero_phase: $zero_phase)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(accuracy >= accuracyMin, 'firequalizer.accuracy must be >= 3');
    assert(accuracy <= accuracyMax, 'firequalizer.accuracy must be <= 1e10');
    assert(delay >= delayMin, 'firequalizer.delay must be >= 0.0');
    assert(delay <= delayMax, 'firequalizer.delay must be <= 1e10');
    final parts = <String>[];
    if (accuracy != 5.0) parts.add('accuracy=' + _wireDouble(accuracy));
    if (delay != 0.01) parts.add('delay=' + _wireDouble(delay));
    if (dumpfile != '') parts.add('dumpfile=' + '[' + dumpfile + ']');
    if (dumpscale != FirequalizerScale.linlog)
      parts.add('dumpscale=' + dumpscale.mpvValue);
    if (fft2 != false) parts.add('fft2=' + (fft2 ? '1' : '0'));
    if (fixed != false) parts.add('fixed=' + (fixed ? '1' : '0'));
    if (gain != 'gain_interpolate(f)') parts.add('gain=' + '[' + gain + ']');
    if (gain_entry != '') parts.add('gain_entry=' + '[' + gain_entry + ']');
    if (min_phase != false) parts.add('min_phase=' + (min_phase ? '1' : '0'));
    if (multi != false) parts.add('multi=' + (multi ? '1' : '0'));
    if (scale != FirequalizerScale.linlog) parts.add('scale=' + scale.mpvValue);
    if (wfunc != FirequalizerWfunc.hann) parts.add('wfunc=' + wfunc.mpvValue);
    if (zero_phase != false)
      parts.add('zero_phase=' + (zero_phase ? '1' : '0'));
    return parts.isEmpty
        ? 'lavfi-firequalizer'
        : 'lavfi-firequalizer=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  List<(String, String)>? _runtimeDiff(FirequalizerSettings prev) {
    final out = <(String, String)>[];
    if (accuracy != prev.accuracy) return null;
    if (delay != prev.delay) return null;
    if (dumpfile != prev.dumpfile) return null;
    if (dumpscale != prev.dumpscale) return null;
    if (fft2 != prev.fft2) return null;
    if (fixed != prev.fixed) return null;
    if (gain != prev.gain) {
      out.add(('gain', gain));
    }
    if (gain_entry != prev.gain_entry) {
      out.add(('gain_entry', gain_entry));
    }
    if (min_phase != prev.min_phase) return null;
    if (multi != prev.multi) return null;
    if (scale != prev.scale) return null;
    if (wfunc != prev.wfunc) return null;
    if (zero_phase != prev.zero_phase) return null;
    return out;
  }
}

/// Configuration for the `flanger` audio effect.
///
/// Apply a flanging effect to the audio.
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [delay]: Set base delay in milliseconds. Range from 0 to 30. Default value is 0. (range 0..30, default 0)
/// - [depth]: Set added sweep delay in milliseconds. Range from 0 to 10. Default value is 2. (range 0..10, default 2)
/// - [interp]: Set delay-line interpolation, `linear` or `quadratic`. Default is `linear`. (range 0..1, default 0)
/// - [phase]: Set swept wave percentage-shift for multi channel. Range from 0 to 100. Default value is 25. (range 0..100, default 25)
/// - [regen]: Set percentage regeneration (delayed signal feedback). Range from -95 to 95. Default value is 0. (range -95..95, default 0)
/// - [shape]: Set swept wave shape, can be `triangular` or `sinusoidal`. Default value is `sinusoidal`. (default WAVE_SIN)
/// - [speed]: Set sweeps per second (Hz). Range from 0.1 to 10. Default value is 0.5. (range 0.1..10, default 0.5)
/// - [width]: Set percentage of delayed signal mixed with original. Range from 0 to 100. Default value is 71. (range 0..100, default 71)
final class FlangerSettings {
  /// Default value for [delay].
  static const double delayDefault = 0.0;

  /// Minimum value for [delay].
  static const double delayMin = 0.0;

  /// Maximum value for [delay].
  static const double delayMax = 30.0;

  /// Default value for [depth].
  static const double depthDefault = 2.0;

  /// Minimum value for [depth].
  static const double depthMin = 0.0;

  /// Maximum value for [depth].
  static const double depthMax = 10.0;

  /// Default value for [phase].
  static const double phaseDefault = 25.0;

  /// Minimum value for [phase].
  static const double phaseMin = 0.0;

  /// Maximum value for [phase].
  static const double phaseMax = 100.0;

  /// Default value for [regen].
  static const double regenDefault = 0.0;

  /// Minimum value for [regen].
  static const double regenMin = -95.0;

  /// Maximum value for [regen].
  static const double regenMax = 95.0;

  /// Default value for [speed].
  static const double speedDefault = 0.5;

  /// Minimum value for [speed].
  static const double speedMin = 0.1;

  /// Maximum value for [speed].
  static const double speedMax = 10.0;

  /// Default value for [width].
  static const double widthDefault = 71.0;

  /// Minimum value for [width].
  static const double widthMin = 0.0;

  /// Maximum value for [width].
  static const double widthMax = 100.0;

  /// Whether this effect is inserted into the audio chain.
  final bool enabled;

  /// base delay in milliseconds
  final double delay;

  /// added swept delay in milliseconds
  final double depth;

  /// delay-line interpolation
  final FlangerItype interp;

  /// swept wave percentage phase-shift for multi-channel
  final double phase;

  /// percentage regeneration (delayed signal feedback)
  final double regen;

  /// swept wave shape
  final FlangerType shape;

  /// sweeps per second (Hz)
  final double speed;

  /// percentage of delayed signal mixed with original
  final double width;

  /// Creates an [FlangerSettings] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default; the effect stays
  /// inactive until [enabled] is set to `true`.
  const FlangerSettings({
    this.enabled = false,
    this.delay = 0.0,
    this.depth = 2.0,
    this.interp = FlangerItype.linear,
    this.phase = 25.0,
    this.regen = 0.0,
    this.shape = FlangerType.sinusoidal,
    this.speed = 0.5,
    this.width = 71.0,
  });

  /// Returns a copy of this [FlangerSettings] with the given fields replaced.
  FlangerSettings copyWith({
    bool? enabled,
    double? delay,
    double? depth,
    FlangerItype? interp,
    double? phase,
    double? regen,
    FlangerType? shape,
    double? speed,
    double? width,
  }) =>
      FlangerSettings(
        enabled: enabled ?? this.enabled,
        delay: delay ?? this.delay,
        depth: depth ?? this.depth,
        interp: interp ?? this.interp,
        phase: phase ?? this.phase,
        regen: regen ?? this.regen,
        shape: shape ?? this.shape,
        speed: speed ?? this.speed,
        width: width ?? this.width,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FlangerSettings &&
          other.enabled == enabled &&
          other.delay == delay &&
          other.depth == depth &&
          other.interp == interp &&
          other.phase == phase &&
          other.regen == regen &&
          other.shape == shape &&
          other.speed == speed &&
          other.width == width);

  @override
  int get hashCode => Object.hash(
      enabled, delay, depth, interp, phase, regen, shape, speed, width,);

  @override
  String toString() =>
      'FlangerSettings(enabled: $enabled, delay: $delay, depth: $depth, interp: $interp, phase: $phase, regen: $regen, shape: $shape, speed: $speed, width: $width)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(delay >= delayMin, 'flanger.delay must be >= 0');
    assert(delay <= delayMax, 'flanger.delay must be <= 30');
    assert(depth >= depthMin, 'flanger.depth must be >= 0');
    assert(depth <= depthMax, 'flanger.depth must be <= 10');
    assert(phase >= phaseMin, 'flanger.phase must be >= 0');
    assert(phase <= phaseMax, 'flanger.phase must be <= 100');
    assert(regen >= regenMin, 'flanger.regen must be >= -95');
    assert(regen <= regenMax, 'flanger.regen must be <= 95');
    assert(speed >= speedMin, 'flanger.speed must be >= 0.1');
    assert(speed <= speedMax, 'flanger.speed must be <= 10');
    assert(width >= widthMin, 'flanger.width must be >= 0');
    assert(width <= widthMax, 'flanger.width must be <= 100');
    final parts = <String>[];
    if (delay != 0.0) parts.add('delay=' + _wireDouble(delay));
    if (depth != 2.0) parts.add('depth=' + _wireDouble(depth));
    if (interp != FlangerItype.linear) parts.add('interp=' + interp.mpvValue);
    if (phase != 25.0) parts.add('phase=' + _wireDouble(phase));
    if (regen != 0.0) parts.add('regen=' + _wireDouble(regen));
    if (shape != FlangerType.sinusoidal) parts.add('shape=' + shape.mpvValue);
    if (speed != 0.5) parts.add('speed=' + _wireDouble(speed));
    if (width != 71.0) parts.add('width=' + _wireDouble(width));
    return parts.isEmpty ? 'lavfi-flanger' : 'lavfi-flanger=' + parts.join(':');
  }
}

/// Configuration for the `haas` audio effect.
///
/// Apply Haas effect to audio.
///
/// Note that this makes most sense to apply on mono signals.
/// With this filter applied to mono signals it give some directionality and
/// stretches its stereo image.
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [left_balance]: set left balance (range -1..1, default -1.0)
/// - [left_delay]: set left delay (range 0..40, default 2.05)
/// - [left_gain]: set left gain (range 0.015625..64, default 1)
/// - [left_phase]: set left phase (range 0..1, default 0)
/// - [level_in]: Set input level. By default is `1`, or 0dB (range 0.015625..64, default 1)
/// - [level_out]: Set output level. By default is `1`, or 0dB. (range 0.015625..64, default 1)
/// - [middle_phase]: set middle phase (range 0..1, default 0)
/// - [middle_source]: Set kind of middle source. Can be one of the following: (range 0..3, default 2)
/// - [right_balance]: set right balance (range -1..1, default 1)
/// - [right_delay]: set right delay (range 0..40, default 2.12)
/// - [right_gain]: set right gain (range 0.015625..64, default 1)
/// - [right_phase]: set right phase (range 0..1, default 1)
/// - [side_gain]: Set gain applied to side part of signal. By default is `1`. (range 0.015625..64, default 1)
final class HaasSettings {
  /// Default value for [left_balance].
  static const double left_balanceDefault = -1.0;

  /// Minimum value for [left_balance].
  static const double left_balanceMin = -1.0;

  /// Maximum value for [left_balance].
  static const double left_balanceMax = 1.0;

  /// Default value for [left_delay].
  static const double left_delayDefault = 2.05;

  /// Minimum value for [left_delay].
  static const double left_delayMin = 0.0;

  /// Maximum value for [left_delay].
  static const double left_delayMax = 40.0;

  /// Default value for [left_gain].
  static const double left_gainDefault = 1.0;

  /// Minimum value for [left_gain].
  static const double left_gainMin = 0.015625;

  /// Maximum value for [left_gain].
  static const double left_gainMax = 64.0;

  /// Default value for [level_in].
  static const double level_inDefault = 1.0;

  /// Minimum value for [level_in].
  static const double level_inMin = 0.015625;

  /// Maximum value for [level_in].
  static const double level_inMax = 64.0;

  /// Default value for [level_out].
  static const double level_outDefault = 1.0;

  /// Minimum value for [level_out].
  static const double level_outMin = 0.015625;

  /// Maximum value for [level_out].
  static const double level_outMax = 64.0;

  /// Default value for [right_balance].
  static const double right_balanceDefault = 1.0;

  /// Minimum value for [right_balance].
  static const double right_balanceMin = -1.0;

  /// Maximum value for [right_balance].
  static const double right_balanceMax = 1.0;

  /// Default value for [right_delay].
  static const double right_delayDefault = 2.12;

  /// Minimum value for [right_delay].
  static const double right_delayMin = 0.0;

  /// Maximum value for [right_delay].
  static const double right_delayMax = 40.0;

  /// Default value for [right_gain].
  static const double right_gainDefault = 1.0;

  /// Minimum value for [right_gain].
  static const double right_gainMin = 0.015625;

  /// Maximum value for [right_gain].
  static const double right_gainMax = 64.0;

  /// Default value for [side_gain].
  static const double side_gainDefault = 1.0;

  /// Minimum value for [side_gain].
  static const double side_gainMin = 0.015625;

  /// Maximum value for [side_gain].
  static const double side_gainMax = 64.0;

  /// Whether this effect is inserted into the audio chain.
  final bool enabled;

  /// set left balance
  final double left_balance;

  /// set left delay
  final double left_delay;

  /// set left gain
  final double left_gain;

  /// set left phase
  final bool left_phase;

  /// set level in
  final double level_in;

  /// set level out
  final double level_out;

  /// set middle phase
  final bool middle_phase;

  /// set middle source
  final HaasSource middle_source;

  /// set right balance
  final double right_balance;

  /// set right delay
  final double right_delay;

  /// set right gain
  final double right_gain;

  /// set right phase
  final bool right_phase;

  /// set side gain
  final double side_gain;

  /// Creates an [HaasSettings] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default; the effect stays
  /// inactive until [enabled] is set to `true`.
  const HaasSettings({
    this.enabled = false,
    this.left_balance = -1.0,
    this.left_delay = 2.05,
    this.left_gain = 1.0,
    this.left_phase = false,
    this.level_in = 1.0,
    this.level_out = 1.0,
    this.middle_phase = false,
    this.middle_source = HaasSource.mid,
    this.right_balance = 1.0,
    this.right_delay = 2.12,
    this.right_gain = 1.0,
    this.right_phase = true,
    this.side_gain = 1.0,
  });

  /// Returns a copy of this [HaasSettings] with the given fields replaced.
  HaasSettings copyWith({
    bool? enabled,
    double? left_balance,
    double? left_delay,
    double? left_gain,
    bool? left_phase,
    double? level_in,
    double? level_out,
    bool? middle_phase,
    HaasSource? middle_source,
    double? right_balance,
    double? right_delay,
    double? right_gain,
    bool? right_phase,
    double? side_gain,
  }) =>
      HaasSettings(
        enabled: enabled ?? this.enabled,
        left_balance: left_balance ?? this.left_balance,
        left_delay: left_delay ?? this.left_delay,
        left_gain: left_gain ?? this.left_gain,
        left_phase: left_phase ?? this.left_phase,
        level_in: level_in ?? this.level_in,
        level_out: level_out ?? this.level_out,
        middle_phase: middle_phase ?? this.middle_phase,
        middle_source: middle_source ?? this.middle_source,
        right_balance: right_balance ?? this.right_balance,
        right_delay: right_delay ?? this.right_delay,
        right_gain: right_gain ?? this.right_gain,
        right_phase: right_phase ?? this.right_phase,
        side_gain: side_gain ?? this.side_gain,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HaasSettings &&
          other.enabled == enabled &&
          other.left_balance == left_balance &&
          other.left_delay == left_delay &&
          other.left_gain == left_gain &&
          other.left_phase == left_phase &&
          other.level_in == level_in &&
          other.level_out == level_out &&
          other.middle_phase == middle_phase &&
          other.middle_source == middle_source &&
          other.right_balance == right_balance &&
          other.right_delay == right_delay &&
          other.right_gain == right_gain &&
          other.right_phase == right_phase &&
          other.side_gain == side_gain);

  @override
  int get hashCode => Object.hash(
      enabled,
      left_balance,
      left_delay,
      left_gain,
      left_phase,
      level_in,
      level_out,
      middle_phase,
      middle_source,
      right_balance,
      right_delay,
      right_gain,
      right_phase,
      side_gain,);

  @override
  String toString() =>
      'HaasSettings(enabled: $enabled, left_balance: $left_balance, left_delay: $left_delay, left_gain: $left_gain, left_phase: $left_phase, level_in: $level_in, level_out: $level_out, middle_phase: $middle_phase, middle_source: $middle_source, right_balance: $right_balance, right_delay: $right_delay, right_gain: $right_gain, right_phase: $right_phase, side_gain: $side_gain)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(left_balance >= left_balanceMin, 'haas.left_balance must be >= -1');
    assert(left_balance <= left_balanceMax, 'haas.left_balance must be <= 1');
    assert(left_delay >= left_delayMin, 'haas.left_delay must be >= 0');
    assert(left_delay <= left_delayMax, 'haas.left_delay must be <= 40');
    assert(left_gain >= left_gainMin, 'haas.left_gain must be >= 0.015625');
    assert(left_gain <= left_gainMax, 'haas.left_gain must be <= 64');
    assert(level_in >= level_inMin, 'haas.level_in must be >= 0.015625');
    assert(level_in <= level_inMax, 'haas.level_in must be <= 64');
    assert(level_out >= level_outMin, 'haas.level_out must be >= 0.015625');
    assert(level_out <= level_outMax, 'haas.level_out must be <= 64');
    assert(
        right_balance >= right_balanceMin, 'haas.right_balance must be >= -1',);
    assert(
        right_balance <= right_balanceMax, 'haas.right_balance must be <= 1',);
    assert(right_delay >= right_delayMin, 'haas.right_delay must be >= 0');
    assert(right_delay <= right_delayMax, 'haas.right_delay must be <= 40');
    assert(right_gain >= right_gainMin, 'haas.right_gain must be >= 0.015625');
    assert(right_gain <= right_gainMax, 'haas.right_gain must be <= 64');
    assert(side_gain >= side_gainMin, 'haas.side_gain must be >= 0.015625');
    assert(side_gain <= side_gainMax, 'haas.side_gain must be <= 64');
    final parts = <String>[];
    if (left_balance != -1.0)
      parts.add('left_balance=' + _wireDouble(left_balance));
    if (left_delay != 2.05) parts.add('left_delay=' + _wireDouble(left_delay));
    if (left_gain != 1.0) parts.add('left_gain=' + _wireDouble(left_gain));
    if (left_phase != false)
      parts.add('left_phase=' + (left_phase ? '1' : '0'));
    if (level_in != 1.0) parts.add('level_in=' + _wireDouble(level_in));
    if (level_out != 1.0) parts.add('level_out=' + _wireDouble(level_out));
    if (middle_phase != false)
      parts.add('middle_phase=' + (middle_phase ? '1' : '0'));
    if (middle_source != HaasSource.mid)
      parts.add('middle_source=' + middle_source.mpvValue);
    if (right_balance != 1.0)
      parts.add('right_balance=' + _wireDouble(right_balance));
    if (right_delay != 2.12)
      parts.add('right_delay=' + _wireDouble(right_delay));
    if (right_gain != 1.0) parts.add('right_gain=' + _wireDouble(right_gain));
    if (right_phase != true)
      parts.add('right_phase=' + (right_phase ? '1' : '0'));
    if (side_gain != 1.0) parts.add('side_gain=' + _wireDouble(side_gain));
    return parts.isEmpty ? 'lavfi-haas' : 'lavfi-haas=' + parts.join(':');
  }
}

/// Configuration for the `hdcd` audio effect.
///
/// Decodes High Definition Compatible Digital (HDCD) data. A 16-bit PCM stream with
/// embedded HDCD codes is expanded into a 20-bit PCM stream.
///
/// The filter supports the Peak Extend and Low-level Gain Adjustment features
/// of HDCD, and detects the Transient Filter flag.
///
/// When using the filter with wav, note the default encoding for wav is 16-bit,
/// so the resulting 20-bit stream will be truncated back to 16-bit. Use something
/// like @command{-acodec pcm_s24le} after the filter to get 24-bit PCM output.
///
/// ffmpeg -i HDCD16.wav -af hdcd -c:a pcm_s24le OUT24.wav
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [analyze_mode]: Replace audio with a solid tone and adjust the amplitude to signal some specific aspect of the decoding process. The output file can be loaded in an audio editor alongside the original to aid analysis.  `analyze_mode=pe:force_pe=true` can be used to see all samples above the PE level.  Modes are: (range 0..4, default HDCD_ANA_OFF)
/// - [bits_per_sample]: Valid bits per sample (location of the true LSB). (range 16..24, default 16)
/// - [cdt_ms]: Set the code detect timer period in ms. (range 100..60000, default 2000)
/// - [disable_autoconvert]: Disable any automatic format conversion or resampling in the filter graph. (range 0..1, default 1)
/// - [force_pe]: Always extend peaks above -3dBFS even if PE isn't signaled. (range 0..1, default 0)
/// - [process_stereo]: Process the stereo channels together. If target_gain does not match between channels, consider it invalid and use the last valid target_gain. (range 0..1, default HDCD_PROCESS_STEREO_DEFAULT)
final class HdcdSettings {
  /// Default value for [cdt_ms].
  static const int cdt_msDefault = 2000;

  /// Minimum value for [cdt_ms].
  static const int cdt_msMin = 100;

  /// Maximum value for [cdt_ms].
  static const int cdt_msMax = 60000;

  /// Whether this effect is inserted into the audio chain.
  final bool enabled;

  /// Replace audio with solid tone and signal some processing aspect in the amplitude.
  final HdcdAnalyzeMode analyze_mode;

  /// Valid bits per sample (location of the true LSB).
  final HdcdBitsPerSample bits_per_sample;

  /// Code detect timer period in ms.
  final int cdt_ms;

  /// Disable any format conversion or resampling in the filter graph.
  final bool disable_autoconvert;

  /// Always extend peaks above -3dBFS even when PE is not signaled.
  final bool force_pe;

  /// Process stereo channels together. Only apply target_gain when both channels match.
  final bool process_stereo;

  /// Creates an [HdcdSettings] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default; the effect stays
  /// inactive until [enabled] is set to `true`.
  const HdcdSettings({
    this.enabled = false,
    this.analyze_mode = HdcdAnalyzeMode.off,
    this.bits_per_sample = HdcdBitsPerSample.n16,
    this.cdt_ms = 2000,
    this.disable_autoconvert = true,
    this.force_pe = false,
    this.process_stereo = false,
  });

  /// Returns a copy of this [HdcdSettings] with the given fields replaced.
  HdcdSettings copyWith({
    bool? enabled,
    HdcdAnalyzeMode? analyze_mode,
    HdcdBitsPerSample? bits_per_sample,
    int? cdt_ms,
    bool? disable_autoconvert,
    bool? force_pe,
    bool? process_stereo,
  }) =>
      HdcdSettings(
        enabled: enabled ?? this.enabled,
        analyze_mode: analyze_mode ?? this.analyze_mode,
        bits_per_sample: bits_per_sample ?? this.bits_per_sample,
        cdt_ms: cdt_ms ?? this.cdt_ms,
        disable_autoconvert: disable_autoconvert ?? this.disable_autoconvert,
        force_pe: force_pe ?? this.force_pe,
        process_stereo: process_stereo ?? this.process_stereo,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HdcdSettings &&
          other.enabled == enabled &&
          other.analyze_mode == analyze_mode &&
          other.bits_per_sample == bits_per_sample &&
          other.cdt_ms == cdt_ms &&
          other.disable_autoconvert == disable_autoconvert &&
          other.force_pe == force_pe &&
          other.process_stereo == process_stereo);

  @override
  int get hashCode => Object.hash(enabled, analyze_mode, bits_per_sample,
      cdt_ms, disable_autoconvert, force_pe, process_stereo,);

  @override
  String toString() =>
      'HdcdSettings(enabled: $enabled, analyze_mode: $analyze_mode, bits_per_sample: $bits_per_sample, cdt_ms: $cdt_ms, disable_autoconvert: $disable_autoconvert, force_pe: $force_pe, process_stereo: $process_stereo)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(cdt_ms >= cdt_msMin, 'hdcd.cdt_ms must be >= 100');
    assert(cdt_ms <= cdt_msMax, 'hdcd.cdt_ms must be <= 60000');
    final parts = <String>[];
    if (analyze_mode != HdcdAnalyzeMode.off)
      parts.add('analyze_mode=' + analyze_mode.mpvValue);
    if (bits_per_sample != HdcdBitsPerSample.n16)
      parts.add('bits_per_sample=' + bits_per_sample.mpvValue);
    if (cdt_ms != 2000) parts.add('cdt_ms=' + cdt_ms.toString());
    if (disable_autoconvert != true)
      parts.add('disable_autoconvert=' + (disable_autoconvert ? '1' : '0'));
    if (force_pe != false) parts.add('force_pe=' + (force_pe ? '1' : '0'));
    if (process_stereo != false)
      parts.add('process_stereo=' + (process_stereo ? '1' : '0'));
    return parts.isEmpty ? 'lavfi-hdcd' : 'lavfi-hdcd=' + parts.join(':');
  }
}

/// Configuration for the `highpass` audio effect.
///
/// Apply a high-pass filter with 3dB point frequency.
/// The filter can be either single-pole, or double-pole (the default).
/// The filter roll off at 6dB per pole per octave (20dB per pole per decade).
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [a]: Set transform type of IIR filter. (range 0..6, default DI)
/// - [b]: Set block size used for reverse IIR processing. If this value is set to high enough value (higher than impulse response length truncated when reaches near zero values) filtering will become linear phase otherwise if not big enough it will just produce nasty artifacts.  Note that filter delay will be exactly this many samples when set to non-zero value. (range 0..32768, default 0)
/// - [blocksize]: set the block size (range 0..32768, default 0)
/// - [c]: Specify which channels to filter, by default all available are filtered. (range 0..0, default "all", runtime-tunable)
/// - [channels]: Specify which channels to filter, by default all available are filtered. (range 0..0, default "all", runtime-tunable)
/// - [f]: Set frequency in Hz. Default is 3000. (range 0..999999, default 3000, runtime-tunable)
/// - [frequency]: Set frequency in Hz. Default is 3000. (range 0..999999, default 3000, runtime-tunable)
/// - [m]: How much to use filtered signal in output. Default is 1. Range is between 0 and 1. (range 0..1, default 1, runtime-tunable)
/// - [mix]: How much to use filtered signal in output. Default is 1. Range is between 0 and 1. (range 0..1, default 1, runtime-tunable)
/// - [n]: Normalize biquad coefficients, by default is disabled. Enabling it will normalize magnitude response at DC to 0dB. (range 0..1, default 0, runtime-tunable)
/// - [normalize]: Normalize biquad coefficients, by default is disabled. Enabling it will normalize magnitude response at DC to 0dB. (range 0..1, default 0, runtime-tunable)
/// - [p]: Set number of poles. Default is 2. (range 1..2, default 2)
/// - [poles]: Set number of poles. Default is 2. (range 1..2, default 2)
/// - [precision]: Set precision of filtering. (range -1..3, default -1)
/// - [r]: Set precision of filtering. (range -1..3, default -1)
/// - [t]: Set method to specify band-width of filter. (range 1..5, default QFACTOR, runtime-tunable)
/// - [transform]: Set transform type of IIR filter. (range 0..6, default DI)
/// - [w]: Specify the band-width of a filter in width_type units. Applies only to double-pole filter. The default is 0.707q and gives a Butterworth response. (range 0..99999, default 0.707, runtime-tunable)
/// - [width]: Specify the band-width of a filter in width_type units. Applies only to double-pole filter. The default is 0.707q and gives a Butterworth response. (range 0..99999, default 0.707, runtime-tunable)
/// - [width_type]: Set method to specify band-width of filter. (range 1..5, default QFACTOR, runtime-tunable)
final class HighpassSettings {
  /// Default value for [b].
  static const int bDefault = 0;

  /// Minimum value for [b].
  static const int bMin = 0;

  /// Maximum value for [b].
  static const int bMax = 32768;

  /// Default value for [blocksize].
  static const int blocksizeDefault = 0;

  /// Minimum value for [blocksize].
  static const int blocksizeMin = 0;

  /// Maximum value for [blocksize].
  static const int blocksizeMax = 32768;

  /// Default value for [f].
  static const double fDefault = 3000.0;

  /// Minimum value for [f].
  static const double fMin = 0.0;

  /// Maximum value for [f].
  static const double fMax = 999999.0;

  /// Default value for [frequency].
  static const double frequencyDefault = 3000.0;

  /// Minimum value for [frequency].
  static const double frequencyMin = 0.0;

  /// Maximum value for [frequency].
  static const double frequencyMax = 999999.0;

  /// Default value for [m].
  static const double mDefault = 1.0;

  /// Minimum value for [m].
  static const double mMin = 0.0;

  /// Maximum value for [m].
  static const double mMax = 1.0;

  /// Default value for [mix].
  static const double mixDefault = 1.0;

  /// Minimum value for [mix].
  static const double mixMin = 0.0;

  /// Maximum value for [mix].
  static const double mixMax = 1.0;

  /// Default value for [p].
  static const int pDefault = 2;

  /// Minimum value for [p].
  static const int pMin = 1;

  /// Maximum value for [p].
  static const int pMax = 2;

  /// Default value for [poles].
  static const int polesDefault = 2;

  /// Minimum value for [poles].
  static const int polesMin = 1;

  /// Maximum value for [poles].
  static const int polesMax = 2;

  /// Default value for [w].
  static const double wDefault = 0.707;

  /// Minimum value for [w].
  static const double wMin = 0.0;

  /// Maximum value for [w].
  static const double wMax = 99999.0;

  /// Default value for [width].
  static const double widthDefault = 0.707;

  /// Minimum value for [width].
  static const double widthMin = 0.0;

  /// Maximum value for [width].
  static const double widthMax = 99999.0;

  /// Whether this effect is inserted into the audio chain.
  final bool enabled;

  /// set transform type
  final HighpassTransformType a;

  /// set the block size
  final int b;

  /// set the block size
  final int blocksize;

  /// set channels to filter
  final String c;

  /// set channels to filter
  final String channels;

  /// set frequency
  final double f;

  /// set frequency
  final double frequency;

  /// set mix
  final double m;

  /// set mix
  final double mix;

  /// normalize coefficients
  final bool n;

  /// normalize coefficients
  final bool normalize;

  /// set number of poles
  final int p;

  /// set number of poles
  final int poles;

  /// set filtering precision
  final HighpassPrecision precision;

  /// set filtering precision
  final HighpassPrecision r;

  /// set filter-width type
  final HighpassWidthType t;

  /// set transform type
  final HighpassTransformType transform;

  /// set width
  final double w;

  /// set width
  final double width;

  /// set filter-width type
  final HighpassWidthType width_type;

  /// Creates an [HighpassSettings] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default; the effect stays
  /// inactive until [enabled] is set to `true`.
  const HighpassSettings({
    this.enabled = false,
    this.a = HighpassTransformType.di,
    this.b = 0,
    this.blocksize = 0,
    this.c = 'all',
    this.channels = 'all',
    this.f = 3000.0,
    this.frequency = 3000.0,
    this.m = 1.0,
    this.mix = 1.0,
    this.n = false,
    this.normalize = false,
    this.p = 2,
    this.poles = 2,
    this.precision = HighpassPrecision.auto,
    this.r = HighpassPrecision.auto,
    this.t = HighpassWidthType.q,
    this.transform = HighpassTransformType.di,
    this.w = 0.707,
    this.width = 0.707,
    this.width_type = HighpassWidthType.q,
  });

  /// Returns a copy of this [HighpassSettings] with the given fields replaced.
  HighpassSettings copyWith({
    bool? enabled,
    HighpassTransformType? a,
    int? b,
    int? blocksize,
    String? c,
    String? channels,
    double? f,
    double? frequency,
    double? m,
    double? mix,
    bool? n,
    bool? normalize,
    int? p,
    int? poles,
    HighpassPrecision? precision,
    HighpassPrecision? r,
    HighpassWidthType? t,
    HighpassTransformType? transform,
    double? w,
    double? width,
    HighpassWidthType? width_type,
  }) =>
      HighpassSettings(
        enabled: enabled ?? this.enabled,
        a: a ?? this.a,
        b: b ?? this.b,
        blocksize: blocksize ?? this.blocksize,
        c: c ?? this.c,
        channels: channels ?? this.channels,
        f: f ?? this.f,
        frequency: frequency ?? this.frequency,
        m: m ?? this.m,
        mix: mix ?? this.mix,
        n: n ?? this.n,
        normalize: normalize ?? this.normalize,
        p: p ?? this.p,
        poles: poles ?? this.poles,
        precision: precision ?? this.precision,
        r: r ?? this.r,
        t: t ?? this.t,
        transform: transform ?? this.transform,
        w: w ?? this.w,
        width: width ?? this.width,
        width_type: width_type ?? this.width_type,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HighpassSettings &&
          other.enabled == enabled &&
          other.a == a &&
          other.b == b &&
          other.blocksize == blocksize &&
          other.c == c &&
          other.channels == channels &&
          other.f == f &&
          other.frequency == frequency &&
          other.m == m &&
          other.mix == mix &&
          other.n == n &&
          other.normalize == normalize &&
          other.p == p &&
          other.poles == poles &&
          other.precision == precision &&
          other.r == r &&
          other.t == t &&
          other.transform == transform &&
          other.w == w &&
          other.width == width &&
          other.width_type == width_type);

  @override
  int get hashCode => Object.hashAll([
        enabled,
        a,
        b,
        blocksize,
        c,
        channels,
        f,
        frequency,
        m,
        mix,
        n,
        normalize,
        p,
        poles,
        precision,
        r,
        t,
        transform,
        w,
        width,
        width_type,
      ]);

  @override
  String toString() =>
      'HighpassSettings(enabled: $enabled, a: $a, b: $b, blocksize: $blocksize, c: $c, channels: $channels, f: $f, frequency: $frequency, m: $m, mix: $mix, n: $n, normalize: $normalize, p: $p, poles: $poles, precision: $precision, r: $r, t: $t, transform: $transform, w: $w, width: $width, width_type: $width_type)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(b >= bMin, 'highpass.b must be >= 0');
    assert(b <= bMax, 'highpass.b must be <= 32768');
    assert(blocksize >= blocksizeMin, 'highpass.blocksize must be >= 0');
    assert(blocksize <= blocksizeMax, 'highpass.blocksize must be <= 32768');
    assert(f >= fMin, 'highpass.f must be >= 0');
    assert(f <= fMax, 'highpass.f must be <= 999999');
    assert(frequency >= frequencyMin, 'highpass.frequency must be >= 0');
    assert(frequency <= frequencyMax, 'highpass.frequency must be <= 999999');
    assert(m >= mMin, 'highpass.m must be >= 0');
    assert(m <= mMax, 'highpass.m must be <= 1');
    assert(mix >= mixMin, 'highpass.mix must be >= 0');
    assert(mix <= mixMax, 'highpass.mix must be <= 1');
    assert(p >= pMin, 'highpass.p must be >= 1');
    assert(p <= pMax, 'highpass.p must be <= 2');
    assert(poles >= polesMin, 'highpass.poles must be >= 1');
    assert(poles <= polesMax, 'highpass.poles must be <= 2');
    assert(w >= wMin, 'highpass.w must be >= 0');
    assert(w <= wMax, 'highpass.w must be <= 99999');
    assert(width >= widthMin, 'highpass.width must be >= 0');
    assert(width <= widthMax, 'highpass.width must be <= 99999');
    final parts = <String>[];
    if (a != HighpassTransformType.di) parts.add('a=' + a.mpvValue);
    if (b != 0) parts.add('b=' + b.toString());
    if (blocksize != 0) parts.add('blocksize=' + blocksize.toString());
    if (c != 'all') parts.add('c=' + '[' + c + ']');
    if (channels != 'all') parts.add('channels=' + '[' + channels + ']');
    if (f != 3000.0) parts.add('f=' + _wireDouble(f));
    if (frequency != 3000.0) parts.add('frequency=' + _wireDouble(frequency));
    if (m != 1.0) parts.add('m=' + _wireDouble(m));
    if (mix != 1.0) parts.add('mix=' + _wireDouble(mix));
    if (n != false) parts.add('n=' + (n ? '1' : '0'));
    if (normalize != false) parts.add('normalize=' + (normalize ? '1' : '0'));
    if (p != 2) parts.add('p=' + p.toString());
    if (poles != 2) parts.add('poles=' + poles.toString());
    if (precision != HighpassPrecision.auto)
      parts.add('precision=' + precision.mpvValue);
    if (r != HighpassPrecision.auto) parts.add('r=' + r.mpvValue);
    if (t != HighpassWidthType.q) parts.add('t=' + t.mpvValue);
    if (transform != HighpassTransformType.di)
      parts.add('transform=' + transform.mpvValue);
    if (w != 0.707) parts.add('w=' + _wireDouble(w));
    if (width != 0.707) parts.add('width=' + _wireDouble(width));
    if (width_type != HighpassWidthType.q)
      parts.add('width_type=' + width_type.mpvValue);
    return parts.isEmpty
        ? 'lavfi-highpass'
        : 'lavfi-highpass=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  List<(String, String)>? _runtimeDiff(HighpassSettings prev) {
    final out = <(String, String)>[];
    if (a != prev.a) return null;
    if (b != prev.b) return null;
    if (blocksize != prev.blocksize) return null;
    if (c != prev.c) {
      out.add(('c', c));
    }
    if (channels != prev.channels) {
      out.add(('channels', channels));
    }
    if (f != prev.f) {
      out.add(('f', _wireDouble(f)));
    }
    if (frequency != prev.frequency) {
      out.add(('frequency', _wireDouble(frequency)));
    }
    if (m != prev.m) {
      out.add(('m', _wireDouble(m)));
    }
    if (mix != prev.mix) {
      out.add(('mix', _wireDouble(mix)));
    }
    if (n != prev.n) {
      out.add(('n', (n ? '1' : '0')));
    }
    if (normalize != prev.normalize) {
      out.add(('normalize', (normalize ? '1' : '0')));
    }
    if (p != prev.p) return null;
    if (poles != prev.poles) return null;
    if (precision != prev.precision) return null;
    if (r != prev.r) return null;
    if (t != prev.t) {
      out.add(('t', t.mpvValue));
    }
    if (transform != prev.transform) return null;
    if (w != prev.w) {
      out.add(('w', _wireDouble(w)));
    }
    if (width != prev.width) {
      out.add(('width', _wireDouble(width)));
    }
    if (width_type != prev.width_type) {
      out.add(('width_type', width_type.mpvValue));
    }
    return out;
  }
}

/// Configuration for the `highshelf` audio effect.
///
/// Boost or cut treble (upper) frequencies of the audio using a two-pole
/// shelving filter with a response similar to that of a standard
/// hi-fi's tone-controls. This is also known as shelving equalisation (EQ).
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [a]: Set transform type of IIR filter. (range 0..6, default DI)
/// - [b]: Set block size used for reverse IIR processing. If this value is set to high enough value (higher than impulse response length truncated when reaches near zero values) filtering will become linear phase otherwise if not big enough it will just produce nasty artifacts.  Note that filter delay will be exactly this many samples when set to non-zero value. (range 0..32768, default 0)
/// - [blocksize]: set the block size (range 0..32768, default 0)
/// - [c]: Specify which channels to filter, by default all available are filtered. (range 0..0, default "all", runtime-tunable)
/// - [channels]: Specify which channels to filter, by default all available are filtered. (range 0..0, default "all", runtime-tunable)
/// - [f]: Set the filter's central frequency and so can be used to extend or reduce the frequency range to be boosted or cut. The default value is `3000` Hz. (range 0..999999, default 3000, runtime-tunable)
/// - [frequency]: Set the filter's central frequency and so can be used to extend or reduce the frequency range to be boosted or cut. The default value is `3000` Hz. (range 0..999999, default 3000, runtime-tunable)
/// - [g]: Give the gain at whichever is the lower of ~22 kHz and the Nyquist frequency. Its useful range is about -20 (for a large cut) to +20 (for a large boost). Beware of clipping when using a positive gain. (range -900..900, default 0, runtime-tunable)
/// - [gain]: Give the gain at whichever is the lower of ~22 kHz and the Nyquist frequency. Its useful range is about -20 (for a large cut) to +20 (for a large boost). Beware of clipping when using a positive gain. (range -900..900, default 0, runtime-tunable)
/// - [m]: How much to use filtered signal in output. Default is 1. Range is between 0 and 1. (range 0..1, default 1, runtime-tunable)
/// - [mix]: How much to use filtered signal in output. Default is 1. Range is between 0 and 1. (range 0..1, default 1, runtime-tunable)
/// - [n]: Normalize biquad coefficients, by default is disabled. Enabling it will normalize magnitude response at DC to 0dB. (range 0..1, default 0, runtime-tunable)
/// - [normalize]: Normalize biquad coefficients, by default is disabled. Enabling it will normalize magnitude response at DC to 0dB. (range 0..1, default 0, runtime-tunable)
/// - [p]: Set number of poles. Default is 2. (range 1..2, default 2)
/// - [poles]: Set number of poles. Default is 2. (range 1..2, default 2)
/// - [precision]: Set precision of filtering. (range -1..3, default -1)
/// - [r]: Set precision of filtering. (range -1..3, default -1)
/// - [t]: Set method to specify band-width of filter. (range 1..5, default QFACTOR, runtime-tunable)
/// - [transform]: Set transform type of IIR filter. (range 0..6, default DI)
/// - [w]: Determine how steep is the filter's shelf transition. (range 0..99999, default 0.5, runtime-tunable)
/// - [width]: Determine how steep is the filter's shelf transition. (range 0..99999, default 0.5, runtime-tunable)
/// - [width_type]: Set method to specify band-width of filter. (range 1..5, default QFACTOR, runtime-tunable)
final class HighshelfSettings {
  /// Default value for [b].
  static const int bDefault = 0;

  /// Minimum value for [b].
  static const int bMin = 0;

  /// Maximum value for [b].
  static const int bMax = 32768;

  /// Default value for [blocksize].
  static const int blocksizeDefault = 0;

  /// Minimum value for [blocksize].
  static const int blocksizeMin = 0;

  /// Maximum value for [blocksize].
  static const int blocksizeMax = 32768;

  /// Default value for [f].
  static const double fDefault = 3000.0;

  /// Minimum value for [f].
  static const double fMin = 0.0;

  /// Maximum value for [f].
  static const double fMax = 999999.0;

  /// Default value for [frequency].
  static const double frequencyDefault = 3000.0;

  /// Minimum value for [frequency].
  static const double frequencyMin = 0.0;

  /// Maximum value for [frequency].
  static const double frequencyMax = 999999.0;

  /// Default value for [g].
  static const double gDefault = 0.0;

  /// Minimum value for [g].
  static const double gMin = -900.0;

  /// Maximum value for [g].
  static const double gMax = 900.0;

  /// Default value for [gain].
  static const double gainDefault = 0.0;

  /// Minimum value for [gain].
  static const double gainMin = -900.0;

  /// Maximum value for [gain].
  static const double gainMax = 900.0;

  /// Default value for [m].
  static const double mDefault = 1.0;

  /// Minimum value for [m].
  static const double mMin = 0.0;

  /// Maximum value for [m].
  static const double mMax = 1.0;

  /// Default value for [mix].
  static const double mixDefault = 1.0;

  /// Minimum value for [mix].
  static const double mixMin = 0.0;

  /// Maximum value for [mix].
  static const double mixMax = 1.0;

  /// Default value for [p].
  static const int pDefault = 2;

  /// Minimum value for [p].
  static const int pMin = 1;

  /// Maximum value for [p].
  static const int pMax = 2;

  /// Default value for [poles].
  static const int polesDefault = 2;

  /// Minimum value for [poles].
  static const int polesMin = 1;

  /// Maximum value for [poles].
  static const int polesMax = 2;

  /// Default value for [w].
  static const double wDefault = 0.5;

  /// Minimum value for [w].
  static const double wMin = 0.0;

  /// Maximum value for [w].
  static const double wMax = 99999.0;

  /// Default value for [width].
  static const double widthDefault = 0.5;

  /// Minimum value for [width].
  static const double widthMin = 0.0;

  /// Maximum value for [width].
  static const double widthMax = 99999.0;

  /// Whether this effect is inserted into the audio chain.
  final bool enabled;

  /// set transform type
  final HighshelfTransformType a;

  /// set the block size
  final int b;

  /// set the block size
  final int blocksize;

  /// set channels to filter
  final String c;

  /// set channels to filter
  final String channels;

  /// set central frequency
  final double f;

  /// set central frequency
  final double frequency;

  /// set gain
  final double g;

  /// set gain
  final double gain;

  /// set mix
  final double m;

  /// set mix
  final double mix;

  /// normalize coefficients
  final bool n;

  /// normalize coefficients
  final bool normalize;

  /// set number of poles
  final int p;

  /// set number of poles
  final int poles;

  /// set filtering precision
  final HighshelfPrecision precision;

  /// set filtering precision
  final HighshelfPrecision r;

  /// set filter-width type
  final HighshelfWidthType t;

  /// set transform type
  final HighshelfTransformType transform;

  /// set width
  final double w;

  /// set width
  final double width;

  /// set filter-width type
  final HighshelfWidthType width_type;

  /// Creates an [HighshelfSettings] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default; the effect stays
  /// inactive until [enabled] is set to `true`.
  const HighshelfSettings({
    this.enabled = false,
    this.a = HighshelfTransformType.di,
    this.b = 0,
    this.blocksize = 0,
    this.c = 'all',
    this.channels = 'all',
    this.f = 3000.0,
    this.frequency = 3000.0,
    this.g = 0.0,
    this.gain = 0.0,
    this.m = 1.0,
    this.mix = 1.0,
    this.n = false,
    this.normalize = false,
    this.p = 2,
    this.poles = 2,
    this.precision = HighshelfPrecision.auto,
    this.r = HighshelfPrecision.auto,
    this.t = HighshelfWidthType.q,
    this.transform = HighshelfTransformType.di,
    this.w = 0.5,
    this.width = 0.5,
    this.width_type = HighshelfWidthType.q,
  });

  /// Returns a copy of this [HighshelfSettings] with the given fields replaced.
  HighshelfSettings copyWith({
    bool? enabled,
    HighshelfTransformType? a,
    int? b,
    int? blocksize,
    String? c,
    String? channels,
    double? f,
    double? frequency,
    double? g,
    double? gain,
    double? m,
    double? mix,
    bool? n,
    bool? normalize,
    int? p,
    int? poles,
    HighshelfPrecision? precision,
    HighshelfPrecision? r,
    HighshelfWidthType? t,
    HighshelfTransformType? transform,
    double? w,
    double? width,
    HighshelfWidthType? width_type,
  }) =>
      HighshelfSettings(
        enabled: enabled ?? this.enabled,
        a: a ?? this.a,
        b: b ?? this.b,
        blocksize: blocksize ?? this.blocksize,
        c: c ?? this.c,
        channels: channels ?? this.channels,
        f: f ?? this.f,
        frequency: frequency ?? this.frequency,
        g: g ?? this.g,
        gain: gain ?? this.gain,
        m: m ?? this.m,
        mix: mix ?? this.mix,
        n: n ?? this.n,
        normalize: normalize ?? this.normalize,
        p: p ?? this.p,
        poles: poles ?? this.poles,
        precision: precision ?? this.precision,
        r: r ?? this.r,
        t: t ?? this.t,
        transform: transform ?? this.transform,
        w: w ?? this.w,
        width: width ?? this.width,
        width_type: width_type ?? this.width_type,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HighshelfSettings &&
          other.enabled == enabled &&
          other.a == a &&
          other.b == b &&
          other.blocksize == blocksize &&
          other.c == c &&
          other.channels == channels &&
          other.f == f &&
          other.frequency == frequency &&
          other.g == g &&
          other.gain == gain &&
          other.m == m &&
          other.mix == mix &&
          other.n == n &&
          other.normalize == normalize &&
          other.p == p &&
          other.poles == poles &&
          other.precision == precision &&
          other.r == r &&
          other.t == t &&
          other.transform == transform &&
          other.w == w &&
          other.width == width &&
          other.width_type == width_type);

  @override
  int get hashCode => Object.hashAll([
        enabled,
        a,
        b,
        blocksize,
        c,
        channels,
        f,
        frequency,
        g,
        gain,
        m,
        mix,
        n,
        normalize,
        p,
        poles,
        precision,
        r,
        t,
        transform,
        w,
        width,
        width_type,
      ]);

  @override
  String toString() =>
      'HighshelfSettings(enabled: $enabled, a: $a, b: $b, blocksize: $blocksize, c: $c, channels: $channels, f: $f, frequency: $frequency, g: $g, gain: $gain, m: $m, mix: $mix, n: $n, normalize: $normalize, p: $p, poles: $poles, precision: $precision, r: $r, t: $t, transform: $transform, w: $w, width: $width, width_type: $width_type)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(b >= bMin, 'highshelf.b must be >= 0');
    assert(b <= bMax, 'highshelf.b must be <= 32768');
    assert(blocksize >= blocksizeMin, 'highshelf.blocksize must be >= 0');
    assert(blocksize <= blocksizeMax, 'highshelf.blocksize must be <= 32768');
    assert(f >= fMin, 'highshelf.f must be >= 0');
    assert(f <= fMax, 'highshelf.f must be <= 999999');
    assert(frequency >= frequencyMin, 'highshelf.frequency must be >= 0');
    assert(frequency <= frequencyMax, 'highshelf.frequency must be <= 999999');
    assert(g >= gMin, 'highshelf.g must be >= -900');
    assert(g <= gMax, 'highshelf.g must be <= 900');
    assert(gain >= gainMin, 'highshelf.gain must be >= -900');
    assert(gain <= gainMax, 'highshelf.gain must be <= 900');
    assert(m >= mMin, 'highshelf.m must be >= 0');
    assert(m <= mMax, 'highshelf.m must be <= 1');
    assert(mix >= mixMin, 'highshelf.mix must be >= 0');
    assert(mix <= mixMax, 'highshelf.mix must be <= 1');
    assert(p >= pMin, 'highshelf.p must be >= 1');
    assert(p <= pMax, 'highshelf.p must be <= 2');
    assert(poles >= polesMin, 'highshelf.poles must be >= 1');
    assert(poles <= polesMax, 'highshelf.poles must be <= 2');
    assert(w >= wMin, 'highshelf.w must be >= 0');
    assert(w <= wMax, 'highshelf.w must be <= 99999');
    assert(width >= widthMin, 'highshelf.width must be >= 0');
    assert(width <= widthMax, 'highshelf.width must be <= 99999');
    final parts = <String>[];
    if (a != HighshelfTransformType.di) parts.add('a=' + a.mpvValue);
    if (b != 0) parts.add('b=' + b.toString());
    if (blocksize != 0) parts.add('blocksize=' + blocksize.toString());
    if (c != 'all') parts.add('c=' + '[' + c + ']');
    if (channels != 'all') parts.add('channels=' + '[' + channels + ']');
    if (f != 3000.0) parts.add('f=' + _wireDouble(f));
    if (frequency != 3000.0) parts.add('frequency=' + _wireDouble(frequency));
    if (g != 0.0) parts.add('g=' + _wireDouble(g));
    if (gain != 0.0) parts.add('gain=' + _wireDouble(gain));
    if (m != 1.0) parts.add('m=' + _wireDouble(m));
    if (mix != 1.0) parts.add('mix=' + _wireDouble(mix));
    if (n != false) parts.add('n=' + (n ? '1' : '0'));
    if (normalize != false) parts.add('normalize=' + (normalize ? '1' : '0'));
    if (p != 2) parts.add('p=' + p.toString());
    if (poles != 2) parts.add('poles=' + poles.toString());
    if (precision != HighshelfPrecision.auto)
      parts.add('precision=' + precision.mpvValue);
    if (r != HighshelfPrecision.auto) parts.add('r=' + r.mpvValue);
    if (t != HighshelfWidthType.q) parts.add('t=' + t.mpvValue);
    if (transform != HighshelfTransformType.di)
      parts.add('transform=' + transform.mpvValue);
    if (w != 0.5) parts.add('w=' + _wireDouble(w));
    if (width != 0.5) parts.add('width=' + _wireDouble(width));
    if (width_type != HighshelfWidthType.q)
      parts.add('width_type=' + width_type.mpvValue);
    return parts.isEmpty
        ? 'lavfi-highshelf'
        : 'lavfi-highshelf=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  List<(String, String)>? _runtimeDiff(HighshelfSettings prev) {
    final out = <(String, String)>[];
    if (a != prev.a) return null;
    if (b != prev.b) return null;
    if (blocksize != prev.blocksize) return null;
    if (c != prev.c) {
      out.add(('c', c));
    }
    if (channels != prev.channels) {
      out.add(('channels', channels));
    }
    if (f != prev.f) {
      out.add(('f', _wireDouble(f)));
    }
    if (frequency != prev.frequency) {
      out.add(('frequency', _wireDouble(frequency)));
    }
    if (g != prev.g) {
      out.add(('g', _wireDouble(g)));
    }
    if (gain != prev.gain) {
      out.add(('gain', _wireDouble(gain)));
    }
    if (m != prev.m) {
      out.add(('m', _wireDouble(m)));
    }
    if (mix != prev.mix) {
      out.add(('mix', _wireDouble(mix)));
    }
    if (n != prev.n) {
      out.add(('n', (n ? '1' : '0')));
    }
    if (normalize != prev.normalize) {
      out.add(('normalize', (normalize ? '1' : '0')));
    }
    if (p != prev.p) return null;
    if (poles != prev.poles) return null;
    if (precision != prev.precision) return null;
    if (r != prev.r) return null;
    if (t != prev.t) {
      out.add(('t', t.mpvValue));
    }
    if (transform != prev.transform) return null;
    if (w != prev.w) {
      out.add(('w', _wireDouble(w)));
    }
    if (width != prev.width) {
      out.add(('width', _wireDouble(width)));
    }
    if (width_type != prev.width_type) {
      out.add(('width_type', width_type.mpvValue));
    }
    return out;
  }
}

/// Configuration for the `loudnorm` audio effect.
///
/// EBU R128 loudness normalization. Includes both dynamic and linear normalization modes.
/// Support for both single pass (livestreams, files) and double pass (files) modes.
/// This algorithm can target IL, LRA, and maximum true peak. In dynamic mode, to accurately
/// detect true peaks, the audio stream will be upsampled to 192 kHz.
/// Use the `-ar` option or `aresample` filter to explicitly set an output sample rate.
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [I]: Set integrated loudness target. Range is -70.0 - -5.0. Default value is -24.0. (range -70.0..-5.0, default -24.)
/// - [LRA]: Set loudness range target. Range is 1.0 - 50.0. Default value is 7.0. (range 1.0..50.0, default 7.)
/// - [TP]: Set maximum true peak. Range is -9.0 - +0.0. Default value is -2.0. (range -9.0..0.0, default -2.)
/// - [dual_mono]: Treat mono input files as "dual-mono". If a mono file is intended for playback on a stereo system, its EBU R128 measurement will be perceptually incorrect. If set to `true`, this option will compensate for this effect. Multi-channel input files are not affected by this option. Options are true or false. Default is false. (range 0..1, default 0)
/// - [i]: Set integrated loudness target. Range is -70.0 - -5.0. Default value is -24.0. (range -70.0..-5.0, default -24.)
/// - [linear]: Normalize by linearly scaling the source audio. `measured_I`, `measured_LRA`, `measured_TP`, and `measured_thresh` must all be specified. Target LRA shouldn't be lower than source LRA and the change in integrated loudness shouldn't result in a true peak which exceeds the target TP. If any of these conditions aren't met, normalization mode will revert to `dynamic`. Options are `true` or `false`. Default is `true`. (range 0..1, default 1)
/// - [lra]: Set loudness range target. Range is 1.0 - 50.0. Default value is 7.0. (range 1.0..50.0, default 7.)
/// - [measured_I]: Measured IL of input file. Range is -99.0 - +0.0. (range -99.0..0.0, default 0.)
/// - [measured_LRA]: Measured LRA of input file. Range is  0.0 - 99.0. (range 0.0..99.0, default 0.)
/// - [measured_TP]: Measured true peak of input file. Range is  -99.0 - +99.0. (range -99.0..99.0, default 99.)
/// - [measured_i]: Measured IL of input file. Range is -99.0 - +0.0. (range -99.0..0.0, default 0.)
/// - [measured_lra]: Measured LRA of input file. Range is  0.0 - 99.0. (range 0.0..99.0, default 0.)
/// - [measured_thresh]: Measured threshold of input file. Range is -99.0 - +0.0. (range -99.0..0.0, default -70.)
/// - [measured_tp]: Measured true peak of input file. Range is  -99.0 - +99.0. (range -99.0..99.0, default 99.)
/// - [offset]: Set offset gain. Gain is applied before the true-peak limiter. Range is  -99.0 - +99.0. Default is +0.0. (range -99.0..99.0, default 0.)
/// - [print_format]: Set print format for stats. Options are summary, json, or none. Default value is none. (range 0..2, default NONE)
/// - [stats_file]: Write stats to specified file. Format is controlled by @option{print_format}, which must be set. Specify `-` to write to standard output. Default is unset. (range 0..0, default "")
/// - [tp]: Set maximum true peak. Range is -9.0 - +0.0. Default value is -2.0. (range -9.0..0.0, default -2.)
final class LoudnormSettings {
  /// Default value for [I].
  static const double IDefault = -24.0;

  /// Minimum value for [I].
  static const double IMin = -70.0;

  /// Maximum value for [I].
  static const double IMax = -5.0;

  /// Default value for [LRA].
  static const double LRADefault = 7.0;

  /// Minimum value for [LRA].
  static const double LRAMin = 1.0;

  /// Maximum value for [LRA].
  static const double LRAMax = 50.0;

  /// Default value for [TP].
  static const double TPDefault = -2.0;

  /// Minimum value for [TP].
  static const double TPMin = -9.0;

  /// Maximum value for [TP].
  static const double TPMax = 0.0;

  /// Default value for [i].
  static const double iDefault = -24.0;

  /// Minimum value for [i].
  static const double iMin = -70.0;

  /// Maximum value for [i].
  static const double iMax = -5.0;

  /// Default value for [lra].
  static const double lraDefault = 7.0;

  /// Minimum value for [lra].
  static const double lraMin = 1.0;

  /// Maximum value for [lra].
  static const double lraMax = 50.0;

  /// Default value for [measured_I].
  static const double measured_IDefault = 0.0;

  /// Minimum value for [measured_I].
  static const double measured_IMin = -99.0;

  /// Maximum value for [measured_I].
  static const double measured_IMax = 0.0;

  /// Default value for [measured_LRA].
  static const double measured_LRADefault = 0.0;

  /// Minimum value for [measured_LRA].
  static const double measured_LRAMin = 0.0;

  /// Maximum value for [measured_LRA].
  static const double measured_LRAMax = 99.0;

  /// Default value for [measured_TP].
  static const double measured_TPDefault = 99.0;

  /// Minimum value for [measured_TP].
  static const double measured_TPMin = -99.0;

  /// Maximum value for [measured_TP].
  static const double measured_TPMax = 99.0;

  /// Default value for [measured_i].
  static const double measured_iDefault = 0.0;

  /// Minimum value for [measured_i].
  static const double measured_iMin = -99.0;

  /// Maximum value for [measured_i].
  static const double measured_iMax = 0.0;

  /// Default value for [measured_lra].
  static const double measured_lraDefault = 0.0;

  /// Minimum value for [measured_lra].
  static const double measured_lraMin = 0.0;

  /// Maximum value for [measured_lra].
  static const double measured_lraMax = 99.0;

  /// Default value for [measured_thresh].
  static const double measured_threshDefault = -70.0;

  /// Minimum value for [measured_thresh].
  static const double measured_threshMin = -99.0;

  /// Maximum value for [measured_thresh].
  static const double measured_threshMax = 0.0;

  /// Default value for [measured_tp].
  static const double measured_tpDefault = 99.0;

  /// Minimum value for [measured_tp].
  static const double measured_tpMin = -99.0;

  /// Maximum value for [measured_tp].
  static const double measured_tpMax = 99.0;

  /// Default value for [offset].
  static const double offsetDefault = 0.0;

  /// Minimum value for [offset].
  static const double offsetMin = -99.0;

  /// Maximum value for [offset].
  static const double offsetMax = 99.0;

  /// Default value for [tp].
  static const double tpDefault = -2.0;

  /// Minimum value for [tp].
  static const double tpMin = -9.0;

  /// Maximum value for [tp].
  static const double tpMax = 0.0;

  /// Whether this effect is inserted into the audio chain.
  final bool enabled;

  /// set integrated loudness target
  final double I;

  /// set loudness range target
  final double LRA;

  /// set maximum true peak
  final double TP;

  /// treat mono input as dual-mono
  final bool dual_mono;

  /// set integrated loudness target
  final double i;

  /// normalize linearly if possible
  final bool linear;

  /// set loudness range target
  final double lra;

  /// measured IL of input file
  final double measured_I;

  /// measured LRA of input file
  final double measured_LRA;

  /// measured true peak of input file
  final double measured_TP;

  /// measured IL of input file
  final double measured_i;

  /// measured LRA of input file
  final double measured_lra;

  /// measured threshold of input file
  final double measured_thresh;

  /// measured true peak of input file
  final double measured_tp;

  /// set offset gain
  final double offset;

  /// set print format for stats
  final LoudnormPrintFormat print_format;

  /// set stats output file
  final String stats_file;

  /// set maximum true peak
  final double tp;

  /// Creates an [LoudnormSettings] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default; the effect stays
  /// inactive until [enabled] is set to `true`.
  const LoudnormSettings({
    this.enabled = false,
    this.I = -24.0,
    this.LRA = 7.0,
    this.TP = -2.0,
    this.dual_mono = false,
    this.i = -24.0,
    this.linear = true,
    this.lra = 7.0,
    this.measured_I = 0.0,
    this.measured_LRA = 0.0,
    this.measured_TP = 99.0,
    this.measured_i = 0.0,
    this.measured_lra = 0.0,
    this.measured_thresh = -70.0,
    this.measured_tp = 99.0,
    this.offset = 0.0,
    this.print_format = LoudnormPrintFormat.none,
    this.stats_file = '',
    this.tp = -2.0,
  });

  /// Returns a copy of this [LoudnormSettings] with the given fields replaced.
  LoudnormSettings copyWith({
    bool? enabled,
    double? I,
    double? LRA,
    double? TP,
    bool? dual_mono,
    double? i,
    bool? linear,
    double? lra,
    double? measured_I,
    double? measured_LRA,
    double? measured_TP,
    double? measured_i,
    double? measured_lra,
    double? measured_thresh,
    double? measured_tp,
    double? offset,
    LoudnormPrintFormat? print_format,
    String? stats_file,
    double? tp,
  }) =>
      LoudnormSettings(
        enabled: enabled ?? this.enabled,
        I: I ?? this.I,
        LRA: LRA ?? this.LRA,
        TP: TP ?? this.TP,
        dual_mono: dual_mono ?? this.dual_mono,
        i: i ?? this.i,
        linear: linear ?? this.linear,
        lra: lra ?? this.lra,
        measured_I: measured_I ?? this.measured_I,
        measured_LRA: measured_LRA ?? this.measured_LRA,
        measured_TP: measured_TP ?? this.measured_TP,
        measured_i: measured_i ?? this.measured_i,
        measured_lra: measured_lra ?? this.measured_lra,
        measured_thresh: measured_thresh ?? this.measured_thresh,
        measured_tp: measured_tp ?? this.measured_tp,
        offset: offset ?? this.offset,
        print_format: print_format ?? this.print_format,
        stats_file: stats_file ?? this.stats_file,
        tp: tp ?? this.tp,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LoudnormSettings &&
          other.enabled == enabled &&
          other.I == I &&
          other.LRA == LRA &&
          other.TP == TP &&
          other.dual_mono == dual_mono &&
          other.i == i &&
          other.linear == linear &&
          other.lra == lra &&
          other.measured_I == measured_I &&
          other.measured_LRA == measured_LRA &&
          other.measured_TP == measured_TP &&
          other.measured_i == measured_i &&
          other.measured_lra == measured_lra &&
          other.measured_thresh == measured_thresh &&
          other.measured_tp == measured_tp &&
          other.offset == offset &&
          other.print_format == print_format &&
          other.stats_file == stats_file &&
          other.tp == tp);

  @override
  int get hashCode => Object.hash(
      enabled,
      I,
      LRA,
      TP,
      dual_mono,
      i,
      linear,
      lra,
      measured_I,
      measured_LRA,
      measured_TP,
      measured_i,
      measured_lra,
      measured_thresh,
      measured_tp,
      offset,
      print_format,
      stats_file,
      tp,);

  @override
  String toString() =>
      'LoudnormSettings(enabled: $enabled, I: $I, LRA: $LRA, TP: $TP, dual_mono: $dual_mono, i: $i, linear: $linear, lra: $lra, measured_I: $measured_I, measured_LRA: $measured_LRA, measured_TP: $measured_TP, measured_i: $measured_i, measured_lra: $measured_lra, measured_thresh: $measured_thresh, measured_tp: $measured_tp, offset: $offset, print_format: $print_format, stats_file: $stats_file, tp: $tp)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(I >= IMin, 'loudnorm.I must be >= -70.0');
    assert(I <= IMax, 'loudnorm.I must be <= -5.0');
    assert(LRA >= LRAMin, 'loudnorm.LRA must be >= 1.0');
    assert(LRA <= LRAMax, 'loudnorm.LRA must be <= 50.0');
    assert(TP >= TPMin, 'loudnorm.TP must be >= -9.0');
    assert(TP <= TPMax, 'loudnorm.TP must be <= 0.0');
    assert(i >= iMin, 'loudnorm.i must be >= -70.0');
    assert(i <= iMax, 'loudnorm.i must be <= -5.0');
    assert(lra >= lraMin, 'loudnorm.lra must be >= 1.0');
    assert(lra <= lraMax, 'loudnorm.lra must be <= 50.0');
    assert(measured_I >= measured_IMin, 'loudnorm.measured_I must be >= -99.0');
    assert(measured_I <= measured_IMax, 'loudnorm.measured_I must be <= 0.0');
    assert(measured_LRA >= measured_LRAMin,
        'loudnorm.measured_LRA must be >= 0.0',);
    assert(measured_LRA <= measured_LRAMax,
        'loudnorm.measured_LRA must be <= 99.0',);
    assert(
        measured_TP >= measured_TPMin, 'loudnorm.measured_TP must be >= -99.0',);
    assert(
        measured_TP <= measured_TPMax, 'loudnorm.measured_TP must be <= 99.0',);
    assert(measured_i >= measured_iMin, 'loudnorm.measured_i must be >= -99.0');
    assert(measured_i <= measured_iMax, 'loudnorm.measured_i must be <= 0.0');
    assert(measured_lra >= measured_lraMin,
        'loudnorm.measured_lra must be >= 0.0',);
    assert(measured_lra <= measured_lraMax,
        'loudnorm.measured_lra must be <= 99.0',);
    assert(measured_thresh >= measured_threshMin,
        'loudnorm.measured_thresh must be >= -99.0',);
    assert(measured_thresh <= measured_threshMax,
        'loudnorm.measured_thresh must be <= 0.0',);
    assert(
        measured_tp >= measured_tpMin, 'loudnorm.measured_tp must be >= -99.0',);
    assert(
        measured_tp <= measured_tpMax, 'loudnorm.measured_tp must be <= 99.0',);
    assert(offset >= offsetMin, 'loudnorm.offset must be >= -99.0');
    assert(offset <= offsetMax, 'loudnorm.offset must be <= 99.0');
    assert(tp >= tpMin, 'loudnorm.tp must be >= -9.0');
    assert(tp <= tpMax, 'loudnorm.tp must be <= 0.0');
    final parts = <String>[];
    if (I != -24.0) parts.add('I=' + _wireDouble(I));
    if (LRA != 7.0) parts.add('LRA=' + _wireDouble(LRA));
    if (TP != -2.0) parts.add('TP=' + _wireDouble(TP));
    if (dual_mono != false) parts.add('dual_mono=' + (dual_mono ? '1' : '0'));
    if (i != -24.0) parts.add('i=' + _wireDouble(i));
    if (linear != true) parts.add('linear=' + (linear ? '1' : '0'));
    if (lra != 7.0) parts.add('lra=' + _wireDouble(lra));
    if (measured_I != 0.0) parts.add('measured_I=' + _wireDouble(measured_I));
    if (measured_LRA != 0.0)
      parts.add('measured_LRA=' + _wireDouble(measured_LRA));
    if (measured_TP != 99.0)
      parts.add('measured_TP=' + _wireDouble(measured_TP));
    if (measured_i != 0.0) parts.add('measured_i=' + _wireDouble(measured_i));
    if (measured_lra != 0.0)
      parts.add('measured_lra=' + _wireDouble(measured_lra));
    if (measured_thresh != -70.0)
      parts.add('measured_thresh=' + _wireDouble(measured_thresh));
    if (measured_tp != 99.0)
      parts.add('measured_tp=' + _wireDouble(measured_tp));
    if (offset != 0.0) parts.add('offset=' + _wireDouble(offset));
    if (print_format != LoudnormPrintFormat.none)
      parts.add('print_format=' + print_format.mpvValue);
    if (stats_file != '') parts.add('stats_file=' + '[' + stats_file + ']');
    if (tp != -2.0) parts.add('tp=' + _wireDouble(tp));
    return parts.isEmpty
        ? 'lavfi-loudnorm'
        : 'lavfi-loudnorm=' + parts.join(':');
  }
}

/// Configuration for the `lowpass` audio effect.
///
/// Apply a low-pass filter with 3dB point frequency.
/// The filter can be either single-pole or double-pole (the default).
/// The filter roll off at 6dB per pole per octave (20dB per pole per decade).
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [a]: Set transform type of IIR filter. (range 0..6, default DI)
/// - [b]: Set block size used for reverse IIR processing. If this value is set to high enough value (higher than impulse response length truncated when reaches near zero values) filtering will become linear phase otherwise if not big enough it will just produce nasty artifacts.  Note that filter delay will be exactly this many samples when set to non-zero value. (range 0..32768, default 0)
/// - [blocksize]: set the block size (range 0..32768, default 0)
/// - [c]: Specify which channels to filter, by default all available are filtered. (range 0..0, default "all", runtime-tunable)
/// - [channels]: Specify which channels to filter, by default all available are filtered. (range 0..0, default "all", runtime-tunable)
/// - [f]: Set frequency in Hz. Default is 500. (range 0..999999, default 500, runtime-tunable)
/// - [frequency]: Set frequency in Hz. Default is 500. (range 0..999999, default 500, runtime-tunable)
/// - [m]: How much to use filtered signal in output. Default is 1. Range is between 0 and 1. (range 0..1, default 1, runtime-tunable)
/// - [mix]: How much to use filtered signal in output. Default is 1. Range is between 0 and 1. (range 0..1, default 1, runtime-tunable)
/// - [n]: Normalize biquad coefficients, by default is disabled. Enabling it will normalize magnitude response at DC to 0dB. (range 0..1, default 0, runtime-tunable)
/// - [normalize]: Normalize biquad coefficients, by default is disabled. Enabling it will normalize magnitude response at DC to 0dB. (range 0..1, default 0, runtime-tunable)
/// - [p]: Set number of poles. Default is 2. (range 1..2, default 2)
/// - [poles]: Set number of poles. Default is 2. (range 1..2, default 2)
/// - [precision]: Set precision of filtering. (range -1..3, default -1)
/// - [r]: Set precision of filtering. (range -1..3, default -1)
/// - [t]: Set method to specify band-width of filter. (range 1..5, default QFACTOR, runtime-tunable)
/// - [transform]: Set transform type of IIR filter. (range 0..6, default DI)
/// - [w]: Specify the band-width of a filter in width_type units. Applies only to double-pole filter. The default is 0.707q and gives a Butterworth response. (range 0..99999, default 0.707, runtime-tunable)
/// - [width]: Specify the band-width of a filter in width_type units. Applies only to double-pole filter. The default is 0.707q and gives a Butterworth response. (range 0..99999, default 0.707, runtime-tunable)
/// - [width_type]: Set method to specify band-width of filter. (range 1..5, default QFACTOR, runtime-tunable)
final class LowpassSettings {
  /// Default value for [b].
  static const int bDefault = 0;

  /// Minimum value for [b].
  static const int bMin = 0;

  /// Maximum value for [b].
  static const int bMax = 32768;

  /// Default value for [blocksize].
  static const int blocksizeDefault = 0;

  /// Minimum value for [blocksize].
  static const int blocksizeMin = 0;

  /// Maximum value for [blocksize].
  static const int blocksizeMax = 32768;

  /// Default value for [f].
  static const double fDefault = 500.0;

  /// Minimum value for [f].
  static const double fMin = 0.0;

  /// Maximum value for [f].
  static const double fMax = 999999.0;

  /// Default value for [frequency].
  static const double frequencyDefault = 500.0;

  /// Minimum value for [frequency].
  static const double frequencyMin = 0.0;

  /// Maximum value for [frequency].
  static const double frequencyMax = 999999.0;

  /// Default value for [m].
  static const double mDefault = 1.0;

  /// Minimum value for [m].
  static const double mMin = 0.0;

  /// Maximum value for [m].
  static const double mMax = 1.0;

  /// Default value for [mix].
  static const double mixDefault = 1.0;

  /// Minimum value for [mix].
  static const double mixMin = 0.0;

  /// Maximum value for [mix].
  static const double mixMax = 1.0;

  /// Default value for [p].
  static const int pDefault = 2;

  /// Minimum value for [p].
  static const int pMin = 1;

  /// Maximum value for [p].
  static const int pMax = 2;

  /// Default value for [poles].
  static const int polesDefault = 2;

  /// Minimum value for [poles].
  static const int polesMin = 1;

  /// Maximum value for [poles].
  static const int polesMax = 2;

  /// Default value for [w].
  static const double wDefault = 0.707;

  /// Minimum value for [w].
  static const double wMin = 0.0;

  /// Maximum value for [w].
  static const double wMax = 99999.0;

  /// Default value for [width].
  static const double widthDefault = 0.707;

  /// Minimum value for [width].
  static const double widthMin = 0.0;

  /// Maximum value for [width].
  static const double widthMax = 99999.0;

  /// Whether this effect is inserted into the audio chain.
  final bool enabled;

  /// set transform type
  final LowpassTransformType a;

  /// set the block size
  final int b;

  /// set the block size
  final int blocksize;

  /// set channels to filter
  final String c;

  /// set channels to filter
  final String channels;

  /// set frequency
  final double f;

  /// set frequency
  final double frequency;

  /// set mix
  final double m;

  /// set mix
  final double mix;

  /// normalize coefficients
  final bool n;

  /// normalize coefficients
  final bool normalize;

  /// set number of poles
  final int p;

  /// set number of poles
  final int poles;

  /// set filtering precision
  final LowpassPrecision precision;

  /// set filtering precision
  final LowpassPrecision r;

  /// set filter-width type
  final LowpassWidthType t;

  /// set transform type
  final LowpassTransformType transform;

  /// set width
  final double w;

  /// set width
  final double width;

  /// set filter-width type
  final LowpassWidthType width_type;

  /// Creates an [LowpassSettings] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default; the effect stays
  /// inactive until [enabled] is set to `true`.
  const LowpassSettings({
    this.enabled = false,
    this.a = LowpassTransformType.di,
    this.b = 0,
    this.blocksize = 0,
    this.c = 'all',
    this.channels = 'all',
    this.f = 500.0,
    this.frequency = 500.0,
    this.m = 1.0,
    this.mix = 1.0,
    this.n = false,
    this.normalize = false,
    this.p = 2,
    this.poles = 2,
    this.precision = LowpassPrecision.auto,
    this.r = LowpassPrecision.auto,
    this.t = LowpassWidthType.q,
    this.transform = LowpassTransformType.di,
    this.w = 0.707,
    this.width = 0.707,
    this.width_type = LowpassWidthType.q,
  });

  /// Returns a copy of this [LowpassSettings] with the given fields replaced.
  LowpassSettings copyWith({
    bool? enabled,
    LowpassTransformType? a,
    int? b,
    int? blocksize,
    String? c,
    String? channels,
    double? f,
    double? frequency,
    double? m,
    double? mix,
    bool? n,
    bool? normalize,
    int? p,
    int? poles,
    LowpassPrecision? precision,
    LowpassPrecision? r,
    LowpassWidthType? t,
    LowpassTransformType? transform,
    double? w,
    double? width,
    LowpassWidthType? width_type,
  }) =>
      LowpassSettings(
        enabled: enabled ?? this.enabled,
        a: a ?? this.a,
        b: b ?? this.b,
        blocksize: blocksize ?? this.blocksize,
        c: c ?? this.c,
        channels: channels ?? this.channels,
        f: f ?? this.f,
        frequency: frequency ?? this.frequency,
        m: m ?? this.m,
        mix: mix ?? this.mix,
        n: n ?? this.n,
        normalize: normalize ?? this.normalize,
        p: p ?? this.p,
        poles: poles ?? this.poles,
        precision: precision ?? this.precision,
        r: r ?? this.r,
        t: t ?? this.t,
        transform: transform ?? this.transform,
        w: w ?? this.w,
        width: width ?? this.width,
        width_type: width_type ?? this.width_type,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LowpassSettings &&
          other.enabled == enabled &&
          other.a == a &&
          other.b == b &&
          other.blocksize == blocksize &&
          other.c == c &&
          other.channels == channels &&
          other.f == f &&
          other.frequency == frequency &&
          other.m == m &&
          other.mix == mix &&
          other.n == n &&
          other.normalize == normalize &&
          other.p == p &&
          other.poles == poles &&
          other.precision == precision &&
          other.r == r &&
          other.t == t &&
          other.transform == transform &&
          other.w == w &&
          other.width == width &&
          other.width_type == width_type);

  @override
  int get hashCode => Object.hashAll([
        enabled,
        a,
        b,
        blocksize,
        c,
        channels,
        f,
        frequency,
        m,
        mix,
        n,
        normalize,
        p,
        poles,
        precision,
        r,
        t,
        transform,
        w,
        width,
        width_type,
      ]);

  @override
  String toString() =>
      'LowpassSettings(enabled: $enabled, a: $a, b: $b, blocksize: $blocksize, c: $c, channels: $channels, f: $f, frequency: $frequency, m: $m, mix: $mix, n: $n, normalize: $normalize, p: $p, poles: $poles, precision: $precision, r: $r, t: $t, transform: $transform, w: $w, width: $width, width_type: $width_type)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(b >= bMin, 'lowpass.b must be >= 0');
    assert(b <= bMax, 'lowpass.b must be <= 32768');
    assert(blocksize >= blocksizeMin, 'lowpass.blocksize must be >= 0');
    assert(blocksize <= blocksizeMax, 'lowpass.blocksize must be <= 32768');
    assert(f >= fMin, 'lowpass.f must be >= 0');
    assert(f <= fMax, 'lowpass.f must be <= 999999');
    assert(frequency >= frequencyMin, 'lowpass.frequency must be >= 0');
    assert(frequency <= frequencyMax, 'lowpass.frequency must be <= 999999');
    assert(m >= mMin, 'lowpass.m must be >= 0');
    assert(m <= mMax, 'lowpass.m must be <= 1');
    assert(mix >= mixMin, 'lowpass.mix must be >= 0');
    assert(mix <= mixMax, 'lowpass.mix must be <= 1');
    assert(p >= pMin, 'lowpass.p must be >= 1');
    assert(p <= pMax, 'lowpass.p must be <= 2');
    assert(poles >= polesMin, 'lowpass.poles must be >= 1');
    assert(poles <= polesMax, 'lowpass.poles must be <= 2');
    assert(w >= wMin, 'lowpass.w must be >= 0');
    assert(w <= wMax, 'lowpass.w must be <= 99999');
    assert(width >= widthMin, 'lowpass.width must be >= 0');
    assert(width <= widthMax, 'lowpass.width must be <= 99999');
    final parts = <String>[];
    if (a != LowpassTransformType.di) parts.add('a=' + a.mpvValue);
    if (b != 0) parts.add('b=' + b.toString());
    if (blocksize != 0) parts.add('blocksize=' + blocksize.toString());
    if (c != 'all') parts.add('c=' + '[' + c + ']');
    if (channels != 'all') parts.add('channels=' + '[' + channels + ']');
    if (f != 500.0) parts.add('f=' + _wireDouble(f));
    if (frequency != 500.0) parts.add('frequency=' + _wireDouble(frequency));
    if (m != 1.0) parts.add('m=' + _wireDouble(m));
    if (mix != 1.0) parts.add('mix=' + _wireDouble(mix));
    if (n != false) parts.add('n=' + (n ? '1' : '0'));
    if (normalize != false) parts.add('normalize=' + (normalize ? '1' : '0'));
    if (p != 2) parts.add('p=' + p.toString());
    if (poles != 2) parts.add('poles=' + poles.toString());
    if (precision != LowpassPrecision.auto)
      parts.add('precision=' + precision.mpvValue);
    if (r != LowpassPrecision.auto) parts.add('r=' + r.mpvValue);
    if (t != LowpassWidthType.q) parts.add('t=' + t.mpvValue);
    if (transform != LowpassTransformType.di)
      parts.add('transform=' + transform.mpvValue);
    if (w != 0.707) parts.add('w=' + _wireDouble(w));
    if (width != 0.707) parts.add('width=' + _wireDouble(width));
    if (width_type != LowpassWidthType.q)
      parts.add('width_type=' + width_type.mpvValue);
    return parts.isEmpty ? 'lavfi-lowpass' : 'lavfi-lowpass=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  List<(String, String)>? _runtimeDiff(LowpassSettings prev) {
    final out = <(String, String)>[];
    if (a != prev.a) return null;
    if (b != prev.b) return null;
    if (blocksize != prev.blocksize) return null;
    if (c != prev.c) {
      out.add(('c', c));
    }
    if (channels != prev.channels) {
      out.add(('channels', channels));
    }
    if (f != prev.f) {
      out.add(('f', _wireDouble(f)));
    }
    if (frequency != prev.frequency) {
      out.add(('frequency', _wireDouble(frequency)));
    }
    if (m != prev.m) {
      out.add(('m', _wireDouble(m)));
    }
    if (mix != prev.mix) {
      out.add(('mix', _wireDouble(mix)));
    }
    if (n != prev.n) {
      out.add(('n', (n ? '1' : '0')));
    }
    if (normalize != prev.normalize) {
      out.add(('normalize', (normalize ? '1' : '0')));
    }
    if (p != prev.p) return null;
    if (poles != prev.poles) return null;
    if (precision != prev.precision) return null;
    if (r != prev.r) return null;
    if (t != prev.t) {
      out.add(('t', t.mpvValue));
    }
    if (transform != prev.transform) return null;
    if (w != prev.w) {
      out.add(('w', _wireDouble(w)));
    }
    if (width != prev.width) {
      out.add(('width', _wireDouble(width)));
    }
    if (width_type != prev.width_type) {
      out.add(('width_type', width_type.mpvValue));
    }
    return out;
  }
}

/// Configuration for the `lowshelf` audio effect.
///
/// Boost or cut the bass (lower) frequencies of the audio using a two-pole
/// shelving filter with a response similar to that of a standard
/// hi-fi's tone-controls. This is also known as shelving equalisation (EQ).
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [a]: Set transform type of IIR filter. (range 0..6, default DI)
/// - [b]: Set block size used for reverse IIR processing. If this value is set to high enough value (higher than impulse response length truncated when reaches near zero values) filtering will become linear phase otherwise if not big enough it will just produce nasty artifacts.  Note that filter delay will be exactly this many samples when set to non-zero value. (range 0..32768, default 0)
/// - [blocksize]: set the block size (range 0..32768, default 0)
/// - [c]: Specify which channels to filter, by default all available are filtered. (range 0..0, default "all", runtime-tunable)
/// - [channels]: Specify which channels to filter, by default all available are filtered. (range 0..0, default "all", runtime-tunable)
/// - [f]: Set the filter's central frequency and so can be used to extend or reduce the frequency range to be boosted or cut. The default value is `100` Hz. (range 0..999999, default 100, runtime-tunable)
/// - [frequency]: Set the filter's central frequency and so can be used to extend or reduce the frequency range to be boosted or cut. The default value is `100` Hz. (range 0..999999, default 100, runtime-tunable)
/// - [g]: Give the gain at 0 Hz. Its useful range is about -20 (for a large cut) to +20 (for a large boost). Beware of clipping when using a positive gain. (range -900..900, default 0, runtime-tunable)
/// - [gain]: Give the gain at 0 Hz. Its useful range is about -20 (for a large cut) to +20 (for a large boost). Beware of clipping when using a positive gain. (range -900..900, default 0, runtime-tunable)
/// - [m]: How much to use filtered signal in output. Default is 1. Range is between 0 and 1. (range 0..1, default 1, runtime-tunable)
/// - [mix]: How much to use filtered signal in output. Default is 1. Range is between 0 and 1. (range 0..1, default 1, runtime-tunable)
/// - [n]: Normalize biquad coefficients, by default is disabled. Enabling it will normalize magnitude response at DC to 0dB. (range 0..1, default 0, runtime-tunable)
/// - [normalize]: Normalize biquad coefficients, by default is disabled. Enabling it will normalize magnitude response at DC to 0dB. (range 0..1, default 0, runtime-tunable)
/// - [p]: Set number of poles. Default is 2. (range 1..2, default 2)
/// - [poles]: Set number of poles. Default is 2. (range 1..2, default 2)
/// - [precision]: Set precision of filtering. (range -1..3, default -1)
/// - [r]: Set precision of filtering. (range -1..3, default -1)
/// - [t]: Set method to specify band-width of filter. (range 1..5, default QFACTOR, runtime-tunable)
/// - [transform]: Set transform type of IIR filter. (range 0..6, default DI)
/// - [w]: Determine how steep is the filter's shelf transition. (range 0..99999, default 0.5, runtime-tunable)
/// - [width]: Determine how steep is the filter's shelf transition. (range 0..99999, default 0.5, runtime-tunable)
/// - [width_type]: Set method to specify band-width of filter. (range 1..5, default QFACTOR, runtime-tunable)
final class LowshelfSettings {
  /// Default value for [b].
  static const int bDefault = 0;

  /// Minimum value for [b].
  static const int bMin = 0;

  /// Maximum value for [b].
  static const int bMax = 32768;

  /// Default value for [blocksize].
  static const int blocksizeDefault = 0;

  /// Minimum value for [blocksize].
  static const int blocksizeMin = 0;

  /// Maximum value for [blocksize].
  static const int blocksizeMax = 32768;

  /// Default value for [f].
  static const double fDefault = 100.0;

  /// Minimum value for [f].
  static const double fMin = 0.0;

  /// Maximum value for [f].
  static const double fMax = 999999.0;

  /// Default value for [frequency].
  static const double frequencyDefault = 100.0;

  /// Minimum value for [frequency].
  static const double frequencyMin = 0.0;

  /// Maximum value for [frequency].
  static const double frequencyMax = 999999.0;

  /// Default value for [g].
  static const double gDefault = 0.0;

  /// Minimum value for [g].
  static const double gMin = -900.0;

  /// Maximum value for [g].
  static const double gMax = 900.0;

  /// Default value for [gain].
  static const double gainDefault = 0.0;

  /// Minimum value for [gain].
  static const double gainMin = -900.0;

  /// Maximum value for [gain].
  static const double gainMax = 900.0;

  /// Default value for [m].
  static const double mDefault = 1.0;

  /// Minimum value for [m].
  static const double mMin = 0.0;

  /// Maximum value for [m].
  static const double mMax = 1.0;

  /// Default value for [mix].
  static const double mixDefault = 1.0;

  /// Minimum value for [mix].
  static const double mixMin = 0.0;

  /// Maximum value for [mix].
  static const double mixMax = 1.0;

  /// Default value for [p].
  static const int pDefault = 2;

  /// Minimum value for [p].
  static const int pMin = 1;

  /// Maximum value for [p].
  static const int pMax = 2;

  /// Default value for [poles].
  static const int polesDefault = 2;

  /// Minimum value for [poles].
  static const int polesMin = 1;

  /// Maximum value for [poles].
  static const int polesMax = 2;

  /// Default value for [w].
  static const double wDefault = 0.5;

  /// Minimum value for [w].
  static const double wMin = 0.0;

  /// Maximum value for [w].
  static const double wMax = 99999.0;

  /// Default value for [width].
  static const double widthDefault = 0.5;

  /// Minimum value for [width].
  static const double widthMin = 0.0;

  /// Maximum value for [width].
  static const double widthMax = 99999.0;

  /// Whether this effect is inserted into the audio chain.
  final bool enabled;

  /// set transform type
  final LowshelfTransformType a;

  /// set the block size
  final int b;

  /// set the block size
  final int blocksize;

  /// set channels to filter
  final String c;

  /// set channels to filter
  final String channels;

  /// set central frequency
  final double f;

  /// set central frequency
  final double frequency;

  /// set gain
  final double g;

  /// set gain
  final double gain;

  /// set mix
  final double m;

  /// set mix
  final double mix;

  /// normalize coefficients
  final bool n;

  /// normalize coefficients
  final bool normalize;

  /// set number of poles
  final int p;

  /// set number of poles
  final int poles;

  /// set filtering precision
  final LowshelfPrecision precision;

  /// set filtering precision
  final LowshelfPrecision r;

  /// set filter-width type
  final LowshelfWidthType t;

  /// set transform type
  final LowshelfTransformType transform;

  /// set width
  final double w;

  /// set width
  final double width;

  /// set filter-width type
  final LowshelfWidthType width_type;

  /// Creates an [LowshelfSettings] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default; the effect stays
  /// inactive until [enabled] is set to `true`.
  const LowshelfSettings({
    this.enabled = false,
    this.a = LowshelfTransformType.di,
    this.b = 0,
    this.blocksize = 0,
    this.c = 'all',
    this.channels = 'all',
    this.f = 100.0,
    this.frequency = 100.0,
    this.g = 0.0,
    this.gain = 0.0,
    this.m = 1.0,
    this.mix = 1.0,
    this.n = false,
    this.normalize = false,
    this.p = 2,
    this.poles = 2,
    this.precision = LowshelfPrecision.auto,
    this.r = LowshelfPrecision.auto,
    this.t = LowshelfWidthType.q,
    this.transform = LowshelfTransformType.di,
    this.w = 0.5,
    this.width = 0.5,
    this.width_type = LowshelfWidthType.q,
  });

  /// Returns a copy of this [LowshelfSettings] with the given fields replaced.
  LowshelfSettings copyWith({
    bool? enabled,
    LowshelfTransformType? a,
    int? b,
    int? blocksize,
    String? c,
    String? channels,
    double? f,
    double? frequency,
    double? g,
    double? gain,
    double? m,
    double? mix,
    bool? n,
    bool? normalize,
    int? p,
    int? poles,
    LowshelfPrecision? precision,
    LowshelfPrecision? r,
    LowshelfWidthType? t,
    LowshelfTransformType? transform,
    double? w,
    double? width,
    LowshelfWidthType? width_type,
  }) =>
      LowshelfSettings(
        enabled: enabled ?? this.enabled,
        a: a ?? this.a,
        b: b ?? this.b,
        blocksize: blocksize ?? this.blocksize,
        c: c ?? this.c,
        channels: channels ?? this.channels,
        f: f ?? this.f,
        frequency: frequency ?? this.frequency,
        g: g ?? this.g,
        gain: gain ?? this.gain,
        m: m ?? this.m,
        mix: mix ?? this.mix,
        n: n ?? this.n,
        normalize: normalize ?? this.normalize,
        p: p ?? this.p,
        poles: poles ?? this.poles,
        precision: precision ?? this.precision,
        r: r ?? this.r,
        t: t ?? this.t,
        transform: transform ?? this.transform,
        w: w ?? this.w,
        width: width ?? this.width,
        width_type: width_type ?? this.width_type,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LowshelfSettings &&
          other.enabled == enabled &&
          other.a == a &&
          other.b == b &&
          other.blocksize == blocksize &&
          other.c == c &&
          other.channels == channels &&
          other.f == f &&
          other.frequency == frequency &&
          other.g == g &&
          other.gain == gain &&
          other.m == m &&
          other.mix == mix &&
          other.n == n &&
          other.normalize == normalize &&
          other.p == p &&
          other.poles == poles &&
          other.precision == precision &&
          other.r == r &&
          other.t == t &&
          other.transform == transform &&
          other.w == w &&
          other.width == width &&
          other.width_type == width_type);

  @override
  int get hashCode => Object.hashAll([
        enabled,
        a,
        b,
        blocksize,
        c,
        channels,
        f,
        frequency,
        g,
        gain,
        m,
        mix,
        n,
        normalize,
        p,
        poles,
        precision,
        r,
        t,
        transform,
        w,
        width,
        width_type,
      ]);

  @override
  String toString() =>
      'LowshelfSettings(enabled: $enabled, a: $a, b: $b, blocksize: $blocksize, c: $c, channels: $channels, f: $f, frequency: $frequency, g: $g, gain: $gain, m: $m, mix: $mix, n: $n, normalize: $normalize, p: $p, poles: $poles, precision: $precision, r: $r, t: $t, transform: $transform, w: $w, width: $width, width_type: $width_type)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(b >= bMin, 'lowshelf.b must be >= 0');
    assert(b <= bMax, 'lowshelf.b must be <= 32768');
    assert(blocksize >= blocksizeMin, 'lowshelf.blocksize must be >= 0');
    assert(blocksize <= blocksizeMax, 'lowshelf.blocksize must be <= 32768');
    assert(f >= fMin, 'lowshelf.f must be >= 0');
    assert(f <= fMax, 'lowshelf.f must be <= 999999');
    assert(frequency >= frequencyMin, 'lowshelf.frequency must be >= 0');
    assert(frequency <= frequencyMax, 'lowshelf.frequency must be <= 999999');
    assert(g >= gMin, 'lowshelf.g must be >= -900');
    assert(g <= gMax, 'lowshelf.g must be <= 900');
    assert(gain >= gainMin, 'lowshelf.gain must be >= -900');
    assert(gain <= gainMax, 'lowshelf.gain must be <= 900');
    assert(m >= mMin, 'lowshelf.m must be >= 0');
    assert(m <= mMax, 'lowshelf.m must be <= 1');
    assert(mix >= mixMin, 'lowshelf.mix must be >= 0');
    assert(mix <= mixMax, 'lowshelf.mix must be <= 1');
    assert(p >= pMin, 'lowshelf.p must be >= 1');
    assert(p <= pMax, 'lowshelf.p must be <= 2');
    assert(poles >= polesMin, 'lowshelf.poles must be >= 1');
    assert(poles <= polesMax, 'lowshelf.poles must be <= 2');
    assert(w >= wMin, 'lowshelf.w must be >= 0');
    assert(w <= wMax, 'lowshelf.w must be <= 99999');
    assert(width >= widthMin, 'lowshelf.width must be >= 0');
    assert(width <= widthMax, 'lowshelf.width must be <= 99999');
    final parts = <String>[];
    if (a != LowshelfTransformType.di) parts.add('a=' + a.mpvValue);
    if (b != 0) parts.add('b=' + b.toString());
    if (blocksize != 0) parts.add('blocksize=' + blocksize.toString());
    if (c != 'all') parts.add('c=' + '[' + c + ']');
    if (channels != 'all') parts.add('channels=' + '[' + channels + ']');
    if (f != 100.0) parts.add('f=' + _wireDouble(f));
    if (frequency != 100.0) parts.add('frequency=' + _wireDouble(frequency));
    if (g != 0.0) parts.add('g=' + _wireDouble(g));
    if (gain != 0.0) parts.add('gain=' + _wireDouble(gain));
    if (m != 1.0) parts.add('m=' + _wireDouble(m));
    if (mix != 1.0) parts.add('mix=' + _wireDouble(mix));
    if (n != false) parts.add('n=' + (n ? '1' : '0'));
    if (normalize != false) parts.add('normalize=' + (normalize ? '1' : '0'));
    if (p != 2) parts.add('p=' + p.toString());
    if (poles != 2) parts.add('poles=' + poles.toString());
    if (precision != LowshelfPrecision.auto)
      parts.add('precision=' + precision.mpvValue);
    if (r != LowshelfPrecision.auto) parts.add('r=' + r.mpvValue);
    if (t != LowshelfWidthType.q) parts.add('t=' + t.mpvValue);
    if (transform != LowshelfTransformType.di)
      parts.add('transform=' + transform.mpvValue);
    if (w != 0.5) parts.add('w=' + _wireDouble(w));
    if (width != 0.5) parts.add('width=' + _wireDouble(width));
    if (width_type != LowshelfWidthType.q)
      parts.add('width_type=' + width_type.mpvValue);
    return parts.isEmpty
        ? 'lavfi-lowshelf'
        : 'lavfi-lowshelf=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  List<(String, String)>? _runtimeDiff(LowshelfSettings prev) {
    final out = <(String, String)>[];
    if (a != prev.a) return null;
    if (b != prev.b) return null;
    if (blocksize != prev.blocksize) return null;
    if (c != prev.c) {
      out.add(('c', c));
    }
    if (channels != prev.channels) {
      out.add(('channels', channels));
    }
    if (f != prev.f) {
      out.add(('f', _wireDouble(f)));
    }
    if (frequency != prev.frequency) {
      out.add(('frequency', _wireDouble(frequency)));
    }
    if (g != prev.g) {
      out.add(('g', _wireDouble(g)));
    }
    if (gain != prev.gain) {
      out.add(('gain', _wireDouble(gain)));
    }
    if (m != prev.m) {
      out.add(('m', _wireDouble(m)));
    }
    if (mix != prev.mix) {
      out.add(('mix', _wireDouble(mix)));
    }
    if (n != prev.n) {
      out.add(('n', (n ? '1' : '0')));
    }
    if (normalize != prev.normalize) {
      out.add(('normalize', (normalize ? '1' : '0')));
    }
    if (p != prev.p) return null;
    if (poles != prev.poles) return null;
    if (precision != prev.precision) return null;
    if (r != prev.r) return null;
    if (t != prev.t) {
      out.add(('t', t.mpvValue));
    }
    if (transform != prev.transform) return null;
    if (w != prev.w) {
      out.add(('w', _wireDouble(w)));
    }
    if (width != prev.width) {
      out.add(('width', _wireDouble(width)));
    }
    if (width_type != prev.width_type) {
      out.add(('width_type', width_type.mpvValue));
    }
    return out;
  }
}

/// Configuration for the `mcompand` audio effect.
///
/// Multiband Compress or expand the audio's dynamic range.
///
/// The input audio is divided into bands using 4th order Linkwitz-Riley IIRs.
/// This is akin to the crossover of a loudspeaker, and results in flat frequency
/// response when absent compander action.
///
/// It accepts the following parameters:
///
/// Parameters:
/// - [args]: This option syntax is: attack,decay,[attack,decay..] soft-knee points crossover_frequency [delay [initial_volume [gain]]] | attack,decay ... For explanation of each item refer to compand filter documentation. (range 0..0, default "0.005,0.1 6 -47/-40,-34/-34,-17/-33 100 | 0.003,0.05 6 -47/-40,-34/-34,-17/-33 400 | 0.000625,0.0125 6 -47/-40,-34/-34,-15/-33 1600 | 0.0001,0.025 6 -47/-40,-34/-34,-31/-31,-0/-30 6400 | 0,0.025 6 -38/-31,-28/-28,-0/-25 22000")
final class McompandSettings {
  /// Whether this effect is inserted into the audio chain.
  final bool enabled;

  /// set parameters for each band
  final String args;

  /// Creates an [McompandSettings] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default; the effect stays
  /// inactive until [enabled] is set to `true`.
  const McompandSettings({
    this.enabled = false,
    this.args =
        '0.005,0.1 6 -47/-40,-34/-34,-17/-33 100 | 0.003,0.05 6 -47/-40,-34/-34,-17/-33 400 | 0.000625,0.0125 6 -47/-40,-34/-34,-15/-33 1600 | 0.0001,0.025 6 -47/-40,-34/-34,-31/-31,-0/-30 6400 | 0,0.025 6 -38/-31,-28/-28,-0/-25 22000',
  });

  /// Returns a copy of this [McompandSettings] with the given fields replaced.
  McompandSettings copyWith({
    bool? enabled,
    String? args,
  }) =>
      McompandSettings(
        enabled: enabled ?? this.enabled,
        args: args ?? this.args,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is McompandSettings &&
          other.enabled == enabled &&
          other.args == args);

  @override
  int get hashCode => Object.hash(enabled, args);

  @override
  String toString() => 'McompandSettings(enabled: $enabled, args: $args)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    final parts = <String>[];
    if (args !=
        '0.005,0.1 6 -47/-40,-34/-34,-17/-33 100 | 0.003,0.05 6 -47/-40,-34/-34,-17/-33 400 | 0.000625,0.0125 6 -47/-40,-34/-34,-15/-33 1600 | 0.0001,0.025 6 -47/-40,-34/-34,-31/-31,-0/-30 6400 | 0,0.025 6 -38/-31,-28/-28,-0/-25 22000')
      parts.add('args=' + '[' + args + ']');
    return parts.isEmpty
        ? 'lavfi-mcompand'
        : 'lavfi-mcompand=' + parts.join(':');
  }
}

/// Configuration for the `pan` audio effect.
///
/// Mix channels with specific gain levels. The filter accepts the output
/// channel layout followed by a set of channels definitions.
///
/// This filter is also designed to efficiently remap the channels of an audio
/// stream.
///
/// The filter accepts parameters of the form:
/// "`l`|`outdef`|`outdef`|..."
///
/// Parameters:
/// - [args]:  (range 0..0, default "")
final class PanSettings {
  /// Whether this effect is inserted into the audio chain.
  final bool enabled;

  /// The `args` parameter.
  final String args;

  /// Creates an [PanSettings] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default; the effect stays
  /// inactive until [enabled] is set to `true`.
  const PanSettings({
    this.enabled = false,
    required this.args,
  });

  /// Returns a copy of this [PanSettings] with the given fields replaced.
  PanSettings copyWith({
    bool? enabled,
    String? args,
  }) =>
      PanSettings(
        enabled: enabled ?? this.enabled,
        args: args ?? this.args,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PanSettings && other.enabled == enabled && other.args == args);

  @override
  int get hashCode => Object.hash(enabled, args);

  @override
  String toString() => 'PanSettings(enabled: $enabled, args: $args)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    final parts = <String>[];
    parts.add('args=' + '[' + args + ']');
    return parts.isEmpty ? 'lavfi-pan' : 'lavfi-pan=' + parts.join(':');
  }
}

/// Configuration for the `rubberband` audio effect.
///
/// Apply time-stretching and pitch-shifting with librubberband.
///
/// To enable compilation of this filter, you need to configure FFmpeg with
/// `--enable-librubberband`.
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [channels]: set channels (range 0..2147483647, default 0)
/// - [detector]: set detector (range 0..2147483647, default 0)
/// - [formant]: set formant (range 0..2147483647, default 0)
/// - [phase]: set phase (range 0..2147483647, default 0)
/// - [pitch]: Set pitch scale factor. (range 0.01..100, default 1, runtime-tunable)
/// - [pitchq]: set pitch quality (range 0..2147483647, default 0)
/// - [smoothing]: set smoothing (range 0..2147483647, default 0)
/// - [tempo]: Set tempo scale factor. (range 0.01..100, default 1, runtime-tunable)
/// - [transients]: Set transients detector. Possible values are: (range 0..2147483647, default 0)
/// - [window]: set window (range 0..2147483647, default 0)
final class RubberbandSettings {
  /// Default value for [pitch].
  static const double pitchDefault = 1.0;

  /// Minimum value for [pitch].
  static const double pitchMin = 0.01;

  /// Maximum value for [pitch].
  static const double pitchMax = 100.0;

  /// Default value for [tempo].
  static const double tempoDefault = 1.0;

  /// Minimum value for [tempo].
  static const double tempoMin = 0.01;

  /// Maximum value for [tempo].
  static const double tempoMax = 100.0;

  /// Whether this effect is inserted into the audio chain.
  final bool enabled;

  /// set channels
  final RubberbandChannels channels;

  /// set detector
  final RubberbandDetector detector;

  /// set formant
  final RubberbandFormant formant;

  /// set phase
  final RubberbandPhase phase;

  /// set pitch scale factor
  final double pitch;

  /// set pitch quality
  final RubberbandPitch pitchq;

  /// set smoothing
  final RubberbandSmoothing smoothing;

  /// set tempo scale factor
  final double tempo;

  /// set transients
  final RubberbandTransients transients;

  /// set window
  final RubberbandWindow window;

  /// Creates an [RubberbandSettings] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default; the effect stays
  /// inactive until [enabled] is set to `true`.
  const RubberbandSettings({
    this.enabled = false,
    this.channels = RubberbandChannels.apart,
    this.detector = RubberbandDetector.compound,
    this.formant = RubberbandFormant.shifted,
    this.phase = RubberbandPhase.laminar,
    this.pitch = 1.0,
    this.pitchq = RubberbandPitch.quality,
    this.smoothing = RubberbandSmoothing.off,
    this.tempo = 1.0,
    this.transients = RubberbandTransients.crisp,
    this.window = RubberbandWindow.standard,
  });

  /// Returns a copy of this [RubberbandSettings] with the given fields replaced.
  RubberbandSettings copyWith({
    bool? enabled,
    RubberbandChannels? channels,
    RubberbandDetector? detector,
    RubberbandFormant? formant,
    RubberbandPhase? phase,
    double? pitch,
    RubberbandPitch? pitchq,
    RubberbandSmoothing? smoothing,
    double? tempo,
    RubberbandTransients? transients,
    RubberbandWindow? window,
  }) =>
      RubberbandSettings(
        enabled: enabled ?? this.enabled,
        channels: channels ?? this.channels,
        detector: detector ?? this.detector,
        formant: formant ?? this.formant,
        phase: phase ?? this.phase,
        pitch: pitch ?? this.pitch,
        pitchq: pitchq ?? this.pitchq,
        smoothing: smoothing ?? this.smoothing,
        tempo: tempo ?? this.tempo,
        transients: transients ?? this.transients,
        window: window ?? this.window,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RubberbandSettings &&
          other.enabled == enabled &&
          other.channels == channels &&
          other.detector == detector &&
          other.formant == formant &&
          other.phase == phase &&
          other.pitch == pitch &&
          other.pitchq == pitchq &&
          other.smoothing == smoothing &&
          other.tempo == tempo &&
          other.transients == transients &&
          other.window == window);

  @override
  int get hashCode => Object.hash(enabled, channels, detector, formant, phase,
      pitch, pitchq, smoothing, tempo, transients, window,);

  @override
  String toString() =>
      'RubberbandSettings(enabled: $enabled, channels: $channels, detector: $detector, formant: $formant, phase: $phase, pitch: $pitch, pitchq: $pitchq, smoothing: $smoothing, tempo: $tempo, transients: $transients, window: $window)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(pitch >= pitchMin, 'rubberband.pitch must be >= 0.01');
    assert(pitch <= pitchMax, 'rubberband.pitch must be <= 100');
    assert(tempo >= tempoMin, 'rubberband.tempo must be >= 0.01');
    assert(tempo <= tempoMax, 'rubberband.tempo must be <= 100');
    final parts = <String>[];
    if (channels != RubberbandChannels.apart)
      parts.add('channels=' + channels.mpvValue);
    if (detector != RubberbandDetector.compound)
      parts.add('detector=' + detector.mpvValue);
    if (formant != RubberbandFormant.shifted)
      parts.add('formant=' + formant.mpvValue);
    if (phase != RubberbandPhase.laminar) parts.add('phase=' + phase.mpvValue);
    if (pitch != 1.0) parts.add('pitch=' + _wireDouble(pitch));
    if (pitchq != RubberbandPitch.quality)
      parts.add('pitchq=' + pitchq.mpvValue);
    if (smoothing != RubberbandSmoothing.off)
      parts.add('smoothing=' + smoothing.mpvValue);
    if (tempo != 1.0) parts.add('tempo=' + _wireDouble(tempo));
    if (transients != RubberbandTransients.crisp)
      parts.add('transients=' + transients.mpvValue);
    if (window != RubberbandWindow.standard)
      parts.add('window=' + window.mpvValue);
    return parts.isEmpty
        ? 'lavfi-rubberband'
        : 'lavfi-rubberband=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  List<(String, String)>? _runtimeDiff(RubberbandSettings prev) {
    final out = <(String, String)>[];
    if (channels != prev.channels) return null;
    if (detector != prev.detector) return null;
    if (formant != prev.formant) return null;
    if (phase != prev.phase) return null;
    if (pitch != prev.pitch) {
      out.add(('pitch', _wireDouble(pitch)));
    }
    if (pitchq != prev.pitchq) return null;
    if (smoothing != prev.smoothing) return null;
    if (tempo != prev.tempo) {
      out.add(('tempo', _wireDouble(tempo)));
    }
    if (transients != prev.transients) return null;
    if (window != prev.window) return null;
    return out;
  }
}

/// Configuration for the `silenceremove` audio effect.
///
/// Remove silence from the beginning, middle or end of the audio.
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [detection]: Set how is silence detected. (range 0..5, default D_RMS)
/// - [start_duration]: Specify the amount of time that non-silence must be detected before it stops trimming audio. By increasing the duration, bursts of noises can be treated as silence and trimmed off. Default value is `0`. (range 0..2147483647, default 0)
/// - [start_mode]: Specify mode of detection of silence end at start of multi-channel audio. Can be `any` or `all`. Default is `any`. With `any`, any sample from any channel that is detected as non-silence will trigger end of silence trimming at start of audio stream. With `all`, only if every sample from every channel is detected as non-silence will trigger end of silence trimming at start of audio stream, limited usage. (range 0..1, default T_ANY, runtime-tunable)
/// - [start_periods]: This value is used to indicate if audio should be trimmed at beginning of the audio. A value of zero indicates no silence should be trimmed from the beginning. When specifying a non-zero value, it trims audio up until it finds non-silence. Normally, when trimming silence from beginning of audio the `start_periods` will be `1` but it can be increased to higher values to trim all audio up to specific count of non-silence periods. Default value is `0`. (range 0..9000, default 0)
/// - [start_silence]: Specify max duration of silence at beginning that will be kept after trimming. Default is 0, which is equal to trimming all samples detected as silence. (range 0..2147483647, default 0)
/// - [start_threshold]: This indicates what sample value should be treated as silence. For digital audio, a value of `0` may be fine but for audio recorded from analog, you may wish to increase the value to account for background noise. Can be specified in dB (in case "dB" is appended to the specified value) or amplitude ratio. Default value is `0`. (range 0..1.7976931348623157e+308, default 0, runtime-tunable)
/// - [stop_duration]: Specify a duration of silence that must exist before audio is not copied any more. By specifying a higher duration, silence that is wanted can be left in the audio. Default value is `0`. (range 0..2147483647, default 0)
/// - [stop_mode]: Specify mode of detection of silence start after start of multi-channel audio. Can be `any` or `all`. Default is `all`. With `any`, any sample from any channel that is detected as silence will trigger start of silence trimming after start of audio stream, limited usage. With `all`, only if every sample from every channel is detected as silence will trigger start of silence trimming after start of audio stream. (range 0..1, default T_ALL, runtime-tunable)
/// - [stop_periods]: Set the count for trimming silence from the end of audio. When specifying a positive value, it trims audio after it finds specified silence period. To remove silence from the middle of a file, specify a `stop_periods` that is negative. This value is then treated as a positive value and is used to indicate the effect should restart processing as specified by `stop_periods`, making it suitable for removing periods of silence in the middle of the audio. Default value is `0`. (range -9000..9000, default 0)
/// - [stop_silence]: Specify max duration of silence at end that will be kept after trimming. Default is 0, which is equal to trimming all samples detected as silence. (range 0..2147483647, default 0)
/// - [stop_threshold]: This is the same as @option{start_threshold} but for trimming silence from the end of audio. Can be specified in dB (in case "dB" is appended to the specified value) or amplitude ratio. Default value is `0`. (range 0..1.7976931348623157e+308, default 0, runtime-tunable)
/// - [timestamp]: Set processing mode of every audio frame output timestamp. (range 0..1, default TS_WRITE)
/// - [window]: Set duration in number of seconds used to calculate size of window in number of samples for detecting silence. Using `0` will effectively disable any windowing and use only single sample per channel for silence detection. In that case it may be needed to also set @option{start_silence} and/or @option{stop_silence} to nonzero values with also @option{start_duration} and/or @option{stop_duration} to nonzero values. Default value is `0.02`. Allowed range is from `0` to `10`. (range 0..100000000, default 20000)
final class SilenceremoveSettings {
  /// Default value for [start_periods].
  static const int start_periodsDefault = 0;

  /// Minimum value for [start_periods].
  static const int start_periodsMin = 0;

  /// Maximum value for [start_periods].
  static const int start_periodsMax = 9000;

  /// Default value for [start_threshold].
  static const double start_thresholdDefault = 0.0;

  /// Minimum value for [start_threshold].
  static const double start_thresholdMin = 0.0;

  /// Maximum value for [start_threshold].
  static const double start_thresholdMax = 1.7976931348623157e+308;

  /// Default value for [stop_periods].
  static const int stop_periodsDefault = 0;

  /// Minimum value for [stop_periods].
  static const int stop_periodsMin = -9000;

  /// Maximum value for [stop_periods].
  static const int stop_periodsMax = 9000;

  /// Default value for [stop_threshold].
  static const double stop_thresholdDefault = 0.0;

  /// Minimum value for [stop_threshold].
  static const double stop_thresholdMin = 0.0;

  /// Maximum value for [stop_threshold].
  static const double stop_thresholdMax = 1.7976931348623157e+308;

  /// Whether this effect is inserted into the audio chain.
  final bool enabled;

  /// set how silence is detected
  final SilenceremoveDetection detection;

  /// set start duration of non-silence part
  final Duration start_duration;

  /// set which channel will trigger trimming from start
  final SilenceremoveMode start_mode;

  /// set periods of silence parts to skip from start
  final int start_periods;

  /// set start duration of silence part to keep
  final Duration start_silence;

  /// set threshold for start silence detection
  final double start_threshold;

  /// set stop duration of silence part
  final Duration stop_duration;

  /// set which channel will trigger trimming from end
  final SilenceremoveMode stop_mode;

  /// set periods of silence parts to skip from end
  final int stop_periods;

  /// set stop duration of silence part to keep
  final Duration stop_silence;

  /// set threshold for stop silence detection
  final double stop_threshold;

  /// set how every output frame timestamp is processed
  final SilenceremoveTimestamp timestamp;

  /// set duration of window for silence detection
  final Duration window;

  /// Creates an [SilenceremoveSettings] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default; the effect stays
  /// inactive until [enabled] is set to `true`.
  const SilenceremoveSettings({
    this.enabled = false,
    this.detection = SilenceremoveDetection.rms,
    this.start_duration = Duration.zero,
    this.start_mode = SilenceremoveMode.any,
    this.start_periods = 0,
    this.start_silence = Duration.zero,
    this.start_threshold = 0.0,
    this.stop_duration = Duration.zero,
    this.stop_mode = SilenceremoveMode.all,
    this.stop_periods = 0,
    this.stop_silence = Duration.zero,
    this.stop_threshold = 0.0,
    this.timestamp = SilenceremoveTimestamp.write,
    this.window = const Duration(microseconds: 20000),
  });

  /// Returns a copy of this [SilenceremoveSettings] with the given fields replaced.
  SilenceremoveSettings copyWith({
    bool? enabled,
    SilenceremoveDetection? detection,
    Duration? start_duration,
    SilenceremoveMode? start_mode,
    int? start_periods,
    Duration? start_silence,
    double? start_threshold,
    Duration? stop_duration,
    SilenceremoveMode? stop_mode,
    int? stop_periods,
    Duration? stop_silence,
    double? stop_threshold,
    SilenceremoveTimestamp? timestamp,
    Duration? window,
  }) =>
      SilenceremoveSettings(
        enabled: enabled ?? this.enabled,
        detection: detection ?? this.detection,
        start_duration: start_duration ?? this.start_duration,
        start_mode: start_mode ?? this.start_mode,
        start_periods: start_periods ?? this.start_periods,
        start_silence: start_silence ?? this.start_silence,
        start_threshold: start_threshold ?? this.start_threshold,
        stop_duration: stop_duration ?? this.stop_duration,
        stop_mode: stop_mode ?? this.stop_mode,
        stop_periods: stop_periods ?? this.stop_periods,
        stop_silence: stop_silence ?? this.stop_silence,
        stop_threshold: stop_threshold ?? this.stop_threshold,
        timestamp: timestamp ?? this.timestamp,
        window: window ?? this.window,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SilenceremoveSettings &&
          other.enabled == enabled &&
          other.detection == detection &&
          other.start_duration == start_duration &&
          other.start_mode == start_mode &&
          other.start_periods == start_periods &&
          other.start_silence == start_silence &&
          other.start_threshold == start_threshold &&
          other.stop_duration == stop_duration &&
          other.stop_mode == stop_mode &&
          other.stop_periods == stop_periods &&
          other.stop_silence == stop_silence &&
          other.stop_threshold == stop_threshold &&
          other.timestamp == timestamp &&
          other.window == window);

  @override
  int get hashCode => Object.hash(
      enabled,
      detection,
      start_duration,
      start_mode,
      start_periods,
      start_silence,
      start_threshold,
      stop_duration,
      stop_mode,
      stop_periods,
      stop_silence,
      stop_threshold,
      timestamp,
      window,);

  @override
  String toString() =>
      'SilenceremoveSettings(enabled: $enabled, detection: $detection, start_duration: $start_duration, start_mode: $start_mode, start_periods: $start_periods, start_silence: $start_silence, start_threshold: $start_threshold, stop_duration: $stop_duration, stop_mode: $stop_mode, stop_periods: $stop_periods, stop_silence: $stop_silence, stop_threshold: $stop_threshold, timestamp: $timestamp, window: $window)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(start_periods >= start_periodsMin,
        'silenceremove.start_periods must be >= 0',);
    assert(start_periods <= start_periodsMax,
        'silenceremove.start_periods must be <= 9000',);
    assert(start_threshold >= start_thresholdMin,
        'silenceremove.start_threshold must be >= 0',);
    assert(start_threshold <= start_thresholdMax,
        'silenceremove.start_threshold must be <= 1.7976931348623157e+308',);
    assert(stop_periods >= stop_periodsMin,
        'silenceremove.stop_periods must be >= -9000',);
    assert(stop_periods <= stop_periodsMax,
        'silenceremove.stop_periods must be <= 9000',);
    assert(stop_threshold >= stop_thresholdMin,
        'silenceremove.stop_threshold must be >= 0',);
    assert(stop_threshold <= stop_thresholdMax,
        'silenceremove.stop_threshold must be <= 1.7976931348623157e+308',);
    final parts = <String>[];
    if (detection != SilenceremoveDetection.rms)
      parts.add('detection=' + detection.mpvValue);
    if (start_duration != Duration.zero)
      parts.add(
          'start_duration=' + _wireDouble(start_duration.inMicroseconds / 1e6),);
    if (start_mode != SilenceremoveMode.any)
      parts.add('start_mode=' + start_mode.mpvValue);
    if (start_periods != 0)
      parts.add('start_periods=' + start_periods.toString());
    if (start_silence != Duration.zero)
      parts.add(
          'start_silence=' + _wireDouble(start_silence.inMicroseconds / 1e6),);
    if (start_threshold != 0.0)
      parts.add('start_threshold=' + _wireDouble(start_threshold));
    if (stop_duration != Duration.zero)
      parts.add(
          'stop_duration=' + _wireDouble(stop_duration.inMicroseconds / 1e6),);
    if (stop_mode != SilenceremoveMode.all)
      parts.add('stop_mode=' + stop_mode.mpvValue);
    if (stop_periods != 0) parts.add('stop_periods=' + stop_periods.toString());
    if (stop_silence != Duration.zero)
      parts.add(
          'stop_silence=' + _wireDouble(stop_silence.inMicroseconds / 1e6),);
    if (stop_threshold != 0.0)
      parts.add('stop_threshold=' + _wireDouble(stop_threshold));
    if (timestamp != SilenceremoveTimestamp.write)
      parts.add('timestamp=' + timestamp.mpvValue);
    if (window != const Duration(microseconds: 20000))
      parts.add('window=' + _wireDouble(window.inMicroseconds / 1e6));
    return parts.isEmpty
        ? 'lavfi-silenceremove'
        : 'lavfi-silenceremove=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  List<(String, String)>? _runtimeDiff(SilenceremoveSettings prev) {
    final out = <(String, String)>[];
    if (detection != prev.detection) return null;
    if (start_duration != prev.start_duration) return null;
    if (start_mode != prev.start_mode) {
      out.add(('start_mode', start_mode.mpvValue));
    }
    if (start_periods != prev.start_periods) return null;
    if (start_silence != prev.start_silence) return null;
    if (start_threshold != prev.start_threshold) {
      out.add(('start_threshold', _wireDouble(start_threshold)));
    }
    if (stop_duration != prev.stop_duration) return null;
    if (stop_mode != prev.stop_mode) {
      out.add(('stop_mode', stop_mode.mpvValue));
    }
    if (stop_periods != prev.stop_periods) return null;
    if (stop_silence != prev.stop_silence) return null;
    if (stop_threshold != prev.stop_threshold) {
      out.add(('stop_threshold', _wireDouble(stop_threshold)));
    }
    if (timestamp != prev.timestamp) return null;
    if (window != prev.window) return null;
    return out;
  }
}

/// Configuration for the `speechnorm` audio effect.
///
/// Speech Normalizer.
///
/// This filter expands or compresses each half-cycle of audio samples
/// (local set of samples all above or all below zero and between two nearest zero crossings) depending
/// on threshold value, so audio reaches target peak value under conditions controlled by below options.
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [c]: Set the maximum compression factor. Allowed range is from 1.0 to 50.0. Default value is 2.0. This option controls maximum local half-cycle of samples compression. This option is used only if @option{threshold} option is set to value greater than 0.0, then in such cases when local peak is lower or same as value set by @option{threshold} all samples belonging to that peak's half-cycle will be compressed by current compression factor. (range 1.0..50.0, default 2.0, runtime-tunable)
/// - [channels]: Specify which channels to filter, by default all available channels are filtered. (range 0..0, default "all", runtime-tunable)
/// - [compression]: Set the maximum compression factor. Allowed range is from 1.0 to 50.0. Default value is 2.0. This option controls maximum local half-cycle of samples compression. This option is used only if @option{threshold} option is set to value greater than 0.0, then in such cases when local peak is lower or same as value set by @option{threshold} all samples belonging to that peak's half-cycle will be compressed by current compression factor. (range 1.0..50.0, default 2.0, runtime-tunable)
/// - [e]: Set the maximum expansion factor. Allowed range is from 1.0 to 50.0. Default value is 2.0. This option controls maximum local half-cycle of samples expansion. The maximum expansion would be such that local peak value reaches target peak value but never to surpass it and that ratio between new and previous peak value does not surpass this option value. (range 1.0..50.0, default 2.0, runtime-tunable)
/// - [expansion]: Set the maximum expansion factor. Allowed range is from 1.0 to 50.0. Default value is 2.0. This option controls maximum local half-cycle of samples expansion. The maximum expansion would be such that local peak value reaches target peak value but never to surpass it and that ratio between new and previous peak value does not surpass this option value. (range 1.0..50.0, default 2.0, runtime-tunable)
/// - [f]: Set the compression raising amount per each half-cycle of samples. Default value is 0.001. Allowed range is from 0.0 to 1.0. This controls how fast compression factor is raised per each new half-cycle until it reaches @option{compression} value. (range 0.0..1.0, default 0.001, runtime-tunable)
/// - [fall]: Set the compression raising amount per each half-cycle of samples. Default value is 0.001. Allowed range is from 0.0 to 1.0. This controls how fast compression factor is raised per each new half-cycle until it reaches @option{compression} value. (range 0.0..1.0, default 0.001, runtime-tunable)
/// - [h]: Specify which channels to filter, by default all available channels are filtered. (range 0..0, default "all", runtime-tunable)
/// - [i]: Enable inverted filtering, by default is disabled. This inverts interpretation of @option{threshold} option. When enabled any half-cycle of samples with their local peak value below or same as @option{threshold} option will be expanded otherwise it will be compressed. (range 0..1, default 0, runtime-tunable)
/// - [invert]: Enable inverted filtering, by default is disabled. This inverts interpretation of @option{threshold} option. When enabled any half-cycle of samples with their local peak value below or same as @option{threshold} option will be expanded otherwise it will be compressed. (range 0..1, default 0, runtime-tunable)
/// - [l]: Link channels when calculating gain applied to each filtered channel sample, by default is disabled. When disabled each filtered channel gain calculation is independent, otherwise when this option is enabled the minimum of all possible gains for each filtered channel is used. (range 0..1, default 0, runtime-tunable)
/// - [link]: Link channels when calculating gain applied to each filtered channel sample, by default is disabled. When disabled each filtered channel gain calculation is independent, otherwise when this option is enabled the minimum of all possible gains for each filtered channel is used. (range 0..1, default 0, runtime-tunable)
/// - [m]: Set the expansion target RMS value. This specifies the highest allowed RMS level for the normalized audio input. Default value is 0.0, thus disabled. Allowed range is from 0.0 to 1.0. (range 0.0..1.0, default 0.0, runtime-tunable)
/// - [p]: Set the expansion target peak value. This specifies the highest allowed absolute amplitude level for the normalized audio input. Default value is 0.95. Allowed range is from 0.0 to 1.0. (range 0.0..1.0, default 0.95, runtime-tunable)
/// - [peak]: Set the expansion target peak value. This specifies the highest allowed absolute amplitude level for the normalized audio input. Default value is 0.95. Allowed range is from 0.0 to 1.0. (range 0.0..1.0, default 0.95, runtime-tunable)
/// - [r]: Set the expansion raising amount per each half-cycle of samples. Default value is 0.001. Allowed range is from 0.0 to 1.0. This controls how fast expansion factor is raised per each new half-cycle until it reaches @option{expansion} value. Setting this options too high may lead to distortions. (range 0.0..1.0, default 0.001, runtime-tunable)
/// - [raise]: Set the expansion raising amount per each half-cycle of samples. Default value is 0.001. Allowed range is from 0.0 to 1.0. This controls how fast expansion factor is raised per each new half-cycle until it reaches @option{expansion} value. Setting this options too high may lead to distortions. (range 0.0..1.0, default 0.001, runtime-tunable)
/// - [rms]: Set the expansion target RMS value. This specifies the highest allowed RMS level for the normalized audio input. Default value is 0.0, thus disabled. Allowed range is from 0.0 to 1.0. (range 0.0..1.0, default 0.0, runtime-tunable)
/// - [t]: Set the threshold value. Default value is 0.0. Allowed range is from 0.0 to 1.0. This option specifies which half-cycles of samples will be compressed and which will be expanded. Any half-cycle samples with their local peak value below or same as this option value will be compressed by current compression factor, otherwise, if greater than threshold value they will be expanded with expansion factor so that it could reach peak target value but never surpass it. (range 0.0..1.0, default 0, runtime-tunable)
/// - [threshold]: Set the threshold value. Default value is 0.0. Allowed range is from 0.0 to 1.0. This option specifies which half-cycles of samples will be compressed and which will be expanded. Any half-cycle samples with their local peak value below or same as this option value will be compressed by current compression factor, otherwise, if greater than threshold value they will be expanded with expansion factor so that it could reach peak target value but never surpass it. (range 0.0..1.0, default 0, runtime-tunable)
final class SpeechnormSettings {
  /// Default value for [c].
  static const double cDefault = 2.0;

  /// Minimum value for [c].
  static const double cMin = 1.0;

  /// Maximum value for [c].
  static const double cMax = 50.0;

  /// Default value for [compression].
  static const double compressionDefault = 2.0;

  /// Minimum value for [compression].
  static const double compressionMin = 1.0;

  /// Maximum value for [compression].
  static const double compressionMax = 50.0;

  /// Default value for [e].
  static const double eDefault = 2.0;

  /// Minimum value for [e].
  static const double eMin = 1.0;

  /// Maximum value for [e].
  static const double eMax = 50.0;

  /// Default value for [expansion].
  static const double expansionDefault = 2.0;

  /// Minimum value for [expansion].
  static const double expansionMin = 1.0;

  /// Maximum value for [expansion].
  static const double expansionMax = 50.0;

  /// Default value for [f].
  static const double fDefault = 0.001;

  /// Minimum value for [f].
  static const double fMin = 0.0;

  /// Maximum value for [f].
  static const double fMax = 1.0;

  /// Default value for [fall].
  static const double fallDefault = 0.001;

  /// Minimum value for [fall].
  static const double fallMin = 0.0;

  /// Maximum value for [fall].
  static const double fallMax = 1.0;

  /// Default value for [m].
  static const double mDefault = 0.0;

  /// Minimum value for [m].
  static const double mMin = 0.0;

  /// Maximum value for [m].
  static const double mMax = 1.0;

  /// Default value for [p].
  static const double pDefault = 0.95;

  /// Minimum value for [p].
  static const double pMin = 0.0;

  /// Maximum value for [p].
  static const double pMax = 1.0;

  /// Default value for [peak].
  static const double peakDefault = 0.95;

  /// Minimum value for [peak].
  static const double peakMin = 0.0;

  /// Maximum value for [peak].
  static const double peakMax = 1.0;

  /// Default value for [r].
  static const double rDefault = 0.001;

  /// Minimum value for [r].
  static const double rMin = 0.0;

  /// Maximum value for [r].
  static const double rMax = 1.0;

  /// Default value for [raise].
  static const double raiseDefault = 0.001;

  /// Minimum value for [raise].
  static const double raiseMin = 0.0;

  /// Maximum value for [raise].
  static const double raiseMax = 1.0;

  /// Default value for [rms].
  static const double rmsDefault = 0.0;

  /// Minimum value for [rms].
  static const double rmsMin = 0.0;

  /// Maximum value for [rms].
  static const double rmsMax = 1.0;

  /// Default value for [t].
  static const double tDefault = 0.0;

  /// Minimum value for [t].
  static const double tMin = 0.0;

  /// Maximum value for [t].
  static const double tMax = 1.0;

  /// Default value for [threshold].
  static const double thresholdDefault = 0.0;

  /// Minimum value for [threshold].
  static const double thresholdMin = 0.0;

  /// Maximum value for [threshold].
  static const double thresholdMax = 1.0;

  /// Whether this effect is inserted into the audio chain.
  final bool enabled;

  /// set the max compression factor
  final double c;

  /// set channels to filter
  final String channels;

  /// set the max compression factor
  final double compression;

  /// set the max expansion factor
  final double e;

  /// set the max expansion factor
  final double expansion;

  /// set the compression raising amount
  final double f;

  /// set the compression raising amount
  final double fall;

  /// set channels to filter
  final String h;

  /// set inverted filtering
  final bool i;

  /// set inverted filtering
  final bool invert;

  /// set linked channels filtering
  final bool l;

  /// set linked channels filtering
  final bool link;

  /// set the RMS value
  final double m;

  /// set the peak value
  final double p;

  /// set the peak value
  final double peak;

  /// set the expansion raising amount
  final double r;

  /// set the expansion raising amount
  final double raise;

  /// set the RMS value
  final double rms;

  /// set the threshold value
  final double t;

  /// set the threshold value
  final double threshold;

  /// Creates an [SpeechnormSettings] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default; the effect stays
  /// inactive until [enabled] is set to `true`.
  const SpeechnormSettings({
    this.enabled = false,
    this.c = 2.0,
    this.channels = 'all',
    this.compression = 2.0,
    this.e = 2.0,
    this.expansion = 2.0,
    this.f = 0.001,
    this.fall = 0.001,
    this.h = 'all',
    this.i = false,
    this.invert = false,
    this.l = false,
    this.link = false,
    this.m = 0.0,
    this.p = 0.95,
    this.peak = 0.95,
    this.r = 0.001,
    this.raise = 0.001,
    this.rms = 0.0,
    this.t = 0.0,
    this.threshold = 0.0,
  });

  /// Returns a copy of this [SpeechnormSettings] with the given fields replaced.
  SpeechnormSettings copyWith({
    bool? enabled,
    double? c,
    String? channels,
    double? compression,
    double? e,
    double? expansion,
    double? f,
    double? fall,
    String? h,
    bool? i,
    bool? invert,
    bool? l,
    bool? link,
    double? m,
    double? p,
    double? peak,
    double? r,
    double? raise,
    double? rms,
    double? t,
    double? threshold,
  }) =>
      SpeechnormSettings(
        enabled: enabled ?? this.enabled,
        c: c ?? this.c,
        channels: channels ?? this.channels,
        compression: compression ?? this.compression,
        e: e ?? this.e,
        expansion: expansion ?? this.expansion,
        f: f ?? this.f,
        fall: fall ?? this.fall,
        h: h ?? this.h,
        i: i ?? this.i,
        invert: invert ?? this.invert,
        l: l ?? this.l,
        link: link ?? this.link,
        m: m ?? this.m,
        p: p ?? this.p,
        peak: peak ?? this.peak,
        r: r ?? this.r,
        raise: raise ?? this.raise,
        rms: rms ?? this.rms,
        t: t ?? this.t,
        threshold: threshold ?? this.threshold,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SpeechnormSettings &&
          other.enabled == enabled &&
          other.c == c &&
          other.channels == channels &&
          other.compression == compression &&
          other.e == e &&
          other.expansion == expansion &&
          other.f == f &&
          other.fall == fall &&
          other.h == h &&
          other.i == i &&
          other.invert == invert &&
          other.l == l &&
          other.link == link &&
          other.m == m &&
          other.p == p &&
          other.peak == peak &&
          other.r == r &&
          other.raise == raise &&
          other.rms == rms &&
          other.t == t &&
          other.threshold == threshold);

  @override
  int get hashCode => Object.hashAll([
        enabled,
        c,
        channels,
        compression,
        e,
        expansion,
        f,
        fall,
        h,
        i,
        invert,
        l,
        link,
        m,
        p,
        peak,
        r,
        raise,
        rms,
        t,
        threshold,
      ]);

  @override
  String toString() =>
      'SpeechnormSettings(enabled: $enabled, c: $c, channels: $channels, compression: $compression, e: $e, expansion: $expansion, f: $f, fall: $fall, h: $h, i: $i, invert: $invert, l: $l, link: $link, m: $m, p: $p, peak: $peak, r: $r, raise: $raise, rms: $rms, t: $t, threshold: $threshold)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(c >= cMin, 'speechnorm.c must be >= 1.0');
    assert(c <= cMax, 'speechnorm.c must be <= 50.0');
    assert(
        compression >= compressionMin, 'speechnorm.compression must be >= 1.0',);
    assert(compression <= compressionMax,
        'speechnorm.compression must be <= 50.0',);
    assert(e >= eMin, 'speechnorm.e must be >= 1.0');
    assert(e <= eMax, 'speechnorm.e must be <= 50.0');
    assert(expansion >= expansionMin, 'speechnorm.expansion must be >= 1.0');
    assert(expansion <= expansionMax, 'speechnorm.expansion must be <= 50.0');
    assert(f >= fMin, 'speechnorm.f must be >= 0.0');
    assert(f <= fMax, 'speechnorm.f must be <= 1.0');
    assert(fall >= fallMin, 'speechnorm.fall must be >= 0.0');
    assert(fall <= fallMax, 'speechnorm.fall must be <= 1.0');
    assert(m >= mMin, 'speechnorm.m must be >= 0.0');
    assert(m <= mMax, 'speechnorm.m must be <= 1.0');
    assert(p >= pMin, 'speechnorm.p must be >= 0.0');
    assert(p <= pMax, 'speechnorm.p must be <= 1.0');
    assert(peak >= peakMin, 'speechnorm.peak must be >= 0.0');
    assert(peak <= peakMax, 'speechnorm.peak must be <= 1.0');
    assert(r >= rMin, 'speechnorm.r must be >= 0.0');
    assert(r <= rMax, 'speechnorm.r must be <= 1.0');
    assert(raise >= raiseMin, 'speechnorm.raise must be >= 0.0');
    assert(raise <= raiseMax, 'speechnorm.raise must be <= 1.0');
    assert(rms >= rmsMin, 'speechnorm.rms must be >= 0.0');
    assert(rms <= rmsMax, 'speechnorm.rms must be <= 1.0');
    assert(t >= tMin, 'speechnorm.t must be >= 0.0');
    assert(t <= tMax, 'speechnorm.t must be <= 1.0');
    assert(threshold >= thresholdMin, 'speechnorm.threshold must be >= 0.0');
    assert(threshold <= thresholdMax, 'speechnorm.threshold must be <= 1.0');
    final parts = <String>[];
    if (c != 2.0) parts.add('c=' + _wireDouble(c));
    if (channels != 'all') parts.add('channels=' + '[' + channels + ']');
    if (compression != 2.0)
      parts.add('compression=' + _wireDouble(compression));
    if (e != 2.0) parts.add('e=' + _wireDouble(e));
    if (expansion != 2.0) parts.add('expansion=' + _wireDouble(expansion));
    if (f != 0.001) parts.add('f=' + _wireDouble(f));
    if (fall != 0.001) parts.add('fall=' + _wireDouble(fall));
    if (h != 'all') parts.add('h=' + '[' + h + ']');
    if (i != false) parts.add('i=' + (i ? '1' : '0'));
    if (invert != false) parts.add('invert=' + (invert ? '1' : '0'));
    if (l != false) parts.add('l=' + (l ? '1' : '0'));
    if (link != false) parts.add('link=' + (link ? '1' : '0'));
    if (m != 0.0) parts.add('m=' + _wireDouble(m));
    if (p != 0.95) parts.add('p=' + _wireDouble(p));
    if (peak != 0.95) parts.add('peak=' + _wireDouble(peak));
    if (r != 0.001) parts.add('r=' + _wireDouble(r));
    if (raise != 0.001) parts.add('raise=' + _wireDouble(raise));
    if (rms != 0.0) parts.add('rms=' + _wireDouble(rms));
    if (t != 0.0) parts.add('t=' + _wireDouble(t));
    if (threshold != 0.0) parts.add('threshold=' + _wireDouble(threshold));
    return parts.isEmpty
        ? 'lavfi-speechnorm'
        : 'lavfi-speechnorm=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  List<(String, String)>? _runtimeDiff(SpeechnormSettings prev) {
    final out = <(String, String)>[];
    if (c != prev.c) {
      out.add(('c', _wireDouble(c)));
    }
    if (channels != prev.channels) {
      out.add(('channels', channels));
    }
    if (compression != prev.compression) {
      out.add(('compression', _wireDouble(compression)));
    }
    if (e != prev.e) {
      out.add(('e', _wireDouble(e)));
    }
    if (expansion != prev.expansion) {
      out.add(('expansion', _wireDouble(expansion)));
    }
    if (f != prev.f) {
      out.add(('f', _wireDouble(f)));
    }
    if (fall != prev.fall) {
      out.add(('fall', _wireDouble(fall)));
    }
    if (h != prev.h) {
      out.add(('h', h));
    }
    if (i != prev.i) {
      out.add(('i', (i ? '1' : '0')));
    }
    if (invert != prev.invert) {
      out.add(('invert', (invert ? '1' : '0')));
    }
    if (l != prev.l) {
      out.add(('l', (l ? '1' : '0')));
    }
    if (link != prev.link) {
      out.add(('link', (link ? '1' : '0')));
    }
    if (m != prev.m) {
      out.add(('m', _wireDouble(m)));
    }
    if (p != prev.p) {
      out.add(('p', _wireDouble(p)));
    }
    if (peak != prev.peak) {
      out.add(('peak', _wireDouble(peak)));
    }
    if (r != prev.r) {
      out.add(('r', _wireDouble(r)));
    }
    if (raise != prev.raise) {
      out.add(('raise', _wireDouble(raise)));
    }
    if (rms != prev.rms) {
      out.add(('rms', _wireDouble(rms)));
    }
    if (t != prev.t) {
      out.add(('t', _wireDouble(t)));
    }
    if (threshold != prev.threshold) {
      out.add(('threshold', _wireDouble(threshold)));
    }
    return out;
  }
}

/// Configuration for the `stereotools` audio effect.
///
/// This filter has some handy utilities to manage stereo signals, for converting
/// M/S stereo recordings to L/R signal while having control over the parameters
/// or spreading the stereo image of master track.
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [balance_in]: Set input balance between both channels. Default is 0. Allowed range is from -1 to 1. (range -1..1, default 0, runtime-tunable)
/// - [balance_out]: Set output balance between both channels. Default is 0. Allowed range is from -1 to 1. (range -1..1, default 0, runtime-tunable)
/// - [base]: set stereo base (range -1..1, default 0, runtime-tunable)
/// - [bmode_in]: set balance in mode (range 0..2, default 0, runtime-tunable)
/// - [bmode_out]: set balance out mode (range 0..2, default 0, runtime-tunable)
/// - [delay]: set delay (range -20..20, default 0, runtime-tunable)
/// - [level_in]: Set input level before filtering for both channels. Defaults is 1. Allowed range is from 0.015625 to 64. (range 0.015625..64, default 1, runtime-tunable)
/// - [level_out]: Set output level after filtering for both channels. Defaults is 1. Allowed range is from 0.015625 to 64. (range 0.015625..64, default 1, runtime-tunable)
/// - [mlev]: set middle level (range 0.015625..64, default 1, runtime-tunable)
/// - [mode]: Set stereo mode. Available values are: (range 0..10, default 0, runtime-tunable)
/// - [mpan]: set middle pan (range -1..1, default 0, runtime-tunable)
/// - [mutel]: Mute the left channel. Disabled by default. (range 0..1, default 0, runtime-tunable)
/// - [muter]: Mute the right channel. Disabled by default. (range 0..1, default 0, runtime-tunable)
/// - [phase]: set stereo phase (range 0..360, default 0, runtime-tunable)
/// - [phasel]: Change the phase of the left channel. Disabled by default. (range 0..1, default 0, runtime-tunable)
/// - [phaser]: Change the phase of the right channel. Disabled by default. (range 0..1, default 0, runtime-tunable)
/// - [sbal]: set side balance (range -1..1, default 0, runtime-tunable)
/// - [sclevel]: set S/C level (range 1..100, default 1, runtime-tunable)
/// - [slev]: set side level (range 0.015625..64, default 1, runtime-tunable)
/// - [softclip]: Enable softclipping. Results in analog distortion instead of harsh digital 0dB clipping. Disabled by default. (range 0..1, default 0, runtime-tunable)
final class StereotoolsSettings {
  /// Default value for [balance_in].
  static const double balance_inDefault = 0.0;

  /// Minimum value for [balance_in].
  static const double balance_inMin = -1.0;

  /// Maximum value for [balance_in].
  static const double balance_inMax = 1.0;

  /// Default value for [balance_out].
  static const double balance_outDefault = 0.0;

  /// Minimum value for [balance_out].
  static const double balance_outMin = -1.0;

  /// Maximum value for [balance_out].
  static const double balance_outMax = 1.0;

  /// Default value for [base].
  static const double baseDefault = 0.0;

  /// Minimum value for [base].
  static const double baseMin = -1.0;

  /// Maximum value for [base].
  static const double baseMax = 1.0;

  /// Default value for [delay].
  static const double delayDefault = 0.0;

  /// Minimum value for [delay].
  static const double delayMin = -20.0;

  /// Maximum value for [delay].
  static const double delayMax = 20.0;

  /// Default value for [level_in].
  static const double level_inDefault = 1.0;

  /// Minimum value for [level_in].
  static const double level_inMin = 0.015625;

  /// Maximum value for [level_in].
  static const double level_inMax = 64.0;

  /// Default value for [level_out].
  static const double level_outDefault = 1.0;

  /// Minimum value for [level_out].
  static const double level_outMin = 0.015625;

  /// Maximum value for [level_out].
  static const double level_outMax = 64.0;

  /// Default value for [mlev].
  static const double mlevDefault = 1.0;

  /// Minimum value for [mlev].
  static const double mlevMin = 0.015625;

  /// Maximum value for [mlev].
  static const double mlevMax = 64.0;

  /// Default value for [mpan].
  static const double mpanDefault = 0.0;

  /// Minimum value for [mpan].
  static const double mpanMin = -1.0;

  /// Maximum value for [mpan].
  static const double mpanMax = 1.0;

  /// Default value for [phase].
  static const double phaseDefault = 0.0;

  /// Minimum value for [phase].
  static const double phaseMin = 0.0;

  /// Maximum value for [phase].
  static const double phaseMax = 360.0;

  /// Default value for [sbal].
  static const double sbalDefault = 0.0;

  /// Minimum value for [sbal].
  static const double sbalMin = -1.0;

  /// Maximum value for [sbal].
  static const double sbalMax = 1.0;

  /// Default value for [sclevel].
  static const double sclevelDefault = 1.0;

  /// Minimum value for [sclevel].
  static const double sclevelMin = 1.0;

  /// Maximum value for [sclevel].
  static const double sclevelMax = 100.0;

  /// Default value for [slev].
  static const double slevDefault = 1.0;

  /// Minimum value for [slev].
  static const double slevMin = 0.015625;

  /// Maximum value for [slev].
  static const double slevMax = 64.0;

  /// Whether this effect is inserted into the audio chain.
  final bool enabled;

  /// set balance in
  final double balance_in;

  /// set balance out
  final double balance_out;

  /// set stereo base
  final double base;

  /// set balance in mode
  final StereotoolsBmode bmode_in;

  /// set balance out mode
  final StereotoolsBmode bmode_out;

  /// set delay
  final double delay;

  /// set level in
  final double level_in;

  /// set level out
  final double level_out;

  /// set middle level
  final double mlev;

  /// set stereo mode
  final StereotoolsMode mode;

  /// set middle pan
  final double mpan;

  /// mute L
  final bool mutel;

  /// mute R
  final bool muter;

  /// set stereo phase
  final double phase;

  /// phase L
  final bool phasel;

  /// phase R
  final bool phaser;

  /// set side balance
  final double sbal;

  /// set S/C level
  final double sclevel;

  /// set side level
  final double slev;

  /// enable softclip
  final bool softclip;

  /// Creates an [StereotoolsSettings] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default; the effect stays
  /// inactive until [enabled] is set to `true`.
  const StereotoolsSettings({
    this.enabled = false,
    this.balance_in = 0.0,
    this.balance_out = 0.0,
    this.base = 0.0,
    this.bmode_in = StereotoolsBmode.balance,
    this.bmode_out = StereotoolsBmode.balance,
    this.delay = 0.0,
    this.level_in = 1.0,
    this.level_out = 1.0,
    this.mlev = 1.0,
    this.mode = StereotoolsMode.lr_to_lr,
    this.mpan = 0.0,
    this.mutel = false,
    this.muter = false,
    this.phase = 0.0,
    this.phasel = false,
    this.phaser = false,
    this.sbal = 0.0,
    this.sclevel = 1.0,
    this.slev = 1.0,
    this.softclip = false,
  });

  /// Returns a copy of this [StereotoolsSettings] with the given fields replaced.
  StereotoolsSettings copyWith({
    bool? enabled,
    double? balance_in,
    double? balance_out,
    double? base,
    StereotoolsBmode? bmode_in,
    StereotoolsBmode? bmode_out,
    double? delay,
    double? level_in,
    double? level_out,
    double? mlev,
    StereotoolsMode? mode,
    double? mpan,
    bool? mutel,
    bool? muter,
    double? phase,
    bool? phasel,
    bool? phaser,
    double? sbal,
    double? sclevel,
    double? slev,
    bool? softclip,
  }) =>
      StereotoolsSettings(
        enabled: enabled ?? this.enabled,
        balance_in: balance_in ?? this.balance_in,
        balance_out: balance_out ?? this.balance_out,
        base: base ?? this.base,
        bmode_in: bmode_in ?? this.bmode_in,
        bmode_out: bmode_out ?? this.bmode_out,
        delay: delay ?? this.delay,
        level_in: level_in ?? this.level_in,
        level_out: level_out ?? this.level_out,
        mlev: mlev ?? this.mlev,
        mode: mode ?? this.mode,
        mpan: mpan ?? this.mpan,
        mutel: mutel ?? this.mutel,
        muter: muter ?? this.muter,
        phase: phase ?? this.phase,
        phasel: phasel ?? this.phasel,
        phaser: phaser ?? this.phaser,
        sbal: sbal ?? this.sbal,
        sclevel: sclevel ?? this.sclevel,
        slev: slev ?? this.slev,
        softclip: softclip ?? this.softclip,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StereotoolsSettings &&
          other.enabled == enabled &&
          other.balance_in == balance_in &&
          other.balance_out == balance_out &&
          other.base == base &&
          other.bmode_in == bmode_in &&
          other.bmode_out == bmode_out &&
          other.delay == delay &&
          other.level_in == level_in &&
          other.level_out == level_out &&
          other.mlev == mlev &&
          other.mode == mode &&
          other.mpan == mpan &&
          other.mutel == mutel &&
          other.muter == muter &&
          other.phase == phase &&
          other.phasel == phasel &&
          other.phaser == phaser &&
          other.sbal == sbal &&
          other.sclevel == sclevel &&
          other.slev == slev &&
          other.softclip == softclip);

  @override
  int get hashCode => Object.hashAll([
        enabled,
        balance_in,
        balance_out,
        base,
        bmode_in,
        bmode_out,
        delay,
        level_in,
        level_out,
        mlev,
        mode,
        mpan,
        mutel,
        muter,
        phase,
        phasel,
        phaser,
        sbal,
        sclevel,
        slev,
        softclip,
      ]);

  @override
  String toString() =>
      'StereotoolsSettings(enabled: $enabled, balance_in: $balance_in, balance_out: $balance_out, base: $base, bmode_in: $bmode_in, bmode_out: $bmode_out, delay: $delay, level_in: $level_in, level_out: $level_out, mlev: $mlev, mode: $mode, mpan: $mpan, mutel: $mutel, muter: $muter, phase: $phase, phasel: $phasel, phaser: $phaser, sbal: $sbal, sclevel: $sclevel, slev: $slev, softclip: $softclip)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(balance_in >= balance_inMin, 'stereotools.balance_in must be >= -1');
    assert(balance_in <= balance_inMax, 'stereotools.balance_in must be <= 1');
    assert(
        balance_out >= balance_outMin, 'stereotools.balance_out must be >= -1',);
    assert(
        balance_out <= balance_outMax, 'stereotools.balance_out must be <= 1',);
    assert(base >= baseMin, 'stereotools.base must be >= -1');
    assert(base <= baseMax, 'stereotools.base must be <= 1');
    assert(delay >= delayMin, 'stereotools.delay must be >= -20');
    assert(delay <= delayMax, 'stereotools.delay must be <= 20');
    assert(level_in >= level_inMin, 'stereotools.level_in must be >= 0.015625');
    assert(level_in <= level_inMax, 'stereotools.level_in must be <= 64');
    assert(
        level_out >= level_outMin, 'stereotools.level_out must be >= 0.015625',);
    assert(level_out <= level_outMax, 'stereotools.level_out must be <= 64');
    assert(mlev >= mlevMin, 'stereotools.mlev must be >= 0.015625');
    assert(mlev <= mlevMax, 'stereotools.mlev must be <= 64');
    assert(mpan >= mpanMin, 'stereotools.mpan must be >= -1');
    assert(mpan <= mpanMax, 'stereotools.mpan must be <= 1');
    assert(phase >= phaseMin, 'stereotools.phase must be >= 0');
    assert(phase <= phaseMax, 'stereotools.phase must be <= 360');
    assert(sbal >= sbalMin, 'stereotools.sbal must be >= -1');
    assert(sbal <= sbalMax, 'stereotools.sbal must be <= 1');
    assert(sclevel >= sclevelMin, 'stereotools.sclevel must be >= 1');
    assert(sclevel <= sclevelMax, 'stereotools.sclevel must be <= 100');
    assert(slev >= slevMin, 'stereotools.slev must be >= 0.015625');
    assert(slev <= slevMax, 'stereotools.slev must be <= 64');
    final parts = <String>[];
    if (balance_in != 0.0) parts.add('balance_in=' + _wireDouble(balance_in));
    if (balance_out != 0.0)
      parts.add('balance_out=' + _wireDouble(balance_out));
    if (base != 0.0) parts.add('base=' + _wireDouble(base));
    if (bmode_in != StereotoolsBmode.balance)
      parts.add('bmode_in=' + bmode_in.mpvValue);
    if (bmode_out != StereotoolsBmode.balance)
      parts.add('bmode_out=' + bmode_out.mpvValue);
    if (delay != 0.0) parts.add('delay=' + _wireDouble(delay));
    if (level_in != 1.0) parts.add('level_in=' + _wireDouble(level_in));
    if (level_out != 1.0) parts.add('level_out=' + _wireDouble(level_out));
    if (mlev != 1.0) parts.add('mlev=' + _wireDouble(mlev));
    if (mode != StereotoolsMode.lr_to_lr) parts.add('mode=' + mode.mpvValue);
    if (mpan != 0.0) parts.add('mpan=' + _wireDouble(mpan));
    if (mutel != false) parts.add('mutel=' + (mutel ? '1' : '0'));
    if (muter != false) parts.add('muter=' + (muter ? '1' : '0'));
    if (phase != 0.0) parts.add('phase=' + _wireDouble(phase));
    if (phasel != false) parts.add('phasel=' + (phasel ? '1' : '0'));
    if (phaser != false) parts.add('phaser=' + (phaser ? '1' : '0'));
    if (sbal != 0.0) parts.add('sbal=' + _wireDouble(sbal));
    if (sclevel != 1.0) parts.add('sclevel=' + _wireDouble(sclevel));
    if (slev != 1.0) parts.add('slev=' + _wireDouble(slev));
    if (softclip != false) parts.add('softclip=' + (softclip ? '1' : '0'));
    return parts.isEmpty
        ? 'lavfi-stereotools'
        : 'lavfi-stereotools=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  List<(String, String)>? _runtimeDiff(StereotoolsSettings prev) {
    final out = <(String, String)>[];
    if (balance_in != prev.balance_in) {
      out.add(('balance_in', _wireDouble(balance_in)));
    }
    if (balance_out != prev.balance_out) {
      out.add(('balance_out', _wireDouble(balance_out)));
    }
    if (base != prev.base) {
      out.add(('base', _wireDouble(base)));
    }
    if (bmode_in != prev.bmode_in) {
      out.add(('bmode_in', bmode_in.mpvValue));
    }
    if (bmode_out != prev.bmode_out) {
      out.add(('bmode_out', bmode_out.mpvValue));
    }
    if (delay != prev.delay) {
      out.add(('delay', _wireDouble(delay)));
    }
    if (level_in != prev.level_in) {
      out.add(('level_in', _wireDouble(level_in)));
    }
    if (level_out != prev.level_out) {
      out.add(('level_out', _wireDouble(level_out)));
    }
    if (mlev != prev.mlev) {
      out.add(('mlev', _wireDouble(mlev)));
    }
    if (mode != prev.mode) {
      out.add(('mode', mode.mpvValue));
    }
    if (mpan != prev.mpan) {
      out.add(('mpan', _wireDouble(mpan)));
    }
    if (mutel != prev.mutel) {
      out.add(('mutel', (mutel ? '1' : '0')));
    }
    if (muter != prev.muter) {
      out.add(('muter', (muter ? '1' : '0')));
    }
    if (phase != prev.phase) {
      out.add(('phase', _wireDouble(phase)));
    }
    if (phasel != prev.phasel) {
      out.add(('phasel', (phasel ? '1' : '0')));
    }
    if (phaser != prev.phaser) {
      out.add(('phaser', (phaser ? '1' : '0')));
    }
    if (sbal != prev.sbal) {
      out.add(('sbal', _wireDouble(sbal)));
    }
    if (sclevel != prev.sclevel) {
      out.add(('sclevel', _wireDouble(sclevel)));
    }
    if (slev != prev.slev) {
      out.add(('slev', _wireDouble(slev)));
    }
    if (softclip != prev.softclip) {
      out.add(('softclip', (softclip ? '1' : '0')));
    }
    return out;
  }
}

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
final class StereowidenSettings {
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

  /// Whether this effect is inserted into the audio chain.
  final bool enabled;

  /// set cross feed
  final double crossfeed;

  /// set delay time
  final double delay;

  /// set dry-mix
  final double drymix;

  /// set feedback gain
  final double feedback;

  /// Creates an [StereowidenSettings] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default; the effect stays
  /// inactive until [enabled] is set to `true`.
  const StereowidenSettings({
    this.enabled = false,
    this.crossfeed = .3,
    this.delay = 20.0,
    this.drymix = .8,
    this.feedback = .3,
  });

  /// Returns a copy of this [StereowidenSettings] with the given fields replaced.
  StereowidenSettings copyWith({
    bool? enabled,
    double? crossfeed,
    double? delay,
    double? drymix,
    double? feedback,
  }) =>
      StereowidenSettings(
        enabled: enabled ?? this.enabled,
        crossfeed: crossfeed ?? this.crossfeed,
        delay: delay ?? this.delay,
        drymix: drymix ?? this.drymix,
        feedback: feedback ?? this.feedback,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StereowidenSettings &&
          other.enabled == enabled &&
          other.crossfeed == crossfeed &&
          other.delay == delay &&
          other.drymix == drymix &&
          other.feedback == feedback);

  @override
  int get hashCode => Object.hash(enabled, crossfeed, delay, drymix, feedback);

  @override
  String toString() =>
      'StereowidenSettings(enabled: $enabled, crossfeed: $crossfeed, delay: $delay, drymix: $drymix, feedback: $feedback)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
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
  List<(String, String)>? _runtimeDiff(StereowidenSettings prev) {
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

/// Configuration for the `superequalizer` audio effect.
///
/// Apply 18 band equalizer.
///
/// The filter accepts the following options:
///
/// Parameters whose names start with a digit, addressed by
/// their original key in the [params] map:
/// - `10b`: Set 1480Hz band gain. (range 0..20, default 1)
/// - `11b`: Set 2093Hz band gain. (range 0..20, default 1)
/// - `12b`: Set 2960Hz band gain. (range 0..20, default 1)
/// - `13b`: Set 4186Hz band gain. (range 0..20, default 1)
/// - `14b`: Set 5920Hz band gain. (range 0..20, default 1)
/// - `15b`: Set 8372Hz band gain. (range 0..20, default 1)
/// - `16b`: Set 11840Hz band gain. (range 0..20, default 1)
/// - `17b`: Set 16744Hz band gain. (range 0..20, default 1)
/// - `18b`: Set 20000Hz band gain. (range 0..20, default 1)
/// - `1b`: Set 65Hz band gain. (range 0..20, default 1)
/// - `2b`: Set 92Hz band gain. (range 0..20, default 1)
/// - `3b`: Set 131Hz band gain. (range 0..20, default 1)
/// - `4b`: Set 185Hz band gain. (range 0..20, default 1)
/// - `5b`: Set 262Hz band gain. (range 0..20, default 1)
/// - `6b`: Set 370Hz band gain. (range 0..20, default 1)
/// - `7b`: Set 523Hz band gain. (range 0..20, default 1)
/// - `8b`: Set 740Hz band gain. (range 0..20, default 1)
/// - `9b`: Set 1047Hz band gain. (range 0..20, default 1)
final class SuperequalizerSettings {
  /// Whether this effect is inserted into the audio chain.
  final bool enabled;

  /// Raw values for parameters whose names start with a digit,
  /// keyed by their original ffmpeg option name.
  final Map<String, double> params;

  /// Creates an [SuperequalizerSettings] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default; the effect stays
  /// inactive until [enabled] is set to `true`.
  const SuperequalizerSettings({
    this.enabled = false,
    this.params = const <String, double>{},
  });

  /// Returns a copy of this [SuperequalizerSettings] with the given fields replaced.
  SuperequalizerSettings copyWith({
    bool? enabled,
    Map<String, double>? params,
  }) =>
      SuperequalizerSettings(
        enabled: enabled ?? this.enabled,
        params: params ?? this.params,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SuperequalizerSettings &&
          other.enabled == enabled &&
          _mapEq(params, other.params));

  @override
  int get hashCode => Object.hash(
      enabled,
      Object.hashAllUnordered(
          params.entries.map((e) => Object.hash(e.key, e.value)),),);

  @override
  String toString() =>
      'SuperequalizerSettings(enabled: $enabled, params: $params)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    final parts = <String>[];
    params.forEach((k, v) => parts.add('$k=' + _wireDouble(v)));
    return parts.isEmpty
        ? 'lavfi-superequalizer'
        : 'lavfi-superequalizer=' + parts.join(':');
  }
}

/// Configuration for the `surround` audio effect.
///
/// Apply audio surround upmix filter.
///
/// This filter allows to produce multichannel output from audio stream.
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [allx]: Set spread usage of stereo image across X axis for all channels. Allowed range is from `-1` to `15`. By default this value is negative `-1`, and thus unused. (range -1..15, default -1, runtime-tunable)
/// - [ally]: Set spread usage of stereo image across Y axis for all channels. Allowed range is from `-1` to `15`. By default this value is negative `-1`, and thus unused. (range -1..15, default -1, runtime-tunable)
/// - [angle]: Set angle of stereo surround transform, Allowed range is from `0` to `360`. Default is `90`. (range 0..360, default 90, runtime-tunable)
/// - [bc_in]: Set back center input volume. By default, this is `1`. (range 0..10, default 1, runtime-tunable)
/// - [bc_out]: Set back center output volume. By default, this is `1`. (range 0..10, default 1, runtime-tunable)
/// - [bcx]: Set spread usage of stereo image across X axis for each channel. Allowed range is from `0.06` to `15`. By default this value is `0.5`. (range .06..15, default 0.5, runtime-tunable)
/// - [bcy]: Set spread usage of stereo image across Y axis for each channel. Allowed range is from `0.06` to `15`. By default this value is `0.5`. (range .06..15, default 0.5, runtime-tunable)
/// - [bl_in]: Set back left input volume. By default, this is `1`. (range 0..10, default 1, runtime-tunable)
/// - [bl_out]: Set back left output volume. By default, this is `1`. (range 0..10, default 1, runtime-tunable)
/// - [blx]: Set spread usage of stereo image across X axis for each channel. Allowed range is from `0.06` to `15`. By default this value is `0.5`. (range .06..15, default 0.5, runtime-tunable)
/// - [bly]: Set spread usage of stereo image across Y axis for each channel. Allowed range is from `0.06` to `15`. By default this value is `0.5`. (range .06..15, default 0.5, runtime-tunable)
/// - [br_in]: Set back right input volume. By default, this is `1`. (range 0..10, default 1, runtime-tunable)
/// - [br_out]: Set back right output volume. By default, this is `1`. (range 0..10, default 1, runtime-tunable)
/// - [brx]: Set spread usage of stereo image across X axis for each channel. Allowed range is from `0.06` to `15`. By default this value is `0.5`. (range .06..15, default 0.5, runtime-tunable)
/// - [bry]: Set spread usage of stereo image across Y axis for each channel. Allowed range is from `0.06` to `15`. By default this value is `0.5`. (range .06..15, default 0.5, runtime-tunable)
/// - [chl_in]: Set input channel layout. By default, this is `stereo`.  See channel layout syntax for the required syntax. (range 0..0, default "stereo")
/// - [chl_out]: Set output channel layout. By default, this is `5.1`.  See channel layout syntax for the required syntax. (range 0..0, default "5.1")
/// - [fc_in]: Set front center input volume. By default, this is `1`. (range 0..10, default 1, runtime-tunable)
/// - [fc_out]: Set front center output volume. By default, this is `1`. (range 0..10, default 1, runtime-tunable)
/// - [fcx]: Set spread usage of stereo image across X axis for each channel. Allowed range is from `0.06` to `15`. By default this value is `0.5`. (range .06..15, default 0.5, runtime-tunable)
/// - [fcy]: Set spread usage of stereo image across Y axis for each channel. Allowed range is from `0.06` to `15`. By default this value is `0.5`. (range .06..15, default 0.5, runtime-tunable)
/// - [fl_in]: Set front left input volume. By default, this is `1`. (range 0..10, default 1, runtime-tunable)
/// - [fl_out]: Set front left output volume. By default, this is `1`. (range 0..10, default 1, runtime-tunable)
/// - [flx]: Set spread usage of stereo image across X axis for each channel. Allowed range is from `0.06` to `15`. By default this value is `0.5`. (range .06..15, default 0.5, runtime-tunable)
/// - [fly]: Set spread usage of stereo image across Y axis for each channel. Allowed range is from `0.06` to `15`. By default this value is `0.5`. (range .06..15, default 0.5, runtime-tunable)
/// - [focus]: Set focus of stereo surround transform, Allowed range is from `-1` to `1`. Default is `0`. (range -1..1, default 0, runtime-tunable)
/// - [fr_in]: Set front right input volume. By default, this is `1`. (range 0..10, default 1, runtime-tunable)
/// - [fr_out]: Set front right output volume. By default, this is `1`. (range 0..10, default 1, runtime-tunable)
/// - [frx]: Set spread usage of stereo image across X axis for each channel. Allowed range is from `0.06` to `15`. By default this value is `0.5`. (range .06..15, default 0.5, runtime-tunable)
/// - [fry]: Set spread usage of stereo image across Y axis for each channel. Allowed range is from `0.06` to `15`. By default this value is `0.5`. (range .06..15, default 0.5, runtime-tunable)
/// - [level_in]: Set input volume level. By default, this is `1`. (range 0..10, default 1, runtime-tunable)
/// - [level_out]: Set output volume level. By default, this is `1`. (range 0..10, default 1, runtime-tunable)
/// - [lfe]: Enable LFE channel output if output channel layout has it. By default, this is enabled. (range 0..1, default 1, runtime-tunable)
/// - [lfe_high]: Set LFE high cut off frequency. By default, this is `256` Hz. (range 0..512, default 256)
/// - [lfe_in]: Set LFE input volume. By default, this is `1`. (range 0..10, default 1, runtime-tunable)
/// - [lfe_low]: Set LFE low cut off frequency. By default, this is `128` Hz. (range 0..256, default 128)
/// - [lfe_mode]: Set LFE mode, can be `add` or `sub`. Default is `add`. In `add` mode, LFE channel is created from input audio and added to output. In `sub` mode, LFE channel is created from input audio and added to output but also all non-LFE output channels are subtracted with output LFE channel. (range 0..1, default 0, runtime-tunable)
/// - [lfe_out]: Set LFE output volume. By default, this is `1`. (range 0..10, default 1, runtime-tunable)
/// - [overlap]: set window overlap (range 0..1, default 0.5, runtime-tunable)
/// - [sl_in]: Set side left input volume. By default, this is `1`. (range 0..10, default 1, runtime-tunable)
/// - [sl_out]: Set side left output volume. By default, this is `1`. (range 0..10, default 1, runtime-tunable)
/// - [slx]: Set spread usage of stereo image across X axis for each channel. Allowed range is from `0.06` to `15`. By default this value is `0.5`. (range .06..15, default 0.5, runtime-tunable)
/// - [sly]: Set spread usage of stereo image across Y axis for each channel. Allowed range is from `0.06` to `15`. By default this value is `0.5`. (range .06..15, default 0.5, runtime-tunable)
/// - [smooth]: Set temporal smoothness strength, used to gradually change factors when transforming stereo sound in time. Allowed range is from `0.0` to `1.0`. Useful to improve output quality with `focus` option values greater than `0.0`. Default is `0.0`. Only values inside this range and without edges are effective. (range 0..1, default 0, runtime-tunable)
/// - [sr_in]: Set side right input volume. By default, this is `1`. (range 0..10, default 1, runtime-tunable)
/// - [sr_out]: Set side right output volume. By default, this is `1`. (range 0..10, default 1, runtime-tunable)
/// - [srx]: Set spread usage of stereo image across X axis for each channel. Allowed range is from `0.06` to `15`. By default this value is `0.5`. (range .06..15, default 0.5, runtime-tunable)
/// - [sry]: Set spread usage of stereo image across Y axis for each channel. Allowed range is from `0.06` to `15`. By default this value is `0.5`. (range .06..15, default 0.5, runtime-tunable)
/// - [win_func]: Set window function.  It accepts the following values: (default WFUNC_HANNING)
/// - [win_size]: Set window size. Allowed range is from `1024` to `65536`. Default size is `4096`. (range 1024..65536, default 4096)
final class SurroundSettings {
  /// Default value for [allx].
  static const double allxDefault = -1.0;

  /// Minimum value for [allx].
  static const double allxMin = -1.0;

  /// Maximum value for [allx].
  static const double allxMax = 15.0;

  /// Default value for [ally].
  static const double allyDefault = -1.0;

  /// Minimum value for [ally].
  static const double allyMin = -1.0;

  /// Maximum value for [ally].
  static const double allyMax = 15.0;

  /// Default value for [angle].
  static const double angleDefault = 90.0;

  /// Minimum value for [angle].
  static const double angleMin = 0.0;

  /// Maximum value for [angle].
  static const double angleMax = 360.0;

  /// Default value for [bc_in].
  static const double bc_inDefault = 1.0;

  /// Minimum value for [bc_in].
  static const double bc_inMin = 0.0;

  /// Maximum value for [bc_in].
  static const double bc_inMax = 10.0;

  /// Default value for [bc_out].
  static const double bc_outDefault = 1.0;

  /// Minimum value for [bc_out].
  static const double bc_outMin = 0.0;

  /// Maximum value for [bc_out].
  static const double bc_outMax = 10.0;

  /// Default value for [bcx].
  static const double bcxDefault = 0.5;

  /// Minimum value for [bcx].
  static const double bcxMin = .06;

  /// Maximum value for [bcx].
  static const double bcxMax = 15.0;

  /// Default value for [bcy].
  static const double bcyDefault = 0.5;

  /// Minimum value for [bcy].
  static const double bcyMin = .06;

  /// Maximum value for [bcy].
  static const double bcyMax = 15.0;

  /// Default value for [bl_in].
  static const double bl_inDefault = 1.0;

  /// Minimum value for [bl_in].
  static const double bl_inMin = 0.0;

  /// Maximum value for [bl_in].
  static const double bl_inMax = 10.0;

  /// Default value for [bl_out].
  static const double bl_outDefault = 1.0;

  /// Minimum value for [bl_out].
  static const double bl_outMin = 0.0;

  /// Maximum value for [bl_out].
  static const double bl_outMax = 10.0;

  /// Default value for [blx].
  static const double blxDefault = 0.5;

  /// Minimum value for [blx].
  static const double blxMin = .06;

  /// Maximum value for [blx].
  static const double blxMax = 15.0;

  /// Default value for [bly].
  static const double blyDefault = 0.5;

  /// Minimum value for [bly].
  static const double blyMin = .06;

  /// Maximum value for [bly].
  static const double blyMax = 15.0;

  /// Default value for [br_in].
  static const double br_inDefault = 1.0;

  /// Minimum value for [br_in].
  static const double br_inMin = 0.0;

  /// Maximum value for [br_in].
  static const double br_inMax = 10.0;

  /// Default value for [br_out].
  static const double br_outDefault = 1.0;

  /// Minimum value for [br_out].
  static const double br_outMin = 0.0;

  /// Maximum value for [br_out].
  static const double br_outMax = 10.0;

  /// Default value for [brx].
  static const double brxDefault = 0.5;

  /// Minimum value for [brx].
  static const double brxMin = .06;

  /// Maximum value for [brx].
  static const double brxMax = 15.0;

  /// Default value for [bry].
  static const double bryDefault = 0.5;

  /// Minimum value for [bry].
  static const double bryMin = .06;

  /// Maximum value for [bry].
  static const double bryMax = 15.0;

  /// Default value for [fc_in].
  static const double fc_inDefault = 1.0;

  /// Minimum value for [fc_in].
  static const double fc_inMin = 0.0;

  /// Maximum value for [fc_in].
  static const double fc_inMax = 10.0;

  /// Default value for [fc_out].
  static const double fc_outDefault = 1.0;

  /// Minimum value for [fc_out].
  static const double fc_outMin = 0.0;

  /// Maximum value for [fc_out].
  static const double fc_outMax = 10.0;

  /// Default value for [fcx].
  static const double fcxDefault = 0.5;

  /// Minimum value for [fcx].
  static const double fcxMin = .06;

  /// Maximum value for [fcx].
  static const double fcxMax = 15.0;

  /// Default value for [fcy].
  static const double fcyDefault = 0.5;

  /// Minimum value for [fcy].
  static const double fcyMin = .06;

  /// Maximum value for [fcy].
  static const double fcyMax = 15.0;

  /// Default value for [fl_in].
  static const double fl_inDefault = 1.0;

  /// Minimum value for [fl_in].
  static const double fl_inMin = 0.0;

  /// Maximum value for [fl_in].
  static const double fl_inMax = 10.0;

  /// Default value for [fl_out].
  static const double fl_outDefault = 1.0;

  /// Minimum value for [fl_out].
  static const double fl_outMin = 0.0;

  /// Maximum value for [fl_out].
  static const double fl_outMax = 10.0;

  /// Default value for [flx].
  static const double flxDefault = 0.5;

  /// Minimum value for [flx].
  static const double flxMin = .06;

  /// Maximum value for [flx].
  static const double flxMax = 15.0;

  /// Default value for [fly].
  static const double flyDefault = 0.5;

  /// Minimum value for [fly].
  static const double flyMin = .06;

  /// Maximum value for [fly].
  static const double flyMax = 15.0;

  /// Default value for [focus].
  static const double focusDefault = 0.0;

  /// Minimum value for [focus].
  static const double focusMin = -1.0;

  /// Maximum value for [focus].
  static const double focusMax = 1.0;

  /// Default value for [fr_in].
  static const double fr_inDefault = 1.0;

  /// Minimum value for [fr_in].
  static const double fr_inMin = 0.0;

  /// Maximum value for [fr_in].
  static const double fr_inMax = 10.0;

  /// Default value for [fr_out].
  static const double fr_outDefault = 1.0;

  /// Minimum value for [fr_out].
  static const double fr_outMin = 0.0;

  /// Maximum value for [fr_out].
  static const double fr_outMax = 10.0;

  /// Default value for [frx].
  static const double frxDefault = 0.5;

  /// Minimum value for [frx].
  static const double frxMin = .06;

  /// Maximum value for [frx].
  static const double frxMax = 15.0;

  /// Default value for [fry].
  static const double fryDefault = 0.5;

  /// Minimum value for [fry].
  static const double fryMin = .06;

  /// Maximum value for [fry].
  static const double fryMax = 15.0;

  /// Default value for [level_in].
  static const double level_inDefault = 1.0;

  /// Minimum value for [level_in].
  static const double level_inMin = 0.0;

  /// Maximum value for [level_in].
  static const double level_inMax = 10.0;

  /// Default value for [level_out].
  static const double level_outDefault = 1.0;

  /// Minimum value for [level_out].
  static const double level_outMin = 0.0;

  /// Maximum value for [level_out].
  static const double level_outMax = 10.0;

  /// Default value for [lfe_high].
  static const int lfe_highDefault = 256;

  /// Minimum value for [lfe_high].
  static const int lfe_highMin = 0;

  /// Maximum value for [lfe_high].
  static const int lfe_highMax = 512;

  /// Default value for [lfe_in].
  static const double lfe_inDefault = 1.0;

  /// Minimum value for [lfe_in].
  static const double lfe_inMin = 0.0;

  /// Maximum value for [lfe_in].
  static const double lfe_inMax = 10.0;

  /// Default value for [lfe_low].
  static const int lfe_lowDefault = 128;

  /// Minimum value for [lfe_low].
  static const int lfe_lowMin = 0;

  /// Maximum value for [lfe_low].
  static const int lfe_lowMax = 256;

  /// Default value for [lfe_out].
  static const double lfe_outDefault = 1.0;

  /// Minimum value for [lfe_out].
  static const double lfe_outMin = 0.0;

  /// Maximum value for [lfe_out].
  static const double lfe_outMax = 10.0;

  /// Default value for [overlap].
  static const double overlapDefault = 0.5;

  /// Minimum value for [overlap].
  static const double overlapMin = 0.0;

  /// Maximum value for [overlap].
  static const double overlapMax = 1.0;

  /// Default value for [sl_in].
  static const double sl_inDefault = 1.0;

  /// Minimum value for [sl_in].
  static const double sl_inMin = 0.0;

  /// Maximum value for [sl_in].
  static const double sl_inMax = 10.0;

  /// Default value for [sl_out].
  static const double sl_outDefault = 1.0;

  /// Minimum value for [sl_out].
  static const double sl_outMin = 0.0;

  /// Maximum value for [sl_out].
  static const double sl_outMax = 10.0;

  /// Default value for [slx].
  static const double slxDefault = 0.5;

  /// Minimum value for [slx].
  static const double slxMin = .06;

  /// Maximum value for [slx].
  static const double slxMax = 15.0;

  /// Default value for [sly].
  static const double slyDefault = 0.5;

  /// Minimum value for [sly].
  static const double slyMin = .06;

  /// Maximum value for [sly].
  static const double slyMax = 15.0;

  /// Default value for [smooth].
  static const double smoothDefault = 0.0;

  /// Minimum value for [smooth].
  static const double smoothMin = 0.0;

  /// Maximum value for [smooth].
  static const double smoothMax = 1.0;

  /// Default value for [sr_in].
  static const double sr_inDefault = 1.0;

  /// Minimum value for [sr_in].
  static const double sr_inMin = 0.0;

  /// Maximum value for [sr_in].
  static const double sr_inMax = 10.0;

  /// Default value for [sr_out].
  static const double sr_outDefault = 1.0;

  /// Minimum value for [sr_out].
  static const double sr_outMin = 0.0;

  /// Maximum value for [sr_out].
  static const double sr_outMax = 10.0;

  /// Default value for [srx].
  static const double srxDefault = 0.5;

  /// Minimum value for [srx].
  static const double srxMin = .06;

  /// Maximum value for [srx].
  static const double srxMax = 15.0;

  /// Default value for [sry].
  static const double sryDefault = 0.5;

  /// Minimum value for [sry].
  static const double sryMin = .06;

  /// Maximum value for [sry].
  static const double sryMax = 15.0;

  /// Default value for [win_size].
  static const int win_sizeDefault = 4096;

  /// Minimum value for [win_size].
  static const int win_sizeMin = 1024;

  /// Maximum value for [win_size].
  static const int win_sizeMax = 65536;

  /// Whether this effect is inserted into the audio chain.
  final bool enabled;

  /// set all channel's x spread
  final double allx;

  /// set all channel's y spread
  final double ally;

  /// set soundfield transform angle
  final double angle;

  /// set back center channel input level
  final double bc_in;

  /// set back center channel output level
  final double bc_out;

  /// set back center channel x spread
  final double bcx;

  /// set back center channel y spread
  final double bcy;

  /// set back left channel input level
  final double bl_in;

  /// set back left channel output level
  final double bl_out;

  /// set back left channel x spread
  final double blx;

  /// set back left channel y spread
  final double bly;

  /// set back right channel input level
  final double br_in;

  /// set back right channel output level
  final double br_out;

  /// set back right channel x spread
  final double brx;

  /// set back right channel y spread
  final double bry;

  /// set input channel layout
  final String chl_in;

  /// set output channel layout
  final String chl_out;

  /// set front center channel input level
  final double fc_in;

  /// set front center channel output level
  final double fc_out;

  /// set front center channel x spread
  final double fcx;

  /// set front center channel y spread
  final double fcy;

  /// set front left channel input level
  final double fl_in;

  /// set front left channel output level
  final double fl_out;

  /// set front left channel x spread
  final double flx;

  /// set front left channel y spread
  final double fly;

  /// set soundfield transform focus
  final double focus;

  /// set front right channel input level
  final double fr_in;

  /// set front right channel output level
  final double fr_out;

  /// set front right channel x spread
  final double frx;

  /// set front right channel y spread
  final double fry;

  /// set input level
  final double level_in;

  /// set output level
  final double level_out;

  /// output LFE
  final bool lfe;

  /// LFE high cut off
  final int lfe_high;

  /// set lfe channel input level
  final double lfe_in;

  /// LFE low cut off
  final int lfe_low;

  /// set LFE channel mode
  final SurroundLfeMode lfe_mode;

  /// set lfe channel output level
  final double lfe_out;

  /// set window overlap
  final double overlap;

  /// set side left channel input level
  final double sl_in;

  /// set side left channel output level
  final double sl_out;

  /// set side left channel x spread
  final double slx;

  /// set side left channel y spread
  final double sly;

  /// set temporal smoothness strength
  final double smooth;

  /// set side right channel input level
  final double sr_in;

  /// set side right channel output level
  final double sr_out;

  /// set side right channel x spread
  final double srx;

  /// set side right channel y spread
  final double sry;

  /// set window function
  final SurroundWinFunc win_func;

  /// set window size
  final int win_size;

  /// Creates an [SurroundSettings] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default; the effect stays
  /// inactive until [enabled] is set to `true`.
  const SurroundSettings({
    this.enabled = false,
    this.allx = -1.0,
    this.ally = -1.0,
    this.angle = 90.0,
    this.bc_in = 1.0,
    this.bc_out = 1.0,
    this.bcx = 0.5,
    this.bcy = 0.5,
    this.bl_in = 1.0,
    this.bl_out = 1.0,
    this.blx = 0.5,
    this.bly = 0.5,
    this.br_in = 1.0,
    this.br_out = 1.0,
    this.brx = 0.5,
    this.bry = 0.5,
    this.chl_in = 'stereo',
    this.chl_out = '5.1',
    this.fc_in = 1.0,
    this.fc_out = 1.0,
    this.fcx = 0.5,
    this.fcy = 0.5,
    this.fl_in = 1.0,
    this.fl_out = 1.0,
    this.flx = 0.5,
    this.fly = 0.5,
    this.focus = 0.0,
    this.fr_in = 1.0,
    this.fr_out = 1.0,
    this.frx = 0.5,
    this.fry = 0.5,
    this.level_in = 1.0,
    this.level_out = 1.0,
    this.lfe = true,
    this.lfe_high = 256,
    this.lfe_in = 1.0,
    this.lfe_low = 128,
    this.lfe_mode = SurroundLfeMode.add,
    this.lfe_out = 1.0,
    this.overlap = 0.5,
    this.sl_in = 1.0,
    this.sl_out = 1.0,
    this.slx = 0.5,
    this.sly = 0.5,
    this.smooth = 0.0,
    this.sr_in = 1.0,
    this.sr_out = 1.0,
    this.srx = 0.5,
    this.sry = 0.5,
    this.win_func = SurroundWinFunc.hann,
    this.win_size = 4096,
  });

  /// Returns a copy of this [SurroundSettings] with the given fields replaced.
  SurroundSettings copyWith({
    bool? enabled,
    double? allx,
    double? ally,
    double? angle,
    double? bc_in,
    double? bc_out,
    double? bcx,
    double? bcy,
    double? bl_in,
    double? bl_out,
    double? blx,
    double? bly,
    double? br_in,
    double? br_out,
    double? brx,
    double? bry,
    String? chl_in,
    String? chl_out,
    double? fc_in,
    double? fc_out,
    double? fcx,
    double? fcy,
    double? fl_in,
    double? fl_out,
    double? flx,
    double? fly,
    double? focus,
    double? fr_in,
    double? fr_out,
    double? frx,
    double? fry,
    double? level_in,
    double? level_out,
    bool? lfe,
    int? lfe_high,
    double? lfe_in,
    int? lfe_low,
    SurroundLfeMode? lfe_mode,
    double? lfe_out,
    double? overlap,
    double? sl_in,
    double? sl_out,
    double? slx,
    double? sly,
    double? smooth,
    double? sr_in,
    double? sr_out,
    double? srx,
    double? sry,
    SurroundWinFunc? win_func,
    int? win_size,
  }) =>
      SurroundSettings(
        enabled: enabled ?? this.enabled,
        allx: allx ?? this.allx,
        ally: ally ?? this.ally,
        angle: angle ?? this.angle,
        bc_in: bc_in ?? this.bc_in,
        bc_out: bc_out ?? this.bc_out,
        bcx: bcx ?? this.bcx,
        bcy: bcy ?? this.bcy,
        bl_in: bl_in ?? this.bl_in,
        bl_out: bl_out ?? this.bl_out,
        blx: blx ?? this.blx,
        bly: bly ?? this.bly,
        br_in: br_in ?? this.br_in,
        br_out: br_out ?? this.br_out,
        brx: brx ?? this.brx,
        bry: bry ?? this.bry,
        chl_in: chl_in ?? this.chl_in,
        chl_out: chl_out ?? this.chl_out,
        fc_in: fc_in ?? this.fc_in,
        fc_out: fc_out ?? this.fc_out,
        fcx: fcx ?? this.fcx,
        fcy: fcy ?? this.fcy,
        fl_in: fl_in ?? this.fl_in,
        fl_out: fl_out ?? this.fl_out,
        flx: flx ?? this.flx,
        fly: fly ?? this.fly,
        focus: focus ?? this.focus,
        fr_in: fr_in ?? this.fr_in,
        fr_out: fr_out ?? this.fr_out,
        frx: frx ?? this.frx,
        fry: fry ?? this.fry,
        level_in: level_in ?? this.level_in,
        level_out: level_out ?? this.level_out,
        lfe: lfe ?? this.lfe,
        lfe_high: lfe_high ?? this.lfe_high,
        lfe_in: lfe_in ?? this.lfe_in,
        lfe_low: lfe_low ?? this.lfe_low,
        lfe_mode: lfe_mode ?? this.lfe_mode,
        lfe_out: lfe_out ?? this.lfe_out,
        overlap: overlap ?? this.overlap,
        sl_in: sl_in ?? this.sl_in,
        sl_out: sl_out ?? this.sl_out,
        slx: slx ?? this.slx,
        sly: sly ?? this.sly,
        smooth: smooth ?? this.smooth,
        sr_in: sr_in ?? this.sr_in,
        sr_out: sr_out ?? this.sr_out,
        srx: srx ?? this.srx,
        sry: sry ?? this.sry,
        win_func: win_func ?? this.win_func,
        win_size: win_size ?? this.win_size,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SurroundSettings &&
          other.enabled == enabled &&
          other.allx == allx &&
          other.ally == ally &&
          other.angle == angle &&
          other.bc_in == bc_in &&
          other.bc_out == bc_out &&
          other.bcx == bcx &&
          other.bcy == bcy &&
          other.bl_in == bl_in &&
          other.bl_out == bl_out &&
          other.blx == blx &&
          other.bly == bly &&
          other.br_in == br_in &&
          other.br_out == br_out &&
          other.brx == brx &&
          other.bry == bry &&
          other.chl_in == chl_in &&
          other.chl_out == chl_out &&
          other.fc_in == fc_in &&
          other.fc_out == fc_out &&
          other.fcx == fcx &&
          other.fcy == fcy &&
          other.fl_in == fl_in &&
          other.fl_out == fl_out &&
          other.flx == flx &&
          other.fly == fly &&
          other.focus == focus &&
          other.fr_in == fr_in &&
          other.fr_out == fr_out &&
          other.frx == frx &&
          other.fry == fry &&
          other.level_in == level_in &&
          other.level_out == level_out &&
          other.lfe == lfe &&
          other.lfe_high == lfe_high &&
          other.lfe_in == lfe_in &&
          other.lfe_low == lfe_low &&
          other.lfe_mode == lfe_mode &&
          other.lfe_out == lfe_out &&
          other.overlap == overlap &&
          other.sl_in == sl_in &&
          other.sl_out == sl_out &&
          other.slx == slx &&
          other.sly == sly &&
          other.smooth == smooth &&
          other.sr_in == sr_in &&
          other.sr_out == sr_out &&
          other.srx == srx &&
          other.sry == sry &&
          other.win_func == win_func &&
          other.win_size == win_size);

  @override
  int get hashCode => Object.hashAll([
        enabled,
        allx,
        ally,
        angle,
        bc_in,
        bc_out,
        bcx,
        bcy,
        bl_in,
        bl_out,
        blx,
        bly,
        br_in,
        br_out,
        brx,
        bry,
        chl_in,
        chl_out,
        fc_in,
        fc_out,
        fcx,
        fcy,
        fl_in,
        fl_out,
        flx,
        fly,
        focus,
        fr_in,
        fr_out,
        frx,
        fry,
        level_in,
        level_out,
        lfe,
        lfe_high,
        lfe_in,
        lfe_low,
        lfe_mode,
        lfe_out,
        overlap,
        sl_in,
        sl_out,
        slx,
        sly,
        smooth,
        sr_in,
        sr_out,
        srx,
        sry,
        win_func,
        win_size,
      ]);

  @override
  String toString() =>
      'SurroundSettings(enabled: $enabled, allx: $allx, ally: $ally, angle: $angle, bc_in: $bc_in, bc_out: $bc_out, bcx: $bcx, bcy: $bcy, bl_in: $bl_in, bl_out: $bl_out, blx: $blx, bly: $bly, br_in: $br_in, br_out: $br_out, brx: $brx, bry: $bry, chl_in: $chl_in, chl_out: $chl_out, fc_in: $fc_in, fc_out: $fc_out, fcx: $fcx, fcy: $fcy, fl_in: $fl_in, fl_out: $fl_out, flx: $flx, fly: $fly, focus: $focus, fr_in: $fr_in, fr_out: $fr_out, frx: $frx, fry: $fry, level_in: $level_in, level_out: $level_out, lfe: $lfe, lfe_high: $lfe_high, lfe_in: $lfe_in, lfe_low: $lfe_low, lfe_mode: $lfe_mode, lfe_out: $lfe_out, overlap: $overlap, sl_in: $sl_in, sl_out: $sl_out, slx: $slx, sly: $sly, smooth: $smooth, sr_in: $sr_in, sr_out: $sr_out, srx: $srx, sry: $sry, win_func: $win_func, win_size: $win_size)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(allx >= allxMin, 'surround.allx must be >= -1');
    assert(allx <= allxMax, 'surround.allx must be <= 15');
    assert(ally >= allyMin, 'surround.ally must be >= -1');
    assert(ally <= allyMax, 'surround.ally must be <= 15');
    assert(angle >= angleMin, 'surround.angle must be >= 0');
    assert(angle <= angleMax, 'surround.angle must be <= 360');
    assert(bc_in >= bc_inMin, 'surround.bc_in must be >= 0');
    assert(bc_in <= bc_inMax, 'surround.bc_in must be <= 10');
    assert(bc_out >= bc_outMin, 'surround.bc_out must be >= 0');
    assert(bc_out <= bc_outMax, 'surround.bc_out must be <= 10');
    assert(bcx >= bcxMin, 'surround.bcx must be >= .06');
    assert(bcx <= bcxMax, 'surround.bcx must be <= 15');
    assert(bcy >= bcyMin, 'surround.bcy must be >= .06');
    assert(bcy <= bcyMax, 'surround.bcy must be <= 15');
    assert(bl_in >= bl_inMin, 'surround.bl_in must be >= 0');
    assert(bl_in <= bl_inMax, 'surround.bl_in must be <= 10');
    assert(bl_out >= bl_outMin, 'surround.bl_out must be >= 0');
    assert(bl_out <= bl_outMax, 'surround.bl_out must be <= 10');
    assert(blx >= blxMin, 'surround.blx must be >= .06');
    assert(blx <= blxMax, 'surround.blx must be <= 15');
    assert(bly >= blyMin, 'surround.bly must be >= .06');
    assert(bly <= blyMax, 'surround.bly must be <= 15');
    assert(br_in >= br_inMin, 'surround.br_in must be >= 0');
    assert(br_in <= br_inMax, 'surround.br_in must be <= 10');
    assert(br_out >= br_outMin, 'surround.br_out must be >= 0');
    assert(br_out <= br_outMax, 'surround.br_out must be <= 10');
    assert(brx >= brxMin, 'surround.brx must be >= .06');
    assert(brx <= brxMax, 'surround.brx must be <= 15');
    assert(bry >= bryMin, 'surround.bry must be >= .06');
    assert(bry <= bryMax, 'surround.bry must be <= 15');
    assert(fc_in >= fc_inMin, 'surround.fc_in must be >= 0');
    assert(fc_in <= fc_inMax, 'surround.fc_in must be <= 10');
    assert(fc_out >= fc_outMin, 'surround.fc_out must be >= 0');
    assert(fc_out <= fc_outMax, 'surround.fc_out must be <= 10');
    assert(fcx >= fcxMin, 'surround.fcx must be >= .06');
    assert(fcx <= fcxMax, 'surround.fcx must be <= 15');
    assert(fcy >= fcyMin, 'surround.fcy must be >= .06');
    assert(fcy <= fcyMax, 'surround.fcy must be <= 15');
    assert(fl_in >= fl_inMin, 'surround.fl_in must be >= 0');
    assert(fl_in <= fl_inMax, 'surround.fl_in must be <= 10');
    assert(fl_out >= fl_outMin, 'surround.fl_out must be >= 0');
    assert(fl_out <= fl_outMax, 'surround.fl_out must be <= 10');
    assert(flx >= flxMin, 'surround.flx must be >= .06');
    assert(flx <= flxMax, 'surround.flx must be <= 15');
    assert(fly >= flyMin, 'surround.fly must be >= .06');
    assert(fly <= flyMax, 'surround.fly must be <= 15');
    assert(focus >= focusMin, 'surround.focus must be >= -1');
    assert(focus <= focusMax, 'surround.focus must be <= 1');
    assert(fr_in >= fr_inMin, 'surround.fr_in must be >= 0');
    assert(fr_in <= fr_inMax, 'surround.fr_in must be <= 10');
    assert(fr_out >= fr_outMin, 'surround.fr_out must be >= 0');
    assert(fr_out <= fr_outMax, 'surround.fr_out must be <= 10');
    assert(frx >= frxMin, 'surround.frx must be >= .06');
    assert(frx <= frxMax, 'surround.frx must be <= 15');
    assert(fry >= fryMin, 'surround.fry must be >= .06');
    assert(fry <= fryMax, 'surround.fry must be <= 15');
    assert(level_in >= level_inMin, 'surround.level_in must be >= 0');
    assert(level_in <= level_inMax, 'surround.level_in must be <= 10');
    assert(level_out >= level_outMin, 'surround.level_out must be >= 0');
    assert(level_out <= level_outMax, 'surround.level_out must be <= 10');
    assert(lfe_high >= lfe_highMin, 'surround.lfe_high must be >= 0');
    assert(lfe_high <= lfe_highMax, 'surround.lfe_high must be <= 512');
    assert(lfe_in >= lfe_inMin, 'surround.lfe_in must be >= 0');
    assert(lfe_in <= lfe_inMax, 'surround.lfe_in must be <= 10');
    assert(lfe_low >= lfe_lowMin, 'surround.lfe_low must be >= 0');
    assert(lfe_low <= lfe_lowMax, 'surround.lfe_low must be <= 256');
    assert(lfe_out >= lfe_outMin, 'surround.lfe_out must be >= 0');
    assert(lfe_out <= lfe_outMax, 'surround.lfe_out must be <= 10');
    assert(overlap >= overlapMin, 'surround.overlap must be >= 0');
    assert(overlap <= overlapMax, 'surround.overlap must be <= 1');
    assert(sl_in >= sl_inMin, 'surround.sl_in must be >= 0');
    assert(sl_in <= sl_inMax, 'surround.sl_in must be <= 10');
    assert(sl_out >= sl_outMin, 'surround.sl_out must be >= 0');
    assert(sl_out <= sl_outMax, 'surround.sl_out must be <= 10');
    assert(slx >= slxMin, 'surround.slx must be >= .06');
    assert(slx <= slxMax, 'surround.slx must be <= 15');
    assert(sly >= slyMin, 'surround.sly must be >= .06');
    assert(sly <= slyMax, 'surround.sly must be <= 15');
    assert(smooth >= smoothMin, 'surround.smooth must be >= 0');
    assert(smooth <= smoothMax, 'surround.smooth must be <= 1');
    assert(sr_in >= sr_inMin, 'surround.sr_in must be >= 0');
    assert(sr_in <= sr_inMax, 'surround.sr_in must be <= 10');
    assert(sr_out >= sr_outMin, 'surround.sr_out must be >= 0');
    assert(sr_out <= sr_outMax, 'surround.sr_out must be <= 10');
    assert(srx >= srxMin, 'surround.srx must be >= .06');
    assert(srx <= srxMax, 'surround.srx must be <= 15');
    assert(sry >= sryMin, 'surround.sry must be >= .06');
    assert(sry <= sryMax, 'surround.sry must be <= 15');
    assert(win_size >= win_sizeMin, 'surround.win_size must be >= 1024');
    assert(win_size <= win_sizeMax, 'surround.win_size must be <= 65536');
    final parts = <String>[];
    if (allx != -1.0) parts.add('allx=' + _wireDouble(allx));
    if (ally != -1.0) parts.add('ally=' + _wireDouble(ally));
    if (angle != 90.0) parts.add('angle=' + _wireDouble(angle));
    if (bc_in != 1.0) parts.add('bc_in=' + _wireDouble(bc_in));
    if (bc_out != 1.0) parts.add('bc_out=' + _wireDouble(bc_out));
    if (bcx != 0.5) parts.add('bcx=' + _wireDouble(bcx));
    if (bcy != 0.5) parts.add('bcy=' + _wireDouble(bcy));
    if (bl_in != 1.0) parts.add('bl_in=' + _wireDouble(bl_in));
    if (bl_out != 1.0) parts.add('bl_out=' + _wireDouble(bl_out));
    if (blx != 0.5) parts.add('blx=' + _wireDouble(blx));
    if (bly != 0.5) parts.add('bly=' + _wireDouble(bly));
    if (br_in != 1.0) parts.add('br_in=' + _wireDouble(br_in));
    if (br_out != 1.0) parts.add('br_out=' + _wireDouble(br_out));
    if (brx != 0.5) parts.add('brx=' + _wireDouble(brx));
    if (bry != 0.5) parts.add('bry=' + _wireDouble(bry));
    if (chl_in != 'stereo') parts.add('chl_in=' + '[' + chl_in + ']');
    if (chl_out != '5.1') parts.add('chl_out=' + '[' + chl_out + ']');
    if (fc_in != 1.0) parts.add('fc_in=' + _wireDouble(fc_in));
    if (fc_out != 1.0) parts.add('fc_out=' + _wireDouble(fc_out));
    if (fcx != 0.5) parts.add('fcx=' + _wireDouble(fcx));
    if (fcy != 0.5) parts.add('fcy=' + _wireDouble(fcy));
    if (fl_in != 1.0) parts.add('fl_in=' + _wireDouble(fl_in));
    if (fl_out != 1.0) parts.add('fl_out=' + _wireDouble(fl_out));
    if (flx != 0.5) parts.add('flx=' + _wireDouble(flx));
    if (fly != 0.5) parts.add('fly=' + _wireDouble(fly));
    if (focus != 0.0) parts.add('focus=' + _wireDouble(focus));
    if (fr_in != 1.0) parts.add('fr_in=' + _wireDouble(fr_in));
    if (fr_out != 1.0) parts.add('fr_out=' + _wireDouble(fr_out));
    if (frx != 0.5) parts.add('frx=' + _wireDouble(frx));
    if (fry != 0.5) parts.add('fry=' + _wireDouble(fry));
    if (level_in != 1.0) parts.add('level_in=' + _wireDouble(level_in));
    if (level_out != 1.0) parts.add('level_out=' + _wireDouble(level_out));
    if (lfe != true) parts.add('lfe=' + (lfe ? '1' : '0'));
    if (lfe_high != 256) parts.add('lfe_high=' + lfe_high.toString());
    if (lfe_in != 1.0) parts.add('lfe_in=' + _wireDouble(lfe_in));
    if (lfe_low != 128) parts.add('lfe_low=' + lfe_low.toString());
    if (lfe_mode != SurroundLfeMode.add)
      parts.add('lfe_mode=' + lfe_mode.mpvValue);
    if (lfe_out != 1.0) parts.add('lfe_out=' + _wireDouble(lfe_out));
    if (overlap != 0.5) parts.add('overlap=' + _wireDouble(overlap));
    if (sl_in != 1.0) parts.add('sl_in=' + _wireDouble(sl_in));
    if (sl_out != 1.0) parts.add('sl_out=' + _wireDouble(sl_out));
    if (slx != 0.5) parts.add('slx=' + _wireDouble(slx));
    if (sly != 0.5) parts.add('sly=' + _wireDouble(sly));
    if (smooth != 0.0) parts.add('smooth=' + _wireDouble(smooth));
    if (sr_in != 1.0) parts.add('sr_in=' + _wireDouble(sr_in));
    if (sr_out != 1.0) parts.add('sr_out=' + _wireDouble(sr_out));
    if (srx != 0.5) parts.add('srx=' + _wireDouble(srx));
    if (sry != 0.5) parts.add('sry=' + _wireDouble(sry));
    if (win_func != SurroundWinFunc.hann)
      parts.add('win_func=' + win_func.mpvValue);
    if (win_size != 4096) parts.add('win_size=' + win_size.toString());
    return parts.isEmpty
        ? 'lavfi-surround'
        : 'lavfi-surround=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  List<(String, String)>? _runtimeDiff(SurroundSettings prev) {
    final out = <(String, String)>[];
    if (allx != prev.allx) {
      out.add(('allx', _wireDouble(allx)));
    }
    if (ally != prev.ally) {
      out.add(('ally', _wireDouble(ally)));
    }
    if (angle != prev.angle) {
      out.add(('angle', _wireDouble(angle)));
    }
    if (bc_in != prev.bc_in) {
      out.add(('bc_in', _wireDouble(bc_in)));
    }
    if (bc_out != prev.bc_out) {
      out.add(('bc_out', _wireDouble(bc_out)));
    }
    if (bcx != prev.bcx) {
      out.add(('bcx', _wireDouble(bcx)));
    }
    if (bcy != prev.bcy) {
      out.add(('bcy', _wireDouble(bcy)));
    }
    if (bl_in != prev.bl_in) {
      out.add(('bl_in', _wireDouble(bl_in)));
    }
    if (bl_out != prev.bl_out) {
      out.add(('bl_out', _wireDouble(bl_out)));
    }
    if (blx != prev.blx) {
      out.add(('blx', _wireDouble(blx)));
    }
    if (bly != prev.bly) {
      out.add(('bly', _wireDouble(bly)));
    }
    if (br_in != prev.br_in) {
      out.add(('br_in', _wireDouble(br_in)));
    }
    if (br_out != prev.br_out) {
      out.add(('br_out', _wireDouble(br_out)));
    }
    if (brx != prev.brx) {
      out.add(('brx', _wireDouble(brx)));
    }
    if (bry != prev.bry) {
      out.add(('bry', _wireDouble(bry)));
    }
    if (chl_in != prev.chl_in) return null;
    if (chl_out != prev.chl_out) return null;
    if (fc_in != prev.fc_in) {
      out.add(('fc_in', _wireDouble(fc_in)));
    }
    if (fc_out != prev.fc_out) {
      out.add(('fc_out', _wireDouble(fc_out)));
    }
    if (fcx != prev.fcx) {
      out.add(('fcx', _wireDouble(fcx)));
    }
    if (fcy != prev.fcy) {
      out.add(('fcy', _wireDouble(fcy)));
    }
    if (fl_in != prev.fl_in) {
      out.add(('fl_in', _wireDouble(fl_in)));
    }
    if (fl_out != prev.fl_out) {
      out.add(('fl_out', _wireDouble(fl_out)));
    }
    if (flx != prev.flx) {
      out.add(('flx', _wireDouble(flx)));
    }
    if (fly != prev.fly) {
      out.add(('fly', _wireDouble(fly)));
    }
    if (focus != prev.focus) {
      out.add(('focus', _wireDouble(focus)));
    }
    if (fr_in != prev.fr_in) {
      out.add(('fr_in', _wireDouble(fr_in)));
    }
    if (fr_out != prev.fr_out) {
      out.add(('fr_out', _wireDouble(fr_out)));
    }
    if (frx != prev.frx) {
      out.add(('frx', _wireDouble(frx)));
    }
    if (fry != prev.fry) {
      out.add(('fry', _wireDouble(fry)));
    }
    if (level_in != prev.level_in) {
      out.add(('level_in', _wireDouble(level_in)));
    }
    if (level_out != prev.level_out) {
      out.add(('level_out', _wireDouble(level_out)));
    }
    if (lfe != prev.lfe) {
      out.add(('lfe', (lfe ? '1' : '0')));
    }
    if (lfe_high != prev.lfe_high) return null;
    if (lfe_in != prev.lfe_in) {
      out.add(('lfe_in', _wireDouble(lfe_in)));
    }
    if (lfe_low != prev.lfe_low) return null;
    if (lfe_mode != prev.lfe_mode) {
      out.add(('lfe_mode', lfe_mode.mpvValue));
    }
    if (lfe_out != prev.lfe_out) {
      out.add(('lfe_out', _wireDouble(lfe_out)));
    }
    if (overlap != prev.overlap) {
      out.add(('overlap', _wireDouble(overlap)));
    }
    if (sl_in != prev.sl_in) {
      out.add(('sl_in', _wireDouble(sl_in)));
    }
    if (sl_out != prev.sl_out) {
      out.add(('sl_out', _wireDouble(sl_out)));
    }
    if (slx != prev.slx) {
      out.add(('slx', _wireDouble(slx)));
    }
    if (sly != prev.sly) {
      out.add(('sly', _wireDouble(sly)));
    }
    if (smooth != prev.smooth) {
      out.add(('smooth', _wireDouble(smooth)));
    }
    if (sr_in != prev.sr_in) {
      out.add(('sr_in', _wireDouble(sr_in)));
    }
    if (sr_out != prev.sr_out) {
      out.add(('sr_out', _wireDouble(sr_out)));
    }
    if (srx != prev.srx) {
      out.add(('srx', _wireDouble(srx)));
    }
    if (sry != prev.sry) {
      out.add(('sry', _wireDouble(sry)));
    }
    if (win_func != prev.win_func) return null;
    if (win_size != prev.win_size) return null;
    return out;
  }
}

/// Configuration for the `tiltshelf` audio effect.
///
/// Boost or cut the lower frequencies and cut or boost higher frequencies
/// of the audio using a two-pole shelving filter with a response similar to
/// that of a standard hi-fi's tone-controls.
/// This is also known as shelving equalisation (EQ).
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [a]: Set transform type of IIR filter. (range 0..6, default DI)
/// - [b]: Set block size used for reverse IIR processing. If this value is set to high enough value (higher than impulse response length truncated when reaches near zero values) filtering will become linear phase otherwise if not big enough it will just produce nasty artifacts.  Note that filter delay will be exactly this many samples when set to non-zero value. (range 0..32768, default 0)
/// - [blocksize]: set the block size (range 0..32768, default 0)
/// - [c]: Specify which channels to filter, by default all available are filtered. (range 0..0, default "all", runtime-tunable)
/// - [channels]: Specify which channels to filter, by default all available are filtered. (range 0..0, default "all", runtime-tunable)
/// - [f]: Set the filter's central frequency and so can be used to extend or reduce the frequency range to be boosted or cut. The default value is `3000` Hz. (range 0..999999, default 3000, runtime-tunable)
/// - [frequency]: Set the filter's central frequency and so can be used to extend or reduce the frequency range to be boosted or cut. The default value is `3000` Hz. (range 0..999999, default 3000, runtime-tunable)
/// - [g]: Give the gain at 0 Hz. Its useful range is about -20 (for a large cut) to +20 (for a large boost). Beware of clipping when using a positive gain. (range -900..900, default 0, runtime-tunable)
/// - [gain]: Give the gain at 0 Hz. Its useful range is about -20 (for a large cut) to +20 (for a large boost). Beware of clipping when using a positive gain. (range -900..900, default 0, runtime-tunable)
/// - [m]: How much to use filtered signal in output. Default is 1. Range is between 0 and 1. (range 0..1, default 1, runtime-tunable)
/// - [mix]: How much to use filtered signal in output. Default is 1. Range is between 0 and 1. (range 0..1, default 1, runtime-tunable)
/// - [n]: Normalize biquad coefficients, by default is disabled. Enabling it will normalize magnitude response at DC to 0dB. (range 0..1, default 0, runtime-tunable)
/// - [normalize]: Normalize biquad coefficients, by default is disabled. Enabling it will normalize magnitude response at DC to 0dB. (range 0..1, default 0, runtime-tunable)
/// - [p]: Set number of poles. Default is 2. (range 1..2, default 2)
/// - [poles]: Set number of poles. Default is 2. (range 1..2, default 2)
/// - [precision]: Set precision of filtering. (range -1..3, default -1)
/// - [r]: Set precision of filtering. (range -1..3, default -1)
/// - [t]: Set method to specify band-width of filter. (range 1..5, default QFACTOR, runtime-tunable)
/// - [transform]: Set transform type of IIR filter. (range 0..6, default DI)
/// - [w]: Determine how steep is the filter's shelf transition. (range 0..99999, default 0.5, runtime-tunable)
/// - [width]: Determine how steep is the filter's shelf transition. (range 0..99999, default 0.5, runtime-tunable)
/// - [width_type]: Set method to specify band-width of filter. (range 1..5, default QFACTOR, runtime-tunable)
final class TiltshelfSettings {
  /// Default value for [b].
  static const int bDefault = 0;

  /// Minimum value for [b].
  static const int bMin = 0;

  /// Maximum value for [b].
  static const int bMax = 32768;

  /// Default value for [blocksize].
  static const int blocksizeDefault = 0;

  /// Minimum value for [blocksize].
  static const int blocksizeMin = 0;

  /// Maximum value for [blocksize].
  static const int blocksizeMax = 32768;

  /// Default value for [f].
  static const double fDefault = 3000.0;

  /// Minimum value for [f].
  static const double fMin = 0.0;

  /// Maximum value for [f].
  static const double fMax = 999999.0;

  /// Default value for [frequency].
  static const double frequencyDefault = 3000.0;

  /// Minimum value for [frequency].
  static const double frequencyMin = 0.0;

  /// Maximum value for [frequency].
  static const double frequencyMax = 999999.0;

  /// Default value for [g].
  static const double gDefault = 0.0;

  /// Minimum value for [g].
  static const double gMin = -900.0;

  /// Maximum value for [g].
  static const double gMax = 900.0;

  /// Default value for [gain].
  static const double gainDefault = 0.0;

  /// Minimum value for [gain].
  static const double gainMin = -900.0;

  /// Maximum value for [gain].
  static const double gainMax = 900.0;

  /// Default value for [m].
  static const double mDefault = 1.0;

  /// Minimum value for [m].
  static const double mMin = 0.0;

  /// Maximum value for [m].
  static const double mMax = 1.0;

  /// Default value for [mix].
  static const double mixDefault = 1.0;

  /// Minimum value for [mix].
  static const double mixMin = 0.0;

  /// Maximum value for [mix].
  static const double mixMax = 1.0;

  /// Default value for [p].
  static const int pDefault = 2;

  /// Minimum value for [p].
  static const int pMin = 1;

  /// Maximum value for [p].
  static const int pMax = 2;

  /// Default value for [poles].
  static const int polesDefault = 2;

  /// Minimum value for [poles].
  static const int polesMin = 1;

  /// Maximum value for [poles].
  static const int polesMax = 2;

  /// Default value for [w].
  static const double wDefault = 0.5;

  /// Minimum value for [w].
  static const double wMin = 0.0;

  /// Maximum value for [w].
  static const double wMax = 99999.0;

  /// Default value for [width].
  static const double widthDefault = 0.5;

  /// Minimum value for [width].
  static const double widthMin = 0.0;

  /// Maximum value for [width].
  static const double widthMax = 99999.0;

  /// Whether this effect is inserted into the audio chain.
  final bool enabled;

  /// set transform type
  final TiltshelfTransformType a;

  /// set the block size
  final int b;

  /// set the block size
  final int blocksize;

  /// set channels to filter
  final String c;

  /// set channels to filter
  final String channels;

  /// set central frequency
  final double f;

  /// set central frequency
  final double frequency;

  /// set gain
  final double g;

  /// set gain
  final double gain;

  /// set mix
  final double m;

  /// set mix
  final double mix;

  /// normalize coefficients
  final bool n;

  /// normalize coefficients
  final bool normalize;

  /// set number of poles
  final int p;

  /// set number of poles
  final int poles;

  /// set filtering precision
  final TiltshelfPrecision precision;

  /// set filtering precision
  final TiltshelfPrecision r;

  /// set filter-width type
  final TiltshelfWidthType t;

  /// set transform type
  final TiltshelfTransformType transform;

  /// set width
  final double w;

  /// set width
  final double width;

  /// set filter-width type
  final TiltshelfWidthType width_type;

  /// Creates an [TiltshelfSettings] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default; the effect stays
  /// inactive until [enabled] is set to `true`.
  const TiltshelfSettings({
    this.enabled = false,
    this.a = TiltshelfTransformType.di,
    this.b = 0,
    this.blocksize = 0,
    this.c = 'all',
    this.channels = 'all',
    this.f = 3000.0,
    this.frequency = 3000.0,
    this.g = 0.0,
    this.gain = 0.0,
    this.m = 1.0,
    this.mix = 1.0,
    this.n = false,
    this.normalize = false,
    this.p = 2,
    this.poles = 2,
    this.precision = TiltshelfPrecision.auto,
    this.r = TiltshelfPrecision.auto,
    this.t = TiltshelfWidthType.q,
    this.transform = TiltshelfTransformType.di,
    this.w = 0.5,
    this.width = 0.5,
    this.width_type = TiltshelfWidthType.q,
  });

  /// Returns a copy of this [TiltshelfSettings] with the given fields replaced.
  TiltshelfSettings copyWith({
    bool? enabled,
    TiltshelfTransformType? a,
    int? b,
    int? blocksize,
    String? c,
    String? channels,
    double? f,
    double? frequency,
    double? g,
    double? gain,
    double? m,
    double? mix,
    bool? n,
    bool? normalize,
    int? p,
    int? poles,
    TiltshelfPrecision? precision,
    TiltshelfPrecision? r,
    TiltshelfWidthType? t,
    TiltshelfTransformType? transform,
    double? w,
    double? width,
    TiltshelfWidthType? width_type,
  }) =>
      TiltshelfSettings(
        enabled: enabled ?? this.enabled,
        a: a ?? this.a,
        b: b ?? this.b,
        blocksize: blocksize ?? this.blocksize,
        c: c ?? this.c,
        channels: channels ?? this.channels,
        f: f ?? this.f,
        frequency: frequency ?? this.frequency,
        g: g ?? this.g,
        gain: gain ?? this.gain,
        m: m ?? this.m,
        mix: mix ?? this.mix,
        n: n ?? this.n,
        normalize: normalize ?? this.normalize,
        p: p ?? this.p,
        poles: poles ?? this.poles,
        precision: precision ?? this.precision,
        r: r ?? this.r,
        t: t ?? this.t,
        transform: transform ?? this.transform,
        w: w ?? this.w,
        width: width ?? this.width,
        width_type: width_type ?? this.width_type,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TiltshelfSettings &&
          other.enabled == enabled &&
          other.a == a &&
          other.b == b &&
          other.blocksize == blocksize &&
          other.c == c &&
          other.channels == channels &&
          other.f == f &&
          other.frequency == frequency &&
          other.g == g &&
          other.gain == gain &&
          other.m == m &&
          other.mix == mix &&
          other.n == n &&
          other.normalize == normalize &&
          other.p == p &&
          other.poles == poles &&
          other.precision == precision &&
          other.r == r &&
          other.t == t &&
          other.transform == transform &&
          other.w == w &&
          other.width == width &&
          other.width_type == width_type);

  @override
  int get hashCode => Object.hashAll([
        enabled,
        a,
        b,
        blocksize,
        c,
        channels,
        f,
        frequency,
        g,
        gain,
        m,
        mix,
        n,
        normalize,
        p,
        poles,
        precision,
        r,
        t,
        transform,
        w,
        width,
        width_type,
      ]);

  @override
  String toString() =>
      'TiltshelfSettings(enabled: $enabled, a: $a, b: $b, blocksize: $blocksize, c: $c, channels: $channels, f: $f, frequency: $frequency, g: $g, gain: $gain, m: $m, mix: $mix, n: $n, normalize: $normalize, p: $p, poles: $poles, precision: $precision, r: $r, t: $t, transform: $transform, w: $w, width: $width, width_type: $width_type)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(b >= bMin, 'tiltshelf.b must be >= 0');
    assert(b <= bMax, 'tiltshelf.b must be <= 32768');
    assert(blocksize >= blocksizeMin, 'tiltshelf.blocksize must be >= 0');
    assert(blocksize <= blocksizeMax, 'tiltshelf.blocksize must be <= 32768');
    assert(f >= fMin, 'tiltshelf.f must be >= 0');
    assert(f <= fMax, 'tiltshelf.f must be <= 999999');
    assert(frequency >= frequencyMin, 'tiltshelf.frequency must be >= 0');
    assert(frequency <= frequencyMax, 'tiltshelf.frequency must be <= 999999');
    assert(g >= gMin, 'tiltshelf.g must be >= -900');
    assert(g <= gMax, 'tiltshelf.g must be <= 900');
    assert(gain >= gainMin, 'tiltshelf.gain must be >= -900');
    assert(gain <= gainMax, 'tiltshelf.gain must be <= 900');
    assert(m >= mMin, 'tiltshelf.m must be >= 0');
    assert(m <= mMax, 'tiltshelf.m must be <= 1');
    assert(mix >= mixMin, 'tiltshelf.mix must be >= 0');
    assert(mix <= mixMax, 'tiltshelf.mix must be <= 1');
    assert(p >= pMin, 'tiltshelf.p must be >= 1');
    assert(p <= pMax, 'tiltshelf.p must be <= 2');
    assert(poles >= polesMin, 'tiltshelf.poles must be >= 1');
    assert(poles <= polesMax, 'tiltshelf.poles must be <= 2');
    assert(w >= wMin, 'tiltshelf.w must be >= 0');
    assert(w <= wMax, 'tiltshelf.w must be <= 99999');
    assert(width >= widthMin, 'tiltshelf.width must be >= 0');
    assert(width <= widthMax, 'tiltshelf.width must be <= 99999');
    final parts = <String>[];
    if (a != TiltshelfTransformType.di) parts.add('a=' + a.mpvValue);
    if (b != 0) parts.add('b=' + b.toString());
    if (blocksize != 0) parts.add('blocksize=' + blocksize.toString());
    if (c != 'all') parts.add('c=' + '[' + c + ']');
    if (channels != 'all') parts.add('channels=' + '[' + channels + ']');
    if (f != 3000.0) parts.add('f=' + _wireDouble(f));
    if (frequency != 3000.0) parts.add('frequency=' + _wireDouble(frequency));
    if (g != 0.0) parts.add('g=' + _wireDouble(g));
    if (gain != 0.0) parts.add('gain=' + _wireDouble(gain));
    if (m != 1.0) parts.add('m=' + _wireDouble(m));
    if (mix != 1.0) parts.add('mix=' + _wireDouble(mix));
    if (n != false) parts.add('n=' + (n ? '1' : '0'));
    if (normalize != false) parts.add('normalize=' + (normalize ? '1' : '0'));
    if (p != 2) parts.add('p=' + p.toString());
    if (poles != 2) parts.add('poles=' + poles.toString());
    if (precision != TiltshelfPrecision.auto)
      parts.add('precision=' + precision.mpvValue);
    if (r != TiltshelfPrecision.auto) parts.add('r=' + r.mpvValue);
    if (t != TiltshelfWidthType.q) parts.add('t=' + t.mpvValue);
    if (transform != TiltshelfTransformType.di)
      parts.add('transform=' + transform.mpvValue);
    if (w != 0.5) parts.add('w=' + _wireDouble(w));
    if (width != 0.5) parts.add('width=' + _wireDouble(width));
    if (width_type != TiltshelfWidthType.q)
      parts.add('width_type=' + width_type.mpvValue);
    return parts.isEmpty
        ? 'lavfi-tiltshelf'
        : 'lavfi-tiltshelf=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  List<(String, String)>? _runtimeDiff(TiltshelfSettings prev) {
    final out = <(String, String)>[];
    if (a != prev.a) return null;
    if (b != prev.b) return null;
    if (blocksize != prev.blocksize) return null;
    if (c != prev.c) {
      out.add(('c', c));
    }
    if (channels != prev.channels) {
      out.add(('channels', channels));
    }
    if (f != prev.f) {
      out.add(('f', _wireDouble(f)));
    }
    if (frequency != prev.frequency) {
      out.add(('frequency', _wireDouble(frequency)));
    }
    if (g != prev.g) {
      out.add(('g', _wireDouble(g)));
    }
    if (gain != prev.gain) {
      out.add(('gain', _wireDouble(gain)));
    }
    if (m != prev.m) {
      out.add(('m', _wireDouble(m)));
    }
    if (mix != prev.mix) {
      out.add(('mix', _wireDouble(mix)));
    }
    if (n != prev.n) {
      out.add(('n', (n ? '1' : '0')));
    }
    if (normalize != prev.normalize) {
      out.add(('normalize', (normalize ? '1' : '0')));
    }
    if (p != prev.p) return null;
    if (poles != prev.poles) return null;
    if (precision != prev.precision) return null;
    if (r != prev.r) return null;
    if (t != prev.t) {
      out.add(('t', t.mpvValue));
    }
    if (transform != prev.transform) return null;
    if (w != prev.w) {
      out.add(('w', _wireDouble(w)));
    }
    if (width != prev.width) {
      out.add(('width', _wireDouble(width)));
    }
    if (width_type != prev.width_type) {
      out.add(('width_type', width_type.mpvValue));
    }
    return out;
  }
}

/// Configuration for the `treble` audio effect.
///
/// Boost or cut treble (upper) frequencies of the audio using a two-pole
/// shelving filter with a response similar to that of a standard
/// hi-fi's tone-controls. This is also known as shelving equalisation (EQ).
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [a]: Set transform type of IIR filter. (range 0..6, default DI)
/// - [b]: Set block size used for reverse IIR processing. If this value is set to high enough value (higher than impulse response length truncated when reaches near zero values) filtering will become linear phase otherwise if not big enough it will just produce nasty artifacts.  Note that filter delay will be exactly this many samples when set to non-zero value. (range 0..32768, default 0)
/// - [blocksize]: set the block size (range 0..32768, default 0)
/// - [c]: Specify which channels to filter, by default all available are filtered. (range 0..0, default "all", runtime-tunable)
/// - [channels]: Specify which channels to filter, by default all available are filtered. (range 0..0, default "all", runtime-tunable)
/// - [f]: Set the filter's central frequency and so can be used to extend or reduce the frequency range to be boosted or cut. The default value is `3000` Hz. (range 0..999999, default 3000, runtime-tunable)
/// - [frequency]: Set the filter's central frequency and so can be used to extend or reduce the frequency range to be boosted or cut. The default value is `3000` Hz. (range 0..999999, default 3000, runtime-tunable)
/// - [g]: Give the gain at whichever is the lower of ~22 kHz and the Nyquist frequency. Its useful range is about -20 (for a large cut) to +20 (for a large boost). Beware of clipping when using a positive gain. (range -900..900, default 0, runtime-tunable)
/// - [gain]: Give the gain at whichever is the lower of ~22 kHz and the Nyquist frequency. Its useful range is about -20 (for a large cut) to +20 (for a large boost). Beware of clipping when using a positive gain. (range -900..900, default 0, runtime-tunable)
/// - [m]: How much to use filtered signal in output. Default is 1. Range is between 0 and 1. (range 0..1, default 1, runtime-tunable)
/// - [mix]: How much to use filtered signal in output. Default is 1. Range is between 0 and 1. (range 0..1, default 1, runtime-tunable)
/// - [n]: Normalize biquad coefficients, by default is disabled. Enabling it will normalize magnitude response at DC to 0dB. (range 0..1, default 0, runtime-tunable)
/// - [normalize]: Normalize biquad coefficients, by default is disabled. Enabling it will normalize magnitude response at DC to 0dB. (range 0..1, default 0, runtime-tunable)
/// - [p]: Set number of poles. Default is 2. (range 1..2, default 2)
/// - [poles]: Set number of poles. Default is 2. (range 1..2, default 2)
/// - [precision]: Set precision of filtering. (range -1..3, default -1)
/// - [r]: Set precision of filtering. (range -1..3, default -1)
/// - [t]: Set method to specify band-width of filter. (range 1..5, default QFACTOR, runtime-tunable)
/// - [transform]: Set transform type of IIR filter. (range 0..6, default DI)
/// - [w]: Determine how steep is the filter's shelf transition. (range 0..99999, default 0.5, runtime-tunable)
/// - [width]: Determine how steep is the filter's shelf transition. (range 0..99999, default 0.5, runtime-tunable)
/// - [width_type]: Set method to specify band-width of filter. (range 1..5, default QFACTOR, runtime-tunable)
final class TrebleSettings {
  /// Default value for [b].
  static const int bDefault = 0;

  /// Minimum value for [b].
  static const int bMin = 0;

  /// Maximum value for [b].
  static const int bMax = 32768;

  /// Default value for [blocksize].
  static const int blocksizeDefault = 0;

  /// Minimum value for [blocksize].
  static const int blocksizeMin = 0;

  /// Maximum value for [blocksize].
  static const int blocksizeMax = 32768;

  /// Default value for [f].
  static const double fDefault = 3000.0;

  /// Minimum value for [f].
  static const double fMin = 0.0;

  /// Maximum value for [f].
  static const double fMax = 999999.0;

  /// Default value for [frequency].
  static const double frequencyDefault = 3000.0;

  /// Minimum value for [frequency].
  static const double frequencyMin = 0.0;

  /// Maximum value for [frequency].
  static const double frequencyMax = 999999.0;

  /// Default value for [g].
  static const double gDefault = 0.0;

  /// Minimum value for [g].
  static const double gMin = -900.0;

  /// Maximum value for [g].
  static const double gMax = 900.0;

  /// Default value for [gain].
  static const double gainDefault = 0.0;

  /// Minimum value for [gain].
  static const double gainMin = -900.0;

  /// Maximum value for [gain].
  static const double gainMax = 900.0;

  /// Default value for [m].
  static const double mDefault = 1.0;

  /// Minimum value for [m].
  static const double mMin = 0.0;

  /// Maximum value for [m].
  static const double mMax = 1.0;

  /// Default value for [mix].
  static const double mixDefault = 1.0;

  /// Minimum value for [mix].
  static const double mixMin = 0.0;

  /// Maximum value for [mix].
  static const double mixMax = 1.0;

  /// Default value for [p].
  static const int pDefault = 2;

  /// Minimum value for [p].
  static const int pMin = 1;

  /// Maximum value for [p].
  static const int pMax = 2;

  /// Default value for [poles].
  static const int polesDefault = 2;

  /// Minimum value for [poles].
  static const int polesMin = 1;

  /// Maximum value for [poles].
  static const int polesMax = 2;

  /// Default value for [w].
  static const double wDefault = 0.5;

  /// Minimum value for [w].
  static const double wMin = 0.0;

  /// Maximum value for [w].
  static const double wMax = 99999.0;

  /// Default value for [width].
  static const double widthDefault = 0.5;

  /// Minimum value for [width].
  static const double widthMin = 0.0;

  /// Maximum value for [width].
  static const double widthMax = 99999.0;

  /// Whether this effect is inserted into the audio chain.
  final bool enabled;

  /// set transform type
  final TrebleTransformType a;

  /// set the block size
  final int b;

  /// set the block size
  final int blocksize;

  /// set channels to filter
  final String c;

  /// set channels to filter
  final String channels;

  /// set central frequency
  final double f;

  /// set central frequency
  final double frequency;

  /// set gain
  final double g;

  /// set gain
  final double gain;

  /// set mix
  final double m;

  /// set mix
  final double mix;

  /// normalize coefficients
  final bool n;

  /// normalize coefficients
  final bool normalize;

  /// set number of poles
  final int p;

  /// set number of poles
  final int poles;

  /// set filtering precision
  final TreblePrecision precision;

  /// set filtering precision
  final TreblePrecision r;

  /// set filter-width type
  final TrebleWidthType t;

  /// set transform type
  final TrebleTransformType transform;

  /// set width
  final double w;

  /// set width
  final double width;

  /// set filter-width type
  final TrebleWidthType width_type;

  /// Creates an [TrebleSettings] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default; the effect stays
  /// inactive until [enabled] is set to `true`.
  const TrebleSettings({
    this.enabled = false,
    this.a = TrebleTransformType.di,
    this.b = 0,
    this.blocksize = 0,
    this.c = 'all',
    this.channels = 'all',
    this.f = 3000.0,
    this.frequency = 3000.0,
    this.g = 0.0,
    this.gain = 0.0,
    this.m = 1.0,
    this.mix = 1.0,
    this.n = false,
    this.normalize = false,
    this.p = 2,
    this.poles = 2,
    this.precision = TreblePrecision.auto,
    this.r = TreblePrecision.auto,
    this.t = TrebleWidthType.q,
    this.transform = TrebleTransformType.di,
    this.w = 0.5,
    this.width = 0.5,
    this.width_type = TrebleWidthType.q,
  });

  /// Returns a copy of this [TrebleSettings] with the given fields replaced.
  TrebleSettings copyWith({
    bool? enabled,
    TrebleTransformType? a,
    int? b,
    int? blocksize,
    String? c,
    String? channels,
    double? f,
    double? frequency,
    double? g,
    double? gain,
    double? m,
    double? mix,
    bool? n,
    bool? normalize,
    int? p,
    int? poles,
    TreblePrecision? precision,
    TreblePrecision? r,
    TrebleWidthType? t,
    TrebleTransformType? transform,
    double? w,
    double? width,
    TrebleWidthType? width_type,
  }) =>
      TrebleSettings(
        enabled: enabled ?? this.enabled,
        a: a ?? this.a,
        b: b ?? this.b,
        blocksize: blocksize ?? this.blocksize,
        c: c ?? this.c,
        channels: channels ?? this.channels,
        f: f ?? this.f,
        frequency: frequency ?? this.frequency,
        g: g ?? this.g,
        gain: gain ?? this.gain,
        m: m ?? this.m,
        mix: mix ?? this.mix,
        n: n ?? this.n,
        normalize: normalize ?? this.normalize,
        p: p ?? this.p,
        poles: poles ?? this.poles,
        precision: precision ?? this.precision,
        r: r ?? this.r,
        t: t ?? this.t,
        transform: transform ?? this.transform,
        w: w ?? this.w,
        width: width ?? this.width,
        width_type: width_type ?? this.width_type,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TrebleSettings &&
          other.enabled == enabled &&
          other.a == a &&
          other.b == b &&
          other.blocksize == blocksize &&
          other.c == c &&
          other.channels == channels &&
          other.f == f &&
          other.frequency == frequency &&
          other.g == g &&
          other.gain == gain &&
          other.m == m &&
          other.mix == mix &&
          other.n == n &&
          other.normalize == normalize &&
          other.p == p &&
          other.poles == poles &&
          other.precision == precision &&
          other.r == r &&
          other.t == t &&
          other.transform == transform &&
          other.w == w &&
          other.width == width &&
          other.width_type == width_type);

  @override
  int get hashCode => Object.hashAll([
        enabled,
        a,
        b,
        blocksize,
        c,
        channels,
        f,
        frequency,
        g,
        gain,
        m,
        mix,
        n,
        normalize,
        p,
        poles,
        precision,
        r,
        t,
        transform,
        w,
        width,
        width_type,
      ]);

  @override
  String toString() =>
      'TrebleSettings(enabled: $enabled, a: $a, b: $b, blocksize: $blocksize, c: $c, channels: $channels, f: $f, frequency: $frequency, g: $g, gain: $gain, m: $m, mix: $mix, n: $n, normalize: $normalize, p: $p, poles: $poles, precision: $precision, r: $r, t: $t, transform: $transform, w: $w, width: $width, width_type: $width_type)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(b >= bMin, 'treble.b must be >= 0');
    assert(b <= bMax, 'treble.b must be <= 32768');
    assert(blocksize >= blocksizeMin, 'treble.blocksize must be >= 0');
    assert(blocksize <= blocksizeMax, 'treble.blocksize must be <= 32768');
    assert(f >= fMin, 'treble.f must be >= 0');
    assert(f <= fMax, 'treble.f must be <= 999999');
    assert(frequency >= frequencyMin, 'treble.frequency must be >= 0');
    assert(frequency <= frequencyMax, 'treble.frequency must be <= 999999');
    assert(g >= gMin, 'treble.g must be >= -900');
    assert(g <= gMax, 'treble.g must be <= 900');
    assert(gain >= gainMin, 'treble.gain must be >= -900');
    assert(gain <= gainMax, 'treble.gain must be <= 900');
    assert(m >= mMin, 'treble.m must be >= 0');
    assert(m <= mMax, 'treble.m must be <= 1');
    assert(mix >= mixMin, 'treble.mix must be >= 0');
    assert(mix <= mixMax, 'treble.mix must be <= 1');
    assert(p >= pMin, 'treble.p must be >= 1');
    assert(p <= pMax, 'treble.p must be <= 2');
    assert(poles >= polesMin, 'treble.poles must be >= 1');
    assert(poles <= polesMax, 'treble.poles must be <= 2');
    assert(w >= wMin, 'treble.w must be >= 0');
    assert(w <= wMax, 'treble.w must be <= 99999');
    assert(width >= widthMin, 'treble.width must be >= 0');
    assert(width <= widthMax, 'treble.width must be <= 99999');
    final parts = <String>[];
    if (a != TrebleTransformType.di) parts.add('a=' + a.mpvValue);
    if (b != 0) parts.add('b=' + b.toString());
    if (blocksize != 0) parts.add('blocksize=' + blocksize.toString());
    if (c != 'all') parts.add('c=' + '[' + c + ']');
    if (channels != 'all') parts.add('channels=' + '[' + channels + ']');
    if (f != 3000.0) parts.add('f=' + _wireDouble(f));
    if (frequency != 3000.0) parts.add('frequency=' + _wireDouble(frequency));
    if (g != 0.0) parts.add('g=' + _wireDouble(g));
    if (gain != 0.0) parts.add('gain=' + _wireDouble(gain));
    if (m != 1.0) parts.add('m=' + _wireDouble(m));
    if (mix != 1.0) parts.add('mix=' + _wireDouble(mix));
    if (n != false) parts.add('n=' + (n ? '1' : '0'));
    if (normalize != false) parts.add('normalize=' + (normalize ? '1' : '0'));
    if (p != 2) parts.add('p=' + p.toString());
    if (poles != 2) parts.add('poles=' + poles.toString());
    if (precision != TreblePrecision.auto)
      parts.add('precision=' + precision.mpvValue);
    if (r != TreblePrecision.auto) parts.add('r=' + r.mpvValue);
    if (t != TrebleWidthType.q) parts.add('t=' + t.mpvValue);
    if (transform != TrebleTransformType.di)
      parts.add('transform=' + transform.mpvValue);
    if (w != 0.5) parts.add('w=' + _wireDouble(w));
    if (width != 0.5) parts.add('width=' + _wireDouble(width));
    if (width_type != TrebleWidthType.q)
      parts.add('width_type=' + width_type.mpvValue);
    return parts.isEmpty ? 'lavfi-treble' : 'lavfi-treble=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  List<(String, String)>? _runtimeDiff(TrebleSettings prev) {
    final out = <(String, String)>[];
    if (a != prev.a) return null;
    if (b != prev.b) return null;
    if (blocksize != prev.blocksize) return null;
    if (c != prev.c) {
      out.add(('c', c));
    }
    if (channels != prev.channels) {
      out.add(('channels', channels));
    }
    if (f != prev.f) {
      out.add(('f', _wireDouble(f)));
    }
    if (frequency != prev.frequency) {
      out.add(('frequency', _wireDouble(frequency)));
    }
    if (g != prev.g) {
      out.add(('g', _wireDouble(g)));
    }
    if (gain != prev.gain) {
      out.add(('gain', _wireDouble(gain)));
    }
    if (m != prev.m) {
      out.add(('m', _wireDouble(m)));
    }
    if (mix != prev.mix) {
      out.add(('mix', _wireDouble(mix)));
    }
    if (n != prev.n) {
      out.add(('n', (n ? '1' : '0')));
    }
    if (normalize != prev.normalize) {
      out.add(('normalize', (normalize ? '1' : '0')));
    }
    if (p != prev.p) return null;
    if (poles != prev.poles) return null;
    if (precision != prev.precision) return null;
    if (r != prev.r) return null;
    if (t != prev.t) {
      out.add(('t', t.mpvValue));
    }
    if (transform != prev.transform) return null;
    if (w != prev.w) {
      out.add(('w', _wireDouble(w)));
    }
    if (width != prev.width) {
      out.add(('width', _wireDouble(width)));
    }
    if (width_type != prev.width_type) {
      out.add(('width_type', width_type.mpvValue));
    }
    return out;
  }
}

/// Configuration for the `tremolo` audio effect.
///
/// Sinusoidal amplitude modulation.
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [d]: Depth of modulation as a percentage. Range is 0.0 - 1.0. Default value is 0.5. (range 0.0..1.0, default 0.5)
/// - [f]: Modulation frequency in Hertz. Modulation frequencies in the subharmonic range (20 Hz or lower) will result in a tremolo effect. This filter may also be used as a ring modulator by specifying a modulation frequency higher than 20 Hz. Range is 0.1 - 20000.0. Default value is 5.0 Hz. (range 0.1..20000.0, default 5.0)
final class TremoloSettings {
  /// Default value for [d].
  static const double dDefault = 0.5;

  /// Minimum value for [d].
  static const double dMin = 0.0;

  /// Maximum value for [d].
  static const double dMax = 1.0;

  /// Default value for [f].
  static const double fDefault = 5.0;

  /// Minimum value for [f].
  static const double fMin = 0.1;

  /// Maximum value for [f].
  static const double fMax = 20000.0;

  /// Whether this effect is inserted into the audio chain.
  final bool enabled;

  /// set depth as percentage
  final double d;

  /// set frequency in hertz
  final double f;

  /// Creates an [TremoloSettings] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default; the effect stays
  /// inactive until [enabled] is set to `true`.
  const TremoloSettings({
    this.enabled = false,
    this.d = 0.5,
    this.f = 5.0,
  });

  /// Returns a copy of this [TremoloSettings] with the given fields replaced.
  TremoloSettings copyWith({
    bool? enabled,
    double? d,
    double? f,
  }) =>
      TremoloSettings(
        enabled: enabled ?? this.enabled,
        d: d ?? this.d,
        f: f ?? this.f,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TremoloSettings &&
          other.enabled == enabled &&
          other.d == d &&
          other.f == f);

  @override
  int get hashCode => Object.hash(enabled, d, f);

  @override
  String toString() => 'TremoloSettings(enabled: $enabled, d: $d, f: $f)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(d >= dMin, 'tremolo.d must be >= 0.0');
    assert(d <= dMax, 'tremolo.d must be <= 1.0');
    assert(f >= fMin, 'tremolo.f must be >= 0.1');
    assert(f <= fMax, 'tremolo.f must be <= 20000.0');
    final parts = <String>[];
    if (d != 0.5) parts.add('d=' + _wireDouble(d));
    if (f != 5.0) parts.add('f=' + _wireDouble(f));
    return parts.isEmpty ? 'lavfi-tremolo' : 'lavfi-tremolo=' + parts.join(':');
  }
}

/// Configuration for the `vibrato` audio effect.
///
/// Sinusoidal phase modulation.
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [d]: Depth of modulation as a percentage. Range is 0.0 - 1.0. Default value is 0.5. (range 0.00..1.0, default 0.5)
/// - [f]: Modulation frequency in Hertz. Range is 0.1 - 20000.0. Default value is 5.0 Hz. (range 0.1..20000.0, default 5.0)
final class VibratoSettings {
  /// Default value for [d].
  static const double dDefault = 0.5;

  /// Minimum value for [d].
  static const double dMin = 0.00;

  /// Maximum value for [d].
  static const double dMax = 1.0;

  /// Default value for [f].
  static const double fDefault = 5.0;

  /// Minimum value for [f].
  static const double fMin = 0.1;

  /// Maximum value for [f].
  static const double fMax = 20000.0;

  /// Whether this effect is inserted into the audio chain.
  final bool enabled;

  /// set depth as percentage
  final double d;

  /// set frequency in hertz
  final double f;

  /// Creates an [VibratoSettings] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default; the effect stays
  /// inactive until [enabled] is set to `true`.
  const VibratoSettings({
    this.enabled = false,
    this.d = 0.5,
    this.f = 5.0,
  });

  /// Returns a copy of this [VibratoSettings] with the given fields replaced.
  VibratoSettings copyWith({
    bool? enabled,
    double? d,
    double? f,
  }) =>
      VibratoSettings(
        enabled: enabled ?? this.enabled,
        d: d ?? this.d,
        f: f ?? this.f,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VibratoSettings &&
          other.enabled == enabled &&
          other.d == d &&
          other.f == f);

  @override
  int get hashCode => Object.hash(enabled, d, f);

  @override
  String toString() => 'VibratoSettings(enabled: $enabled, d: $d, f: $f)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(d >= dMin, 'vibrato.d must be >= 0.00');
    assert(d <= dMax, 'vibrato.d must be <= 1.0');
    assert(f >= fMin, 'vibrato.f must be >= 0.1');
    assert(f <= fMax, 'vibrato.f must be <= 20000.0');
    final parts = <String>[];
    if (d != 0.5) parts.add('d=' + _wireDouble(d));
    if (f != 5.0) parts.add('f=' + _wireDouble(f));
    return parts.isEmpty ? 'lavfi-vibrato' : 'lavfi-vibrato=' + parts.join(':');
  }
}

/// Configuration for the `virtualbass` audio effect.
///
/// Apply audio Virtual Bass filter.
///
/// This filter accepts stereo input and produce stereo with LFE (2.1) channels output.
/// The newly produced LFE channel have enhanced virtual bass originally obtained from both stereo channels.
/// This filter outputs front left and front right channels unchanged as available in stereo input.
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [cutoff]: Set the virtual bass cutoff frequency. Default value is 250 Hz. Allowed range is from 100 to 500 Hz. (range 100..500, default 250)
/// - [strength]: Set the virtual bass strength. Allowed range is from 0.5 to 3. Default value is 3. (range 0.5..3, default 3, runtime-tunable)
final class VirtualbassSettings {
  /// Default value for [cutoff].
  static const double cutoffDefault = 250.0;

  /// Minimum value for [cutoff].
  static const double cutoffMin = 100.0;

  /// Maximum value for [cutoff].
  static const double cutoffMax = 500.0;

  /// Default value for [strength].
  static const double strengthDefault = 3.0;

  /// Minimum value for [strength].
  static const double strengthMin = 0.5;

  /// Maximum value for [strength].
  static const double strengthMax = 3.0;

  /// Whether this effect is inserted into the audio chain.
  final bool enabled;

  /// set virtual bass cutoff
  final double cutoff;

  /// set virtual bass strength
  final double strength;

  /// Creates an [VirtualbassSettings] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default; the effect stays
  /// inactive until [enabled] is set to `true`.
  const VirtualbassSettings({
    this.enabled = false,
    this.cutoff = 250.0,
    this.strength = 3.0,
  });

  /// Returns a copy of this [VirtualbassSettings] with the given fields replaced.
  VirtualbassSettings copyWith({
    bool? enabled,
    double? cutoff,
    double? strength,
  }) =>
      VirtualbassSettings(
        enabled: enabled ?? this.enabled,
        cutoff: cutoff ?? this.cutoff,
        strength: strength ?? this.strength,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VirtualbassSettings &&
          other.enabled == enabled &&
          other.cutoff == cutoff &&
          other.strength == strength);

  @override
  int get hashCode => Object.hash(enabled, cutoff, strength);

  @override
  String toString() =>
      'VirtualbassSettings(enabled: $enabled, cutoff: $cutoff, strength: $strength)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(cutoff >= cutoffMin, 'virtualbass.cutoff must be >= 100');
    assert(cutoff <= cutoffMax, 'virtualbass.cutoff must be <= 500');
    assert(strength >= strengthMin, 'virtualbass.strength must be >= 0.5');
    assert(strength <= strengthMax, 'virtualbass.strength must be <= 3');
    final parts = <String>[];
    if (cutoff != 250.0) parts.add('cutoff=' + _wireDouble(cutoff));
    if (strength != 3.0) parts.add('strength=' + _wireDouble(strength));
    return parts.isEmpty
        ? 'lavfi-virtualbass'
        : 'lavfi-virtualbass=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  List<(String, String)>? _runtimeDiff(VirtualbassSettings prev) {
    final out = <(String, String)>[];
    if (cutoff != prev.cutoff) return null;
    if (strength != prev.strength) {
      out.add(('strength', _wireDouble(strength)));
    }
    return out;
  }
}

/// One incremental `af-command` update produced by
/// [AudioEffects.diffCommands]: applies [option] = [value] to the
/// live chain stage labelled [label] (an instance of the ffmpeg
/// filter [filterName]).
typedef AfCommand = ({
  String label,
  String option,
  String value,
  String filterName
});

/// All audio effects bundled into a single atomic configuration
/// applied via `Player.setAudioEffects` / `Player.updateAudioEffects`.
///
/// Each effect has its own nullable `XxxSettings` field defaulting to
/// `null` (not configured). Assign a settings instance with
/// `enabled: true` to insert that stage in the audio chain; a `null`
/// slot and a disabled instance are identical on the wire.
///
/// Fields you never assign cost nothing in your app binary: the
/// compiler tree-shakes every `*Settings` class your code doesn't
/// name.
///
/// `custom` carries raw lavfi-style filter strings (e.g.
/// `'lavfi-aeval=val(0)|val(1)'`) emitted at the head of the chain,
/// before any typed stage. Use it for expression-based filters or
/// experimental ffmpeg filters that don't have a typed equivalent.
final class AudioEffects {
  /// Raw lavfi filter strings emitted at the head of the chain,
  /// before any typed stage. Use for expression-based or
  /// experimental filters without a typed equivalent.
  final List<String> custom;

  /// Configuration for the `acompressor` audio effect.
  ///
  /// `null` = not configured (same wire output as a
  /// disabled instance).
  final AcompressorSettings? acompressor;

  /// Configuration for the `acontrast` audio effect.
  ///
  /// `null` = not configured (same wire output as a
  /// disabled instance).
  final AcontrastSettings? acontrast;

  /// Configuration for the `acrusher` audio effect.
  ///
  /// `null` = not configured (same wire output as a
  /// disabled instance).
  final AcrusherSettings? acrusher;

  /// Configuration for the `adeclick` audio effect.
  ///
  /// `null` = not configured (same wire output as a
  /// disabled instance).
  final AdeclickSettings? adeclick;

  /// Configuration for the `adeclip` audio effect.
  ///
  /// `null` = not configured (same wire output as a
  /// disabled instance).
  final AdeclipSettings? adeclip;

  /// Configuration for the `adecorrelate` audio effect.
  ///
  /// `null` = not configured (same wire output as a
  /// disabled instance).
  final AdecorrelateSettings? adecorrelate;

  /// Configuration for the `adelay` audio effect.
  ///
  /// `null` = not configured (same wire output as a
  /// disabled instance).
  final AdelaySettings? adelay;

  /// Configuration for the `adenorm` audio effect.
  ///
  /// `null` = not configured (same wire output as a
  /// disabled instance).
  final AdenormSettings? adenorm;

  /// Configuration for the `aderivative` audio effect.
  ///
  /// `null` = not configured (same wire output as a
  /// disabled instance).
  final AderivativeSettings? aderivative;

  /// Configuration for the `adrc` audio effect.
  ///
  /// `null` = not configured (same wire output as a
  /// disabled instance).
  final AdrcSettings? adrc;

  /// Configuration for the `adynamicequalizer` audio effect.
  ///
  /// `null` = not configured (same wire output as a
  /// disabled instance).
  final AdynamicequalizerSettings? adynamicequalizer;

  /// Configuration for the `adynamicsmooth` audio effect.
  ///
  /// `null` = not configured (same wire output as a
  /// disabled instance).
  final AdynamicsmoothSettings? adynamicsmooth;

  /// Configuration for the `aecho` audio effect.
  ///
  /// `null` = not configured (same wire output as a
  /// disabled instance).
  final AechoSettings? aecho;

  /// Configuration for the `aemphasis` audio effect.
  ///
  /// `null` = not configured (same wire output as a
  /// disabled instance).
  final AemphasisSettings? aemphasis;

  /// Configuration for the `aeval` audio effect.
  ///
  /// `null` = not configured (same wire output as a
  /// disabled instance).
  final AevalSettings? aeval;

  /// Configuration for the `aexciter` audio effect.
  ///
  /// `null` = not configured (same wire output as a
  /// disabled instance).
  final AexciterSettings? aexciter;

  /// Configuration for the `afade` audio effect.
  ///
  /// `null` = not configured (same wire output as a
  /// disabled instance).
  final AfadeSettings? afade;

  /// Configuration for the `afftdn` audio effect.
  ///
  /// `null` = not configured (same wire output as a
  /// disabled instance).
  final AfftdnSettings? afftdn;

  /// Configuration for the `afftfilt` audio effect.
  ///
  /// `null` = not configured (same wire output as a
  /// disabled instance).
  final AfftfiltSettings? afftfilt;

  /// Configuration for the `aformat` audio effect.
  ///
  /// `null` = not configured (same wire output as a
  /// disabled instance).
  final AformatSettings? aformat;

  /// Configuration for the `afreqshift` audio effect.
  ///
  /// `null` = not configured (same wire output as a
  /// disabled instance).
  final AfreqshiftSettings? afreqshift;

  /// Configuration for the `afwtdn` audio effect.
  ///
  /// `null` = not configured (same wire output as a
  /// disabled instance).
  final AfwtdnSettings? afwtdn;

  /// Configuration for the `agate` audio effect.
  ///
  /// `null` = not configured (same wire output as a
  /// disabled instance).
  final AgateSettings? agate;

  /// Configuration for the `aiir` audio effect.
  ///
  /// `null` = not configured (same wire output as a
  /// disabled instance).
  final AiirSettings? aiir;

  /// Configuration for the `aintegral` audio effect.
  ///
  /// `null` = not configured (same wire output as a
  /// disabled instance).
  final AintegralSettings? aintegral;

  /// Configuration for the `alimiter` audio effect.
  ///
  /// `null` = not configured (same wire output as a
  /// disabled instance).
  final AlimiterSettings? alimiter;

  /// Configuration for the `allpass` audio effect.
  ///
  /// `null` = not configured (same wire output as a
  /// disabled instance).
  final AllpassSettings? allpass;

  /// Configuration for the `anequalizer` audio effect.
  ///
  /// `null` = not configured (same wire output as a
  /// disabled instance).
  final AnequalizerSettings? anequalizer;

  /// Configuration for the `anlmdn` audio effect.
  ///
  /// `null` = not configured (same wire output as a
  /// disabled instance).
  final AnlmdnSettings? anlmdn;

  /// Configuration for the `apad` audio effect.
  ///
  /// `null` = not configured (same wire output as a
  /// disabled instance).
  final ApadSettings? apad;

  /// Configuration for the `aphaser` audio effect.
  ///
  /// `null` = not configured (same wire output as a
  /// disabled instance).
  final AphaserSettings? aphaser;

  /// Configuration for the `aphaseshift` audio effect.
  ///
  /// `null` = not configured (same wire output as a
  /// disabled instance).
  final AphaseshiftSettings? aphaseshift;

  /// Configuration for the `apsyclip` audio effect.
  ///
  /// `null` = not configured (same wire output as a
  /// disabled instance).
  final ApsyclipSettings? apsyclip;

  /// Configuration for the `apulsator` audio effect.
  ///
  /// `null` = not configured (same wire output as a
  /// disabled instance).
  final ApulsatorSettings? apulsator;

  /// Configuration for the `aresample` audio effect.
  ///
  /// `null` = not configured (same wire output as a
  /// disabled instance).
  final AresampleSettings? aresample;

  /// Configuration for the `arnndn` audio effect.
  ///
  /// `null` = not configured (same wire output as a
  /// disabled instance).
  final ArnndnSettings? arnndn;

  /// Configuration for the `asetrate` audio effect.
  ///
  /// `null` = not configured (same wire output as a
  /// disabled instance).
  final AsetrateSettings? asetrate;

  /// Configuration for the `asoftclip` audio effect.
  ///
  /// `null` = not configured (same wire output as a
  /// disabled instance).
  final AsoftclipSettings? asoftclip;

  /// Configuration for the `asubboost` audio effect.
  ///
  /// `null` = not configured (same wire output as a
  /// disabled instance).
  final AsubboostSettings? asubboost;

  /// Configuration for the `asubcut` audio effect.
  ///
  /// `null` = not configured (same wire output as a
  /// disabled instance).
  final AsubcutSettings? asubcut;

  /// Configuration for the `asupercut` audio effect.
  ///
  /// `null` = not configured (same wire output as a
  /// disabled instance).
  final AsupercutSettings? asupercut;

  /// Configuration for the `asuperpass` audio effect.
  ///
  /// `null` = not configured (same wire output as a
  /// disabled instance).
  final AsuperpassSettings? asuperpass;

  /// Configuration for the `asuperstop` audio effect.
  ///
  /// `null` = not configured (same wire output as a
  /// disabled instance).
  final AsuperstopSettings? asuperstop;

  /// Configuration for the `atempo` audio effect.
  ///
  /// `null` = not configured (same wire output as a
  /// disabled instance).
  final AtempoSettings? atempo;

  /// Configuration for the `atilt` audio effect.
  ///
  /// `null` = not configured (same wire output as a
  /// disabled instance).
  final AtiltSettings? atilt;

  /// Configuration for the `bandpass` audio effect.
  ///
  /// `null` = not configured (same wire output as a
  /// disabled instance).
  final BandpassSettings? bandpass;

  /// Configuration for the `bandreject` audio effect.
  ///
  /// `null` = not configured (same wire output as a
  /// disabled instance).
  final BandrejectSettings? bandreject;

  /// Configuration for the `bass` audio effect.
  ///
  /// `null` = not configured (same wire output as a
  /// disabled instance).
  final BassSettings? bass;

  /// Configuration for the `biquad` audio effect.
  ///
  /// `null` = not configured (same wire output as a
  /// disabled instance).
  final BiquadSettings? biquad;

  /// Configuration for the `channelmap` audio effect.
  ///
  /// `null` = not configured (same wire output as a
  /// disabled instance).
  final ChannelmapSettings? channelmap;

  /// Configuration for the `chorus` audio effect.
  ///
  /// `null` = not configured (same wire output as a
  /// disabled instance).
  final ChorusSettings? chorus;

  /// Configuration for the `compand` audio effect.
  ///
  /// `null` = not configured (same wire output as a
  /// disabled instance).
  final CompandSettings? compand;

  /// Configuration for the `compensationdelay` audio effect.
  ///
  /// `null` = not configured (same wire output as a
  /// disabled instance).
  final CompensationdelaySettings? compensationdelay;

  /// Configuration for the `crossfeed` audio effect.
  ///
  /// `null` = not configured (same wire output as a
  /// disabled instance).
  final CrossfeedSettings? crossfeed;

  /// Configuration for the `crystalizer` audio effect.
  ///
  /// `null` = not configured (same wire output as a
  /// disabled instance).
  final CrystalizerSettings? crystalizer;

  /// Configuration for the `dcshift` audio effect.
  ///
  /// `null` = not configured (same wire output as a
  /// disabled instance).
  final DcshiftSettings? dcshift;

  /// Configuration for the `deesser` audio effect.
  ///
  /// `null` = not configured (same wire output as a
  /// disabled instance).
  final DeesserSettings? deesser;

  /// Configuration for the `dialoguenhance` audio effect.
  ///
  /// `null` = not configured (same wire output as a
  /// disabled instance).
  final DialoguenhanceSettings? dialoguenhance;

  /// Configuration for the `drmeter` audio effect.
  ///
  /// `null` = not configured (same wire output as a
  /// disabled instance).
  final DrmeterSettings? drmeter;

  /// Configuration for the `dynaudnorm` audio effect.
  ///
  /// `null` = not configured (same wire output as a
  /// disabled instance).
  final DynaudnormSettings? dynaudnorm;

  /// Configuration for the `earwax` audio effect.
  ///
  /// `null` = not configured (same wire output as a
  /// disabled instance).
  final EarwaxSettings? earwax;

  /// Configuration for the `ebur128` audio effect.
  ///
  /// `null` = not configured (same wire output as a
  /// disabled instance).
  final Ebur128Settings? ebur128;

  /// Configuration for the `equalizer` audio effect.
  ///
  /// `null` = not configured (same wire output as a
  /// disabled instance).
  final EqualizerSettings? equalizer;

  /// Configuration for the `extrastereo` audio effect.
  ///
  /// `null` = not configured (same wire output as a
  /// disabled instance).
  final ExtrastereoSettings? extrastereo;

  /// Configuration for the `firequalizer` audio effect.
  ///
  /// `null` = not configured (same wire output as a
  /// disabled instance).
  final FirequalizerSettings? firequalizer;

  /// Configuration for the `flanger` audio effect.
  ///
  /// `null` = not configured (same wire output as a
  /// disabled instance).
  final FlangerSettings? flanger;

  /// Configuration for the `haas` audio effect.
  ///
  /// `null` = not configured (same wire output as a
  /// disabled instance).
  final HaasSettings? haas;

  /// Configuration for the `hdcd` audio effect.
  ///
  /// `null` = not configured (same wire output as a
  /// disabled instance).
  final HdcdSettings? hdcd;

  /// Configuration for the `highpass` audio effect.
  ///
  /// `null` = not configured (same wire output as a
  /// disabled instance).
  final HighpassSettings? highpass;

  /// Configuration for the `highshelf` audio effect.
  ///
  /// `null` = not configured (same wire output as a
  /// disabled instance).
  final HighshelfSettings? highshelf;

  /// Configuration for the `loudnorm` audio effect.
  ///
  /// `null` = not configured (same wire output as a
  /// disabled instance).
  final LoudnormSettings? loudnorm;

  /// Configuration for the `lowpass` audio effect.
  ///
  /// `null` = not configured (same wire output as a
  /// disabled instance).
  final LowpassSettings? lowpass;

  /// Configuration for the `lowshelf` audio effect.
  ///
  /// `null` = not configured (same wire output as a
  /// disabled instance).
  final LowshelfSettings? lowshelf;

  /// Configuration for the `mcompand` audio effect.
  ///
  /// `null` = not configured (same wire output as a
  /// disabled instance).
  final McompandSettings? mcompand;

  /// Configuration for the `pan` audio effect.
  ///
  /// `null` = not configured (same wire output as a
  /// disabled instance).
  final PanSettings? pan;

  /// Configuration for the `rubberband` audio effect.
  ///
  /// `null` = not configured (same wire output as a
  /// disabled instance).
  final RubberbandSettings? rubberband;

  /// Configuration for the `silenceremove` audio effect.
  ///
  /// `null` = not configured (same wire output as a
  /// disabled instance).
  final SilenceremoveSettings? silenceremove;

  /// Configuration for the `speechnorm` audio effect.
  ///
  /// `null` = not configured (same wire output as a
  /// disabled instance).
  final SpeechnormSettings? speechnorm;

  /// Configuration for the `stereotools` audio effect.
  ///
  /// `null` = not configured (same wire output as a
  /// disabled instance).
  final StereotoolsSettings? stereotools;

  /// Configuration for the `stereowiden` audio effect.
  ///
  /// `null` = not configured (same wire output as a
  /// disabled instance).
  final StereowidenSettings? stereowiden;

  /// Configuration for the `superequalizer` audio effect.
  ///
  /// `null` = not configured (same wire output as a
  /// disabled instance).
  final SuperequalizerSettings? superequalizer;

  /// Configuration for the `surround` audio effect.
  ///
  /// `null` = not configured (same wire output as a
  /// disabled instance).
  final SurroundSettings? surround;

  /// Configuration for the `tiltshelf` audio effect.
  ///
  /// `null` = not configured (same wire output as a
  /// disabled instance).
  final TiltshelfSettings? tiltshelf;

  /// Configuration for the `treble` audio effect.
  ///
  /// `null` = not configured (same wire output as a
  /// disabled instance).
  final TrebleSettings? treble;

  /// Configuration for the `tremolo` audio effect.
  ///
  /// `null` = not configured (same wire output as a
  /// disabled instance).
  final TremoloSettings? tremolo;

  /// Configuration for the `vibrato` audio effect.
  ///
  /// `null` = not configured (same wire output as a
  /// disabled instance).
  final VibratoSettings? vibrato;

  /// Configuration for the `virtualbass` audio effect.
  ///
  /// `null` = not configured (same wire output as a
  /// disabled instance).
  final VirtualbassSettings? virtualbass;

  /// Creates an [AudioEffects] bundle.
  ///
  /// Every effect defaults to `null` (not configured); assign the
  /// ones you need and apply the whole bundle atomically.
  const AudioEffects({
    this.custom = const <String>[],
    this.acompressor,
    this.acontrast,
    this.acrusher,
    this.adeclick,
    this.adeclip,
    this.adecorrelate,
    this.adelay,
    this.adenorm,
    this.aderivative,
    this.adrc,
    this.adynamicequalizer,
    this.adynamicsmooth,
    this.aecho,
    this.aemphasis,
    this.aeval,
    this.aexciter,
    this.afade,
    this.afftdn,
    this.afftfilt,
    this.aformat,
    this.afreqshift,
    this.afwtdn,
    this.agate,
    this.aiir,
    this.aintegral,
    this.alimiter,
    this.allpass,
    this.anequalizer,
    this.anlmdn,
    this.apad,
    this.aphaser,
    this.aphaseshift,
    this.apsyclip,
    this.apulsator,
    this.aresample,
    this.arnndn,
    this.asetrate,
    this.asoftclip,
    this.asubboost,
    this.asubcut,
    this.asupercut,
    this.asuperpass,
    this.asuperstop,
    this.atempo,
    this.atilt,
    this.bandpass,
    this.bandreject,
    this.bass,
    this.biquad,
    this.channelmap,
    this.chorus,
    this.compand,
    this.compensationdelay,
    this.crossfeed,
    this.crystalizer,
    this.dcshift,
    this.deesser,
    this.dialoguenhance,
    this.drmeter,
    this.dynaudnorm,
    this.earwax,
    this.ebur128,
    this.equalizer,
    this.extrastereo,
    this.firequalizer,
    this.flanger,
    this.haas,
    this.hdcd,
    this.highpass,
    this.highshelf,
    this.loudnorm,
    this.lowpass,
    this.lowshelf,
    this.mcompand,
    this.pan,
    this.rubberband,
    this.silenceremove,
    this.speechnorm,
    this.stereotools,
    this.stereowiden,
    this.superequalizer,
    this.surround,
    this.tiltshelf,
    this.treble,
    this.tremolo,
    this.vibrato,
    this.virtualbass,
  });

  /// Returns a copy of this bundle with the given effects replaced.
  ///
  /// A `null` argument keeps the current value. To take a stage
  /// out of the chain, disable it via its `enabled` flag — on the
  /// wire that is identical to an unset slot.
  AudioEffects copyWith({
    List<String>? custom,
    AcompressorSettings? acompressor,
    AcontrastSettings? acontrast,
    AcrusherSettings? acrusher,
    AdeclickSettings? adeclick,
    AdeclipSettings? adeclip,
    AdecorrelateSettings? adecorrelate,
    AdelaySettings? adelay,
    AdenormSettings? adenorm,
    AderivativeSettings? aderivative,
    AdrcSettings? adrc,
    AdynamicequalizerSettings? adynamicequalizer,
    AdynamicsmoothSettings? adynamicsmooth,
    AechoSettings? aecho,
    AemphasisSettings? aemphasis,
    AevalSettings? aeval,
    AexciterSettings? aexciter,
    AfadeSettings? afade,
    AfftdnSettings? afftdn,
    AfftfiltSettings? afftfilt,
    AformatSettings? aformat,
    AfreqshiftSettings? afreqshift,
    AfwtdnSettings? afwtdn,
    AgateSettings? agate,
    AiirSettings? aiir,
    AintegralSettings? aintegral,
    AlimiterSettings? alimiter,
    AllpassSettings? allpass,
    AnequalizerSettings? anequalizer,
    AnlmdnSettings? anlmdn,
    ApadSettings? apad,
    AphaserSettings? aphaser,
    AphaseshiftSettings? aphaseshift,
    ApsyclipSettings? apsyclip,
    ApulsatorSettings? apulsator,
    AresampleSettings? aresample,
    ArnndnSettings? arnndn,
    AsetrateSettings? asetrate,
    AsoftclipSettings? asoftclip,
    AsubboostSettings? asubboost,
    AsubcutSettings? asubcut,
    AsupercutSettings? asupercut,
    AsuperpassSettings? asuperpass,
    AsuperstopSettings? asuperstop,
    AtempoSettings? atempo,
    AtiltSettings? atilt,
    BandpassSettings? bandpass,
    BandrejectSettings? bandreject,
    BassSettings? bass,
    BiquadSettings? biquad,
    ChannelmapSettings? channelmap,
    ChorusSettings? chorus,
    CompandSettings? compand,
    CompensationdelaySettings? compensationdelay,
    CrossfeedSettings? crossfeed,
    CrystalizerSettings? crystalizer,
    DcshiftSettings? dcshift,
    DeesserSettings? deesser,
    DialoguenhanceSettings? dialoguenhance,
    DrmeterSettings? drmeter,
    DynaudnormSettings? dynaudnorm,
    EarwaxSettings? earwax,
    Ebur128Settings? ebur128,
    EqualizerSettings? equalizer,
    ExtrastereoSettings? extrastereo,
    FirequalizerSettings? firequalizer,
    FlangerSettings? flanger,
    HaasSettings? haas,
    HdcdSettings? hdcd,
    HighpassSettings? highpass,
    HighshelfSettings? highshelf,
    LoudnormSettings? loudnorm,
    LowpassSettings? lowpass,
    LowshelfSettings? lowshelf,
    McompandSettings? mcompand,
    PanSettings? pan,
    RubberbandSettings? rubberband,
    SilenceremoveSettings? silenceremove,
    SpeechnormSettings? speechnorm,
    StereotoolsSettings? stereotools,
    StereowidenSettings? stereowiden,
    SuperequalizerSettings? superequalizer,
    SurroundSettings? surround,
    TiltshelfSettings? tiltshelf,
    TrebleSettings? treble,
    TremoloSettings? tremolo,
    VibratoSettings? vibrato,
    VirtualbassSettings? virtualbass,
  }) =>
      AudioEffects(
        custom: custom ?? this.custom,
        acompressor: acompressor ?? this.acompressor,
        acontrast: acontrast ?? this.acontrast,
        acrusher: acrusher ?? this.acrusher,
        adeclick: adeclick ?? this.adeclick,
        adeclip: adeclip ?? this.adeclip,
        adecorrelate: adecorrelate ?? this.adecorrelate,
        adelay: adelay ?? this.adelay,
        adenorm: adenorm ?? this.adenorm,
        aderivative: aderivative ?? this.aderivative,
        adrc: adrc ?? this.adrc,
        adynamicequalizer: adynamicequalizer ?? this.adynamicequalizer,
        adynamicsmooth: adynamicsmooth ?? this.adynamicsmooth,
        aecho: aecho ?? this.aecho,
        aemphasis: aemphasis ?? this.aemphasis,
        aeval: aeval ?? this.aeval,
        aexciter: aexciter ?? this.aexciter,
        afade: afade ?? this.afade,
        afftdn: afftdn ?? this.afftdn,
        afftfilt: afftfilt ?? this.afftfilt,
        aformat: aformat ?? this.aformat,
        afreqshift: afreqshift ?? this.afreqshift,
        afwtdn: afwtdn ?? this.afwtdn,
        agate: agate ?? this.agate,
        aiir: aiir ?? this.aiir,
        aintegral: aintegral ?? this.aintegral,
        alimiter: alimiter ?? this.alimiter,
        allpass: allpass ?? this.allpass,
        anequalizer: anequalizer ?? this.anequalizer,
        anlmdn: anlmdn ?? this.anlmdn,
        apad: apad ?? this.apad,
        aphaser: aphaser ?? this.aphaser,
        aphaseshift: aphaseshift ?? this.aphaseshift,
        apsyclip: apsyclip ?? this.apsyclip,
        apulsator: apulsator ?? this.apulsator,
        aresample: aresample ?? this.aresample,
        arnndn: arnndn ?? this.arnndn,
        asetrate: asetrate ?? this.asetrate,
        asoftclip: asoftclip ?? this.asoftclip,
        asubboost: asubboost ?? this.asubboost,
        asubcut: asubcut ?? this.asubcut,
        asupercut: asupercut ?? this.asupercut,
        asuperpass: asuperpass ?? this.asuperpass,
        asuperstop: asuperstop ?? this.asuperstop,
        atempo: atempo ?? this.atempo,
        atilt: atilt ?? this.atilt,
        bandpass: bandpass ?? this.bandpass,
        bandreject: bandreject ?? this.bandreject,
        bass: bass ?? this.bass,
        biquad: biquad ?? this.biquad,
        channelmap: channelmap ?? this.channelmap,
        chorus: chorus ?? this.chorus,
        compand: compand ?? this.compand,
        compensationdelay: compensationdelay ?? this.compensationdelay,
        crossfeed: crossfeed ?? this.crossfeed,
        crystalizer: crystalizer ?? this.crystalizer,
        dcshift: dcshift ?? this.dcshift,
        deesser: deesser ?? this.deesser,
        dialoguenhance: dialoguenhance ?? this.dialoguenhance,
        drmeter: drmeter ?? this.drmeter,
        dynaudnorm: dynaudnorm ?? this.dynaudnorm,
        earwax: earwax ?? this.earwax,
        ebur128: ebur128 ?? this.ebur128,
        equalizer: equalizer ?? this.equalizer,
        extrastereo: extrastereo ?? this.extrastereo,
        firequalizer: firequalizer ?? this.firequalizer,
        flanger: flanger ?? this.flanger,
        haas: haas ?? this.haas,
        hdcd: hdcd ?? this.hdcd,
        highpass: highpass ?? this.highpass,
        highshelf: highshelf ?? this.highshelf,
        loudnorm: loudnorm ?? this.loudnorm,
        lowpass: lowpass ?? this.lowpass,
        lowshelf: lowshelf ?? this.lowshelf,
        mcompand: mcompand ?? this.mcompand,
        pan: pan ?? this.pan,
        rubberband: rubberband ?? this.rubberband,
        silenceremove: silenceremove ?? this.silenceremove,
        speechnorm: speechnorm ?? this.speechnorm,
        stereotools: stereotools ?? this.stereotools,
        stereowiden: stereowiden ?? this.stereowiden,
        superequalizer: superequalizer ?? this.superequalizer,
        surround: surround ?? this.surround,
        tiltshelf: tiltshelf ?? this.tiltshelf,
        treble: treble ?? this.treble,
        tremolo: tremolo ?? this.tremolo,
        vibrato: vibrato ?? this.vibrato,
        virtualbass: virtualbass ?? this.virtualbass,
      );

  /// Returns a copy with the `acompressor` slot transformed by [f];
  /// a never-configured (`null`) slot is seeded with its
  /// defaults first.
  AudioEffects updateAcompressor(
          AcompressorSettings Function(AcompressorSettings) f,) =>
      copyWith(acompressor: f(acompressor ?? const AcompressorSettings()));

  /// Returns a copy with the `acontrast` slot transformed by [f];
  /// a never-configured (`null`) slot is seeded with its
  /// defaults first.
  AudioEffects updateAcontrast(
          AcontrastSettings Function(AcontrastSettings) f,) =>
      copyWith(acontrast: f(acontrast ?? const AcontrastSettings()));

  /// Returns a copy with the `acrusher` slot transformed by [f];
  /// a never-configured (`null`) slot is seeded with its
  /// defaults first.
  AudioEffects updateAcrusher(AcrusherSettings Function(AcrusherSettings) f) =>
      copyWith(acrusher: f(acrusher ?? const AcrusherSettings()));

  /// Returns a copy with the `adeclick` slot transformed by [f];
  /// a never-configured (`null`) slot is seeded with its
  /// defaults first.
  AudioEffects updateAdeclick(AdeclickSettings Function(AdeclickSettings) f) =>
      copyWith(adeclick: f(adeclick ?? const AdeclickSettings()));

  /// Returns a copy with the `adeclip` slot transformed by [f];
  /// a never-configured (`null`) slot is seeded with its
  /// defaults first.
  AudioEffects updateAdeclip(AdeclipSettings Function(AdeclipSettings) f) =>
      copyWith(adeclip: f(adeclip ?? const AdeclipSettings()));

  /// Returns a copy with the `adecorrelate` slot transformed by [f];
  /// a never-configured (`null`) slot is seeded with its
  /// defaults first.
  AudioEffects updateAdecorrelate(
          AdecorrelateSettings Function(AdecorrelateSettings) f,) =>
      copyWith(adecorrelate: f(adecorrelate ?? const AdecorrelateSettings()));

  /// Returns a copy with the `adelay` slot transformed by [f];
  /// a never-configured (`null`) slot is seeded with its
  /// defaults first.
  AudioEffects updateAdelay(AdelaySettings Function(AdelaySettings) f) =>
      copyWith(adelay: f(adelay ?? const AdelaySettings()));

  /// Returns a copy with the `adenorm` slot transformed by [f];
  /// a never-configured (`null`) slot is seeded with its
  /// defaults first.
  AudioEffects updateAdenorm(AdenormSettings Function(AdenormSettings) f) =>
      copyWith(adenorm: f(adenorm ?? const AdenormSettings()));

  /// Returns a copy with the `aderivative` slot transformed by [f];
  /// a never-configured (`null`) slot is seeded with its
  /// defaults first.
  AudioEffects updateAderivative(
          AderivativeSettings Function(AderivativeSettings) f,) =>
      copyWith(aderivative: f(aderivative ?? const AderivativeSettings()));

  /// Returns a copy with the `adrc` slot transformed by [f];
  /// a never-configured (`null`) slot is seeded with its
  /// defaults first.
  AudioEffects updateAdrc(AdrcSettings Function(AdrcSettings) f) =>
      copyWith(adrc: f(adrc ?? const AdrcSettings()));

  /// Returns a copy with the `adynamicequalizer` slot transformed by [f];
  /// a never-configured (`null`) slot is seeded with its
  /// defaults first.
  AudioEffects updateAdynamicequalizer(
          AdynamicequalizerSettings Function(AdynamicequalizerSettings) f,) =>
      copyWith(
          adynamicequalizer:
              f(adynamicequalizer ?? const AdynamicequalizerSettings()),);

  /// Returns a copy with the `adynamicsmooth` slot transformed by [f];
  /// a never-configured (`null`) slot is seeded with its
  /// defaults first.
  AudioEffects updateAdynamicsmooth(
          AdynamicsmoothSettings Function(AdynamicsmoothSettings) f,) =>
      copyWith(
          adynamicsmooth: f(adynamicsmooth ?? const AdynamicsmoothSettings()),);

  /// Returns a copy with the `aecho` slot transformed by [f];
  /// a never-configured (`null`) slot is seeded with its
  /// defaults first.
  AudioEffects updateAecho(AechoSettings Function(AechoSettings) f) =>
      copyWith(aecho: f(aecho ?? const AechoSettings()));

  /// Returns a copy with the `aemphasis` slot transformed by [f];
  /// a never-configured (`null`) slot is seeded with its
  /// defaults first.
  AudioEffects updateAemphasis(
          AemphasisSettings Function(AemphasisSettings) f,) =>
      copyWith(aemphasis: f(aemphasis ?? const AemphasisSettings()));

  /// Returns a copy with the `aeval` slot transformed by [f];
  /// a never-configured (`null`) slot is seeded with its
  /// defaults first.
  AudioEffects updateAeval(AevalSettings Function(AevalSettings) f) =>
      copyWith(aeval: f(aeval ?? const AevalSettings(exprs: 'val(0)|val(1)')));

  /// Returns a copy with the `aexciter` slot transformed by [f];
  /// a never-configured (`null`) slot is seeded with its
  /// defaults first.
  AudioEffects updateAexciter(AexciterSettings Function(AexciterSettings) f) =>
      copyWith(aexciter: f(aexciter ?? const AexciterSettings()));

  /// Returns a copy with the `afade` slot transformed by [f];
  /// a never-configured (`null`) slot is seeded with its
  /// defaults first.
  AudioEffects updateAfade(AfadeSettings Function(AfadeSettings) f) =>
      copyWith(afade: f(afade ?? const AfadeSettings()));

  /// Returns a copy with the `afftdn` slot transformed by [f];
  /// a never-configured (`null`) slot is seeded with its
  /// defaults first.
  AudioEffects updateAfftdn(AfftdnSettings Function(AfftdnSettings) f) =>
      copyWith(afftdn: f(afftdn ?? const AfftdnSettings()));

  /// Returns a copy with the `afftfilt` slot transformed by [f];
  /// a never-configured (`null`) slot is seeded with its
  /// defaults first.
  AudioEffects updateAfftfilt(AfftfiltSettings Function(AfftfiltSettings) f) =>
      copyWith(afftfilt: f(afftfilt ?? const AfftfiltSettings()));

  /// Returns a copy with the `aformat` slot transformed by [f];
  /// a never-configured (`null`) slot is seeded with its
  /// defaults first.
  AudioEffects updateAformat(AformatSettings Function(AformatSettings) f) =>
      copyWith(aformat: f(aformat ?? const AformatSettings()));

  /// Returns a copy with the `afreqshift` slot transformed by [f];
  /// a never-configured (`null`) slot is seeded with its
  /// defaults first.
  AudioEffects updateAfreqshift(
          AfreqshiftSettings Function(AfreqshiftSettings) f,) =>
      copyWith(afreqshift: f(afreqshift ?? const AfreqshiftSettings()));

  /// Returns a copy with the `afwtdn` slot transformed by [f];
  /// a never-configured (`null`) slot is seeded with its
  /// defaults first.
  AudioEffects updateAfwtdn(AfwtdnSettings Function(AfwtdnSettings) f) =>
      copyWith(afwtdn: f(afwtdn ?? const AfwtdnSettings()));

  /// Returns a copy with the `agate` slot transformed by [f];
  /// a never-configured (`null`) slot is seeded with its
  /// defaults first.
  AudioEffects updateAgate(AgateSettings Function(AgateSettings) f) =>
      copyWith(agate: f(agate ?? const AgateSettings()));

  /// Returns a copy with the `aiir` slot transformed by [f];
  /// a never-configured (`null`) slot is seeded with its
  /// defaults first.
  AudioEffects updateAiir(AiirSettings Function(AiirSettings) f) =>
      copyWith(aiir: f(aiir ?? const AiirSettings()));

  /// Returns a copy with the `aintegral` slot transformed by [f];
  /// a never-configured (`null`) slot is seeded with its
  /// defaults first.
  AudioEffects updateAintegral(
          AintegralSettings Function(AintegralSettings) f,) =>
      copyWith(aintegral: f(aintegral ?? const AintegralSettings()));

  /// Returns a copy with the `alimiter` slot transformed by [f];
  /// a never-configured (`null`) slot is seeded with its
  /// defaults first.
  AudioEffects updateAlimiter(AlimiterSettings Function(AlimiterSettings) f) =>
      copyWith(alimiter: f(alimiter ?? const AlimiterSettings()));

  /// Returns a copy with the `allpass` slot transformed by [f];
  /// a never-configured (`null`) slot is seeded with its
  /// defaults first.
  AudioEffects updateAllpass(AllpassSettings Function(AllpassSettings) f) =>
      copyWith(allpass: f(allpass ?? const AllpassSettings()));

  /// Returns a copy with the `anequalizer` slot transformed by [f];
  /// a never-configured (`null`) slot is seeded with its
  /// defaults first.
  AudioEffects updateAnequalizer(
          AnequalizerSettings Function(AnequalizerSettings) f,) =>
      copyWith(anequalizer: f(anequalizer ?? const AnequalizerSettings()));

  /// Returns a copy with the `anlmdn` slot transformed by [f];
  /// a never-configured (`null`) slot is seeded with its
  /// defaults first.
  AudioEffects updateAnlmdn(AnlmdnSettings Function(AnlmdnSettings) f) =>
      copyWith(anlmdn: f(anlmdn ?? const AnlmdnSettings()));

  /// Returns a copy with the `apad` slot transformed by [f];
  /// a never-configured (`null`) slot is seeded with its
  /// defaults first.
  AudioEffects updateApad(ApadSettings Function(ApadSettings) f) =>
      copyWith(apad: f(apad ?? const ApadSettings()));

  /// Returns a copy with the `aphaser` slot transformed by [f];
  /// a never-configured (`null`) slot is seeded with its
  /// defaults first.
  AudioEffects updateAphaser(AphaserSettings Function(AphaserSettings) f) =>
      copyWith(aphaser: f(aphaser ?? const AphaserSettings()));

  /// Returns a copy with the `aphaseshift` slot transformed by [f];
  /// a never-configured (`null`) slot is seeded with its
  /// defaults first.
  AudioEffects updateAphaseshift(
          AphaseshiftSettings Function(AphaseshiftSettings) f,) =>
      copyWith(aphaseshift: f(aphaseshift ?? const AphaseshiftSettings()));

  /// Returns a copy with the `apsyclip` slot transformed by [f];
  /// a never-configured (`null`) slot is seeded with its
  /// defaults first.
  AudioEffects updateApsyclip(ApsyclipSettings Function(ApsyclipSettings) f) =>
      copyWith(apsyclip: f(apsyclip ?? const ApsyclipSettings()));

  /// Returns a copy with the `apulsator` slot transformed by [f];
  /// a never-configured (`null`) slot is seeded with its
  /// defaults first.
  AudioEffects updateApulsator(
          ApulsatorSettings Function(ApulsatorSettings) f,) =>
      copyWith(apulsator: f(apulsator ?? const ApulsatorSettings()));

  /// Returns a copy with the `aresample` slot transformed by [f];
  /// a never-configured (`null`) slot is seeded with its
  /// defaults first.
  AudioEffects updateAresample(
          AresampleSettings Function(AresampleSettings) f,) =>
      copyWith(aresample: f(aresample ?? const AresampleSettings()));

  /// Returns a copy with the `arnndn` slot transformed by [f];
  /// a never-configured (`null`) slot is seeded with its
  /// defaults first.
  AudioEffects updateArnndn(ArnndnSettings Function(ArnndnSettings) f) =>
      copyWith(arnndn: f(arnndn ?? const ArnndnSettings(model: '')));

  /// Returns a copy with the `asetrate` slot transformed by [f];
  /// a never-configured (`null`) slot is seeded with its
  /// defaults first.
  AudioEffects updateAsetrate(AsetrateSettings Function(AsetrateSettings) f) =>
      copyWith(asetrate: f(asetrate ?? const AsetrateSettings()));

  /// Returns a copy with the `asoftclip` slot transformed by [f];
  /// a never-configured (`null`) slot is seeded with its
  /// defaults first.
  AudioEffects updateAsoftclip(
          AsoftclipSettings Function(AsoftclipSettings) f,) =>
      copyWith(asoftclip: f(asoftclip ?? const AsoftclipSettings()));

  /// Returns a copy with the `asubboost` slot transformed by [f];
  /// a never-configured (`null`) slot is seeded with its
  /// defaults first.
  AudioEffects updateAsubboost(
          AsubboostSettings Function(AsubboostSettings) f,) =>
      copyWith(asubboost: f(asubboost ?? const AsubboostSettings()));

  /// Returns a copy with the `asubcut` slot transformed by [f];
  /// a never-configured (`null`) slot is seeded with its
  /// defaults first.
  AudioEffects updateAsubcut(AsubcutSettings Function(AsubcutSettings) f) =>
      copyWith(asubcut: f(asubcut ?? const AsubcutSettings()));

  /// Returns a copy with the `asupercut` slot transformed by [f];
  /// a never-configured (`null`) slot is seeded with its
  /// defaults first.
  AudioEffects updateAsupercut(
          AsupercutSettings Function(AsupercutSettings) f,) =>
      copyWith(asupercut: f(asupercut ?? const AsupercutSettings()));

  /// Returns a copy with the `asuperpass` slot transformed by [f];
  /// a never-configured (`null`) slot is seeded with its
  /// defaults first.
  AudioEffects updateAsuperpass(
          AsuperpassSettings Function(AsuperpassSettings) f,) =>
      copyWith(asuperpass: f(asuperpass ?? const AsuperpassSettings()));

  /// Returns a copy with the `asuperstop` slot transformed by [f];
  /// a never-configured (`null`) slot is seeded with its
  /// defaults first.
  AudioEffects updateAsuperstop(
          AsuperstopSettings Function(AsuperstopSettings) f,) =>
      copyWith(asuperstop: f(asuperstop ?? const AsuperstopSettings()));

  /// Returns a copy with the `atempo` slot transformed by [f];
  /// a never-configured (`null`) slot is seeded with its
  /// defaults first.
  AudioEffects updateAtempo(AtempoSettings Function(AtempoSettings) f) =>
      copyWith(atempo: f(atempo ?? const AtempoSettings()));

  /// Returns a copy with the `atilt` slot transformed by [f];
  /// a never-configured (`null`) slot is seeded with its
  /// defaults first.
  AudioEffects updateAtilt(AtiltSettings Function(AtiltSettings) f) =>
      copyWith(atilt: f(atilt ?? const AtiltSettings()));

  /// Returns a copy with the `bandpass` slot transformed by [f];
  /// a never-configured (`null`) slot is seeded with its
  /// defaults first.
  AudioEffects updateBandpass(BandpassSettings Function(BandpassSettings) f) =>
      copyWith(bandpass: f(bandpass ?? const BandpassSettings()));

  /// Returns a copy with the `bandreject` slot transformed by [f];
  /// a never-configured (`null`) slot is seeded with its
  /// defaults first.
  AudioEffects updateBandreject(
          BandrejectSettings Function(BandrejectSettings) f,) =>
      copyWith(bandreject: f(bandreject ?? const BandrejectSettings()));

  /// Returns a copy with the `bass` slot transformed by [f];
  /// a never-configured (`null`) slot is seeded with its
  /// defaults first.
  AudioEffects updateBass(BassSettings Function(BassSettings) f) =>
      copyWith(bass: f(bass ?? const BassSettings()));

  /// Returns a copy with the `biquad` slot transformed by [f];
  /// a never-configured (`null`) slot is seeded with its
  /// defaults first.
  AudioEffects updateBiquad(BiquadSettings Function(BiquadSettings) f) =>
      copyWith(biquad: f(biquad ?? const BiquadSettings()));

  /// Returns a copy with the `channelmap` slot transformed by [f];
  /// a never-configured (`null`) slot is seeded with its
  /// defaults first.
  AudioEffects updateChannelmap(
          ChannelmapSettings Function(ChannelmapSettings) f,) =>
      copyWith(
          channelmap: f(channelmap ?? const ChannelmapSettings(map: '0|1')),);

  /// Returns a copy with the `chorus` slot transformed by [f];
  /// a never-configured (`null`) slot is seeded with its
  /// defaults first.
  AudioEffects updateChorus(ChorusSettings Function(ChorusSettings) f) =>
      copyWith(
          chorus: f(chorus ??
              const ChorusSettings(
                  delays: '55|60',
                  decays: '0.4|0.32',
                  speeds: '0.25|0.4',
                  depths: '2|1.3',),),);

  /// Returns a copy with the `compand` slot transformed by [f];
  /// a never-configured (`null`) slot is seeded with its
  /// defaults first.
  AudioEffects updateCompand(CompandSettings Function(CompandSettings) f) =>
      copyWith(compand: f(compand ?? const CompandSettings()));

  /// Returns a copy with the `compensationdelay` slot transformed by [f];
  /// a never-configured (`null`) slot is seeded with its
  /// defaults first.
  AudioEffects updateCompensationdelay(
          CompensationdelaySettings Function(CompensationdelaySettings) f,) =>
      copyWith(
          compensationdelay:
              f(compensationdelay ?? const CompensationdelaySettings()),);

  /// Returns a copy with the `crossfeed` slot transformed by [f];
  /// a never-configured (`null`) slot is seeded with its
  /// defaults first.
  AudioEffects updateCrossfeed(
          CrossfeedSettings Function(CrossfeedSettings) f,) =>
      copyWith(crossfeed: f(crossfeed ?? const CrossfeedSettings()));

  /// Returns a copy with the `crystalizer` slot transformed by [f];
  /// a never-configured (`null`) slot is seeded with its
  /// defaults first.
  AudioEffects updateCrystalizer(
          CrystalizerSettings Function(CrystalizerSettings) f,) =>
      copyWith(crystalizer: f(crystalizer ?? const CrystalizerSettings()));

  /// Returns a copy with the `dcshift` slot transformed by [f];
  /// a never-configured (`null`) slot is seeded with its
  /// defaults first.
  AudioEffects updateDcshift(DcshiftSettings Function(DcshiftSettings) f) =>
      copyWith(dcshift: f(dcshift ?? const DcshiftSettings()));

  /// Returns a copy with the `deesser` slot transformed by [f];
  /// a never-configured (`null`) slot is seeded with its
  /// defaults first.
  AudioEffects updateDeesser(DeesserSettings Function(DeesserSettings) f) =>
      copyWith(deesser: f(deesser ?? const DeesserSettings()));

  /// Returns a copy with the `dialoguenhance` slot transformed by [f];
  /// a never-configured (`null`) slot is seeded with its
  /// defaults first.
  AudioEffects updateDialoguenhance(
          DialoguenhanceSettings Function(DialoguenhanceSettings) f,) =>
      copyWith(
          dialoguenhance: f(dialoguenhance ?? const DialoguenhanceSettings()),);

  /// Returns a copy with the `drmeter` slot transformed by [f];
  /// a never-configured (`null`) slot is seeded with its
  /// defaults first.
  AudioEffects updateDrmeter(DrmeterSettings Function(DrmeterSettings) f) =>
      copyWith(drmeter: f(drmeter ?? const DrmeterSettings()));

  /// Returns a copy with the `dynaudnorm` slot transformed by [f];
  /// a never-configured (`null`) slot is seeded with its
  /// defaults first.
  AudioEffects updateDynaudnorm(
          DynaudnormSettings Function(DynaudnormSettings) f,) =>
      copyWith(dynaudnorm: f(dynaudnorm ?? const DynaudnormSettings()));

  /// Returns a copy with the `earwax` slot transformed by [f];
  /// a never-configured (`null`) slot is seeded with its
  /// defaults first.
  AudioEffects updateEarwax(EarwaxSettings Function(EarwaxSettings) f) =>
      copyWith(earwax: f(earwax ?? const EarwaxSettings()));

  /// Returns a copy with the `ebur128` slot transformed by [f];
  /// a never-configured (`null`) slot is seeded with its
  /// defaults first.
  AudioEffects updateEbur128(Ebur128Settings Function(Ebur128Settings) f) =>
      copyWith(ebur128: f(ebur128 ?? const Ebur128Settings()));

  /// Returns a copy with the `equalizer` slot transformed by [f];
  /// a never-configured (`null`) slot is seeded with its
  /// defaults first.
  AudioEffects updateEqualizer(
          EqualizerSettings Function(EqualizerSettings) f,) =>
      copyWith(equalizer: f(equalizer ?? const EqualizerSettings()));

  /// Returns a copy with the `extrastereo` slot transformed by [f];
  /// a never-configured (`null`) slot is seeded with its
  /// defaults first.
  AudioEffects updateExtrastereo(
          ExtrastereoSettings Function(ExtrastereoSettings) f,) =>
      copyWith(extrastereo: f(extrastereo ?? const ExtrastereoSettings()));

  /// Returns a copy with the `firequalizer` slot transformed by [f];
  /// a never-configured (`null`) slot is seeded with its
  /// defaults first.
  AudioEffects updateFirequalizer(
          FirequalizerSettings Function(FirequalizerSettings) f,) =>
      copyWith(firequalizer: f(firequalizer ?? const FirequalizerSettings()));

  /// Returns a copy with the `flanger` slot transformed by [f];
  /// a never-configured (`null`) slot is seeded with its
  /// defaults first.
  AudioEffects updateFlanger(FlangerSettings Function(FlangerSettings) f) =>
      copyWith(flanger: f(flanger ?? const FlangerSettings()));

  /// Returns a copy with the `haas` slot transformed by [f];
  /// a never-configured (`null`) slot is seeded with its
  /// defaults first.
  AudioEffects updateHaas(HaasSettings Function(HaasSettings) f) =>
      copyWith(haas: f(haas ?? const HaasSettings()));

  /// Returns a copy with the `hdcd` slot transformed by [f];
  /// a never-configured (`null`) slot is seeded with its
  /// defaults first.
  AudioEffects updateHdcd(HdcdSettings Function(HdcdSettings) f) =>
      copyWith(hdcd: f(hdcd ?? const HdcdSettings()));

  /// Returns a copy with the `highpass` slot transformed by [f];
  /// a never-configured (`null`) slot is seeded with its
  /// defaults first.
  AudioEffects updateHighpass(HighpassSettings Function(HighpassSettings) f) =>
      copyWith(highpass: f(highpass ?? const HighpassSettings()));

  /// Returns a copy with the `highshelf` slot transformed by [f];
  /// a never-configured (`null`) slot is seeded with its
  /// defaults first.
  AudioEffects updateHighshelf(
          HighshelfSettings Function(HighshelfSettings) f,) =>
      copyWith(highshelf: f(highshelf ?? const HighshelfSettings()));

  /// Returns a copy with the `loudnorm` slot transformed by [f];
  /// a never-configured (`null`) slot is seeded with its
  /// defaults first.
  AudioEffects updateLoudnorm(LoudnormSettings Function(LoudnormSettings) f) =>
      copyWith(loudnorm: f(loudnorm ?? const LoudnormSettings()));

  /// Returns a copy with the `lowpass` slot transformed by [f];
  /// a never-configured (`null`) slot is seeded with its
  /// defaults first.
  AudioEffects updateLowpass(LowpassSettings Function(LowpassSettings) f) =>
      copyWith(lowpass: f(lowpass ?? const LowpassSettings()));

  /// Returns a copy with the `lowshelf` slot transformed by [f];
  /// a never-configured (`null`) slot is seeded with its
  /// defaults first.
  AudioEffects updateLowshelf(LowshelfSettings Function(LowshelfSettings) f) =>
      copyWith(lowshelf: f(lowshelf ?? const LowshelfSettings()));

  /// Returns a copy with the `mcompand` slot transformed by [f];
  /// a never-configured (`null`) slot is seeded with its
  /// defaults first.
  AudioEffects updateMcompand(McompandSettings Function(McompandSettings) f) =>
      copyWith(mcompand: f(mcompand ?? const McompandSettings()));

  /// Returns a copy with the `pan` slot transformed by [f];
  /// a never-configured (`null`) slot is seeded with its
  /// defaults first.
  AudioEffects updatePan(PanSettings Function(PanSettings) f) =>
      copyWith(pan: f(pan ?? const PanSettings(args: 'stereo|c0=c0|c1=c1')));

  /// Returns a copy with the `rubberband` slot transformed by [f];
  /// a never-configured (`null`) slot is seeded with its
  /// defaults first.
  AudioEffects updateRubberband(
          RubberbandSettings Function(RubberbandSettings) f,) =>
      copyWith(rubberband: f(rubberband ?? const RubberbandSettings()));

  /// Returns a copy with the `silenceremove` slot transformed by [f];
  /// a never-configured (`null`) slot is seeded with its
  /// defaults first.
  AudioEffects updateSilenceremove(
          SilenceremoveSettings Function(SilenceremoveSettings) f,) =>
      copyWith(
          silenceremove: f(silenceremove ?? const SilenceremoveSettings()),);

  /// Returns a copy with the `speechnorm` slot transformed by [f];
  /// a never-configured (`null`) slot is seeded with its
  /// defaults first.
  AudioEffects updateSpeechnorm(
          SpeechnormSettings Function(SpeechnormSettings) f,) =>
      copyWith(speechnorm: f(speechnorm ?? const SpeechnormSettings()));

  /// Returns a copy with the `stereotools` slot transformed by [f];
  /// a never-configured (`null`) slot is seeded with its
  /// defaults first.
  AudioEffects updateStereotools(
          StereotoolsSettings Function(StereotoolsSettings) f,) =>
      copyWith(stereotools: f(stereotools ?? const StereotoolsSettings()));

  /// Returns a copy with the `stereowiden` slot transformed by [f];
  /// a never-configured (`null`) slot is seeded with its
  /// defaults first.
  AudioEffects updateStereowiden(
          StereowidenSettings Function(StereowidenSettings) f,) =>
      copyWith(stereowiden: f(stereowiden ?? const StereowidenSettings()));

  /// Returns a copy with the `superequalizer` slot transformed by [f];
  /// a never-configured (`null`) slot is seeded with its
  /// defaults first.
  AudioEffects updateSuperequalizer(
          SuperequalizerSettings Function(SuperequalizerSettings) f,) =>
      copyWith(
          superequalizer: f(superequalizer ?? const SuperequalizerSettings()),);

  /// Returns a copy with the `surround` slot transformed by [f];
  /// a never-configured (`null`) slot is seeded with its
  /// defaults first.
  AudioEffects updateSurround(SurroundSettings Function(SurroundSettings) f) =>
      copyWith(surround: f(surround ?? const SurroundSettings()));

  /// Returns a copy with the `tiltshelf` slot transformed by [f];
  /// a never-configured (`null`) slot is seeded with its
  /// defaults first.
  AudioEffects updateTiltshelf(
          TiltshelfSettings Function(TiltshelfSettings) f,) =>
      copyWith(tiltshelf: f(tiltshelf ?? const TiltshelfSettings()));

  /// Returns a copy with the `treble` slot transformed by [f];
  /// a never-configured (`null`) slot is seeded with its
  /// defaults first.
  AudioEffects updateTreble(TrebleSettings Function(TrebleSettings) f) =>
      copyWith(treble: f(treble ?? const TrebleSettings()));

  /// Returns a copy with the `tremolo` slot transformed by [f];
  /// a never-configured (`null`) slot is seeded with its
  /// defaults first.
  AudioEffects updateTremolo(TremoloSettings Function(TremoloSettings) f) =>
      copyWith(tremolo: f(tremolo ?? const TremoloSettings()));

  /// Returns a copy with the `vibrato` slot transformed by [f];
  /// a never-configured (`null`) slot is seeded with its
  /// defaults first.
  AudioEffects updateVibrato(VibratoSettings Function(VibratoSettings) f) =>
      copyWith(vibrato: f(vibrato ?? const VibratoSettings()));

  /// Returns a copy with the `virtualbass` slot transformed by [f];
  /// a never-configured (`null`) slot is seeded with its
  /// defaults first.
  AudioEffects updateVirtualbass(
          VirtualbassSettings Function(VirtualbassSettings) f,) =>
      copyWith(virtualbass: f(virtualbass ?? const VirtualbassSettings()));

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AudioEffects &&
          _listEq(custom, other.custom) &&
          other.acompressor == acompressor &&
          other.acontrast == acontrast &&
          other.acrusher == acrusher &&
          other.adeclick == adeclick &&
          other.adeclip == adeclip &&
          other.adecorrelate == adecorrelate &&
          other.adelay == adelay &&
          other.adenorm == adenorm &&
          other.aderivative == aderivative &&
          other.adrc == adrc &&
          other.adynamicequalizer == adynamicequalizer &&
          other.adynamicsmooth == adynamicsmooth &&
          other.aecho == aecho &&
          other.aemphasis == aemphasis &&
          other.aeval == aeval &&
          other.aexciter == aexciter &&
          other.afade == afade &&
          other.afftdn == afftdn &&
          other.afftfilt == afftfilt &&
          other.aformat == aformat &&
          other.afreqshift == afreqshift &&
          other.afwtdn == afwtdn &&
          other.agate == agate &&
          other.aiir == aiir &&
          other.aintegral == aintegral &&
          other.alimiter == alimiter &&
          other.allpass == allpass &&
          other.anequalizer == anequalizer &&
          other.anlmdn == anlmdn &&
          other.apad == apad &&
          other.aphaser == aphaser &&
          other.aphaseshift == aphaseshift &&
          other.apsyclip == apsyclip &&
          other.apulsator == apulsator &&
          other.aresample == aresample &&
          other.arnndn == arnndn &&
          other.asetrate == asetrate &&
          other.asoftclip == asoftclip &&
          other.asubboost == asubboost &&
          other.asubcut == asubcut &&
          other.asupercut == asupercut &&
          other.asuperpass == asuperpass &&
          other.asuperstop == asuperstop &&
          other.atempo == atempo &&
          other.atilt == atilt &&
          other.bandpass == bandpass &&
          other.bandreject == bandreject &&
          other.bass == bass &&
          other.biquad == biquad &&
          other.channelmap == channelmap &&
          other.chorus == chorus &&
          other.compand == compand &&
          other.compensationdelay == compensationdelay &&
          other.crossfeed == crossfeed &&
          other.crystalizer == crystalizer &&
          other.dcshift == dcshift &&
          other.deesser == deesser &&
          other.dialoguenhance == dialoguenhance &&
          other.drmeter == drmeter &&
          other.dynaudnorm == dynaudnorm &&
          other.earwax == earwax &&
          other.ebur128 == ebur128 &&
          other.equalizer == equalizer &&
          other.extrastereo == extrastereo &&
          other.firequalizer == firequalizer &&
          other.flanger == flanger &&
          other.haas == haas &&
          other.hdcd == hdcd &&
          other.highpass == highpass &&
          other.highshelf == highshelf &&
          other.loudnorm == loudnorm &&
          other.lowpass == lowpass &&
          other.lowshelf == lowshelf &&
          other.mcompand == mcompand &&
          other.pan == pan &&
          other.rubberband == rubberband &&
          other.silenceremove == silenceremove &&
          other.speechnorm == speechnorm &&
          other.stereotools == stereotools &&
          other.stereowiden == stereowiden &&
          other.superequalizer == superequalizer &&
          other.surround == surround &&
          other.tiltshelf == tiltshelf &&
          other.treble == treble &&
          other.tremolo == tremolo &&
          other.vibrato == vibrato &&
          other.virtualbass == virtualbass);

  @override
  int get hashCode => Object.hashAll([
        Object.hashAll(custom),
        acompressor,
        acontrast,
        acrusher,
        adeclick,
        adeclip,
        adecorrelate,
        adelay,
        adenorm,
        aderivative,
        adrc,
        adynamicequalizer,
        adynamicsmooth,
        aecho,
        aemphasis,
        aeval,
        aexciter,
        afade,
        afftdn,
        afftfilt,
        aformat,
        afreqshift,
        afwtdn,
        agate,
        aiir,
        aintegral,
        alimiter,
        allpass,
        anequalizer,
        anlmdn,
        apad,
        aphaser,
        aphaseshift,
        apsyclip,
        apulsator,
        aresample,
        arnndn,
        asetrate,
        asoftclip,
        asubboost,
        asubcut,
        asupercut,
        asuperpass,
        asuperstop,
        atempo,
        atilt,
        bandpass,
        bandreject,
        bass,
        biquad,
        channelmap,
        chorus,
        compand,
        compensationdelay,
        crossfeed,
        crystalizer,
        dcshift,
        deesser,
        dialoguenhance,
        drmeter,
        dynaudnorm,
        earwax,
        ebur128,
        equalizer,
        extrastereo,
        firequalizer,
        flanger,
        haas,
        hdcd,
        highpass,
        highshelf,
        loudnorm,
        lowpass,
        lowshelf,
        mcompand,
        pan,
        rubberband,
        silenceremove,
        speechnorm,
        stereotools,
        stereowiden,
        superequalizer,
        surround,
        tiltshelf,
        treble,
        tremolo,
        vibrato,
        virtualbass,
      ]);

  @override
  String toString() {
    final enabled = <String>[];
    if (acompressor?.enabled ?? false) enabled.add('acompressor');
    if (acontrast?.enabled ?? false) enabled.add('acontrast');
    if (acrusher?.enabled ?? false) enabled.add('acrusher');
    if (adeclick?.enabled ?? false) enabled.add('adeclick');
    if (adeclip?.enabled ?? false) enabled.add('adeclip');
    if (adecorrelate?.enabled ?? false) enabled.add('adecorrelate');
    if (adelay?.enabled ?? false) enabled.add('adelay');
    if (adenorm?.enabled ?? false) enabled.add('adenorm');
    if (aderivative?.enabled ?? false) enabled.add('aderivative');
    if (adrc?.enabled ?? false) enabled.add('adrc');
    if (adynamicequalizer?.enabled ?? false) enabled.add('adynamicequalizer');
    if (adynamicsmooth?.enabled ?? false) enabled.add('adynamicsmooth');
    if (aecho?.enabled ?? false) enabled.add('aecho');
    if (aemphasis?.enabled ?? false) enabled.add('aemphasis');
    if (aeval?.enabled ?? false) enabled.add('aeval');
    if (aexciter?.enabled ?? false) enabled.add('aexciter');
    if (afade?.enabled ?? false) enabled.add('afade');
    if (afftdn?.enabled ?? false) enabled.add('afftdn');
    if (afftfilt?.enabled ?? false) enabled.add('afftfilt');
    if (aformat?.enabled ?? false) enabled.add('aformat');
    if (afreqshift?.enabled ?? false) enabled.add('afreqshift');
    if (afwtdn?.enabled ?? false) enabled.add('afwtdn');
    if (agate?.enabled ?? false) enabled.add('agate');
    if (aiir?.enabled ?? false) enabled.add('aiir');
    if (aintegral?.enabled ?? false) enabled.add('aintegral');
    if (alimiter?.enabled ?? false) enabled.add('alimiter');
    if (allpass?.enabled ?? false) enabled.add('allpass');
    if (anequalizer?.enabled ?? false) enabled.add('anequalizer');
    if (anlmdn?.enabled ?? false) enabled.add('anlmdn');
    if (apad?.enabled ?? false) enabled.add('apad');
    if (aphaser?.enabled ?? false) enabled.add('aphaser');
    if (aphaseshift?.enabled ?? false) enabled.add('aphaseshift');
    if (apsyclip?.enabled ?? false) enabled.add('apsyclip');
    if (apulsator?.enabled ?? false) enabled.add('apulsator');
    if (aresample?.enabled ?? false) enabled.add('aresample');
    if (arnndn?.enabled ?? false) enabled.add('arnndn');
    if (asetrate?.enabled ?? false) enabled.add('asetrate');
    if (asoftclip?.enabled ?? false) enabled.add('asoftclip');
    if (asubboost?.enabled ?? false) enabled.add('asubboost');
    if (asubcut?.enabled ?? false) enabled.add('asubcut');
    if (asupercut?.enabled ?? false) enabled.add('asupercut');
    if (asuperpass?.enabled ?? false) enabled.add('asuperpass');
    if (asuperstop?.enabled ?? false) enabled.add('asuperstop');
    if (atempo?.enabled ?? false) enabled.add('atempo');
    if (atilt?.enabled ?? false) enabled.add('atilt');
    if (bandpass?.enabled ?? false) enabled.add('bandpass');
    if (bandreject?.enabled ?? false) enabled.add('bandreject');
    if (bass?.enabled ?? false) enabled.add('bass');
    if (biquad?.enabled ?? false) enabled.add('biquad');
    if (channelmap?.enabled ?? false) enabled.add('channelmap');
    if (chorus?.enabled ?? false) enabled.add('chorus');
    if (compand?.enabled ?? false) enabled.add('compand');
    if (compensationdelay?.enabled ?? false) enabled.add('compensationdelay');
    if (crossfeed?.enabled ?? false) enabled.add('crossfeed');
    if (crystalizer?.enabled ?? false) enabled.add('crystalizer');
    if (dcshift?.enabled ?? false) enabled.add('dcshift');
    if (deesser?.enabled ?? false) enabled.add('deesser');
    if (dialoguenhance?.enabled ?? false) enabled.add('dialoguenhance');
    if (drmeter?.enabled ?? false) enabled.add('drmeter');
    if (dynaudnorm?.enabled ?? false) enabled.add('dynaudnorm');
    if (earwax?.enabled ?? false) enabled.add('earwax');
    if (ebur128?.enabled ?? false) enabled.add('ebur128');
    if (equalizer?.enabled ?? false) enabled.add('equalizer');
    if (extrastereo?.enabled ?? false) enabled.add('extrastereo');
    if (firequalizer?.enabled ?? false) enabled.add('firequalizer');
    if (flanger?.enabled ?? false) enabled.add('flanger');
    if (haas?.enabled ?? false) enabled.add('haas');
    if (hdcd?.enabled ?? false) enabled.add('hdcd');
    if (highpass?.enabled ?? false) enabled.add('highpass');
    if (highshelf?.enabled ?? false) enabled.add('highshelf');
    if (loudnorm?.enabled ?? false) enabled.add('loudnorm');
    if (lowpass?.enabled ?? false) enabled.add('lowpass');
    if (lowshelf?.enabled ?? false) enabled.add('lowshelf');
    if (mcompand?.enabled ?? false) enabled.add('mcompand');
    if (pan?.enabled ?? false) enabled.add('pan');
    if (rubberband?.enabled ?? false) enabled.add('rubberband');
    if (silenceremove?.enabled ?? false) enabled.add('silenceremove');
    if (speechnorm?.enabled ?? false) enabled.add('speechnorm');
    if (stereotools?.enabled ?? false) enabled.add('stereotools');
    if (stereowiden?.enabled ?? false) enabled.add('stereowiden');
    if (superequalizer?.enabled ?? false) enabled.add('superequalizer');
    if (surround?.enabled ?? false) enabled.add('surround');
    if (tiltshelf?.enabled ?? false) enabled.add('tiltshelf');
    if (treble?.enabled ?? false) enabled.add('treble');
    if (tremolo?.enabled ?? false) enabled.add('tremolo');
    if (vibrato?.enabled ?? false) enabled.add('vibrato');
    if (virtualbass?.enabled ?? false) enabled.add('virtualbass');
    return 'AudioEffects(custom: $custom, enabled: $enabled)';
  }

  /// Builds the audio chain string from this bundle.
  ///
  /// Returns the empty string when nothing is enabled. Raw entries
  /// from [custom] are emitted first (in declaration order), then
  /// every enabled typed stage. All entries are joined with `,`.
  String toAfChain() {
    final parts = <String>[];
    for (final raw in custom) {
      final t = raw.trim();
      if (t.isNotEmpty) parts.add(t);
    }
    if (acompressor?.enabled ?? false)
      parts.add('@aek_acompressor:' + acompressor!.toFilterString());
    if (acontrast?.enabled ?? false)
      parts.add('@aek_acontrast:' + acontrast!.toFilterString());
    if (acrusher?.enabled ?? false)
      parts.add('@aek_acrusher:' + acrusher!.toFilterString());
    if (adeclick?.enabled ?? false)
      parts.add('@aek_adeclick:' + adeclick!.toFilterString());
    if (adeclip?.enabled ?? false)
      parts.add('@aek_adeclip:' + adeclip!.toFilterString());
    if (adecorrelate?.enabled ?? false)
      parts.add('@aek_adecorrelate:' + adecorrelate!.toFilterString());
    if (adelay?.enabled ?? false)
      parts.add('@aek_adelay:' + adelay!.toFilterString());
    if (adenorm?.enabled ?? false)
      parts.add('@aek_adenorm:' + adenorm!.toFilterString());
    if (aderivative?.enabled ?? false)
      parts.add('@aek_aderivative:' + aderivative!.toFilterString());
    if (adrc?.enabled ?? false)
      parts.add('@aek_adrc:' + adrc!.toFilterString());
    if (adynamicequalizer?.enabled ?? false)
      parts
          .add('@aek_adynamicequalizer:' + adynamicequalizer!.toFilterString());
    if (adynamicsmooth?.enabled ?? false)
      parts.add('@aek_adynamicsmooth:' + adynamicsmooth!.toFilterString());
    if (aecho?.enabled ?? false)
      parts.add('@aek_aecho:' + aecho!.toFilterString());
    if (aemphasis?.enabled ?? false)
      parts.add('@aek_aemphasis:' + aemphasis!.toFilterString());
    if (aeval?.enabled ?? false)
      parts.add('@aek_aeval:' + aeval!.toFilterString());
    if (aexciter?.enabled ?? false)
      parts.add('@aek_aexciter:' + aexciter!.toFilterString());
    if (afade?.enabled ?? false)
      parts.add('@aek_afade:' + afade!.toFilterString());
    if (afftdn?.enabled ?? false)
      parts.add('@aek_afftdn:' + afftdn!.toFilterString());
    if (afftfilt?.enabled ?? false)
      parts.add('@aek_afftfilt:' + afftfilt!.toFilterString());
    if (aformat?.enabled ?? false)
      parts.add('@aek_aformat:' + aformat!.toFilterString());
    if (afreqshift?.enabled ?? false)
      parts.add('@aek_afreqshift:' + afreqshift!.toFilterString());
    if (afwtdn?.enabled ?? false)
      parts.add('@aek_afwtdn:' + afwtdn!.toFilterString());
    if (agate?.enabled ?? false)
      parts.add('@aek_agate:' + agate!.toFilterString());
    if (aiir?.enabled ?? false)
      parts.add('@aek_aiir:' + aiir!.toFilterString());
    if (aintegral?.enabled ?? false)
      parts.add('@aek_aintegral:' + aintegral!.toFilterString());
    if (allpass?.enabled ?? false)
      parts.add('@aek_allpass:' + allpass!.toFilterString());
    if (anequalizer?.enabled ?? false)
      parts.add('@aek_anequalizer:' + anequalizer!.toFilterString());
    if (anlmdn?.enabled ?? false)
      parts.add('@aek_anlmdn:' + anlmdn!.toFilterString());
    if (apad?.enabled ?? false)
      parts.add('@aek_apad:' + apad!.toFilterString());
    if (aphaser?.enabled ?? false)
      parts.add('@aek_aphaser:' + aphaser!.toFilterString());
    if (aphaseshift?.enabled ?? false)
      parts.add('@aek_aphaseshift:' + aphaseshift!.toFilterString());
    if (apsyclip?.enabled ?? false)
      parts.add('@aek_apsyclip:' + apsyclip!.toFilterString());
    if (apulsator?.enabled ?? false)
      parts.add('@aek_apulsator:' + apulsator!.toFilterString());
    if (arnndn?.enabled ?? false)
      parts.add('@aek_arnndn:' + arnndn!.toFilterString());
    if (asetrate?.enabled ?? false)
      parts.add('@aek_asetrate:' + asetrate!.toFilterString());
    if (asoftclip?.enabled ?? false)
      parts.add('@aek_asoftclip:' + asoftclip!.toFilterString());
    if (asubboost?.enabled ?? false)
      parts.add('@aek_asubboost:' + asubboost!.toFilterString());
    if (asubcut?.enabled ?? false)
      parts.add('@aek_asubcut:' + asubcut!.toFilterString());
    if (asupercut?.enabled ?? false)
      parts.add('@aek_asupercut:' + asupercut!.toFilterString());
    if (asuperpass?.enabled ?? false)
      parts.add('@aek_asuperpass:' + asuperpass!.toFilterString());
    if (asuperstop?.enabled ?? false)
      parts.add('@aek_asuperstop:' + asuperstop!.toFilterString());
    if (atempo?.enabled ?? false)
      parts.add('@aek_atempo:' + atempo!.toFilterString());
    if (atilt?.enabled ?? false)
      parts.add('@aek_atilt:' + atilt!.toFilterString());
    if (bandpass?.enabled ?? false)
      parts.add('@aek_bandpass:' + bandpass!.toFilterString());
    if (bandreject?.enabled ?? false)
      parts.add('@aek_bandreject:' + bandreject!.toFilterString());
    if (bass?.enabled ?? false)
      parts.add('@aek_bass:' + bass!.toFilterString());
    if (biquad?.enabled ?? false)
      parts.add('@aek_biquad:' + biquad!.toFilterString());
    if (channelmap?.enabled ?? false)
      parts.add('@aek_channelmap:' + channelmap!.toFilterString());
    if (chorus?.enabled ?? false)
      parts.add('@aek_chorus:' + chorus!.toFilterString());
    if (compand?.enabled ?? false)
      parts.add('@aek_compand:' + compand!.toFilterString());
    if (compensationdelay?.enabled ?? false)
      parts
          .add('@aek_compensationdelay:' + compensationdelay!.toFilterString());
    if (crossfeed?.enabled ?? false)
      parts.add('@aek_crossfeed:' + crossfeed!.toFilterString());
    if (crystalizer?.enabled ?? false)
      parts.add('@aek_crystalizer:' + crystalizer!.toFilterString());
    if (dcshift?.enabled ?? false)
      parts.add('@aek_dcshift:' + dcshift!.toFilterString());
    if (deesser?.enabled ?? false)
      parts.add('@aek_deesser:' + deesser!.toFilterString());
    if (dialoguenhance?.enabled ?? false)
      parts.add('@aek_dialoguenhance:' + dialoguenhance!.toFilterString());
    if (drmeter?.enabled ?? false)
      parts.add('@aek_drmeter:' + drmeter!.toFilterString());
    if (dynaudnorm?.enabled ?? false)
      parts.add('@aek_dynaudnorm:' + dynaudnorm!.toFilterString());
    if (earwax?.enabled ?? false)
      parts.add('@aek_earwax:' + earwax!.toFilterString());
    if (ebur128?.enabled ?? false)
      parts.add('@aek_ebur128:' + ebur128!.toFilterString());
    if (equalizer?.enabled ?? false)
      parts.add('@aek_equalizer:' + equalizer!.toFilterString());
    if (extrastereo?.enabled ?? false)
      parts.add('@aek_extrastereo:' + extrastereo!.toFilterString());
    if (firequalizer?.enabled ?? false)
      parts.add('@aek_firequalizer:' + firequalizer!.toFilterString());
    if (flanger?.enabled ?? false)
      parts.add('@aek_flanger:' + flanger!.toFilterString());
    if (haas?.enabled ?? false)
      parts.add('@aek_haas:' + haas!.toFilterString());
    if (hdcd?.enabled ?? false)
      parts.add('@aek_hdcd:' + hdcd!.toFilterString());
    if (highpass?.enabled ?? false)
      parts.add('@aek_highpass:' + highpass!.toFilterString());
    if (highshelf?.enabled ?? false)
      parts.add('@aek_highshelf:' + highshelf!.toFilterString());
    if (loudnorm?.enabled ?? false)
      parts.add('@aek_loudnorm:' + loudnorm!.toFilterString());
    if (lowpass?.enabled ?? false)
      parts.add('@aek_lowpass:' + lowpass!.toFilterString());
    if (lowshelf?.enabled ?? false)
      parts.add('@aek_lowshelf:' + lowshelf!.toFilterString());
    if (mcompand?.enabled ?? false)
      parts.add('@aek_mcompand:' + mcompand!.toFilterString());
    if (pan?.enabled ?? false) parts.add('@aek_pan:' + pan!.toFilterString());
    if (rubberband?.enabled ?? false)
      parts.add('@aek_rubberband:' + rubberband!.toFilterString());
    if (silenceremove?.enabled ?? false)
      parts.add('@aek_silenceremove:' + silenceremove!.toFilterString());
    if (speechnorm?.enabled ?? false)
      parts.add('@aek_speechnorm:' + speechnorm!.toFilterString());
    if (stereotools?.enabled ?? false)
      parts.add('@aek_stereotools:' + stereotools!.toFilterString());
    if (stereowiden?.enabled ?? false)
      parts.add('@aek_stereowiden:' + stereowiden!.toFilterString());
    if (superequalizer?.enabled ?? false)
      parts.add('@aek_superequalizer:' + superequalizer!.toFilterString());
    if (surround?.enabled ?? false)
      parts.add('@aek_surround:' + surround!.toFilterString());
    if (tiltshelf?.enabled ?? false)
      parts.add('@aek_tiltshelf:' + tiltshelf!.toFilterString());
    if (treble?.enabled ?? false)
      parts.add('@aek_treble:' + treble!.toFilterString());
    if (tremolo?.enabled ?? false)
      parts.add('@aek_tremolo:' + tremolo!.toFilterString());
    if (vibrato?.enabled ?? false)
      parts.add('@aek_vibrato:' + vibrato!.toFilterString());
    if (virtualbass?.enabled ?? false)
      parts.add('@aek_virtualbass:' + virtualbass!.toFilterString());
    // LOOPER PATCH: the limiter catches every boost before it, and the
    // resampler runs last (see LOOPER_PATCH.md).
    if (alimiter?.enabled ?? false)
      parts.add('@aek_alimiter:' + alimiter!.toFilterString());
    if (aresample?.enabled ?? false)
      parts.add('@aek_aresample:' + aresample!.toFilterString());
    return parts.join(',');
  }

  /// Computes the incremental `af-command` updates that turn the
  /// live chain built from [prev] into this bundle.
  ///
  /// Returns `null` when the change needs a full chain rebuild
  /// (an effect entered/left the chain, a non-runtime-tunable
  /// option changed, or the filter doesn't accept live commands);
  /// an empty list when the two bundles are wire-identical.
  List<AfCommand>? diffCommands(AudioEffects prev) {
    if (!_listEq(custom, prev.custom)) return null;
    final out = <AfCommand>[];
    {
      final a = prev.acompressor;
      final b = acompressor;
      if ((a?.enabled ?? false) != (b?.enabled ?? false)) return null;
      if ((b?.enabled ?? false) && !identical(a, b)) {
        final d = b!._runtimeDiff(a!);
        if (d == null) return null;
        for (final (opt, val) in d) {
          out.add((
            label: 'aek_acompressor',
            option: opt,
            value: val,
            filterName: 'acompressor'
          ),);
        }
      }
    }
    {
      final a = prev.acontrast;
      final b = acontrast;
      if ((a?.enabled ?? false) != (b?.enabled ?? false)) return null;
      if ((b?.enabled ?? false) && a != b) return null;
    }
    {
      final a = prev.acrusher;
      final b = acrusher;
      if ((a?.enabled ?? false) != (b?.enabled ?? false)) return null;
      if ((b?.enabled ?? false) && !identical(a, b)) {
        final d = b!._runtimeDiff(a!);
        if (d == null) return null;
        for (final (opt, val) in d) {
          out.add((
            label: 'aek_acrusher',
            option: opt,
            value: val,
            filterName: 'acrusher'
          ),);
        }
      }
    }
    {
      final a = prev.adeclick;
      final b = adeclick;
      if ((a?.enabled ?? false) != (b?.enabled ?? false)) return null;
      if ((b?.enabled ?? false) && a != b) return null;
    }
    {
      final a = prev.adeclip;
      final b = adeclip;
      if ((a?.enabled ?? false) != (b?.enabled ?? false)) return null;
      if ((b?.enabled ?? false) && a != b) return null;
    }
    {
      final a = prev.adecorrelate;
      final b = adecorrelate;
      if ((a?.enabled ?? false) != (b?.enabled ?? false)) return null;
      if ((b?.enabled ?? false) && a != b) return null;
    }
    {
      final a = prev.adelay;
      final b = adelay;
      if ((a?.enabled ?? false) != (b?.enabled ?? false)) return null;
      if ((b?.enabled ?? false) && !identical(a, b)) {
        final d = b!._runtimeDiff(a!);
        if (d == null) return null;
        for (final (opt, val) in d) {
          out.add((
            label: 'aek_adelay',
            option: opt,
            value: val,
            filterName: 'adelay'
          ),);
        }
      }
    }
    {
      final a = prev.adenorm;
      final b = adenorm;
      if ((a?.enabled ?? false) != (b?.enabled ?? false)) return null;
      if ((b?.enabled ?? false) && !identical(a, b)) {
        final d = b!._runtimeDiff(a!);
        if (d == null) return null;
        for (final (opt, val) in d) {
          out.add((
            label: 'aek_adenorm',
            option: opt,
            value: val,
            filterName: 'adenorm'
          ),);
        }
      }
    }
    {
      final a = prev.aderivative;
      final b = aderivative;
      if ((a?.enabled ?? false) != (b?.enabled ?? false)) return null;
      if ((b?.enabled ?? false) && a != b) return null;
    }
    {
      final a = prev.adrc;
      final b = adrc;
      if ((a?.enabled ?? false) != (b?.enabled ?? false)) return null;
      if ((b?.enabled ?? false) && !identical(a, b)) {
        final d = b!._runtimeDiff(a!);
        if (d == null) return null;
        for (final (opt, val) in d) {
          out.add(
              (label: 'aek_adrc', option: opt, value: val, filterName: 'adrc'),);
        }
      }
    }
    {
      final a = prev.adynamicequalizer;
      final b = adynamicequalizer;
      if ((a?.enabled ?? false) != (b?.enabled ?? false)) return null;
      if ((b?.enabled ?? false) && !identical(a, b)) {
        final d = b!._runtimeDiff(a!);
        if (d == null) return null;
        for (final (opt, val) in d) {
          out.add((
            label: 'aek_adynamicequalizer',
            option: opt,
            value: val,
            filterName: 'adynamicequalizer'
          ),);
        }
      }
    }
    {
      final a = prev.adynamicsmooth;
      final b = adynamicsmooth;
      if ((a?.enabled ?? false) != (b?.enabled ?? false)) return null;
      if ((b?.enabled ?? false) && !identical(a, b)) {
        final d = b!._runtimeDiff(a!);
        if (d == null) return null;
        for (final (opt, val) in d) {
          out.add((
            label: 'aek_adynamicsmooth',
            option: opt,
            value: val,
            filterName: 'adynamicsmooth'
          ),);
        }
      }
    }
    {
      final a = prev.aecho;
      final b = aecho;
      if ((a?.enabled ?? false) != (b?.enabled ?? false)) return null;
      if ((b?.enabled ?? false) && a != b) return null;
    }
    {
      final a = prev.aemphasis;
      final b = aemphasis;
      if ((a?.enabled ?? false) != (b?.enabled ?? false)) return null;
      if ((b?.enabled ?? false) && !identical(a, b)) {
        final d = b!._runtimeDiff(a!);
        if (d == null) return null;
        for (final (opt, val) in d) {
          out.add((
            label: 'aek_aemphasis',
            option: opt,
            value: val,
            filterName: 'aemphasis'
          ),);
        }
      }
    }
    {
      final a = prev.aeval;
      final b = aeval;
      if ((a?.enabled ?? false) != (b?.enabled ?? false)) return null;
      if ((b?.enabled ?? false) && a != b) return null;
    }
    {
      final a = prev.aexciter;
      final b = aexciter;
      if ((a?.enabled ?? false) != (b?.enabled ?? false)) return null;
      if ((b?.enabled ?? false) && !identical(a, b)) {
        final d = b!._runtimeDiff(a!);
        if (d == null) return null;
        for (final (opt, val) in d) {
          out.add((
            label: 'aek_aexciter',
            option: opt,
            value: val,
            filterName: 'aexciter'
          ),);
        }
      }
    }
    {
      final a = prev.afade;
      final b = afade;
      if ((a?.enabled ?? false) != (b?.enabled ?? false)) return null;
      if ((b?.enabled ?? false) && !identical(a, b)) {
        final d = b!._runtimeDiff(a!);
        if (d == null) return null;
        for (final (opt, val) in d) {
          out.add((
            label: 'aek_afade',
            option: opt,
            value: val,
            filterName: 'afade'
          ),);
        }
      }
    }
    {
      final a = prev.afftdn;
      final b = afftdn;
      if ((a?.enabled ?? false) != (b?.enabled ?? false)) return null;
      if ((b?.enabled ?? false) && !identical(a, b)) {
        final d = b!._runtimeDiff(a!);
        if (d == null) return null;
        for (final (opt, val) in d) {
          out.add((
            label: 'aek_afftdn',
            option: opt,
            value: val,
            filterName: 'afftdn'
          ),);
        }
      }
    }
    {
      final a = prev.afftfilt;
      final b = afftfilt;
      if ((a?.enabled ?? false) != (b?.enabled ?? false)) return null;
      if ((b?.enabled ?? false) && a != b) return null;
    }
    {
      final a = prev.aformat;
      final b = aformat;
      if ((a?.enabled ?? false) != (b?.enabled ?? false)) return null;
      if ((b?.enabled ?? false) && a != b) return null;
    }
    {
      final a = prev.afreqshift;
      final b = afreqshift;
      if ((a?.enabled ?? false) != (b?.enabled ?? false)) return null;
      if ((b?.enabled ?? false) && !identical(a, b)) {
        final d = b!._runtimeDiff(a!);
        if (d == null) return null;
        for (final (opt, val) in d) {
          out.add((
            label: 'aek_afreqshift',
            option: opt,
            value: val,
            filterName: 'afreqshift'
          ),);
        }
      }
    }
    {
      final a = prev.afwtdn;
      final b = afwtdn;
      if ((a?.enabled ?? false) != (b?.enabled ?? false)) return null;
      if ((b?.enabled ?? false) && !identical(a, b)) {
        final d = b!._runtimeDiff(a!);
        if (d == null) return null;
        for (final (opt, val) in d) {
          out.add((
            label: 'aek_afwtdn',
            option: opt,
            value: val,
            filterName: 'afwtdn'
          ),);
        }
      }
    }
    {
      final a = prev.agate;
      final b = agate;
      if ((a?.enabled ?? false) != (b?.enabled ?? false)) return null;
      if ((b?.enabled ?? false) && !identical(a, b)) {
        final d = b!._runtimeDiff(a!);
        if (d == null) return null;
        for (final (opt, val) in d) {
          out.add((
            label: 'aek_agate',
            option: opt,
            value: val,
            filterName: 'agate'
          ),);
        }
      }
    }
    {
      final a = prev.aiir;
      final b = aiir;
      if ((a?.enabled ?? false) != (b?.enabled ?? false)) return null;
      if ((b?.enabled ?? false) && a != b) return null;
    }
    {
      final a = prev.aintegral;
      final b = aintegral;
      if ((a?.enabled ?? false) != (b?.enabled ?? false)) return null;
      if ((b?.enabled ?? false) && a != b) return null;
    }
    {
      final a = prev.alimiter;
      final b = alimiter;
      if ((a?.enabled ?? false) != (b?.enabled ?? false)) return null;
      if ((b?.enabled ?? false) && !identical(a, b)) {
        final d = b!._runtimeDiff(a!);
        if (d == null) return null;
        for (final (opt, val) in d) {
          out.add((
            label: 'aek_alimiter',
            option: opt,
            value: val,
            filterName: 'alimiter'
          ),);
        }
      }
    }
    {
      final a = prev.allpass;
      final b = allpass;
      if ((a?.enabled ?? false) != (b?.enabled ?? false)) return null;
      if ((b?.enabled ?? false) && !identical(a, b)) {
        final d = b!._runtimeDiff(a!);
        if (d == null) return null;
        for (final (opt, val) in d) {
          out.add((
            label: 'aek_allpass',
            option: opt,
            value: val,
            filterName: 'allpass'
          ),);
        }
      }
    }
    {
      final a = prev.anequalizer;
      final b = anequalizer;
      if ((a?.enabled ?? false) != (b?.enabled ?? false)) return null;
      if ((b?.enabled ?? false) && !identical(a, b)) {
        final d = b!._runtimeDiff(a!);
        if (d == null) return null;
        for (final (opt, val) in d) {
          out.add((
            label: 'aek_anequalizer',
            option: opt,
            value: val,
            filterName: 'anequalizer'
          ),);
        }
      }
    }
    {
      final a = prev.anlmdn;
      final b = anlmdn;
      if ((a?.enabled ?? false) != (b?.enabled ?? false)) return null;
      if ((b?.enabled ?? false) && !identical(a, b)) {
        final d = b!._runtimeDiff(a!);
        if (d == null) return null;
        for (final (opt, val) in d) {
          out.add((
            label: 'aek_anlmdn',
            option: opt,
            value: val,
            filterName: 'anlmdn'
          ),);
        }
      }
    }
    {
      final a = prev.apad;
      final b = apad;
      if ((a?.enabled ?? false) != (b?.enabled ?? false)) return null;
      if ((b?.enabled ?? false) && a != b) return null;
    }
    {
      final a = prev.aphaser;
      final b = aphaser;
      if ((a?.enabled ?? false) != (b?.enabled ?? false)) return null;
      if ((b?.enabled ?? false) && a != b) return null;
    }
    {
      final a = prev.aphaseshift;
      final b = aphaseshift;
      if ((a?.enabled ?? false) != (b?.enabled ?? false)) return null;
      if ((b?.enabled ?? false) && !identical(a, b)) {
        final d = b!._runtimeDiff(a!);
        if (d == null) return null;
        for (final (opt, val) in d) {
          out.add((
            label: 'aek_aphaseshift',
            option: opt,
            value: val,
            filterName: 'aphaseshift'
          ),);
        }
      }
    }
    {
      final a = prev.apsyclip;
      final b = apsyclip;
      if ((a?.enabled ?? false) != (b?.enabled ?? false)) return null;
      if ((b?.enabled ?? false) && !identical(a, b)) {
        final d = b!._runtimeDiff(a!);
        if (d == null) return null;
        for (final (opt, val) in d) {
          out.add((
            label: 'aek_apsyclip',
            option: opt,
            value: val,
            filterName: 'apsyclip'
          ),);
        }
      }
    }
    {
      final a = prev.apulsator;
      final b = apulsator;
      if ((a?.enabled ?? false) != (b?.enabled ?? false)) return null;
      if ((b?.enabled ?? false) && a != b) return null;
    }
    {
      final a = prev.aresample;
      final b = aresample;
      if ((a?.enabled ?? false) != (b?.enabled ?? false)) return null;
      if ((b?.enabled ?? false) && a != b) return null;
    }
    {
      final a = prev.arnndn;
      final b = arnndn;
      if ((a?.enabled ?? false) != (b?.enabled ?? false)) return null;
      if ((b?.enabled ?? false) && !identical(a, b)) {
        final d = b!._runtimeDiff(a!);
        if (d == null) return null;
        for (final (opt, val) in d) {
          out.add((
            label: 'aek_arnndn',
            option: opt,
            value: val,
            filterName: 'arnndn'
          ),);
        }
      }
    }
    {
      final a = prev.asetrate;
      final b = asetrate;
      if ((a?.enabled ?? false) != (b?.enabled ?? false)) return null;
      if ((b?.enabled ?? false) && a != b) return null;
    }
    {
      final a = prev.asoftclip;
      final b = asoftclip;
      if ((a?.enabled ?? false) != (b?.enabled ?? false)) return null;
      if ((b?.enabled ?? false) && !identical(a, b)) {
        final d = b!._runtimeDiff(a!);
        if (d == null) return null;
        for (final (opt, val) in d) {
          out.add((
            label: 'aek_asoftclip',
            option: opt,
            value: val,
            filterName: 'asoftclip'
          ),);
        }
      }
    }
    {
      final a = prev.asubboost;
      final b = asubboost;
      if ((a?.enabled ?? false) != (b?.enabled ?? false)) return null;
      if ((b?.enabled ?? false) && !identical(a, b)) {
        final d = b!._runtimeDiff(a!);
        if (d == null) return null;
        for (final (opt, val) in d) {
          out.add((
            label: 'aek_asubboost',
            option: opt,
            value: val,
            filterName: 'asubboost'
          ),);
        }
      }
    }
    {
      final a = prev.asubcut;
      final b = asubcut;
      if ((a?.enabled ?? false) != (b?.enabled ?? false)) return null;
      if ((b?.enabled ?? false) && !identical(a, b)) {
        final d = b!._runtimeDiff(a!);
        if (d == null) return null;
        for (final (opt, val) in d) {
          out.add((
            label: 'aek_asubcut',
            option: opt,
            value: val,
            filterName: 'asubcut'
          ),);
        }
      }
    }
    {
      final a = prev.asupercut;
      final b = asupercut;
      if ((a?.enabled ?? false) != (b?.enabled ?? false)) return null;
      if ((b?.enabled ?? false) && !identical(a, b)) {
        final d = b!._runtimeDiff(a!);
        if (d == null) return null;
        for (final (opt, val) in d) {
          out.add((
            label: 'aek_asupercut',
            option: opt,
            value: val,
            filterName: 'asupercut'
          ),);
        }
      }
    }
    {
      final a = prev.asuperpass;
      final b = asuperpass;
      if ((a?.enabled ?? false) != (b?.enabled ?? false)) return null;
      if ((b?.enabled ?? false) && !identical(a, b)) {
        final d = b!._runtimeDiff(a!);
        if (d == null) return null;
        for (final (opt, val) in d) {
          out.add((
            label: 'aek_asuperpass',
            option: opt,
            value: val,
            filterName: 'asuperpass'
          ),);
        }
      }
    }
    {
      final a = prev.asuperstop;
      final b = asuperstop;
      if ((a?.enabled ?? false) != (b?.enabled ?? false)) return null;
      if ((b?.enabled ?? false) && !identical(a, b)) {
        final d = b!._runtimeDiff(a!);
        if (d == null) return null;
        for (final (opt, val) in d) {
          out.add((
            label: 'aek_asuperstop',
            option: opt,
            value: val,
            filterName: 'asuperstop'
          ),);
        }
      }
    }
    {
      final a = prev.atempo;
      final b = atempo;
      if ((a?.enabled ?? false) != (b?.enabled ?? false)) return null;
      if ((b?.enabled ?? false) && !identical(a, b)) {
        final d = b!._runtimeDiff(a!);
        if (d == null) return null;
        for (final (opt, val) in d) {
          out.add((
            label: 'aek_atempo',
            option: opt,
            value: val,
            filterName: 'atempo'
          ),);
        }
      }
    }
    {
      final a = prev.atilt;
      final b = atilt;
      if ((a?.enabled ?? false) != (b?.enabled ?? false)) return null;
      if ((b?.enabled ?? false) && !identical(a, b)) {
        final d = b!._runtimeDiff(a!);
        if (d == null) return null;
        for (final (opt, val) in d) {
          out.add((
            label: 'aek_atilt',
            option: opt,
            value: val,
            filterName: 'atilt'
          ),);
        }
      }
    }
    {
      final a = prev.bandpass;
      final b = bandpass;
      if ((a?.enabled ?? false) != (b?.enabled ?? false)) return null;
      if ((b?.enabled ?? false) && !identical(a, b)) {
        final d = b!._runtimeDiff(a!);
        if (d == null) return null;
        for (final (opt, val) in d) {
          out.add((
            label: 'aek_bandpass',
            option: opt,
            value: val,
            filterName: 'bandpass'
          ),);
        }
      }
    }
    {
      final a = prev.bandreject;
      final b = bandreject;
      if ((a?.enabled ?? false) != (b?.enabled ?? false)) return null;
      if ((b?.enabled ?? false) && !identical(a, b)) {
        final d = b!._runtimeDiff(a!);
        if (d == null) return null;
        for (final (opt, val) in d) {
          out.add((
            label: 'aek_bandreject',
            option: opt,
            value: val,
            filterName: 'bandreject'
          ),);
        }
      }
    }
    {
      final a = prev.bass;
      final b = bass;
      if ((a?.enabled ?? false) != (b?.enabled ?? false)) return null;
      if ((b?.enabled ?? false) && !identical(a, b)) {
        final d = b!._runtimeDiff(a!);
        if (d == null) return null;
        for (final (opt, val) in d) {
          out.add(
              (label: 'aek_bass', option: opt, value: val, filterName: 'bass'),);
        }
      }
    }
    {
      final a = prev.biquad;
      final b = biquad;
      if ((a?.enabled ?? false) != (b?.enabled ?? false)) return null;
      if ((b?.enabled ?? false) && !identical(a, b)) {
        final d = b!._runtimeDiff(a!);
        if (d == null) return null;
        for (final (opt, val) in d) {
          out.add((
            label: 'aek_biquad',
            option: opt,
            value: val,
            filterName: 'biquad'
          ),);
        }
      }
    }
    {
      final a = prev.channelmap;
      final b = channelmap;
      if ((a?.enabled ?? false) != (b?.enabled ?? false)) return null;
      if ((b?.enabled ?? false) && a != b) return null;
    }
    {
      final a = prev.chorus;
      final b = chorus;
      if ((a?.enabled ?? false) != (b?.enabled ?? false)) return null;
      if ((b?.enabled ?? false) && a != b) return null;
    }
    {
      final a = prev.compand;
      final b = compand;
      if ((a?.enabled ?? false) != (b?.enabled ?? false)) return null;
      if ((b?.enabled ?? false) && a != b) return null;
    }
    {
      final a = prev.compensationdelay;
      final b = compensationdelay;
      if ((a?.enabled ?? false) != (b?.enabled ?? false)) return null;
      if ((b?.enabled ?? false) && !identical(a, b)) {
        final d = b!._runtimeDiff(a!);
        if (d == null) return null;
        for (final (opt, val) in d) {
          out.add((
            label: 'aek_compensationdelay',
            option: opt,
            value: val,
            filterName: 'compensationdelay'
          ),);
        }
      }
    }
    {
      final a = prev.crossfeed;
      final b = crossfeed;
      if ((a?.enabled ?? false) != (b?.enabled ?? false)) return null;
      if ((b?.enabled ?? false) && !identical(a, b)) {
        final d = b!._runtimeDiff(a!);
        if (d == null) return null;
        for (final (opt, val) in d) {
          out.add((
            label: 'aek_crossfeed',
            option: opt,
            value: val,
            filterName: 'crossfeed'
          ),);
        }
      }
    }
    {
      final a = prev.crystalizer;
      final b = crystalizer;
      if ((a?.enabled ?? false) != (b?.enabled ?? false)) return null;
      if ((b?.enabled ?? false) && !identical(a, b)) {
        final d = b!._runtimeDiff(a!);
        if (d == null) return null;
        for (final (opt, val) in d) {
          out.add((
            label: 'aek_crystalizer',
            option: opt,
            value: val,
            filterName: 'crystalizer'
          ),);
        }
      }
    }
    {
      final a = prev.dcshift;
      final b = dcshift;
      if ((a?.enabled ?? false) != (b?.enabled ?? false)) return null;
      if ((b?.enabled ?? false) && a != b) return null;
    }
    {
      final a = prev.deesser;
      final b = deesser;
      if ((a?.enabled ?? false) != (b?.enabled ?? false)) return null;
      if ((b?.enabled ?? false) && a != b) return null;
    }
    {
      final a = prev.dialoguenhance;
      final b = dialoguenhance;
      if ((a?.enabled ?? false) != (b?.enabled ?? false)) return null;
      if ((b?.enabled ?? false) && !identical(a, b)) {
        final d = b!._runtimeDiff(a!);
        if (d == null) return null;
        for (final (opt, val) in d) {
          out.add((
            label: 'aek_dialoguenhance',
            option: opt,
            value: val,
            filterName: 'dialoguenhance'
          ),);
        }
      }
    }
    {
      final a = prev.drmeter;
      final b = drmeter;
      if ((a?.enabled ?? false) != (b?.enabled ?? false)) return null;
      if ((b?.enabled ?? false) && a != b) return null;
    }
    {
      final a = prev.dynaudnorm;
      final b = dynaudnorm;
      if ((a?.enabled ?? false) != (b?.enabled ?? false)) return null;
      if ((b?.enabled ?? false) && !identical(a, b)) {
        final d = b!._runtimeDiff(a!);
        if (d == null) return null;
        for (final (opt, val) in d) {
          out.add((
            label: 'aek_dynaudnorm',
            option: opt,
            value: val,
            filterName: 'dynaudnorm'
          ),);
        }
      }
    }
    {
      final a = prev.earwax;
      final b = earwax;
      if ((a?.enabled ?? false) != (b?.enabled ?? false)) return null;
      if ((b?.enabled ?? false) && a != b) return null;
    }
    {
      final a = prev.ebur128;
      final b = ebur128;
      if ((a?.enabled ?? false) != (b?.enabled ?? false)) return null;
      if ((b?.enabled ?? false) && a != b) return null;
    }
    {
      final a = prev.equalizer;
      final b = equalizer;
      if ((a?.enabled ?? false) != (b?.enabled ?? false)) return null;
      if ((b?.enabled ?? false) && !identical(a, b)) {
        final d = b!._runtimeDiff(a!);
        if (d == null) return null;
        for (final (opt, val) in d) {
          out.add((
            label: 'aek_equalizer',
            option: opt,
            value: val,
            filterName: 'equalizer'
          ),);
        }
      }
    }
    {
      final a = prev.extrastereo;
      final b = extrastereo;
      if ((a?.enabled ?? false) != (b?.enabled ?? false)) return null;
      if ((b?.enabled ?? false) && !identical(a, b)) {
        final d = b!._runtimeDiff(a!);
        if (d == null) return null;
        for (final (opt, val) in d) {
          out.add((
            label: 'aek_extrastereo',
            option: opt,
            value: val,
            filterName: 'extrastereo'
          ),);
        }
      }
    }
    {
      final a = prev.firequalizer;
      final b = firequalizer;
      if ((a?.enabled ?? false) != (b?.enabled ?? false)) return null;
      if ((b?.enabled ?? false) && !identical(a, b)) {
        final d = b!._runtimeDiff(a!);
        if (d == null) return null;
        for (final (opt, val) in d) {
          out.add((
            label: 'aek_firequalizer',
            option: opt,
            value: val,
            filterName: 'firequalizer'
          ),);
        }
      }
    }
    {
      final a = prev.flanger;
      final b = flanger;
      if ((a?.enabled ?? false) != (b?.enabled ?? false)) return null;
      if ((b?.enabled ?? false) && a != b) return null;
    }
    {
      final a = prev.haas;
      final b = haas;
      if ((a?.enabled ?? false) != (b?.enabled ?? false)) return null;
      if ((b?.enabled ?? false) && a != b) return null;
    }
    {
      final a = prev.hdcd;
      final b = hdcd;
      if ((a?.enabled ?? false) != (b?.enabled ?? false)) return null;
      if ((b?.enabled ?? false) && a != b) return null;
    }
    {
      final a = prev.highpass;
      final b = highpass;
      if ((a?.enabled ?? false) != (b?.enabled ?? false)) return null;
      if ((b?.enabled ?? false) && !identical(a, b)) {
        final d = b!._runtimeDiff(a!);
        if (d == null) return null;
        for (final (opt, val) in d) {
          out.add((
            label: 'aek_highpass',
            option: opt,
            value: val,
            filterName: 'highpass'
          ),);
        }
      }
    }
    {
      final a = prev.highshelf;
      final b = highshelf;
      if ((a?.enabled ?? false) != (b?.enabled ?? false)) return null;
      if ((b?.enabled ?? false) && !identical(a, b)) {
        final d = b!._runtimeDiff(a!);
        if (d == null) return null;
        for (final (opt, val) in d) {
          out.add((
            label: 'aek_highshelf',
            option: opt,
            value: val,
            filterName: 'highshelf'
          ),);
        }
      }
    }
    {
      final a = prev.loudnorm;
      final b = loudnorm;
      if ((a?.enabled ?? false) != (b?.enabled ?? false)) return null;
      if ((b?.enabled ?? false) && a != b) return null;
    }
    {
      final a = prev.lowpass;
      final b = lowpass;
      if ((a?.enabled ?? false) != (b?.enabled ?? false)) return null;
      if ((b?.enabled ?? false) && !identical(a, b)) {
        final d = b!._runtimeDiff(a!);
        if (d == null) return null;
        for (final (opt, val) in d) {
          out.add((
            label: 'aek_lowpass',
            option: opt,
            value: val,
            filterName: 'lowpass'
          ),);
        }
      }
    }
    {
      final a = prev.lowshelf;
      final b = lowshelf;
      if ((a?.enabled ?? false) != (b?.enabled ?? false)) return null;
      if ((b?.enabled ?? false) && !identical(a, b)) {
        final d = b!._runtimeDiff(a!);
        if (d == null) return null;
        for (final (opt, val) in d) {
          out.add((
            label: 'aek_lowshelf',
            option: opt,
            value: val,
            filterName: 'lowshelf'
          ),);
        }
      }
    }
    {
      final a = prev.mcompand;
      final b = mcompand;
      if ((a?.enabled ?? false) != (b?.enabled ?? false)) return null;
      if ((b?.enabled ?? false) && a != b) return null;
    }
    {
      final a = prev.pan;
      final b = pan;
      if ((a?.enabled ?? false) != (b?.enabled ?? false)) return null;
      if ((b?.enabled ?? false) && a != b) return null;
    }
    {
      final a = prev.rubberband;
      final b = rubberband;
      if ((a?.enabled ?? false) != (b?.enabled ?? false)) return null;
      if ((b?.enabled ?? false) && !identical(a, b)) {
        final d = b!._runtimeDiff(a!);
        if (d == null) return null;
        for (final (opt, val) in d) {
          out.add((
            label: 'aek_rubberband',
            option: opt,
            value: val,
            filterName: 'rubberband'
          ),);
        }
      }
    }
    {
      final a = prev.silenceremove;
      final b = silenceremove;
      if ((a?.enabled ?? false) != (b?.enabled ?? false)) return null;
      if ((b?.enabled ?? false) && !identical(a, b)) {
        final d = b!._runtimeDiff(a!);
        if (d == null) return null;
        for (final (opt, val) in d) {
          out.add((
            label: 'aek_silenceremove',
            option: opt,
            value: val,
            filterName: 'silenceremove'
          ),);
        }
      }
    }
    {
      final a = prev.speechnorm;
      final b = speechnorm;
      if ((a?.enabled ?? false) != (b?.enabled ?? false)) return null;
      if ((b?.enabled ?? false) && !identical(a, b)) {
        final d = b!._runtimeDiff(a!);
        if (d == null) return null;
        for (final (opt, val) in d) {
          out.add((
            label: 'aek_speechnorm',
            option: opt,
            value: val,
            filterName: 'speechnorm'
          ),);
        }
      }
    }
    {
      final a = prev.stereotools;
      final b = stereotools;
      if ((a?.enabled ?? false) != (b?.enabled ?? false)) return null;
      if ((b?.enabled ?? false) && !identical(a, b)) {
        final d = b!._runtimeDiff(a!);
        if (d == null) return null;
        for (final (opt, val) in d) {
          out.add((
            label: 'aek_stereotools',
            option: opt,
            value: val,
            filterName: 'stereotools'
          ),);
        }
      }
    }
    {
      final a = prev.stereowiden;
      final b = stereowiden;
      if ((a?.enabled ?? false) != (b?.enabled ?? false)) return null;
      if ((b?.enabled ?? false) && !identical(a, b)) {
        final d = b!._runtimeDiff(a!);
        if (d == null) return null;
        for (final (opt, val) in d) {
          out.add((
            label: 'aek_stereowiden',
            option: opt,
            value: val,
            filterName: 'stereowiden'
          ),);
        }
      }
    }
    {
      final a = prev.superequalizer;
      final b = superequalizer;
      if ((a?.enabled ?? false) != (b?.enabled ?? false)) return null;
      if ((b?.enabled ?? false) && a != b) return null;
    }
    {
      final a = prev.surround;
      final b = surround;
      if ((a?.enabled ?? false) != (b?.enabled ?? false)) return null;
      if ((b?.enabled ?? false) && !identical(a, b)) {
        final d = b!._runtimeDiff(a!);
        if (d == null) return null;
        for (final (opt, val) in d) {
          out.add((
            label: 'aek_surround',
            option: opt,
            value: val,
            filterName: 'surround'
          ),);
        }
      }
    }
    {
      final a = prev.tiltshelf;
      final b = tiltshelf;
      if ((a?.enabled ?? false) != (b?.enabled ?? false)) return null;
      if ((b?.enabled ?? false) && !identical(a, b)) {
        final d = b!._runtimeDiff(a!);
        if (d == null) return null;
        for (final (opt, val) in d) {
          out.add((
            label: 'aek_tiltshelf',
            option: opt,
            value: val,
            filterName: 'tiltshelf'
          ),);
        }
      }
    }
    {
      final a = prev.treble;
      final b = treble;
      if ((a?.enabled ?? false) != (b?.enabled ?? false)) return null;
      if ((b?.enabled ?? false) && !identical(a, b)) {
        final d = b!._runtimeDiff(a!);
        if (d == null) return null;
        for (final (opt, val) in d) {
          out.add((
            label: 'aek_treble',
            option: opt,
            value: val,
            filterName: 'treble'
          ),);
        }
      }
    }
    {
      final a = prev.tremolo;
      final b = tremolo;
      if ((a?.enabled ?? false) != (b?.enabled ?? false)) return null;
      if ((b?.enabled ?? false) && a != b) return null;
    }
    {
      final a = prev.vibrato;
      final b = vibrato;
      if ((a?.enabled ?? false) != (b?.enabled ?? false)) return null;
      if ((b?.enabled ?? false) && a != b) return null;
    }
    {
      final a = prev.virtualbass;
      final b = virtualbass;
      if ((a?.enabled ?? false) != (b?.enabled ?? false)) return null;
      if ((b?.enabled ?? false) && !identical(a, b)) {
        final d = b!._runtimeDiff(a!);
        if (d == null) return null;
        for (final (opt, val) in d) {
          out.add((
            label: 'aek_virtualbass',
            option: opt,
            value: val,
            filterName: 'virtualbass'
          ),);
        }
      }
    }
    return out;
  }
}

/// Cross-link between the singular [AudioEffect] enum and the
/// plural [AudioEffects] bundle: yields the [AudioEffect] for
/// every slot whose `*Settings.enabled` is `true`, in the same
/// declaration order as the bundle's fields.
///
/// Useful when iterating the active rack — e.g. attaching a
/// per-filter visualizer to every enabled stage:
///
/// ```dart
/// for (final f in player.state.audioEffects.active) {
///   player.stream.tap(f, side: TapSide.post).listen(_paint);
/// }
/// ```
extension AudioEffectsX on AudioEffects {
  /// The [AudioEffect] for every slot whose `*Settings.enabled` is
  /// `true`, in the bundle's field declaration order.
  Iterable<AudioEffect> get active sync* {
    if (acompressor?.enabled ?? false) yield AudioEffect.acompressor;
    if (acontrast?.enabled ?? false) yield AudioEffect.acontrast;
    if (acrusher?.enabled ?? false) yield AudioEffect.acrusher;
    if (adeclick?.enabled ?? false) yield AudioEffect.adeclick;
    if (adeclip?.enabled ?? false) yield AudioEffect.adeclip;
    if (adecorrelate?.enabled ?? false) yield AudioEffect.adecorrelate;
    if (adelay?.enabled ?? false) yield AudioEffect.adelay;
    if (adenorm?.enabled ?? false) yield AudioEffect.adenorm;
    if (aderivative?.enabled ?? false) yield AudioEffect.aderivative;
    if (adrc?.enabled ?? false) yield AudioEffect.adrc;
    if (adynamicequalizer?.enabled ?? false)
      yield AudioEffect.adynamicequalizer;
    if (adynamicsmooth?.enabled ?? false) yield AudioEffect.adynamicsmooth;
    if (aecho?.enabled ?? false) yield AudioEffect.aecho;
    if (aemphasis?.enabled ?? false) yield AudioEffect.aemphasis;
    if (aeval?.enabled ?? false) yield AudioEffect.aeval;
    if (aexciter?.enabled ?? false) yield AudioEffect.aexciter;
    if (afade?.enabled ?? false) yield AudioEffect.afade;
    if (afftdn?.enabled ?? false) yield AudioEffect.afftdn;
    if (afftfilt?.enabled ?? false) yield AudioEffect.afftfilt;
    if (aformat?.enabled ?? false) yield AudioEffect.aformat;
    if (afreqshift?.enabled ?? false) yield AudioEffect.afreqshift;
    if (afwtdn?.enabled ?? false) yield AudioEffect.afwtdn;
    if (agate?.enabled ?? false) yield AudioEffect.agate;
    if (aiir?.enabled ?? false) yield AudioEffect.aiir;
    if (aintegral?.enabled ?? false) yield AudioEffect.aintegral;
    if (alimiter?.enabled ?? false) yield AudioEffect.alimiter;
    if (allpass?.enabled ?? false) yield AudioEffect.allpass;
    if (anequalizer?.enabled ?? false) yield AudioEffect.anequalizer;
    if (anlmdn?.enabled ?? false) yield AudioEffect.anlmdn;
    if (apad?.enabled ?? false) yield AudioEffect.apad;
    if (aphaser?.enabled ?? false) yield AudioEffect.aphaser;
    if (aphaseshift?.enabled ?? false) yield AudioEffect.aphaseshift;
    if (apsyclip?.enabled ?? false) yield AudioEffect.apsyclip;
    if (apulsator?.enabled ?? false) yield AudioEffect.apulsator;
    if (aresample?.enabled ?? false) yield AudioEffect.aresample;
    if (arnndn?.enabled ?? false) yield AudioEffect.arnndn;
    if (asetrate?.enabled ?? false) yield AudioEffect.asetrate;
    if (asoftclip?.enabled ?? false) yield AudioEffect.asoftclip;
    if (asubboost?.enabled ?? false) yield AudioEffect.asubboost;
    if (asubcut?.enabled ?? false) yield AudioEffect.asubcut;
    if (asupercut?.enabled ?? false) yield AudioEffect.asupercut;
    if (asuperpass?.enabled ?? false) yield AudioEffect.asuperpass;
    if (asuperstop?.enabled ?? false) yield AudioEffect.asuperstop;
    if (atempo?.enabled ?? false) yield AudioEffect.atempo;
    if (atilt?.enabled ?? false) yield AudioEffect.atilt;
    if (bandpass?.enabled ?? false) yield AudioEffect.bandpass;
    if (bandreject?.enabled ?? false) yield AudioEffect.bandreject;
    if (bass?.enabled ?? false) yield AudioEffect.bass;
    if (biquad?.enabled ?? false) yield AudioEffect.biquad;
    if (channelmap?.enabled ?? false) yield AudioEffect.channelmap;
    if (chorus?.enabled ?? false) yield AudioEffect.chorus;
    if (compand?.enabled ?? false) yield AudioEffect.compand;
    if (compensationdelay?.enabled ?? false)
      yield AudioEffect.compensationdelay;
    if (crossfeed?.enabled ?? false) yield AudioEffect.crossfeed;
    if (crystalizer?.enabled ?? false) yield AudioEffect.crystalizer;
    if (dcshift?.enabled ?? false) yield AudioEffect.dcshift;
    if (deesser?.enabled ?? false) yield AudioEffect.deesser;
    if (dialoguenhance?.enabled ?? false) yield AudioEffect.dialoguenhance;
    if (drmeter?.enabled ?? false) yield AudioEffect.drmeter;
    if (dynaudnorm?.enabled ?? false) yield AudioEffect.dynaudnorm;
    if (earwax?.enabled ?? false) yield AudioEffect.earwax;
    if (ebur128?.enabled ?? false) yield AudioEffect.ebur128;
    if (equalizer?.enabled ?? false) yield AudioEffect.equalizer;
    if (extrastereo?.enabled ?? false) yield AudioEffect.extrastereo;
    if (firequalizer?.enabled ?? false) yield AudioEffect.firequalizer;
    if (flanger?.enabled ?? false) yield AudioEffect.flanger;
    if (haas?.enabled ?? false) yield AudioEffect.haas;
    if (hdcd?.enabled ?? false) yield AudioEffect.hdcd;
    if (highpass?.enabled ?? false) yield AudioEffect.highpass;
    if (highshelf?.enabled ?? false) yield AudioEffect.highshelf;
    if (loudnorm?.enabled ?? false) yield AudioEffect.loudnorm;
    if (lowpass?.enabled ?? false) yield AudioEffect.lowpass;
    if (lowshelf?.enabled ?? false) yield AudioEffect.lowshelf;
    if (mcompand?.enabled ?? false) yield AudioEffect.mcompand;
    if (pan?.enabled ?? false) yield AudioEffect.pan;
    if (rubberband?.enabled ?? false) yield AudioEffect.rubberband;
    if (silenceremove?.enabled ?? false) yield AudioEffect.silenceremove;
    if (speechnorm?.enabled ?? false) yield AudioEffect.speechnorm;
    if (stereotools?.enabled ?? false) yield AudioEffect.stereotools;
    if (stereowiden?.enabled ?? false) yield AudioEffect.stereowiden;
    if (superequalizer?.enabled ?? false) yield AudioEffect.superequalizer;
    if (surround?.enabled ?? false) yield AudioEffect.surround;
    if (tiltshelf?.enabled ?? false) yield AudioEffect.tiltshelf;
    if (treble?.enabled ?? false) yield AudioEffect.treble;
    if (tremolo?.enabled ?? false) yield AudioEffect.tremolo;
    if (vibrato?.enabled ?? false) yield AudioEffect.vibrato;
    if (virtualbass?.enabled ?? false) yield AudioEffect.virtualbass;
  }
}
