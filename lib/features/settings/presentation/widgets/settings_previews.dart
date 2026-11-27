import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:looper_player/core/services/haptics/app_haptics.dart';
import 'package:looper_player/core/utils/motion.dart';
import 'package:looper_player/l10n/app_localizations.dart';
import 'package:looper_player/ui/android/player/lyrics/lyrics_screen_style.dart';
import 'package:looper_player/ui/android/shell/bar_styles.dart';

/// Skeleton previews and looping demos for settings rows. Everything is
/// drawn in code with grey blocks and the accent, so it costs no assets
/// and follows the theme.

const _skeleton = Color(0x24FFFFFF);
const _skeletonDim = Color(0x14FFFFFF);

/// Repeating 0..1 clock for a preview; frozen half way with reduced motion.
class _Loop extends StatefulWidget {
  const _Loop({super.key, required this.period, required this.builder});

  final Duration period;
  final Widget Function(double t) builder;

  @override
  State<_Loop> createState() => _LoopState();
}

class _LoopState extends State<_Loop> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.period,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Motion.reducedOf(context)) {
      _c.value = 0.5;
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: AnimatedBuilder(
      animation: _c,
      builder: (_, _) => widget.builder(_c.value),
    ),
  );
}

/// Frame every preview sits in.
class _PreviewFrame extends StatelessWidget {
  const _PreviewFrame({required this.height, required this.child});

  final double height;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    height: height,
    width: double.infinity,
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.04),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.white10, width: 0.5),
    ),
    clipBehavior: Clip.antiAlias,
    child: child,
  );
}

/// Mini Now Playing skeleton for 'classic', 'arc' or 'linear'; the seek
/// bar runs so it reads as a live player.
class PlayerStylePreview extends StatelessWidget {
  const PlayerStylePreview({
    super.key,
    required this.style,
    required this.accent,
  });

  final String style;
  final Color accent;

  @override
  Widget build(BuildContext context) => _PreviewFrame(
    height: 150,
    child: AnimatedSwitcher(
      duration: Duration(milliseconds: Motion.reducedOf(context) ? 0 : 280),
      child: _Loop(
        key: ValueKey(style),
        period: const Duration(seconds: 6),
        builder: (t) => CustomPaint(
          size: Size.infinite,
          painter: _PlayerStylePainter(style, accent, t),
        ),
      ),
    ),
  );
}

class _PlayerStylePainter extends CustomPainter {
  _PlayerStylePainter(this.style, this.accent, this.t);

