import 'dart:math' as math;
import 'dart:ui' show ImageFilter, lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:looper_player/core/services/screen_awake.dart';
import 'package:looper_player/core/theme/app_fonts.dart';
import 'package:looper_player/core/utils/motion.dart';
import 'package:looper_player/features/library/domain/models/models.dart'
    show AppSettings;
import 'package:looper_player/features/playback/domain/lyric_models.dart';
import 'package:looper_player/features/playback/presentation/providers/lyrics/lyrics_notifier.dart';
import 'package:looper_player/features/playback/presentation/providers/playback/playback_notifier.dart';
import 'package:looper_player/features/playback/presentation/screens/lyrics_view.dart'
    show LyricsSyncMode;
import 'package:looper_player/features/playback/presentation/widgets/lyrics/advanced_lyric_line/advanced_lyric_line.dart';
import 'package:looper_player/features/playback/presentation/widgets/lyrics/advanced_lyric_line/word_synced_lyric_text.dart';
import 'package:looper_player/features/playback/presentation/widgets/lyrics/lyrics_scale.dart';
import 'package:looper_player/features/settings/presentation/providers/settings_notifier.dart';

/// Shared by the line under the cover and its landing spot on the lyrics
/// screen.
const String playerLyricLineHeroTag = 'player_lyric_line';

/// The current song's timed lyrics, or none (not loaded yet, another
/// song's, or lyrics without timestamps).
final playerLyricLinesProvider = Provider<List<LyricLine>>((ref) {
  final songId = ref.watch(playbackProvider.select((s) => s.currentSong?.id));
  return ref.watch(
    lyricsProvider.select(
      (s) => s.isSynced && s.songId == songId && songId != null
          ? s.parsedLines
          : const <LyricLine>[],
    ),
  );
});

/// The line sung at [position]: the first before the lyrics start, the last
/// after they end, -1 when there are none.
int lyricLineIndexAt(List<LyricLine> lines, Duration position) {
  if (lines.isEmpty) return -1;
  final i = lines.indexWhere(
    (l) => position >= l.startTime && position < l.endTime,
  );
  if (i >= 0) return i;
  return position < lines.first.startTime ? 0 : lines.length - 1;
}

/// How a line hands over to the next one (AppSettings.playerLyricLineTransition).
enum LyricLineTransition {
  cube,
  roll,
  flip,
  blur;

  static LyricLineTransition fromSetting(String value) => values.firstWhere(
    (t) => t.name == value,
    orElse: () => LyricLineTransition.cube,
  );
}

/// One line of the current lyric under the player's cover: as wide as the
/// cover, never wrapping (a long line pans as it's sung), in the lyrics
/// screen's font, colour and word / letter sync. Lines change with a cube,
/// rolling-digit, flip or blur transition. Tap opens the lyrics.
class PlayerLyricLine extends ConsumerStatefulWidget {
  const PlayerLyricLine({
    super.key,
    required this.width,
    required this.onTap,
    this.scale = 1.0,
    this.edgeInset = 0,
  });

  /// Room the line takes under the cover (gap included) at scale 1.
  static const double rowHeight = 38;
  static const double _gap = 10;
  static const double fontSize = 17;

  final double width;
  final double scale;

  /// How far in from the cover's edge a left / right aligned line starts,
  /// so it lines up with the title below instead of the cover's edge.
  final double edgeInset;
  final VoidCallback onTap;

  @override
  ConsumerState<PlayerLyricLine> createState() => _PlayerLyricLineState();
}

class _PlayerLyricLineState extends ConsumerState<PlayerLyricLine> {
  int _shown = -1;
  bool _forward = true;

