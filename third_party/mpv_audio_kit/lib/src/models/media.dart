// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'package:meta/meta.dart';

import '../internals/equality.dart';
import '../internals/unset_sentinel.dart';
import 'media_blob_io.dart' if (dart.library.js_interop) 'media_blob_web.dart';

/// A piece of media that can be loaded into the [Player].
///
/// Wraps a URI string with optional metadata and per-track configuration.
///
/// ```dart
/// final track = Media('https://example.com/audio.mp3');
/// final local = Media('file:///home/user/music/song.flac');
/// final asset = Media('asset:///assets/audio/sample.mp3');
///
/// // Attach arbitrary data to a track (available via
/// // Player.state.playback.playlist), and start it 5 minutes in.
/// final rich = Media(
///   'https://cdn.example.com/episode-42.mp3',
///   extras: {
///     'title':  'Episode 42',
///     'artist': 'The Podcast',
///     'art':    'https://cdn.example.com/art.jpg',
///   },
///   httpHeaders: {
///     'User-Agent': 'mpv_audio_kit',
///   },
///   start: Duration(minutes: 5),
/// );
///
/// // Opt in to chunked range requests so a CDN that throttles long
/// // open-ended requests keeps serving at full speed after a seek.
/// final throttled = Media(streamUrl, httpChunkSize: 8 * 1024 * 1024);
/// ```
///
/// Equality compares every field ([uri], [extras], [httpHeaders],
/// [httpChunkSize], [streamLavfOptions], [demuxerLavfOptions], [start],
/// [end] and [waveformDurationHint]), so two instances that differ in any of them are not equal:
/// useful when diffing playlists for re-render decisions. The maps compare
/// by content, their values by `==`.
///
/// {@category Playback}
final class Media {
  /// The URI of the media resource.
  ///
  /// Supported schemes: `http://`, `https://`, `file://`, `asset:///`,
  /// `rtsp://`, `rtmp://`, and anything else that libmpv accepts.
  final String uri;

  /// Optional user-supplied metadata attached to this track.
  ///
  /// The values are carried through the playlist so the UI layer can
  /// access them without a separate lookup. Playback ignores them; the OS
  /// media session reads four string keys as a fallback for files without
  /// tags (a transcoded stream, a radio):
  /// - `title`, `artist` and `album`: used when the file has no such tag
  ///   and [MediaSession] sets no override. `title` comes before mpv's
  ///   `media-title`, which falls back to the file name or URL.
  /// - `art`: the URL of the cover, in a scheme
  ///   [MediaSessionArtwork.uri] loads, used when the artwork is
  ///   [MediaSessionArtwork.embedded] and the file has none.
  final Map<String, Object?>? extras;

  /// Optional HTTP headers for network streams.
  ///
  /// Applied automatically on every load path: [Player.open],
  /// [Player.openAll], [Player.add] and [Player.replace] all attach
  /// these headers to the matching mpv `loadfile` as file-local
  /// options (`http-header-fields=...`), so the headers ride along
  /// with that exact playlist entry without leaking onto other
  /// entries or the global `http-header-fields` option.
  ///
  /// If you need headers that depend on runtime state computed at
  /// load time (e.g. a token refreshed asynchronously), register an
  /// `on_load` hook (see `Player.registerHook`) and set
  /// `file-local-options/http-header-fields` from the handler. With
  /// [Player.setPrefetchPlaylist] on, that handler also runs for the next
  /// entry while the current one plays, and a write there lands on the
  /// playing entry: these headers do not have that problem.
  final Map<String, String>? httpHeaders;

