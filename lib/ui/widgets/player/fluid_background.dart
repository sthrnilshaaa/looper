import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:adaptive_palette/adaptive_palette.dart';
import 'package:looper_player/core/utils/artwork_colors.dart';

/// Fallback palette mode when image is unavailable or extraction fails.
enum FluidFallbackMode { dark, light, auto }

/// An ambient "noise blur" background — a slow, organic field of color
/// sampled from the song's artwork with a fine animated grain dusted on
/// top, rendered on the GPU via a fragment shader. Mirrors the relaxing,
/// continuously-breathing lyrics background used by Apple Music: no hard
/// edges, no discrete shapes, just color drifting into color.
class FluidBackground extends StatefulWidget {
  const FluidBackground({
    super.key,
    this.imageProvider,
    required this.child,
    this.blurSigma =
        40, // Kept for API compatibility; the shader is inherently soft, no image blur pass needed
    this.overlayDarken = 0.10,
    this.animate = false,
    this.fallbackMode = FluidFallbackMode.auto,
    this.transitionDuration = const Duration(milliseconds: 1800),
  });

  final ImageProvider? imageProvider;
  final Widget child;
  final double blurSigma;
  final double overlayDarken;
  final bool animate;
  final FluidFallbackMode fallbackMode;
  final Duration transitionDuration;

  @override
  State<FluidBackground> createState() => _FluidBackgroundState();
}

class _FluidBackgroundState extends State<FluidBackground>
    with TickerProviderStateMixin {
  FluidPalette? _oldPalette;
  FluidPalette? _palette;
  int _loadSession = 0;
  bool _routeTransitionFinished = false;
  Animation<double>? _routeAnimation;

  late final AnimationController _revealController = AnimationController(
    vsync: this,
    duration: widget.transitionDuration,
  );

  /// Free-running elapsed time (seconds) fed to the shader as `uTime`.
  /// Unbounded and never looped, so the flow field never visibly "resets".
  final ValueNotifier<double> _time = ValueNotifier<double>(0);
  late final Ticker _ticker = createTicker(_onTick);
  Duration _tickBase = Duration.zero;

  void _onTick(Duration elapsed) {
    _time.value = (elapsed - _tickBase).inMicroseconds / 1e6;
  }

  void _startTicker() {
    if (!_ticker.isTicking) {
      // A fresh Ticker.start() measures `elapsed` from zero again, so
      // offset it by the negative of where the clock left off — resuming
      // continues the flow field exactly where it froze instead of
      // jumping, with no visible jolt.
      _tickBase = Duration(microseconds: -(_time.value * 1e6).round());
      _ticker.start();
    }
  }

  void _stopTicker() {
    if (_ticker.isTicking) _ticker.stop();
  }

  FluidPalette _fallbackFor(BuildContext context) {
    switch (widget.fallbackMode) {
      case FluidFallbackMode.dark:
        return const FluidPalette.fallback();
      case FluidFallbackMode.light:
        return const FluidPalette.fallbackLight();
      case FluidFallbackMode.auto:
        final brightness = Theme.of(context).brightness;
        return brightness == Brightness.light
            ? const FluidPalette.fallbackLight()
            : const FluidPalette.fallback();
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.animate) {
      _startTicker();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    final animation = route?.animation;
    if (_routeAnimation != animation) {
      _routeAnimation?.removeStatusListener(_onRouteAnimationStatusChanged);
      _routeAnimation = animation;
      if (animation != null) {
        if (animation.isCompleted) {
          _routeTransitionFinished = true;
          _kickLoad();
          if (widget.animate) _startTicker();
        } else {
          _routeTransitionFinished = false;
          animation.addStatusListener(_onRouteAnimationStatusChanged);
        }
      } else {
        _routeTransitionFinished = true;
        _kickLoad();
        if (widget.animate) _startTicker();
      }
    }
  }

  void _onRouteAnimationStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      if (mounted) {
        setState(() {
          _routeTransitionFinished = true;
        });
        _kickLoad();
        if (widget.animate) _startTicker();
      }
    } else {
      if (mounted && _routeTransitionFinished) {
        setState(() {
          _routeTransitionFinished = false;
        });
        _stopTicker();
      }
    }
  }

  @override
  void didUpdateWidget(covariant FluidBackground oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.animate != widget.animate) {
      if (widget.animate && _routeTransitionFinished) {
        _startTicker();
      } else {
        _stopTicker();
      }
    }

    if (oldWidget.imageProvider != widget.imageProvider) {
      _kickLoad();
    }
  }

  @override
  void dispose() {
    _routeAnimation?.removeStatusListener(_onRouteAnimationStatusChanged);
    _ticker.dispose();
    _time.dispose();
    _revealController.dispose();
    super.dispose();
  }

  void _kickLoad() {
    if (!_routeTransitionFinished) return;
    final int loadToken = ++_loadSession;

    final provider = widget.imageProvider;
    if (provider == null) {
      setState(() {
        _oldPalette = _palette ?? _fallbackFor(context);
        _palette = null;
      });
      _revealController.forward(from: 0);
      return;
    }
    _load(provider, loadToken: loadToken);
  }

  Future<void> _load(ImageProvider provider, {required int loadToken}) async {
    try {
      // Real artwork colors (see ArtworkColors), laid out as a FluidPalette:
      // a deep shade of the dominant color as the base, the ranked colors
      // as accents.
      final ArtworkColors? art = await ArtworkColors.fromProvider(provider);
      if (art == null) throw StateError('unreadable artwork');
      final List<Color> accents = art.accents;
      Color accent(int i) => accents[i % accents.length];
      final HSLColor dom = HSLColor.fromColor(art.dominant);
      final FluidPalette pal = FluidPalette(
        baseDark: dom
            .withLightness(math.min(dom.lightness, 0.14))
            .withSaturation(math.min(dom.saturation, 0.55))
            .toColor(),
        accent1: accent(0),
        accent2: accent(1),
        accent3: accent(2),
        accent4: accent(3),
      );

      if (!mounted || loadToken != _loadSession) return;
      setState(() {
        _oldPalette = _palette ?? _fallbackFor(context);
        _palette = pal;
      });

      _revealController.forward(from: 0);
    } catch (_) {
      if (!mounted || loadToken != _loadSession) return;
      setState(() {
        _oldPalette = _palette ?? _fallbackFor(context);
        _palette = null;
      });
      _revealController.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fallbackPalette = _fallbackFor(context);
    final FluidPalette target = _palette ?? fallbackPalette;
    final overlayColor = fallbackPalette.baseDark.computeLuminance() > 0.55
        ? Colors.white.withValues(alpha: widget.overlayDarken * 0.45)
        : Colors.black.withValues(alpha: widget.overlayDarken);

    return Container(
      color: target.baseDark,
      child: AnimatedBuilder(
        animation: _revealController,
        child: RepaintBoundary(child: widget.child),
        builder: (context, child) {
          final double k = _revealController.value;
          final FluidPalette current = FluidPalette.lerp(
            _oldPalette ?? fallbackPalette,
            target,
            k,
          );

          return Stack(
            fit: StackFit.expand,
            children: [
              // Matte base so there's never a flash of nothing while the
              // shader compiles on first frame.
              _MatteBase(palette: current),

              // GPU noise-blur color field, driven by the artwork palette.
              _NoiseBlurField(palette: current, time: _time),

              // Legibility overlay (static layer)
              IgnorePointer(child: Container(color: overlayColor)),

              // Foreground Child
              child!,
            ],
          );
        },
      ),
    );
  }
}

