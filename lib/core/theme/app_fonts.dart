import 'package:flutter/material.dart';

class AppFonts {
  static String activeFontFamily = dmSans;
  static const String stackSansText = 'Stack Sans Text';

  static const String jost = 'Jost';

  // Lyrics fonts (excluded from main font change)
  static const String spaceGrotesk = 'Space Grotesk';
  static const String sora = 'Sora';
  static const String googleSans = 'Google Sans';
  static const String plusJakartaSans = 'Plus Jakarta Sans';

  static const String poppins = 'Poppins';
  static const String notoSansDevanagari = 'Noto Sans Devanagari';

  /// Fonts used per glyph when [family] lacks one, so mixed Hindi/English
  /// text keeps [family] for Latin. Stack Sans and most pickable families
  /// are Latin-only, so Hindi goes to a bundled Devanagari font closest in
  /// shape: Noto Sans Devanagari for Stack Sans (the user's chosen Hindi
  /// lyrics look), Poppins for the round geometric families, Google Sans
  /// for the grotesques. Google Sans always comes last because it also
  /// covers Bengali, Gurmukhi, Tamil and other Indic scripts.
  static List<String> scriptFallbackFor(String? family) => switch (family) {
    googleSans => const [],
    poppins => const [googleSans],
    stackSansText => const [notoSansDevanagari, googleSans],
    jost || 'DM Sans' || sora || plusJakartaSans => const [poppins, googleSans],
    _ => const [googleSans],
  };

  /// Families offered by both the app and lyrics font pickers. Each must
  /// be declared under `fonts:` in pubspec.yaml.
  static const List<String> selectableFamilies = [
    'Jost',
    'Stack Sans Text',
    'DM Sans',
    'Poppins',
    'Space Grotesk',
    'Plus Jakarta Sans',
    'Sora',
    'Google Sans',
  ];

  // Centrally managed Font Weights (updated dynamically based on delta)
  static int appFontWeightDelta = 0;

  /// App-wide letter spacing in percent of the font size (the Font settings
  /// slider). Applied by [jostStyle] and [adjustTextTheme].
  static double appLetterSpacingPercent = -2.0;

  /// [base] plus the app-wide spacing for text of [fontSize].
  static double spacingFor(double? fontSize, [double? base]) =>
      (base ?? 0) + appLetterSpacingPercent / 100 * (fontSize ?? 14);
  static int lyricsFontWeightDelta = 0;

  static FontWeight getAdjustedWeight(FontWeight baseWeight, int delta) {
    if (delta == 0) return baseWeight;
    final baseIndex = (baseWeight.value ~/ 100) - 1;
    final targetIndex = (baseIndex + delta).clamp(0, 8);
    return FontWeight.values[targetIndex];
  }

  static TextTheme adjustTextTheme(
    TextTheme baseTheme,
    int delta, {
    double letterSpacingPercent = 0,
  }) {
    if (delta == 0 && letterSpacingPercent == 0) return baseTheme;

    TextStyle? adjust(TextStyle? style) => style?.copyWith(
      fontWeight: getAdjustedWeight(
        style.fontWeight ?? FontWeight.normal,
        delta,
      ),
      letterSpacing:
          (style.letterSpacing ?? 0) +
          letterSpacingPercent / 100 * (style.fontSize ?? 14),
    );

    return baseTheme.copyWith(
      displayLarge: adjust(baseTheme.displayLarge),
      displayMedium: adjust(baseTheme.displayMedium),
      displaySmall: adjust(baseTheme.displaySmall),
      headlineLarge: adjust(baseTheme.headlineLarge),
      headlineMedium: adjust(baseTheme.headlineMedium),
      headlineSmall: adjust(baseTheme.headlineSmall),
      titleLarge: adjust(baseTheme.titleLarge),
      titleMedium: adjust(baseTheme.titleMedium),
      titleSmall: adjust(baseTheme.titleSmall),
      bodyLarge: adjust(baseTheme.bodyLarge),
      bodyMedium: adjust(baseTheme.bodyMedium),
      bodySmall: adjust(baseTheme.bodySmall),
      labelLarge: adjust(baseTheme.labelLarge),
      labelMedium: adjust(baseTheme.labelMedium),
      labelSmall: adjust(baseTheme.labelSmall),
    );
  }

  static const String dmSans = 'DM Sans';

