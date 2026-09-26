import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
              size: width != null ? (width! * 0.5).clamp(16, 48) : 32,
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
    final int computedCacheWidth =
        cacheWidth ?? (width != null ? (width! * dpr).toInt() : 400);
    final int? computedCacheHeight = cacheHeight;

    if (resolvedImagePath != null && resolvedImagePath.isNotEmpty) {
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
}
