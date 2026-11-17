import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:looper_player/core/services/haptics/app_haptics.dart';
import 'package:looper_player/core/utils/motion.dart';
import 'package:looper_player/l10n/app_localizations.dart';

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
