// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import '../generated/audio_effects_settings.dart';
import '../models/audio_params.dart';
import '../models/chapter.dart';
import '../models/device.dart';
import '../models/mpv_track.dart';
import '../types/enums/cover.dart';
import '../types/enums/format.dart';
import '../types/enums/gapless.dart';
import '../types/enums/hls_bitrate.dart';
import '../types/enums/spdif.dart';
import '../types/sealed/channels.dart';
import '../types/settings/cache_settings.dart';
import '../types/settings/demuxer_settings.dart';
import '../types/settings/replay_gain_settings.dart';
import '../types/state/audio_output_state.dart';
import '../types/state/mpv_prefetch_state.dart';
import 'reactive_property.dart';

/// Bundles the [ReactiveProperty]s that back state fields the registry
/// "owns" — for the most part one per observed mpv property, but a few
/// (`playing`, `audioParams`, `cache`, `replayGain`) are aggregate cells
/// that several specs share so dedup happens on the full struct.
class DefaultPropertyReactives {
  /// Creates the bundle with every cell seeded to mpv's documented default.
  DefaultPropertyReactives();

  // Lifecycle.

  /// Actual-output axis: `true` only while mpv is genuinely producing
  /// audio. Mirrors `core-idle` inverted, so it toggles transiently on
  /// every seek and while buffering. Use it for spinners, not the
  /// play/pause button.
  final ReactiveProperty<bool> playing = ReactiveProperty<bool>(false);

  /// User intent to play (the play/pause axis). Distinct from [playing]
  /// (which mirrors `core-idle` — actual output). Driven by the
  /// play/pause/open/stop call sites plus an idle-active reset, never by
  /// mpv's `pause` property; unaffected by seeking or buffering.
  final ReactiveProperty<bool> playWhenReady = ReactiveProperty<bool>(false);

  // Playback / timing.

  /// Current playhead position (`time-pos`).
  final ReactiveProperty<Duration> position =
      ReactiveProperty<Duration>(Duration.zero);

  /// Total duration of the current file (`duration`).
  final ReactiveProperty<Duration> duration =
      ReactiveProperty<Duration>(Duration.zero);

  /// Buffered-ahead time as a wall-clock instant (`demuxer-cache-time`).
  final ReactiveProperty<Duration> buffer =
      ReactiveProperty<Duration>(Duration.zero);

  /// Output volume in percent (`volume`); `100` is unattenuated.
  final ReactiveProperty<double> volume = ReactiveProperty<double>(100.0);

  /// Playback rate multiplier (`speed`); `1.0` is normal speed.
  final ReactiveProperty<double> rate = ReactiveProperty<double>(1.0);

  /// Pitch multiplier (`pitch`); `1.0` leaves pitch unchanged.
  final ReactiveProperty<double> pitch = ReactiveProperty<double>(1.0);

  /// Whether output is muted (`mute`).
  final ReactiveProperty<bool> mute = ReactiveProperty<bool>(false);

  /// Whether the playlist is played in shuffled order (`shuffle`).
  final ReactiveProperty<bool> shuffle = ReactiveProperty<bool>(false);

  /// Whether pitch is held constant when [rate] changes
  /// (`audio-pitch-correction`).
  final ReactiveProperty<bool> pitchCorrection = ReactiveProperty<bool>(true);

  /// Audio-versus-video sync offset (`audio-delay`).
  final ReactiveProperty<Duration> audioDelay =
      ReactiveProperty<Duration>(Duration.zero);

  /// Measured audio bitrate (`audio-bitrate`); `null` until known.
  final ReactiveProperty<double?> audioBitrate =
      ReactiveProperty<double?>(null);

  /// Currently selected output device (`audio-device`).
  final ReactiveProperty<Device> audioDevice =
      ReactiveProperty<Device>(const Device(name: 'auto', description: 'Auto'));

  /// Decoder-side audio parameters — aggregate of `audio-params` (NODE),
  /// `audio-codec`, and `audio-codec-name`. The three specs all dedup and
  /// emit on this single cell so listeners see one [AudioParams] snapshot
  /// per change.
  final ReactiveProperty<AudioParams> audioParams =
      ReactiveProperty<AudioParams>(const AudioParams());

  /// Hardware-side audio parameters (`audio-out-params`) — a single
  /// node-map; mpv exposes no codec/codec-name siblings on the output side.
  final ReactiveProperty<AudioParams> audioOutParamsNode =
      ReactiveProperty<AudioParams>(const AudioParams());

