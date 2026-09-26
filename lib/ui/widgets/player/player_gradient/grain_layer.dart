part of 'animated_player_gradient.dart';

/// Static film grain, tiled from one small texture rendered once per app
/// run. Light and dark specks at low alpha, so it reads on any palette and
/// also hides gradient banding.
class _GrainLayer extends StatelessWidget {
  const _GrainLayer();

  static const int _tile = 256;
  static ui.Image? _image;

  static ui.Image _grain() {
    final cached = _image;
    if (cached != null) return cached;
    final random = math.Random(7);
    final light = <double>[];
    final dark = <double>[];
    for (int y = 0; y < _tile; y++) {
      for (int x = 0; x < _tile; x++) {
        final double v = random.nextDouble();
        if (v < 0.22) {
          dark
            ..add(x + 0.5)
            ..add(y + 0.5);
        } else if (v > 0.78) {
          light
            ..add(x + 0.5)
            ..add(y + 0.5);
        }
      }
    }
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.square;
    canvas
      ..drawRawPoints(
        ui.PointMode.points,
        Float32List.fromList(dark),
        paint..color = const Color(0x10000000),
      )
      ..drawRawPoints(
        ui.PointMode.points,
        Float32List.fromList(light),
        paint..color = const Color(0x0DFFFFFF),
      );
    final picture = recorder.endRecording();
    final image = picture.toImageSync(_tile, _tile);
    picture.dispose();
    return _image = image;
  }

  @override
  Widget build(BuildContext context) {
    final double dpr = MediaQuery.maybeDevicePixelRatioOf(context) ?? 2.0;
    return IgnorePointer(
      child: CustomPaint(
        painter: _GrainPainter(_grain(), 1.5 / dpr),
        size: Size.infinite,
      ),
    );
  }
}

class _GrainPainter extends CustomPainter {
  _GrainPainter(this.image, this.scale);

  final ui.Image image;
  final double scale; // logical px per grain texel (~1.5 physical px)

  @override
  void paint(Canvas canvas, Size size) {
    final matrix = Float64List(16)
      ..[0] = scale
      ..[5] = scale
      ..[10] = 1
      ..[15] = 1;
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = ImageShader(
          image,
          TileMode.repeated,
          TileMode.repeated,
          matrix,
          filterQuality: FilterQuality.none,
        ),
    );
  }

  @override
  bool shouldRepaint(covariant _GrainPainter oldDelegate) =>
      oldDelegate.image != image || oldDelegate.scale != scale;
}
