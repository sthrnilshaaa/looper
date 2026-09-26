import 'package:flutter/material.dart';
import '../utils/ui_utils.dart';

class AppFonts {
  static String activeFontFamily = 'DM Sans';

  static const String jost = 'Jost';
  static const String dmSans = 'DMSans';

  // Lyrics fonts (excluded from main font change)
  static const String spaceGrotesk = 'Space Grotesk';
  static const String sora = 'Sora';
  static const String googleSans = 'Google Sans';
  static const String plusJakartaSans = 'Plus Jakarta Sans';

  // Centrally managed Font Weights (updated dynamically based on delta)
  static int appFontWeightDelta = 0;
  static int lyricsFontWeightDelta = 0;

  static FontWeight getAdjustedWeight(FontWeight baseWeight, int delta) {
    if (delta == 0) return baseWeight;
    final baseIndex = (baseWeight.value ~/ 100) - 1;
    final targetIndex = (baseIndex + delta).clamp(0, 8);
    return FontWeight.values[targetIndex];
  }

  static TextTheme adjustTextTheme(TextTheme baseTheme, int delta) {
    if (delta == 0) return baseTheme;

    FontWeight adjust(FontWeight? w) {
      final baseWeight = w ?? FontWeight.normal;
      final baseIndex = (baseWeight.value ~/ 100) - 1;
      final targetIndex = (baseIndex + delta).clamp(0, 8);
      return FontWeight.values[targetIndex];
    }

    return baseTheme.copyWith(
      displayLarge: baseTheme.displayLarge?.copyWith(
        fontWeight: adjust(baseTheme.displayLarge?.fontWeight),
      ),
      displayMedium: baseTheme.displayMedium?.copyWith(
        fontWeight: adjust(baseTheme.displayMedium?.fontWeight),
      ),
      displaySmall: baseTheme.displaySmall?.copyWith(
        fontWeight: adjust(baseTheme.displaySmall?.fontWeight),
      ),
      headlineLarge: baseTheme.headlineLarge?.copyWith(
        fontWeight: adjust(baseTheme.headlineLarge?.fontWeight),
      ),
      headlineMedium: baseTheme.headlineMedium?.copyWith(
        fontWeight: adjust(baseTheme.headlineMedium?.fontWeight),
      ),
      headlineSmall: baseTheme.headlineSmall?.copyWith(
        fontWeight: adjust(baseTheme.headlineSmall?.fontWeight),
      ),
      titleLarge: baseTheme.titleLarge?.copyWith(
        fontWeight: adjust(baseTheme.titleLarge?.fontWeight),
      ),
      titleMedium: baseTheme.titleMedium?.copyWith(
        fontWeight: adjust(baseTheme.titleMedium?.fontWeight),
      ),
      titleSmall: baseTheme.titleSmall?.copyWith(
        fontWeight: adjust(baseTheme.titleSmall?.fontWeight),
      ),
      bodyLarge: baseTheme.bodyLarge?.copyWith(
        fontWeight: adjust(baseTheme.bodyLarge?.fontWeight),
      ),
      bodyMedium: baseTheme.bodyMedium?.copyWith(
        fontWeight: adjust(baseTheme.bodyMedium?.fontWeight),
      ),
      bodySmall: baseTheme.bodySmall?.copyWith(
        fontWeight: adjust(baseTheme.bodySmall?.fontWeight),
      ),
      labelLarge: baseTheme.labelLarge?.copyWith(
        fontWeight: adjust(baseTheme.labelLarge?.fontWeight),
      ),
      labelMedium: baseTheme.labelMedium?.copyWith(
        fontWeight: adjust(baseTheme.labelMedium?.fontWeight),
      ),
      labelSmall: baseTheme.labelSmall?.copyWith(
        fontWeight: adjust(baseTheme.labelSmall?.fontWeight),
      ),
    );
  }

  static FontWeight get weightLight =>
      getAdjustedWeight(FontWeight.w200, appFontWeightDelta);
  static FontWeight get weightNormal =>
      getAdjustedWeight(FontWeight.w300, appFontWeightDelta);
  static FontWeight get weightMedium =>
      getAdjustedWeight(FontWeight.w400, appFontWeightDelta);
  static FontWeight get weightSemiBold =>
      getAdjustedWeight(FontWeight.w500, appFontWeightDelta);
  static FontWeight get weightBold =>
      getAdjustedWeight(FontWeight.w700, appFontWeightDelta);

