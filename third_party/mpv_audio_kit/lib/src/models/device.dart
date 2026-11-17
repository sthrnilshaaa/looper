// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

/// Represents an audio output device detected by mpv.
final class Device {
  /// Internal mpv device name, used with [Player.setAudioDevice].
  ///
  /// The special value `"auto"` lets mpv choose the default system device.
  final String name;

  /// Human-readable description shown in system mixer / device pickers.
  final String description;

  /// Creates a device descriptor from its mpv [name] and [description].
  const Device({required this.name, required this.description});

  /// The default automatic device selection.
  static const Device auto = Device(name: 'auto', description: 'Auto');

  // Equality on [name] only — same-name instances must dedup even when
  // [description] differs, since mpv echoes only the name and the
  // description is reattached from `audio-device-list` afterwards.
  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Device && name == other.name;

  @override
  int get hashCode => name.hashCode;

  @override
  String toString() => 'Device($name, "$description")';
}
