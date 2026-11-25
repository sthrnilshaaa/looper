// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import '../generated/audio_effects_settings.dart';
import '../internals/unset_sentinel.dart';
import '../models/audio_params.dart';
import '../models/chapter.dart';
import '../models/demuxer_cache_state.dart';
import '../models/device.dart';
import '../models/mpv_track.dart';
import '../models/playlist.dart';
import '../types/enums/cover.dart';
import '../types/enums/format.dart';
import '../types/enums/gapless.dart';
import '../types/enums/hls_bitrate.dart';
import '../types/enums/loop.dart';
import '../types/enums/spdif.dart';
import '../types/sealed/channels.dart';
import '../types/settings/cache_settings.dart';
import '../types/settings/demuxer_settings.dart';
import '../types/settings/replay_gain_settings.dart';
import '../types/settings/spectrum_settings.dart';
import '../types/state/audio_output_state.dart';
import '../types/state/mpv_playback_state.dart';
import 'mpv_playback_state_derive.dart';
import 'state/file_state.dart';
import 'state/library_versions.dart';
import 'state/network_state.dart';
import 'state/output_state.dart';
import 'state/playback_state.dart';
import 'state/player_settings.dart';

part '../generated/player_state_data.dart';

/// Immutable snapshot of the [Player]'s complete playback state, in six
/// groups: [playback], [network], [file], [output], [settings] and
/// [versions].
///
/// Retrieve the current snapshot synchronously via `player.state`, or subscribe
/// to individual fields via the typed streams in `player.stream`.
///
/// A value is read from its group: `state.playback.position`,
/// `state.settings.volume`. [copyWith] takes the groups and every field of
/// every group.
///
/// {@category State and streams}
final class PlayerState with _$PlayerState {
  /// Transport, position and the playlist.
  final PlaybackState playback;

  /// Buffering, cache and read health of the current source.
  final NetworkState network;

  /// What mpv read from the current file.
  final FileState file;

  /// The audio output in use.
  final OutputState output;

  /// What the app asked of the player.
  final PlayerSettings settings;

  /// The versions of libmpv and FFmpeg.
  final LibraryVersions versions;

  /// Creates a [PlayerState]; each group defaults to the one of a player
  /// that has loaded nothing.
  const PlayerState({
    this.playback = const PlaybackState(),
    this.network = const NetworkState(),
    this.file = const FileState(),
    this.output = const OutputState(),
    this.settings = const PlayerSettings(),
    this.versions = const LibraryVersions(),
  });

  /// The aggregate playback lifecycle of this snapshot, the value
  /// `PlayerStream.playbackState` emits: derived from
  /// [PlaybackState.playing], [NetworkState.buffering],
  /// [PlaybackState.completed], [NetworkState.pausedForCache] and whether
  /// [FileState.path] names a loaded file.
  MpvPlaybackState get playbackState => deriveMpvPlaybackState(
    playing: playback.playing,
    buffering: network.buffering,
    completed: playback.completed,
    pausedForCache: network.pausedForCache,
    fileLoaded: file.path.isNotEmpty,
  );

  @override
  String toString() =>
      'PlayerState(playing: ${playback.playing}, playWhenReady: ${playback.playWhenReady}, position: ${playback.position}, duration: ${playback.duration}, volume: ${settings.volume}, mediaTitle: ${file.mediaTitle})';
}
