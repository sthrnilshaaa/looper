import 'dart:io';
import 'package:looper_player/core/theme/app_fonts.dart';
import 'package:looper_player/core/utils/ui_utils.dart';
import 'package:looper_player/core/utils/responsive.dart';
import 'package:looper_player/core/theme/app_icons.dart';
import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:looper_player/features/library/domain/models/models.dart';
import 'package:looper_player/ui/desktop/folders/folders_view.dart';
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
import 'package:looper_player/ui/desktop/welcome/desktop_welcome_screen.dart';
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
import 'package:looper_player/core/services/update/update_service.dart';
import 'package:looper_player/core/services/update/apk_installer.dart';
import 'package:looper_player/core/services/update/apk_update_notifier.dart';
import 'package:looper_player/ui/widgets/sheets/apk_update_sheet.dart';

import '../android/shell/android_main_screen.dart';
import '../android/widgets/empty_library_view.dart';
import 'custom_title_bar.dart';
import 'desktop_shell_rules.dart';
import 'package:looper_player/features/analyze/presentation/screens/looper_analyze_view.dart';
import 'package:looper_player/ui/android/tabs/library/categories/genres_grid_view.dart';
import 'package:looper_player/core/utils/l10n.dart';
import 'package:looper_player/core/theme/app_assets.dart';
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
      _checkForUpdates();

      // Handle file passed via CLI arguments
      final initialFile = ref.read(startupFileProvider);
      if (initialFile != null) {
        ref.read(playbackProvider.notifier).playFromFile(initialFile);
        return;
      }
    });
  }

  /// The github APK downloads and installs the release itself, so it gets
  /// the update sheet; every other build is pointed at its store or the
  /// release page.
  Future<void> _checkForUpdates() async {
    if (!ApkInstaller.supported) return UpdateService.checkForUpdates();
    final prompt = await ref.read(apkUpdateProvider.notifier).checkOnLaunch();
    if (prompt && mounted) showApkUpdateSheet(context);
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
    // The setup screen runs its own scan, so it stays up while scanning.
    final bool showWelcome = !isSetupComplete;
    final bool isNarrow =
        Responsive.windowClass(MediaQuery.of(context).size.width) ==
        WindowClass.compact;

    final isOverlayMode = ref.watch(overlayModeProvider);
    // Background darkness slider (Settings); NaN on rows saved before it.
    final bgDarkness =
        (settings.desktopBackgroundDarkness.isNaN
                ? AppSettings.defaultDesktopBackgroundDarkness
                : settings.desktopBackgroundDarkness)
            .clamp(0.0, 1.0);

    // Lyrics-only full screen hides the rest of the shell; leaving the lyrics
    // page (or Esc) ends it.
    final lyricsOnly =
        ref.watch(lyricsFullscreenProvider) && nav.activeItem == NavItem.lyrics;
    ref.listen(appNavigationProvider.select((n) => n.activeItem), (_, item) {
      if (item != NavItem.lyrics) {
        ref.read(lyricsFullscreenProvider.notifier).set(false);
      }
    });

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
                  settings.enableDynamicTheming) ...[
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
                            // Outgoing and incoming artwork both fill the
                            // window while they cross-fade.
                            layoutBuilder: (current, previous) => Stack(
                              fit: StackFit.expand,
                              children: [...previous, ?current],
                            ),
                            child: ImageFiltered(
                              // The key must sit on the switcher's direct
                              // child, or a new song swaps in with no fade.
                              key: ValueKey(currentSongArtPath),
                              // The 80px art is stretched across a whole
                              // desktop window: a wide blur plus smooth
                              // upscaling keeps it from looking blocky.
                              imageFilter: ImageFilter.blur(
                                sigmaX: 64,
                                sigmaY: 64,
                                tileMode: TileMode.clamp,
                              ),
                              child: Image.file(
                                File(currentSongArtPath),
                                // Without a size the image keeps its own
                                // (tiny) size instead of filling the window.
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                                filterQuality: FilterQuality.medium,
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
                        // Near-black at the top, letting the artwork's
                        // colour glow through towards the bottom.
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withValues(
                                    alpha: math.sqrt(bgDarkness),
                                  ),
                                  Colors.black.withValues(alpha: bgDarkness),
                                  Colors.black.withValues(
                                    alpha: bgDarkness * 0.75,
                                  ),
                                ],
                                stops: const [0.0, 0.45, 1.0],
                              ),
                            ),
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
                SizedBox(
                  height: 36,
                  child: CustomTitleBar(showMenu: isNarrow && !showWelcome),
                ),
                Expanded(
                  child: showWelcome
                      ? const DesktopWelcomeScreen()
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            final bool isNarrowLayout =
                                Responsive.windowClass(constraints.maxWidth) ==
                                WindowClass.compact;

                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Sidebar - hidden on narrow screens
                                if (!isNarrowLayout && !lyricsOnly)
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
                                        if (!lyricsOnly &&
                                            DesktopShellRules.showTopBar(
                                              nav.activeItem,
                                            ))
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
                                                    // Lay the button out at its full width while the slot
                                                    // animates, so it is clipped instead of overflowing.
                                                    child: SizedBox(
                                                      height: 55.s,
                                                      child: OverflowBox(
                                                        alignment: Alignment
                                                            .centerLeft,
                                                        minWidth: 120,
                                                        maxWidth: 120,
                                                        child: AnimatedScale(
                                                          scale:
                                                              nav
                                                                  .history
                                                                  .isEmpty
                                                              ? 0.0
                                                              : 1.0,
                                                          duration:
                                                              const Duration(
                                                                milliseconds:
                                                                    300,
                                                              ),
                                                          curve: Curves
                                                              .easeOutBack,
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
                                                              isDynamic:
                                                                  isDynamic,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                // The search bar takes the
                                                // row but stops growing at
                                                // 640px, so on a wide window
                                                // it doesn't stretch to half
                                                // the screen.
                                                Expanded(
                                                  child: Align(
                                                    alignment:
                                                        Alignment.centerLeft,
                                                    child: ConstrainedBox(
                                                      constraints:
                                                          const BoxConstraints(
                                                            maxWidth: 640,
                                                          ),
                                                      child:
                                                          const GlobalSearchBar(),
                                                    ),
                                                  ),
                                                ),
                                                if (DesktopShellRules.showAddFolder(
                                                  nav.activeItem,
                                                  libraryEmpty:
                                                      library.songs.isEmpty,
                                                )) ...[
                                                  const SizedBox(width: 16),
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
                                                    compact: isNarrowLayout,
                                                  ),
                                                ],
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
                if (!nav.isPlayerExpanded && !lyricsOnly)
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
          artist: nav.activeArtist,
        );
      case NavItem.queue:
        return const QueueView();
      case NavItem.songs:
        return library.songs.isEmpty
            ? _buildEmptyState(context, l10n)
            : SongsList(songs: library.songs);
      case NavItem.genres:
        return const GenresGridView();
      case NavItem.folders:
        return const DesktopFoldersView();
      case NavItem.analyze:
        return const LooperAnalyzeView();
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
