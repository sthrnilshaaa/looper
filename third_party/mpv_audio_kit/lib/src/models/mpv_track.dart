// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import '../internals/unset_sentinel.dart';

bool _mapEq(Map<String, String> a, Map<String, String> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (final entry in a.entries) {
    if (b[entry.key] != entry.value) return false;
  }
  return true;
}

/// A single track entry from mpv's `track-list` (or
/// `current-tracks/audio`).
///
/// mpv reports every track in a multi-track file as a node-map: an
/// integer [id] (used for switching via
/// `Player.setAudioTrack(Track.id(...))`), a
/// [type] (`'audio'`, `'video'`, `'sub'`, etc.), and metadata like
/// [title] / [lang] / [defaultTrack] / [forced]. Audio tracks
/// additionally expose decoder-side parameters ([sampleRate],
/// [channels], [channelCount]).
///
/// The [image] / [albumArt] flags distinguish embedded picture streams
/// (`attached_pic`) from regular audio tracks — set [image] to skip
/// such pseudo-tracks when populating a "switch audio track" UI.
final class MpvTrack {
  /// mpv's integer track ID. Wrap in [Track.id] and pass to
  /// `Player.setAudioTrack` to switch to this track.
  final int id;

  /// `'audio'` / `'video'` / `'sub'`. Empty when mpv omits the field.
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

  /// Whether this track is an embedded picture / cover art stream
  /// (`attached_pic`). UI track switchers should typically skip these.
  final bool image;

  /// Whether this track is specifically marked as album art.
  final bool albumArt;

  /// Whether this track was loaded from a separate file (via
  /// [Player.addAudioTrack] or mpv's external-file auto-load) rather than the
  /// container itself. Mirrors mpv's `external`.
  final bool external;

  /// Path/URI of the external file backing this track, or `null` for tracks
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

  /// Decoder-side sample rate in Hz. Audio tracks only.
  final int? sampleRate;

  /// Decoder-side channel layout (e.g. `'stereo'`, `'5.1'`).
  final String? channels;

  /// Decoder-side channel count.
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

  /// Per-track tag dictionary. Distinct from [PlayerState.metadata]
  /// (which is global / file-level): this is the metadata mpv keeps
  /// per stream, useful in multi-track containers where each track
  /// carries its own title / artist / role tags.
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