  /// ReplayGain configuration — aggregate of `replaygain`,
  /// `replaygain-preamp`, `replaygain-fallback`, and `replaygain-clip`.
  /// All four specs dedup and emit on this single cell.
  final ReactiveProperty<ReplayGainSettings> replayGain =
      ReactiveProperty<ReplayGainSettings>(const ReplayGainSettings());

  /// Decoder-side gain applied on top of [volume] (`volume-gain`), in dB.
  final ReactiveProperty<double> volumeGain = ReactiveProperty<double>(0.0);

  /// Lower clamp mpv applies to [volumeGain] (`volume-gain-min`), in dB.
  final ReactiveProperty<double> volumeGainMin =
      ReactiveProperty<double>(-96.0);

  /// Upper clamp mpv applies to [volumeGain] (`volume-gain-max`), in dB.
  final ReactiveProperty<double> volumeGainMax = ReactiveProperty<double>(12.0);

  /// OS per-app mixer volume in percent (`ao-volume`); `null` when the active
  /// audio output doesn't expose system volume (e.g. the null AO, or a
  /// backend without per-app volume). Best-effort — distinct from soft
  /// [volume].
  final ReactiveProperty<double?> systemVolume = ReactiveProperty<double?>(null);

  /// OS per-app mute (`ao-mute`); `null` when the active audio output doesn't
  /// expose system mute. Best-effort — distinct from soft [mute].
  final ReactiveProperty<bool?> systemMute = ReactiveProperty<bool?>(null);

  /// Gapless-playback policy across playlist boundaries (`gapless-audio`).
  final ReactiveProperty<Gapless> gapless =
      ReactiveProperty<Gapless>(Gapless.weak);

  /// Demuxer cache configuration — aggregate of `cache`, `cache-secs`,
  /// `cache-on-disk`, `cache-pause`, `cache-pause-wait`, and
  /// `cache-pause-initial`. All six specs dedup and emit on this single cell.
  final ReactiveProperty<CacheSettings> cache =
      ReactiveProperty<CacheSettings>(const CacheSettings());

  /// Demuxer buffering configuration — aggregate of `demuxer-max-bytes`,
  /// `demuxer-max-back-bytes`, and `demuxer-readahead-secs`. All three specs
  /// dedup and emit on this single cell so listeners see one [DemuxerSettings]
  /// snapshot per change.
  final ReactiveProperty<DemuxerSettings> demuxer =
      ReactiveProperty<DemuxerSettings>(const DemuxerSettings());

  /// Network I/O timeout (`network-timeout`).
  final ReactiveProperty<Duration> networkTimeout =
      ReactiveProperty<Duration>(const Duration(seconds: 60));

  /// Whether the server certificate is verified for TLS streams
  /// (`tls-verify`).
  final ReactiveProperty<bool> tlsVerify = ReactiveProperty<bool>(false);

  /// Path to a custom CA bundle for TLS verification (`tls-ca-file`).
  final ReactiveProperty<String> tlsCaFile = ReactiveProperty<String>('');

  /// HLS variant-selection policy (`hls-bitrate`).
  final ReactiveProperty<HlsBitrate> hlsBitrate =
      ReactiveProperty<HlsBitrate>(HlsBitrate.max);

  /// Whether the HTTP cookie jar is enabled for network streams (`cookies`).
  final ReactiveProperty<bool> cookies = ReactiveProperty<bool>(false);

  /// HTTP proxy URL for network streams (`http-proxy`); empty when none is
  /// configured.
  final ReactiveProperty<String> httpProxy = ReactiveProperty<String>('');

  /// Whether playback is currently paused waiting for the cache to fill
  /// (`paused-for-cache`).
  final ReactiveProperty<bool> pausedForCache = ReactiveProperty<bool>(false);

  /// Whether the current source is being read over the network
  /// (`demuxer-via-network`).
  final ReactiveProperty<bool> demuxerViaNetwork =
      ReactiveProperty<bool>(false);

  /// Whether the audio device is opened in exclusive mode (`audio-exclusive`).
  final ReactiveProperty<bool> audioExclusive = ReactiveProperty<bool>(false);

  /// Whether mpv tags the stream's media role as "music" on the audio server
  /// (`audio-set-media-role`; PulseAudio / PipeWire).
  final ReactiveProperty<bool> audioMediaRole = ReactiveProperty<bool>(false);

  /// Output device buffer size (`audio-buffer`).
  final ReactiveProperty<Duration> audioBuffer =
      ReactiveProperty<Duration>(const Duration(milliseconds: 200));

  /// Whether silence is streamed to keep the device open while idle
  /// (`audio-stream-silence`).
  final ReactiveProperty<bool> audioStreamSilence =
      ReactiveProperty<bool>(false);