  final String style;
  final Color accent;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()..color = _skeleton;
    final dim = Paint()..color = _skeletonDim;
    final acc = Paint()..color = accent;
    final w = size.width;
    final cx = w / 2;
    RRect r(double x, double y, double rw, double rh, [double rad = 3]) =>
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, rw, rh),
          Radius.circular(rad),
        );

    switch (style) {
      case 'arc':
        // Big cover, seek bar curving under it, controls below.
        final art = Rect.fromCenter(
          center: Offset(cx, 52),
          width: 76,
          height: 76,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(art, const Radius.circular(10)),
          fill,
        );
        final arc = Rect.fromCenter(
          center: Offset(cx, 52),
          width: 104,
          height: 104,
        );
        final track = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round;
        canvas.drawArc(
          arc,
          math.pi * 0.15,
          math.pi * 0.7,
          false,
          track..color = _skeleton,
        );
        canvas.drawArc(
          arc,
          math.pi * 0.85,
          -math.pi * 0.7 * t,
          false,
          track..color = accent,
        );
        canvas.drawRRect(r(cx - 34, 116, 68, 6), fill);
        canvas.drawRRect(r(cx - 22, 127, 44, 5), dim);
        for (var i = 0; i < 3; i++) {
          canvas.drawCircle(
            Offset(cx + (i - 1) * 22, 141),
            i == 1 ? 6 : 4,
            i == 1 ? acc : fill,
          );
        }
      case 'linear':
        // Cover full width at the top, big title, straight bar.
        canvas.drawRect(Rect.fromLTWH(0, 0, w, 78), fill);
        canvas.drawRRect(r(16, 88, w * 0.55, 9), fill);
        canvas.drawRRect(r(16, 102, w * 0.3, 6), dim);
        canvas.drawRRect(r(16, 118, w - 32, 3, 2), dim);
        canvas.drawRRect(r(16, 118, (w - 32) * t, 3, 2), acc);
        for (var i = 0; i < 3; i++) {
          canvas.drawCircle(
            Offset(cx + (i - 1) * 26, 135),
            i == 1 ? 7 : 5,
            i == 1 ? acc : fill,
          );
        }
      case 'card':
        // Card style: floating card artwork, seekbar row directly under, lyrics on left, controls on right.
        final art = Rect.fromCenter(
          center: Offset(cx, 38),
          width: 58,
          height: 58,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(art, const Radius.circular(5)),
          fill,
        );
        const barY = 74.0;
        final barX = cx - w * 0.38;
        final barW = w * 0.76;
        canvas.drawRRect(r(barX, barY, 14, 4, 1.5), fill);
        canvas.drawRRect(r(barX + 18, barY + 1, barW - 36, 2, 1), dim);
        canvas.drawRRect(r(barX + 18, barY + 1, (barW - 36) * t, 2, 1), acc);
        canvas.drawRRect(r(barX + barW - 14, barY, 14, 4, 1.5), dim);
        canvas.drawRRect(r(18, 88, w * 0.45, 8, 2), acc);
        canvas.drawRRect(r(18, 100, w * 0.38, 5, 2), dim);
        canvas.drawRRect(r(18, 118, w * 0.32, 7, 2), fill);
        canvas.drawRRect(r(18 + w * 0.32 + 4, 119, 12, 6, 2), dim);
        canvas.drawRRect(r(18, 129, w * 0.22, 5, 2), dim);
        final ctrlX = w - 22;
        canvas.drawCircle(Offset(ctrlX, 90), 3.5, dim);
        canvas.drawCircle(Offset(ctrlX, 104), 3.5, fill);
        canvas.drawCircle(Offset(ctrlX, 118), 5.5, acc);
        canvas.drawCircle(Offset(ctrlX, 132), 3.5, fill);
        canvas.drawCircle(Offset(ctrlX, 144), 3, dim);
      case 'disc':
        canvas.drawCircle(Offset(cx, 44), 32, fill);
        final arc = Rect.fromCenter(
          center: Offset(cx, 44),
          width: 82,
          height: 82,
        );
        final track = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round;
        canvas.drawArc(arc, math.pi * 0.2, math.pi * 0.6, false, track..color = _skeleton);
        canvas.drawArc(arc, math.pi * 0.8, -math.pi * 0.6 * t, false, track..color = accent);
        canvas.drawRRect(r(18, 108, w * 0.45, 9, 2), fill);
        canvas.drawRRect(r(18, 121, w * 0.32, 6, 2), dim);
        final ctrlX = w - 22;
        canvas.drawCircle(Offset(ctrlX, 106), 4, fill);
        canvas.drawCircle(Offset(ctrlX, 120), 6, acc);
        canvas.drawCircle(Offset(ctrlX, 134), 4, fill);
      case 'asymmetric':
        canvas.drawRRect(
          RRect.fromRectAndCorners(
            Rect.fromLTWH(0, 0, w * 0.72, 68),
            bottomRight: const Radius.circular(14),
          ),
          fill,
        );
        canvas.drawRRect(r(16, 78, w - 32, 3, 2), dim);
        canvas.drawRRect(r(16, 78, (w - 32) * t, 3, 2), acc);
        canvas.drawRRect(r(16, 106, w * 0.45, 9, 2), fill);
        canvas.drawRRect(r(16, 120, w * 0.30, 6, 2), dim);
        final ctrlX = w - 22;
        canvas.drawCircle(Offset(ctrlX, 104), 4, fill);
        canvas.drawCircle(Offset(ctrlX, 118), 6, acc);
        canvas.drawCircle(Offset(ctrlX, 132), 4, fill);
      case 'fullbleed':
        canvas.drawRect(Rect.fromLTWH(0, 0, w, 78), fill);
        canvas.drawRRect(r(16, 86, w * 0.55, 9), fill);
        canvas.drawRRect(r(16, 100, w * 0.3, 6), dim);
        canvas.drawRRect(r(16, 122, w - 32, 3, 2), dim);
        canvas.drawRRect(r(16, 122, (w - 32) * t, 3, 2), acc);
      case 'capsule':
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(cx, 38), width: 64, height: 64),
            const Radius.circular(22),
          ),
          fill,
        );
        canvas.drawRRect(r(18, 80, w - 36, 5, 2.5), dim);
        canvas.drawRRect(r(18, 80, (w - 36) * t, 5, 2.5), acc);
        canvas.drawRRect(r(18, 108, w * 0.44, 9, 2), fill);
        canvas.drawRRect(r(18, 122, w * 0.30, 6, 2), dim);
      case 'm3wavy' || 'm3scallop' || 'm3clover' || 'm3burst':
        final rad = style == 'm3wavy' ? 14.0 : 28.0;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(cx, 38), width: 62, height: 62),
            Radius.circular(rad),
          ),
          fill,
        );
        canvas.drawRRect(r(18, 84, w * 0.52, 8, 2), fill);
        canvas.drawRRect(r(18, 96, w * 0.34, 5, 2), dim);
        canvas.drawRRect(r(18, 112, w - 36, 4, 2), dim);
        canvas.drawRRect(r(18, 112, (w - 36) * t, 4, 2), acc);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(cx, 134), width: 24, height: 18),
            const Radius.circular(7),
          ),
          acc,
        );
        canvas.drawCircle(Offset(cx - 28, 134), 6, fill);
        canvas.drawCircle(Offset(cx + 28, 134), 6, fill);
      default:
        // Classic: rounded cover, title, seek bar, transport row.
        canvas.drawRRect(r(cx - 40, 10, 80, 64, 8), fill);
        canvas.drawRRect(r(cx - 36, 82, 72, 7), fill);
        canvas.drawRRect(r(cx - 24, 94, 48, 5), dim);
        final barX = cx - w * 0.32, barW = w * 0.64;
        canvas.drawRRect(r(barX, 108, barW, 3, 2), dim);
        canvas.drawRRect(r(barX, 108, barW * t, 3, 2), acc);
        canvas.drawCircle(Offset(barX + barW * t, 109.5), 4, acc);
        for (var i = 0; i < 3; i++) {
          canvas.drawCircle(
            Offset(cx + (i - 1) * 28, 132),
            i == 1 ? 9 : 6,
            i == 1 ? acc : fill,
          );
        }
    }
  }

  @override
  bool shouldRepaint(_PlayerStylePainter old) =>
      old.t != t || old.style != style || old.accent != accent;
}

