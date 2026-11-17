library;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'line_thumb_shape.dart';
import 'squiggly_slider_track_shape.dart';

/// A Material Design Squiggly [Slider].
///
/// Used to select from a range of values while signaling something is live.
///
/// ![A squiggly slider widget, squiggly slider track shape.](https://github.com/hannesgith/squiggly_slider/raw/main/assets/sample.gif)
///
/// The Squiggly Sliders value is part of the Stateful widget subclass to change the value
/// setState was called.
/// The squiggly sinus curve can be controlled by the [squiggleAmplitude] and [squiggleWavelength] parameters.
/// The [squiggleSpeed] parameter controls the speed of the animation.
///
/// ** See code in examples/lib/main.dart **
///
/// See also:
///
///  * [Slider] for more information about the component parts of a slider.
class SquigglySlider extends Slider {
  /// Creates a squiggly Material Design slider.
  ///
  /// The squiggle itself is a sinus curve with rounded edges, vertically centered
  /// its amplitude and wavelength can be adjusted by [squiggleAmplitude] and [squiggleWavelength] respectively,
  /// the curve itself is animated, and the animation speed can be adjusted with [squiggleSpeed] which controls how many waves pass from left to right in one second.
  ///
  /// The slider itself does not maintain any state. Instead, when the state of
  /// the slider changes, the widget calls the [onChanged] callback. Most
  /// widgets that use a slider will listen for the [onChanged] callback and
  /// rebuild the slider with a new [value] to update the visual appearance of
  /// the slider.
  ///
  /// * [value] determines currently selected value for this slider.
  /// * [onChanged] is called while the user is selecting a new value for the
  ///   slider.
  /// * [onChangeStart] is called when the user starts to select a new value for
  ///   the slider.
  /// * [onChangeEnd] is called when the user is done selecting a new value for
  ///   the slider.
  ///
  /// You can override some of the colors with the [activeColor] and
  /// [inactiveColor] properties, although more fine-grained control of the
  /// appearance is achieved using a [SliderThemeData].
  ///
  /// A slider can be used to select from either a continuous or a discrete set of
  /// values. The default is to use a continuous range of values from [min] to
  /// [max]. To use discrete values, use a non-null value for [divisions], which
  /// indicates the number of discrete intervals. For example, if [min] is 0.0 and
  /// [max] is 50.0 and [divisions] is 5, then the slider can take on the
  /// discrete values 0.0, 10.0, 20.0, 30.0, 40.0, and 50.0.
  ///
  /// The terms for the parts of a slider are:
  ///
  ///  * The "thumb", which is a shape that slides horizontally when the user
  ///    drags it.
  ///  * The "track", which is the line that the slider thumb slides along.
  ///  * The "value indicator", which is a shape that pops up when the user
  ///    is dragging the thumb to indicate the value being selected.
  ///  * The "active" side of the slider is the side between the thumb and the
  ///    minimum value.
  ///  * The "inactive" side of the slider is the side between the thumb and the
  ///    maximum value.
  ///
  /// The slider will be disabled if [onChanged] is null or if the range given by
  /// [min]..[max] is empty (i.e. if [min] is equal to [max]).
  ///
  /// The slider widget itself does not maintain any state. Instead, when the state
  /// of the slider changes, the widget calls the [onChanged] callback. Most
  /// widgets that use a slider will listen for the [onChanged] callback and
  /// rebuild the slider with a new [value] to update the visual appearance of the
  /// slider. To know when the value starts to change, or when it is done
  /// changing, set the optional callbacks [onChangeStart] and/or [onChangeEnd].
  ///
  /// By default, a slider will be as wide as possible, centered vertically. When
  /// given unbounded constraints, it will attempt to make the track 144 pixels
  /// wide (with margins on each side) and will shrink-wrap vertically.
  ///
  const SquigglySlider({
    super.key,
    required super.value,
    super.secondaryTrackValue,
    required super.onChanged,
    super.onChangeStart,
    super.onChangeEnd,
    super.min = 0.0,
    super.max = 1.0,
    super.divisions,
    super.label,
    super.activeColor,
    super.inactiveColor,
    super.secondaryActiveColor,
    super.thumbColor,
    super.overlayColor,
    super.mouseCursor,
    super.semanticFormatterCallback,
    super.focusNode,
    super.autofocus = false,
    this.squiggleAmplitude = 0.0,
    this.squiggleWavelength = 0.0,
    this.squiggleSpeed = 1.0,
    this.squiggleAnimating = true,
    this.thumbGap,
    this.useLineThumb = false,
  });

