// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
part of '../player.dart';

/// Audio setters: volume, mute, output device, format / channel layout,
/// the [AudioEffects] DSP pipeline, and the cover-art display options.
mixin _AudioModule on _PlayerBase {
  /// Sets volume (0–100; values above 100 amplify the signal).
  Future<void> setVolume(double volume) async {
    await _gate();
    _checkFinite(volume, 'volume');
    await _prop('volume', volume.toStringAsFixed(1));
    _updateField((s) => s.copyWith(volume: volume), _reactives.volume, volume);
  }

  /// Sets playback rate (1.0 = normal speed).
  Future<void> setRate(double rate) async {
    await _gate();
    _checkFinite(rate, 'rate');
    await _prop('speed', rate.toStringAsFixed(4));
    _updateField((s) => s.copyWith(rate: rate), _reactives.rate, rate);
  }

  /// Sets pitch (1.0 = original pitch).
  Future<void> setPitch(double pitch) async {
    await _gate();
    _checkFinite(pitch, 'pitch');
    await _prop('pitch', pitch.toStringAsFixed(4));
    _updateField((s) => s.copyWith(pitch: pitch), _reactives.pitch, pitch);
  }

  /// Mutes or unmutes audio output.
  Future<void> setMute(bool mute) async {
    await _gate();
    await _prop('mute', mute ? 'yes' : 'no');
    _updateField((s) => s.copyWith(mute: mute), _reactives.mute, mute);
  }

  /// Sets the active audio output device.
  ///
  /// The `description` field of [device] is ignored — the description
  /// is resolved from `state.audioDevices` (mpv's authoritative
  /// `audio-device-list`). Pass [Device]s built from that list, or use
  /// the `name` only.
  Future<void> setAudioDevice(Device device) async {
    await _gate();
    await _prop('audio-device', device.name);
    _updateActiveAudioDevice(device.name);
  }

  /// Enables or disables pitch correction (mpv's `scaletempo` engine)
  /// for non-1.0 playback rates. When disabled, raising the rate also
  /// raises pitch (chipmunk effect); enabled keeps pitch constant.
  Future<void> setPitchCorrection(bool enable) async {
    await _gate();
    await _prop('audio-pitch-correction', enable ? 'yes' : 'no');
    _updateField((s) => s.copyWith(pitchCorrection: enable),
        _reactives.pitchCorrection, enable,);
  }

  /// Sets the audio delay relative to video (mpv's `audio-delay`).
  ///
  /// Sign convention: positive values **delay** audio relative to video
  /// (audio plays later), negative values **advance** it (audio plays
  /// earlier). This matches mpv's convention but is counterintuitive
  /// when thought of as "audio offset" — positive does NOT mean "audio
  /// ahead".
  ///
  /// Resolution is millisecond-rounded — sub-millisecond precision is
  /// stripped before the value is sent to mpv.
  Future<void> setAudioDelay(Duration delay) async {
    await _gate();
    await _prop('audio-delay', durationToSeconds(delay).toStringAsFixed(3));
    _updateField(
        (s) => s.copyWith(audioDelay: delay), _reactives.audioDelay, delay,);
  }

  /// Enables or disables gapless playback. See [Gapless] for the
  /// available variants.
  Future<void> setGapless(Gapless gapless) async {
    await _gate();
    await _prop('gapless-audio', gapless.mpvValue);
    _updateField(
        (s) => s.copyWith(gapless: gapless), _reactives.gapless, gapless,);
  }

  /// Sets the ReplayGain normalization configuration atomically.
  ///
  /// Writes the four backing mpv properties (`replaygain`,
  /// `replaygain-preamp`, `replaygain-clip`, `replaygain-fallback`) in
  /// one shot. If any of the writes fails, the previously-committed
  /// fields are rolled back to the prior [ReplayGainSettings] before
  /// the error is rethrown — the consumer never observes a half-applied
  /// state.
  Future<void> setReplayGain(ReplayGainSettings settings) async {
    await _gate();
    final previous = state.replayGain;
    final writes = <(String, String, String)>[
      ('replaygain', settings.mode.mpvValue, previous.mode.mpvValue),
      (
        'replaygain-preamp',
        settings.preamp.toStringAsFixed(2),
        previous.preamp.toStringAsFixed(2)
      ),
      (
        'replaygain-clip',
        settings.clip ? 'yes' : 'no',
        previous.clip ? 'yes' : 'no'
      ),
      (
        'replaygain-fallback',
        settings.fallback.toStringAsFixed(2),
        previous.fallback.toStringAsFixed(2)
      ),
    ];
    final committed = <(String, String)>[];
    try {
      for (final (name, value, prior) in writes) {
        await _prop(name, value);
        committed.add((name, prior));
      }
    } catch (_) {
      for (final (name, prior) in committed.reversed) {
        await _propRc(name, prior);
      }
      rethrow;
    }
    _updateField((s) => s.copyWith(replayGain: settings), _reactives.replayGain,
        settings,);
  }

  /// Sets volume gain in dB (pre-amplification on top of [setVolume]).
  ///
  /// Hard range: -150 to +150 dB. The default soft clamp mpv applies is
  /// -96 to +12 dB, configurable via [setVolumeGainMin] / [setVolumeGainMax].
  /// 0 dB = unity. Values above ~+6 dB risk clipping unless [setReplayGain]
  /// or a downstream limiter is in the chain.
  Future<void> setVolumeGain(double gainDb) async {
    await _gate();
    _checkFinite(gainDb, 'gainDb');
    await _prop('volume-gain', gainDb.toStringAsFixed(2));
    _updateField(
        (s) => s.copyWith(volumeGain: gainDb), _reactives.volumeGain, gainDb,);
  }

  /// Sets the lower clamp applied to [setVolumeGain], in dB
  /// (mpv's `volume-gain-min`). Range -150 to 0; default -96.
  Future<void> setVolumeGainMin(double gainDb) async {
    await _gate();
    _checkFinite(gainDb, 'gainDb');
    await _prop('volume-gain-min', gainDb.toStringAsFixed(2));
    _updateField((s) => s.copyWith(volumeGainMin: gainDb),
        _reactives.volumeGainMin, gainDb,);
  }

  /// Sets the upper clamp applied to [setVolumeGain], in dB
  /// (mpv's `volume-gain-max`). Range 0 to 150; default +12.
  Future<void> setVolumeGainMax(double gainDb) async {
    await _gate();
    _checkFinite(gainDb, 'gainDb');
    await _prop('volume-gain-max', gainDb.toStringAsFixed(2));
    _updateField((s) => s.copyWith(volumeGainMax: gainDb),
        _reactives.volumeGainMax, gainDb,);
  }

  /// Sets the OS per-app mixer volume in percent (`ao-volume`) — the system
  /// volume slider for this app, distinct from the soft [setVolume].
  ///
  /// Best-effort: when the active audio output doesn't expose system volume
  /// (the null AO, or a backend without per-app volume) the call is silently
  /// ignored — it does NOT throw, and [PlayerState.systemVolume] stays `null`.
  Future<void> setSystemVolume(double volume) async {
    await _gate();
    _checkFinite(volume, 'volume');
    final rc = await _propRc('ao-volume', volume.toStringAsFixed(1));
    if (rc >= 0) {
      _updateField((s) => s.copyWith(systemVolume: volume),
          _reactives.systemVolume, volume,);
    }
  }

  /// Sets the OS per-app mute (`ao-mute`), distinct from the soft [setMute].
  ///
  /// Best-effort, like [setSystemVolume]: silently ignored (no throw) when the
  /// active audio output doesn't expose system mute (e.g. coreaudio on macOS).
  Future<void> setSystemMute(bool mute) async {
    await _gate();
    final rc = await _propRc('ao-mute', mute ? 'yes' : 'no');
    if (rc >= 0) {
      _updateField(
          (s) => s.copyWith(systemMute: mute), _reactives.systemMute, mute,);
    }
  }

  /// Sets the upper bound the user-facing volume scale is clamped to.
  ///
  /// Range: 100 to 1000. Default 130 (matches mpv's default and the slider
  /// range most apps expose). Setting above 100 lets [setVolume] amplify
  /// past unity; values up to 1000 = +20 dB digital boost. mpv hard-rejects
  /// values below 100.
  Future<void> setVolumeMax(double limit) async {
    await _gate();
    _checkFinite(limit, 'limit');
    await _prop('volume-max', limit.toStringAsFixed(1));
    _updateField(
        (s) => s.copyWith(volumeMax: limit), _reactives.volumeMax, limit,);
  }

  /// Enables exclusive audio mode (WASAPI / ALSA / CoreAudio).
  Future<void> setAudioExclusive(bool exclusive) async {
    await _gate();
    await _prop('audio-exclusive', exclusive ? 'yes' : 'no');
    _updateField((s) => s.copyWith(audioExclusive: exclusive),
        _reactives.audioExclusive, exclusive,);
  }

  /// Whether mpv reports a "music" media role to the OS audio server
  /// (mpv's `audio-set-media-role`). On PulseAudio / PipeWire (Linux) this
  /// lets the server apply the right routing / volume profile for music;
  /// a no-op on backends without a media-role concept.
  Future<void> setAudioMediaRole(bool enable) async {
    await _gate();
    await _prop('audio-set-media-role', enable ? 'yes' : 'no');
    _updateField((s) => s.copyWith(audioMediaRole: enable),
        _reactives.audioMediaRole, enable,);
  }

  /// Sets HDMI/S/PDIF audio passthrough codecs.
  ///
  /// Pass a [Set] of [Spdif] values to enable passthrough for those
  /// codecs (e.g. `{Spdif.ac3, Spdif.dts}`); pass `{}` to disable
  /// passthrough entirely. Order does not matter.
  Future<void> setAudioSpdif(Set<Spdif> codecs) async {
    await _gate();
    await _prop('audio-spdif', Spdif.formatMpvList(codecs));
    _updateField(
        (s) => s.copyWith(audioSpdif: codecs), _reactives.audioSpdif, codecs,);
  }

  /// Selects the audio track via a typed [Track] —
  /// [Track.auto] defers to mpv's automatic choice
  /// (container default or first audio track),
  /// [Track.off] disables audio output entirely, and
  /// [Track.id] selects a specific track by its mpv ID
  /// (match an entry in [PlayerState.tracks]).
  ///
  /// State updates flow through the `current-tracks/audio` observer
  /// (no optimistic update — mpv may reject an unknown id).
  Future<void> setAudioTrack(Track track) async {
    await _gate();
    await _prop('aid', track.mpvValue);
  }

  /// Loads an external audio file as an additional selectable track on the
  /// currently-playing file (mpv's `audio-add`) — e.g. a separate-language
  /// dub or a commentary track. The new track appears in
  /// [PlayerState.tracks]; switch to it with [setAudioTrack].
  ///
  /// [select] `true` (default) selects the new track immediately; `false`
  /// adds it without switching. [title] / [lang] tag it for the track list.
  /// Requires a file to be loaded first. Per-[Media] options
  /// (`httpHeaders`, …) are validated but not applied — `audio-add` has no
  /// file-local options slot.
  Future<void> addAudioTrack(
    Media file, {
    bool select = true,
    String? title,
    String? lang,
  }) async {
    _checkNotDisposed();
    // Snapshot the load epoch: a content-replacing call landing while the
    // URI resolves makes this add stale — the track belongs to the file
    // that is no longer playing (see [Player.open]).
    final epoch = _loadEpoch;
    await _gate();
    _validateLoadOptions(file);
    final resolved = await resolveUri(file.uri);
    if (_disposed || epoch != _loadEpoch) {
      await resolved.dispose?.call();
      return;
    }
    final args = <String>['audio-add', resolved.uri, select ? 'select' : 'auto'];
    // mpv's args are positional: to pass `lang` you must also pass `title`.
    if (title != null || lang != null) args.add(title ?? '');
    if (lang != null) args.add(lang);
    await _command(args);
  }

  /// Removes an audio track (mpv's `audio-remove`). Pass [Track.id] to remove
  /// a specific track (typically one added via [addAudioTrack]); [Track.auto]
  /// removes the currently-selected audio track. The track-list observer
  /// folds the removal back into [PlayerState.tracks].
  ///
  /// [Track.off] is rejected with an [ArgumentError]: mpv's `audio-remove`
  /// takes an optional track id and has no "off" notion, so removing "no
  /// track" is meaningless. Use [setAudioTrack] with [Track.off] to mute the
  /// selection instead.
  Future<void> removeAudioTrack(Track track) async {
    _checkNotDisposed();
    if (track is TrackOff) {
      throw ArgumentError.value(
        track,
        'track',
        'Track.off has no meaning for removeAudioTrack — pass Track.id to '
            'remove a specific track or Track.auto to remove the current one.',
      );
    }
    await _gate();
    await _command(track is TrackId
        ? ['audio-remove', '${track.trackId}']
        : ['audio-remove'],);
  }

  /// Forcibly reloads the audio output.
  Future<void> reloadAudio() async {
    await _gate();
    await _command(['ao-reload']);
  }

  /// Re-scans sidecar external files (auto-loaded audio / cover art) for the
  /// current file — mpv's `rescan-external-files`. Use after dropping a cover
  /// or companion audio file next to the playing file so it gets picked up
  /// without reopening. With [keepSelection] the current track selection is
  /// preserved; otherwise mpv reselects the default streams. Newly found
  /// tracks / cover art fold into [PlayerState.tracks] / the cover-art stream.
  Future<void> rescanExternalFiles({bool keepSelection = false}) async {
    await _gate();
    await _command(
        ['rescan-external-files', keepSelection ? 'keep-selection' : 'reselect'],);
  }

  // ── DSP pipeline ────────────────────────────────────────────────────
  // The DSP pipeline lives in a single [AudioEffects] bundle. Apply it
  // atomically with [setAudioEffects] (replace) or [updateAudioEffects]
  // (Freezed-style copyWith mapper). Each per-effect Settings owns an
  // `enabled` flag — disabling a stage drops it from the pipeline while
  // preserving its parameters on the bundle for the next toggle.

  /// Replaces the entire DSP pipeline in one atomic write.
  ///
  /// Use for full-bundle config (initial setup, preset application,
  /// preset restore from JSON). To mutate a single field — typical of
  /// UI sliders — prefer [updateAudioEffects].
  ///
  /// `effects.custom` carries raw mpv `--af` effect strings consumed
  /// verbatim — useful for expression-based effects (`pan`, `aeval`)
  /// or any effect without a typed equivalent on the bundle.
  /// The bundle is the only writer of mpv's `af` property: raw writes
  /// via `setRawProperty('af', ...)` are rejected, and any pre-existing
  /// `af` value (e.g. from `mpv.conf`) is overridden by the first call
  /// here.
  Future<void> setAudioEffects(AudioEffects effects) async {
    await _gate();
    await _applyAudioEffects(effects);
  }

  /// Whether the bundle has written `af` at least once. The first write
  /// must always go through — it overrides any pre-existing `af` value
  /// (e.g. from `mpv.conf`) even when the requested bundle equals the
  /// default state.
  bool _afChainWritten = false;

  /// Write + commit shared by [setAudioEffects] and [updateAudioEffects].
  /// The diff computation, the wire enqueue and the state commit are all
  /// SUSPENSION-FREE — [updateAudioEffects] relies on mapper → enqueue →
  /// commit happening in one microtask so that concurrent un-awaited calls
  /// each observe the previous commit, and the async client API enqueues
  /// in call order so the core sees the writes FIFO. Only the mpv
  /// confirmation (the returned future) is deferred.
  ///
  /// Parameter-only changes on command-capable filters go through
  /// `af-command` — the live graph updates in place instead of being
  /// torn down and rebuilt (glitch-free slider drags). Topology changes,
  /// non-runtime options, and command failures fall back to the full
  /// `af` rewrite, which is always correct.
  Future<void> _applyAudioEffects(AudioEffects effects) {
    // No-op writes skip the serialization + FFI round-trip entirely.
    // Cheap check: copyWith shares unchanged sub-settings by reference,
    // so `==` short-circuits on identical().
    if (_afChainWritten && effects == _state.audioEffects) {
      return Future.value();
    }
    final cmds =
        _afChainWritten ? effects.diffCommands(_state.audioEffects) : null;
    final Future<void> settled;
    if (cmds != null) {
      // Enqueue the whole diff now (in order); validate the outcomes when
      // the replies land. The string is stale the moment the commands are
      // queued — the live graph moves ahead of the `af` property.
      final rcs = <Future<int>>[
        for (final c in cmds)
          _command(['af-command', c.label, c.option, c.value, c.filterName]),
      ];
      if (cmds.isNotEmpty) _afStringStale = true;
      settled = _settleAfCommands(rcs);
    } else {
      // The `af` string flag is owned by _rewriteAfChain: cleared only once
      // the rewrite reply confirms the string matches the live graph, and
      // re-armed if the write is rejected (clearing it eagerly here would,
      // on a failed rewrite that followed a diff, skip the FILE_LOADED resync
      // and silently lose the diff'd runtime value).
      final previous = _state.audioEffects;
      settled = _rewriteAfChain(effects, previous);
    }
    _afChainWritten = true;
    _updateField(
      (s) => s.copyWith(audioEffects: effects),
      _reactives.audioEffects,
      effects,
    );
    return settled;
  }

  /// Awaits the diff's replies; on any rejected command rewrites the chain
  /// from the LATEST committed bundle, healing a partial apply (and any
  /// later updates already committed — mpv dedups identical `af` strings,
  /// so a redundant rewrite is cheap).
  Future<void> _settleAfCommands(List<Future<int>> rcs) async {
    final results = await Future.wait(rcs);
    if (results.any((rc) => rc < 0)) {
      final healRc = await _propRc('af', _state.audioEffects.toAfChain());
      // Only mark the string clean if the heal write actually landed; a
      // rejected heal leaves it stale for the next FILE_LOADED resync.
      if (healRc >= 0) _afStringStale = false;
    }
  }

  /// Awaits the full-rewrite reply and owns the `_afStringStale` flag. On
  /// success the `af` string matches the live graph (flag cleared). On
  /// rejection (e.g. a malformed [AudioEffects.custom] entry) the string is
  /// in an unknown state vs the committed bundle — a preceding diff may have
  /// moved the live graph ahead of it — so the flag is RE-ARMED for the next
  /// FILE_LOADED resync, the optimistic commit is rolled back to [previous]
  /// (unless a later update already replaced it), and the [MpvException]
  /// propagates to the caller.
  Future<void> _rewriteAfChain(AudioEffects effects, AudioEffects previous) async {
    try {
      await _prop('af', effects.toAfChain());
      _afStringStale = false;
    } catch (_) {
      _afStringStale = true;
      if (identical(_state.audioEffects, effects)) {
        _updateField(
          (s) => s.copyWith(audioEffects: previous),
          _reactives.audioEffects,
          previous,
        );
      }
      rethrow;
    }
  }

  /// Mutates the audio-effects bundle with a Freezed-style copyWith
  /// mapper.
  ///
  /// Convenience over `setAudioEffects(state.audioEffects.copyWith(...))`.
  /// The mapper receives the current bundle and must return the new
  /// one — same semantics as Riverpod's `update`.
  ///
  /// Example:
  /// ```dart
  /// // Toggle the compressor (a never-configured slot is seeded with
  /// // its defaults by the per-effect updater):
  /// await player.updateAudioEffects(
  ///   (e) => e.updateAcompressor((c) => c.copyWith(enabled: !c.enabled)),
  /// );
  ///
  /// // Replace one effect entirely:
  /// await player.updateAudioEffects((e) => e.copyWith(
  ///   acompressor: const AcompressorSettings(
  ///     enabled: true, threshold: 0.1, ratio: 4),
  /// ));
  /// ```
  Future<void> updateAudioEffects(
    AudioEffects Function(AudioEffects) mapper,
  ) async {
    _checkNotDisposed();
    // Run the mapper only AFTER the ready gate, and commit in the same
    // microtask: two un-awaited calls in one synchronous turn would
    // otherwise both run their mapper on the same pre-commit bundle, and
    // the second commit would silently drop the first mutation. The
    // single suspension point serializes each read-modify-write in call
    // order on the microtask queue.
    await _gate();
    await _applyAudioEffects(mapper(_state.audioEffects));
  }

  // ── Cover Art ──────────────────────────────────────────────────────────────

  /// Controls whether mpv automatically loads external cover art files
  /// sitting next to the audio file (e.g. `cover.jpg`). See [Cover] for
  /// the available variants. Embedded cover bytes are surfaced through
  /// [PlayerStream.coverArt] regardless of this setting.
  Future<void> setCoverArtAuto(Cover cover) async {
    await _gate();
    await _prop('cover-art-auto', cover.mpvValue);
    _updateField(
        (s) => s.copyWith(coverArtAuto: cover), _reactives.coverArtAuto, cover,);
  }

  /// Sets the target audio sample rate.
  Future<void> setAudioSampleRate(int rate) async {
    await _gate();
    await _prop('audio-samplerate', rate.toString());
    _updateField((s) => s.copyWith(audioSampleRate: rate),
        _reactives.audioSampleRate, rate,);
  }

  /// Sets the target audio sample format. Use [Format.auto] to
  /// reset to mpv's pick.
  Future<void> setAudioFormat(Format format) async {
    await _gate();
    await _prop('audio-format', format.mpvValue);
    _updateField(
        (s) => s.copyWith(audioFormat: format), _reactives.audioFormat, format,);
  }

  /// Sets the target audio channel layout. Use the named static
  /// constants on [Channels] for common presets, or
  /// [Channels.custom] for any other mpv-recognised layout
  /// string.
  Future<void> setAudioChannels(Channels channels) async {
    await _gate();
    await _prop('audio-channels', channels.mpvValue);
    _updateField((s) => s.copyWith(audioChannels: channels),
        _reactives.audioChannels, channels,);
  }

  /// Sets the audio client name.
  Future<void> setAudioClientName(String name) async {
    await _gate();
    await _prop('audio-client-name', name);
    _updateField((s) => s.copyWith(audioClientName: name),
        _reactives.audioClientName, name,);
  }

  /// Sets the audio output driver — e.g. `'coreaudio'` (macOS),
  /// `'wasapi'` (Windows), `'pulse'` / `'alsa'` / `'pipewire'` (Linux).
  ///
  /// Pass `'auto'` or an empty string to let mpv auto-probe the best
  /// available backend (the default). mpv has no backend literally named
  /// `auto` — setting `ao=auto` fails to initialize any output — so both
  /// are normalized to an empty `ao`, which is mpv's auto-probe value.
  Future<void> setAudioDriver(String driver) async {
    await _gate();
    // 'auto' is a convenience alias for mpv's empty-string auto-probe;
    // the literal string 'auto' is not a valid AO backend.
    final ao = driver == 'auto' ? '' : driver;
    await _prop('ao', ao);
    _updateField(
        (s) => s.copyWith(audioDriver: ao), _reactives.audioDriver, ao,);
  }

  // ── Spectrum / PCM streams ───────────────────────────────────────────
  // The FFT spectrum + raw PCM streams are a separate subsystem from
  // the typed mpv setters above — they don't write any mpv property,
  // they configure the polling pipeline that reads the
  // `pcm-tap-frame` property at the configured emit rate.

  /// Replaces the spectrum / PCM pipeline configuration.
  ///
  /// Use for full-bundle config (initial setup, preset application).
  /// To mutate a single field — typical of UI sliders — prefer
  /// [updateSpectrum].
  ///
  /// Reallocates FFT memory only when [SpectrumSettings.fftSize] /
  /// window / band layout actually changes; idempotent on no-op
  /// settings. Re-arms the poll timer when [SpectrumSettings.emitInterval]
  /// changes mid-stream.
  ///
  /// The pipeline is **lazy** — calling this when nobody has
  /// subscribed to [PlayerStream.spectrum] / [PlayerStream.pcm] just
  /// updates the pending configuration; the poll loop only starts on
  /// the first subscriber.
  Future<void> setSpectrum(SpectrumSettings settings) async {
    await _gate();
    _spectrumPipeline.setSettings(settings);
  }

  /// Mutates the spectrum settings with a Freezed-style copyWith
  /// mapper.
  ///
  /// Convenience over `setSpectrum(spectrumSettings.copyWith(...))`.
  /// The mapper receives the current bundle and must return the new
  /// one — same semantics as `Player.updateAudioEffects`.
  ///
  /// Example:
  /// ```dart
  /// // Switch to 60 fps with a Blackman-Harris window:
  /// await player.updateSpectrum((s) => s.copyWith(
  ///   emitInterval: const Duration(milliseconds: 16),
  ///   window: WindowFunction.blackmanHarris,
  /// ));
  /// ```
  Future<void> updateSpectrum(
    SpectrumSettings Function(SpectrumSettings) mapper,
  ) async {
    await setSpectrum(mapper(_spectrumPipeline.settings));
  }

  /// Current spectrum / PCM pipeline configuration. Reflects the last
  /// [setSpectrum] / [updateSpectrum] call (or [SpectrumSettings.defaults]
  /// when never set).
  SpectrumSettings get spectrumSettings => _spectrumPipeline.settings;
}