  @override
  void dispose() {
    ScreenAwake.set(this, false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lines = ref.watch(playerLyricLinesProvider);
    final index = ref.watch(
      playbackProvider.select((s) => lyricLineIndexAt(lines, s.position)),
    );
    if (index != _shown) {
      // A seek back rolls the other way.
      _forward = _shown < 0 || index > _shown;
      _shown = index;
    }
    // Screen stays on while the line is showing and playing; the expanded
    // player stays mounted when collapsed, with its tickers off.
    ScreenAwake.set(
      this,
      lines.isNotEmpty &&
          TickerMode.valuesOf(context).enabled &&
          ref.watch(playbackProvider.select((s) => s.isPlaying)),
    );
    final settings = ref.watch(settingsProvider);
    final transition = LyricLineTransition.fromSetting(
      settings.playerLyricLineTransition,
    );
    final lineHeight =
        (PlayerLyricLine.rowHeight - PlayerLyricLine._gap) * widget.scale;
    final style = miniLyricStyle(
      settings,
      Theme.of(context).colorScheme.primary,
      PlayerLyricLine.fontSize * widget.scale,
    );
    final reduced = Motion.reducedOf(context);

    final align = switch (settings.lyricsAlignment) {
      'left' => TextAlign.left,
      'right' => TextAlign.right,
      _ => TextAlign.center,
    };
    final inset = align == TextAlign.center
        ? 0.0
        : widget.edgeInset.clamp(0.0, widget.width / 4);
    Widget content = index < 0
        ? const SizedBox.shrink()
        : _ActiveLyricLine(
            key: ValueKey(index),
            line: lines[index],
            mode: LyricsSyncMode.fromSetting(settings.lyricsSyncStyle),
            style: style,
            unsungColor: Colors.white.withValues(
              alpha: inactiveLyricsOpacity(settings),
            ),
            align: align,
            width: widget.width - inset,
            height: lineHeight,
          );
    if (inset > 0 && index >= 0) {
      content = Padding(
        // The hand-off tells the new line from the old one by this key.
        key: ValueKey(index),
        padding: align == TextAlign.left
            ? EdgeInsets.only(left: inset)
            : EdgeInsets.only(right: inset),
        child: content,
      );
    }
    content = AnimatedSwitcher(
      duration: Duration(milliseconds: reduced ? 0 : 460),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      layoutBuilder: (current, previous) => Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [...previous, ?current],
      ),
      transitionBuilder: (child, animation) => _LineHandOff(
        animation: animation,
        transition: transition,
        incoming: child.key == ValueKey(index),
        forward: _forward,
        height: lineHeight,
        child: child,
      ),
      child: content,
    );
    // The odometer look needs its window; the cube and flip turn in depth
    // and would be cut flat by a clip.
    if (transition == LyricLineTransition.roll) {
      content = ClipRect(child: content);
    }

    return Padding(
      padding: EdgeInsets.only(top: PlayerLyricLine._gap * widget.scale),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: Hero(
          tag: playerLyricLineHeroTag,
          flightShuttleBuilder: playerLyricLineShuttle,
          child: Material(
            type: MaterialType.transparency,
            child: SizedBox(
              width: widget.width,
              height: lineHeight,
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}

/// The lyrics screen's active-line style at [fontSize].
TextStyle miniLyricStyle(AppSettings settings, Color accent, double fontSize) {
  return AppFonts.getLyricsStyle(
    useNewFontLyrics: settings.useNewFontLyrics,
    family: settings.customFontFamilyLyrics,
    weightDelta: settings.customFontWeightLyricsDelta,
    activeWeightDelta: settings.activeLyricsFontWeightDelta,
    isActive: true,
    fontSize: fontSize,
    height: 1.15,
    color: activeLyricsColor(settings, accent: accent),
  );
}

/// Moves one line in or out. [animation] runs 0 -> 1 for the incoming line
/// and 1 -> 0 for the outgoing one, so `1 - value` is how far a line is
/// from its resting place either way; [incoming] picks the side it is on.
class _LineHandOff extends StatelessWidget {
  const _LineHandOff({
    required this.animation,
    required this.transition,
    required this.incoming,
    required this.forward,
    required this.height,
    required this.child,
  });

  final Animation<double> animation;
  final LyricLineTransition transition;
  final bool incoming;
  final bool forward;
  final double height;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        final v = animation.value.clamp(0.0, 1.0);
        final p = 1 - v;
        // Next line comes from below and the old one leaves upward
        // (reversed after a seek back).
        final side = (incoming ? 1.0 : -1.0) * (forward ? 1.0 : -1.0);
        switch (transition) {
          case LyricLineTransition.cube:
            // Faces of a cube turning about its own centre, half a line
            // behind the text.
            final depth = height / 2;
            return Opacity(
              opacity: (1 - p * 0.7).clamp(0.0, 1.0),
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.006)
                  ..translateByDouble(0, 0, depth, 1)
                  ..rotateX(side * p * math.pi / 2)
                  ..translateByDouble(0, 0, -depth, 1),
                child: child,
              ),
            );
          case LyricLineTransition.roll:
            // A digit on a rolling counter.
            return Opacity(
              opacity: v,
              child: Transform.translate(
                offset: Offset(0, side * p * height),
                child: child,
              ),
            );
          case LyricLineTransition.flip:
            // Split-flap: the old line folds away in the first half, the
            // new one unfolds in the second.
            if (v < 0.5) return const SizedBox.shrink();
            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.004)
                ..rotateX(side * (1 - v) * 2 * math.pi / 2),
              child: child,
            );
          case LyricLineTransition.blur:
            final sigma = p * 6;
            return Opacity(
              opacity: v,
              child: Transform.translate(
                offset: Offset(0, side * p * height * 0.35),
                child: Transform.scale(
                  scale: 1 - p * 0.08,
                  child: sigma < 0.1
                      ? child
                      : ImageFiltered(
                          imageFilter: ImageFilter.blur(
                            sigmaX: sigma,
                            sigmaY: sigma,
                          ),
                          child: child,
                        ),
                ),
              ),
            );
        }
      },
    );
  }
}

