import 'package:flutter/material.dart';

/// Collection entries recede behind explicit choices without looking disabled.
class QueueEntryFade extends StatelessWidget {
  const QueueEntryFade({
    super.key,
    required this.automatic,
    required this.child,
    this.automaticOpacity = 0.576,
  });

  final bool automatic;
  final double automaticOpacity;
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedOpacity(
    opacity: automatic ? automaticOpacity : 1,
    duration: const Duration(milliseconds: 180),
    curve: Curves.easeOut,
    child: child,
  );
}