  /// Settings screens' text: always DM Sans at its default weight and
  /// zero letter spacing, whatever app font the user picked.
  static TextStyle settingsStyle({
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    double? height,
    List<FontFeature>? fontFeatures,
  }) => familyStyle(
    dmSans,
    weightDelta: 0,
    color: color,
    fontSize: fontSize,
    fontWeight: fontWeight,
    fontStyle: fontStyle,
    height: height,
    fontFeatures: fontFeatures,
    letterSpacing: 0,
  );

  /// The app's text style: the active app font, with the app weight delta
  /// applied. (Named for the font it started out as.)
  static TextStyle jostStyle({
    TextStyle? textStyle,
    Color? color,
    Color? backgroundColor,
    double? fontSize,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    double? letterSpacing,
    double? wordSpacing,
    TextBaseline? textBaseline,
    double? height,
    Locale? locale,
    Paint? foreground,
    Paint? background,
    List<Shadow>? shadows,
    List<FontFeature>? fontFeatures,
    TextDecoration? decoration,
    Color? decorationColor,
    TextDecorationStyle? decorationStyle,
    double? decorationThickness,
  }) {
    return familyStyle(
      activeFontFamily,
      weightDelta: appFontWeightDelta,
      textStyle: textStyle,
      color: color,
      backgroundColor: backgroundColor,
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      letterSpacing: spacingFor(fontSize ?? textStyle?.fontSize, letterSpacing),
      wordSpacing: wordSpacing,
      textBaseline: textBaseline,
      height: height,
      locale: locale,
      foreground: foreground,
      background: background,
      shadows: shadows,
      fontFeatures: fontFeatures,
      decoration: decoration,
      decorationColor: decorationColor,
      decorationStyle: decorationStyle,
      decorationThickness: decorationThickness,
    );
  }

  /// A text style in a specific [fontFamily]. The weight is shifted by
  /// [weightDelta]; left null, that is the lyrics delta for the lyrics-only
  /// families and the app delta for the rest.
  static TextStyle familyStyle(
    String fontFamily, {
    int? weightDelta,
    TextStyle? textStyle,
    Color? color,
    Color? backgroundColor,
    double? fontSize,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    double? letterSpacing,
    double? wordSpacing,
    TextBaseline? textBaseline,
    double? height,
    Locale? locale,
    Paint? foreground,
    Paint? background,
    List<Shadow>? shadows,
    List<FontFeature>? fontFeatures,
    TextDecoration? decoration,
    Color? decorationColor,
    TextDecorationStyle? decorationStyle,
    double? decorationThickness,
  }) {
    final isLyricsFont =
        fontFamily == spaceGrotesk ||
        fontFamily == sora ||
        fontFamily == googleSans ||
        fontFamily == plusJakartaSans;
    final delta =
        weightDelta ??
        (isLyricsFont ? lyricsFontWeightDelta : appFontWeightDelta);
    final resolvedWeight = getAdjustedWeight(
      fontWeight ?? textStyle?.fontWeight ?? FontWeight.normal,
      delta,
    );

    TextStyle style = TextStyle(
      fontFamily: fontFamily,
      fontFamilyFallback: scriptFallbackFor(fontFamily),
      color: color,
      backgroundColor: backgroundColor,
      fontSize: fontSize,
      fontWeight: resolvedWeight,
      fontStyle: fontStyle,
      letterSpacing: letterSpacing,
      wordSpacing: wordSpacing,
      textBaseline: textBaseline,
      height: height,
      locale: locale,
      foreground: foreground,
      background: background,
      shadows: shadows,
      fontFeatures: fontFeatures,
      decoration: decoration,
      decorationColor: decorationColor,
      decorationStyle: decorationStyle,
      decorationThickness: decorationThickness,
    );
    if (textStyle != null) {
      style = textStyle.merge(style).copyWith(fontWeight: resolvedWeight);
    }
    return style;
  }

  static TextStyle getLyricsStyle({
    required bool useNewFontLyrics,
    required String family,
    required int weightDelta,
    required int activeWeightDelta,
    required bool isActive,
    Color? color,
    double? fontSize,
    double? height,
    List<Shadow>? shadows,
  }) {
    final activeFamily = useNewFontLyrics ? family : stackSansText;
    final style = familyStyle(activeFamily);

    FontWeight weight;
    // Use a uniform weight (w600/SemiBold) to completely eliminate text wrapping jumps and layout transition glitches
    final delta = useNewFontLyrics ? activeWeightDelta : 0;
    weight = getAdjustedWeight(FontWeight.w600, delta);

    return style.copyWith(
      fontSize: fontSize,
      fontWeight: weight,
      color: color,
      height: height,
      shadows: shadows,
    );
  }
}
