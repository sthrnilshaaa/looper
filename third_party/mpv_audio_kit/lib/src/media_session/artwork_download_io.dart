// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

// The artwork download of artwork_fetcher.dart on dart:io platforms.

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/cover_art.dart';
import 'artwork_cancel.dart';
import 'artwork_fetcher.dart' show ArtworkFetcher, downloadsArtworkOn;
import 'artwork_sources.dart';

/// The plugin's channel that reads a `content://` cover on Android, on a
/// queue of its own (ArtworkChannel.kt).
const MethodChannel _channel = MethodChannel('mpv_audio_kit/artwork');

const Duration _timeout = Duration(seconds: 15);

/// Redirects followed before giving up, as many as [HttpClient] follows.
const int _maxRedirects = 5;

/// Default [ArtworkFetcher] where [downloadsArtworkOn] holds. It always
/// verifies the certificate, whatever the player's `tls-verify`: a cover
/// URL often carries the server's credentials. Each of [caFiles] adds to
/// the system roots, so a self-hosted server with its own CA or a
/// self-signed certificate shows its covers. Redirects are
/// followed by hand, so one from `https` to plain `http` is refused before
/// anything is sent over it. A response that announces more than 20 MB is
/// dropped before its body is read.
///
/// A `file://` URL is read from disk instead, with the same 20 MB limit,
/// and its MIME type comes from the extension.
///
/// A [cancel] that fires closes the connection, whatever the download was
/// waiting for, and the result is `null`. The timeouts here are between
/// two steps (the connection, the headers, a piece of the body): the limit
/// on the whole download is the one of whoever holds [cancel]
/// (ArtworkLoader).
@internal
Future<CoverArt?> downloadArtwork(
  Uri uri, [
  List<String> caFiles = const [],
  ArtworkCancel? cancel,
]) async {
  if (cancel?.isCancelled ?? false) return null;
  if (uri.scheme == 'file') return _readArtworkFile(uri);
  if (uri.scheme != 'http' && uri.scheme != 'https') return null;
  HttpClient? client;
  try {
    if (caFiles.isEmpty) {
      client = HttpClient();
    } else {
      final context = SecurityContext(withTrustedRoots: true);
      for (final file in caFiles) {
        context.setTrustedCertificates(file);
      }
      client = HttpClient(context: context);
    }
    client.connectionTimeout = _timeout;
    final connection = client;
    // What awaits the connection then fails, and the catch ends the load.
    unawaited(cancel?.whenCancelled.then((_) => connection.close(force: true)));
    final response = await _getFollowing(client, uri);
    if (response == null) return null;
    final cover = await _readArtworkBody(response);
    // A body cut short by the close is no cover.
    return (cancel?.isCancelled ?? false) ? null : cover;
  } catch (_) {
    return null;
  } finally {
    client?.close(force: true);
  }
}

/// The response to a GET of [uri] once its redirects are followed;
/// `null` past [_maxRedirects] hops, at a redirect without a location, or
/// at one from https down to another scheme.
Future<HttpClientResponse?> _getFollowing(HttpClient client, Uri uri) async {
  var target = uri;
  var response = await _get(client, target);
  for (var hops = 0; response.isRedirect; hops++) {
    final location = response.headers.value(HttpHeaders.locationHeader);
    await response.drain<void>();
    if (location == null || hops == _maxRedirects) return null;
    final next = target.resolve(location);
    if (target.scheme == 'https' && next.scheme != 'https') return null;
    target = next;
    response = await _get(client, target);
  }
  return response;
}

/// The picture [response] carries; `null` when it is no 200, is empty,
/// or holds more than [maxArtworkBytes].
Future<CoverArt?> _readArtworkBody(HttpClientResponse response) async {
  // Not drained: the forced close of the client drops the connection.
  if (response.statusCode != HttpStatus.ok ||
      response.contentLength > maxArtworkBytes) {
    return null;
  }
  final bytes = BytesBuilder(copy: false);
  await for (final chunk in response.timeout(_timeout)) {
    bytes.add(chunk);
    if (bytes.length > maxArtworkBytes) return null;
  }
  if (bytes.isEmpty) return null;
  return CoverArt(
    bytes: bytes.takeBytes(),
    mimeType: response.headers.contentType?.mimeType ?? '',
  );
}

Future<HttpClientResponse> _get(HttpClient client, Uri uri) async {
  final request = await client.getUrl(uri).timeout(_timeout);
  request.followRedirects = false;
  return request.close().timeout(_timeout);
}

Future<CoverArt?> _readArtworkFile(Uri uri) async {
  try {
    final file = File.fromUri(uri);
    final length = await file.length();
    if (length == 0 || length > maxArtworkBytes) return null;
    final bytes = await file.readAsBytes();
    // The file may have changed since its length was read.
    if (bytes.isEmpty || bytes.length > maxArtworkBytes) return null;
    return CoverArt(bytes: bytes, mimeType: artworkMimeType(uri.path));
  } catch (_) {
    return null;
  }
}

/// Default [ArtworkFetcher] where [downloadsArtworkOn] holds: an
/// `asset://` [url] from the app's bundle and, on Android, a `content://`
/// or `android.resource://` one through the ContentResolver, as the app
/// wrote it; the rest through [downloadArtwork], which [cancel] stops.
@internal
Future<CoverArt?> loadArtwork(
  String url, [
  List<String> caFiles = const [],
  ArtworkCancel? cancel,
]) async {
  switch (artworkScheme(url)) {
    case 'asset':
      return readArtworkAsset(url);
    case 'content' || 'android.resource':
      return defaultTargetPlatform == TargetPlatform.android
          ? _readArtworkContent(url)
          : null;
  }
  final uri = Uri.tryParse(url);
  return uri == null ? null : downloadArtwork(uri, caFiles, cancel);
}

/// A provider that never answers gives up like an HTTP server does.
Future<CoverArt?> _readArtworkContent(String url) async {
  try {
    final read = await _channel
        .invokeMapMethod<String, Object?>('readArtwork', {
          'uri': url,
          'maxBytes': maxArtworkBytes,
        })
        .timeout(_timeout);
    final bytes = read?['bytes'];
    if (bytes is! Uint8List || bytes.isEmpty) return null;
    if (bytes.length > maxArtworkBytes) return null;
    final type = read?['mimeType'];
    return CoverArt(
      bytes: bytes,
      mimeType: type is String && type.isNotEmpty
          ? type
          : artworkMimeType(Uri.tryParse(url)?.path ?? ''),
    );
  } catch (_) {
    return null;
  }
}
