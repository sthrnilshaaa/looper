import 'package:looper_player/core/motion/looper_scroll_physics.dart';
import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:looper_player/core/utils/motion.dart';
import 'package:looper_player/core/utils/ui_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:looper_player/core/theme/app_fonts.dart';

import '../../../domain/lyric_models.dart';
import '../../screens/lyrics_view.dart';
import '../../providers/lyrics/lyrics_search_provider.dart';
import 'advanced_lyric_line/advanced_lyric_line.dart';
import 'lyrics_follow_motion.dart';
import 'lyrics_scale.dart';

import 'package:looper_player/features/settings/presentation/providers/settings_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:looper_player/features/playback/presentation/providers/playback/playback_notifier.dart';

import '../../providers/lyrics/lyrics_notifier.dart';
import '../../providers/lyrics/lyrics_selection_notifier.dart';

import 'package:looper_player/core/utils/l10n.dart';
import 'package:looper_player/core/services/haptics/app_haptics.dart';

class AdvancedLyricRenderer extends ConsumerStatefulWidget {
  final List<LyricLine> lines;
  final LyricsSyncMode mode;
  final Function(Duration) onSeek;

  /// False for lyrics without timestamps: plain text to read, with no
  /// current line, no following the song and no tap-to-seek.
  final bool synced;

  /// Text scale supplied by the parent. Null keeps the renderer's own
  /// pinch-driven scale, which starts from the saved lyrics size and is
  /// saved again when a pinch ends.
  final double? fontScale;

  /// With [fontScale] set, a pinch reports the scale it asks for here.
  final ValueChanged<double>? onFontScaleChanged;

  /// Left/right and bottom padding of the list. Null keeps the defaults.
  final double? horizontalPadding;
  final double? bottomPadding;

  const AdvancedLyricRenderer({
    super.key,
    required this.lines,
    required this.mode,
    required this.onSeek,
    this.synced = true,
    this.fontScale,
    this.onFontScaleChanged,
    this.horizontalPadding,
    this.bottomPadding,
  });

  @override
  ConsumerState<AdvancedLyricRenderer> createState() =>
      _AdvancedLyricRendererState();
}

