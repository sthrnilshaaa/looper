part of 'collection_detail_view.dart';

extension _CollectionHeader on CollectionDetailView {
  /// Songs join a playlist from their own options menu, so the playlist's +
  /// button explains where that is rather than opening a picker.
  void _showAddSongsHint(BuildContext context) {
    AppHaptics.light();
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(
            UiUtils.isDesktop
                ? l10n.addSongsToPlaylistHintDesktop
                : l10n.addSongsToPlaylistHint,
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
        ),
      );
  }

  /// Rows only start dragging after a long-press, which isn't discoverable
  /// on its own, so the playlist header's info button explains it.
  void _showReorderHint(BuildContext context) {
    AppHaptics.light();
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.reorderSongsHint),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
  }

  Widget _buildArt(
    BuildContext context,
    bool isNarrow,
    String? artOverride, {
    Playlist? playlist,
    String? imageUrl,
  }) {
    final double size = 140; // Unified size for a cleaner Row look
    if (playlist != null) {
      return PlaylistArtwork(
        songPaths: playlist.songPaths,
        size: size,
        borderRadius: BorderRadius.circular(16),
      );
    }
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
    List<Song> songsToRender, {
    bool songsLoading = false,
    bool canReorder = false,
    Key? titleKey,
    Artist? reactiveArtist,
  }) {
    final l10n = AppLocalizations.of(context)!;
    // Lit only while this collection is the one playing shuffled.
    final key = collectionKey(songsToRender);
    final isShuffle = ref.watch(
      playbackProvider.select((s) => s.isShuffle && s.queueSourceKey == key),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titleToRender,
          key: titleKey,
          style: AppFonts.jostStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Flexible(
              child: _buildCollectionSubtitle(
                reactivePlaylist != null ? l10n.playlist : subtitleToRender,
                songsToRender,
                l10n,
                fontSize: 16,
                songsLoading: songsLoading,
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ),
            if (canReorder)
              IconButton(
                tooltip: l10n.reorderSongsHint,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(
                  width: 32,
                  height: 32,
                ),
                style: IconButton.styleFrom(
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () => _showReorderHint(context),
                icon: Icon(
                  LucideIcons.info,
                  size: 16,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
          ],
        ),
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
                AppHaptics.medium();
                final playback = ref.read(playbackProvider.notifier);
                playback.playCollection(
                  songsToRender,
                  sourcePlaylistId: reactivePlaylist?.id,
                );
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
                    l10n.play,
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
              backgroundColor: isShuffle
                  ? Colors.white.withValues(alpha: 0.10)
                  : null,
              onTap: () {
                AppHaptics.light();
                ref
                    .read(playbackProvider.notifier)
                    .toggleCollectionShuffle(
                      songsToRender,
                      sourcePlaylistId: reactivePlaylist?.id,
                    );
              },
              child: Semantics(
                label: l10n.shuffleTitle,
                toggled: isShuffle,
                child: Icon(
                  LucideIcons.shuffle,
                  size: 16,
                  color: isShuffle
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.5),
                ),
              ),
            ),
            const SizedBox(width: 8),
            PremiumSection(
              borderRadius: BorderRadius.circular(12),
              width: 44,
              height: 44,
              useExpanded: false,
              onTap: () {
                AppHaptics.light();
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
                  AppHaptics.light();
                  _showEditAlbumSheet(context, ref, reactiveAlbum);
                },
                child: const Icon(
                  LucideIcons.edit2,
                  size: 18,
                  color: Colors.white,
                ),
              ),
            ] else if (reactiveArtist != null) ...[
              const SizedBox(width: 8),
              PremiumSection(
                borderRadius: BorderRadius.circular(12),
                width: 44,
                height: 44,
                useExpanded: false,
                onTap: () {
                  AppHaptics.light();
                  _showEditArtistSheet(context, reactiveArtist);
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
