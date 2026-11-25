#
# mpv_audio_kit podspec, for iOS and macOS.
#
# Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
# All rights reserved.
# Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
#
# libmpv is not part of this pod: the package's build hook
# (hook/build.dart) downloads it and Flutter bundles it with the app as
# libmpv_audio_kit.framework, a code asset the Dart side binds with @Native.
#
# A Flutter plugin ships both dependency-manager manifests, this podspec
# (CocoaPods) and mpv_audio_kit/Package.swift (Swift Package Manager), and
# the consuming app's setup decides which one Flutter uses. pubspec.yaml
# sets sharedDarwinSource, so both platforms read them from darwin/.
#

Pod::Spec.new do |s|
  s.name             = 'mpv_audio_kit'
  s.version          = '0.8.0'
  s.summary          = 'Flutter audio player powered by libmpv.'
  s.description      = <<-DESC
    Supports audio filters, pitch control, equalizer, and all mpv audio features.
  DESC
  s.homepage         = 'https://github.com/ales-drnz/mpv_audio_kit'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'mpv_audio_kit' => 'ales.drnz@gmail.com' }

  s.source           = { :path => '.' }
  # The same Swift sources as the Swift package.
  s.source_files     = 'mpv_audio_kit/Sources/mpv_audio_kit/**/*.swift'
  # Apple privacy manifest. Shipped as a CocoaPods resource bundle so it is
  # embedded (and codesigned) into the built framework. Kept out of `source_files` (which is `*.swift`) so
  # it isn't double-referenced.
  s.resource_bundles = {
    'mpv_audio_kit_privacy' => ['mpv_audio_kit/Sources/mpv_audio_kit/PrivacyInfo.xcprivacy'],
  }

  s.ios.dependency 'Flutter'
  s.osx.dependency 'FlutterMacOS'

  s.ios.deployment_target = '15.0'
  s.osx.deployment_target = '12.0'

  # MediaPlayer hosts MPNowPlayingInfoCenter and MPRemoteCommandCenter, the
  # lockscreen, Control Center and CarPlay Now Playing entry. AVFoundation
  # is needed on iOS for AVAudioSession (audio interruption handling).
  s.ios.frameworks = 'MediaPlayer', 'AVFoundation'
  s.osx.frameworks = 'MediaPlayer'

  s.swift_version         = '5.0'
  s.pod_target_xcconfig   = { 'DEFINES_MODULE' => 'YES' }
end
