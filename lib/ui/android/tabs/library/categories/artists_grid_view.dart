import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

class ArtistsGridView extends ConsumerWidget {
  const ArtistsGridView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final sortOptionIndex = ref.watch(
      settingsProvider.select((s) => s.artistSortOptionIndex),
    );
    final sortOption = ArtistSortOption
        .values[sortOptionIndex.clamp(0, ArtistSortOption.values.length - 1)];
    final sortedArtists = ref.watch(artistsSortedProvider(sortOption));

    if (sortedArtists.isEmpty) {
      return EmptyStateCard(icon: LucideIcons.user, title: l10n.noArtistsFound);
    }

    return GridView.builder(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 200),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200,
        mainAxisSpacing: 24,
        crossAxisSpacing: 24,
        childAspectRatio: 0.8,
      ),
      itemCount: sortedArtists.length,
      itemBuilder: (context, index) {
        final artist = sortedArtists[index];
        return InkWell(
          onTap: () async {
            final songs = await DbService.isar.songs
                .filter()
                .artistEqualTo(artist.name)
                .findAll();
            // Correctly distinguish between a local downloaded image and a remote URL
            final imageUrl = artist.artistImageUrl;
            final bool isLocalImage =
                imageUrl != null && !imageUrl.startsWith('http');
            final bool isNetworkImage =
                imageUrl != null && imageUrl.startsWith('http');
            ref
                .read(appNavigationProvider.notifier)
                .showCollection(
                  title: artist.name,
                  subtitle: l10n.artist,
                  art: isLocalImage ? imageUrl : artist.artPath,
                  imageUrl: isNetworkImage ? imageUrl : null,
                  songs: songs,
                );
          },
          child: Column(
            children: [
              Expanded(
                child: ClipOval(
                  child: OptimizedImage(
                    imageUrl:
                        artist.artistImageUrl != null &&
                            artist.artistImageUrl!.startsWith('http')
                        ? artist.artistImageUrl
                        : null,
                    imagePath:
                        artist.artistImageUrl != null &&
                            !artist.artistImageUrl!.startsWith('http')
                        ? artist.artistImageUrl
                        : artist.artPath,
                    fit: BoxFit.cover,
                    placeholder: Container(
                      color: Colors.white10,
                      child: const Center(
                        child: Icon(
                          LucideIcons.user,
                          size: 40,
                          color: Colors.white38,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                artist.name,
                style: AppFonts.jostStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }
}
