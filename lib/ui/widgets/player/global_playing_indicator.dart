import 'package:flutter/material.dart';
import 'dart:math' as math;

class GlobalPlayingIndicator extends StatefulWidget {
  final double size;
  final Color? color;

  const GlobalPlayingIndicator({super.key, this.size = 24, this.color});

  @override
  State<GlobalPlayingIndicator> createState() => _GlobalPlayingIndicatorState();
}

class _GlobalPlayingIndicatorState extends State<GlobalPlayingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(context).colorScheme.primary;

    // This animates indefinitely (repeat()) at 60fps for as long as
    // something's playing, and sits inside scrollable grid/list tiles -
    // isolate its continuous repaint from the rest of the tile's layer.
    return RepaintBoundary(
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(3, (index) {
            return AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final double value = math.sin(
                  (_controller.value * 2 * math.pi) + (index * math.pi / 3),
                );
                final double heightFactor = 0.5 + (value.abs() * 0.5);

                return Container(
                  width: widget.size / 6,
                  height: widget.size * heightFactor,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(widget.size / 12),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.3),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                );
              },
            );
          }),
        ),
      ),
    );
  }
}

class PlayingOverlay extends StatelessWidget {
  final Widget child;
  final bool isPlaying;
  final double borderRadius;

  const PlayingOverlay({
    super.key,
    required this.child,
    required this.isPlaying,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isPlaying)
          Positioned.fill(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(borderRadius),
              ),
              child: const Center(child: GlobalPlayingIndicator(size: 28)),
            ),
          ),
      ],
    );
  }
}
