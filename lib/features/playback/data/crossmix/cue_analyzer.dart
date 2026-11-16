import 'dart:isolate';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:looper_player/core/services/storage/local_json_store.dart';
import 'package:looper_player/features/library/domain/models/models.dart';
import 'package:looper_player/features/playback/domain/crossmix_models.dart';
import 'package:looper_player/features/playback/domain/lyric_models.dart';

/// Analyzes cue points, energy envelope, and silence thresholds for songs.
class CueAnalyzer {
  // v2: v1 cached guessed cues for files it could not decode.
  static const String cachePrefix = 'crossmix_analysis_v2_';

  /// -45 dB under peak amplitude is treated as the threshold for real music.
  /// 10^(-45 / 20) ≈ 0.00562
  static const double silenceThresholdRatio = 0.005623;

  /// Retrieves cached analysis or performs new analysis.
  static Future<CrossmixAnalysis?> getOrAnalyze(Song song) async {
    // Unsaved (online) songs share a placeholder id; never key a cache on it.
    if (song.id <= 0 || song.path.isEmpty) return null;
    final cacheKey = '$cachePrefix${song.id}';
    final cached = await LocalJsonStore.read(cacheKey);
    if (cached is Map) {
      try {
        final analysis =
            CrossmixAnalysis.fromJson(Map<String, dynamic>.from(cached));
        return analysis;
      } catch (_) {}
    }

    final fresh = await analyzeSong(song);
    if (fresh != null) {
      await LocalJsonStore.write(cacheKey, fresh.toJson());
    }
    return fresh;
  }

  /// Analyzes local file cues (or extracts bounds based on metadata / file data).
  static Future<CrossmixAnalysis?> analyzeSong(Song song) async {
    final songDurationMs = song.duration ?? 0;
    if (songDurationMs <= 0) return null;

    final file = File(song.path);
    int? fileSize;
    if (await file.exists()) {
      try {
        fileSize = await file.length();
        // If file is a WAV file, we can directly parse PCM samples
        if (song.path.toLowerCase().endsWith('.wav')) {
          final bytes = await file.readAsBytes();
          final id = song.id, size = fileSize;
          // Off the UI isolate: analysis must not compete with playback.
          return await Isolate.run(
            () => analyzeWavBytes(bytes, songId: id, fileSize: size),
          );
        }
      } catch (_) {}
    }

    // No PCM decoder for this format yet (doc 24 §3): no analysis, so the
    // planner uses a plain crossfade. Guessed cues would cut real audio.
    return null;
  }

  /// Parses and analyzes raw 16-bit PCM WAV bytes.
  static CrossmixAnalysis? analyzeWavBytes(
    Uint8List bytes, {
    required int songId,
    int? fileSize,
  }) {
    if (bytes.length < 44) return null;
    final header = String.fromCharCodes(bytes.sublist(0, 4));
    final format = String.fromCharCodes(bytes.sublist(8, 12));
    if (header != 'RIFF' || format != 'WAVE') return null;

    final channels = bytes.buffer.asByteData().getUint16(22, Endian.little);
    final sampleRate = bytes.buffer.asByteData().getUint32(24, Endian.little);
    final bitsPerSample =
        bytes.buffer.asByteData().getUint16(34, Endian.little);

    if (sampleRate == 0 || channels == 0 || bitsPerSample != 16) return null;

    // Find 'data' chunk
    int dataOffset = 12;
    int dataLength = 0;
    final byteData = bytes.buffer.asByteData();
    while (dataOffset + 8 <= bytes.length) {
      final chunkId = String.fromCharCodes(
        bytes.sublist(dataOffset, dataOffset + 4),
      );
      final chunkSize = byteData.getUint32(dataOffset + 4, Endian.little);
      if (chunkId == 'data') {
        dataOffset += 8;
        dataLength = math.min(chunkSize, bytes.length - dataOffset);
        break;
      }
      dataOffset += 8 + chunkSize;
    }

    if (dataLength <= 0) return null;

    final numSamples = dataLength ~/ 2;
    final samples = Int16List.view(bytes.buffer, dataOffset, numSamples);
    return analyzePcm16(
      samples,
      sampleRate: sampleRate,
      channels: channels,
      songId: songId,
      fileSize: fileSize,
    );
  }