  /// Returns a copy with the given fields replaced. Pass `null` for a
  /// nullable field to clear it; omitted fields keep their current value.
  MpvTrack copyWith({
    int? id,
    String? type,
    bool? selected,
    Object? title = unset,
    Object? lang = unset,
    bool? defaultTrack,
    bool? forced,
    bool? dependent,
    bool? visualImpaired,
    bool? hearingImpaired,
    bool? image,
    bool? albumArt,
    bool? external,
    Object? externalFilename = unset,
    Object? codec = unset,
    Object? codecDesc = unset,
    Object? codecProfile = unset,
    Object? decoder = unset,
    Object? decoderDesc = unset,
    Object? formatName = unset,
    Object? sampleRate = unset,
    Object? channels = unset,
    Object? channelCount = unset,
    Object? demuxBitrate = unset,
    Object? hlsBitrate = unset,
    Object? replayGainTrackGain = unset,
    Object? replayGainTrackPeak = unset,
    Object? replayGainAlbumGain = unset,
    Object? replayGainAlbumPeak = unset,
    Map<String, String>? metadata,
  }) =>
      MpvTrack(
        id: id ?? this.id,
        type: type ?? this.type,
        selected: selected ?? this.selected,
        title: identical(title, unset) ? this.title : title as String?,
        lang: identical(lang, unset) ? this.lang : lang as String?,
        defaultTrack: defaultTrack ?? this.defaultTrack,
        forced: forced ?? this.forced,
        dependent: dependent ?? this.dependent,
        visualImpaired: visualImpaired ?? this.visualImpaired,
        hearingImpaired: hearingImpaired ?? this.hearingImpaired,
        image: image ?? this.image,
        albumArt: albumArt ?? this.albumArt,
        external: external ?? this.external,
        externalFilename: identical(externalFilename, unset)
            ? this.externalFilename
            : externalFilename as String?,
        codec: identical(codec, unset) ? this.codec : codec as String?,
        codecDesc:
            identical(codecDesc, unset) ? this.codecDesc : codecDesc as String?,
        codecProfile: identical(codecProfile, unset)
            ? this.codecProfile
            : codecProfile as String?,
        decoder: identical(decoder, unset) ? this.decoder : decoder as String?,
        decoderDesc: identical(decoderDesc, unset)
            ? this.decoderDesc
            : decoderDesc as String?,
        formatName: identical(formatName, unset)
            ? this.formatName
            : formatName as String?,
        sampleRate:
            identical(sampleRate, unset) ? this.sampleRate : sampleRate as int?,
        channels:
            identical(channels, unset) ? this.channels : channels as String?,
        channelCount: identical(channelCount, unset)
            ? this.channelCount
            : channelCount as int?,
        demuxBitrate: identical(demuxBitrate, unset)
            ? this.demuxBitrate
            : demuxBitrate as double?,
        hlsBitrate: identical(hlsBitrate, unset)
            ? this.hlsBitrate
            : hlsBitrate as double?,
        replayGainTrackGain: identical(replayGainTrackGain, unset)
            ? this.replayGainTrackGain
            : replayGainTrackGain as double?,
        replayGainTrackPeak: identical(replayGainTrackPeak, unset)
            ? this.replayGainTrackPeak
            : replayGainTrackPeak as double?,
        replayGainAlbumGain: identical(replayGainAlbumGain, unset)
            ? this.replayGainAlbumGain
            : replayGainAlbumGain as double?,
        replayGainAlbumPeak: identical(replayGainAlbumPeak, unset)
            ? this.replayGainAlbumPeak
            : replayGainAlbumPeak as double?,
        metadata: metadata ?? this.metadata,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MpvTrack &&
          other.id == id &&
          other.type == type &&
          other.selected == selected &&
          other.title == title &&
          other.lang == lang &&
          other.defaultTrack == defaultTrack &&
          other.forced == forced &&
          other.dependent == dependent &&
          other.visualImpaired == visualImpaired &&
          other.hearingImpaired == hearingImpaired &&
          other.image == image &&
          other.albumArt == albumArt &&
          other.external == external &&
          other.externalFilename == externalFilename &&
          other.codec == codec &&
          other.codecDesc == codecDesc &&
          other.codecProfile == codecProfile &&
          other.decoder == decoder &&
          other.decoderDesc == decoderDesc &&
          other.formatName == formatName &&
          other.sampleRate == sampleRate &&
          other.channels == channels &&
          other.channelCount == channelCount &&
          other.demuxBitrate == demuxBitrate &&
          other.hlsBitrate == hlsBitrate &&
          other.replayGainTrackGain == replayGainTrackGain &&
          other.replayGainTrackPeak == replayGainTrackPeak &&
          other.replayGainAlbumGain == replayGainAlbumGain &&
          other.replayGainAlbumPeak == replayGainAlbumPeak &&
          _mapEq(metadata, other.metadata));

  @override
  int get hashCode => Object.hashAll([
        id,
        type,
        selected,
        title,
        lang,
        defaultTrack,
        forced,
        dependent,
        visualImpaired,
        hearingImpaired,
        image,
        albumArt,
        external,
        externalFilename,
        codec,
        codecDesc,
        codecProfile,
        decoder,
        decoderDesc,
        formatName,
        sampleRate,
        channels,
        channelCount,
        demuxBitrate,
        hlsBitrate,
        replayGainTrackGain,
        replayGainTrackPeak,
        replayGainAlbumGain,
        replayGainAlbumPeak,
        Object.hashAllUnordered(
          metadata.entries.map((e) => Object.hash(e.key, e.value)),
        ),
      ]);

  @override
  String toString() => 'MpvTrack(id: $id, type: $type, selected: $selected, '
      'title: $title, lang: $lang)';
}
