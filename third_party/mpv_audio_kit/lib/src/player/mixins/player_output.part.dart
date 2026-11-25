// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
part of '../player.dart';

/// The audio output: the device and the driver, the exclusive mode and
/// the media role, passthrough, and the rate, format and channel layout
/// asked of the output.
mixin _OutputModule on _PlayerBase, _PropertiesModule {
  /// Sets the active audio output device.
  ///
  /// The `description` field of [device] is ignored: the description
  /// is resolved from `state.output.audioDevices` (mpv's authoritative
  /// `audio-device-list`). Pass [Device]s built from that list, or use
  /// the `name` only.
  Future<void> setAudioDevice(Device device) async {
    await _gate();
    await _calls.prop('audio-device', device.name);
    _updateActiveAudioDevice(device.name);
  }

  /// Requests exclusive use of the audio device (mpv's `audio-exclusive`).
  ///
  /// - WASAPI (Windows) and CoreAudio (macOS) take the device for the
  ///   player and switch it to the track's rate when it supports it, so
  ///   the system mixer neither resamples nor sets the volume. Other apps
  ///   have no sound on that device. The player keeps it while paused and
  ///   at the end of the queue, until [Player.stop], a call with `false`
  ///   or [Player.dispose].
  /// - PipeWire keeps other streams off the sink, but the stream still
  ///   goes through PipeWire: its volume applies, and the audio is
  ///   resampled when the rate is not one the server allows.
  /// - On Android the default `audiotrack` driver ignores it. `aaudio`
  ///   gets an exclusive stream only with mpv's `aaudio-performance-mode`
  ///   set to `low-latency`, on Android 8.1 or later with a device that
  ///   supports it, and the system has the last word. Other apps keep
  ///   playing.
  /// - On iOS it has no effect: the audio never mixes with other apps,
  ///   and changing the value only reopens the output.
  ///
  /// Other drivers ignore it.
  Future<void> setAudioExclusive(bool exclusive) async {
    await _write(
      'audio-exclusive',
      exclusive ? 'yes' : 'no',
      _reactives.audioExclusive,
      exclusive,
      (s) => s.copyWith(audioExclusive: exclusive),
    );
  }

  /// Whether mpv reports a "music" media role to the OS audio server
  /// (mpv's `audio-set-media-role`). On PulseAudio and PipeWire (Linux) this
  /// lets the server apply the right routing and volume profile for music.
  /// On Android the `audiotrack` driver, and `aaudio` from API 28, only tag
  /// the content type as music: the usage stays media, so routing and
  /// volume do not change. Other drivers ignore it.
  Future<void> setAudioMediaRole(bool enable) async {
    await _write(
      'audio-set-media-role',
      enable ? 'yes' : 'no',
      _reactives.audioMediaRole,
      enable,
      (s) => s.copyWith(audioMediaRole: enable),
    );
  }

  /// Sets HDMI and S/PDIF audio passthrough codecs.
  ///
  /// Pass a [Set] of [Spdif] values to enable passthrough for those
  /// codecs (e.g. `{Spdif.ac3, Spdif.dts}`); pass `{}` to disable
  /// passthrough entirely. Order does not matter.
  ///
  /// While a track passes through, the receiver decodes it and mpv cannot
  /// touch the audio: the effects chain, the soft volume and mute,
  /// ReplayGain, the volume gain, pitch, and the output rate, format and
  /// channels do not apply, a speed other than 1 drops or repeats parts of
  /// the stream instead of stretching it, and [PlayerStream.fft],
  /// [PlayerStream.pcm], the taps and [PlayerStream.loudnessMeter] emit
  /// nothing. When the output refuses the format, mpv decodes the track
  /// instead. Changed during playback, the list reopens the decoder, with
  /// a short gap.
  Future<void> setAudioSpdif(Set<Spdif> codecs) async {
    // A copy: the caller's set, changed later, must not change the state.
    final value = Set<Spdif>.unmodifiable(codecs);
    await _write(
      'audio-spdif',
      Spdif.formatMpvList(value),
      _reactives.audioSpdif,
      value,
      (s) => s.copyWith(audioSpdif: value),
    );
  }

  /// Sets the target audio sample rate.
  ///
  /// The output driver can still change it: [OutputState.audioOutParams]
  /// shows the rate the device gets. On Android `audiotrack` plays at most
  /// at the device's native rate, usually 48 kHz. Changed during playback,
  /// it reopens the output, with a short gap. A track in passthrough
  /// ([setAudioSpdif]) ignores it.
  ///
  /// On the web the page's audio output is remade at [rate] (`0` for the
  /// device's), so the browser does not resample: every player of the
  /// page plays at that rate. A rate the browser refuses throws a
  /// [StateError]: the page's output stays at the rate before, and so do
  /// this player's `audio-samplerate` and [PlayerSettings.audioSampleRate],
  /// unless another call set a rate since.
  ///
  /// Throws [RangeError] outside 0 to 768000, mpv's range (`0` leaves the
  /// rate to the file).
  Future<void> setAudioSampleRate(int rate) async {
    RangeError.checkValueInInterval(rate, 0, 768000, 'rate');
    await _gate();
    // Taken before the write: the observer of audio-samplerate may report
    // the new rate before the browser refuses it.
    final before = _state.settings.audioSampleRate;
    await _calls.prop('audio-samplerate', rate.toString());
    final output = setOutputSampleRate(rate);
    if (output != null) {
      try {
        await output;
      } catch (_) {
        // The browser refused the rate and kept its output at the rate
        // before: mpv and the state go back to it too, unless another
        // call wrote a rate since, which stands.
        if (await _readString('audio-samplerate') == rate.toString()) {
          await _calls.prop('audio-samplerate', before.toString());
          _updateField(
            (s) => s.copyWith(audioSampleRate: before),
            _reactives.audioSampleRate,
            before,
          );
        }
        rethrow;
      }
    }
    _updateField(
      (s) => s.copyWith(audioSampleRate: rate),
      _reactives.audioSampleRate,
      rate,
    );
  }

  /// Sets the target audio sample format. Use [Format.auto] to
  /// reset to mpv's pick.
  ///
  /// The output driver can still change it: [OutputState.audioOutParams]
  /// shows the format the device gets. On Android `audiotrack` plays only
  /// 8-bit, 16-bit and float samples, so other integer formats become
  /// 16-bit, and `aaudio` takes 32-bit integers from Android 12 (API 31).
  /// For a source above 16 bits there, [Format.float32] keeps the
  /// resolution. Changed during playback, it reopens the output, with a
  /// short gap. A track in passthrough ([setAudioSpdif]) ignores it.
  Future<void> setAudioFormat(Format format) async {
    await _write(
      'audio-format',
      format.mpvValue,
      _reactives.audioFormat,
      format,
      (s) => s.copyWith(audioFormat: format),
    );
  }

  /// Sets the target audio channel layout. Use the named static
  /// constants on [Channels] for common presets, or
  /// [Channels.custom] for any other mpv-recognised layout
  /// string. Changed during playback, it reopens the output, with a short
  /// gap. A track in passthrough ([setAudioSpdif]) ignores it.
  Future<void> setAudioChannels(Channels channels) async {
    await _write(
      'audio-channels',
      channels.mpvValue,
      _reactives.audioChannels,
      channels,
      (s) => s.copyWith(audioChannels: channels),
    );
  }

  /// Sets the audio client name.
  Future<void> setAudioClientName(String name) async {
    await _write(
      'audio-client-name',
      name,
      _reactives.audioClientName,
      name,
      (s) => s.copyWith(audioClientName: name),
    );
  }

  /// Sets the audio output driver, e.g. `'coreaudio'` (macOS),
  /// `'wasapi'` (Windows), `'pulse'`, `'alsa'` or `'pipewire'` (Linux).
  ///
  /// On Android the automatic choice is `audiotrack`. `aaudio` needs
  /// Android 8 (API 26): below it mpv falls back to its null output and
  /// nothing is heard. `opensles` plays stereo only.
  ///
  /// Pass `'auto'` or an empty string to let mpv auto-probe the best
  /// available backend (the default). mpv has no backend literally named
  /// `auto` (setting `ao=auto` fails to initialize any output), so both
  /// are normalized to an empty `ao`, which is mpv's auto-probe value.
  Future<void> setAudioDriver(String driver) async {
    // 'auto' is a convenience alias for mpv's empty-string auto-probe;
    // the literal string 'auto' is not a valid AO backend.
    final ao = driver == 'auto' ? '' : driver;
    await _write(
      'ao',
      ao,
      _reactives.audioDriver,
      ao,
      (s) => s.copyWith(audioDriver: ao),
    );
  }
}
