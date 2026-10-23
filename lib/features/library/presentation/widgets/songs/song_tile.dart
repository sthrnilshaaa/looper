import 'package:looper_player/core/providers/collection_navigation.dart';
import 'package:looper_player/ui/widgets/common/song_artist_picker.dart';
import 'package:looper_player/core/theme/app_fonts.dart';
import 'package:looper_player/core/utils/song_metadata.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:looper_player/ui/widgets/common/highlighted_text.dart';
import 'package:looper_player/ui/widgets/common/optimized_image.dart';
import 'package:looper_player/ui/widgets/common/song_favorite_button.dart';
import 'package:looper_player/ui/widgets/common/playlist_reorderable_listener.dart';
import 'package:looper_player/ui/widgets/common/song_playback_overlay.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:looper_player/features/playback/presentation/providers/playback/playback_notifier.dart';
import 'package:looper_player/core/providers/navigation_provider.dart';
import 'package:looper_player/core/services/storage/db_service.dart';
import 'package:isar_community/isar.dart';
import 'package:looper_player/l10n/app_localizations.dart';
import 'package:looper_player/ui/widgets/sheets/song_options_bottom_sheet.dart';
import 'package:looper_player/core/services/haptics/app_haptics.dart';
import 'package:looper_player/features/search/domain/lyric_snippet.dart'
    as search
    show lyricSnippet;

class SongTile extends ConsumerWidget {
  final Song song;
  final List<Song> songs;
  final AppLocalizations l10n;
  final String? searchQuery;
  final Playlist? playlist;
  final bool showAlbum;
  final bool selectionMode;
  final bool selected;
  final VoidCallback? onToggleSelect;
  final VoidCallback? onEnterSelection;
  // A displayed position is independent of whether sorting permits reordering.
  final int? collectionIndex;
  final int? reorderIndex;
  // Search-only extras: highlight the [searchQuery] match in the title, and
  // get told when a tap starts playback (not when it toggles a selection).
  final bool highlightTitle;
  final VoidCallback? onPlay;

  const SongTile({
    required this.song,
    required this.songs,
    required this.l10n,
    this.searchQuery,
    this.playlist,
    this.showAlbum = false,
    this.selectionMode = false,
    this.selected = false,
    this.onToggleSelect,
    this.onEnterSelection,
    this.collectionIndex,
    this.reorderIndex,
    this.highlightTitle = false,
    this.onPlay,
    super.key,
  });

