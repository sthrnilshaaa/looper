import 'package:flutter/widgets.dart';

/// Drops keyboard focus the moment the slide-gesture player starts expanding.
///
/// In that mode the player is an overlay inside the same route as the screen
/// behind it, not a route of its own, so opening it never moves focus. A text
/// field left focused underneath (the search box) then gets focus - and the
/// keyboard - handed back when a route pushed from the player, such as the
/// lyrics screen, pops: Flutter restores the previous route scope's
/// last-focused node. Unfocusing here (with the default `scope` disposition)
/// also clears that scope's focus history, so there is nothing to restore.
///
/// Call with each `playerExpandProgressProvider` change; it only acts on the
/// change that leaves the fully collapsed state, so it never fights a user who
/// taps into a field while the player is mid-animation or already open.
void dismissFocusWhenPlayerExpands(double? previous, double next) {
  final bool startedExpanding = (previous ?? 0.0) <= 0.0 && next > 0.0;
  if (startedExpanding) {
    FocusManager.instance.primaryFocus?.unfocus();
  }
}
