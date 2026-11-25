// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.
//
// The host side of uri_resolver.dart on dart:io platforms: `asset://`
// copies out of the bundle, Android `content://` descriptors.

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../events/player_exception.dart';
import 'debug_log.dart';
import 'uri_resolver.dart' show ResolvedUri;

const MethodChannel _channel = MethodChannel('mpv_audio_kit');
final Map<String, String> _assetCache = {};

// Deduplicates concurrent [resolveUri] calls for the same asset: the
// first caller does the bundle load + file write, concurrent callers
// await the same Future. Without this, two open() calls on the same
// asset could both reach `writeAsBytes` and the second writer could
// truncate the first writer's file mid-flush.
final Map<String, Future<String>> _assetInflight = {};

/// Whether local paths are Windows paths, as mpv takes them on this host.
bool get hostIsWindows => Platform.isWindows;

/// Whether `content://` URIs are resolved through the plugin: on Android.
/// A test turns it on to reach that path on another host.
@visibleForTesting
bool debugResolvesContentUris = Platform.isAndroid;

/// Resolves a [uri] that is no `file://` URL: an `asset://` becomes the
/// path of its copy, an Android `content://` an open descriptor, anything
/// else goes to mpv as it is.
Future<ResolvedUri> resolveHostUri(String uri) async {
  if (uri.startsWith('asset://')) {
    try {
      return ResolvedUri(await _copyAssetToCache(uri));
    } catch (e) {
      throw SourceException(uri, 'the asset could not be loaded: $e');
    }
  }
  if (debugResolvesContentUris && uri.startsWith('content://')) {
    try {
      final fd = await _channel.invokeMethod<int>('openFileDescriptor', {
        'uri': uri,
      });
      if (fd != null && fd > 0) {
        return ResolvedUri('fd://$fd', () => _closeAndroidFd(fd));
      }
      throw SourceException(
        uri,
        'the ContentResolver returned no file descriptor (it may have '
        'rejected the URI, or the app lacks read permission)',
      );
    } on PlatformException catch (e) {
      throw SourceException(uri, '${e.code}: ${e.message}');
    } on MissingPluginException catch (e) {
      // An engine the plugin is not registered with.
      throw SourceException(uri, 'the plugin does not answer: ${e.message}');
    }
  }
  return ResolvedUri(uri);
}

/// The name [resolveHostUri] gives mpv for an `asset://` [uri], without
/// copying it; [uri] itself for the other schemes.
Future<String> hostLoadedName(String uri) async {
  if (uri.startsWith('asset://')) {
    return _assetCache[uri] ?? await _assetCopyPath(_assetKey(uri));
  }
  return uri;
}

Future<void> _closeAndroidFd(int fd) async {
  try {
    await _channel.invokeMethod<void>('closeFileDescriptor', {'fd': fd});
  } catch (e) {
    debugLog('mpv_audio_kit: closeFileDescriptor failed for fd=$fd: $e');
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
  final dir = Directory(
    '${Directory.systemTemp.path}${Platform.pathSeparator}$name',
  );
  await dir.create(recursive: true);
  return dir;
}

Future<String> _copyAssetToCache(String uri) async {
  final cached = _assetCache[uri];
  // Re-check the file on every hit. macOS and Linux may evict /tmp between
  // sessions or under disk pressure; without this guard a cached path
  // outlives its file and `loadfile` fails opaquely. The miss path
  // re-extracts the asset.
  if (cached != null) {
    if (await File(cached).exists()) return cached;
    _assetCache.remove(uri);
  }
  return _assetInflight.putIfAbsent(uri, () => _doCopyAsset(uri));
}

/// The bundle key of an `asset://` [uri].
String _assetKey(String uri) {
  final assetPath = uri.substring('asset://'.length);
  return assetPath.startsWith('/') ? assetPath.substring(1) : assetPath;
}

/// The most characters of an asset key a copy's name keeps, from its end.
const _kAssetNameTail = 64;

/// Where the copy of the asset at [assetPath] goes.
Future<String> _assetCopyPath(String assetPath) async {
  // Both POSIX (`/`) and Windows (`\`) separators are flattened so the
  // temp filename never contains directory parts. On POSIX
  // `Platform.pathSeparator` is `/` and the second pass is a no-op.
  final flat = assetPath
      .replaceAll(Platform.pathSeparator, '_')
      .replaceAll('/', '_');
  // Only the tail is kept, extension included: a deep key flattened whole
  // can pass NAME_MAX, and on Windows MAX_PATH, past which mpv cannot
  // open the copy.
  final runes = flat.runes;
  final safeName = runes.length <= _kAssetNameTail
      ? flat
      : String.fromCharCodes(runes.skip(runes.length - _kAssetNameTail));
  // Flattening and cutting are ambiguous: `a/b.mp3` and `a_b.mp3`
  // collapse to the same name, and the second extraction would overwrite
  // a file mpv may still be streaming. A hash of the ORIGINAL path
  // disambiguates.
  final dir = await _assetDirectory();
  return '${dir.path}${Platform.pathSeparator}'
      'mpv_asset_${_fnv1a(assetPath)}_$safeName';
}

Future<String> _doCopyAsset(String uri) async {
  try {
    final assetPath = _assetKey(uri);
    final data = await rootBundle.load(assetPath);
    final file = File(await _assetCopyPath(assetPath));

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
        // Left behind; only a later copy from this same process (same
        // pid in the name) overwrites it.
      }
      if (!await file.exists()) rethrow;
    }

    _assetCache[uri] = file.path;
    return file.path;
  } finally {
    // `remove` returns the in-flight Future we are currently completing;
    // discard it: awaiting our own pending Future here would deadlock.
    unawaited(_assetInflight.remove(uri));
  }
}
