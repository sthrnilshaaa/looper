// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

// One-shot diagnostic lines: stderr on dart:io platforms, the console in
// the browser.
export 'debug_log_io.dart' if (dart.library.js_interop) 'debug_log_web.dart';
