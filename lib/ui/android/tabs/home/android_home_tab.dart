import 'package:looper_player/core/motion/looper_scroll_physics.dart';
import 'package:looper_player/core/providers/collection_navigation.dart';
import 'dart:async';
import 'dart:math' as math;

import 'package:looper_player/core/utils/song_metadata.dart';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:looper_player/ui/widgets/common/song_artwork.dart';
import 'package:looper_player/ui/widgets/common/mochy_card_row.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:isar_community/isar.dart';
import 'package:looper_player/core/theme/app_fonts.dart';
import 'package:looper_player/core/theme/app_icons.dart';
import 'package:looper_player/core/services/storage/db_service.dart';
import 'package:looper_player/core/providers/navigation_provider.dart';
import 'package:looper_player/core/utils/responsive.dart';
import 'package:looper_player/features/library/presentation/providers/library/library_notifier.dart';
import 'package:looper_player/features/library/presentation/widgets/songs/songs_list.dart';
import 'package:looper_player/features/playback/presentation/providers/playback/playback_notifier.dart';
import 'package:looper_player/features/playlists/presentation/screens/playlist_view.dart';
import 'package:looper_player/features/settings/presentation/providers/settings_notifier.dart';
import 'package:looper_player/l10n/app_localizations.dart';
import 'package:looper_player/ui/widgets/common/app_refresh_indicator.dart';
import 'package:looper_player/ui/widgets/common/optimized_image.dart';
import 'package:looper_player/ui/widgets/common/selected_avatar.dart';
import 'package:looper_player/ui/widgets/sheets/song_options_bottom_sheet.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../widgets/empty_library_view.dart';
import '../../widgets/library_skeletons.dart';
import '../../widgets/premium_loading_view.dart';
import '../../widgets/premium_section.dart';
import '../library/categories/library_categories_views.dart';
import '../../widgets/genre_card.dart';
import '../../widgets/recent_song_pills.dart';

import 'package:looper_player/core/services/haptics/app_haptics.dart';
import 'package:looper_player/features/settings/domain/home_order.dart';
import 'hold_bloom.dart';
import 'home_hero.dart';
import 'package:looper_player/ui/widgets/common/home_design_kit.dart';

part 'home_sections.dart';
part 'home_reorder.dart';

class AndroidHomeTab extends ConsumerStatefulWidget {
  const AndroidHomeTab({super.key});

  @override
  ConsumerState<AndroidHomeTab> createState() => _AndroidHomeTabState();
}

