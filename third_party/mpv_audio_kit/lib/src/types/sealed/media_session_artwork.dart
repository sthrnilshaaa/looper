// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import '../../models/cover_art.dart';
import '../../models/media.dart';

/// Artwork shown on the OS media session (lockscreen, Control Center,
/// SMTC, MPRIS). Set via [MediaSession.artwork].
///
/// - [MediaSessionArtwork.embedded] (default): the picture embedded in
///   the playing file, exposed by [PlayerStream.coverArt].
/// - [MediaSessionArtwork.custom]: a specific image you supply, ignoring
///   the file's embedded cover.
/// - [MediaSessionArtwork.uri]: an image at a URL, for streams whose file
///   carries no embedded cover (for example a transcoded server track).
///   The package loads the image (see the schemes below), and only the
///   image reaches the OS.
/// - [MediaSessionArtwork.none]: no artwork. The OS shows its own
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

  /// Show the image at [uri], ignoring any embedded cover. The URL never
  /// reaches the OS, since cover URLs often carry credentials: the package
  /// loads the image and hands the native side the bytes. It skips an
  /// image over 20 MB.
  ///
  /// [uri] must load without custom headers:
  /// - an `http(s)://` URL (a tokenised query string is fine) or a
  ///   `file://` path, on every platform;
  /// - an `asset://` one from the app's bundle, on every platform: write
  ///   `asset:///` and the key, since a [Uri] lowers the case of what
  ///   follows two slashes;
  /// - a `content://` or `android.resource://` one on Android, read
  ///   through the ContentResolver: an image (PNG, JPEG, GIF, WebP, BMP,
  ///   HEIF or AVIF), not a song, a vector or an adaptive icon;
  /// - a `blob:` one of the page on the web.
  ///
  /// Any other scheme shows no artwork. For art behind custom headers,
  /// fetch the bytes yourself and use [MediaSessionArtwork.custom].
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

/// The [MediaSessionArtwork.uri] variant: the image at a URL, which the
/// package loads (see [MediaSessionArtwork.uri] for the schemes).
final class MediaSessionArtworkUri extends MediaSessionArtwork {
  /// The artwork location, in a scheme [MediaSessionArtwork.uri] loads.
  final Uri uri;

  const MediaSessionArtworkUri._(this.uri) : super._();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MediaSessionArtworkUri && other.uri == uri;

  @override
  int get hashCode => Object.hash(MediaSessionArtworkUri, uri);

  /// Prints [uri] without its user info and with the names of its query
  /// only: a cover URL often carries credentials.
  @override
  String toString() => 'MediaSessionArtwork.uri(${redactUrl(uri.toString())})';
}
