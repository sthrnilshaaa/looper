import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import 'package:looper_player/core/utils/motion.dart';
import 'package:looper_player/ui/widgets/common/scrolling_text.dart';
import 'package:looper_player/ui/widgets/common/song_playback_overlay.dart';

import 'android_lyrics_screen.dart';

/// Player -> lyrics. The artwork, title, artist, seek bar and transport
/// buttons fly to their lyrics-screen spots as Heroes (one shared motion);
/// the route itself only cross-fades the backgrounds, finishing early so the
/// flights are what the eye follows. The lyrics text enters after them (see
/// [LyricsEntrance]). Popping runs the same path backwards.
Route<void> lyricsRoute() {
  if (Motion.reduced) {
    return PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 150),
      reverseTransitionDuration: const Duration(milliseconds: 150),
      pageBuilder: (context, animation, secondaryAnimation) =>
          const AndroidLyricsScreen(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) =>
          FadeTransition(opacity: animation, child: child),
    );
  }
  return PageRouteBuilder<void>(
    transitionDuration: const Duration(milliseconds: 400),
    reverseTransitionDuration: const Duration(milliseconds: 350),
    pageBuilder: (context, animation, secondaryAnimation) =>
        const AndroidLyricsScreen(),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(
          parent: animation,
          curve: const Interval(0.0, 0.55, curve: Curves.easeOut),
        ),
        child: SemanticsWhileStill(animation: animation, child: child),
      );
    },
  );
}

/// Brings the lyrics in once the flights have mostly landed - fades and
/// rises [distance] over the last 60 % of the route animation. On close the
/// same mapping runs backwards, so the lyrics leave first and the flights
/// return after.
class LyricsEntrance extends StatelessWidget {
  const LyricsEntrance({super.key, required this.child, this.distance = 24});

  final Widget child;
  final double distance;