const String _lyricEllipsis = '\u2026';

/// One lyric line, kept to one row in the lyrics alignment. A line too long
/// for the cover is cut at the last word that fits and ends in "…".
class _ActiveLyricLine extends ConsumerWidget {
  const _ActiveLyricLine({
    super.key,
    required this.line,
    required this.mode,
    required this.style,
    required this.unsungColor,
    required this.align,
    required this.width,
    required this.height,
  });

  final LyricLine line;
  final LyricsSyncMode mode;
  final TextStyle style;
  final Color unsungColor;
  final TextAlign align;
  final double width;
  final double height;

  bool get _instrumental => AdvancedLyricLine.isInstrumentalText(line.text);

  bool get _wordTimed =>
      !_instrumental && mode != LyricsSyncMode.line && line.hasWordTiming;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Widget body;
    if (_wordTimed) {
      final shown = fitLyricWords(
        line,
        style,
        // Room for the sung words' lift and swell.
        width - (style.fontSize ?? 17) * 0.6,
        MediaQuery.textScalerOf(context),
      );
      body = Consumer(
        builder: (context, ref, _) {
          final reported = ref.watch(
            playbackProvider.select((s) => s.position),
          );
          final isPlaying = ref.watch(
            playbackProvider.select((s) => s.isPlaying),
          );
          // Before the seek to this line lands, show it unsung.
          final position =
              reported < line.startTime ||
                  reported > line.endTime + const Duration(seconds: 1)
              ? line.startTime
              : reported;
          return WordSyncedLyricText(
            line: shown,
            position: position,
            isPlaying: isPlaying,
            style: style,
            activeColor: style.color ?? Colors.white,
            unsungColor: unsungColor,
            textAlign: align,
            fontScale: (style.fontSize ?? 17) / 30,
            wipe: mode == LyricsSyncMode.char,
            showBackground: false,
          );
        },
      );
    } else {
      body = Text(
        _instrumental ? '\u266b' : line.text,
        style: style,
        textAlign: align,
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.ellipsis,
      );
    }
    return SizedBox(
      width: width,
      height: height,
      // Clipped so a word's lift can never spill a second row.
      child: ClipRect(
        child: Align(
          alignment: switch (align) {
            TextAlign.left => Alignment.centerLeft,
            TextAlign.right => Alignment.centerRight,
            _ => Alignment.center,
          },
          child: body,
        ),
      ),
    );
  }
}

/// [line] as is when it fits in [maxWidth]; otherwise its words up to the
/// last whole word that fits with "…" after it. The "…" is timed over the
/// words it stands for, so it fills while they are sung.
LyricLine fitLyricWords(
  LyricLine line,
  TextStyle style,
  double maxWidth,
  TextScaler scaler,
) {
  double widthOf(String text) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textScaler: scaler,
      maxLines: 1,
    )..layout();
    final w = painter.width;
    painter.dispose();
    return w;
  }

  final words = line.words;
  if (widthOf(words.map((w) => w.text).join()) <= maxWidth) return line;
  var keep = 0;
  var text = '';
  for (var i = 0; i < words.length; i++) {
    text += words[i].text;
    final atWordEnd =
        i == words.length - 1 ||
        words[i].text.endsWith(' ') ||
        words[i + 1].text.startsWith(' ');
    if (!atWordEnd) continue;
    if (widthOf(text.trimRight() + _lyricEllipsis) > maxWidth) break;
    keep = i + 1;
  }
  // Not even one word fits: cut that word's text short.
  if (keep == 0) keep = 1;
  final kept = [
    ...words.take(keep - 1),
    LyricWord(
      startTime: words[keep - 1].startTime,
      endTime: words[keep - 1].endTime,
      text: words[keep - 1].text.trimRight(),
    ),
  ];
  return LyricLine(
    startTime: line.startTime,
    endTime: line.endTime,
    text: kept.map((w) => w.text).join() + _lyricEllipsis,
    words: [
      ...kept,
      LyricWord(
        startTime: keep < words.length
            ? words[keep].startTime
            : words.last.endTime,
        endTime: words.last.endTime,
        text: _lyricEllipsis,
      ),
    ],
  );
}

