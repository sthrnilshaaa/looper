import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:looper_player/core/utils/artwork_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';

import 'package:looper_player/core/providers/player_expand_provider.dart';
import 'package:looper_player/core/providers/providers.dart';
import 'package:looper_player/features/playback/presentation/providers/playback/playback_notifier.dart';
import 'package:looper_player/ui/widgets/player/player_gradient/gradient_audio_energy.dart';
import 'package:looper_player/ui/widgets/player/player_spectrum.dart';
part 'blob_painter.dart';
part 'grain_layer.dart';

/// The "Animated Gradient" background: large, soft primary and tertiary
/// color blobs traveling across the whole screen over a surface-blended base,
/// with a static film grain on top, on a slow ~48 s loop. The music's FFT
/// gently shapes it: primary blobs breathe slightly with the bass, the
/// others glow a little with the mids and highs.
///
/// Built to stay cheap, unlike a per-pixel noise shader:
/// * Each blob is a native radial gradient (a handful of draw calls a frame,
///   no per-pixel noise math).
/// * The grain is one pre-rendered tile in its own [RepaintBoundary], so it
///   is never re-recorded.
/// * Repaints are capped at ~30 fps, and only the blob layer repaints.
/// * The ticker and the FFT subscription only run while the background is
///   actually visible: tickers enabled, app resumed, player fully expanded
///   (Fluid Player), animations not disabled. On pause the motion eases to a
///   stop and the ticker turns off.
class AnimatedPlayerGradient extends ConsumerStatefulWidget {
  final double darkness;

  /// Hold the motion until the Fluid Player is fully expanded, so dragging
  /// it doesn't pay for an animating background.
  final bool followExpandProgress;

  /// The opposite, for backgrounds behind the Fluid Player (Home, Songs,
  /// Library): hold the motion as soon as the player starts covering them.
  final bool pauseUnderPlayer;

  /// When set (the lyrics screen's Ambient Color Background), the colors
  /// come from this artwork instead of the theme. Changing it cross-fades
  /// to the new artwork's colors without restarting the motion.
  final ImageProvider? artwork;

  /// False draws the gradient as a still frame: no ticker, no FFT
  /// subscription, no per-frame repaint. Callers pass the user's Animated
  /// Gradient setting, so nothing animates unless they turned it on.
  final bool animate;

  const AnimatedPlayerGradient({
    required this.darkness,
    this.followExpandProgress = false,
    this.pauseUnderPlayer = false,
    this.artwork,
    this.animate = true,
    super.key,
  });

  @override
  ConsumerState<AnimatedPlayerGradient> createState() =>
      _AnimatedPlayerGradientState();
}

