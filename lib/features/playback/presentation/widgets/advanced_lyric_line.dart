import 'dart:io';
import 'package:flutter/material.dart';
import 'package:looper_player/core/app_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:adaptive_palette/adaptive_palette.dart';
import '../playback_notifier.dart';
import '../lyrics_search_provider.dart';
import '../../domain/lyric_models.dart';
import '../lyrics_view.dart';
import '../../../settings/presentation/settings_notifier.dart';

final artworkColorProvider = FutureProvider<Color?>((ref) async {
  final currentSong = ref.watch(playbackProvider.select((s) => s.currentSong));
  final artPath = currentSong?.artPath;
  if (artPath == null) return null;

  final file = File(artPath);
  if (!await file.exists()) return null;

  try {
    final colors = await FluidPaletteExtractor.extractColors(
      FileImage(file),
      count: 1,
    );
    if (colors.isNotEmpty) {
      final extractedColor = colors.first;
      final HSLColor hsl = HSLColor.fromColor(extractedColor);
      double newLightness = hsl.lightness + 0.15;
      if (newLightness < 0.60) {
        newLightness = 0.60;
      }
      newLightness = newLightness.clamp(0.0, 0.95);
      return hsl.withLightness(newLightness).toColor();
    }
  } catch (e) {}
  return null;
});

