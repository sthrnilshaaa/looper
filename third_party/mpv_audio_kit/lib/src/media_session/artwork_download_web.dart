// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

// The artwork download of artwork_fetcher.dart in the browser: a fetch,
// which reads only what CORS allows. A URL it cannot read reaches the
// browser's media session as it is (media_session_controller.dart), and the
// browser loads it as an image.

import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

import 'package:meta/meta.dart';

import '../models/cover_art.dart';
import 'artwork_cancel.dart';
import 'artwork_sources.dart';

const Duration _timeout = Duration(seconds: 15);

@JS('fetch')
external JSPromise<_Response> _fetch(String url, JSObject init);

@JS('AbortController')
extension type _AbortController._(JSObject _) implements JSObject {
  external _AbortController();
  external JSObject get signal;
  external void abort();
}

extension type _Response._(JSObject _) implements JSObject {
  external bool get ok;
  external JSObject get headers;
  external _Body? get body;
}

extension type _Body._(JSObject _) implements JSObject {
  external _Reader getReader();
}

extension type _Reader._(JSObject _) implements JSObject {
  external JSPromise<_Chunk> read();
  external JSPromise<JSAny?> cancel();
}

extension type _Chunk._(JSObject _) implements JSObject {
  external bool get done;
  external JSUint8Array? get value;
}

/// Default `ArtworkFetcher` in the browser: fetches an `http(s)://` URL
/// with CORS, without credentials, or a `blob:` one of the page, and
/// returns the image with the MIME type the server gives; `null` for a URL
/// the page cannot read (no CORS, a network error, an error status), for a
/// `file://` URL (no file system), and past 20 MB. [caFiles] has no meaning
/// there: the browser verifies certificates.
///
/// The fetch is aborted when the download ends any other way than with
/// the image: no answer within 15 s, a body that takes longer than that,
/// or one past 20 MB, which is not read to its end. A [cancel] that fires
/// aborts it too.
@internal
Future<CoverArt?> downloadArtwork(
  Uri uri, [
  List<String> caFiles = const [],
  ArtworkCancel? cancel,
]) async {
  if (uri.scheme != 'http' && uri.scheme != 'https' && uri.scheme != 'blob') {
    return null;
  }
  if (cancel?.isCancelled ?? false) return null;
  // Aborting it rejects the fetch and the read in flight, which end the
  // download below with `null`: all that stopping it from outside takes.
  final abort = _AbortController();
  unawaited(cancel?.whenCancelled.then((_) => abort.abort()));
  try {
    final init = JSObject()
      ..['mode'] = 'cors'.toJS
      ..['credentials'] = 'omit'.toJS
      ..['signal'] = abort.signal;
    final response = await _fetch(
      uri.toString(),
      init,
    ).toDart.timeout(_timeout);
    if (!response.ok) return null;
    final length = int.tryParse(_header(response, 'content-length') ?? '');
    if (length != null && length > maxArtworkBytes) return null;
    final bytes = await _readBody(response);
    if (bytes == null || bytes.isEmpty) return null;
    final type = _header(response, 'content-type') ?? '';
    return CoverArt(bytes: bytes, mimeType: type.split(';').first.trim());
  } catch (_) {
    return null;
  } finally {
    // Nothing to stop after a whole body; otherwise the connection.
    abort.abort();
  }
}

/// The body of [response], read chunk by chunk within [_timeout]: `null`
/// for a response without one and past [maxArtworkBytes], where the rest
/// is cancelled instead of read. A server that sends no content-length
/// (a chunked body) is bounded here.
Future<Uint8List?> _readBody(_Response response) async {
  final reader = response.body?.getReader();
  if (reader == null) return null;
  final bytes = BytesBuilder(copy: false);
  final clock = Stopwatch()..start();
  var whole = false;
  try {
    while (true) {
      final left = _timeout - clock.elapsed;
      if (left <= Duration.zero) return null;
      final chunk = await reader.read().toDart.timeout(left);
      if (chunk.done) {
        whole = true;
        return bytes.takeBytes();
      }
      final value = chunk.value;
      if (value == null) continue;
      bytes.add(value.toDart);
      if (bytes.length > maxArtworkBytes) return null;
    }
  } finally {
    if (!whole) reader.cancel().toDart.ignore();
  }
}

/// Default `ArtworkFetcher` in the browser: an `asset://` [url] from the
/// app's bundle, as the app wrote it; the rest through [downloadArtwork],
/// which [cancel] stops.
@internal
Future<CoverArt?> loadArtwork(
  String url, [
  List<String> caFiles = const [],
  ArtworkCancel? cancel,
]) async {
  if (artworkScheme(url) == 'asset') return readArtworkAsset(url);
  final uri = Uri.tryParse(url);
  return uri == null ? null : downloadArtwork(uri, caFiles, cancel);
}

String? _header(_Response response, String name) {
  final value = response.headers.callMethod<JSString?>('get'.toJS, name.toJS);
  return value?.toDart;
}
