import 'dart:math' as math;
import 'dart:ui' as ui show Gradient;
import 'dart:ui' show PathMetric;

import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:looper_player/core/motion/pause_when_offscreen.dart';
import 'package:looper_player/core/services/haptics/app_haptics.dart';
import 'package:looper_player/core/utils/motion.dart';
import 'package:looper_player/ui/widgets/common/setup_logo_shapes.dart';

/// Building blocks of the first-run setup flow (Figma "devvlooper" onboarding).
/// The setup keeps one fixed accent on purpose, not the dynamic theme one.
const kSetupAccent = Color(0xFFC0E200);
const kSetupBg = Color(0xFF0A0A0A);
const kSetupCard = Color(0xFF161615);
const kSetupInner = Color(0xFF232323); // rows / picked items inside a card
const kSetupLine = Color(0xFF222222);
const kSetupMuted = Color(0xFF4D4D4D);

TextStyle setupTitleStyle() => const TextStyle(
  fontFamily: 'Stack Sans Text',
  fontSize: 40,
  height: 42 / 40,
  letterSpacing: -0.8,
  color: Colors.white,
);

TextStyle setupBody({
  double size = 16,
  Color color = kSetupMuted,
  FontWeight weight = FontWeight.w500,
  double height = 22 / 16,
}) => TextStyle(
  fontFamily: 'DM Sans',
  fontSize: size,
  height: height,
  fontWeight: weight,
  letterSpacing: -0.02 * size,
  color: color,
);

/// Dark backdrop with three dim Looper-logo outlines; a soft grey light
/// travels along each one.
class SetupBackground extends StatefulWidget {
  const SetupBackground({super.key, required this.child});
  final Widget child;

  @override
  State<SetupBackground> createState() => _SetupBackgroundState();
}

class _SetupBackgroundState extends State<SetupBackground>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 9),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Motion.reducedOf(context)) {
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
  Widget build(BuildContext context) {
    return ColoredBox(
      color: kSetupBg,
      child: Stack(
        fit: StackFit.expand,
        children: [
          RepaintBoundary(child: CustomPaint(painter: _FlowLinesPainter(_c))),
          widget.child,
        ],
      ),
    );
  }
}

class _FlowLinesPainter extends CustomPainter {
  _FlowLinesPainter(this.t) : super(repaint: t);
  final Animation<double> t;

  Size? _size;
  double _s = 1;
  late List<Path> _shapes;
  late List<(int, PathMetric, double)> _spots; // logo, path it rides, phase

  /// One glow per logo: (logo, which of its two shapes it rides, phase).
  static const _glows = [(0, 1, 0.0), (1, 0, 0.35), (2, 1, 0.7)];
  late List<Shader> _outline; // per logo

  void _build(Size size) {
    _size = size;
    // Cover-fit the 402x874 design frame, centred horizontally.
    final s = _s = math.max(size.width / 402, size.height / 874);
    final dx = (size.width - 402 * s) / 2;
    _shapes = [
      for (final n in kSetupLogoShapes)
        () {
          final p = Path()..moveTo(dx + n[0] * s, n[1] * s);
          for (var i = 2; i + 5 < n.length; i += 6) {
            p.cubicTo(
              dx + n[i] * s,
              n[i + 1] * s,
              dx + n[i + 2] * s,
              n[i + 3] * s,
              dx + n[i + 4] * s,
              n[i + 5] * s,
            );
          }
          return p..close();
        }(),
    ];
    _outline = [
      // Figma: each outline fades #141414 (top) to #0E0E0E (bottom).
      for (final (top, bottom) in kSetupLogoSpans)
        ui.Gradient.linear(Offset(0, top * s), Offset(0, bottom * s), const [
          Color(0xFF141414),
          Color(0xFF0E0E0E),
        ]),
    ];
    _spots = [
      for (final (logo, part, phase) in _glows)
        (logo, _shapes[logo * 2 + part].computeMetrics().first, phase),
    ];
    _stroke.strokeWidth = 10 * s;
    _lit.strokeWidth = 10 * s;
  }

