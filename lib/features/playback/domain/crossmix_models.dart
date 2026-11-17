import 'dart:math' as math;
import 'package:looper_player/features/library/domain/models/models.dart';
import 'package:looper_player/features/settings/domain/app_defaults.dart';

/// Available transition blend styles for Crossmix.
enum TransitionStyle {
  /// Equal-power sinusoidal crossfade (sin/cos curves, total power = 1.0).
  equalPower,

  /// Bass hand-off: lowpass / highpass crossover at 200 Hz.
  bassSwap,

  /// Filter ride: exponential frequency sweep across the overlap.
  filterRide,

  /// Gapless transition for consecutive album tracks.
  gapless,

  /// Clean direct cut.
  cut,
}

/// Settings for Crossmix audio transitions.
class CrossmixSettings {
  const CrossmixSettings({
    this.crossfadeEnabled = AppDefaults.crossfadeEnabled,
    this.durationSeconds = AppDefaults.crossmixDurationSeconds,
    this.smartTransitions = AppDefaults.crossmixSmartTransitions,
    this.beatMixing = AppDefaults.crossmixBeatMixing,
  });

  /// Master switch for crossfade transitions between songs.
  final bool crossfadeEnabled;

  /// Duration of the transition in seconds (clamped to 1.0 .. 12.0).
  final double durationSeconds;

  /// Stage 2: Cue points without beat matching (skips silence, respects lyrics lines).
  final bool smartTransitions;

  /// Stage 3: Beat-matched transitions (experimental, off by default).
  final bool beatMixing;

  Duration get duration =>
      Duration(milliseconds: (durationSeconds.clamp(1.0, 12.0) * 1000).round());

  CrossmixSettings copyWith({
    bool? crossfadeEnabled,
    double? durationSeconds,
    bool? smartTransitions,
    bool? beatMixing,
  }) => CrossmixSettings(
    crossfadeEnabled: crossfadeEnabled ?? this.crossfadeEnabled,
    durationSeconds: durationSeconds ?? this.durationSeconds,
    smartTransitions: smartTransitions ?? this.smartTransitions,
    beatMixing: beatMixing ?? this.beatMixing,
  );

  Map<String, dynamic> toJson() => {
    'crossfadeEnabled': crossfadeEnabled,
    'durationSeconds': durationSeconds,
    'smartTransitions': smartTransitions,
    'beatMixing': beatMixing,
  };

  factory CrossmixSettings.fromJson(Map<String, dynamic> json) =>
      CrossmixSettings(
        crossfadeEnabled: json['crossfadeEnabled'] as bool? ?? false,
        durationSeconds:
            (json['durationSeconds'] as num?)?.toDouble().clamp(1.0, 12.0) ??
            6.0,
        smartTransitions: json['smartTransitions'] as bool? ?? true,
        beatMixing: json['beatMixing'] as bool? ?? true,
      );
}

/// Cached analysis data for a song (Stage 2 cue points & Stage 3 beat info).
class CrossmixAnalysis {
  const CrossmixAnalysis({
    required this.songId,
    required this.leadInMs,
    required this.leadOutMs,
    required this.hasFadeOut,
    this.bpm,
    this.tempoConfidence,
    this.beatGridMs = const [],
    this.energyProfile = const [],
    this.fileSize,
    this.analyzedAt,
  });

  final int songId;

  /// First sound timestamp in milliseconds (skips silent intro).
  final int leadInMs;

  /// Last real-music timestamp in milliseconds (-45 dB below peak, skips silent outro).
  final int leadOutMs;

  /// True if the song's ending naturally fades out.
  final bool hasFadeOut;

  /// Estimated tempo in BPM (beats per minute).
  final double? bpm;

  /// Confidence of tempo estimate (0.0 to 1.0). Below 0.35, beat matching is skipped.
  final double? tempoConfidence;

  /// Periodic beat timestamps in milliseconds around mix regions.
  final List<int> beatGridMs;

  /// Per-second RMS energy values normalized relative to peak (0.0 to 1.0).
  final List<double> energyProfile;

