part of 'android_expanded_player.dart';

/// [style] as drawn inside [heroContext]'s PlayerScaled subtree, so a text
/// shuttle lands at the size the scaled player really shows.
TextStyle _scaledHeroStyle(TextStyle style, BuildContext heroContext) {
  final double k = PlayerScale.of(heroContext);
  if (k == 1.0) return style;
  return style.copyWith(
    fontSize: (style.fontSize ?? 14) * k,
    letterSpacing: style.letterSpacing == null
        ? null
        : style.letterSpacing! * k,
  );
}
