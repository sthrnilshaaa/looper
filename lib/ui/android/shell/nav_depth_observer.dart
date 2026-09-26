part of 'android_main_screen.dart';

class _NavDepthObserver extends NavigatorObserver {
  _NavDepthObserver({required this.onAtRootChanged});

  final ValueChanged<bool> onAtRootChanged;
  int _depth = 0;

  void _report() => onAtRootChanged(_depth <= 1);

  @override
  void didPush(Route route, Route? previousRoute) {
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
