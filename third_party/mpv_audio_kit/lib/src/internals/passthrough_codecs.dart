// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../types/enums/spdif.dart';

/// The plugin's channel that tells the passthrough codecs of the output
/// on Android (PassthroughChannel.kt).
const MethodChannel _channel = MethodChannel('mpv_audio_kit/passthrough');

/// The codecs of `audio-spdif` the output takes, on Android; none on the
/// other platforms, or when the channel fails.
@internal
Future<Set<Spdif>> readPassthroughCodecs() async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
    return const <Spdif>{};
  }
  try {
    final codecs = await _channel.invokeListMethod<String>('codecs');
    return {for (final c in codecs ?? const <String>[]) ?Spdif.fromMpv(c)};
  } on PlatformException {
    return const <Spdif>{};
  } on MissingPluginException {
    return const <Spdif>{};
  }
}
