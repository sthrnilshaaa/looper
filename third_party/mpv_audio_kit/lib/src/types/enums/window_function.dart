// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'dart:math' as math;
import 'dart:typed_data';

/// Window function applied to each FFT block before transform.
///
/// Windows trade off main-lobe width vs side-lobe leakage. For music
/// visualizers the default is [hann] — smooth taper, decent leakage,
/// the canonical music-visualizer window. [blackmanHarris] suppresses
/// side-lobes harder for cleaner-looking peaks at the cost of a wider
/// main lobe. [rectangular] is the no-window debug option (DC ripple,
/// prominent leakage between bins).
///
/// Set via [SpectrumSettings.window].
enum WindowFunction {
  /// Hann (a.k.a. Hanning): 0.5 - 0.5·cos(2πn/(N-1)). Default —
  /// smooth taper to zero at edges, -31 dB peak side-lobe, -18 dB/oct
  /// roll-off. The universal music-visualizer choice.
  hann,

  /// Blackman-Harris 4-term: -92 dB peak side-lobe. Cleaner-looking
  /// peaks, slightly wider main lobe than Hann. Use when bass and
  /// midrange frequencies blur into each other on Hann.
  blackmanHarris,

  /// No window — every sample multiplied by 1.0. Severe spectral
  /// leakage; useful only for debugging. Don't ship this in a
  /// visualizer.
  rectangular;

  /// Pre-computes the window of length [n] into a [Float32List].
  /// Call once per FFT-size change; multiply each input block in-place.
  Float32List compute(int n) {
    final w = Float32List(n);
    switch (this) {
      case WindowFunction.hann:
        for (var i = 0; i < n; i++) {
          w[i] = 0.5 - 0.5 * math.cos(2 * math.pi * i / (n - 1));
        }
      case WindowFunction.blackmanHarris:
        // 4-term Blackman-Harris coefficients — Harris (1978).
        const a0 = 0.35875, a1 = 0.48829, a2 = 0.14128, a3 = 0.01168;
        for (var i = 0; i < n; i++) {
          final t = 2 * math.pi * i / (n - 1);
          w[i] = a0 -
              a1 * math.cos(t) +
              a2 * math.cos(2 * t) -
              a3 * math.cos(3 * t);
        }
      case WindowFunction.rectangular:
        for (var i = 0; i < n; i++) {
          w[i] = 1.0;
        }
    }
    return w;
  }
}
