// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

/// Aggregate of mpv's three demuxer-buffering properties
/// (`demuxer-max-bytes`, `demuxer-max-back-bytes`, `demuxer-readahead-secs`).
///
/// Apply atomically via [Player.setDemuxer]. For one-off tweaks use
/// `state.demuxer.copyWith(...)`. Read the current configuration via
/// [PlayerState.demuxer] or observe live changes via [PlayerStream.demuxer].
final class DemuxerSettings {
  /// Maximum bytes the demuxer is allowed to cache ahead of the playhead.
  /// Default 150 MiB (mpv's `--demuxer-max-bytes=150MiB`). Forwarded as a raw
  /// byte count, so sub-MiB precision is preserved (mpv accepts plain integers
  /// and SI / IEC suffixes interchangeably).
  final int maxBytes;

  /// Maximum bytes of already-played content kept buffered for instant
  /// seekback. Default 50 MiB (mpv's `--demuxer-max-back-bytes=50MiB`). Set to
  /// `0` on live / radio streams where seeking back is never needed.
  final int maxBackBytes;

  /// Minimum amount of audio the demuxer keeps buffered ahead of the playhead.
  /// Default 1 second (mpv's `--demuxer-readahead-secs=1`). mpv's option is
  /// fractional seconds, so sub-second [Duration]s are honoured (not
  /// truncated).
  final Duration readahead;

  /// Creates a demuxer configuration. Each default mirrors the corresponding
  /// mpv property default.
  const DemuxerSettings({
    this.maxBytes = 150 * 1024 * 1024,
    this.maxBackBytes = 50 * 1024 * 1024,
    this.readahead = const Duration(seconds: 1),
  });

  /// Returns a copy with the given fields replaced. Omitted fields keep their
  /// current value.
  DemuxerSettings copyWith({
    int? maxBytes,
    int? maxBackBytes,
    Duration? readahead,
  }) =>
      DemuxerSettings(
        maxBytes: maxBytes ?? this.maxBytes,
        maxBackBytes: maxBackBytes ?? this.maxBackBytes,
        readahead: readahead ?? this.readahead,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DemuxerSettings &&
          other.maxBytes == maxBytes &&
          other.maxBackBytes == maxBackBytes &&
          other.readahead == readahead);

  @override
  int get hashCode => Object.hash(maxBytes, maxBackBytes, readahead);

  @override
  String toString() =>
      'DemuxerSettings(maxBytes: $maxBytes, maxBackBytes: $maxBackBytes, '
      'readahead: $readahead)';
}
