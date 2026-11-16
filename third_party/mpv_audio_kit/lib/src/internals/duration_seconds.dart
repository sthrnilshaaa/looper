// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

/// Helpers for the `Duration ↔ fractional-seconds-as-double` conversion that
/// libmpv uses on the wire for time-based properties (`audio-delay`,
/// `cache-secs`, `cache-pause-wait`, `network-timeout`, `audio-buffer`,
/// `time-pos`, `duration`, `demuxer-cache-time`).
///
/// Centralised here so the conversion strategy is defined once. The current
/// strategy is **microsecond-rounded**: convert to/from `Duration` via
/// `inMicroseconds`, divide by `1e6`. This preserves sub-millisecond
/// precision for properties like `audio-delay` (which can be ~5ms) while
/// staying well within IEEE-754 double precision for the longest values
/// libmpv accepts (`network-timeout` up to ~1 day).
library;

/// Converts a fractional-seconds [double] (as emitted by mpv) into a
/// [Duration]. Sub-microsecond precision is rounded.
Duration secondsToDuration(double seconds) =>
    Duration(microseconds: (seconds * 1e6).round());

/// Converts a [Duration] back into fractional seconds for mpv property
/// strings. Returns a [double] suitable for `toStringAsFixed(3)` etc.
double durationToSeconds(Duration d) => d.inMicroseconds / 1e6;
