// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb, listEquals;
import 'package:flutter/services.dart' show RootIsolateToken;
import 'package:meta/meta.dart';

import '../backend/backend.dart';
import '../dsp/filter_tap_pipeline.dart';
import '../dsp/loudness_meter_pipeline.dart';
import '../dsp/loudness_scan_pipeline.dart';
import '../dsp/spectrum_pipeline.dart';
import '../dsp/waveform_pipeline.dart';
import '../events/mpv_hook_event.dart';
import '../events/mpv_log_entry.dart';
import '../events/player_error.dart';
import '../events/player_exception.dart';
import '../generated/audio_effects_settings.dart';
import '../internals/audio_effects_validation.dart';
import '../internals/core_calls.dart';
import '../internals/core_events.dart';
import '../internals/debug_log.dart';
import '../internals/duration_seconds.dart';
import '../internals/entry_table.dart';
import '../internals/hook_table.dart';
import '../internals/mpv_audio_kit.dart';
import '../internals/mpv_float.dart';
import '../internals/owned_source.dart';
import '../internals/transport_machine.dart';
import '../internals/uri_resolver.dart';
import '../media_session/media_session_controller.dart';
import '../media_session/media_session_inputs.dart';
import '../models/chapter.dart';
import '../models/cover_art.dart';
import '../models/demuxer_cache_state.dart';
import '../models/device.dart';
import '../models/fft_frame.dart';
import '../models/loudness.dart';
import '../models/loudness_scan.dart';
import '../models/media.dart';
import '../models/media_session.dart';
import '../models/pcm_frame.dart';
import '../models/playlist.dart';
import '../models/source_resolve_request.dart';
import '../models/waveform_data.dart';
import '../mpv_constants.dart' hide MpvEndFileReason;
import '../pcm/pcm_format.dart';
import '../pcm/pcm_source.dart';
import '../reactive/default_reactives.dart';
import '../reactive/default_specs.dart';
import '../reactive/duration_hint.dart';
import '../reactive/node_parsers.dart';
import '../reactive/property_registry.dart';
import '../reactive/reactive_property.dart';
import '../types/enums/cover.dart';
import '../types/enums/format.dart';
import '../types/enums/gapless.dart';
import '../types/enums/hls_bitrate.dart';
import '../types/enums/hook.dart';
import '../types/enums/log_level.dart';
import '../types/enums/loop.dart';
import '../types/enums/spdif.dart';
import '../types/enums/tap_side.dart';
import '../types/sealed/channels.dart';
import '../types/sealed/media_session_command.dart';
import '../types/sealed/track.dart';
import '../types/settings/cache_settings.dart';
import '../types/settings/demuxer_settings.dart';
import '../types/settings/replay_gain_settings.dart';
import '../types/settings/spectrum_settings.dart';
import '../types/state/audio_output_state.dart';
import 'audio_output_error.dart';
import 'lifecycle_transitions.dart';
import 'load_options.dart';
import 'media_cache.dart';
import 'player_api.dart';
import 'player_configuration.dart';
import 'player_state.dart';
import 'player_stream.dart';
import 'playlist_nav_gate.dart';
import 'state/player_settings.dart';

part 'effects_chain.part.dart';
part 'lifecycle.part.dart';
part 'mixins/player_audio.part.dart';
part 'mixins/player_dispatch.part.dart';
part 'mixins/player_effects.part.dart';
part 'mixins/player_file_events.part.dart';
part 'mixins/player_hooks.part.dart';
part 'mixins/player_init.part.dart';
part 'mixins/player_loadfile.part.dart';
part 'mixins/player_media_session.part.dart';
part 'mixins/player_navigation.part.dart';
part 'mixins/player_network.part.dart';
part 'mixins/player_open.part.dart';
part 'mixins/player_open_all.part.dart';
part 'mixins/player_output.part.dart';
part 'mixins/player_pcm.part.dart';
part 'mixins/player_pcm_cut.part.dart';
part 'mixins/player_playback.part.dart';
part 'mixins/player_properties.part.dart';
part 'mixins/player_queue.part.dart';
part 'mixins/player_raw.part.dart';
part 'mixins/player_teardown.part.dart';
part 'mixins/player_tracks.part.dart';
part 'player_base.part.dart';
part 'source_resolver_driver.part.dart';
part 'stream_hub.part.dart';
part 'transport.part.dart';

