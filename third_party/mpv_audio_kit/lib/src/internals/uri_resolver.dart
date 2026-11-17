// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.
//
// Internal URI normalizer invoked by `Player.open()` / `Player.openAll()` /
// `Player.add()` / `Player.replace()` for every media URI before it
// reaches `loadfile`. Translates host-platform schemes that libmpv does
// not understand into something it does:
//
//   asset://path/in/bundle → <temp>/mpv_audio_kit_assets_<app>/<hash>_<name>
//   content://...               → fd://<n>                     (Android only)
//   file:///path/a%20b.flac     → /path/a b.flac
//
// `file://` URIs become the path mpv itself would store for them, so the
// playlist entries mpv reports match the Media cache keys. All other URIs
// (`http(s)://`, `smb2://`, plain filesystem paths, …) pass through
// unchanged.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

const MethodChannel _channel = MethodChannel('mpv_audio_kit');
final Map<String, String> _assetCache = {};

// Deduplicates concurrent [resolveUri] calls for the same asset: the
// first caller does the bundle load + file write, concurrent callers
// await the same Future. Without this, two open() calls on the same
// asset could both reach `writeAsBytes` and the second writer could
// truncate the first writer's file mid-flush.
final Map<String, Future<String>> _assetInflight = {};

/// Resolution result for a URI passed through [resolveUri].
///
/// Carries the libmpv-loadable [uri] plus an optional [dispose] callback
/// the caller MUST invoke if the URI is never handed to mpv (e.g. when
/// the caller's `_disposed` flag flips between resolve and `loadfile`).
/// For Android `content://` URIs the call detaches a file descriptor
/// from the JVM side; without disposing on abort the FD is leaked for
/// the process lifetime.
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

/// Resolves [uri] for libmpv and returns a [ResolvedUri] whose
/// [ResolvedUri.dispose] callback must be invoked if the result is
/// never passed to `loadfile`.
///
/// Throws a [StateError] when an Android `content://` URI cannot be
/// resolved to an open file descriptor — letting the failure surface
/// at the `Player.open()` call site rather than silently handing mpv
/// a URI it cannot open. `asset://` failures keep the soft-fallback
/// behaviour: the original URI is returned and mpv emits a typed
/// end-file error if the path does not work either.
Future<ResolvedUri> resolveUri(String uri) async {
  final path = fileUrlToPath(uri);
  if (path != null) return ResolvedUri(path);
  if (uri.startsWith('asset://')) {
    try {
      return ResolvedUri(await _copyAssetToCache(uri));
    } catch (e) {
      debugPrint('mpv_audio_kit: asset resolution failed for $uri: $e');
      return ResolvedUri(uri);
    }
  }
  if (Platform.isAndroid && uri.startsWith('content://')) {
    try {
      final fd =
          await _channel.invokeMethod<int>('openFileDescriptor', {'uri': uri});
      if (fd != null && fd > 0) {
        return ResolvedUri('fd://$fd', () => _closeAndroidFd(fd));
      }
      throw StateError(
        'mpv_audio_kit: content:// resolution returned no file descriptor '
        'for $uri (the ContentResolver may have rejected the URI or the '
        'caller lacks read permission)',
      );
    } on PlatformException catch (e) {
      throw StateError(
        'mpv_audio_kit: content:// resolution failed for $uri '
        '(${e.code}: ${e.message})',
      );
    }
  }
  return ResolvedUri(uri);
}

/// The path mpv stores for a `file://` [uri], or `null` for any other URI.
///
/// Mirrors mpv's `mp_file_url_to_filename`, which every `loadfile` goes
/// through: the scheme is dropped whatever its case, `%NN` escapes are
/// decoded byte by byte (a malformed one is kept as it is), and on Windows
/// `/C:/` becomes `C:/`. The playlist then names the entry by this path,
/// not by the URL it was loaded with.
@visibleForTesting
String? fileUrlToPath(String uri, {bool? windows}) {
  if (uri.length < 7 || uri.substring(0, 7).toLowerCase() != 'file://') {
    return null;
  }
  final src = utf8.encode(uri.substring(7));
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
  var path = utf8.decode(out, allowMalformed: true);
  if ((windows ?? Platform.isWindows) &&
      path.length > 2 &&
      path[0] == '/' &&
      path[2] == ':') {
    path = path.substring(1);
  }
  return path;
}

int _hexDigit(int c) {
  if (c >= 0x30 && c <= 0x39) return c - 0x30;
  if (c >= 0x41 && c <= 0x46) return c - 0x41 + 10;
  if (c >= 0x61 && c <= 0x66) return c - 0x61 + 10;
  return -1;
}

