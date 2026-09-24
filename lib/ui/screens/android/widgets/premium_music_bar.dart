import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:looper_player/features/playback/presentation/playback_notifier.dart';
import 'package:looper_player/features/settings/presentation/settings_notifier.dart';
import 'package:looper_player/ui/screens/android/player/android_expanded_player.dart';
import 'package:looper_player/ui/screens/android/player/player_landscape_layout.dart';
import 'package:looper_player/ui/widgets/optimized_image.dart';
import 'package:looper_player/core/responsive.dart';
import 'package:looper_player/core/ui_utils.dart';
import 'package:looper_player/core/app_icons.dart';
import 'package:looper_player/ui/widgets/animated_play_pause_icon.dart';
import 'package:looper_player/core/app_fonts.dart';
import 'package:looper_player/ui/widgets/scrolling_text.dart';
import 'package:looper_player/core/player_expand_focus.dart';
import 'package:looper_player/core/player_expand_provider.dart';
import 'package:looper_player/features/library/domain/models/models.dart';
import 'dart:ui';

import 'premium_section.dart';

class PremiumMusicBar extends ConsumerStatefulWidget {
  const PremiumMusicBar({super.key});

  @override
  ConsumerState<PremiumMusicBar> createState() => _PremiumMusicBarState();
}

class _PremiumMusicBarState extends ConsumerState<PremiumMusicBar> with TickerProviderStateMixin {
  late AnimationController _dragController;
  Offset _dragOffset = Offset.zero;
  bool _isDragging = false;
  bool _isPushing = false;

