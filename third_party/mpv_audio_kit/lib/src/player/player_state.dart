// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'package:mpv_audio_kit/src/generated/audio_effects_settings.dart';
import 'package:mpv_audio_kit/src/internals/unset_sentinel.dart';
import 'package:mpv_audio_kit/src/models/audio_params.dart';
import 'package:mpv_audio_kit/src/models/chapter.dart';
import 'package:mpv_audio_kit/src/models/cover_art.dart';
import 'package:mpv_audio_kit/src/models/demuxer_cache_state.dart';
import 'package:mpv_audio_kit/src/models/device.dart';
import 'package:mpv_audio_kit/src/models/media_session.dart';
import 'package:mpv_audio_kit/src/models/mpv_track.dart';
import 'package:mpv_audio_kit/src/models/playlist.dart';
import 'package:mpv_audio_kit/src/types/enums/cover.dart';
import 'package:mpv_audio_kit/src/types/enums/format.dart';
import 'package:mpv_audio_kit/src/types/enums/gapless.dart';
import 'package:mpv_audio_kit/src/types/enums/hls_bitrate.dart';
import 'package:mpv_audio_kit/src/types/enums/loop.dart';
import 'package:mpv_audio_kit/src/types/enums/spdif.dart';
import 'package:mpv_audio_kit/src/types/sealed/channels.dart';
import 'package:mpv_audio_kit/src/types/settings/cache_settings.dart';
import 'package:mpv_audio_kit/src/types/settings/demuxer_settings.dart';
import 'package:mpv_audio_kit/src/types/settings/replay_gain_settings.dart';
import 'package:mpv_audio_kit/src/types/state/audio_output_state.dart';

const _kEmptyPlaylist = Playlist.empty;
const _kAutoDevice = Device(name: 'auto', description: 'Auto');
const _kDefaultDevices = <Device>[_kAutoDevice];

// Collection equality helpers — kept inline to avoid a transitive
// `package:collection` dependency. PlayerState only carries small
// Set / Map / List<MpvTrack | Chapter | Device | Media> fields, so a
// hand-rolled compare is plenty.
bool _setEq<T>(Set<T> a, Set<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (final e in a) {
    if (!b.contains(e)) return false;
  }
  return true;
}

bool _mapEq<K, V>(Map<K, V> a, Map<K, V> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (final entry in a.entries) {
    if (!b.containsKey(entry.key) || b[entry.key] != entry.value) {
      return false;
    }
  }
  return true;
}

bool _listEq<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// Immutable snapshot of the [Player]'s complete playback state.
///
/// Retrieve the current snapshot synchronously via `player.state`, or subscribe
/// to individual fields via the typed streams in `player.stream`.
final class PlayerState {
  /// The currently loaded playlist and active track index.
  final Playlist playlist;

  /// Whether the player is currently producing output (not paused, not
  /// buffering, not mid-seek). Mirrors mpv's `core-idle` (inverted) —
  /// the *actual-output* axis. It toggles transiently during seeks and
  /// buffering; for a stable play/pause indicator bind to [playWhenReady]
  /// instead.
  final bool playing;

  /// User intent to play — the play/pause axis, set by [Player.play] /
  /// [Player.pause] / [Player.open] / [Player.stop] (and released at the
  /// natural end of content). Unlike [playing], it does NOT flip during a
  /// seek or while buffering, so it is the correct signal to drive a
  /// play/pause button (including the OS media-session control). "Actually
  /// emitting audio" is `playWhenReady && playing`.
  final bool playWhenReady;

  /// Whether the current track has played to its end.
  ///
  /// Becomes `true` at the natural end of a track: at the end of every
  /// finished entry during a playlist, and — crucially under the shipped
  /// `keep-open` policy, where mpv parks paused on the last frame instead
  /// of emitting an end-of-file event — at the end of a single track or the
  /// last playlist entry. Resets to `false` when a new track starts (a fresh
  /// [Player.open] / [Player.openAll] or a playlist advance) or when you
  /// seek back into the track. Pairs with [eofReached] (the raw mpv signal);
  /// drives [MpvPlaybackState.completed].
  final bool completed;

  /// Current playback position.
  final Duration position;

  /// Total duration of the current track. Zero when unknown (e.g. live streams).
  final Duration duration;

  /// Current volume level, 0–100. Values above 100 amplify the signal.
  final double volume;

  /// Playback speed multiplier. 1.0 = normal speed.
  final double rate;

  /// Pitch multiplier. 1.0 = original pitch.
  final double pitch;

  /// Whether the player is currently buffering.
  final bool buffering;

  /// Absolute position up to which the demuxer has buffered content.
  ///
  /// This is an absolute timestamp from the start of the track (equivalent
  /// to `demuxer-cache-time` in mpv), not a relative duration. For example,
  /// if the current position is 1:00 and 30 s are cached ahead, [buffer] is
  /// 1:30. Use this value directly as the buffered position in audio_service
  /// or any progress-bar UI without adding [position].
  final Duration buffer;

