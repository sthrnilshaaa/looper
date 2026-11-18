import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:looper_player/core/theme/app_icons.dart';
import 'package:looper_player/features/library/domain/models/models.dart';
import 'package:looper_player/l10n/app_localizations.dart';
import 'package:looper_player/features/library/presentation/providers/library/library_notifier.dart';
import 'package:looper_player/features/settings/presentation/providers/settings_notifier.dart';
import 'package:looper_player/features/library/presentation/widgets/songs/songs_list.dart';
import 'package:looper_player/features/playback/presentation/providers/playback/playback_notifier.dart';
import 'package:looper_player/ui/widgets/common/momentum_scroll_controller.dart';

import '../../widgets/premium_section.dart';
import '../../widgets/large_tab_header.dart';
import '../../widgets/empty_library_view.dart';
import '../../widgets/premium_loading_view.dart';
import '../../widgets/library_skeletons.dart';

import 'package:looper_player/core/services/haptics/app_haptics.dart';

class AndroidSongsTab extends ConsumerStatefulWidget {
  const AndroidSongsTab({super.key});

  @override
  ConsumerState<AndroidSongsTab> createState() => _AndroidSongsTabState();
}

class _AndroidSongsTabState extends ConsumerState<AndroidSongsTab> {
  late final ScrollController _scrollController;
  bool _isButtonVisible = true;

  // The skeleton was on screen in this tab: the list then cross-fades in
  // over it and skips its row wave.
  bool _shownSkeleton = false;
  double _lastOffset = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = MomentumScrollController();
    _scrollController.addListener(_scrollListener);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // All three tabs mount together at app launch now (see
      // AndroidMainScreen), so this fires immediately on every cold start
      // regardless of which tab is active - previously it only fired once
      // the user actually navigated to Songs. A brief delay here lets the
      // very first Home-screen frames settle before a scan's background
      // metadata-extraction work starts competing with the main isolate for
      // CPU (see LibraryScanner's batched _extractMetadata calls).
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        // refreshIfStale (rather than scanSavedFolders directly) skips the
        // rescan if one already ran recently - this tab now stays mounted
        // across Home<->Songs switches (see AndroidMainScreen), so without
        // this gate every switch back to Songs would still trigger a full
        // rescan for no reason.
        ref.read(libraryProvider.notifier).refreshIfStale();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    final currentOffset = _scrollController.offset;
    if (currentOffset <= 0) {
      if (!_isButtonVisible) {
        setState(() {
          _isButtonVisible = true;
        });
      }
    } else if (currentOffset > _lastOffset && currentOffset > 50) {
      if (_isButtonVisible) {
        setState(() {
          _isButtonVisible = false;
        });
      }
    } else if (currentOffset < _lastOffset) {
      if (!_isButtonVisible) {
        setState(() {
          _isButtonVisible = true;
        });
      }
    }
    _lastOffset = currentOffset;
  }

  @override
  Widget build(BuildContext context) {
    // LibraryState also carries artists/albums/playlists/sort settings that
    // this tab never renders - watching the whole object rebuilt this tab on
    // any of those (e.g. a playlist renamed elsewhere) even when the songs
    // list itself hadn't changed. Select just the fields actually used.
    final (isInitialized, isScanning, fullSongs, loadingSongs, totalCount) = ref
        .watch(
          libraryProvider.select(
            (s) => (
              s.isInitialized,
              s.isScanning,
              s.songs,
              s.loadingSongs,
              s.totalSongCount,
            ),
          ),
        );
    // While the saved library loads at app start, show the part that is in
    // so far; rows below it stay skeletons until their part arrives.
    final bool loadingInParts = !isInitialized && loadingSongs.isNotEmpty;
    final songs = loadingInParts ? loadingSongs : fullSongs;
    final settings = ref.watch(settingsProvider);
    // Only the presence of a current song matters here (to make room for the
    // mini player), so select a bool instead of the Song object - otherwise
    // this whole (potentially large) list rebuilds on every track change.
    final hasCurrentSong = ref.watch(
      playbackProvider.select((s) => s.currentSong != null),
    );
    final l10n = AppLocalizations.of(context)!;

    // Reopening the app: the saved library is still loading from the
    // database. The first scan of an empty library keeps the animated view
    // with its progress messages.
    if (!isInitialized && !loadingInParts) {
      _shownSkeleton = true;
      return const LoadStateSwitcher(state: 'loading', child: SongsSkeleton());
    }
    if (isScanning && songs.isEmpty) {
      return const LoadStateSwitcher(
        state: 'scanning',
        child: PremiumLoadingView(),
      );
    }

    return LoadStateSwitcher(
      state: songs.isEmpty ? 'empty' : 'content',
      child: songs.isEmpty
          ? EmptyLibraryView(title: l10n.noSongsFound)
          : Container(
              color:
                  (settings.enableDynamicTheming ||
                      settings.keepBackgroundGradient)
                  ? Colors.transparent
                  : Theme.of(context).colorScheme.surface,
              child: Stack(
                children: [
                  SafeArea(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LargeTabHeader(
                          eyebrow: l10n.allSongsEyebrow,
                          title: l10n.songs,
                        ),
                        Expanded(
                          child: SongsList(
                            songs: songs,
                            controller: _scrollController,
                            showEnrichmentIndicator: true,
                            loading: loadingInParts,
                            totalCount: totalCount,
                            wave: !_shownSkeleton,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: AnimatedSlide(
                      duration: const Duration(milliseconds: 300),
                      offset: _isButtonVisible
                          ? Offset.zero
                          : const Offset(0, 2),
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 300),
                        opacity: _isButtonVisible ? 1.0 : 0.0,
                        child: AnimatedPadding(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOut,
                          padding: EdgeInsets.only(
                            bottom: hasCurrentSong ? 200 : 120,
                            right: 40,
                          ),
                          child: PremiumSection(
                            width: 48,
                            height: 48,
                            borderRadius: BorderRadius.circular(48),
                            useBlur: true,
                            useExpanded: false,
                            // forceNoBlur: true,
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.04,
                            ),
                            onTap: () {
                              AppHaptics.medium();
                              if (songs.isNotEmpty) {
                                // Shuffles the whole library, waiting for
                                // it if it is still loading.
                                final playback = ref.read(
                                  playbackProvider.notifier,
                                );
                                ref
                                    .read(libraryProvider.notifier)
                                    .loadedSongs()
                                    .then((all) {
                                      if (all.isEmpty) return;
                                      playback.setPlaylist(
                                        List<Song>.from(all)..shuffle(),
                                        initialIndex: 0,
                                      );
                                    });
                              }
                            },
                            child: SvgPicture.asset(
                              AppIcons.shuffleHome,
                              width: 40,
                            ),
                            // Icon(LucideIcons.shuffle, color: Colors.white, size: 18),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
