import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:looper_player/features/library/domain/models/models.dart';

class BlurredBackgroundArt extends StatelessWidget {
  final Song song;
  const BlurredBackgroundArt({required this.song, super.key});

  @override
  Widget build(BuildContext context) {
    final path = song.artPath;
    if (path == null) return const SizedBox.shrink();
    return RepaintBoundary(
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Image.file(
          File(path),
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          filterQuality: FilterQuality.low,
          cacheWidth: 80,
          cacheHeight: 80,
          gaplessPlayback: true,
          errorBuilder: (_, _, _) => const SizedBox.shrink(),
        ),
      ),
    );
  }
}
