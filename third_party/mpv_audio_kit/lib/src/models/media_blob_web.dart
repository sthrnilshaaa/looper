// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

// The `Media.fromBlob` side of the web: an object URL of the page for a
// File or Blob, which the web module reads through makblob://
// (internals/uri_resolver_web.dart).

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

@JS('URL.createObjectURL')
external String _createObjectUrl(JSObject blob);

/// A `blob:` URL of the page for [blob], a File or Blob of the browser,
/// and the File's name; throws [ArgumentError] for anything else.
(String, String?) blobUrl(Object blob) {
  final JSObject js;
  try {
    js = blob as JSObject;
  } on TypeError {
    throw ArgumentError.value(blob, 'blob', 'not a File or Blob');
  }
  if (!js.instanceOfString('Blob')) {
    throw ArgumentError.value(blob, 'blob', 'not a File or Blob');
  }
  final name = js['name'];
  return (
    _createObjectUrl(js),
    name.isA<JSString>() ? (name as JSString).toDart : null,
  );
}
