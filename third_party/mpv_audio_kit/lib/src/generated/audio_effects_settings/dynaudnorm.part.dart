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
/// - [channels]: Specify which channels to filter, by default all available channels are filtered. (range 0..0, default "all", runtime-tunable)
/// - [compress]: Set the compress factor. In range from 0.0 to 30.0. Default is 0.0. By default, the Dynamic Audio Normalizer does not apply "traditional" compression. This means that signal peaks will not be pruned and thus the full dynamic range will be retained within each local neighbourhood. However, in some cases it may be desirable to combine the Dynamic Audio Normalizer's normalization algorithm with a more "traditional" compression. For this purpose, the Dynamic Audio Normalizer provides an optional compression (thresholding) function. If (and only if) the compression feature is enabled, all input frames will be processed by a soft knee thresholding function prior to the actual normalization process. Put simply, the thresholding function is going to prune all samples whose magnitude exceeds a certain threshold value. However, the Dynamic Audio Normalizer does not simply apply a fixed threshold value. Instead, the threshold value will be adjusted for each individual frame. In general, smaller parameters result in stronger compression, and vice versa. Values below 3.0 are not recommended, because audible distortion may appear. (range 0.0..30.0, default 0.0, runtime-tunable)
/// - [correctdc]: Enable DC bias correction. By default is disabled. An audio signal (in the time domain) is a sequence of sample values. In the Dynamic Audio Normalizer these sample values are represented in the -1.0 to 1.0 range, regardless of the original input format. Normally, the audio signal, or "waveform", should be centered around the zero point. That means if we calculate the mean value of all samples in a file, or in a single frame, then the result should be 0.0 or at least very close to that value. If, however, there is a significant deviation of the mean value from 0.0, in either positive or negative direction, this is referred to as a DC bias or DC offset. Since a DC bias is clearly undesirable, the Dynamic Audio Normalizer provides optional DC bias correction. With DC bias correction enabled, the Dynamic Audio Normalizer will determine the mean value, or "DC correction" offset, of each input frame and subtract that value from all of the frame's sample values which ensures those samples are centered around 0.0 again. Also, in order to avoid "gaps" at the frame boundaries, the DC correction offset values will be interpolated smoothly between neighbouring frames. (range 0..1, default 0, runtime-tunable)
/// - [coupling]: Enable channels coupling. By default is enabled. By default, the Dynamic Audio Normalizer will amplify all channels by the same amount. This means the same gain factor will be applied to all channels, i.e. the maximum possible gain factor is determined by the "loudest" channel. However, in some recordings, it may happen that the volume of the different channels is uneven, e.g. one channel may be "quieter" than the other one(s). In this case, this option can be used to disable the channel coupling. This way, the gain factor will be determined independently for each channel, depending only on the individual channel's highest magnitude sample. This allows for harmonizing the volume of the different channels. (range 0..1, default 1, runtime-tunable)
/// - [curve]: Specify the peak mapping curve expression which is going to be used when calculating gain applied to frames. The max output frame gain will still be limited by other options mentioned previously for this filter.  The expression can contain the following constants: (default "", runtime-tunable)
/// - [framelen]: Set the frame length in milliseconds. In range from 10 to 8000 milliseconds. Default is 500 milliseconds. The Dynamic Audio Normalizer processes the input audio in small chunks, referred to as frames. This is required, because a peak magnitude has no meaning for just a single sample value. Instead, we need to determine the peak magnitude for a contiguous sequence of sample values. While a "standard" normalizer would simply use the peak magnitude of the complete file, the Dynamic Audio Normalizer determines the peak magnitude individually for each frame. The length of a frame is specified in milliseconds. By default, the Dynamic Audio Normalizer uses a frame length of 500 milliseconds, which has been found to give good results with most files. Note that the exact frame length, in number of samples, will be determined automatically, based on the sampling rate of the individual input audio file. (range 10..8000, default 500, runtime-tunable)
/// - [gausssize]: Set the Gaussian filter window size. In range from 3 to 301, must be odd number. Default is 31. Probably the most important parameter of the Dynamic Audio Normalizer is the `window size` of the Gaussian smoothing filter. The filter's window size is specified in frames, centered around the current frame. For the sake of simplicity, this must be an odd number. Consequently, the default value of 31 takes into account the current frame, as well as the 15 preceding frames and the 15 subsequent frames. Using a larger window results in a stronger smoothing effect and thus in less gain variation, i.e. slower gain adaptation. Conversely, using a smaller window results in a weaker smoothing effect and thus in more gain variation, i.e. faster gain adaptation. In other words, the more you increase this value, the more the Dynamic Audio Normalizer will behave like a "traditional" normalization filter. On the contrary, the more you decrease this value, the more the Dynamic Audio Normalizer will behave like a dynamic range compressor. (range 3..301, default 31, runtime-tunable)
/// - [maxgain]: Set the maximum gain factor. In range from 1.0 to 100.0. Default is 10.0. The Dynamic Audio Normalizer determines the maximum possible (local) gain factor for each input frame, i.e. the maximum gain factor that does not result in clipping or distortion. The maximum gain factor is determined by the frame's highest magnitude sample. However, the Dynamic Audio Normalizer additionally bounds the frame's maximum gain factor by a predetermined (global) maximum gain factor. This is done in order to avoid excessive gain factors in "silent" or almost silent frames. By default, the maximum gain factor is 10.0, For most inputs the default value should be sufficient and it usually is not recommended to increase this value. Though, for input with an extremely low overall volume level, it may be necessary to allow even higher gain factors. Note, however, that the Dynamic Audio Normalizer does not simply apply a "hard" threshold (i.e. cut off values above the threshold). Instead, a "sigmoid" threshold function will be applied. This way, the gain factors will smoothly approach the threshold value, but never exceed that value. (range 1.0..100.0, default 10.0, runtime-tunable)
/// - [overlap]: Specify overlap for frames. If set to 0 (default) no frame overlapping is done. Using >0 and <1 values will make less conservative gain adjustments, like when framelen option is set to smaller value, if framelen option value is compensated for non-zero overlap then gain adjustments will be smoother across time compared to zero overlap case. (range 0.0..1.0, default .0, runtime-tunable)
/// - [peak]: Set the target peak value. This specifies the highest permissible magnitude level for the normalized audio input. This filter will try to approach the target peak magnitude as closely as possible, but at the same time it also makes sure that the normalized signal will never exceed the peak magnitude. A frame's maximum local gain factor is imposed directly by the target peak magnitude. The default value is 0.95 and thus leaves a headroom of 5%*. It is not recommended to go above this value. (range 0.0..1.0, default 0.95, runtime-tunable)
/// - [targetrms]: Set the target RMS. In range from 0.0 to 1.0. Default is 0.0 - disabled. By default, the Dynamic Audio Normalizer performs "peak" normalization. This means that the maximum local gain factor for each frame is defined (only) by the frame's highest magnitude sample. This way, the samples can be amplified as much as possible without exceeding the maximum signal level, i.e. without clipping. Optionally, however, the Dynamic Audio Normalizer can also take into account the frame's root mean square, abbreviated RMS. In electrical engineering, the RMS is commonly used to determine the power of a time-varying signal. It is therefore considered that the RMS is a better approximation of the "perceived loudness" than just looking at the signal's peak magnitude. Consequently, by adjusting all frames to a constant RMS value, a uniform "perceived loudness" can be established. If a target RMS value has been specified, a frame's local gain factor is defined as the factor that would result in exactly that RMS value. Note, however, that the maximum local gain factor is still restricted by the frame's highest magnitude sample, in order to prevent clipping. (range 0.0..1.0, default 0.0, runtime-tunable)
/// - [threshold]: Set the target threshold value. This specifies the lowest permissible magnitude level for the audio input which will be normalized. If input frame volume is above this value frame will be normalized. Otherwise frame may not be normalized at all. The default value is set to 0, which means all input frames will be normalized. This option is mostly useful if digital noise is not wanted to be amplified. (range 0.0..1.0, default 0.0, runtime-tunable)
final class DynaudnormEffect extends AudioEffect {
  /// Default value for [compress].
  static const double compressDefault = 0.0;