/// Lyrics skeleton aligned 'left', 'center' or 'right'; the active line
/// steps down so the alignment reads in motion.
class LyricsAlignmentPreview extends StatelessWidget {
  const LyricsAlignmentPreview({
    super.key,
    required this.alignment,
    required this.accent,
  });

  final String alignment;
  final Color accent;

  @override
  Widget build(BuildContext context) => _PreviewFrame(
    height: 92,
    child: _Loop(
      period: const Duration(seconds: 4),
      builder: (t) => CustomPaint(
        size: Size.infinite,
        painter: _LyricsAlignPainter(alignment, accent, t),
      ),
    ),
  );
}

class _LyricsAlignPainter extends CustomPainter {
  _LyricsAlignPainter(this.alignment, this.accent, this.t);

  final String alignment;
  final Color accent;
  final double t;

  static const _widths = [0.62, 0.78, 0.5, 0.7];

  @override
  void paint(Canvas canvas, Size size) {
    final active = (t * _widths.length).floor() % _widths.length;
    const pad = 16.0;
    for (var i = 0; i < _widths.length; i++) {
      final lw = (size.width - pad * 2) * _widths[i];
      final x = switch (alignment) {
        'center' => (size.width - lw) / 2,
        'right' => size.width - pad - lw,
        _ => pad,
      };
      final paint = Paint()..color = i == active ? accent : _skeleton;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, 14 + i * 18.0, lw, i == active ? 9 : 7),
          const Radius.circular(4),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_LyricsAlignPainter old) =>
      old.t != t || old.alignment != alignment || old.accent != accent;
}

/// Which looping demo a toggle shows.
enum SettingsDemoKind { crossfade, fade, gradient, segmentedButtons, lyricLine }

/// Wraps a settings row: long-press slides a short looping demo of what
/// the option does open below it (and shut again).
class SettingsDemo extends StatefulWidget {
  const SettingsDemo({
    super.key,
    required this.kind,
    required this.accent,
    required this.child,
  });

  final SettingsDemoKind kind;
  final Color accent;
  final Widget child;

  @override
  State<SettingsDemo> createState() => _SettingsDemoState();
}

