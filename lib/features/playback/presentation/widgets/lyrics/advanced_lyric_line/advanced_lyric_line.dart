import 'dart:io';

import 'package:flutter/material.dart';
import 'package:looper_player/core/utils/motion.dart';
import 'package:looper_player/core/theme/app_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:looper_player/core/utils/artwork_colors.dart';
import 'package:looper_player/features/library/domain/models/models.dart'
    show AppSettings;

import '../../../providers/playback/playback_notifier.dart';
import '../../../providers/lyrics/lyrics_search_provider.dart';
import '../../../../domain/lyric_models.dart';
import '../../../screens/lyrics_view.dart';
import '../../../../../settings/presentation/providers/settings_notifier.dart';
import 'word_synced_lyric_text.dart';
part 'pulsing_instrumental_icon.dart';

/// The current artwork's raw primary color, extracted once per song.
final artworkRawColorProvider = FutureProvider<Color?>((ref) async {
  final currentSong = ref.watch(playbackProvider.select((s) => s.currentSong));
  final artPath = currentSong?.artPath;
  if (artPath == null) return null;

  final file = File(artPath);
  if (!await file.exists()) return null;

  try {
    final colors = await ArtworkColors.fromProvider(FileImage(file));
    if (colors != null) return colors.primary;
  } catch (e) {}
  return null;
});

/// The artwork color, lifted to read on a dark background (lyrics share
/// card). Separate from [artworkRawColorProvider] so it's extracted once.
final artworkColorProvider = Provider<Color?>((ref) {
  final raw = ref.watch(artworkRawColorProvider).value;
  return raw == null ? null : readableOnDark(raw);
});

/// Whether the active lyric line is plain white ("Dynamic Color Active
/// Line" off). The accent toggle and intensity slider do nothing then.
bool activeLyricsIsWhite(AppSettings settings) =>
    !settings.dynamicColorActiveLyrics;

/// The active lyric line's color, from the app [accent] (theme primary,
/// which already follows the artwork with dynamic theming):
/// - "Accent Color Active Line" on: the accent itself, made more saturated
///   by the intensity slider ([lyricsActiveColor]).
/// - off: the accent blended with white, the slider bringing back more of
///   the color ([lyricsSoftActiveColor]).
Color activeLyricsColor(AppSettings settings, {required Color accent}) {
  if (activeLyricsIsWhite(settings)) return Colors.white;
  return !settings.activeLyricsSoftColor
      ? lyricsActiveColor(accent, intensity: settings.activeLyricsIntensity)
      : lyricsSoftActiveColor(
          accent,
          intensity: settings.activeLyricsIntensity,
        );
}

class AdvancedLyricLine extends ConsumerWidget {
  final LyricLine line;
  final LyricsSyncMode mode;
  final bool isActive;

  /// The first line of a pair sung in one breath, while the second is
  /// current: it keeps the active look, fully sung, instead of dimming.
  final bool held;
  final VoidCallback onTap;
  final double fontScale;

  /// How many lines away from the current one this line is. Lines dim
  /// step by step with it, so the lyrics fade into the dark above and
  /// below the line being sung.
  final int distance;

  /// What an inactive line's text opacity is [distance] lines from the
  /// current one: the old uniform 0.35 next to it, down to a floor that
  /// still reads.
  static double inactiveOpacity(int distance) =>
      (0.35 - (distance - 1).clamp(0, 5) * 0.05).clamp(0.12, 0.35);

  /// False for lyrics without timestamps: every line reads as plain text,
  /// none of them current, sung or tappable to seek.
  final bool synced;

  /// Whether this line is part of the current share-card selection, and
  /// whether a selection is in progress at all (used to dim non-selected
  /// lines so the picked lines stand out). Long-pressing starts a selection.
  final bool isSelected;
  final bool selectionActive;
  final VoidCallback onLongPress;

  const AdvancedLyricLine({
    super.key,
    required this.line,
    required this.mode,
    required this.isActive,
    required this.onTap,
    required this.onLongPress,
    this.held = false,
    this.isSelected = false,
    this.selectionActive = false,
    this.fontScale = 1.0,
    this.synced = true,
    this.distance = 1,
  });