  /// Buffer fill percentage (0.0–100.0).
  final double bufferingPercentage;

  /// Rich demuxer cache snapshot — buffered time ranges + network-cache flags
  /// (mpv's `demuxer-cache-state`). Empty for directly-seekable local files;
  /// populated when streaming. Render `seekableRanges` as the downloaded
  /// regions of a network seek bar. Read live via
  /// [PlayerStream.demuxerCacheState].
  final DemuxerCacheState demuxerCacheState;

  /// Current loop / repeat mode.
  final Loop loop;

  /// Whether the playlist is in shuffle mode.
  final bool shuffle;

  /// Audio format parameters from the decoder (track source).
  final AudioParams audioParams;

  /// Audio format parameters as sent to the hardware (post-processing).
  final AudioParams audioOutParams;

  /// Current audio bitrate in bps. `null` if unavailable.
  final double? audioBitrate;

  /// The currently selected audio output device.
  final Device audioDevice;

  /// All audio output devices detected by mpv.
  final List<Device> audioDevices;

  /// Whether the player is muted.
  final bool mute;

  /// Audio delay applied to the output stream. Positive values delay
  /// audio relative to video; negative values advance it.
  final Duration audioDelay;

  /// Whether pitch correction is enabled when changing playback speed.
  final bool pitchCorrection;

  /// Dictionary of tags/metadata for the current track (e.g. Title, Artist).
  final Map<String, String> metadata;

  /// Gapless playback mode.
  final Gapless gapless;

  /// ReplayGain configuration. Set via [Player.setReplayGain].
  final ReplayGainSettings replayGain;

  /// Software volume gain in dB.
  final double volumeGain;

  /// Lower clamp mpv applies to [volumeGain], in dB (`volume-gain-min`,
  /// default -96). Set via [Player.setVolumeGainMin].
  final double volumeGainMin;

  /// Upper clamp mpv applies to [volumeGain], in dB (`volume-gain-max`,
  /// default +12). Set via [Player.setVolumeGainMax].
  final double volumeGainMax;

  /// OS per-app mixer volume in percent (`ao-volume`), distinct from soft
  /// [volume]. `null` when the active audio output doesn't expose it. Set via
  /// [Player.setSystemVolume] (best-effort).
  final double? systemVolume;

  /// OS per-app mute (`ao-mute`), distinct from soft [mute]. `null` when the
  /// active audio output doesn't expose it. Set via [Player.setSystemMute].
  final bool? systemMute;

  /// Cache configuration. Set via [Player.setCache].
  final CacheSettings cache;

  /// Demuxer buffering configuration (forward cache cap, seekback cap,
  /// readahead). Set via [Player.setDemuxer]. Distinct from
  /// [demuxerCacheState], which is the live read-only cache snapshot.
  final DemuxerSettings demuxer;

  /// Network connection timeout. Default 60s mirrors mpv's
  /// `--network-timeout=60`.
  final Duration networkTimeout;

  /// Whether playback is paused because the network cache ran empty.
  ///
  /// This is mpv's `paused-for-cache` property — the authoritative signal
  /// for network buffering stalls. When `true`, mpv is waiting for data
  /// and will auto-resume once [CacheSettings.pauseWait] seconds are buffered.
  final bool pausedForCache;

  /// Whether the current stream is being read via a network protocol.
  ///
  /// Mirrors mpv's `demuxer-via-network` property. Useful for deciding
  /// whether an error is likely network-related.
  final bool demuxerViaNetwork;

  /// Whether to verify TLS/SSL certificates on `https://` streams.
  /// Mirrors mpv's `--tls-verify` default of `false`. Enable via
  /// [Player.setTlsVerify] when a bundled CA is in use.
  final bool tlsVerify;

  /// Absolute filesystem path to a custom PEM bundle of trusted CA
  /// certificates, or empty string when the built-in roots are used.
  ///
  /// Empty by default: the bundled libmpv has the Mozilla CA roots compiled
  /// in, so [tlsVerify] works on every platform out of the box. Set
  /// [Player.setTlsCaFile] to override those roots with a custom bundle
  /// (e.g. a corporate trust root).
  final String tlsCaFile;

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

  /// Whether audio exclusive mode is enabled.
  final bool audioExclusive;

  /// Whether mpv tags the stream's media role as "music" on the OS audio
  /// server (`audio-set-media-role`; PulseAudio / PipeWire). Set via
  /// [Player.setAudioMediaRole].
  final bool audioMediaRole;

  /// Audio buffer size.
  final Duration audioBuffer;

  /// Whether to stream silence when nothing is playing.
  final bool audioStreamSilence;

  /// Whether to fallback to untimed null output.
  final bool audioNullUntimed;

