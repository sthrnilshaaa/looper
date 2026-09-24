import 'package:flutter/material.dart';
import 'package:looper_player/ui/widgets/app_loading_indicator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:looper_player/features/library/domain/models/models.dart';
import 'package:looper_player/core/db_service.dart';
import 'package:isar_community/isar.dart';
import 'package:looper_player/features/library/presentation/songs_list.dart';
import 'package:looper_player/l10n/app_localizations.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'smart_views.g.dart';

@Riverpod(keepAlive: true)
Stream<List<Song>> favorites(Ref ref) {
  return DbService.isar.songs
      .filter()
      .isFavoriteEqualTo(true)
      .watch(fireImmediately: true);
}

/// Last 50 played songs for the dedicated "Recently Played" screen. Distinct
/// from [dashboardRecentlyPlayedProvider] (library_notifier.dart, limit 10)
/// which backs the Home dashboard's smaller preview list.
@Riverpod(keepAlive: true)
Stream<List<Song>> recentlyPlayedScreen(Ref ref) {
  return DbService.isar.songs
      .where()
      .filter()
      .lastPlayedIsNotNull()
      .sortByLastPlayedDesc()
      .limit(50)
      .watch(fireImmediately: true);
}

class FavoritesView extends ConsumerWidget {
  const FavoritesView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final favoritesAsync = ref.watch(favoritesProvider);

    return favoritesAsync.when(
      data: (songs) => songs.isEmpty
          ? _buildEmpty(context, LucideIcons.heart, l10n.noFavoritesYet)
          : SongsList(songs: songs),
      loading: () => const AppLoadingIndicator(),
      error: (e, s) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildEmpty(BuildContext context, IconData icon, String text) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Text(text),
        ],
      ),
    );
  }
}

class RecentlyPlayedView extends ConsumerWidget {
  const RecentlyPlayedView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final recentlyPlayedAsync = ref.watch(recentlyPlayedScreenProvider);

    return recentlyPlayedAsync.when(
      data: (songs) => songs.isEmpty
          ? _buildEmpty(context, LucideIcons.clock, l10n.noHistoryYet)
          : SongsList(songs: songs),
      loading: () => const AppLoadingIndicator(),
      error: (e, s) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildEmpty(BuildContext context, IconData icon, String text) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Text(text),
        ],
      ),
    );
  }
}