class _SettingsDemoState extends State<SettingsDemo> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          onLongPressHint: l10n.showPreview,
          child: GestureDetector(
            onLongPress: () {
              AppHaptics.medium();
              setState(() => _open = !_open);
            },
            child: widget.child,
          ),
        ),
        AnimatedSize(
          duration: Duration(milliseconds: Motion.reducedOf(context) ? 0 : 240),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: !_open
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: _PreviewFrame(
                    height: 64,
                    child: _Loop(
                      period: const Duration(milliseconds: 3200),
                      builder: (t) => CustomPaint(
                        size: Size.infinite,
                        painter: _DemoPainter(widget.kind, widget.accent, t),
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

class _DemoPainter extends CustomPainter {
  _DemoPainter(this.kind, this.accent, this.t);

  final SettingsDemoKind kind;
  final Color accent;
  final double t;

  static double _smooth(double a, double b, double x) {
    final v = ((x - a) / (b - a)).clamp(0.0, 1.0);
    return v * v * (3 - 2 * v);
  }

  /// A row of waveform bars from [x0] to [x1], scaled by [gain].
  void _wave(
    Canvas c,
    double x0,
    double x1,
    double midY,
    double gain,
    Paint p,
  ) {
    const step = 5.0;
    for (var x = x0; x < x1; x += step) {
      final amp = (0.35 + 0.65 * (math.sin(x * 0.37) * 0.5 + 0.5)) * 16 * gain;
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(x, midY),
            width: 3,
            height: math.max(2, amp * 2),
          ),
          const Radius.circular(1.5),
        ),
        p,
      );
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final grey = Paint()..color = _skeleton;
    final acc = Paint()..color = accent;
    switch (kind) {
      case SettingsDemoKind.crossfade:
        // Outgoing song fades as the next one rises under it.
        final b = _smooth(0.25, 0.75, t);
        _wave(canvas, 14, w - 14, h * 0.33, 1 - b, grey);
        _wave(canvas, 14, w - 14, h * 0.67, b, acc);
      case SettingsDemoKind.fade:
        // Volume eases down to pause, then back up on play.
        final g = t < 0.5 ? 1 - _smooth(0.1, 0.45, t) : _smooth(0.55, 0.9, t);
        _wave(canvas, 14, w - 14, h / 2, g, acc);
      case SettingsDemoKind.gradient:
        // Colour wash drifting behind the player.
        final a = t * math.pi * 2;
        canvas.drawRect(Offset.zero & size, Paint()..color = Colors.black26);
        for (final (i, color) in [
          accent,
          accent.withValues(alpha: 0.5),
        ].indexed) {
          final phase = a + i * math.pi;
          final c = Offset(
            w / 2 + math.cos(phase) * w * 0.25,
            h / 2 + math.sin(phase) * h * 0.2,
          );
          canvas.drawCircle(
            c,
            h * 0.9,
            Paint()
              ..shader = RadialGradient(
                colors: [
                  color.withValues(alpha: 0.55),
                  color.withValues(alpha: 0),
                ],
              ).createShader(Rect.fromCircle(center: c, radius: h * 0.9)),
          );
        }
      case SettingsDemoKind.segmentedButtons:
        // Four utility buttons pulling apart into separate pills and back.
        final split = _smooth(0.2, 0.45, t) * (1 - _smooth(0.7, 0.95, t));
        const n = 4;
        final gap = 10 * split;
        final total = w * 0.7;
        final bw = (total - gap * (n - 1)) / n;
        final x0 = (w - total) / 2;
        for (var i = 0; i < n; i++) {
          final rect = Rect.fromLTWH(x0 + i * (bw + gap), h / 2 - 12, bw, 24);
          final outer = 12.0, inner = 12 * split;
          canvas.drawRRect(
            RRect.fromRectAndCorners(
              rect,
              topLeft: Radius.circular(i == 0 ? outer : inner),
              bottomLeft: Radius.circular(i == 0 ? outer : inner),
              topRight: Radius.circular(i == n - 1 ? outer : inner),
              bottomRight: Radius.circular(i == n - 1 ? outer : inner),
            ),
            i == 1 ? acc : grey,
          );
        }
      case SettingsDemoKind.lyricLine:
        // Current line rolls up and the next one takes its place.
        final roll = _smooth(0.6, 0.9, t);
        canvas.clipRect(Offset.zero & size);
        final y = h / 2 - roll * 22;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(w * 0.2, y - 5, w * 0.6, 10),
            const Radius.circular(5),
          ),
          Paint()..color = accent.withValues(alpha: 1 - roll),
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(w * 0.28, y + 17, w * 0.44, 10),
            const Radius.circular(5),
          ),
          Paint()..color = Color.lerp(_skeleton, accent, roll)!,
        );
    }
  }

  @override
  bool shouldRepaint(_DemoPainter old) =>
      old.t != t || old.kind != kind || old.accent != accent;
}

/// Neutral skeleton preview for each [MusicBarStyle].
class MusicBarStyleSkeleton extends StatelessWidget {
  final MusicBarStyle style;
  const MusicBarStyleSkeleton({super.key, required this.style});

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: CustomPaint(
      size: Size.infinite,
      painter: _MusicBarSkeletonPainter(style),
    ),
  );
}

