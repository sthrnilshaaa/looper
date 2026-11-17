import 'dart:math' as math;
import 'dart:typed_data';

/// Result of tempo and beat tracking analysis.
class BeatTrackingResult {
  const BeatTrackingResult({
    required this.bpm,
    required this.confidence,
    required this.beatTimestampsMs,
  });

  /// Detected tempo in beats per minute.
  final double bpm;

  /// Confidence score between 0.0 and 1.0. Below 0.35, beat matching is skipped.
  final double confidence;

  /// Beat timestamps in milliseconds.
  final List<int> beatTimestampsMs;
}

/// Ellis dynamic-programming beat tracker & onset autocorrelation tempo analyzer.
class BeatTracker {
  /// Analyzes PCM audio samples to extract tempo, confidence, and beat grid.
  static BeatTrackingResult analyzePcm(
    Int16List samples, {
    required int sampleRate,
    required int channels,
  }) {
    if (samples.isEmpty || sampleRate <= 0 || channels <= 0) {
      return const BeatTrackingResult(
        bpm: 120.0,
        confidence: 0.0,
        beatTimestampsMs: [],
      );
    }

    // Step 1: Compute downsampled energy onset envelope (hop size ~ 10ms)
    final hopSize = (sampleRate * 0.01).round(); // 10ms per frame
    final totalFrames = samples.length ~/ (channels * hopSize);
    if (totalFrames < 100) {
      return const BeatTrackingResult(
        bpm: 120.0,
        confidence: 0.0,
        beatTimestampsMs: [],
      );
    }

    final onsetEnv = Float32List(totalFrames);
    double prevEnergy = 0.0;

    for (int frame = 0; frame < totalFrames; frame++) {
      final sampleStart = frame * hopSize * channels;
      final sampleEnd = math.min(
        samples.length,
        (frame + 1) * hopSize * channels,
      );
      double frameSumSq = 0.0;
      int count = 0;

      for (int i = sampleStart; i < sampleEnd; i++) {
        final val = samples[i] / 32768.0;
        frameSumSq += val * val;
        count++;
      }

      final energy = count > 0 ? math.sqrt(frameSumSq / count) : 0.0;
      // Half-wave rectified flux
      final flux = math.max(0.0, energy - prevEnergy);
      onsetEnv[frame] = flux;
      prevEnergy = energy;
    }

    // Step 2: Remove local average from onset curve
    final winSize = 10;
    final cleanOnset = Float32List(totalFrames);
    for (int i = 0; i < totalFrames; i++) {
      int start = math.max(0, i - winSize);
      int end = math.min(totalFrames, i + winSize + 1);
      double sum = 0.0;
      for (int j = start; j < end; j++) {
        sum += onsetEnv[j];
      }
      final localAvg = sum / (end - start);
      cleanOnset[i] = math.max(0.0, onsetEnv[i] - localAvg);
    }

    // Step 3: Autocorrelation over realistic BPM range (60 to 180 BPM)
    // At 100 frames/sec (10ms hop):
    // 60 BPM -> 1 beat = 1.0s = 100 frames
    // 180 BPM -> 1 beat = 0.333s = 33 frames
    final minLag = (100 * 60 / 180).round(); // ~33
    final maxLag = (100 * 60 / 60).round(); // ~100

    double bestCorr = 0.0;
    int bestLag = 50; // default 120 BPM (50 frames = 0.5s)
    double sumAllCorr = 0.0;
    int corrCount = 0;

    for (int lag = minLag; lag <= maxLag; lag++) {
      double corr = 0.0;
      int count = 0;
      for (int i = 0; i < totalFrames - lag; i++) {
        corr += cleanOnset[i] * cleanOnset[i + lag];
        count++;
      }
      if (count > 0) corr /= count;

      // Prior centered at 120 BPM (lag = 50 frames)
      final bpmAtLag = 6000.0 / lag;
      final prior = math.exp(-math.pow(math.log(bpmAtLag / 120.0), 2) / 0.5);
      final weightedCorr = corr * prior;

      sumAllCorr += corr;
      corrCount++;

      if (weightedCorr > bestCorr) {
        bestCorr = weightedCorr;
        bestLag = lag;
      }
    }

    final avgCorr = corrCount > 0 ? sumAllCorr / corrCount : 0.00001;
    // Calculate confidence: peak to average ratio
    double confidence = 0.0;
    if (avgCorr > 0) {
      final ratio = bestCorr / avgCorr;
      confidence = ((ratio - 1.0) / 3.0).clamp(0.0, 1.0);
    }

    final detectedBpm = 6000.0 / bestLag;

    // Step 4: Beat tracking via dynamic programming (Ellis method)
    final beatTimestampsMs = <int>[];
    if (confidence >= 0.35) {
      final periodFrames = bestLag;
      final dpScore = Float32List(totalFrames);
      final backpointer = Int32List(totalFrames);

      for (int i = 0; i < totalFrames; i++) {
        double maxScore = cleanOnset[i];
        int bestPrev = -1;

        final minPrev = math.max(0, i - (periodFrames * 1.5).round());
        final maxPrev = math.max(0, i - (periodFrames * 0.5).round());

        for (int j = minPrev; j <= maxPrev; j++) {
          final delta = i - j;
          final penalty = 100.0 * math.pow(math.log(delta / periodFrames), 2);
          final score = dpScore[j] + cleanOnset[i] - penalty;
          if (score > maxScore) {
            maxScore = score;
            bestPrev = j;
          }
        }

        dpScore[i] = maxScore;
        backpointer[i] = bestPrev;
      }

      // Backtrack from best end frame
      int bestEnd = 0;
      double maxFinal = -double.infinity;
      for (
        int i = math.max(0, totalFrames - periodFrames);
        i < totalFrames;
        i++
      ) {
        if (dpScore[i] > maxFinal) {
          maxFinal = dpScore[i];
          bestEnd = i;
        }
      }

      final beatFrames = <int>[];
      int curr = bestEnd;
      while (curr > 0) {
        beatFrames.add(curr);
        curr = backpointer[curr];
      }
      beatFrames.sort();

      for (final f in beatFrames) {
        beatTimestampsMs.add(f * 10);
      }
    }

    return BeatTrackingResult(
      bpm: detectedBpm,
      confidence: confidence,
      beatTimestampsMs: beatTimestampsMs,
    );
  }
}