  /// All tracks reported by mpv for the current file (audio, video,
  /// embedded picture, …). Filter by [MpvTrack.type] for a typed
  /// "audio tracks only" view; switch via [Player.setAudioTrack].
  final List<MpvTrack> tracks;

  /// The single audio track currently selected for output, or `null`
  /// when audio is muted at the track level. Distinct from [tracks],
  /// which lists every track the demuxer surfaced. Mirrors mpv's
  /// `current-tracks/audio`.
  final MpvTrack? currentAudioTrack;

  /// S/PDIF passthrough codecs. Empty set = passthrough disabled.
  /// Apply via [Player.setAudioSpdif].
  final Set<Spdif> audioSpdif;

  /// Max volume limit (up to 1000).
  final double volumeMax;

  /// Target sample rate (0 for auto).
  final int audioSampleRate;

  /// Sample format requested from mpv. `Format.auto` defers to
  /// mpv's pick; the other variants force a specific bit depth /
  /// signedness / planarity. Setter: [Player.setAudioFormat].
  final Format audioFormat;

  /// Channel-layout request. Use the named static fields for the common
  /// presets (mono, stereo, 5.1, 7.1, …) or
  /// `Channels.custom('…')` for any layout string mpv
  /// recognises. Setter: [Player.setAudioChannels].
  final Channels audioChannels;

  /// Audio client name (used by backend drivers like PulseAudio).
  final String audioClientName;

  /// Audio output driver ('auto', 'coreaudio', 'pulse', 'alsa', 'wasapi', etc.).
  final String audioDriver;

  /// Audio output lifecycle (`closed` / `initializing` / `active` /
  /// `failed`). See [AudioOutputState].
  final AudioOutputState audioOutputState;

  /// All DSP effects in mpv's `--af` pipeline, bundled into a single
  /// atomic configuration object. Set via [Player.setAudioEffects]
  /// (replace) or [Player.updateAudioEffects] (mutate one or more
  /// fields). Read live via [PlayerStream.audioEffects].
  final AudioEffects audioEffects;

  /// Embedded cover art of the currently loaded track, or `null`
  /// when the file has no embedded picture. Refreshes on every
  /// `Player.open()` / playlist transition. Read live via
  /// [PlayerStream.coverArt].
  final CoverArt? coverArt;

  /// Controls whether mpv automatically loads external cover art files.
  /// See [Cover] for the available variants.
  final Cover coverArtAuto;

  /// Whether mpv prefetches the next playlist item in the background.
  ///
  /// When `true`, the demuxer for the next track opens before the current
  /// one finishes, eliminating the file-boundary stall. Observe progress
  /// via [PlayerStream.prefetchState].
  final bool prefetchPlaylist;

  /// Audio frame timestamp at the playhead. Advances per audio frame
  /// (more granular than `position`, which mpv updates on a fixed
  /// schedule) and includes audio driver latency. Useful for
  /// audio-only sync calculations.
  final Duration audioPts;

  /// Time remaining until the file ends, ignoring playback speed.
  final Duration timeRemaining;

  /// Time remaining until the file ends, adjusted for playback speed —
  /// what the listener will actually wait. At 2.0x speed on a 60 s
  /// remaining file this is 30 s.
  final Duration playtimeRemaining;

  /// Whether playback has reached end-of-file. Distinct from
  /// `completed` (lifecycle flag): `eofReached` mirrors mpv's
  /// `eof-reached` and disambiguates a natural EOF from a user pause.
  final bool eofReached;

  /// Whether the current stream supports seeking at all (live streams
  /// often do not).
  final bool seekable;

  /// Whether the stream is partially seekable — only some ranges are
  /// reachable (typical for HLS / DASH when only a sliding window is
  /// available).
  final bool partiallySeekable;

  /// Display name for the current track. Falls back to the file name
  /// when no `title` tag is available. Mirrors mpv's `media-title`.
  final String mediaTitle;

  /// Container format (e.g. `mp4`, `m4a`, `flac`, `mp3`). Comma-separated
  /// list when the demuxer matches multiple formats.
  final String fileFormat;

  /// Total stream size in bytes. Zero when unknown (live streams).
  final int fileSize;

  /// Buffered duration ahead of the playhead — `demuxer-cache-duration`.
  /// Complements [buffer] (which is `demuxer-cache-time`, an absolute
  /// timestamp): [bufferDuration] is the headroom.
  final Duration bufferDuration;

  /// Whether the demuxer thread is idle. `true` while the demuxer has
  /// no data to fetch (cache full or EOF); `false` while pulling.
  /// Combined with `pausedForCache` it disambiguates "starved network"
  /// from "fully cached, sitting idle".
  final bool demuxerIdle;

  /// Index of the active chapter (0-based), or `null` when no chapter
  /// is active or the file has none. Setter: [Player.setChapter].
  final int? currentChapter;

