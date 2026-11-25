// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

/// How the player reacts when the OS interrupts audio: a phone call,
/// Siri, an alarm, or another app taking audio focus. Set via
/// [MediaSession.interruptionPolicy].
///
/// **Platform reach:** honoured on iOS (`AVAudioSession`), Android (audio
/// focus) and the web, where the interruption is a pause of the media
/// session's `<audio>` element from outside the page's output (the
/// browser, a call, another app) and the end of it the browser playing
/// that element again, or the page's audio running again after an
/// interruption (iOS). macOS, Linux and Windows have no per-app audio
/// session, so the policy is a no-op there; the OS arbitrates routing
/// itself.
///
/// Under every policy the player keeps playing when another app asks it
/// to duck, such as a navigation prompt: Android 8 and later lower the
/// volume on their own, while on Android 7 (API 24 and 25) the player
/// stays at full volume.
enum InterruptionPolicy {
  /// Pause on an interruption and resume afterwards when the OS signals
  /// it is safe (iOS `shouldResume`, Android focus regain). The default.
  pauseAndResume,

  /// Pause on an interruption but never auto-resume: playback stays
  /// paused until the user resumes it manually.
  pauseOnly,

  /// Never auto-pause for an interruption: keep playing at full volume.
  /// On iOS this also asks the system not to pre-empt playback for
  /// incidental alerts. A headphone unplug still pauses (Apple HIG).
  ///
  /// Honest limits: an accepted phone or FaceTime call or Siri still
  /// takes the audio route on iOS (that cannot be overridden) and on
  /// Android 12+ the system may fade the app out when another app gains
  /// focus.
  ///
  /// Observability: because this policy never pauses, an interruption
  /// emits NO command on [PlayerStream.mediaSessionCommands].
  keepPlaying,
}
