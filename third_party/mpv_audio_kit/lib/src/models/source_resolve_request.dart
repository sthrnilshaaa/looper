// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'dart:async';

import 'media.dart';

/// Resolves the URL mpv should actually open for a playlist entry, invoked
/// by the library right before each stream open (and once more after a
/// failed open, so an expired URL can be refreshed).
///
/// Return the URL to play, or `null` (or the unchanged
/// [SourceResolveRequest.uri]) to keep the current one. Install with
/// [Player.setSourceResolver].
typedef SourceResolver = FutureOr<String?> Function(
  SourceResolveRequest request,
);

/// The context handed to a [SourceResolver] for one load attempt.
///
/// Carries the original [Media] of the playlist entry being opened — with
/// its [Media.extras] and [Media.httpHeaders] intact — so the resolver can
/// branch on consumer-attached data (a track id, a per-source auth flow)
/// without a separate lookup:
///
/// ```dart
/// player.setSourceResolver((request) async {
///   final id = request.media.extras?['trackId'] as String?;
///   if (id == null) return null;           // not ours — keep the URL
///   return service.getPlaybackUrl(id);     // temporary CDN / token URL
/// });
/// ```
final class SourceResolveRequest {
  /// The playlist entry being opened, as originally passed to
  /// [Player.open] / [Player.openAll] / [Player.add] — [Media.extras]
  /// and [Media.httpHeaders] included. Falls back to a bare
  /// `Media(uri)` when the entry did not come from this player's load
  /// API (e.g. expanded out of a playlist file).
  final Media media;

  /// The URL mpv is about to open (the current `stream-open-filename`).
  /// On a retry this is the URL that just failed, including any rewrite
  /// applied on the initial attempt.
  final String uri;

  /// `false` for the regular pre-open resolution (`on_load`), `true`
  /// when the resolver is re-invoked after a failed open
  /// (`on_load_fail`) — the "URL has expired" case. At most one retry
  /// is attempted per load, and only when the resolver returns a URL
  /// different from [uri].
  final bool isRetry;

  /// Creates the request for one resolution pass. Instances are built
  /// by the library; consumers only read them inside a [SourceResolver].
  const SourceResolveRequest({
    required this.media,
    required this.uri,
    required this.isRetry,
  });

  @override
  String toString() =>
      'SourceResolveRequest(uri: $uri, isRetry: $isRetry, media: $media)';
}
