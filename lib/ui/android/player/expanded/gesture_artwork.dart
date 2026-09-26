import 'dart:io';

import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:looper_player/core/theme/app_fonts.dart';
import 'package:looper_player/core/services/storage/db_service.dart';
import 'package:looper_player/l10n/app_localizations.dart';
import 'package:looper_player/features/library/domain/models/models.dart';
import 'package:looper_player/features/settings/presentation/providers/settings_notifier.dart';
import 'package:looper_player/core/utils/responsive.dart';
import 'package:looper_player/features/playback/presentation/providers/playback/playback_notifier.dart';
import 'package:looper_player/ui/widgets/common/optimized_image.dart';

import 'player_landscape_layout.dart';

import 'package:looper_player/core/providers/player_expand_provider.dart';

import 'android_expanded_player.dart';

class GestureArtworkWithFeedback extends ConsumerStatefulWidget {
  final Song song;
  final VoidCallback onTap;

  const GestureArtworkWithFeedback({
    super.key,
    required this.song,
    required this.onTap,
  });

  /// How far the artwork is inset in its square slot: it shrinks slightly
  /// while paused. The Fluid Player's morphing art lands on the same rect.
  static double inset({required bool isPlaying}) => isPlaying ? 0.0 : 2.0;

  @override
  ConsumerState<GestureArtworkWithFeedback> createState() =>
      _GestureArtworkWithFeedbackState();
}

