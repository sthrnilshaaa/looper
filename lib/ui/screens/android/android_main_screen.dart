import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:looper_player/features/library/presentation/library_notifier.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:looper_player/core/app_fonts.dart';
import 'package:looper_player/core/navigation_provider.dart';
import 'package:looper_player/core/responsive.dart';
import 'package:looper_player/features/library/domain/models/models.dart';
import 'package:looper_player/features/settings/presentation/settings_notifier.dart';
import 'package:looper_player/features/settings/presentation/settings_view.dart';
import 'package:looper_player/l10n/app_localizations.dart';
import 'package:looper_player/ui/screens/android/widgets/premium_music_bar.dart';
import 'package:looper_player/ui/screens/welcome_screen.dart';
import 'package:looper_player/ui/widgets/collection_detail_view.dart';
import 'package:looper_player/features/playlists/presentation/playlist_view.dart';
import 'package:looper_player/ui/screens/android/tabs/views/library_categories_views.dart';

import 'tabs/android_home_tab.dart';
import 'tabs/android_search_tab.dart';
import 'tabs/android_library_tab.dart';
import 'tabs/android_songs_tab.dart';
import 'package:looper_player/features/playback/presentation/playback_notifier.dart';
import 'package:looper_player/core/player_expand_provider.dart';
import 'widgets/premium_navbar.dart';
import 'widgets/premium_section.dart';
import 'package:looper_player/features/library/presentation/smart_views.dart';
import 'package:looper_player/features/library/presentation/queue_view.dart';
import 'package:looper_player/features/analyze/presentation/looper_analyze_view.dart';

part 'android_main_screen.g.dart';

@Riverpod(keepAlive: true)
GlobalKey<NavigatorState> androidNavigatorKey(Ref ref) =>
    GlobalKey<NavigatorState>();

/// The bottom-nav "root" tab (Home/Songs/Library) currently active, derived
/// by walking back through navigation history when a pushed sub-view (a
/// collection, settings, search, ...) is on top. Used via `.select()` so
/// screens only rebuild when this actually changes value, not on every
/// NavigationState field (isPlayerExpanded, collectionSongs, ...).
NavItem _rootNavItem(NavigationState nav) {
  final active = nav.activeItem;
  if (active == NavItem.home ||
      active == NavItem.songs ||
      active == NavItem.library) {
    return active;
  }
  for (final histState in nav.history.reversed) {
    final histActive = histState.activeItem;
    if (histActive == NavItem.home ||
        histActive == NavItem.songs ||
        histActive == NavItem.library) {
      return histActive;
    }
  }
  return NavItem.home;
}

int _navItemTabIndex(NavItem item) {
  return item == NavItem.home ? 0 : (item == NavItem.songs ? 1 : 2);
}

class AndroidMainScreen extends ConsumerStatefulWidget {
  const AndroidMainScreen({super.key});

  @override
  ConsumerState<AndroidMainScreen> createState() => _AndroidMainScreenState();
}

