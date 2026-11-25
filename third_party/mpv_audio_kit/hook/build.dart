// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

// Build hook: fetches the libmpv binary for the target from the
// libmpv-<release> GitHub release, checks its SHA-256 and bundles it as the
// code asset `package:mpv_audio_kit/libmpv`, which
// lib/src/ffi/mpv_library_bundled.dart binds with @Native. One script for
// every platform, in place of a Gradle task, two podspecs, two SwiftPM
// manifests and two CMake files.
//
// Offline builds and custom binaries: point the app at a local copy with
//
//   hooks:
//     user_defines:
//       mpv_audio_kit:
//         libmpv: path/to/libmpv
//
// in the app's pubspec. A directory holds files named like the release
// assets (libmpv_android-arm64-v8a.so, libmpv_ios.xcframework.zip, ...),
// and each target takes its own. A single file is bundled for every
// target, so it only suits a build for one target and architecture. Local
// files are bundled as they are, without a checksum.
//
// tvOS is the exception: the plugin's tvos/Package.swift links libmpv
// there, and this hook bundles nothing. Tizen, through flutter-tizen, is
// linux here and takes its own libmpv_tizen assets: on arm (the TVs) by
// itself, on x64 (the TV emulator) with
//
//   hooks:
//     user_defines:
//       mpv_audio_kit:
//         tizen: true
//
// OpenHarmony and HarmonyOS (OHOS), through Flutter-OH
// (https://gitcode.com/CPF-Flutter/flutter_flutter), are linux here too,
// with the arch of the HAP: they take the libmpv_ohos assets, which are
// built against the musl of the OHOS native SDK. A build is OHOS when the
// target OS is ohos or when the C compiler Flutter-OH passes is the clang
// of the OpenHarmony SDK; `ohos: true` or `ohos: false` says it outright,
// for a linux or ohos target only.

import 'dart:io';

import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';

import 'package:mpv_audio_kit/src/internals/hook_download.dart';
import 'package:mpv_audio_kit/src/internals/libmpv_release.dart';

const _release = 'libmpv-$libmpvRelease';
const _baseUrl =
    'https://github.com/ales-drnz/mpv_audio_kit/releases/download/$_release';

/// SHA-256 of every release asset, from the release's manifest.json.
const _sha256 = <String, String>{
  'libmpv_android-arm64-v8a.so':
      '70a9d58cf2a56dd0fd389385efcbf719278cae796a5ee250c51a22ce740ee7e6',
  'libmpv_android-armeabi-v7a.so':
      'ba427db72afbfa4e7cc70e1cba84d58d23fa6871e4a71e4ecdface18f393f10b',
  'libmpv_android-x86_64.so':
      'c1d64c62e58cd9451b5885a97b871b81166693cad0c7f98fa890f87b2fde09e6',
  'libmpv_ios.xcframework.zip':
      'd12798c0f72661035bba7108e3b9d7b8a77107675fe76004c0dc7c24d368bdd8',
  'libmpv_linux-aarch64.so':
      '0db8bd8c55f84cc641209f8523fac11547be5a8d099896430c019065ee3974e6',
  'libmpv_linux-x86_64.so':
      '5b974ea687640a545f4c43e89be168bca49a3eda29e2dfd85baf551c34ee4b35',
  'libmpv_ohos-arm64-v8a.so':
      '0b6e7a8aaedfdb57b28bff2b15a8f8a99ba8d4c974d2c90923e5d66594ca2d1e',
  'libmpv_ohos-x86_64.so':
      '2eff5d0ed6b96a6fd223e85fe7b188b2c921b9d62eb99e8c25d36c3e72eba0df',
  'libmpv_macos.xcframework.zip':
      '7709cc28b14b71ba0c80e9d00a561ae6279cf7e3590ba9b9dff8b3db8d3f95cc',
  'libmpv_tizen-armv7l.so':
      '7ac807280291bef753ccc7f6c9776dbeb17f85a17d9db82a5fd3e0b0830ffd4f',
  'libmpv_tizen-x86_64.so':
      '279dd4848557db92ca18ac9e2ccfae7abb5753de80932f11ae2451bb671f545f',
  'libmpv_windows-arm64.dll':
      '9db0dc8b80a5b7e40e7867399021cbbf613f712574912a0ca51c482d38c6d6f7',
  'libmpv_windows-x86_64.dll':
      '1b3d4a9711d03bb1e02c4db784acd1b56caec0512282ef8ab50f9a33638c0f66',
};