class AdvancedLyricLine extends ConsumerWidget {
  final LyricLine line;
  final LyricsSyncMode mode;
  final bool isActive;
  final int relativeIndex;
  final VoidCallback onTap;
  final double fontScale;

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
    required this.relativeIndex,
    required this.onTap,
    required this.onLongPress,
    this.isSelected = false,
    this.selectionActive = false,
    this.fontScale = 1.0,
  });

  bool _isHindi(String text) {
    return RegExp(r'[\u0900-\u097F]').hasMatch(text);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Only watch position if this line is active and in word/char sync modes, avoiding rebuilds of all other lines
    final needsPosition =
        isActive &&
        (mode == LyricsSyncMode.word || mode == LyricsSyncMode.char);
    final currentPosition = needsPosition
        ? ref.watch(playbackProvider.select((s) => s.position))
        : Duration.zero;

    final progress = line.getProgress(currentPosition);
    final isPast = isActive
        ? false
        : (ref.read(playbackProvider).position > line.endTime);

    // Calculate absolute distance for opacity and duration
    final absIndex = relativeIndex.abs();

    // Calculate dynamic opacity based on distance from active line for a smoother transition
    double lineOpacity = 1.0;
    if (isSelected) {
      lineOpacity =
          1.0; // selected lines should read clearly regardless of playback position
    } else if (selectionActive) {
      lineOpacity =
          0.18; // dim everything else while the user is picking lines to share
    } else if (!isActive) {
      lineOpacity =
          0.35; // ponytail: make inactive lyrics lines all have uniform opacity
    }

    final settings = ref.watch(settingsProvider);
    final alignmentString = settings.lyricsAlignment;
    final useDynamicColor =
        (settings.dynamicColorActiveLyrics &&
            (settings.enableDynamicTheming || settings.dynamicLyrics)) ||
        settings.blurredArtworkForLyrics;

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

    final wrapAlignment = alignmentString == 'left'
        ? WrapAlignment.start
        : alignmentString == 'right'
        ? WrapAlignment.end
        : WrapAlignment.center;

    // Extract dynamic color from artwork or fallback to Theme primary / white
    final artworkColorAsync = ref.watch(artworkColorProvider);
    final artworkColor = artworkColorAsync.value;

    // useDynamicColor already covers every case where dynamicColorActiveLyrics
    // is meaningfully "on" (it requires enableDynamicTheming, dynamicLyrics, or
    // blurredArtworkForLyrics to actually have a dynamic source). So once we're
    // here, dynamicColorActiveLyrics being true with nothing dynamic active
    // (e.g. blurred artwork turned off) must still fall back to the accent
    // color, not white -- white is only correct while dynamicLyrics' own
    // visual mode is genuinely active and needs contrast against it.
    final activeColor = useDynamicColor
        ? (artworkColor ?? Theme.of(context).colorScheme.primary)
        : (settings.dynamicLyrics ? Colors.white : Color(settings.accentColor));

    // Language-aware font selection
    final bool isHindiText = _isHindi(line.text);
    final baseStyle = AppFonts.getLyricsStyle(
      useNewFontLyrics: settings.useNewFontLyrics,
      family: isHindiText ? 'Google Sans' : settings.customFontFamilyLyrics,
      weightDelta: settings.customFontWeightLyricsDelta,
      activeWeightDelta: settings.activeLyricsFontWeightDelta,
      isActive: isActive,
      fontSize: 30 * fontScale, //(isActive ? 30.5 : 30) * fontScale,
      height: 1.15,
      color: isActive
          ? activeColor
          : Colors.white.withValues(alpha: lineOpacity),
      shadows: isActive && useDynamicColor
          ? [
              Shadow(
                color: activeColor.withValues(alpha: 0.01),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ]
          : null,
    ).copyWith(letterSpacing: isHindiText ? 0.95 : 0);

    // Unified animation duration and easeInOutCubic curve for a buttery-smooth transition
    final animDuration = const Duration(milliseconds: 400);
    final curve = Curves.easeInOutCubic;

    // Watch the search query for highlighting
    final searchQuery = ref.watch(lyricsSearchQueryProvider).toLowerCase();

    final childWidget = _buildModeContent(
      context,
      progress,
      isPast,
      baseStyle,
      activeColor,
      searchQuery,
      textAlign,
      iconAlignment,
      wrapAlignment,
    );

    // Optimization: If the line is far from the active line (distance > 1),
    // skip expensive animation/mouse widgets and render a static layout.
    // This reduces widget tree depth by 75% and resolves slow frames.
    if (absIndex > 2) {
      return GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: EdgeInsets.only(top: 8 * fontScale, bottom: 8 * fontScale),
          child: _selectionHighlight(
            child: DefaultTextStyle(
              style: baseStyle,
              textAlign: textAlign,
              softWrap: true,
              child: childWidget,
            ),
          ),
        ),
      );
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: AnimatedPadding(
          duration: animDuration,
          curve: curve,
          padding: EdgeInsets.only(
            top: (isActive ? 12 : 8) * fontScale,
            bottom: (isActive ? 16 : 8) * fontScale,
          ),
          child: _selectionHighlight(
            child: AnimatedDefaultTextStyle(
              duration: animDuration,
              curve: curve,
              style: baseStyle,
              softWrap: true,
              textAlign: textAlign,
              child: childWidget,
            ),
          ),
        ),
      ),
    );
  }

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
    double progress,
    bool isPast,
    TextStyle baseStyle,
    Color activeColor,
    String searchQuery,
    TextAlign textAlign,
    Alignment iconAlignment,
    WrapAlignment wrapAlignment,
  ) {
    final String text = line.text;
    final bool isInstrumental =
        text.isEmpty ||
        text.toLowerCase().contains('instrumental') ||
        text.toLowerCase().contains('[music]') ||
        text.trim() == '♪';

    // If there is a search match, always highlight it
    final bool isSearchMatch =
        searchQuery.isNotEmpty && text.toLowerCase().contains(searchQuery);

    if (!isActive && !isPast) {
      return isInstrumental
          ? Align(
              alignment: iconAlignment,
              child: Text(
                '♫',
                style: baseStyle.copyWith(color: Colors.white24),
              ),
            )
          : Text(
              text,
              style: isSearchMatch
                  ? baseStyle.copyWith(
                      color: activeColor.withValues(alpha: 0.9),
                    )
                  : null,
              textAlign: textAlign,
              softWrap: true,
              overflow: TextOverflow.visible,
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
          : Text(
              text,
              textAlign: textAlign,
              softWrap: true,
              overflow: TextOverflow.visible,
            );
    }

    // For active line, add music symbols if it's instrumental
    final displayText = isInstrumental ? '♫' : text;

    switch (mode) {
      case LyricsSyncMode.line:
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
            : Text(
                displayText,
                textAlign: textAlign,
                softWrap: true,
                overflow: TextOverflow.visible,
                style: baseStyle,
              );

      case LyricsSyncMode.word:
        return _buildWordMode(
          displayText,
          progress,
          baseStyle,
          activeColor,
          wrapAlignment,
        );

      case LyricsSyncMode.char:
        return _buildCharMode(
          displayText,
          progress,
          baseStyle,
          activeColor,
          textAlign,
        );
    }
  }

  Widget _buildWordMode(
    String text,
    double progress,
    TextStyle baseStyle,
    Color activeColor,
    WrapAlignment wrapAlignment,
  ) {
    final words = text.split(' ');
    if (words.isEmpty) return const SizedBox.shrink();

    // Estimate progress per word
    final wordCount = words.length;
    final activeWordIndex = (progress * wordCount).floor();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Wrap(
            alignment: wrapAlignment,
            spacing: 12 * fontScale,
            children: List.generate(words.length, (index) {
              final isWordActive = index <= activeWordIndex;
              return AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                style: baseStyle.copyWith(
                  color: isWordActive
                      ? activeColor
                      : baseStyle.color?.withValues(alpha: 0.5),
                  shadows: isWordActive
                      ? [
                          Shadow(
                            color: activeColor.withValues(alpha: 0.3),
                            blurRadius: 16 * fontScale,
                          ),
                        ]
                      : null,
                ),
                child: Text(words[index]),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildCharMode(
    String text,
    double progress,
    TextStyle baseStyle,
    Color activeColor,
    TextAlign textAlign,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (bounds) {
              const gradientWidth = 0.01;
              final start = (progress - gradientWidth).clamp(0.0, 1.0);
              final end = (progress + gradientWidth).clamp(0.0, 1.0);

              return LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  activeColor,
                  activeColor.withValues(alpha: 0.8),
                  baseStyle.color ?? Colors.white24,
                ],
                stops: [start, progress, end],
              ).createShader(bounds);
            },
            child: Text(
              text,
              style: baseStyle.copyWith(color: Colors.white),
              textAlign: textAlign,
              softWrap: true,
              overflow: TextOverflow.visible,
            ),
          ),
        ),
      ],
    );
  }
}

