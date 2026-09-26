import 'dart:io';
import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:looper_player/core/theme/app_fonts.dart';
import 'package:looper_player/core/utils/responsive.dart';
import 'package:looper_player/features/playback/presentation/providers/playback/playback_notifier.dart';
import 'package:looper_player/features/playback/presentation/screens/lyrics_view.dart';
import 'package:looper_player/features/settings/presentation/providers/settings_notifier.dart';
import 'package:looper_player/ui/android/widgets/premium_section.dart';
import 'package:looper_player/ui/widgets/common/optimized_image.dart';
import 'package:looper_player/core/utils/ui_utils.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:looper_player/core/theme/app_icons.dart';
import 'package:looper_player/ui/widgets/player/animated_play_pause_icon.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:looper_player/ui/widgets/common/scrolling_text.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:looper_player/ui/widgets/player/fluid_background.dart';
import 'package:looper_player/features/playback/presentation/providers/lyrics/lyrics_notifier.dart';
import 'package:looper_player/ui/widgets/player/premium_progress_bar.dart';
import 'package:looper_player/ui/android/player/lyrics/widgets/android_lyrics_menu_sheet.dart';
import 'package:looper_player/ui/android/player/lyrics/widgets/lyrics_selection_toolbar.dart';
import 'package:looper_player/ui/android/player/lyrics/widgets/lyrics_gestures_tutorial_sheet.dart';
import 'package:looper_player/l10n/app_localizations.dart';
import 'package:looper_player/ui/widgets/player/player_gradient/animated_player_gradient.dart';
import 'package:looper_player/core/utils/l10n.dart';

class AndroidLyricsScreen extends ConsumerStatefulWidget {
  const AndroidLyricsScreen({super.key});

  @override
  ConsumerState<AndroidLyricsScreen> createState() =>
      _AndroidLyricsScreenState();
}

class _AndroidLyricsScreenState extends ConsumerState<AndroidLyricsScreen> {
  bool _delayCompleted = false;
  Timer? _delayTimer;
  Animation<double>? _routeAnimation;

  // Manual scroll & bottom controller states
  bool _showController = true;
  Timer? _hideTimer;

  // Independent tap pulses for the prev/next transport icons so tapping one
  // never replays the other's "pop" animation (each button owns its own key).
  final ValueNotifier<int> _prevTapPulse = ValueNotifier<int>(0);
  final ValueNotifier<int> _nextTapPulse = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    final isPlaying = ref.read(playbackProvider).isPlaying;
    if (isPlaying) {
      _enableWakelock();
    } else {
      _disableWakelock();
    }

