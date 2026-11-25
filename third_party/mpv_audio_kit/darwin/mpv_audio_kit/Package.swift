// swift-tools-version: 5.9
// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
//
// libmpv is not part of this package: the build hook (hook/build.dart)
// downloads it and Flutter bundles it with the app as a code asset.
//
// One package for iOS and macOS: pubspec.yaml sets sharedDarwinSource, so
// Flutter reads the plugin from darwin/ on both.

import PackageDescription

let package = Package(
    name: "mpv_audio_kit",
    platforms: [
        .iOS("15.0"),
        .macOS("12.0"),
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
            ],
            path: "Sources/mpv_audio_kit",
            // Apple privacy manifest, embedded into the built bundle.
            // .process places it at the bundle root.
            resources: [
                .process("PrivacyInfo.xcprivacy"),
            ],
            linkerSettings: [
                // MediaPlayer hosts MPNowPlayingInfoCenter and
                // MPRemoteCommandCenter, the lockscreen and Control Center
                // Now Playing entry. AVFoundation is needed on iOS for
                // AVAudioSession (interruption handling).
                .linkedFramework("MediaPlayer"),
                .linkedFramework("AVFoundation", .when(platforms: [.iOS])),
            ]
        ),
    ]
)
