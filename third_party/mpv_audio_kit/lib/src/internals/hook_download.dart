// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

// The build hook's download and its shared cache, apart so a test can
// drive them against a local server and a temporary directory.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

/// An HTTP answer that ends the download: a status other than 200 below
/// 500 (a 404, a 403), or a 5xx still failing after the last attempt.
class DownloadRefused implements Exception {
  /// The refusal of [url] with [statusCode].
  DownloadRefused(this.statusCode, this.url);

  /// The HTTP status of the answer.
  final int statusCode;

  /// The URL that was refused.
  final String url;

  @override
  String toString() =>
      'mpv_audio_kit: HTTP $statusCode for $url'
      '${statusCode == HttpStatus.notFound ? '. The pinned libmpv release '
                'may not be published yet: point the libmpv user define at '
                'a local copy (see hook/build.dart)' : ''}';
}

/// Downloads [url] into [target]. A connection that does not open within
/// [connectTimeout], or a body that sends nothing for [idleTimeout], counts
/// as a network failure, and a network failure (or a 5xx answer) is tried
/// again, up to [attempts] times in all, waiting [backoff] and then twice
/// as long. A 5xx after the last attempt throws [DownloadRefused], and any
/// other HTTP status throws it at once.
Future<void> download(
  String url,
  File target, {
  Duration connectTimeout = const Duration(seconds: 30),
  Duration idleTimeout = const Duration(seconds: 60),
  int attempts = 3,
  Duration backoff = const Duration(seconds: 2),
}) async {
  var wait = backoff;
  for (var attempt = 1; ; attempt++) {
    try {
      await _downloadOnce(url, target, connectTimeout, idleTimeout);
      return;
    } on DownloadRefused {
      rethrow;
    } on Object catch (e) {
      final retryable =
          e is SocketException ||
          e is TimeoutException ||
          e is HttpException ||
          e is HandshakeException ||
          e is _ServerError;
      if (!retryable || attempt >= attempts) {
        if (e is _ServerError) throw DownloadRefused(e.statusCode, url);
        rethrow;
      }
      stderr.writeln(
        'mpv_audio_kit: download of $url failed ($e), '
        'attempt $attempt of $attempts; retrying in ${wait.inSeconds} s',
      );
      await Future<void>.delayed(wait);
      wait *= 2;
    }
  }
}

class _ServerError implements Exception {
  _ServerError(this.statusCode);
  final int statusCode;
  @override
  String toString() => 'HTTP $statusCode';
}

Future<void> _downloadOnce(
  String url,
  File target,
  Duration connectTimeout,
  Duration idleTimeout,
) async {
  final client = HttpClient()
    ..findProxy = HttpClient.findProxyFromEnvironment
    ..connectionTimeout = connectTimeout
    ..idleTimeout = idleTimeout;
  try {
    final request = await client.getUrl(Uri.parse(url)).timeout(connectTimeout);
    final response = await request.close().timeout(idleTimeout);
    if (response.statusCode >= 500) {
      await response.drain<void>().catchError((_) {});
      throw _ServerError(response.statusCode);
    }
    if (response.statusCode != HttpStatus.ok) {
      await response.drain<void>().catchError((_) {});
      throw DownloadRefused(response.statusCode, url);
    }
    final sink = target.openWrite();
    try {
      await sink.addStream(response.timeout(idleTimeout));
    } finally {
      // After a failed addStream close() reports that failure again, as a
      // closed file: the one thrown above is the one to keep.
      await sink.close().then<void>((_) {}, onError: (Object _) {});
    }
    final expected = response.contentLength;
    if (expected >= 0 && await target.length() != expected) {
      throw HttpException(
        'body cut short: ${await target.length()} of $expected bytes',
        uri: Uri.parse(url),
      );
    }
  } finally {
    client.close(force: true);
  }
}

/// A download that failed on the network after the last attempt.
class DownloadFailed implements Exception {
  /// The failure of [asset] of [release], fetched from [url], with [cause].
  DownloadFailed(this.asset, this.release, this.url, this.cause);

  /// The release asset that was fetched.
  final String asset;

  /// The libmpv release the asset belongs to, as `libmpv-rN`.
  final String release;

