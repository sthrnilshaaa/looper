// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

part of 'default_specs.dart';

// The parsers the specs share.

/// Decodes a `MPV_FORMAT_NODE_MAP` whose values are uniformly strings
/// (mpv emits this shape for `chapter-metadata`, `vf-metadata`, …).
/// Falls back to an empty map on a non-map payload; a single malformed
/// emission shouldn't tear down the metadata view.
Map<String, String> _parseStringMap(dynamic raw) {
  if (raw is! Map) return const <String, String>{};
  return raw.map((k, v) => MapEntry(k.toString(), v.toString()));
}

// ── Tiny inline parsers used by buildDefaultSpecs ──────────────────────────

double _identityDouble(double raw, PlayerState _) => raw;

// mpv's `float` options echo a single-precision value; see canonicalFloat.
double _canonicalFloat(double raw, PlayerState _) => canonicalFloat(raw);
int _identityInt(int raw, PlayerState _) => raw;
bool _identityBool(bool raw, PlayerState _) => raw;
String _identityString(String raw, PlayerState _) => raw;
Duration _toDuration(double raw, PlayerState _) => secondsToDuration(raw);

/// `ab-loop-a` and `ab-loop-b` parser. mpv emits `'no'` when disabled
/// (the `M_OPT_ALLOW_NO` flag on `OPT_TIME`); any other value is a
/// numeric string in seconds.
Duration? _parseAbLoopTime(String raw) {
  if (raw == 'no' || raw.isEmpty) return null;
  final secs = double.tryParse(raw);
  if (secs == null || secs.isNaN) return null;
  return secondsToDuration(secs);
}

/// `ab-loop-count` parser. `'inf'` = infinite; non-negative int = explicit
/// repetition count.
int? _parseAbLoopCount(String raw) {
  if (raw == 'inf' || raw.isEmpty) return null;
  return int.tryParse(raw);
}
