part of 'collection_detail_view.dart';

extension _CollectionSortSheet on CollectionDetailView {
  void _showSortBottomSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        final bool isArtistCollection =
            (subtitle != null &&
                (subtitle!.toLowerCase() == 'artist' ||
                    subtitle == l10n.artist)) ||
            (songs.isNotEmpty &&
                songs.every(
                  (s) => s.artist?.toLowerCase() == title.toLowerCase(),
                ));

        return AppBottomSheetContainer(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.sortBy,
                style: AppFonts.jostStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              PremiumSection(
                borderRadius: BorderRadius.circular(20),
                padding: EdgeInsets.zero,
                useExpanded: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildSortItem(
                      context,
                      ref,
                      l10n.sortDefault,
                      CollectionSortOption.defaultOrder,
                    ),
                    const Divider(
                      color: Colors.white10,
                      height: 1,
                      indent: 20,
                      endIndent: 20,
                    ),
                    _buildSortItem(
                      context,
                      ref,
                      l10n.sortAlphabeticalAZ,
                      CollectionSortOption.titleAsc,
                    ),
                    const Divider(
                      color: Colors.white10,
                      height: 1,
                      indent: 20,
                      endIndent: 20,
                    ),
                    _buildSortItem(
                      context,
                      ref,
                      l10n.sortAlphabeticalZA,
                      CollectionSortOption.titleDesc,
                    ),
                    if (!isArtistCollection) ...[
                      const Divider(
                        color: Colors.white10,
                        height: 1,
                        indent: 20,
                        endIndent: 20,
                      ),
                      _buildSortItem(
                        context,
                        ref,
                        l10n.sortArtistAsc,
                        CollectionSortOption.artistAsc,
                      ),
                    ],
                    const Divider(
                      color: Colors.white10,
                      height: 1,
                      indent: 20,
                      endIndent: 20,
                    ),
                    _buildSortItem(
                      context,
                      ref,
                      l10n.sortAlbumAsc,
                      CollectionSortOption.albumAsc,
                    ),
                    const Divider(
                      color: Colors.white10,
                      height: 1,
                      indent: 20,
                      endIndent: 20,
                    ),
                    _buildSortItem(
                      context,
                      ref,
                      l10n.sortDuration,
                      CollectionSortOption.duration,
                    ),
                    const Divider(
                      color: Colors.white10,
                      height: 1,
                      indent: 20,
                      endIndent: 20,
                    ),
                    _buildSortItem(
                      context,
                      ref,
                      l10n.sortYearNewest,
                      CollectionSortOption.yearNewest,
                    ),
                    const Divider(
                      color: Colors.white10,
                      height: 1,
                      indent: 20,
                      endIndent: 20,
                    ),
                    _buildSortItem(
                      context,
                      ref,
                      l10n.sortYearOldest,
                      CollectionSortOption.yearOldest,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSortItem(
    BuildContext context,
    WidgetRef ref,
    String label,
    CollectionSortOption value,
  ) {
    final settings = ref.watch(settingsProvider);
    final isSelected = settings.collectionSortOptionIndex == value.index;
    final accentColor = Color(settings.accentColor);

    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        ref
            .read(settingsProvider.notifier)
            .updateCollectionSortOptionIndex(value.index);
        Navigator.pop(context);
      },
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: AppFonts.jostStyle(
                color: isSelected ? accentColor : Colors.white70,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 15,
              ),
            ),
            if (isSelected)
              Icon(LucideIcons.check, color: accentColor, size: 20),
          ],
        ),
      ),
    );
  }
}
