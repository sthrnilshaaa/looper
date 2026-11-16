import 'dart:math' as math;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:looper_player/core/utils/ui_utils.dart';

import '../../../../domain/lyric_models.dart';

/// The active lyric line when the source has real word timing (lrc.red,
/// LyricsPlus, enhanced LRC). With [wipe] (the "character" style) each word
/// fills with [activeColor] left to right at the singer's pace, a soft-edged
/// wipe, Apple Music style; without it (the "word" style) each word lights
/// up whole the moment it's sung. Either way sung words lift slightly, and
/// background vocals render smaller underneath with the same treatment.
///
/// Playback position only arrives every few dozen ms, so between updates
/// the position is extrapolated with a [Ticker] (only while [isPlaying]) -
/// otherwise the wipe would visibly step. Only the single active line ever
/// builds this widget, so there's at most one ticker running.
class WordSyncedLyricText extends StatefulWidget {
  final LyricLine line;
  final Duration position;
  final bool isPlaying;

  /// Style of the active line; its font size drives the background-vocal
  /// size and the wipe's soft edge.
  final TextStyle style;
  final Color activeColor;
  final Color unsungColor;
  final TextAlign textAlign;
  final double fontScale;
  final bool wipe;

  /// Whether this is still the current line. When it stops being current
  /// the widget stays up for the hand-off animation: it keeps its own clock
  /// (new positions belong to the next line) while [emphasis] runs to 0.
  final bool active;

  /// 1 = fully the current line; 0 = looks exactly like a plain inactive
  /// line (every word [unsungColor], no lift, no glow), so the caller can
  /// swap to plain text at 0 without a visible jump.
  final double emphasis;

  /// False keeps it to the main line (background vocals left out).
  final bool showBackground;

  const WordSyncedLyricText({
    super.key,
    required this.line,
    required this.position,
    required this.isPlaying,
    required this.style,
    required this.activeColor,
    required this.unsungColor,
    required this.textAlign,
    this.fontScale = 1.0,
    this.wipe = true,
    this.active = true,
    this.emphasis = 1.0,
    this.showBackground = true,
  });

  /// Blend from [dim] (the inactive look) to [lit] at [t]. A plain
  /// Color.lerp from a faint white to the accent passes through a pale,
  /// milky tint; here the hue moves early and the opacity follows the
  /// animation, so a finishing line reads as the accent dimming down and a
  /// starting one as the accent lighting up.
  static Color settleColor(Color dim, Color lit, double t) {
    if (t <= 0) return dim;
    if (t >= 1) return lit;
    final hue = Color.lerp(
      dim.withValues(alpha: 1),
      lit.withValues(alpha: 1),
      Curves.easeOutCubic.transform(t),
    )!;
    return hue.withValues(alpha: dim.a + (lit.a - dim.a) * t);
  }

  @override
  State<WordSyncedLyricText> createState() => _WordSyncedLyricTextState();
}

