import 'dart:math' as math;

import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:looper_player/core/services/haptics/app_haptics.dart';
import 'package:looper_player/core/services/storage/local_json_store.dart';
import 'package:looper_player/core/utils/motion.dart';
import 'package:looper_player/core/utils/ui_utils.dart';
import 'package:looper_player/features/playback/presentation/providers/playback/playback_notifier.dart';

/// Material 3 Expressive color roles matching the `.dc.html` spec.
class M3StylePalette {
  final Color glow;
  final Color surface;
  final Color container;
  final Color on;
  final Color primary;
  final Color onPrimary;

  const M3StylePalette({
    required this.glow,
    required this.surface,
    required this.container,
    required this.on,
    required this.primary,
    required this.onPrimary,
  });

  factory M3StylePalette.fromAccent(Color accent, {required bool useAccent}) {
    if (!useAccent) {
      return const M3StylePalette(
        glow: Color(0x0FFFFFFF),
        surface: Color(0xF20A0A0C),
        container: Color(0x1FFFFFFF),
        on: Colors.white,
        primary: Colors.white,
        onPrimary: Color(0xFF0A0A0A),
      );
    }
    final primary = Color.lerp(accent, Colors.white, 0.45)!;
    final onPrimary =
        ThemeData.estimateBrightnessForColor(primary) == Brightness.dark
        ? Colors.white
        : const Color(0xFF111111);
    return M3StylePalette(
      glow: accent.withValues(alpha: 0.28),
      surface: Color.lerp(
        accent,
        const Color(0xFF08080A),
        0.92,
      )!.withValues(alpha: 0.95),
      container: accent.withValues(alpha: 0.20),
      on: Color.lerp(accent, Colors.white, 0.72)!,
      primary: primary,
      onPrimary: onPrimary,
    );
  }
}

/// Shapes from the `.dc.html` specs (`squircle`, `scallop`, `clover`, `burst`, `arch`).
enum ExpressiveArtShape { squircle, scallop, clover, burst, arch }

/// Deterministic per-song shape for Style 9 (M3 Wavy).
ExpressiveArtShape expressiveShapeForSong(int songId, int styleSeed) {
  const pool = [
    ExpressiveArtShape.clover,
    ExpressiveArtShape.scallop,
    ExpressiveArtShape.arch,
    ExpressiveArtShape.squircle,
  ];
  final int hash = (songId * 2654435761) ^ (styleSeed * 1597334677);
  return pool[hash.abs() % pool.length];
}

/// Clips artwork into the exact Material 3 Expressive shapes from the spec.
class ExpressiveShapeClipper extends CustomClipper<Path> {
  final ExpressiveArtShape shape;
  const ExpressiveShapeClipper(this.shape);

  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2;
    final maxR = math.min(cx, cy);

    if (shape == ExpressiveArtShape.squircle) {
      return Path()
        ..addRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(0, 0, w, h),
            Radius.circular(math.min(w, h) * 0.22),
          ),
        );
    }

    if (shape == ExpressiveArtShape.arch) {
      return Path()
        ..addRRect(
          RRect.fromRectAndCorners(
            Rect.fromLTWH(0, 0, w, h),
            topLeft: Radius.circular(maxR),
            topRight: Radius.circular(maxR),
            bottomLeft: Radius.circular(w * 0.12),
            bottomRight: Radius.circular(w * 0.12),
          ),
        );
    }

    final (int lobes, double base, double amp, double phase) = switch (shape) {
      ExpressiveArtShape.scallop => (12, 0.92, 0.06, 0.0),
      ExpressiveArtShape.clover => (4, 0.80, 0.18, math.pi / 4),
      ExpressiveArtShape.burst => (8, 0.89, 0.09, 0.0),
      ExpressiveArtShape.squircle || ExpressiveArtShape.arch => (4, 1.0, 0.0, 0.0),
    };

    const steps = 144;
    final path = Path();
    for (int i = 0; i <= steps; i++) {
      final theta = (i / steps) * math.pi * 2;
      final r = maxR * (base + amp * math.cos(lobes * (theta + phase)));
      final x = cx + r * math.cos(theta);
      final y = cy + r * math.sin(theta);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  @override
  bool shouldReclip(ExpressiveShapeClipper old) => old.shape != shape;
}

