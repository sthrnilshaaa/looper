// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.
//
// Internal URI normalizer invoked by `Player.open()`, `Player.openAll()`,
// `Player.openPlaylistFile()`, `Player.add()`, `Player.replace()` and
// `Player.addAudioTrack()` for every media URI before it reaches mpv.
// Translates host-platform schemes that libmpv does not understand into
// something it does:
//
//   asset://path/inside/bundle  → <temp>/mpv_audio_kit_assets_<app>/mpv_asset_<hash>_<safe_name>
//   content://...               → fd://<n>                     (Android only)
//   file:///path/a%20b.flac     → /path/a b.flac
//
// `file://` URIs become the path mpv itself would store for them, so the
// playlist entries mpv reports match the Media cache keys. All other URIs
// (`http(s)://`, `smb2://`, plain filesystem paths, …) pass through
// unchanged. In the browser (uri_resolver_web.dart):
//
//   blob:<url of the page>      → makblob://<url of the page>
//   asset://path/inside/bundle  → the asset's absolute URL on the page's origin

import 'dart:convert';

import 'package:meta/meta.dart';

import '../events/player_exception.dart';
import 'uri_resolver_io.dart'
    if (dart.library.js_interop) 'uri_resolver_web.dart';

export 'uri_resolver_io.dart'
    if (dart.library.js_interop) 'uri_resolver_web.dart'
    show hostIsWindows;

/// Resolution result for a URI passed through [resolveUri].
///
/// Carries the libmpv-loadable [uri] plus an optional [dispose] callback
/// that releases what the resolution allocated. For Android `content://`
/// URIs the call detaches a file descriptor from the JVM side, and mpv
/// never closes an `fd://` descriptor (it reads it again on every open of
/// the entry). The player holds it while the entry is in the playlist and
/// calls [dispose] afterwards, at dispose, or at once when the load is
/// aborted before mpv gets the URI.
///
/// For URIs that don't allocate platform resources (asset://, plain
/// paths, network URLs) [dispose] is `null`.
class ResolvedUri {
  /// Wraps a libmpv-loadable [uri] with an optional [dispose] callback
  /// that releases any platform resources the resolution allocated.
  const ResolvedUri(this.uri, [this.dispose]);

  /// The URI as libmpv accepts it (`fd://N`, an absolute filesystem
  /// path, or the original string for pass-through schemes).
  final String uri;

  /// Releases any platform resources allocated by the resolution.
  /// `null` when the resolution allocated nothing.
  final Future<void> Function()? dispose;
}

/// Test-only: replaces [resolveUri] for every load, so a test can stand in
/// for a source that holds a platform resource (an Android `content://`
/// descriptor) on any host, and count its releases.
@visibleForTesting
Future<ResolvedUri> Function(String uri)? debugResolveUriOverride;

/// Resolves [uri] for libmpv and returns a [ResolvedUri] whose
/// [ResolvedUri.dispose] callback must be invoked if the result is
/// never passed to `loadfile`.
///
/// Throws a [SourceException] when an `asset://` cannot be copied out of
/// the bundle, or an Android `content://` URI cannot be resolved to an
/// open file descriptor, so the failure surfaces at the `Player.open()`
/// call site rather than as a URI mpv cannot open.
Future<ResolvedUri> resolveUri(String uri) async {
  final override = debugResolveUriOverride;
  if (override != null) return override(uri);
  final path = fileUrlToPath(uri);
  if (path != null) return ResolvedUri(path);
  return resolveHostUri(uri);
}

/// The name [resolveUri] gives mpv for [uri], worked out without loading
/// or copying anything: the path of a `file://` URL or of an `asset://`
/// copy, or [uri] itself. mpv keys a resume point by that name. An
/// Android `content://` URI gets a new descriptor at each load, so it
/// has no name to give and comes back as it is.
Future<String> loadedName(String uri) async {
  final path = fileUrlToPath(uri);
  if (path != null) return path;
  return hostLoadedName(uri);
}

