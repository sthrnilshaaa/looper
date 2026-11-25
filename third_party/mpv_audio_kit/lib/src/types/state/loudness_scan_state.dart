// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import '../enums/mpv_value.dart';

/// Lifecycle of the offline loudness scan observed on
/// `PlayerStream.loudnessScan`.
enum LoudnessScanState {
  /// No scan has run for the current source. `PlayerStream.loudnessScan`
  /// does not emit it: it emits `null` when a file loads instead.
  idle,

  /// The scan is decoding the file.
  scanning,

  /// The scan finished: the measurement fields are populated.
  ready,

  /// The scan could not complete (decode error).
  failed,

  /// The source cannot be scanned up-front (adaptive, live or
  /// non-seekable stream): use the live `PlayerStream.loudnessMeter`
  /// instead.
  unavailable;

  /// The mpv wire value of this state.
  String get mpvValue => name;

  /// Parses an mpv wire value; unknown values fall back to [idle].
  static LoudnessScanState fromMpv(String value) =>
      byMpvValue(values, value, (v) => v.mpvValue) ?? idle;
}
