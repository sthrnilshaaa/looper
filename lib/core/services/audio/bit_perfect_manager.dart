import 'package:looper_player/core/services/storage/local_json_store.dart';
import 'package:looper_player/features/playback/presentation/providers/equalizer/equalizer_state.dart';

class AudioBlocker {
  final String key;
  final String name;
  final dynamic value;

  const AudioBlocker({
    required this.key,
    required this.name,
    required this.value,
  });

  Map<String, dynamic> toJson() => {'key': key, 'name': name, 'value': value};

  factory AudioBlocker.fromJson(Map<String, dynamic> json) => AudioBlocker(
    key: json['key'] as String,
    name: json['name'] as String,
    value: json['value'],
  );
}

/// Detects DSP blockers, toggles bit-perfect state, and provides
/// "turn these off" / "turn these back on" with LocalJsonStore
abstract final class BitPerfectManager {
  static const _backupKey = 'bitperfect_blockers_backup_v1';

  /// Evaluates whether any DSP effect or non-unity processing is active.
  static List<AudioBlocker> getActiveBlockers({
    required EqualizerState eqState,
    required double playbackRate,
    required double playbackPitch,
    required bool crossfadeActive,
  }) {
    final blockers = <AudioBlocker>[];

    // Master EQ or individual bands
    if (eqState.enabled) {
      blockers.add(
        AudioBlocker(key: 'eq_enabled', name: 'Equalizer Enabled', value: true),
      );
      final hasNonZeroBand = eqState.currentSongGains
          .take(18)
          .any((g) => g.abs() > 0.01);
      if (hasNonZeroBand) {
        blockers.add(
          AudioBlocker(
            key: 'eq_bands',
            name: 'Equalizer Bands Non-Flat',
            value: List<double>.from(eqState.currentSongGains.take(18)),
          ),
        );
      }
      if (eqState.preampGain.abs() > 0.01) {
        blockers.add(
          AudioBlocker(
            key: 'eq_preamp',
            name: 'Preamp (${eqState.preampGain.toStringAsFixed(1)} dB)',
            value: eqState.preampGain,
          ),
        );
      }
      if (eqState.shelvingEnabled &&
          (eqState.bassGain.abs() > 0.01 || eqState.trebleGain.abs() > 0.01)) {
        blockers.add(
          AudioBlocker(
            key: 'eq_shelving',
            name: 'Bass/Treble Tone Shelving',
            value: [eqState.bassGain, eqState.trebleGain],
          ),
        );
      }
      if (eqState.compressorEnabled) {
        blockers.add(
          const AudioBlocker(
            key: 'eq_compressor',
            name: 'Dynamic Range Compressor',
            value: true,
          ),
        );
      }
      if (eqState.loudnormEnabled) {
        blockers.add(
          const AudioBlocker(
            key: 'eq_loudnorm',
            name: 'Loudness Normalization',
            value: true,
          ),
        );
      }
      if (eqState.crossfeedEnabled) {
        blockers.add(
          const AudioBlocker(
            key: 'eq_crossfeed',
            name: 'Headphone Crossfeed',
            value: true,
          ),
        );
      }
      if (eqState.stereoWidthEnabled) {
        blockers.add(
          const AudioBlocker(
            key: 'eq_width',
            name: 'Stereo Widening',
            value: true,
          ),
        );
      }
      if (eqState.silenceTrimEnabled) {
        blockers.add(
          const AudioBlocker(
            key: 'eq_trim',
            name: 'Silence Trimming',
            value: true,
          ),
        );
      }
      if (eqState.lofiEnabled) {
        blockers.add(
          const AudioBlocker(key: 'eq_lofi', name: 'Lo-Fi Effect', value: true),
        );
      }
      if (eqState.speechFilterEnabled) {
        blockers.add(
          const AudioBlocker(
            key: 'eq_speech',
            name: 'Speech Enhancement Filter',
            value: true,
          ),
        );
      }
      if (eqState.reverbEnabled) {
        blockers.add(
          const AudioBlocker(
            key: 'eq_reverb',
            name: 'Studio Room Reverb',
            value: true,
          ),
        );
      }
      if (eqState.surroundEnabled) {
        blockers.add(
          const AudioBlocker(
            key: 'eq_surround',
            name: 'Virtual Surround Sound',
            value: true,
          ),
        );
      }
    }

    if (eqState.monoEnabled) {
      blockers.add(
        const AudioBlocker(
          key: 'mono',
          name: 'Mono Audio Downmix',
          value: true,
        ),
      );
    }

    if (eqState.autoEqEnabled) {
      blockers.add(
        const AudioBlocker(
          key: 'auto_eq',
          name: 'AutoEQ Headphone Correction',
          value: true,
        ),
      );
    }

    if (eqState.replayGainMode != 0) {
      blockers.add(
        AudioBlocker(
          key: 'replay_gain',
          name: 'Volume Normalization / ReplayGain',
          value: eqState.replayGainMode,
        ),
      );
    }

    if ((playbackRate - 1.0).abs() > 0.001) {
      blockers.add(
        AudioBlocker(
          key: 'speed',
          name: 'Playback Speed (${playbackRate.toStringAsFixed(2)}×)',
          value: playbackRate,
        ),
      );
    }

    if ((playbackPitch - 1.0).abs() > 0.001) {
      blockers.add(
        AudioBlocker(
          key: 'pitch',
          name: 'Pitch Shift (${playbackPitch.toStringAsFixed(2)}×)',
          value: playbackPitch,
        ),
      );
    }

    if (crossfadeActive) {
      blockers.add(
        const AudioBlocker(
          key: 'crossfade',
          name: 'Crossmix / Crossfade Transition',
          value: true,
        ),
      );
    }

    if (eqState.customFilterString.trim().isNotEmpty) {
      blockers.add(
        AudioBlocker(
          key: 'custom_filter',
          name: 'Custom Filter String',
          value: eqState.customFilterString,
        ),
      );
    }

    return blockers;
  }