class _AndroidHomeTabState extends ConsumerState<AndroidHomeTab>
    with TickerProviderStateMixin {
  // Reorder mode (docs/online/27). Nothing is saved until Done.
  bool _reordering = false;
  List<String> _draftOrder = const [];
  // Set each build: the rows on screen, and whether the 5 s hold may start.
  List<String> _visibleRows = const [];
  bool _holdAllowed = false;

  // The 4 s hold that enters reorder mode: a thin ring fills around the
  // finger from 1 s to 4 s, then ripples spread like a drop on water
  // (see hold_bloom.dart).
  late final _hold = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  );
  late final _bloom = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );
  late final _modeFade = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
    value: 1,
  );
  Timer? _holdTimer;
  Offset? _holdStart;
  // Where the finger went down, local to Home: the drop's center.
  Offset _dropAt = Offset.zero;
  int _pointers = 0;
  // How far Home is pulled past its top; the hero artwork stretches to fill it.
  final _overscroll = ValueNotifier<double>(0);
  // How far Home is scrolled down; the pinned buttons tuck up with it.
  final _scrolled = ValueNotifier<double>(0);

  @override
  void dispose() {
    _overscroll.dispose();
    _scrolled.dispose();
    _holdTimer?.cancel();
    if (homeReorderCancel == _cancelReorder) homeReorderCancel = null;
    _hold.dispose();
    _bloom.dispose();
    _modeFade.dispose();
    super.dispose();
  }

  // Both the tab's own route and the route holding the tab navigator must be
  // on top, so a sheet opened by a card's long-press stops the hold.
  bool get _homeOnTop =>
      (ModalRoute.of(context)?.isCurrent ?? true) &&
      (ModalRoute.of(Navigator.of(context).context)?.isCurrent ?? true);

  // Raw pointer events, outside the gesture arena: a card's tap, a scroll
  // or a card's own long-press can win the arena without telling a losing
  // recognizer, which left the old hold running after plain taps. Here any
  // lift, cancel, move past touch slop, second finger or scroll stops it.
  void _onPointerDown(PointerDownEvent e) {
    _pointers++;
    if (_pointers > 1) return _stopHold();
    if (!_bloom.isAnimating) _dropAt = e.localPosition;
    _startHold(e.position);
  }

  void _onPointerMove(PointerMoveEvent e) {
    final start = _holdStart;
    if (start != null && (e.position - start).distance > kTouchSlop) {
      _stopHold();
    }
  }

  void _onPointerEnd(PointerEvent _) {
    _pointers = math.max(0, _pointers - 1);
    _stopHold();
  }

  void _startHold(Offset at) {
    _stopHold();
    if (!_holdAllowed || _bloom.isAnimating) return;
    _holdStart = at;
    var seconds = 0;
    _holdTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      seconds++;
      if (!mounted || !_holdAllowed || !_homeOnTop) return _stopHold();
      if (seconds == 1) {
        _hold.forward(from: 0);
      } else if (seconds < 4) {
        AppHaptics.tick();
      } else {
        _enterReorder();
      }
    });
  }

  void _stopHold() {
    _holdTimer?.cancel();
    _holdTimer = null;
    _holdStart = null;
    if (_bloom.isAnimating) return;
    // Stop first: a grow that just started still reads 0.
    _hold.stop();
    if (_hold.value > 0) {
      _hold.animateBack(
        0,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _enterReorder() {
    _holdTimer?.cancel();
    _holdTimer = null;
    _holdStart = null;
    AppHaptics.success();
    void swapIn() {
      if (!mounted || _reordering) return;
      setState(() {
        _reordering = true;
        _draftOrder = [..._visibleRows];
      });
      _modeFade.forward(from: 0);
      homeReorderCancel = _cancelReorder;
    }

    if (MediaQuery.disableAnimationsOf(context)) {
      _hold.value = 0;
      return swapIn();
    }
    // Reorder mode fades in under the ripples, just after the splash.
    void onBloom() {
      if (_bloom.value < 0.12) return;
      _bloom.removeListener(onBloom);
      swapIn();
    }

    _bloom.addListener(onBloom);
    _bloom.forward(from: 0).whenComplete(() {
      _bloom.removeListener(onBloom);
      if (!mounted) return;
      swapIn();
      _hold.value = 0;
      _bloom.value = 0;
    });
  }

  void _cancelReorder() => _leaveReorder(save: false);

  /// [to] is the index before removal, as [SliverReorderableList] gives it.
  void _moveDraft(List<String> rows, int from, int to) {
    if (to > from) to--;
    setState(() => _draftOrder = rows..insert(to, rows.removeAt(from)));
  }

  void _leaveReorder({required bool save}) {
    if (!_reordering) return;
    if (save) {
      final saved = ref.read(settingsProvider).homeSectionOrder;
      ref
          .read(settingsProvider.notifier)
          .updateHomeSectionOrder(mergeHomeOrder(saved, _draftOrder));
      AppHaptics.success();
    }
    homeReorderCancel = null;
    setState(() => _reordering = false);
    _modeFade.forward(from: 0);
  }

  void _showSongOptions(BuildContext context, Song song) {
    showSongOptionsBottomSheet(
      context: context,
      ref: ref,
      song: song,
      showEqualizerAndTechnicalInfoOptions: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final showAlbumInQuickPicks = watchShowAlbumInQuickPicks(ref);
    // This tab is now permanently mounted alongside Songs/Library (see
    // AndroidMainScreen) instead of being torn down on every tab switch, so
    // an unscoped watch of the entire LibraryState/AppSettings objects meant
    // it silently rebuilt this whole (large, image-heavy) tab in the
    // background on every unrelated settings tweak or library write - e.g.
    // every darkness slider drag, or the ~20s listen-time checkpoint during
    // any playback - even while a different tab was on screen. Select just
    // the fields this tab actually renders.
    final (
      songs,
      rawArtists,
      rawAlbums,
      isInitialized,
      isScanning,
      previewReady,
      previewQuickPicks,
      previewRecentlyAdded,
    ) = ref.watch(
      libraryProvider.select(
        (s) => (
          s.songs,
          s.artists,
          s.albums,
          s.isInitialized,
          s.isScanning,
          s.previewReady,
          s.previewQuickPicks,
          s.previewRecentlyAdded,
        ),
      ),
    );
    // App start, saved library still loading: Quick Picks and Recently
    // Added come from small queries of their own, and every other section
    // shows a skeleton until its data is in.
    final bool loadingInParts = !isInitialized && previewReady;
    final l10n = AppLocalizations.of(context)!;
    final (
      albumSortOptionIndex,
      artistSortOptionIndex,
      genreSortOptionIndex,
      disableBlur,
      enableDynamicTheming,
      homeSectionOrder,
      showHomeArtists,
      showHomeAlbums,
      showHomeGenres,
      showHomeRecent,
      showHomePlaylists,
    ) = ref.watch(
      settingsProvider.select(
        (s) => (
          s.albumSortOptionIndex,
          s.artistSortOptionIndex,
          s.genreSortOptionIndex,
          s.disableBlur,
          s.enableDynamicTheming,
          s.homeSectionOrder,
          s.showHomeArtists,
          s.showHomeAlbums,
          s.showHomeGenres,
          s.showHomeRecent,
          s.showHomePlaylists ?? true,
        ),
      ),
    );
    final recentSongs = ref.watch(dashboardRecentlyPlayedProvider).value ?? [];
    final playlists = ref.watch(dashboardPlaylistsProvider).value ?? [];

    final albumSort =
        AlbumSortOption.values[albumSortOptionIndex.clamp(
          0,
          AlbumSortOption.values.length - 1,
        )];
    final artistSort =
        ArtistSortOption.values[artistSortOptionIndex.clamp(
          0,
          ArtistSortOption.values.length - 1,
        )];
    final genreSort =
        GenreSortOption.values[genreSortOptionIndex.clamp(
          0,
          GenreSortOption.values.length - 1,
        )];

    final genresMap = <String, List<Song>>{};
    for (var song in songs) {
      final genre = song.genre ?? l10n.unknown;
      genresMap.putIfAbsent(genre, () => []).add(song);
    }

    final genres = genresMap.keys.toList();
    sortGenresList(genres, genresMap, genreSort);

    final artists = List<Artist>.from(rawArtists);
    sortArtistsList(artists, songs, artistSort);

    final albums = List<Album>.from(rawAlbums);
    sortAlbumsList(albums, songs, albumSort);

    // Reopening the app: the saved library is still loading from the
    // database - show the layout it's about to fill.
    if (!isInitialized && !previewReady) {
      return const LoadStateSwitcher(state: 'loading', child: HomeSkeleton());
    }

    // First scan of an empty library can take minutes; keep the animated
    // view with its rotating progress messages for that.
    if (isScanning && songs.isEmpty) {
      return const LoadStateSwitcher(
        state: 'scanning',
        child: PremiumLoadingView(),
      );
    }

    if (songs.isEmpty && !loadingInParts) {
      return LoadStateSwitcher(
        state: 'empty',
        child: SafeArea(child: EmptyLibraryView(title: l10n.noSongsFound)),
      );
    }

    // Quick Picks (most played, up to 18 for 3 pages of 6) and Recently
    // Added (newest first) are computed in memoized providers instead of
    // inline here - same sort, same output, just not redone on every
    // rebuild of this screen. See their doc comments in library_notifier.dart.
    final allQuickPicks = ref.watch(homeQuickPicksProvider);
    final dateAddedSongs = ref.watch(homeRecentlyAddedProvider);

    // Same rule as sheets: Dynamic Theming's blur toggle, else
    // "Always Blur Sheets & Headers".
    final useBlur = ref.watch(settingsProvider.select((s) => s.statusBarBlur));

    // Switching tabs cancels reorder mode.
    ref.listen(appNavigationProvider.select((s) => s.activeItem), (_, item) {
      if (item != NavItem.home) _cancelReorder();
    });

    final header = HomeHero(
      key: const ValueKey('header'),
      mix: allQuickPicks,
      library: songs,
      artists: rawArtists,
      stretch: _overscroll,
      onPlayMix: () {
        AppHaptics.medium();
        ref
            .read(playbackProvider.notifier)
            .setPlaylist(List<Song>.from(allQuickPicks)..shuffle());
      },
      onPlayCover: (queue, index) {
        AppHaptics.light();
        ref
            .read(playbackProvider.notifier)
            .setPlaylist(queue, initialIndex: index);
      },
      onSurprise: (pick) {
        AppHaptics.medium();
        final queue = List<Song>.from(songs)..shuffle();
        if (pick != null) {
          queue
            ..removeWhere((s) => s.path == pick.path)
            ..insert(0, pick);
        }
        ref.read(playbackProvider.notifier).setPlaylist(queue);
      },
    );

    // Every row follows homeSectionOrder. Rows with nothing to show keep
    // their slot but are left out, also in reorder mode.
    final visibleRows = <String>[];
    final rowSlivers = <Widget>[];
    for (final section in homeSectionOrder) {
      final slivers = <Widget>[];
      if (section == 'quick_picks') {
        if (allQuickPicks.isNotEmpty) {
          slivers.add(
            SliverToBoxAdapter(
              child: HomeSectionHeader(
                label: l10n.homePicksLabel,
                title: l10n.homeForYou,
                // Right under the hero when it is the first row.
                padding: EdgeInsets.fromLTRB(
                  23,
                  visibleRows.isEmpty ? 0 : 36,
                  16,
                  19,
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    HomeRoundButton(
                      semanticLabel: l10n.playAll,
                      onTap: () {
                        AppHaptics.medium();
                        ref
                            .read(playbackProvider.notifier)
                            .setPlaylist(allQuickPicks);
                      },
                      child: homeSectionPlayIcon,
                    ),
                    const SizedBox(width: 6),
                    HomeViewAllPill(
                      label: l10n.viewAll,
                      onTap: () {
                        AppHaptics.light();
                        ref
                            .read(appNavigationProvider.notifier)
                            .setItem(NavItem.songs);
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
          slivers.add(
            SliverToBoxAdapter(
              child: _buildPicksPager(
                allQuickPicks,
                l10n,
                showAlbum: showAlbumInQuickPicks,
              ),
            ),
          );
        }
      } else if (section == 'songs' && dateAddedSongs.isNotEmpty) {
        slivers.add(
          SliverToBoxAdapter(
            child: _homeSectionHeader(
              title: l10n.songs,
              onViewAll: () {
                AppHaptics.light();
                ref.read(appNavigationProvider.notifier).setItem(NavItem.songs);
              },
            ),
          ),
        );

        slivers.add(
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final song = dateAddedSongs[index];
                return SongTile(
                  showAlbum: true,
                  key: ValueKey(song.path),
                  song: song,
                  l10n: l10n,
                  songs: dateAddedSongs,
                  // Only the first rows are loaded yet; a tap queues the
                  // whole Recently Added list once it is in.
                  resolveQueue: loadingInParts
                      ? () async {
                          await ref
                              .read(libraryProvider.notifier)
                              .loadedSongs();
                          return ref.read(homeRecentlyAddedProvider);
                        }
                      : null,
                );
              },
              childCount: dateAddedSongs.length > 10
                  ? 10
                  : dateAddedSongs.length,
            ),
          ),
        );
        slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 16)));
      } else if (section == 'playlists') {
        if (showHomePlaylists && (playlists.isNotEmpty || loadingInParts)) {
          final displayCount = math.min(15, playlists.length);
          final hasMore = playlists.length > 15;
          slivers.add(
            _buildHorizontalSection(
              title: l10n.library,
              label: l10n.homeYourOwn,
              actionText: l10n.viewAll,
              onActionTap: () {
                AppHaptics.medium();
                ref
                    .read(appNavigationProvider.notifier)
                    .setItem(NavItem.playlists);
              },
              itemCount: (loadingInParts && playlists.isEmpty)
                  ? 0
                  : displayCount + (hasMore ? 1 : 0),
              loading: loadingInParts && playlists.isEmpty,
              itemBuilder: (context, index) {
                if (index >= displayCount) {
                  return _buildViewAllEndCard(
                    onTap: () => ref
                        .read(appNavigationProvider.notifier)
                        .setItem(NavItem.playlists),
                    l10n: l10n,
                    width: 128,
                  );
                }
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.5),
                  child: SizedBox(
                    width: 128,
                    child: PlaylistCard(
                      playlist: playlists[index],
                      titleStyle: homeCardTitle(),
                      subtitleStyle: homeCardSub(size: 15),
                    ),
                  ),
                );
              },
            ),
          );
        }
      } else if (section == 'artists') {
        if (showHomeArtists && (artists.isNotEmpty || loadingInParts)) {
          final displayCount = math.min(15, artists.length);
          final hasMore = artists.length > 15;
          slivers.add(
            _buildHorizontalSection(
              title: l10n.artists,
              actionText: l10n.viewAll,
              onActionTap: () {
                AppHaptics.medium();
                ref
                    .read(appNavigationProvider.notifier)
                    .setItem(NavItem.artists);
              },
              itemCount: (loadingInParts && artists.isEmpty)
                  ? 0
                  : displayCount + (hasMore ? 1 : 0),
              loading: loadingInParts && artists.isEmpty,
              circleSkeleton: true,
              arrows: true,
              itemBuilder: (context, index) {
                if (index >= displayCount) {
                  return _buildViewAllEndCard(
                    onTap: () => ref
                        .read(appNavigationProvider.notifier)
                        .setItem(NavItem.artists),
                    l10n: l10n,
                    width: 90,
                    circle: true,
                  );
                }
                return _buildArtistItem(artists[index], l10n);
              },
              listHeight: 108,
            ),
          );
        }
      } else if (section == 'albums') {
        if (showHomeAlbums && (albums.isNotEmpty || loadingInParts)) {
          final displayCount = math.min(15, albums.length);
          final hasMore = albums.length > 15;
          slivers.add(
            _buildHorizontalSection(
              title: l10n.albums,
              actionText: l10n.viewAll,
              onActionTap: () {
                AppHaptics.medium();
                ref
                    .read(appNavigationProvider.notifier)
                    .setItem(NavItem.albums);
              },
              itemCount: (loadingInParts && albums.isEmpty)
                  ? 0
                  : displayCount + (hasMore ? 1 : 0),
              loading: loadingInParts && albums.isEmpty,
              itemBuilder: (context, index) {
                if (index >= displayCount) {
                  return _buildViewAllEndCard(
                    onTap: () => ref
                        .read(appNavigationProvider.notifier)
                        .setItem(NavItem.albums),
                    l10n: l10n,
                    width: 128,
                  );
                }
                return _buildAlbumItem(albums[index], l10n);
              },
              listHeight: 190,
            ),
          );
        }
      } else if (section == 'genres') {
        // Genres are counted over every song, so they wait for all of them.
        if (showHomeGenres && (genres.isNotEmpty || loadingInParts)) {
          final displayCount = math.min(15, genres.length);
          final hasMore = genres.length > 15;
          slivers.add(
            _buildHorizontalSection(
              title: l10n.genres,
              actionText: l10n.viewAll,
              onActionTap: () {
                AppHaptics.medium();
                ref
                    .read(appNavigationProvider.notifier)
                    .setItem(NavItem.genres);
              },
              itemCount: (loadingInParts && genres.isEmpty)
                  ? 0
                  : displayCount + (hasMore ? 1 : 0),
              listHeight: _HomeTabSections.genreRowHeight,
              loading: loadingInParts && genres.isEmpty,
              itemBuilder: (context, index) {
                if (index >= displayCount) {
                  return _buildViewAllEndCard(
                    onTap: () => ref
                        .read(appNavigationProvider.notifier)
                        .setItem(NavItem.genres),
                    l10n: l10n,
                    width: _HomeTabSections._genreCardWidth,
                  );
                }
                final genre = genres[index];
                return _buildGenreItem(genre, genresMap[genre]!);
              },
            ),
          );
        }
      } else if (section == 'recent') {
        if (showHomeRecent && recentSongs.isNotEmpty) {
          slivers.add(
            SliverToBoxAdapter(
              child: _homeSectionHeader(
                title: l10n.recentPlayed,
                onViewAll: () {
                  AppHaptics.light();
                  ref
                      .read(appNavigationProvider.notifier)
                      .setItem(NavItem.history);
                },
              ),
            ),
          );

          slivers.add(
            SliverToBoxAdapter(
              child: RecentSongPills(songs: recentSongs, horizontalPadding: 16),
            ),
          );
          slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 16)));
        }
      }
      if (slivers.isNotEmpty) {
        visibleRows.add(section);
        rowSlivers.addAll(slivers);
      }
    }
    _visibleRows = visibleRows;
    _holdAllowed = !_reordering && !loadingInParts && visibleRows.length >= 2;

    final accent = ref.watch(settingsProvider.select((s) => s.accent));
    final orderedSlivers = <Widget>[
      SliverToBoxAdapter(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: _reordering
              ? Padding(
                  padding: EdgeInsets.only(
                    top: MediaQuery.paddingOf(context).top,
                  ),
                  child: _buildReorderBar(l10n, useBlur, accent),
                )
              : header,
        ),
      ),
      SliverFadeTransition(
        opacity: CurvedAnimation(parent: _modeFade, curve: Curves.easeOutCubic),
        sliver: _reordering
            ? _buildReorderList(
                l10n: l10n,
                accent: accent,
                visible: visibleRows,
                allQuickPicks: allQuickPicks,
                dateAddedSongs: dateAddedSongs,
                recentSongs: recentSongs,
                albums: albums,
                artists: artists,
                genres: genres,
                genresMap: genresMap,
              )
            : rowSlivers.isEmpty
            ? const SliverToBoxAdapter(child: SizedBox.shrink())
            : SliverMainAxisGroup(slivers: rowSlivers),
      ),
    ];

    orderedSlivers.add(const SliverToBoxAdapter(child: SizedBox(height: 200)));

    return LoadStateSwitcher(
      state: 'content',
      child: SafeArea(
        top: false,
        child: _wrapHold(
          accent: accent,
          child: AppRefreshIndicator(
            enabled: !_reordering,
            onRefresh: () async {
              ref
                  .read(libraryProvider.notifier)
                  .refreshLibrary(showVisualIndicator: true)
                  .ignore();
            },
            child: Stack(
              children: [
                NotificationListener<ScrollUpdateNotification>(
                  onNotification: (n) {
                    if (n.depth == 0) {
                      final m = n.metrics;
                      _overscroll.value = math.max(
                        0.0,
                        m.minScrollExtent - m.pixels,
                      );
                      _scrolled.value = math.max(
                        0.0,
                        m.pixels - m.minScrollExtent,
                      );
                    }
                    return false;
                  },
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: LooperScrollPhysics(),
                    ),
                    slivers: orderedSlivers,
                  ),
                ),
                // Pinned over the page; the reorder bar takes its place.
                if (!_reordering)
                  HomeTopBar(
                    blur: useBlur,
                    scrolled: _scrolled,
                    onSearch: () {
                      AppHaptics.light();
                      ref
                          .read(appNavigationProvider.notifier)
                          .setItem(NavItem.search);
                    },
                    onProfile: () {
                      AppHaptics.light();
                      ref
                          .read(appNavigationProvider.notifier)
                          .setItem(NavItem.account);
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
