import 'dart:io';
import 'dart:ui';

import 'package:looper_player/ui/android/player/lyrics/lyrics_screen_style.dart';

import 'package:looper_player/ui/widgets/common/optimized_image.dart';
import 'package:flutter/material.dart';
import 'package:looper_player/core/utils/motion.dart';
import 'package:looper_player/core/utils/responsive.dart';
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

  if (!await artAvailable(artPath)) return null;

  try {
    final colors = await ArtworkColors.fromProvider(artImage(artPath));
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
/// Line" off). The intensity slider does nothing then.
bool activeLyricsIsWhite(AppSettings settings) =>
    !settings.dynamicColorActiveLyrics;

/// The active lyric line's color: white, or the app [accent] (theme
/// primary, which follows the artwork with dynamic theming) made more
/// saturated by the intensity slider.
Color activeLyricsColor(AppSettings settings, {required Color accent}) {
  if (activeLyricsIsWhite(settings)) return Colors.white;
  return lyricsActiveColor(accent, intensity: settings.activeLyricsIntensity);
}

/// The opacity of the inactive lyric line next to the current one, from the
/// "Inactive Line Opacity" slider.
double inactiveLyricsOpacity(AppSettings settings) {
  final v = settings.inactiveLyricsOpacity;
  return v == null || v.isNaN
      ? AdvancedLyricLine.defaultInactiveOpacity
      : v
            .clamp(
              AdvancedLyricLine.minInactiveOpacity,
              AdvancedLyricLine.maxInactiveOpacity,
            )
            .toDouble();
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

  static const double defaultInactiveOpacity = 0.51,
      minInactiveOpacity = 0.1,
      maxInactiveOpacity = 1.0;

  /// What an inactive line's text opacity is [distance] lines from the
  /// current one: [near] next to it, fading down the lines to about a third
  /// of that. Above the default the fade shrinks, so [near] = 1 is solid.
  static double inactiveOpacity(
    int distance, [
    double near = defaultInactiveOpacity,
  ]) {
    final fade =
        (0.35 - (distance - 1).clamp(0, 5) * 0.05).clamp(0.12, 0.35) / 0.35;
    final solid =
        ((near - defaultInactiveOpacity) / (1 - defaultInactiveOpacity)).clamp(
          0.0,
          1.0,
        );
    return near * fade + (1 - fade) * solid;
  }

  /// False for lyrics without timestamps: every line reads as plain text,
  /// none of them current, sung or tappable to seek.
  final bool synced;

  /// Whether this line is part of the current share-card selection, and
  /// whether a selection is in progress at all (used to dim non-selected
  /// lines so the picked lines stand out). Long-pressing starts a selection.
  final bool isSelected;
  final bool selectionActive;
  final VoidCallback onLongPress;
  final LyricsScreenStyle? previewStyle;

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
    this.previewStyle,
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

    final settings = ref.watch(settingsProvider);
    final screenStyle =
        previewStyle ?? LyricsScreenStyle.fromSetting(settings.lyricsStyle);
    final isLandscape = Responsive.isShort(MediaQuery.sizeOf(context));
    final resolved = ResolvedLyricsTextConfig.resolve(
      screenStyle,
      settings,
      isLandscape: isLandscape,
    );
    final inactiveNear = inactiveLyricsOpacity(settings);

    final bool isBigType = screenStyle == LyricsScreenStyle.bigtype;
    final bool isZen = screenStyle == LyricsScreenStyle.zen;
    if (isZen && synced && distance > 1) {
      return const SizedBox.shrink();
    }
    if (isBigType && synced && (isPast || (!lit && distance > 1))) {
      return const SizedBox.shrink();
    }

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
      lineOpacity = switch (screenStyle) {
        LyricsScreenStyle.oled => 0.18,
        LyricsScreenStyle.karaoke => 0.26,
        LyricsScreenStyle.spatial => 0.32,
        LyricsScreenStyle.bigtype => 0.40,
        _ => inactiveOpacity(distance, inactiveNear),
      };
    }

    // Explicit alignment overrides duet and centered styles; Auto flips duet v2 right when left-aligned.
    final TextAlign textAlign = resolved.explicitAlign
        ? resolved.align
        : (line.isOppositeSide && resolved.align == TextAlign.left
              ? TextAlign.right
              : resolved.align);

    final iconAlignment = switch (textAlign) {
      TextAlign.left || TextAlign.start => Alignment.centerLeft,
      TextAlign.right || TextAlign.end => Alignment.centerRight,
      _ => Alignment.center,
    };

    // Glow for colored active lines, not plain white.
    final useDynamicColor =
        !activeLyricsIsWhite(settings) &&
        screenStyle != LyricsScreenStyle.oled;

    final activeColor =
        resolved.activeColorOverride ??
        activeLyricsColor(
          settings,
          accent: Theme.of(context).colorScheme.primary,
        );

    double lineFontSize = resolved.activeSize * fontScale;
    if (isZen && synced && !lit) {
      lineFontSize = 17.0 * (resolved.activeSize / 30.0) * fontScale;
    } else if (isBigType && synced && !lit) {
      lineFontSize = 16.0 * (resolved.activeSize / 42.0) * fontScale;
    }

    final double? letterSpacing = resolved.letterSpacingEm != null
        ? resolved.letterSpacingEm! * lineFontSize
        : null;

    // Hindi and other Indic text falls back per glyph to a bundled font that
    // matches the chosen one (see AppFonts.scriptFallbackFor).
    final baseStyle = AppFonts.getLyricsStyle(
      useNewFontLyrics: true,
      family: resolved.family,
      weightDelta: settings.customFontWeightLyricsDelta,
      activeWeightDelta: settings.activeLyricsFontWeightDelta,
      isActive: lit,
      fontWeight: (isBigType && synced && !lit)
          ? FontWeight.w500
          : resolved.weight,
      fontStyle: resolved.fontStyle,
      letterSpacing: letterSpacing,
      fontSize: lineFontSize,
      height: resolved.height,
      color: lit ? activeColor : Colors.white.withValues(alpha: lineOpacity),
      shadows: lit && useDynamicColor
          ? [
              screenStyle == LyricsScreenStyle.karaoke
                  ? Shadow(
                      color: activeColor.withValues(alpha: 0.35),
                      blurRadius: 30,
                    )
                  : _glow(activeColor, 1),
            ]
          : null,
    );

    // Unified animation duration and easeInOutCubic curve for a buttery-smooth transition
    final animDuration = const Duration(milliseconds: 400);
    final curve = Curves.easeInOutCubic;

    // Watch the search query for highlighting
    final searchQuery = ref.watch(lyricsSearchQueryProvider).toLowerCase();

    final content = _buildModeContent(
      context,
      isPast,
      baseStyle,
      activeColor,
      searchQuery,
      textAlign,
      iconAlignment,
      currentPosition,
      isPlaying,
      inactiveNear,
      textTransform: resolved.applyCase,
    );

    final childWidget = (isBigType && synced && !lit)
        ? content
        : _withExtraLines(
            content,
            textAlign,
            showTranslation: settings.showLyricsTranslation,
            showRomanization: settings.showLyricsRomanization,
            fontFamily: resolved.family,
            gap: isBigType ? 12 * fontScale : 5 * fontScale,
          );

    Widget styledChild = AnimatedDefaultTextStyle(
      duration: animDuration,
      curve: curve,
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
                style: TextStyle(
                  shadows: [
                    screenStyle == LyricsScreenStyle.karaoke
                        ? Shadow(
                            color: activeColor.withValues(alpha: 0.35 * glow),
                            blurRadius: 30,
                          )
                        : _glow(activeColor, glow),
                  ],
                ),
                child: child!,
              ),
      ),
    );

    if (screenStyle == LyricsScreenStyle.spatial && synced && !lit) {
      styledChild = ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 1.6, sigmaY: 1.6),
        child: styledChild,
      );
    } else if (screenStyle == LyricsScreenStyle.karaoke && synced && !lit) {
      styledChild = Transform.scale(scale: 0.84, child: styledChild);
    } else if (screenStyle == LyricsScreenStyle.editorial && lit) {
      styledChild = Container(
        padding: const EdgeInsets.only(left: 12),
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: activeColor, width: 2)),
        ),
        child: styledChild,
      );
    } else if (screenStyle == LyricsScreenStyle.m3 && lit) {
      styledChild = Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: activeColor.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(24),
        ),
        child: styledChild,
      );
    } else if (screenStyle == LyricsScreenStyle.timeline) {
      final sec = line.startTime.inSeconds.clamp(0, 359999);
      final ts =
          '${(sec ~/ 60).toString().padLeft(2, '0')}:${(sec % 60).toString().padLeft(2, '0')}';
      styledChild = Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          SizedBox(
            width: 46,
            child: Text(
              ts,
              style: AppFonts.familyStyle(
                AppFonts.jetBrainsMono,
                fontSize: 11,
                fontWeight: lit ? FontWeight.w600 : FontWeight.w400,
                color: lit ? activeColor : Colors.white.withValues(alpha: 0.38),
              ),
            ),
          ),
          Expanded(child: styledChild),
        ],
      );
    } else if (isBigType && synced && !lit) {
      styledChild = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 1,
            margin: const EdgeInsets.only(top: 14, bottom: 14),
            color: Colors.white.withValues(alpha: 0.10),
          ),
          styledChild,
        ],
      );
    }

    return MouseRegion(
      cursor: synced ? SystemMouseCursors.click : MouseCursor.defer,
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        // The same height whether active or not: the list's follow motion
        // measures where a line rests, so a line must not resize under it.
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8 * fontScale),
          child: _selectionHighlight(child: styledChild),
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
    double inactiveNear, {
    String Function(String)? textTransform,
  }) {
    final String text = textTransform != null
        ? textTransform(line.text)
        : line.text;
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
                text,
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
                    ? Colors.white.withValues(alpha: inactiveNear)
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
              text,
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
              text,
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
    String displayText,
    bool isPast,
    TextStyle baseStyle,
    Color activeColor,
    bool isSearchMatch,
    TextAlign textAlign,
  ) {
    return _withBackgroundVocals(
      Text(
        displayText,
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

  static final RegExp _nonLatin = RegExp(
    r'[\u3040-\u30ff\u3400-\u9fff\uac00-\ud7af\u0400-\u04ff\u0600-\u06ff\u0900-\u097f]',
  );

  List<String> _visibleExtraLines({
    required bool showTranslation,
    required bool showRomanization,
  }) {
    if (line.extraLines.isEmpty || (!showTranslation && !showRomanization)) {
      return const [];
    }
    if (line.extraLines.length == 1) {
      final only = line.extraLines.first;
      final isRomaji =
          _nonLatin.hasMatch(line.text) && !_nonLatin.hasMatch(only);
      if (isRomaji) return showRomanization ? [only] : const [];
      return showTranslation ? [only] : const [];
    }
    return [
      if (showTranslation) line.extraLines[0],
      if (showRomanization) ...line.extraLines.skip(1),
    ];
  }

  /// The lines sharing this line's timestamp (translation, romanization)
  /// as smaller, dimmer lines under [main]. They wear the line's animated
  /// style, so the whole block eases in and out of being current together.
  Widget _withExtraLines(
    Widget main,
    TextAlign textAlign, {
    required bool showTranslation,
    required bool showRomanization,
    String? fontFamily,
    double? gap,
  }) {
    final visible = _visibleExtraLines(
      showTranslation: showTranslation,
      showRomanization: showRomanization,
    );
    if (visible.isEmpty) return main;
    return Column(
      crossAxisAlignment: switch (textAlign) {
        TextAlign.left => CrossAxisAlignment.start,
        TextAlign.right => CrossAxisAlignment.end,
        _ => CrossAxisAlignment.center,
      },
      mainAxisSize: MainAxisSize.min,
      children: [
        main,
        for (final extra in visible) ...[
          SizedBox(height: gap ?? (5 * fontScale)),
          Builder(
            builder: (context) {
              final style = DefaultTextStyle.of(context).style;
              return Text(
                extra,
                textAlign: textAlign,
                softWrap: true,
                style: style.copyWith(
                  fontFamily: fontFamily,
                  fontSize: 13 * fontScale,
                  fontWeight: FontWeight.w500,
                  fontStyle: FontStyle.normal,
                  height: 1.2,
                  color: Colors.white.withValues(alpha: 0.45),
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
