import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:looper_player/features/playback/presentation/providers/playback/playback_notifier.dart';
import 'package:looper_player/features/settings/presentation/providers/settings_notifier.dart';
import 'package:looper_player/ui/android/player/expanded/android_expanded_player.dart';
import 'package:looper_player/ui/android/player/expanded/gesture_artwork.dart';
import 'package:looper_player/ui/android/player/expanded/player_landscape_layout.dart';
import 'package:looper_player/ui/widgets/common/optimized_image.dart';
import 'package:looper_player/core/utils/responsive.dart';
import 'package:looper_player/core/utils/ui_utils.dart';
import 'package:looper_player/core/theme/app_icons.dart';
import 'package:looper_player/ui/widgets/player/animated_play_pause_icon.dart';
import 'package:looper_player/core/theme/app_fonts.dart';
import 'package:looper_player/ui/widgets/common/scrolling_text.dart';
import 'package:looper_player/core/providers/player_expand_focus.dart';
import 'package:looper_player/core/providers/player_expand_provider.dart';
import 'package:looper_player/features/library/domain/models/models.dart';

import 'dart:ui';

import 'fluid_player_motion.dart';
import '../../widgets/premium_section.dart';

import 'package:looper_player/core/utils/l10n.dart';
part 'mini_player_content.dart';

class PremiumMusicBar extends ConsumerStatefulWidget {
  const PremiumMusicBar({super.key, this.restingBottom = 0.0});

  /// Fluid Player only: gap between the collapsed mini bar and the bottom
  /// of the screen. The bar animates changes to it itself (so the host never
  /// rebuilds it per frame).
  final double restingBottom;

  @override
  ConsumerState<PremiumMusicBar> createState() => _PremiumMusicBarState();
}

