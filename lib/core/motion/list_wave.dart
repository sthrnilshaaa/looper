import 'package:flutter/widgets.dart';

import 'package:looper_player/core/utils/motion.dart';

/// Staggers the [WaveItem]s below it in as one spatial wave: each item fades
/// and rises in with a delay set by where it sits on screen (top-left first,
/// rows below later, grid columns slightly after), and the whole group
/// finishes within [total] (1 s).
///
/// One animation per change: the wave only plays when content appears on a
/// screen that is already in place - data replacing a loading skeleton, for
/// example. If the page is still sliding in (its route is animating), the
/// route's motion is that change's animation and the wave is skipped. It
/// plays once per mount, never on rebuilds, and not at all with Reduce
/// Motion. Items below the fold (or built after the wave ends) show at rest.
class ListWave extends StatefulWidget {
  const ListWave({super.key, required this.child});

  final Widget child;

  /// The whole group's budget.
  static const Duration total = Duration(milliseconds: 1000);

  /// Each item's own fade/rise.
  static const double itemShare = 0.45;

  /// Rise distance.
  static const double distance = 18.0;

  @override
  State<ListWave> createState() => _ListWaveState();
}

class _ListWaveState extends State<ListWave>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: ListWave.total,
  );
  bool _decided = false;
  bool _plays = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_decided) return;
    _decided = true;
    final Animation<double>? route = ModalRoute.of(context)?.animation;
    final bool routeSettled = route == null || route.isCompleted;
    _plays = routeSettled && !Motion.reducedOf(context);
    if (_plays) {
      _controller.forward();
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _WaveScope(
      controller: _controller,
      plays: _plays,
      child: widget.child,
    );
  }
}

class _WaveScope extends InheritedWidget {
  const _WaveScope({
    required this.controller,
    required this.plays,
    required super.child,
  });

  final AnimationController controller;
  final bool plays;

  @override
  bool updateShouldNotify(_WaveScope old) =>
      controller != old.controller || plays != old.plays;
}

/// One item of a [ListWave]. Outside a wave (or once it has finished) it is
/// just [child].
class WaveItem extends StatefulWidget {
  const WaveItem({super.key, required this.child});

  final Widget child;

  @override
  State<WaveItem> createState() => _WaveItemState();
}

class _WaveItemState extends State<WaveItem> {
  /// Where this item starts in the wave, 0 (first) to 1 (last on screen);
  /// null until measured after the first layout.
  double? _start;
  bool _atRest = false;

  @override
  Widget build(BuildContext context) {
    final _WaveScope? scope = context
        .dependOnInheritedWidgetOfExactType<_WaveScope>();
    if (_atRest ||
        scope == null ||
        !scope.plays ||
        scope.controller.isCompleted) {
      return widget.child;
    }
    final AnimationController controller = scope.controller;
    if (_start == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _measure(scope));
    }
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final double? start = _start;
        if (start == null) {
          // First frame, before measuring: hidden, so nothing pops.
          return Opacity(opacity: 0.0, child: child);
        }
        const double share = ListWave.itemShare;
        final double t = ((controller.value - start * (1.0 - share)) / share)
            .clamp(0.0, 1.0)
            .toDouble();
        if (t >= 1.0) return child!;
        final double eased = Curves.easeOutCubic.transform(t);
        return Opacity(
          opacity: eased,
          child: Transform.translate(
            offset: Offset(0, (1.0 - eased) * ListWave.distance),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }

  void _measure(_WaveScope scope) {
    if (!mounted) return;
    final RenderObject? self = context.findRenderObject();
    final RenderObject? viewport = Scrollable.maybeOf(
      context,
    )?.context.findRenderObject();
    double start = 0.0;
    if (self is RenderBox && self.hasSize && viewport is RenderBox) {
      final Offset o = self.localToGlobal(Offset.zero, ancestor: viewport);
      final Size v = viewport.size;
      if (v.height > 0 && v.width > 0) {
        // Down the screen is the wave; across adds a small diagonal lag.
        final double down = o.dy / v.height;
        final double across = o.dx / v.width;
        start = (down * 0.85 + across * 0.15).clamp(0.0, 2.0).toDouble();
      }
    }
    setState(() {
      if (start > 1.0) {
        _atRest = true; // below the fold: nobody sees it arrive
      } else {
        _start = start;
      }
    });
  }
}

/// Wraps every item an [IndexedWidgetBuilder] builds in a [WaveItem].
IndexedWidgetBuilder waveItems(IndexedWidgetBuilder builder) =>
    (context, index) => WaveItem(child: builder(context, index));
