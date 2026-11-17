// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

/// Internal enum for the 41 named layouts mpv recognises (mpv's
/// `std_layout_names[]` table minus its leading `empty` placeholder, which is
/// not a usable output layout). Private — consumers use the [Channels]
/// static fields (`Channels.stereo`, `Channels.fiveOneSide`, …) which
/// wrap each member in a [Channels] instance.
enum _Named {
  /// Defer to mpv's automatic channel-layout choice.
  auto('auto'),

  /// Like [auto] but reject multichannel layouts unless the audio device
  /// explicitly advertises support.
  autoSafe('auto-safe'),

  /// Single front-centre channel.
  mono('mono'),

  /// Alias of [mono].
  oneZero('1.0'),

  /// Front-left + front-right.
  stereo('stereo'),

  /// Alias of [stereo].
  twoZero('2.0'),

  /// Two main channels + LFE.
  twoOne('2.1'),

  /// Front-left + front-right + front-centre.
  threeZero('3.0'),

  /// Front pair + back-centre.
  threeZeroBack('3.0(back)'),

  /// Front pair + front-centre + back-centre.
  fourZero('4.0'),

  /// Front pair + back pair.
  quad('quad'),

  /// Front pair + side surrounds (instead of back).
  quadSide('quad(side)'),

  /// Three main channels + LFE.
  threeOne('3.1'),

  /// 3.1 with back-centre.
  threeOneBack('3.1(back)'),

  /// Five main channels (front + back surrounds), no LFE.
  fiveZero('5.0'),

  /// 5.0 in ALSA channel order.
  fiveZeroAlsa('5.0(alsa)'),

  /// 5.0 with side surrounds (instead of back).
  fiveZeroSide('5.0(side)'),

  /// Four main channels + LFE.
  fourOne('4.1'),

  /// 4.1 in ALSA channel order.
  fourOneAlsa('4.1(alsa)'),

  /// Five main channels + LFE, back surrounds (DVD / Dolby Digital).
  fiveOne('5.1'),

  /// 5.1 in ALSA channel order.
  fiveOneAlsa('5.1(alsa)'),

  /// Five main channels + LFE, side surrounds (DTS / ATSC).
  fiveOneSide('5.1(side)'),

  /// Front + back-centre + side surrounds, no LFE.
  sixZero('6.0'),

  /// 6.0 with front-left/right-of-centre.
  sixZeroFront('6.0(front)'),

  /// Six-channel hexagonal layout.
  hexagonal('hexagonal'),

  /// Six main channels + LFE.
  sixOne('6.1'),

  /// 6.1 with back surrounds.
  sixOneBack('6.1(back)'),

  /// 6.1 with top-centre channel.
  sixOneTop('6.1(top)'),

  /// 6.1 with front-left/right-of-centre.
  sixOneFront('6.1(front)'),

  /// Seven main channels (front + back + side), no LFE.
  sevenZero('7.0'),

  /// 7.0 with front wide channels.
  sevenZeroFront('7.0(front)'),

  /// 7.0 with surround-direct-left/right (rear).
  sevenZeroRear('7.0(rear)'),

  /// Seven main channels + LFE — canonical 7.1.
  sevenOne('7.1'),

  /// 7.1 in ALSA channel order.
  sevenOneAlsa('7.1(alsa)'),

  /// 7.1 with front wide channels (instead of side surrounds).
  sevenOneWide('7.1(wide)'),

  /// 7.1 with both wide-fronts AND side surrounds (no back surrounds).
  sevenOneWideSide('7.1(wide-side)'),

  /// 7.1 with top-front-left/right (height channels).
  sevenOneTop('7.1(top)'),

  /// 7.1 with surround-direct-left/right (rear).
  sevenOneRear('7.1(rear)'),

  /// Eight-channel octagonal layout.
  octagonal('octagonal'),

  /// Front pair + back pair + four top channels.
  cube('cube'),

  /// 16-channel cinema-grade overhead array.
  hexadecagonal('hexadecagonal'),

  /// Stereo downmix (semantic alias of [stereo]).
  downmix('downmix'),

  /// NHK / ITU-R BS.775 immersive layout (24 channels).
  surround222('22.2');

  const _Named(this.mpvValue);
  final String mpvValue;
}

