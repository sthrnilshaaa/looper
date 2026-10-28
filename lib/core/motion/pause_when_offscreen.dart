import 'package:flutter/widgets.dart';

/// Pauses the decorative animation in [child] (its tickers, via
/// [TickerMode]) while it is scrolled out of its nearest scroll view's
/// viewport, and isolates its repaints in a [RepaintBoundary] so a looping
/// animation never repaints the list around it.
///
/// Hidden tabs, covered routes and a backgrounded app are already paused by
/// the shell's TickerMode, the Navigator's Overlay and the engine; this
/// covers the one case those miss - an element that is still mounted but
/// off screen (a non-lazy scroll view, or a lazy one's cache extent).
///
/// Use it only around animations that loop on their own. Wrapping static
/// content adds a layer for nothing.
class PauseWhenOffscreen extends StatefulWidget {
  const PauseWhenOffscreen({super.key, required this.child});

  final Widget child;

  @override
  State<PauseWhenOffscreen> createState() => _PauseWhenOffscreenState();
}

class _PauseWhenOffscreenState extends State<PauseWhenOffscreen> {
  ScrollPosition? _position;
  bool _visible = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ScrollPosition? next = Scrollable.maybeOf(context)?.position;
    if (next != _position) {
      _position?.removeListener(_check);
      _position = next?..addListener(_check);
      WidgetsBinding.instance.addPostFrameCallback((_) => _check());
    }
  }

  @override
  void dispose() {
    _position?.removeListener(_check);
    super.dispose();
  }

  void _check() {
    if (!mounted) return;
    final RenderObject? self = context.findRenderObject();
    final ScrollableState? scrollable = Scrollable.maybeOf(context);
    final RenderObject? viewport = scrollable?.context.findRenderObject();
    if (self is! RenderBox ||
        viewport is! RenderBox ||
        !self.attached ||
        !self.hasSize ||
        !viewport.hasSize) {
      return;
    }
    final Rect mine = MatrixUtils.transformRect(
      self.getTransformTo(viewport),
      Offset.zero & self.size,
    );
    final bool visible = mine.overlaps(Offset.zero & viewport.size);
    if (visible != _visible) setState(() => _visible = visible);
  }

  @override
  Widget build(BuildContext context) {
    return TickerMode(
      enabled: _visible,
      child: RepaintBoundary(child: widget.child),
    );
  }
}
