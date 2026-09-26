import 'dart:async';
import 'package:isar_community/isar.dart';
import 'package:looper_player/core/services/storage/db_service.dart';
import 'package:looper_player/features/settings/presentation/providers/settings_notifier.dart';
import 'package:looper_player/features/playback/presentation/providers/playback/playback_notifier.dart';
import 'package:looper_player/core/providers/providers.dart';
import 'package:looper_player/core/services/storage/local_json_store.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'equalizer_state.dart';
export 'equalizer_state.dart';

part 'equalizer_notifier.g.dart';

@Riverpod(keepAlive: true)
class Equalizer extends _$Equalizer {
  Timer? _debounceTimer;
  List<double>? _pendingSongGains;
  List<double>? _pendingGlobalGains;
  Song? _pendingSaveSong;

  @override
  EqualizerState build() {
    ref.onDispose(_flushPendingSaveSync);
    final settings = ref.read(settingsProvider);
    return EqualizerState(
      enabled: settings.equalizerEnabled,
      globalGains: _ensureLength(settings.globalEqualizerGains, 48),
      currentSongGains: _ensureLength(settings.globalEqualizerGains, 48),
      currentSongHasCustom: false,
    );
  }

  List<double> _ensureLength(List<double> list, int targetLength) {
    if (list.length >= targetLength) {
      return List<double>.from(list);
    }
    final newList = List<double>.filled(targetLength, 0.0);
    for (int i = 0; i < list.length; i++) {
      newList[i] = list[i];
    }
    if (list.length <= 20) newList[20] = -50.0;
    if (list.length <= 22) newList[22] = 0.2;
    if (list.length <= 24) newList[24] = -20.0;
    if (list.length <= 25) newList[25] = 2.0;
    if (list.length <= 26) newList[26] = 20.0;
    if (list.length <= 27) newList[27] = 250.0;
    if (list.length <= 29) newList[29] = -24.0;
    if (list.length <= 31) newList[31] = 2.5;
    if (list.length <= 34) newList[34] = 1.0;
    if (list.length <= 35) newList[35] = 1.0;
    if (list.length <= 36) newList[36] = 0.0;
    if (list.length <= 37) newList[37] = 0.0;
    if (list.length <= 39) newList[39] = 150.0;
    if (list.length <= 40) newList[40] = 4000.0;
    if (list.length <= 44) newList[44] = 1.0;
    if (list.length <= 45) newList[45] = 1.0;
    return newList;
  }

  void onSongChanged(Song? song) {
    _flushPendingSaveSync();
    final settings = ref.read(settingsProvider);
    final isGlobal = settings.equalizerGlobalMode;

    if (isGlobal) {
      state = state.copyWith(
        enabled: settings.equalizerEnabled,
        currentSongGains: _ensureLength(settings.globalEqualizerGains, 48),
        globalGains: _ensureLength(settings.globalEqualizerGains, 48),
        currentSongHasCustom: false,
      );
      _pendingSaveSong = null;
    } else {
      if (song == null) {
        state = state.copyWith(
          enabled: settings.equalizerEnabled,
          currentSongGains: _getDefaultGains(),
          currentSongHasCustom: false,
        );
        _pendingSaveSong = null;
        return;
      }

      final hasCustom = song.hasCustomEqualizer;
      final songGains = (hasCustom && song.equalizerGains != null)
          ? _ensureLength(song.equalizerGains!, 48)
          : _getDefaultGains();

      state = state.copyWith(
        enabled: settings.equalizerEnabled,
        currentSongGains: songGains,
        globalGains: _ensureLength(settings.globalEqualizerGains, 48),
        currentSongHasCustom: hasCustom,
      );
      _pendingSaveSong = song;
    }
  }

