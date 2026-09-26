import 'dart:io';
import 'package:looper_player/core/utils/ui_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:looper_player/core/theme/app_fonts.dart';
import '../../../domain/lyric_models.dart';
import '../../screens/lyrics_view.dart';
import '../../providers/lyrics/lyrics_search_provider.dart';
import 'advanced_lyric_line/advanced_lyric_line.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:looper_player/features/playback/presentation/providers/playback/playback_notifier.dart';

import '../../providers/lyrics/lyrics_notifier.dart';
import '../../providers/lyrics/lyrics_selection_notifier.dart';
import 'package:looper_player/core/utils/l10n.dart';

class AdvancedLyricRenderer extends ConsumerStatefulWidget {
  final List<LyricLine> lines;
  final LyricsSyncMode mode;
  final Function(Duration) onSeek;

  const AdvancedLyricRenderer({
    super.key,
    required this.lines,
    required this.mode,
    required this.onSeek,
  });

  @override
  ConsumerState<AdvancedLyricRenderer> createState() =>
      _AdvancedLyricRendererState();
}

class _AdvancedLyricRendererState extends ConsumerState<AdvancedLyricRenderer> {
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _lineKeys = {};
  int _currentLineIndex = -1;
  double _fontScale = 1.0;
  double _baseScale = 1.0;

  // Pinch-to-zoom is tracked by hand from raw pointer events (via Listener)
  // instead of a GestureDetector's ScaleGestureRecognizer. A real scale
  // recognizer also tracks single-finger movement (that's why the old code
  // needed a `pointerCount >= 2` guard before applying it), and just by
  // entering the gesture arena it could occasionally out-compete a lyric
  // line's own tap recognizer for a single-finger touch, silently
  // swallowing the tap. A Listener never enters the arena at all, so a line
  // underneath it always gets a clean shot at recognizing its own tap.
  final Map<int, Offset> _activePointers = {};
  double? _pinchStartDistance;