  // Centrally managed Font Sizes
  static double get sizeTitleLarge => 24.ts;
  static double get sizeTitleMedium => 18.ts;
  static double get sizeTitleSmall => 16.ts;
  static double get sizeBodyLarge => 16.ts;
  static double get sizeBodyMedium => 14.ts;
  static double get sizeBodySmall => 12.ts;
  static double get sizeCaption => 10.ts;

  // Centrally managed TextStyle Templates
  static TextStyle get titleLargeStyle =>
      jostStyle(fontSize: sizeTitleLarge, fontWeight: FontWeight.bold);

  static TextStyle get titleMediumStyle =>
      jostStyle(fontSize: sizeTitleMedium, fontWeight: FontWeight.bold);

  static TextStyle get titleSmallStyle =>
      jostStyle(fontSize: sizeTitleSmall, fontWeight: FontWeight.w500);

  static TextStyle get bodyLargeStyle =>
      jostStyle(fontSize: sizeBodyLarge, fontWeight: FontWeight.normal);

  static TextStyle get bodyMediumStyle =>
      jostStyle(fontSize: sizeBodyMedium, fontWeight: FontWeight.normal);

  static TextStyle get bodySmallStyle =>
      jostStyle(fontSize: sizeBodySmall, fontWeight: FontWeight.normal);

  static TextStyle get captionStyle =>
      jostStyle(fontSize: sizeCaption, fontWeight: FontWeight.normal);

  /// Wrapper for Jost font
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
    FontWeight? resolvedWeight = fontWeight;
    if (resolvedWeight != null) {
      resolvedWeight = getAdjustedWeight(resolvedWeight, appFontWeightDelta);
    } else if (textStyle?.fontWeight != null) {
      resolvedWeight = getAdjustedWeight(
        textStyle!.fontWeight!,
        appFontWeightDelta,
      );
    } else {
      resolvedWeight = getAdjustedWeight(FontWeight.normal, appFontWeightDelta);
    }

    TextStyle baseStyle = TextStyle(
      fontFamily: activeFontFamily,
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
      baseStyle = textStyle
          .merge(baseStyle)
          .copyWith(fontWeight: resolvedWeight);
    }
    return baseStyle;
  }

  static TextStyle _customTextStyle({
    required String fontFamily,
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
    final delta = isLyricsFont ? lyricsFontWeightDelta : appFontWeightDelta;

    FontWeight? resolvedWeight = fontWeight;
    if (resolvedWeight != null) {
      resolvedWeight = getAdjustedWeight(resolvedWeight, delta);
    } else if (textStyle?.fontWeight != null) {
      resolvedWeight = getAdjustedWeight(textStyle!.fontWeight!, delta);
    } else {
      resolvedWeight = getAdjustedWeight(FontWeight.normal, delta);
    }

    TextStyle style = TextStyle(
      fontFamily: fontFamily,
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

  /// Wrapper for Space Grotesk font (lyrics)
  static TextStyle spaceGroteskStyle({
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
    return _customTextStyle(
      fontFamily: 'Space Grotesk',
      textStyle: textStyle,
      color: color,
      backgroundColor: backgroundColor,
      fontSize: fontSize,
      fontWeight: fontWeight,
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
  }

  /// Wrapper for Sora font (lyrics)
  static TextStyle soraStyle({
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
    return _customTextStyle(
      fontFamily: 'Sora',
      textStyle: textStyle,
      color: color,
      backgroundColor: backgroundColor,
      fontSize: fontSize,
      fontWeight: fontWeight,
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
  }

  /// Wrapper for Google Sans font (lyrics)
  static TextStyle googleSansStyle({
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
    return _customTextStyle(
      fontFamily: 'Google Sans',
      textStyle: textStyle,
      color: color,
      backgroundColor: backgroundColor,
      fontSize: fontSize,
      fontWeight: fontWeight,
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
  }

  /// Wrapper for Plus Jakarta Sans font (lyrics)
  static TextStyle plusJakartaSansStyle({
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
    return _customTextStyle(
      fontFamily: 'Plus Jakarta Sans',
      textStyle: textStyle,
      color: color,
      backgroundColor: backgroundColor,
      fontSize: fontSize,
      fontWeight: fontWeight,
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
    TextStyle style;
    final activeFamily = useNewFontLyrics ? family : 'Sora';
    switch (activeFamily) {
      case 'Space Grotesk':
        style = spaceGroteskStyle();
        break;
      case 'Google Sans':
        style = googleSansStyle();
        break;
      case 'Plus Jakarta Sans':
        style = plusJakartaSansStyle();
        break;
      case 'Jost':
        style = jostStyle();
        break;
      case 'Sora':
      default:
        style = soraStyle();
        break;
    }

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