class _PremiumMusicBarState extends ConsumerState<PremiumMusicBar>
    with TickerProviderStateMixin {
  late AnimationController _dragController;
  late final ValueNotifier<double> _expandProgress;
  // Animates restingBottom changes (navbar shown/hidden) - same 300ms
  // easeInOut as the navbar's own slide in android_main_screen.dart.
  late final AnimationController _restController;
  late double _restFrom;
  late double _restTo;
  Offset _dragOffset = Offset.zero;
  bool _isDragging = false;
  bool _isPushing = false;

  @override
  void initState() {
    super.initState();
    _expandProgress = ref.read(playerExpandProgressProvider);
    _dragController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
      value: _expandProgress.value,
    )..addListener(_onExpandTick);
    _restFrom = _restTo = widget.restingBottom;
    _restController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: 1.0,
    );
  }

  @override
  void didUpdateWidget(PremiumMusicBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.restingBottom != _restTo) {
      _restFrom = _restingBottom;
      _restTo = widget.restingBottom;
      _restController.forward(from: 0.0);
    }
  }

  double get _restingBottom => lerpDouble(
    _restFrom,
    _restTo,
    Curves.easeInOut.transform(_restController.value),
  )!;

  // Settles the Fluid Player open/closed on a critically damped spring,
  // starting from the finger's velocity (progress units/s) so letting go
  // never jumps in speed. snapToEnd lands exactly on 0/1, so settled layers
  // end at opacity 1.0 (no leftover compositing layer) and the p > 0.99
  // handoffs always fire.
  void _settle(double target, {double velocity = 0.0}) {
    _dragController.animateWith(
      SpringSimulation(
        fluidPlayerSpring,
        _dragController.value,
        target,
        velocity.clamp(-8.0, 8.0).toDouble(),
        snapToEnd: true,
      ),
    );
  }

  // Runs every animation frame / drag event. Only feeds the shared notifier -
  // nothing here may call setState, or the whole bar rebuilds per frame.
  void _onExpandTick() {
    final double next = _dragController.value;
    dismissFocusWhenPlayerExpands(_expandProgress.value, next);
    _expandProgress.value = next;
  }

  @override
  void dispose() {
    _dragController.dispose();
    _restController.dispose();
    super.dispose();
  }

  void _triggerHaptic() {
    HapticFeedback.lightImpact();
  }

  void _pushExpandedPlayer(BuildContext context, dynamic settings) async {
    if (settings.enableSlideGesture) {
      _settle(1.0);
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
    ref.listen<int>(playerCollapseTriggerProvider, (prev, next) {
      if (settings.enableSlideGesture) {
        _isDragging = false;
        _settle(0.0);
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

    // ---- Fluid Player (slide gesture) ----
    //
    // A full-screen layer. The panel (background + rounded clip) grows from
    // the mini bar's rect to the whole screen; the expanded player's content
    // stays pinned to the screen and eases its sections in on their own
    // (FluidSectionMotion in android_expanded_player.dart) instead of riding
    // the panel's top edge ~500dp up the screen. The clip also limits hit
    // testing to the panel, so the transparent rest of the layer never
    // swallows touches meant for the screen behind it.
    final bool isBlurActive = useBlur && !settings.disableBlur;
    final Color minimizedBgColor = isBlurActive
        ? Colors.white.withValues(alpha: 0.05)
        : Theme.of(context).colorScheme.surfaceContainer;
    final Size windowSize = MediaQuery.sizeOf(context);
    final double musicDarkness = settings.musicDarkness.isNaN
        ? 0.62
        : settings.musicDarkness;

    // Everything below is built once per real change (song, settings,
    // window) and handed to the per-frame builder unchanged. Flutter skips
    // rebuilding an identical widget instance, and each of these gets fixed
    // constraints, so a frame of motion is just new paint offsets/opacities.
    final Widget expandedBackground = RepaintBoundary(
      child: () {
        if (useBlur && song.artPath != null) {
          return Stack(
            fit: StackFit.expand,
            children: [
              BlurredBackgroundArt(song: song),
              ColoredBox(color: Colors.black.withValues(alpha: musicDarkness)),
            ],
          );
        } else if (settings.enablePlayerGradient) {
          return PlayerGradientBackground(
            darkness: musicDarkness,
            animated: settings.animatePlayerGradient,
            followExpandProgress: true,
          );
        }
        return ColoredBox(color: Theme.of(context).colorScheme.surface);
      }(),
    );

    // Taps on the mini bar only - the expanded player's own buttons handle
    // theirs, and an ancestor tap recognizer over them only delayed their
    // press feedback and turned taps on empty space into play/pause.
    final Widget miniContent = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapUp: (details) {
        if (_isDragging) return;
        if (details.localPosition.dx > _geometry(windowSize).miniWidth * 0.75) {
          HapticFeedback.lightImpact();
          ref.read(playbackProvider.notifier).togglePlay();
        } else {
          _pushExpandedPlayer(context, settings);
        }
      },
      child: RepaintBoundary(
        child: _buildMiniPlayerContent(
          song,
          isPlaying,
          useBlur,
          Colors.transparent,
          0.0,
          settings,
        ),
      ),
    );
    const Widget expandedPlayer = RepaintBoundary(
      child: AndroidExpandedPlayer(),
    );

    // Morphing album art target. The real artwork's measured rect (reported
    // by PositionReporter/playerArtworkRectProvider once AndroidExpandedPlayer
    // has fully expanded at least once) so the handoff at p > 0.99 lands
    // exactly where the real widget renders; before it's ever been measured
    // (the very first expand after launch), an approximation. In landscape
    // the rect is a pure function of the window (PlayerLandscapeMetrics) -
    // the measurement is only ever taken in portrait and would be stale
    // after a rotation.
    final bool isLandscape = Responsive.isLandscape(windowSize);
    final Rect expandedSlotRect = () {
      final Rect? measured = isLandscape
          ? PlayerLandscapeMetrics.of(
              windowSize,
              MediaQuery.paddingOf(context),
            ).artRect
          : ref.watch(playerArtworkRectProvider);
      if (measured != null) return measured;
      final double topPadding = MediaQuery.paddingOf(context).top;
      final double size = windowSize.width - 40.0;
      final double availableHeight =
          windowSize.height - topPadding - 56.0 - 380.0;
      return Rect.fromLTWH(
        20.0,
        topPadding +
            56.0 +
            (availableHeight - size).clamp(0.0, double.infinity) / 2,
        size,
        size,
      );
    }();
    // The real artwork sits inset in that square slot while paused; land on
    // the art itself, or the handoff jumps by the inset.
    final Rect expandedArtRect = expandedSlotRect.deflate(
      GestureArtworkWithFeedback.inset(isPlaying: isPlaying),
    );

    // Laid out once at the expanded size; the morph only scales it (a
    // Transform), so no per-frame relayout. Decoded at exactly the width
    // ForegroundAlbumArt uses, so both share one ImageCache entry - kept
    // alive by the always-mounted real artwork - and the morph, remounted at
    // the start of every collapse, paints on its first frame (no blank
    // frame after a cache eviction) with the same pixels as the real art.
    Widget? morphImage;
    Widget? morphPlayingIcon;
    if (song.artPath != null) {
      final double dpr = MediaQuery.maybeDevicePixelRatioOf(context) ?? 2.0;
      final double decodeWidth = isLandscape
          ? expandedSlotRect.width
          : windowSize.width;
      morphImage = OptimizedImage(
        imagePath: !song.artPath!.startsWith('http') ? song.artPath : null,
        imageUrl: song.artPath!.startsWith('http') ? song.artPath : null,
        fit: BoxFit.cover,
        cacheWidth: (decodeWidth * dpr).toInt(),
      );
      // GIF frame decoding doesn't respect TickerMode - skip it while
      // ticking is paused (e.g. mid route transition).
      morphPlayingIcon = TickerMode.of(context)
          ? Image.asset(
              'assets/android_icons/Playing.gif',
              width: 24,
              height: 24,
              color: Colors.white,
            )
          : const SizedBox(width: 24, height: 24);
    }

    return GestureDetector(
      // Only the drag lives up here; taps are handled by the mini bar and
      // the expanded player's own controls.
      onPanStart: (details) {
        _isDragging = true;
        _dragController.stop();
      },
      onPanUpdate: (details) {
        final double travel = _geometry(windowSize).travel;
        _dragController.value -= details.delta.dy / travel;
      },
      onPanEnd: (details) {
        _isDragging = false;
        final FluidPlayerGeometry geometry = _geometry(windowSize);
        final double dy = details.velocity.pixelsPerSecond.dy;
        final double target;
        if (dy < -200) {
          target = 1.0;
        } else if (dy > 200) {
          target = 0.0;
        } else {
          target = _dragController.value > 0.4 ? 1.0 : 0.0;
        }
        _settle(target, velocity: geometry.progressVelocity(dy));
      },
      onPanCancel: () {
        if (!_isDragging) return;
        _isDragging = false;
        _settle(_dragController.value > 0.4 ? 1.0 : 0.0);
      },
      child: AnimatedBuilder(
        animation: Listenable.merge([_expandProgress, _restController]),
        builder: (context, _) {
          final double p = _expandProgress.value;
          final FluidPlayerGeometry geometry = _geometry(windowSize);
          final Rect panel = geometry.panelRect(p);
          final RRect panelRRect = RRect.fromRectAndRadius(
            panel,
            const Radius.circular(FluidPlayerGeometry.panelRadius),
          );
          final double shadowAlpha = 0.3 * (1.0 - p * 5.0).clamp(0.0, 1.0);

          return Stack(
            fit: StackFit.expand,
            children: [
              // Shadow + hairline border of the panel. Fades out in the
              // first 20% so the blurred shadow isn't redrawn across a
              // screen-sized rect for the whole motion.
              if (p < 0.99)
                Positioned.fromRect(
                  rect: panel,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(
                          FluidPlayerGeometry.panelRadius,
                        ),
                        border: Border.all(
                          color: Colors.white.withValues(
                            alpha: 0.05 * (1.0 - p),
                          ),
                          width: 1.2,
                        ),
                        boxShadow: shadowAlpha > 0
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(
                                    alpha: shadowAlpha,
                                  ),
                                  blurRadius: 15,
                                  spreadRadius: 2,
                                ),
                              ]
                            : null,
                      ),
                    ),
                  ),
                ),
              ClipRRect(
                clipper: _FluidPanelClipper(panelRRect),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // 1. Minimized background. Faded through its color and
                    // blur strength rather than an Opacity: a BackdropFilter
                    // under an Opacity forces an extra offscreen pass.
                    if (p < 0.99)
                      Positioned.fill(
                        key: const ValueKey('fluid_bg_minimized'),
                        child: () {
                          final Widget fill = ColoredBox(
                            color: minimizedBgColor.withValues(
                              alpha: minimizedBgColor.a * (1.0 - p),
                            ),
                          );
                          if (!isBlurActive) return fill;
                          return BackdropFilter(
                            filter: ImageFilter.blur(
                              sigmaX: 3.0 * (1.0 - p),
                              sigmaY: 3.0 * (1.0 - p),
                            ),
                            child: fill,
                          );
                        }(),
                      ),

                    // 2. Expanded background, pinned to the screen.
                    Positioned.fill(
                      key: const ValueKey('fluid_bg_expanded'),
                      child: _fluidLayer(
                        visible: p > 0.01,
                        tickers: p > 0.01,
                        child: Opacity(opacity: p, child: expandedBackground),
                      ),
                    ),

                    // 3. Mini bar content, riding the panel's top-left corner.
                    Positioned(
                      key: const ValueKey('fluid_mini'),
                      left: 0,
                      top: 0,
                      width: geometry.miniWidth,
                      height: FluidPlayerGeometry.miniHeight,
                      child: Transform.translate(
                        offset: geometry.miniOrigin(p),
                        child: _fluidLayer(
                          visible: p < 0.34,
                          tickers: p < 0.34,
                          child: Opacity(
                            opacity: (1.0 - p * 3.0).clamp(0.0, 1.0),
                            child: miniContent,
                          ),
                        ),
                      ),
                    ),

                    // 4. Expanded player, pinned to the screen. Kept mounted
                    // while collapsed so expanding never builds it, decodes
                    // its images or loads its icons mid-motion; its tickers
                    // (squiggle, marquee) only run once it has settled open.
                    Positioned.fill(
                      key: const ValueKey('fluid_expanded'),
                      child: _fluidLayer(
                        visible: p > 0.01,
                        tickers: p >= 0.99,
                        child: expandedPlayer,
                      ),
                    ),

                    // 5. Morphing album art (flying/scaling between layouts).
                    if (morphImage != null && p < 0.99)
                      () {
                        final Rect art = geometry.morphArtRect(
                          p,
                          expandedArtRect,
                        );
                        final double scale = art.width / expandedArtRect.width;
                        // The real artwork's drop shadow, faded in over the
                        // last stretch so it doesn't pop in at the handoff.
                        // In the unscaled box, like the radius.
                        final double shadowT = ((p - 0.6) / 0.39)
                            .clamp(0.0, 1.0)
                            .toDouble();
                        return Positioned(
                          key: const ValueKey('fluid_morph_art'),
                          left: 0,
                          top: 0,
                          width: expandedArtRect.width,
                          height: expandedArtRect.height,
                          child: IgnorePointer(
                            child: Transform(
                              transform: Matrix4.translationValues(
                                art.left,
                                art.top,
                                0,
                              )..scaleByDouble(scale, scale, 1.0, 1.0),
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(
                                    FluidPlayerGeometry.morphArtRadius(p) /
                                        scale,
                                  ),
                                  boxShadow: shadowT > 0
                                      ? [
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.4 * shadowT,
                                            ),
                                            blurRadius: 16 / scale,
                                            spreadRadius: -6 / scale,
                                            offset: Offset(0, 10 / scale),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: ClipRRect(
                                  // Radius is in the unscaled box, so divide
                                  // by the scale to get the on-screen radius.
                                  borderRadius: BorderRadius.circular(
                                    FluidPlayerGeometry.morphArtRadius(p) /
                                        scale,
                                  ),
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      morphImage!,
                                      if (morphPlayingIcon != null && p < 0.25)
                                        Positioned.fill(
                                          child: AnimatedOpacity(
                                            duration: const Duration(
                                              milliseconds: 300,
                                            ),
                                            opacity: isPlaying ? 1.0 : 0.0,
                                            child: Opacity(
                                              opacity: (1.0 - p * 4.0).clamp(
                                                0.0,
                                                1.0,
                                              ),
                                              child: ColoredBox(
                                                color: Colors.black.withValues(
                                                  alpha: 0.4,
                                                ),
                                                child: Center(
                                                  child: Transform.scale(
                                                    scale: 1.0 / scale,
                                                    child: morphPlayingIcon,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }(),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  FluidPlayerGeometry _geometry(Size windowSize) => FluidPlayerGeometry(
    screenSize: windowSize,
    restingBottom: _restingBottom,
  );

  // A Fluid Player layer that stays mounted when hidden: not painted or hit
  // tested, its Heroes left out of route transitions (the expanded player
  // shares hero tags with the lyrics screen), and its tickers paused unless
  // [tickers] says otherwise.
  Widget _fluidLayer({
    required bool visible,
    required bool tickers,
    required Widget child,
  }) {
    return Offstage(
      offstage: !visible,
      child: TickerMode(
        enabled: visible && tickers,
        child: HeroMode(enabled: visible, child: child),
      ),
    );
  }
}

// Clips the Fluid Player's full-screen layer to the panel. Given a clipper,
// RenderClipRRect also hit-tests against the clip, so touches outside the
// panel fall through to the screen behind.
class _FluidPanelClipper extends CustomClipper<RRect> {
  const _FluidPanelClipper(this.rrect);

  final RRect rrect;

  @override
  RRect getClip(Size size) => rrect;

  @override
  bool shouldReclip(_FluidPanelClipper oldClipper) => oldClipper.rrect != rrect;
}
