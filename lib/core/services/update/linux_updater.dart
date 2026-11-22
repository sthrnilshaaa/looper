import 'dart:ffi' show Abi;
import 'dart:io';
import 'dart:ui' show AppExitType;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:looper_player/core/services/update/apk_installer.dart';
import 'package:looper_player/core/services/update/github_release.dart';
import 'package:path/path.dart' as p;

/// How this copy of the app was installed; each updates differently.
enum LinuxInstallKind { appImage, deb, rpm, tarball }

/// The release asset for [kind], or null when the release has none. An asset
/// without a published SHA-256 is skipped: it would be installed unverified,
/// for the package formats as root.
ApkAsset? linuxAssetFor(List<ApkAsset> assets, LinuxInstallKind kind) {
  final suffix = switch (kind) {
    LinuxInstallKind.appImage => '_x86_64.appimage',
    LinuxInstallKind.deb => '_amd64.deb',
    LinuxInstallKind.rpm => '.x86_64.rpm',
    LinuxInstallKind.tarball => '_linux_x64.tar.gz',
  };
  for (final asset in assets) {
    if (asset.sha256 != null && asset.name.toLowerCase().endsWith(suffix)) {
      return asset;
    }
  }
  return null;
}

/// The root command that installs the package at [path], using the first
/// package manager [has] finds, or null when there is none.
List<String>? linuxPackageCommand(
  LinuxInstallKind kind,
  String path,
  bool Function(String tool) has,
) => switch (kind) {
  LinuxInstallKind.deb when has('apt-get') => [
    'pkexec',
    'apt-get',
    'install',
    '-y',
    path,
  ],
  // The file's digest was already checked against the GitHub release.
  LinuxInstallKind.rpm when has('dnf') => [
    'pkexec',
    'dnf',
    'install',
    '-y',
    '--nogpgcheck',
    path,
  ],
  LinuxInstallKind.rpm when has('zypper') => [
    'pkexec',
    'zypper',
    '--non-interactive',
    '--no-gpg-checks',
    'install',
    '--allow-unsigned-rpm',
    path,
  ],
  _ => null,
};

/// Installs a downloaded, verified release over this copy, then restarts.
abstract final class LinuxUpdater {
  static const _packagedDir = '/usr/lib/looper-player/';
  static const _packagedLauncher = '/usr/bin/looper-player';

  static bool _detected = false;
  static LinuxInstallKind? _kind;

  /// Null when this copy can't update itself (a development build, or a CPU
  /// the releases aren't built for).
  static LinuxInstallKind? get kind {
    if (!_detected) {
      _detected = true;
      _kind = _detect();
    }
    return _kind;
  }

  static LinuxInstallKind? _detect() {
    if (!Platform.isLinux || Abi.current() != Abi.linuxX64) return null;
    if (Platform.environment['APPIMAGE']?.isNotEmpty ?? false) {
      return LinuxInstallKind.appImage;
    }
    final exe = Platform.resolvedExecutable;
    if (exe.startsWith(_packagedDir)) {
      if (_owns('dpkg-query', ['-S', exe])) return LinuxInstallKind.deb;
      if (_owns('rpm', ['-qf', exe])) return LinuxInstallKind.rpm;
      return null;
    }
    if (!kReleaseMode || exe.contains('/build/linux/')) return null;
    final dir = p.dirname(exe);
    return Directory(p.join(dir, 'lib')).existsSync() &&
            Directory(p.join(dir, 'data')).existsSync()
        ? LinuxInstallKind.tarball
        : null;
  }

  static bool _owns(String tool, List<String> args) {
    try {
      return Process.runSync(tool, args).exitCode == 0;
    } on ProcessException {
      return false;
    }
  }

  static ApkAsset? assetFor(GithubRelease release) {
    final current = kind;
    return current == null ? null : linuxAssetFor(release.assets, current);
  }

  static Future<({ApkInstallStatus status, String? message})> install(
    File file,
  ) async {
    final current = kind;
    if (current == null) {
      return (status: ApkInstallStatus.failed, message: null);
    }
    try {
      final String relaunch;
      switch (current) {
        case LinuxInstallKind.appImage:
          relaunch = await replaceAppImage(
            file,
            Platform.environment['APPIMAGE']!,
          );
        case LinuxInstallKind.tarball:
          relaunch = await replaceBundle(file, Platform.resolvedExecutable);
        case LinuxInstallKind.deb || LinuxInstallKind.rpm:
          final failure = await _installPackage(current, file);
          if (failure != null) return failure;
          relaunch = _packagedLauncher;
      }
      await _restart(relaunch);
      return (status: ApkInstallStatus.success, message: null);
    } on FileSystemException catch (e) {
      return (status: ApkInstallStatus.storage, message: e.message);
    } catch (e) {
      return (status: ApkInstallStatus.failed, message: e.toString());
    }
  }

