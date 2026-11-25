// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'package:meta/meta.dart';

/// Writes a single diagnostic line to the browser console, the web
/// counterpart of the stderr line of the dart:io platforms.
@internal
void debugLog(String message) {
  // ignore: avoid_print
  print(message);
}
