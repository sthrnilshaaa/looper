import 'package:looper_player/features/library/data/services/artist_catalog.dart';
import 'package:looper_player/core/utils/song_metadata.dart';
import 'package:looper_player/core/providers/collection_navigation.dart';
import 'package:flutter/material.dart';
import 'package:looper_player/ui/widgets/common/song_artwork.dart';
import 'package:looper_player/core/utils/ui_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:looper_player/ui/widgets/common/optimized_image.dart';
import 'package:flutter_svg/svg.dart';
import 'package:looper_player/features/library/presentation/widgets/library_grids.dart';
import 'package:looper_player/features/settings/presentation/providers/settings_notifier.dart';
import 'package:looper_player/ui/widgets/common/color_maper.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:looper_player/features/library/presentation/providers/library/library_notifier.dart';
import 'package:looper_player/features/playback/presentation/providers/playback/playback_notifier.dart';
import 'package:looper_player/features/playlists/presentation/screens/playlist_view.dart';
import 'package:looper_player/core/providers/navigation_provider.dart';
import 'package:looper_player/l10n/app_localizations.dart';
import 'package:looper_player/core/services/storage/db_service.dart';
import 'package:isar_community/isar.dart';
import 'package:looper_player/core/utils/l10n.dart';
import 'package:looper_player/core/theme/app_assets.dart';
import 'package:looper_player/ui/desktop/dashboard/desktop_home_sections.dart';
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
    final playlists = ref.watch(dashboardPlaylistsProvider).value ?? [];

    final genresMap = <String, List<Song>>{};
    for (var song in library.songs) {
      final genre = song.genre ?? l10n.unknown;
      genresMap.putIfAbsent(genre, () => []).add(song);
    }
    final genres = genresMap.keys.toList()..sort();

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isNarrow = constraints.maxWidth < 600;
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
                    AppAssets.logo,
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

        const gap = SizedBox(height: 28);

        // Fixed desktop order; a row with nothing to show is skipped whole,
        // so it leaves no gap behind.
        for (final section in desktopHomeSections(
          showPlaylists: settings.showHomePlaylists ?? true,
          showRecent: settings.showHomeRecent,
          showGenres: settings.showHomeGenres,
          showArtists: settings.showHomeArtists,
        )) {
          switch (section) {
            case DesktopHomeSection.quickPicks:
              if ((ref.watch(topSongsProvider).value ?? const []).isEmpty) {
                continue;
              }
              orderedChildren.add(
                _buildQuickPicks(context, ref, isNarrow, isDynamic, l10n),
              );
            case DesktopHomeSection.playlists:
              if (playlists.isEmpty) continue;
              orderedChildren.add(
                _buildDesktopHorizontalSection(
                  context,
                  title: l10n.playlists,
                  l10n: l10n,
                  onViewAll: () => ref
                      .read(appNavigationProvider.notifier)
                      .setItem(NavItem.playlists),
                  itemCount: playlists.length,
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: SizedBox(
                      width: 140,
                      child: PlaylistCard(playlist: playlists[index]),
                    ),
                  ),
                ),
              );
            case DesktopHomeSection.recentlyPlayed:
              if ((ref.watch(dashboardRecentlyPlayedProvider).value ?? const [])
                  .isEmpty) {
                continue;
              }
              orderedChildren.add(
                _buildRecentlyPlayed(context, ref, isNarrow, isDynamic, l10n),
              );
            case DesktopHomeSection.featuredArtists:
              if ((ref.watch(artistsProvider).value ?? const []).isEmpty) {
                continue;
              }
              orderedChildren.add(
                _buildTopArtists(context, ref, isNarrow, isDynamic, l10n),
              );
            case DesktopHomeSection.albums:
              if ((ref.watch(albumsProvider).value ?? const []).isEmpty) {
                continue;
              }
              orderedChildren.add(
                _buildFeaturedAlbums(ref, isNarrow, isDynamic, context),
              );
            case DesktopHomeSection.genres:
              if (genres.isEmpty) continue;
              orderedChildren.add(
                _buildDesktopHorizontalSection(
                  context,
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
            case DesktopHomeSection.artists:
              if (library.artists.isEmpty) continue;
              orderedChildren.add(
                _buildDesktopHorizontalSection(
                  context,
                  title: l10n.artists,
                  l10n: l10n,
                  onViewAll: () => ref
                      .read(appNavigationProvider.notifier)
                      .setItem(NavItem.artists),
                  itemCount: library.artists.length,
                  itemBuilder: (context, index) => _buildDesktopArtistItem(
                    ref,
                    library.artists[index],
                    l10n,
                  ),
                ),
              );
          }
          orderedChildren.add(gap);
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
