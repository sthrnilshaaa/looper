// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

/// Capabilities to advertise to the operating system's media session
/// (lockscreen controls, Bluetooth AVRCP, headset buttons, …).
///
/// Pass a [Set] of these via [MediaSession.actions] to control
/// which buttons appear. The actual command delivery — what arrives on
/// [PlayerStream.mediaSessionCommands] when the user taps — is governed
/// by which platform exposes which action; some surfaces (e.g. a
/// Bluetooth headset's hardware play button) ignore the advertised set
/// and fire [playPause] regardless.
///
/// **Which actions actually render differs sharply per platform** — e.g.
/// macOS Control Center draws no stop / repeat / shuffle / rate / like
/// control, and Android's system notification auto-renders only transport +
/// seek bar. Advertising an action it doesn't render is harmless (it's just
/// not drawn). See the README's *OS media session* section for the full
/// per-platform support matrix.
enum MediaAction {
  /// Start playback. Default-on.
  play,

  /// Pause playback. Default-on.
  pause,

  /// Toggle between play and pause. Sent by single-button hardware
  /// (most Bluetooth headsets) and by the spacebar key on macOS.
  playPause,

  /// Stop playback and clear the now-playing entry. Default-off — most
  /// music apps do not expose stop on the lockscreen; including it
  /// causes the OS to allocate UI space for a third button alongside
  /// the existing play/pause and seek.
  stop,

  /// Skip to the next track. See [MediaSession.actions] for the
  /// "next" semantics — by default, the package routes this to mpv's
  /// `playlist-next` when a playlist is loaded, otherwise emits on
  /// [PlayerStream.mediaSessionCommands] for the consumer to handle.
  next,

  /// Skip to the previous track. Symmetric to [next].
  previous,

  /// Seek to an absolute position. Required for the scrubber bar on
  /// iOS/macOS lockscreen, Windows SMTC progress, and the seek gesture
  /// on Android Auto.
  seek,

  /// Skip forward by a fixed interval (typically 15 or 30 seconds).
  /// Distinct from [seek] (absolute) and [next] (track-level).
  fastForward,

  /// Skip backward by a fixed interval. Symmetric to [fastForward].
  rewind,

  /// Cycle repeat mode (off / file / playlist) from the OS UI. iOS /
  /// macOS render this as the loop icon in the Now Playing widget;
  /// Android renders it in MediaStyle notifications; MPRIS exposes it
  /// via `LoopStatus`. Command arrives as [MediaSessionCommandSetRepeatMode].
  setRepeatMode,

  /// Toggle shuffle on/off from the OS UI. Same surfaces as
  /// [setRepeatMode]. Command arrives as [MediaSessionCommandSetShuffle].
  setShuffle,

  /// Change playback speed from the OS UI (typically a 1x / 1.5x / 2x
  /// rotary in Now Playing). The set of selectable rates is governed
  /// by [MediaSession.supportedPlaybackRates]. Command arrives as
  /// [MediaSessionCommandSetPlaybackRate].
  setPlaybackRate,

  /// "Like" / favourite feedback (Apple `MPFeedbackCommand.likeCommand`).
  ///
  /// Rendered only on the iOS lock-screen Now Playing (and CarPlay / watchOS):
  /// the macOS Control Center widget and Windows SMTC draw no feedback button,
  /// Linux MPRIS has no like concept, and Android's system controls have no
  /// built-in like slot.
  ///
  /// The press arrives as [MediaSessionCommandLike] on
  /// [PlayerStream.mediaSessionCommands] — emit-only (not auto-applied, since
  /// there is no built-in favourite concept). Reflect the chosen state back
  /// via [MediaSession.isFavorite] to fill or empty the star.
  like,
}