/// Soft matte gradient shown beneath (and briefly before) the shader.
class _MatteBase extends StatelessWidget {
  const _MatteBase({required this.palette});
  final FluidPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [palette.accent1.withValues(alpha: 0.35), palette.baseDark],
        ),
      ),
    );
  }
}

/// Renders the animated noise-blur color field via `shaders/ambient_noise.frag`.
///
/// The shader blends a 6-stop ramp built from the artwork palette through a
/// slow-drifting value-noise flow field (the "blur" — organically soft with
/// no gaussian pass needed) and dusts a fine, filmic grain on top (the
/// "noise") for texture and color variety, matching the relaxing, ever-
/// shifting ambient background used by Apple Music's lyrics screen.
class _NoiseBlurField extends StatefulWidget {
  const _NoiseBlurField({required this.palette, required this.time});

  final FluidPalette palette;
  final ValueNotifier<double> time;

  @override
  State<_NoiseBlurField> createState() => _NoiseBlurFieldState();
}

class _NoiseBlurFieldState extends State<_NoiseBlurField> {
  static Future<ui.FragmentProgram>? _programFuture;
  ui.FragmentShader? _shader;

  @override
  void initState() {
    super.initState();
    _programFuture ??= ui.FragmentProgram.fromAsset(
      'media/shaders/ambient_noise.frag',
    );
    _programFuture!.then((program) {
      if (!mounted) return;
      setState(() {
        _shader = program.fragmentShader();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final shader = _shader;
    if (shader == null) return const SizedBox.shrink();

    return RepaintBoundary(
      child: CustomPaint(
        painter: _NoiseBlurPainter(
          shader: shader,
          palette: widget.palette,
          time: widget.time,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _NoiseBlurPainter extends CustomPainter {
  _NoiseBlurPainter({
    required this.shader,
    required this.palette,
    required this.time,
  }) : super(repaint: time);

  final ui.FragmentShader shader;
  final FluidPalette palette;
  final ValueNotifier<double> time;

  static const double _grainStrength = 0.028;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    // Six-stop color ramp derived from the extracted palette: the dark
    // base anchors both rare extremes (occasional deeper patches for
    // depth) while the four vivid accents dominate the middle of the
    // field, giving natural-looking color variety without ever repeating
    // the exact same blend twice.
    final Color c5 =
        Color.lerp(palette.baseDark, palette.accent4, 0.35) ?? palette.baseDark;

    int i = 0;
    shader
      ..setFloat(i++, size.width)
      ..setFloat(i++, size.height)
      ..setFloat(i++, time.value)
      ..setFloat(i++, _grainStrength);

    void setColor(Color color) {
      shader
        ..setFloat(i++, color.r)
        ..setFloat(i++, color.g)
        ..setFloat(i++, color.b);
    }

    setColor(palette.baseDark);
    setColor(palette.accent1);
    setColor(palette.accent2);
    setColor(palette.accent3);
    setColor(palette.accent4);
    setColor(c5);

    final paint = Paint()..shader = shader;
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant _NoiseBlurPainter oldDelegate) {
    return oldDelegate.palette != palette || oldDelegate.shader != shader;
  }
}
