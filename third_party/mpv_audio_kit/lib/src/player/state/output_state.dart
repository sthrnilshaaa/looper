// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import '../../internals/unset_sentinel.dart';
import '../../models/audio_params.dart';
import '../../models/device.dart';
import '../../types/state/audio_output_state.dart';

part '../../generated/output_state_data.dart';

const _kAutoDevice = Device(name: 'auto', description: 'Auto');
const _kDefaultDevices = <Device>[_kAutoDevice];

/// The audio output in use: its device, the format it plays and its state, and
/// the system mixer when the output has one.
///
/// The [PlayerState.output] of a player: read it from `player.state.output`, or
/// follow one value through its stream in `player.stream`.
///
/// {@category State and streams}
final class OutputState with _$OutputState {
  /// Audio format parameters as sent to the hardware (post-processing).
  final AudioParams audioOutParams;

  /// The currently selected audio output device.
  final Device audioDevice;

  /// All audio output devices detected by mpv. On Android these are the
  /// drivers, not the physical devices: see [Device].
  final List<Device> audioDevices;

  /// Audio output lifecycle: in practice `closed`, then `active` or
  /// `failed`. See [AudioOutputState].
  final AudioOutputState audioOutputState;

  /// Name of the audio output driver in use (e.g. `coreaudio`, `pulse`,
  /// `wasapi`). Differs from [PlayerSettings.audioDriver] (which is the
  /// requested driver, empty for the automatic choice): this is what mpv
  /// actually resolved at runtime. Mirrors mpv's `current-ao`.
  final String currentAo;

  /// The volume the audio driver exposes, in percent (`ao-volume`), distinct
  /// from soft [PlayerSettings.volume]: the app's stream on most drivers, the
  /// whole device with ALSA and WASAPI in exclusive mode. `null` when the
  /// active audio output doesn't expose it, as on iOS and Android. Set via
  /// [Player.setSystemVolume] (best-effort).
  final double? systemVolume;

  /// The mute the audio driver exposes (`ao-mute`), distinct from soft
  /// [PlayerSettings.mute]. `null` when the active audio output doesn't expose
  /// it. Set via [Player.setSystemMute].
  final bool? systemMute;

  /// Creates a [OutputState]; each value defaults to the one of a player that
  /// has loaded nothing.
  const OutputState({
    this.audioOutParams = const AudioParams(),
    this.audioDevice = _kAutoDevice,
    this.audioDevices = _kDefaultDevices,
    this.audioOutputState = AudioOutputState.closed,
    this.currentAo = '',
    this.systemVolume,
    this.systemMute,
  });
}
