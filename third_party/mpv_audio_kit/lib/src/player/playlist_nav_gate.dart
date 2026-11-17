// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

/// Decides whether an OS media-session *next* / *previous* command should
/// drive mpv's playlist directly.
///
/// True only when BOTH hold:
/// - the app has not opted out via `MediaSession.autoApplyPlaylistNavigation`
///   (a `null` config means "not set" → the default `true` applies); and
/// - the active playlist has more than one entry — a lone entry has nowhere to
///   navigate, so the command is left for the consumer's own queue logic.
///
/// When this returns `false` the command is emit-only (still surfaced on
/// [PlayerStream.mediaSessionCommands]); the package does not call
/// `Player.next` / `Player.previous`.
bool shouldAutoApplyPlaylistNav({
  required bool? autoApplyPlaylistNavigation,
  required int playlistLength,
}) =>
    (autoApplyPlaylistNavigation ?? true) && playlistLength > 1;
