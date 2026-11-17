// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'media.dart';

bool _listEq<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// An ordered list of [Media] items loaded into the [Player].
///
/// Two playlists compare equal only when both [items] (deep equality)
/// and [index] match — useful when diffing playlists for re-render
/// decisions.
final class Playlist {
  /// The ordered list of tracks.
  final List<Media> items;

  /// The index of the currently active track. `0` for an empty playlist,
  /// `-1` when entries exist but none is active yet (the append build-up
  /// phase of [Player.openAll], before playback starts). Guard reads
  /// with `index >= 0` before using it to address [items].
  final int index;

  /// Creates a playlist from an ordered list of [items], with [index]
  /// marking the active track (defaults to the first).
  const Playlist(this.items, {this.index = 0});

  /// The empty playlist — no tracks, index 0. Const-evaluable so it can
  /// seed default fields without runtime allocation.
  static const Playlist empty = Playlist(<Media>[]);

  /// Returns a copy with the given fields replaced. Omitted fields keep
  /// their current value.
  Playlist copyWith({List<Media>? items, int? index}) => Playlist(
        items ?? this.items,
        index: index ?? this.index,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Playlist &&
          other.index == index &&
          _listEq(items, other.items));

  @override
  int get hashCode => Object.hash(Object.hashAll(items), index);

  @override
  String toString() => 'Playlist(items: $items, index: $index)';
}
