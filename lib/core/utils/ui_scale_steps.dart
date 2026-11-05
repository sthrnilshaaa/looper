import 'package:looper_player/core/utils/ui_utils.dart';

/// The whole-UI scale a user can pick. Phones get a narrower range: past
/// 120% a 360dp phone has under 300dp of layout room.
class UiScaleSteps {
  static const List<double> desktopSteps = [0.8, 0.9, 1.0, 1.1, 1.25, 1.5];
  static const List<double> mobileSteps = [0.8, 0.9, 1.0, 1.1, 1.2];

  static List<double> get steps =>
      UiUtils.isDesktop ? desktopSteps : mobileSteps;

  /// The nearest step. Rows saved before the setting existed read back as
  /// NaN - those, and anything else unusable, mean 100%.
  static double normalize(double value) {
    if (!value.isFinite || value <= 0) return 1.0;
    return steps.reduce(
      (a, b) => (value - a).abs() <= (value - b).abs() ? a : b,
    );
  }

  static double next(double value) {
    final i = steps.indexOf(normalize(value));
    return steps[(i + 1).clamp(0, steps.length - 1)];
  }

  static double previous(double value) {
    final i = steps.indexOf(normalize(value));
    return steps[(i - 1).clamp(0, steps.length - 1)];
  }
}
