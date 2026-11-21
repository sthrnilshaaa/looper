part of 'android_main_screen.dart';

class _NavDepthObserver extends NavigatorObserver {
  _NavDepthObserver({required this.onAtRootChanged});

  final ValueChanged<bool> onAtRootChanged;
  int _depth = 0;
  NavigatorState? _navigator;

  void _report() => onAtRootChanged(_depth <= 1);

  // A disposed Navigator never reports its routes as removed, so when the
  // shell remounts (e.g. right after first-run setup) the old count would
  // linger and hide the navbar. Start over for each new Navigator.
  void _track(Route route) {
    if (route.navigator == _navigator) return;
    _navigator = route.navigator;
    _depth = 0;
  }

  @override
  void didPush(Route route, Route? previousRoute) {
    _track(route);
    _depth++;
    _report();
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    _depth = _depth > 0 ? _depth - 1 : 0;
    _report();
  }

  @override
  void didRemove(Route route, Route? previousRoute) {
    _depth = _depth > 0 ? _depth - 1 : 0;
    _report();
  }
}
