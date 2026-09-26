import 'dart:io';
import 'package:looper_player/core/theme/app_fonts.dart';
import 'package:looper_player/core/utils/ui_utils.dart';
import 'package:looper_player/core/theme/app_icons.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:looper_player/ui/widgets/common/app_loading_indicator.dart';
import 'package:looper_player/ui/widgets/common/color_maper.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../widgets/player/player_bar/player_bar.dart';
import '../widgets/player/expanded_player.dart';
import 'package:looper_player/features/library/presentation/providers/library/library_notifier.dart';
import 'package:looper_player/features/library/presentation/widgets/songs/songs_list.dart';
import 'package:looper_player/features/library/presentation/widgets/library_grids.dart';
import 'package:looper_player/ui/desktop/dashboard/home_dashboard.dart';
import 'package:looper_player/features/playlists/presentation/screens/playlist_view.dart';
import 'package:looper_player/features/search/presentation/screens/search_view.dart';
import 'package:looper_player/core/providers/navigation_provider.dart';
import 'package:looper_player/features/library/presentation/screens/smart_views.dart';
import 'package:looper_player/ui/desktop/settings/settings_view.dart';
import 'package:looper_player/ui/welcome/welcome_screen.dart';
import 'package:looper_player/ui/widgets/common/folder_picker_helper.dart';

import 'package:looper_player/ui/widgets/collection_detail/collection_detail_view.dart';
import 'package:looper_player/features/playback/presentation/screens/lyrics_view.dart';
import 'package:looper_player/features/playback/presentation/providers/playback/playback_notifier.dart';
import 'package:looper_player/features/playback/presentation/providers/lyrics/lyrics_notifier.dart';
import 'package:looper_player/features/library/presentation/screens/queue_view.dart';
import 'package:looper_player/features/settings/presentation/providers/settings_notifier.dart';
import 'package:looper_player/core/providers/providers.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:looper_player/l10n/app_localizations.dart';
import '../widgets/common/global_search_bar.dart';
import 'package:looper_player/features/playback/presentation/widgets/lyrics/overlay_lyrics_widget.dart';
import 'package:looper_player/core/services/update_service.dart';

