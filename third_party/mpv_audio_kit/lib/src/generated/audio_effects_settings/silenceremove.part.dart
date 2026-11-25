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

/// Configuration for the `silenceremove` audio effect.
///
/// Remove silence from the beginning, middle or end of the audio.
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [detection]: Set how is silence detected. (range 0..5, default D_RMS)
/// - [startDuration]: Specify the amount of time that non-silence must be detected before it stops trimming audio. By increasing the duration, bursts of noises can be treated as silence and trimmed off. Default value is `0`. (range 0..2147483647, default 0)
/// - [startMode]: Specify mode of detection of silence end at start of multi-channel audio. Can be `any` or `all`. Default is `any`. With `any`, any sample from any channel that is detected as non-silence will trigger end of silence trimming at start of audio stream. With `all`, only if every sample from every channel is detected as non-silence will trigger end of silence trimming at start of audio stream, limited usage. (range 0..1, default T_ANY, runtime-tunable)
/// - [startPeriods]: This value is used to indicate if audio should be trimmed at beginning of the audio. A value of zero indicates no silence should be trimmed from the beginning. When specifying a non-zero value, it trims audio up until it finds non-silence. Normally, when trimming silence from beginning of audio the `start_periods` will be `1` but it can be increased to higher values to trim all audio up to specific count of non-silence periods. Default value is `0`. (range 0..9000, default 0)
/// - [startSilence]: Specify max duration of silence at beginning that will be kept after trimming. Default is 0, which is equal to trimming all samples detected as silence. (range 0..2147483647, default 0)
/// - [startThreshold]: This indicates what sample value should be treated as silence. For digital audio, a value of `0` may be fine but for audio recorded from analog, you may wish to increase the value to account for background noise. Can be specified in dB (in case "dB" is appended to the specified value) or amplitude ratio. Default value is `0`. (range 0..1.7976931348623157e+308, default 0, runtime-tunable)
/// - [stopDuration]: Specify a duration of silence that must exist before audio is not copied any more. By specifying a higher duration, silence that is wanted can be left in the audio. Default value is `0`. (range 0..2147483647, default 0)
/// - [stopMode]: Specify mode of detection of silence start after start of multi-channel audio. Can be `any` or `all`. Default is `all`. With `any`, any sample from any channel that is detected as silence will trigger start of silence trimming after start of audio stream, limited usage. With `all`, only if every sample from every channel is detected as silence will trigger start of silence trimming after start of audio stream. (range 0..1, default T_ALL, runtime-tunable)
/// - [stopPeriods]: Set the count for trimming silence from the end of audio. When specifying a positive value, it trims audio after it finds specified silence period. To remove silence from the middle of a file, specify a `stop_periods` that is negative. This value is then treated as a positive value and is used to indicate the effect should restart processing as specified by `stop_periods`, making it suitable for removing periods of silence in the middle of the audio. Default value is `0`. (range -9000..9000, default 0)
/// - [stopSilence]: Specify max duration of silence at end that will be kept after trimming. Default is 0, which is equal to trimming all samples detected as silence. (range 0..2147483647, default 0)
/// - [stopThreshold]: This is the same as @option{start_threshold} but for trimming silence from the end of audio. Can be specified in dB (in case "dB" is appended to the specified value) or amplitude ratio. Default value is `0`. (range 0..1.7976931348623157e+308, default 0, runtime-tunable)
/// - [timestamp]: Set processing mode of every audio frame output timestamp. (range 0..1, default TS_WRITE)
/// - [window]: Set duration in number of seconds used to calculate size of window in number of samples for detecting silence. Using `0` will effectively disable any windowing and use only single sample per channel for silence detection. In that case it may be needed to also set @option{start_silence} and/or @option{stop_silence} to nonzero values with also @option{start_duration} and/or @option{stop_duration} to nonzero values. Default value is `0.02`. Allowed range is from `0` to `10`. (range 0..100000000, default 20000)
final class SilenceremoveEffect extends AudioEffect {
  /// Default value for [startPeriods].
  static const int startPeriodsDefault = 0;

  /// Minimum value for [startPeriods].
  static const int startPeriodsMin = 0;

  /// Maximum value for [startPeriods].
  static const int startPeriodsMax = 9000;

  /// Default value for [startThreshold].
  static const double startThresholdDefault = 0.0;

  /// Minimum value for [startThreshold].
  static const double startThresholdMin = 0.0;

