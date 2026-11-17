import 'dart:async';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:looper_player/core/services/storage/local_json_store.dart';
import 'package:looper_player/core/services/update/apk_installer.dart';
import 'package:looper_player/core/services/update/github_release.dart';
import 'package:looper_player/core/services/update/update_service.dart';

part 'apk_update_notifier.g.dart';

enum ApkUpdatePhase {
  /// No newer release is known.
  idle,

  /// A newer release exists; nothing is downloaded yet.
  available,
  downloading,

  /// Checking a finished or previously downloaded APK against its digest.
  verifying,

  /// A verified APK is on disk, waiting for the user to install it.
  ready,

  /// Handed to the system installer, waiting for its answer.
  installing,
  failed,

  /// The app is running the latest release.
  upToDate,
}

enum ApkUpdateError { network, checksum, storage, install }

enum ApkCheckResult { available, upToDate, failed }

class ApkUpdateState {
  final ApkUpdatePhase phase;
  final GithubRelease? release;
  final ApkAsset? asset;
  final int received;
  final int total;
  final ApkUpdateError? error;

  /// The system's own wording for an install failure, when it gave one.
  final String? errorDetail;

  const ApkUpdateState({
    this.phase = ApkUpdatePhase.idle,
    this.release,
    this.asset,
    this.received = 0,
    this.total = 0,
    this.error,
    this.errorDetail,
  });

  bool get hasUpdate =>
      release != null &&
      asset != null &&
      phase != ApkUpdatePhase.upToDate &&
      phase != ApkUpdatePhase.idle;

  bool get isUpToDate => phase == ApkUpdatePhase.upToDate;

  bool get isBusy =>
      phase == ApkUpdatePhase.downloading ||
      phase == ApkUpdatePhase.verifying ||
      phase == ApkUpdatePhase.installing;

  /// Download progress from 0 to 1, or null while the size is unknown.
  double? get progress => total > 0 ? (received / total).clamp(0.0, 1.0) : null;

  ApkUpdateState _to(
    ApkUpdatePhase phase, {
    int received = 0,
    int total = 0,
    ApkUpdateError? error,
    String? errorDetail,
  }) => ApkUpdateState(
    phase: phase,
    release: release,
    asset: asset,
    received: received,
    total: total,
    error: error,
    errorDetail: errorDetail,
  );
}

/// In-app update for the Android `github` build: finds the newest GitHub
/// release, downloads the APK for this device and hands it to the system
/// installer. Other builds never leave [ApkUpdatePhase.idle].
@Riverpod(keepAlive: true)
class ApkUpdate extends _$ApkUpdate {
  static const _dismissedVersionKey = 'update_dismissed_version';

  http.Client? _client;
  bool _cancelled = false;

  @override
  ApkUpdateState build() => const ApkUpdateState();

  /// The launch-time check. Returns true when the update sheet should open:
  /// a newer release exists and the user hasn't already said "Later" to it.
  Future<bool> checkOnLaunch() async {
    if (await check() != ApkCheckResult.available) return false;
    return await LocalJsonStore.read(_dismissedVersionKey) !=
        state.release?.tag;
  }

  /// Looks for the newest release and checks if an update is available.
  Future<ApkCheckResult> check() async {
    // A download or install is already under way for the release we know.
    if (state.isBusy) return ApkCheckResult.available;

    final GithubRelease release;
    try {
      release = await UpdateService.fetchLatestRelease();
    } catch (_) {
      return state.hasUpdate ? ApkCheckResult.available : ApkCheckResult.failed;
    }
    if (state.isBusy) return ApkCheckResult.available;

    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    final bool isNewer =
        release.tag.isNotEmpty &&
        isNewerVersion(packageInfo.version, release.tag);

    final abis = await ApkInstaller.supportedAbis();
    final asset = release.apkFor(
      abis.isNotEmpty ? abis : const ['arm64-v8a', 'universal'],
    );

    // Our APK isn't on the release yet: say nothing until it is.
    if (!isNewer || release.waitingForMyApk) {
      await _clearDownloads(keep: null);
      state = ApkUpdateState(
        phase: ApkUpdatePhase.upToDate,
        release: release,
        asset: asset,
      );
      return ApkCheckResult.upToDate;
    }

    if (asset == null) {
      // A release without an APK for this device: link to it instead.
      await UpdateService.announceRelease(release);
      state = ApkUpdateState(phase: ApkUpdatePhase.available, release: release);
      return ApkCheckResult.available;
    }

    await _clearDownloads(keep: asset.name);
    // Keep "ready" when re-checking the release that is already downloaded.
    final sameReady =
        state.phase == ApkUpdatePhase.ready && state.asset?.name == asset.name;
    state = ApkUpdateState(
      phase: sameReady ? ApkUpdatePhase.ready : ApkUpdatePhase.available,
      release: release,
      asset: asset,
    );
    return ApkCheckResult.available;
  }

  /// "Later": stop prompting for this release at launch.
  Future<void> dismiss() async {
    final tag = state.release?.tag;
    if (tag != null) await LocalJsonStore.write(_dismissedVersionKey, tag);
  }

