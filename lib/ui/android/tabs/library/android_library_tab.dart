import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:looper_player/core/providers/navigation_provider.dart';
import 'package:looper_player/features/library/presentation/providers/library/library_notifier.dart';
import 'package:looper_player/ui/widgets/common/app_refresh_indicator.dart';
import 'package:looper_player/l10n/app_localizations.dart';
import 'package:looper_player/ui/android/widgets/premium_section.dart';
import 'package:looper_player/ui/widgets/common/optimized_image.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:looper_player/features/playback/presentation/providers/playback/playback_notifier.dart';
import 'package:looper_player/core/theme/app_fonts.dart';
import 'package:looper_player/features/library/domain/models/models.dart';

class AndroidLibraryTab extends ConsumerWidget {
  const AndroidLibraryTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                PremiumSection(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(32),
                    bottomLeft: Radius.circular(32),
                    topRight: Radius.circular(10),
                    bottomRight: Radius.circular(10),
                  ),
                  width: 48,
                  height: 48,
                  useExpanded: false,
                  useBlur: true,
                  backgroundColor: Colors.white.withValues(alpha: 0.04),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    ref
                        .read(appNavigationProvider.notifier)
                        .setItem(NavItem.search);
                  },
                  child: const Icon(
                    LucideIcons.search,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                Text(
                  l10n.library,
                  style: AppFonts.jostStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                PremiumSection(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(10),
                    bottomLeft: Radius.circular(10),
                    topRight: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                  width: 48,
                  backgroundColor: Colors.white.withValues(alpha: 0.04),
                  height: 48,
                  useExpanded: false,
                  useBlur: true,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    ref
                        .read(appNavigationProvider.notifier)
                        .setItem(NavItem.settings);
                  },
                  child: const Icon(
                    LucideIcons.settings,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
          // Thin divider below the header
          Container(
            height: 0.5,
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            color: Colors.white.withValues(alpha: 0.15),
          ),
          //const SizedBox(height: 8),
          Expanded(
            child: AppRefreshIndicator(
              onRefresh: () => ref
                  .read(libraryProvider.notifier)
                  .scanSavedFolders(showVisualIndicator: true),
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  // Recent Played Pill
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                      child: Row(
                        children: [
                          PremiumSection(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(32),
                              bottomLeft: Radius.circular(32),
                              topRight: Radius.circular(10),
                              bottomRight: Radius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            useExpanded: false,
                            //useBlur: true,
                            child: Text(
                              l10n.recentPlayed,
                              style: AppFonts.jostStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Recent Played Horizontal Cards
                  SliverToBoxAdapter(
                    child: _buildRecentlyAccessed(context, ref),
                  ),

                  // Categories Pill
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                      child: Row(
                        children: [
                          PremiumSection(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(32),
                              bottomLeft: Radius.circular(32),
                              topRight: Radius.circular(10),
                              bottomRight: Radius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            useExpanded: false,
                            child: Text(
                              l10n.categories,
                              style: AppFonts.jostStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Categories Block 1
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: PremiumSection(
                        borderRadius: BorderRadius.circular(20),
                        padding: EdgeInsets.zero,
                        useExpanded: false,
                        child: Column(
                          children: [
                            _buildCategoryRow(
                              context: context,
                              ref: ref,
                              icon: LucideIcons.star,
                              title: 'Favorites',
                              onTap: () {
                                HapticFeedback.lightImpact();
                                ref
                                    .read(appNavigationProvider.notifier)
                                    .setItem(NavItem.favorites);
                              },
                              isLast: false,
                            ),
                            _buildCategoryRow(
                              context: context,
                              ref: ref,
                              icon: LucideIcons.disc,
                              title: 'Albums',
                              onTap: () {
                                HapticFeedback.lightImpact();
                                ref
                                    .read(appNavigationProvider.notifier)
                                    .setItem(NavItem.albums);
                              },
                              isLast: false,
                            ),
                            _buildCategoryRow(
                              context: context,
                              ref: ref,
                              icon: LucideIcons.users,
                              title: 'Artists',
                              onTap: () {
                                HapticFeedback.lightImpact();
                                ref
                                    .read(appNavigationProvider.notifier)
                                    .setItem(NavItem.artists);
                              },
                              isLast: false,
                            ),
                            _buildCategoryRow(
                              context: context,
                              ref: ref,
                              icon: LucideIcons.listMusic,
                              title: 'Playlists',
                              onTap: () {
                                HapticFeedback.lightImpact();
                                ref
                                    .read(appNavigationProvider.notifier)
                                    .setItem(NavItem.playlists);
                              },
                              isLast: true,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 16)),

                  // Categories Block 2
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: PremiumSection(
                        borderRadius: BorderRadius.circular(20),
                        padding: EdgeInsets.zero,
                        useExpanded: false,
                        child: Column(
                          children: [
                            _buildCategoryRow(
                              context: context,
                              ref: ref,
                              icon: LucideIcons.folder,
                              title: 'Folders',
                              onTap: () {
                                HapticFeedback.lightImpact();
                                ref
                                    .read(appNavigationProvider.notifier)
                                    .setItem(NavItem.folders);
                              },
                              isLast: false,
                            ),
                            _buildCategoryRow(
                              context: context,
                              ref: ref,
                              icon: LucideIcons.music,
                              title: 'Genres',
                              onTap: () {
                                HapticFeedback.lightImpact();
                                ref
                                    .read(appNavigationProvider.notifier)
                                    .setItem(NavItem.genres);
                              },
                              isLast: false,
                            ),
                            _buildCategoryRow(
                              context: context,
                              ref: ref,
                              icon: LucideIcons.list,
                              title: 'Queue',
                              onTap: () {
                                HapticFeedback.lightImpact();
                                ref
                                    .read(appNavigationProvider.notifier)
                                    .setItem(NavItem.queue);
                              },
                              isLast: false,
                            ),
                            _buildCategoryRow(
                              context: context,
                              ref: ref,
                              icon: LucideIcons.history,
                              title: 'History',
                              onTap: () {
                                HapticFeedback.lightImpact();
                                ref
                                    .read(appNavigationProvider.notifier)
                                    .setItem(NavItem.history);
                              },
                              isLast: false,
                            ),
                            _buildCategoryRow(
                              context: context,
                              ref: ref,
                              icon: LucideIcons.barChart3,
                              title: 'Looper Analyze',
                              onTap: () {
                                HapticFeedback.lightImpact();
                                ref
                                    .read(appNavigationProvider.notifier)
                                    .setItem(NavItem.analyze);
                              },
                              isLast: true,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Bottom padding to clear Mini Player and let UI breathe
                  const SliverToBoxAdapter(child: SizedBox(height: 200)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentlyAccessed(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final recentSongs = ref.watch(dashboardRecentlyPlayedProvider).value ?? [];
    if (recentSongs.isEmpty) {
      return SizedBox(
        height: 100,
        child: Center(
          child: Text(
            l10n.noRecentlyPlayedTracks,
            style: AppFonts.jostStyle(
              color: Colors.white.withValues(alpha: 0.3),
              fontSize: 13,
            ),
          ),
        ),
      );
    }

    final row1Songs = <Song>[];
    final row2Songs = <Song>[];
    for (int i = 0; i < recentSongs.length; i++) {
      if (i % 2 == 0) {
        row1Songs.add(recentSongs[i]);
      } else {
        row2Songs.add(recentSongs[i]);
      }
    }

    final hasTwoRows = recentSongs.length > 1;

    return SizedBox(
      height: hasTwoRows ? 100 : 50,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: row1Songs.map((song) {
                final globalIndex = recentSongs.indexOf(song);
                return _buildRecentPill(
                  context,
                  ref,
                  song,
                  recentSongs,
                  globalIndex,
                );
              }).toList(),
            ),
            if (hasTwoRows) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: row2Songs.map((song) {
                  final globalIndex = recentSongs.indexOf(song);
                  return _buildRecentPill(
                    context,
                    ref,
                    song,
                    recentSongs,
                    globalIndex,
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRecentPill(
    BuildContext context,
    WidgetRef ref,
    Song song,
    List<Song> recentSongs,
    int index,
  ) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: PremiumSection(
        borderRadius: BorderRadius.circular(36),
        useExpanded: false,
        onTap: () {
          HapticFeedback.lightImpact();
          ref
              .read(playbackProvider.notifier)
              .setPlaylist(recentSongs, initialIndex: index);
        },
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                width: 24,
                height: 24,
                child: OptimizedImage(
                  imagePath: song.artPath,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              song.title,
              style: AppFonts.jostStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryRow({
    required BuildContext context,
    required WidgetRef ref,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required bool isLast,
  }) {
    final l10n = AppLocalizations.of(context)!;
    String translatedTitle = title;
    switch (title) {
      case 'Favorites':
        translatedTitle = l10n.favorites;
        break;
      case 'Albums':
        translatedTitle = l10n.albums;
        break;
      case 'Artists':
        translatedTitle = l10n.artists;
        break;
      case 'Playlists':
        translatedTitle = l10n.playlists;
        break;
      case 'Folders':
        translatedTitle = l10n.folders;
        break;
      case 'Genres':
        translatedTitle = l10n.genres;
        break;
      case 'Queue':
        translatedTitle = l10n.queue;
        break;
      case 'History':
        translatedTitle = l10n.history;
        break;
      case 'Looper Analyze':
        translatedTitle = l10n.looperAnalyze;
        break;
    }

    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: Colors.white.withValues(alpha: 0.9),
                  size: 22,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    translatedTitle,
                    style: AppFonts.jostStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Icon(
                  LucideIcons.chevronRight,
                  color: Colors.white.withValues(alpha: 0.9),
                  size: 18,
                ),
              ],
            ),
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            thickness: 0.9,
            color: Colors.white.withValues(alpha: 0.1),
            indent: 20,
            endIndent: 20,
          ),
      ],
    );
  }
}