  bool _transitionFinished = false;
  Animation<double>? _routeAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final currentPos = ref.read(playbackProvider).position;
        _updateActiveLine(currentPos, forceScroll: true);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    final animation = route?.animation;
    if (_routeAnimation != animation) {
      _routeAnimation?.removeStatusListener(_onRouteAnimationStatusChanged);
      _routeAnimation = animation;
      if (animation != null) {
        if (animation.isCompleted) {
          _transitionFinished = true;
          final currentPos = ref.read(playbackProvider).position;
          _updateActiveLine(currentPos, forceScroll: true);
        } else {
          _transitionFinished = false;
          animation.addStatusListener(_onRouteAnimationStatusChanged);
        }
      } else {
        _transitionFinished = true;
        final currentPos = ref.read(playbackProvider).position;
        _updateActiveLine(currentPos, forceScroll: true);
      }
    }
  }

  void _onRouteAnimationStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      if (mounted) {
        setState(() {
          _transitionFinished = true;
        });
        final currentPos = ref.read(playbackProvider).position;
        _updateActiveLine(currentPos, forceScroll: true);
      }
      _routeAnimation?.removeStatusListener(_onRouteAnimationStatusChanged);
    }
  }

  @override
  void didUpdateWidget(AdvancedLyricRenderer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lines != widget.lines) {
      _currentLineIndex = -1;
      _lineKeys.clear();
      // The lines changed (new song, or a different lyrics source/provider
      // was picked) — any in-progress share selection no longer points at
      // the right text, so drop it.
      ref.read(lyricsSelectionProvider.notifier).clear();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(lyricsManualScrollProvider.notifier).set(false);
        }
      });
    }
    final currentPos = ref.read(playbackProvider).position;
    _updateActiveLine(
      currentPos,
      forceScroll:
          oldWidget.mode != widget.mode || oldWidget.lines != widget.lines,
    );
  }

  void _updateActiveLine(Duration position, {bool forceScroll = false}) {
    final route = ModalRoute.of(context);
    final isExiting =
        route != null && route.animation?.status == AnimationStatus.reverse;
    if (isExiting) return;

    int index = widget.lines.indexWhere(
      (line) => position >= line.startTime && position < line.endTime,
    );

    if (index == -1 && widget.lines.isNotEmpty) {
      if (position < widget.lines.first.startTime) {
        index = 0;
      } else if (position >= widget.lines.last.endTime) {
        index = widget.lines.length - 1;
      }
    }

    final isManual = ref.read(lyricsManualScrollProvider);
    if (index != -1 && (index != _currentLineIndex || forceScroll)) {
      _currentLineIndex = index;
      if (!isManual || forceScroll) {
        _scrollToIndex(index, animate: _transitionFinished);
      }
      if (mounted) setState(() {});
    }
    // The active row's position within the viewport can change even
    // without the list itself moving - e.g. while manual scroll is
    // suppressing auto-follow, playback advancing to a different line
    // changes which row is "active" without the list scrolling to it. Runs
    // after this frame's layout so the new line's GlobalKey (if it just
    // became active) has an attached RenderBox to measure.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _checkActiveLineVisibility(),
    );
  }

  /// Updates lyricsActiveLineVisibleProvider based on whether the active
  /// line's row currently overlaps this renderer's own visible bounds (which
  /// match the list's viewport, since the ListView is this widget's only
  /// child) - used by AndroidLyricsScreen to only show its "re-sync" button
  /// once the active line has actually scrolled off screen, not on every
  /// scroll touch regardless of whether the line ever left view.
  DateTime _lastVisibilityCheck = DateTime.fromMillisecondsSinceEpoch(0);

  void _checkActiveLineVisibility() {
    if (!mounted || _currentLineIndex < 0) return;
    // Called from a ScrollNotification listener, which fires many times a
    // second during a drag/fling - the two RenderBox lookups below don't
    // need to run at that frequency for a boolean "is the active line on
    // screen" flag that only drives a re-sync button's visibility, so
    // coalesce to at most once every ~100ms (imperceptible for this UI).
    final now = DateTime.now();
    if (now.difference(_lastVisibilityCheck) <
        const Duration(milliseconds: 100)) {
      return;
    }
    _lastVisibilityCheck = now;
    final lineBox =
        _lineKeys[_currentLineIndex]?.currentContext?.findRenderObject()
            as RenderBox?;
    final viewportBox = context.findRenderObject() as RenderBox?;
    if (lineBox == null ||
        viewportBox == null ||
        !lineBox.attached ||
        !viewportBox.attached) {
      return;
    }

    final lineTop = lineBox
        .localToGlobal(Offset.zero, ancestor: viewportBox)
        .dy;
    final lineBottom = lineTop + lineBox.size.height;
    final visible = lineBottom > 0 && lineTop < viewportBox.size.height;

    final provider = ref.read(lyricsActiveLineVisibleProvider);
    if (provider != visible) {
      ref.read(lyricsActiveLineVisibleProvider.notifier).set(visible);
    }
  }

  void _scrollToIndex(int index, {bool isSearch = false, bool animate = true}) {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final key = _lineKeys[index];
      if (animate) {
        if (key?.currentContext != null) {
          Scrollable.ensureVisible(
            key!.currentContext!,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOutCubic,
            alignment: isSearch ? 0.5 : 0.15, // Center more for search matches
          );
        } else if (_scrollController.hasClients) {
          _scrollController
              .animateTo(
                ((index - 1) * 80.0).clamp(0.0, double.infinity),
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOutCubic,
              )
              .then((_) {
                if (mounted && _lineKeys[index]?.currentContext != null) {
                  Scrollable.ensureVisible(
                    _lineKeys[index]!.currentContext!,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOutCubic,
                    alignment: isSearch ? 0.5 : 0.15,
                  );
                }
              });
        }
      } else {
        // Entrance: jump to slightly offset position, then animate to target to show a beautiful scroll entry effect
        if (_scrollController.hasClients) {
          final startOffset = (index * 80.0 - 80.0).clamp(0.0, double.infinity);
          _scrollController.jumpTo(startOffset);
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          final currentKey = _lineKeys[index];
          if (currentKey?.currentContext != null) {
            Scrollable.ensureVisible(
              currentKey!.currentContext!,
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeOutCubic,
              alignment: isSearch ? 0.5 : 0.15,
            );
          } else if (_scrollController.hasClients) {
            _scrollController.animateTo(
              ((index - 1) * 80.0).clamp(0.0, double.infinity),
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeOutCubic,
            );
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _routeAnimation?.removeStatusListener(_onRouteAnimationStatusChanged);
    _scrollController.dispose();
    super.dispose();
  }

  /// Distance between whichever two pointers touched down first. Good
  /// enough for a two-finger pinch; a stray third finger just rides along
  /// without being part of the distance calculation.
  double _distanceBetweenFirstTwoPointers() {
    final positions = _activePointers.values.toList(growable: false);
    return (positions[0] - positions[1]).distance;
  }

  void _onPointerDown(PointerDownEvent event) {
    _activePointers[event.pointer] = event.position;
    if (_activePointers.length == 2) {
      _pinchStartDistance = _distanceBetweenFirstTwoPointers();
      _baseScale = _fontScale;
    }
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (!_activePointers.containsKey(event.pointer)) return;
    _activePointers[event.pointer] = event.position;

    final startDistance = _pinchStartDistance;
    if (_activePointers.length < 2 ||
        startDistance == null ||
        startDistance <= 0) {
      return;
    }

    final scale = _distanceBetweenFirstTwoPointers() / startDistance;
    final newFontScale = (_baseScale * scale).clamp(0.6, 2.5);
    if (newFontScale != _fontScale) {
      setState(() => _fontScale = newFontScale);
    }
  }

  void _onPointerUpOrCancel(PointerEvent event) {
    _activePointers.remove(event.pointer);
    // Re-baseline against whatever's left so a lifted finger (or a third
    // finger joining/leaving mid-pinch) never causes a sudden jump the next
    // time a two-finger pinch resumes.
    if (_activePointers.length >= 2) {
      _pinchStartDistance = _distanceBetweenFirstTwoPointers();
    } else {
      _pinchStartDistance = null;
    }
    _baseScale = _fontScale;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<Duration>(playbackProvider.select((s) => s.position), (
      previous,
      next,
    ) {
      _updateActiveLine(next);
    });

    ref.listen<bool>(lyricsManualScrollProvider, (previous, next) {
      if (next == false) {
        final currentPos = ref.read(playbackProvider).position;
        _updateActiveLine(currentPos, forceScroll: true);
      }
    });

    final selection = ref.watch(lyricsSelectionProvider);

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _onPointerDown,
      onPointerMove: _onPointerMove,
      onPointerUp: _onPointerUpOrCancel,
      onPointerCancel: _onPointerUpOrCancel,
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          // Re-check on every scroll tick, not just when the active line
          // itself changes - the whole point of the re-sync button is to
          // react to the user scrolling the list, and that's exactly the
          // case where the active line's on-screen position moves without
          // _updateActiveLine ever running. Returning false lets
          // AndroidLyricsScreen's own ScrollNotification listener (which
          // drives _onUserScrolled/lyricsManualScrollProvider) still see it.
          _checkActiveLineVisibility();
          return false;
        },
        child: ListView.builder(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          itemCount: widget.lines.length + 1,
          padding: EdgeInsets.only(
            top: 60.s,
            bottom: (Platform.isAndroid || Platform.isIOS) ? 120.s : 400.s,
            left: 24.s,
            right: 24.s,
          ),
          itemBuilder: (context, index) {
            if (index == widget.lines.length) {
              final source = ref.watch(lyricsProvider.select((s) => s.source));
              if (source == null || source.isEmpty) {
                return const SizedBox.shrink();
              }

              String displaySource = source.toUpperCase();
              if (source == 'local') {
                displaySource = context.l10n.lyricsSourceLocalFile;
              }
              if (source == 'embedded') {
                displaySource = context.l10n.lyricsSourceEmbedded;
              }

              return Padding(
                padding: const EdgeInsets.only(top: 24.0, bottom: 48.0),
                child: Opacity(
                  opacity: 0.35,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.scroll, size: 10.s, color: Colors.white),
                      const SizedBox(width: 6),
                      Text(
                        context.l10n.lyricsProvidedBy(displaySource),
                        style: AppFonts.jostStyle(
                          fontSize: 10.ts,
                          color: Colors.white,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final line = widget.lines[index];
            final isActive = index == _currentLineIndex;

            // Assign or retrieve key for this line
            final key = _lineKeys.putIfAbsent(index, () => GlobalKey());

            return Padding(
              key: key,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: AdvancedLyricLine(
                line: line,
                mode: widget.mode,
                isActive: isActive,
                fontScale: _fontScale,
                relativeIndex: _currentLineIndex == -1
                    ? index
                    : index - _currentLineIndex,
                isSelected: selection.contains(index),
                selectionActive: selection.isActive,
                onTap: () {
                  // While picking lines for the share card, tapping extends
                  // (or shrinks) the selection instead of seeking.
                  if (selection.isActive) {
                    HapticFeedback.selectionClick();
                    ref.read(lyricsSelectionProvider.notifier).extendTo(index);
                  } else {
                    widget.onSeek(line.startTime);
                  }
                },
                onLongPress: () {
                  HapticFeedback.mediumImpact();
                  ref
                      .read(lyricsSelectionProvider.notifier)
                      .startSelection(index);
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
