// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

// The snapshots the media session pushes, built from the state of the
// player: pure functions, apart from the artwork, which the controller
// loads.

import 'package:flutter/foundation.dart';

import '../models/cover_art.dart';
import '../models/media.dart';
import '../models/media_session.dart';
import '../player/player_state.dart';
import '../types/enums/loop.dart';
import '../types/sealed/media_session_artwork.dart';
import 'media_session_channel.dart';
import 'media_session_uris.dart';

/// The metadata the OS shows for [state]: the explicit override first,
/// then mpv's tags, the extras of the current item and the media title.
/// [artworkFor] turns the resolved artwork into the picture and the URL
/// that are pushed.
@internal
MediaSessionMetadataSnapshot metadataSnapshot(
  PlayerState state,
  ({CoverArt? cover, String? artworkUrl}) Function(
    ({CoverArt? bytes, String? uri}) artwork,
  )
  artworkFor,
) {
  final override = state.settings.mediaSession;
  final mpvMeta = state.file.metadata;

  // The currently-playing queue item. Its consumer-attached
  // [Media.extras] are the metadata fallback for tag-less files, most
  // importantly transcoded streams (HLS or DASH), where mpv sees no tags and
  // reports the stream URL as `media-title`. extras sit below mpv's real
  // tags but above the filename-derived `media-title`.
  final item = _currentItem(state);
  final extras = item?.extras;

  // Title falls through: explicit override → mpv's `metadata.title` tag
  // → consumer-attached `extras['title']` → mpv's `media-title` (which
  // itself falls back to the filename for files without a title tag).
  // For a network item that last fallback is derived from the URL, so its
  // query string (often credentials) is stripped first.
  final remote = item != null && !isLocalUri(item.uri);
  final title =
      override?.title ??
      _firstTagValue(mpvMeta, const ['title']) ??
      _extra(extras, 'title') ??
      _mediaTitle(state.file.mediaTitle, remote: remote);

  final artist =
      override?.artist ??
      _firstTagValue(mpvMeta, const ['artist', 'album_artist']) ??
      _extra(extras, 'artist');

  final album =
      override?.album ??
      _firstTagValue(mpvMeta, const ['album']) ??
      _extra(extras, 'album');

  final duration =
      override?.duration ??
      (state.playback.duration == Duration.zero
          ? null
          : state.playback.duration);

  // Rich tags (mpv-derived, with the extras-attached artist as a final
  // fallback for the album-artist line on tag-less streams).
  final albumArtist =
      _firstTagValue(mpvMeta, const ['album_artist']) ??
      _extra(extras, 'artist');
  final genre = _firstTagValue(mpvMeta, const ['genre']);
  // mpv `track` and `disc` tags are often "3" or "3/12"; take the leading
  // int.
  final trackNumber = _parseLeadingInt(
    _firstTagValue(mpvMeta, const ['track']),
  );
  final discNumber = _parseLeadingInt(_firstTagValue(mpvMeta, const ['disc']));

  // Source URI of the current item, for MPRIS xesam:url, which takes a URI:
  // a bare path is not one. Only local files: the bus is readable by every
  // process in the session, and a network URL can carry credentials
  // (Subsonic `u`, `t` and `s`, Jellyfin `api_key`).
  final url = remote || item == null ? null : fileUri(item.uri);

  final (:cover, :artworkUrl) = artworkFor(
    _resolveArtwork(override, state.file.coverArt, extras),
  );

  return MediaSessionMetadataSnapshot(
    title: title,
    artist: artist,
    album: album,
    artwork: cover,
    duration: duration,
    trackNumber: trackNumber,
    discNumber: discNumber,
    albumArtist: albumArtist,
    genre: genre,
    url: url,
    artworkUrl: artworkUrl,
  );
}

/// The item of [state]'s playlist that is current, `null` when none is.
Media? _currentItem(PlayerState state) {
  final playlist = state.playback.playlist;
  final index = playlist.index;
  if (index < 0 || index >= playlist.items.length) return null;
  return playlist.items[index];
}

/// mpv's `media-title`, the last fallback of the title: `null` when
/// empty, its query string stripped for a [remote] item, whose title is
/// derived from the URL.
String? _mediaTitle(String mediaTitle, {required bool remote}) {
  if (mediaTitle.isEmpty) return null;
  return remote ? redactUrlTitle(mediaTitle) : mediaTitle;
}