/// The instrumental/music-gap symbol ("♫") for the currently active line -
/// same glyph the inactive and already-played instrumental symbols use, but
/// pulsing with a soft glow and a gentle bounce for as long as this line
/// stays active, so the animation itself (not a different symbol) is what
/// marks it as the current one.
class _PulsingInstrumentalIcon extends StatefulWidget {
  const _PulsingInstrumentalIcon({required this.color, required this.style});

  /// Color of the glow halo behind the symbol - the symbol's own color
  /// already comes from [style].
  final Color color;
  final TextStyle style;

  @override
  State<_PulsingInstrumentalIcon> createState() =>
      _PulsingInstrumentalIconState();
}

class _PulsingInstrumentalIconState extends State<_PulsingInstrumentalIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_controller.value);
        return Transform.translate(
          // Bounce: rises slightly on each beat, settles back down.
          offset: Offset(0, -4.0 * t),
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                // Glow: a soft halo behind the icon that swells and fades
                // with the same beat as the bounce.
                BoxShadow(
                  color: widget.color.withValues(alpha: 0.15 + 0.35 * t),
                  blurRadius: 10 + 14 * t,
                  spreadRadius: 1 + 3 * t,
                ),
              ],
            ),
            child: child,
          ),
        );
      },
      child: Text('♫', style: widget.style),
    );
  }
}
