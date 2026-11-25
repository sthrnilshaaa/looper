import 'dart:collection';
import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:looper_player/features/library/domain/models/models.dart';
import 'package:looper_player/ui/android/shell/smooth_blur.dart';

/// The song's art, blurred, filling its box. The blur is drawn once per song
/// and box size into a small image that every copy (main screen, music bar,
/// player) reuses. A live ImageFiltered re-blurred the whole screen on every
/// frame: Impeller has no raster cache, so RepaintBoundary didn't help.
class BlurredBackgroundArt extends StatelessWidget {
  final Song song;

  /// Scale applied around the blurred art (the player zooms in slightly).
  final double zoom;

  /// Blur strength in logical pixels of the box, saturation (0 = grey,
  /// 1 = unchanged) and edge mode of the baked image.
  final double sigma;
  final double saturation;
  final TileMode tileMode;

  /// Pixels per logical pixel of the baked image; null fits it to a
  /// 256 px long side. Pass the device pixel ratio to bake exactly what a
  /// live ImageFiltered would draw: shown 1:1, since upscaling a strongly
  /// blurred bake shows the blur's own low-res grid.
  final double? resolution;

  /// Zoom applied to the art before the blur, around [artAlignment] (the
  /// live version's Transform.scale under the ImageFiltered).
  final double artZoom;
  final Alignment artAlignment;

  /// Shows the theme gradient until the image is ready (else nothing).
  final bool placeholder;
  const BlurredBackgroundArt({
    required this.song,
    this.zoom = 1.0,
    this.sigma = _kSigma,
    this.saturation = 1.0,
    this.tileMode = TileMode.clamp,
    this.resolution,
    this.artZoom = 1.0,
    this.artAlignment = Alignment.center,
    this.placeholder = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final path = song.artPath;
    return (path != null && path.isNotEmpty)
        ? RepaintBoundary(
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (!constraints.hasBoundedWidth ||
                    !constraints.hasBoundedHeight ||
                    constraints.biggest.isEmpty) {
                  return const SizedBox.shrink();
                }
                final Widget art = _BlurredArtImage(
                  path: path,
                  size: constraints.biggest,
                  style: (
                    sigma,
                    saturation,
                    tileMode,
                    resolution,
                    artZoom,
                    artAlignment,
                  ),
                  placeholder: placeholder,
                );
                return zoom == 1.0
                    ? art
                    : Transform.scale(scale: zoom, child: art);
              },
            ),
          )
        : const SizedBox.shrink();
  }
}

typedef _BlurStyle = (
  double sigma,
  double saturation,
  TileMode tileMode,
  double? resolution,
  double artZoom,
  Alignment artAlignment,
);

class _BlurredArtImage extends StatefulWidget {
  final String path;
  final Size size;
  final _BlurStyle style;
  final bool placeholder;
  const _BlurredArtImage({
    required this.path,
    required this.size,
    required this.style,
    required this.placeholder,
  });

  @override
  State<_BlurredArtImage> createState() => _BlurredArtImageState();
}

class _BlurredArtImageState extends State<_BlurredArtImage> {
  ui.Image? _image;
  Object? _request;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(_BlurredArtImage old) {
    super.didUpdateWidget(old);
    if (old.path != widget.path ||
        old.size != widget.size ||
        old.style != widget.style) {
      _load();
    }
  }

  // Keeps showing the previous image until the new one is ready.
  void _load() {
    final Future<ui.Image?> request = _blurredArt(
      widget.path,
      widget.size,
      widget.style,
    );
    _request = request;
    // Already baked: show it on the first frame instead of the placeholder
    // (a screen opening over the player otherwise flashed dark). Called from
    // initState/didUpdateWidget, so no setState needed.
    final ui.Image? ready = _baked[request];
    if (ready != null) {
      _image = ready;
      return;
    }
    request.then((image) {
      if (mounted && identical(_request, request)) {
        setState(() => _image = image);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final image = _image;
    if (image == null) {
      if (!widget.placeholder) return const SizedBox.shrink();
      final theme = Theme.of(context);
      return DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.primary.withValues(alpha: 0.3),
              theme.colorScheme.surface,
            ],
          ),
        ),
      );
    }
    return RawImage(
      image: image,
      fit: BoxFit.fill,
      width: double.infinity,
      height: double.infinity,
      filterQuality: FilterQuality.low,
    );
  }
}

const double _kSigma = 18; // blur strength, in logical pixels
const double _kLongSide = 256; // pixels on the cached image's long side
final LinkedHashMap<String, Future<ui.Image?>> _cache = LinkedHashMap();