/// 7-scallop bottom wave edge from `Scallop.dc.html`.
class ScallopEdgeClipper extends CustomClipper<Path> {
  const ScallopEdgeClipper();

  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    final p = Path()
      ..moveTo(0, 0)
      ..lineTo(w, 0)
      ..lineTo(w, h * 0.92);
    const scallops = 7;
    for (int i = scallops - 1; i >= 0; i--) {
      final ctrlX = w * ((i + 0.5) / scallops);
      final endX = w * (i / scallops);
      p.quadraticBezierTo(ctrlX, h, endX, h * 0.92);
    }
    p.close();
    return p;
  }

  @override
  bool shouldReclip(ScallopEdgeClipper old) => false;
}

/// Outer clover spins clockwise while inner artwork counter-spins to stay upright.
class CounterSpinningCloverArt extends StatefulWidget {
  final bool playing;
  final Widget child;
  const CounterSpinningCloverArt({
    super.key,
    required this.playing,
    required this.child,
  });

  @override
  State<CounterSpinningCloverArt> createState() =>
      _CounterSpinningCloverArtState();
}

class _CounterSpinningCloverArtState extends State<CounterSpinningCloverArt>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 24),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(CounterSpinningCloverArt old) {
    super.didUpdateWidget(old);
    if (old.playing != widget.playing) _sync();
  }

  void _sync() {
    if (widget.playing && !Motion.reducedOf(context)) {
      if (!_spin.isAnimating) _spin.repeat();
    } else {
      if (_spin.isAnimating) _spin.stop();
    }
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: AnimatedBuilder(
      animation: _spin,
      child: RepaintBoundary(child: widget.child),
      builder: (_, child) {
        final angle = _spin.value * math.pi * 2;
        return Transform.rotate(
          angle: angle,
          child: ClipPath(
            clipper: const ExpressiveShapeClipper(ExpressiveArtShape.clover),
            child: Transform.rotate(angle: -angle, child: child),
          ),
        );
      },
    ),
  );
}

/// 12-point spinning burst Play/Pause FAB from `Burst.dc.html`.
class SpinningBurstPlayButton extends StatefulWidget {
  final bool playing;
  final double size;
  final Color color;
  final Color iconColor;
  final VoidCallback onTap;

  const SpinningBurstPlayButton({
    super.key,
    required this.playing,
    required this.size,
    required this.color,
    required this.iconColor,
    required this.onTap,
  });

  @override
  State<SpinningBurstPlayButton> createState() =>
      _SpinningBurstPlayButtonState();
}

