// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'libmpv_release.dart';

/// The libmpv-scripts release stamped in an mpv version string:
/// `mpv v0.42.0+r27` gives `r27`. `null` for a version without the stamp, a
/// build of upstream mpv.
String? libmpvReleaseOfVersion(String version) =>
    RegExp(r'\+(r\d+)$').firstMatch(version.trim())?.group(1);

/// Why the player cannot run on a libmpv that reports [version] (`null`
/// when the read failed), or `null` when it is a build of [libmpvRelease].
///
/// Each version of the package drives the libmpv of its pin and no other:
/// the struct layout, the properties and the events of the patches are
/// those of that release. A libmpv the app bundles itself or passes to
/// `MpvAudioKit.ensureInitialized` is held to the same release.
String? libmpvMismatch(String? version) {
  if (version != null && libmpvReleaseOfVersion(version) == libmpvRelease) {
    return null;
  }
  return 'libmpv reports "${version ?? 'no version'}", and this '
      'mpv_audio_kit runs on libmpv-$libmpvRelease only: bundle the '
      'libmpv of the libmpv-$libmpvRelease release, or a build of '
      'libmpv-scripts at libmpv-$libmpvRelease';
}
