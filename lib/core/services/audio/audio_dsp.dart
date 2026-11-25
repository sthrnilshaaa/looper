part of 'audio_service.dart';

/// Centre frequencies (Hz) of the 18 equalizer bands.
const List<double> _eqBandFreqs = [
  65,
  92,
  131,
  185,
  262,
  370,
  523,
  740,
  1000,
  1400,
  2000,
  2900,
  4100,
  5900,
  8300,
  11700,
  16600,
  20000,
];

/// Width (Hz) of each of the 18 equalizer bands, matching [_eqBandFreqs].
const List<double> _eqBandWidths = [
  20,
  30,
  40,
  60,
  80,
  110,
  160,
  220,
  300,
  420,
  600,
  850,
  1200,
  1750,
  2500,
  3500,
  5000,
  6000,
];

/// The equalizer and DSP half of [AudioService]: live (throttled) updates
/// while a control is dragged, and the full filter-chain rebuild.
extension AudioServiceDsp on AudioService {
  void _triggerThrottledEq(
    List<double> gains,
    bool enabled,
    String? customFilter,
  ) {
    _throttledGains = List<double>.from(gains);
    _throttledEnabled = enabled;
    _throttledCustomFilter = customFilter;
    if (_liveEqThrottleTimer == null || !_liveEqThrottleTimer!.isActive) {
      _liveEqThrottleTimer = Timer(const Duration(milliseconds: 100), () {
        _applyThrottledEq();
      });
    }
  }

  Future<void> _applyThrottledEq() async {
    if (_throttledGains == null) return;
    await setEqualizerGains(
      _throttledGains!,
      _throttledEnabled,
      customFilter: _throttledCustomFilter,
    );
  }

  /// Applies [update] to [player], and to [idlePlayer] when it has a file.
  Future<void> _updateBoth(
    List<AudioEffect> Function(List<AudioEffect>) update,
  ) async {
    try {
      await player.updateAudioEffects(update);
      if (idlePlayer.state.playback.playlist.items.isNotEmpty) {
        try {
          await idlePlayer.updateAudioEffects(update);
        } catch (_) {}
      }
    } catch (_) {}
  }

  /// Replaces the first [T] stage with `update(it)`, or inserts
  /// `update(null)` before the limiter, so the limiter and resampler stay
  /// last (doc 25 §3.1).
  static List<AudioEffect> _upsert<T extends AudioEffect>(
    List<AudioEffect> fx,
    T Function(T? current) update,
  ) {
    final out = [...fx];
    final i = out.indexWhere((e) => e is T);
    if (i >= 0) {
      out[i] = update(out[i] as T);
    } else {
      final at = out.indexWhere((e) => e is AlimiterEffect);
      out.insert(at < 0 ? out.length : at, update(null));
    }
    return out;
  }

  Future<void> setLiveBandGain(int bandIndex, double gain) async {
    if (!_filtersInitialized || player.state.playback.playlist.items.isEmpty) {
      return;
    }
    if (_lastEqualizerGains == null) return;
    _lastEqualizerGains![bandIndex] = gain;
    final clampedGain = gain.clamp(-20.0, 20.0);
    // A gain-only change keeps the chain's shape, so mpv_audio_kit applies
    // it live with af-command instead of rebuilding (doc 25 §3.3).
    await _updateBoth((fx) {
      var band = 0;
      return [
        for (final e in fx)
          if (e is EqualizerEffect && band++ == bandIndex)
            e.copyWith(gain: clampedGain)
          else
            e,
      ];
    });
  }

  Future<void> setLivePreamp(double preamp) async {
    if (!_filtersInitialized || player.state.playback.playlist.items.isEmpty) {
      return;
    }
    if (_lastEqualizerGains == null) return;
    _lastEqualizerGains![18] = preamp;
    // The preamp is the limiter's input gain, so the limiter catches it
    // (doc 25 §3.1); a live af-command, no chain rebuild while dragging.
    final levelIn = _preampLevel(_equalizerEnabled ? preamp : 0.0);
    await _updateBoth(
      (fx) => _upsert<AlimiterEffect>(fx, (_) => _limiter(levelIn)),
    );
  }