/// An audio player on libmpv: a queue, effects, analysis and the OS media
/// session.
///
/// Implements [PlayerApi] so test code can mock the player without
/// dragging in the FFI handle and event isolate
/// (`class MockPlayer extends Mock implements PlayerApi {}`).
///
/// {@category Playback}
interface class Player extends _PlayerBase
    with
        _PcmCutModule,
        _PropertiesModule,
        _LoadfileModule,
        _RawModule,
        _OpenModule,
        _PcmModule,
        _EffectsModule,
        _FileEventsModule,
        _HooksModule,
        _DispatchModule,
        _PlaybackModule,
        _QueueModule,
        _NavigationModule,
        _AudioModule,
        _TracksModule,
        _OutputModule,
        _NetworkModule,
        _MediaSessionModule,
        _TeardownModule,
        _InitModule
    implements PlayerApi {
  /// Creates a [Player] instance with optional [configuration].
  Player({super.configuration}) {
    _start();
  }

  /// Test-only. The event isolate writes to [wakeupCounterAddress] on
  /// every wakeup: a bogus value corrupts process memory.
  @visibleForTesting
  Player.testInstrumented({
    super.configuration,
    required int super.wakeupCounterAddress,
  }) {
    _start();
  }

  // --- Public Specialized API ---

  /// Opens a [Media] and optionally starts playback immediately.
  ///
  /// `pause` is set as a global property before `loadfile` so the
  /// property observer always fires on the first-load transition
  /// (a per-file option can skip the `PROPERTY_CHANGE` emit).
  /// Rapid back-to-back `open()` calls don't race: each call claims the
  /// load epoch synchronously and aborts at its next await once a later
  /// content-replacing call (open, openAll, openPlaylistFile, stop,
  /// clearPlaylist) has claimed a newer one, so the call that is LAST
  /// in program order wins, regardless of per-URI resolve latency.
  @override
  Future<void> open(Media media, {bool? play}) =>
      _transport.trackLoad(() => _open(media, play));

  /// Opens a list of [Media] items as the new playlist, optionally starting at [index].
  ///
  /// Multi-media counterpart of [open]. [index] is clamped to
  /// `[0, medias.length - 1]`.
  ///
  /// Entries are appended on the core WITHOUT starting playback (mpv's
  /// `loadfile append` never autostarts), then a single
  /// `playlist-play-index` starts directly at [index]. The entry at
  /// position 0 is never loaded, played, or reported as current unless
  /// it IS the requested index, so a UI bound to
  /// [PlaybackState.playlist]'s `index` never flashes track 1 before the
  /// selected track, and no audio from track 1 leaks out. During the
  /// transition the outgoing track keeps playing (or stays parked) until
  /// the jump; while entries build up on an idle core the playlist
  /// `index` reports `-1` (see [Playlist.index]).
  ///
  /// The call succeeds or fails as a whole. When mpv refuses an entry it
  /// throws [MpvCommandException], the entries it already added leave the
  /// playlist, the track that was playing keeps playing (parked at the
  /// end, the playlist is left empty), and the play intent goes back to
  /// what it was.
  @override
  Future<void> openAll(List<Media> medias, {bool? play, int index = 0}) =>
      _transport.trackLoad(() => _openAll(medias, play, index));

  /// Loads a playlist FILE or URL (`.m3u`, `.m3u8`, `.pls` or `.cue`) and
  /// optionally starts playback. Unlike [open], which loads [playlist] as a
  /// single entry, this parses it with mpv's `loadlist`, so its entries
  /// become the playlist. This is the path for internet-radio station lists
  /// and remote `.m3u` playlists.
  ///
  /// [PlayerStream.playlist] and [PlaybackState.playlist] reflect the parsed
  /// entries once mpv expands them. When [play] is null the configuration's
  /// autoplay value decides. Replaces any currently loaded file or playlist.
  ///
  /// Per-[Media] options (`httpHeaders`, `demuxerLavfOptions`, `httpChunkSize`,
  /// `start`, `end`, `waveformDurationHint`) are validated but NOT applied
  /// to the playlist fetch:
  /// `loadlist` has no file-local options slot. Entries parsed out of the playlist inherit the
  /// global network and demuxer settings.
  @override
  Future<void> openPlaylistFile(Media playlist, {bool? play}) =>
      _transport.trackLoad(() => _openPlaylistFile(playlist, play));
}
