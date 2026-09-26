import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:looper_player/core/services/storage/db_service.dart';
import 'package:looper_player/core/providers/navigation_provider.dart';
import 'package:looper_player/features/library/domain/models/models.dart';
import 'package:looper_player/features/library/presentation/providers/library/library_notifier.dart';
import 'package:looper_player/l10n/app_localizations.dart';
import 'package:looper_player/ui/widgets/common/optimized_image.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:looper_player/features/settings/presentation/providers/settings_notifier.dart';
import 'package:looper_player/core/theme/app_fonts.dart';
import 'library_categories_views.dart';

class GenresGridView extends ConsumerWidget {
  const GenresGridView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Isar doesn't have a distinct query easily for genres if they are just
    // strings in Songs, so the grouping itself is cached in
    // songsByGenreProvider (memoized on the song list, not this screen's
    // build cycle) - only the localized "Unknown" label is applied here.
    final l10n = AppLocalizations.of(context)!;
    final songsByGenre = ref.watch(songsByGenreProvider);
    final genresMap = <String, List<Song>>{};
    for (final entry in songsByGenre.entries) {
      final genre = entry.key ?? l10n.unknown;
      genresMap.putIfAbsent(genre, () => []).addAll(entry.value);
    }

    final sortOptionIndex = ref.watch(
      settingsProvider.select((s) => s.genreSortOptionIndex),
    );
    final sortOption = GenreSortOption
        .values[sortOptionIndex.clamp(0, GenreSortOption.values.length - 1)];
    final genres = genresMap.keys.toList();
    switch (sortOption) {
      case GenreSortOption.nameAsc:
        genres.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
        break;
      case GenreSortOption.nameDesc:
        genres.sort((a, b) => b.toLowerCase().compareTo(a.toLowerCase()));
        break;
      case GenreSortOption.songCountDesc:
        genres.sort(
          (a, b) => genresMap[b]!.length.compareTo(genresMap[a]!.length),
        );
        break;
      case GenreSortOption.songCountAsc:
        genres.sort(
          (a, b) => genresMap[a]!.length.compareTo(genresMap[b]!.length),
        );
        break;
    }

    return GridView.builder(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 200),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 220,
        mainAxisSpacing: 20,
        crossAxisSpacing: 20,
        childAspectRatio: 1.35,
      ),
      itemCount: genres.length,
      itemBuilder: (context, index) {
        final genre = genres[index];
        final genreSongs = genresMap[genre]!;

        // Hash the genre string to produce a consistent vibrant color gradient
        final int hash = genre.hashCode;
        final double hue = (hash.abs() % 360).toDouble();
        final Color startColor = HSLColor.fromAHSL(
          1.0,
          hue,
          0.70,
          0.35,
        ).toColor();
        final Color endColor = HSLColor.fromAHSL(
          1.0,
          (hue + 45) % 360,
          0.80,
          0.18,
        ).toColor();

        // Get first song with art if available
        final firstSongWithArt = genreSongs.firstWhere(
          (s) => s.artPath != null,
          orElse: () => genreSongs.first,
        );

        return InkWell(
          onTap: () {
            // Pick the first song with art as the genre cover
            final firstWithArt = genreSongs.firstWhere(
              (s) => s.artPath != null,
              orElse: () => genreSongs.first,
            );
            ref
                .read(appNavigationProvider.notifier)
                .showCollection(
                  title: genre,
                  subtitle: l10n.genre,
                  art: firstWithArt.artPath,
                  songs: genreSongs,
                );
          },
          borderRadius: BorderRadius.circular(24),
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [startColor, endColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Rotated Album Art in the bottom right corner
                if (firstSongWithArt.artPath != null)
                  Positioned(
                    bottom: -12,
                    right: -12,
                    child: Transform.rotate(
                      angle: 0.25,
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.4),
                              blurRadius: 8,
                              offset: const Offset(2, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: OptimizedImage(
                            imagePath: firstSongWithArt.artPath,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  Positioned(
                    bottom: -10,
                    right: -10,
                    child: Transform.rotate(
                      angle: 0.25,
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          LucideIcons.music,
                          size: 28,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ),

                // Genre info on the left side
                Positioned(
                  left: 16,
                  top: 16,
                  bottom: 16,
                  right:
                      56, // Leave room so text doesn't overlap the album art too much
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        genre,
                        style: AppFonts.jostStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${genreSongs.length} ${l10n.songs}',
                        style: AppFonts.jostStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
