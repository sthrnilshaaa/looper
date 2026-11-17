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

  /// Full-bleed hero artwork: the playlist's grid / cover, or the
  /// album / artist / list art.
  Widget _heroStill(Playlist? playlist, String? art, String? imageUrl) {
    if (playlist != null) {
      return FittedBox(
        fit: BoxFit.cover,
        clipBehavior: Clip.hardEdge,
        child: PlaylistArtwork(
          songPaths: playlist.songPaths,
          coverPath: playlist.coverPath,
          size: collectionHeroHeight,
          borderRadius: BorderRadius.zero,
        ),
      );
    }
    return OptimizedImage(
      imagePath: art,
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      placeholder: ColoredBox(
        color: Colors.white.withValues(alpha: 0.05),
        child: const Center(
          child: Icon(LucideIcons.music, size: 64, color: Colors.grey),
        ),
      ),
    );
  }

  /// The small cover in [CollectionHeroBar].
  Widget _miniCover(Playlist? playlist, String? art, String? imageUrl) {
    const size = 42.0;
    final radius = BorderRadius.circular(4);
    if (playlist != null) {
      return PlaylistArtwork(
        songPaths: playlist.songPaths,
        coverPath: playlist.coverPath,
        size: size,
        borderRadius: radius,
      );
    }
    return OptimizedImage(
      imagePath: art,
      imageUrl: imageUrl,
      width: size,
      height: size,
      borderRadius: radius,
      placeholder: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: radius,
        ),
        child: const Icon(LucideIcons.music, size: 16, color: Colors.grey),
      ),
    );
  }

  /// The hero's action row, scrolling sideways when it outgrows the screen.
  Widget _heroActions(
    BuildContext context,
    WidgetRef ref, {
    required bool isArtist,
    required String title,
    required List<Song> songs,
    String? thumbnail,
    Playlist? playlist,
    Album? album,
    Artist? artist,
    bool canReorder = false,
  }) {
    final l10n = AppLocalizations.of(context)!;
    // Lit only while this collection is the one playing shuffled.
    final key = collectionKey(songs);
    final isShuffle = ref.watch(
      playbackProvider.select((s) => s.isShuffle && s.queueSourceKey == key),
    );
    Widget round(IconData icon, VoidCallback onTap, String label) => Padding(
      padding: const EdgeInsets.only(left: 12),
      child: HeroRoundButton(
        icon: icon,
        size: 48,
        semanticLabel: label,
        onTap: () {
          AppHaptics.light();
          onTap();
        },
      ),
    );
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          HeroPillButton(
            icon: Icons.play_arrow_rounded,
            label: l10n.play,
            onTap: () {
              AppHaptics.medium();
              ref
                  .read(playbackProvider.notifier)
                  .playCollection(songs, sourcePlaylistId: playlist?.id);
            },
          ),
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Semantics(
              toggled: isShuffle,
              child: HeroRoundButton(
                icon: LucideIcons.shuffle,
                size: 48,
                semanticLabel: l10n.shuffleTitle,
                fill: isShuffle
                    ? Colors.white.withValues(alpha: 0.24)
                    : const Color(0x17FFFFFF),
                onTap: () {
                  AppHaptics.light();
                  ref
                      .read(playbackProvider.notifier)
                      .toggleCollectionShuffle(
                        songs,
                        sourcePlaylistId: playlist?.id,
                      );
                },
              ),
            ),
          ),
          round(
            LucideIcons.arrowUpDown,
            () => _showSortBottomSheet(context, ref),
            l10n.sortBy,
          ),
          if (playlist != null)
            round(
              LucideIcons.moreHorizontal,
              () => _showPlaylistOptions(context, ref, playlist),
              l10n.playlist,
            )
          else if (album != null)
            round(
              LucideIcons.edit2,
              () => _showEditAlbumSheet(context, ref, album),
              l10n.editAlbumInfo,
            )
          else if (artist != null)
            round(
              LucideIcons.edit2,
              () => _showEditArtistSheet(context, artist),
              l10n.editArtistPicture,
            ),
          if (canReorder)
            round(
              LucideIcons.info,
              () => _showReorderHint(context),
              l10n.reorderSongsHint,
            ),
        ],
      ),
    );
  }
}