  /// Analyzes 16-bit PCM samples to compute RMS energy, peak, lead-in, and lead-out.
  static CrossmixAnalysis analyzePcm16(
    Int16List samples, {
    required int sampleRate,
    required int channels,
    required int songId,
    int? fileSize,
  }) {
    final framesPerSecond = sampleRate;
    final totalFrames = samples.length ~/ channels;
    final durationSeconds = totalFrames / sampleRate;
    final totalMs = (durationSeconds * 1000).round();

    // Compute peak amplitude
    double peak = 0.0;
    for (int i = 0; i < samples.length; i++) {
      final amp = samples[i].abs().toDouble();
      if (amp > peak) peak = amp;
    }
    if (peak == 0.0) peak = 1.0;

    final silenceThreshold = peak * silenceThresholdRatio;

    // Detect lead-in (first sound exceeding silence threshold)
    int firstSoundFrame = 0;
    for (int frame = 0; frame < totalFrames; frame++) {
      double frameMax = 0.0;
      for (int c = 0; c < channels; c++) {
        final val = samples[frame * channels + c].abs().toDouble();
        if (val > frameMax) frameMax = val;
      }
      if (frameMax >= silenceThreshold) {
        firstSoundFrame = frame;
        break;
      }
    }

    // Detect lead-out (last real-music sound exceeding silence threshold)
    int lastSoundFrame = totalFrames - 1;
    for (int frame = totalFrames - 1; frame >= 0; frame--) {
      double frameMax = 0.0;
      for (int c = 0; c < channels; c++) {
        final val = samples[frame * channels + c].abs().toDouble();
        if (val > frameMax) frameMax = val;
      }
      if (frameMax >= silenceThreshold) {
        lastSoundFrame = frame;
        break;
      }
    }

    final leadInMs = ((firstSoundFrame / sampleRate) * 1000).round();
    final leadOutMs = ((lastSoundFrame / sampleRate) * 1000).round();

    // Calculate per-second RMS energy profile
    final numSeconds = math.max(1, durationSeconds.ceil());
    final energyProfile = <double>[];
    for (int s = 0; s < numSeconds; s++) {
      final startFrame = s * framesPerSecond;
      final endFrame = math.min(totalFrames, (s + 1) * framesPerSecond);
      if (startFrame >= endFrame) break;

      double sumSq = 0.0;
      int count = 0;
      for (int f = startFrame; f < endFrame; f++) {
        for (int c = 0; c < channels; c++) {
          final sVal = samples[f * channels + c] / 32768.0;
          sumSq += sVal * sVal;
          count++;
        }
      }
      final rms = count > 0 ? math.sqrt(sumSq / count) : 0.0;
      energyProfile.add(rms);
    }

    // Check if ending fades out
    bool hasFadeOut = false;
    if (energyProfile.length >= 4) {
      final lastIdx = energyProfile.length - 1;
      final eLast = energyProfile[lastIdx];
      final ePrev = energyProfile[lastIdx - 1];
      final ePrev2 = energyProfile[lastIdx - 2];
      hasFadeOut = (eLast < ePrev && ePrev < ePrev2) || eLast < 0.05;
    }

    return CrossmixAnalysis(
      songId: songId,
      leadInMs: leadInMs,
      leadOutMs: leadOutMs,
      hasFadeOut: hasFadeOut,
      energyProfile: energyProfile,
      fileSize: fileSize,
      analyzedAt: DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Adjusts trigger offset to avoid cutting off a singer mid-line (Stage 2 rule).
  static Duration adjustTriggerForLyrics(
    Duration desiredTrigger,
    List<LyricLine> lyrics, {
    Duration songDuration = Duration.zero,
  }) {
    if (lyrics.isEmpty) return desiredTrigger;

    const safetyBuffer = Duration(milliseconds: 300);
    for (final line in lyrics) {
      final lineStart = line.startTime - safetyBuffer;
      final lineEnd = line.endTime + safetyBuffer;

      // If desired trigger falls inside an active singing line
      if (desiredTrigger >= lineStart && desiredTrigger <= lineEnd) {
        // Prefer placing trigger after the line completes if within reasonable bounds
        if (lineEnd <= songDuration || songDuration == Duration.zero) {
          return lineEnd;
        } else {
          return lineStart;
        }
      }
    }
    return desiredTrigger;
  }
}