/// Whether mpv reads [uri] from an open descriptor (`fd://N`, as an
/// Android `content://` URI loads, or `fdclose://N`).
bool isFdUri(String uri) =>
    uri.startsWith('fd://') || uri.startsWith('fdclose://');

/// The path mpv stores for a `file://` [uri], or `null` for any other URI.
///
/// Mirrors mpv's `mp_file_url_to_filename`, which every `loadfile` goes
/// through: the scheme is dropped whatever its case, `%NN` escapes are
/// decoded byte by byte (a malformed one is kept as it is), and on Windows
/// `/C:/` becomes `C:/`. The playlist then names the entry by this path,
/// not by the URL it was loaded with. Escapes that are not UTF-8 (a
/// Latin-1 file name) give `null`: a Dart string cannot carry those bytes,
/// so the URL goes to mpv as it is and mpv decodes it.
///
/// A host is read as RFC 8089 reads it, where mpv would keep it as the
/// start of a relative path. `localhost` is dropped. On Windows any other
/// host names a share, `\\host\share\...`, as `Uri.file` writes one; so
/// does `localhost` when no drive letter follows it. Elsewhere another host
/// stays in the path, as in mpv. A drive right after the scheme
/// (`file://C:/...`) is a drive, not a host: mpv opens it as `C:/...`.
String? fileUrlToPath(String uri, {bool? windows}) {
  if (uri.length < 7 || uri.substring(0, 7).toLowerCase() != 'file://') {
    return null;
  }
  final isWindows = windows ?? hostIsWindows;
  final (raw, share) = _fileUrlHost(uri.substring(7), isWindows: isWindows);
  final bytes = _percentDecode(utf8.encode(raw));
  String path;
  try {
    path = utf8.decode(bytes);
  } on FormatException {
    return null;
  }
  if (share) return r'\\' + path.replaceAll('/', r'\');
  if (isWindows && path.length > 2 && path[0] == '/' && path[2] == ':') {
    path = path.substring(1);
  }
  return path;
}

// The part of a `file://` URL after the scheme, [raw], without its host
// when that is `localhost`, and whether it names a Windows share: a host
// other than `localhost` on Windows, or `localhost` before no drive.
(String, bool) _fileUrlHost(String raw, {required bool isWindows}) {
  final slash = raw.indexOf('/');
  if (slash <= 0 || _isDrive(raw.substring(0, slash))) return (raw, false);
  final local = raw.substring(0, slash).toLowerCase() == 'localhost';
  final drive = raw.length > slash + 2 && raw[slash + 2] == ':';
  if (isWindows && !(local && drive)) return (raw, true);
  return (local ? raw.substring(slash) : raw, false);
}

// [src] with each `%` and two hex digits turned into the byte they name;
// a `%` without two hex digits stays as it is.
List<int> _percentDecode(List<int> src) {
  final out = <int>[];
  for (var i = 0; i < src.length;) {
    if (src[i] != 0x25 || i + 2 >= src.length) {
      out.add(src[i++]);
      continue;
    }
    final hi = _hexDigit(src[i + 1]);
    final lo = _hexDigit(src[i + 2]);
    if (hi >= 0 && lo >= 0) {
      out.add(hi * 16 + lo);
    } else {
      out.addAll(src.sublist(i, i + 3));
    }
    i += 3;
  }
  return out;
}

// A drive letter and ':', as in `C:`: no host is written that way.
bool _isDrive(String s) =>
    s.length == 2 &&
    s[1] == ':' &&
    ((s.codeUnitAt(0) | 0x20) >= 0x61 && (s.codeUnitAt(0) | 0x20) <= 0x7a);

int _hexDigit(int c) {
  if (c >= 0x30 && c <= 0x39) return c - 0x30;
  if (c >= 0x41 && c <= 0x46) return c - 0x41 + 10;
  if (c >= 0x61 && c <= 0x66) return c - 0x61 + 10;
  return -1;
}
