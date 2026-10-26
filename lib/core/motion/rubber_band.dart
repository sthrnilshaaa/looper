/// Rubber-band resistance shared by the Fluid Player and every scroll view,
/// so pulling past an end feels like one material across the app.
library;

/// Resistance constant of [rubberBand] (the iOS rubber-band value).
const double kRubberBandC = 0.55;

/// How far something moves when the finger has gone [x] px past an edge:
/// `f(x) = x*d*c / (d + c*x)`. Slope [kRubberBandC] at the edge, growing
/// resistance after, never reaching [d].
double rubberBand(double x, double d) {
  if (x <= 0.0 || d <= 0.0) return 0.0;
  return x * d * kRubberBandC / (d + kRubberBandC * x);
}

/// Inverse of [rubberBand]: the finger overshoot that produces a displayed
/// displacement [y]. `x = d*y / (c*(d - y))`, for `0 <= y < d`.
double inverseRubberBand(double y, double d) {
  if (y <= 0.0 || d <= 0.0) return 0.0;
  final double capped = y < d * 0.999 ? y : d * 0.999;
  return d * capped / (kRubberBandC * (d - capped));
}

/// Derivative of [rubberBand] at [x]: `c*d^2 / (d + c*x)^2`.
double rubberBandSlope(double x, double d) {
  if (d <= 0.0) return 0.0;
  if (x <= 0.0) return kRubberBandC;
  final double denom = d + kRubberBandC * x;
  return kRubberBandC * d * d / (denom * denom);
}