  /// Chapters in the current file (audiobook / podcast markers).
  /// Empty list when the file carries no chapter table.
  final List<Chapter> chapters;

  /// Full path or URI of the current file as canonicalized by mpv after
  /// any redirect. Empty when no file is loaded. Mirrors mpv's `path`.
  final String path;

  /// File name only (no directory) of the current file. Mirrors mpv's
  /// `filename`. Empty when no file is loaded.
  final String filename;

  /// URI of the current file as originally requested, before any
  /// redirect from `on_load` hooks or protocol resolution. Mirrors
  /// mpv's `stream-path`. Empty when no file is loaded.
  final String streamPath;

  /// URI of the current file as actually opened post-redirect.
  /// Identical to [streamPath] when no `on_load` hook rewrote the URL.
  /// Mirrors mpv's `stream-open-filename`.
  final String streamOpenFilename;

  /// Source playlist of the current entry (`playlist-path`) — the original
  /// `.m3u` / `.pls` path it was expanded from. Empty when the current file
  /// was not loaded via a playlist.
  final String playlistPath;

  /// A-B loop start point. `null` when disabled. Setter:
  /// [Player.setAbLoopA]. Mirrors mpv's `ab-loop-a`.
  final Duration? abLoopA;

  /// A-B loop end point. `null` when disabled. Setter:
  /// [Player.setAbLoopB]. Mirrors mpv's `ab-loop-b`.
  final Duration? abLoopB;

  /// Total number of A-B loop repetitions configured. `null` =
  /// infinite loop (mpv's `inf`); positive = explicit count. Setter:
  /// [Player.setAbLoopCount]. Mirrors mpv's `ab-loop-count`.
  final int? abLoopCount;

  /// Remaining number of A-B loop repetitions in the active loop.
  /// `null` when no loop is active or when the count is infinite.
  /// Read-only — mirrors mpv's `remaining-ab-loops`.
  final int? remainingAbLoops;

  /// Whether mpv is currently seeking. Useful as a UI gate to prevent
  /// new seek commands from racing the in-flight one (slider drag
  /// during a long network seek). Mirrors mpv's `seeking`.
  final bool seeking;

  /// Playback position as a percentage of the file duration (0–100).
  /// Convenience for progress bar UIs that want a single normalized
  /// value rather than `position / duration` math. Mirrors mpv's
  /// `percent-pos`.
  final double percentPos;

  /// Current demuxer cache download speed in bytes per second.
  /// `0.0` when no network reads are active. Mirrors mpv's
  /// `cache-speed`.
  final double cacheSpeed;

  /// Cache fill state as a percentage (0–100). Distinct from
  /// [bufferingPercentage] (which is computed against `cache.secs`):
  /// this is mpv's own assessment of how much of the configured cache
  /// is full. Mirrors mpv's `cache-buffering-state`. `0` when no
  /// caching is active.
  final int cacheBufferingState;

  /// Name of the demuxer in use (e.g. `mkv`, `lavf`, `mp3`). Empty
  /// when no file is loaded. Mirrors mpv's `current-demuxer`.
  final String currentDemuxer;

  /// Name of the audio output driver in use (e.g. `coreaudio`,
  /// `pulse`, `wasapi`). Differs from [audioDriver] (which is the
  /// requested driver, possibly `auto`): this is what mpv actually
  /// resolved at runtime. Mirrors mpv's `current-ao`.
  final String currentAo;

  /// Initial timestamp offset of the current file, as reported by the
  /// demuxer. Useful when the container's first frame isn't at zero
  /// (chapter-skipped files, edited cuts). Mirrors mpv's
  /// `demuxer-start-time`.
  final Duration demuxerStartTime;

  /// Tag dictionary for the active chapter (per-chapter metadata).
  /// Empty when no chapter is active or the file has no chapter tags.
  /// Mirrors mpv's `chapter-metadata`. Distinct from [metadata] (file
  /// level) and from [Chapter.title] (chapter list, just the title).
  final Map<String, String> chapterMetadata;

  /// Version of mpv linked into the current build (e.g. `0.41.0`).
  /// Read once at first observe and stable for the lifetime of the
  /// [Player]. Mirrors mpv's `mpv-version`.
  final String mpvVersion;

  /// Version of FFmpeg linked into the current mpv build.
  /// Read once at first observe. Mirrors mpv's `ffmpeg-version`.
  final String ffmpegVersion;

  /// Active OS media-session config + metadata override, or `null`
  /// when no media session is currently published to the lockscreen /
  /// SMTC / MPRIS. Set via [Player.setMediaSession]; pass `null` to
  /// disable. See [MediaSession] for the full field semantics.
  final MediaSession? mediaSession;

