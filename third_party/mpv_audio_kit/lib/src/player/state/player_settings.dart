// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import '../../generated/audio_effects_settings.dart';
import '../../internals/unset_sentinel.dart';
import '../../models/media_session.dart';
import '../../types/enums/cover.dart';
import '../../types/enums/format.dart';
import '../../types/enums/gapless.dart';
import '../../types/enums/hls_bitrate.dart';
import '../../types/enums/spdif.dart';
import '../../types/sealed/channels.dart';
import '../../types/settings/cache_settings.dart';
import '../../types/settings/demuxer_settings.dart';
import '../../types/settings/replay_gain_settings.dart';
import '../../types/settings/spectrum_settings.dart';

part '../../generated/player_settings_data.dart';

/// What the app asked of the player: volume and speed, the effects and the
/// analysis, the output it wants, the network and the media session.
///
/// The [PlayerState.settings] of a player: read it from
/// `player.state.settings`, or follow one value through its stream in
/// `player.stream`.
///
/// {@category State and streams}
final class PlayerSettings with _$PlayerSettings {
  /// Current soft volume in percent, 0 to 1000. 100 is unity, and values
  /// above it amplify the signal.
  final double volume;

  /// Whether the player is muted.
  final bool mute;

  /// mpv's `volume-max`, 100 to 1000 (default 130): the top of mpv's
  /// relative volume steps and a natural top for a volume slider. It does
  /// not cap [Player.setVolume].
  final double volumeMax;

  /// Software volume gain in dB.
  final double volumeGain;

  /// mpv's `volume-gain-min`, in dB (default -96): the floor of mpv's
  /// relative steps on the gain, not of [Player.setVolumeGain]. Set via
  /// [Player.setVolumeGainMin].
  final double volumeGainMin;

  /// mpv's `volume-gain-max`, in dB (default +12): the top of mpv's
  /// relative steps on the gain, not of [Player.setVolumeGain]. Set via
  /// [Player.setVolumeGainMax].
  final double volumeGainMax;

  /// Playback speed multiplier. 1.0 = normal speed.
  final double rate;

  /// Pitch multiplier. 1.0 = original pitch.
  final double pitch;

  /// Whether pitch correction is enabled when changing playback speed.
  final bool pitchCorrection;

  /// Audio delay applied to the output stream, against the playback
  /// clock. Positive values delay the audio; negative values advance it.
  final Duration audioDelay;

  /// Gapless playback mode.
  final Gapless gapless;

  /// ReplayGain configuration. Set via [Player.setReplayGain].
  final ReplayGainSettings replayGain;

  /// The DSP effects in mpv's `--af` chain, as an ordered list applied
  /// in order. Set via [Player.setAudioEffects]
  /// (replace) or [Player.updateAudioEffects] (mapper). Read live via
  /// [PlayerStream.audioEffects].
  final List<AudioEffect> audioEffects;

  /// The configuration of the FFT pipeline behind [PlayerStream.fft]
  /// (size, bands, window, emit rate, smoothing, dB range). Set via
  /// [Player.setSpectrum] or [Player.updateSpectrum], read live via
  /// [PlayerStream.spectrum]. Lives on the Dart side only.
  final SpectrumSettings spectrum;

  /// Controls whether mpv automatically loads external cover art files.
  /// See [Cover] for the available variants.
  final Cover coverArtAuto;

  /// Whether mpv prefetches the next playlist item in the background.
  ///
  /// When `true`, the demuxer for the next track opens before the current
  /// one finishes, eliminating the file-boundary stall. Observe progress
  /// via [PlayerStream.prefetchState].
  final bool prefetchPlaylist;

  /// Cache configuration. Set via [Player.setCache].
  final CacheSettings cache;

  /// Demuxer buffering configuration (forward cache cap, seekback cap,
  /// readahead). Set via [Player.setDemuxer]. Distinct from
  /// [NetworkState.demuxerCacheState], which is the live read-only cache
  /// snapshot.
  final DemuxerSettings demuxer;

  /// Network connection timeout. Default 60s mirrors mpv's
  /// `--network-timeout=60`.
  final Duration networkTimeout;

  /// Whether to verify TLS/SSL certificates on `https://` streams.
  ///
  /// [PlayerConfiguration.tlsVerify] at the start, `true` by default: the
  /// bundled libmpv carries the Mozilla CA roots, so it works on every
  /// platform. Change it with [Player.setTlsVerify].
  final bool tlsVerify;

  /// Absolute filesystem path to a custom PEM bundle of trusted CA
  /// certificates, or empty string when the built-in roots are used.
  ///
  /// Empty by default: the bundled libmpv has the Mozilla CA roots compiled
  /// in, so [tlsVerify] works on every platform out of the box. Set
  /// [Player.setTlsCaFile] to override those roots with a custom bundle
  /// (e.g. a corporate trust root).
  final String tlsCaFile;

