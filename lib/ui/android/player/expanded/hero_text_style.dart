part of 'android_expanded_player.dart';

TextStyle _getHeroStyle(Hero hero, TextStyle fallback) {
  final child = hero.child;
  if (child is ScrollingText) {
    return child.style ?? fallback;
  }
  if (child is Text) {
    return child.style ?? fallback;
  }
  return fallback;
}