  // Stroked 10 wide but clipped to the shape: a 5px inside stroke, as in
  // the Figma frame.
  final _stroke = Paint()..style = PaintingStyle.stroke;
  final _lit = Paint()..style = PaintingStyle.stroke;

  void _strokeInside(Canvas canvas, Path shape, Paint paint) => canvas
    ..save()
    ..clipPath(shape)
    ..drawPath(shape, paint)
    ..restore();

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    if (_size != size) _build(size);
    for (var i = 0; i < _shapes.length; i++) {
      _stroke.shader = _outline[i ~/ 2];
      _strokeInside(canvas, _shapes[i], _stroke);
    }
    // Figma: a blurred #262626 blob (100px, blur 18) masked by the logo's
    // outline, so only the outline lights up around it. Here it rides along.
    for (final (logo, m, phase) in _spots) {
      final c = m
          .getTangentForOffset(((t.value + phase) % 1) * m.length)!
          .position;
      _lit.shader = ui.Gradient.radial(
        c,
        86 * _s,
        const [Color(0xFF262626), Color(0xCC262626), Color(0x00262626)],
        const [0, 0.38, 1],
      );
      _strokeInside(canvas, _shapes[logo * 2], _lit);
      _strokeInside(canvas, _shapes[logo * 2 + 1], _lit);
    }
  }

  @override
  bool shouldRepaint(_FlowLinesPainter old) => old.t != t;
}

/// One setup screen: step label, title, description, body, bottom bar.
/// Short bodies sit low on the screen like the design; [expand] lets a long
/// body (the artist grid) take all the room left.
class SetupPage extends StatelessWidget {
  const SetupPage({
    super.key,
    this.step,
    this.title,
    this.description,
    required this.body,
    required this.bottom,
    this.expand = false,
  });

  final String? step;
  final String? title;
  final String? description;
  final Widget body;
  final Widget bottom;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final header = [
      if (title != null)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(title!, style: setupTitleStyle()),
        ),
      if (description != null) ...[
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(description!, style: setupBody()),
        ),
      ],
      if (title != null || description != null) const SizedBox(height: 24),
    ];
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(21, 0, 21, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 52,
              child: Align(
                alignment: Alignment.centerRight,
                child: step == null
                    ? null
                    : Text(
                        step!,
                        style: setupBody(
                          size: 13,
                          color: const Color(0xFF333333),
                        ),
                      ),
              ),
            ),
            if (expand) ...[
              const SizedBox(height: 28),
              ...header,
              Expanded(child: body),
            ] else
              Expanded(
                child: LayoutBuilder(
                  builder: (context, c) => SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: c.maxHeight),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [...header, body],
                      ),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: bottom,
            ),
          ],
        ),
      ),
    );
  }
}

/// Round grey button (back arrow, language globe) + white pill action.
class SetupBottomBar extends StatelessWidget {
  const SetupBottomBar({
    super.key,
    required this.label,
    required this.onNext,
    this.onBack,
    this.leadingIcon = Icons.arrow_back_rounded,
  });