/// Small LRU so the main screen, music bar and player share one render.
Future<ui.Image?> _blurredArt(String path, Size size, _BlurStyle style) {
  final (sigma, saturation, tileMode, resolution, artZoom, artAlignment) =
      style;
  final double k = resolution ?? _kLongSide / math.max(size.width, size.height);
  final int w = math.max(1, (size.width * k).round());
  final int h = math.max(1, (size.height * k).round());
  final String key = '$path|${w}x$h|$style';
  final Future<ui.Image?>? hit = _cache.remove(key);
  if (hit != null) return _cache[key] = hit;
  if (_cache.length >= 8) _cache.remove(_cache.keys.first);
  // A screen-sized bake is ~10 MB: keep only the latest one (a widget still
  // showing an older one holds its own reference).
  if (resolution != null) {
    final String? old = _screenSizedKey;
    if (old != null) _cache.remove(old);
    _screenSizedKey = key;
  }
  final Future<ui.Image?> render = _render(
    path,
    w,
    h,
    sigma * k,
    saturation,
    tileMode,
    artZoom,
    artAlignment,
    keepAspect: resolution != null,
  );
  render.then((image) {
    if (image != null) _baked[render] = image;
  });
  return _cache[key] = render;
}

/// Finished bakes by request, so a cache hit can be shown synchronously.
final Expando<ui.Image> _baked = Expando();

String? _screenSizedKey;

/// How much smaller than the screen the software blur works.
const int _kSoftBlurScale = 8;

Future<Uint8List> _smoothBlurOffThread(
  Uint8List rgba,
  int width,
  int height,
  double sigma,
  int outWidth,
  int outHeight,
) => Isolate.run(
  () => smoothBlur(rgba, width, height, sigma, outWidth, outHeight),
);

// Saturation matrix: 0 = grey, 1 = unchanged.
List<double> _saturationMatrix(double v) {
  const r = 0.2126, g = 0.7152, b = 0.0722;
  final i = 1 - v;
  return [
    r * i + v, g * i, b * i, 0, 0, //
    r * i, g * i + v, b * i, 0, 0, //
    r * i, g * i, b * i + v, 0, 0, //
    0, 0, 0, 1, 0,
  ];
}

/// Same picture the old live blur drew: art squashed to 80x80, cover-fitted,
/// blurred with solid (clamped) edges - transparent edges let the screen
/// behind show through - at a size scaled down by the
/// blur-to-size ratio so it upscales without visible steps.
/// [keepAspect] decodes 64 px wide at the art's own aspect instead, like the
/// styled player's live blur (OptimizedImage cacheWidth: 64).
Future<ui.Image?> _render(
  String path,
  int w,
  int h,
  double sigma,
  double saturation,
  TileMode tileMode,
  double artZoom,
  Alignment artAlignment, {
  required bool keepAspect,
}) async {
  try {
    final Uint8List bytes;
    if (path.startsWith('http://') || path.startsWith('https://')) {
      final file = await DefaultCacheManager().getSingleFile(path);
      bytes = await file.readAsBytes();
    } else {
      bytes = await File(path).readAsBytes();
    }
    final codec = await ui.instantiateImageCodec(
      bytes,
      targetWidth: keepAspect ? 64 : 80,
      targetHeight: keepAspect ? null : 80,
    );
    final ui.Image src = (await codec.getNextFrame()).image;
    codec.dispose();
    final Rect rect = Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble());
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    // Screen-sized bakes blur in software: at these strengths the GPU blur
    // shows its low-res grid as fine lines. The art is drawn small for it.
    final int smallW = math.max(1, (w / _kSoftBlurScale).round());
    final int smallH = math.max(1, (h / _kSoftBlurScale).round());
    if (keepAspect) canvas.scale(smallW / w, smallH / h);
    final Paint layer = Paint();
    if (!keepAspect) {
      layer.imageFilter = ui.ImageFilter.blur(
        sigmaX: sigma,
        sigmaY: sigma,
        tileMode: tileMode,
      );
    }
    if (saturation != 1.0) {
      layer.colorFilter = ColorFilter.matrix(_saturationMatrix(saturation));
    }
    // Unbounded, so the blur also reads the zoomed art past the edges, as
    // the live ImageFiltered did before its ClipRect.
    canvas.saveLayer(null, layer);
    if (artZoom != 1.0) {
      final Offset o = artAlignment.alongSize(rect.size);
      canvas
        ..translate(o.dx, o.dy)
        ..scale(artZoom)
        ..translate(-o.dx, -o.dy);
    }
    paintImage(
      canvas: canvas,
      rect: rect,
      image: src,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.low,
    );
    canvas.restore();
    final picture = recorder.endRecording();
    final ui.Image drawn = keepAspect
        ? await picture.toImage(smallW, smallH)
        : await picture.toImage(w, h);
    picture.dispose();
    src.dispose();
    if (!keepAspect) return drawn;
    final ByteData? small = await drawn.toByteData();
    drawn.dispose();
    if (small == null) return null;
    final Uint8List pixels = await _smoothBlurOffThread(
      small.buffer.asUint8List(small.offsetInBytes, small.lengthInBytes),
      smallW,
      smallH,
      sigma * smallW / w,
      w,
      h,
    );
    final done = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      pixels,
      w,
      h,
      ui.PixelFormat.rgba8888,
      done.complete,
    );
    return await done.future;
  } catch (_) {
    return null;
  }
}
