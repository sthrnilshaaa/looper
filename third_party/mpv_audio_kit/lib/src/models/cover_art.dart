// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:flutter/widgets.dart';

/// Cover-art payload extracted from the currently loaded file.
///
/// [bytes] holds the original codec data (PNG / JPEG / WEBP / BMP /
/// GIF) exactly as it was embedded in the audio file's attached
/// picture stream — no re-encoding, no thumbnail generation.
///
/// Drop directly into a Flutter `Image` widget via [image]:
///
/// ```dart
/// Image(image: art.image, fit: BoxFit.cover)
/// ```
///
/// Equality follows reference identity: two [CoverArt] instances with
/// the same byte content compare unequal because [Uint8List] itself
/// does not implement value equality. Use the bytes directly for image
/// cache keys.
class CoverArt {
  /// Creates a cover-art payload from raw image [bytes] and their [mimeType].
  const CoverArt({required this.bytes, required this.mimeType});

  /// The raw file content (e.g. PNG bytes starting with `\x89PNG`).
  final Uint8List bytes;

  /// MIME type — `image/png`, `image/jpeg`, `image/webp`, `image/bmp`,
  /// or `image/gif`.
  final String mimeType;

  /// A Flutter [ImageProvider] backed by [bytes]. Pass straight to
  /// `Image(image: …)`.
  ImageProvider get image => MemoryImage(bytes);

  /// File extension matching [mimeType] — `png`, `jpg`, `webp`, `bmp`,
  /// `gif`, or empty if the MIME type is unknown.
  ///
  /// Useful for saving the cover to disk:
  /// ```dart
  /// File('cover.${art.extension}').writeAsBytes(art.bytes);
  /// ```
  String get extension => switch (mimeType) {
        'image/png' => 'png',
        'image/jpeg' => 'jpg',
        'image/webp' => 'webp',
        'image/bmp' => 'bmp',
        'image/gif' => 'gif',
        _ => '',
      };

  /// Whether [mimeType] is `image/png`.
  bool get isPng => mimeType == 'image/png';

  /// Whether [mimeType] is `image/jpeg`.
  bool get isJpeg => mimeType == 'image/jpeg';

  /// Whether [mimeType] is `image/webp`.
  bool get isWebp => mimeType == 'image/webp';

  /// Whether [mimeType] is `image/bmp`.
  bool get isBmp => mimeType == 'image/bmp';

  /// Whether [mimeType] is `image/gif`.
  bool get isGif => mimeType == 'image/gif';
}
