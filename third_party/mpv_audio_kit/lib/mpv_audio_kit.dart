// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

/// mpv_audio_kit — Flutter audio player powered by libmpv.
///
/// Supports macOS, Windows, Linux, iOS, and Android.
///
/// ## Quick start
/// ```dart
/// import 'package:mpv_audio_kit/mpv_audio_kit.dart';
///
/// final player = Player();
///
/// player.stream.position.listen((pos) => print(pos));
/// player.stream.playing.listen((p)   => print('playing: $p'));
///
/// await player.open(Media('https://example.com/audio.mp3'));
/// await player.play();
///
/// // ...
/// await player.dispose();
/// ```
library;

export 'src/dsp/band_processor.dart' show BandProcessor;
export 'src/events/mpv_exception.dart' show MpvException;
export 'src/events/mpv_hook_event.dart' show MpvHookEvent;
export 'src/events/mpv_log_entry.dart' show MpvLogEntry;
export 'src/events/mpv_player_error.dart'
    show
        MpvPlayerError,
        MpvEndFileError,
        MpvEndFileErrorX,
        MpvLogError,
        MpvEndFileReason,
        MpvFileEndedEvent,
        MpvFileEndedEventX;
export 'src/generated/audio_effects.dart';
export 'src/generated/audio_effects_extensions.dart';
export 'src/generated/audio_effects_settings.dart';
export 'src/internals/library_loader.dart' show MpvAudioKit;
export 'src/models/audio_params.dart' show AudioParams;
export 'src/models/chapter.dart' show Chapter;
export 'src/models/cover_art.dart' show CoverArt;
export 'src/models/demuxer_cache_state.dart' show DemuxerCacheState, CacheRange;
export 'src/models/device.dart' show Device;
export 'src/models/fft_frame.dart' show FftFrame;
export 'src/models/loudness.dart' show Loudness;
export 'src/models/loudness_scan.dart' show LoudnessScan;
export 'src/models/media.dart' show Media;
export 'src/models/media_session.dart' show MediaSession;
export 'src/models/mpv_track.dart' show MpvTrack;
export 'src/models/pcm_frame.dart' show PcmFrame;
export 'src/models/playlist.dart' show Playlist;
export 'src/models/source_resolve_request.dart'
    show SourceResolveRequest, SourceResolver;
export 'src/models/waveform_data.dart' show WaveformData;
export 'src/mpv_bindings.dart' show MpvLibraryException, MpvError;
export 'src/player/player.dart' show Player;
export 'src/player/player_api.dart' show PlayerApi;
export 'src/player/player_configuration.dart' show PlayerConfiguration;
export 'src/player/player_state.dart' show PlayerState;
export 'src/player/player_stream.dart' show PlayerStream;
export 'src/types/enums/cache.dart' show Cache;
export 'src/types/enums/cover.dart' show Cover;
export 'src/types/enums/format.dart' show Format;
export 'src/types/enums/gapless.dart' show Gapless;
export 'src/types/enums/hls_bitrate.dart' show HlsBitrate;
export 'src/types/enums/hook.dart' show Hook;
export 'src/types/enums/interruption_policy.dart' show InterruptionPolicy;
export 'src/types/enums/log_level.dart' show LogLevel;
export 'src/types/enums/loop.dart' show Loop;
export 'src/types/enums/media_action.dart' show MediaAction;
export 'src/types/enums/replay_gain.dart' show ReplayGain;
export 'src/types/enums/spdif.dart' show Spdif;
export 'src/types/enums/tap_side.dart' show TapSide;
export 'src/types/enums/window_function.dart' show WindowFunction;
export 'src/types/sealed/channels.dart' show Channels;
export 'src/types/sealed/media_session_artwork.dart' show MediaSessionArtwork;
export 'src/types/sealed/media_session_command.dart'
    show
        MediaSessionCommand,
        MediaSessionCommandPlay,
        MediaSessionCommandPause,
        MediaSessionCommandPlayPause,
        MediaSessionCommandStop,
        MediaSessionCommandNext,
        MediaSessionCommandPrevious,
        MediaSessionCommandLike,
        MediaSessionCommandSeekTo,
        MediaSessionCommandSeekBy,
        MediaSessionCommandSetRepeatMode,
        MediaSessionCommandSetShuffle,
        MediaSessionCommandSetPlaybackRate;
export 'src/types/sealed/track.dart' show Track;
export 'src/types/settings/cache_settings.dart' show CacheSettings;
export 'src/types/settings/demuxer_settings.dart' show DemuxerSettings;
export 'src/types/settings/replay_gain_settings.dart' show ReplayGainSettings;
export 'src/types/settings/spectrum_settings.dart' show SpectrumSettings;
export 'src/types/state/audio_output_state.dart' show AudioOutputState;
export 'src/types/state/loudness_scan_state.dart' show LoudnessScanState;
export 'src/types/state/mpv_playback_state.dart' show MpvPlaybackState;
export 'src/types/state/mpv_prefetch_state.dart' show MpvPrefetchState;