  /// Creates a state snapshot; every field defaults to the player's
  /// at-rest value before any property has been observed.
  const PlayerState({
    this.playlist = _kEmptyPlaylist,
    this.playing = false,
    this.playWhenReady = false,
    this.completed = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.volume = 100.0,
    this.rate = 1.0,
    this.pitch = 1.0,
    this.buffering = false,
    this.buffer = Duration.zero,
    this.bufferingPercentage = 0.0,
    this.demuxerCacheState = DemuxerCacheState.empty,
    this.loop = Loop.off,
    this.shuffle = false,
    this.audioParams = const AudioParams(),
    this.audioOutParams = const AudioParams(),
    this.audioBitrate,
    this.audioDevice = _kAutoDevice,
    this.audioDevices = _kDefaultDevices,
    this.mute = false,
    this.audioDelay = Duration.zero,
    this.pitchCorrection = true,
    this.metadata = const <String, String>{},
    this.gapless = Gapless.weak,
    this.replayGain = const ReplayGainSettings(),
    this.volumeGain = 0.0,
    this.volumeGainMin = -96.0,
    this.volumeGainMax = 12.0,
    this.systemVolume,
    this.systemMute,
    this.cache = const CacheSettings(),
    this.demuxer = const DemuxerSettings(),
    this.networkTimeout = const Duration(seconds: 60),
    this.pausedForCache = false,
    this.demuxerViaNetwork = false,
    this.tlsVerify = false,
    this.tlsCaFile = '',
    this.hlsBitrate = HlsBitrate.max,
    this.cookies = false,
    this.httpProxy = '',
    this.audioExclusive = false,
    this.audioMediaRole = false,
    this.audioBuffer = const Duration(milliseconds: 200),
    this.audioStreamSilence = false,
    this.audioNullUntimed = false,
    this.tracks = const <MpvTrack>[],
    this.currentAudioTrack,
    this.audioSpdif = const <Spdif>{},
    this.volumeMax = 130.0,
    this.audioSampleRate = 0,
    this.audioFormat = Format.auto,
    this.audioChannels = Channels.auto,
    this.audioClientName = 'mpv_audio_kit',
    this.audioDriver = 'auto',
    this.audioOutputState = AudioOutputState.closed,
    this.audioEffects = const AudioEffects(),
    this.coverArt,
    this.coverArtAuto = Cover.no,
    this.prefetchPlaylist = false,
    this.audioPts = Duration.zero,
    this.timeRemaining = Duration.zero,
    this.playtimeRemaining = Duration.zero,
    this.eofReached = false,
    this.seekable = false,
    this.partiallySeekable = false,
    this.mediaTitle = '',
    this.fileFormat = '',
    this.fileSize = 0,
    this.bufferDuration = Duration.zero,
    this.demuxerIdle = true,
    this.currentChapter,
    this.chapters = const <Chapter>[],
    this.path = '',
    this.filename = '',
    this.streamPath = '',
    this.streamOpenFilename = '',
    this.playlistPath = '',
    this.abLoopA,
    this.abLoopB,
    this.abLoopCount,
    this.remainingAbLoops,
    this.seeking = false,
    this.percentPos = 0.0,
    this.cacheSpeed = 0.0,
    this.cacheBufferingState = 0,
    this.currentDemuxer = '',
    this.currentAo = '',
    this.demuxerStartTime = Duration.zero,
    this.chapterMetadata = const <String, String>{},
    this.mpvVersion = '',
    this.ffmpegVersion = '',
    this.mediaSession,
  });