  /// Whether a line is a music break, shown as "♫" instead of its text.
  static bool isInstrumentalText(String text) =>
      text.isEmpty ||
      text.toLowerCase().contains('instrumental') ||
      text.toLowerCase().contains('[music]') ||
      text.trim() == '♪';

  /// Word/char styles only apply to lines with real word timing; anything
  /// else is shown line by line, whatever style is picked.
  bool get usesWordTiming => mode != LyricsSyncMode.line && line.hasWordTiming;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Only watch position if this line is active and in word/char sync modes, avoiding rebuilds of all other lines
    final lit = isActive || held;
    final needsPosition = lit && usesWordTiming;
    final reportedPosition = needsPosition
        ? ref.watch(playbackProvider.select((s) => s.position))
        : Duration.zero;
    // Right after tapping a line it's active before the seek lands, so the
    // position can still be from elsewhere in the song - show it unsung
    // rather than flashing it fully sung.
    // A held line is past its own time by design: it follows the real
    // position (its last word may still be finishing) and is otherwise
    // fully sung.
    final currentPosition = !needsPosition
        ? reportedPosition
        : held
        ? (reportedPosition < line.startTime
              ? const Duration(days: 1)
              : reportedPosition)
        : (reportedPosition < line.startTime ||
              reportedPosition > line.endTime + const Duration(seconds: 1))
        ? line.startTime
        : reportedPosition;
    // Word-timed lines also need it while inactive: a line that just
    // finished keeps its last word running while it settles.
    final isPlaying = usesWordTiming
        ? ref.watch(playbackProvider.select((s) => s.isPlaying))
        : false;

    final isPast = isActive || !synced
        ? false
        : (ref.read(playbackProvider).position > line.endTime);

    // Calculate dynamic opacity based on distance from active line for a smoother transition
    double lineOpacity = 1.0;
    if (isSelected) {
      lineOpacity =
          1.0; // selected lines should read clearly regardless of playback position
    } else if (selectionActive) {
      lineOpacity =
          0.18; // dim everything else while the user is picking lines to share
    } else if (!synced) {
      lineOpacity = 0.8; // text to read: no current line to stand out from
    } else if (!lit) {
      lineOpacity = inactiveOpacity(distance);
    }

    final settings = ref.watch(settingsProvider);
    // Duet partner lines sit on the opposite side (centered stays centered).
    final alignmentString = switch ((
      line.isOppositeSide,
      settings.lyricsAlignment,
    )) {
      (true, 'left') => 'right',
      (true, 'right') => 'left',
      (_, final alignment) => alignment,
    };
    // Glow for colored active lines, not plain white.
    final useDynamicColor = !activeLyricsIsWhite(settings);

    final textAlign = alignmentString == 'left'
        ? TextAlign.left
        : alignmentString == 'right'
        ? TextAlign.right
        : TextAlign.center;

    final iconAlignment = alignmentString == 'left'
        ? Alignment.centerLeft
        : alignmentString == 'right'
        ? Alignment.centerRight
        : Alignment.center;

    final activeColor = activeLyricsColor(
      settings,
      accent: Theme.of(context).colorScheme.primary,
    );

    // Hindi and other Indic text falls back per glyph to a bundled font that
    // matches the chosen one (see AppFonts.scriptFallbackFor).
    final baseStyle = AppFonts.getLyricsStyle(
      useNewFontLyrics: settings.useNewFontLyrics,
      family: settings.customFontFamilyLyrics,
      weightDelta: settings.customFontWeightLyricsDelta,
      activeWeightDelta: settings.activeLyricsFontWeightDelta,
      isActive: lit,
      fontSize: 30 * fontScale, //(isActive ? 30.5 : 30) * fontScale,
      height: 1.15,
      color: lit ? activeColor : Colors.white.withValues(alpha: lineOpacity),
      shadows: lit && useDynamicColor ? [_glow(activeColor, 1)] : null,
    );

    // Unified animation duration and easeInOutCubic curve for a buttery-smooth transition
    final animDuration = const Duration(milliseconds: 400);
    final curve = Curves.easeInOutCubic;

    // Watch the search query for highlighting
    final searchQuery = ref.watch(lyricsSearchQueryProvider).toLowerCase();

