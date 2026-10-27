part of 'advanced_lyric_line.dart';

/// The instrumental/music-gap symbol ("♫") for the currently active line -
/// same glyph the inactive and already-played instrumental symbols use, but
/// pulsing with a soft glow and a gentle bounce for as long as this line
/// stays active, so the animation itself (not a different symbol) is what
/// marks it as the current one. While playback is paused the pulse eases
/// back to rest (no glow, no bounce) and picks up again on resume.
class _PulsingInstrumentalIcon extends ConsumerStatefulWidget {
  const _PulsingInstrumentalIcon({required this.color, required this.style});

  /// Color of the glow halo behind the symbol - the symbol's own color
  /// already comes from [style].
  final Color color;
  final TextStyle style;

  @override
  ConsumerState<_PulsingInstrumentalIcon> createState() =>
      _PulsingInstrumentalIconState();
}

class _PulsingInstrumentalIconState
    extends ConsumerState<_PulsingInstrumentalIcon>
    with SingleTickerProviderStateMixin {
  static const _beat = Duration(milliseconds: 900);

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _beat,
  );

  @override
  void initState() {
    super.initState();
    if (ref.read(playbackProvider).isPlaying && !Motion.reduced) {
      _controller.repeat(reverse: true);
    }
  }

  void _syncWithPlayback(bool playing) {
    if (playing) {
      if (Motion.reduced) return;
      if (!_controller.isAnimating) _controller.repeat(reverse: true);
    } else {
      // Settle back down instead of freezing mid-glow.
      _controller.animateTo(0, duration: _beat * _controller.value);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(
      playbackProvider.select((s) => s.isPlaying),
      (_, playing) => _syncWithPlayback(playing),
    );
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_controller.value);
        return Transform.translate(
          // Bounce: rises slightly on each beat, settles back down.
          offset: Offset(0, -4.0 * t),
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                // Glow: a soft halo behind the icon that swells and fades
                // with the same beat as the bounce.
                BoxShadow(
                  color: widget.color.withValues(alpha: 0.15 + 0.35 * t),
                  blurRadius: 10 + 14 * t,
                  spreadRadius: 1 + 3 * t,
                ),
              ],
            ),
            child: child,
          ),
        );
      },
      // Pops in when the break starts (it isn't shown before): scale only,
      // so the line keeps its size and the list doesn't move.
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: Motion.reduced ? 1.0 : 0.0, end: 1.0),
        duration: const Duration(milliseconds: 520),
        curve: Curves.easeOutBack,
        child: Text('♫', style: widget.style),
        builder: (context, t, child) => Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform.scale(scale: 0.4 + 0.6 * t, child: child),
        ),
      ),
    );
  }
}
