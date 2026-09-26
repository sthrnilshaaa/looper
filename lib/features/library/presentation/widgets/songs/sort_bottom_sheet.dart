part of 'songs_list.dart';

void _showSortBottomSheet(
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
          final settings = ref.watch(settingsProvider);
          final accentColor = Color(settings.accentColor);

          return AppBottomSheetContainer(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Text(
                        l10n.sortOrder,
                        style: AppFonts.jostStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        ref.read(libraryProvider.notifier).toggleSortOrder();
                      },
                      icon: Icon(
                        state.isAscending
                            ? LucideIcons.arrowUpAZ
                            : LucideIcons.arrowDownAZ,
                        size: 18,
                      ),
                      label: Text(
                        state.isAscending ? l10n.ascending : l10n.descending,
                      ),
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
                  ],
                ),
                const Divider(color: Colors.white10, height: 24),
                Flexible(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20.0,
                        vertical: 8.0,
                      ),
                      child: PremiumSection(
                        borderRadius: BorderRadius.circular(20),
                        padding: EdgeInsets.zero,
                        useExpanded: false,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _SortOption(
                              label: l10n.dateAdded,
                              icon: LucideIcons.calendar,
                              isSelected:
                                  state.sortStrategy ==
                                  SongSortStrategy.dateAdded,
                              accentColor: accentColor,
                              isLast: false,
                              onTap: () {
                                HapticFeedback.lightImpact();
                                ref
                                    .read(libraryProvider.notifier)
                                    .setSortStrategy(
                                      SongSortStrategy.dateAdded,
                                    );
                                Navigator.pop(context);
                              },
                            ),
                            _SortOption(
                              label: l10n.title,
                              icon: LucideIcons.type,
                              isSelected:
                                  state.sortStrategy == SongSortStrategy.title,
                              accentColor: accentColor,
                              isLast: false,
                              onTap: () {
                                HapticFeedback.lightImpact();
                                ref
                                    .read(libraryProvider.notifier)
                                    .setSortStrategy(SongSortStrategy.title);
                                Navigator.pop(context);
                              },
                            ),
                            _SortOption(
                              label: l10n.artist,
                              icon: LucideIcons.mic2,
                              isSelected:
                                  state.sortStrategy == SongSortStrategy.artist,
                              accentColor: accentColor,
                              isLast: false,
                              onTap: () {
                                HapticFeedback.lightImpact();
                                ref
                                    .read(libraryProvider.notifier)
                                    .setSortStrategy(SongSortStrategy.artist);
                                Navigator.pop(context);
                              },
                            ),
                            _SortOption(
                              label: l10n.album,
                              icon: LucideIcons.disc,
                              isSelected:
                                  state.sortStrategy == SongSortStrategy.album,
                              accentColor: accentColor,
                              isLast: false,
                              onTap: () {
                                HapticFeedback.lightImpact();
                                ref
                                    .read(libraryProvider.notifier)
                                    .setSortStrategy(SongSortStrategy.album);
                                Navigator.pop(context);
                              },
                            ),
                            _SortOption(
                              label: l10n.duration,
                              icon: LucideIcons.clock,
                              isSelected:
                                  state.sortStrategy ==
                                  SongSortStrategy.duration,
                              accentColor: accentColor,
                              isLast: false,
                              onTap: () {
                                HapticFeedback.lightImpact();
                                ref
                                    .read(libraryProvider.notifier)
                                    .setSortStrategy(SongSortStrategy.duration);
                                Navigator.pop(context);
                              },
                            ),
                            _SortOption(
                              label: l10n.year,
                              icon: LucideIcons.calendarDays,
                              isSelected:
                                  state.sortStrategy == SongSortStrategy.year,
                              accentColor: accentColor,
                              isLast: false,
                              onTap: () {
                                HapticFeedback.lightImpact();
                                ref
                                    .read(libraryProvider.notifier)
                                    .setSortStrategy(SongSortStrategy.year);
                                Navigator.pop(context);
                              },
                            ),
                            _SortOption(
                              label: l10n.mostPlayed,
                              icon: LucideIcons.trendingUp,
                              isSelected:
                                  state.sortStrategy ==
                                  SongSortStrategy.playCount,
                              accentColor: accentColor,
                              isLast: false,
                              onTap: () {
                                HapticFeedback.lightImpact();
                                ref
                                    .read(libraryProvider.notifier)
                                    .setSortStrategy(
                                      SongSortStrategy.playCount,
                                    );
                                Navigator.pop(context);
                              },
                            ),
                            _SortOption(
                              label: l10n.recentlyPlayed,
                              icon: LucideIcons.history,
                              isSelected:
                                  state.sortStrategy ==
                                  SongSortStrategy.lastPlayed,
                              accentColor: accentColor,
                              isLast: true,
                              onTap: () {
                                HapticFeedback.lightImpact();
                                ref
                                    .read(libraryProvider.notifier)
                                    .setSortStrategy(
                                      SongSortStrategy.lastPlayed,
                                    );
                                Navigator.pop(context);
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      );
    },
  );
}

class _SortOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Color accentColor;
  final bool isLast;
  final VoidCallback onTap;

  const _SortOption({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.accentColor,
    required this.isLast,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
                  size: 22,
                  color: isSelected
                      ? accentColor
                      : Colors.white.withValues(alpha: 0.9),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: AppFonts.jostStyle(
                      color: isSelected
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: accentColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      LucideIcons.check,
                      color: Colors.white,
                      size: 10,
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            thickness: 0.8,
            color: Colors.white.withValues(alpha: 0.04),
            indent: 20,
            endIndent: 20,
          ),
      ],
    );
  }
}
