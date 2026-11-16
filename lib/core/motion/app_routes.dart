import 'package:flutter/material.dart';

import 'package:looper_player/core/utils/motion.dart';

/// Motion vocabulary for routes: pages you drill into slide in from the side
/// (the shell's _createPremiumRoute); tasks - editors, tools, dialogs - rise
/// from below. Each is one movement, and both reverse along the same path
/// when popped or interrupted mid-way.

/// A full-screen task (equalizer, tag editor): rises a short way from below
/// while fading in.
Route<T> riseRoute<T>(Widget page, {RouteSettings? settings}) {
  final bool reduced = Motion.reduced;
  return PageRouteBuilder<T>(
    settings: settings,
    transitionDuration: Duration(milliseconds: reduced ? 120 : 340),
    reverseTransitionDuration: Duration(milliseconds: reduced ? 120 : 300),
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) =>
        _rise(animation, child, reduced: reduced, distance: 0.08),
  );
}

/// [showDialog] with the task motion: the dialog rises a little as it fades
/// in, instead of Material's scale. Same theming as [showDialog].
Future<T?> showTaskDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  bool useRootNavigator = true,
}) {
  final NavigatorState navigator = Navigator.of(
    context,
    rootNavigator: useRootNavigator,
  );
  final CapturedThemes themes = InheritedTheme.capture(
    from: context,
    to: navigator.context,
  );
  return navigator.push<T>(
    _RiseDialogRoute<T>(
      context: context,
      builder: builder,
      barrierDismissible: barrierDismissible,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      themes: themes,
    ),
  );
}

class _RiseDialogRoute<T> extends DialogRoute<T> {
  _RiseDialogRoute({
    required super.context,
    required super.builder,
    super.barrierDismissible,
    super.barrierLabel,
    super.themes,
  });

  @override
  Duration get transitionDuration =>
      Duration(milliseconds: Motion.reduced ? 100 : 260);

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => _rise(animation, child, reduced: Motion.reduced, distance: 0.04);
}

Widget _rise(
  Animation<double> animation,
  Widget child, {
  required bool reduced,
  required double distance,
}) {
  final CurvedAnimation curved = CurvedAnimation(
    parent: animation,
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeInCubic,
  );
  if (reduced) return FadeTransition(opacity: curved, child: child);
  return FadeTransition(
    opacity: curved,
    child: SlideTransition(
      position: Tween<Offset>(
        begin: Offset(0, distance),
        end: Offset.zero,
      ).animate(curved),
      child: child,
    ),
  );
}