class _SpinningBurstPlayButtonState extends State<SpinningBurstPlayButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 14),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(SpinningBurstPlayButton old) {
    super.didUpdateWidget(old);
    if (old.playing != widget.playing) _sync();
  }

  void _sync() {
    if (widget.playing && !Motion.reducedOf(context)) {
      if (!_spin.isAnimating) _spin.repeat();
    } else {
      if (_spin.isAnimating) _spin.stop();
    }
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    return RepaintBoundary(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: SizedBox.square(
          dimension: s,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 240),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, a) => FadeTransition(
                  opacity: a,
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.88, end: 1.0).animate(a),
                    child: child,
                  ),
                ),
                child: widget.playing
                    ? AnimatedBuilder(
                        key: const ValueKey('burst_play'),
                        animation: _spin,
                        child: RepaintBoundary(
                          child: CustomPaint(
                            size: Size.square(s),
                            painter: _BurstPolygonPainter(color: widget.color),
                          ),
                        ),
                        builder: (_, child) => Transform.rotate(
                          angle: _spin.value * math.pi * 2,
                          child: child,
                        ),
                      )
                    : Container(
                        key: const ValueKey('burst_pause'),
                        width: s * 0.85,
                        height: s * 0.85,
                        decoration: BoxDecoration(
                          color: widget.color,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.4),
                              offset: const Offset(0, 10),
                              blurRadius: 20,
                            ),
                          ],
                        ),
                      ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: Icon(
                  widget.playing
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  key: ValueKey(widget.playing),
                  size: s * 0.36,
                  color: widget.iconColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BurstPolygonPainter extends CustomPainter {
  final Color color;
  const _BurstPolygonPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final scale = size.width / 100;
    final path = Path();
    const n = 12;
    for (int i = 0; i < n * 2; i++) {
      final a = math.pi * i / n - math.pi / 2;
      final r = (i.isOdd ? 37.0 : 45.0) * scale;
      final x = cx + math.cos(a) * r;
      final y = cy + math.sin(a) * r;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawShadow(path, Colors.black.withValues(alpha: 0.45), 12, false);
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8 * scale
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_BurstPolygonPainter old) => old.color != color;
}

/// Shared scrub helper for M3 Expressive seekbars.
mixin _M3Scrubbing<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  double? dragFraction;

  void scrubStart(double f) {
    ref.read(playbackProvider.notifier).startScrubbing();
    setState(() => dragFraction = f);
  }

  void scrubUpdate(double f) => setState(() => dragFraction = f);

  void scrubEnd() {
    final f = dragFraction;
    final playback = ref.read(playbackProvider.notifier);
    if (f != null) {
      final d = ref.read(playbackProvider).duration;
      playback.seek(d * f);
    }
    playback.stopScrubbing();
    setState(() => dragFraction = null);
  }

  void tapSeek(double f) {
    AppHaptics.light();
    final d = ref.read(playbackProvider).duration;
    ref.read(playbackProvider.notifier).seek(d * f);
  }
}

TextStyle _m3TimeStyle(double s, {bool spaceGrotesk = false}) => TextStyle(
  fontFamily: spaceGrotesk ? 'Space Grotesk' : 'DM Sans',
  fontSize: 12.5 * s,
  fontWeight: spaceGrotesk ? FontWeight.w500 : FontWeight.w600,
  color: Colors.white.withValues(alpha: 0.62),
  fontFeatures: const [FontFeature.tabularFigures()],
);

/// Material 3 Expressive wavy progress seekbar (reversed wave direction).
class M3WavySeekRow extends ConsumerStatefulWidget {
  final double scale;
  final Color activeColor;
  final bool showEndDot;
  final bool spaceGroteskTimes;
  const M3WavySeekRow({
    super.key,
    required this.scale,
    required this.activeColor,
    this.showEndDot = true,
    this.spaceGroteskTimes = false,
  });

  @override
  ConsumerState<M3WavySeekRow> createState() => _M3WavySeekRowState();
}