/// Reads a non-empty string [key] from a queue item's [Media.extras];
/// `null` if the map is absent, lacks the key, or the value is blank or
/// not a string. Lets a consumer supply lockscreen metadata for streams
/// the file itself can't tag.
String? _extra(Map<String, Object?>? extras, String key) {
  final v = extras?[key];
  return (v is String && v.isNotEmpty) ? v : null;
}

/// Parses the leading integer from a tag like `"3"` or `"3/12"`; `null` if
/// absent or non-numeric.
int? _parseLeadingInt(String? raw) {
  if (raw == null) return null;
  final match = RegExp(r'^\s*(\d+)').firstMatch(raw);
  return match == null ? null : int.tryParse(match.group(1)!);
}

/// Resolves the effective artwork into one of two shapes: decoded [bytes]
/// (embedded or custom) or a [uri], which the fetcher loads.
///
/// For the default [MediaSessionArtwork.embedded] the file's embedded cover
/// wins; when it has none (the common case for a transcoded stream) we
/// fall back to a network artwork URL the consumer attached to the queue
/// item as `extras['art']`, mirroring the title, artist and album fallback.
/// An explicit [MediaSessionArtwork.none] suppresses art outright (no
/// fallback).
({CoverArt? bytes, String? uri}) _resolveArtwork(
  MediaSession? override,
  CoverArt? embedded,
  Map<String, Object?>? extras,
) {
  final artwork = override?.artwork ?? MediaSessionArtwork.embedded;
  return switch (artwork) {
    MediaSessionArtworkNone() => (bytes: null, uri: null),
    MediaSessionArtworkCustom(:final cover) => (bytes: cover, uri: null),
    MediaSessionArtworkUri(:final uri) => (bytes: null, uri: uri.toString()),
    MediaSessionArtworkEmbedded() =>
      embedded != null
          ? (bytes: embedded, uri: null)
          : (bytes: null, uri: _extra(extras, 'art')),
  };
}

/// The playback the OS shows for [state]. While the network buffers, the
/// `seekable` stays [pushedSeekable], the one last sent, when there is one.
@internal
MediaSessionPlaybackSnapshot playbackSnapshot(
  PlayerState state, {
  required bool seek,
  required bool? pushedSeekable,
  required int appPauses,
  bool stopped = false,
}) {
  // Navigability: a real multi-item mpv playlist reflects its bounds
  // (loop=playlist wraps both ways); a single item stays navigable so an
  // external-queue consumer still receives next and previous.
  final pl = state.playback.playlist;
  final multi = pl.items.length > 1;
  final loopPlaylist = state.playback.loop == Loop.playlist;
  final hasNext = !multi || loopPlaylist || pl.index < pl.items.length - 1;
  final hasPrevious = !multi || loopPlaylist || pl.index > 0;
  final seekable = state.network.buffering
      ? pushedSeekable ?? state.playback.seekable
      : state.playback.seekable;
  return MediaSessionPlaybackSnapshot(
    playing: state.playback.playWhenReady,
    position: state.playback.position,
    rate: state.settings.rate,
    seekable: seekable,
    loop: state.playback.loop,
    shuffle: state.playback.shuffle,
    // Terminal end-of-content. The end-of-content settle releases
    // `playWhenReady` at true EOF, which already drives a playback push,
    // so the completed transition is carried on that same snapshot.
    completed: state.playback.completed,
    stopped: stopped,
    queued: pl.items.isNotEmpty,
    seek: seek,
    // Actual output + buffering, for extrapolation gating and the loading
    // state. Independent of the intent axis the button binds to.
    actualPlaying: state.playback.playing,
    buffering: state.network.buffering,
    hasNext: hasNext,
    hasPrevious: hasPrevious,
    appPauses: appPauses,
  );
}

/// First non-empty value among [keys] in the mpv metadata map, matched
/// **case-insensitively**: mpv's tag-key casing varies by container
/// (ID3v2 and Vorbis come back lowercase, but MP4 and iTunes atoms do not),
/// so never assume a fixed case. [keys] are given lowercase; the list
/// also carries semantic fallbacks (e.g. `album_artist` when `artist`
/// is absent).
String? _firstTagValue(Map<String, String> meta, List<String> keys) {
  for (final key in keys) {
    for (final entry in meta.entries) {
      if (entry.value.isNotEmpty && entry.key.toLowerCase() == key) {
        return entry.value;
      }
    }
  }
  return null;
}
