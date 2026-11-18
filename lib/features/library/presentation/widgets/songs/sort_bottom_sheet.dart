part of 'songs_list.dart';

/// The library's song sort menu.
void showSongSortSheet(
  BuildContext context,
  WidgetRef ref,
  AppLocalizations l10n,
) {
  showModalBottomSheet(
    context: context,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black54,
    isScrollControlled: true,
    builder: (context) {
      return Consumer(
        builder: (context, ref, child) {
          final state = ref.watch(libraryProvider);
          final accentColor = ref.watch(settingsProvider).accent;
          final notifier = ref.read(libraryProvider.notifier);
          SortMenuItem item(
            String label,
            IconData icon,
            SongSortStrategy strategy,
          ) => SortMenuItem(
            label: label,
            icon: icon,
            selected: state.sortStrategy == strategy,
            onTap: () => notifier.setSortStrategy(strategy),
          );

          return SortMenuSheet(
            title: l10n.sortOrder,
            trailing: TextButton.icon(
              onPressed: () {
                AppHaptics.light();
                notifier.toggleSortOrder();
              },
              icon: Icon(
                state.isAscending
                    ? LucideIcons.arrowUpAZ
                    : LucideIcons.arrowDownAZ,
                size: 18,
              ),
              label: Text(state.isAscending ? l10n.ascending : l10n.descending),
              style: TextButton.styleFrom(
                foregroundColor: accentColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            items: [
              item(
                l10n.dateAdded,
                LucideIcons.calendar,
                SongSortStrategy.dateAdded,
              ),
              item(l10n.title, LucideIcons.type, SongSortStrategy.title),
              item(l10n.artist, LucideIcons.mic2, SongSortStrategy.artist),
              item(l10n.album, LucideIcons.disc, SongSortStrategy.album),
              item(l10n.duration, LucideIcons.clock, SongSortStrategy.duration),
              item(l10n.year, LucideIcons.calendarDays, SongSortStrategy.year),
              item(
                l10n.mostPlayed,
                LucideIcons.trendingUp,
                SongSortStrategy.playCount,
              ),
              item(
                l10n.recentlyPlayed,
                LucideIcons.history,
                SongSortStrategy.lastPlayed,
              ),
              item(
                l10n.mostFullyPlayed,
                LucideIcons.circleCheckBig,
                SongSortStrategy.fullPlays,
              ),
            ],
          );
        },
      );
    },
  );
}
