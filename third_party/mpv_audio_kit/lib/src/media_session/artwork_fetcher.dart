// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'package:flutter/foundation.dart';

import '../models/cover_art.dart';

export 'artwork_download_io.dart'
    if (dart.library.js_interop) 'artwork_download_web.dart';

/// Loads an artwork URL into a [CoverArt], trusting the PEM files
/// `caFiles` (the player's `tls-ca-file` and `ca_extra_file`, those set)
/// on top of the system roots; `null` on any failure. The URL comes as the app wrote it:
/// parsing it into a [Uri] would lower the case of an Android authority
/// and of the first part of an `asset://` key.
typedef ArtworkFetcher =
    Future<CoverArt?> Function(String url, List<String> caFiles);

/// Whether the media session loads artwork URLs in Dart on [platform]:
/// it downloads an `http(s)://` one, reads a `file://`, an `asset://` and
/// on Android a `content://` one (loadArtwork), and the native side only
/// ever gets bytes. Remote cover URLs often carry
/// credentials in the query (Subsonic `u`, `t` and `s`, Jellyfin
/// `api_key`, Plex `X-Plex-Token`), and the OS would publish them: MPRIS
/// `mpris:artUrl` on the session bus (Linux), the session metadata other
/// apps with notification access read (Android), the thumbnail source SMTC
/// is given (Windows). Apple's Now Playing takes an image, never a URL.
///
/// In the browser [defaultTargetPlatform] is the one of the device, so the
/// fetch runs there too, with CORS (artwork_download_web.dart).
@internal
bool downloadsArtworkOn(TargetPlatform platform) => switch (platform) {
  TargetPlatform.linux ||
  TargetPlatform.android ||
  TargetPlatform.windows ||
  TargetPlatform.iOS ||
  TargetPlatform.macOS => true,
  // Flutter-OH's TargetPlatform.ohos, which Flutter's enum lacks.
  _ => platform.name == 'ohos',
};

/// Whether an artwork URL the fetcher could not load goes to the media
/// session as it is: in the browser only, which loads it as an image and
/// hands the OS the picture.
@internal
const bool passesArtworkUrl = kIsWeb;