class _AnimatedPlayerGradientState extends ConsumerState<AnimatedPlayerGradient>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  // A full drift loop at average speed takes about this many seconds.
  static const double _loopSeconds = 48;
  // Capped at ~30 fps: the motion is slow enough that 60 adds nothing.
  static const Duration _paintInterval = Duration(milliseconds: 33);

  late final Ticker _ticker = createTicker(_onTick);
  late final AnimationController _colorAnim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );
  final ValueNotifier<int> _frame = ValueNotifier<int>(0);
  final _GradientMotion _motion = _GradientMotion();
  late final Listenable _repaint = Listenable.merge([_frame, _colorAnim]);

  StreamSubscription<FftFrame>? _fftSub;
  ValueNotifier<double>? _expand;
  Duration? _lastElapsed;
  Duration _lastPaint = Duration.zero;

  _BlobPalette? _fromPalette;
  _BlobPalette? _toPalette;
  _BlobPalette? _artPalette;
  int _artToken = 0;
  bool _artRequested = false;

  bool _playing = false;
  bool _tickerModeOn = true;
  bool _resumed = true;
  // Whether the Fluid Player's expand progress allows motion right now.
  bool _expandAllows = true;
  bool _reduceMotion = false;

  bool get _active =>
      widget.animate &&
      _tickerModeOn &&
      _resumed &&
      _expandAllows &&
      !_reduceMotion;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    _resumed = lifecycle == null || lifecycle == AppLifecycleState.resumed;
    _playing = ref.read(playbackProvider).isPlaying;
    ref.listenManual(playbackProvider.select((s) => s.isPlaying), (_, playing) {
      _playing = playing;
      _sync();
    });
    if (widget.followExpandProgress || widget.pauseUnderPlayer) {
      final expand = ref.read(playerExpandProgressProvider)
        ..addListener(_onExpand);
      _expand = expand;
      _expandAllows = _allowsAt(expand.value);
    }
    _colorAnim.addListener(() {
      _motion.palette = _BlobPalette.lerp(
        _fromPalette!,
        _toPalette!,
        Curves.easeInOut.transform(_colorAnim.value),
      );
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _tickerModeOn = TickerMode.of(context);
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    _updatePalette(
      _artPalette ?? _BlobPalette.fromScheme(Theme.of(context).colorScheme),
    );
    if (!_artRequested) {
      _artRequested = true;
      _loadArtwork();
    }
    _sync();
  }

  @override
  void didUpdateWidget(covariant AnimatedPlayerGradient oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.artwork != widget.artwork) _loadArtwork();
    if (oldWidget.animate != widget.animate) _sync();
  }

  /// Extracts the artwork's colors (same extractor and 128px downsample as
  /// FluidBackground) and cross-fades to them. Until they arrive, or if the
  /// artwork is missing or fails to decode, the theme colors stay.
  Future<void> _loadArtwork() async {
    final int token = ++_artToken;
    final ImageProvider? artwork = widget.artwork;
    if (artwork == null) {
      _artPalette = null;
      if (mounted) {
        _updatePalette(_BlobPalette.fromScheme(Theme.of(context).colorScheme));
      }
      return;
    }
    try {
      final ArtworkColors? art = await ArtworkColors.fromProvider(artwork);
      if (!mounted || token != _artToken || art == null) return;
      _artPalette = _BlobPalette.fromArtwork(art);
      _updatePalette(_artPalette!);
    } catch (_) {
      // Keep whatever is showing.
    }
  }

  void _updatePalette(_BlobPalette next) {
    if (_toPalette == null) {
      _fromPalette = _toPalette = _motion.palette = next;
      return;
    }
    if (next == _toPalette) return;
    // Cross-fade from wherever the current fade has got to.
    _fromPalette = _motion.palette;
    _toPalette = next;
    _colorAnim.forward(from: 0);
  }

  bool _allowsAt(double progress) =>
      widget.followExpandProgress ? progress >= 0.99 : progress <= 0.01;

  void _onExpand() {
    final bool allows = _allowsAt(_expand!.value);
    if (allows == _expandAllows) return;
    _expandAllows = allows;
    _sync();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _resumed = state == AppLifecycleState.resumed;
    _sync();
  }

  /// Starts or stops the FFT subscription and the ticker to match what is
  /// actually needed right now.
  void _sync() {
    if (!mounted) return;
    final bool wantFft = _active && _playing;
    if (wantFft && _fftSub == null) {
      final player = ref.read(audioServiceProvider).player;
      PlayerSpectrum.ensureConfigured(player);
      _fftSub = player.stream.fft.listen((frame) {
        _motion.energy.addFrame(frame.bands, frame.bandLowHz, frame.bandHighHz);
      });
    } else if (!wantFft && _fftSub != null) {
      _fftSub!.cancel();
      _fftSub = null;
    }

    final bool wantTick = _active && (_playing || !_motion.energy.settled);
    if (wantTick && !_ticker.isActive) {
      _lastElapsed = null;
      _lastPaint = Duration.zero;
      _ticker.start();
    } else if (!wantTick && _ticker.isActive) {
      _ticker.stop();
    }
  }

  void _onTick(Duration elapsed) {
    final Duration? last = _lastElapsed;
    _lastElapsed = elapsed;
    if (last == null) return;
    // Clamped so a long frame hitch never makes the blobs jump.
    final double dt = ((elapsed - last).inMicroseconds / 1e6).clamp(0.0, 0.1);
    final energy = _motion.energy..step(dt, playing: _playing);
    // A calm drift that only picks up a little in louder passages.
    _motion.phase +=
        dt *
        energy.speed *
        (0.9 + 0.2 * energy.energy) *
        (2 * math.pi / _loopSeconds);

    if (elapsed - _lastPaint >= _paintInterval) {
      _lastPaint = elapsed;
      _frame.value++;
    }
    if (!_playing && energy.settled) {
      _frame.value++;
      _sync();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _expand?.removeListener(_onExpand);
    _fftSub?.cancel();
    _ticker.dispose();
    _colorAnim.dispose();
    _frame.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Drawn at quarter resolution into a cached image and stretched:
        // the blobs are soft gradients, so it looks the same, but the GPU
        // fills 1/16 of the pixels. Flutter re-renders the whole scene each
        // frame of a transition, and five ~1000 px blobs at full resolution
        // were a large share of the player/lyrics transition cost.
        RepaintBoundary(
          child: _LowResPaint(
            painter: _BlobPainter(motion: _motion, repaint: _repaint),
          ),
        ),
        const RepaintBoundary(child: _GrainLayer()),
        // Music Darkness slider, same as the static gradient.
        if (widget.darkness > 0)
          ColoredBox(color: Colors.black.withValues(alpha: widget.darkness)),
      ],
    );
  }
}