/// The tizen user define, true or false. Anything else fails the build: an
/// emulator build would bundle the desktop library and fail when it loads.
bool _tizen(BuildInput input) => switch (input.userDefines['tizen']) {
  null || false => false,
  true => true,
  final other => throw ArgumentError(
    'mpv_audio_kit: the tizen user define is true or false, not $other',
  ),
};

/// Whether the build is for OHOS: the ohos user define, true or false, or
/// when it is not set, a target OS of ohos (a Flutter-OH that stops writing
/// linux) or the SDK's clang as the C compiler. Anything else fails the
/// build. The define counts only where Flutter-OH builds, a target OS of
/// linux or ohos: an app that sets it builds for Android or Windows too.
bool _ohos(BuildInput input) {
  final define = switch (input.userDefines['ohos']) {
    final bool value => value,
    null => null,
    final other => throw ArgumentError(
      'mpv_audio_kit: the ohos user define is true or false, not $other',
    ),
  };
  final os = _targetOSName(input);
  if (os != 'linux' && os != 'ohos') return false;
  return define ?? (os == 'ohos' || _ohosCompiler(input));
}

/// Whether the C compiler of the input is the clang of the OpenHarmony SDK,
/// `<sdk>/<version>/openharmony/native/llvm/bin/clang`, which Flutter-OH
/// passes to the hooks of an OHOS build (`cCompilerConfigOhos`). Read raw,
/// as [_targetOSName].
bool _ohosCompiler(BuildInput input) {
  final extensions = input.config.json['extensions'];
  final code = extensions is Map ? extensions['code_assets'] : null;
  final compiler = code is Map ? code['c_compiler'] : null;
  final cc = compiler is Map ? compiler['cc'] : null;
  if (cc is! String) return false;
  return cc.replaceAll(r'\', '/').contains('/openharmony/native/llvm/bin/');
}

/// The target architecture as the hook protocol writes it, read raw: an
/// OHOS target OS is one code_assets cannot parse.
String? _targetArchitectureName(BuildInput input) {
  final extensions = input.config.json['extensions'];
  final code = extensions is Map ? extensions['code_assets'] : null;
  final arch = code is Map ? code['target_architecture'] : null;
  return arch is String ? arch : null;
}

void main(List<String> args) async {
  await build(args, (input, output) async {
    if (!input.config.buildCodeAssets) return;
    // flutter-tvos (https://fluttertv.dev) runs the hook but installs no
    // code asset, so tvos/Package.swift links libmpv into the app and
    // @Native finds its symbols in the process. Read before
    // input.config.code, which code_assets before 2.0.0 cannot parse for
    // an OS it does not know.
    if (_targetOSName(input) == 'tvos') return;
    final tizen = _tizen(input);
    final ohos = _ohos(input);
    if (tizen && ohos) {
      throw ArgumentError(
        'mpv_audio_kit: a build is for Tizen or for OHOS, not both',
      );
    }
    // OHOS before input.config.code, which fails on a target OS of ohos.
    final _Target target;
    final CodeConfig? code;
    if (ohos) {
      code = null;
      target = _Target.ohos(_targetArchitectureName(input));
    } else {
      code = input.config.code;
      target = _Target.of(code, iOSVersion: _iOSVersion(input), tizen: tizen);
    }
    final out = File.fromUri(input.outputDirectory.resolve(target.fileName));

    final local = input.userDefines.path('libmpv');
    if (local != null &&
        await FileSystemEntity.type(local.toFilePath()) ==
            FileSystemEntityType.notFound) {
      throw StateError(
        'mpv_audio_kit: the libmpv user define points at '
        '${local.toFilePath()}, which does not exist',
      );
    }
    if (local != null &&
        !await FileSystemEntity.isDirectory(local.toFilePath())) {
      // A single file is the finished library, bundled for every target.
      output.dependencies.add(local);
      await File.fromUri(local).copy(out.path);
    } else {
      final asset = local == null
          ? await _fetch(target.asset, input.outputDirectoryShared)
          : await _localAsset(local, target.asset);
      if (local != null) output.dependencies.add(asset.uri);
      if (target.appleSlice == null) {
        await asset.copy(out.path);
      } else {
        // A pinned download never changes, so its unpacked copy is kept
        // beside it and its binary checked on each build; a local zip may,
        // so it is unpacked again each build.
        final unpacked = local == null
            ? Directory('${asset.parent.path}/unzipped')
            : Directory.fromUri(input.outputDirectory.resolve('unzipped'));
        if (local != null && await unpacked.exists()) {
          await unpacked.delete(recursive: true);
        }
        await _extractAppleSlice(
          asset,
          unpacked,
          target,
          code!.targetArchitecture,
          out,
          zipSha256: local == null ? _sha256[target.asset] : null,
        );
      }
    }

    output.assets.code.add(
      CodeAsset(
        package: input.packageName,
        name: 'libmpv',
        linkMode: DynamicLoadingBundled(),
        file: out.uri,
      ),
    );
  });
}

/// The target OS as the hook protocol writes it, read off the JSON input.
String? _targetOSName(BuildInput input) {
  final extensions = input.config.json['extensions'];
  final code = extensions is Map ? extensions['code_assets'] : null;
  final os = code is Map ? code['target_os'] : null;
  return os is String ? os : null;
}

/// The iOS version the build targets, as Flutter writes it in the input:
/// `deployment_version` (code_assets 2.2) or `target_version` before.
/// Read raw, as [_targetOSName]: code_assets 2.2 deprecates
/// `IOSCodeConfig.targetVersion` for `deploymentVersion`, which the
/// code_assets 1.x of Flutter 3.41 lacks. `null` when the input has none.
int? _iOSVersion(BuildInput input) {
  final extensions = input.config.json['extensions'];
  final code = extensions is Map ? extensions['code_assets'] : null;
  final ios = code is Map ? code['ios'] : null;
  if (ios is! Map) return null;
  final deployment = ios['deployment_version'];
  final major = deployment is Map ? deployment['major'] : ios['target_version'];
  return major is int ? major : null;
}

/// Which release asset a target needs, and the file name it is bundled
/// under. The name is the package's own, never `libmpv`, so it cannot
/// collide with another plugin's copy on disk or in the loader (bionic
/// matches a dlopen by name against the SONAMEs already loaded; the SONAME
/// inside is the same). On Apple the file becomes
/// `libmpv_audio_kit.framework/libmpv_audio_kit`: not `mpv_audio_kit`,
/// which is the framework CocoaPods builds for the plugin itself under
/// `use_frameworks!`, and both land in the app's Frameworks directory.
class _Target {
  const _Target(this.asset, this.fileName, {this.appleSlice});

  final String asset;
  final String fileName;

  /// The xcframework directory holding the slice, on Apple.
  final String? appleSlice;

  /// OHOS on [arch], the target architecture's name in the hook protocol:
  /// arm64 for the devices, x64 for the emulators. No 32-bit arm build.
  static _Target ohos(String? arch) => _Target(switch (arch) {
    'arm64' => 'libmpv_ohos-arm64-v8a.so',
    'x64' => 'libmpv_ohos-x86_64.so',
    _ => throw UnsupportedError(
      'mpv_audio_kit: no libmpv for ohos $arch in $_release',
    ),
  }, 'libmpv_audio_kit.so');

  static _Target of(CodeConfig code, {int? iOSVersion, bool tizen = false}) {
    final arch = code.targetArchitecture;
    Never unsupported() => throw UnsupportedError(
      'mpv_audio_kit: no libmpv for ${code.targetOS} '
      '$arch in $_release',
    );
    // The iOS binary is built for iOS 15, and Flutter writes this version
    // into the framework's MinimumOSVersion: a lower one does not match the
    // binary. Flutter before 3.47.4 passes 12 or 13.
    if (code.targetOS == OS.iOS && iOSVersion != null && iOSVersion < 15) {
      throw UnsupportedError(
        'mpv_audio_kit: building for iOS needs Flutter 3.47.4 or later, '
        'which targets iOS 15 like the bundled libmpv '
        '(this Flutter targets iOS $iOSVersion).',
      );
    }
    return switch (code.targetOS) {
      // flutter-tizen (https://github.com/flutter-tizen/flutter-tizen)
      // writes linux with the arch of the Tizen build: arm for the TVs,
      // which Flutter's Linux desktop never builds, and x64 for the TV
      // emulator, which it does, so there the app sets the tizen user define.
      // Flutter-OH writes linux too, but its builds never get here: they
      // are _Target.ohos.
      OS.linux => _Target(switch ((arch, tizen)) {
        (Architecture.arm, _) => 'libmpv_tizen-armv7l.so',
        (Architecture.x64, true) => 'libmpv_tizen-x86_64.so',
        (Architecture.x64, false) => 'libmpv_linux-x86_64.so',
        (Architecture.arm64, false) => 'libmpv_linux-aarch64.so',
        _ => unsupported(),
      }, 'libmpv_audio_kit.so'),
      OS.android => _Target(
        'libmpv_android-${switch (arch) {
          Architecture.arm64 => 'arm64-v8a',
          Architecture.arm => 'armeabi-v7a',
          Architecture.x64 => 'x86_64',
          _ => unsupported(),
        }}.so',
        'libmpv_audio_kit.so',
      ),
      OS.windows => _Target(
        'libmpv_windows-${switch (arch) {
          Architecture.x64 => 'x86_64',
          Architecture.arm64 => 'arm64',
          _ => unsupported(),
        }}.dll',
        'mpv_audio_kit.dll',
      ),
      OS.macOS => const _Target(
        'libmpv_macos.xcframework.zip',
        'libmpv_audio_kit',
        appleSlice: 'macos-arm64_x86_64',
      ),
      OS.iOS => _Target(
        'libmpv_ios.xcframework.zip',
        'libmpv_audio_kit',
        appleSlice: code.iOS.targetSdk == IOSSdk.iPhoneSimulator
            ? 'ios-arm64_x86_64-simulator'
            : 'ios-arm64',
      ),
      _ => unsupported(),
    };
  }
}

