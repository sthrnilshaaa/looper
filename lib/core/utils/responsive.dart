import 'package:flutter/widgets.dart';

/// Window-shape checks shared by the orientation-aware layouts.
///
/// These key off the window size rather than `Orientation` or the platform: a
/// landscape phone is wide but *short*, and it's the height that breaks
/// layouts designed portrait-first.
class Responsive {
  /// Below this window height the landscape layouts switch to compact metrics.
  /// Phones in landscape (roughly 320-430dp tall) fall under it; tablets don't.
  static const double shortHeight = 480;

  static bool isLandscape(Size size) => size.width > size.height;

  static bool isShort(Size size) => size.height < shortHeight;
}
