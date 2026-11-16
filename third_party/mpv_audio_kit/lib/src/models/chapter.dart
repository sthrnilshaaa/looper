// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import '../internals/unset_sentinel.dart';

/// A chapter entry in the current track's `chapter-list`.
///
/// Audiobook / podcast files often carry chapter markers that mpv
/// surfaces via the `chapter-list` property. Subscribe via
/// [PlayerStream.chapters] for the live list; observe
/// [PlayerStream.currentChapter] for the active index, or jump with
/// [Player.setChapter].
final class Chapter {
  /// Start time of the chapter from the file origin.
  final Duration time;

  /// Optional human-readable title. mpv leaves this null when the
  /// container provides no chapter name.
  final String? title;

  /// Creates a chapter marker at [time] with an optional [title].
  const Chapter({required this.time, this.title});

  /// Returns a copy with the given fields replaced. Pass `null` for [title]
  /// to clear it; omitted fields keep their current value.
  Chapter copyWith({Duration? time, Object? title = unset}) => Chapter(
        time: time ?? this.time,
        title: identical(title, unset) ? this.title : title as String?,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Chapter && other.time == time && other.title == title);

  @override
  int get hashCode => Object.hash(time, title);

  @override
  String toString() => 'Chapter(time: $time, title: $title)';
}