class _MusicBarSkeletonPainter extends CustomPainter {
  final MusicBarStyle style;
  const _MusicBarSkeletonPainter(this.style);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final fill = Paint()..color = const Color(0xFF1E1E1E);
    final fillBright = Paint()..color = Colors.white.withValues(alpha: 0.14);
    final border = Paint()
      ..color = Colors.white.withValues(alpha: 0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final hi = Paint()..color = Colors.white.withValues(alpha: 0.78);
    final dim = Paint()..color = Colors.white.withValues(alpha: 0.30);

    final barH = h * 0.56;
    final top = (h - barH) / 2;
    final padX = w * 0.06;
    final barW = w - padX * 2;

    switch (style) {
      case MusicBarStyle.pill:
        final rect = Rect.fromLTWH(padX, top, barW, barH);
        final rr = RRect.fromRectAndRadius(rect, Radius.circular(barH / 2));
        canvas.drawRRect(rr, fill);
        canvas.drawRRect(rr, border);
        final artR = barH * 0.34;
        canvas.drawCircle(
          Offset(padX + 6 + artR, h / 2),
          artR,
          fillBright,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(padX + 12 + artR * 2, h / 2 - 6, barW * 0.36, 5),
            const Radius.circular(3),
          ),
          hi,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(padX + 12 + artR * 2, h / 2 + 2, barW * 0.22, 4),
            const Radius.circular(2),
          ),
          dim,
        );
        canvas.drawCircle(Offset(padX + barW - 30, h / 2), 4.5, hi);
        canvas.drawCircle(Offset(padX + barW - 14, h / 2), 4.0, dim);

      case MusicBarStyle.sections:
        const gap = 4.0;
        final w1 = barW * 0.62;
        final w2 = (barW - w1 - gap * 2) * 0.52;
        final w3 = barW - w1 - w2 - gap * 2;
        final r1 = RRect.fromRectAndCorners(
          Rect.fromLTWH(padX, top, w1, barH),
          topLeft: Radius.circular(barH / 2),
          bottomLeft: Radius.circular(barH / 2),
          topRight: const Radius.circular(6),
          bottomRight: const Radius.circular(6),
        );
        final r2 = RRect.fromRectAndRadius(
          Rect.fromLTWH(padX + w1 + gap, top, w2, barH),
          const Radius.circular(6),
        );
        final r3 = RRect.fromRectAndCorners(
          Rect.fromLTWH(padX + w1 + w2 + gap * 2, top, w3, barH),
          topLeft: const Radius.circular(6),
          bottomLeft: const Radius.circular(6),
          topRight: Radius.circular(barH / 2),
          bottomRight: Radius.circular(barH / 2),
        );
        canvas.drawRRect(r1, fill);
        canvas.drawRRect(r1, border);
        canvas.drawRRect(r2, fillBright);
        canvas.drawRRect(r2, border);
        canvas.drawRRect(r3, fill);
        canvas.drawRRect(r3, border);
        final artR = barH * 0.32;
        canvas.drawCircle(Offset(padX + 5 + artR, h / 2), artR, fillBright);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(padX + 10 + artR * 2, h / 2 - 4, w1 * 0.42, 4),
            const Radius.circular(2),
          ),
          hi,
        );
        canvas.drawCircle(Offset(padX + w1 + gap + w2 / 2, h / 2), 4, hi);
        canvas.drawCircle(
          Offset(padX + w1 + w2 + gap * 2 + w3 / 2, h / 2),
          3.5,
          dim,
        );

      case MusicBarStyle.artglow:
        final rect = Rect.fromLTWH(padX, top, barW, barH);
        final rr = RRect.fromRectAndRadius(rect, Radius.circular(barH / 2));
        final grad = Paint()
          ..shader = const LinearGradient(
            colors: [Color(0xFF2D2538), Color(0xFF242424), Color(0xFF181818)],
          ).createShader(rect);
        canvas.drawRRect(rr, grad);
        canvas.save();
        canvas.clipRRect(rr);
        canvas.drawRect(
          Rect.fromLTWH(padX, top, barW * 0.52, barH),
          Paint()..color = Colors.white.withValues(alpha: 0.06),
        );
        canvas.restore();
        canvas.drawRRect(rr, border);
        final artR = barH * 0.34;
        canvas.drawCircle(Offset(padX + 6 + artR, h / 2), artR, fillBright);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(padX + 12 + artR * 2, h / 2 - 5, barW * 0.34, 5),
            const Radius.circular(3),
          ),
          hi,
        );
        canvas.drawCircle(Offset(padX + barW - 28, h / 2), 4.5, hi);
        canvas.drawCircle(Offset(padX + barW - 14, h / 2), 4.0, dim);

      case MusicBarStyle.bare:
        final artSz = barH * 0.66;
        final artY = top + 2;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(padX + 2, artY, artSz, artSz),
            const Radius.circular(4),
          ),
          fillBright,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(padX + artSz + 8, artY + 3, barW * 0.38, 5),
            const Radius.circular(2.5),
          ),
          hi,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(padX + artSz + 8, artY + 11, barW * 0.24, 3.5),
            const Radius.circular(2),
          ),
          dim,
        );
        canvas.drawCircle(Offset(padX + barW - 26, artY + artSz / 2), 4.5, hi);
        canvas.drawCircle(
          Offset(padX + barW - 10, artY + artSz / 2),
          4.0,
          dim,
        );
        final lineY = top + barH - 3;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(padX + 2, lineY, barW - 4, 2),
            const Radius.circular(1),
          ),
          dim,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(padX + 2, lineY, (barW - 4) * 0.45, 2),
            const Radius.circular(1),
          ),
          hi,
        );
    }
  }

  @override
  bool shouldRepaint(_MusicBarSkeletonPainter old) => old.style != style;
}

