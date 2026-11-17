// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

#if os(iOS)
import Flutter
import UIKit
#elseif os(macOS)
import Cocoa
import FlutterMacOS
#endif

/// Apple (iOS + macOS) entry point of the mpv_audio_kit Flutter plugin.
///
/// Most of the package's surface is delivered via direct FFI calls to
/// `libmpv`; this class only exists to:
///
/// - register the `mpv_audio_kit` method channel (unused on Apple — its
///   only method, `openFileDescriptor` for `content://` URIs, is
///   Android-only), and
/// - hand control off to `MediaSessionPlugin.register(with:)` so the
///   OS Now Playing widget / Control Center / lockscreen integration
///   gets wired up alongside the core plugin.
public class MpvAudioKitPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    #if os(iOS)
    let messenger = registrar.messenger()
    #elseif os(macOS)
    let messenger = registrar.messenger
    #endif

    let channel = FlutterMethodChannel(
      name: "mpv_audio_kit", binaryMessenger: messenger)
    let instance = MpvAudioKitPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)

    MediaSessionPlugin.register(with: registrar)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    // The `mpv_audio_kit` channel carries no methods on Apple; libmpv is
    // driven via FFI from Dart.
    result(FlutterMethodNotImplemented)
  }
}
