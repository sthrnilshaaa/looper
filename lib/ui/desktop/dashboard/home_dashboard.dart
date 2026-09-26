import 'package:flutter/material.dart';
import 'package:looper_player/core/utils/ui_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:looper_player/ui/widgets/common/optimized_image.dart';
import 'package:flutter_svg/svg.dart';
import 'package:looper_player/ui/widgets/player/global_playing_indicator.dart';
import 'package:looper_player/features/library/presentation/widgets/library_grids.dart';
import 'package:looper_player/features/settings/presentation/providers/settings_notifier.dart';
import 'package:looper_player/ui/widgets/common/color_maper.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:looper_player/features/library/presentation/providers/library/library_notifier.dart';
import 'package:looper_player/features/playback/presentation/providers/playback/playback_notifier.dart';
import 'package:looper_player/core/providers/navigation_provider.dart';
import 'package:looper_player/l10n/app_localizations.dart';
import 'package:looper_player/core/services/storage/db_service.dart';
import 'package:isar_community/isar.dart';
import 'package:looper_player/core/utils/l10n.dart';
part 'featured_artist_card.dart';
part 'dashboard_sections.dart';
part 'desktop_items.dart';

class HomeDashboard extends ConsumerWidget {
  const HomeDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final bool isDynamic = settings.enableDynamicTheming;
    final library = ref.watch(libraryProvider);
    final l10n = AppLocalizations.of(context)!;

    final genresMap = <String, List<Song>>{};
    for (var song in library.songs) {
      final genre = song.genre ?? l10n.unknown;
      genresMap.putIfAbsent(genre, () => []).add(song);
    }
    final genres = genresMap.keys.toList()..sort();

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isNarrow = constraints.maxWidth < 600;
        final bool isMedium = constraints.maxWidth < 1000;
        final bool showLogo = MediaQuery.of(context).size.width < 800;

        final orderedChildren = <Widget>[];

        if (showLogo) {
          orderedChildren.add(
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 50.s,
                  child: SvgPicture.asset(
                    'assets/main_logo_transparent.svg',
                    fit: BoxFit.contain,
                    colorMapper: AccentColorMapper(
                      Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        }

        // Support desktop-specific helper rows at the very top
        orderedChildren.add(
          _buildRecentlyPlayed(ref, isNarrow, isDynamic, l10n),
        );
        orderedChildren.add(const SizedBox(height: 16));
        orderedChildren.add(
          _buildAlbumsIfSmall(ref, isNarrow, isDynamic, l10n),
        );
        orderedChildren.add(const SizedBox(height: 16));

        // Render sections dynamically in user's customized order
        for (final section in settings.homeSectionOrder) {
          if (section == 'quick_picks') {
            orderedChildren.add(
              _buildQuickPicks(ref, isNarrow, isMedium, isDynamic, l10n),
            );
            orderedChildren.add(const SizedBox(height: 16));
          } else if (section == 'songs') {
            // Render Featured Artists and Albums for the "songs" slot on desktop
            orderedChildren.add(
              _buildTopArtists(ref, isNarrow, isDynamic, l10n),
            );
            orderedChildren.add(const SizedBox(height: 16));
            orderedChildren.add(
              _buildFeaturedAlbums(ref, isNarrow, isDynamic, context),
            );
            orderedChildren.add(const SizedBox(height: 16));
          } else if (section == 'artists') {
            if (settings.showHomeArtists && library.artists.isNotEmpty) {
              orderedChildren.add(
                _buildDesktopHorizontalSection(
                  title: l10n.artists,
                  l10n: l10n,
                  onViewAll: () => ref
                      .read(appNavigationProvider.notifier)
                      .setItem(NavItem.artists),
                  itemCount: library.artists.length,
                  itemBuilder: (context, index) {
                    return _buildDesktopArtistItem(
                      ref,
                      library.artists[index],
                      l10n,
                    );
                  },
                ),
              );
              orderedChildren.add(const SizedBox(height: 16));
            }
          } else if (section == 'albums') {
            if (settings.showHomeAlbums && library.albums.isNotEmpty) {
              orderedChildren.add(
                _buildDesktopHorizontalSection(
                  title: l10n.albums,
                  l10n: l10n,
                  onViewAll: () => ref
                      .read(appNavigationProvider.notifier)
                      .setItem(NavItem.albums),
                  itemCount: library.albums.length,
                  itemBuilder: (context, index) {
                    return _buildDesktopAlbumItem(
                      ref,
                      library.albums[index],
                      l10n,
                    );
                  },
                ),
              );
              orderedChildren.add(const SizedBox(height: 16));
            }
          } else if (section == 'genres') {
            if (settings.showHomeGenres && genres.isNotEmpty) {
              orderedChildren.add(
                _buildDesktopHorizontalSection(
                  title: l10n.genres,
                  l10n: l10n,
                  onViewAll: () => ref
                      .read(appNavigationProvider.notifier)
                      .setItem(NavItem.genres),
                  itemCount: genres.length,
                  itemBuilder: (context, index) {
                    final genre = genres[index];
                    return _buildDesktopGenreItem(
                      ref,
                      genre,
                      genresMap[genre]!,
                      l10n,
                    );
                  },
                ),
              );
              orderedChildren.add(const SizedBox(height: 16));
            }
          }
        }

        orderedChildren.add(const SizedBox(height: 120));

        return ListView(
          padding: EdgeInsets.only(
            top: (isNarrow ? 4 : 8).s,
            left: (isNarrow ? 16 : 32).s,
            right: (isNarrow ? 16 : 32).s,
          ),
          children: orderedChildren,
        );
      },
    );
  }
}