  List<double> _getDefaultGains() {
    final list = List<double>.filled(48, 0.0);
    list[20] = -50.0;
    list[22] = 0.2;
    list[24] = -20.0;
    list[25] = 2.0;
    list[26] = 20.0;
    list[27] = 250.0;
    list[29] = -24.0;
    list[31] = 2.5;
    list[34] = 1.0;
    list[35] = 1.0;
    list[39] = 150.0;
    list[40] = 4000.0;
    list[44] = 1.0;
    list[45] = 1.0;
    return list;
  }

  Future<void> toggleEqualizer(bool enabled) async {
    state = state.copyWith(enabled: enabled);

    await ref.read(settingsProvider.notifier).updateEqualizerEnabled(enabled);
    applyEqualizerInstant();
  }

  void applyEqualizerInstant() {
    ref
        .read(audioServiceProvider)
        .setEqualizerGains(
          state.currentSongGains,
          state.enabled,
          customFilter: state.customFilterString,
        );
  }

  Future<void> setCustomFilterString(String filter) async {
    state = state.copyWith(customFilterString: filter);
    applyEqualizerInstant();
  }

  Future<void> _setMultipleBands(
    Map<int, double> bandValues, {
    bool applyInstant = false,
  }) async {
    final newSongGains = List<double>.from(state.currentSongGains);

    final settings = ref.read(settingsProvider);
    final isGlobal = settings.equalizerGlobalMode;

    final newGains = List<double>.from(state.currentSongGains);
    bandValues.forEach((bandIndex, val) {
      newGains[bandIndex] = clampEqGain(bandIndex, val);
    });

    if (isGlobal) {
      state = state.copyWith(
        currentSongGains: newGains,
        globalGains: newGains,
        currentSongHasCustom: false,
      );
    } else {
      state = state.copyWith(
        currentSongGains: newGains,
        currentSongHasCustom: true,
      );
    }

    if (applyInstant) {
      applyEqualizerInstant();
    } else {
      final audioSvc = ref.read(audioServiceProvider);
      audioSvc.setEqualizerGains(
        newGains,
        state.enabled,
        customFilter: state.customFilterString,
      );
    }

    if (isGlobal) {
      _persistGainsDebounced(songGains: null, globalGains: newGains);
    } else {
      _persistGainsDebounced(songGains: newGains, globalGains: null);
    }
  }

  // Support for new 45-gain layout setters with auto-restore on disable
  Future<void> setSilenceTrimEnabled(bool enabled) async {
    final gains = {19: enabled ? 1.0 : 0.0};
    if (!enabled) {
      gains[20] = -50.0;
    }
    await _setMultipleBands(gains, applyInstant: true);
  }

  Future<void> setSilenceTrimThreshold(double db) async =>
      setBandGain(20, db, applyInstant: false);

  Future<void> setCrossfeedEnabled(bool enabled) async {
    final gains = {21: enabled ? 1.0 : 0.0};
    if (!enabled) {
      gains[22] = 0.2;
    }
    await _setMultipleBands(gains, applyInstant: true);
  }

  Future<void> setCrossfeedStrength(double strength) async =>
      setBandGain(22, strength, applyInstant: false);

  Future<void> setCompressorEnabled(bool enabled) async {
    final gains = {23: enabled ? 1.0 : 0.0};
    if (!enabled) {
      gains[24] = -20.0;
      gains[25] = 2.0;
      gains[26] = 20.0;
      gains[27] = 250.0;
    }
    await _setMultipleBands(gains, applyInstant: true);
  }

  Future<void> setCompressorThreshold(double db) async =>
      setBandGain(24, db, applyInstant: false);
  Future<void> setCompressorRatio(double ratio) async =>
      setBandGain(25, ratio, applyInstant: false);
  Future<void> setCompressorAttack(double attack) async =>
      setBandGain(26, attack, applyInstant: false);
  Future<void> setCompressorRelease(double release) async =>
      setBandGain(27, release, applyInstant: false);

