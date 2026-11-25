// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

/// Helpers for the `Duration ↔ fractional-seconds-as-double` conversion that
/// libmpv uses on the wire for time-based properties (`audio-delay`,
/// `cache-secs`, `cache-pause-wait`, `network-timeout`, `audio-buffer`,
/// `time-pos`, `duration`, `demuxer-cache-time`).
///
/// Centralised here so the conversion strategy is defined once. The current
/// strategy is **microsecond-rounded**: convert to and from `Duration` via
/// `inMicroseconds`, divide by `1e6`. This preserves sub-millisecond
/// precision for properties like `audio-delay` (which can be ~5ms) while
/// staying well within IEEE-754 double precision for the longest values
/// libmpv accepts.
library;

/// Converts a fractional-seconds [double] (as emitted by mpv) into a
/// [Duration]. Sub-microsecond precision is rounded. A value that is not
/// finite (NaN or an infinity) gives [Duration.zero]: `double.round`
/// throws on it.
Duration secondsToDuration(double seconds) => seconds.isFinite
    ? Duration(microseconds: (seconds * 1e6).round())
    : Duration.zero;

/// Converts a [Duration] back into fractional seconds for mpv property
/// strings. Returns a [double] suitable for `toStringAsFixed(6)`.
double durationToSeconds(Duration d) => d.inMicroseconds / 1e6;

/// [d] in seconds for an mpv option string: 3 decimals when that is exact,
/// 6 when it is not, which holds every microsecond. Never an exponent,
/// which `toString` writes for small values and mpv's time parser does
/// not read. The same form as the durations of the effects chain.
String durationToOption(Duration d) {
  final v = durationToSeconds(d);
  final fixed = v.toStringAsFixed(3);
  return double.parse(fixed) == v ? fixed : v.toStringAsFixed(6);
}