  /// Downloads and verifies the APK, then opens the installer if the app is
  /// still in the foreground. Also the retry action after a failure.
  Future<void> download() async {
    final asset = state.asset;
    if (asset == null || state.isBusy) return;

    final File file;
    try {
      file = await _apkFile(asset);
      state = state._to(ApkUpdatePhase.verifying);
      if (await _matches(file, asset)) {
        await _downloaded();
        return;
      }
    } catch (_) {
      state = state._to(ApkUpdatePhase.failed, error: ApkUpdateError.storage);
      return;
    }

    final part = File('${file.path}.part');
    final client = _client = http.Client();
    _cancelled = false;
    state = state._to(ApkUpdatePhase.downloading, total: asset.size);

    RandomAccessFile? out;
    final digest = _DigestSink();
    final hasher = sha256.startChunkedConversion(digest);
    var received = 0;
    var writing = false;
    try {
      final response = await client
          .send(http.Request('GET', Uri.parse(asset.url)))
          .timeout(const Duration(seconds: 30));
      if (response.statusCode != 200) {
        throw HttpException('Download answered ${response.statusCode}');
      }
      final total = response.contentLength ?? asset.size;
      out = await part.open(mode: FileMode.write);

      var lastUpdate = DateTime.now();
      // A stalled connection would otherwise wait forever.
      final chunks = response.stream.timeout(const Duration(seconds: 30));
      await for (final chunk in chunks) {
        writing = true;
        await out.writeFrom(chunk);
        writing = false;
        hasher.add(chunk);
        received += chunk.length;
        final now = DateTime.now();
        if (now.difference(lastUpdate).inMilliseconds >= 100) {
          lastUpdate = now;
          state = state._to(
            ApkUpdatePhase.downloading,
            received: received,
            total: total,
          );
        }
      }
      await out.close();
      out = null;
      hasher.close();

      state = state._to(ApkUpdatePhase.verifying);
      final expected = asset.sha256;
      if (received != asset.size ||
          (expected != null && digest.value.toString() != expected)) {
        await _delete(part);
        state = state._to(
          ApkUpdatePhase.failed,
          error: ApkUpdateError.checksum,
        );
        return;
      }
      await part.rename(file.path);
    } catch (_) {
      try {
        await out?.close();
      } catch (_) {}
      await _delete(part);
      state = _cancelled
          ? state._to(ApkUpdatePhase.available)
          : state._to(
              ApkUpdatePhase.failed,
              // A failed write is the disk, anything else the connection.
              error: writing ? ApkUpdateError.storage : ApkUpdateError.network,
            );
      return;
    } finally {
      client.close();
      if (identical(_client, client)) _client = null;
    }
    await _downloaded();
  }

  /// Stops an in-flight download and discards what was fetched.
  void cancel() {
    if (state.phase != ApkUpdatePhase.downloading) return;
    _cancelled = true;
    _client?.close();
  }

  /// Opens the system install dialog for the downloaded APK.
  Future<void> install() async {
    final asset = state.asset;
    if (asset == null || state.phase != ApkUpdatePhase.ready) return;

    final file = await _apkFile(asset);
    if (!await file.exists()) {
      // The system cleared the cache since the download.
      state = state._to(ApkUpdatePhase.available);
      return download();
    }

    state = state._to(ApkUpdatePhase.installing);
    final result = await ApkInstaller.install(file.path);
    switch (result.status) {
      case ApkInstallStatus.success:
        // Normally unreachable: the update replaces this process.
        state = const ApkUpdateState();
      case ApkInstallStatus.aborted:
        state = state._to(ApkUpdatePhase.ready);
      case ApkInstallStatus.storage:
        state = state._to(ApkUpdatePhase.failed, error: ApkUpdateError.storage);
      case ApkInstallStatus.failed:
        state = state._to(
          ApkUpdatePhase.failed,
          error: ApkUpdateError.install,
          errorDetail: result.message,
        );
    }
  }

  /// Retry after a failure: an install failure keeps the verified APK and
  /// goes back to the installer, anything else downloads again.
  Future<void> retry() async {
    if (state.phase != ApkUpdatePhase.failed) return;
    return download();
  }

  Future<void> _downloaded() async {
    state = state._to(ApkUpdatePhase.ready);
    // Android won't let a backgrounded app open the install dialog; the
    // sheet's Install button covers that case.
    if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
      await install();
    }
  }

  static Future<Directory> _downloadsDir() async =>
      Directory(p.join((await getTemporaryDirectory()).path, 'updates'));

  static Future<File> _apkFile(ApkAsset asset) async {
    final dir = await _downloadsDir();
    await dir.create(recursive: true);
    // The name comes from the network; never let it leave the folder.
    return File(p.join(dir.path, p.basename(asset.name)));
  }

  /// Whether [file] is a complete, untampered copy of [asset].
  static Future<bool> _matches(File file, ApkAsset asset) async {
    if (!await file.exists() || await file.length() != asset.size) return false;
    final expected = asset.sha256;
    if (expected == null) return true;
    return (await sha256.bind(file.openRead()).first).toString() == expected;
  }

  /// Removes old downloads, sparing the APK named [keep].
  static Future<void> _clearDownloads({required String? keep}) async {
    try {
      final dir = await _downloadsDir();
      if (!await dir.exists()) return;
      await for (final entry in dir.list()) {
        if (keep != null && p.basename(entry.path) == p.basename(keep)) {
          continue;
        }
        await entry.delete(recursive: true);
      }
    } catch (_) {}
  }

  static Future<void> _delete(File file) async {
    try {
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }
}

class _DigestSink implements Sink<Digest> {
  late Digest value;

  @override
  void add(Digest data) => value = data;

  @override
  void close() {}
}
