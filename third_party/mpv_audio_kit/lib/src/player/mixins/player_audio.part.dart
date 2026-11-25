// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
part of '../player.dart';

/// Audio setters: volume, rate and pitch, gain and ReplayGain and the
/// spectrum settings. The audio tracks and the cover-art display options
/// live in `_TracksModule`, the output in `_OutputModule`, the effects
/// chain in `_EffectsModule`.
mixin _AudioModule on _PlayerBase {
  /// Sets the soft volume in percent: 100 plays at unity and values above
  /// it amplify. mpv's scale is cubic: 130 is about +7 dB, 1000 is +60 dB.
  ///
  /// Takes 0 to 1000, mpv's range: throws [RangeError] outside it.
  /// [PlayerSettings.volumeMax] does not cap this call: it bounds mpv's
  /// relative steps (`add`, `cycle`) only. Clamp a slider to it yourself.
  Future<void> setVolume(double volume) async {
    _checkRange(volume, 0, 1000, 'volume');
    final value = canonicalFloat(volume);
    // The option, not the property: from mpv 0.42 the property refuses a
    // value above volume-max, the option takes its own 0 to 1000.
    await _write(
      'options/volume',
      value.toString(),
      _reactives.volume,
      value,
      (s) => s.copyWith(volume: value),
    );
  }

  /// Sets playback rate (1.0 = normal speed). Throws [RangeError] outside
  /// mpv's `[0.01, 100]`.
  Future<void> setRate(double rate) async {
    _checkRange(rate, 0.01, 100, 'rate');
    await _write(
      'speed',
      rate.toString(),
      _reactives.rate,
      rate,
      (s) => s.copyWith(rate: rate),
    );
  }

  /// Sets pitch (1.0 = original pitch). Throws [RangeError] outside
  /// mpv's `[0.01, 100]`.
  Future<void> setPitch(double pitch) async {
    _checkRange(pitch, 0.01, 100, 'pitch');
    await _write(
      'pitch',
      pitch.toString(),
      _reactives.pitch,
      pitch,
      (s) => s.copyWith(pitch: pitch),
    );
  }

  /// Mutes or unmutes audio output.
  Future<void> setMute(bool mute) async {
    await _write(
      'mute',
      mute ? 'yes' : 'no',
      _reactives.mute,
      mute,
      (s) => s.copyWith(mute: mute),
    );
  }

  /// Enables or disables pitch correction (mpv's `audio-pitch-correction`,
  /// which inserts `scaletempo2`) for non-1.0 playback rates. Enabled by
  /// default. When disabled, raising the rate also raises the pitch.
  Future<void> setPitchCorrection(bool enable) async {
    await _write(
      'audio-pitch-correction',
      enable ? 'yes' : 'no',
      _reactives.pitchCorrection,
      enable,
      (s) => s.copyWith(pitchCorrection: enable),
    );
  }

  /// Sets the audio delay against the playback clock (mpv's
  /// `audio-delay`), for example to match a Bluetooth output to a visual.
  ///
  /// Sign convention: positive values **delay** the audio (it plays
  /// later), negative values **advance** it (it plays earlier). This
  /// matches mpv's convention but is counterintuitive when thought of as
  /// "audio offset": positive does NOT mean "audio ahead".
  ///
  /// Sent to mpv in seconds with six decimals, so microseconds are kept.
  Future<void> setAudioDelay(Duration delay) async {
    await _write(
      'audio-delay',
      durationToSeconds(delay).toStringAsFixed(6),
      _reactives.audioDelay,
      delay,
      (s) => s.copyWith(audioDelay: delay),
    );
  }

  /// Enables or disables gapless playback. See [Gapless] for the
  /// available variants. During a live [PcmSource] entry, which plays
  /// without gapless, a new value holds only until that entry ends.
  Future<void> setGapless(Gapless gapless) async {
    await _write(
      'gapless-audio',
      gapless.mpvValue,
      _reactives.gapless,
      gapless,
      (s) => s.copyWith(gapless: gapless),
    );
  }

  /// Sets the ReplayGain normalization configuration atomically.
  ///
  /// Writes the four backing mpv properties (`replaygain`,
  /// `replaygain-preamp`, `replaygain-clip`, `replaygain-fallback`) in
  /// one shot. If any of the writes fails, the previously-committed
  /// fields and the state go back to the prior [ReplayGainSettings]
  /// before the error is rethrown, so the consumer never observes a
  /// half-applied state.
  Future<void> setReplayGain(ReplayGainSettings requested) async {
    await _gate();
    final settings = requested.copyWith(
      preamp: canonicalFloat(requested.preamp),
      fallback: canonicalFloat(requested.fallback),
    );
    final previous = state.settings.replayGain;
    final writes = <(String, String, String)>[
      ('replaygain', settings.mode.mpvValue, previous.mode.mpvValue),
      (
        'replaygain-preamp',
        settings.preamp.toString(),
        previous.preamp.toString(),
      ),
      (
        'replaygain-clip',
        settings.clip ? 'yes' : 'no',
        previous.clip ? 'yes' : 'no',
      ),
      (
        'replaygain-fallback',
        settings.fallback.toString(),
        previous.fallback.toString(),
      ),
    ];
    await _calls.writeBundle(
      writes,
      (v) => _updateField(
        (s) => s.copyWith(replayGain: v),
        _reactives.replayGain,
        v,
      ),
      settings,
      previous,
    );
  }

  /// Sets volume gain in dB (pre-amplification on top of [setVolume]).
  ///
  /// Takes -150 to +150 dB, mpv's range: throws [RangeError] outside it.
  /// [setVolumeGainMin] and
  /// [setVolumeGainMax] do not cap this call: they bound mpv's relative
  /// steps (`add`, `cycle`) only. 0 dB = unity. Values above about +6 dB
  /// risk clipping unless [setReplayGain] or a downstream limiter is in
  /// the chain.
  Future<void> setVolumeGain(double gainDb) async {
    _checkRange(gainDb, -150, 150, 'gainDb');
    final value = canonicalFloat(gainDb);
    // The option, as for setVolume: the property refuses a value outside
    // volume-gain-min and volume-gain-max from mpv 0.42.
    await _write(
      'options/volume-gain',
      value.toString(),
      _reactives.volumeGain,
      value,
      (s) => s.copyWith(volumeGain: value),
    );
  }

  /// Sets mpv's `volume-gain-min`, in dB. Range -150 to 0; default -96.
  /// Throws [RangeError] outside it.
  ///
  /// It is the floor of mpv's relative steps on the gain (`add` and
  /// `cycle` through [Player.sendRawCommand]), not of [setVolumeGain],
  /// which takes down to -150 whatever this value.
  Future<void> setVolumeGainMin(double gainDb) async {
    _checkRange(gainDb, -150, 0, 'gainDb');
    final value = canonicalFloat(gainDb);
    await _write(
      'volume-gain-min',
      value.toString(),
      _reactives.volumeGainMin,
      value,
      (s) => s.copyWith(volumeGainMin: value),
    );
  }

  /// Sets mpv's `volume-gain-max`, in dB. Range 0 to 150; default +12.
  /// Throws [RangeError] outside it.
  ///
  /// It is the top of mpv's relative steps on the gain (`add` and `cycle`
  /// through [Player.sendRawCommand]), not of [setVolumeGain], which takes
  /// up to +150 whatever this value.
  Future<void> setVolumeGainMax(double gainDb) async {
    _checkRange(gainDb, 0, 150, 'gainDb');
    final value = canonicalFloat(gainDb);
    await _write(
      'volume-gain-max',
      value.toString(),
      _reactives.volumeGainMax,
      value,
      (s) => s.copyWith(volumeGainMax: value),
    );
  }

  /// Sets the volume the audio driver exposes, in percent (mpv's
  /// `ao-volume`), distinct from the soft [setVolume]. Throws [RangeError]
  /// outside `[0, 100]`.
  ///
  /// What it moves depends on the driver:
  /// - the app's own stream with PulseAudio, PipeWire, WASAPI in shared
  ///   mode and CoreAudio on macOS;
  /// - the whole device, for every app, with ALSA (the card's mixer) and
  ///   with WASAPI in exclusive mode (the device's hardware volume, when it
  ///   has one). The system keeps that value after [Player.dispose].
  ///
  /// Best-effort: where the driver exposes no volume (iOS, Android, macOS
  /// in exclusive mode, the null AO) the call is silently ignored: it does
  /// NOT throw, and [OutputState.systemVolume] stays `null`. On Android the
  /// app's volume is the system's media volume, which the app sets through
  /// the platform's AudioManager.
  ///
  /// On the web it is the gain of the page's audio output, after the
  /// effects and the PCM taps, for this player only. It holds across
  /// files, and set before the first file it applies once that one plays.
  Future<void> setSystemVolume(double volume) async {
    _checkRange(volume, 0, 100, 'volume');
    await _gate();
    final value = canonicalFloat(volume);
    var rc = await _calls.propRc('ao-volume', value.toString());
    // No output open yet: the option the next one starts from, where the
    // driver has one (the web).
    const option = kOutputVolumeOption;
    if (rc < 0 && option != null) {
      rc = await _calls.propRc(option, value.toString());
    }
    if (rc >= 0) {
      _updateField(
        (s) => s.copyWith(systemVolume: value),
        _reactives.systemVolume,
        value,
      );
    }
  }

  /// Sets the mute the audio driver exposes (`ao-mute`), distinct from the
  /// soft [setMute]. It reaches as far as [setSystemVolume] does: the
  /// whole device with ALSA and with WASAPI in exclusive mode.
  ///
  /// Best-effort, like [setSystemVolume]: silently ignored (no throw) when the
  /// active audio output doesn't expose system mute (coreaudio on macOS,
  /// iOS, Android). On the web it mutes the page's output for this player,
  /// as [setSystemVolume] sets its gain.
  Future<void> setSystemMute(bool mute) async {
    await _gate();
    var rc = await _calls.propRc('ao-mute', mute ? 'yes' : 'no');
    const option = kOutputMuteOption;
    if (rc < 0 && option != null) {
      rc = await _calls.propRc(option, mute ? 'yes' : 'no');
    }
    if (rc >= 0) {
      _updateField(
        (s) => s.copyWith(systemMute: mute),
        _reactives.systemMute,
        mute,
      );
    }
  }

  /// Sets mpv's `volume-max`, in percent.
  ///
  /// Range: 100 to 1000; default 130, mpv's own. It is the top of mpv's
  /// relative volume steps (`add` and `cycle` through
  /// [Player.sendRawCommand]), and a natural top for a volume slider, read
  /// back from [PlayerSettings.volumeMax]. It does not cap [setVolume], which
  /// takes up to 1000 whatever this value. Throws [RangeError] outside the
  /// range.
  Future<void> setVolumeMax(double limit) async {
    _checkRange(limit, 100, 1000, 'limit');
    final value = canonicalFloat(limit);
    await _write(
      'volume-max',
      value.toString(),
      _reactives.volumeMax,
      value,
      (s) => s.copyWith(volumeMax: value),
    );
  }

  /// Forcibly reloads the audio output.
  Future<void> reloadAudio() async {
    await _gate();
    await _calls.commandChecked(['ao-reload']);
  }

  // ── Spectrum and PCM streams ───────────────────────────────────────
  // The FFT spectrum + raw PCM streams are a separate subsystem from
  // the typed mpv setters above: they don't write any mpv property,
  // they configure the polling pipeline that reads the
  // `pcm-tap-frame` property at the configured emit rate.

  /// Replaces the spectrum and PCM pipeline configuration.
  ///
  /// Use for full-bundle config (initial setup, preset application).
  /// To mutate a single field (typical of UI sliders), prefer
  /// [updateSpectrum].
  ///
  /// Reallocates FFT memory only when [SpectrumSettings.fftSize],
  /// window or band layout actually changes; idempotent on no-op
  /// settings. Re-arms the poll timer when [SpectrumSettings.emitInterval]
  /// changes mid-stream.
  ///
  /// Synchronous: the pipeline is Dart-side, so the new settings are in
  /// [PlayerSettings.spectrum] when the call returns, even before the player
  /// has finished starting. The pipeline is **lazy**: with no subscriber
  /// to [PlayerStream.fft] or [PlayerStream.pcm] this only stores the
  /// configuration; the poll loop starts on the first subscriber.
  ///
  /// Throws [ArgumentError] (a [RangeError] for a bound), with the state
  /// unchanged, when a field is outside the range its doc gives. The
  /// constructor's asserts check the same ranges, but a release build
  /// skips them.
  void setSpectrum(SpectrumSettings settings) {
    _checkNotDisposed();
    settings.validate();
    assert(
      settings.emitInterval >= SpectrumPipeline.minEmitInterval,
      'emitInterval must be at least 8 ms',
    );
    _updateField(
      (s) => s.copyWith(spectrum: settings),
      _reactives.spectrum,
      settings,
    );
    if (_bringUpCompleted) _spectrumPipeline.setSettings(settings);
  }

  /// Mutates the spectrum settings with a Freezed-style copyWith
  /// mapper.
  ///
  /// Convenience over `setSpectrum(state.settings.spectrum.copyWith(...))`.
  /// The mapper receives the current bundle and must return the new
  /// one: same semantics as `Player.updateAudioEffects`.
  ///
  /// Example:
  /// ```dart
  /// // Switch to 60 fps with a Blackman-Harris window:
  /// player.updateSpectrum((s) => s.copyWith(
  ///   emitInterval: const Duration(milliseconds: 16),
  ///   window: WindowFunction.blackmanHarris,
  /// ));
  /// ```
  void updateSpectrum(SpectrumSettings Function(SpectrumSettings) mapper) {
    setSpectrum(mapper(_state.settings.spectrum));
  }
}
