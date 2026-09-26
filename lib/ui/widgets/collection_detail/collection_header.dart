part of 'collection_detail_view.dart';

extension _CollectionHeader on CollectionDetailView {
  Widget _buildArt(BuildContext context, bool isNarrow, String? artOverride) {
    final double size = 140; // Unified size for a cleaner Row look
    return OptimizedImage(
      imagePath: artOverride,
      imageUrl: imageUrl,
      width: size,
      height: size,
      borderRadius: BorderRadius.circular(16),
      placeholder: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(LucideIcons.music, size: 48, color: Colors.grey),
      ),
    );
  }

  Widget _buildInfo(
    BuildContext context,
    WidgetRef ref,
    bool isNarrow,
    String? activeArtworkPath,
    Playlist? reactivePlaylist,
    Album? reactiveAlbum,
    String titleToRender,
    String? subtitleToRender,
    List<Song> songsToRender,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titleToRender,
          style: AppFonts.jostStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (subtitleToRender != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitleToRender,
            style: AppFonts.jostStyle(
              fontSize: 16,
              color: Colors.white.withValues(alpha: 0.5),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            PremiumSection(
              borderRadius: BorderRadius.circular(12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              height: 44,
              useExpanded: false,
              onTap: () {
                HapticFeedback.mediumImpact();
                ref.read(playbackProvider.notifier).setPlaylist(songsToRender);
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    AppLocalizations.of(context)!.playAll,
                    style: AppFonts.jostStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            PremiumSection(
              borderRadius: BorderRadius.circular(12),
              width: 44,
              height: 44,
              useExpanded: false,
              onTap: () {
                HapticFeedback.lightImpact();
                ref.read(playbackProvider.notifier).toggleShuffle();
                ref.read(playbackProvider.notifier).setPlaylist(songsToRender);
              },
              child: const Icon(
                LucideIcons.shuffle,
                size: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            PremiumSection(
              borderRadius: BorderRadius.circular(12),
              width: 44,
              height: 44,
              useExpanded: false,
              onTap: () {
                HapticFeedback.lightImpact();
                _showSortBottomSheet(context, ref);
              },
              child: const Icon(
                LucideIcons.arrowUpDown,
                size: 16,
                color: Colors.white,
              ),
            ),
            if (reactivePlaylist != null) ...[
              const SizedBox(width: 8),
              PremiumSection(
                borderRadius: BorderRadius.circular(12),
                width: 44,
                height: 44,
                useExpanded: false,
                onTap: () =>
                    _showPlaylistOptions(context, ref, reactivePlaylist),
                child: const Icon(
                  LucideIcons.moreHorizontal,
                  size: 18,
                  color: Colors.white,
                ),
              ),
            ] else if (reactiveAlbum != null) ...[
              const SizedBox(width: 8),
              PremiumSection(
                borderRadius: BorderRadius.circular(12),
                width: 44,
                height: 44,
                useExpanded: false,
                onTap: () {
                  HapticFeedback.lightImpact();
                  _showEditAlbumSheet(context, ref, reactiveAlbum);
                },
                child: const Icon(
                  LucideIcons.edit2,
                  size: 18,
                  color: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