  /// Optional per-track options for FFmpeg's network protocols, added to
  /// mpv's global `stream-lavf-o` for this exact playlist entry
  /// (`stream-lavf-o-add`), the stream-side twin of [demuxerLavfOptions].
  /// Each `key: value` becomes one `key=value` entry.
  ///
  /// The player sets the global value when it starts, so a dropped
  /// connection is retried instead of ending the track early:
  /// - `reconnect=1` and `reconnect_delay_max=7`, mpv's own values for a
  ///   file, also for the segments of an HLS stream: a body cut short is
  ///   requested again from where it stopped, on a server that accepts
  ///   range requests, after 0, 1, 3 and 7 s;
  /// - `reconnect_on_network_error=1`: a connection that fails to open
  ///   (refused, reset, a name that does not resolve, a TLS error) is tried
  ///   again on the same schedule, so an unreachable server fails the
  ///   entry after about 11 s;
  /// - `seg_max_retry=4`: the HLS demuxer requests a segment that fails to
  ///   open four more times before it skips it.
  ///
  /// A key set here wins over them, and over what [httpChunkSize] adds.
  /// For a live stream (a radio) add `'reconnect_streamed': '1'`, so a
  /// stream that drops is opened again:
  ///
  /// ```dart
  /// Media(radioUrl, streamLavfOptions: {'reconnect_streamed': '1'})
  /// ```
  ///
  /// Keep it for live streams. A file the server sends without range
  /// support is opened again from its first byte: it plays again from its
  /// start after a cut, and one sent with no length at all plays over and
  /// over.
  ///
  /// Values must not contain a comma; keys must be non-empty. `null`
  /// (default) adds nothing. A global `stream-lavf-o` the app sets with
  /// `Player.setRawProperty` replaces the defaults above, and these
  /// options add to it. With [Player.setPrefetchPlaylist] on, an entry
  /// with these options opens ahead only after an entry with the same
  /// ones.
  final Map<String, String>? streamLavfOptions;

  /// Optional per-track options for libmpv's libavformat (`lavf`) demuxer,
  /// applied as the file-local `demuxer-lavf-o`, the demuxer-side analogue of
  /// [httpHeaders]. Each `key: value` becomes one `key=value` entry, scoped to
  /// this exact playlist entry.
  ///
  /// A common use is reaching the segment demuxer of an HLS or DASH stream via the
  /// HLS demuxer's `seg_format_options` dictionary, e.g.
  /// `{'seg_format_options': 'advanced_editlist=0'}`.
  ///
  /// Values must not contain a comma; keys must be non-empty. `null` (default)
  /// sets nothing.
  ///
  /// With [Player.setPrefetchPlaylist] on, this entry and the entry after
  /// it open when they start, not from the prefetch: the change of these
  /// options makes mpv drop a prefetched demuxer.
  final Map<String, String>? demuxerLavfOptions;

  /// Opt-in maximum size, in bytes, of each HTTP range request for this
  /// source. `null` (default) leaves mpv's normal behaviour: one open-ended
  /// request for the rest of the file.
  ///
  /// Set it to fetch the stream in bounded chunks instead. Some CDNs
  /// rate-limit a single open-ended request for the whole file to a crawl, so
  /// seeking back freezes once the buffered audio drains. Capping each request
  /// below the CDN's threshold (a common value is `8 * 1024 * 1024`, 8 MiB)
  /// keeps it serving at full speed.
  ///
  /// Leave it `null` for fast, trusted servers (Plex, Jellyfin, your own
  /// library) where one large request buffers fastest. Like [httpHeaders],
  /// the value is scoped to this exact `loadfile` and never leaks onto other
  /// playlist entries. Must be positive when set.
  final int? httpChunkSize;

  /// Where this entry starts playing, as a time from the start of the
  /// file (mpv's per-file `start`). `null` (default) starts at the
  /// beginning, or at a resume point saved for the file.
  ///
  /// It holds each time the entry loads: going back to it with
  /// [Player.previous] or [Player.jump], or a playlist loop, starts it here
  /// again. [Loop.file] and [Player.play] at the end of the queue start the
  /// file from its beginning. It wins over a resume point saved with
  /// [Player.writeResumeConfig], whose other values (speed, volume and so
  /// on) still apply, and the load uses that point up as any resume does.
  /// With [Player.setPrefetchPlaylist] on, an entry whose
  /// options differ from the playing entry's, a start included, is not
  /// opened ahead, so the change to it is not gapless.
  ///
  /// Must not be negative. Past the end of the file the entry ends at
  /// once. Like the other per-entry options it does not apply to
  /// [Player.openPlaylistFile], and a live [PcmSource] entry refuses it:
  /// it plays from its first chunk.
  final Duration? start;

  /// Where this entry stops, as a time from the start of the file (mpv's
  /// per-file `end`). `null` (default) plays the file to its end. For a
  /// preview, or a section of a long file queued as an entry of its own.
  ///
  /// The entry ends there as at the end of the file: the playlist moves
  /// on, or the last entry parks and [PlaybackState.completed] turns true.
  /// [PlaybackState.duration], `timeRemaining` and `percentPos` still
  /// describe the whole file. [Loop.file] and [Player.play] at the end of
  /// the queue start the file again from its beginning, and stop at [end]
  /// again. With [Player.setPrefetchPlaylist] on, an entry with an end is
  /// opened ahead only when the playing entry has the same options, and
  /// the entry after one that ends early only once mpv has read its file
  /// to the end.
  ///
  /// Must be later than [start], or than zero when [start] is null. Like
  /// [start] it does not apply to [Player.openPlaylistFile], and a live
  /// [PcmSource] entry refuses it.
  final Duration? end;

