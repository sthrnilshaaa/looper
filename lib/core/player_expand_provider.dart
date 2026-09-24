import 'package:flutter/rendering.dart' show Rect;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'player_expand_provider.g.dart';

@Riverpod(keepAlive: true)
class PlayerExpandProgress extends _$PlayerExpandProgress {
  @override
  double build() => 0.0;

  void set(double value) => state = value;
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
