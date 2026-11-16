// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import '../internals/unset_sentinel.dart';

/// EBU R128 loudness measurement snapshot, in LUFS / LU.
///
/// Emitted on `PlayerStream.loudnessMeter` while the `ebur128` audio effect is
/// enabled with its `metadata` option on — the meter runs inside the audio
/// chain and the player polls its per-frame measurements. Each field is
/// `null` until the corresponding window has accumulated enough audio.
class Loudness {
  /// Momentary loudness (400 ms window), in LUFS.
  final double? momentary;

  /// Short-term loudness (3 s window), in LUFS.
  final double? shortTerm;

  /// Integrated (programme) loudness since the meter started, in LUFS.
  final double? integrated;

  /// Loudness range (LRA), in LU.
  final double? range;

  /// Creates a loudness snapshot.
  const Loudness({
    this.momentary,
    this.shortTerm,
    this.integrated,
    this.range,
  });

  /// Returns a copy with the given fields replaced.
  Loudness copyWith({
    Object? momentary = unset,
    Object? shortTerm = unset,
    Object? integrated = unset,
    Object? range = unset,
  }) =>
      Loudness(
        momentary:
            identical(momentary, unset) ? this.momentary : momentary as double?,
        shortTerm:
            identical(shortTerm, unset) ? this.shortTerm : shortTerm as double?,
        integrated: identical(integrated, unset)
            ? this.integrated
            : integrated as double?,
        range: identical(range, unset) ? this.range : range as double?,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Loudness &&
          other.momentary == momentary &&
          other.shortTerm == shortTerm &&
          other.integrated == integrated &&
          other.range == range);

  @override
  int get hashCode => Object.hash(momentary, shortTerm, integrated, range);

  @override
  String toString() => 'Loudness(momentary: $momentary, shortTerm: $shortTerm, '
      'integrated: $integrated, range: $range)';
}