import '../android/shell/android_main_screen.dart';
import '../android/widgets/empty_library_view.dart';
import 'custom_title_bar.dart';
import 'package:looper_player/core/utils/l10n.dart';
part 'sidebar.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Trigger library scan for saved folders on startup
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Wait for settings to load from DB
      await ref.read(settingsProvider.notifier).initialization;
      final settings = ref.read(settingsProvider);

      // Check for application updates on GitHub
      UpdateService.checkForUpdates();

      // Handle file passed via CLI arguments
      final initialFile = ref.read(startupFileProvider);
      if (initialFile != null) {
        ref.read(playbackProvider.notifier).playFromFile(initialFile);
        return;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (Platform.isAndroid) {
      return const AndroidMainScreen();
    }

    final library = ref.watch(libraryProvider);
    final nav = ref.watch(appNavigationProvider);
    final currentSongArtPath = ref.watch(
      playbackProvider.select((s) => s.currentSong?.artPath),
    );
    final settings = ref.watch(settingsProvider);
    final isDynamic = settings.enableDynamicTheming;
    final l10n = AppLocalizations.of(context)!;

    // Ensure lyrics pre-fetching is active
    ref.watch(lyricsProvider);

    final isSetupComplete = ref.watch(welcomeBypassedProvider);
    final bool showWelcome = !isSetupComplete && !library.isScanning;
    final bool isNarrow = MediaQuery.of(context).size.width < 800;

    final isOverlayMode = ref.watch(overlayModeProvider);

    if (isOverlayMode) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: OverlayLyricsWidget(),
      );
    }

    final bool hasBgLayer =
        settings.enableDynamicTheming || settings.keepBackgroundGradient;
    final Color scaffoldBg =
        (Theme.of(context).scaffoldBackgroundColor == Colors.transparent)
        ? const Color(0xFF121214)
        : Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: hasBgLayer ? Colors.transparent : scaffoldBg,
      drawer: isNarrow
          ? Drawer(
              child: Container(
                color: Theme.of(context).colorScheme.surface,
                child: Sidebar(l10n: l10n),
              ),
            )
          : null,
      body: SafeArea(
        child: Stack(
          children: [
            // Global Background Art / persistent gradient
            if (!showWelcome &&
                (settings.enableDynamicTheming ||
                    settings.keepBackgroundGradient)) ...[
              if (currentSongArtPath != null &&
                  settings.enableDynamicTheming &&
                  (settings.keepBackgroundGradient ||
                      nav.activeItem != NavItem.settings)) ...[
                Positioned.fill(
                  child: RepaintBoundary(
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: AnimatedSwitcher(
                            // Matches the Android equivalent's crossfade
                            // duration (android_main_screen.dart) for the
                            // same blurred-background-art effect.
                            duration: const Duration(milliseconds: 800),
                            child: ImageFiltered(
                              imageFilter: ImageFilter.blur(
                                sigmaX: 16,
                                sigmaY: 16,
                              ),
                              child: Image.file(
                                File(currentSongArtPath),
                                key: ValueKey(currentSongArtPath),
                                fit: BoxFit.cover,
                                filterQuality: FilterQuality.low,
                                // Downsample before blurring, same as every
                                // other blurred-background usage in the app
                                // (BlurredBackgroundArt, android_lyrics_screen,
                                // song_info_screen, looper_analyze_view) -
                                // without this the full-resolution art was
                                // decoded on every song change just to be
                                // blurred away.
                                cacheWidth: 80,
                                cacheHeight: 80,
                                gaplessPlayback: true,
                                errorBuilder: (_, _, _) =>
                                    const SizedBox.shrink(),
                              ),
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: Container(
                            color: Colors.black.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                Positioned.fill(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeInOut,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.topRight,
                        radius: 1.5,
                        colors: [
                          Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.18),
                          Theme.of(context).scaffoldBackgroundColor,
                        ],
                        stops: const [0.0, 1.0],
                      ),
                    ),
                  ),
                ),
              ],
            ],

            Column(
              children: [
                // Custom Title Bar always at the top
                SizedBox(height: 36, child: CustomTitleBar(showMenu: isNarrow)),
                Expanded(
                  child: showWelcome
                      ? const WelcomeScreen()
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            final bool isNarrowLayout =
                                constraints.maxWidth < 800;

                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Sidebar - hidden on narrow screens
                                if (!isNarrowLayout)
                                  Container(
                                    width: 240.s,
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .surfaceContainerHighest
                                          .withValues(alpha: 0.01),
                                      border: Border(
                                        right: BorderSide(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .outlineVariant
                                              .withValues(alpha: 0.2),
                                          width: 1.5,
                                        ),
                                      ),
                                    ),
                                    child: Sidebar(l10n: l10n),
                                  ),

                                // Main Content Area
                                Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.only(left: 20),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (nav.activeItem != NavItem.lyrics)
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 24,
                                            ),
                                            child: Row(
                                              children: [
                                                AnimatedContainer(
                                                  duration: const Duration(
                                                    milliseconds: 300,
                                                  ),
                                                  curve: Curves.easeInOutCubic,
                                                  width: nav.history.isEmpty
                                                      ? 0
                                                      : 120,
                                                  child: ClipRect(
                                                    child: AnimatedScale(
                                                      scale: nav.history.isEmpty
                                                          ? 0.0
                                                          : 1.0,
                                                      duration: const Duration(
                                                        milliseconds: 300,
                                                      ),
                                                      curve: Curves.easeOutBack,
                                                      child: Padding(
                                                        padding:
                                                            const EdgeInsets.only(
                                                              right: 16,
                                                            ),
                                                        child: _HeaderButton(
                                                          onTap: () => ref
                                                              .read(
                                                                appNavigationProvider
                                                                    .notifier,
                                                              )
                                                              .goBack(),
                                                          icon: LucideIcons
                                                              .arrowLeft,
                                                          label: l10n.back,
                                                          isDynamic: isDynamic,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const Expanded(
                                                  child: GlobalSearchBar(),
                                                ),
                                                // const SizedBox(width: 48),
                                                Spacer(),
                                                _HeaderButton(
                                                  onTap: () {
                                                    FolderPickerHelper.pickFolder(
                                                      context,
                                                      ref,
                                                    );
                                                  },
                                                  icon: LucideIcons.plus,
                                                  label: l10n.addFolder,
                                                  isDynamic: isDynamic,
                                                ),
                                              ],
                                            ),
                                          ),
                                        Expanded(
                                          child: _buildMainContent(
                                            nav,
                                            library,
                                            context,
                                            l10n,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                ),
                // Global Player Bar always at the bottom
                if (!nav.isPlayerExpanded)
                  GestureDetector(
                    onVerticalDragUpdate: (details) {
                      if (Platform.isAndroid || Platform.isIOS) {
                        if (details.delta.dy < -10) {
                          ref
                              .read(appNavigationProvider.notifier)
                              .setPlayerExpansion(true);
                        }
                      }
                    },
                    child: const PlayerBar(),
                  ),
              ],
            ),
            // Expanded Player View
            if (nav.isPlayerExpanded)
              Positioned.fill(
                child: WillPopScope(
                  onWillPop: () async {
                    ref
                        .read(appNavigationProvider.notifier)
                        .setPlayerExpansion(false);
                    return false;
                  },
                  child: const ExpandedPlayer(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent(
    NavigationState nav,
    LibraryState library,
    BuildContext context,
    AppLocalizations l10n,
  ) {
    if (!library.isInitialized ||
        (library.isScanning && library.songs.isEmpty)) {
      return const AppLoadingIndicator();
    }

    final childWidget = _getWidgetForNavItem(nav, library, context, l10n);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      switchInCurve: Curves.easeInOut,
      switchOutCurve: Curves.easeInOut,
      transitionBuilder: (child, animation) =>
          FadeTransition(opacity: animation, child: child),
      child: KeyedSubtree(key: ValueKey(nav.activeItem), child: childWidget),
    );
  }

  Widget _getWidgetForNavItem(
    NavigationState nav,
    LibraryState library,
    BuildContext context,
    AppLocalizations l10n,
  ) {
    switch (nav.activeItem) {
      case NavItem.search:
        return const SearchView();
      case NavItem.albums:
        return const AlbumsGrid();
      case NavItem.artists:
        return const ArtistsGrid();
      case NavItem.playlists:
        return const PlaylistView();
      case NavItem.favorites:
        return const FavoritesView();
      case NavItem.recentlyPlayed:
      case NavItem.history:
        return const RecentlyPlayedView();
      case NavItem.lyrics:
        return const LyricsView();
      case NavItem.settings:
        return const SettingsView();
      case NavItem.collectionDetail:
        return CollectionDetailView(
          title: nav.collectionTitle ?? context.l10n.unknown,
          subtitle: nav.collectionSubtitle,
          artPath: nav.collectionArt,
          imageUrl: nav.collectionImageUrl,
          songs: nav.collectionSongs,
          playlist: nav.activePlaylist,
          album: nav.activeAlbum,
        );
      case NavItem.queue:
        return const QueueView();
      case NavItem.songs:
        return library.songs.isEmpty
            ? _buildEmptyState(context, l10n)
            : SongsList(songs: library.songs);
      case NavItem.home:
      default:
        return library.songs.isEmpty
            ? _buildEmptyState(context, l10n)
            : const HomeDashboard();
    }
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n) {
    return EmptyLibraryView(title: l10n.noSongsFound);
  }
}
