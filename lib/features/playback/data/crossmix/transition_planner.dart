import 'dart:math' as math;
import 'package:looper_player/features/library/domain/models/models.dart';
import 'package:looper_player/features/playback/data/crossmix/cue_analyzer.dart';
import 'package:looper_player/features/playback/domain/crossmix_models.dart';
import 'package:looper_player/features/playback/domain/lyric_models.dart';

/// Deterministic transition planner for Crossmix hand-overs.
class TransitionPlanner {
  /// Evaluates whether two consecutive tracks should skip crossfading.
  static bool shouldSkipCrossfade({
    required CrossmixSettings settings,
    required Song? currentSong,
    required Song? nextSong,
    bool isRepeatOne = false,
    bool isSleepTimerAtEnd = false,
    bool isManualUserSkip = false,
  }) {
    // 1. Setting is off
    if (!settings.crossfadeEnabled) return true;

    // 2. Missing songs
    if (currentSong == null || nextSong == null) return true;

    // 3. Repeat-one mode
    if (isRepeatOne) return true;

    // 4. Sleep timer set to "end of song"
    if (isSleepTimerAtEnd) return true;

    // 5. Short songs under 45 seconds
    final curDurationSecs = (currentSong.duration ?? 0) / 1000.0;
    final nextDurationSecs = (nextSong.duration ?? 0) / 1000.0;
    if (curDurationSecs < 45.0 || nextDurationSecs < 45.0) return true;

    // 6. Same album in order (must play gapless)
    if (_isConsecutiveAlbumTrack(currentSong, nextSong)) return true;

    return false;
  }

  /// True if nextSong is the consecutive next track on the same album.
  static bool _isConsecutiveAlbumTrack(Song a, Song b) {
    if (a.album == null || b.album == null) return false;
    final albumA = a.album!.trim().toLowerCase();
    final albumB = b.album!.trim().toLowerCase();
    if (albumA.isEmpty || albumA != albumB) return false;

    // Check track number progression if known
    final trackA = a.trackNumber;
    final trackB = b.trackNumber;
    if (trackA != null && trackB != null && trackA > 0 && trackB > 0) {
      return trackB == trackA + 1;
    }

    return false;
  }