  final int? fileSize;
  final int? analyzedAt;

  Duration get leadIn => Duration(milliseconds: math.max(0, leadInMs));
  Duration get leadOut => Duration(milliseconds: math.max(0, leadOutMs));

  Map<String, dynamic> toJson() => {
    'songId': songId,
    'leadInMs': leadInMs,
    'leadOutMs': leadOutMs,
    'hasFadeOut': hasFadeOut,
    if (bpm != null) 'bpm': bpm,
    if (tempoConfidence != null) 'tempoConfidence': tempoConfidence,
    if (beatGridMs.isNotEmpty) 'beatGridMs': beatGridMs,
    if (energyProfile.isNotEmpty) 'energyProfile': energyProfile,
    if (fileSize != null) 'fileSize': fileSize,
    if (analyzedAt != null) 'analyzedAt': analyzedAt,
  };

  factory CrossmixAnalysis.fromJson(Map<String, dynamic> json) =>
      CrossmixAnalysis(
        songId: json['songId'] as int? ?? 0,
        leadInMs: json['leadInMs'] as int? ?? 0,
        leadOutMs: json['leadOutMs'] as int? ?? 0,
        hasFadeOut: json['hasFadeOut'] as bool? ?? false,
        bpm: (json['bpm'] as num?)?.toDouble(),
        tempoConfidence: (json['tempoConfidence'] as num?)?.toDouble(),
        beatGridMs:
            (json['beatGridMs'] as List?)
                ?.map((e) => (e as num).toInt())
                .toList() ??
            const [],
        energyProfile:
            (json['energyProfile'] as List?)
                ?.map((e) => (e as num).toDouble())
                .toList() ??
            const [],
        fileSize: json['fileSize'] as int?,
        analyzedAt: json['analyzedAt'] as int?,
      );
}

/// An executable transition plan between two consecutive songs.
class TransitionPlan {
  const TransitionPlan({
    required this.outgoingSong,
    required this.incomingSong,
    required this.style,
    required this.outgoingTriggerOffset,
    required this.incomingStartOffset,
    required this.overlapDuration,
    this.speedAdjustment = 1.0,
    this.swapProgress = 0.5,
    this.filterCutoffHz,
    this.incomingBpm,
  });

  final Song outgoingSong;
  final Song incomingSong;
  final TransitionStyle style;

  /// Playback position on the outgoing song when the transition should begin.
  final Duration outgoingTriggerOffset;

  /// Start position within the incoming song (skipping silent lead-in).
  final Duration incomingStartOffset;

  /// Duration of the dual-player audio overlap.
  final Duration overlapDuration;

  /// Tempo adjustment factor applied to slower song (between 1.0 and 1.10).
  final double speedAdjustment;

  /// Progress fraction (0.0 to 1.0) where now-playing and media session swap occurs.
  final double swapProgress;

  /// Filter crossover cutoff frequency in Hz for bass swap / filter ride.
  final double? filterCutoffHz;

  /// The incoming song's tempo, for easing a beat-match speed-up back.
  final double? incomingBpm;

  /// Equal power volume gain for outgoing player at normalized progress t (0.0 .. 1.0).
  /// Uses cos(t * pi / 2) with -3dB compensation factor (1 / sqrt(2) at midpoint).
  static double calculateOutgoingGain(double t) {
    final progress = t.clamp(0.0, 1.0);
    return math.cos(progress * math.pi / 2.0);
  }

  /// Equal power volume gain for incoming player at normalized progress t (0.0 .. 1.0).
  /// Uses sin(t * pi / 2) with -3dB compensation factor.
  static double calculateIncomingGain(double t) {
    final progress = t.clamp(0.0, 1.0);
    return math.sin(progress * math.pi / 2.0);
  }

  /// Whether this plan is an active crossfade overlap.
  bool get hasOverlap =>
      overlapDuration > Duration.zero &&
      style != TransitionStyle.gapless &&
      style != TransitionStyle.cut;
}