class _AdvancedLyricRendererState extends ConsumerState<AdvancedLyricRenderer>
    with SingleTickerProviderStateMixin {
  // No PageStorage restore: this renderer is rebuilt for every song (the
  // loading skeleton replaces it in between), and restoring would open the
  // next song's lyrics at wherever the previous song was scrolled to.
  final ScrollController _scrollController = ScrollController(
    keepScrollOffset: false,
  );
  final Map<int, GlobalKey> _lineKeys = {};
  late final LyricsFollowMotion _followMotion = LyricsFollowMotion(this);
  int _currentLineIndex = -1;

  /// The line the list rests on while the line at [index] is current: the
  /// line itself, or the one before it when the two are sung as one (see
  /// [LyricLine.pairHeads]). Only word and letter styles pair lines, and
  /// only while "Group Continued Lines" is on.
  int _anchorIndexOf(int index) {
    if (index < 0 || widget.mode == LyricsSyncMode.line) return index;
    if (ref.read(settingsProvider).lyricsNoLineGrouping) return index;
    final heads = LyricLine.pairHeads(widget.lines);
    return index < heads.length ? heads[index] : index;
  }

  /// Where the active line rests, as a fraction of the list's height.
  static const double _anchor = 0.15;

  /// How far the lines slide in after a jump to a far-away line.
  static const double _farSlide = 72;

  /// A tapped line stays active for [_tapHold] even while the player still
  /// reports positions from before the seek (or lands a hair short of the
  /// line's start) - otherwise the highlight flicks back to the previous
  /// line for a frame or two.
  int _tappedIndex = -1;
  DateTime _tappedAt = DateTime.fromMillisecondsSinceEpoch(0);
  static const Duration _tapHold = Duration(seconds: 1);
  double _fontScale = 1.0;
  double _baseScale = 1.0;

  double get _effectiveFontScale => widget.fontScale ?? _fontScale;

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
    _fontScale = LyricsScale.normalize(
      ref.read(settingsProvider).lyricsFontScale,
    );
    _baseScale = _fontScale;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // New lyrics start following from the top even if the user had
        // scrolled away (re-sync button up) during the previous song.
        ref.read(lyricsManualScrollProvider.notifier).set(false);
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
    if (oldWidget.lines != widget.lines || oldWidget.synced != widget.synced) {
      _currentLineIndex = -1;
      _tappedIndex = -1;
      _lineKeys.clear();
      // The lines changed (new song, or a different lyrics source/provider
      // was picked) — any in-progress share selection no longer points at
      // the right text, so drop it in the next frame to avoid modifying
      // providers while building.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(lyricsSelectionProvider.notifier).clear();
          if (_scrollController.hasClients) _scrollController.jumpTo(0);
          ref.read(lyricsManualScrollProvider.notifier).set(false);
        }
      });
    }
    final currentPos = ref.read(playbackProvider).position;
    _updateActiveLine(
      currentPos,
      forceScroll:
          oldWidget.mode != widget.mode ||
          oldWidget.lines != widget.lines ||
          oldWidget.synced != widget.synced,
    );
  }

  void _updateActiveLine(Duration position, {bool forceScroll = false}) {
    final route = ModalRoute.of(context);
    final isExiting =
        route != null && route.animation?.status == AnimationStatus.reverse;
    if (isExiting) return;

    if (!widget.synced) {
      // No line is current, so none can be off screen either (which is
      // what brings up the re-sync button).
      _currentLineIndex = -1;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !ref.read(lyricsActiveLineVisibleProvider)) {
          ref.read(lyricsActiveLineVisibleProvider.notifier).set(true);
        }
      });
      return;
    }

    // Most position updates land inside the line that is already active:
    // nothing to search for, nothing to scroll.
    if (!forceScroll &&
        _tappedIndex < 0 &&
        _currentLineIndex >= 0 &&
        _currentLineIndex < widget.lines.length) {
      final current = widget.lines[_currentLineIndex];
      if (position >= current.startTime && position < current.endTime) return;
    }

    int index = widget.lines.indexWhere(
      (line) => position >= line.startTime && position < line.endTime,
    );

    if (_tappedIndex >= 0 && _tappedIndex < widget.lines.length) {
      final holding = DateTime.now().difference(_tappedAt) < _tapHold;
      final tapped = widget.lines[_tappedIndex];
      final inTapped =
          position >= tapped.startTime && position < tapped.endTime;
      if (holding && !inTapped) {
        index = _tappedIndex;
      } else if (!holding) {
        _tappedIndex = -1;
      }
    }

    if (index == -1 && widget.lines.isNotEmpty) {
      if (position < widget.lines.first.startTime) {
        index = 0;
      } else if (position >= widget.lines.last.endTime) {
        index = widget.lines.length - 1;
      }
    }

    var isManual = ref.read(lyricsManualScrollProvider);
    if (index != -1 && (index != _currentLineIndex || forceScroll)) {
      // A manual scroll only pauses auto-follow while it actually took the
      // lyrics away: if the line being left is still on screen (so no
      // re-sync button), keep following onto the new one.
      if (isManual && !forceScroll && _canResumeFollow(_currentLineIndex)) {
        isManual = false;
        _resumeFollow();
      }
      // The second line of a pair takes over where the list already rests.
      final anchor = _anchorIndexOf(index);
      final samePair =
          !forceScroll && anchor == _anchorIndexOf(_currentLineIndex);
      _currentLineIndex = index;
      if ((!isManual || forceScroll) && !samePair) {
        _scrollToIndex(anchor, animate: _transitionFinished);
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

  /// Whether auto-follow can take over again: the line at [index] is on
  /// screen and the user isn't touching or flinging the list.
  bool _canResumeFollow(int index) {
    if (_activePointers.isNotEmpty) return false;
    if (_scrollController.hasClients &&
        _scrollController.position.isScrollingNotifier.value) {
      return false;
    }
    return index >= 0 && _isLineOnScreen(index);
  }

  bool _isLineOnScreen(int index) {
    final lineBox =
        _lineKeys[index]?.currentContext?.findRenderObject() as RenderBox?;
    final viewportBox = context.findRenderObject() as RenderBox?;
    if (lineBox == null ||
        viewportBox == null ||
        !lineBox.attached ||
        !viewportBox.attached) {
      return false;
    }
    final top = lineBox.localToGlobal(Offset.zero, ancestor: viewportBox).dy;
    return top + lineBox.size.height > 0 && top < viewportBox.size.height;
  }

  /// Clears the manual-scroll flag, which also hides the re-sync button;
  /// the provider listener in build scrolls back to the active line.
  void _resumeFollow() {
    _resumeTimer?.cancel();
    // Can be reached from didUpdateWidget, i.e. mid-build, where providers
    // can't be modified - flip the flag once this frame is done.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(lyricsManualScrollProvider.notifier).set(false);
    });
  }

  /// After the user lets go with the active line still in view, snap back
  /// to it shortly rather than waiting for the next line (which can be a
  /// long instrumental away).
  Timer? _resumeTimer;
  static const Duration _resumeDelay = Duration(milliseconds: 1500);

  void _scheduleResumeFollow() {
    _resumeTimer?.cancel();
    _resumeTimer = Timer(_resumeDelay, () {
      if (!mounted || !ref.read(lyricsManualScrollProvider)) return;
      if (_canResumeFollow(_currentLineIndex)) _resumeFollow();
    });
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

  void _scrollToIndex(int index, {bool animate = true}) {
    if (!mounted) return;
    // After this frame's layout, so the new active line is measured as laid
    // out now.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _follow(index, animate: animate),
    );
  }

  /// The scroll offset that puts the line at [index] on the anchor, or null
  /// while that line isn't built.
  double? _restingOffset(int index) {
    final box = _lineKeys[index]?.currentContext?.findRenderObject();
    if (box == null || !box.attached) return null;
    final position = _scrollController.position;
    return RenderAbstractViewport.of(box)
        .getOffsetToReveal(box, _anchor)
        .offset
        .clamp(position.minScrollExtent, position.maxScrollExtent);
  }

  /// A guess at [_restingOffset] for a line that isn't built, from the
  /// nearest line that is and the average height of the built ones.
  double _estimatedOffset(int index) {
    int? nearest;
    RenderBox? nearestBox;
    var heights = 0.0;
    var count = 0;
    _lineKeys.forEach((i, key) {
      final box = key.currentContext?.findRenderObject();
      if (box is! RenderBox || !box.attached) return;
      heights += box.size.height;
      count++;
      if (nearest == null || (i - index).abs() < (nearest! - index).abs()) {
        nearest = i;
        nearestBox = box;
      }
    });
    if (nearest == null) return _scrollController.position.pixels;
    final base = RenderAbstractViewport.of(
      nearestBox!,
    ).getOffsetToReveal(nearestBox!, _anchor).offset;
    return base + (index - nearest!) * heights / count;
  }

  void _follow(int index, {required bool animate, int attempt = 0}) {
    if (!mounted || !_scrollController.hasClients) return;
    if (index != _anchorIndexOf(_currentLineIndex)) return;
    final position = _scrollController.position;

    final target = _restingOffset(index);
    if (target == null) {
      // The line is too far away to be built: jump next to it and measure
      // again once it has been laid out.
      if (attempt >= 4) return;
      position.jumpTo(
        _estimatedOffset(
          index,
        ).clamp(position.minScrollExtent, position.maxScrollExtent),
      );
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _follow(index, animate: animate, attempt: attempt + 1),
      );
      // A frame is needed for that layout even if nothing else asks for one.
      WidgetsBinding.instance.scheduleFrame();
      return;
    }

    final delta = target - position.pixels;
    final far = attempt > 0 || delta.abs() > position.viewportDimension;
    if (delta.abs() < 0.5 && !far) return;
    // The stagger is decoration; following the song is not.
    final elastic = animate && !Motion.reduced;

    if (!animate || far) {
      position.jumpTo(target);
      if (elastic && delta != 0) {
        _followMotion.push(delta.sign * _farSlide, anchor: index, led: false);
      }
      return;
    }

    position.animateTo(
      target,
      duration: LyricsFollowMotion.duration,
      curve: LyricsFollowMotion.curve,
    );
    if (elastic) _followMotion.push(delta, anchor: index);
  }

  @override
  void dispose() {
    _routeAnimation?.removeStatusListener(_onRouteAnimationStatusChanged);
    _resumeTimer?.cancel();
    _followMotion.dispose();
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
      _baseScale = _effectiveFontScale;
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
    final newFontScale = (_baseScale * scale).clamp(
      LyricsScale.min,
      LyricsScale.max,
    );
    if (newFontScale != _effectiveFontScale) {
      final onChanged = widget.onFontScaleChanged;
      if (widget.fontScale != null && onChanged != null) {
        onChanged(newFontScale);
      } else {
        setState(() => _fontScale = newFontScale);
      }
    }
  }

  /// Saves the pinch-driven scale once the pinch is over (not per move:
  /// every save is a database write), so the lyrics reopen at the same size.
  /// A parent-supplied [AdvancedLyricRenderer.fontScale] is saved by the
  /// parent instead.
  void _saveOwnFontScale() {
    if (widget.fontScale != null) return;
    final saved = LyricsScale.normalize(
      ref.read(settingsProvider).lyricsFontScale,
    );
    if ((saved - _fontScale).abs() < 0.001) return;
    ref.read(settingsProvider.notifier).updateLyricsFontScale(_fontScale);
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
      _saveOwnFontScale();
    }
    _baseScale = _effectiveFontScale;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<Duration>(playbackProvider.select((s) => s.position), (
      previous,
      next,
    ) {
      _updateActiveLine(next);
    });

    final browsing = ref.watch(lyricsManualScrollProvider);
    ref.listen<bool>(lyricsManualScrollProvider, (previous, next) {
      if (next == false) {
        final currentPos = ref.read(playbackProvider).position;
        _updateActiveLine(currentPos, forceScroll: true);
      }
    });

    final selection = ref.watch(lyricsSelectionProvider);
    // Rebuild (and re-anchor) when grouping is switched.
    ref.listen<bool>(settingsProvider.select((s) => s.lyricsNoLineGrouping), (
      _,
      _,
    ) {
      final currentPos = ref.read(playbackProvider).position;
      _updateActiveLine(currentPos, forceScroll: true);
      setState(() {});
    });

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
          if (notification is ScrollStartNotification) {
            _resumeTimer?.cancel();
          } else if (notification is ScrollEndNotification &&
              ref.read(lyricsManualScrollProvider)) {
            _scheduleResumeFollow();
          }
          return false;
        },
        child: LayoutBuilder(
          builder: (context, constraints) => ListView.builder(
            controller: _scrollController,
            physics: const LooperScrollPhysics(),
            itemCount: widget.lines.length + 1,
            padding: EdgeInsets.only(
              top: 60.s,
              // Enough room below the last line for it to reach the anchor
              // like every other line.
              bottom: math.max(
                widget.bottomPadding ??
                    ((Platform.isAndroid || Platform.isIOS) ? 120.s : 400.s),
                constraints.maxHeight * 0.8,
              ),
              left: widget.horizontalPadding ?? 24.s,
              right: widget.horizontalPadding ?? 24.s,
            ),
            itemBuilder: (context, index) {
              if (index == widget.lines.length) {
                final source = ref.watch(
                  lyricsProvider.select((s) => s.source),
                );
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
                        Icon(
                          LucideIcons.scroll,
                          size: 10.s,
                          color: Colors.white,
                        ),
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
              final pairHead = _anchorIndexOf(_currentLineIndex);

              // Assign or retrieve key for this line
              final key = _lineKeys.putIfAbsent(index, () => GlobalKey());

              final Widget row = Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: LyricsFollowOffset(
                  motion: _followMotion,
                  index: index,
                  child: AdvancedLyricLine(
                    line: line,
                    mode: widget.mode,
                    isActive: isActive,
                    held: !isActive && index == pairHead,
                    // While the user scrolls around on their own, every
                    // line stays readable; the fade is for following.
                    distance: browsing || _currentLineIndex < 0
                        ? 1
                        : math.min(
                            (index - _currentLineIndex).abs(),
                            (index - pairHead).abs(),
                          ),
                    synced: widget.synced,
                    fontScale: _effectiveFontScale,
                    isSelected: selection.contains(index),
                    selectionActive: selection.isActive,
                    onTap: () {
                      // While picking lines for the share card, tapping extends
                      // (or shrinks) the selection instead of seeking.
                      if (selection.isActive) {
                        AppHaptics.selection();
                        ref
                            .read(lyricsSelectionProvider.notifier)
                            .extendTo(index);
                      } else if (widget.synced) {
                        _tappedIndex = index;
                        _tappedAt = DateTime.now();
                        _updateActiveLine(line.startTime);
                        widget.onSeek(line.startTime);
                      }
                    },
                    onLongPress: () {
                      AppHaptics.medium();
                      ref
                          .read(lyricsSelectionProvider.notifier)
                          .startSelection(index);
                    },
                  ),
                ),
              );

              // A music break ("♫") takes no room until it starts: upcoming
              // breaks are collapsed and open up when they become current.
              // The list rests on a line's top edge, so the opening only
              // pushes the upcoming lines down - the current spot stays put.
              if (!widget.synced ||
                  !AdvancedLyricLine.isInstrumentalText(line.text)) {
                return KeyedSubtree(key: key, child: row);
              }
              return AnimatedSize(
                key: key,
                duration: Duration(
                  milliseconds: Motion.reducedOf(context) ? 0 : 380,
                ),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                // The icon pops in while the row opens; don't cut its glow.
                clipBehavior: Clip.none,
                child: index > _currentLineIndex
                    ? const SizedBox(width: double.infinity, height: 0)
                    : row,
              );
            },
          ),
        ),
      ),
    );
  }
}
