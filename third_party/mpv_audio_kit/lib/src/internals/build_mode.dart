// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'package:meta/meta.dart';

/// Whether this build can Hot Restart: debug builds only.
///
/// Profile and release builds run AOT, without Hot Reload or Hot Restart,
/// and a profile build still has `dart.vm.product` false: keyed on that
/// alone, it took the debug behavior. The same value as Flutter's
/// `kDebugMode`, without importing Flutter into the event isolate.
@internal
const bool kHotRestartPossible =
    !bool.fromEnvironment('dart.vm.product') &&
    !bool.fromEnvironment('dart.vm.profile');
