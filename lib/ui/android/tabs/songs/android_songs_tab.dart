import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:looper_player/core/theme/app_icons.dart';
import 'package:looper_player/features/library/domain/models/models.dart';
import 'package:looper_player/l10n/app_localizations.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:looper_player/core/providers/navigation_provider.dart';
import 'package:looper_player/features/library/presentation/providers/library/library_notifier.dart';
import 'package:looper_player/features/settings/presentation/providers/settings_notifier.dart';
import 'package:looper_player/features/library/presentation/widgets/songs/songs_list.dart';
import 'package:looper_player/features/playback/presentation/providers/playback/playback_notifier.dart';
import 'package:looper_player/core/theme/app_fonts.dart';
import '../../widgets/premium_section.dart';
import '../../widgets/empty_library_view.dart';
import '../../widgets/premium_loading_view.dart';

class AndroidSongsTab extends ConsumerStatefulWidget {
  const AndroidSongsTab({super.key});

  @override
  ConsumerState<AndroidSongsTab> createState() => _AndroidSongsTabState();
}

class _AndroidSongsTabState extends ConsumerState<AndroidSongsTab> {
  late final ScrollController _scrollController;
  bool _isButtonVisible = true;
  double _lastOffset = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
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
    final (isInitialized, isScanning, songs) = ref.watch(
      libraryProvider.select((s) => (s.isInitialized, s.isScanning, s.songs)),
    );
    final settings = ref.watch(settingsProvider);
    // Only the presence of a current song matters here (to make room for the
    // mini player), so select a bool instead of the Song object - otherwise
    // this whole (potentially large) list rebuilds on every track change.
    final hasCurrentSong = ref.watch(
      playbackProvider.select((s) => s.currentSong != null),
    );
    final l10n = AppLocalizations.of(context)!;

    if (!isInitialized || (isScanning && songs.isEmpty)) {
      return const PremiumLoadingView();
    }

    return songs.isEmpty
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
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            PremiumSection(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(32),
                                bottomLeft: Radius.circular(32),
                                topRight: Radius.circular(10),
                                bottomRight: Radius.circular(10),
                              ),
                              width: 48,
                              height: 48,
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.04,
                              ),
                              useBlur: true,
                              useExpanded: false,
                              onTap: () {
                                HapticFeedback.lightImpact();
                                ref
                                    .read(appNavigationProvider.notifier)
                                    .setItem(NavItem.search);
                              },
                              child: const Icon(
                                LucideIcons.search,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            Text(
                              l10n.allSongs,
                              style: AppFonts.jostStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            PremiumSection(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(10),
                                bottomLeft: Radius.circular(10),
                                topRight: Radius.circular(32),
                                bottomRight: Radius.circular(32),
                              ),
                              width: 48,
                              height: 48,
                              useExpanded: false,
                              useBlur: true,
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.04,
                              ),
                              forceNoBlur: true,
                              onTap: () {
                                HapticFeedback.lightImpact();
                                ref
                                    .read(appNavigationProvider.notifier)
                                    .setItem(NavItem.settings);
                              },
                              child: const Icon(
                                LucideIcons.settings,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Thin divider below the header
                      Container(
                        height: 0.5,
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: SongsList(
                          songs: songs,
                          controller: _scrollController,
                          showEnrichmentIndicator: true,
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
                    offset: _isButtonVisible ? Offset.zero : const Offset(0, 2),
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
                          backgroundColor: Colors.white.withValues(alpha: 0.04),
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            if (songs.isNotEmpty) {
                              final randomSongList = List<Song>.from(songs)
                                ..shuffle();
                              ref
                                  .read(playbackProvider.notifier)
                                  .setPlaylist(randomSongList, initialIndex: 0);
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
          );
  }
}