  /// The amplitude of the squiggle.
  final double squiggleAmplitude;

  /// The wavelength of the squiggle.
  final double squiggleWavelength;

  /// The speed of the squiggle in waves per second.
  final double squiggleSpeed;

  /// Whether the wave moves. When false it holds still where it is.
  final bool squiggleAnimating;

  /// Empty space between the thumb and each side of the track, see
  /// [SquigglySliderTrackShape.thumbGap].
  final double? thumbGap;

  /// Use the Android 13's like slider thumb
  final bool useLineThumb;

  @override
  State<SquigglySlider> createState() => _SquigglySliderState();
}

class _SquigglySliderState extends State<SquigglySlider>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  // The wave's phase in [0, 1), advanced by a ticker. The track shape reads
  // it at paint time, so moving the wave only repaints the slider's own
  // layer (via [_boundaryKey]) instead of rebuilding the whole Slider.
  final ValueNotifier<double> _phase = ValueNotifier<double>(0.5);
  final GlobalKey _boundaryKey = GlobalKey();
  late final Ticker _ticker = createTicker(_onTick);
  Duration? _lastElapsed;
  // Capped at ~30 fps: the wave is very slow (0.08 waves/sec), so ticking at
  // full panel refresh (90/120Hz) wastes GPU/CPU cycles with zero visual gain.
  static const Duration _paintInterval = Duration(milliseconds: 33);
  Duration _lastPaint = Duration.zero;
  bool _resumed = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    _resumed = lifecycle == null || lifecycle == AppLifecycleState.resumed;
    _syncTicker();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final bool resumed = state == AppLifecycleState.resumed;
    if (resumed != _resumed) {
      _resumed = resumed;
      _syncTicker();
    }
  }

  @override
  void didUpdateWidget(covariant SquigglySlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncTicker();
  }

  bool get _wantsTick =>
      _resumed &&
      widget.squiggleSpeed != 0 &&
      widget.squiggleAnimating &&
      // Nothing visible changes while the wave is flat (amplitude 0 -
      // paused, or squiggle disabled), so don't tick for it.
      widget.squiggleAmplitude != 0;

  void _syncTicker() {
    if (_wantsTick && !_ticker.isActive) {
      _lastElapsed = null;
      _lastPaint = Duration.zero;
      _ticker.start();
    } else if (!_wantsTick && _ticker.isActive) {
      _ticker.stop();
    }
  }

  void _onTick(Duration elapsed) {
    final Duration? last = _lastElapsed;
    _lastElapsed = elapsed;
    if (last == null) return;
    final double dt = ((elapsed - last).inMicroseconds / 1e6).clamp(0.0, 0.1);
    // In wave cycles: the same visual speed as before (speed x wavelength
    // cycles a second), but the track's wrap is now seamless.
    final double next =
        (_phase.value + dt * widget.squiggleSpeed * widget.squiggleWavelength) %
        1.0;
    _phase.value = next < 0 ? next + 1 : next;
    // Capped at ~30 fps: prevents 120Hz continuous repaint loops on mobile
    if (elapsed - _lastPaint >= _paintInterval) {
      _lastPaint = elapsed;
      _boundaryKey.currentContext?.findRenderObject()?.markNeedsPaint();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker.dispose();
    _phase.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    key: _boundaryKey,
    child: SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackShape: SquigglySliderTrackShape(
          squiggleAmplitude: widget.squiggleAmplitude,
          squiggleWavelength: widget.squiggleWavelength,
          phase: _phase,
          thumbGap: widget.thumbGap,
        ),
        thumbShape: widget.useLineThumb ? const LineThumbShape() : null,
      ),
      child: Slider(
        key: widget.key,
        value: widget.value,
        secondaryTrackValue: widget.secondaryTrackValue,
        onChanged: widget.onChanged,
        onChangeStart: widget.onChangeStart,
        onChangeEnd: widget.onChangeEnd,
        min: widget.min,
        max: widget.max,
        divisions: widget.divisions,
        label: widget.label,
        activeColor: widget.activeColor,
        inactiveColor: widget.inactiveColor,
        secondaryActiveColor: widget.secondaryActiveColor,
        thumbColor: widget.thumbColor,
        overlayColor: widget.overlayColor,
        mouseCursor: widget.mouseCursor,
        semanticFormatterCallback: widget.semanticFormatterCallback,
        focusNode: widget.focusNode,
        autofocus: widget.autofocus,
      ),
    ),
  );
}
