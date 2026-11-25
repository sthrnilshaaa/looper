// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'mpv_value.dart';

/// Lifecycle hook fired by mpv during file loading and unloading.
///
/// Seven phases you can intercept to lazily resolve a URL, attach
/// per-file HTTP headers, drive a fallback path, or react to a track
/// boundary.
///
/// Pass to [Player.registerHook] to subscribe; the matching
/// [MpvHookEvent] arrives on [PlayerStream.hook].
///
/// ```dart
/// player.registerHook(Hook.load);
/// player.stream.hook.listen((event) async {
///   try {
///     switch (event.hook) {
///       case Hook.load:
///       // Redirect the URL via stream-open-filename, attach
///       // file-local-options/http-header-fields, etc.
///       default:
///     }
///   } finally {
///     player.continueHook(event.id); // always, even on error
///   }
/// });
/// ```
///
/// {@category Hooks and raw access}
enum Hook {
  /// Before any per-file work begins. Drains any pending property
  /// changes from the previous file before the new `start-file`
  /// event fires.
  beforeStartFile('on_before_start_file'),

  /// Before a stream is opened. The most common interception point:
  /// rewrite `stream-open-filename` to redirect the URL, or set
  /// `file-local-options/http-header-fields` to attach per-file
  /// HTTP headers.
  ///
  /// It runs once per entry, when the entry starts. The early open of the
  /// next entry with `Player.setPrefetchPlaylist` runs [prefetch] instead.
  load('on_load'),

  /// After a stream failed to open. Useful for fallback URLs:
  /// rewrite `stream-open-filename` and mpv will retry.
  loadFail('on_load_fail'),

  /// File open, demuxer ready, but track selection and decoder
  /// init haven't run yet. Last chance to influence track choice
  /// via mpv's selection properties (`aid`, `vid`, `sid`).
  preloaded('on_preloaded'),

  /// Before a file is closed. Cleanup hook for resources tied to
  /// the current file. Cannot resume playback from this state.
  unload('on_unload'),

  /// After a file finished and was fully unloaded. The next file
  /// (if any) hasn't started yet.
  afterEndFile('on_after_end_file'),

  /// Before mpv opens the next entry ahead of time, while the current one
  /// plays (`Player.setPrefetchPlaylist`). The current entry keeps playing
  /// while the hook is held.
  ///
  /// Read `prefetch-open-filename` for the URL mpv will open, and write it
  /// to open another one; `prefetch-playlist-entry-id` is the id of the
  /// entry. Other properties, `path`, `stream-open-filename` and
  /// `file-local-options` among them, still belong to the playing entry.
  /// When the entry starts, [load] runs for it with its own URL in
  /// `stream-open-filename`: write there the URL given here, and mpv plays
  /// the opened stream.
  ///
  /// When the entry starts before the hook continues, or the playlist no
  /// longer has it next, mpv drops the early open: both properties become
  /// unavailable and the continue does nothing.
  ///
  /// Until the hook continues, dropped or not, no other entry opens ahead
  /// of time, not even after an open or openAll: a listener that never
  /// continues takes the prefetch away from every entry after it. Pass a
  /// `timeout` to `Player.registerHook` for this hook.
  prefetch('on_prefetch');

  const Hook(this.mpvValue);

  /// The wire-level name mpv expects in `mpv_hook_add()`.
  final String mpvValue;

  /// Maps an mpv-side hook name to the typed enum. Returns `null` for
  /// unknown values, forward-compat with future mpv builds that may
  /// add new hook phases (a warning is logged and the hook auto-
  /// continues so mpv never stalls).
  static Hook? fromMpv(String raw) =>
      byMpvValue(values, raw, (v) => v.mpvValue);
}
