import 'dart:ui';

import 'package:looper_player/core/utils/song_metadata.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/rendering.dart';
import 'package:looper_player/core/utils/motion.dart';
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

import 'fluid_player_motion.dart';
import '../../widgets/premium_section.dart';

import 'package:looper_player/core/utils/l10n.dart';
import 'package:looper_player/ui/widgets/common/song_playback_overlay.dart';
import 'package:looper_player/core/services/haptics/app_haptics.dart';
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
  // Classic bar (Fluid Player off): finger travel of the current drag, and
  // the bar's shown offset - the finger through a rubber band while held,
  // then a bouncy spring back to rest on release.
  Offset _dragOffset = Offset.zero;
  late final AnimationController _barX;
  late final AnimationController _barY;
  static const double _barStretchX = 120.0;
  static const double _barStretchY = 60.0;
  static final SpringDescription _barBounceSpring =
      SpringDescription.withDampingRatio(
        mass: 1.0,
        stiffness: 420.0,
        ratio: 0.5,
      );
  bool _isDragging = false;
  bool _isPushing = false;
  // Pointer that caught the panel mid-flight, until it lifts.
  int? _catchPointer;
  // Drag-down dismiss (collapsed mini bar): 0..1 slide-out + fade, starting
  // from the sink [_dismissFrom] (px) the finger left it at.
  late final AnimationController _dismissController;
  double _dismissFrom = 0.0;

  @override
  void initState() {
    super.initState();
    _expandProgress = ref.read(playerExpandProgressProvider);
    // Unbounded: values past 0..1 are the finger's (or a bounce's) overshoot
    // beyond an end, shown as rubber-band stretch (FluidPlayerGeometry
    // .stretchOf). Everything else only ever sees the clamped progress.
    _dragController = AnimationController.unbounded(
      vsync: this,
      value: _expandProgress.value,
    )..addListener(_onExpandTick);
    _barX = AnimationController.unbounded(vsync: this);
    _barY = AnimationController.unbounded(vsync: this);
    _restFrom = _restTo = widget.restingBottom;
    _dismissController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );
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

  // Settles the Fluid Player open/closed on a spring started from the
  // finger's velocity (progress units/s), so letting go never jumps in
  // speed. snapToEnd lands exactly on 0/1, so settled layers end at opacity
  // 1.0 (no leftover compositing layer) and the handoffs always fire.
  //
  // Every open and close bounces (taps, throws, back button): the whole
  // sheet carries a little past the end - shown as rubber-band stretch - and
  // settles back once. Opening lifts the full player, minimizing dips the
  // mini bar under its rest. Releases from inside a stretch, a caught panel
  // let go without a drag, and reduced motion land dead.
  void _settle(
    double target, {
    double velocity = 0.0,
    bool allowBounce = true,
  }) {
    final double r = _dragController.value;
    final double v = velocity.clamp(-8.0, 8.0).toDouble();
    final bool bounce =
        allowBounce && r >= 0.0 && r <= 1.0 && r != target && !Motion.reduced;
    _dragController.animateWith(
      SpringSimulation(
        !bounce
            ? fluidPlayerSpring
            : target == 1.0
            ? fluidPlayerOpenBounceSpring
            : fluidPlayerCloseBounceSpring,
        r,
        target,
        v,
        snapToEnd: true,
      ),
    );
  }

  // Drag-down dismiss of the collapsed mini bar (as in the classic bar):
  // it slides the rest of the way off the bottom and fades, then the queue
  // is cleared. Reset to rest once the bar has gone (see build).
  void _dismiss(FluidPlayerGeometry geometry) {
    _dragController.stop();
    _dismissFrom = -geometry.stretchOf(_dragController.value);
    AppHaptics.medium();
    _dismissController.forward(from: 0.0).then((_) {
      if (!mounted) return;
      ref.read(playbackProvider.notifier).clearQueue();
    });
  }

  // Release target: from inside a stretch, always back to the stretched end
  // (a rubber band, so a small flick while letting go never flips it);
  // otherwise velocity first, then position.
  double _releaseTarget(double pixelsPerSecondDy) {
    final double r = _dragController.value;
    if (r > 1.0) return 1.0;
    if (r < 0.0) return 0.0;
    if (pixelsPerSecondDy < -200) return 1.0;
    if (pixelsPerSecondDy > 200) return 0.0;
    return r > 0.4 ? 1.0 : 0.0;
  }

  // Runs every animation frame / drag event. Only feeds the shared notifier -
  // nothing here may call setState, or the whole bar rebuilds per frame.
  void _onExpandTick() {
    final double next = FluidPlayerGeometry.progressOf(_dragController.value);
    if (next == _expandProgress.value) return;
    dismissFocusWhenPlayerExpands(_expandProgress.value, next);
    _expandProgress.value = next;
  }

  @override
  void dispose() {
    _dragController.dispose();
    _restController.dispose();
    _dismissController.dispose();
    _barX.dispose();
    _barY.dispose();
    super.dispose();
  }

  static double _band(double x, double d) =>
      x < 0 ? -rubberBand(-x, d) : rubberBand(x, d);

  static double _unband(double y, double d) =>
      y < 0 ? -inverseRubberBand(-y, d) : inverseRubberBand(y, d);

  // Classic bar released: springs back to rest with a visible wobble (or
  // dead, under reduced motion), carrying the finger's shown velocity.
  void _springBarBack(double vx, double vy) {
    final SpringDescription spring = Motion.reduced
        ? fluidPlayerSpring
        : _barBounceSpring;
    _barX.animateWith(
      SpringSimulation(spring, _barX.value, 0.0, vx, snapToEnd: true),
    );
    _barY.animateWith(
      SpringSimulation(spring, _barY.value, 0.0, vy, snapToEnd: true),
    );
  }

  void _triggerHaptic() {
    AppHaptics.light();
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

    if (song == null) {
      // Dismissed: put the bar back at rest, hidden, for the next song.
      if (_dismissController.value != 0.0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _dismissController.value = 0.0;
          _dragController.value = 0.0;
        });
      }
      return const SizedBox.shrink();
    }

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
            _isDragging = true;
            // Catching the bar mid-bounce continues from where it is.
            _barX.stop();
            _barY.stop();
            _dragOffset = Offset(
              _unband(_barX.value, _barStretchX),
              _unband(_barY.value, _barStretchY),
            );
          },
          onPanUpdate: (details) {
            _dragOffset += details.delta;
            _barX.value = _band(_dragOffset.dx, _barStretchX);
            _barY.value = _band(_dragOffset.dy, _barStretchY);
          },
          onPanEnd: (details) {
            _isDragging = false;
            final dx = _dragOffset.dx;
            final dy = _dragOffset.dy;

            if (dy > 70 && dy.abs() > dx.abs()) {
              AppHaptics.medium();
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

            final Offset v = details.velocity.pixelsPerSecond;
            _springBarBack(
              v.dx * rubberBandSlope(dx.abs(), _barStretchX),
              v.dy * rubberBandSlope(dy.abs(), _barStretchY),
            );
            _dragOffset = Offset.zero;
          },
          onPanCancel: () {
            _isDragging = false;
            _dragOffset = Offset.zero;
            _springBarBack(0.0, 0.0);
          },
          onTapUp: (details) {
            if (_isDragging) return;

            final RenderBox box = context.findRenderObject() as RenderBox;
            final localX = details.localPosition.dx;
            final width = box.size.width;

            if (localX > width * 0.75) {
              AppHaptics.light();
              ref.read(playbackProvider.notifier).togglePlay();
            } else {
              _pushExpandedPlayer(context, settings);
            }
          },
          child: AnimatedBuilder(
            animation: Listenable.merge([_barX, _barY]),
            builder: (context, child) {
              final double ox = _barX.value;
              final double oy = _barY.value;
              if (ox == 0.0 && oy == 0.0) return child!;
              final double tiltX = (ox / 190).clamp(-0.2, 0.2);
              final double tiltY = (oy / 150).clamp(-0.1, 0.1);

              final matrix = Matrix4.identity()
                ..setEntry(3, 2, 0.001) // perspective
                ..rotateX(-tiltY)
                ..rotateY(tiltX)
                ..translateByDouble(ox, oy, 0.0, 1.0);

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
          AppHaptics.light();
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
      morphPlayingIcon = SongPlaybackIndicator(isPlaying: isPlaying);
    }

    // Catch: a finger landing on the moving panel stops it on that frame
    // (a Listener, so no gesture-arena delay). The _CatchShield below
    // swallows that touch, so catching never also taps a button or the
    // mini bar; dragging from there continues from the frozen spot.
    return Listener(
      onPointerDown: (event) {
        if (_dismissController.isAnimating) return;
        if (_dragController.isAnimating) {
          _dragController.stop();
          _catchPointer = event.pointer;
        }
      },
      onPointerUp: (event) => _releaseCatch(event.pointer),
      onPointerCancel: (event) => _releaseCatch(event.pointer),
      child: GestureDetector(
        // Only the drag lives up here; taps are handled by the mini bar and
        // the expanded player's own controls.
        onPanStart: (details) {
          _isDragging = true;
          _dragController.stop();
        },
        onPanUpdate: (details) {
          // Linear in the unbounded position; past an end the overshoot is
          // damped on output (stretchOf), which gives the rubber band.
          final double travel = _geometry(windowSize).travel;
          _dragController.value -= details.delta.dy / travel;
        },
        onPanEnd: (details) {
          _isDragging = false;
          final FluidPlayerGeometry geometry = _geometry(windowSize);
          final double dy = details.velocity.pixelsPerSecond.dy;
          // Pushed down past the collapsed bar: far enough (finger 70 px,
          // like the classic bar) or flicked down -> dismiss the player.
          final double r = _dragController.value;
          if (r < 0.0 && (-r * geometry.travel > 70.0 || dy > 700.0)) {
            _dismiss(geometry);
            return;
          }
          _settle(_releaseTarget(dy), velocity: geometry.progressVelocity(dy));
        },
        onPanCancel: () {
          if (!_isDragging) return;
          _isDragging = false;
          _settle(_releaseTarget(0.0), allowBounce: false);
        },
        child: AnimatedBuilder(
          animation: _dismissController,
          builder: (context, child) {
            final double t = _dismissController.value;
            if (t == 0.0) return child!;
            return Opacity(
              opacity: 1.0 - Curves.easeIn.transform(t),
              child: child,
            );
          },
          child: AnimatedBuilder(
            animation: Listenable.merge([
              _dragController,
              _restController,
              _dismissController,
            ]),
            builder: (context, _) {
              final double r = _dragController.value;
              final double p = FluidPlayerGeometry.progressOf(r);
              final FluidPlayerGeometry geometry = _geometry(windowSize);
              final double dismissT = Curves.easeInCubic.transform(
                _dismissController.value,
              );
              final double stretch = dismissT > 0
                  ? -lerpDouble(_dismissFrom, geometry.dismissTravel, dismissT)!
                  : geometry.stretchOf(r);
              final double lift = stretch > 0 ? stretch : 0.0;
              final Rect panel = geometry.panelRect(p, stretch: stretch);
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
                  if (p < kFluidHandoff)
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
                    child: // While the panel moves its content leaves the accessibility
                        // tree: one update at each end instead of every node's
                        // geometry recomputed every frame (~10 ms a frame on
                        // phones with any accessibility service on, e.g. a
                        // password manager).
                        ExcludeSemantics(
                          excluding: p > 0.01 && p < kFluidHandoff,
                          child: _CatchShield(
                            absorb: () =>
                                _dragController.isAnimating ||
                                _dismissController.isAnimating ||
                                _catchPointer != null,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                // 1. Minimized background. Faded through its color and
                                // blur strength rather than an Opacity: a BackdropFilter
                                // under an Opacity forces an extra offscreen pass.
                                if (p < kFluidHandoff)
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

                                // 2. Expanded background, pinned to the screen. Laid out
                                // taller than the screen so lifting it with the open-end
                                // stretch never exposes a strip at the bottom.
                                Positioned(
                                  key: const ValueKey('fluid_bg_expanded'),
                                  left: 0,
                                  top: 0,
                                  right: 0,
                                  bottom: -geometry.stretchOpenMax,
                                  child: Transform.translate(
                                    offset: Offset(0, -lift),
                                    child: _fluidLayer(
                                      visible: p > 0.01,
                                      tickers: p > 0.01,
                                      child: Opacity(
                                        opacity: p,
                                        child: expandedBackground,
                                      ),
                                    ),
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
                                    offset: geometry.miniOrigin(
                                      p,
                                      stretch: stretch,
                                    ),
                                    child: _fluidLayer(
                                      visible: p < 0.34,
                                      tickers: p < 0.34,
                                      child: Opacity(
                                        opacity: (1.0 - p * 3.0).clamp(
                                          0.0,
                                          1.0,
                                        ),
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
                                  child: Transform.translate(
                                    offset: Offset(0, -lift),
                                    // Tickers on as soon as it shows: Riverpod
                                    // pauses a widget's subscriptions while its
                                    // TickerMode is off, so holding them until
                                    // p >= 0.99 kept the player on stale state
                                    // (old seek position, old layout) through the
                                    // whole open, then it snapped after landing.
                                    child: _fluidLayer(
                                      visible: p > 0.01,
                                      tickers: p > 0.01,
                                      child: expandedPlayer,
                                    ),
                                  ),
                                ),

                                // 5. Morphing album art (flying/scaling between layouts).
                                if (morphImage != null && p < kFluidHandoff)
                                  () {
                                    final Rect art = geometry.morphArtRect(
                                      p,
                                      expandedArtRect,
                                      stretch: stretch,
                                    );
                                    final double scale =
                                        art.width / expandedArtRect.width;
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
                                          transform:
                                              Matrix4.translationValues(
                                                art.left,
                                                art.top,
                                                0,
                                              )..scaleByDouble(
                                                scale,
                                                scale,
                                                1.0,
                                                1.0,
                                              ),
                                          child: DecoratedBox(
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(
                                                FluidPlayerGeometry.morphArtRadius(
                                                      p,
                                                    ) /
                                                    scale,
                                              ),
                                              boxShadow: shadowT > 0
                                                  ? [
                                                      BoxShadow(
                                                        color: Colors.black
                                                            .withValues(
                                                              alpha:
                                                                  0.4 * shadowT,
                                                            ),
                                                        blurRadius: 16 / scale,
                                                        spreadRadius:
                                                            -6 / scale,
                                                        offset: Offset(
                                                          0,
                                                          10 / scale,
                                                        ),
                                                      ),
                                                    ]
                                                  : null,
                                            ),
                                            child: ClipRRect(
                                              // Radius is in the unscaled box, so divide
                                              // by the scale to get the on-screen radius.
                                              borderRadius: BorderRadius.circular(
                                                FluidPlayerGeometry.morphArtRadius(
                                                      p,
                                                    ) /
                                                    scale,
                                              ),
                                              child: Stack(
                                                fit: StackFit.expand,
                                                children: [
                                                  morphImage!,
                                                  if (morphPlayingIcon !=
                                                          null &&
                                                      p < 0.25)
                                                    Positioned.fill(
                                                      child: Opacity(
                                                        opacity: (1.0 - p * 4.0)
                                                            .clamp(0.0, 1.0),
                                                        child: ColoredBox(
                                                          color: Colors.black
                                                              .withValues(
                                                                alpha:
                                                                    SongPlaybackOverlay
                                                                        .dimAlpha,
                                                              ),
                                                          child: Center(
                                                            child: Transform.scale(
                                                              scale:
                                                                  1.0 / scale,
                                                              child:
                                                                  morphPlayingIcon,
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
                        ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // The catching pointer lifted. If it never dragged, settle from where it
  // was caught (no bounce); a drag already settled in onPanEnd. Runs before
  // the recognizers see the up event, hence the _isDragging check.
  void _releaseCatch(int pointer) {
    if (_catchPointer != pointer) return;
    _catchPointer = null;
    if (_isDragging) return;
    _settle(_releaseTarget(0.0), allowBounce: false);
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

// Swallows a touch (counts it as hit, but hides it from the panel's own
// buttons and taps) while [absorb] says so - checked at hit-test time, which
// is before the Listener above sees the pointer-down. Ancestors (the drag
// GestureDetector) still get it.
class _CatchShield extends SingleChildRenderObjectWidget {
  const _CatchShield({required this.absorb, super.child});

  final bool Function() absorb;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderCatchShield(absorb);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderCatchShield renderObject,
  ) {
    renderObject.absorb = absorb;
  }
}

class _RenderCatchShield extends RenderProxyBox {
  _RenderCatchShield(this.absorb);

  bool Function() absorb;

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (absorb()) {
      if (!size.contains(position)) return false;
      result.add(BoxHitTestEntry(this, position));
      return true;
    }
    return super.hitTest(result, position: position);
  }
}
