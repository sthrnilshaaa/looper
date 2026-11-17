// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

/// S/PDIF (or HDMI) compressed-audio passthrough codec.
///
/// Mirrors mpv's `--audio-spdif=<codecs>` option: the wire-level value is
/// a comma-separated list of codec tokens. mpv's `audio-spdif` accepts
/// exactly `ac3`, `dts`, `dts-hd`, `eac3`, `truehd`, so [Spdif] is a closed
/// enum over that set; tokens unknown to mpv are silently dropped on parse
/// to stay forward-compatible with future mpv builds.
///
/// Pass a [Set] (any size, including empty) to [Player.setAudioSpdif] to
/// enable passthrough atomically. An empty set disables passthrough.
///
/// ```dart
/// // Home-theater Dolby + DTS-HD passthrough
/// await player.setAudioSpdif({Spdif.ac3, Spdif.eac3, Spdif.trueHd, Spdif.dtsHd});
///
/// // Disable
/// await player.setAudioSpdif({});
/// ```
///
/// **Note on [dtsHd]**: it is a *modifier* applied when the source codec
/// is DTS — it requests DTS-HD MA passthrough but also implicitly enables
/// the standard DTS path. Specifying both `dts` and `dtsHd` is equivalent
/// to specifying `dtsHd` alone.
enum Spdif {
  /// Dolby Digital (AC-3) passthrough.
  ac3('ac3'),

  /// DTS Coherent Acoustics passthrough (low-bitrate core).
  dts('dts'),

  /// DTS-HD Master Audio passthrough — implies and supersedes [dts].
  /// Receiver / OS support varies.
  dtsHd('dts-hd'),

  /// Dolby Digital Plus (Enhanced AC-3) passthrough.
  eac3('eac3'),

  /// Dolby TrueHD passthrough — high-bitrate lossless over HDMI.
  trueHd('truehd');

  const Spdif(this.mpvValue);

  /// The wire-level token mpv expects for this codec.
  final String mpvValue;

  /// Maps a single mpv-side codec token to [Spdif]. Returns `null` for
  /// unknown values (forward-compat with future mpv builds adding new
  /// passthrough codecs).
  static Spdif? fromMpv(String raw) => switch (raw) {
        'ac3' => ac3,
        'dts' => dts,
        'dts-hd' => dtsHd,
        'eac3' => eac3,
        'truehd' => trueHd,
        _ => null,
      };

  /// Parses mpv's wire-level CSV (`'ac3,dts,truehd'`) into a typed set.
  /// Empty / whitespace-only input → empty set. Unknown tokens are
  /// dropped silently.
  static Set<Spdif> parseMpvList(String raw) {
    if (raw.trim().isEmpty) return const <Spdif>{};
    return raw
        .split(',')
        .map((s) => fromMpv(s.trim()))
        .whereType<Spdif>()
        .toSet();
  }

  /// Serialises a set into the comma-separated wire format mpv expects.
  /// Empty set → empty string.
  static String formatMpvList(Set<Spdif> codecs) =>
      codecs.map((c) => c.mpvValue).join(',');
}