/// The release [asset] in the user-defined directory [dir].
Future<File> _localAsset(Uri dir, String asset) async {
  // Resolve inside the directory even when the path has no trailing slash.
  final base = dir.path.endsWith('/') ? dir : dir.replace(path: '${dir.path}/');
  final file = File.fromUri(base.resolve(asset));
  if (!await file.exists()) {
    throw StateError(
      'mpv_audio_kit: the libmpv user define points at ${dir.toFilePath()}, '
      'which has no $asset',
    );
  }
  return file;
}

/// The release [asset], downloaded once into [cacheDir] and reused by every
/// build that asks for the same checksum. The assets of other releases are
/// pruned from [cacheDir] after it.
Future<File> _fetch(String asset, Uri cacheDir) async {
  final expected = _sha256[asset];
  if (expected == null || expected.isEmpty) {
    throw StateError('mpv_audio_kit: no SHA-256 pinned for $asset');
  }
  final file = await fetchPinned(
    asset: asset,
    release: _release,
    url: '$_baseUrl/$asset',
    sha256Hex: expected,
    cacheDir: cacheDir,
  );
  await pruneCache(cacheDir, _sha256.values);
  return file;
}

/// Copies the libmpv binary of the xcframework slice, unpacked from [zip]
/// into [dir] and checked by [unpackedBinary], into [out], thinned to
/// [arch] when the slice is universal: Flutter runs the hook once per
/// architecture and merges the results itself.
Future<void> _extractAppleSlice(
  File zip,
  Directory dir,
  _Target target,
  Architecture arch,
  File out, {
  String? zipSha256,
}) async {
  // A macOS framework keeps its binary under Versions/; the path returned
  // follows the link.
  final binary = await unpackedBinary(
    zip,
    dir,
    'libmpv.xcframework/${target.appleSlice}/libmpv.framework/libmpv',
    zipSha256: zipSha256,
  );
  final lipoArch = switch (arch) {
    Architecture.arm64 => 'arm64',
    Architecture.x64 => 'x86_64',
    _ => throw UnsupportedError('mpv_audio_kit: no Apple slice for $arch'),
  };
  final archs = (await _run('lipo', ['-archs', binary])).trim().split(' ');
  if (archs.length == 1) {
    if (archs.single != lipoArch) {
      throw StateError(
        'mpv_audio_kit: $binary is ${archs.single}, '
        'the build wants $lipoArch',
      );
    }
    await File(binary).copy(out.path);
  } else {
    await _run('lipo', [binary, '-thin', lipoArch, '-output', out.path]);
  }
}

Future<String> _run(String executable, List<String> arguments) async {
  final result = await Process.run(executable, arguments);
  if (result.exitCode != 0) {
    throw ProcessException(
      executable,
      arguments,
      '${result.stderr}',
      result.exitCode,
    );
  }
  return result.stdout as String;
}
