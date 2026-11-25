// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

part '../../generated/library_versions_data.dart';

/// The versions of the libmpv and FFmpeg the player runs on.
///
/// The [PlayerState.versions] of a player: read it from `player.state.versions`,
/// or follow one value through its stream in `player.stream`.
///
/// {@category State and streams}
final class LibraryVersions with _$LibraryVersions {
  /// Version of mpv linked into the current build (e.g. `0.42.0`).
  /// Read once at first observe and stable for the lifetime of the
  /// [Player]. Mirrors mpv's `mpv-version`.
  final String mpvVersion;

  /// Version of FFmpeg linked into the current mpv build.
  /// Read once at first observe. Mirrors mpv's `ffmpeg-version`.
  final String ffmpegVersion;

  /// Creates a [LibraryVersions]; each value defaults to the one of a player that
  /// has loaded nothing.
  const LibraryVersions({this.mpvVersion = '', this.ffmpegVersion = ''});
}
