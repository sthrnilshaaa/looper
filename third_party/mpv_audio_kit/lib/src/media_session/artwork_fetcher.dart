// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import '../models/cover_art.dart';

/// Downloads a remote artwork URL into a [CoverArt]; `null` on any failure.
typedef ArtworkFetcher = Future<CoverArt?> Function(Uri uri);

/// Upper bound on a downloaded cover. Real covers are a few MB at most;
/// anything larger is not an image worth putting on the media session.
const int _maxArtworkBytes = 20 * 1024 * 1024;

const Duration _timeout = Duration(seconds: 15);

/// Whether the media session downloads remote artwork in Dart on
/// [platform], handing the native side bytes instead of the URL. Remote
/// cover URLs often carry credentials in the query (Subsonic `u`, `t` and
/// `s`, Jellyfin `api_key`, Plex `X-Plex-Token`), and these platforms would
/// publish them: MPRIS `mpris:artUrl` on the session bus (Linux), the
/// session metadata other apps with notification access read (Android),
/// the thumbnail source SMTC is given (Windows). The Apple plugin fetches
/// the image itself and publishes only its bytes.
@internal
bool downloadsArtworkOn(TargetPlatform platform) => switch (platform) {
  TargetPlatform.linux ||
  TargetPlatform.android ||
  TargetPlatform.windows => true,
  _ => false,
};

/// Default [ArtworkFetcher] where [downloadsArtworkOn] holds.
@internal
Future<CoverArt?> downloadArtwork(Uri uri) async {
  final client = HttpClient()..connectionTimeout = _timeout;
  try {
    final request = await client.getUrl(uri).timeout(_timeout);
    final response = await request.close().timeout(_timeout);
    if (response.statusCode != HttpStatus.ok) {
      await response.drain<void>();
      return null;
    }
    final bytes = BytesBuilder(copy: false);
    await for (final chunk in response.timeout(_timeout)) {
      bytes.add(chunk);
      if (bytes.length > _maxArtworkBytes) return null;
    }
    if (bytes.isEmpty) return null;
    return CoverArt(
      bytes: bytes.takeBytes(),
      mimeType: response.headers.contentType?.mimeType ?? '',
    );
  } catch (_) {
    return null;
  } finally {
    client.close(force: true);
  }
}