  @override
  Widget build(BuildContext context) {
    final Animation<double>? route = ModalRoute.of(context)?.animation;
    if (route == null || Motion.reducedOf(context)) return child;
    final Animation<double> t = CurvedAnimation(
      parent: route,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOutCubic),
    );
    return AnimatedBuilder(
      animation: t,
      builder: (context, child) => Opacity(
        opacity: t.value,
        child: Transform.translate(
          offset: Offset(0, (1 - t.value) * distance),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

/// Artwork flight between the player (large) and a small artwork (the
/// lyrics header, or the classic mini bar): always flies the large side's
/// artwork, so the shuttle never upscales a small thumbnail into a blurry
/// square. When the small side is the mini bar, its now-playing overlay
/// (dark layer + playing animation) rides along and fades out toward the
/// player - and back in on the way down - instead of popping.
Widget artworkFlightShuttle(
  BuildContext flightContext,
  Animation<double> animation,
  HeroFlightDirection flightDirection,
  BuildContext fromHeroContext,
  BuildContext toHeroContext,
) {
  Size sizeOf(BuildContext c) {
    final RenderObject? box = c.findRenderObject();
    if (box is RenderBox && box.hasSize) return box.size;
    return Size.zero;
  }

  final Hero from = fromHeroContext.widget as Hero;
  final Hero to = toHeroContext.widget as Hero;
  final Size fromSize = sizeOf(fromHeroContext);
  final Size toSize = sizeOf(toHeroContext);
  final bool fromIsBig =
      fromSize.width * fromSize.height >= toSize.width * toSize.height;
  final Widget big = fromIsBig ? from.child : to.child;
  final Size bigSize = fromIsBig ? fromSize : toSize;
  // Laid out at its real (large) size and scaled uniformly into the flight
  // rect. Laid out directly at the shrinking rect, the player's artwork
  // (fixed-size image inside a decorated frame) didn't fill it: its dark
  // frame/shadow showed above the picture mid-flight, then snapped on
  // landing.
  // Corners morph from one hero's radius to the other's. A fixed 12 landed
  // as a rounded square on the classic mini bar's round thumbnail (radius
  // 32 on 50 dp) and its corners snapped on the landing frame.
  // animation.value is 1 at the pushed route's end in both directions.
  final bool push = flightDirection == HeroFlightDirection.push;
  final double pushedRadius = _clipRadius(
    push ? toHeroContext : fromHeroContext,
  );
  final double belowRadius = _clipRadius(
    push ? fromHeroContext : toHeroContext,
  );
  BorderRadius radiusAt(double t) =>
      BorderRadius.circular(lerpDouble(belowRadius, pushedRadius, t)!);
  Widget clip(Widget child) => pushedRadius == belowRadius
      ? ClipRRect(
          borderRadius: BorderRadius.circular(pushedRadius),
          child: child,
        )
      : AnimatedBuilder(
          animation: animation,
          child: child,
          builder: (context, child) =>
              ClipRRect(borderRadius: radiusAt(animation.value), child: child),
        );
  final Widget art = clip(
    bigSize.isEmpty
        ? big
        // Uniform scale, cropping any overflow: the flight rect isn't
        // always the artwork's shape near the small end, and filling it
        // stretched the cover.
        : FittedBox(
            fit: BoxFit.cover,
            clipBehavior: Clip.hardEdge,
            child: SizedBox.fromSize(size: bigSize, child: big),
          ),
  );
  final SongPlaybackOverlay? overlay =
      _findOverlay(fromHeroContext) ?? _findOverlay(toHeroContext);
  if (overlay == null) return art;
  // animation.value is 1 at the pushed (large) end in both directions.
  return Stack(
    fit: StackFit.expand,
    children: [
      art,
      Positioned.fill(
        child: FadeTransition(
          opacity: ReverseAnimation(animation),
          child: clip(SongPlaybackOverlay(isPlaying: overlay.isPlaying)),
        ),
      ),
    ],
  );
}

// The walks below run inside Hero shuttle builders, i.e. during a build.
// They use visitChildren, not visitChildElements, whose debug-only check
// rejects any walk during a build. That's safe here: the heroes sit on the two
// routes already on screen, which aren't the ones being rebuilt.

/// Corner radius of the first ClipRRect inside a hero (its artwork's
/// on-screen rounding), or 12 - the player artwork's - when it has none.
double _clipRadius(BuildContext heroContext) {
  double? found;
  void visit(Element element) {
    if (found != null) return;
    final Widget w = element.widget;
    if (w is ClipRRect) {
      found = w.borderRadius.resolve(TextDirection.ltr).topLeft.x;
      return;
    }
    element.visitChildren(visit);
  }

  if (heroContext is Element) heroContext.visitChildren(visit);
  return found ?? 12.0;
}

SongPlaybackOverlay? _findOverlay(BuildContext heroContext) {
  SongPlaybackOverlay? found;
  void visit(Element element) {
    if (found != null) return;
    final Widget w = element.widget;
    if (w is SongPlaybackOverlay) {
      found = w;
      return;
    }
    element.visitChildren(visit);
  }

  if (heroContext is Element) heroContext.visitChildren(visit);
  return found;
}

/// The text style a title/artist Hero actually renders with: the first
/// ScrollingText or styled Text inside it. Walking the subtree (not just the
/// Hero's direct child) matters on the player, where the text sits inside
/// tap targets - reading only the child fell back to a guessed style, so the
/// flight started at the wrong size/colour and snapped.
TextStyle heroTextStyle(BuildContext heroContext, TextStyle fallback) {
  TextStyle? found;
  void visit(Element element) {
    if (found != null) return;
    final Widget w = element.widget;
    if (w is ScrollingText) {
      found = w.style;
      return;
    }
    if (w is Text && w.style != null) {
      found = w.style;
      return;
    }
    element.visitChildren(visit);
  }

  if (heroContext is Element) heroContext.visitChildren(visit);
  return found ?? fallback;
}

/// Leaves [child] out of the accessibility tree while [animation] runs and
/// puts it back when it settles. With an accessibility service on (password
/// managers, launchers, ...), every moving node's geometry is otherwise
/// recomputed on every frame of a transition. Rebuilds only when the status
/// changes, never per frame.
class SemanticsWhileStill extends StatefulWidget {
  const SemanticsWhileStill({
    super.key,
    required this.animation,
    required this.child,
  });

  final Animation<double> animation;
  final Widget child;

  @override
  State<SemanticsWhileStill> createState() => _SemanticsWhileStillState();
}

class _SemanticsWhileStillState extends State<SemanticsWhileStill> {
  late bool _moving = widget.animation.isAnimating;

  @override
  void initState() {
    super.initState();
    widget.animation.addStatusListener(_onStatus);
  }

  @override
  void didUpdateWidget(SemanticsWhileStill old) {
    super.didUpdateWidget(old);
    if (old.animation != widget.animation) {
      old.animation.removeStatusListener(_onStatus);
      widget.animation.addStatusListener(_onStatus);
      _moving = widget.animation.isAnimating;
    }
  }

  @override
  void dispose() {
    widget.animation.removeStatusListener(_onStatus);
    super.dispose();
  }

  void _onStatus(AnimationStatus status) {
    final bool moving = status.isAnimating;
    if (moving != _moving && mounted) setState(() => _moving = moving);
  }

  @override
  Widget build(BuildContext context) =>
      ExcludeSemantics(excluding: _moving, child: widget.child);
}