/// How [Player.setAudioChannels] should resolve mpv's `audio-channels`
/// property.
///
/// Sealed union over:
/// - [auto] / [autoSafe] — let mpv pick.
/// - 41 named layouts (mirror of mpv's `std_layout_names[]`).
/// - [Channels.custom] for raw mpv strings (comma-separated layouts or
///   speaker-tag arrays such as `'fl-fr-fc-bl-br-sl-sr-lfe'`).
///
/// Use the static fields at call-site:
///
/// ```dart
/// await player.setAudioChannels(Channels.stereo);
/// await player.setAudioChannels(Channels.fiveOneSide);
/// await player.setAudioChannels(Channels.custom('fl-fr-lfe'));
/// ```
sealed class Channels {
  const Channels._();

  /// The wire-level string mpv expects on the `audio-channels` property.
  String get mpvValue;

  // ── Special modes ──────────────────────────────────────────────────

  /// Defer to mpv's automatic channel-layout choice. `audio-channels=auto`.
  static const Channels auto = _StdChannels(_Named.auto);

  /// Same as [auto] but reject multichannel layouts unless the device
  /// explicitly advertises support. `audio-channels=auto-safe`.
  static const Channels autoSafe = _StdChannels(_Named.autoSafe);

  // ── Named layouts (41 — mirror of mpv std_layout_names[]) ──────────

  /// `mono` — single front-centre channel.
  static const Channels mono = _StdChannels(_Named.mono);

  /// `1.0` — alias of [mono].
  static const Channels oneZero = _StdChannels(_Named.oneZero);

  /// `stereo` — front-left + front-right.
  static const Channels stereo = _StdChannels(_Named.stereo);

  /// `2.0` — alias of [stereo].
  static const Channels twoZero = _StdChannels(_Named.twoZero);

  /// `2.1` — two main channels + LFE.
  static const Channels twoOne = _StdChannels(_Named.twoOne);

  /// `3.0` — front-left + front-right + front-centre.
  static const Channels threeZero = _StdChannels(_Named.threeZero);

  /// `3.0(back)` — front pair + back-centre.
  static const Channels threeZeroBack = _StdChannels(_Named.threeZeroBack);

  /// `4.0` — front pair + front-centre + back-centre.
  static const Channels fourZero = _StdChannels(_Named.fourZero);

  /// `quad` — front pair + back pair.
  static const Channels quad = _StdChannels(_Named.quad);

  /// `quad(side)` — front pair + side surrounds (instead of back).
  static const Channels quadSide = _StdChannels(_Named.quadSide);

  /// `3.1` — three main channels + LFE.
  static const Channels threeOne = _StdChannels(_Named.threeOne);

  /// `3.1(back)` — 3.1 with back-centre.
  static const Channels threeOneBack = _StdChannels(_Named.threeOneBack);

  /// `5.0` — five main channels (front + back surrounds), no LFE.
  static const Channels fiveZero = _StdChannels(_Named.fiveZero);

  /// `5.0(alsa)` — 5.0 in ALSA channel order.
  static const Channels fiveZeroAlsa = _StdChannels(_Named.fiveZeroAlsa);

  /// `5.0(side)` — 5.0 with side surrounds (instead of back).
  static const Channels fiveZeroSide = _StdChannels(_Named.fiveZeroSide);

  /// `4.1` — four main channels + LFE.
  static const Channels fourOne = _StdChannels(_Named.fourOne);

  /// `4.1(alsa)` — 4.1 in ALSA channel order.
  static const Channels fourOneAlsa = _StdChannels(_Named.fourOneAlsa);

  /// `5.1` — five main channels + LFE, back surrounds (DVD / Dolby
  /// Digital canonical).
  static const Channels fiveOne = _StdChannels(_Named.fiveOne);

  /// `5.1(alsa)` — 5.1 in ALSA channel order.
  static const Channels fiveOneAlsa = _StdChannels(_Named.fiveOneAlsa);

  /// `5.1(side)` — five main channels + LFE, side surrounds (DTS / ATSC).
  static const Channels fiveOneSide = _StdChannels(_Named.fiveOneSide);

  /// `6.0` — front + back-centre + side surrounds, no LFE.
  static const Channels sixZero = _StdChannels(_Named.sixZero);

  /// `6.0(front)` — 6.0 with front-left/right-of-centre.
  static const Channels sixZeroFront = _StdChannels(_Named.sixZeroFront);

  /// `hexagonal` — six-channel hexagonal layout.
  static const Channels hexagonal = _StdChannels(_Named.hexagonal);

  /// `6.1` — six main channels + LFE.
  static const Channels sixOne = _StdChannels(_Named.sixOne);

  /// `6.1(back)` — 6.1 with back surrounds.
  static const Channels sixOneBack = _StdChannels(_Named.sixOneBack);

  /// `6.1(top)` — 6.1 with top-centre channel.
  static const Channels sixOneTop = _StdChannels(_Named.sixOneTop);

