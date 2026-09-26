part of 'audio_analysis_widget.dart';

class _SpectrogramView extends StatelessWidget {
  final ui.Image image;
  final int sampleRate;
  final double maxFreq;

  const _SpectrogramView({
    required this.image,
    required this.sampleRate,
    required this.maxFreq,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.black,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 2.0,
            child: CustomPaint(
              painter: _ImagePainter(image),
              size: Size.infinite,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Text(
                  context.l10n.sampleRateHz(sampleRate),
                  style: AppFonts.jostStyle(
                    color: Colors.white54,
                    fontSize: 11,
                  ),
                ),
                const Spacer(),
                Text(
                  context.l10n.nyquistKhz((maxFreq / 1000).toStringAsFixed(1)),
                  style: AppFonts.jostStyle(
                    color: Colors.white54,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ImagePainter extends CustomPainter {
  final ui.Image image;
  _ImagePainter(this.image);

  @override
  void paint(Canvas canvas, Size size) {
    paintImage(
      canvas: canvas,
      rect: Offset.zero & size,
      image: image,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
    );
  }

  @override
  bool shouldRepaint(covariant _ImagePainter old) => old.image != image;
}

class _SpectrogramRenderParams {
  final SpectrogramData spectrum;
  final int width;
  final int height;

  const _SpectrogramRenderParams({
    required this.spectrum,
    required this.width,
    required this.height,
  });
}

Uint8List _renderSpectrogramPixels(_SpectrogramRenderParams params) {
  final w = params.width;
  final h = params.height;
  final spectrum = params.spectrum;
  final pixels = Uint8List(w * h * 4);

  for (int i = 3; i < pixels.length; i += 4) {
    pixels[i] = 255;
  }

  final slices = spectrum.magnitudes;
  if (slices.isEmpty) return pixels;

  final freqBins = spectrum.freqBins;

  double minDB = 0;
  double maxDB = -200;
  for (final slice in slices) {
    for (int i = 0; i < slice.length; i++) {
      final db = slice[i];
      if (db > maxDB) maxDB = db;
      if (db < minDB && db > -200) minDB = db;
    }
  }
  minDB = math.max(minDB, maxDB - 90);
  final dbRange = maxDB - minDB;
  if (dbRange <= 0) return pixels;

  for (int px = 0; px < w; px++) {
    final t = (px / w * slices.length).floor().clamp(0, slices.length - 1);
    final slice = slices[t];

    for (int py = 0; py < h; py++) {
      final freqRatio = 1.0 - (py / h);
      final f = (freqRatio * freqBins).floor().clamp(0, freqBins - 1);
      if (f >= slice.length) continue;

      final db = slice[f];
      final intensity = ((db - minDB) / dbRange).clamp(0.0, 1.0);
      final color = _spekColorRGB(intensity);

      final offset = (py * w + px) * 4;
      pixels[offset] = color[0];
      pixels[offset + 1] = color[1];
      pixels[offset + 2] = color[2];
      pixels[offset + 3] = 255;
    }
  }

  return pixels;
}

List<int> _spekColorRGB(double intensity) {
  int r, g, b;
  if (intensity < 0.08) {
    final t = intensity / 0.08;
    r = 0;
    g = 0;
    b = (t * 80).floor();
  } else if (intensity < 0.18) {
    final t = (intensity - 0.08) / 0.10;
    r = (t * 50).floor();
    g = (t * 30).floor();
    b = (80 + t * 175).floor();
  } else if (intensity < 0.28) {
    final t = (intensity - 0.18) / 0.10;
    r = (50 + t * 150).floor();
    g = (30 - t * 30).floor();
    b = (255 - t * 55).floor();
  } else if (intensity < 0.40) {
    final t = (intensity - 0.28) / 0.12;
    r = (200 + t * 55).floor();
    g = 0;
    b = (200 - t * 200).floor();
  } else if (intensity < 0.52) {
    final t = (intensity - 0.40) / 0.12;
    r = 255;
    g = (t * 100).floor();
    b = 0;
  } else if (intensity < 0.65) {
    final t = (intensity - 0.52) / 0.13;
    r = 255;
    g = (100 + t * 80).floor();
    b = 0;
  } else if (intensity < 0.78) {
    final t = (intensity - 0.65) / 0.13;
    r = 255;
    g = (180 + t * 55).floor();
    b = (t * 30).floor();
  } else if (intensity < 0.90) {
    final t = (intensity - 0.78) / 0.12;
    r = 255;
    g = (235 + t * 20).floor();
    b = (30 + t * 100).floor();
  } else {
    final t = (intensity - 0.90) / 0.10;
    r = 255;
    g = 255;
    b = (130 + t * 125).floor();
  }
  return [r.clamp(0, 255), g.clamp(0, 255), b.clamp(0, 255)];
}