  /// Creates a deterministic transition plan between two songs.
  static TransitionPlan planTransition({
    required Song outgoingSong,
    required Song incomingSong,
    required CrossmixSettings settings,
    CrossmixAnalysis? outgoingAnalysis,
    CrossmixAnalysis? incomingAnalysis,
    List<LyricLine> outgoingLyrics = const [],
    bool isManualUserSkip = false,
  }) {
    // Handle manual user skips: short outgoing fade of at most 1.5s
    if (isManualUserSkip) {
      const skipFade = Duration(milliseconds: 1500);
      final outDur = Duration(milliseconds: outgoingSong.duration ?? 0);
      return TransitionPlan(
        outgoingSong: outgoingSong,
        incomingSong: incomingSong,
        style: TransitionStyle.equalPower,
        outgoingTriggerOffset: outDur > skipFade ? outDur - skipFade : Duration.zero,
        incomingStartOffset: Duration.zero,
        overlapDuration: skipFade,
        swapProgress: 0.5,
      );
    }

    // Gapless if consecutive album tracks
    if (_isConsecutiveAlbumTrack(outgoingSong, incomingSong)) {
      final outDur = Duration(milliseconds: outgoingSong.duration ?? 0);
      return TransitionPlan(
        outgoingSong: outgoingSong,
        incomingSong: incomingSong,
        style: TransitionStyle.gapless,
        outgoingTriggerOffset: outDur,
        incomingStartOffset: Duration.zero,
        overlapDuration: Duration.zero,
      );
    }

    // Direct cut if crossfade is disabled or either song is under 45s
    final outDurMs = outgoingSong.duration ?? 0;
    final inDurMs = incomingSong.duration ?? 0;
    if (!settings.crossfadeEnabled || outDurMs < 45000 || inDurMs < 45000) {
      final outDur = Duration(milliseconds: outDurMs);
      return TransitionPlan(
        outgoingSong: outgoingSong,
        incomingSong: incomingSong,
        style: TransitionStyle.cut,
        outgoingTriggerOffset: outDur,
        incomingStartOffset: Duration.zero,
        overlapDuration: Duration.zero,
      );
    }

    // Overlap length from settings (1s - 12s, default 6s)
    double targetOverlapSecs = settings.durationSeconds.clamp(1.0, 12.0);

    // Stage 2: Cue point offsets
    Duration leadInOffset = Duration.zero;
    Duration realMusicEnd = Duration(milliseconds: outDurMs);

    if (settings.smartTransitions) {
      if (incomingAnalysis != null && incomingAnalysis.leadInMs > 50) {
        // Skip silent lead-in, capped at 3 seconds
        final leadInCap = math.min(3000, incomingAnalysis.leadInMs);
        leadInOffset = Duration(milliseconds: leadInCap);
      }
      if (outgoingAnalysis != null && outgoingAnalysis.leadOutMs > 0) {
        // Fade ends where music ends, capped at losing at most 12s of track
        final maxUnplayed = 12000;
        final candidateEnd = outgoingAnalysis.leadOutMs;
        if (outDurMs - candidateEnd <= maxUnplayed && candidateEnd > 30000) {
          realMusicEnd = Duration(milliseconds: candidateEnd);
        }
      }
    }

    // Calculate transition trigger point
    var triggerOffset = realMusicEnd - Duration(milliseconds: (targetOverlapSecs * 1000).round());
    if (triggerOffset < Duration.zero) triggerOffset = Duration.zero;

    // Stage 2: Respect lyrics line boundaries
    if (settings.smartTransitions && outgoingLyrics.isNotEmpty) {
      triggerOffset = CueAnalyzer.adjustTriggerForLyrics(
        triggerOffset,
        outgoingLyrics,
        songDuration: Duration(milliseconds: outDurMs),
      );
    }
    // Moving off a sung line must not stretch the fade past 12 s (never
    // leave more of the song unplayed, doc 24 §2.3) or squash it under 1 s;
    // the last line often runs to the end, which pulled the start back 15+ s.
    final planned = realMusicEnd - triggerOffset;
    if (planned > const Duration(seconds: 12) ||
        planned < const Duration(seconds: 1)) {
      triggerOffset =
          realMusicEnd -
          Duration(milliseconds: (targetOverlapSecs * 1000).round());
      if (triggerOffset < Duration.zero) triggerOffset = Duration.zero;
    }

    // Stage 3: Beat-matched mix
    TransitionStyle style = TransitionStyle.equalPower;
    double speedAdjustment = 1.0;
    double? filterCutoffHz;

    if (settings.beatMixing &&
        outgoingAnalysis?.bpm != null &&
        incomingAnalysis?.bpm != null &&
        (outgoingAnalysis?.tempoConfidence ?? 0.0) >= 0.35 &&
        (incomingAnalysis?.tempoConfidence ?? 0.0) >= 0.35) {
      final bpmA = outgoingAnalysis!.bpm!;
      final bpmB = incomingAnalysis!.bpm!;

      // Normalize tempos (handle half-time / double-time)
      double ratio = bpmB / bpmA;
      if (ratio > 1.8 && ratio < 2.2) ratio /= 2.0;
      if (ratio > 0.45 && ratio < 0.55) ratio *= 2.0;

      // Only the slower song is sped up, by at most 10%, and never slowed.
      // The outgoing song is already playing, so only an incoming song that
      // is slower gets the speed-up; within 0.3% nothing is stretched.
      if (ratio >= 0.90 && ratio <= 1.10) {
        if (ratio < 0.997) speedAdjustment = (1.0 / ratio).clamp(1.0, 1.10);

        // Bass hand-off crossover at 200 Hz
        style = TransitionStyle.bassSwap;
        filterCutoffHz = 200.0;
      } else {
        // Clashing tempos -> filter ride
        style = TransitionStyle.filterRide;
        filterCutoffHz = 350.0;
      }
    }

    final effectiveOverlap = realMusicEnd > triggerOffset
        ? realMusicEnd - triggerOffset
        : Duration(milliseconds: (targetOverlapSecs * 1000).round());

    return TransitionPlan(
      outgoingSong: outgoingSong,
      incomingSong: incomingSong,
      style: style,
      outgoingTriggerOffset: triggerOffset,
      incomingStartOffset: leadInOffset,
      overlapDuration: effectiveOverlap,
      speedAdjustment: speedAdjustment,
      swapProgress: 0.5,
      filterCutoffHz: filterCutoffHz,
      incomingBpm: incomingAnalysis?.bpm,
    );
  }
}