  /// `6.1(front)` — 6.1 with front-left/right-of-centre.
  static const Channels sixOneFront = _StdChannels(_Named.sixOneFront);

  /// `7.0` — seven main channels (front + back + side), no LFE.
  static const Channels sevenZero = _StdChannels(_Named.sevenZero);

  /// `7.0(front)` — 7.0 with front wide channels.
  static const Channels sevenZeroFront = _StdChannels(_Named.sevenZeroFront);

  /// `7.0(rear)` — 7.0 with surround-direct-left/right (rear).
  static const Channels sevenZeroRear = _StdChannels(_Named.sevenZeroRear);

  /// `7.1` — seven main channels + LFE, canonical layout.
  static const Channels sevenOne = _StdChannels(_Named.sevenOne);

  /// `7.1(alsa)` — 7.1 in ALSA channel order.
  static const Channels sevenOneAlsa = _StdChannels(_Named.sevenOneAlsa);

  /// `7.1(wide)` — 7.1 with front wide channels (instead of side
  /// surrounds).
  static const Channels sevenOneWide = _StdChannels(_Named.sevenOneWide);

  /// `7.1(wide-side)` — 7.1 with both wide-fronts AND side surrounds
  /// (no back surrounds).
  static const Channels sevenOneWideSide =
      _StdChannels(_Named.sevenOneWideSide);

  /// `7.1(top)` — 7.1 with top-front-left/right (height channels).
  static const Channels sevenOneTop = _StdChannels(_Named.sevenOneTop);

  /// `7.1(rear)` — 7.1 with surround-direct-left/right (rear).
  static const Channels sevenOneRear = _StdChannels(_Named.sevenOneRear);

  /// `octagonal` — eight-channel octagonal layout.
  static const Channels octagonal = _StdChannels(_Named.octagonal);

  /// `cube` — front pair + back pair + four top channels.
  static const Channels cube = _StdChannels(_Named.cube);

  /// `hexadecagonal` — 16-channel cinema-grade overhead array.
  static const Channels hexadecagonal = _StdChannels(_Named.hexadecagonal);

  /// `downmix` — stereo downmix (semantic alias of [stereo]).
  static const Channels downmix = _StdChannels(_Named.downmix);

  /// `22.2` — NHK / ITU-R BS.775 immersive layout (24 channels).
  static const Channels surround222 = _StdChannels(_Named.surround222);

  // ── Escape ─────────────────────────────────────────────────────────

  /// Any other mpv-recognised channel string — comma-separated layouts
  /// or raw speaker-tag lists (e.g. `'fl-fr-fc-bl-br-sl-sr-lfe'`).
  /// Forwarded to mpv verbatim.
  const factory Channels.custom(String mpvLayout) = ChannelsCustom._;

  /// Maps a raw mpv-side value back to the typed surface. Recognises
  /// `auto`, `auto-safe`, and every entry of mpv's `std_layout_names[]`;
  /// anything else falls through to [Channels.custom] so external
  /// mutations (raw `setRawProperty`, future mpv versions, or arbitrary
  /// speaker-tag layouts) are still observable.
  static Channels fromMpv(String raw) {
    if (raw.isEmpty) return Channels.auto;
    for (final n in _Named.values) {
      if (n.mpvValue == raw) return _StdChannels(n);
    }
    return Channels.custom(raw);
  }
}

/// Pattern-matching variant for any of the 41 named layouts. Carries the
/// internal [_Named] tag — consumers compare via `==` against the
/// `Channels.<name>` static fields, or pattern-match the outer
/// [Channels] sealed type.
final class _StdChannels extends Channels {
  final _Named name;

  const _StdChannels(this.name) : super._();

  @override
  String get mpvValue => name.mpvValue;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is _StdChannels && other.name == name);

  @override
  int get hashCode => name.hashCode;

  @override
  String toString() => 'Channels.${name.name}';
}

/// Custom-string variant — escape hatch for mpv layouts beyond the
/// 41 named ones (comma-separated layouts, raw speaker tags, future mpv
/// additions).
final class ChannelsCustom extends Channels {
  /// The raw layout string passed straight to mpv's `audio-channels`
  /// property (e.g. a comma-separated list or raw speaker tags).
  final String mpvLayout;

  const ChannelsCustom._(this.mpvLayout) : super._();

  @override
  String get mpvValue => mpvLayout;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChannelsCustom && other.mpvLayout == mpvLayout);

  @override
  int get hashCode => Object.hash(ChannelsCustom, mpvLayout);

  @override
  String toString() => 'Channels.custom($mpvLayout)';
}
