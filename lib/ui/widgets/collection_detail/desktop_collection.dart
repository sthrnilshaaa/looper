part of 'collection_detail_view.dart';

/// Desktop (Linux) layout of the collection page: a wide header, a stats row
/// and full-width song rows over the shell's blurred artwork background. The
/// shell's top bar already carries Back and search.
extension _DesktopCollection on CollectionDetailView {
  static const _pillColor = Color(0x0FFFFFFF);

  Widget _buildDesktop(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required String? subtitle,
    required String? art,
    required String? imageUrl,
    required List<Song> songs,
    required bool songsLoading,
    required Playlist? reactivePlaylist,
    required Album? reactiveAlbum,
    required Artist? reactiveArtist,
    required bool canReorder,
    required String? activePath,
  }) {
    final l10n = AppLocalizations.of(context)!;
    // Lit only while this collection is the one playing shuffled.
    final key = collectionKey(songs);
    final isShuffle = ref.watch(
      playbackProvider.select((s) => s.isShuffle && s.queueSourceKey == key),
    );

    Widget row(int index, {int? reorderIndex}) {
      final song = songs[index];
      return _DesktopSongRow(
        key: ValueKey((song.path, index)),
        song: song,
        songs: songs,
        index: index,
        playlist: reactivePlaylist,
        isCurrent: song.path == activePath,
        reorderIndex: reorderIndex,
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CollectionScrollToEnd(
        bottomPadding: activePath != null ? 100 : 16,
        builder: (controller) => CustomScrollView(
          controller: controller,
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (reactivePlaylist != null)
                          PlaylistArtwork(
                            songPaths: reactivePlaylist.songPaths,
                            size: 140,
                            borderRadius: BorderRadius.circular(6),
                          )
                        else
                          OptimizedImage(
                            imagePath: art,
                            imageUrl: imageUrl,
                            width: 140,
                            height: 140,
                            borderRadius: BorderRadius.circular(6),
                            placeholder: Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(
                                LucideIcons.music,
                                size: 48,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        const SizedBox(width: 22),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                title,
                                style: AppFonts.jostStyle(
                                  fontSize: 34,
                                  height: 1.15,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              _buildCollectionSubtitle(
                                reactivePlaylist != null
                                    ? l10n.playlist
                                    : subtitle,
                                songs,
                                l10n,
                                fontSize: 22,
                                songsLoading: songsLoading,
                                color: Colors.white.withValues(alpha: 0.45),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  _DesktopPill(
                                    onTap: () {
                                      final playback = ref.read(
                                        playbackProvider.notifier,
                                      );
                                      playback.playCollection(
                                        songs,
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
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  _DesktopPill.icon(
                                    icon: LucideIcons.shuffle,
                                    iconColor: isShuffle
                                        ? Colors.white
                                        : Colors.white.withValues(alpha: 0.5),
                                    backgroundColor: isShuffle
                                        ? Colors.white.withValues(alpha: 0.10)
                                        : null,
                                    tooltip: l10n.shuffleTitle,
                                    onTap: () {
                                      ref
                                          .read(playbackProvider.notifier)
                                          .toggleCollectionShuffle(
                                            songs,
                                            sourcePlaylistId:
                                                reactivePlaylist?.id,
                                          );
                                    },
                                  ),
                                  if (reactivePlaylist != null) ...[
                                    const SizedBox(width: 10),
                                    _DesktopPill.icon(
                                      icon: LucideIcons.plus,
                                      tooltip: l10n.addSongsToPlaylistTitle,
                                      onTap: () => _showAddSongsHint(context),
                                    ),
                                    const SizedBox(width: 10),
                                    _DesktopPill.icon(
                                      icon: LucideIcons.moreHorizontal,
                                      onTap: () => _showPlaylistOptions(
                                        context,
                                        ref,
                                        reactivePlaylist,
                                      ),
                                    ),
                                  ] else if (reactiveAlbum != null) ...[
                                    const SizedBox(width: 10),
                                    _DesktopPill.icon(
                                      icon: LucideIcons.edit2,
                                      onTap: () => _showEditAlbumSheet(
                                        context,
                                        ref,
                                        reactiveAlbum,
                                      ),
                                    ),
                                  ] else if (reactiveArtist != null) ...[
                                    const SizedBox(width: 10),
                                    _DesktopPill.icon(
                                      icon: LucideIcons.edit2,
                                      tooltip: l10n.editArtistPicture,
                                      onTap: () => _showEditArtistSheet(
                                        context,
                                        reactiveArtist,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 38),
                    Row(
                      children: [
                        const Spacer(),
                        _DesktopPill.icon(
                          icon: LucideIcons.arrowUpDown,
                          onTap: () => _showSortBottomSheet(context, ref),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              // Dragging to reorder only applies to a playlist in its own saved
              // order (see the mobile layout).
              sliver: canReorder
                  ? SliverReorderableList(
                      itemExtent: 56,
                      itemCount: songs.length,
                      onReorderStart: (_) => AppHaptics.medium(),
                      itemBuilder: (context, index) =>
                          row(index, reorderIndex: index),
                      onReorder: (oldIndex, newIndex) {
                        PlaylistService.reorderSong(
                          reactivePlaylist!,
                          oldIndex,
                          newIndex,
                        );
                      },
                    )
                  : SliverFixedExtentList(
                      itemExtent: 56,
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => row(index),
                        childCount: songs.length,
                      ),
                    ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 48)),
          ],
        ),
      ),
    );
  }
}

/// Dark rounded pill used for the header buttons and the stats chips.
class _DesktopPill extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final String? tooltip;
  final bool circle;
  final Color? backgroundColor;

  const _DesktopPill({required this.child, this.onTap})
    : tooltip = null,
      circle = false,
      backgroundColor = null;

  _DesktopPill.icon({
    required IconData icon,
    Color iconColor = Colors.white,
    this.backgroundColor,
    this.onTap,
    this.tooltip,
  }) : child = Icon(icon, size: 15, color: iconColor),
       circle = true;

  @override
  Widget build(BuildContext context) {
    final pill = Material(
      color: backgroundColor ?? _DesktopCollection._pillColor,
      shape: const StadiumBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 36,
          width: circle ? 36 : null,
          alignment: circle ? Alignment.center : null,
          padding: circle ? null : const EdgeInsets.symmetric(horizontal: 18),
          child: circle ? child : Center(widthFactor: 1, child: child),
        ),
      ),
    );
    return tooltip == null ? pill : Tooltip(message: tooltip!, child: pill);
  }
}

/// One song in the desktop collection list: artwork, title, artist, favourite
/// and duration. Click plays, right-click (or the hover button) opens the
/// song options.
class _DesktopSongRow extends ConsumerStatefulWidget {
  final Song song;
  final List<Song> songs;
  final int index;
  final Playlist? playlist;
  final bool isCurrent;
  final int? reorderIndex;

  const _DesktopSongRow({
    super.key,
    required this.song,
    required this.songs,
    required this.index,
    required this.isCurrent,
    this.playlist,
    this.reorderIndex,
  });

  @override
  ConsumerState<_DesktopSongRow> createState() => _DesktopSongRowState();
}

class _DesktopSongRowState extends ConsumerState<_DesktopSongRow> {
  bool _hovered = false;
  void _play() {
    final playback = ref.read(playbackProvider.notifier);
    playback.setPlaylist(
      widget.songs,
      initialIndex: widget.index,
      sourcePlaylistId: widget.playlist?.id,
    );
  }

  void _showOptions() => showSongOptionsBottomSheet(
    context: context,
    ref: ref,
    song: widget.song,
    playlist: widget.playlist,
    showEqualizerAndTechnicalInfoOptions: false,
  );

  String _duration() {
    final d = Duration(milliseconds: widget.song.duration ?? 0);
    final minutes = d.inMinutes.toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final showAlbum = watchShowAlbum(ref);
    final l10n = AppLocalizations.of(context)!;
    final song = widget.song;
    final isPlaying = ref.watch(playbackProvider.select((s) => s.isPlaying));
    final lit = _hovered || widget.isCurrent;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _play,
        onSecondaryTap: _showOptions,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          height: 56,
          padding: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            color: lit
                ? Colors.white.withValues(alpha: 0.04)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 20,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.center,
                  child: Text(
                    '${widget.index + 1}',
                    maxLines: 1,
                    style: AppFonts.jostStyle(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Stack(
                  children: [
                    OptimizedImage(
                      imagePath: song.artPath,
                      width: 42,
                      height: 42,
                      borderRadius: BorderRadius.circular(4),
                      placeholder: Container(
                        color: Colors.white.withValues(alpha: 0.05),
                        child: const Icon(
                          LucideIcons.music,
                          size: 16,
                          color: Colors.white24,
                        ),
                      ),
                    ),
                    if (widget.isCurrent)
                      Positioned.fill(
                        child: SongPlaybackOverlay(isPlaying: isPlaying),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      song.title,
                      style: AppFonts.jostStyle(
                        color: Colors.white,
                        fontSize: 16,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      artistAlbumLabel(song, l10n, showAlbum: showAlbum),
                      style: AppFonts.jostStyle(
                        color: Colors.white.withValues(alpha: 0.45),
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // A mouse can't discover a long-press, so Linux keeps a grip.
              if (widget.reorderIndex != null)
                ReorderableDragStartListener(
                  index: widget.reorderIndex!,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(
                      LucideIcons.gripVertical,
                      size: 18,
                      color: Colors.white38,
                    ),
                  ),
                ),
              Opacity(
                opacity: _hovered ? 1 : 0,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(
                    width: 32,
                    height: 36,
                  ),
                  style: IconButton.styleFrom(
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: const Icon(
                    Icons.more_vert,
                    size: 18,
                    color: Colors.white54,
                  ),
                  onPressed: _showOptions,
                ),
              ),
              SongFavoriteButton(song: song),
              const SizedBox(width: 12),
              SizedBox(
                width: 48,
                child: Text(
                  _duration(),
                  style: AppFonts.jostStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