  /// Minimum value for [compress].
  static const double compressMin = 0.0;

  /// Maximum value for [compress].
  static const double compressMax = 30.0;

  /// Default value for [framelen].
  static const int framelenDefault = 500;

  /// Minimum value for [framelen].
  static const int framelenMin = 10;

  /// Maximum value for [framelen].
  static const int framelenMax = 8000;

  /// Default value for [gausssize].
  static const int gausssizeDefault = 31;

  /// Minimum value for [gausssize].
  static const int gausssizeMin = 3;

  /// Maximum value for [gausssize].
  static const int gausssizeMax = 301;

  /// Default value for [maxgain].
  static const double maxgainDefault = 10.0;

  /// Minimum value for [maxgain].
  static const double maxgainMin = 1.0;

  /// Maximum value for [maxgain].
  static const double maxgainMax = 100.0;

  /// Default value for [overlap].
  static const double overlapDefault = .0;

  /// Minimum value for [overlap].
  static const double overlapMin = 0.0;

  /// Maximum value for [overlap].
  static const double overlapMax = 1.0;

  /// Default value for [peak].
  static const double peakDefault = 0.95;

  /// Minimum value for [peak].
  static const double peakMin = 0.0;

  /// Maximum value for [peak].
  static const double peakMax = 1.0;

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

  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// set alternative boundary mode
  final bool altboundary;

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
  final int framelen;