  /// The URL that failed.
  final String url;

  /// The last network error.
  final Object cause;

  @override
  String toString() =>
      'mpv_audio_kit: could not download $asset of $release from $url '
      '($cause). To build without network, save that asset of the $release '
      'release in a directory and point the libmpv user define at it '
      '(see hook/build.dart).';
}

/// A download whose SHA-256 is not the pinned one.
class ChecksumMismatch implements Exception {
  /// The mismatch of [asset] from [url]: [actual] in place of [expected].
  ChecksumMismatch(this.asset, this.url, this.expected, this.actual);

  /// The release asset that was fetched.
  final String asset;

  /// The URL it came from.
  final String url;

  /// The pinned SHA-256.
  final String expected;

  /// The SHA-256 of what arrived.
  final String actual;

  @override
  String toString() =>
      'mpv_audio_kit: SHA-256 mismatch for $asset from $url: '
      'expected $expected, got $actual';
}

/// The release [asset] of [release], downloaded from [url] once into
/// [cacheDir] as `<sha256Hex>/<asset>` and reused by every build that asks
/// for the same checksum. The file is checked on every call; a download
/// lands in a partial file of its own and is renamed into place only when
/// its SHA-256 is [sha256Hex], so the cache never holds a wrong or half
/// file. A network failure throws [DownloadFailed], a wrong body
/// [ChecksumMismatch], an HTTP refusal [DownloadRefused].
Future<File> fetchPinned({
  required String asset,
  required String release,
  required String url,
  required String sha256Hex,
  required Uri cacheDir,
  Duration connectTimeout = const Duration(seconds: 30),
  Duration idleTimeout = const Duration(seconds: 60),
  int attempts = 3,
  Duration backoff = const Duration(seconds: 2),
}) async {
  final cached = File.fromUri(cacheDir.resolve('$sha256Hex/$asset'));
  if (await _sha256Of(cached) == sha256Hex) return cached;

  await cached.parent.create(recursive: true);
  // One partial file per build: Flutter can run the hook for two
  // architectures at once, and both would download the same asset.
  final partial = File('${cached.path}.$pid.part');
  try {
    try {
      await download(
        url,
        partial,
        connectTimeout: connectTimeout,
        idleTimeout: idleTimeout,
        attempts: attempts,
        backoff: backoff,
      );
    } on DownloadRefused {
      rethrow;
    } on Object catch (e) {
      throw DownloadFailed(asset, release, url, e);
    }
    final actual = await _sha256Of(partial);
    if (actual != sha256Hex) {
      throw ChecksumMismatch(asset, url, sha256Hex, actual ?? 'nothing');
    }
    return await partial.rename(cached.path);
  } finally {
    if (await partial.exists()) await partial.delete();
  }
}

final _sha256Name = RegExp(r'^[0-9a-f]{64}$');

/// Deletes the directories of [cacheDir] that [fetchPinned] made for a
/// checksum not in [keep]: the assets of earlier releases, about 8 MB each.
/// Everything else in the directory is left alone, and so are the
/// directories of [keep], which a build for another target may be using
/// right now. Best effort: a directory that cannot be deleted stays for the
/// next build.
Future<void> pruneCache(Uri cacheDir, Iterable<String> keep) async {
  final dir = Directory.fromUri(cacheDir);
  if (!await dir.exists()) return;
  final kept = keep.toSet();
  await for (final entity in dir.list(followLinks: false)) {
    final name = entity.uri.pathSegments.lastWhere((s) => s.isNotEmpty);
    if (entity is! Directory ||
        !_sha256Name.hasMatch(name) ||
        kept.contains(name)) {
      continue;
    }
    try {
      await entity.delete(recursive: true);
    } on FileSystemException {
      // In use or already gone.
    }
  }
}

/// The marker [unpackedBinary] writes inside an unpacked zip.
const unpackedMarker = '.mpv_audio_kit_unpacked.json';

