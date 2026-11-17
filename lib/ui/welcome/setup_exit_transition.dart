import 'package:flutter/material.dart';
import 'package:looper_player/ui/widgets/common/setup_kit.dart';

/// Brings [child] in after setup: it fades up from the setup's dark
/// background while settling from a slight zoom-out. Plays once when [play]
/// is true; otherwise (and afterwards) it is a pass-through that keeps
/// [child] mounted in the same place.
class HomeReveal extends StatefulWidget {
  const HomeReveal({super.key, required this.play, required this.child});

  final bool play;
  final Widget child;

  @override
  State<HomeReveal> createState() => _HomeRevealState();
}

class _HomeRevealState extends State<HomeReveal>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 560),
    value: 1,
  );
  late final _fade = CurvedAnimation(parent: _c, curve: Curves.easeOut);
  late final _zoom = Tween(
    begin: 0.96,
    end: 1.0,
  ).animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));

  @override
  void initState() {
    super.initState();
    if (widget.play) _c.forward(from: 0);
  }

  @override
  void didUpdateWidget(HomeReveal old) {
    super.didUpdateWidget(old);
    if (widget.play && !old.play) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Opacity 1 and scale 1 paint straight through once it has played.
    return ColoredBox(
      color: kSetupBg,
      child: FadeTransition(
        opacity: _fade,
        child: ScaleTransition(scale: _zoom, child: widget.child),
      ),
    );
  }
}