class _AndroidMainScreenState extends ConsumerState<AndroidMainScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  DateTime? _lastBackPressTime;
  bool _permissionsGranted = true;

  bool _navAtRoot = true;
  late final _NavDepthObserver _navDepthObserver;

  void _setNavAtRoot(bool atRoot) {
    if (_navAtRoot == atRoot) return;
    setState(() => _navAtRoot = atRoot);
  }

  final List<Widget> _tabs = [
    const AndroidHomeTab(),
    const AndroidSongsTab(),
    const AndroidLibraryTab(),
  ];

  // The three root tabs stay mounted permanently (see _buildTabStack) so
  // switching tabs no longer tears down and recreates their state - it used
  // to, via a PageTransitionSwitcher keyed by tab index, which meant e.g.
  // AndroidSongsTab was destroyed and rebuilt from scratch (new
  // ScrollController, fresh initState-triggered library rescan, brand new
  // ListView) on every single Home<->Songs switch. That rebuild landing
  // right as the user's first scroll gesture arrived was what caused the
  // stutter. _tabFadeController drives a manual crossfade reproducing
  // Material's "fade through" timing/curves (see _tabFadeOutOpacity /
  // _tabFadeInOpacity / _tabScaleIn below - lifted straight from the
  // `animations` package's FadeThroughTransition) so the transition looks
  // and feels the same as the old PageTransitionSwitcher did, without the
  // underlying destroy/rebuild.
  late final AnimationController _tabFadeController;
  int _currentTabIndex = 0;
  int? _previousTabIndex;

  // Outgoing tab: fades 1->0 over the first 30% of the transition with an
  // ease-in curve, then stays hidden.
  static final CurveTween _tabFadeOutCurve = CurveTween(
    curve: const Cubic(0.4, 0.0, 1.0, 1.0),
  );
  static final TweenSequence<double> _tabFadeOutOpacity =
      TweenSequence<double>([
        TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 0.0).chain(_tabFadeOutCurve),
          weight: 6 / 20,
        ),
        TweenSequenceItem(tween: ConstantTween(0.0), weight: 14 / 20),
      ]);

  // Incoming tab: stays hidden/scaled-down for the first 30%, then fades
  // 0->1 and scales 0.92->1.0 over the remaining 70% with a decelerate
  // curve. Scale only applies to the incoming tab, per the Material spec.
  static final CurveTween _tabFadeInCurve = CurveTween(
    curve: const Cubic(0.0, 0.0, 0.2, 1.0),
  );
  static final TweenSequence<double> _tabFadeInOpacity = TweenSequence<double>([
    TweenSequenceItem(tween: ConstantTween(0.0), weight: 6 / 20),
    TweenSequenceItem(
      tween: Tween(begin: 0.0, end: 1.0).chain(_tabFadeInCurve),
      weight: 14 / 20,
    ),
  ]);
  static final TweenSequence<double> _tabScaleIn = TweenSequence<double>([
    TweenSequenceItem(tween: ConstantTween(0.92), weight: 6 / 20),
    TweenSequenceItem(
      tween: Tween(begin: 0.92, end: 1.0).chain(_tabFadeInCurve),
      weight: 14 / 20,
    ),
  ]);

  @override
  void initState() {
    super.initState();
    _navDepthObserver = _NavDepthObserver(onAtRootChanged: _setNavAtRoot);
    WidgetsBinding.instance.addObserver(this);
    _requestNotificationPermissionIfNeeded();
    _checkAndroidPermissions();
    _tabFadeController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 500),
          value: 1.0,
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed) {
            _previousTabIndex = null;
          }
        });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(settingsProvider.notifier).initialization;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabFadeController.dispose();
    super.dispose();
  }

  Widget _buildTabStack() {
    return AnimatedBuilder(
      animation: _tabFadeController,
      builder: (context, _) {
        final double t = _tabFadeController.value;
        return Stack(
          children: List.generate(_tabs.length, (i) {
            final bool isCurrent = i == _currentTabIndex;
            final bool isPrevious = i == _previousTabIndex;
            final bool participates = isCurrent || isPrevious;
            final double opacity = isCurrent
                ? _tabFadeInOpacity.transform(t)
                : (isPrevious ? _tabFadeOutOpacity.transform(t) : 0.0);
            final double scale = isCurrent ? _tabScaleIn.transform(t) : 1.0;

            // Every tab keeps the exact same wrapper shape across frames
            // (only these bool/double params change) so Flutter updates
            // each Element in place instead of tearing the subtree (and its
            // state) down when a tab moves in or out of the fade.
            return Offstage(
              key: ValueKey('root_tab_$i'),
              offstage: !participates,
              child: TickerMode(
                enabled: isCurrent,
                child: Opacity(
                  opacity: opacity,
                  child: Transform.scale(
                    scale: scale,
                    child: IgnorePointer(
                      ignoring: !isCurrent,
                      child: TransitionStatusProvider(
                        isTransitioning:
                            _tabFadeController.isAnimating && participates,
                        child: _tabs[i],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkAndroidPermissions();
      ref.read(libraryProvider.notifier).refreshIfStale();
    }
  }

  Future<void> _checkAndroidPermissions() async {
    if (Platform.isAndroid) {
      int sdkInt = 0;
      try {
        final sdkMatch = RegExp(
          r'API\s+(\d+)',
        ).firstMatch(Platform.operatingSystemVersion);
        if (sdkMatch != null) {
          sdkInt = int.parse(sdkMatch.group(1)!);
        }
      } catch (_) {}

      final hasAudio = await Permission.audio.isGranted;
      final hasStorage = sdkInt < 33 && await Permission.storage.isGranted;
      final isGranted = hasAudio || hasStorage;
      if (mounted && _permissionsGranted != isGranted) {
        setState(() {
          _permissionsGranted = isGranted;
        });
      }
    }
  }

  Future<void> _requestNotificationPermissionIfNeeded() async {
    if (Platform.isAndroid) {
      final status = await Permission.notification.status;
      if (!status.isGranted) {
        await Permission.notification.request();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final song = ref.watch(playbackProvider.select((s) => s.currentSong));
    final navigatorKey = ref.read(androidNavigatorKeyProvider);
    final rootItem = ref.watch(appNavigationProvider.select(_rootNavItem));

    // Drives the tab crossfade (see _buildTabStack) whenever the active root
    // tab actually changes - kept separate from the sub-view Navigator
    // listener below since this is only about Home/Songs/Library, not the
    // full navigation stack.
    ref.listen(appNavigationProvider.select(_rootNavItem), (previous, next) {
      final int newIndex = _navItemTabIndex(next);
      if (newIndex == _currentTabIndex) return;
      _previousTabIndex = _currentTabIndex;
      _currentTabIndex = newIndex;
      _tabFadeController.forward(from: 0);
    });

    // Handle Sub-view Navigation via Navigator (to enable Hero)
    ref.listen(appNavigationProvider, (previous, next) {
      final isForward = next.history.length >= (previous?.history.length ?? 0);

      if (next.activeItem == NavItem.home) {
        navigatorKey.currentState?.popUntil((route) => route.isFirst);
      } else if (next.activeItem == NavItem.songs) {
        navigatorKey.currentState?.popUntil((route) => route.isFirst);
      } else if (next.activeItem == NavItem.library) {
        navigatorKey.currentState?.popUntil((route) => route.isFirst);
      } else if (isForward && next.activeItem == NavItem.playlists) {
        navigatorKey.currentState?.push(
          _createPremiumRoute(
            CategoryDetailWrapper(title: 'Playlists', child: PlaylistView()),
          ),
        );
      } else if (isForward && next.activeItem == NavItem.collectionDetail) {
        navigatorKey.currentState?.push(
          _createPremiumRoute(
            CollectionDetailView(
              title: next.collectionTitle ?? 'Unknown',
              subtitle: next.collectionSubtitle,
              artPath: next.collectionArt,
              imageUrl: next.collectionImageUrl,
              songs: next.collectionSongs,
              playlist: next.activePlaylist,
              album: next.activeAlbum,
            ),
          ),
        );
      } else if (isForward && next.activeItem == NavItem.search) {
        navigatorKey.currentState?.push(
          _createPremiumRoute(const AndroidSearchTab()),
        );
      } else if (isForward && next.activeItem == NavItem.settings) {
        navigatorKey.currentState?.push(
          _createPremiumRoute(const SettingsView()),
        );
      } else if (isForward && next.activeItem == NavItem.settingsCategory) {
        navigatorKey.currentState?.push(
          _createPremiumRoute(
            SettingsCategoryScreen(
              categoryId: next.settingsCategoryId ?? '',
              title: next.settingsCategoryTitle ?? '',
            ),
          ),
        );
      } else if (isForward && next.activeItem == NavItem.favorites) {
        navigatorKey.currentState?.push(
          _createPremiumRoute(
            const CategoryDetailWrapper(
              title: 'Favorites',
              child: FavoritesView(),
            ),
          ),
        );
      } else if (isForward && next.activeItem == NavItem.albums) {
        navigatorKey.currentState?.push(
          _createPremiumRoute(
            const CategoryDetailWrapper(
              title: 'Albums',
              child: AlbumsGridView(),
            ),
          ),
        );
      } else if (isForward && next.activeItem == NavItem.artists) {
        navigatorKey.currentState?.push(
          _createPremiumRoute(
            const CategoryDetailWrapper(
              title: 'Artists',
              child: ArtistsGridView(),
            ),
          ),
        );
      } else if (isForward && next.activeItem == NavItem.genres) {
        navigatorKey.currentState?.push(
          _createPremiumRoute(
            const CategoryDetailWrapper(
              title: 'Genres',
              child: GenresGridView(),
            ),
          ),
        );
      } else if (isForward && next.activeItem == NavItem.folders) {
        navigatorKey.currentState?.push(
          _createPremiumRoute(
            const CategoryDetailWrapper(
              title: 'Folders',
              child: FoldersListView(),
            ),
          ),
        );
      } else if (isForward && next.activeItem == NavItem.queue) {
        navigatorKey.currentState?.push(
          _createPremiumRoute(
            const CategoryDetailWrapper(title: 'Queue', child: QueueView()),
          ),
        );
      } else if (isForward &&
          (next.activeItem == NavItem.history ||
              next.activeItem == NavItem.recentlyPlayed)) {
        navigatorKey.currentState?.push(
          _createPremiumRoute(
            const CategoryDetailWrapper(
              title: 'Recently Played',
              child: RecentlyPlayedView(),
            ),
          ),
        );
      } else if (isForward && next.activeItem == NavItem.analyze) {
        navigatorKey.currentState?.push(
          _createPremiumRoute(const LooperAnalyzeView()),
        );
      } else if (!isForward) {
        if (navigatorKey.currentState?.canPop() ?? false) {
          navigatorKey.currentState?.pop();
        }
      }
    });

    final settings = ref.watch(settingsProvider);
    final isWelcomeBypassed = ref.watch(welcomeBypassedProvider);
    final showSupportUsSheet = ref.watch(supportUsSheetVisibleProvider);
    // Mirrors PremiumNavbar's own compact sizing on a short (landscape
    // phone) window, so the mini player's resting offset and the navbar's
    // off-screen slide distance both still match its real height exactly.
    final bool isShortWindow = Responsive.isShort(MediaQuery.sizeOf(context));
    final double navbarHeight =
        (isShortWindow ? 56.0 + 10.0 : 72.0 + 18.0) +
            MediaQuery.of(context).padding.bottom;

    final activeDarkness = () {
      final val = rootItem == NavItem.home
          ? settings.homeDarkness
          : rootItem == NavItem.songs
          ? settings.songsDarkness
          : rootItem == NavItem.library
          ? settings.libraryDarkness
          : 0.72;
      return val.isNaN ? 0.72 : val;
    }();

    final isSetupComplete = isWelcomeBypassed;

    if (!isSetupComplete) {
      return const WelcomeScreen();
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        // 1. If sliding player is open/expanded (vertical motion), collapse it
        final double slideProgress = ref.read(playerExpandProgressProvider);
        if (settings.enableSlideGesture && slideProgress > 0.01) {
          _lastBackPressTime = null;
          ref.read(playerCollapseTriggerProvider.notifier).bump();
          return;
        }

        // 2. If non-sliding player is expanded, collapse it
        if (!settings.enableSlideGesture &&
            ref.read(appNavigationProvider).isPlayerExpanded) {
          _lastBackPressTime = null;
          ref.read(appNavigationProvider.notifier).setPlayerExpansion(false);
          return;
        }
        final bool canPopNavigator =
            navigatorKey.currentState?.canPop() ?? false;
        if (canPopNavigator) {
          ref.read(appNavigationProvider.notifier).goBack();
          return;
        }

        // 4. If we have tab history, navigate back through the tabs
        if (ref.read(appNavigationProvider).history.isNotEmpty) {
          ref.read(appNavigationProvider.notifier).goBack();
          return;
        }

        // 5. Double press to exit
        final now = DateTime.now();
        if (_lastBackPressTime == null ||
            now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
          _lastBackPressTime = now;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                l10n.pressBackExit,
                style: AppFonts.jostStyle(color: Colors.white),
              ),
              backgroundColor: Colors.black87,
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              margin: EdgeInsets.only(
                bottom: song != null ? 180 : 100, // Above the navbar
                left: 20,
                right: 20,
              ),
            ),
          );
        } else {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: Stack(
          children: [
            // Dynamic Background / Gradient Layer
            if (settings.enableDynamicTheming ||
                settings.keepBackgroundGradient) ...[
              if (song?.artPath != null && settings.enableDynamicTheming) ...[
                Positioned.fill(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 800),
                    transitionBuilder: (child, animation) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                    child: BlurredBackgroundArt(
                      key: ValueKey(song!.artPath),
                      song: song,
                    ),
                  ),
                ),

                // Dark overlay
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withValues(alpha: activeDarkness),
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
                          Theme.of(context).colorScheme.surface,
                        ],
                        stops: const [0.0, 1.0],
                      ),
                    ),
                  ),
                ),

                // Dark overlay - same per-screen darkness sliders as the
                // dynamic-art background above, so they aren't dead controls
                // when gradient mode is what's actually active.
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withValues(alpha: activeDarkness),
                  ),
                ),
              ],
            ],

            Positioned.fill(
              child: Navigator(
                key: navigatorKey,
                observers: [_navDepthObserver],
                onGenerateRoute: (settings) {
                  return PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        _buildTabStack(),
                  );
                },
              ),
            ),
            // Backdrop behind the navbar - always present and faded with it
            // (same duration) rather than popping in/out out of sync with it.
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: IgnorePointer(
                child: AnimatedOpacity(
                  opacity: _navAtRoot ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  child: Container(
                    height: 180,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.45),
                          Colors.black.withValues(alpha: 0.8),
                          Colors.black,
                        ],
                        stops: const [0.0, 0.35, 0.7, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            if (settings.enableSlideGesture)
              Positioned.fill(
                child: Consumer(
                  builder: (context, ref, child) {
                    final progress = ref.watch(playerExpandProgressProvider);
                    return Stack(
                      children: [
                        Positioned(
                          key: const ValueKey('navbar_slot'),
                          left: 0,
                          right: 0,
                          bottom: MediaQuery.of(context).viewInsets.bottom > 0
                              ? -150
                              : 0,
                          child: IgnorePointer(
                            ignoring: !_navAtRoot,
                            child: AnimatedOpacity(
                              opacity: !_navAtRoot
                                  ? 0.0
                                  : (MediaQuery.of(context).viewInsets.bottom >
                                            0
                                        ? 0.0
                                        : (1.0 - progress * 3.0).clamp(
                                            0.0,
                                            1.0,
                                          )),
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                              child: AnimatedSlide(
                                // Offset is a fraction of the navbar's own
                                // size - 1.2 clears it fully off-screen
                                // (previously 0.4, only 40% of its own
                                // height, which just moved it partway while
                                // fading, on a different clock than the
                                // mini player's reposition below).
                                offset: _navAtRoot
                                    ? Offset.zero
                                    : const Offset(0, 1.2),
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                                child: Transform.translate(
                                  offset: Offset(0.0, progress * 110.0),
                                  child: PremiumNavbar(
                                    currentIndex: rootItem == NavItem.home
                                        ? 0
                                        : (rootItem == NavItem.songs ? 1 : 2),
                                    onTap: (index) {
                                      NavItem target;
                                      switch (index) {
                                        case 1:
                                          target = NavItem.songs;
                                          break;
                                        case 2:
                                          target = NavItem.library;
                                          break;
                                        case 0:
                                        default:
                                          target = NavItem.home;
                                          break;
                                      }
                                      ref
                                          .read(appNavigationProvider.notifier)
                                          .setItem(target);
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        if (song != null && !showSupportUsSheet)
                          TweenAnimationBuilder<double>(
                            key: const ValueKey('music_bar_slot'),
                            // Same duration/curve as the navbar's fade+slide
                            // above so the two move in lockstep instead of
                            // finishing at different times.
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            tween: Tween<double>(
                              end: _navAtRoot
                                  ? (navbarHeight + 4.0)
                                  : (16.0 +
                                        MediaQuery.of(context).padding.bottom),
                            ),
                            builder: (context, restingOffset, child) {
                              return Positioned(
                                left: 0,
                                right: 0,
                                bottom:
                                    MediaQuery.of(context).viewInsets.bottom > 0
                                    ? -150
                                    : restingOffset * (1.0 - progress),
                                height:
                                    72.0 +
                                    (MediaQuery.of(context).size.height -
                                            72.0) *
                                        progress,
                                child: child!,
                              );
                            },
                            child: const PremiumMusicBar(
                              key: ValueKey('music_bar'),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              )
            else ...[
              // Mini player and navbar each get their own AnimatedPositioned,
              // on the same duration/curve, instead of both being stacked in
              // one Column that an AnimatedSwitcher resized abruptly. That
              // old version only animated *opacity* (AnimatedSwitcher doesn't
              // animate its own layout box's size) while the Column's actual
              // height snapped to the new value the instant the switch
              // resolved - since the whole block was pinned by `bottom: 0`,
              // that snap yanked the mini player to its new position in one
              // frame. Now the navbar genuinely slides fully off-screen and
              // the mini player genuinely slides down into the spot it
              // vacates, in lockstep.
              if (song != null && !showSupportUsSheet)
                AnimatedPositioned(
                  // Keyed so the conditional `if` above never makes this
                  // slot's element get reused-by-index for the always-
                  // present navbar slot below when it disappears (that
                  // index shuffle was corrupting the navbar's own
                  // AnimatedPositioned - it would resume its animation from
                  // this widget's last position instead of its own,
                  // producing a visible pop on dismiss).
                  key: const ValueKey('music_bar_slot'),
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  left: 0,
                  right: 0,
                  bottom: MediaQuery.of(context).viewInsets.bottom > 0
                      ? -150
                      : (_navAtRoot
                            ? navbarHeight + 4.0
                            : 16.0 + MediaQuery.of(context).padding.bottom),
                  child: AnimatedOpacity(
                    opacity: MediaQuery.of(context).viewInsets.bottom > 0
                        ? 0.0
                        : 1.0,
                    duration: const Duration(milliseconds: 200),
                    child: const PremiumMusicBar(key: ValueKey('music_bar')),
                  ),
                ),
              AnimatedPositioned(
                key: const ValueKey('navbar_slot'),
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                left: 0,
                right: 0,
                bottom: MediaQuery.of(context).viewInsets.bottom > 0
                    ? -150
                    : (_navAtRoot ? 0 : -navbarHeight),
                child: IgnorePointer(
                  ignoring: !_navAtRoot,
                  child: AnimatedOpacity(
                    opacity: MediaQuery.of(context).viewInsets.bottom > 0
                        ? 0.0
                        : (_navAtRoot ? 1.0 : 0.0),
                    duration: const Duration(milliseconds: 200),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 4),
                        PremiumNavbar(
                          currentIndex: rootItem == NavItem.home
                              ? 0
                              : (rootItem == NavItem.songs ? 1 : 2),
                          onTap: (index) {
                            NavItem target;
                            switch (index) {
                              case 1:
                                target = NavItem.songs;
                                break;
                              case 2:
                                target = NavItem.library;
                                break;
                              case 0:
                              default:
                                target = NavItem.home;
                                break;
                            }
                            ref
                                .read(appNavigationProvider.notifier)
                                .setItem(target);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Route _createPremiumRoute(Widget page) {
    return PageRouteBuilder(
      opaque: true,
      transitionDuration: const Duration(milliseconds: 320),
      reverseTransitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final enter = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        final exit = CurvedAnimation(
          parent: secondaryAnimation,
          curve: Curves.easeInCubic,
        );
        return Stack(
          children: [
            Positioned.fill(
              child: ColoredBox(color: Theme.of(context).colorScheme.surface),
            ),
            SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.06, 0),
                end: Offset.zero,
              ).animate(enter),
              child: FadeTransition(
                opacity: enter,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: Offset.zero,
                    end: const Offset(-0.06, 0),
                  ).animate(exit),
                  child: FadeTransition(
                    opacity: Tween<double>(begin: 1, end: 0).animate(exit),
                    child: child,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class BlurredBackgroundArt extends StatelessWidget {
  final Song song;
  const BlurredBackgroundArt({required this.song, super.key});

  @override
  Widget build(BuildContext context) {
    final path = song.artPath;
    if (path == null) return const SizedBox.shrink();
    return RepaintBoundary(
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Image.file(
          File(path),
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          filterQuality: FilterQuality.low,
          cacheWidth: 80,
          cacheHeight: 80,
          gaplessPlayback: true,
          errorBuilder: (_, _, _) => const SizedBox.shrink(),
        ),
      ),
    );
  }
}

class _NavDepthObserver extends NavigatorObserver {
  _NavDepthObserver({required this.onAtRootChanged});

  final ValueChanged<bool> onAtRootChanged;
  int _depth = 0;

  void _report() => onAtRootChanged(_depth <= 1);

  @override
  void didPush(Route route, Route? previousRoute) {
    _depth++;
    _report();
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    _depth = _depth > 0 ? _depth - 1 : 0;
    _report();
  }

  @override
  void didRemove(Route route, Route? previousRoute) {
    _depth = _depth > 0 ? _depth - 1 : 0;
    _report();
  }
}