  /// Bit-perfect badge decision:
  /// True only when:
  /// 1. Exclusive mode is on.
  /// 2. No blocker is active.
  /// 3. Output format (rate, format, channels) equals the source's.
  static bool isBitPerfect({
    required bool exclusiveMode,
    required List<AudioBlocker> activeBlockers,
    required int? sourceRate,
    required int? outRate,
    required String? sourceFormat,
    required String? outFormat,
    required int? sourceChannels,
    required int? outChannels,
  }) {
    if (!exclusiveMode) return false;
    if (activeBlockers.isNotEmpty) return false;

    if (sourceRate != null && outRate != null && sourceRate != outRate) {
      return false;
    }
    if (sourceFormat != null &&
        outFormat != null &&
        sourceFormat.isNotEmpty &&
        outFormat.isNotEmpty &&
        sourceFormat.toLowerCase() != outFormat.toLowerCase()) {
      return false;
    }
    if (sourceChannels != null &&
        outChannels != null &&
        sourceChannels != outChannels) {
      return false;
    }

    return true;
  }

  /// Saves active blockers state to LocalJsonStore and returns backup payload.
  static Future<Map<String, dynamic>> saveBlockersBackup(
    List<AudioBlocker> blockers,
  ) async {
    final map = <String, dynamic>{for (final b in blockers) b.key: b.value};
    await LocalJsonStore.write(_backupKey, map);
    return map;
  }

  /// Loads the saved blockers backup, or null if none.
  static Future<Map<String, dynamic>?> loadBlockersBackup() async {
    final json = await LocalJsonStore.read(_backupKey);
    if (json is Map && json.isNotEmpty) {
      return Map<String, dynamic>.from(json);
    }
    return null;
  }

  /// Clears the saved backup after restoration.
  static Future<void> clearBlockersBackup() async {
    await LocalJsonStore.write(_backupKey, <String, dynamic>{});
  }
}
