// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

/// Side of an audio filter at which a per-filter tap captures samples.
///
/// Selects whether [PlayerStream.tap] reads the audio just before the
/// filter's DSP runs ([pre], "input signal") or just after ([post],
/// "output signal"). The two sides share the same engine machinery —
/// pick whichever matches the metering or visualisation you need.
enum TapSide {
  /// Tap captures samples *before* the filter applies its DSP. Use
  /// for "input signal" overlays in a per-filter editor, or any
  /// analysis on the raw samples that hit a specific point in the
  /// `af` chain.
  pre,

  /// Tap captures samples *after* the filter has processed them. Use
  /// for "output signal" overlays — what the listener will actually
  /// hear once this stage is in the chain.
  post,
}
