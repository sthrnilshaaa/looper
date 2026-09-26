import 'dart:io';

class UiUtils {
  static bool get isAndroid => Platform.isAndroid;
  static bool get isLinux => Platform.isLinux;

  /// Returns a scaling factor for UI components.
  /// Android gets a smaller scale (0.85) to fit more content.
  static double get scale => isAndroid ? 0.85 : 1.0;

  /// Scales a value based on the platform.
  static double s(double value) => value * scale;

  /// Scales text size.
  static double ts(double value) => value * scale;

  /// Returns a smaller spacing for Android.
  static double spacing(double value) => isAndroid ? value * 0.7 : value;

  static String formatPlaybackDuration(
    Duration duration, {
    bool showHours = false,
  }) {
    final safeDuration = duration.isNegative ? Duration.zero : duration;
    final seconds = (safeDuration.inSeconds % 60).toString().padLeft(2, '0');
    final minutes = (safeDuration.inMinutes % 60).toString().padLeft(2, '0');
    if (showHours || safeDuration.inHours > 0) {
      return '${safeDuration.inHours}:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }
}

extension UiScalingExtension on num {
  double get s => UiUtils.s(toDouble());
  double get ts => UiUtils.ts(toDouble());
  double get sp => UiUtils.spacing(toDouble());
}
