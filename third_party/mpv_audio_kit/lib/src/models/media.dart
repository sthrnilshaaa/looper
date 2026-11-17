// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import '../internals/unset_sentinel.dart';

bool _mapEqDyn(Map<String, Object?>? a, Map<String, Object?>? b) {
  if (identical(a, b)) return true;
  if (a == null || b == null) return false;
  if (a.length != b.length) return false;
  for (final entry in a.entries) {
    if (!b.containsKey(entry.key) || b[entry.key] != entry.value) return false;
  }
  return true;
}

bool _mapEq(Map<String, String>? a, Map<String, String>? b) {
  if (identical(a, b)) return true;
  if (a == null || b == null) return false;
  if (a.length != b.length) return false;
  for (final entry in a.entries) {
    if (b[entry.key] != entry.value) return false;
  }
  return true;
}

/// A piece of media that can be loaded into the [Player].
///
/// Wraps a URI string with optional metadata and per-track configuration.
///
/// ```dart
/// final track = Media('https://example.com/audio.mp3');
/// final local = Media('file:///home/user/music/song.flac');
/// final asset = Media('asset:///assets/audio/sample.mp3');
///
/// // Attach arbitrary data to a track (available via Player.state.playlist).
/// final rich = Media(
///   'https://cdn.example.com/episode-42.mp3',
///   extras: {
///     'title':   'Episode 42',
///     'artist':  'The Podcast',
///     'artUri':  'https://cdn.example.com/art.jpg',
///     'startAt': Duration(minutes: 5),
///   },
///   httpHeaders: {
///     'User-Agent': 'mpv_audio_kit',
///   },
/// );
///
/// // Opt in to chunked range requests so a throttling CDN (YouTube /
/// // googlevideo) keeps serving at full speed after a seek.
/// final yt = Media(googlevideoUrl, httpChunkSize: 8 * 1024 * 1024);
/// ```
///
/// Equality considers all fields ([uri], [extras] and [httpHeaders]) so two
/// instances that differ in any of them sort and compare distinctly — useful
/// when diffing playlists for re-render decisions.
final class Media {
  /// The URI of the media resource.
  ///
  /// Supported schemes: `http://`, `https://`, `file://`, `asset:///`,
  /// `rtsp://`, `rtmp://`, and anything else that libmpv accepts.
  final String uri;

  /// Optional user-supplied metadata attached to this track.
  ///
  /// The player itself does not interpret these values; they are carried
  /// through the playlist so the UI layer can access them without a
  /// separate lookup.
  final Map<String, Object?>? extras;

  /// Optional HTTP headers for network streams.
  ///
  /// Applied automatically on every load path — [Player.open],
  /// [Player.openAll], [Player.add] and [Player.replace] all attach
  /// these headers to the matching mpv `loadfile` as file-local
  /// options (`http-header-fields=...`), so the headers ride along
  /// with that exact playlist entry without leaking onto other
  /// entries or the global `http-header-fields` option.
  ///
  /// If you need headers that depend on runtime state computed at
  /// load time (e.g. a token refreshed asynchronously), register an
  /// `on_load` hook (see `Player.registerHook`) and set
  /// `file-local-options/http-header-fields` from the handler.
  final Map<String, String>? httpHeaders;

  /// Optional per-track options for libmpv's libavformat (`lavf`) demuxer,
  /// applied as the file-local `demuxer-lavf-o` — the demuxer-side analogue of
  /// [httpHeaders]. Each `key: value` becomes one `key=value` entry, scoped to
  /// this exact playlist entry.
  ///
  /// A common use is reaching the segment demuxer of an HLS/DASH stream via the
  /// HLS demuxer's `seg_format_options` dictionary, e.g.
  /// `{'seg_format_options': 'advanced_editlist=0'}`.
  ///
  /// Values must not contain a comma; keys must be non-empty. `null` (default)
  /// sets nothing.
  final Map<String, String>? demuxerLavfOptions;

  /// Opt-in maximum size, in bytes, of each HTTP range request for this
  /// source. `null` (default) leaves mpv's normal behaviour — one open-ended
  /// request for the rest of the file.
  ///
  /// Set it to fetch the stream in bounded chunks instead. Some CDNs —
  /// notably progressive YouTube / `googlevideo` audio — rate-limit a single
  /// open-ended request for the whole file to a crawl, so seeking back
  /// freezes once the buffered audio drains. Capping each request below the
  /// CDN's threshold (a common value is `8 * 1024 * 1024`, 8 MiB) keeps it
  /// serving at full speed. The same technique yt-dlp uses (`--http-chunk-size`).
  ///
  /// Leave it `null` for fast, trusted servers (Plex, Jellyfin, your own
  /// library) where one large request buffers fastest. Like [httpHeaders],
  /// the value is scoped to this exact `loadfile` and never leaks onto other
  /// playlist entries. Must be positive when set.
  final int? httpChunkSize;

  /// Creates an immutable media item for [uri], with optional consumer
  /// [extras], per-request [httpHeaders] and [httpChunkSize].
  const Media(
    this.uri, {
    this.extras,
    this.httpHeaders,
    this.httpChunkSize,
    this.demuxerLavfOptions,
  });

  /// Returns a copy with the given fields replaced. Pass `null` for
  /// [extras], [httpHeaders], [httpChunkSize] or [demuxerLavfOptions] to
  /// clear them; omitted fields keep their current value.
  Media copyWith({
    String? uri,
    Object? extras = unset,
    Object? httpHeaders = unset,
    Object? httpChunkSize = unset,
    Object? demuxerLavfOptions = unset,
  }) =>
      Media(
        uri ?? this.uri,
        extras: identical(extras, unset)
            ? this.extras
            : extras as Map<String, Object?>?,
        httpHeaders: identical(httpHeaders, unset)
            ? this.httpHeaders
            : httpHeaders as Map<String, String>?,
        httpChunkSize: identical(httpChunkSize, unset)
            ? this.httpChunkSize
            : httpChunkSize as int?,
        demuxerLavfOptions: identical(demuxerLavfOptions, unset)
            ? this.demuxerLavfOptions
            : demuxerLavfOptions as Map<String, String>?,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Media &&
          other.uri == uri &&
          other.httpChunkSize == httpChunkSize &&
          _mapEqDyn(extras, other.extras) &&
          _mapEq(httpHeaders, other.httpHeaders) &&
          _mapEq(demuxerLavfOptions, other.demuxerLavfOptions));

  @override
  int get hashCode => Object.hash(
        uri,
        httpChunkSize,
        extras == null
            ? null
            : Object.hashAllUnordered(
                extras!.entries.map((e) => Object.hash(e.key, e.value)),
              ),
        httpHeaders == null
            ? null
            : Object.hashAllUnordered(
                httpHeaders!.entries.map((e) => Object.hash(e.key, e.value)),
              ),
        demuxerLavfOptions == null
            ? null
            : Object.hashAllUnordered(
                demuxerLavfOptions!.entries
                    .map((e) => Object.hash(e.key, e.value)),
              ),
      );

  @override
  String toString() => 'Media(uri: $uri, extras: $extras, '
      'httpHeaders: $httpHeaders, httpChunkSize: $httpChunkSize, '
      'demuxerLavfOptions: $demuxerLavfOptions)';
}