/// Where the line lands on the lyrics screen: the spot the active line rests
/// at (see AdvancedLyricRenderer's anchor). The lyrics list only scrolls to
/// its active line after its first frame, and a hero's landing spot is fixed
/// when it takes off, so it aims here and fades into the real line.
class PlayerLyricLineLanding extends ConsumerWidget {
  const PlayerLyricLineLanding({super.key, required this.horizontalPadding});

  final double horizontalPadding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fontScale = LyricsScale.normalize(
      ref.watch(settingsProvider.select((s) => s.lyricsFontScale)),
    );
    final lineHeight = 30 * fontScale * 1.15;
    return LayoutBuilder(
      builder: (context, box) {
        // Row = list padding 7 + line padding 8 + selection inset 2, top
        // and bottom, around the text.
        final rowHeight = lineHeight + 14 + 20 * fontScale;
        final top = 0.15 * (box.maxHeight - rowHeight) + 7 + 10 * fontScale;
        return Stack(
          children: [
            Positioned(
              top: top,
              left: horizontalPadding,
              right: horizontalPadding,
              height: lineHeight,
              child: const IgnorePointer(
                child: Hero(
                  tag: playerLyricLineHeroTag,
                  flightShuttleBuilder: playerLyricLineShuttle,
                  child: SizedBox.expand(),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// The current line growing from the player's small line into the lyrics
/// screen's big one (and back), fading into the real line at the big end.
Widget playerLyricLineShuttle(
  BuildContext flightContext,
  Animation<double> animation,
  HeroFlightDirection flightDirection,
  BuildContext fromHeroContext,
  BuildContext toHeroContext,
) {
  final playerSide = flightDirection == HeroFlightDirection.push
      ? fromHeroContext
      : toHeroContext;
  double heightOf(BuildContext c) {
    final box = c.findRenderObject();
    return box is RenderBox && box.hasSize ? box.size.height : 0;
  }

  return _LyricLineFlight(
    animation: animation,
    smallHeight: heightOf(playerSide),
  );
}

class _LyricLineFlight extends ConsumerWidget {
  const _LyricLineFlight({required this.animation, required this.smallHeight});

  /// 0 at the player, 1 at the lyrics screen, in both directions.
  final Animation<double> animation;
  final double smallHeight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lines = ref.watch(playerLyricLinesProvider);
    final index = lyricLineIndexAt(lines, ref.read(playbackProvider).position);
    if (index < 0) return const SizedBox.shrink();
    final line = lines[index];
    final settings = ref.watch(settingsProvider);
    final accent = Theme.of(context).colorScheme.primary;
    final fontScale = LyricsScale.normalize(settings.lyricsFontScale);
    final smallSize = smallHeight > 0
        ? smallHeight /
              (PlayerLyricLine.rowHeight - PlayerLyricLine._gap) *
              PlayerLyricLine.fontSize
        : PlayerLyricLine.fontSize;
    final small = miniLyricStyle(settings, accent, smallSize);
    final big = miniLyricStyle(settings, accent, 30 * fontScale);
    final bigAlign = switch (settings.lyricsAlignment) {
      'left' => Alignment.centerLeft,
      'right' => Alignment.centerRight,
      _ => Alignment.center,
    };
    final text = AdvancedLyricLine.isInstrumentalText(line.text)
        ? '♫'
        : line.text;
    return Material(
      type: MaterialType.transparency,
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, _) {
          final t = Curves.easeInOutCubic.transform(animation.value);
          return Opacity(
            // Hands over to the real line as the lyrics fade in under it.
            opacity: 1 - const Interval(0.7, 1.0).transform(animation.value),
            child: ClipRect(
              child: OverflowBox(
                alignment: bigAlign,
                minWidth: 0,
                maxWidth: double.infinity,
                maxHeight: double.infinity,
                child: Text(
                  text,
                  style: TextStyle.lerp(small, big, t)!.copyWith(
                    fontSize: lerpDouble(small.fontSize, big.fontSize, t),
                  ),
                  maxLines: 1,
                  softWrap: false,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