    final childWidget = _withExtraLines(
      _buildModeContent(
        context,
        isPast,
        baseStyle,
        activeColor,
        searchQuery,
        textAlign,
        iconAlignment,
        currentPosition,
        isPlaying,
      ),
      textAlign,
    );

    return MouseRegion(
      cursor: synced ? SystemMouseCursors.click : MouseCursor.defer,
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        // The same height whether active or not: the list's follow motion
        // measures where a line rests, so a line must not resize under it.
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8 * fontScale),
          child: _selectionHighlight(
            child: AnimatedDefaultTextStyle(
              duration: animDuration,
              curve: curve,
              // The glow is faded below, not here: a text style animating
              // to "no shadow" only shrinks the shadow's blur and keeps
              // its colour, so a line that stopped being current held a
              // sharp accent copy of itself behind the fading text - and
              // dropped it in one frame when the animation ended.
              style: baseStyle.copyWith(shadows: const []),
              softWrap: true,
              textAlign: textAlign,
              child: TweenAnimationBuilder<double>(
                tween: Tween(end: lit && useDynamicColor ? 1.0 : 0.0),
                duration: animDuration,
                curve: curve,
                child: childWidget,
                builder: (context, glow, child) => glow <= 0
                    ? child!
                    : DefaultTextStyle.merge(
                        style: TextStyle(shadows: [_glow(activeColor, glow)]),
                        child: child!,
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// The soft glow under a colored active line, at [strength] 0..1.
  static Shadow _glow(Color color, double strength) => Shadow(
    color: color.withValues(alpha: 0.3 * strength),
    blurRadius: 20,
    offset: const Offset(0, 4),
  );

  /// Wraps [child] in a tinted, rounded background when this line is part
  /// of the active share-card selection.
  Widget _selectionHighlight({required Widget child}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      padding: EdgeInsets.symmetric(
        horizontal: isSelected ? 10 * fontScale : 0,
        vertical: 2 * fontScale,
      ),
      decoration: BoxDecoration(
        color: isSelected
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }

  Widget _buildModeContent(
    BuildContext context,
    bool isPast,
    TextStyle baseStyle,
    Color activeColor,
    String searchQuery,
    TextAlign textAlign,
    Alignment iconAlignment,
    Duration position,
    bool isPlaying,
  ) {
    final String text = line.text;
    final bool isInstrumental = isInstrumentalText(text);

    // If there is a search match, always highlight it
    final bool isSearchMatch =
        searchQuery.isNotEmpty &&
        line.fullText.toLowerCase().contains(searchQuery);

    // Word/char styles follow the singer's real word timing (lrc.red,
    // LyricsPlus, enhanced LRC). The word-synced text stays up across the
    // hand-off in both directions: swapping it for plain text the frame
    // the line changed dropped the lifted words, cut the glow and faded
    // through a milky accent-to-white mix. Instead lift, glow and colour
    // settle together, and plain text takes over only once it looks the
    // same.
    if (!isInstrumental && usesWordTiming) {
      final lit = isActive || held;
      return TweenAnimationBuilder<double>(
        tween: Tween(end: lit ? 1.0 : 0.0),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
        builder: (context, emphasis, _) => !lit && emphasis <= 0
            ? _inactiveText(
                isPast,
                baseStyle,
                activeColor,
                isSearchMatch,
                textAlign,
              )
            : WordSyncedLyricText(
                wipe: mode == LyricsSyncMode.char,
                line: line,
                position: position,
                isPlaying: isPlaying,
                style: baseStyle,
                activeColor: activeColor,
                // Upcoming words wear the plain inactive-line color (and a
                // settling line ends on exactly that color).
                unsungColor: lit
                    ? Colors.white.withValues(alpha: 0.35)
                    : (baseStyle.color ?? Colors.white.withValues(alpha: 0.85)),
                textAlign: textAlign,
                fontScale: fontScale,
                active: lit,
                emphasis: emphasis,
              ),
      );
    }

    if (!isActive && !isPast) {
      return isInstrumental
          ? Align(
              alignment: iconAlignment,
              child: Text(
                '♫',
                style: baseStyle.copyWith(color: Colors.white24),
              ),
            )
          : _inactiveText(
              isPast,
              baseStyle,
              activeColor,
              isSearchMatch,
              textAlign,
            );
    }

    if (isPast) {
      return isInstrumental
          ? Align(
              alignment: iconAlignment,
              child: Text(
                '♫',
                style: baseStyle.copyWith(color: Colors.white10),
              ),
            )
          : _inactiveText(
              isPast,
              baseStyle,
              activeColor,
              isSearchMatch,
              textAlign,
            );
    }

    // For active line, add music symbols if it's instrumental
    final displayText = isInstrumental ? '♫' : text;

    // Line style, or an instrumental break in any style.
    return isInstrumental
        ? Align(
            alignment: iconAlignment,
            // Same "♫" glyph as the not-active/past instrumental symbol
            // above - only the animation (see _PulsingInstrumentalIcon)
            // marks this one out as the active line, not a symbol swap.
            child: _PulsingInstrumentalIcon(
              color: activeColor,
              style: baseStyle,
            ),
          )
        // No style of its own: it wears the animated one above, so the
        // line eases into its active colour and glow the way it eases out.
        : Text(
            displayText,
            textAlign: textAlign,
            softWrap: true,
            overflow: TextOverflow.visible,
          );
  }

  /// The plain text of a line that isn't current (upcoming lines can carry
  /// a search highlight; past ones never do).
  Widget _inactiveText(
    bool isPast,
    TextStyle baseStyle,
    Color activeColor,
    bool isSearchMatch,
    TextAlign textAlign,
  ) {
    return _withBackgroundVocals(
      Text(
        line.text,
        style: !isPast && isSearchMatch
            ? baseStyle.copyWith(color: activeColor.withValues(alpha: 0.9))
            : null,
        textAlign: textAlign,
        softWrap: true,
        overflow: TextOverflow.visible,
      ),
      baseStyle,
      textAlign,
    );
  }

  /// The lines sharing this line's timestamp (translation, romanization)
  /// as smaller, dimmer lines under [main]. They wear the line's animated
  /// style, so the whole block eases in and out of being current together.
  Widget _withExtraLines(Widget main, TextAlign textAlign) {
    if (line.extraLines.isEmpty) return main;
    return Column(
      crossAxisAlignment: switch (textAlign) {
        TextAlign.left => CrossAxisAlignment.start,
        TextAlign.right => CrossAxisAlignment.end,
        _ => CrossAxisAlignment.center,
      },
      mainAxisSize: MainAxisSize.min,
      children: [
        main,
        for (final extra in line.extraLines) ...[
          SizedBox(height: 4 * fontScale),
          Builder(
            builder: (context) {
              final style = DefaultTextStyle.of(context).style;
              return Text(
                extra,
                textAlign: textAlign,
                softWrap: true,
                style: style.copyWith(
                  fontSize: (style.fontSize ?? 30) * 0.62,
                  height: 1.2,
                  color: (style.color ?? Colors.white).withValues(
                    alpha: (style.color?.a ?? 1) * 0.7,
                  ),
                ),
              );
            },
          ),
        ],
      ],
    );
  }

  /// Background vocals as a smaller, dimmer line under [main] (inactive and
  /// past lines; the active line's are animated by WordSyncedLyricText).
  Widget _withBackgroundVocals(
    Widget main,
    TextStyle baseStyle,
    TextAlign textAlign,
  ) {
    final background = line.backgroundText;
    if (background.isEmpty) return main;
    return Column(
      crossAxisAlignment: switch (textAlign) {
        TextAlign.left => CrossAxisAlignment.start,
        TextAlign.right => CrossAxisAlignment.end,
        _ => CrossAxisAlignment.center,
      },
      mainAxisSize: MainAxisSize.min,
      children: [
        main,
        SizedBox(height: 4 * fontScale),
        Text(
          background,
          textAlign: textAlign,
          softWrap: true,
          style: baseStyle.copyWith(
            fontSize: (baseStyle.fontSize ?? 30) * 0.62,
            height: 1.2,
            color: (baseStyle.color ?? Colors.white).withValues(
              alpha: (baseStyle.color?.a ?? 1) * 0.7,
            ),
          ),
        ),
      ],
    );
  }
}