/// The path of [binary], a file inside [zip] such as
/// `libmpv.xcframework/ios-arm64/libmpv.framework/libmpv`, in the copy of
/// [zip] unpacked into [dir], with its links followed.
///
/// The copy is unpacked once with [extract] and kept: at that moment the
/// SHA-256 of every file in it is written into [unpackedMarker], with
/// [zipSha256] when given. Each later call hashes [binary] only and unpacks
/// again when it does not match, when the marker is missing or names
/// another zip, or when the copy is incomplete. The zip itself is the
/// caller's to check.
Future<String> unpackedBinary(
  File zip,
  Directory dir,
  String binary, {
  String? zipSha256,
  Future<void> Function(File zip, Directory into) extract = _unzip,
}) async {
  final found = await _verifiedBinary(dir, binary, zipSha256);
  if (found != null) return found;
  // Unpack beside it and rename into place, so an interrupted unzip never
  // leaves a half directory that a later build would trust.
  await dir.parent.create(recursive: true);
  final staging = await dir.parent.createTemp('unzip-');
  try {
    await extract(zip, staging);
    await File('${staging.path}/$unpackedMarker').writeAsString(
      jsonEncode({'zip': ?zipSha256, 'files': await _hashTree(staging)}),
    );
    // Another build may have put a good copy in place meanwhile: keep it.
    final again = await _verifiedBinary(dir, binary, zipSha256);
    if (again != null) return again;
    if (await dir.exists()) {
      // Moved aside first: a rename never replaces a directory that has
      // files in it.
      final stale = Directory(
        '${dir.path}.stale-$pid-${DateTime.now().microsecondsSinceEpoch}',
      );
      await dir.rename(stale.path);
      await stale.delete(recursive: true);
    }
    try {
      await staging.rename(dir.path);
    } on FileSystemException {
      // Another build renamed its copy in first; it is the same zip.
    }
  } finally {
    if (await staging.exists()) await staging.delete(recursive: true);
  }
  final unpacked = await _verifiedBinary(dir, binary, zipSha256);
  if (unpacked == null) {
    throw StateError(
      'mpv_audio_kit: ${zip.path} does not hold $binary as unpacked',
    );
  }
  return unpacked;
}

/// [binary] in [dir], resolved, when the marker vouches for it.
Future<String?> _verifiedBinary(
  Directory dir,
  String binary,
  String? zipSha256,
) async {
  try {
    final marker = File('${dir.path}/$unpackedMarker');
    if (!await marker.exists()) return null;
    final json = jsonDecode(await marker.readAsString());
    if (json is! Map || json['zip'] != zipSha256) return null;
    final files = json['files'];
    if (files is! Map) return null;
    final root = await dir.resolveSymbolicLinks();
    final resolved = await File('${dir.path}/$binary').resolveSymbolicLinks();
    final relative = _under(root, resolved);
    if (relative == null) return null;
    final expected = files[relative];
    if (expected is! String) return null;
    return await _sha256Of(File(resolved)) == expected ? resolved : null;
  } on FileSystemException {
    return null;
  } on FormatException {
    return null;
  }
}

/// The SHA-256 of every regular file under [dir], by path relative to it.
Future<Map<String, String>> _hashTree(Directory dir) async {
  final root = await dir.resolveSymbolicLinks();
  final hashes = <String, String>{};
  await for (final entity in Directory(
    root,
  ).list(recursive: true, followLinks: false)) {
    if (entity is File) {
      hashes[_under(root, entity.path)!] = (await _sha256Of(entity))!;
    }
  }
  return hashes;
}

/// The path of [path] inside [root], with `/` between its parts on every
/// host, or `null` when it is not inside: the marker names the files of a
/// copy the same way on Windows, where the paths have backslashes.
String? _under(String root, String path) {
  final sep = Platform.pathSeparator;
  if (!path.startsWith('$root$sep')) return null;
  return path.substring(root.length + 1).replaceAll(sep, '/');
}

/// The SHA-256 of [file] in hex, `null` when it does not exist.
Future<String?> _sha256Of(File file) async {
  if (!await file.exists()) return null;
  return (await sha256.bind(file.openRead()).first).toString();
}

Future<void> _unzip(File zip, Directory into) async {
  final result = await Process.run('unzip', ['-q', zip.path, '-d', into.path]);
  if (result.exitCode != 0) {
    throw ProcessException(
      'unzip',
      ['-q', zip.path, '-d', into.path],
      '${result.stderr}',
      result.exitCode,
    );
  }
}