    _delayTimer = Timer(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _delayCompleted = true;
        });
        _maybeShowGesturesTutorial();
      }
    });

    _resetHideTimer(const Duration(seconds: 3));

    // Reset manual scroll provider when opening lyrics screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(lyricsManualScrollProvider.notifier).set(false);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null && route.animation != _routeAnimation) {
      _routeAnimation?.removeStatusListener(_onRouteAnimationStatusChanged);
      _routeAnimation = route.animation;
      _routeAnimation?.addStatusListener(_onRouteAnimationStatusChanged);
    }
  }

  void _onRouteAnimationStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.reverse) {
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _hideTimer?.cancel();
    _routeAnimation?.removeStatusListener(_onRouteAnimationStatusChanged);
    _disableWakelock();
    _prevTapPulse.dispose();
    _nextTapPulse.dispose();
    super.dispose();
  }

  Future<void> _enableWakelock() async {
    try {
      await WakelockPlus.enable();
    } catch (e) {}
  }

  Future<void> _disableWakelock() async {
    try {
      await WakelockPlus.disable();
    } catch (e) {}
  }

  void _maybeShowGesturesTutorial() {
    if (!mounted) return;
    if (ref.read(settingsProvider).lyricsGestureTutorialSeen) return;
    showLyricsGesturesTutorial(context, ref);
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _onUserScrolled() {
    if (!mounted) return;
    ref.read(lyricsManualScrollProvider.notifier).set(true);
    if (!_showController) {
      setState(() {
        _showController = true;
      });
    }
    _resetHideTimer();
  }

  DateTime _lastHideTimerReset = DateTime.fromMillisecondsSinceEpoch(0);

  void _resetHideTimer([Duration duration = const Duration(seconds: 4)]) {
    // Called from a ScrollNotification listener, which fires many times a
    // second during a drag/fling - coalesce to at most one Timer
    // cancel+recreate per 200ms instead of one per scroll delta. Safe: as
    // long as scrolling keeps generating events at least that often (true
    // of any active scroll), the still-pending timer from the last real
    // reset has well over 200ms left, so this can never fire early - it
    // only ever pushes the hide out a little later than the theoretical
    // "exactly on the last event" deadline, never sooner.
    final now = DateTime.now();
    if (_hideTimer != null &&
        now.difference(_lastHideTimerReset) <
            const Duration(milliseconds: 200)) {
      return;
    }
    _lastHideTimerReset = now;
    _hideTimer?.cancel();
    _hideTimer = Timer(duration, () {
      if (mounted) {
        setState(() {
          _showController = false;
        });
      }
    });
  }

  TextStyle _getHeroStyle(Hero hero, TextStyle fallback) {
    final child = hero.child;
    if (child is ScrollingText) {
      return child.style;
    }
    if (child is Text) {
      return child.style ?? fallback;
    }
    return fallback;
  }

  Widget _buildHeroTextShuttle(
    BuildContext flightContext,
    Animation<double> animation,
    HeroFlightDirection flightDirection,
    BuildContext fromHeroContext,
    BuildContext toHeroContext,
  ) {
    final Hero fromHero = fromHeroContext.widget as Hero;
    final Hero toHero = toHeroContext.widget as Hero;

    final isArtist =
        fromHero.tag == 'song_artist' || toHero.tag == 'song_artist';
    final playback = ref.read(playbackProvider);
    final song = playback.currentSong;
    if (song == null) return const SizedBox.shrink();

    final text = isArtist
        ? (song.artist ?? context.l10n.unknownArtist)
        : song.title;

    final fallbackFrom = isArtist
        ? AppFonts.jostStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 14,
          )
        : AppFonts.jostStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          );

    final fallbackTo = isArtist
        ? AppFonts.jostStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 18,
          )
        : AppFonts.jostStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          );

    final fromStyle = _getHeroStyle(fromHero, fallbackFrom);
    final toStyle = _getHeroStyle(toHero, fallbackTo);

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final lerpValue = flightDirection == HeroFlightDirection.push
            ? animation.value
            : 1.0 - animation.value;

        return Material(
          type: MaterialType.transparency,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              text,
              style: TextStyle.lerp(fromStyle, toStyle, lerpValue),
              maxLines: 1,
              overflow: TextOverflow.visible,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    ref.listen<PlaybackState>(playbackProvider, (previous, next) {
      if (next.isPlaying != previous?.isPlaying) {
        if (next.isPlaying) {
          _enableWakelock();
        } else {
          _disableWakelock();
        }
      }
    });

    final song = ref.watch(playbackProvider.select((s) => s.currentSong));
    final isManualScroll = ref.watch(lyricsManualScrollProvider);
    // The re-sync button itself should only appear once the active line has
    // actually scrolled out of view - not on every scroll touch regardless
    // of whether the current line is still sitting right there on screen.
    final activeLineVisible = ref.watch(lyricsActiveLineVisibleProvider);
    final showResync = isManualScroll && !activeLineVisible;
    final settings = ref.watch(settingsProvider);

    if (song == null) return const SizedBox.shrink();

    // On a short window (landscape phones - same check PlayerLandscapeMetrics
    // uses) the bottom controller's original 350dp height, tuned for a tall
    // portrait screen, ate a large fraction of the available height and
    // covered the lyrics behind it. Shrink it to just fit the seek bar +
    // transport row + safe-area padding instead of the extra gradient
    // headroom that only looks right when there's plenty of vertical space.
    final bool isCompactHeight = Responsive.isShort(MediaQuery.sizeOf(context));
    final double bottomControllerHeight = isCompactHeight ? 220.s : 350.s;

    final mainContent = SafeArea(
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollUpdateNotification) {
            if (notification.dragDetails != null) {
              _onUserScrolled();
            }
          } else if (notification is ScrollStartNotification) {
            if (notification.dragDetails != null) {
              _onUserScrolled();
            }
          } else if (notification is UserScrollNotification) {
            if (notification.direction != ScrollDirection.idle) {
              _onUserScrolled();
            }
          }
          return false;
        },
        child: Column(
          children: [
            // Top Row: Album Art + Song Info
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
              child: Row(
                children: [
                  Hero(
                    tag: 'album_art',
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: OptimizedImage(
                        imagePath: song.artPath,
                        width: 60.s,
                        height: 60.s,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Hero(
                          tag: 'song_title',
                          flightShuttleBuilder: _buildHeroTextShuttle,
                          child: ScrollingText(
                            text: song.title,
                            style: AppFonts.jostStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                        Hero(
                          tag: 'song_artist',
                          flightShuttleBuilder: _buildHeroTextShuttle,
                          child: ScrollingText(
                            text: song.artist ?? context.l10n.unknownArtist,
                            style: AppFonts.jostStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 14,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Menu Button
                  PremiumSection(
                    //  borderRadius: BorderRadius.circular(32),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(32),
                      bottomLeft: Radius.circular(32),
                      topRight: Radius.circular(10),
                      bottomRight: Radius.circular(10),
                    ),
                    width: 48.s,
                    height: 48.s,
                    useExpanded: false,
                    forceNoBlur: true,
                    backgroundColor: Colors.white.withOpacity(0.04),
                    showBorder: false,
                    useBlur:
                        settings.ambientColorBackground ||
                        settings.enableDynamicTheming ||
                        settings.dynamicLyrics ||
                        settings.blurredArtworkForLyrics,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      showLyricsMenuBottomSheet(context, ref, song);
                    },
                    child: const Icon(
                      LucideIcons.ellipsisVertical,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 2),
                  // Down Arrow
                  PremiumSection(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(10),
                      bottomLeft: Radius.circular(10),
                      topRight: Radius.circular(32),
                      bottomRight: Radius.circular(32),
                    ),
                    width: 48.s,
                    height: 48.s,
                    showBorder: false,
                    useExpanded: false,
                    forceNoBlur: true,
                    backgroundColor: Colors.white.withOpacity(0.04),
                    useBlur:
                        settings.ambientColorBackground ||
                        settings.enableDynamicTheming ||
                        settings.dynamicLyrics ||
                        settings.blurredArtworkForLyrics,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(context);
                    },
                    child: const Icon(
                      LucideIcons.chevronDown,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),

            // Thin grey line
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                height: 0.5,
                width: double.infinity,
                color: Colors.white.withValues(alpha: 0.15),
              ),
            ),

            // Lyrics Content
            const Expanded(child: LyricsView()),
          ],
        ),
      ),
    );

    final lyricsDarkness = settings.lyricsDarkness.isNaN
        ? 0.55
        : settings.lyricsDarkness;

    final route = ModalRoute.of(context);
    final isExiting =
        route != null && route.animation?.status == AnimationStatus.reverse;

    final showDynamicBg =
        !isExiting &&
        _delayCompleted &&
        (settings.ambientColorBackground ||
            ((settings.enableDynamicTheming || settings.dynamicLyrics) &&
                !settings.blurredArtworkForLyrics)) &&
        song.artPath != null;

    final showBlurredArtworkBg =
        !isExiting &&
        _delayCompleted &&
        !settings.ambientColorBackground &&
        settings.blurredArtworkForLyrics &&
        song.artPath != null;

    final transitionDuration = isExiting
        ? Duration.zero
        : const Duration(milliseconds: 1000);

    return GestureDetector(
      onVerticalDragEnd: (details) {
        if (details.primaryVelocity! > 300) {
          HapticFeedback.mediumImpact();
          Navigator.of(context).pop();
        }
      },
      onTap: () {
        setState(() {
          _showController = !_showController;
        });
        if (_showController) {
          _resetHideTimer();
        } else {
          _hideTimer?.cancel();
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            // Background Layer: AnimatedSwitcher smoothly transitions between fallback static background and the dynamic fluid background
            Positioned.fill(
              child: AnimatedSwitcher(
                duration: transitionDuration,
                child: showDynamicBg && settings.ambientColorBackground
                    // Ambient Color Background: the animated gradient in the
                    // artwork's colors. One stable key so a song change
                    // cross-fades colors inside it instead of restarting
                    // the motion.
                    ? AnimatedPlayerGradient(
                        key: const ValueKey('ambient_bg'),
                        artwork: FileImage(File(song.artPath!)),
                        darkness: lyricsDarkness,
                      )
                    : showDynamicBg
                    ? Consumer(
                        key: ValueKey('fluid_bg_${song.path}'),
                        builder: (context, ref, child) {
                          final isPlaying = ref.watch(
                            playbackProvider.select((s) => s.isPlaying),
                          );
                          return FluidBackground(
                            key: ValueKey('fluid_bg_child_${song.path}'),
                            imageProvider: FileImage(File(song.artPath!)),
                            animate: isPlaying,
                            blurSigma: 80,
                            overlayDarken: lyricsDarkness,
                            child: const SizedBox.expand(),
                          );
                        },
                      )
                    : (showBlurredArtworkBg
                          ? RepaintBoundary(
                              key: ValueKey('blurred_art_bg_${song.path}'),
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    child: ImageFiltered(
                                      imageFilter: ImageFilter.blur(
                                        sigmaX: 25,
                                        sigmaY: 25,
                                      ),
                                      child: Image.file(
                                        File(song.artPath!),
                                        fit: BoxFit.cover,
                                        filterQuality: FilterQuality.low,
                                        cacheWidth: 100,
                                        cacheHeight: 100,
                                        gaplessPlayback: true,
                                        errorBuilder: (_, _, _) =>
                                            const SizedBox.shrink(),
                                      ),
                                    ),
                                  ),
                                  Positioned.fill(
                                    child: Container(
                                      color: Colors.black.withValues(
                                        alpha: lyricsDarkness,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : (settings.enablePlayerGradient
                                // Same flowing gradient as the player, always
                                // animated here regardless of the player's
                                // Animated Gradient toggle, with lyricsDarkness
                                // as its darkness layer.
                                ? AnimatedPlayerGradient(
                                    key: const ValueKey('gradient_bg'),
                                    darkness: lyricsDarkness,
                                  )
                                : Container(
                                    key: const ValueKey('static_bg'),
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.surface,
                                  ))),
              ),
            ),
            // Foreground Content Layer: Kept outside of AnimatedSwitcher to prevent state/scroll resets
            Positioned.fill(child: mainContent),

            // Share-selection toolbar: floats in once the user long-presses
            // a lyric line to start picking lines for a share card.
            Positioned(
              top: MediaQuery.of(context).padding.top + 100.s,
              left: 0,
              right: 0,
              child: Center(child: LyricsSelectionToolbar(song: song)),
            ),
            // Re-sync Pill Button

            // Bottom Controller Layer (Includes gradient dark shadow + controls)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: AnimatedSlide(
                offset: _showController ? Offset.zero : const Offset(0, 1),
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeInOutCubic,
                child: AnimatedOpacity(
                  opacity: _showController ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: IgnorePointer(
                    ignoring: !_showController,
                    child: Container(
                      height: bottomControllerHeight,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent.withValues(alpha: 0.010),
                            Colors.transparent.withValues(alpha: 0.40),
                            Colors.black.withValues(alpha: 0.80),
                            Colors.black.withValues(alpha: 0.99),
                          ],
                          stops: const [0.0, 0.2, 0.75, 1.0],
                        ),
                      ),
                      padding: EdgeInsets.only(
                        left: 24.s,
                        right: 24.s,
                        bottom: MediaQuery.of(context).padding.bottom + 24.s,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // ExpressiveSlider Seek Bar (from android_expanded_player.dart)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Consumer(
                              builder: (context, ref, child) {
                                final currentPosition = ref.watch(
                                  playbackProvider.select((s) => s.position),
                                );
                                final duration = ref.watch(
                                  playbackProvider.select((s) => s.duration),
                                );
                                final isPlaying = ref.watch(
                                  playbackProvider.select((s) => s.isPlaying),
                                );
                                return Hero(
                                  tag: 'player_seek_bar',
                                  child: Material(
                                    type: MaterialType.transparency,
                                    child: ExpressiveSlider(
                                      position: currentPosition,
                                      duration: duration,
                                      isPlaying: isPlaying,
                                      onSeek: (pos) {
                                        _resetHideTimer();
                                        ref
                                            .read(playbackProvider.notifier)
                                            .seek(pos);
                                      },
                                      onSeekStart: () {
                                        _resetHideTimer();
                                        ref
                                            .read(playbackProvider.notifier)
                                            .startScrubbing();
                                      },
                                      onSeekEnd: () {
                                        _resetHideTimer();
                                        ref
                                            .read(playbackProvider.notifier)
                                            .stopScrubbing();
                                      },
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary.withValues(alpha: 0.9),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),

                          SizedBox(height: isCompactHeight ? 6 : 12),

                          // Playback Controls Row matching android_expanded_player.dart exactly
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 0,
                              vertical: isCompactHeight ? 4 : 14,
                            ),
                            child: Consumer(
                              builder: (context, ref, child) {
                                final isPlaying = ref.watch(
                                  playbackProvider.select((s) => s.isPlaying),
                                );
                                // Portrait-tuned 80dp buttons, unchanged
                                // there; on a short window the outer
                                // controller container is already shrunk
                                // (see bottomControllerHeight above) but
                                // these stayed fixed, leaving almost no
                                // margin before the seek bar + this row +
                                // safe-area padding overflowed it.
                                final double transportButtonHeight =
                                    isCompactHeight ? 56.0 : 80.0;
                                return Row(
                                  children: [
                                    // Previous
                                    PremiumSection(
                                      heroTag: 'player_prev_btn',
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(40),
                                        bottomLeft: Radius.circular(40),
                                        topRight: Radius.circular(12),
                                        bottomRight: Radius.circular(12),
                                      ),
                                      height: transportButtonHeight,
                                      showShadow: false,
                                      useBlur: settings.enableDynamicTheming,
                                      forceNoBlur: true,
                                      backgroundColor: Colors.white.withOpacity(
                                        0.04,
                                      ),
                                      showBorder: false,
                                      onTap: () {
                                        _resetHideTimer();
                                        HapticFeedback.lightImpact();
                                        _prevTapPulse.value++;
                                        ref
                                            .read(playbackProvider.notifier)
                                            .skipPrevious();
                                      },
                                      child: ValueListenableBuilder<int>(
                                        valueListenable: _prevTapPulse,
                                        builder: (context, tick, child) {
                                          return AnimatedTransportIcon(
                                            asset: AppIcons.prev,
                                            color: Colors.white,
                                            size: AppIcons
                                                .expandedPlayerMainControl
                                                .s,
                                            triggerKey: tick,
                                          );
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    // Play/Pause
                                    PremiumSection(
                                      heroTag: 'player_play_pause_btn',
                                      borderRadius: BorderRadius.circular(12),
                                      height: transportButtonHeight,
                                      showBorder: false,
                                      showShadow: false,
                                      useBlur: settings.enableDynamicTheming,
                                      forceNoBlur: true,
                                      backgroundColor: isPlaying
                                          ? Colors.white.withOpacity(0.04)
                                          : Theme.of(
                                              context,
                                            ).colorScheme.primary.withValues(alpha: 0.9),
                                      onTap: () {
                                        _resetHideTimer();
                                        HapticFeedback.mediumImpact();
                                        ref
                                            .read(playbackProvider.notifier)
                                            .togglePlay();
                                      },
                                      child: AnimatedScale(
                                        scale: 1.1,
                                        duration: const Duration(
                                          milliseconds: 300,
                                        ),
                                        curve: Curves.easeOutBack,
                                        child: AnimatedPlayPauseIcon(
                                          isPlaying: isPlaying,
                                          color: Colors.white,
                                          size: AppIcons
                                              .expandedPlayerPlayPauseIcon
                                              .s,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    // Next
                                    PremiumSection(
                                      heroTag: 'player_next_btn',
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(12),
                                        bottomLeft: Radius.circular(12),
                                        topRight: Radius.circular(40),
                                        bottomRight: Radius.circular(40),
                                      ),
                                      height: transportButtonHeight,
                                      useBlur: settings.enableDynamicTheming,
                                      showShadow: false,
                                      backgroundColor: Colors.white.withOpacity(
                                        0.04,
                                      ),
                                      showBorder: false,
                                      forceNoBlur: true,
                                      onTap: () {
                                        _resetHideTimer();
                                        HapticFeedback.lightImpact();
                                        _nextTapPulse.value++;
                                        ref
                                            .read(playbackProvider.notifier)
                                            .skipNext();
                                      },
                                      child: ValueListenableBuilder<int>(
                                        valueListenable: _nextTapPulse,
                                        builder: (context, tick, child) {
                                          return AnimatedTransportIcon(
                                            asset: AppIcons.next,
                                            color: Colors.white,
                                            size: AppIcons
                                                .expandedPlayerMainControl
                                                .s,
                                            triggerKey: tick,
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            AnimatedPositioned(
              bottom: _showController ? bottomControllerHeight - 50.s : 50.s,
              left: 0,
              right: 0,
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeInOutCubic,
              child: Center(
                child: AnimatedOpacity(
                  opacity: showResync ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: AnimatedScale(
                    scale: showResync ? 1.0 : 0.8,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutBack,
                    child: IgnorePointer(
                      ignoring: !showResync,
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          ref
                              .read(lyricsManualScrollProvider.notifier)
                              .set(false);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.onSecondary,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                LucideIcons.refreshCw,
                                size: 14,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                l10n.resync,
                                style: AppFonts.jostStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
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
