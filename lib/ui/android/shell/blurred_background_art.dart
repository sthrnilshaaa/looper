import 'dart:collection';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:looper_player/features/library/domain/models/models.dart';

/// The song's art, blurred, filling its box. The blur is drawn once per song
/// and box size into a small image that every copy (main screen, music bar,
/// player) reuses. A live ImageFiltered re-blurred the whole screen on every
/// frame: Impeller has no raster cache, so RepaintBoundary didn't help.
class BlurredBackgroundArt extends StatelessWidget {
  final Song song;

  /// Scale applied around the blurred art (the player zooms in slightly).
  final double zoom;
  const BlurredBackgroundArt({required this.song, this.zoom = 1.0, super.key});

  @override
  Widget build(BuildContext context) {
    final path = song.artPath;
    if (path == null) return const SizedBox.shrink();
    return RepaintBoundary(
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
          );
          return zoom == 1.0 ? art : Transform.scale(scale: zoom, child: art);
        },
      ),
    );
  }
}

class _BlurredArtImage extends StatefulWidget {
  final String path;
  final Size size;
  const _BlurredArtImage({required this.path, required this.size});

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
    if (old.path != widget.path || old.size != widget.size) _load();
  }

  // Keeps showing the previous image until the new one is ready.
  void _load() {
    final Future<ui.Image?> request = _blurredArt(widget.path, widget.size);
    _request = request;
    request.then((image) {
      if (mounted && identical(_request, request)) {
        setState(() => _image = image);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final image = _image;
    if (image == null) return const SizedBox.expand();
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
Future<ui.Image?> _blurredArt(String path, Size size) {
  final double k = _kLongSide / math.max(size.width, size.height);
  final int w = math.max(1, (size.width * k).round());
  final int h = math.max(1, (size.height * k).round());
  final String key = '$path|${w}x$h';
  final Future<ui.Image?>? hit = _cache.remove(key);
  if (hit != null) return _cache[key] = hit;
  if (_cache.length >= 8) _cache.remove(_cache.keys.first);
  return _cache[key] = _render(path, w, h, _kSigma * k);
}

/// Same picture the old live blur drew: art squashed to 80x80, cover-fitted,
/// blurred with solid (clamped) edges - transparent edges let the screen
/// behind show through - at a size scaled down by the
/// blur-to-size ratio so it upscales without visible steps.
Future<ui.Image?> _render(String path, int w, int h, double sigma) async {
  try {
    final codec = await ui.instantiateImageCodec(
      await File(path).readAsBytes(),
      targetWidth: 80,
      targetHeight: 80,
    );
    final ui.Image src = (await codec.getNextFrame()).image;
    codec.dispose();
    final Rect rect = Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble());
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.saveLayer(
      rect,
      Paint()
        ..imageFilter = ui.ImageFilter.blur(
          sigmaX: sigma,
          sigmaY: sigma,
          tileMode: TileMode.clamp,
        ),
    );
    paintImage(
      canvas: canvas,
      rect: rect,
      image: src,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.low,
    );
    canvas.restore();
    final picture = recorder.endRecording();
    final ui.Image out = await picture.toImage(w, h);
    picture.dispose();
    src.dispose();
    return out;
  } catch (_) {
    return null;
  }
}
