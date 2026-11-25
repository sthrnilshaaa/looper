// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

/// The libmpv-scripts release the build hook bundles (hook/build.dart), as
/// stamped into mpv's version string (`mpv v0.42.0+rN`). The one place the
/// package names it: the hook downloads `libmpv-<release>` from it, and
/// scripts/update_libmpv.sh rewrites it.
const String libmpvRelease = 'r27';

/// The ABI of the web module (`MAK_WEB_ABI` of libmpv-scripts) this package
/// drives: the exports it calls, the struct layout it decodes, the wakeup
/// bridge and `Module.makWebAudio`. The module states its own at load, and
/// scripts/update_libmpv.sh refuses a release whose manifest names another.
const int webModuleAbi = 2;