  Future<void> _openArtist(BuildContext context, WidgetRef ref) async {
    if (song.artist == null || song.artist!.trim().isEmpty) return;
    // A song by several artists asks which one to open.
    final artistName = await pickSongArtist(context, song);
    if (artistName == null || !context.mounted) return;
    await ref
        .read(appNavigationProvider.notifier)
        .showArtistNamed(
          artistName,
          subtitle: l10n.artists,
          fallbackArt: song.artPath,
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCurrent = ref.watch(
      playbackProvider.select((s) => s.currentSong?.path == song.path),
    );
    final isPlaying =
        isCurrent && ref.watch(playbackProvider.select((s) => s.isPlaying));
    final isCollection = collectionIndex != null || playlist != null;
    final songSubtitle = artistAlbumLabel(
      song,
      l10n,
      showAlbum: (showAlbum || isCollection) && watchShowAlbum(ref),
    );

    // The ListTile subtitle fills its column. Loosen those constraints so the
    // link only covers the smaller text, leaving row taps around it for Play.
    final subtitle = Align(
      alignment: Alignment.centerLeft,
      heightFactor: 1,
      child: InkWell(
        onTap: !selectionMode && song.artist?.trim().isNotEmpty == true
            ? () => _openArtist(context, ref)
            : null,
        child: Text(
          songSubtitle,
          style: AppFonts.jostStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 12,
            height: 1.15,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );

    String? lyricSnippet;
    if (searchQuery != null && searchQuery!.isNotEmpty && song.lyrics != null) {
      lyricSnippet = search.lyricSnippet(song.lyrics!, searchQuery!);
    }

    final tile = Material(
      type: selected ? MaterialType.canvas : MaterialType.transparency,
      color: selected
          ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.08)
          : null,
      child: _SongTileBouncyTap(
        onTap: () {
          if (selectionMode) {
            onToggleSelect?.call();
            return;
          }
          onPlay?.call();
          final index =
              collectionIndex ?? songs.indexWhere((s) => s.path == song.path);
          if (index != -1) {
            ref
                .read(playbackProvider.notifier)
                .setPlaylist(
                  songs,
                  initialIndex: index,
                  sourcePlaylistId: playlist?.id,
                );
          } else {
            ref
                .read(playbackProvider.notifier)
                .play(song, sourcePlaylistId: playlist?.id);
          }
        },
        // A long-press on any row starts a selection (with that row already
        // checked) instead of requiring a separate "select" mode button -
        // there's nowhere else in this list a batch action could live.
        onLongPress: selectionMode ? null : onEnterSelection,
        child: ListTile(
          contentPadding: EdgeInsets.only(
            left: collectionIndex != null ? 8 : 16,
            right: 4,
            top: 0,
            bottom: 0,
          ),
          leading: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (collectionIndex != null) ...[
                SizedBox(
                  width: 20,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.center,
                    child: Text(
                      '${collectionIndex! + 1}',
                      maxLines: 1,
                      style: AppFonts.jostStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Stack(
                  children: [
                    OptimizedImage(
                      imagePath: song.artPath,
                      width: 52,
                      height: 52,
                      fit: BoxFit.cover,
                    ),
                    if (isCurrent)
                      Positioned.fill(
                        child: SongPlaybackOverlay(isPlaying: isPlaying),
                      ),
                    if (selectionMode)
                      Positioned.fill(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          curve: Curves.easeOutCubic,
                          color: selected
                              ? Colors.black.withValues(alpha: 0.35)
                              : Colors.transparent,
                          child: selected
                              ? Icon(
                                  LucideIcons.checkCircle2,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 24,
                                )
                              : null,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          title: highlightTitle && !isCurrent
              ? highlightedText(
                  text: song.title,
                  query: searchQuery ?? '',
                  baseStyle: AppFonts.jostStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  highlightStyle: AppFonts.jostStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                )
              : Text(
                  song.title,
                  style: AppFonts.jostStyle(
                    color: isCurrent
                        ? Theme.of(context).colorScheme.primary
                        : Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
          subtitle: lyricSnippet != null
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    subtitle,
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.12),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            LucideIcons.quote,
                            size: 9,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: highlightedText(
                              text: lyricSnippet,
                              query: searchQuery ?? '',
                              baseStyle: AppFonts.jostStyle(
                                color: Colors.white.withValues(alpha: 0.75),
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                              ),
                              highlightStyle: AppFonts.jostStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              : subtitle,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isCollection) SongFavoriteButton(song: song),
              IconButton(
                padding: isCollection ? EdgeInsets.zero : null,
                constraints: isCollection
                    ? const BoxConstraints.tightFor(width: 32, height: 36)
                    : null,
                style: isCollection
                    ? IconButton.styleFrom(
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      )
                    : null,
                icon: Icon(
                  Icons.more_vert,
                  size: isCollection ? 20 : 24,
                  color: Colors.grey,
                ),
                onPressed: () => showSongOptionsBottomSheet(
                  context: context,
                  ref: ref,
                  song: song,
                  playlist: playlist,
                  showEqualizerAndTechnicalInfoOptions: false,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return reorderIndex == null
        ? tile
        : PlaylistReorderableListener(
            index: reorderIndex!,
            enabled: !selectionMode,
            child: tile,
          );
  }
}

class _SongTileBouncyTap extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _SongTileBouncyTap({
    required this.child,
    required this.onTap,
    this.onLongPress,
  });

  @override
  State<_SongTileBouncyTap> createState() => _SongTileBouncyTapState();
}

class _SongTileBouncyTapState extends State<_SongTileBouncyTap>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.97,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      onLongPress: widget.onLongPress == null
          ? null
          : () {
              AppHaptics.medium();
              widget.onLongPress!();
            },
      behavior: HitTestBehavior.opaque,
      // ScaleTransition builds a Transform, which always needs its own
      // compositing layer whenever it has a child -- even sitting still at
      // scale 1.0. With a long list of these tiles that's a permanent extra
      // layer per visible row for the ~99% of the time nothing's being
      // pressed, on top of the churn of allocating one per tile as
      // ListView.builder recycles rows during a fling. Only pay for that
      // layer while the press animation is actually running; otherwise
      // render the row directly with no Transform at all.
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          if (_controller.value == 0.0) return child!;
          return Transform.scale(scale: _scaleAnimation.value, child: child);
        },
        child: widget.child,
      ),
    );
  }
}
