// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

/// The one of [values] whose mpv string, read with [mpvValue], is [raw],
/// or `null` when none is. The `fromMpv` of each enum is this lookup plus
/// its own fallback, so a value's string is written once, on the value.
T? byMpvValue<T extends Enum>(
  List<T> values,
  String raw,
  String Function(T value) mpvValue,
) {
  for (final value in values) {
    if (mpvValue(value) == raw) return value;
  }
  return null;
}