  /// Maximum value for [startThreshold].
  static const double startThresholdMax = 1.7976931348623157e+308;

  /// Default value for [stopPeriods].
  static const int stopPeriodsDefault = 0;

  /// Minimum value for [stopPeriods].
  static const int stopPeriodsMin = -9000;

  /// Maximum value for [stopPeriods].
  static const int stopPeriodsMax = 9000;

  /// Default value for [stopThreshold].
  static const double stopThresholdDefault = 0.0;

  /// Minimum value for [stopThreshold].
  static const double stopThresholdMin = 0.0;

  /// Maximum value for [stopThreshold].
  static const double stopThresholdMax = 1.7976931348623157e+308;

  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// set how silence is detected
  final SilenceremoveDetection detection;

  /// set start duration of non-silence part
  final Duration startDuration;

  /// set which channel will trigger trimming from start
  final SilenceremoveMode startMode;

  /// set periods of silence parts to skip from start
  final int startPeriods;

  /// set start duration of silence part to keep
  final Duration startSilence;

  /// set threshold for start silence detection
  final double startThreshold;

  /// set stop duration of silence part
  final Duration stopDuration;

  /// set which channel will trigger trimming from end
  final SilenceremoveMode stopMode;

  /// set periods of silence parts to skip from end
  final int stopPeriods;

  /// set stop duration of silence part to keep
  final Duration stopSilence;

  /// set threshold for stop silence detection
  final double stopThreshold;

  /// set how every output frame timestamp is processed
  final SilenceremoveTimestamp timestamp;

  /// set duration of window for silence detection
  final Duration window;