  /// The length of this entry, for the waveform and the loudness scan of
  /// an HTTP stream that cannot seek and does not tell its length, or
  /// tells only one estimated from the bitrate: a transcode a music server
  /// sends without byte ranges, whose catalog knows the track's length.
  /// With it the analysis decodes the stream from mpv's cache as it
  /// downloads, and the waveform fills ahead of playback and turns final,
  /// instead of growing from playback (mpv's per-file
  /// `waveform-duration-hint`).
  ///
  /// The waveform lays out this length. A hint a little off still ends
  /// final: a shorter one leaves the rest of the stream out, a longer one
  /// leaves the bins after the end of the stream unfilled. Any other
  /// source ignores it for the analysis.
  ///
  /// It is also [PlaybackState.duration] of this entry, whatever its
  /// source, while mpv only has a duration estimated from the bitrate
  /// ([PlaybackState.durationEstimated] is then false). An exact duration
  /// of mpv's always wins. Unlike the other per-entry options it does not
  /// keep the entry from opening ahead with [Player.setPrefetchPlaylist].
  ///
  /// `null` (default) gives none. Must be positive. mpv ignores a hint past
  /// 5,000,000 s.
  final Duration? waveformDurationHint;

  /// Creates an immutable media item for [uri], with optional consumer
  /// [extras], per-request [httpHeaders] and [httpChunkSize], per-entry
  /// [streamLavfOptions] and [demuxerLavfOptions], the [start] and [end] of
  /// what it plays, and the [waveformDurationHint] of a stream without a
  /// length.
  const Media(
    this.uri, {
    this.extras,
    this.httpHeaders,
    this.httpChunkSize,
    this.streamLavfOptions,
    this.demuxerLavfOptions,
    this.start,
    this.end,
    this.waveformDurationHint,
  });

  /// A media item for a file the user picked in the browser: [blob], a
  /// `File` or `Blob` of the page, as an `<input type="file">`, a drop or
  /// `showDirectoryPicker` give it. The file can sit on a network share
  /// the system has mounted (an SMB or NFS folder): the browser reads it
  /// through the system, on demand, as it plays and seeks.
  ///
  /// The media plays a `blob:` URL the page makes for the file, valid
  /// until the page closes; a `File` from disk stays on disk meanwhile.
  /// [extras] gets the file's name as `title` unless it has one, for the
  /// media session and the playlist UI. [start] and [end] are those of
  /// [Media.new].
  ///
  /// On the web only: elsewhere it throws [UnsupportedError], and a file
  /// opens by its path. Throws [ArgumentError] when [blob] is not a `File`
  /// or `Blob`. A `blob:` URL the app already has (the `path` of an
  /// `XFile` of file_selector on the web) plays as `Media(url)` too.
  factory Media.fromBlob(
    Object blob, {
    Map<String, Object?>? extras,
    Duration? start,
    Duration? end,
  }) {
    final (url, name) = blobUrl(blob);
    final titled = name == null || (extras?.containsKey('title') ?? false)
        ? extras
        : Map<String, Object?>.unmodifiable({'title': name, ...?extras});
    return Media(url, extras: titled, start: start, end: end);
  }

  /// Whether this media is a live PCM input made by `PcmSource.toMedia`
  /// (a `mak-pcm://` URI): read once, not seekable, of a length not known
  /// in advance.
  bool get isPcmStream => uri.startsWith('mak-pcm://');