  Future<void> setLoudnormEnabled(bool enabled) async {
    final gains = {28: enabled ? 1.0 : 0.0};
    if (!enabled) {
      gains[29] = -24.0;
    }
    await _setMultipleBands(gains, applyInstant: true);
  }

  Future<void> setLoudnormTarget(double target) async =>
      setBandGain(29, target, applyInstant: false);

  Future<void> setStereoWidthEnabled(bool enabled) async {
    final gains = {30: enabled ? 1.0 : 0.0};
    if (!enabled) {
      gains[31] = 2.5;
    }
    await _setMultipleBands(gains, applyInstant: true);
  }

  Future<void> setStereoWidthFactor(double factor) async =>
      setBandGain(31, factor, applyInstant: false);

  Future<void> setBassGain(double db) async =>
      setBandGain(32, db, applyInstant: false);
  Future<void> setTrebleGain(double db) async =>
      setBandGain(33, db, applyInstant: false);

  Future<void> setPitch(double val) async =>
      setBandGain(34, val, applyInstant: false);
  Future<void> setTempo(double val) async =>
      setBandGain(35, val, applyInstant: false);

  Future<void> setReplayGainMode(int mode) async =>
      setBandGain(36, mode.toDouble(), applyInstant: true);
  Future<void> setReplayGainPreamp(double preamp) async =>
      setBandGain(37, preamp, applyInstant: false);

  Future<void> setSpeechFilterEnabled(bool enabled) async {
    final gains = {38: enabled ? 1.0 : 0.0};
    if (!enabled) {
      gains[39] = 150.0;
      gains[40] = 4000.0;
    }
    await _setMultipleBands(gains, applyInstant: true);
  }

  Future<void> setSpeechHighpass(double freq) async =>
      setBandGain(39, freq, applyInstant: false);
  Future<void> setSpeechLowpass(double freq) async =>
      setBandGain(40, freq, applyInstant: false);

  Future<void> setLofiEnabled(bool enabled) async =>
      setBandGain(41, enabled ? 1.0 : 0.0, applyInstant: true);
  Future<void> setReverbEnabled(bool enabled) async =>
      setBandGain(42, enabled ? 1.0 : 0.0, applyInstant: true);
  Future<void> setSurroundEnabled(bool enabled) async =>
      setBandGain(43, enabled ? 1.0 : 0.0, applyInstant: true);

  Future<void> setShelvingEnabled(bool enabled) async {
    final gains = {44: enabled ? 1.0 : 0.0};
    if (!enabled) {
      gains[32] = 0.0;
      gains[33] = 0.0;
    }
    await _setMultipleBands(gains, applyInstant: true);
  }

  Future<void> setPitchTempoEnabled(bool enabled) async {
    final gains = {45: enabled ? 1.0 : 0.0};
    if (!enabled) {
      gains[34] = 1.0;
      gains[35] = 1.0;
    }
    await _setMultipleBands(gains, applyInstant: true);
  }

