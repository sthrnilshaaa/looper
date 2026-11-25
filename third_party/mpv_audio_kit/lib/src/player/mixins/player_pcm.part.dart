// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
part of '../player.dart';

/// Live PCM input: [openPcmStream] creates a [PcmSource] and opens it. The
/// player holds every source whose media it loaded while the entry is in
/// its playlist ([_PlayerBase._entries]), so a source the app no longer
/// references still plays, and ends a source as stopped when its entry
/// leaves the playlist unread or the player is disposed. The cut of a
/// source being aborted lives in `_PcmCutModule`.
mixin _PcmModule on _PlayerBase, _OpenModule {
  /// Creates a live [PcmSource] of [format] and opens it as the sole
  /// playlist entry, like [Player.open] with its [PcmSource.toMedia].
  /// Feed the returned source and [PcmSource.close] it when the input
  /// ends: the entry then ends normally after the last sample. When
  /// [play] is null [PlayerConfiguration.autoPlay] decides, as for
  /// [Player.open].
  ///
  /// Playback starts a fraction of a second after the first chunk, once
  /// the audio output buffer is full (see [PcmSource]). [maxBuffered] and
  /// [lowLatency] are those of [PcmSource.create], [extras] that of
  /// [PcmSource.toMedia].
  ///
  /// When a later `open()` or `stop()` takes over before this one loads,
  /// the source ends as [PcmSourceState.stopped]. To queue several sources
  /// back to back, create them with [PcmSource.create] and pass their
  /// media to [Player.openAll] or [Player.add].
  ///
  /// On the web it waits for the libmpv module to load, which
  /// [PcmSource.create] cannot do.
  ///
  /// ```dart
  /// final source = await player.openPcmStream(
  ///   const PcmFormat(sampleRate: 24000, channels: 1),
  ///   play: true,
  /// );
  /// socket.listen(
  ///   (message) => source.add(message as Uint8List),
  ///   onDone: source.close,
  /// );
  /// ```
  Future<PcmSource> openPcmStream(
    PcmFormat format, {
    bool? play,
    Duration maxBuffered = const Duration(seconds: 30),
    bool lowLatency = false,
    Map<String, Object?>? extras,
  }) async {
    _checkNotDisposed();
    // Statements, not `?.` with an await: see [play].
    final loading = backendReady();
    if (loading != null) await loading;
    final source = PcmSource.create(
      format,
      maxBuffered: maxBuffered,
      lowLatency: lowLatency,
    );
    try {
      // As [Player.open] runs it.
      final media = source.toMedia(extras: extras);
      await _transport.trackLoad(() => _open(media, play));
    } catch (_) {
      source.abort();
      rethrow;
    }
    // Superseded by a later open() or stop(), or a dispose: no entry, so
    // no reader will ever come.
    if (_disposed || !_entries.holdsLive(source)) source.endUnread();
    return source;
  }
}
