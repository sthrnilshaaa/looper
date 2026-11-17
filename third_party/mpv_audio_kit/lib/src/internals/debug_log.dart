// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'dart:io';

import 'package:meta/meta.dart';

/// Minimal Flutter-free replacement for `debugPrint` from
/// `package:flutter/foundation.dart`.
///
/// Writes a single line to `stderr`. Behaviour parity with `debugPrint`
/// is intentionally minimal — used only for one-shot diagnostic
/// warnings (orphan-handle cleanup, locale init failure, JSON parse
/// warnings). Throughput protection isn't relevant.
@internal
void debugLog(String message) {
  // ignore: avoid_print
  stderr.writeln(message);
}
