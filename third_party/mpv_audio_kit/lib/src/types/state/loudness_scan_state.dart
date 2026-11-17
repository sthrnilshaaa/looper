// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

/// Lifecycle of the offline loudness scan observed on
/// `PlayerStream.loudness`.
enum LoudnessScanState {
  /// No scan has run for the current source.
  idle,

  /// The scan is decoding the file.
  scanning,

  /// The scan finished — the measurement fields are populated.
  ready,

  /// The scan could not complete (decode error).
  failed,

  /// The source cannot be scanned up-front (adaptive / live /
  /// non-seekable stream) — use the live `PlayerStream.loudnessMeter`
  /// instead.
  unavailable;

  /// The mpv wire value of this state.
  String get mpvValue => name;

  /// Parses an mpv wire value; unknown values fall back to [idle].
  static LoudnessScanState fromMpv(String value) => switch (value) {
        'scanning' => LoudnessScanState.scanning,
        'ready' => LoudnessScanState.ready,
        'failed' => LoudnessScanState.failed,
        'unavailable' => LoudnessScanState.unavailable,
        _ => LoudnessScanState.idle,
      };
}
