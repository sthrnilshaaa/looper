// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import '../internals/unset_sentinel.dart';

part '../generated/mpv_track_data.dart';

/// A single track entry from mpv's `track-list` (or
/// `current-tracks/audio`).
///
/// mpv reports every track in a multi-track file as a node-map: an
/// integer [id] (used for switching via
/// `Player.setAudioTrack(Track.id(...))`), a
/// [type] (`'audio'`, `'video'`, `'sub'`, etc.), and metadata like
/// [title], [lang], [defaultTrack] and [forced]. Audio tracks
/// additionally expose the parameters the demuxer reports ([sampleRate],
/// [channels], [channelCount], from mpv's `demux-*` fields).
///
/// The [image] and [albumArt] flags distinguish embedded picture streams
/// (`attached_pic`) from regular audio tracks: check [image] to skip such
/// pseudo-tracks when populating a "switch audio track" UI.
final class MpvTrack with _$MpvTrack {
  /// mpv's integer track ID. Wrap in [Track.id] and pass to
  /// `Player.setAudioTrack` to switch to this track.
  final int id;

  /// `'audio'`, `'video'` or `'sub'`. Empty when mpv omits the field.
  final String type;

  /// Whether mpv currently has this track selected for output.
  final bool selected;

  /// Track title from container metadata. `null` when absent.
  final String? title;

  /// ISO 639 language code from the container. `null` when absent.
  final String? lang;

  /// Container's default-track flag.
  final bool defaultTrack;

  /// Container's forced-track flag (mostly relevant for subtitles).
  final bool forced;

  /// Container's dependent-track flag. Tracks marked dependent are
  /// auxiliary streams (e.g. commentary depending on a main mix).
  final bool dependent;

  /// Container's visual-impaired flag (audio descriptions for
  /// visually-impaired listeners).
  final bool visualImpaired;

  /// Container's hearing-impaired flag (sub-mixes adapted for
  /// hearing-impaired listeners; common in broadcast).
  final bool hearingImpaired;

  /// Whether this track is an embedded picture or cover art stream
  /// (`attached_pic`). UI track switchers should typically skip these.
  final bool image;

  /// Whether this track is specifically marked as album art.
  final bool albumArt;

  /// Whether this track was loaded from a separate file (via
  /// [Player.addAudioTrack] or mpv's external-file auto-load) rather than the
  /// container itself. Mirrors mpv's `external`.
  final bool external;

  /// Path or URI of the external file backing this track, or `null` for tracks
  /// embedded in the main container. Mirrors mpv's `external-filename`.
  final String? externalFilename;

  /// Codec short name (e.g. `'flac'`, `'aac'`).
  final String? codec;

  /// Human-readable codec description from libavcodec.
  final String? codecDesc;

  /// Codec profile string when the container reports one (e.g. `'LC'`,
  /// `'HE-AAC'`). `null` when unknown. Mirrors mpv's `codec-profile`.
  final String? codecProfile;

  /// Short decoder name actually used by mpv at runtime (`'flac'`,
  /// `'libfdk-aac'`, …). Differs from [codec] when multiple decoders
  /// are available for the same codec or when the chosen decoder is
  /// vendor-specific.
  final String? decoder;

  /// Human-readable description of the decoder in use.
  final String? decoderDesc;

  /// Sample format short name (e.g. `'fltp'`, `'s16'`).
  final String? formatName;

  /// Sample rate in Hz, as the demuxer reports it (mpv's
  /// `demux-samplerate`). Audio tracks only.
  final int? sampleRate;

  /// Channel layout as the demuxer reports it (e.g. `'stereo'`, `'5.1'`;
  /// mpv's `demux-channels`).
  final String? channels;

  /// Channel count as the demuxer reports it (mpv's
  /// `demux-channel-count`).
  final int? channelCount;

  /// Average bitrate as reported by the demuxer, in bits per second.
  /// Complements [codec] when the source's bitrate is variable or when
  /// the container's metadata doesn't carry it elsewhere.
  final double? demuxBitrate;

  /// HLS variant bitrate when the source is an HLS playlist, in bits
  /// per second. `null` for non-HLS sources.
  final double? hlsBitrate;

  /// ReplayGain track-level gain in dB. Only present for audio tracks
  /// with corresponding tag information.
  final double? replayGainTrackGain;

  /// ReplayGain track-level peak as a linear amplitude (1.0 = full
  /// scale). Only present for audio tracks with corresponding tag
  /// information.
  final double? replayGainTrackPeak;

  /// ReplayGain album-level gain in dB. mpv falls back to the
  /// per-track value when the file carries only per-track tags.
  final double? replayGainAlbumGain;

  /// ReplayGain album-level peak as a linear amplitude. Same per-track
  /// fallback as [replayGainAlbumGain].
  final double? replayGainAlbumPeak;

  /// Per-track tag dictionary. Distinct from [FileState.metadata]
  /// (which is global and file-level): this is the metadata mpv keeps
  /// per stream, useful in multi-track containers where each track
  /// carries its own title, artist and role tags.
  final Map<String, String> metadata;

  /// Creates a track descriptor. Only [id] and [type] are required; the
  /// remaining fields mirror the optional entries mpv exposes per track.
  const MpvTrack({
    required this.id,
    required this.type,
    this.selected = false,
    this.title,
    this.lang,
    this.defaultTrack = false,
    this.forced = false,
    this.dependent = false,
    this.visualImpaired = false,
    this.hearingImpaired = false,
    this.image = false,
    this.albumArt = false,
    this.external = false,
    this.externalFilename,
    this.codec,
    this.codecDesc,
    this.codecProfile,
    this.decoder,
    this.decoderDesc,
    this.formatName,
    this.sampleRate,
    this.channels,
    this.channelCount,
    this.demuxBitrate,
    this.hlsBitrate,
    this.replayGainTrackGain,
    this.replayGainTrackPeak,
    this.replayGainAlbumGain,
    this.replayGainAlbumPeak,
    this.metadata = const <String, String>{},
  });

  @override
  String toString() =>
      'MpvTrack(id: $id, type: $type, selected: $selected, '
      'title: $title, lang: $lang)';
}
