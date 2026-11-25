// swift-tools-version: 5.9
// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
//
// The tvOS plugin, which flutter-tvos (https://fluttertv.dev) reads from
// tvos/Package.swift. Sources/ holds copies of darwin/'s, which
// test/packaging/darwin_package_test.dart keeps identical: SwiftPM takes
// no target outside the package root, and dart pub publish does not keep
// a symlink.
//
// On tvOS libmpv comes from here, not from the build hook: flutter-tvos
// runs the hook but installs none of its code assets. The package links
// libmpv_tvos.xcframework.zip of the release, which SwiftPM downloads and
// checks against `checksum`, both written by scripts/update_libmpv.sh;
// the Dart side binds it with @Native, whose symbols then resolve in the
// process. A libmpv build of your own (libmpv-scripts'
// build_libmpv_tvos.sh) placed at tvos/libmpv.xcframework is linked
// instead, like the hook's libmpv user define on the other platforms.

import Foundation
import PackageDescription

let release = "libmpv-r27"
let checksum = "14b1ce4754f3be5e80eb145998d5b79ba6baaa8b442c45b284a81df147656b89"

let local = FileManager.default.fileExists(
    atPath: Context.packageDirectory + "/libmpv.xcframework")

let package = Package(
    name: "mpv_audio_kit",
    platforms: [
        .tvOS("15.0"),
    ],
    products: [
        .library(name: "mpv-audio-kit", targets: ["mpv_audio_kit"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework"),
    ],
    targets: [
        .target(
            name: "mpv_audio_kit",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework"),
                "libmpv",
            ],
            path: "Sources/mpv_audio_kit",
            // Apple privacy manifest, embedded into the built bundle.
            resources: [
                .process("PrivacyInfo.xcprivacy"),
            ],
            linkerSettings: [
                // MediaPlayer hosts MPNowPlayingInfoCenter and
                // MPRemoteCommandCenter, AVFoundation the AVAudioSession.
                .linkedFramework("MediaPlayer"),
                .linkedFramework("AVFoundation"),
            ]
        ),
        local
            ? .binaryTarget(name: "libmpv", path: "libmpv.xcframework")
            : .binaryTarget(
                name: "libmpv",
                url: "https://github.com/ales-drnz/mpv_audio_kit/releases/download/\(release)/libmpv_tvos.xcframework.zip",
                checksum: checksum),
    ]
)
