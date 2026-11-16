import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:looper_player/ui/widgets/common/cover_resize_image.dart';

/// An image provider for an artwork path: a network URL (online songs keep
/// their thumbnail URL in `artPath`) or a local file.
ImageProvider artImage(String path) =>
    path.startsWith('http://') || path.startsWith('https://')
    ? CachedNetworkImageProvider(path)
    : FileImage(File(path));

/// Whether [path] is worth trying to load: a URL, or a file that exists.
Future<bool> artAvailable(String path) async =>
    path.startsWith('http') || await File(path).exists();

class OptimizedImage extends StatelessWidget {
  final String? imagePath;
  final String? imageUrl;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final BoxFit fit;
  final int? cacheWidth;
  final int? cacheHeight;

  const OptimizedImage({
    super.key,
    this.imagePath,
    this.imageUrl,
    this.width,
    this.height,
    this.borderRadius,
    this.placeholder,
    this.fit = BoxFit.cover,
    this.cacheWidth,
    this.cacheHeight,
  });

  @override
  Widget build(BuildContext context) {
    final fallback =
        placeholder ??
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: borderRadius,
          ),
          child: Center(
            child: Icon(
              Icons.music_note_rounded,
              color: Colors.white.withValues(alpha: 0.3),
              size: (width != null && width!.isFinite) ? (width! * 0.5).clamp(16, 48) : 32,
            ),
          ),
        );

    final String? resolvedImageUrl =
        imageUrl ??
        ((imagePath != null &&
                (imagePath!.startsWith('http://') ||
                    imagePath!.startsWith('https://')))
            ? imagePath
            : null);
    final String? resolvedImagePath = (resolvedImageUrl == null)
        ? imagePath
        : null;

    Widget imageWidget;

    final double dpr = MediaQuery.maybeDevicePixelRatioOf(context) ?? 2.0;
    final double? finiteW = _finite(width ?? 0) ?? MediaQuery.maybeSizeOf(context)?.width;
    final int computedCacheWidth = cacheWidth ??
        (finiteW != null && finiteW.isFinite ? (finiteW * dpr).round() : 400);
    final int? computedCacheHeight = cacheHeight ??
        ((height != null && height!.isFinite) ? (height! * dpr).round() : null);

    if (resolvedImagePath != null &&
        resolvedImagePath.isNotEmpty &&
        cacheWidth == null &&
        cacheHeight == null) {
      // Decode for the box actually on screen (measured when no size was
      // given), covering it on both sides - see [CoverResizeImage].
      Widget sized(double boxWidth, double boxHeight) => Image(
        image: CoverResizeImage(
          FileImage(File(resolvedImagePath)),
          width: _bucket(boxWidth * dpr),
          height: _bucket(boxHeight * dpr),
        ),
        width: width,
        height: height,
        fit: fit,
        gaplessPlayback: true,
        errorBuilder: (context, error, stackTrace) => fallback,
      );
      // Measure only when the size wasn't given (a LayoutBuilder can't
      // answer intrinsic-size queries).
      imageWidget = (width != null && width!.isFinite) && (height != null && height!.isFinite)
          ? sized(width!, height!)
          : LayoutBuilder(
              builder: (context, constraints) {
                double? boxWidth = _finite(width ?? 0) ?? _finite(constraints.maxWidth);
                double? boxHeight = _finite(height ?? 0) ?? _finite(constraints.maxHeight);
                boxWidth ??= boxHeight ?? 200;
                boxHeight ??= boxWidth;
                return sized(boxWidth, boxHeight);
              },
            );
    } else if (resolvedImagePath != null && resolvedImagePath.isNotEmpty) {
      imageWidget = Image.file(
        File(resolvedImagePath),
        width: width,
        height: height,
        fit: fit,
        gaplessPlayback: true,
        cacheWidth: computedCacheWidth,
        cacheHeight: computedCacheHeight,
        errorBuilder: (context, error, stackTrace) => fallback,
      );
    } else if (resolvedImageUrl != null && resolvedImageUrl.isNotEmpty) {
      imageWidget = CachedNetworkImage(
        imageUrl: resolvedImageUrl,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, url) => fallback,
        errorWidget: (context, url, error) => fallback,
        memCacheWidth: computedCacheWidth,
        memCacheHeight: computedCacheHeight,
      );
    } else {
      imageWidget = fallback;
    }

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: SizedBox(width: width, height: height, child: imageWidget),
      );
    }

    return SizedBox(width: width, height: height, child: imageWidget);
  }

  static double? _finite(double value) =>
      value.isFinite && value > 0 ? value : null;

  /// Rounds a decode size up to a few fixed steps, so a picture whose box
  /// animates (hero flights, the player expanding) decodes a handful of
  /// times instead of once per frame, and the image cache can reuse them.
  static int _bucket(double pixels) {
    if (!pixels.isFinite || pixels <= 0) return 400;
    const steps = [96, 160, 256, 384, 512, 768, 1024, 1536, 2048];
    for (final step in steps) {
      if (pixels <= step) return step;
    }
    return pixels.ceil();
  }
}
