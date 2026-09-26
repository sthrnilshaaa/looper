part of 'animated_player_gradient.dart';

/// Colors pre-blended onto the surface with the same kind of tint alphas as
/// the static PlayerGradientBackground, so brightness and Music Darkness
/// behave the same.
@immutable
class _BlobPalette {
  final Color baseTop;
  final Color baseBottom;
  final List<Color> blobs;

  const _BlobPalette(this.baseTop, this.baseBottom, this.blobs);

  factory _BlobPalette.fromScheme(ColorScheme scheme) => _BlobPalette._build(
    primary: scheme.primary,
    tertiary: scheme.tertiary,
    surface: scheme.surface,
    intensity: 1.0,
  );

  /// Ambient Color mode: the artwork's two leading real colors take the
  /// primary and tertiary roles over a deep shade of its dominant color.
  factory _BlobPalette.fromArtwork(ArtworkColors art) => _BlobPalette._build(
    primary: art.primary,
    tertiary: art.secondary,
    surface: _deepShade(art.dominant),
    intensity: 1.15,
  );

  /// A very dark version of [color] (same hue) to paint the field on.
  static Color _deepShade(Color color) {
    final HSLColor hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness(math.min(hsl.lightness, 0.10))
        .withSaturation(math.min(hsl.saturation, 0.55))
        .toColor();
  }

  factory _BlobPalette._build({
    required Color primary,
    required Color tertiary,
    required Color surface,
    required double intensity,
  }) {
    Color tint(Color color, double alpha) => Color.alphaBlend(
      color.withValues(alpha: (alpha * intensity).clamp(0.0, 1.0)),
      surface,
    );
    final Color vividPrimary = _vivid(primary);
    final Color vividTertiary = _vivid(tertiary);
    return _BlobPalette(tint(vividPrimary, 0.30), tint(vividTertiary, 0.18), [
      // Only primary/tertiary shades, all at least as bright as the base:
      // the old primaryContainer/tertiaryContainer blobs are dark tones
      // in dark themes and read as dark holes drifting over the field.
      tint(vividPrimary, 0.68),
      tint(vividTertiary, 0.62),
      tint(Color.lerp(vividPrimary, vividTertiary, 0.2)!, 0.58),
      tint(Color.lerp(vividTertiary, vividPrimary, 0.15)!, 0.56),
      tint(Color.lerp(vividPrimary, vividTertiary, 0.5)!, 0.58),
    ]);
  }

  /// Material dark-theme primaries are pale pastels, which melt into a
  /// washed-out field once blended over the surface. Push the hue's
  /// saturation up and keep lightness in a rich mid band so blobs read as
  /// real color. Near-grey colors are left alone: their hue is noise.
  static Color _vivid(Color color) {
    final HSLColor hsl = HSLColor.fromColor(color);
    if (hsl.saturation < 0.08) return color;
    return hsl
        .withSaturation(hsl.saturation + (1 - hsl.saturation) * 0.3)
        .withLightness(hsl.lightness.clamp(0.50, 0.68))
        .toColor();
  }

  static _BlobPalette lerp(_BlobPalette a, _BlobPalette b, double t) =>
      _BlobPalette(
        Color.lerp(a.baseTop, b.baseTop, t)!,
        Color.lerp(a.baseBottom, b.baseBottom, t)!,
        [
          for (int i = 0; i < a.blobs.length; i++)
            Color.lerp(a.blobs[i], b.blobs[i], t)!,
        ],
      );

  @override
  bool operator ==(Object other) =>
      other is _BlobPalette &&
      other.baseTop == baseTop &&
      other.baseBottom == baseBottom &&
      _listEquals(other.blobs, blobs);

  @override
  int get hashCode => Object.hash(baseTop, baseBottom, Object.hashAll(blobs));