  /// Preamp in dB (±12) as the limiter's linear input gain.
  static double _preampLevel(double db) =>
      math.pow(10, db.clamp(-12.0, 12.0) / 20).toDouble();

  /// Always in the chain, last before the resampler, at -0.5 dBFS.
  static AlimiterEffect _limiter(double levelIn) => AlimiterEffect(
    limit: 0.944,
    attack: 5.0,
    release: 80.0,
    level: false,
    levelIn: levelIn,
  );

  /// The 18 peaking bands: gain-only changes are live (no rebuild).
  static List<EqualizerEffect> _eqBands(List<double> gains) => [
    for (int i = 0; i < 18; i++)
      EqualizerEffect(
        frequency: _eqBandFreqs[i],
        width: _eqBandWidths[i],
        widthType: EqualizerWidthType.h,
        gain: i < gains.length ? gains[i].clamp(-20.0, 20.0) : 0.0,
      ),
  ];

  Future<void> _updateLive(
    List<AudioEffect> Function(List<AudioEffect>) update,
  ) async {
    if (!_filtersInitialized || player.state.playback.playlist.items.isEmpty) {
      return;
    }
    try {
      await player.updateAudioEffects(update);
    } catch (_) {}
  }

  Future<void> setLiveCompressor({
    double? threshold,
    double? ratio,
    double? attack,
    double? release,
  }) => _updateLive(
    (fx) => _upsert<AcompressorEffect>(fx, (c) {
      final current = c ?? const AcompressorEffect();
      double dBToMultiplier(double dB) => math.pow(10.0, dB / 20.0).toDouble();
      return current.copyWith(
        threshold: threshold != null
            ? dBToMultiplier(threshold.clamp(-40.0, 0.0))
            : current.threshold,
        ratio: ratio ?? current.ratio,
        attack: attack ?? current.attack,
        release: release ?? current.release,
      );
    }),
  );

  Future<void> setLiveBass(double gain) => _updateLive(
    (fx) => _upsert<BassEffect>(
      fx,
      (c) => (c ?? const BassEffect(frequency: 100.0)).copyWith(
        gain: gain.clamp(-10.0, 15.0),
      ),
    ),
  );

  Future<void> setLiveTreble(double gain) => _updateLive(
    (fx) => _upsert<TrebleEffect>(
      fx,
      (c) => (c ?? const TrebleEffect(frequency: 8000.0)).copyWith(
        gain: gain.clamp(-10.0, 15.0),
      ),
    ),
  );

  Future<void> setLiveStereoWidth(double m) => _updateLive(
    (fx) => _upsert<ExtrastereoEffect>(
      fx,
      (c) => (c ?? const ExtrastereoEffect()).copyWith(m: m.clamp(-10.0, 10.0)),
    ),
  );

  Future<void> setLiveCrossfeed(double strength) => _updateLive(
    (fx) => _upsert<CrossfeedEffect>(
      fx,
      (c) => (c ?? const CrossfeedEffect()).copyWith(
        strength: strength.clamp(0.0, 1.0),
      ),
    ),
  );

  Future<void> setLiveHighpass(double f) => _updateLive(
    (fx) => _upsert<HighpassEffect>(
      fx,
      (c) => (c ?? const HighpassEffect()).copyWith(
        frequency: f.clamp(100.0, 300.0),
      ),
    ),
  );

  Future<void> setLiveLowpass(double f) => _updateLive(
    (fx) => _upsert<LowpassEffect>(
      fx,
      (c) => (c ?? const LowpassEffect()).copyWith(
        frequency: f.clamp(3000.0, 6000.0),
      ),
    ),
  );