  static Future<({ApkInstallStatus status, String? message})?> _installPackage(
    LinuxInstallKind kind,
    File file,
  ) async {
    final tools = <String, bool>{};
    for (final tool in const ['pkexec', 'apt-get', 'dnf', 'zypper']) {
      final found = await Process.run('sh', ['-c', 'command -v "\$0"', tool]);
      tools[tool] = found.exitCode == 0;
    }
    final command = linuxPackageCommand(
      kind,
      file.path,
      (tool) => tools[tool] ?? false,
    );
    if (command == null || tools['pkexec'] != true) {
      return (
        status: ApkInstallStatus.failed,
        message: 'pkexec and a package manager are required.',
      );
    }
    final result = await Process.run(command.first, command.sublist(1));
    if (result.exitCode == 0) return null;
    // pkexec: 126 = the password prompt was dismissed.
    if (result.exitCode == 126) {
      return (status: ApkInstallStatus.aborted, message: null);
    }
    final lines = '${result.stderr}'.trim().split('\n');
    return (status: ApkInstallStatus.failed, message: lines.last);
  }

  /// A running AppImage can be renamed over: it keeps its old file open.
  @visibleForTesting
  static Future<String> replaceAppImage(File file, String target) async {
    final next = '$target.new';
    try {
      await file.copy(next);
      final chmod = await Process.run('chmod', ['755', next]);
      if (chmod.exitCode != 0) {
        throw FileSystemException('chmod failed', next);
      }
      await File(next).rename(target);
    } catch (_) {
      await _deleteQuietly(File(next));
      rethrow;
    }
    return target;
  }

  /// Unpacks next to the app folder and swaps the two with renames, putting
  /// the old folder back if the swap fails.
  @visibleForTesting
  static Future<String> replaceBundle(File archive, String exe) async {
    final appDir = p.dirname(exe);
    final temp = Directory('$appDir.update');
    final old = Directory('$appDir.old');
    await _deleteQuietly(temp);
    await _deleteQuietly(old);
    await temp.create();
    try {
      final tar = await Process.run('tar', [
        '-xzf',
        archive.path,
        '-C',
        temp.path,
        '--no-same-owner',
      ]);
      if (tar.exitCode != 0) {
        throw ProcessException('tar', const [], '${tar.stderr}');
      }

      final roots = await temp
          .list()
          .where((e) => e is Directory)
          .cast<Directory>()
          .toList();
      if (roots.length != 1 ||
          !await File(p.join(roots.single.path, p.basename(exe))).exists() ||
          !await Directory(p.join(roots.single.path, 'lib')).exists() ||
          !await Directory(p.join(roots.single.path, 'data')).exists()) {
        throw const FormatException('Unexpected archive layout');
      }

      await Directory(appDir).rename(old.path);
      try {
        await roots.single.rename(appDir);
      } catch (_) {
        await old.rename(appDir);
        rethrow;
      }
    } finally {
      await _deleteQuietly(temp);
    }
    await _deleteQuietly(old);
    return exe;
  }

  static Future<void> _deleteQuietly(FileSystemEntity entity) async {
    try {
      if (await entity.exists()) await entity.delete(recursive: true);
    } catch (_) {}
  }

  /// Starts the new version a moment after this process has gone.
  static Future<void> _restart(String executable) async {
    final environment = Map<String, String>.of(Platform.environment);
    // Paths into the old AppImage's mount, which disappears with this process.
    if (kind == LinuxInstallKind.appImage) {
      for (final key in const [
        'APPDIR',
        'APPIMAGE',
        'ARGV0',
        'OWD',
        'LD_LIBRARY_PATH',
      ]) {
        environment.remove(key);
      }
    }
    await Process.start(
      '/bin/sh',
      ['-c', 'sleep 1; exec "\$0"', executable],
      mode: ProcessStartMode.detached,
      environment: environment,
      includeParentEnvironment: false,
      workingDirectory: Platform.environment['HOME'],
    );
    await ServicesBinding.instance.exitApplication(AppExitType.required);
    exit(0);
  }
}
