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
            _isArtistPage(l10n) ||
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
              if (isArtistCollection) ...[
                const _GroupByAlbumToggle(),
                const SizedBox(height: 12),
              ],
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
        AppHaptics.light();
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

/// "Group by album" switch at the top of an artist page's sort sheet.
class _GroupByAlbumToggle extends ConsumerWidget {
  const _GroupByAlbumToggle();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final value = ref.watch(
      settingsProvider.select((s) => s.artistGroupByAlbum),
    );
    final accent = Color(
      ref.watch(settingsProvider.select((s) => s.accentColor)),
    );
    void toggle() {
      AppHaptics.light();
      ref.read(settingsProvider.notifier).updateArtistGroupByAlbum(!value);
    }

    return PremiumSection(
      borderRadius: BorderRadius.circular(20),
      padding: EdgeInsets.zero,
      useExpanded: false,
      child: InkWell(
        onTap: toggle,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
          child: Row(
            children: [
              Icon(LucideIcons.disc3, size: 20, color: accent),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.groupByAlbum,
                      style: AppFonts.jostStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.groupByAlbumDesc,
                      style: AppFonts.jostStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: value,
                activeThumbColor: accent,
                onChanged: (_) => toggle(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
