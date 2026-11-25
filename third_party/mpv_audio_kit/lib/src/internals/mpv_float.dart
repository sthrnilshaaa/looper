// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

/// Values of mpv's single-precision options.
library;

import 'dart:typed_data';

final Float32List _f32 = Float32List(1);

/// The shortest decimal that names the same single-precision value as
/// [value]. mpv stores options like `volume` as a C `float`, so writing
/// `42.37` echoes back `42.369998931884766`; both map to `42.37` here,
/// which keeps the state equal to what the caller asked for and lets the
/// echo deduplicate against it.
double canonicalFloat(double value) {
  if (!value.isFinite) return value;
  _f32[0] = value;
  final single = _f32[0];
  for (var digits = 1; digits <= 9; digits++) {
    final candidate = double.parse(single.toStringAsPrecision(digits));
    _f32[0] = candidate;
    if (_f32[0] == single) return candidate;
  }
  return single;
}