  /// Absolute filesystem path to a PEM file of certificates trusted on top
  /// of the roots in use, or empty string for none. Set with
  /// [Player.setTlsExtraCaFile]: for a home server with a self-signed
  /// certificate or a private CA, while public servers are verified as
  /// before.
  final String tlsExtraCaFile;

  /// HLS variant-selection policy (`hls-bitrate`). Default [HlsBitrate.max]
  /// mirrors mpv. Set via [Player.setHlsBitrate].
  final HlsBitrate hlsBitrate;

  /// Whether mpv's HTTP cookie jar is enabled for network streams
  /// (`cookies`). Mirrors mpv's default of `false`. Set via
  /// [Player.setCookies].
  final bool cookies;

  /// HTTP proxy URL applied to network streams (`http-proxy`), or empty
  /// string when none is configured. Set via [Player.setHttpProxy].
  final String httpProxy;

  /// Whether audio exclusive mode is requested. What it does depends on
  /// the driver: see [Player.setAudioExclusive].
  final bool audioExclusive;

  /// Whether mpv tags the stream's media role as "music" on the OS audio
  /// server (`audio-set-media-role`): a role on PulseAudio and PipeWire, a
  /// content type on Android. Set via [Player.setAudioMediaRole].
  final bool audioMediaRole;

  /// Audio buffer size.
  final Duration audioBuffer;

  /// Whether to stream silence when nothing is playing.
  final bool audioStreamSilence;

  /// Whether the null audio output runs untimed (`ao-null-untimed`).
  final bool audioNullUntimed;

  /// S/PDIF passthrough codecs. Empty set = passthrough disabled.
  /// Apply via [Player.setAudioSpdif].
  final Set<Spdif> audioSpdif;

  /// Target sample rate (0 for auto).
  final int audioSampleRate;

  /// Sample format requested from mpv. `Format.auto` defers to
  /// mpv's pick; the other variants force a specific bit depth,
  /// signedness or planarity. Setter: [Player.setAudioFormat].
  final Format audioFormat;

  /// Channel-layout request. Use the named static fields for the common
  /// presets (mono, stereo, 5.1, 7.1, …) or
  /// `Channels.custom('…')` for any layout string mpv
  /// recognises. Setter: [Player.setAudioChannels].
  final Channels audioChannels;

  /// Audio client name (used by backend drivers like PulseAudio).
  final String audioClientName;

  /// Requested audio output driver ('coreaudio', 'pulse', 'alsa',
  /// 'wasapi', etc.), or empty for mpv's automatic choice, which is also
  /// what `setAudioDriver('auto')` stores.
  final String audioDriver;

  /// Active OS media-session config + metadata override, or `null`
  /// when no media session is currently published to the lockscreen,
  /// SMTC or MPRIS. Set via [Player.setMediaSession]; pass `null` to
  /// disable. See [MediaSession] for the full field semantics.
  final MediaSession? mediaSession;

  /// Creates a [PlayerSettings]; each value defaults to the one of a player
  /// that has loaded nothing.
  const PlayerSettings({
    this.volume = 100.0,
    this.mute = false,
    this.volumeMax = 130.0,
    this.volumeGain = 0.0,
    this.volumeGainMin = -96.0,
    this.volumeGainMax = 12.0,
    this.rate = 1.0,
    this.pitch = 1.0,
    this.pitchCorrection = true,
    this.audioDelay = Duration.zero,
    this.gapless = Gapless.weak,
    this.replayGain = const ReplayGainSettings(),
    this.audioEffects = const [],
    this.spectrum = SpectrumSettings.defaults,
    this.coverArtAuto = Cover.no,
    this.prefetchPlaylist = false,
    this.cache = const CacheSettings(),
    this.demuxer = const DemuxerSettings(),
    this.networkTimeout = const Duration(seconds: 60),
    this.tlsVerify = true,
    this.tlsCaFile = '',
    this.tlsExtraCaFile = '',
    this.hlsBitrate = HlsBitrate.max,
    this.cookies = false,
    this.httpProxy = '',
    this.audioExclusive = false,
    this.audioMediaRole = false,
    this.audioBuffer = const Duration(milliseconds: 200),
    this.audioStreamSilence = false,
    this.audioNullUntimed = false,
    this.audioSpdif = const <Spdif>{},
    this.audioSampleRate = 0,
    this.audioFormat = Format.auto,
    this.audioChannels = Channels.auto,
    this.audioClientName = 'mpv_audio_kit',
    this.audioDriver = '',
    this.mediaSession,
  });
}
