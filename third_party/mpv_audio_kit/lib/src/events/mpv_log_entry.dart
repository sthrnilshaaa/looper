// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import '../types/enums/log_level.dart';

/// A structured log entry. Emitted on [PlayerStream.log] for messages
/// from the mpv engine (`'ffmpeg'`, `'demux'`, `'ao'`, …) and on
/// [PlayerStream.internalLog] for library-side diagnostics (parse
/// warnings, hook timeouts; always carries `prefix: 'mpv_audio_kit'`).
/// Filter by [level] to reduce noise.
///
/// Example:
/// ```dart
/// player.stream.log.listen((entry) {
///   if (entry.level == LogLevel.error) {
///     print('[${entry.prefix}] ${entry.level.mpvValue}: ${entry.text}');
///   }
/// });
/// ```
class MpvLogEntry {
  /// The mpv subsystem that generated this message (e.g. `'ffmpeg'`, `'demux'`).
  final String prefix;

  /// Severity level — see [LogLevel] for the closed set.
  final LogLevel level;

  /// The log message text. Trailing newlines are stripped before delivery
  /// so you can concatenate or render entries without per-line trimming.
  final String text;

  /// Creates a log entry from a single mpv log line.
  const MpvLogEntry({
    required this.prefix,
    required this.level,
    required this.text,
  });

  @override
  String toString() => '[$prefix] ${level.mpvValue}: $text';
}