/// Neutral skeleton preview for each [NavbarStyle].
class NavbarStyleSkeleton extends StatelessWidget {
  final NavbarStyle style;
  const NavbarStyleSkeleton({super.key, required this.style});

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: CustomPaint(
      size: Size.infinite,
      painter: _NavbarSkeletonPainter(style),
    ),
  );
}

class _NavbarSkeletonPainter extends CustomPainter {
  final NavbarStyle style;
  const _NavbarSkeletonPainter(this.style);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final hi = Paint()..color = Colors.white;
    final dim = Paint()..color = const Color(0xFF5C5C5C);
    final padX = w * 0.08;
    final innerW = w - padX * 2;

    switch (style) {
      case NavbarStyle.premium:
        for (var i = 0; i < 4; i++) {
          final cx = padX + innerW * (i + 0.5) / 4;
          final sel = i == 0;
          canvas.drawCircle(Offset(cx, h * 0.40), 5.5, sel ? hi : dim);
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(center: Offset(cx, h * 0.68), width: 18, height: 3),
              const Radius.circular(1.5),
            ),
            sel ? hi : dim,
          );
        }

      case NavbarStyle.classic:
        final pillW = innerW * 0.72;
        final pillH = h * 0.54;
        final pillY = (h - pillH) / 2;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(padX, pillY, pillW, pillH),
            Radius.circular(pillH / 2),
          ),
          Paint()..color = const Color(0xFF1A1A1A),
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(padX + 4, pillY + 4, pillW * 0.34, pillH - 8),
            Radius.circular((pillH - 8) / 2),
          ),
          Paint()..color = Colors.white.withValues(alpha: 0.14),
        );
        for (var i = 0; i < 3; i++) {
          final cx = padX + pillW * (i + 0.5) / 3;
          canvas.drawCircle(Offset(cx, h / 2), 4.5, i == 0 ? hi : dim);
        }
        canvas.drawCircle(
          Offset(padX + innerW - pillH / 2, h / 2),
          pillH * 0.44,
          Paint()..color = const Color(0xFF1A1A1A),
        );
        canvas.drawCircle(Offset(padX + innerW - pillH / 2, h / 2), 4.5, hi);

      case NavbarStyle.capsule:
        final capH = h * 0.56;
        final capY = (h - capH) / 2;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(padX, capY, innerW, capH),
            Radius.circular(capH / 2),
          ),
          Paint()..color = const Color(0xFF0A0A0A),
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(padX, capY, innerW, capH),
            Radius.circular(capH / 2),
          ),
          Paint()
            ..color = Colors.white.withValues(alpha: 0.08)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1,
        );
        final actW = innerW * 0.38;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(padX + 4, capY + 4, actW, capH - 8),
            Radius.circular((capH - 8) / 2),
          ),
          Paint()..color = const Color(0xFF1F1F1F),
        );
        canvas.drawCircle(Offset(padX + 16, h / 2), 4.5, hi);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(padX + 24, h / 2 - 2, actW - 34, 4),
            const Radius.circular(2),
          ),
          hi,
        );
        for (var i = 0; i < 3; i++) {
          final cx = padX + actW + 8 + (innerW - actW - 12) * (i + 0.5) / 3;
          canvas.drawCircle(Offset(cx, h / 2), 4.5, dim);
        }

      case NavbarStyle.minimal:
        canvas.drawLine(
          Offset(0, h * 0.16),
          Offset(w, h * 0.16),
          Paint()
            ..color = Colors.white.withValues(alpha: 0.08)
            ..strokeWidth = 1,
        );
        for (var i = 0; i < 4; i++) {
          final cx = padX + innerW * (i + 0.5) / 4;
          final sel = i == 0;
          canvas.drawCircle(Offset(cx, h * 0.48), 5.5, sel ? hi : dim);
          if (sel) {
            canvas.drawRRect(
              RRect.fromRectAndRadius(
                Rect.fromCenter(
                  center: Offset(cx, h * 0.76),
                  width: 12,
                  height: 2.5,
                ),
                const Radius.circular(1.25),
              ),
              hi,
            );
          }
        }
    }
  }

  @override
  bool shouldRepaint(_NavbarSkeletonPainter old) => old.style != style;
}