  /// Returns a copy with the given fields replaced. Pass `null` for
  /// [extras], [httpHeaders], [httpChunkSize], [streamLavfOptions],
  /// [demuxerLavfOptions], [start], [end] or [waveformDurationHint] to
  /// clear them; omitted fields keep their current value.
  Media copyWith({
    String? uri,
    Object? extras = unset,
    Object? httpHeaders = unset,
    Object? httpChunkSize = unset,
    Object? streamLavfOptions = unset,
    Object? demuxerLavfOptions = unset,
    Object? start = unset,
    Object? end = unset,
    Object? waveformDurationHint = unset,
  }) => Media(
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
    streamLavfOptions: identical(streamLavfOptions, unset)
        ? this.streamLavfOptions
        : streamLavfOptions as Map<String, String>?,
    demuxerLavfOptions: identical(demuxerLavfOptions, unset)
        ? this.demuxerLavfOptions
        : demuxerLavfOptions as Map<String, String>?,
    start: identical(start, unset) ? this.start : start as Duration?,
    end: identical(end, unset) ? this.end : end as Duration?,
    waveformDurationHint: identical(waveformDurationHint, unset)
        ? this.waveformDurationHint
        : waveformDurationHint as Duration?,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Media &&
          other.uri == uri &&
          other.httpChunkSize == httpChunkSize &&
          other.start == start &&
          other.end == end &&
          other.waveformDurationHint == waveformDurationHint &&
          mapEq(extras, other.extras) &&
          mapEq(httpHeaders, other.httpHeaders) &&
          mapEq(streamLavfOptions, other.streamLavfOptions) &&
          mapEq(demuxerLavfOptions, other.demuxerLavfOptions));

  @override
  int get hashCode => Object.hash(
    uri,
    httpChunkSize,
    start,
    end,
    waveformDurationHint,
    mapHash(extras),
    mapHash(httpHeaders),
    mapHash(demuxerLavfOptions),
    mapHash(streamLavfOptions),
  );

  /// Prints the names of [httpHeaders], [streamLavfOptions] and
  /// [demuxerLavfOptions] only, and the [uri] without its user info and
  /// with the names of its query only, as any value of [extras] that is a
  /// URL: they often carry credentials (an `Authorization` token, a proxy
  /// password, a `decryption_key`, the `api_key` of a music server) that
  /// must not reach a log.
  @override
  String toString() {
    String? names(Map<String, String>? map) => map == null
        ? null
        : '{${map.keys.map((k) => '$k: <redacted>').join(', ')}}';
    Object? printed(Object? value) => switch (value) {
      Uri() => redactUrl(value.toString()),
      String() when _hasAuthority.hasMatch(value) => redactUrl(value),
      _ => value,
    };
    final extras = this.extras;
    final shownExtras = extras == null
        ? null
        : '{${extras.entries.map((e) => '${e.key}: ${printed(e.value)}').join(', ')}}';
    return 'Media(uri: ${redactUrl(uri)}, extras: $shownExtras, '
        'httpHeaders: ${names(httpHeaders)}, httpChunkSize: $httpChunkSize, '
        'streamLavfOptions: ${names(streamLavfOptions)}, '
        'demuxerLavfOptions: ${names(demuxerLavfOptions)}, start: $start, '
        'end: $end, waveformDurationHint: $waveformDurationHint)';
  }
}

final RegExp _userInfo = RegExp(r'^([A-Za-z][A-Za-z0-9+.-]*://)[^/?#]*@');

/// [uri] with the user info of its authority, a name and often a
/// password, replaced by `<redacted>`, for a log. Anything else is kept.
@internal
String redactUserInfo(String uri) =>
    uri.replaceFirstMapped(_userInfo, (m) => '${m[1]}<redacted>@');

final RegExp _scheme = RegExp(r'^[A-Za-z][A-Za-z0-9+.-]*:');
final RegExp _hasAuthority = RegExp(r'^[A-Za-z][A-Za-z0-9+.-]*://');

/// [uri] for a log: without the user info of its authority, as
/// [redactUserInfo] gives it, and with each value of its query replaced
/// by `<redacted>`. The names of the query stay, since they tell what
/// the URL asks for, and the values are where a music server's
/// credentials sit (`api_key`, `X-Plex-Token`, Subsonic's `u`, `t` and
/// `s`). A string with no scheme, a path, is kept as it is.
@internal
String redactUrl(String uri) {
  final url = redactUserInfo(uri);
  final query = url.indexOf('?') + 1;
  if (query == 0 || !_scheme.hasMatch(url)) return url;
  final fragment = url.indexOf('#', query);
  final end = fragment < 0 ? url.length : fragment;
  final redacted = url
      .substring(query, end)
      .split('&')
      .map((pair) {
        final equals = pair.indexOf('=');
        return equals < 0 ? pair : '${pair.substring(0, equals)}=<redacted>';
      })
      .join('&');
  return '${url.substring(0, query)}$redacted${url.substring(end)}';
}
