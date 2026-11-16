// swift-tools-version: 5.9
// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
//
// libmpv ships as a dynamic .xcframework, consumed via a SwiftPM
// .binaryTarget. Two interchangeable forms — keep exactly ONE active:
//
//   • url + checksum — downloads the xcframework from this package's
//     GitHub Releases. The standard practice for a distributed binary;
//     use this once the release zip is published.
//   • path — uses a libmpv.xcframework already in Frameworks/. Use
//     this to test a local libmpv build before publishing a release.

import PackageDescription

let package = Package(
    name: "mpv_audio_kit",
    platforms: [
        .iOS("15.0")
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
                "libmpv",
                .product(name: "FlutterFramework", package: "FlutterFramework"),
            ],
            // The Swift here is real-file copies, intentionally NOT
            // symlinks: `dart pub publish` flattens symlinks into regular
            // files whose body is the link-target path, which then fails to
            // compile in the consumer's Xcode. (SwiftPM also rejects a
            // `path:` that escapes the package root, ruling out one shared
            // dir.)
            path: "Sources/mpv_audio_kit",
            // Apple privacy manifest, embedded into the built bundle —
            // required for App Store submission. A real per-platform file;
            // keep the iOS/macOS copies in sync by hand. .process places it
            // at the bundle root.
            resources: [
                .process("PrivacyInfo.xcprivacy"),
            ],
            linkerSettings: [
                // MediaPlayer hosts MPNowPlayingInfoCenter +
                // MPRemoteCommandCenter (lockscreen / Control Center
                // Now Playing entry). AVFoundation is needed for
                // AVAudioSession (interruption handling).
                .linkedFramework("MediaPlayer"),
                .linkedFramework("AVFoundation"),
            ]
        ),
        // The libmpv binary source is toggled by the build kit's "Libs"
        // actions (local / remote / clean). Exactly ONE region below is active
        // at a time — the kit comments/uncomments these blocks; do not hand-edit
        // the mpvkit: markers.
        // mpvkit:local:begin
        // .binaryTarget(
            // name: "libmpv",
            // path: "Frameworks/libmpv.xcframework"),
        // mpvkit:local:end
        // mpvkit:remote:begin
        .binaryTarget(
            name: "libmpv",
            url: "https://github.com/ales-drnz/mpv_audio_kit/releases/download/libmpv-r15/libmpv_ios.xcframework.zip",
            checksum: "d19ff4184753eefcda7e1cc0627f0aa0e34e0df5d2a2fca0dddb9b574f721b50"),
        // mpvkit:remote:end
    ]
)