  /// Creates an [SilenceremoveEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const SilenceremoveEffect({
    this.enabled = true,
    this.detection = SilenceremoveDetection.rms,
    this.startDuration = Duration.zero,
    this.startMode = SilenceremoveMode.any,
    this.startPeriods = 0,
    this.startSilence = Duration.zero,
    this.startThreshold = 0.0,
    this.stopDuration = Duration.zero,
    this.stopMode = SilenceremoveMode.all,
    this.stopPeriods = 0,
    this.stopSilence = Duration.zero,
    this.stopThreshold = 0.0,
    this.timestamp = SilenceremoveTimestamp.write,
    this.window = const Duration(microseconds: 20000),
  });

  @override
  String get filterName => 'silenceremove';

  @override
  AudioFilter get filter => AudioFilter.silenceremove;

  /// Returns a copy of this [SilenceremoveEffect] with the given fields replaced.
  SilenceremoveEffect copyWith({
    bool? enabled,
    SilenceremoveDetection? detection,
    Duration? startDuration,
    SilenceremoveMode? startMode,
    int? startPeriods,
    Duration? startSilence,
    double? startThreshold,
    Duration? stopDuration,
    SilenceremoveMode? stopMode,
    int? stopPeriods,
    Duration? stopSilence,
    double? stopThreshold,
    SilenceremoveTimestamp? timestamp,
    Duration? window,
  }) => SilenceremoveEffect(
    enabled: enabled ?? this.enabled,
    detection: detection ?? this.detection,
    startDuration: startDuration ?? this.startDuration,
    startMode: startMode ?? this.startMode,
    startPeriods: startPeriods ?? this.startPeriods,
    startSilence: startSilence ?? this.startSilence,
    startThreshold: startThreshold ?? this.startThreshold,
    stopDuration: stopDuration ?? this.stopDuration,
    stopMode: stopMode ?? this.stopMode,
    stopPeriods: stopPeriods ?? this.stopPeriods,
    stopSilence: stopSilence ?? this.stopSilence,
    stopThreshold: stopThreshold ?? this.stopThreshold,
    timestamp: timestamp ?? this.timestamp,
    window: window ?? this.window,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SilenceremoveEffect &&
          other.enabled == enabled &&
          other.detection == detection &&
          other.startDuration == startDuration &&
          other.startMode == startMode &&
          other.startPeriods == startPeriods &&
          other.startSilence == startSilence &&
          other.startThreshold == startThreshold &&
          other.stopDuration == stopDuration &&
          other.stopMode == stopMode &&
          other.stopPeriods == stopPeriods &&
          other.stopSilence == stopSilence &&
          other.stopThreshold == stopThreshold &&
          other.timestamp == timestamp &&
          other.window == window);

  @override
  int get hashCode => Object.hash(
    enabled,
    detection,
    startDuration,
    startMode,
    startPeriods,
    startSilence,
    startThreshold,
    stopDuration,
    stopMode,
    stopPeriods,
    stopSilence,
    stopThreshold,
    timestamp,
    window,
  );

  @override
  String toString() =>
      'SilenceremoveEffect(enabled: $enabled, detection: $detection, startDuration: $startDuration, startMode: $startMode, startPeriods: $startPeriods, startSilence: $startSilence, startThreshold: $startThreshold, stopDuration: $stopDuration, stopMode: $stopMode, stopPeriods: $stopPeriods, stopSilence: $stopSilence, stopThreshold: $stopThreshold, timestamp: $timestamp, window: $window)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    assert(
      startPeriods >= startPeriodsMin,
      'silenceremove.start_periods must be >= 0',
    );
    assert(
      startPeriods <= startPeriodsMax,
      'silenceremove.start_periods must be <= 9000',
    );
    assert(
      startThreshold >= startThresholdMin,
      'silenceremove.start_threshold must be >= 0',
    );
    assert(
      startThreshold <= startThresholdMax,
      'silenceremove.start_threshold must be <= 1.7976931348623157e+308',
    );
    assert(
      stopPeriods >= stopPeriodsMin,
      'silenceremove.stop_periods must be >= -9000',
    );
    assert(
      stopPeriods <= stopPeriodsMax,
      'silenceremove.stop_periods must be <= 9000',
    );
    assert(
      stopThreshold >= stopThresholdMin,
      'silenceremove.stop_threshold must be >= 0',
    );
    assert(
      stopThreshold <= stopThresholdMax,
      'silenceremove.stop_threshold must be <= 1.7976931348623157e+308',
    );
    final parts = <String>[];
    if (detection != SilenceremoveDetection.rms)
      parts.add('detection=' + detection.mpvValue);
    if (startDuration != Duration.zero)
      parts.add('start_duration=' + _wireDuration(startDuration));
    if (startMode != SilenceremoveMode.any)
      parts.add('start_mode=' + startMode.mpvValue);
    if (startPeriods != 0)
      parts.add('start_periods=' + startPeriods.toString());
    if (startSilence != Duration.zero)
      parts.add('start_silence=' + _wireDuration(startSilence));
    if (startThreshold != 0.0)
      parts.add('start_threshold=' + _wireDouble(startThreshold));
    if (stopDuration != Duration.zero)
      parts.add('stop_duration=' + _wireDuration(stopDuration));
    if (stopMode != SilenceremoveMode.all)
      parts.add('stop_mode=' + stopMode.mpvValue);
    if (stopPeriods != 0) parts.add('stop_periods=' + stopPeriods.toString());
    if (stopSilence != Duration.zero)
      parts.add('stop_silence=' + _wireDuration(stopSilence));
    if (stopThreshold != 0.0)
      parts.add('stop_threshold=' + _wireDouble(stopThreshold));
    if (timestamp != SilenceremoveTimestamp.write)
      parts.add('timestamp=' + timestamp.mpvValue);
    if (window != const Duration(microseconds: 20000))
      parts.add('window=' + _wireDuration(window));
    return parts.isEmpty
        ? 'lavfi-silenceremove'
        : 'lavfi-silenceremove=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  @override
  List<(String, String)>? _runtimeDiff(covariant SilenceremoveEffect prev) {
    final out = <(String, String)>[];
    if (detection != prev.detection) return null;
    if (startDuration != prev.startDuration) return null;
    if (startMode != prev.startMode) {
      out.add(('start_mode', startMode.mpvValue));
    }
    if (startPeriods != prev.startPeriods) return null;
    if (startSilence != prev.startSilence) return null;
    if (startThreshold != prev.startThreshold) {
      out.add(('start_threshold', _wireDouble(startThreshold)));
    }
    if (stopDuration != prev.stopDuration) return null;
    if (stopMode != prev.stopMode) {
      out.add(('stop_mode', stopMode.mpvValue));
    }
    if (stopPeriods != prev.stopPeriods) return null;
    if (stopSilence != prev.stopSilence) return null;
    if (stopThreshold != prev.stopThreshold) {
      out.add(('stop_threshold', _wireDouble(stopThreshold)));
    }
    if (timestamp != prev.timestamp) return null;
    if (window != prev.window) return null;
    return out;
  }
}
