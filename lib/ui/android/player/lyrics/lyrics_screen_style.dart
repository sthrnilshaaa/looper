import 'package:flutter/material.dart';
import 'package:looper_player/features/library/domain/models/models.dart';

/// Layout and visual styles for [AndroidLyricsScreen].
///
/// The first two (`classic`, `arc`) are the existing production styles; the
/// remaining ten each provide a distinct, minimalistic header, lyric stage,
/// and bottom control layout.
enum LyricsScreenStyle {
  classic,
  arc,
  spatial,
  vinyl,
  editorial,
  karaoke,
  poster,
  oled,
  m3,
  timeline,
  zen,
  bigtype;

  /// True for styles that use the 290dp left-column side layout in landscape.
  bool get isSideLandscape => switch (this) {
    classic ||
    arc ||
    spatial ||
    vinyl ||
    karaoke ||
    poster ||
    m3 ||
    bigtype => true,
    editorial || oled || timeline || zen => false,
  };

  static LyricsScreenStyle fromSetting(String value) => switch (value) {
    'arc' => arc,
    'spatial' => spatial,
    'vinyl' => vinyl,
    'editorial' => editorial,
    'karaoke' => karaoke,
    'poster' => poster,
    'oled' => oled,
    'm3' => m3,
    'timeline' => timeline,
    'zen' => zen,
    'bigtype' || 'carddeck' => bigtype,
    _ => classic,
  };
}

/// Per-style typography defaults (used whenever a setting is on Auto).
class LyricsTextSpec {
  final String family;
  final FontWeight weight;
  final double activeSize;
  final double height;
  final TextAlign align;
  final Color? activeColorOverride;
  final double? letterSpacingEm;

  const LyricsTextSpec({
    this.family = 'Space Grotesk',
    this.weight = FontWeight.w700,
    this.activeSize = 25,
    this.height = 1.22,
    this.align = TextAlign.left,
    this.activeColorOverride,
    this.letterSpacingEm,
  });

  static const LyricsTextSpec classic = LyricsTextSpec(activeSize: 25);
  static const LyricsTextSpec arc = LyricsTextSpec(activeSize: 24);
  static const LyricsTextSpec spatial = LyricsTextSpec(activeSize: 28);
  static const LyricsTextSpec vinyl = LyricsTextSpec(
    family: 'Playfair Display',
    weight: FontWeight.w500,
    activeSize: 23,
    height: 1.24,
    activeColorOverride: Color(0xFFF1D9AE),
  );
  static const LyricsTextSpec editorial = LyricsTextSpec(
    family: 'Playfair Display',
    weight: FontWeight.w500,
    activeSize: 23,
    height: 1.24,
  );
  static const LyricsTextSpec karaoke = LyricsTextSpec(
    activeSize: 28,
    align: TextAlign.center,
  );
  static const LyricsTextSpec poster = LyricsTextSpec(activeSize: 22);
  static const LyricsTextSpec oled = LyricsTextSpec(
    weight: FontWeight.w500,
    activeSize: 23,
    height: 1.24,
    activeColorOverride: Colors.white,
  );
  static const LyricsTextSpec m3 = LyricsTextSpec(activeSize: 24);
  static const LyricsTextSpec timeline = LyricsTextSpec(
    weight: FontWeight.w500,
    activeSize: 20,
    height: 1.24,
  );
  static const LyricsTextSpec zen = LyricsTextSpec(
    activeSize: 30,
    height: 1.20,
    align: TextAlign.center,
  );
  static const LyricsTextSpec bigtype = LyricsTextSpec(
    weight: FontWeight.w800,
    activeSize: 42,
    height: 1.02,
    letterSpacingEm: -0.04,
  );

  static LyricsTextSpec of(LyricsScreenStyle style) => switch (style) {
    LyricsScreenStyle.classic => classic,
    LyricsScreenStyle.arc => arc,
    LyricsScreenStyle.spatial => spatial,
    LyricsScreenStyle.vinyl => vinyl,
    LyricsScreenStyle.editorial => editorial,
    LyricsScreenStyle.karaoke => karaoke,
    LyricsScreenStyle.poster => poster,
    LyricsScreenStyle.oled => oled,
    LyricsScreenStyle.m3 => m3,
    LyricsScreenStyle.timeline => timeline,
    LyricsScreenStyle.zen => zen,
    LyricsScreenStyle.bigtype => bigtype,
  };
}

/// Resolved lyric typography combining [LyricsTextSpec] with user overrides
/// from [AppSettings].
class ResolvedLyricsTextConfig {
  final String family;
  final FontWeight weight;
  final FontStyle fontStyle;
  final double activeSize;
  final double height;
  final TextAlign align;
  final bool explicitAlign;
  final String textCase;
  final Color? activeColorOverride;
  final double? letterSpacingEm;

  const ResolvedLyricsTextConfig({
    required this.family,
    required this.weight,
    required this.fontStyle,
    required this.activeSize,
    required this.height,
    required this.align,
    required this.explicitAlign,
    required this.textCase,
    required this.activeColorOverride,
    required this.letterSpacingEm,
  });

  factory ResolvedLyricsTextConfig.resolve(
    LyricsScreenStyle style,
    AppSettings settings, {
    bool isLandscape = false,
  }) {
    final spec = LyricsTextSpec.of(style);
    final double baseActiveSize = switch ((style, isLandscape)) {
      (LyricsScreenStyle.bigtype, true) => 38,
      (LyricsScreenStyle.zen, true) => 26,
      _ => spec.activeSize,
    };
    final family = (settings.customFontFamilyLyrics?.isNotEmpty ?? false)
        ? settings.customFontFamilyLyrics!
        : spec.family;
    final weight = switch (settings.lyricsWeightOverride) {
      300 => FontWeight.w300,
      500 => FontWeight.w500,
      700 => FontWeight.w700,
      800 => FontWeight.w800,
      _ => spec.weight,
    };
    final fontStyle = settings.lyricsItalic
        ? FontStyle.italic
        : FontStyle.normal;
    final scale = settings.lyricsFontScale.isNaN
        ? 1.0
        : settings.lyricsFontScale.clamp(0.8, 1.3);
    final spacing = settings.lyricsLineSpacing.isNaN
        ? 1.0
        : settings.lyricsLineSpacing.clamp(0.9, 1.5);
    final explicitAlign =
        settings.lyricsAlignment == 'left' ||
        settings.lyricsAlignment == 'center' ||
        settings.lyricsAlignment == 'right';
    final align = switch (settings.lyricsAlignment) {
      'left' => TextAlign.left,
      'center' => TextAlign.center,
      'right' => TextAlign.right,
      _ => spec.align,
    };
    return ResolvedLyricsTextConfig(
      family: family,
      weight: weight,
      fontStyle: fontStyle,
      activeSize: baseActiveSize * scale,
      height: spec.height * spacing,
      align: align,
      explicitAlign: explicitAlign,
      textCase: settings.lyricsTextCase,
      activeColorOverride: spec.activeColorOverride,
      letterSpacingEm: spec.letterSpacingEm,
    );
  }

  String applyCase(String input) => switch (textCase) {
    'upper' => input.toUpperCase(),
    'lower' => input.toLowerCase(),
    _ => input,
  };
}