Future<void> _closeAndroidFd(int fd) async {
  try {
    await _channel.invokeMethod<void>('closeFileDescriptor', {'fd': fd});
  } catch (e) {
    debugPrint('mpv_audio_kit: closeFileDescriptor failed for fd=$fd: $e');
  }
}

/// A stable FNV-1a hash of [text] as eight hex digits (deterministic
/// across sessions, unlike String.hashCode).
String _fnv1a(String text) {
  var hash = 0x811c9dc5;
  for (final unit in text.codeUnits) {
    hash = ((hash ^ unit) * 0x01000193) & 0xFFFFFFFF;
  }
  return hash.toRadixString(16).padLeft(8, '0');
}

/// The directory the asset copies go to. One fixed directory and one fixed
/// name per asset: a relaunch overwrites its old copy instead of leaving a
/// new one behind, and a process killed without dispose (the usual end on
/// mobile) leaks nothing that grows. The name carries the user and the app,
/// so two users sharing `/tmp` on Linux, or two apps with an asset of the
/// same name, never meet; on Linux the per-user `XDG_RUNTIME_DIR` is used
/// when there is one.
Future<Directory> _assetDirectory() async {
  final env = Platform.environment;
  final runtime = Platform.isLinux ? env['XDG_RUNTIME_DIR'] : null;
  final owner =
      '${env['USER'] ?? env['USERNAME'] ?? ''}'
      ' ${Platform.resolvedExecutable}';
  final name = 'mpv_audio_kit_assets_${_fnv1a(owner)}';
  if (runtime != null && runtime.isNotEmpty) {
    try {
      final dir = Directory('$runtime${Platform.pathSeparator}$name');
      await dir.create(recursive: true);
      return dir;
    } on FileSystemException {
      // An inherited XDG_RUNTIME_DIR of another user: fall back to temp.
    }
  }
  final dir =
      Directory('${Directory.systemTemp.path}${Platform.pathSeparator}$name');
  await dir.create(recursive: true);
  return dir;
}

Future<String> _copyAssetToCache(String uri) async {
  final cached = _assetCache[uri];
  // Re-check the file on every hit. macOS / Linux may evict /tmp between
  // sessions or under disk pressure; without this guard a cached path
  // outlives its file and `loadfile` fails opaquely. The miss path
  // re-extracts the asset.
  if (cached != null) {
    if (await File(cached).exists()) return cached;
    _assetCache.remove(uri);
  }
  return _assetInflight.putIfAbsent(uri, () => _doCopyAsset(uri));
}

Future<String> _doCopyAsset(String uri) async {
  try {
    // Re-check the cache: a previous in-flight copy for the same URI
    // may have completed between our cache miss and putIfAbsent.
    final cached = _assetCache[uri];
    if (cached != null) return cached;

    String assetPath = uri.substring('asset://'.length);
    if (assetPath.startsWith('/')) {
      assetPath = assetPath.substring(1);
    }

    final data = await rootBundle.load(assetPath);

    // Both POSIX (`/`) and Windows (`\`) separators are flattened so the
    // temp filename never contains directory parts. On POSIX
    // `Platform.pathSeparator` is `/` and the second pass is a no-op.
    final safeName = assetPath
        .replaceAll(Platform.pathSeparator, '_')
        .replaceAll('/', '_');
    // Flattening alone is ambiguous — `a/b.mp3` and `a_b.mp3` collapse to
    // the same name, and the second extraction would overwrite a file mpv
    // may still be streaming. A hash of the ORIGINAL path disambiguates.
    final dir = await _assetDirectory();
    final file = File(
      '${dir.path}${Platform.pathSeparator}'
      'mpv_asset_${_fnv1a(assetPath)}_$safeName',
    );

    // Written beside the target and renamed onto it, so another instance
    // of the app reading the same copy never sees it truncated. Slice the
    // asset's view explicitly: rootBundle bundles can pack multiple assets
    // into one backing buffer, and the no-arg asUint8List would span the
    // full backing buffer rather than just this asset's range.
    final part = File('${file.path}.$pid.part');
    await part.writeAsBytes(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      flush: true,
    );
    try {
      await part.rename(file.path);
    } on FileSystemException {
      // Windows refuses to replace a file another process has open: that
      // instance holds the same asset, so its copy is kept.
      try {
        await part.delete();
      } on FileSystemException {
        // Left behind; the next copy of this asset overwrites it.
      }
      if (!await file.exists()) rethrow;
    }

    _assetCache[uri] = file.path;
    return file.path;
  } finally {
    // `remove` returns the in-flight Future we are currently completing;
    // discard it — awaiting our own pending Future here would deadlock.
    unawaited(_assetInflight.remove(uri));
  }
}