  Future<void> setPreset(String presetName, List<double> presetGains) async {
    final newSongGains = List<double>.from(state.currentSongGains);
    final currentSong = ref.read(playbackProvider).currentSong;

    for (int i = 0; i < 18 && i < presetGains.length; i++) {
      final clampedGain = presetGains[i].clamp(-20.0, 20.0);
      newSongGains[i] = clampedGain;
    }

    // Adjust Tone Shelving based on preset type
    void applyShelving(List<double> gains) {
      if (presetName == 'Flat') {
        gains[32] = 0.0;
        gains[33] = 0.0;
        gains[44] = 0.0; // Disabled shelving
      } else if (presetName == 'Bass Booster') {
        gains[32] = 8.0; // Bass boost
        gains[33] = 0.0;
        gains[44] = 1.0; // Enabled shelving
      } else if (presetName == 'Treble Booster') {
        gains[32] = 0.0;
        gains[33] = 8.0; // Treble boost
        gains[44] = 1.0;
      } else if (presetName == 'Vocal Booster') {
        gains[32] = -2.0;
        gains[33] = 1.0;
        gains[44] = 1.0;
      } else if (presetName == 'Electronic') {
        gains[32] = 4.0;
        gains[33] = 3.0;
        gains[44] = 1.0;
      } else if (presetName == 'Rock') {
        gains[32] = 4.0;
        gains[33] = 2.0;
        gains[44] = 1.0;
      } else if (presetName == 'Pop') {
        gains[32] = -1.0;
        gains[33] = 2.0;
        gains[44] = 1.0;
      } else if (presetName == 'Jazz') {
        gains[32] = 3.0;
        gains[33] = 1.0;
        gains[44] = 1.0;
      }
    }

    applyShelving(newSongGains);

    final settings = ref.read(settingsProvider);
    final isGlobal = settings.equalizerGlobalMode;

    if (isGlobal) {
      final newGlobalGains = List<double>.from(newSongGains);
      state = state.copyWith(
        currentSongGains: newSongGains,
        globalGains: newGlobalGains,
        currentSongHasCustom: false,
      );
      applyEqualizerInstant();
      _persistGainsDebounced(songGains: null, globalGains: newGlobalGains);
    } else {
      state = state.copyWith(
        currentSongGains: newSongGains,
        currentSongHasCustom: true,
      );
      applyEqualizerInstant();
      _persistGainsDebounced(songGains: newSongGains, globalGains: null);
    }
  }

  /// Restores a full gains snapshot saved by the user (see [CustomEqPreset]),
  /// unlike [setPreset] which only sets the 18 visible bands plus a
  /// name-matched shelving guess for the small set of built-in presets.
  /// Routing every index through [_setMultipleBands] reuses its per-band
  /// clamping and the existing global/per-song persistence path instead of
  /// duplicating either here.
  Future<void> applyCustomPreset(List<double> gains) async {
    final bandValues = <int, double>{
      for (int i = 0; i < gains.length; i++) i: gains[i],
    };
    await _setMultipleBands(bandValues, applyInstant: true);
  }