  /// Whether the null audio output runs untimed (`ao-null-untimed`).
  final ReactiveProperty<bool> audioNullUntimed = ReactiveProperty<bool>(false);

  /// Full track inventory of the current file (`track-list`).
  final ReactiveProperty<List<MpvTrack>> tracks =
      ReactiveProperty<List<MpvTrack>>(const []);

  /// Currently selected audio track (`current-tracks/audio`); `null` when
  /// none is active.
  final ReactiveProperty<MpvTrack?> currentAudioTrack =
      ReactiveProperty<MpvTrack?>(null);

  /// Set of codecs currently passed through as bitstream (`audio-spdif`).
  final ReactiveProperty<Set<Spdif>> audioSpdif =
      ReactiveProperty<Set<Spdif>>(const <Spdif>{});

  /// Upper bound the [volume] setter accepts (`volume-max`), in percent.
  final ReactiveProperty<double> volumeMax = ReactiveProperty<double>(130.0);

  /// Forced output sample rate in Hz (`audio-samplerate`); `0` lets mpv
  /// choose. The *decoded* rate is `audio-params.sampleRate`, not this.
  final ReactiveProperty<int> audioSampleRate = ReactiveProperty<int>(0);

  /// Forced output sample format (`audio-format`); [Format.auto] lets mpv
  /// pick.
  final ReactiveProperty<Format> audioFormat =
      ReactiveProperty<Format>(Format.auto);

  /// Forced output channel layout (`audio-channels`); [Channels.auto] lets
  /// mpv pick.
  final ReactiveProperty<Channels> audioChannels =
      ReactiveProperty<Channels>(Channels.auto);

  /// Client name reported to the audio server (`audio-client-name`).
  final ReactiveProperty<String> audioClientName =
      ReactiveProperty<String>('mpv_audio_kit');

  /// Active audio output driver (`ao`).
  final ReactiveProperty<String> audioDriver = ReactiveProperty<String>('auto');

  /// DSP pipeline — the single bundle reactive backing every effect. Each
  /// effect owns a reserved label inside the `af` pipeline and is upserted
  /// atomically when the bundle is replaced via `Player.setAudioEffects` /
  /// `updateAudioEffects`.
  final ReactiveProperty<AudioEffects> audioEffects =
      ReactiveProperty<AudioEffects>(const AudioEffects());

  /// Audio output lifecycle state (`audio-output-state`).
  final ReactiveProperty<AudioOutputState> audioOutputState =
      ReactiveProperty<AudioOutputState>(AudioOutputState.closed);

  /// Policy for scanning sidecar cover-art files (`cover-art-auto`).
  final ReactiveProperty<Cover> coverArtAuto =
      ReactiveProperty<Cover>(Cover.no);

  /// Background prefetch progress (`prefetch-state`). An event-shaped
  /// signal, not a snapshot value: the cell exists for dedup and dispose
  /// bookkeeping, but the value is exposed exclusively through
  /// [PlayerStream.prefetchState] — never read `.value` from outside.
  final ReactiveProperty<MpvPrefetchState> prefetchState =
      ReactiveProperty<MpvPrefetchState>(MpvPrefetchState.idle);

  /// Seconds of audio buffered ahead in the background prefetch
  /// (`prefetch-cache-duration`), as a [Duration]. Pair with
  /// [prefetchState] for a determinate "Prefetching X%" bar. Stream-only,
  /// exposed through [PlayerStream.prefetchCacheDuration]; `Duration.zero`
  /// when no prefetch is in flight.
  final ReactiveProperty<Duration> prefetchCacheDuration =
      ReactiveProperty<Duration>(Duration.zero);

  /// Whether the next playlist entry is prefetched during playback
  /// (`prefetch-playlist`).
  final ReactiveProperty<bool> prefetchPlaylist = ReactiveProperty<bool>(false);

  /// Presentation timestamp of the audio currently being output
  /// (`audio-pts`).
  final ReactiveProperty<Duration> audioPts =
      ReactiveProperty<Duration>(Duration.zero);

  /// Time left until the end of the current file (`time-remaining`).
  final ReactiveProperty<Duration> timeRemaining =
      ReactiveProperty<Duration>(Duration.zero);

  /// Wall-clock time left at the current [rate] (`playtime-remaining`).
  final ReactiveProperty<Duration> playtimeRemaining =
      ReactiveProperty<Duration>(Duration.zero);

  /// Whether the decoder has reached end-of-file (`eof-reached`).
  final ReactiveProperty<bool> eofReached = ReactiveProperty<bool>(false);

  /// Whether the current stream supports seeking (`seekable`).
  final ReactiveProperty<bool> seekable = ReactiveProperty<bool>(false);

