part of 'collection_detail_view.dart';

extension _CollectionSortSheet on CollectionDetailView {
  void _showSortBottomSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Consumer(
        builder: (context, ref, _) {
          final l10n = AppLocalizations.of(context)!;
          final bool isArtistCollection =
              _isArtistPage(l10n) ||
              (songs.isNotEmpty &&
                  songs.every(
                    (s) => s.artist?.toLowerCase() == title.toLowerCase(),
                  ));
          final current = ref.watch(
            settingsProvider.select((s) => s.collectionSortOptionIndex),
          );
          SortMenuItem item(
            String label,
            IconData icon,
            CollectionSortOption value,
          ) => SortMenuItem(
            label: label,
            icon: icon,
            selected: current == value.index,
            onTap: () => ref
                .read(settingsProvider.notifier)
                .updateCollectionSortOptionIndex(value.index),
          );

          return SortMenuSheet(
            title: l10n.sortBy,
            items: [
              item(
                l10n.sortDefault,
                LucideIcons.listOrdered,
                CollectionSortOption.defaultOrder,
              ),
              item(
                l10n.sortAlphabeticalAZ,
                LucideIcons.arrowDownAZ,
                CollectionSortOption.titleAsc,
              ),
              item(
                l10n.sortAlphabeticalZA,
                LucideIcons.arrowUpZA,
                CollectionSortOption.titleDesc,
              ),
              if (!isArtistCollection)
                item(
                  l10n.sortArtistAsc,
                  LucideIcons.mic2,
                  CollectionSortOption.artistAsc,
                ),
              item(
                l10n.sortAlbumAsc,
                LucideIcons.disc,
                CollectionSortOption.albumAsc,
              ),
              item(
                l10n.sortDuration,
                LucideIcons.clock,
                CollectionSortOption.duration,
              ),
              item(
                l10n.sortYearNewest,
                LucideIcons.calendarArrowDown,
                CollectionSortOption.yearNewest,
              ),
              item(
                l10n.sortYearOldest,
                LucideIcons.calendarArrowUp,
                CollectionSortOption.yearOldest,
              ),
            ],
          );
        },
      ),
    );
  }
}
