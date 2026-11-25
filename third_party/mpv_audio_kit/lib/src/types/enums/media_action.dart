// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

/// Capabilities to advertise to the operating system's media session
/// (lockscreen controls, Bluetooth AVRCP, headset buttons, …).
///
/// Pass a [Set] of these via [MediaSession.actions] to control
/// which buttons appear. The actual command delivery (what arrives on
/// [PlayerStream.mediaSessionCommands] when the user taps) is governed
/// by which platform exposes which action; some surfaces (e.g. a
/// Bluetooth headset's hardware play button) ignore the advertised set
/// and fire [playPause] regardless.
///
/// **Which actions actually render differs sharply per platform**, e.g.
/// macOS Control Center draws no stop, repeat, shuffle, rate or like
/// control, and Android's system notification auto-renders only transport +
/// seek bar. Advertising an action it doesn't render is harmless (it's just
/// not drawn). See the Media session topic for the
/// per-platform table.
///
/// **How each platform reads the set.** The platforms do not map the
/// values the same way, and the differences below are the real ones:
///
/// - **iOS, tvOS and macOS**: one remote command per value. [play],
///   [pause] and [playPause] enable three separate commands, and each
///   arrives as its own command. A value left out is a command turned off.
/// - **Android**: any one of [play], [pause] and [playPause] enables the
///   single play and pause command of the session. The press arrives as
///   [MediaSessionCommandPlay] or [MediaSessionCommandPause], never as
///   [MediaSessionCommandPlayPause].
/// - **Windows**: [play] or [playPause] enables the Play button, [pause] or
///   [playPause] the Pause button. The press arrives as play or pause,
///   never as the toggle. A repeat, shuffle or rate request of the system
///   reaches the app whether [setRepeatMode], [setShuffle] or
///   [setPlaybackRate] is in the set or not.
/// - **Linux (MPRIS)**: `Play` wants [play] or [playPause], `Pause` wants
///   [pause] or [playPause], `Stop` wants [stop]. `PlayPause` arrives as
///   the toggle when [playPause] is in the set, otherwise as the declared
///   one of play and pause that the state calls for. `CanPlay` and
///   `CanPause` follow the same values. A write of `LoopStatus`, `Shuffle`
///   or `Rate` whose value is not in the set is refused with a D-Bus
///   error. A method whose value is not in the set is answered and
///   dropped.
/// - **Web**: [play] and [pause] each register their handler, [playPause]
///   registers both. The press arrives as play or pause. [setRepeatMode],
///   [setShuffle], [setPlaybackRate] and [like] have no handler in the
///   browser.
///
/// So a set with [play] alone gives play and pause on Android, play alone
/// elsewhere. The default set of [MediaSession.actions] holds the three of
/// them and behaves the same everywhere.
enum MediaAction {
  /// Start playback. Default-on. On Android it also enables pause (one
  /// command for both).
  play,

  /// Pause playback. Default-on. On Android it also enables play (one
  /// command for both).
  pause,

  /// Toggle between play and pause. Sent by single-button hardware
  /// (most Bluetooth headsets) and by the spacebar key on macOS.
  ///
  /// Arrives as [MediaSessionCommandPlayPause] on iOS, tvOS, macOS and
  /// Linux. Android, Windows and the web send play or pause in its place,
  /// and there this value enables both.
  playPause,

  /// Stop playback and clear the now-playing entry. Default-off: most
  /// music apps do not expose stop on the lockscreen; including it
  /// causes the OS to allocate UI space for a third button alongside
  /// the existing play-pause and seek. Without it the stop of the system
  /// (the Stop button of SMTC, the `Stop` method of MPRIS, the stop command
  /// of an Apple remote) does not reach the app on any platform.
  stop,

  /// Skip to the next track. The package routes this to mpv's
  /// `playlist-next` when the playlist holds more than one entry and
  /// [MediaSession.autoApplyPlaylistNavigation] is on (the default);
  /// otherwise it only emits on [PlayerStream.mediaSessionCommands], for
  /// the consumer to handle.
  next,

  /// Skip to the previous track. Symmetric to [next].
  previous,

  /// Seek to an absolute position. Required for the scrubber bar on
  /// iOS and macOS lockscreen, Windows SMTC progress, and the seek gesture
  /// on Android Auto.
  seek,

  /// Skip forward by a fixed interval (typically 15 or 30 seconds).
  /// Distinct from [seek] (absolute) and [next] (track-level).
  fastForward,

  /// Skip backward by a fixed interval. Symmetric to [fastForward].
  rewind,

  /// Cycle repeat mode (off, file or playlist) from the OS UI. The package
  /// registers it on every platform: the repeat command in Now Playing,
  /// a button in the Android notification, the SMTC repeat mode, and
  /// `LoopStatus` on MPRIS. Command arrives as [MediaSessionCommandSetRepeatMode].
  ///
  /// Without it Apple and Android turn the command off and Linux refuses
  /// the write of `LoopStatus`. Windows sends the request to the app
  /// either way. The web has no repeat control.
  setRepeatMode,

  /// Toggle shuffle on or off from the OS UI. Same surfaces as
  /// [setRepeatMode], with the same rule per platform (`Shuffle` on
  /// MPRIS). Command arrives as [MediaSessionCommandSetShuffle].
  setShuffle,

  /// Change playback speed from the OS UI (typically a 1x, 1.5x or 2x
  /// rotary in Now Playing). The set of selectable rates is governed
  /// by [MediaSession.supportedPlaybackRates]. Command arrives as
  /// [MediaSessionCommandSetPlaybackRate].
  ///
  /// Without it Apple and Android turn the command off and Linux refuses
  /// the write of `Rate`. Windows sends the request to the app either way.
  setPlaybackRate,

  /// "Like" or favourite feedback (Apple `MPFeedbackCommand.likeCommand`).
  ///
  /// Registered on iOS and macOS as the like command, and on Android as a
  /// custom heart button in the notification. Windows SMTC has no feedback
  /// button and Linux MPRIS has no like concept, so neither registers it.
  /// The macOS Control Center widget draws no feedback button.
  ///
  /// The press arrives as [MediaSessionCommandLike] on
  /// [PlayerStream.mediaSessionCommands], emit-only (not auto-applied, since
  /// there is no built-in favourite concept). Reflect the chosen state back
  /// via [MediaSession.isFavorite] to fill or empty the star.
  like,
}
