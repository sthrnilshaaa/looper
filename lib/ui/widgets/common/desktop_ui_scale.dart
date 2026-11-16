import 'package:flutter/material.dart';
import 'package:looper_player/core/utils/ui_scale_steps.dart';

/// Draws the whole app [scale] times larger. The app is laid
/// out in a box of the window size divided by [scale] and painted scaled up
/// to fill the window, and MediaQuery reports that smaller size, so
/// breakpoints react to the room the layout really has.
///
/// The widget tree has the same shape at every scale (including 100%), so
/// changing the scale never remounts the app below it. At 100% the
/// FittedBox transform is the identity, so it paints without a layer.
class DesktopUiScale extends StatelessWidget {
  final double scale;
  final Widget child;

  const DesktopUiScale({super.key, required this.scale, required this.child});

  @override
  Widget build(BuildContext context) {
    final s = UiScaleSteps.normalize(scale);
    final mq = MediaQuery.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final logical = constraints.biggest / s;
        return FittedBox(
          fit: BoxFit.fill,
          child: SizedBox(
            width: logical.width,
            height: logical.height,
            child: MediaQuery(
              data: mq.copyWith(
                size: logical,
                devicePixelRatio: mq.devicePixelRatio * s,
                padding: mq.padding / s,
                viewPadding: mq.viewPadding / s,
                viewInsets: mq.viewInsets / s,
              ),
              child: child,
            ),
          ),
        );
      },
    );
  }
}