  final String label;
  final VoidCallback? onNext;
  final VoidCallback? onBack;
  final IconData leadingIcon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (onBack != null) ...[
          SetupPressable(
            onTap: onBack!,
            child: Container(
              width: 63,
              height: 63,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0x1AFFFFFF),
              ),
              child: Icon(leadingIcon, color: Colors.white, size: 22),
            ),
          ),
          const SizedBox(width: 9),
        ],
        Expanded(
          child: SetupPressable(
            onTap: onNext,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: onNext == null ? 0.4 : 1,
              child: Container(
                height: 63,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(31.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: setupBody(
                        size: 18,
                        color: Colors.black,
                        height: 1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.black,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Soft press-scale with a light haptic, used by every tappable thing here.
class SetupPressable extends StatefulWidget {
  const SetupPressable({super.key, required this.onTap, required this.child});
  final VoidCallback? onTap;
  final Widget child;

  @override
  State<SetupPressable> createState() => _SetupPressableState();
}

class _SetupPressableState extends State<SetupPressable> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: enabled ? (_) => setState(() => _down = true) : null,
      onTapCancel: () => setState(() => _down = false),
      onTapUp: enabled ? (_) => setState(() => _down = false) : null,
      onTap: enabled
          ? () {
              AppHaptics.light();
              widget.onTap!();
            }
          : null,
      child: AnimatedScale(
        scale: _down ? 0.96 : 1,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// Rounded dark card holding rows, each its own inner card, 9px apart.
class SetupCard extends StatelessWidget {
  const SetupCard({super.key, required this.children, this.padding});
  final List<Widget> children;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: kSetupCard,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(height: 9),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// Title + dim description row with a trailing widget. [filled] gives it
/// the inner-card fill (granted permission, community links).
class SetupRow extends StatelessWidget {
  const SetupRow({
    super.key,
    required this.title,
    required this.description,
    required this.trailing,
    this.icon,
    this.onTap,
    this.filled = true,
  });

  final String title;
  final String description;
  final Widget trailing;
  final Widget? icon;
  final VoidCallback? onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return SetupPressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: filled ? kSetupInner : kSetupInner.withValues(alpha: 0),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (icon != null) ...[icon!, const SizedBox(width: 8)],
                      Flexible(
                        child: Text(
                          title,
                          style: setupBody(size: 15, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: setupBody(size: 13, height: 15 / 13),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 24),
            trailing,
          ],
        ),
      ),
    );
  }
}

/// Round check: grey when off, accent when on, cross-fading between.
class SetupCheck extends StatelessWidget {
  const SetupCheck({super.key, required this.on, this.size = 22});
  final bool on;
  final double size;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: on ? kSetupAccent : const Color(0xFF3A3A3A),
      ),
      child: Icon(
        Icons.check_rounded,
        size: size * 0.7,
        color: on ? Colors.black : const Color(0xFF1A1A1A),
      ),
    );
  }
}

/// Direction-aware shared-axis switcher for moving between setup pages.
class SetupSwitcher extends StatelessWidget {
  const SetupSwitcher({super.key, required this.reverse, required this.child});
  final bool reverse;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return PageTransitionSwitcher(
      reverse: reverse,
      duration: const Duration(milliseconds: 520),
      transitionBuilder: (child, primary, secondary) => SharedAxisTransition(
        animation: primary,
        secondaryAnimation: secondary,
        transitionType: SharedAxisTransitionType.horizontal,
        fillColor: Colors.transparent,
        child: child,
      ),
      child: child,
    );
  }
}

/// Accent check that pops in, ringed by a slowly turning dashed circle.
class SetupDoneBadge extends StatefulWidget {
  const SetupDoneBadge({super.key});

  @override
  State<SetupDoneBadge> createState() => _SetupDoneBadgeState();
}

class _SetupDoneBadgeState extends State<SetupDoneBadge>
    with TickerProviderStateMixin {
  late final _pop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();
  late final _spin = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 12),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Motion.reducedOf(context)) {
      _spin.stop();
      _pop.value = 1;
    } else if (!_spin.isAnimating) {
      _spin.repeat();
    }
  }

  @override
  void dispose() {
    _pop.dispose();
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = CurvedAnimation(parent: _pop, curve: Curves.elasticOut);
    return PauseWhenOffscreen(
      child: SizedBox(
        width: 96,
        height: 96,
        child: Stack(
          alignment: Alignment.center,
          children: [
            FadeTransition(
              opacity: _pop,
              child: RotationTransition(
                turns: _spin,
                child: const CustomPaint(
                  size: Size(96, 96),
                  painter: _DashedRingPainter(),
                ),
              ),
            ),
            ScaleTransition(
              scale: scale,
              child: Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: kSetupAccent,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 46,
                  color: Color(0xFF111111),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashedRingPainter extends CustomPainter {
  const _DashedRingPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..color = kSetupAccent;
    final rect = Offset.zero & size;
    const dashes = 18;
    const sweep = 2 * math.pi / dashes;
    for (var i = 0; i < dashes; i++) {
      canvas.drawArc(rect.deflate(1), i * sweep, sweep * 0.55, false, paint);
    }
  }

  @override
  bool shouldRepaint(_DashedRingPainter old) => false;
}