  Future<void> setEqualizerGains(
    List<double> gains,
    bool enabled, {
    String? customFilter,
    bool? monoEnabled,
    List<String>? autoEqFilters,
  }) async {
    _liveEqThrottleTimer?.cancel();
    _lastEqualizerGains = gains;
    _equalizerEnabled = enabled;
    _customFilterString = customFilter;
    if (monoEnabled != null) _monoEnabled = monoEnabled;
    if (autoEqFilters != null) _autoEqFilters = autoEqFilters;

    if (player.state.playback.playlist.items.isEmpty) {
      // FILE_LOADED hasn't fired yet — the playlist stream listener will
      // apply EQ once items populate. Mark _pendingEqApply so it triggers.

      _pendingEqApply = true;
      _filtersInitialized = false;
      return;
    }

    // Helper conversion dB -> ratio multiplier (e.g. 10^(dB/20))
    double dBToMultiplier(double dB) => math.pow(10.0, dB / 20.0).toDouble();

    // 1. 18 peaking equalizer bands (absent while the EQ is off)
    final eqBands = enabled ? _eqBands(gains) : const <EqualizerEffect>[];

    // 2. Dynamic Range Compressor
    final bool compEnabled =
        enabled && (gains.length > 23 ? gains[23] == 1.0 : false);
    final compressor = compEnabled
        ? AcompressorEffect(
            threshold: gains.length > 24
                ? dBToMultiplier(gains[24].clamp(-40.0, 0.0))
                : 0.125,
            ratio: gains.length > 25 ? gains[25].clamp(1.0, 20.0) : 2.0,
            attack: gains.length > 26 ? gains[26].clamp(0.01, 2000.0) : 20.0,
            release: gains.length > 27 ? gains[27].clamp(0.01, 9000.0) : 250.0,
          )
        : null;

    // 3. Loudness Normalization
    final bool loudnormEnabled =
        enabled && (gains.length > 28 ? gains[28] == 1.0 : false);
    final loudnorm = loudnormEnabled
        ? LoudnormEffect(
            i: gains.length > 29 ? gains[29].clamp(-70.0, -5.0) : -24.0,
            lra: 11.0,
            tp: -1.5,
          )
        : null;

    // 4. Headphone Crossfeed
    final bool crossfeedEnabled =
        enabled && (gains.length > 21 ? gains[21] == 1.0 : false);
    final crossfeed = crossfeedEnabled
        ? CrossfeedEffect(
            strength: gains.length > 22 ? gains[22].clamp(0.0, 1.0) : 0.2,
          )
        : null;

    // 5. Stereo Width Expansion
    final bool widthEnabled =
        enabled && (gains.length > 30 ? gains[30] == 1.0 : false);
    final extrastereo = widthEnabled
        ? ExtrastereoEffect(
            m: gains.length > 31 ? gains[31].clamp(-10.0, 10.0) : 2.5,
          )
        : null;

    // 6. Bass & Treble tone shelving
    final bool shelvingEnabled =
        enabled && (gains.length > 44 ? gains[44] == 1.0 : true);
    final double bassGain = shelvingEnabled
        ? (gains.length > 32 ? gains[32] : 0.0)
        : 0.0;
    final double trebleGain = shelvingEnabled
        ? (gains.length > 33 ? gains[33] : 0.0)
        : 0.0;
    final bass = shelvingEnabled
        ? BassEffect(gain: bassGain.clamp(-10.0, 15.0), frequency: 100.0)
        : null;
    final treble = shelvingEnabled
        ? TrebleEffect(gain: trebleGain.clamp(-10.0, 15.0), frequency: 8000.0)
        : null;

    // 7. Silence Trim
    final bool trimEnabled =
        enabled && (gains.length > 19 ? gains[19] == 1.0 : false);
    final silenceremove = trimEnabled
        ? SilenceremoveEffect(
            startPeriods: 1,
            startThreshold: gains.length > 20
                ? dBToMultiplier(gains[20].clamp(-60.0, -30.0))
                : 0.003,
            stopPeriods: 1,
            stopThreshold: gains.length > 20
                ? dBToMultiplier(gains[20].clamp(-60.0, -30.0))
                : 0.003,
          )
        : null;

    // 8. Lofi (acrusher + lowpass)
    final bool lofiEnabled =
        enabled && (gains.length > 41 ? gains[41] == 1.0 : false);
    final acrusher = lofiEnabled
        ? const AcrusherEffect(bits: 8.0, samples: 4.0, mix: 0.5)
        : null;

    // 9. Speech Enhancement Filter (highpass + lowpass)
    final bool speechEnabled =
        enabled && (gains.length > 38 ? gains[38] == 1.0 : false);
    final double hpCutoff = gains.length > 39
        ? gains[39].clamp(100.0, 300.0)
        : 150.0;
    final double lpCutoff = gains.length > 40
        ? gains[40].clamp(3000.0, 6000.0)
        : 4000.0;

    final highpass = speechEnabled ? HighpassEffect(frequency: hpCutoff) : null;

    // Merge lowpass cutoff between Lofi and Speech
    final LowpassEffect? lowpass;
    if (lofiEnabled) {
      lowpass = const LowpassEffect(frequency: 3000.0);
    } else if (speechEnabled) {
      lowpass = LowpassEffect(frequency: lpCutoff);
    } else {
      lowpass = null;
    }

    // 10. Reverb (aecho)
    final bool reverbEnabled =
        enabled && (gains.length > 42 ? gains[42] == 1.0 : false);
    final aecho = reverbEnabled
        ? const AechoEffect(
            delays: '40|60',
            decays: '0.4|0.3',
            inGain: 0.8,
            outGain: 0.5,
          )
        : null;

    // 11. Surround
    final bool surroundEnabled =
        enabled && (gains.length > 43 ? gains[43] == 1.0 : false);
    final surround = surroundEnabled ? const SurroundEffect() : null;

    // List order is chain order. It keeps the 0.4 chain: raw filters, then
    // the stages alphabetically, then the limiter and the resampler last so
    // the limiter catches every boost (doc 25 §3.1).
    List<AudioEffect> buildEffects() => [
      for (final f in _autoEqFilters)
        if (f.trim().isNotEmpty) RawAudioEffect(f.trim()),
      if (customFilter != null && customFilter.trim().isNotEmpty)
        RawAudioEffect(customFilter.trim()),
      ?compressor,
      ?acrusher,
      ?aecho,
      ...eqBands,
      ?bass,
      ?crossfeed,
      ?extrastereo,
      ?highpass,
      ?loudnorm,
      ?lowpass,
      if (_monoEnabled)
        const PanEffect(args: 'stereo|c0=0.5*c0+0.5*c1|c1=0.5*c0+0.5*c1'),
      ?silenceremove,
      ?surround,
      ?treble,
      _limiter(
        _preampLevel(
          enabled && gains.length > 18 ? gains[18].clamp(-12.0, 12.0) : 0.0,
        ),
      ),
      const AresampleEffect(),
    ];

    bool success = false;
    try {
      // The preamp lives in the limiter (buildEffects); volume-gain stays unity.
      const double totalGain = 0.0;
      final effects = buildEffects();
      await player.setVolumeGain(totalGain);
      await player.setAudioEffects(effects);
      if (idlePlayer.state.playback.playlist.items.isNotEmpty) {
        try {
          await idlePlayer.setVolumeGain(totalGain);
          await idlePlayer.setAudioEffects(effects);
        } catch (_) {}
      }
      AudioService._resolvedResamplerFilter = 'aresample';
      AudioService._resamplerProbed = true;
      success = true;
    } catch (e) {
      debugPrint("Failed to set audio effects: $e");
    }

    if (success) {
      _filtersInitialized = true;
      // Rubberband Tempo and Pitch Shift (gain index 34-35) - keep these working even if master EQ is disabled
      final bool pitchTempoEnabled = gains.length > 45
          ? gains[45] == 1.0
          : true;
      final double pitch = pitchTempoEnabled
          ? (gains.length > 34 ? gains[34].clamp(0.5, 2.0) : 1.0)
          : 1.0;
      final double tempo = pitchTempoEnabled
          ? (gains.length > 35 ? gains[35].clamp(0.5, 3.0) : 1.0)
          : 1.0;
      try {
        await player.setPitch(pitch);
        await player.setRate(tempo);
        try {
          await idlePlayer.setPitch(pitch);
          await idlePlayer.setRate(tempo);
        } catch (_) {}

        // ReplayGain (gain index 36-37)
        final int rgMode = gains.length > 36 ? gains[36].toInt() : 0;
        final double rgPreamp = gains.length > 37 ? gains[37] : 0.0;
        await configureReplayGain(mode: rgMode, preamp: rgPreamp);
      } catch (e) {}
    }
  }
}