  Future<void> setBandGain(
    int bandIndex,
    double gain, {
    bool applyInstant = false,
  }) async {
    final double clampedGain = clampEqGain(bandIndex, gain);

    final settings = ref.read(settingsProvider);
    final isGlobal = settings.equalizerGlobalMode;

    // Update active gains in memory immediately
    final newGains = List<double>.from(state.currentSongGains);
    newGains[bandIndex] = clampedGain;

    if (isGlobal) {
      state = state.copyWith(
        currentSongGains: newGains,
        globalGains: newGains,
        currentSongHasCustom: false,
      );
    } else {
      state = state.copyWith(
        currentSongGains: newGains,
        currentSongHasCustom: true,
      );
    }

    if (applyInstant) {
      applyEqualizerInstant();
    } else {
      final audioSvc = ref.read(audioServiceProvider);
      if (bandIndex < 18) {
        audioSvc.setLiveBandGain(bandIndex, clampedGain);
      } else if (bandIndex == 18) {
        audioSvc.setLivePreamp(clampedGain);
      } else if (bandIndex == 19 || bandIndex == 20) {
        audioSvc.setEqualizerGains(
          newGains,
          state.enabled,
          customFilter: state.customFilterString,
        );
      } else if (bandIndex == 21) {
        audioSvc.setEqualizerGains(
          newGains,
          state.enabled,
          customFilter: state.customFilterString,
        );
      } else if (bandIndex == 22) {
        audioSvc.setLiveCrossfeed(clampedGain);
      } else if (bandIndex == 23) {
        audioSvc.setEqualizerGains(
          newGains,
          state.enabled,
          customFilter: state.customFilterString,
        );
      } else if (bandIndex == 24) {
        audioSvc.setLiveCompressor(threshold: clampedGain);
      } else if (bandIndex == 25) {
        audioSvc.setLiveCompressor(ratio: clampedGain);
      } else if (bandIndex == 26) {
        audioSvc.setLiveCompressor(attack: clampedGain);
      } else if (bandIndex == 27) {
        audioSvc.setLiveCompressor(release: clampedGain);
      } else if (bandIndex == 28 || bandIndex == 29) {
        audioSvc.setEqualizerGains(
          newGains,
          state.enabled,
          customFilter: state.customFilterString,
        );
      } else if (bandIndex == 30) {
        audioSvc.setEqualizerGains(
          newGains,
          state.enabled,
          customFilter: state.customFilterString,
        );
      } else if (bandIndex == 31) {
        audioSvc.setLiveStereoWidth(clampedGain);
      } else if (bandIndex == 32) {
        audioSvc.setLiveBass(clampedGain);
      } else if (bandIndex == 33) {
        audioSvc.setLiveTreble(clampedGain);
      } else if (bandIndex == 34) {
        audioSvc.player.setPitch(clampedGain);
      } else if (bandIndex == 35) {
        audioSvc.player.setRate(clampedGain);
      } else if (bandIndex == 36 || bandIndex == 37) {
        final mode = bandIndex == 36
            ? clampedGain.toInt()
            : (newGains.length > 36 ? newGains[36].toInt() : 0);
        final preamp = bandIndex == 37
            ? clampedGain
            : (newGains.length > 37 ? newGains[37] : 0.0);
        audioSvc.configureReplayGain(mode: mode, preamp: preamp);
      } else if (bandIndex == 38) {
        audioSvc.setEqualizerGains(
          newGains,
          state.enabled,
          customFilter: state.customFilterString,
        );
      } else if (bandIndex == 39) {
        audioSvc.setLiveHighpass(clampedGain);
      } else if (bandIndex == 40) {
        audioSvc.setLiveLowpass(clampedGain);
      } else if (bandIndex >= 41 && bandIndex <= 45) {
        audioSvc.setEqualizerGains(
          newGains,
          state.enabled,
          customFilter: state.customFilterString,
        );
      } else {
        audioSvc.setEqualizerGains(
          newGains,
          state.enabled,
          customFilter: state.customFilterString,
        );
      }
    }

    if (isGlobal) {
      _persistGainsDebounced(songGains: null, globalGains: newGains);
    } else {
      _persistGainsDebounced(songGains: newGains, globalGains: null);
    }
  }

  Future<void> resetCurrentSongToDefault() async {
    _flushPendingSaveSync();
    final currentSong = ref.read(playbackProvider).currentSong;
    if (currentSong != null) {
      ref
          .read(playbackProvider.notifier)
          .updateSongEqualizer(
            songId: currentSong.id,
            hasCustom: false,
            gains: null,
          );

      await DbService.isar.writeTxn(() async {
        final dbSong = await DbService.isar.songs.get(currentSong.id);
        if (dbSong != null) {
          dbSong.hasCustomEqualizer = false;
          dbSong.equalizerGains = null;
          await DbService.isar.songs.put(dbSong);
        }
      });
    }

    state = state.copyWith(
      currentSongGains: _getDefaultGains(),
      currentSongHasCustom: false,
    );

    applyEqualizerInstant();
  }

  Future<void> applyCurrentGainsToGlobal() async {
    _flushPendingSaveSync();

    final activeGains = List<double>.from(state.currentSongGains);

    state = state.copyWith(globalGains: activeGains);

    await ref
        .read(settingsProvider.notifier)
        .updateGlobalEqualizerGains(activeGains);
  }

  Future<void> resetAllSongsEqualizerData() async {
    _flushPendingSaveSync();

    await DbService.isar.writeTxn(() async {
      final allSongs = await DbService.isar.songs.where().findAll();
      for (final song in allSongs) {
        if (song.hasCustomEqualizer || song.equalizerGains != null) {
          song.hasCustomEqualizer = false;
          song.equalizerGains = null;
          await DbService.isar.songs.put(song);
        }
      }
    });

    ref.read(playbackProvider.notifier).clearAllSongsEqualizer();

    final settings = ref.read(settingsProvider);
    state = state.copyWith(
      currentSongGains: _ensureLength(settings.globalEqualizerGains, 48),
      globalGains: _ensureLength(settings.globalEqualizerGains, 48),
      currentSongHasCustom: false,
    );

    applyEqualizerInstant();
  }

