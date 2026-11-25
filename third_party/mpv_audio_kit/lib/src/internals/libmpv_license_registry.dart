// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'package:flutter/foundation.dart';

import 'libmpv_licenses.dart';

bool _registered = false;

/// Adds the license texts of the bundled libmpv ([libmpvLicenses]) to
/// Flutter's [LicenseRegistry], once per isolate, so `showLicensePage` and
/// `AboutDialog` list them beside the app's Dart packages. Adds nothing
/// when there are none. `MpvAudioKit.ensureInitialized` calls it.
///
/// [entries] replaces [libmpvLicenses] in tests.
void registerLibmpvLicenses({
  @visibleForTesting List<(List<String>, String)>? entries,
}) {
  if (_registered) return;
  _registered = true;
  final licenses = entries ?? libmpvLicenses;
  if (licenses.isEmpty) return;
  LicenseRegistry.addLicense(
    () => Stream.fromIterable([
      for (final (packages, text) in licenses)
        LicenseEntryWithLineBreaks(packages, text),
    ]),
  );
}

/// Lets a test call [registerLibmpvLicenses] again (after
/// `LicenseRegistry.reset`).
@visibleForTesting
void resetLibmpvLicenseRegistration() => _registered = false;