class _GestureArtworkWithFeedbackState
    extends ConsumerState<GestureArtworkWithFeedback>
    with TickerProviderStateMixin {
  String? _feedbackType; // 'rewind', 'forward', 'next', 'previous'
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _snapController;
  bool _isNext = true;
  double _dragOffset = 0.0;
  bool _skipSlideTransition = false;
  bool _isSwipeTriggered = false;

  // Precaching the next/previous song's artwork does a synchronous
  // File.existsSync() stat call - build() used to run on every frame while
  // the user dragged to expand/collapse the player, so without this guard
  // that stat call happened every frame instead of only when the neighbor
  // song actually changes. (build() no longer depends on the expand
  // progress - only the Opacity wrapper below does - but the guard still
  // saves the stat on playback-driven rebuilds.)
  String? _precachedNextArtPath;
  String? _precachedPrevArtPath;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _snapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
  }

  @override
  void didUpdateWidget(GestureArtworkWithFeedback oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.song.path != widget.song.path) {
      if (_isSwipeTriggered ||
          _dragOffset.abs() > 10.0 ||
          _snapController.isAnimating) {
        _skipSlideTransition = true;
        _isSwipeTriggered = false;
      } else {
        _skipSlideTransition = false;
      }
      setState(() {
        _dragOffset = 0.0;
      });
      // Safely extract queue indexes to determine slide direction
      final queue = ref.read(playbackProvider).queue;
      final oldIdx = queue.indexWhere((s) => s.path == oldWidget.song.path);
      final newIdx = queue.indexWhere((s) => s.path == widget.song.path);
      if (oldIdx != -1 && newIdx != -1) {
        setState(() {
          _isNext = newIdx >= oldIdx;
        });
      }
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _snapController.dispose();
    super.dispose();
  }

  void _triggerFeedback(String type) {
    if (!mounted) return;
    setState(() {
      _feedbackType = type;
    });
    _fadeController.forward(from: 0.0).then((_) {
      if (mounted) {
        setState(() {
          _feedbackType = null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(settingsProvider);
    final enableSlide = settings.enableSlideGesture;
    final isPlaying = ref.watch(playbackProvider.select((s) => s.isPlaying));
    final double targetPadding = GestureArtworkWithFeedback.inset(
      isPlaying: isPlaying,
    );
    // While the Fluid Player is collapsed or moving, this artwork is hidden
    // (the morphing art stands in) and its tickers are paused. A song change
    // or play/pause then has to land instantly: a paused transition would
    // sit at its first frame and flash the old art (or the old inset) on the
    // handoff frame before jumping to the end.
    final bool animate = TickerMode.of(context);
    final queue = ref.watch(playbackProvider.select((s) => s.queue));
    final repeatMode = ref.watch(playbackProvider.select((s) => s.repeatMode));
    final currentIdx = queue.indexWhere((s) => s.path == widget.song.path);

    Song? nextSong;
    Song? prevSong;

    if (currentIdx != -1) {
      if (currentIdx + 1 < queue.length) {
        nextSong = queue[currentIdx + 1];
      } else if (repeatMode == RepeatMode.all && queue.isNotEmpty) {
        nextSong = queue[0];
      }

      if (currentIdx - 1 >= 0) {
        prevSong = queue[currentIdx - 1];
      } else if (repeatMode == RepeatMode.all && queue.isNotEmpty) {
        prevSong = queue[queue.length - 1];
      }
    }

    // Swipe distances and decode size follow the artwork's own width: the full
    // window width in portrait (unchanged), but in landscape the artwork is a
    // small square beside the controls, where the window width would demand a
    // ~3x longer swipe and decode a needlessly large bitmap.
    final Size screenSize = MediaQuery.sizeOf(context);
    final PlayerLandscapeMetrics? landscape = Responsive.isLandscape(screenSize)
        ? PlayerLandscapeMetrics.of(screenSize, MediaQuery.paddingOf(context))
        : null;
    final bool isLandscape = landscape != null;
    final double slideExtent = landscape?.artSlideExtent ?? screenSize.width;
    final artSize = landscape?.artRect.width ?? slideExtent - 48;
    final double dpr = MediaQuery.maybeDevicePixelRatioOf(context) ?? 2.0;
    final int computedCacheWidth = (artSize * dpr).toInt();

    final artworkSwitcher = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.04),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 16,
            spreadRadius: -6,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AnimatedSwitcher(
          duration: animate ? const Duration(milliseconds: 320) : Duration.zero,
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
            return Stack(
              alignment: Alignment.center,
              children: <Widget>[
                ...previousChildren,
                if (currentChild != null) currentChild,
              ],
            );
          },
          transitionBuilder: (Widget child, Animation<double> animation) {
            final keyVal = child.key is ValueKey<String>
                ? (child.key as ValueKey<String>).value
                : '';
            final isIncoming = keyVal == widget.song.path;

            if (_skipSlideTransition) {
              if (isIncoming) {
                return SlideTransition(
                  position: const AlwaysStoppedAnimation<Offset>(Offset.zero),
                  child: child,
                );
              } else {
                final double offset = _isNext ? -1.1 : 1.1;
                return SlideTransition(
                  position: AlwaysStoppedAnimation<Offset>(Offset(offset, 0.0)),
                  child: FadeTransition(
                    opacity: Tween<double>(
                      begin: 1.0,
                      end: 0.0,
                    ).animate(animation),
                    child: child,
                  ),
                );
              }
            }

            Offset beginOffset;
            Offset endOffset;

            if (_isNext) {
              beginOffset = isIncoming
                  ? const Offset(1.1, 0.0)
                  : const Offset(-1.1, 0.0);
              endOffset = Offset.zero;
            } else {
              beginOffset = isIncoming
                  ? const Offset(-1.1, 0.0)
                  : const Offset(1.1, 0.0);
              endOffset = Offset.zero;
            }

            return SlideTransition(
              position: Tween<Offset>(
                begin: beginOffset,
                end: endOffset,
              ).animate(animation),
              child: child,
            );
          },
          child: ForegroundAlbumArt(
            key: ValueKey<String>(widget.song.path),
            song: widget.song,
          ),
        ),
      ),
    );

    if (nextSong?.artPath != null &&
        nextSong!.artPath != _precachedNextArtPath) {
      _precachedNextArtPath = nextSong.artPath;
      if (File(nextSong.artPath!).existsSync()) {
        precacheImage(
          ResizeImage(
            FileImage(File(nextSong.artPath!)),
            width: computedCacheWidth,
          ),
          context,
        );
      }
    }
    if (prevSong?.artPath != null &&
        prevSong!.artPath != _precachedPrevArtPath) {
      _precachedPrevArtPath = prevSong.artPath;
      if (File(prevSong.artPath!).existsSync()) {
        precacheImage(
          ResizeImage(
            FileImage(File(prevSong.artPath!)),
            width: computedCacheWidth,
          ),
          context,
        );
      }
    }
    final dragPercent = (_dragOffset / slideExtent).abs().clamp(0.0, 1.0);
    final Song? bgSong = _dragOffset < 0
        ? (nextSong ?? widget.song)
        : (_dragOffset > 0 ? (prevSong ?? widget.song) : null);

    return GestureDetector(
      onTap: widget.onTap,
      onDoubleTapDown: (details) {
        final box = context.findRenderObject() as RenderBox?;
        if (box == null) return;
        final localPos = box.globalToLocal(details.globalPosition);
        final isLeft = localPos.dx < box.size.width / 2;

        if (isLeft) {
          ref.read(playbackProvider.notifier).seekRelative(-10);
          _triggerFeedback('rewind');
        } else {
          ref.read(playbackProvider.notifier).seekRelative(10);
          _triggerFeedback('forward');
        }
      },
      onHorizontalDragUpdate: (details) {
        _snapController.stop();
        setState(() {
          _dragOffset += details.delta.dx;
        });
      },
      onHorizontalDragEnd: (details) {
        final threshold = slideExtent * 0.25;

        if (_dragOffset < -threshold ||
            (details.primaryVelocity != null &&
                details.primaryVelocity! < -300)) {
          // Swipe Left -> Skip Next
          if (nextSong == null) {
            final start = _dragOffset;
            final animation = Tween<double>(begin: start, end: 0.0).animate(
              CurvedAnimation(
                parent: _snapController,
                curve: Curves.elasticOut,
              ),
            );
            animation.addListener(() {
              setState(() {
                _dragOffset = animation.value;
              });
            });
            _snapController.forward(from: 0.0);
          } else {
            setState(() {
              _isNext = true;
              _isSwipeTriggered = true;
            });
            HapticFeedback.mediumImpact();
            final start = _dragOffset;
            final end = -slideExtent;
            final animation = Tween<double>(begin: start, end: end).animate(
              CurvedAnimation(
                parent: _snapController,
                curve: Curves.easeOutCubic,
              ),
            );
            animation.addListener(() {
              setState(() {
                _dragOffset = animation.value;
              });
            });
            _snapController.forward(from: 0.0).then((_) {
              ref.read(playbackProvider.notifier).skipNext();
            });
          }
        } else if (_dragOffset > threshold ||
            (details.primaryVelocity != null &&
                details.primaryVelocity! > 300)) {
          // Swipe Right -> Skip Previous
          if (prevSong == null) {
            final start = _dragOffset;
            final animation = Tween<double>(begin: start, end: 0.0).animate(
              CurvedAnimation(
                parent: _snapController,
                curve: Curves.elasticOut,
              ),
            );
            animation.addListener(() {
              setState(() {
                _dragOffset = animation.value;
              });
            });
            _snapController.forward(from: 0.0);
          } else {
            setState(() {
              _isNext = false;
              _isSwipeTriggered = true;
            });
            HapticFeedback.mediumImpact();
            final start = _dragOffset;
            final end = slideExtent;
            final animation = Tween<double>(begin: start, end: end).animate(
              CurvedAnimation(
                parent: _snapController,
                curve: Curves.easeOutCubic,
              ),
            );
            animation.addListener(() {
              setState(() {
                _dragOffset = animation.value;
              });
            });
            _snapController.forward(from: 0.0).then((_) {
              ref.read(playbackProvider.notifier).skipPrevious(force: true);
            });
          }
        } else {
          // Snap Back
          final start = _dragOffset;
          final animation = Tween<double>(begin: start, end: 0.0).animate(
            CurvedAnimation(parent: _snapController, curve: Curves.elasticOut),
          );
          animation.addListener(() {
            setState(() {
              _dragOffset = animation.value;
            });
          });
          _snapController.forward(from: 0.0);
        }
      },
      // Hidden while the Fluid Player's morphing art stands in for it. Only
      // this wrapper follows the expand progress; the artwork below is built
      // once per real change.
      child: ValueListenableBuilder<double>(
        valueListenable: ref.watch(playerExpandProgressProvider),
        builder: (context, expandProgress, child) {
          return Opacity(
            opacity: !enableSlide || expandProgress >= 0.99 ? 1.0 : 0.0,
            child: child,
          );
        },
        child: AnimatedPadding(
          duration: animate ? const Duration(milliseconds: 350) : Duration.zero,
          curve: Curves.easeInOutCubic,
          padding: EdgeInsets.all(targetPadding),
          child: _ArtCarouselFrame(
            clip: isLandscape,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background Card for real-time carousel transitions (flat horizontal slide)
                if (bgSong != null && _dragOffset.abs() > 1.0)
                  Positioned.fill(
                    child: Transform.translate(
                      offset: Offset(
                        _dragOffset < 0
                            ? _dragOffset + slideExtent
                            : _dragOffset - slideExtent,
                        0,
                      ),
                      child: ClipRRect(
                        // borderRadius: BorderRadius.circular(12),
                        child: OptimizedImage(
                          imagePath:
                              bgSong.artPath != null &&
                                  !bgSong.artPath!.startsWith('http')
                              ? bgSong.artPath
                              : null,
                          imageUrl:
                              bgSong.artPath != null &&
                                  bgSong.artPath!.startsWith('http')
                              ? bgSong.artPath
                              : null,
                          borderRadius: BorderRadius.circular(12),

                          fit: BoxFit.cover,
                          cacheWidth: isLandscape
                              ? computedCacheWidth
                              : (slideExtent * dpr).toInt(),
                        ),
                      ),
                    ),
                  ),

                // Active Sliding Artwork (flat horizontal slide)
                Positioned.fill(
                  child: Transform.translate(
                    offset: Offset(_dragOffset, 0),
                    child: enableSlide
                        ? artworkSwitcher
                        : Hero(tag: 'album_art', child: artworkSwitcher),
                  ),
                ),
                // Feedback Overlay
                if (_feedbackType != null)
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: AnimatedBuilder(
                        animation: _fadeAnimation,
                        builder: (context, child) {
                          final progress = _fadeAnimation.value;
                          final opacity = (1.0 - progress).clamp(0.0, 1.0);
                          final scale = 0.8 + (progress * 0.3);

                          Widget feedbackChild;
                          Alignment alignment = Alignment.center;

                          switch (_feedbackType) {
                            case 'rewind':
                              alignment = const Alignment(-0.5, 0.0);
                              feedbackChild = Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.replay_10_rounded,
                                    color: Colors.white,
                                    size: 48,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '-10s',
                                    style: AppFonts.jostStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              );
                              break;
                            case 'forward':
                              alignment = const Alignment(0.5, 0.0);
                              feedbackChild = Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.forward_10_rounded,
                                    color: Colors.white,
                                    size: 48,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '+10s',
                                    style: AppFonts.jostStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              );
                              break;
                            case 'next':
                              feedbackChild = Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.skip_next_rounded,
                                    color: Colors.white,
                                    size: 48,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    l10n.nextLabel,
                                    style: AppFonts.jostStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              );
                              break;
                            case 'previous':
                              feedbackChild = Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.skip_previous_rounded,
                                    color: Colors.white,
                                    size: 48,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    l10n.previousLabel,
                                    style: AppFonts.jostStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              );
                              break;
                            default:
                              feedbackChild = const SizedBox.shrink();
                          }

                          return Container(
                            color: Colors.black.withValues(
                              alpha: 0.35 * opacity,
                            ),
                            alignment: alignment,
                            child: Opacity(
                              opacity: opacity,
                              child: Transform.scale(
                                scale: scale,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black45,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: feedbackChild,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ArtCarouselFrame extends StatelessWidget {
  final bool clip;
  final Widget child;

  const _ArtCarouselFrame({required this.clip, required this.child});

  @override
  Widget build(BuildContext context) {
    if (!clip) return child;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 16,
            spreadRadius: -6,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(borderRadius: BorderRadius.circular(12), child: child),
    );
  }
}
