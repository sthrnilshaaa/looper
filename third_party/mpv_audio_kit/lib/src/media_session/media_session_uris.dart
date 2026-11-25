// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

// The URIs of the media session: which items are local, the `file:` URI
// of a local item as mpv opens it, the artwork URLs the loader fetches and
// the titles mpv derived from a URL. Pure functions, apart from the
// platform the app runs on.

import 'dart:convert';

import 'package:flutter/foundation.dart';

/// Whether [uri] names a local file: a `file:` URI, a plain path, or a
/// Windows drive path (which parses with a one-letter scheme).
@internal
bool isLocalUri(String uri) {
  final scheme = Uri.tryParse(uri)?.scheme ?? '';
  return scheme.isEmpty || scheme == 'file' || scheme.length == 1;
}

/// The local item [uri] as a `file:` URI, percent-encoded from the path
/// mpv opens: a path as it is, a relative one under the working
/// directory. mpv takes all that follows `file://` as the path,
/// percent-decoded, so a `#` or a `?` there is part of the name (and so
/// is a raw space). `null` for a path no URI can name.
@internal
String? fileUri(String uri) {
  final parsed = Uri.tryParse(uri);
  var path = uri;
  if (parsed?.scheme == 'file' || uri.toLowerCase().startsWith('file:')) {
    if (!uri.toLowerCase().startsWith('file:///')) {
      // A host, or no `//`: not a path of this machine as mpv reads it.
      return parsed?.toString();
    }
    final bytes = _unescape(uri.substring('file://'.length));
    path = utf8.decode(bytes, allowMalformed: true);
    // On Windows `/C:/Music` names `C:/Music`, as mpv reads it there.
    // Elsewhere it is the path it looks like, and so is `/a:b`.
    final drive = _onWindows && _drivePath.hasMatch(path);
    if (drive) path = path.substring(1);
    if (!_isUtf8(bytes)) {
      // A name that is not UTF-8 (Latin-1): no string holds its bytes,
      // so the URI is written from them. The string stands in for the
      // name where a path no URI can name is told.
      if (_pathUri(path) == null) return null;
      return 'file://${_encodePath(bytes, windows: drive)}';
    }
  }
  return _pathUri(path);
}

/// The path [path] as a `file:` URI, a relative one under the working
/// directory. `null` for a path no URI can name.
String? _pathUri(String path) {
  final drive = Uri.tryParse(path)?.scheme.length == 1;
  try {
    return Uri.base
        .resolveUri(Uri.file(path, windows: drive ? true : null))
        .toString();
  } on ArgumentError {
    return null;
  }
}

final RegExp _drivePath = RegExp('^/[A-Za-z]:');

/// Whether paths are read as Windows reads them: the platform the app
/// runs on, or the host whose rules `Uri.file` follows. The two differ
/// under `flutter test`, where the platform is Android on every host
/// while `Uri.file` still takes a backslash for a separator on Windows.
bool get _onWindows =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.windows ||
        Uri.file(r'a\b').pathSegments.length == 2);

/// The bytes of [s] with each `%` and two hex digits decoded, the way
/// mpv decodes a `file:` URI (and `fileUrlToPath` after it). A `%`
/// without them is kept with the two characters after it, so an escape
/// that starts inside those is not one: `%%41` stays as it is.
List<int> _unescape(String s) {
  final src = utf8.encode(s);
  final bytes = <int>[];
  for (var i = 0; i < src.length;) {
    if (src[i] != 0x25 || i + 2 >= src.length) {
      bytes.add(src[i++]);
      continue;
    }
    final hi = _hexDigit(src[i + 1]);
    final lo = _hexDigit(src[i + 2]);
    if (hi >= 0 && lo >= 0) {
      bytes.add(hi * 16 + lo);
    } else {
      bytes.addAll(src.sublist(i, i + 3));
    }
    i += 3;
  }
  return bytes;
}

bool _isUtf8(List<int> bytes) {
  try {
    utf8.decode(bytes);
    return true;
  } on FormatException {
    return false;
  }
}

/// The absolute path [bytes] as the path of a URI: what `Uri.file`
/// leaves as it is stays, every other byte is percent-encoded. On
/// [windows] a backslash separates, as a slash does.
String _encodePath(List<int> bytes, {required bool windows}) {
  const hex = '0123456789ABCDEF';
  final out = StringBuffer();
  for (final byte in bytes) {
    if (windows && byte == 0x5c) {
      out.write('/');
    } else if (byte < 0x80 && _pathBytes.contains(byte)) {
      out.writeCharCode(byte);
    } else {
      out
        ..write('%')
        ..write(hex[byte >> 4])
        ..write(hex[byte & 0xf]);
    }
  }
  return out.toString();
}

// The characters a URI path holds as they are, the ones `Uri.file`
// does not encode.
final Set<int> _pathBytes =
    'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789'
            r"-._~!$&'()*+,;=:@/"
        .codeUnits
        .toSet();

int _hexDigit(int c) {
  if (c >= 0x30 && c <= 0x39) return c - 0x30;
  final letter = c | 0x20;
  return letter >= 0x61 && letter <= 0x66 ? letter - 0x61 + 10 : -1;
}

/// Whether [uri] is an `http(s)://` URL.
@internal
bool isHttpUri(String? uri) {
  if (uri == null) return false;
  final scheme = Uri.tryParse(uri)?.scheme.toLowerCase();
  return scheme == 'http' || scheme == 'https';
}

/// Whether the artwork [uri] goes through the artwork loader: an
/// `http(s)://`, `file://` or `asset://` URL, a `content://` or
/// `android.resource://` one on Android and a `blob:` one in the browser.
/// Any other scheme shows no artwork.
@internal
bool fetchesArtwork(String uri) {
  return switch (Uri.tryParse(uri)?.scheme.toLowerCase()) {
    'http' || 'https' || 'file' || 'asset' => true,
    'content' || 'android.resource' =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android,
    'blob' => kIsWeb,
    _ => false,
  };
}

/// Removes what could be credentials from a title mpv derived from a URL:
/// a trailing `key=value` query or fragment, and the userinfo of a full
/// URL. A real title with a `?` in it ("Who Are You?") has no `=` after
/// it and is left alone. `null` when nothing is left.
@internal
String? redactUrlTitle(String title) {
  var t = title;
  final query = RegExp(r'[?#]\S*$').firstMatch(t);
  if (query != null && query.group(0)!.contains('=')) {
    t = t.substring(0, query.start);
  }
  t = t.replaceFirstMapped(
    RegExp(r'^([a-z][a-z0-9+.-]*://)[^/@\s]*@', caseSensitive: false),
    (m) => m.group(1)!,
  );
  return t.isEmpty ? null : t;
}
