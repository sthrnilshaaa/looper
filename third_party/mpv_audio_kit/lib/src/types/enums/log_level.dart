// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

/// Severity threshold for the mpv log stream and library-side
/// diagnostics. Mirrors mpv's `--msg-level` levels verbatim.
///
/// Used both as the type of [MpvLogEntry.level] (the level a single
/// entry carries) and as the threshold passed to
/// [PlayerConfiguration.logLevel] (anything strictly above the chosen
/// threshold is filtered before reaching the consumer).
///
/// Ordering: [off] < [fatal] < [error] < [warn] < [info] < [v] <
/// [debug] < [trace]. A consumer asking for [warn] sees `warn`,
/// `error`, and `fatal`; asking for [info] adds `info` on top, etc.
enum LogLevel {
  /// No log entries emitted. Use this to silence the engine log entirely.
  off('no'),

  /// Unrecoverable failures (mpv aborting, libmpv shutdown).
  fatal('fatal'),

  /// Error-level messages (failed file load, decoder error, …).
  error('error'),

  /// Warning-level messages (recoverable degradations).
  warn('warn'),

  /// Steady-state informational messages.
  info('info'),

  /// Verbose, mostly useful for debugging.
  v('v'),

  /// Debug, includes per-frame chatter.
  debug('debug'),

  /// Maximum verbosity.
  trace('trace');

  const LogLevel(this.mpvValue);

  /// The string mpv expects in `mpv_request_log_messages` and emits in
  /// every log entry's `level` field.
  final String mpvValue;

  /// Maps a mpv-side level string to the typed enum. Returns [info] for
  /// unknown values — forward-compat with future mpv builds that may
  /// add new levels.
  static LogLevel fromMpv(String value) {
    for (final level in LogLevel.values) {
      if (level.mpvValue == value) return level;
    }
    return LogLevel.info;
  }
}