class _WordSyncedLyricTextState extends State<WordSyncedLyricText>
    with SingleTickerProviderStateMixin {
  /// Never extrapolate further than this past the last real position - if
  /// updates stall (buffering, a paused stream that hasn't reported yet)
  /// the wipe waits instead of racing ahead.
  static const Duration _maxExtrapolation = Duration(milliseconds: 400);

  /// A reported position this far behind the extrapolated one is a seek,
  /// not jitter.
  static const Duration _seekThreshold = Duration(milliseconds: 250);

  late final Ticker _ticker;
  late Duration _anchor;

  /// Frame-clock time (the ticker's elapsed) now and when [_anchor] was
  /// taken. Frame timestamps rather than a stopwatch, so the wipe advances
  /// in step with vsync.
  Duration _frameTime = Duration.zero;
  Duration _anchorFrameTime = Duration.zero;

  @override
  void initState() {
    super.initState();
    _anchor = widget.position;
    _ticker = createTicker((elapsed) => setState(() => _frameTime = elapsed));
    if (widget.isPlaying) _ticker.start();
  }

  @override
  void didUpdateWidget(WordSyncedLyricText oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Once the line has handed over, positions are the next line's; the
    // word being sung keeps finishing on the extrapolated clock (capped by
    // _maxExtrapolation) while the line settles.
    if (widget.active &&
        (widget.position != oldWidget.position || !oldWidget.active)) {
      final extrapolated = _now();
      final behind = extrapolated - widget.position;
      // Small backwards corrections are timer jitter; honoring them would
      // make the wipe twitch backwards. Real seeks jump straight there.
      _anchor = behind > Duration.zero && behind < _seekThreshold
          ? extrapolated
          : widget.position;
      _anchorFrameTime = _frameTime;
    }
    if (widget.isPlaying && !_ticker.isActive) {
      // A restarted ticker counts from zero again.
      _frameTime = Duration.zero;
      _anchorFrameTime = Duration.zero;
      _ticker.start();
    } else if (!widget.isPlaying && _ticker.isActive) {
      _ticker.stop();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  Duration _now() {
    if (!widget.isPlaying) return _anchor;
    final elapsed = _frameTime - _anchorFrameTime;
    return _anchor +
        (elapsed > _maxExtrapolation ? _maxExtrapolation : elapsed);
  }

  @override
  Widget build(BuildContext context) {
    final now = _now();
    final line = widget.line;
    final rtl = _isRtl(line.text);
    final baseSize = widget.style.fontSize ?? 30;
    final emphasis = widget.emphasis.clamp(0.0, 1.0);
    final sungColor = WordSyncedLyricText.settleColor(
      widget.unsungColor,
      widget.activeColor,
      emphasis,
    );

    final main = _WordWrap(
      words: line.words,
      position: now,
      style: widget.style,
      activeColor: sungColor,
      unsungColor: widget.unsungColor,
      textAlign: widget.textAlign,
      rtl: rtl,
      lift: 2.0 * widget.fontScale * emphasis,
      wipe: widget.wipe,
      emphasis: emphasis,
    );
    if (line.backgroundText.isEmpty || !widget.showBackground) return main;
    final backgroundStyle = widget.style.copyWith(
      fontSize: baseSize * 0.62,
      height: 1.2,
      shadows: const [],
    );
    // Same dimming as the plain line's background vocals.
    final backgroundUnsung = widget.unsungColor.withValues(
      alpha: widget.unsungColor.a * 0.7,
    );

    return Column(
      crossAxisAlignment: _crossAxis(widget.textAlign),
      mainAxisSize: MainAxisSize.min,
      children: [
        main,
        SizedBox(height: 4 * widget.fontScale),
        if (line.backgroundWords.isEmpty)
          Text(
            line.backgroundText,
            textAlign: widget.textAlign,
            style: backgroundStyle.copyWith(color: backgroundUnsung),
          )
        else
          _WordWrap(
            words: line.backgroundWords,
            position: now,
            style: backgroundStyle,
            activeColor: WordSyncedLyricText.settleColor(
              backgroundUnsung,
              widget.activeColor.withValues(alpha: 0.85),
              emphasis,
            ),
            unsungColor: backgroundUnsung,
            textAlign: widget.textAlign,
            rtl: rtl,
            lift: 1.0 * widget.fontScale * emphasis,
            wipe: widget.wipe,
            emphasis: emphasis,
          ),
      ],
    );
  }

  static final RegExp _rtlChars = RegExp(r'[֐-ࣿיִ-﷿]');
  static bool _isRtl(String text) => _rtlChars.hasMatch(text);
}

CrossAxisAlignment _crossAxis(TextAlign align) => switch (align) {
  TextAlign.left || TextAlign.start => CrossAxisAlignment.start,
  TextAlign.right || TextAlign.end => CrossAxisAlignment.end,
  _ => CrossAxisAlignment.center,
};

/// Lays timed syllables out as whole words (syllables of one word are
/// grouped so a line never breaks mid-word) and paints each word's fill.
///
/// The words sit in one paragraph as inline widgets with real spaces
/// between them, so the line wraps exactly like the plain-text line it
/// replaces (a paragraph lets a line-end space hang; a Wrap of "word "
/// boxes would count it and push words onto the next line).
class _WordWrap extends StatelessWidget {
  final List<LyricWord> words;
  final Duration position;
  final TextStyle style;
  final Color activeColor;
  final Color unsungColor;
  final TextAlign textAlign;
  final bool rtl;
  final double lift;
  final bool wipe;
  final double emphasis;

  const _WordWrap({
    required this.words,
    required this.position,
    required this.style,
    required this.activeColor,
    required this.unsungColor,
    required this.textAlign,
    required this.rtl,
    required this.lift,
    required this.wipe,
    required this.emphasis,
  });

  static final RegExp _leadingSpace = RegExp(r'^\s+');
  static final RegExp _trailingSpace = RegExp(r'\s+$');

  /// Timed pieces grouped into sung words. A word ends at whitespace or
  /// punctuation ("parvati,parvati" lights up piece by piece), and a piece
  /// that *starts* with whitespace starts a new word - enhanced LRC often
  /// writes `word<t> next`, putting the space on the following piece.
  static List<List<LyricWord>> _groups(List<LyricWord> words) =>
      _groupCache[words] ??= () {
        final groups = <List<LyricWord>>[];
        var current = <LyricWord>[];
        for (final w in LyricLine.splitAtPunctuation(words)) {
          if (current.isNotEmpty && w.text.startsWith(_leadingSpace)) {
            groups.add(current);
            current = <LyricWord>[];
          }
          current.add(w);
          if (LyricLine.endsWord(w.text) || _trailingSpace.hasMatch(w.text)) {
            groups.add(current);
            current = <LyricWord>[];
          }
        }
        if (current.isNotEmpty) groups.add(current);
        // The spacing goes between the word widgets as real text, so each
        // word itself carries none - and none of its wipe time goes to
        // an invisible space.
        return [
          for (final group in groups)
            [
              for (var i = 0; i < group.length; i++)
                LyricWord(
                  startTime: group[i].startTime,
                  endTime: group[i].endTime,
                  text: switch (i) {
                    _ when group.length == 1 => group[i].text.trim(),
                    0 => group[i].text.trimLeft(),
                    _ when i == group.length - 1 => group[i].text.trimRight(),
                    _ => group[i].text,
                  },
                ),
            ],
        ]..removeWhere((g) => g.every((w) => w.text.isEmpty));
      }();

  static final Expando<List<List<LyricWord>>> _groupCache = Expando();

  /// How long a finished word's glow takes to come in.
  static const _glowFade = Duration(milliseconds: 450);

  /// 0..1 glow of a word, eased in over [_glowFade] after its last syllable
  /// ends. On the playback clock, so it pauses with the song and a word
  /// that was already sung shows its glow straight away.
  static double _glowIn(List<LyricWord> group, Duration position) {
    final since = position - group.last.endTime;
    if (since <= Duration.zero) return 0;
    final t = since.inMicroseconds / _glowFade.inMicroseconds;
    return Curves.easeInOutCubic.transform(t.clamp(0.0, 1.0));
  }

  @override
  Widget build(BuildContext context) {
    final groups = _groups(words);
    final direction = rtl ? TextDirection.rtl : TextDirection.ltr;
    return SizedBox(
      width: double.infinity,
      child: Text.rich(
        TextSpan(
          style: style,
          children: [
            for (var i = 0; i < groups.length; i++) ...[
              if (i > 0) const TextSpan(text: ' '),
              WidgetSpan(
                alignment: PlaceholderAlignment.baseline,
                baseline: TextBaseline.alphabetic,
                // The paragraph already scales inline widgets by the
                // system text size; the word's own Text must not scale
                // again, or the active line comes out bigger than the
                // plain line and wraps differently.
                child: MediaQuery.withNoTextScaling(
                  child: _SungWord(
                    text: groups[i].map((w) => w.text).join(),
                    fraction: LyricLine.sungFraction(groups[i], position),
                    glowIn: _glowIn(groups[i], position),
                    style: style,
                    activeColor: activeColor,
                    unsungColor: unsungColor,
                    rtl: rtl,
                    lift: lift,
                    wipe: wipe,
                    emphasis: emphasis,
                  ),
                ),
              ),
            ],
          ],
        ),
        textAlign: textAlign,
        textDirection: direction,
      ),
    );
  }
}

class _SungWord extends StatelessWidget {
  final String text;
  final double fraction;
  final double glowIn;
  final TextStyle style;
  final Color activeColor;
  final Color unsungColor;
  final bool rtl;
  final double lift;
  final bool wipe;
  final double emphasis;

  const _SungWord({
    required this.text,
    required this.fraction,
    required this.glowIn,
    required this.style,
    required this.activeColor,
    required this.unsungColor,
    required this.rtl,
    required this.lift,
    required this.wipe,
    required this.emphasis,
  });

  @override
  Widget build(BuildContext context) {
    final Widget word;
    final fontSize = style.fontSize ?? 30;
    final direction = rtl ? TextDirection.rtl : TextDirection.ltr;
    final singing = fraction > 0 && fraction < 1;
    // Only the word being sung needs its width (wipe gradient, swell).
    final width = singing
        ? (TextPainter(
            text: TextSpan(text: text, style: style),
            textDirection: direction,
            textScaler: TextScaler.noScaling,
            maxLines: 1,
          )..layout()).width
        : 0.0;
    // Sung words glow softly; unsung ones stay flat and dim, so the sung
    // part of the line reads clearly even over a bright artwork backdrop.
    // The glow fades with the line's emphasis, so a finishing line doesn't
    // drop it in one frame.
    // Desktop lyrics are much larger, where the phone-sized glow reads as a
    // heavy halo, so it is toned down there.
    final desktop = UiUtils.isDesktop;
    final glowAlpha = desktop ? 0.24 : 0.45;
    final glowBlur = fontSize * (desktop ? 0.2 : 0.4);
    List<Shadow> glowAt(double strength) => strength <= 0
        ? const <Shadow>[]
        : [
            Shadow(
              color: activeColor.withValues(alpha: glowAlpha * strength),
              blurRadius: glowBlur,
            ),
          ];
    const noGlow = <Shadow>[];

    if (!wipe) {
      // Word style: the whole word lights up as soon as it starts, with a
      // short fade so it reads as a pulse rather than a hard cut. The fade
      // is a 0..1 amount rather than an AnimatedDefaultTextStyle, which
      // would restart (and lag) on every frame while the line settles.
      word = TweenAnimationBuilder<double>(
        tween: Tween(end: fraction > 0 ? 1.0 : 0.0),
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        builder: (context, lit, _) => Text(
          text,
          textDirection: direction,
          style: style.copyWith(
            color: WordSyncedLyricText.settleColor(
              unsungColor,
              activeColor,
              lit,
            ),
            shadows: glowAt(emphasis * lit),
          ),
        ),
      );
    } else if (!singing || width <= 0) {
      // The glow eases in after the wipe has filled the word (glowIn)
      // instead of switching on in the frame it completes, a visible flash.
      final sung = fraction >= 1;
      word = Text(
        text,
        style: style.copyWith(
          color: sung ? activeColor : unsungColor,
          shadows: sung ? glowAt(emphasis * glowIn) : noGlow,
        ),
        textDirection: direction,
      );
    } else {
      // The wipe is painted into the glyphs themselves rather than masked
      // over the text box: Devanagari matras (and other tall marks) draw
      // outside that box, and a ShaderMask left them unpainted white.
      // A horizontal gradient only depends on x, so any rect height works.
      // Soft edge about half a glyph wide, whatever the word's length.
      final feather = (fontSize * 0.5 / width).clamp(0.03, 0.45);
      // Sweep from fully unsung to fully sung, edge included.
      final center = fraction * (1 + 2 * feather) - feather;
      final shader = LinearGradient(
        begin: rtl ? Alignment.centerRight : Alignment.centerLeft,
        end: rtl ? Alignment.centerLeft : Alignment.centerRight,
        colors: [activeColor, activeColor, unsungColor, unsungColor],
        stops: [
          0,
          (center - feather).clamp(0.0, 1.0),
          (center + feather).clamp(0.0, 1.0),
          1,
        ],
      ).createShader(Rect.fromLTWH(0, 0, width, fontSize));
      // A paint shader is placed in canvas coordinates; the boundary gives
      // the word its own layer, so its canvas starts at the word's origin.
      word = RepaintBoundary(
        child: Text(
          text,
          style: style.copyWith(
            foreground: Paint()..shader = shader,
            shadows: noGlow,
          ),
          textDirection: direction,
        ),
      );
    }

    final eased = Curves.easeOutCubic.transform(fraction.clamp(0.0, 1.0));
    // The word being sung swells slightly and settles back as it ends -
    // the "this word, now" cue, on top of the colour change. Capped to a
    // few pixels overall so a long word never grows over the space to
    // its neighbours and reads as merged with them.
    final maxSwell = width <= 0 ? 0.0 : fontSize * 0.12 / width;
    final swell = singing
        ? math.sin(math.pi * fraction) *
              math.min(wipe ? 0.04 : 0.07, maxSwell) *
              emphasis
        : 0.0;
    return Transform.translate(
      offset: Offset(0, -lift * eased),
      child: Transform.scale(
        scale: 1 + swell,
        alignment: Alignment.bottomCenter,
        child: word,
      ),
    );
  }
}
