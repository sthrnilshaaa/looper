// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'package:meta/meta.dart';

/// The `set` commands that turn off the analysis switches of libmpv. The
/// loudness scan goes first: turning the waveform off while the scan still
/// runs would restart the decode pass for the scan alone. The core
/// teardowns that run without a player send them: the native Hot Restart
/// reap and orphan release, and the web Hot Restart registry.
@internal
const List<String> analysisOffCommands = [
  'set loudness-scan-enabled no',
  'set waveform-enabled no',
  'set analyzer-taps ""',
];