class _M3WavySeekRowState extends ConsumerState<M3WavySeekRow>
    with SingleTickerProviderStateMixin, _M3Scrubbing<M3WavySeekRow> {
  late final AnimationController _wave;

  @override
  void initState() {
    super.initState();
    _wave = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
  }

  @override
  void dispose() {
    _wave.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.scale;
    final isPlaying = ref.watch(playbackProvider.select((p) => p.isPlaying));
    final position = ref.watch(playbackProvider.select((p) => p.position));
    final duration = ref.watch(playbackProvider.select((p) => p.duration));
    final reduced = Motion.reducedOf(context);

    if (isPlaying && !reduced) {
      if (!_wave.isAnimating) _wave.repeat();
    } else {
      if (_wave.isAnimating) _wave.stop();
    }

    final ms = duration.inMilliseconds;
    final f =
        dragFraction ??
        (ms <= 0 ? 0.0 : (position.inMilliseconds / ms).clamp(0.0, 1.0));
    final shown = dragFraction != null ? duration * dragFraction! : position;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 28 * s,
          child: LayoutBuilder(
            builder: (context, box) {
              double at(Offset p) => (p.dx / box.maxWidth).clamp(0.0, 1.0);
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: (d) => tapSeek(at(d.localPosition)),
                onHorizontalDragStart: (d) => scrubStart(at(d.localPosition)),
                onHorizontalDragUpdate: (d) => scrubUpdate(at(d.localPosition)),
                onHorizontalDragEnd: (_) => scrubEnd(),
                onHorizontalDragCancel: scrubEnd,
                child: RepaintBoundary(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(
                      end: (isPlaying && !reduced) ? 4.0 * s : 0.6 * s,
                    ),
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeOutCubic,
                    builder: (_, amp, _) => AnimatedBuilder(
                      animation: _wave,
                      builder: (_, _) => CustomPaint(
                        size: Size(box.maxWidth, 28 * s),
                        painter: _M3WavyPainter(
                          fraction: f,
                          phase: _wave.value * math.pi * 2,
                          amplitude: amp,
                          activeColor: widget.activeColor,
                          scale: s,
                          showEndDot: widget.showEndDot,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(height: 4 * s),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              UiUtils.formatPlaybackDuration(shown),
              style: _m3TimeStyle(s, spaceGrotesk: widget.spaceGroteskTimes),
            ),
            Text(
              UiUtils.formatPlaybackDuration(duration),
              style: _m3TimeStyle(s, spaceGrotesk: widget.spaceGroteskTimes),
            ),
          ],
        ),
      ],
    );
  }
}

class _M3WavyPainter extends CustomPainter {
  final double fraction;
  final double phase;
  final double amplitude;
  final Color activeColor;
  final double scale;
  final bool showEndDot;
  const _M3WavyPainter({
    required this.fraction,
    required this.phase,
    required this.amplitude,
    required this.activeColor,
    required this.scale,
    required this.showEndDot,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cy = size.height / 2;
    final strokeW = 6.0 * scale;
    final thumbX = (size.width * fraction).clamp(
      6 * scale,
      size.width - 6 * scale,
    );
    final gap = 8 * scale;
    final paint = Paint()
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.round;

    if (thumbX + gap < size.width - strokeW / 2) {
      paint
        ..color = Colors.white.withValues(alpha: 0.18)
        ..style = PaintingStyle.stroke;
      canvas.drawLine(
        Offset(thumbX + gap, cy),
        Offset(size.width - strokeW / 2, cy),
        paint,
      );
    }

    if (showEndDot) {
      paint
        ..color = activeColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(size.width - 3 * scale, cy), 2.5 * scale, paint);
    }

    final activeEnd = thumbX - gap;
    if (activeEnd > strokeW / 2) {
      final path = Path();
      final freq = 0.20 / math.max(scale, 0.5);
      final step = 3.5 * scale;
      for (double x = strokeW / 2; x <= activeEnd; x += step) {
        final y = cy + math.sin(x * freq + phase) * amplitude;
        if (x == strokeW / 2) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      paint
        ..color = activeColor
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(path, paint);
    }

    paint
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(thumbX, cy),
          width: 5 * scale,
          height: 24 * scale,
        ),
        Radius.circular(2.5 * scale),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(_M3WavyPainter old) =>
      old.fraction != fraction ||
      old.phase != phase ||
      old.amplitude != amplitude ||
      old.activeColor != activeColor ||
      old.showEndDot != showEndDot;
}

/// Gapped thick-track slider used by Style 10 (Scallop) and Style 11 (Clover).
class M3GappedSeekRow extends ConsumerStatefulWidget {
  final double scale;
  final Color activeColor;
  final double barHeight;
  final double thumbHeight;
  final bool showStopDot;
  final bool inlineTimes;
  const M3GappedSeekRow({
    super.key,
    required this.scale,
    required this.activeColor,
    this.barHeight = 18,
    this.thumbHeight = 40,
    this.showStopDot = true,
    this.inlineTimes = false,
  });

  @override
  ConsumerState<M3GappedSeekRow> createState() => _M3GappedSeekRowState();
}

class _M3GappedSeekRowState extends ConsumerState<M3GappedSeekRow>
    with _M3Scrubbing<M3GappedSeekRow> {
  @override
  Widget build(BuildContext context) {
    final s = widget.scale;
    final position = ref.watch(playbackProvider.select((p) => p.position));
    final duration = ref.watch(playbackProvider.select((p) => p.duration));
    final ms = duration.inMilliseconds;
    final f =
        dragFraction ??
        (ms <= 0 ? 0.0 : (position.inMilliseconds / ms).clamp(0.0, 1.0));
    final shown = dragFraction != null ? duration * dragFraction! : position;

    final track = SizedBox(
      height: widget.thumbHeight * s,
      child: LayoutBuilder(
        builder: (context, box) {
          double at(Offset p) => (p.dx / box.maxWidth).clamp(0.0, 1.0);
          final thumbX = (box.maxWidth * f).clamp(4 * s, box.maxWidth - 4 * s);
          final gap = (widget.inlineTimes ? 5 : 6) * s;
          final bh = widget.barHeight * s;
          final outerR = bh / 2;
          final innerR = (widget.inlineTimes ? 2 : 3) * s;
          final activeW = math.max(0.0, thumbX - gap);
          final inactiveLeft = thumbX + gap;
          final inactiveW = math.max(0.0, box.maxWidth - inactiveLeft);

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (d) => tapSeek(at(d.localPosition)),
            onHorizontalDragStart: (d) => scrubStart(at(d.localPosition)),
            onHorizontalDragUpdate: (d) => scrubUpdate(at(d.localPosition)),
            onHorizontalDragEnd: (_) => scrubEnd(),
            onHorizontalDragCancel: scrubEnd,
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                if (activeW > 0)
                  Positioned(
                    left: 0,
                    width: activeW,
                    height: bh,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: widget.activeColor,
                        borderRadius: BorderRadius.horizontal(
                          left: Radius.circular(outerR),
                          right: Radius.circular(innerR),
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  left: thumbX - 2.5 * s,
                  width: (widget.inlineTimes ? 4 : 5) * s,
                  height: widget.thumbHeight * s,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(3 * s),
                    ),
                  ),
                ),
                if (inactiveW > 0)
                  Positioned(
                    left: inactiveLeft,
                    width: inactiveW,
                    height: bh,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.horizontal(
                          left: Radius.circular(innerR),
                          right: Radius.circular(outerR),
                        ),
                      ),
                      child: widget.showStopDot
                          ? Align(
                              alignment: Alignment.centerRight,
                              child: Padding(
                                padding: EdgeInsets.only(right: 6 * s),
                                child: Container(
                                  width: 6 * s,
                                  height: 6 * s,
                                  decoration: BoxDecoration(
                                    color: widget.activeColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            )
                          : null,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );

    if (widget.inlineTimes) {
      return Row(
        children: [
          SizedBox(
            width: 36 * s,
            child: Text(
              UiUtils.formatPlaybackDuration(shown),
              style: _m3TimeStyle(s),
            ),
          ),
          SizedBox(width: 10 * s),
          Expanded(child: track),
          SizedBox(width: 10 * s),
          SizedBox(
            width: 36 * s,
            child: Text(
              UiUtils.formatPlaybackDuration(duration),
              textAlign: TextAlign.right,
              style: _m3TimeStyle(s),
            ),
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        track,
        SizedBox(height: 4 * s),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(UiUtils.formatPlaybackDuration(shown), style: _m3TimeStyle(s)),
            Text(
              UiUtils.formatPlaybackDuration(duration),
              style: _m3TimeStyle(s),
            ),
          ],
        ),
      ],
    );
  }
}

const _kPlayerArtScaleKey = 'player_art_scale_v1';

class PlayerArtScaleNotifier extends Notifier<double> {
  @override
  double build() {
    final raw = LocalJsonStore.readSync(_kPlayerArtScaleKey);
    if (raw is num) return raw.toDouble().clamp(0.70, 1.15);
    return 1.0;
  }

  void setScale(double value) {
    final clamped = value.clamp(0.70, 1.15);
    state = clamped;
    LocalJsonStore.write(_kPlayerArtScaleKey, clamped);
  }
}

final playerArtScaleProvider =
    NotifierProvider<PlayerArtScaleNotifier, double>(
      PlayerArtScaleNotifier.new,
    );