  static bool _listEquals(List<Color> a, List<Color> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

enum _Driver { bass, mid, high }

/// One traveling blob. Its center wanders the whole canvas: each axis sums
/// two sines whose amplitudes add up to ~0.5, so over time it visits every
/// edge and corner. The radius is a fraction of the canvas's longest side.
class _BlobSpec {
  final double fx1, fx2, fy1, fy2; // path frequencies per axis
  final double px, py; // path phase offsets
  final double radius;
  final double aspect; // < 1 squashes the circle into an oval
  final double spin; // rotation per unit of phase
  final _Driver driver;

  const _BlobSpec(
    this.fx1,
    this.fx2,
    this.fy1,
    this.fy2,
    this.px,
    this.py,
    this.radius,
    this.aspect,
    this.spin,
    this.driver,
  );
}

// Indexed like _BlobPalette.blobs: primary blobs breathe with the bass,
// tertiary ones with highs and mids. Frequencies are deliberately
// not simple ratios of each other, so the paths never visibly repeat.
const List<_BlobSpec> _blobSpecs = [
  _BlobSpec(0.90, 1.37, 0.71, 1.23, 0.0, 1.3, 0.46, 0.78, 0.10, _Driver.bass),
  _BlobSpec(0.63, 1.29, 0.93, 1.51, 2.1, 4.0, 0.44, 0.82, -0.08, _Driver.high),
  _BlobSpec(0.79, 1.19, 0.57, 1.41, 4.2, 2.6, 0.42, 0.76, 0.07, _Driver.bass),
  _BlobSpec(1.03, 1.59, 0.83, 1.33, 1.1, 5.3, 0.40, 0.84, -0.11, _Driver.mid),
  _BlobSpec(0.53, 1.27, 1.07, 1.47, 3.3, 0.4, 0.42, 0.78, 0.06, _Driver.mid),
];

class _BlobPainter extends CustomPainter {
  _BlobPainter({required this.motion, required Listenable repaint})
    : super(repaint: repaint);

  final _GradientMotion motion;

  // Gaussian-like falloff so blob edges melt into each other with no rim.
  static const List<double> _falloff = [1.0, 0.72, 0.30, 0.0];
  static const List<double> _stops = [0.0, 0.35, 0.70, 1.0];

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final _BlobPalette palette = motion.palette;
    final GradientAudioEnergy energy = motion.energy;
    final double phase = motion.phase;
    final Rect rect = Offset.zero & size;

    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.linear(rect.topCenter, rect.bottomCenter, [
          palette.baseTop,
          palette.baseBottom,
        ]),
    );

    final double longest = size.longestSide;
    final Paint paint = Paint();
    for (int i = 0; i < _blobSpecs.length; i++) {
      final _BlobSpec spec = _blobSpecs[i];
      final Color color = palette.blobs[i];
      final double scale, strength;
      // The original gentle "breathing": primary blobs swell a little with
      // the bass, the others glow slightly with their band.
      switch (spec.driver) {
        case _Driver.bass:
          scale = 1 + 0.05 * energy.bass + 0.06 * energy.bassPulse;
          strength = 0.85 + 0.15 * energy.bass;
        case _Driver.mid:
          scale = 1 + 0.02 * energy.mid;
          strength = 0.80 + 0.20 * energy.mid;
        case _Driver.high:
          scale = 1 + 0.02 * energy.high;
          strength = 0.80 + 0.20 * energy.high;
      }
      final double r = spec.radius * longest * scale;
      final double x =
          0.5 +
          0.38 * math.sin(spec.fx1 * phase + spec.px) +
          0.10 * math.sin(spec.fx2 * phase + spec.px * 1.7);
      final double y =
          0.5 +
          0.40 * math.sin(spec.fy1 * phase + spec.py) +
          0.10 * math.sin(spec.fy2 * phase + spec.py * 1.3);
      final Offset center = Offset(x * size.width, y * size.height);

      paint.shader = ui.Gradient.radial(Offset.zero, r, [
        for (final f in _falloff) color.withValues(alpha: f * strength),
      ], _stops);
      canvas
        ..save()
        ..translate(center.dx, center.dy)
        ..rotate(spec.spin * phase + i)
        ..scale(1, spec.aspect)
        ..drawCircle(Offset.zero, r, paint)
        ..restore();
    }
  }

  @override
  bool shouldRepaint(covariant _BlobPainter oldDelegate) =>
      oldDelegate.motion != motion;
}
