import 'equalizer_notifier.dart';

class EqualizerState {
  final bool enabled;
  final List<double> globalGains;
  final List<double> currentSongGains;
  final bool currentSongHasCustom;
  final String customFilterString;

  EqualizerState({
    required this.enabled,
    required this.globalGains,
    required this.currentSongGains,
    required this.currentSongHasCustom,
    this.customFilterString = '',
  });

  double get preampGain =>
      currentSongGains.length > 18 ? currentSongGains[18] : 0.0;
  bool get silenceTrimEnabled =>
      currentSongGains.length > 19 ? currentSongGains[19] == 1.0 : false;
  double get silenceTrimThreshold =>
      currentSongGains.length > 20 ? currentSongGains[20] : -50.0;
  bool get crossfeedEnabled =>
      currentSongGains.length > 21 ? currentSongGains[21] == 1.0 : false;
  double get crossfeedStrength =>
      currentSongGains.length > 22 ? currentSongGains[22] : 0.2;
  bool get compressorEnabled =>
      currentSongGains.length > 23 ? currentSongGains[23] == 1.0 : false;
  double get compressorThreshold =>
      currentSongGains.length > 24 ? currentSongGains[24] : -20.0;
  double get compressorRatio =>
      currentSongGains.length > 25 ? currentSongGains[25] : 2.0;
  double get compressorAttack =>
      currentSongGains.length > 26 ? currentSongGains[26] : 20.0;
  double get compressorRelease =>
      currentSongGains.length > 27 ? currentSongGains[27] : 250.0;
  bool get loudnormEnabled =>
      currentSongGains.length > 28 ? currentSongGains[28] == 1.0 : false;
  double get loudnormTarget =>
      currentSongGains.length > 29 ? currentSongGains[29] : -24.0;
  bool get stereoWidthEnabled =>
      currentSongGains.length > 30 ? currentSongGains[30] == 1.0 : false;
  double get stereoWidthFactor =>
      currentSongGains.length > 31 ? currentSongGains[31] : 2.5;
  double get bassGain =>
      currentSongGains.length > 32 ? currentSongGains[32] : 0.0;
  double get trebleGain =>
      currentSongGains.length > 33 ? currentSongGains[33] : 0.0;
  double get pitch => currentSongGains.length > 34 ? currentSongGains[34] : 1.0;
  double get tempo => currentSongGains.length > 35 ? currentSongGains[35] : 1.0;
  int get replayGainMode =>
      currentSongGains.length > 36 ? currentSongGains[36].toInt() : 0;
  double get replayGainPreamp =>
      currentSongGains.length > 37 ? currentSongGains[37] : 0.0;
  bool get speechFilterEnabled =>
      currentSongGains.length > 38 ? currentSongGains[38] == 1.0 : false;
  double get speechHighpass =>
      currentSongGains.length > 39 ? currentSongGains[39] : 150.0;
  double get speechLowpass =>
      currentSongGains.length > 40 ? currentSongGains[40] : 4000.0;

  bool get lofiEnabled =>
      currentSongGains.length > 41 ? currentSongGains[41] == 1.0 : false;
  bool get reverbEnabled =>
      currentSongGains.length > 42 ? currentSongGains[42] == 1.0 : false;
  bool get surroundEnabled =>
      currentSongGains.length > 43 ? currentSongGains[43] == 1.0 : false;
  bool get shelvingEnabled =>
      currentSongGains.length > 44 ? currentSongGains[44] == 1.0 : true;
  bool get pitchTempoEnabled =>
      currentSongGains.length > 45 ? currentSongGains[45] == 1.0 : true;

  EqualizerState copyWith({
    bool? enabled,
    List<double>? globalGains,
    List<double>? currentSongGains,
    bool? currentSongHasCustom,
    String? customFilterString,
  }) {
    return EqualizerState(
      enabled: enabled ?? this.enabled,
      globalGains: globalGains ?? this.globalGains,
      currentSongGains: currentSongGains ?? this.currentSongGains,
      currentSongHasCustom: currentSongHasCustom ?? this.currentSongHasCustom,
      customFilterString: customFilterString ?? this.customFilterString,
    );
  }
}

/// Per-band gain range table, shared by [Equalizer._setMultipleBands] and
/// [Equalizer.setBandGain] - previously two independent copies of the same
/// if/else chain in this file, a correctness risk if one were ever tuned
/// without the other. (`audio_service.dart` also inlines a few of these same
/// ranges at their own named, per-effect call sites - e.g. `bass.clamp(-10,
/// 15)` - deliberately left as-is there since routing through a generic
/// bandIndex lookup would make that native-audio code less self-documenting
/// at each specific effect, not more.)
double clampEqGain(int bandIndex, double value) {
  if (bandIndex < 18) {
    return value.clamp(-20.0, 20.0);
  } else if (bandIndex == 18) {
    return value.clamp(-12.0, 12.0);
  } else if (bandIndex == 20) {
    return value.clamp(-60.0, -30.0);
  } else if (bandIndex == 22) {
    return value.clamp(0.0, 1.0);
  } else if (bandIndex == 24) {
    return value.clamp(-40.0, 0.0);
  } else if (bandIndex == 25) {
    return value.clamp(1.0, 20.0);
  } else if (bandIndex == 26) {
    return value.clamp(0.01, 2000.0);
  } else if (bandIndex == 27) {
    return value.clamp(0.01, 9000.0);
  } else if (bandIndex == 29) {
    return value.clamp(-70.0, -5.0);
  } else if (bandIndex == 31) {
    return value.clamp(-10.0, 10.0);
  } else if (bandIndex == 32 || bandIndex == 33) {
    return value.clamp(-10.0, 15.0);
  } else if (bandIndex == 34) {
    return value.clamp(0.5, 2.0);
  } else if (bandIndex == 35) {
    return value.clamp(0.5, 3.0);
  } else if (bandIndex == 37) {
    return value.clamp(-20.0, 20.0);
  } else if (bandIndex == 39) {
    return value.clamp(100.0, 300.0);
  } else if (bandIndex == 40) {
    return value.clamp(3000.0, 6000.0);
  }
  return value;
}

/// A user-named snapshot of the full gains array, saved from whatever curve
/// they'd drawn so it can be recalled later - the built-in presets in
/// [Equalizer.setPreset] can't be renamed or added to.
class CustomEqPreset {
  final String name;
  final List<double> gains;

  const CustomEqPreset({required this.name, required this.gains});

  Map<String, dynamic> toJson() => {'name': name, 'gains': gains};

  static CustomEqPreset fromJson(Map<String, dynamic> json) => CustomEqPreset(
    name: json['name'] as String,
    gains: (json['gains'] as List).map((g) => (g as num).toDouble()).toList(),
  );
}