/// Mutable motion state shared between the ticker and the painter.
class _GradientMotion {
  final GradientAudioEnergy energy = GradientAudioEnergy();
  double phase = 0;
  late _BlobPalette palette;
}

/// Paints [painter] into an image at 1/[_factor] resolution whenever it asks
/// to repaint (or the size changes), and draws that image stretched with
/// bilinear filtering. Only for content with no hard edges.
class _LowResPaint extends LeafRenderObjectWidget {
  const _LowResPaint({required this.painter});

  final CustomPainter painter;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderLowResPaint(painter);

  @override
  void updateRenderObject(BuildContext context, _RenderLowResPaint render) {
    render.painter = painter;
  }
}

class _RenderLowResPaint extends RenderBox {
  _RenderLowResPaint(this._painter);

  static const double _factor = 4;

  CustomPainter _painter;
  ui.Image? _image;
  Size? _imageFor;
  bool _dirty = true;

  set painter(CustomPainter value) {
    if (identical(value, _painter)) return;
    if (attached) _painter.removeListener(_onRepaint);
    _painter = value;
    if (attached) _painter.addListener(_onRepaint);
    _onRepaint();
  }

  void _onRepaint() {
    _dirty = true;
    markNeedsPaint();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _painter.addListener(_onRepaint);
  }

  @override
  void detach() {
    _painter.removeListener(_onRepaint);
    _image?.dispose();
    _image = null;
    _dirty = true;
    super.detach();
  }

  @override
  bool get sizedByParent => true;

  @override
  Size computeDryLayout(BoxConstraints constraints) => constraints.biggest;

  @override
  bool get isRepaintBoundary => false;

  @override
  void paint(PaintingContext context, Offset offset) {
    if (size.isEmpty) return;
    if (_dirty || _image == null || _imageFor != size) {
      final int w = (size.width / _factor).ceil().clamp(1, 4096);
      final int h = (size.height / _factor).ceil().clamp(1, 4096);
      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(recorder)
        ..scale(w / size.width, h / size.height);
      _painter.paint(canvas, size);
      final ui.Picture picture = recorder.endRecording();
      _image?.dispose();
      _image = picture.toImageSync(w, h);
      picture.dispose();
      _imageFor = size;
      _dirty = false;
    }
    final ui.Image image = _image!;
    context.canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      offset & size,
      Paint()..filterQuality = FilterQuality.medium,
    );
  }
}