  @override
  void initState() {
    super.initState();
    _dragController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    )..addListener(() {
        ref.read(playerExpandProgressProvider.notifier).set(_dragController.value);
      });
  }

  @override
  void dispose() {
    _dragController.dispose();
    super.dispose();
  }

  void _triggerHaptic() {
    HapticFeedback.lightImpact();
  }

  void _pushExpandedPlayer(BuildContext context, dynamic settings) async {
    if (settings.enableSlideGesture) {
      _dragController.animateTo(1.0, curve: Curves.easeOutCubic);
    } else {
      if (_isPushing) return;
      _isPushing = true;
      _triggerHaptic();
      await Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const AndroidExpandedPlayer(),
          transitionDuration: const Duration(milliseconds: 400),
          reverseTransitionDuration: const Duration(milliseconds: 400),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
      _isPushing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final song = ref.watch(playbackProvider.select((s) => s.currentSong));
    final isPlaying = ref.watch(playbackProvider.select((s) => s.isPlaying));
    final settings = ref.watch(settingsProvider);
    final useBlur = settings.enableDynamicTheming;
    final expandProgress = settings.enableSlideGesture
        ? ref.watch(playerExpandProgressProvider)
        : 0.0;

    ref.listen<double>(playerExpandProgressProvider, (prev, next) {
      if (settings.enableSlideGesture) {
        dismissFocusWhenPlayerExpands(prev, next);
        if (next == 0.0 && _dragController.value > 0.0 && !_isDragging) {
          _dragController.animateTo(0.0, curve: Curves.easeOutCubic);
        } else if (next == 1.0 && _dragController.value < 1.0 && !_isDragging) {
          _dragController.animateTo(1.0, curve: Curves.easeOutCubic);
        }
      }
    });

    ref.listen<int>(playerCollapseTriggerProvider, (prev, next) {
      if (settings.enableSlideGesture) {
        _isDragging = false;
        _dragController.animateTo(0.0, curve: Curves.easeOutCubic);
      }
    });

    if (song == null) return const SizedBox.shrink();

    if (!settings.enableSlideGesture) {
      final Size windowSize = MediaQuery.sizeOf(context);
      // Landscape phones are short - shrink the bar to match PremiumNavbar's
      // own compact height (see navbarHeight in android_main_screen.dart, kept
      // in sync with this) instead of the portrait-tuned 72dp.
      final bool isCompact = Responsive.isShort(windowSize);
      final double barHeight = isCompact ? 56.0 : 72.0;

      final Widget bar = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: GestureDetector(
          onPanStart: (details) {
            setState(() {
              _isDragging = true;
            });
          },
          onPanUpdate: (details) {
            setState(() {
              _dragOffset += details.delta;
            });
          },
          onPanEnd: (details) {
            _isDragging = false;
            final dx = _dragOffset.dx;
            final dy = _dragOffset.dy;

            if (dy > 70 && dy.abs() > dx.abs()) {
              HapticFeedback.heavyImpact();
              ref.read(playbackProvider.notifier).clearQueue();
            } else if (dy < -70 && dy.abs() > dx.abs()) {
              _pushExpandedPlayer(context, settings);
            } else if (dx.abs() > dy.abs()) {
              if (dx > 70) {
                _triggerHaptic();
                ref.read(playbackProvider.notifier).skipPrevious();
              } else if (dx < -70) {
                _triggerHaptic();
                ref.read(playbackProvider.notifier).skipNext();
              }
            }

            setState(() {
              _dragOffset = Offset.zero;
            });
          },
          onTapUp: (details) {
            if (_isDragging) return;
            
            final RenderBox box = context.findRenderObject() as RenderBox;
            final localX = details.localPosition.dx;
            final width = box.size.width;

            if (localX > width * 0.75) {
              HapticFeedback.lightImpact();
              ref.read(playbackProvider.notifier).togglePlay();
            } else {
              _pushExpandedPlayer(context, settings);
            }
          },
          child: TweenAnimationBuilder<Offset>(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            tween: Tween(begin: Offset.zero, end: _dragOffset),
            builder: (context, offset, child) {
              final double tiltX = (offset.dx / 100).clamp(-0.2, 0.2);
              final double tiltY = (offset.dy / 100).clamp(-0.1, 0.1);
              
              final matrix = Matrix4.identity();
              if (tiltX != 0 || tiltY != 0) {
                matrix.setEntry(3, 2, 0.001); // perspective
                matrix.rotateX(-tiltY);
                matrix.rotateY(tiltX);
                matrix.translate(offset.dx * 0.3, offset.dy * 0.3);
              }
              
              return Transform(
                transform: matrix,
                alignment: Alignment.center,
                child: child,
              );
            },
            child: SizedBox(
              height: barHeight,
              child: _buildMiniPlayerContent(
                song,
                isPlaying,
                useBlur,
                null,
                3.0,
                settings,
                compact: isCompact,
              ),
            ),
          ),
        ),
      );

      // A landscape window is wide - a 72dp pill stretched edge-to-edge
      // across it read as an oddly thin, stretched strip rather than a
      // player pill. Cap its width and center it, matching the same
      // treatment already applied to sheets/settings/collection views in
      // landscape (this only wraps the mini-player-only bar used here, not
      // the shared slide-gesture container that also hosts the full-screen
      // expanded player below).
      if (Responsive.isLandscape(windowSize)) {
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640.0),
            child: bar,
          ),
        );
      }
      return bar;
    }

    final Color? cardBgColor = settings.enableSlideGesture ? Colors.transparent : null;
    final double cardBlurAmount = settings.enableSlideGesture ? 0.0 : 3.0;

    final bool disableBlur = settings.disableBlur;
    final bool isBlurActive = useBlur && !disableBlur;
    final Color minimizedBgColor = isBlurActive
        ? Colors.white.withValues(alpha: 0.05)
        : Theme.of(context).colorScheme.surfaceContainer;
    final Color currentBorderColor = Colors.white.withValues(alpha: 0.05 * (1.0 - expandProgress));

    Widget buildHero({required String tag, required Widget child}) {
      if (settings.enableSlideGesture) return child;
      return Hero(tag: tag, child: child);
    }

    final double marginHorizontal = settings.enableSlideGesture ? 16.0 * (1.0 - expandProgress) : 0.0;
    final double borderRadiusVal = settings.enableSlideGesture ? 36.0 : 0.0;
    final double topPadding = MediaQuery.of(context).padding.top;
    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: settings.enableSlideGesture ? 0.0 : 16.0),
      child: GestureDetector(
        onPanStart: (details) {
          if (settings.enableSlideGesture) {
            _isDragging = true;
            _dragController.value = expandProgress;
          } else {
            setState(() {
              _isDragging = true;
            });
          }
        },
        onPanUpdate: (details) {
          if (settings.enableSlideGesture) {
            _dragController.value -= details.delta.dy / (screenHeight > 0 ? screenHeight : 1.0);
          } else {
            setState(() {
              _dragOffset += details.delta;
            });
          }
        },
        onPanEnd: (details) {
          _isDragging = false;
          if (settings.enableSlideGesture) {
            if (_dragController.value > 0.01) {
              final velocity = details.velocity.pixelsPerSecond.dy;
              if (velocity < -200) {
                _dragController.animateTo(1.0, curve: Curves.easeOutCubic);
              } else if (velocity > 200) {
                _dragController.animateTo(0.0, curve: Curves.easeOutCubic);
              } else if (_dragController.value > 0.4) {
                _dragController.animateTo(1.0, curve: Curves.easeOutCubic);
              } else {
                _dragController.animateTo(0.0, curve: Curves.easeOutCubic);
              }
              return;
            }
          }

          final dx = _dragOffset.dx;
          final dy = _dragOffset.dy;

          if (dy > 70 && dy.abs() > dx.abs()) {
            HapticFeedback.heavyImpact();
            ref.read(playbackProvider.notifier).clearQueue();
          } else if (dy < -70 && dy.abs() > dx.abs() && !settings.enableSlideGesture) {
            _pushExpandedPlayer(context, settings);
          } else if (dx.abs() > dy.abs()) {
            if (dx > 70) {
              _triggerHaptic();
              ref.read(playbackProvider.notifier).skipPrevious();
            } else if (dx < -70) {
              _triggerHaptic();
              ref.read(playbackProvider.notifier).skipNext();
            }
          }

          setState(() {
            _dragOffset = Offset.zero;
          });
        },
        onTapUp: (details) {
          if (_isDragging) return;
          
          final RenderBox box = context.findRenderObject() as RenderBox;
          final localX = details.localPosition.dx;
          final width = box.size.width;

          if (localX > width * 0.75) {
            HapticFeedback.lightImpact();
            ref.read(playbackProvider.notifier).togglePlay();
          } else {
            _pushExpandedPlayer(context, settings);
          }
        },
        child: TweenAnimationBuilder<Offset>(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          tween: Tween(begin: Offset.zero, end: _dragOffset),
          builder: (context, offset, child) {
            final double tiltX = (offset.dx / 100).clamp(-0.2, 0.2);
            final double tiltY = (offset.dy / 100).clamp(-0.1, 0.1);
            
            final matrix = Matrix4.identity();
            if ((tiltX != 0 || tiltY != 0) && !settings.enableSlideGesture) {
              matrix.setEntry(3, 2, 0.001); // perspective
              matrix.rotateX(-tiltY);
              matrix.rotateY(tiltX);
              matrix.translate(offset.dx * 0.3, offset.dy * 0.3);
            }
            
            return Transform(
              transform: matrix,
              alignment: Alignment.center,
              child: child,
            );
          },
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: marginHorizontal),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(borderRadiusVal),
              border: Border.all(
                color: currentBorderColor,
                width: 1.2,
              ),
              boxShadow: expandProgress < 0.95
                  ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 15,
                        spreadRadius: 2,
                      )
                    ]
                  : null,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(borderRadiusVal),
              child: Stack(
                children: [
                  // 1. Dynamic background stack (cross-fading minimized translucent/blur and expanded player backgrounds)
                  if (settings.enableSlideGesture) ...[
                    // Minimized background (translucent surface container / white glass + backdrop filter blur behind it)
                    // BackdropFilter forces a full offscreen composite pass every frame
                    // regardless of sigma, so it's only mounted when blur is actually
                    // active — a sigma-0 filter would still pay the full cost for
                    // nothing since this bar is present on almost every screen.
                    Positioned.fill(
                      child: Opacity(
                        opacity: (1.0 - expandProgress).clamp(0.0, 1.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(borderRadiusVal),
                          child: isBlurActive
                              ? BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 3.0, sigmaY: 3.0),
                                  child: Container(
                                    color: minimizedBgColor,
                                  ),
                                )
                              : Container(
                                  color: minimizedBgColor,
                                ),
                        ),
                      ),
                    ),

                    // Expanded background (blurred album art or radial gradient or solid surface)
                    Positioned.fill(
                      child: Opacity(
                        opacity: expandProgress,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(borderRadiusVal),
                          child: () {
                            if (useBlur && song.artPath != null) {
                              return Stack(
                                fit: StackFit.expand,
                                children: [
                                  BlurredBackgroundArt(song: song),
                                  Container(
                                    color: Colors.black.withValues(
                                      alpha: settings.musicDarkness.isNaN ? 0.62 : settings.musicDarkness,
                                    ),
                                  ),
                                ],
                              );
                            } else if (settings.enablePlayerGradient) {
                              return Stack(
                                fit: StackFit.expand,
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      gradient: RadialGradient(
                                        center: Alignment.topRight,
                                        radius: 1.5,
                                        colors: [
                                          Theme.of(context).colorScheme.primary.withValues(alpha: 0.18),
                                          Theme.of(context).colorScheme.surface,
                                        ],
                                        stops: const [0.0, 1.0],
                                      ),
                                    ),
                                  ),
                                  // Same musicDarkness slider as the dynamic-art
                                  // background above, so it isn't a dead control
                                  // when gradient mode is what's actually active.
                                  Container(
                                    color: Colors.black.withValues(
                                      alpha: settings.musicDarkness.isNaN ? 0.62 : settings.musicDarkness,
                                    ),
                                  ),
                                ],
                              );
                            } else {
                              return Container(
                                color: Theme.of(context).colorScheme.surface,
                              );
                            }
                          }(),
                        ),
                      ),
                    ),
                  ],

                  // 2. Mini player layout (visible when minimized)
                  if (expandProgress < 0.99)
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: 72,
                      child: Opacity(
                        opacity: (1.0 - expandProgress * 3.0).clamp(0.0, 1.0),
                        child: _buildMiniPlayerContent(song, isPlaying, useBlur, cardBgColor, cardBlurAmount, settings),
                      ),
                    ),

                  // 3. Expanded player layout (visible when expanded)
                  if (expandProgress > 0.01)
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: screenHeight,
                      child: Opacity(
                        opacity: ((expandProgress - 0.25) / 0.75).clamp(0.0, 1.0),
                        child: const AndroidExpandedPlayer(),
                      ),
                    ),

                  // 4. Morphing Album Art image (flying/scaling between layouts)
                  if (settings.enableSlideGesture && song.artPath != null) ...[
                    () {
                      final double dpr = MediaQuery.maybeDevicePixelRatioOf(context) ?? 2.0;

                      // Target the real artwork's measured rect (reported by
                      // PositionReporter/playerArtworkRectProvider once
                      // AndroidExpandedPlayer has fully expanded at least
                      // once) so the handoff at expandProgress > 0.99 lands
                      // exactly where the real widget renders - pixel-perfect
                      // regardless of text scale, safe-area insets, or future
                      // layout changes below the artwork. Before it's ever
                      // been measured (e.g. the very first expand after
                      // launch), fall back to an approximation.
                      //
                      // In landscape the artwork's rect is a pure function of
                      // the window (PlayerLandscapeMetrics), so aim at that
                      // directly: the measurement above is only ever taken in
                      // portrait and would be stale after a rotation.
                      final Size windowSize = Size(screenWidth, screenHeight);
                      final bool isLandscape = Responsive.isLandscape(windowSize);
                      final Rect? measuredRect = isLandscape
                          ? PlayerLandscapeMetrics.of(
                              windowSize,
                              MediaQuery.paddingOf(context),
                            ).artRect
                          : ref.watch(playerArtworkRectProvider);
                      final double expandedArtSize = measuredRect?.width ?? (screenWidth - 40.0);
                      final double expandedArtLeft = measuredRect?.left ?? 20.0;
                      final double expandedArtTop = measuredRect?.top ??
                          () {
                            final double availableHeight =
                                screenHeight - topPadding - 56.0 - 380.0;
                            return topPadding +
                                56.0 +
                                (availableHeight - expandedArtSize).clamp(0.0, double.infinity) /
                                    2;
                          }();

                      final double artSize = 50.0 + (expandedArtSize - 50.0) * expandProgress;
                      final double artLeft = 12.0 + (expandedArtLeft - 12.0) * expandProgress;
                      final double artTop = 11.0 + (expandedArtTop - 11.0) * expandProgress;
                      // Target radius matches artworkSwitcher's real
                      // BorderRadius.circular(12) in android_expanded_player.dart.
                      final double artRadius = 32.0 * (1.0 - expandProgress) + 12.0 * expandProgress;

                      return Positioned(
                        left: artLeft,
                        top: artTop,
                        width: artSize,
                        height: artSize,
                        child: IgnorePointer(
                          ignoring: expandProgress > 0.99,
                          child: Opacity(
                            opacity: expandProgress > 0.99 ? 0.0 : 1.0,
                            child: ClipRRect(
                          borderRadius: BorderRadius.circular(artRadius),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              OptimizedImage(
                                imagePath: !song.artPath!.startsWith('http') ? song.artPath : null,
                                imageUrl: song.artPath!.startsWith('http') ? song.artPath : null,
                                fit: BoxFit.cover,
                                cacheWidth: ((isLandscape ? expandedArtSize : screenWidth) * dpr).toInt(),
                              ),
                              Positioned.fill(
                                child: AnimatedOpacity(
                                  duration: const Duration(milliseconds: 300),
                                  opacity: isPlaying ? (1.0 - expandProgress).clamp(0.0, 1.0) : 0.0,
                                  child: Container(
                                    color: Colors.black.withValues(alpha: 0.4),
                                    child: Center(
                                      // GIF frame decoding doesn't respect
                                      // TickerMode - skip it while ticking is
                                      // paused (e.g. mid route transition).
                                      child: TickerMode.of(context)
                                          ? Image.asset(
                                              'assets/android_icons/Playing.gif',
                                              width: 24,
                                              height: 24,
                                              color: Colors.white,
                                            )
                                          : const SizedBox.shrink(),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                       ),
                      ),
                      );
                    }(),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniPlayerContent(
    Song song,
    bool isPlaying,
    bool useBlur,
    Color? cardBgColor,
    double cardBlurAmount,
    dynamic settings, {
    bool compact = false,
  }) {
    Widget buildHero({required String tag, required Widget child}) {
      if (settings.enableSlideGesture) return child;
      return Hero(tag: tag, child: child);
    }

    final double artSize = compact ? 40.0 : 50.0;
    final double artRadius = compact ? 26.0 : 32.0;
    final double titleFontSize = compact ? 16.0 : 18.0;
    final double artistFontSize = compact ? 13.0 : 16.0;

    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: settings.enableSlideGesture ? 1.2 : 0.0,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left Section: Song Info
          PremiumSection(
            flex: 8,
            useBlur: useBlur,
            forceTransparent: settings.enableSlideGesture,
            keepSurfaceOnDisableBlur: true,
            backgroundColor: cardBgColor,
            blurAmount: cardBlurAmount,
            useExpanded: true,
            onTap: null, // Handled by parent GestureDetector
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(36),
              bottomLeft: Radius.circular(36),
              topRight: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: SizedBox(
                    width: artSize,
                    height: artSize,
                    child: !settings.enableSlideGesture
                        ? Hero(
                            tag: 'album_art',
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(artRadius),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  OptimizedImage(
                                    imagePath: song.artPath != null && !song.artPath!.startsWith('http') ? song.artPath : null,
                                    imageUrl: song.artPath != null && song.artPath!.startsWith('http') ? song.artPath : null,
                                    fit: BoxFit.cover,
                                  ),
                                  Positioned.fill(
                                    child: AnimatedOpacity(
                                      duration: const Duration(milliseconds: 300),
                                      opacity: isPlaying ? 1.0 : 0.0,
                                      child: Container(
                                        color: Colors.black.withValues(alpha: 0.4),
                                        child: Center(
                                          // GIF frame decoding doesn't respect
                                          // TickerMode - skip it while ticking
                                          // is paused (e.g. mid route
                                          // transition).
                                          child: TickerMode.of(context)
                                              ? Image.asset(
                                                  'assets/android_icons/Playing.gif',
                                                  width: 24,
                                                  height: 24,
                                                  color: Colors.white,
                                                )
                                              : const SizedBox.shrink(),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : const SizedBox(),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      buildHero(
                        tag: 'song_title',
                        child: ScrollingText(
                          text: song.title,
                          style: AppFonts.jostStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: titleFontSize.ts,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      buildHero(
                        tag: 'song_artist',
                        child: ScrollingText(
                          text: song.artist ?? 'Unknown Artist',
                          style: AppFonts.jostStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: artistFontSize.ts,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          // Right Section: Play/Pause Button
          PremiumSection(
            flex: 2, 
            useBlur: useBlur,
            forceTransparent: settings.enableSlideGesture,
            keepSurfaceOnDisableBlur: true,
            backgroundColor: cardBgColor,
            blurAmount: cardBlurAmount,
            heroTag: settings.enableSlideGesture ? null : 'player_play_pause_btn',
            useExpanded: true,
            onTap: null, // Handled by parent GestureDetector
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              bottomLeft: Radius.circular(12),
              topRight: Radius.circular(36),
              bottomRight: Radius.circular(36),
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 2.0),
                child: AnimatedScale(
                  scale:  1.0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutBack,
                  child: AnimatedPlayPauseIcon(
                    isPlaying: isPlaying,
                    color: Colors.white,
                    size: (compact
                        ? AppIcons.expandedPlayerPlayPauseIcon * 0.8
                        : AppIcons.expandedPlayerPlayPauseIcon).s,
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
  