  /// Whether the current stream is seekable only within the cached range
  /// (`partially-seekable`).
  final ReactiveProperty<bool> partiallySeekable =
      ReactiveProperty<bool>(false);

  /// Human-readable title of the current media (`media-title`).
  final ReactiveProperty<String> mediaTitle = ReactiveProperty<String>('');

  /// Container format of the current file (`file-format`).
  final ReactiveProperty<String> fileFormat = ReactiveProperty<String>('');

  /// Size of the current file in bytes (`file-size`).
  final ReactiveProperty<int> fileSize = ReactiveProperty<int>(0);

  /// Buffered look-ahead beyond the playhead (`demuxer-cache-duration`).
  final ReactiveProperty<Duration> bufferDuration =
      ReactiveProperty<Duration>(Duration.zero);

  /// Whether the demuxer has stopped reading because its cache is full
  /// (`demuxer-cache-idle`).
  final ReactiveProperty<bool> demuxerIdle = ReactiveProperty<bool>(true);

  /// Index of the active chapter (`chapter`); `null` when none is active.
  final ReactiveProperty<int?> currentChapter = ReactiveProperty<int?>(null);

  /// Chapter list of the current file (`chapter-list`).
  final ReactiveProperty<List<Chapter>> chapters =
      ReactiveProperty<List<Chapter>>(const []);

  /// Resolved path or URI of the current file (`path`).
  final ReactiveProperty<String> path = ReactiveProperty<String>('');

  /// Filename component of the current file (`filename`).
  final ReactiveProperty<String> filename = ReactiveProperty<String>('');

  /// Path of the underlying stream after protocol resolution (`stream-path`).
  final ReactiveProperty<String> streamPath = ReactiveProperty<String>('');

  /// Source playlist of the current entry (`playlist-path`) — the original
  /// `.m3u` / `.pls` path the entry was expanded from. Empty when the current
  /// file was not loaded via a playlist.
  final ReactiveProperty<String> playlistPath = ReactiveProperty<String>('');

  /// Filename mpv opened the stream with (`stream-open-filename`).
  final ReactiveProperty<String> streamOpenFilename =
      ReactiveProperty<String>('');

  /// A-loop point (`ab-loop-a`); `null` when the A-B loop start is unset.
  final ReactiveProperty<Duration?> abLoopA = ReactiveProperty<Duration?>(null);

  /// B-loop point (`ab-loop-b`); `null` when the A-B loop end is unset.
  final ReactiveProperty<Duration?> abLoopB = ReactiveProperty<Duration?>(null);

  /// Number of A-B loop repetitions requested (`ab-loop-count`); `null` is
  /// infinite.
  final ReactiveProperty<int?> abLoopCount = ReactiveProperty<int?>(null);

  /// Repetitions left in the active A-B loop (`remaining-ab-loops`); `null`
  /// is infinite.
  final ReactiveProperty<int?> remainingAbLoops = ReactiveProperty<int?>(null);

  /// Whether a seek is currently in flight (`seeking`).
  final ReactiveProperty<bool> seeking = ReactiveProperty<bool>(false);

  /// Playhead position as a percentage of duration (`percent-pos`).
  final ReactiveProperty<double> percentPos = ReactiveProperty<double>(0.0);

  /// Speed at which the cache is being filled (`cache-speed`), in bytes/s.
  final ReactiveProperty<double> cacheSpeed = ReactiveProperty<double>(0.0);

  /// Cache fill level as a percentage (`cache-buffering-state`).
  final ReactiveProperty<int> cacheBufferingState = ReactiveProperty<int>(0);

  /// Name of the demuxer handling the current file (`current-demuxer`).
  final ReactiveProperty<String> currentDemuxer = ReactiveProperty<String>('');

  /// Name of the active audio output (`current-ao`).
  final ReactiveProperty<String> currentAo = ReactiveProperty<String>('');

  /// Start timestamp of the current stream (`demuxer-start-time`).
  final ReactiveProperty<Duration> demuxerStartTime =
      ReactiveProperty<Duration>(Duration.zero);

  /// Metadata tags attached to the active chapter (`chapter-metadata`).
  final ReactiveProperty<Map<String, String>> chapterMetadata =
      ReactiveProperty<Map<String, String>>(const <String, String>{});

  /// mpv build version string (`mpv-version`).
  final ReactiveProperty<String> mpvVersion = ReactiveProperty<String>('');

  /// Linked ffmpeg version string (`ffmpeg-version`).
  final ReactiveProperty<String> ffmpegVersion = ReactiveProperty<String>('');
}
