// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import '../../internals/unset_sentinel.dart';
import '../../models/audio_params.dart';
import '../../models/chapter.dart';
import '../../models/cover_art.dart';
import '../../models/mpv_track.dart';

part '../../generated/file_state_data.dart';

/// What mpv read from the current file: its tags, tracks, chapters, cover, format and paths. Reset when nothing is loaded.
///
/// The [PlayerState.file] of a player: read it from `player.state.file`,
/// or follow one value through its stream in `player.stream`.
///
/// {@category State and streams}
final class FileState with _$FileState {
  /// Dictionary of tags (metadata) for the current track (e.g. Title, Artist).
  final Map<String, String> metadata;

  /// Tag dictionary for the active chapter (per-chapter metadata).
  /// Empty when no chapter is active or the file has no chapter tags.
  /// Mirrors mpv's `chapter-metadata`. Distinct from [metadata] (file
  /// level) and from [Chapter.title] (chapter list, just the title).
  final Map<String, String> chapterMetadata;

  /// Chapters in the current file (audiobook or podcast markers).
  /// Empty list when the file carries no chapter table.
  final List<Chapter> chapters;

  /// All tracks reported by mpv for the current file (audio, video,
  /// embedded picture, …). Filter by [MpvTrack.type] for a typed
  /// "audio tracks only" view; switch via [Player.setAudioTrack].
  final List<MpvTrack> tracks;

  /// The single audio track currently selected for output, or `null`
  /// when audio is muted at the track level. Distinct from [tracks],
  /// which lists every track the demuxer surfaced. Mirrors mpv's
  /// `current-tracks/audio`.
  final MpvTrack? currentAudioTrack;

  /// Audio format parameters from the decoder (track source).
  final AudioParams audioParams;

  /// Current audio bitrate in bps. `null` if unavailable.
  final double? audioBitrate;

  /// Embedded cover art of the currently loaded track, or `null`
  /// when the file has no embedded picture. Refreshes on every file load,
  /// and goes to `null` first when [Player.open], [Player.openAll] or
  /// [Player.openPlaylistFile] returns. Read live via
  /// [PlayerStream.coverArt].
  final CoverArt? coverArt;

  /// Display name for the current track. Falls back to the file name
  /// when no `title` tag is available. Mirrors mpv's `media-title`.
  final String mediaTitle;

  /// Container format (e.g. `mp4`, `m4a`, `flac`, `mp3`). Comma-separated
  /// list when the demuxer matches multiple formats.
  final String fileFormat;

  /// Total stream size in bytes. Zero when unknown (live streams).
  final int fileSize;

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

  /// Source playlist of the current entry (`playlist-path`): the original
  /// `.m3u` or `.pls` path it was expanded from. Empty when the current file
  /// was not loaded via a playlist.
  final String playlistPath;

  /// Name of the demuxer in use (e.g. `mkv`, `lavf`, `mp3`). Empty
  /// when no file is loaded. Mirrors mpv's `current-demuxer`.
  final String currentDemuxer;

  /// Initial timestamp offset of the current file, as reported by the
  /// demuxer. Useful when the container's first frame isn't at zero
  /// (chapter-skipped files, edited cuts). Mirrors mpv's
  /// `demuxer-start-time`.
  final Duration demuxerStartTime;

  /// Creates a [FileState]; each value defaults to the one of a player that
  /// has loaded nothing.
  const FileState({
    this.metadata = const <String, String>{},
    this.chapterMetadata = const <String, String>{},
    this.chapters = const <Chapter>[],
    this.tracks = const <MpvTrack>[],
    this.currentAudioTrack,
    this.audioParams = const AudioParams(),
    this.audioBitrate,
    this.coverArt,
    this.mediaTitle = '',
    this.fileFormat = '',
    this.fileSize = 0,
    this.path = '',
    this.filename = '',
    this.streamPath = '',
    this.streamOpenFilename = '',
    this.playlistPath = '',
    this.currentDemuxer = '',
    this.demuxerStartTime = Duration.zero,
  });
}
