import 'dart:math' as math;
import 'dart:typed_data';

/// Blurs [rgba] ([width] x [height], opaque) by [sigma] pixels with mirrored
/// edges and returns it enlarged to [outWidth] x [outHeight].
///
/// For very strong blurs: the GPU blur renders those at a tiny internal size
/// and shows its pixel grid as fine lines across the screen. This works in
/// floats and dithers the final 8-bit output, so dark gradients don't band.
/// Takes a few hundred ms at screen size: call it off the UI isolate.
Uint8List smoothBlur(
  Uint8List rgba,
  int width,
  int height,
  double sigma,
  int outWidth,
  int outHeight,
) {
  final pixels = width * height;
  final channels = [for (var c = 0; c < 3; c++) Float32List(pixels)];
  for (var i = 0; i < pixels; i++) {
    for (var c = 0; c < 3; c++) {
      channels[c][i] = rgba[i * 4 + c].toDouble();
    }
  }

  // Three box passes are visually a Gaussian of this sigma.
  final radius = math.max(
    1,
    ((math.sqrt(4 * sigma * sigma + 1) - 1) / 2).round(),
  );
  for (final channel in channels) {
    for (var pass = 0; pass < 3; pass++) {
      for (var y = 0; y < height; y++) {
        _boxLine(channel, y * width, 1, width, radius);
      }
      for (var x = 0; x < width; x++) {
        _boxLine(channel, x, width, height, radius);
      }
    }
  }

  final out = Uint8List(outWidth * outHeight * 4);
  var seed = 0x2545F491;
  double noise() {
    seed ^= (seed << 13) & 0xFFFFFFFF;
    seed ^= seed >> 17;
    seed ^= (seed << 5) & 0xFFFFFFFF;
    return (seed & 0xFFFF) / 0xFFFF;
  }

  var o = 0;
  for (var oy = 0; oy < outHeight; oy++) {
    final fy = ((oy + 0.5) * height / outHeight - 0.5).clamp(0.0, height - 1.0);
    final y0 = fy.floor();
    final y1 = math.min(y0 + 1, height - 1);
    final ty = fy - y0;
    for (var ox = 0; ox < outWidth; ox++) {
      final fx = ((ox + 0.5) * width / outWidth - 0.5).clamp(0.0, width - 1.0);
      final x0 = fx.floor();
      final x1 = math.min(x0 + 1, width - 1);
      final tx = fx - x0;
      for (var c = 0; c < 3; c++) {
        final p = channels[c];
        final top = p[y0 * width + x0] * (1 - tx) + p[y0 * width + x1] * tx;
        final bottom = p[y1 * width + x0] * (1 - tx) + p[y1 * width + x1] * tx;
        // Triangular dither, one 8-bit step either way.
        final v = top * (1 - ty) + bottom * ty + noise() - noise();
        out[o++] = v.round().clamp(0, 255);
      }
      out[o++] = 255;
    }
  }
  return out;
}

/// One box-filter pass over [count] values, [stride] apart from [start].
void _boxLine(Float32List data, int start, int stride, int count, int radius) {
  final line = Float32List(count);
  for (var i = 0; i < count; i++) {
    line[i] = data[start + i * stride];
  }
  double at(int i) {
    final m = i % (2 * count);
    return line[m < count ? m : 2 * count - 1 - m];
  }

  var sum = 0.0;
  for (var i = -radius; i <= radius; i++) {
    sum += at(i);
  }
  final size = 2 * radius + 1;
  for (var i = 0; i < count; i++) {
    data[start + i * stride] = sum / size;
    sum += at(i + radius + 1) - at(i - radius);
  }
}
