// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'package:meta/meta.dart';

import '../models/loudness_scan.dart';
import '../types/state/loudness_scan_state.dart';
import 'analysis_poll_pipeline.dart';

/// Offline loudness-scan pipeline: polls `loudness-scan-data` while
/// [PlayerStream.loudnessScan] has a listener (`loudness-scan-enabled`
/// on), see [AnalysisPollPipeline].
///
/// While the scan runs it emits `scanning` snapshots carrying a progress
/// fraction on each poll. As soon as it reaches a terminal state (`ready`,
/// `failed` or `unavailable`) the result is emitted via [stream] and the timer
/// stops until the next file load. On every file load the player calls
/// [reset]: the pipeline drops the current result, emits `null`, and
/// rearms the timer if still enabled.
@internal
class LoudnessScanPipeline extends AnalysisPollPipeline<LoudnessScan> {
  LoudnessScanPipeline({
    required super.asyncGet,
    required super.asyncSet,
    super.pollInterval,
  }) : super(
         enabledProperty: 'loudness-scan-enabled',
         dataProperty: 'loudness-scan-data',
       );

  // Last scanning fraction seen, to skip re-emitting unchanged progress.
  double? _lastScanProgress;

  @override
  void onDrop() => _lastScanProgress = null;

  // Only a ready scan: mpv keeps it for the same file, and decodes again
  // after a failed or unavailable one.
  @override
  bool keepsAcrossReload(LoudnessScan result) =>
      result.state == LoudnessScanState.ready;

  @override
  bool sameResult(LoudnessScan a, LoudnessScan b) => a == b;

  @override
  void onData(Map<Object?, Object?> value) {
    final state = value['state'];
    if (state is! String) return;

    double asDouble(Object? v) => v is num ? v.toDouble() : 0.0;
    int asInt(Object? v) => v is int ? v : 0;

    double? asFraction(Object? v) =>
        v is num ? v.toDouble().clamp(0.0, 1.0) : null;

    final parsed = LoudnessScanState.fromMpv(state);
    switch (parsed) {
      case LoudnessScanState.ready:
        finish(
          LoudnessScan(
            state: LoudnessScanState.ready,
            integrated: asDouble(value['integrated_lufs']),
            range: asDouble(value['lra_lu']),
            samplePeak: asDouble(value['sample_peak']),
            truePeak: asDouble(value['true_peak']),
            gatedBlockCount: asInt(value['gated_block_count']),
            progress: 1.0,
          ),
        );
      case LoudnessScanState.failed:
      case LoudnessScanState.unavailable:
        finish(LoudnessScan(state: parsed));
      case LoudnessScanState.scanning:
        // Non-terminal: surface a progress snapshot and keep polling until
        // a terminal state lands. De-dup on the fraction to avoid UI churn.
        final progress = asFraction(value['progress']);
        if (progress != _lastScanProgress) {
          _lastScanProgress = progress;
          final scan = LoudnessScan(
            state: LoudnessScanState.scanning,
            progress: progress,
          );
          emit(scan);
        }
        return;
      case LoudnessScanState.idle:
        return; // non-terminal, keep polling
    }
  }
}
