// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
part of '../player.dart';

/// The audio tracks (selection, external files) and the cover-art display
/// options.
mixin _TracksModule on _PlayerBase {
  /// Selects the audio track via a typed [Track]:
  /// [Track.auto] defers to mpv's automatic choice
  /// (container default or first audio track),
  /// [Track.off] disables audio output entirely, and
  /// [Track.id] selects a specific track by its mpv ID
  /// (match an entry in [FileState.tracks]).
  ///
  /// State updates flow through the `current-tracks/audio` observer
  /// (no optimistic update: mpv may reject an unknown id).
  Future<void> setAudioTrack(Track track) async {
    await _gate();
    await _calls.prop('aid', track.mpvValue);
  }

  /// Loads an external audio file as an additional selectable track on the
  /// currently-playing file (mpv's `audio-add`), e.g. a separate-language
  /// dub or a commentary track. The new track appears in
  /// [FileState.tracks]; switch to it with [setAudioTrack].
  ///
  /// [select] `true` (default) selects the new track immediately; `false`
  /// adds it without switching. [title] and [lang] tag it for the track list.
  /// Per-[Media] options (`httpHeaders`, …) are validated but not applied:
  /// `audio-add` has no file-local options slot.
  ///
  /// Throws [MpvCommandException] when mpv refuses the track: a file it
  /// cannot open, or no file loaded to add it to.
  Future<void> addAudioTrack(
    Media file, {
    bool select = true,
    String? title,
    String? lang,
  }) async {
    _checkNotDisposed();
    rejectPcm(file, 'file');
    validateLoadOptions(file);
    // Snapshot the load epoch: a content-replacing call landing while the
    // URI resolves makes this add stale: the track belongs to the file
    // that is no longer playing (see [Player.open]).
    final load = _transport.snapshotLoad();
    await _gate();
    final source = OwnedSource(await resolveUri(file.uri));
    // The call's to release until the track takes it over.
    try {
      if (load.superseded) return;
      final args = <String>[
        'audio-add',
        source.uri,
        select ? 'select' : 'auto',
      ];
      // mpv's args are positional: to pass `lang` you must also pass `title`.
      if (title != null || lang != null) args.add(title ?? '');
      if (lang != null) args.add(lang);
      // An Android content:// URI arrives as an fd:// descriptor that mpv
      // never closes: held until the file the track joins ends.
      final dispose = source.handOver();
      final settle = dispose == null ? null : _entries.holdTrack(dispose);
      var rc = -1;
      try {
        rc = await _calls.command(args);
      } finally {
        await settle?.call(rc >= 0);
      }
      if (rc < 0) {
        throw MpvCommandException(
          name: 'audio-add',
          code: rc,
          message: _calls.errorString(rc),
        );
      }
    } finally {
      await source.release();
    }
  }

  /// Removes an audio track (mpv's `audio-remove`). Pass [Track.id] to remove
  /// a specific track (typically one added via [addAudioTrack]); [Track.auto]
  /// removes the currently-selected audio track. The track-list observer
  /// folds the removal back into [FileState.tracks].
  ///
  /// [Track.off] is rejected with an [ArgumentError]: mpv's `audio-remove`
  /// takes an optional track id and has no "off" notion, so removing "no
  /// track" is meaningless. Use [setAudioTrack] with [Track.off] to mute the
  /// selection instead.
  ///
  /// Throws [MpvCommandException] when mpv refuses: an id with no audio
  /// track, or no track to remove.
  Future<void> removeAudioTrack(Track track) async {
    _checkNotDisposed();
    if (track is TrackOff) {
      throw ArgumentError.value(
        track,
        'track',
        'Track.off has no meaning for removeAudioTrack: pass Track.id to '
            'remove a specific track or Track.auto to remove the current one.',
      );
    }
    await _gate();
    await _calls.commandChecked(
      track is TrackId
          ? ['audio-remove', '${track.trackId}']
          : ['audio-remove'],
    );
  }

  /// Re-scans the external files next to the current file: mpv's
  /// `rescan-external-files`. With [keepSelection] the current track
  /// selection is preserved; otherwise mpv reselects the default streams.
  ///
  /// It loads only what mpv's auto-load options allow, and the player's
  /// defaults allow none of it: cover images need [setCoverArtAuto], and
  /// companion audio files need mpv's `audio-file-auto`, set with
  /// [Player.setRawProperty]. What it finds shows in [FileState.tracks]
  /// only; a cover image does not reach [PlayerStream.coverArt].
  Future<void> rescanExternalFiles({bool keepSelection = false}) async {
    await _gate();
    await _calls.commandChecked([
      'rescan-external-files',
      keepSelection ? 'keep-selection' : 'reselect',
    ]);
  }

  // ── Cover Art ──────────────────────────────────────────────────────────────

  /// Controls whether mpv automatically loads external cover art files
  /// sitting next to the audio file (e.g. `cover.jpg`) as extra tracks.
  /// See [Cover] for the available variants. A loaded image shows in
  /// [FileState.tracks] with `albumArt` and `externalFilename` set; it
  /// does not reach [PlayerStream.coverArt], which carries only embedded
  /// cover bytes, whatever this setting.
  Future<void> setCoverArtAuto(Cover cover) async {
    await _write(
      'cover-art-auto',
      cover.mpvValue,
      _reactives.coverArtAuto,
      cover,
      (s) => s.copyWith(coverArtAuto: cover),
    );
  }
}
