# Changelog

All notable changes to Looper Player. Release pages: [GitHub Releases](https://github.com/SthrNilshaaa/looper/releases).

## [3.0.0]

### Added
- Player styles: Classic, Card, Arc and Linear, with accent, black or blurred-artwork backgrounds.
- Horizontal swipe on the player artwork to change songs.
- Queue sheet redesign: pinned now-playing card, dice shuffle of upcoming songs, swipe to remove, Related tab (local library matches).
- Smart crossfade with beat-aware transition planning.
- Headphone correction (AutoEQ) and per-output EQ profiles applied when the audio output changes.
- ReplayGain volume normalization (track and album modes).
- Bit-perfect status and Bluetooth codec in the audio quality details.
- Lyrics sources: BetterLyrics, BetterLyrics (QQ), PaxSenix, BiniLyrics, Unison.
- "Wrong lyrics": skip the current lyrics source for a song.
- Home section reorder mode (hold Home).
- Account screen with name and profile photo.
- Keep screen awake and high refresh rate options.
- Custom playlist cover photos; whole-app UI scale on Android.

### Changed
- New setup flow (4 steps), settings and About screens.
- Favorites and History load one page (100 songs) at a time.
- Home and Songs skeleton loaders match the real layout.
- Progress wave throttled to 30 fps and paused in the background; word-synced lyrics redraw less often.
- Periodic playback database writes throttled; home widget lyric lookup skipped when no widget is pinned.
- Setup strings translated into all 14 languages.
- Bottom sheets follow the blur settings consistently.

### Fixed
- Playback asked for Music & Audio access even with All Files Access granted (GitHub build).
- Setup showed only All Files Access on the GitHub build; Music & Audio is now offered too.
- Favorite state could flip back after toggling quickly.
- Crash from images with NaN or infinite sizes.

## [2.7.5]

See [release notes](media/release-notes/2.7.5.md).

## [2.7.4]

See [release notes](media/release-notes/2.7.4.md).

[3.0.0]: https://github.com/SthrNilshaaa/looper/compare/2.7.5...3.0.0
[2.7.5]: https://github.com/SthrNilshaaa/looper/compare/2.7.4...2.7.5
[2.7.4]: https://github.com/SthrNilshaaa/looper/releases/tag/2.7.4
