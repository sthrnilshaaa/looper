// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.
//
// The host side of uri_resolver.dart in the browser. http and https go to
// the web module as they are (it reads them through fetch). A `blob:` URL
// of the page (a file the user picked, `Media.fromBlob`) becomes the
// module's `makblob://` scheme, which reads the Blob with its seeks; an
// `asset://` becomes the URL of the asset on the page's origin, absolute,
// since the module's workers resolve a relative URL against their own
// script.

import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'uri_resolver.dart' show ResolvedUri;

@JS('URL')
extension type _Url._(JSObject _) implements JSObject {
  external _Url(String url, String base);
  external String get href;
}

@JS('document.baseURI')
external String get _baseUri;

/// Whether local paths are Windows paths: never in the browser, whose
/// module has a POSIX file system of its own.
bool get hostIsWindows => false;

/// Resolves a [uri] that is no `file://` URL.
Future<ResolvedUri> resolveHostUri(String uri) async =>
    ResolvedUri(webModuleUri(uri));

/// The name [resolveHostUri] gives mpv for [uri].
Future<String> hostLoadedName(String uri) async => webModuleUri(uri);

/// [uri] as the web module opens it.
String webModuleUri(String uri) {
  if (uri.startsWith('blob:')) return 'makblob://${uri.substring(5)}';
  if (uri.startsWith('asset://')) {
    final path = uri.substring('asset://'.length);
    final key = path.startsWith('/') ? path.substring(1) : path;
    return _Url(ui_web.assetManager.getAssetUrl(key), _baseUri).href;
  }
  return uri;
}
