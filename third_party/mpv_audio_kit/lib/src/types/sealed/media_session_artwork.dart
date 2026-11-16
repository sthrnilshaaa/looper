// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import '../../models/cover_art.dart';

/// Artwork shown on the OS media session (lockscreen, Control Center,
/// SMTC, MPRIS). Set via [MediaSession.artwork].
///
/// - [MediaSessionArtwork.embedded] (default): the picture embedded in
///   the playing file, exposed by [PlayerStream.coverArt].
/// - [MediaSessionArtwork.custom]: a specific image you supply, ignoring
///   the file's embedded cover.
/// - [MediaSessionArtwork.uri]: a remote / file URL the OS fetches
///   itself — for streams whose file carries no embedded cover (e.g. a
///   transcoded server track). Cheaper than [MediaSessionArtwork.custom]:
///   only the URL crosses the platform channel, not the decoded bytes.
/// - [MediaSessionArtwork.none]: no artwork — the OS shows its own
///   placeholder (typically the app icon).
sealed class MediaSessionArtwork {
  const MediaSessionArtwork._();

  /// Use the picture embedded in the playing file. Default.
  static const MediaSessionArtwork embedded = MediaSessionArtworkEmbedded._();

  /// Show no artwork.
  static const MediaSessionArtwork none = MediaSessionArtworkNone._();

  /// Show [cover], ignoring any cover embedded in the file.
  const factory MediaSessionArtwork.custom(CoverArt cover) =
      MediaSessionArtworkCustom._;

  /// Show the image at [uri], ignoring any embedded cover. The URL itself
  /// never reaches the OS, since cover URLs often carry credentials: on
  /// Android, Windows and Linux the package downloads an `http(s)://` URL
  /// and hands the native side the bytes, and the Apple plugin loads it
  /// with `URLSession` and publishes only the image.
  ///
  /// [uri] must be self-resolvable by the OS: an `http(s)://` URL that
  /// needs no custom auth headers (a tokenised query string is fine), or a
  /// `file://` path. For art behind custom headers, fetch the bytes
  /// yourself and use [MediaSessionArtwork.custom].
  const factory MediaSessionArtwork.uri(Uri uri) = MediaSessionArtworkUri._;
}

/// The [MediaSessionArtwork.embedded] variant: artwork from the playing
/// file's embedded cover.
final class MediaSessionArtworkEmbedded extends MediaSessionArtwork {
  const MediaSessionArtworkEmbedded._() : super._();

  @override
  String toString() => 'MediaSessionArtwork.embedded';
}

/// The [MediaSessionArtwork.none] variant: show no artwork.
final class MediaSessionArtworkNone extends MediaSessionArtwork {
  const MediaSessionArtworkNone._() : super._();

  @override
  String toString() => 'MediaSessionArtwork.none';
}

/// The [MediaSessionArtwork.custom] variant: a consumer-supplied [cover].
final class MediaSessionArtworkCustom extends MediaSessionArtwork {
  /// The image to publish.
  final CoverArt cover;

  const MediaSessionArtworkCustom._(this.cover) : super._();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MediaSessionArtworkCustom && other.cover == cover;

  @override
  int get hashCode => Object.hash(MediaSessionArtworkCustom, cover);

  @override
  String toString() => 'MediaSessionArtwork.custom($cover)';
}

/// The [MediaSessionArtwork.uri] variant: a remote / file URL the OS
/// fetches itself.
final class MediaSessionArtworkUri extends MediaSessionArtwork {
  /// The artwork location — an `http(s)://` or `file://` URL.
  final Uri uri;

  const MediaSessionArtworkUri._(this.uri) : super._();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MediaSessionArtworkUri && other.uri == uri;

  @override
  int get hashCode => Object.hash(MediaSessionArtworkUri, uri);

  @override
  String toString() => 'MediaSessionArtwork.uri($uri)';
}