  void _flushPendingSaveSync() {
    if (_pendingSongGains == null && _pendingGlobalGains == null) return;
    _debounceTimer?.cancel();

    final songGains = _pendingSongGains;
    final globalGains = _pendingGlobalGains;
    final saveSong = _pendingSaveSong;

    _pendingSongGains = null;
    _pendingGlobalGains = null;
    _pendingSaveSong = null;

    if (globalGains != null) {
      ref
          .read(settingsProvider.notifier)
          .updateGlobalEqualizerGains(globalGains);
    }

    if (saveSong != null && songGains != null) {
      final currentSong = ref.read(playbackProvider).currentSong;
      if (currentSong?.id == saveSong.id) {
        state = state.copyWith(currentSongHasCustom: true);
      }
      ref
          .read(playbackProvider.notifier)
          .updateSongEqualizer(
            songId: saveSong.id,
            hasCustom: true,
            gains: songGains,
          );

      DbService.isar
          .writeTxn(() async {
            final dbSong = await DbService.isar.songs.get(saveSong.id);
            if (dbSong != null) {
              dbSong.hasCustomEqualizer = true;
              dbSong.equalizerGains = songGains;
              await DbService.isar.songs.put(dbSong);
            }
          })
          .catchError((e) {});
    }
  }

  void _persistGainsDebounced({
    List<double>? songGains,
    List<double>? globalGains,
  }) {
    _debounceTimer?.cancel();
    if (songGains != null) {
      _pendingSongGains = songGains;
      _pendingSaveSong = ref.read(playbackProvider).currentSong;
    }
    if (globalGains != null) {
      _pendingGlobalGains = globalGains;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _flushPendingSaveSync();
    });
  }
}

/// Persists custom EQ presets to a local JSON file (see [LocalJsonStore])
/// rather than the Isar schema - a handful of named gain snapshots don't
/// warrant a DB migration.
@Riverpod(keepAlive: true)
class CustomEqPresets extends _$CustomEqPresets {
  static const _storeKey = 'custom_eq_presets';

  @override
  List<CustomEqPreset> build() {
    _load();
    return [];
  }

  Future<void> _load() async {
    final raw = await LocalJsonStore.read(_storeKey);
    if (raw is! List) return;
    state = raw
        .whereType<Map<String, dynamic>>()
        .map(CustomEqPreset.fromJson)
        .toList();
  }

  Future<void> _persist() async {
    await LocalJsonStore.write(
      _storeKey,
      state.map((p) => p.toJson()).toList(),
    );
  }

  Future<void> save(String name, List<double> gains) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) return;
    final preset = CustomEqPreset(name: trimmedName, gains: List.from(gains));
    // Saving under an existing name replaces it rather than piling up
    // duplicates - the name is the only handle the user has to it.
    state = [...state.where((p) => p.name != trimmedName), preset];
    await _persist();
  }

  Future<void> delete(String name) async {
    state = state.where((p) => p.name != name).toList();
    await _persist();
  }

  /// Adds presets from a restored backup that aren't already present by
  /// name, without touching (or being overwritten by) whatever the user
  /// already has saved locally. A single persist for the whole batch,
  /// unlike calling [save] in a loop.
  Future<void> mergeFrom(List<CustomEqPreset> imported) async {
    final existingNames = state.map((p) => p.name).toSet();
    final toAdd = imported.where((p) => !existingNames.contains(p.name));
    if (toAdd.isEmpty) return;
    state = [...state, ...toAdd];
    await _persist();
  }
}