  /// Returns a copy of this state with the given fields replaced; omitted
  /// fields keep their current value.
  PlayerState copyWith({
    Playlist? playlist,
    bool? playing,
    bool? playWhenReady,
    bool? completed,
    Duration? position,
    Duration? duration,
    double? volume,
    double? rate,
    double? pitch,
    bool? buffering,
    Duration? buffer,
    double? bufferingPercentage,
    DemuxerCacheState? demuxerCacheState,
    Loop? loop,
    bool? shuffle,
    AudioParams? audioParams,
    AudioParams? audioOutParams,
    Object? audioBitrate = unset,
    Device? audioDevice,
    List<Device>? audioDevices,
    bool? mute,
    Duration? audioDelay,
    bool? pitchCorrection,
    Map<String, String>? metadata,
    Gapless? gapless,
    ReplayGainSettings? replayGain,
    double? volumeGain,
    double? volumeGainMin,
    double? volumeGainMax,
    Object? systemVolume = unset,
    Object? systemMute = unset,
    CacheSettings? cache,
    DemuxerSettings? demuxer,
    Duration? networkTimeout,
    bool? pausedForCache,
    bool? demuxerViaNetwork,
    bool? tlsVerify,
    String? tlsCaFile,
    HlsBitrate? hlsBitrate,
    bool? cookies,
    String? httpProxy,
    bool? audioExclusive,
    bool? audioMediaRole,
    Duration? audioBuffer,
    bool? audioStreamSilence,
    bool? audioNullUntimed,
    List<MpvTrack>? tracks,
    Object? currentAudioTrack = unset,
    Set<Spdif>? audioSpdif,
    double? volumeMax,
    int? audioSampleRate,
    Format? audioFormat,
    Channels? audioChannels,
    String? audioClientName,
    String? audioDriver,
    AudioOutputState? audioOutputState,
    AudioEffects? audioEffects,
    Object? coverArt = unset,
    Cover? coverArtAuto,
    bool? prefetchPlaylist,
    Duration? audioPts,
    Duration? timeRemaining,
    Duration? playtimeRemaining,
    bool? eofReached,
    bool? seekable,
    bool? partiallySeekable,
    String? mediaTitle,
    String? fileFormat,
    int? fileSize,
    Duration? bufferDuration,
    bool? demuxerIdle,
    Object? currentChapter = unset,
    List<Chapter>? chapters,
    String? path,
    String? filename,
    String? streamPath,
    String? streamOpenFilename,
    String? playlistPath,
    Object? abLoopA = unset,
    Object? abLoopB = unset,
    Object? abLoopCount = unset,
    Object? remainingAbLoops = unset,
    bool? seeking,
    double? percentPos,
    double? cacheSpeed,
    int? cacheBufferingState,
    String? currentDemuxer,
    String? currentAo,
    Duration? demuxerStartTime,
    Map<String, String>? chapterMetadata,
    String? mpvVersion,
    String? ffmpegVersion,
    Object? mediaSession = unset,
  }) =>
      PlayerState(
        playlist: playlist ?? this.playlist,
        playing: playing ?? this.playing,
        playWhenReady: playWhenReady ?? this.playWhenReady,
        completed: completed ?? this.completed,
        position: position ?? this.position,
        duration: duration ?? this.duration,
        volume: volume ?? this.volume,
        rate: rate ?? this.rate,
        pitch: pitch ?? this.pitch,
        buffering: buffering ?? this.buffering,
        buffer: buffer ?? this.buffer,
        bufferingPercentage: bufferingPercentage ?? this.bufferingPercentage,
        demuxerCacheState: demuxerCacheState ?? this.demuxerCacheState,
        loop: loop ?? this.loop,
        shuffle: shuffle ?? this.shuffle,
        audioParams: audioParams ?? this.audioParams,
        audioOutParams: audioOutParams ?? this.audioOutParams,
        audioBitrate: identical(audioBitrate, unset)
            ? this.audioBitrate
            : audioBitrate as double?,
        audioDevice: audioDevice ?? this.audioDevice,
        audioDevices: audioDevices ?? this.audioDevices,
        mute: mute ?? this.mute,
        audioDelay: audioDelay ?? this.audioDelay,
        pitchCorrection: pitchCorrection ?? this.pitchCorrection,
        metadata: metadata ?? this.metadata,
        gapless: gapless ?? this.gapless,
        replayGain: replayGain ?? this.replayGain,
        volumeGain: volumeGain ?? this.volumeGain,
        volumeGainMin: volumeGainMin ?? this.volumeGainMin,
        volumeGainMax: volumeGainMax ?? this.volumeGainMax,
        systemVolume: identical(systemVolume, unset)
            ? this.systemVolume
            : systemVolume as double?,
        systemMute:
            identical(systemMute, unset) ? this.systemMute : systemMute as bool?,
        cache: cache ?? this.cache,
        demuxer: demuxer ?? this.demuxer,
        networkTimeout: networkTimeout ?? this.networkTimeout,
        pausedForCache: pausedForCache ?? this.pausedForCache,
        demuxerViaNetwork: demuxerViaNetwork ?? this.demuxerViaNetwork,
        tlsVerify: tlsVerify ?? this.tlsVerify,
        tlsCaFile: tlsCaFile ?? this.tlsCaFile,
        hlsBitrate: hlsBitrate ?? this.hlsBitrate,
        cookies: cookies ?? this.cookies,
        httpProxy: httpProxy ?? this.httpProxy,
        audioExclusive: audioExclusive ?? this.audioExclusive,
        audioMediaRole: audioMediaRole ?? this.audioMediaRole,
        audioBuffer: audioBuffer ?? this.audioBuffer,
        audioStreamSilence: audioStreamSilence ?? this.audioStreamSilence,
        audioNullUntimed: audioNullUntimed ?? this.audioNullUntimed,
        tracks: tracks ?? this.tracks,
        currentAudioTrack: identical(currentAudioTrack, unset)
            ? this.currentAudioTrack
            : currentAudioTrack as MpvTrack?,
        audioSpdif: audioSpdif ?? this.audioSpdif,
        volumeMax: volumeMax ?? this.volumeMax,
        audioSampleRate: audioSampleRate ?? this.audioSampleRate,
        audioFormat: audioFormat ?? this.audioFormat,
        audioChannels: audioChannels ?? this.audioChannels,
        audioClientName: audioClientName ?? this.audioClientName,
        audioDriver: audioDriver ?? this.audioDriver,
        audioOutputState: audioOutputState ?? this.audioOutputState,
        audioEffects: audioEffects ?? this.audioEffects,
        coverArt:
            identical(coverArt, unset) ? this.coverArt : coverArt as CoverArt?,
        coverArtAuto: coverArtAuto ?? this.coverArtAuto,
        prefetchPlaylist: prefetchPlaylist ?? this.prefetchPlaylist,
        audioPts: audioPts ?? this.audioPts,
        timeRemaining: timeRemaining ?? this.timeRemaining,
        playtimeRemaining: playtimeRemaining ?? this.playtimeRemaining,
        eofReached: eofReached ?? this.eofReached,
        seekable: seekable ?? this.seekable,
        partiallySeekable: partiallySeekable ?? this.partiallySeekable,
        mediaTitle: mediaTitle ?? this.mediaTitle,
        fileFormat: fileFormat ?? this.fileFormat,
        fileSize: fileSize ?? this.fileSize,
        bufferDuration: bufferDuration ?? this.bufferDuration,
        demuxerIdle: demuxerIdle ?? this.demuxerIdle,
        currentChapter: identical(currentChapter, unset)
            ? this.currentChapter
            : currentChapter as int?,
        chapters: chapters ?? this.chapters,
        path: path ?? this.path,
        filename: filename ?? this.filename,
        streamPath: streamPath ?? this.streamPath,
        streamOpenFilename: streamOpenFilename ?? this.streamOpenFilename,
        playlistPath: playlistPath ?? this.playlistPath,
        abLoopA:
            identical(abLoopA, unset) ? this.abLoopA : abLoopA as Duration?,
        abLoopB:
            identical(abLoopB, unset) ? this.abLoopB : abLoopB as Duration?,
        abLoopCount: identical(abLoopCount, unset)
            ? this.abLoopCount
            : abLoopCount as int?,
        remainingAbLoops: identical(remainingAbLoops, unset)
            ? this.remainingAbLoops
            : remainingAbLoops as int?,
        seeking: seeking ?? this.seeking,
        percentPos: percentPos ?? this.percentPos,
        cacheSpeed: cacheSpeed ?? this.cacheSpeed,
        cacheBufferingState: cacheBufferingState ?? this.cacheBufferingState,
        currentDemuxer: currentDemuxer ?? this.currentDemuxer,
        currentAo: currentAo ?? this.currentAo,
        demuxerStartTime: demuxerStartTime ?? this.demuxerStartTime,
        chapterMetadata: chapterMetadata ?? this.chapterMetadata,
        mpvVersion: mpvVersion ?? this.mpvVersion,
        ffmpegVersion: ffmpegVersion ?? this.ffmpegVersion,
        mediaSession: identical(mediaSession, unset)
            ? this.mediaSession
            : mediaSession as MediaSession?,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlayerState &&
          other.playlist == playlist &&
          other.playing == playing &&
          other.playWhenReady == playWhenReady &&
          other.completed == completed &&
          other.position == position &&
          other.duration == duration &&
          other.volume == volume &&
          other.rate == rate &&
          other.pitch == pitch &&
          other.buffering == buffering &&
          other.buffer == buffer &&
          other.bufferingPercentage == bufferingPercentage &&
          other.demuxerCacheState == demuxerCacheState &&
          other.loop == loop &&
          other.shuffle == shuffle &&
          other.audioParams == audioParams &&
          other.audioOutParams == audioOutParams &&
          other.audioBitrate == audioBitrate &&
          other.audioDevice == audioDevice &&
          _listEq(audioDevices, other.audioDevices) &&
          other.mute == mute &&
          other.audioDelay == audioDelay &&
          other.pitchCorrection == pitchCorrection &&
          _mapEq(metadata, other.metadata) &&
          other.gapless == gapless &&
          other.replayGain == replayGain &&
          other.volumeGain == volumeGain &&
          other.volumeGainMin == volumeGainMin &&
          other.volumeGainMax == volumeGainMax &&
          other.systemVolume == systemVolume &&
          other.systemMute == systemMute &&
          other.cache == cache &&
          other.demuxer == demuxer &&
          other.networkTimeout == networkTimeout &&
          other.pausedForCache == pausedForCache &&
          other.demuxerViaNetwork == demuxerViaNetwork &&
          other.tlsVerify == tlsVerify &&
          other.tlsCaFile == tlsCaFile &&
          other.hlsBitrate == hlsBitrate &&
          other.cookies == cookies &&
          other.httpProxy == httpProxy &&
          other.audioExclusive == audioExclusive &&
          other.audioMediaRole == audioMediaRole &&
          other.audioBuffer == audioBuffer &&
          other.audioStreamSilence == audioStreamSilence &&
          other.audioNullUntimed == audioNullUntimed &&
          _listEq(tracks, other.tracks) &&
          other.currentAudioTrack == currentAudioTrack &&
          _setEq(audioSpdif, other.audioSpdif) &&
          other.volumeMax == volumeMax &&
          other.audioSampleRate == audioSampleRate &&
          other.audioFormat == audioFormat &&
          other.audioChannels == audioChannels &&
          other.audioClientName == audioClientName &&
          other.audioDriver == audioDriver &&
          other.audioOutputState == audioOutputState &&
          other.audioEffects == audioEffects &&
          other.coverArt == coverArt &&
          other.coverArtAuto == coverArtAuto &&
          other.prefetchPlaylist == prefetchPlaylist &&
          other.audioPts == audioPts &&
          other.timeRemaining == timeRemaining &&
          other.playtimeRemaining == playtimeRemaining &&
          other.eofReached == eofReached &&
          other.seekable == seekable &&
          other.partiallySeekable == partiallySeekable &&
          other.mediaTitle == mediaTitle &&
          other.fileFormat == fileFormat &&
          other.fileSize == fileSize &&
          other.bufferDuration == bufferDuration &&
          other.demuxerIdle == demuxerIdle &&
          other.currentChapter == currentChapter &&
          _listEq(chapters, other.chapters) &&
          other.path == path &&
          other.filename == filename &&
          other.streamPath == streamPath &&
          other.streamOpenFilename == streamOpenFilename &&
          other.playlistPath == playlistPath &&
          other.abLoopA == abLoopA &&
          other.abLoopB == abLoopB &&
          other.abLoopCount == abLoopCount &&
          other.remainingAbLoops == remainingAbLoops &&
          other.seeking == seeking &&
          other.percentPos == percentPos &&
          other.cacheSpeed == cacheSpeed &&
          other.cacheBufferingState == cacheBufferingState &&
          other.currentDemuxer == currentDemuxer &&
          other.currentAo == currentAo &&
          other.demuxerStartTime == demuxerStartTime &&
          _mapEq(chapterMetadata, other.chapterMetadata) &&
          other.mpvVersion == mpvVersion &&
          other.ffmpegVersion == ffmpegVersion &&
          other.mediaSession == mediaSession);

