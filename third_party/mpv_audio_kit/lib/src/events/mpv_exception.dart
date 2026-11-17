// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

/// Thrown by [Player.setRawProperty] / [Player.sendRawCommand] when
/// libmpv rejects the request — typically a typo in the property name,
/// an out-of-range value, or an unknown command.
///
/// Use [code] for machine-readable dispatch (mirrors `MpvError`
/// constants) and [message] for the human-readable mpv error string.
/// [name] identifies the offending property or command for logging.
class MpvException implements Exception {
  /// Creates an exception describing a rejected libmpv request.
  const MpvException({
    required this.name,
    required this.code,
    required this.message,
  });

  /// The property name (`'volume'`, `'http-header-fields'`, …) or
  /// command name (`'loadfile'`, `'seek'`, …) that mpv rejected.
  final String name;

  /// Negative mpv error code — see `MpvError` for known constants.
  final int code;

  /// Human-readable mpv error string from `mpv_error_string`.
  final String message;

  @override
  String toString() => 'MpvException($name): $message (code=$code)';
}
