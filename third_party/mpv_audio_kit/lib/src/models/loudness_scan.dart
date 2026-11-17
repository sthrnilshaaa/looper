// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import '../types/state/loudness_scan_state.dart';

/// Result of the offline loudness scan (EBU R128 / ITU-R BS.1770) of the
/// loaded source, emitted on `PlayerStream.loudness`.
///
/// Unlike the live `PlayerStream.loudnessMeter` — which measures audio as
/// it plays — the scan decodes the whole file off the playback path at
/// many times realtime, so the integrated loudness of the entire track is
/// known moments after the file loads. Use it to normalize playback volume
/// for tracks without ReplayGain tags:
///
/// ```dart
/// player.stream.loudness.listen((scan) {
///   if (scan?.state == LoudnessScanState.ready) {
///     final gainDb = -18.0 - scan!.integrated!; // ReplayGain 2.0 reference
///     player.setVolumeGain(gainDb.clamp(-24.0, 24.0));
///   }
/// });
/// ```
///
/// The measurement fields are non-null only when [state] is
/// [LoudnessScanState.ready].
class LoudnessScan {
  /// Scan lifecycle state. The stream emits [LoudnessScanState.scanning]
  /// snapshots (carrying [progress]) while the scan runs, then a terminal
  /// state ([LoudnessScanState.ready], [LoudnessScanState.failed],
  /// [LoudnessScanState.unavailable]).
  final LoudnessScanState state;

  /// Integrated (programme) loudness of the whole track, in LUFS.
  final double? integrated;

  /// Loudness range (LRA, EBU Tech 3342), in LU.
  final double? range;

  /// Highest absolute sample value, linear (1.0 = full scale).
  final double? samplePeak;

  /// Highest inter-sample (true) peak, linear, measured on the
  /// 4× oversampled signal per BS.1770.
  final double? truePeak;

  /// Number of 400 ms blocks that survived the BS.1770 gating — a
  /// confidence indicator (0 means the track never rose above the
  /// silence gate and [integrated] is pinned at -70 LUFS).
  final int? gatedBlockCount;

  /// Scan progress in `[0, 1]` while [state] is [LoudnessScanState.scanning]
  /// (`1.0` at [LoudnessScanState.ready]). `null` when the engine did not
  /// report it. Use it to drive a progress indicator; a `null` value means
  /// show an indeterminate one.
  final double? progress;

  /// Creates a scan result snapshot.
  const LoudnessScan({
    required this.state,
    this.integrated,
    this.range,
    this.samplePeak,
    this.truePeak,
    this.gatedBlockCount,
    this.progress,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LoudnessScan &&
          other.state == state &&
          other.integrated == integrated &&
          other.range == range &&
          other.samplePeak == samplePeak &&
          other.truePeak == truePeak &&
          other.gatedBlockCount == gatedBlockCount &&
          other.progress == progress);

  @override
  int get hashCode => Object.hash(
        state,
        integrated,
        range,
        samplePeak,
        truePeak,
        gatedBlockCount,
        progress,
      );

  @override
  String toString() => 'LoudnessScan(state: $state, integrated: $integrated, '
      'range: $range, samplePeak: $samplePeak, truePeak: $truePeak, '
      'gatedBlockCount: $gatedBlockCount, progress: $progress)';
}
