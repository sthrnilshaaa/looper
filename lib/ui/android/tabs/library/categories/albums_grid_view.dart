import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:looper_player/ui/widgets/common/app_loading_indicator.dart';
import 'package:looper_player/core/services/storage/db_service.dart';
import 'package:looper_player/core/providers/navigation_provider.dart';
import 'package:looper_player/l10n/app_localizations.dart';
import 'package:looper_player/ui/widgets/common/optimized_image.dart';
import 'package:looper_player/ui/widgets/common/empty_state_card.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:isar_community/isar.dart';
import 'package:looper_player/features/settings/presentation/providers/settings_notifier.dart';
import 'package:looper_player/core/theme/app_fonts.dart';
import 'library_categories_views.dart';

class AlbumsGridView extends ConsumerWidget {
  const AlbumsGridView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final sortOptionIndex = ref.watch(
      settingsProvider.select((s) => s.albumSortOptionIndex),
    );
    final sortOption = AlbumSortOption
        .values[sortOptionIndex.clamp(0, AlbumSortOption.values.length - 1)];
    final albumsAsync = ref.watch(albumsSortedProvider(sortOption));

    return Builder(
      builder: (context) {
        if (!albumsAsync.hasValue) return const AppLoadingIndicator();
        final albums = albumsAsync.requireValue;
        if (albums.isEmpty) {
          return EmptyStateCard(
            icon: LucideIcons.disc,
            title: l10n.noAlbumsFound,
          );
        }

        // A plain `childAspectRatio` sizes the *whole* card (art + text) to a fixed
        // ratio, so the art itself ends up a hair taller or shorter than it is wide
        // depending on screen width -- that's what read as "not symmetric". Instead
        // compute the column width ourselves, force the art to a true 1:1 square,
        // and give every card the exact same fixed text-block height below it.
        return LayoutBuilder(
          builder: (context, constraints) {
            const crossAxisSpacing = 24.0;
            const horizontalPadding = 24.0;
            const textBlockHeight = 54.0; // 12 gap + title line + subtitle line
            // Was a fixed 2 columns regardless of width - on a landscape
            // phone/tablet that leaves only 2 needlessly huge cards instead
            // of using the extra width for more columns. Same target column
            // width (~200) as the equivalent grid in library_grids.dart, but
            // as a computed crossAxisCount (at least 2) rather than a fixed
            // maxCrossAxisExtent delegate, so the mainAxisExtent below can
            // still force a true 1:1 square art + fixed text block.
            const targetColumnWidth = 200.0;
            final availableWidth = constraints.maxWidth - horizontalPadding * 2;
            final crossAxisCount = math.max(
              2,
              ((availableWidth + crossAxisSpacing) /
                      (targetColumnWidth + crossAxisSpacing))
                  .floor(),
            );
            final itemWidth =
                (availableWidth - crossAxisSpacing * (crossAxisCount - 1)) /
                crossAxisCount;

            return GridView.builder(
              padding: const EdgeInsets.only(
                left: horizontalPadding,
                right: horizontalPadding,
                top: 24,
                bottom: 200,
              ),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: 24,
                crossAxisSpacing: crossAxisSpacing,
                mainAxisExtent: itemWidth + textBlockHeight,
              ),
              itemCount: albums.length,
              itemBuilder: (context, index) {
                final album = albums[index];
                return InkWell(
                  onTap: () async {
                    final songs = await DbService.isar.songs
                        .filter()
                        .albumEqualTo(album.name)
                        .findAll();
                    ref
                        .read(appNavigationProvider.notifier)
                        .showCollection(
                          title: album.name,
                          subtitle: album.artist ?? l10n.unknownArtist,
                          art: album.artPath,
                          songs: songs,
                          album: album,
                        );
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AspectRatio(
                        aspectRatio: 1,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: OptimizedImage(
                            imagePath: album.artPath,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        album.name,
                        style: AppFonts.jostStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        album.artist ?? l10n.unknownArtist,
                        style: AppFonts.jostStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
