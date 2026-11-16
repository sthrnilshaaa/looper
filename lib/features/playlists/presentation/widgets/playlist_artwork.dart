import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:looper_player/core/services/storage/db_service.dart';
import 'package:looper_player/features/settings/presentation/providers/settings_notifier.dart';
import 'package:looper_player/ui/widgets/common/optimized_image.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'playlist_artwork.g.dart';

@riverpod
Stream<List<String?>> playlistArtwork(Ref ref, List<String> songPaths) {
  final paths = songPaths.take(4).toList();
  if (paths.isEmpty) return Stream.value(const <String?>[]);

  // Watch the songs too: scanning or downloading artwork can fill in a
  // cover without changing the playlist. Keep missing and repeated slots.
  return DbService.isar.songs
      .filter()
      .anyOf(paths, (q, path) => q.pathEqualTo(path))
      .watch(fireImmediately: true)
      .map((songs) {
        final artwork = {for (final song in songs) song.path: song.artPath};
        return paths.map((path) => artwork[path]).toList();
      })
      .distinct(listEquals);
}

class PlaylistArtwork extends ConsumerWidget {
  final List<String> songPaths;
  // The user's own picture; replaces the song covers when set.
  final String? coverPath;
  final double? size;
  final BorderRadius borderRadius;

  const PlaylistArtwork({
    super.key,
    required this.songPaths,
    this.coverPath,
    this.size,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final artwork = ref.watch(playlistArtworkProvider(songPaths)).value ?? [];
    final dynamicTheming = ref.watch(
      settingsProvider.select((s) => s.enableDynamicTheming),
    );

    return SizedBox.square(
      dimension: size,
      child: AspectRatio(
        aspectRatio: 1,
        child: ClipRRect(
          borderRadius: borderRadius,
          child: ColoredBox(
            color: Theme.of(context).colorScheme.primaryContainer.withValues(
              alpha: dynamicTheming ? 0.8 : 0.3,
            ),
            child: switch (songPaths.length) {
              _ when coverPath != null => LayoutBuilder(
                builder: (context, constraints) => OptimizedImage(
                  imagePath: coverPath,
                  width: constraints.maxWidth,
                  height: constraints.maxWidth,
                ),
              ),
              0 => const Center(child: Icon(LucideIcons.listMusic, size: 48)),
              // Fewer than four songs can't fill the grid: show one cover,
              // the first song that has artwork.
              < 4 => LayoutBuilder(
                builder: (context, constraints) => OptimizedImage(
                  imagePath: artwork.firstWhere(
                    (art) => art != null,
                    orElse: () => null,
                  ),
                  width: constraints.maxWidth,
                  height: constraints.maxWidth,
                ),
              ),
              _ => LayoutBuilder(
                builder: (context, constraints) {
                  final tileSize = constraints.maxWidth / 2;
                  return Column(
                    children: List.generate(2, (row) {
                      return Expanded(
                        child: Row(
                          children: List.generate(2, (column) {
                            final index = row * 2 + column;
                            return Expanded(
                              child: OptimizedImage(
                                imagePath: index < artwork.length
                                    ? artwork[index]
                                    : null,
                                width: tileSize,
                                height: tileSize,
                              ),
                            );
                          }),
                        ),
                      );
                    }),
                  );
                },
              ),
            },
          ),
        ),
      ),
    );
  }
}