  @override
  int get hashCode => Object.hashAll([
        playlist,
        playing,
        playWhenReady,
        completed,
        position,
        duration,
        volume,
        rate,
        pitch,
        buffering,
        buffer,
        bufferingPercentage,
        demuxerCacheState,
        loop,
        shuffle,
        audioParams,
        audioOutParams,
        audioBitrate,
        audioDevice,
        Object.hashAll(audioDevices),
        mute,
        audioDelay,
        pitchCorrection,
        Object.hashAllUnordered(
            metadata.entries.map((e) => Object.hash(e.key, e.value)),),
        gapless,
        replayGain,
        volumeGain,
        volumeGainMin,
        volumeGainMax,
        systemVolume,
        systemMute,
        cache,
        demuxer,
        networkTimeout,
        pausedForCache,
        demuxerViaNetwork,
        tlsVerify,
        tlsCaFile,
        hlsBitrate,
        cookies,
        httpProxy,
        audioExclusive,
        audioMediaRole,
        audioBuffer,
        audioStreamSilence,
        audioNullUntimed,
        Object.hashAll(tracks),
        currentAudioTrack,
        Object.hashAllUnordered(audioSpdif),
        volumeMax,
        audioSampleRate,
        audioFormat,
        audioChannels,
        audioClientName,
        audioDriver,
        audioOutputState,
        audioEffects,
        coverArt,
        coverArtAuto,
        prefetchPlaylist,
        audioPts,
        timeRemaining,
        playtimeRemaining,
        eofReached,
        seekable,
        partiallySeekable,
        mediaTitle,
        fileFormat,
        fileSize,
        bufferDuration,
        demuxerIdle,
        currentChapter,
        Object.hashAll(chapters),
        path,
        filename,
        streamPath,
        streamOpenFilename,
        playlistPath,
        abLoopA,
        abLoopB,
        abLoopCount,
        remainingAbLoops,
        seeking,
        percentPos,
        cacheSpeed,
        cacheBufferingState,
        currentDemuxer,
        currentAo,
        demuxerStartTime,
        Object.hashAllUnordered(
            chapterMetadata.entries.map((e) => Object.hash(e.key, e.value)),),
        mpvVersion,
        ffmpegVersion,
        mediaSession,
      ]);

  @override
  String toString() =>
      'PlayerState(playing: $playing, playWhenReady: $playWhenReady, position: $position, duration: $duration, volume: $volume, mediaTitle: $mediaTitle)';
}