  /// set the filter size
  final int gausssize;

  /// set the max amplification
  final double maxgain;

  /// set the frame overlap
  final double overlap;

  /// set the peak value
  final double peak;

  /// set the target RMS
  final double targetrms;

  /// set the threshold value
  final double threshold;

  /// Creates an [DynaudnormEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const DynaudnormEffect({
    this.enabled = true,
    this.altboundary = false,
    this.channels = 'all',
    this.compress = 0.0,
    this.correctdc = false,
    this.coupling = true,
    this.curve = '',
    this.framelen = 500,
    this.gausssize = 31,
    this.maxgain = 10.0,
    this.overlap = .0,
    this.peak = 0.95,
    this.targetrms = 0.0,
    this.threshold = 0.0,
  });

  @override
  String get filterName => 'dynaudnorm';

  @override
  AudioFilter get filter => AudioFilter.dynaudnorm;

  /// Returns a copy of this [DynaudnormEffect] with the given fields replaced.
  DynaudnormEffect copyWith({
    bool? enabled,
    bool? altboundary,
    String? channels,
    double? compress,
    bool? correctdc,
    bool? coupling,
    String? curve,
    int? framelen,
    int? gausssize,
    double? maxgain,
    double? overlap,
    double? peak,
    double? targetrms,
    double? threshold,
  }) => DynaudnormEffect(
    enabled: enabled ?? this.enabled,
    altboundary: altboundary ?? this.altboundary,
    channels: channels ?? this.channels,
    compress: compress ?? this.compress,
    correctdc: correctdc ?? this.correctdc,
    coupling: coupling ?? this.coupling,
    curve: curve ?? this.curve,
    framelen: framelen ?? this.framelen,
    gausssize: gausssize ?? this.gausssize,
    maxgain: maxgain ?? this.maxgain,
    overlap: overlap ?? this.overlap,
    peak: peak ?? this.peak,
    targetrms: targetrms ?? this.targetrms,
    threshold: threshold ?? this.threshold,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DynaudnormEffect &&
          other.enabled == enabled &&
          other.altboundary == altboundary &&
          other.channels == channels &&
          other.compress == compress &&
          other.correctdc == correctdc &&
          other.coupling == coupling &&
          other.curve == curve &&
          other.framelen == framelen &&
          other.gausssize == gausssize &&
          other.maxgain == maxgain &&
          other.overlap == overlap &&
          other.peak == peak &&
          other.targetrms == targetrms &&
          other.threshold == threshold);

  @override
  int get hashCode => Object.hash(
    enabled,
    altboundary,
    channels,
    compress,
    correctdc,
    coupling,
    curve,
    framelen,
    gausssize,
    maxgain,
    overlap,
    peak,
    targetrms,
    threshold,
  );

  @override
  String toString() =>
      'DynaudnormEffect(enabled: $enabled, altboundary: $altboundary, channels: $channels, compress: $compress, correctdc: $correctdc, coupling: $coupling, curve: $curve, framelen: $framelen, gausssize: $gausssize, maxgain: $maxgain, overlap: $overlap, peak: $peak, targetrms: $targetrms, threshold: $threshold)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    assert(compress >= compressMin, 'dynaudnorm.compress must be >= 0.0');
    assert(compress <= compressMax, 'dynaudnorm.compress must be <= 30.0');
    assert(framelen >= framelenMin, 'dynaudnorm.framelen must be >= 10');
    assert(framelen <= framelenMax, 'dynaudnorm.framelen must be <= 8000');
    assert(gausssize >= gausssizeMin, 'dynaudnorm.gausssize must be >= 3');
    assert(gausssize <= gausssizeMax, 'dynaudnorm.gausssize must be <= 301');
    assert(maxgain >= maxgainMin, 'dynaudnorm.maxgain must be >= 1.0');
    assert(maxgain <= maxgainMax, 'dynaudnorm.maxgain must be <= 100.0');
    assert(overlap >= overlapMin, 'dynaudnorm.overlap must be >= 0.0');
    assert(overlap <= overlapMax, 'dynaudnorm.overlap must be <= 1.0');
    assert(peak >= peakMin, 'dynaudnorm.peak must be >= 0.0');
    assert(peak <= peakMax, 'dynaudnorm.peak must be <= 1.0');
    assert(targetrms >= targetrmsMin, 'dynaudnorm.targetrms must be >= 0.0');
    assert(targetrms <= targetrmsMax, 'dynaudnorm.targetrms must be <= 1.0');
    assert(threshold >= thresholdMin, 'dynaudnorm.threshold must be >= 0.0');
    assert(threshold <= thresholdMax, 'dynaudnorm.threshold must be <= 1.0');
    final parts = <String>[];
    if (altboundary != false)
      parts.add('altboundary=' + (altboundary ? '1' : '0'));
    if (channels != 'all') parts.add('channels=' + _wireString(channels));
    if (compress != 0.0) parts.add('compress=' + _wireDouble(compress));
    if (correctdc != false) parts.add('correctdc=' + (correctdc ? '1' : '0'));
    if (coupling != true) parts.add('coupling=' + (coupling ? '1' : '0'));
    if (curve != '') parts.add('curve=' + _wireString(curve));
    if (framelen != 500) parts.add('framelen=' + framelen.toString());
    if (gausssize != 31) parts.add('gausssize=' + gausssize.toString());
    if (maxgain != 10.0) parts.add('maxgain=' + _wireDouble(maxgain));
    if (overlap != .0) parts.add('overlap=' + _wireDouble(overlap));
    if (peak != 0.95) parts.add('peak=' + _wireDouble(peak));
    if (targetrms != 0.0) parts.add('targetrms=' + _wireDouble(targetrms));
    if (threshold != 0.0) parts.add('threshold=' + _wireDouble(threshold));
    return parts.isEmpty
        ? 'lavfi-dynaudnorm'
        : 'lavfi-dynaudnorm=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  @override
  List<(String, String)>? _runtimeDiff(covariant DynaudnormEffect prev) {
    final out = <(String, String)>[];
    if (altboundary != prev.altboundary) {
      out.add(('altboundary', (altboundary ? '1' : '0')));
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
    if (framelen != prev.framelen) {
      out.add(('framelen', framelen.toString()));
    }
    if (gausssize != prev.gausssize) {
      out.add(('gausssize', gausssize.toString()));
    }
    if (maxgain != prev.maxgain) {
      out.add(('maxgain', _wireDouble(maxgain)));
    }
    if (overlap != prev.overlap) {
      out.add(('overlap', _wireDouble(overlap)));
    }
    if (peak != prev.peak) {
      out.add(('peak', _wireDouble(peak)));
    }
    if (targetrms != prev.targetrms) {
      out.add(('targetrms', _wireDouble(targetrms)));
    }
    if (threshold != prev.threshold) {
      out.add(('threshold', _wireDouble(threshold)));
    }
    return out;
  }
}
