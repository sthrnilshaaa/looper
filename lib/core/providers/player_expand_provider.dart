import 'package:flutter/foundation.dart' show ValueNotifier;
import 'package:flutter/rendering.dart' show Rect;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'player_expand_provider.g.dart';

// The Fluid Player's expand progress (0 = mini bar, 1 = full player).
//
// A ValueNotifier rather than provider state on purpose: it changes on every
// animation frame and drag event, and routing that through Riverpod rebuilt
// every widget that watched it (the whole mini bar, the navbar stack, the
// artwork) once per frame. Listen to it with ValueListenableBuilder around a
// prebuilt child so only the thin wrapper that actually moves reruns, and
// read `.value` for one-off checks (back button, position reporting).
@Riverpod(keepAlive: true)
ValueNotifier<double> playerExpandProgress(Ref ref) {
  final notifier = ValueNotifier<double>(0.0);
  ref.onDispose(notifier.dispose);
  return notifier;
}

// The expanded artwork's real, measured rect (relative to the player's root),
// reported by PositionReporter once AndroidExpandedPlayer has fully expanded
// at least once. Consumed by the slide-gesture morph animation in
// PremiumMusicBar so the handoff between the animated placeholder and the
// real artwork widget lands exactly where the real one renders, instead of
// guessing at the real layout's dimensions with hardcoded constants.
@Riverpod(keepAlive: true)
class PlayerArtworkRect extends _$PlayerArtworkRect {
  @override
  Rect? build() => null;

  void set(Rect? value) => state = value;
}

@Riverpod(keepAlive: true)
class PlayerCollapseTrigger extends _$PlayerCollapseTrigger {
  @override
  int build() => 0;

  void bump() => state++;
}