/// Miniature skeleton preview for each of the 12 [LyricsScreenStyle]s.
class LyricsStyleSkeleton extends StatelessWidget {
  final LyricsScreenStyle style;
  final Color accent;
  final bool selected;

  const LyricsStyleSkeleton({
    super.key,
    required this.style,
    required this.accent,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: CustomPaint(
      size: Size.infinite,
      painter: _LyricsSkeletonPainter(style, accent, selected),
    ),
  );
}

class _LyricsSkeletonPainter extends CustomPainter {
  final LyricsScreenStyle style;
  final Color accent;
  final bool selected;

  const _LyricsSkeletonPainter(this.style, this.accent, this.selected);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final hi = Paint()..color = Colors.white.withValues(alpha: 0.85);
    final mid = Paint()..color = Colors.white.withValues(alpha: 0.35);
    final dim = Paint()..color = Colors.white.withValues(alpha: 0.16);
    final acc = Paint()..color = accent;
    final pad = 7.0;

    void bar(double x, double y, double bw, double bh, Paint p, {double r = 2}) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(x, y, bw, bh), Radius.circular(r)),
        p,
      );
    }

    // Background tint for special styles
    if (style == LyricsScreenStyle.oled) {
      canvas.drawRect(Offset.zero & size, Paint()..color = Colors.black);
    } else if (style == LyricsScreenStyle.vinyl) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()..color = const Color(0xFF140E0B),
      );
    } else if (style == LyricsScreenStyle.bigtype) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()..color = Color.lerp(const Color(0xFF080808), accent, 0.12)!,
      );
    } else if (style == LyricsScreenStyle.karaoke) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(0, -1.0),
            radius: 1.0,
            colors: [accent.withValues(alpha: 0.32), Colors.transparent],
          ).createShader(Offset.zero & size),
      );
    }

    switch (style) {
      case LyricsScreenStyle.classic:
      case LyricsScreenStyle.arc:
        bar(pad, 8, 12, 12, mid, r: 3);
        bar(pad + 16, 10, w - pad * 2 - 18, 4, hi);
        bar(pad + 16, 16, (w - pad * 2) * 0.5, 3, dim);
        bar(pad, 32, w * 0.62, 5, dim);
        bar(pad, 41, w * 0.72, 6, hi);
        bar(pad, 51, w * 0.52, 5, dim);
        bar(pad, h - 18, w - pad * 2, 2.5, mid);
        bar(pad, h - 12, (w - pad * 2) * 0.45, 7, acc, r: 4);
        bar(pad + (w - pad * 2) * 0.52, h - 12, (w - pad * 2) * 0.48, 7, dim, r: 4);

      case LyricsScreenStyle.spatial:
        bar(w * 0.16, 8, w * 0.68, 9, dim, r: 5);
        bar(pad, 30, w * 0.58, 5, dim);
        bar(pad, 40, w * 0.76, 7, hi);
        bar(pad, 52, w * 0.48, 5, dim);
        bar(pad, h - 15, w - pad * 2, 9, dim, r: 5);
        canvas.drawCircle(Offset(pad + 5, h - 10.5), 3, hi);

      case LyricsScreenStyle.vinyl:
        canvas.drawCircle(Offset(pad + 6, 14), 6, dim);
        canvas.drawCircle(Offset(pad + 6, 14), 2.5, Paint()..color = const Color(0xFFD9B97F));
        bar(pad + 16, 11, w * 0.52, 4, Paint()..color = const Color(0xFFF1D9AE));
        bar(pad, 28, w * 0.6, 5, dim);
        bar(pad, 38, w * 0.7, 6, Paint()..color = const Color(0xFFF1D9AE));
        bar(pad, 48, w * 0.5, 5, dim);
        bar(pad, h - 14, w - pad * 2, 1.5, Paint()..color = const Color(0xFFD9B97F));
        canvas.drawCircle(Offset(w / 2, h - 7), 3, Paint()..color = const Color(0xFFF1D9AE));

      case LyricsScreenStyle.editorial:
        bar(pad, 8, w * 0.35, 3, dim);
        bar(pad, 13, w * 0.65, 5, hi);
        bar(pad, 22, w - pad * 2, 1, dim);
        bar(pad, 32, w * 0.58, 5, dim);
        bar(pad, 41, 1.5, 10, acc, r: 0);
        bar(pad + 5, 43, w * 0.66, 6, hi);
        bar(pad, 56, w * 0.48, 5, dim);
        bar(pad, h - 13, w - pad * 2, 1.5, mid);
        bar(w * 0.38, h - 8, w * 0.24, 3, hi);

      case LyricsScreenStyle.karaoke:
        bar(w * 0.25, 8, w * 0.5, 4, acc, r: 2);
        bar(w * 0.2, 15, w * 0.6, 4, hi);
        bar(w * 0.2, 32, w * 0.6, 4, dim);
        bar(w * 0.14, 41, w * 0.72, 7, acc);
        bar(w * 0.22, 52, w * 0.56, 4, dim);
        canvas.drawCircle(Offset(w / 2, h - 12), 7, acc);

      case LyricsScreenStyle.poster:
        bar(0, 0, w, h * 0.42, Paint()..color = Colors.white.withValues(alpha: 0.10), r: 0);
        bar(pad, h * 0.28, w * 0.55, 6, hi);
        canvas.drawCircle(Offset(w - pad - 5, h * 0.31), 5, acc);
        bar(pad, h * 0.50, w * 0.65, 5, hi);
        bar(pad, h * 0.60, w * 0.5, 5, dim);
        bar(pad, h - 10, w - pad * 2, 3, mid);

      case LyricsScreenStyle.oled:
        bar(pad, 8, w * 0.4, 3, dim);
        bar(w - pad - 12, 8, 12, 3, dim);
        bar(pad, 30, w * 0.6, 5, dim);
        bar(pad, 40, w * 0.72, 6, hi);
        bar(pad, 51, w * 0.48, 5, dim);
        bar(pad, h - 7, w - pad * 2, 1.5, hi);

      case LyricsScreenStyle.m3:
        final tonal = Paint()..color = accent.withValues(alpha: 0.28);
        bar(pad, 8, w - pad * 2 - 12, 10, tonal, r: 4);
        bar(w - pad - 10, 8, 10, 10, tonal, r: 3);
        bar(pad, 28, w * 0.6, 5, dim);
        bar(pad, 37, w - pad * 2, 12, tonal, r: 5);
        bar(pad + 4, 41, w * 0.55, 4, hi);
        bar(pad, h - 15, w - pad * 2 - 14, 10, tonal, r: 5);
        bar(w - pad - 11, h - 15, 11, 10, acc, r: 3);

      case LyricsScreenStyle.timeline:
        for (final y in [28.0, 40.0, 52.0]) {
          bar(pad, y, 10, 3.5, y == 40 ? acc : dim);
          bar(pad + 14, y, w * 0.56, 4.5, y == 40 ? hi : dim);
        }
        bar(pad, h - 10, w - pad * 2, 2, acc, r: 0);

      case LyricsScreenStyle.zen:
        bar(w * 0.28, 9, w * 0.44, 3.5, dim);
        bar(w * 0.24, 32, w * 0.52, 4, dim);
        bar(w * 0.14, 41, w * 0.72, 7, hi);
        bar(w * 0.26, 53, w * 0.48, 4, dim);
        bar(w * 0.3, h - 20, w * 0.4, 2, acc);
        bar(w * 0.25, h - 13, w * 0.5, 7, dim, r: 4);

      case LyricsScreenStyle.bigtype:
        bar(pad, 9, w * 0.45, 4, hi);
        bar(w - pad - 10, 7, 10, 8, acc);
        bar(pad, 28, w * 0.78, 9, hi);
        bar(pad, 40, w * 0.6, 9, hi);
        bar(pad, 54, w - pad * 2, 1, dim);
        bar(pad, 58, w * 0.5, 4, dim);
        bar(0, h - 18, w, 18, acc, r: 0);
        canvas.drawCircle(Offset(w / 2, h - 9), 5, Paint()..color = Colors.black);
    }
  }

  @override
  bool shouldRepaint(_LyricsSkeletonPainter old) =>
      old.style != style || old.accent != accent || old.selected != selected;
}

