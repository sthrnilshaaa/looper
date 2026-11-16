// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license
// that can be found in the LICENSE file.
//
// AUTO-GENERATED — do not edit by hand.

import 'audio_effects.dart';
import 'audio_effects_settings.dart';

// ── aecho ────────────────────────────────────────────────────────────────────

/// One echo tap of the lavfi `aecho` filter.
///
/// Each tap fires the input signal once, [delayMs] after the source
/// transient, attenuated by [decay]. Several taps in series produce
/// the classic multi-tap echo (think spring reverb fingerprint).
final class AechoTap {
  /// Delay in milliseconds.
  final double delayMs;

  /// Decay factor in `[0, 1]`. `1.0` = no attenuation, `0.5` =
  /// half-amplitude.
  final double decay;

  /// Creates an [AechoTap].
  const AechoTap({required this.delayMs, required this.decay});

  /// Returns a copy of this tap with the given fields replaced.
  AechoTap copyWith({double? delayMs, double? decay}) =>
      AechoTap(delayMs: delayMs ?? this.delayMs, decay: decay ?? this.decay);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AechoTap && other.delayMs == delayMs && other.decay == decay);

  @override
  int get hashCode => Object.hash(delayMs, decay);

  @override
  String toString() => 'AechoTap(delay: $delayMs ms, decay: $decay)';
}

/// Typed access over the parallel pipe-separated CSVs lavfi's
/// `aecho` packs as `delays`/`decays`.
///
/// The two CSVs are positional: the Nth delay pairs with the Nth
/// decay. Mismatched lengths are clamped to the shorter list — the
/// dropped tail would crash the filter at config time anyway.
extension AechoTapsX on AechoSettings {
  /// Decoded list of taps in declaration order.
  List<AechoTap> get taps {
    final ds = _splitCsv(delays);
    final cs = _splitCsv(decays);
    final n = ds.length < cs.length ? ds.length : cs.length;
    return List.generate(
      n,
      (i) => AechoTap(delayMs: ds[i], decay: cs[i]),
      growable: false,
    );
  }

  /// Returns a copy whose [delays] / [decays] reflect [taps].
  AechoSettings withTaps(List<AechoTap> taps) {
    if (taps.isEmpty) return copyWith(delays: '0', decays: '0');
    return copyWith(
      delays: taps.map((t) => t.delayMs.toStringAsFixed(2)).join('|'),
      decays: taps.map((t) => t.decay.toStringAsFixed(3)).join('|'),
    );
  }
}

// ── chorus ───────────────────────────────────────────────────────────────────

/// One voice of the lavfi `chorus` filter.
///
/// `chorus` produces a "many singers" effect by mixing the dry input
/// with several delayed, decayed, slowly-detuned copies of itself.
/// Each [ChorusVoice] is one of those copies with its own delay,
/// decay, modulation depth, and modulation rate.
final class ChorusVoice {
  /// Delay in milliseconds (typical chorus range: 30..50 ms).
  final double delayMs;

  /// Decay factor in `[0, 1]`.
  final double decay;

  /// LFO modulation depth in milliseconds.
  final double depthMs;

  /// LFO modulation rate in Hz (typical chorus range: 0.1..1 Hz).
  final double speedHz;

  /// Creates a [ChorusVoice].
  const ChorusVoice({
    required this.delayMs,
    required this.decay,
    required this.depthMs,
    required this.speedHz,
  });

  /// Returns a copy of this voice with the given fields replaced.
  ChorusVoice copyWith({
    double? delayMs,
    double? decay,
    double? depthMs,
    double? speedHz,
  }) =>
      ChorusVoice(
        delayMs: delayMs ?? this.delayMs,
        decay: decay ?? this.decay,
        depthMs: depthMs ?? this.depthMs,
        speedHz: speedHz ?? this.speedHz,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChorusVoice &&
          other.delayMs == delayMs &&
          other.decay == decay &&
          other.depthMs == depthMs &&
          other.speedHz == speedHz);

  @override
  int get hashCode => Object.hash(delayMs, decay, depthMs, speedHz);

  @override
  String toString() => 'ChorusVoice(delay: $delayMs ms, decay: $decay, '
      'depth: $depthMs ms, speed: $speedHz Hz)';
}

/// Typed access over the four parallel pipe-separated CSVs
/// (`delays`/`decays`/`depths`/`speeds`) lavfi's `chorus` exposes.
///
/// The four lists are positional: the Nth delay/decay/depth/speed
/// quartet is one voice. Mismatched lengths collapse to the shortest
/// — lavfi rejects asymmetric configs at chain-build time.
extension ChorusVoicesX on ChorusSettings {
  /// Decoded list of voices in declaration order.
  List<ChorusVoice> get voices {
    final ds = _splitCsv(delays);
    final cs = _splitCsv(decays);
    final dp = _splitCsv(depths);
    final sp = _splitCsv(speeds);
    final n = [ds.length, cs.length, dp.length, sp.length]
        .reduce((a, b) => a < b ? a : b);
    return List.generate(
      n,
      (i) => ChorusVoice(
        delayMs: ds[i],
        decay: cs[i],
        depthMs: dp[i],
        speedHz: sp[i],
      ),
      growable: false,
    );
  }

  /// Returns a copy whose four CSVs reflect [voices].
  ChorusSettings withVoices(List<ChorusVoice> voices) {
    if (voices.isEmpty) {
      return copyWith(delays: '', decays: '', depths: '', speeds: '');
    }
    String join(double Function(ChorusVoice) get) =>
        voices.map((v) => get(v).toStringAsFixed(3)).join('|');
    return copyWith(
      delays: join((v) => v.delayMs),
      decays: join((v) => v.decay),
      depths: join((v) => v.depthMs),
      speeds: join((v) => v.speedHz),
    );
  }
}

// ── compand ──────────────────────────────────────────────────────────────────

/// One break-point of the lavfi `compand` filter's transfer function.
///
/// The transfer function is a piecewise linear mapping of input dB
/// to output dB; consecutive [CompandPoint]s define the segments.
/// `compand` interpolates between them — outside the range of the
/// declared points the output is clipped to the nearest break.
final class CompandPoint {
  /// Input level in dB.
  final double inDb;

  /// Output level in dB.
  final double outDb;

  /// Creates a [CompandPoint].
  const CompandPoint({required this.inDb, required this.outDb});

  /// Returns a copy of this point with the given fields replaced.
  CompandPoint copyWith({double? inDb, double? outDb}) =>
      CompandPoint(inDb: inDb ?? this.inDb, outDb: outDb ?? this.outDb);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CompandPoint && other.inDb == inDb && other.outDb == outDb);

  @override
  int get hashCode => Object.hash(inDb, outDb);

  @override
  String toString() => 'CompandPoint(in: $inDb dB, out: $outDb dB)';
}

/// Typed access over the `points` string lavfi's `compand` carries
/// (space-separated `inDb/outDb` pairs).
extension CompandPointsX on CompandSettings {
  /// Decoded transfer-function points, sorted by ascending input.
  List<CompandPoint> get transferPoints {
    final src = points;
    if (src.trim().isEmpty) return const [];
    final out = <CompandPoint>[];
    for (final pair in src.trim().split(RegExp(r'\s+'))) {
      final xy = pair.split('/');
      if (xy.length != 2) continue;
      final x = double.tryParse(xy[0]);
      final y = double.tryParse(xy[1]);
      if (x != null && y != null) {
        out.add(CompandPoint(inDb: x, outDb: y));
      }
    }
    out.sort((a, b) => a.inDb.compareTo(b.inDb));
    return out;
  }

  /// Returns a copy whose [points] reflects [points] (ascending
  /// input order). Empty input clears the transfer function.
  CompandSettings withTransferPoints(List<CompandPoint> points) {
    if (points.isEmpty) return copyWith(points: '');
    final sorted = [...points]..sort((a, b) => a.inDb.compareTo(b.inDb));
    return copyWith(
      points: sorted
          .map((p) =>
              '${p.inDb.toStringAsFixed(1)}/${p.outDb.toStringAsFixed(1)}',)
          .join(' '),
    );
  }
}

/// One per-channel envelope of the lavfi `compand` filter — the
/// attack and decay time-constants the level detector uses on that
/// channel.
///
/// `compand` accepts independent envelopes per output channel: the
/// first envelope binds to channel 0, the second to channel 1, and
/// so on. When fewer envelopes are declared than the input has
/// channels, the last one applies to the remainder.
final class CompandEnvelope {
  /// Seconds. Attack time-constant (level detector rise).
  final double attackSeconds;

  /// Seconds. Decay time-constant (level detector fall).
  final double decaySeconds;

  /// Creates a [CompandEnvelope].
  const CompandEnvelope({
    required this.attackSeconds,
    required this.decaySeconds,
  });

  /// Returns a copy of this envelope with the given fields replaced.
  CompandEnvelope copyWith({double? attackSeconds, double? decaySeconds}) =>
      CompandEnvelope(
        attackSeconds: attackSeconds ?? this.attackSeconds,
        decaySeconds: decaySeconds ?? this.decaySeconds,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CompandEnvelope &&
          other.attackSeconds == attackSeconds &&
          other.decaySeconds == decaySeconds);

  @override
  int get hashCode => Object.hash(attackSeconds, decaySeconds);

  @override
  String toString() =>
      'CompandEnvelope(attack: $attackSeconds s, decay: $decaySeconds s)';
}

/// Typed access over the parallel pipe-separated CSVs lavfi's
/// `compand` packs as `attacks`/`decays`.
///
/// The two CSVs are positional per-channel: the Nth attack pairs
/// with the Nth decay. Mismatched lengths clamp to the shorter list.
extension CompandEnvelopesX on CompandSettings {
  /// Decoded list of per-channel envelopes in declaration order.
  List<CompandEnvelope> get envelopes {
    final atks = _splitCsv(attacks);
    final decs = _splitCsv(decays);
    final n = atks.length < decs.length ? atks.length : decs.length;
    return List.generate(
      n,
      (i) => CompandEnvelope(
        attackSeconds: atks[i],
        decaySeconds: decs[i],
      ),
      growable: false,
    );
  }

  /// Returns a copy whose [attacks] / [decays] reflect [envelopes].
  CompandSettings withEnvelopes(List<CompandEnvelope> envelopes) {
    if (envelopes.isEmpty) return copyWith(attacks: '0', decays: '0.8');
    return copyWith(
      attacks:
          envelopes.map((e) => e.attackSeconds.toStringAsFixed(4)).join('|'),
      decays: envelopes.map((e) => e.decaySeconds.toStringAsFixed(4)).join('|'),
    );
  }
}

/// lavfi-side default for `compand.soft-knee` — leaves the
/// transfer-function knee hard.
const double kCompandSoftKneeDefault = 0.01;

/// Typed access over `compand.soft-knee` — the smoothing applied
/// across the breakpoints of the transfer function.
///
/// `soft-knee` is a single numeric AVOption, but the codegen routes
/// it through `params: Map<String, double>` because Dart identifiers
/// can't contain a hyphen. This extension hides that detail so
/// consumers can write `s.withSoftKnee(0.5)` instead of building the
/// map by hand.
extension CompandSoftKneeX on CompandSettings {
  /// Soft-knee smoothing in dB. lavfi default is
  /// [kCompandSoftKneeDefault] — a hard knee.
  double get softKnee => params['soft-knee'] ?? kCompandSoftKneeDefault;

  /// Returns a copy whose `params` map carries [v] under the
  /// `soft-knee` key. Values equal to [kCompandSoftKneeDefault] drop
  /// out of the map (the lavfi default applies implicitly).
  CompandSettings withSoftKnee(double v) {
    final next = Map<String, double>.from(params);
    if ((v - kCompandSoftKneeDefault).abs() < 1e-6) {
      next.remove('soft-knee');
    } else {
      next['soft-knee'] = v;
    }
    return copyWith(params: next);
  }
}

// ── firequalizer ─────────────────────────────────────────────────────────────

/// One break-point of the lavfi `firequalizer` filter's gain curve.
///
/// `firequalizer` interpolates between the declared entries (linearly
/// by default, per its `gain_interpolate(f)` expression) into an
/// arbitrary FIR frequency response. Unlike biquad EQs, the resulting
/// curve can have any shape — the FIR is constructed from these
/// points via inverse-FFT.
final class FirequalizerEntry {
  /// Frequency in Hz.
  final double frequencyHz;

  /// Gain in dB at [frequencyHz].
  final double gainDb;

  /// Creates a [FirequalizerEntry].
  const FirequalizerEntry({
    required this.frequencyHz,
    required this.gainDb,
  });

  /// Returns a copy of this entry with the given fields replaced.
  FirequalizerEntry copyWith({double? frequencyHz, double? gainDb}) =>
      FirequalizerEntry(
        frequencyHz: frequencyHz ?? this.frequencyHz,
        gainDb: gainDb ?? this.gainDb,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FirequalizerEntry &&
          other.frequencyHz == frequencyHz &&
          other.gainDb == gainDb);

  @override
  int get hashCode => Object.hash(frequencyHz, gainDb);

  @override
  String toString() =>
      'FirequalizerEntry(frequency: $frequencyHz Hz, gain: $gainDb dB)';
}

/// Typed access over the `gain_entry` string lavfi's `firequalizer`
/// carries (`entry(freq,gain);entry(freq,gain);…`).
extension FirequalizerEntriesX on FirequalizerSettings {
  /// Decoded gain entries, sorted by ascending frequency.
  List<FirequalizerEntry> get gainEntries {
    if (gain_entry.trim().isEmpty) return const [];
    final out = <FirequalizerEntry>[];
    for (final m in _firequalizerEntryRe.allMatches(gain_entry)) {
      final f = double.tryParse(m.group(1)!);
      final g = double.tryParse(m.group(2)!);
      if (f != null && g != null) {
        out.add(FirequalizerEntry(frequencyHz: f, gainDb: g));
      }
    }
    out.sort((a, b) => a.frequencyHz.compareTo(b.frequencyHz));
    return out;
  }

  /// Returns a copy whose [gain_entry] reflects [entries] (ascending
  /// frequency order). Empty input clears the filter's response.
  FirequalizerSettings withGainEntries(List<FirequalizerEntry> entries) {
    if (entries.isEmpty) return copyWith(gain_entry: '');
    final sorted = [...entries]
      ..sort((a, b) => a.frequencyHz.compareTo(b.frequencyHz));
    return copyWith(
      gain_entry: sorted
          .map((e) =>
              'entry(${e.frequencyHz.toStringAsFixed(1)},${e.gainDb.toStringAsFixed(2)})',)
          .join(';'),
    );
  }
}

final RegExp _firequalizerEntryRe =
    RegExp(r'entry\(\s*([-\d.eE+]+)\s*,\s*([-\d.eE+]+)\s*\)');

// ── afftdn ───────────────────────────────────────────────────────────────────

/// Number of fixed bands lavfi's `afftdn` uses for its custom noise
/// profile — the filter splits the spectrum into 15 logarithmic bands
/// and lets the consumer set a noise floor per band.
const int kAfftdnBandCount = 15;

/// Default per-band noise floor when none is provided.
const double kAfftdnBandNoiseDefault = 0.0;

/// Typed access over the `band_noise` (alias `bn`) string lavfi's
/// `afftdn` packs as space- or pipe-separated noise levels per band.
///
/// The list is always exactly [kAfftdnBandCount] long; entries the
/// consumer doesn't touch read as [kAfftdnBandNoiseDefault].
extension AfftdnBandNoiseX on AfftdnSettings {
  /// Decoded per-band noise floors, lows-to-highs, in lavfi's
  /// 15-band logarithmic split. Always length [kAfftdnBandCount];
  /// missing entries fill with [kAfftdnBandNoiseDefault].
  List<double> get bandNoiseLevels {
    final raw = band_noise.trim();
    final parsed = <double>[];
    if (raw.isNotEmpty) {
      for (final part in raw.split(RegExp(r'[ |]+'))) {
        final v = double.tryParse(part.trim());
        if (v != null) parsed.add(v);
        if (parsed.length >= kAfftdnBandCount) break;
      }
    }
    while (parsed.length < kAfftdnBandCount) {
      parsed.add(kAfftdnBandNoiseDefault);
    }
    return List.unmodifiable(parsed);
  }

  /// Returns a copy whose [band_noise] reflects [levels]. Lists
  /// shorter than [kAfftdnBandCount] pad with
  /// [kAfftdnBandNoiseDefault]; longer lists are truncated. The
  /// emitted CSV uses pipe separation (lavfi accepts both space and
  /// pipe; pipe is unambiguous in mpv's filter-args parser).
  AfftdnSettings withBandNoiseLevels(List<double> levels) {
    final padded =
        List<double>.filled(kAfftdnBandCount, kAfftdnBandNoiseDefault);
    for (var i = 0; i < kAfftdnBandCount && i < levels.length; i++) {
      padded[i] = levels[i];
    }
    return copyWith(
      band_noise: padded.map((v) => v.toStringAsFixed(2)).join('|'),
    );
  }
}

// ── anequalizer ──────────────────────────────────────────────────────────────

/// One logical band of the lavfi `anequalizer` filter.
///
/// On the wire this is repeated once per channel inside the
/// `params` CSV — the typed model hides that detail. Stereo content
/// hears the band on both channels by default; surround content past
/// channel 1 is left to mpv's downmix.
final class AnequalizerBand {
  /// Centre frequency in Hz.
  final double frequency;

  /// Bandwidth in Hz (NOT a Q-factor). Use [withQ] to set by Q.
  final double bandwidth;

  /// Gain in dB.
  final double gain;

  /// Filter shape. Defaults to [AnequalizerBandType.butterworth] —
  /// matches the lavfi `t=0` default.
  final AnequalizerBandType type;

  /// Creates an [AnequalizerBand].
  const AnequalizerBand({
    required this.frequency,
    required this.bandwidth,
    required this.gain,
    this.type = AnequalizerBandType.butterworth,
  });

  /// Q-factor view. `Q = frequency / bandwidth`.
  double get q => bandwidth <= 0 ? 1.0 : frequency / bandwidth;

  /// Returns a copy with [bandwidth] derived from a Q-factor.
  AnequalizerBand withQ(double q) =>
      copyWith(bandwidth: frequency / q.clamp(0.001, 1000.0));

  /// Returns a copy of this band with the given fields replaced.
  AnequalizerBand copyWith({
    double? frequency,
    double? bandwidth,
    double? gain,
    AnequalizerBandType? type,
  }) =>
      AnequalizerBand(
        frequency: frequency ?? this.frequency,
        bandwidth: bandwidth ?? this.bandwidth,
        gain: gain ?? this.gain,
        type: type ?? this.type,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AnequalizerBand &&
          other.frequency == frequency &&
          other.bandwidth == bandwidth &&
          other.gain == gain &&
          other.type == type);

  @override
  int get hashCode => Object.hash(frequency, bandwidth, gain, type);

  @override
  String toString() =>
      'AnequalizerBand(frequency: $frequency, bandwidth: $bandwidth, '
      'gain: $gain, type: $type)';
}

/// lavfi `anequalizer` filter shape. Matches `t=0|1|2` on the wire.
enum AnequalizerBandType {
  /// Butterworth response (`t=0`) — maximally flat passband.
  butterworth(0),

  /// Chebyshev type-1 response (`t=1`) — passband ripple, steeper rolloff.
  chebyshev1(1),

  /// Chebyshev type-2 response (`t=2`) — stopband ripple, steeper rolloff.
  chebyshev2(2);

  /// Wire-side integer consumed by lavfi's `t=` option.
  final int wireValue;

  /// Binds each shape to its lavfi `t=` integer.
  const AnequalizerBandType(this.wireValue);

  /// Parses a lavfi `t=` integer back into a shape; unknown values
  /// fall back to [butterworth].
  static AnequalizerBandType fromWire(int v) => switch (v) {
        1 => chebyshev1,
        2 => chebyshev2,
        _ => butterworth,
      };
}

/// Default channel count covered by [AnequalizerBandsX.withBands]. Two
/// channels (L+R) is the canonical stereo case; surround content is
/// left to mpv's automatic downmix.
const int _anequalizerDefaultChannels = 2;

/// Typed access over the raw `params` CSV held by [AnequalizerSettings].
extension AnequalizerBandsX on AnequalizerSettings {
  /// Decoded list of bands in declaration order. Reads the underlying
  /// [params] string; the per-channel repeats `withBands` emits are
  /// collapsed back to one entry per logical band.
  List<AnequalizerBand> get bands => _parseAnequalizerBands(params);

  /// Returns a copy whose [params] reflects [bands]. Each band is
  /// emitted once per channel up to [channels] (defaults to 2 — stereo)
  /// so signals get the band on every channel mpv can downmix to.
  AnequalizerSettings withBands(
    List<AnequalizerBand> bands, {
    int channels = _anequalizerDefaultChannels,
  }) =>
      copyWith(params: _serializeAnequalizerBands(bands, channels: channels));
}

// Parser tolerates the codegen's `[...]` wrap (added for mpv's filter-
// args escape) as well as the bare CSV form.
final RegExp _anequalizerBandRe = RegExp(
  r'c(\d+)\s+f=([0-9.eE+-]+)\s+w=([0-9.eE+-]+)\s+g=([0-9.eE+-]+)'
  r'(?:\s+t=(\d+))?',
);

List<AnequalizerBand> _parseAnequalizerBands(String params) {
  var raw = params.trim();
  if (raw.isEmpty) return const [];
  if (raw.startsWith('[') && raw.endsWith(']')) {
    raw = raw.substring(1, raw.length - 1);
  }
  // anequalizer repeats each logical band once per channel
  // (`c0 … | c1 … `). Group entries by channel index and keep the
  // lowest channel's list in declaration order: higher-channel repeats
  // are dropped, and two bands with identical parameters stay distinct
  // (a value-based dedup would collapse them).
  final byChannel = <int, List<AnequalizerBand>>{};
  for (final entry in raw.split('|')) {
    final s = entry.trim();
    if (s.isEmpty) continue;
    final m = _anequalizerBandRe.firstMatch(s);
    if (m == null) continue;
    final ch = int.tryParse(m.group(1)!) ?? 0;
    final f = double.tryParse(m.group(2)!);
    final w = double.tryParse(m.group(3)!);
    final g = double.tryParse(m.group(4)!);
    final t = int.tryParse(m.group(5) ?? '0') ?? 0;
    if (f == null || w == null || g == null) continue;
    (byChannel[ch] ??= <AnequalizerBand>[]).add(AnequalizerBand(
      frequency: f,
      bandwidth: w,
      gain: g,
      type: AnequalizerBandType.fromWire(t),
    ),);
  }
  if (byChannel.isEmpty) return const [];
  final lowest = byChannel.keys.reduce((a, b) => a < b ? a : b);
  return List.unmodifiable(byChannel[lowest]!);
}

String _serializeAnequalizerBands(
  List<AnequalizerBand> bands, {
  required int channels,
}) {
  if (bands.isEmpty) return '';
  if (channels < 1) channels = 1;
  final out = <String>[];
  for (final b in bands) {
    for (var ch = 0; ch < channels; ch++) {
      out.add(
        'c$ch f=${b.frequency.toStringAsFixed(2)} '
        'w=${b.bandwidth.toStringAsFixed(2)} '
        'g=${b.gain.toStringAsFixed(2)} '
        't=${b.type.wireValue}',
      );
    }
  }
  return out.join('|');
}

// ── aiir ─────────────────────────────────────────────────────────────────────

/// One channel slot of the lavfi `aiir` filter — the per-channel gain
/// plus the polynomial coefficients of its IIR transfer function.
///
/// `aiir` lets the consumer specify a fully custom IIR filter by
/// declaring the numerator (`zeros`) and denominator (`poles`)
/// polynomials per channel; channel order matches the input layout.
/// The format encodes channels separated by `|` and coefficients
/// within a channel separated by spaces.
final class AiirChannel {
  /// Linear gain for this channel.
  final double gain;

  /// Numerator (B / "zeros" / reflection) polynomial coefficients.
  final List<double> zeros;

  /// Denominator (A / "poles" / ladder) polynomial coefficients.
  final List<double> poles;

  /// Creates an [AiirChannel].
  const AiirChannel({
    required this.gain,
    required this.zeros,
    required this.poles,
  });

  /// Returns a copy of this channel with the given fields replaced.
  AiirChannel copyWith({
    double? gain,
    List<double>? zeros,
    List<double>? poles,
  }) =>
      AiirChannel(
        gain: gain ?? this.gain,
        zeros: zeros ?? this.zeros,
        poles: poles ?? this.poles,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AiirChannel &&
          other.gain == gain &&
          _listEq(other.zeros, zeros) &&
          _listEq(other.poles, poles));

  @override
  int get hashCode =>
      Object.hash(gain, Object.hashAll(zeros), Object.hashAll(poles));

  @override
  String toString() => 'AiirChannel(gain: $gain, zeros: $zeros, poles: $poles)';
}

/// Typed access over `aiir`'s three parallel string parameters
/// (`gains`/`k`, `poles`/`p`, `zeros`/`z`). The Nth `|`-section of
/// each string belongs to the Nth output channel; coefficient lists
/// within a channel are space-separated.
///
/// The extension always reads / writes the long-form param names
/// (`gains`, `poles`, `zeros`); the short aliases (`k`, `p`, `z`) are
/// kept untouched on writes — consumers using both would conflict
/// with themselves anyway.
extension AiirChannelsX on AiirSettings {
  /// Decoded channel slots in declaration order. When the three
  /// underlying CSVs differ in length, the shortest list wins (lavfi
  /// rejects asymmetric configs at chain-build time).
  List<AiirChannel> get channels {
    final g = _splitCsv(gains);
    final z = _splitChannelsListCsv(zeros);
    final p = _splitChannelsListCsv(poles);
    final n = [g.length, z.length, p.length].reduce((a, b) => a < b ? a : b);
    return List.generate(
      n,
      (i) => AiirChannel(gain: g[i], zeros: z[i], poles: p[i]),
      growable: false,
    );
  }

  /// Returns a copy whose three CSV strings reflect [channels]. While
  /// [AiirSettings.format] and [AiirSettings.process] are at their defaults
  /// (`zp` and serial), they become [AiirFormat.tf] and [AiirProcess.d]:
  /// the coefficients are real, the numerator ([AiirChannel.zeros]) and
  /// denominator ([AiirChannel.poles]) of a transfer function, which the
  /// defaults do not read. A format or process set by hand is kept.
  AiirSettings withChannels(List<AiirChannel> channels) {
    if (channels.isEmpty) {
      return copyWith(gains: '', zeros: '', poles: '');
    }
    String join(List<double> Function(AiirChannel) get, String inner) =>
        channels
            .map((c) => get(c).map((v) => v.toStringAsFixed(4)).join(inner))
            .join('|');
    final defaultFormat = format == AiirFormat.zp && f == AiirFormat.zp;
    final defaultProcess = process == AiirProcess.s && r == AiirProcess.s;
    return copyWith(
      format: defaultFormat ? AiirFormat.tf : null,
      process: defaultProcess ? AiirProcess.d : null,
      gains: channels.map((c) => c.gain.toStringAsFixed(4)).join('|'),
      zeros: join((c) => c.zeros, ' '),
      poles: join((c) => c.poles, ' '),
    );
  }
}

List<List<double>> _splitChannelsListCsv(String? src) {
  if (src == null || src.trim().isEmpty) return const [];
  final out = <List<double>>[];
  for (final ch in src.split('|')) {
    final coeffs = <double>[];
    for (final tok in ch.trim().split(RegExp(r'\s+'))) {
      final v = double.tryParse(tok);
      if (v != null) coeffs.add(v);
    }
    out.add(coeffs);
  }
  return out;
}

// ── adelay ───────────────────────────────────────────────────────────────────

/// Typed access over lavfi's `adelay.delays` — a pipe-separated list
/// of per-channel delays. The Nth entry is the delay applied to the
/// Nth output channel.
///
/// The lavfi grammar accepts a unit suffix (`ms` for milliseconds,
/// `s` for seconds, `S` for samples). The typed view here normalises
/// to **milliseconds**: any suffix is stripped on parse, and the
/// emitter always writes plain milliseconds. Consumers that need
/// sample-accurate delay should write the raw string via
/// [AdelaySettings.copyWith] instead.
extension AdelayChannelsX on AdelaySettings {
  /// Decoded list of channel delays in milliseconds, in declaration
  /// order (channel 0 first).
  List<double> get channelDelaysMs {
    if (delays.trim().isEmpty) return const [];
    final out = <double>[];
    for (final part in delays.split('|')) {
      final stripped = part.trim().replaceAll(RegExp(r'[a-zA-Z]'), '');
      final v = double.tryParse(stripped);
      if (v != null) out.add(v);
    }
    return out;
  }

  /// Returns a copy whose [delays] string reflects [delaysMs] in
  /// declaration order. Empty input clears the filter.
  AdelaySettings withChannelDelaysMs(List<double> delaysMs) {
    if (delaysMs.isEmpty) return copyWith(delays: '');
    return copyWith(
      delays: delaysMs.map((d) => '${d.toStringAsFixed(2)}ms').join('|'),
    );
  }
}

// ── mcompand ─────────────────────────────────────────────────────────────────

/// One band of the lavfi `mcompand` filter — a self-contained
/// compander stage with its own dynamics envelope, transfer
/// function, soft-knee, makeup gain, and crossover frequency.
///
/// `mcompand` itself splits the input into N bands at the crossover
/// frequencies (lows .. highs in ascending order), runs each band
/// through its own [McompandBand], then sums them back. The band
/// model carries the same six parameters as
/// [AcompressorSettings] — threshold, ratio, attack, release, knee,
/// makeup — plus the band's upper-edge crossover, which lavfi reads
/// as the boundary between this band and the next.
///
/// On the wire ffmpeg packs every band into a single opaque `args`
/// string with a positional grammar
/// (`attack,decay knee points crossover [delay [init_vol [gain]]]`,
/// bands joined by `|`). `McompandBandsX` hides that grammar — read
/// [McompandSettings.bands] for the typed view, write back via
/// [McompandSettings.withBands].
final class McompandBand {
  /// dB. Where compression starts. Negative.
  final double thresholdDb;

  /// Compression ratio, ≥ 1. (1.0 = no compression.)
  final double ratio;

  /// Seconds. Time-constant used by the compander's level detector
  /// when the input rises.
  final double attackSeconds;

  /// Seconds. Time-constant used when the input falls.
  final double releaseSeconds;

  /// Soft-knee width in dB. 0 = hard knee; larger smooths the
  /// compression curve around [thresholdDb].
  final double kneeDb;

  /// dB. Output makeup gain applied after compression.
  final double makeupDb;

  /// Hz. Upper edge of this band — anything above goes to the next
  /// band in `mcompand`'s filter chain.
  final double crossoverHz;

  /// Creates a [McompandBand].
  const McompandBand({
    required this.thresholdDb,
    required this.ratio,
    required this.attackSeconds,
    required this.releaseSeconds,
    required this.kneeDb,
    required this.makeupDb,
    required this.crossoverHz,
  });

  /// Returns a copy of this band with the given fields replaced.
  McompandBand copyWith({
    double? thresholdDb,
    double? ratio,
    double? attackSeconds,
    double? releaseSeconds,
    double? kneeDb,
    double? makeupDb,
    double? crossoverHz,
  }) =>
      McompandBand(
        thresholdDb: thresholdDb ?? this.thresholdDb,
        ratio: ratio ?? this.ratio,
        attackSeconds: attackSeconds ?? this.attackSeconds,
        releaseSeconds: releaseSeconds ?? this.releaseSeconds,
        kneeDb: kneeDb ?? this.kneeDb,
        makeupDb: makeupDb ?? this.makeupDb,
        crossoverHz: crossoverHz ?? this.crossoverHz,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is McompandBand &&
          other.thresholdDb == thresholdDb &&
          other.ratio == ratio &&
          other.attackSeconds == attackSeconds &&
          other.releaseSeconds == releaseSeconds &&
          other.kneeDb == kneeDb &&
          other.makeupDb == makeupDb &&
          other.crossoverHz == crossoverHz);

  @override
  int get hashCode => Object.hash(thresholdDb, ratio, attackSeconds,
      releaseSeconds, kneeDb, makeupDb, crossoverHz,);

  @override
  String toString() => 'McompandBand(threshold: $thresholdDb dB, '
      'ratio: $ratio, attack: $attackSeconds s, '
      'release: $releaseSeconds s, knee: $kneeDb dB, '
      'makeup: $makeupDb dB, crossover: $crossoverHz Hz)';
}

/// Typed access over the raw `args` string held by [McompandSettings].
///
/// The underlying lavfi grammar
/// (`attack,decay knee points crossover [delay [init_vol [gain]]]`,
/// bands joined by `|`) is a minor parser written in `af_mcompand.c`.
/// This extension mirrors that parser exactly. Round-trip is
/// lossless for bands produced by [withBands]; bands hand-written
/// with multi-segment transfer curves collapse to "ratio = last
/// segment's slope, threshold = last break" — informative for
/// editor display, lossy if echoed back unchanged.
extension McompandBandsX on McompandSettings {
  /// Decoded list of bands, sorted by ascending crossover.
  List<McompandBand> get bands => _parseMcompandBands(args);

  /// Returns a copy whose [args] reflects [bands] (ascending
  /// crossover order, lossless serialisation).
  McompandSettings withBands(List<McompandBand> bands) =>
      copyWith(args: _serializeMcompandBands(bands));
}

List<McompandBand> _parseMcompandBands(String? args) {
  if (args == null || args.trim().isEmpty) return const [];
  final out = <McompandBand>[];
  for (final raw in args.split('|')) {
    final fields = raw.trim().split(RegExp(r'\s+'));
    // Minimum 4 fields: attack,decay  knee  points  crossover.
    // Trailing 3 (delay, init_vol, gain) optional.
    if (fields.length < 4) continue;
    final ad = fields[0].split(',');
    if (ad.length != 2) continue;
    final attack = double.tryParse(ad[0]);
    final decay = double.tryParse(ad[1]);
    if (attack == null || decay == null) continue;
    final knee = double.tryParse(fields[1]) ?? 0;
    final pts = <(double, double)>[];
    for (final pair in fields[2].split(',')) {
      final xy = pair.split('/');
      if (xy.length == 2) {
        final x = double.tryParse(xy[0]);
        final y = double.tryParse(xy[1]);
        if (x != null && y != null) pts.add((x, y));
      }
    }
    pts.sort((a, b) => a.$1.compareTo(b.$1));
    final crossover = double.tryParse(fields[3]) ?? 0;
    final gain = fields.length > 6 ? (double.tryParse(fields[6]) ?? 0) : 0.0;

    // Reduce N transfer points to (threshold, ratio): the LAST
    // segment's slope inverse becomes the ratio, the second-to-last
    // input becomes the threshold. Lossless for bands [withBands]
    // produced (3-point compressor curves); lossy on hand-written
    // multi-segment curves.
    double threshold;
    double ratio;
    if (pts.length >= 2) {
      final last = pts.last;
      final prev = pts[pts.length - 2];
      final dIn = (last.$1 - prev.$1).abs();
      if (dIn < 1e-6) {
        threshold = prev.$1;
        ratio = 20.0;
      } else {
        final slope = (last.$2 - prev.$2) / dIn;
        ratio = slope.abs() < 1e-6 ? 20.0 : (1.0 / slope).clamp(1.0, 20.0);
        threshold = prev.$1;
      }
    } else {
      threshold = -24;
      ratio = 1;
    }

    out.add(McompandBand(
      thresholdDb: threshold,
      ratio: ratio,
      attackSeconds: attack,
      releaseSeconds: decay,
      kneeDb: knee,
      makeupDb: gain,
      crossoverHz: crossover,
    ),);
  }
  out.sort((a, b) => a.crossoverHz.compareTo(b.crossoverHz));
  return out;
}

String _serializeMcompandBands(List<McompandBand> bands) {
  if (bands.isEmpty) return '';
  String fmtBand(McompandBand b) {
    // 3-point compressor curve: identity below threshold, slope
    // 1/ratio above. lavfi mcompand band grammar:
    //   attack,decay  knee  points  crossover  [delay  [init_vol  [gain]]]
    final outAtZero = b.thresholdDb + (0 - b.thresholdDb) / b.ratio;
    final pts = '-90/-90,'
        '${b.thresholdDb.toStringAsFixed(1)}/'
        '${b.thresholdDb.toStringAsFixed(1)},'
        '0/${outAtZero.toStringAsFixed(1)}';
    final tail = b.makeupDb.abs() > 1e-3
        // Need to fill in delay + init_vol with neutral defaults to
        // reach the gain field at position 6.
        ? ' 0 0 ${b.makeupDb.toStringAsFixed(1)}'
        : '';
    return '${b.attackSeconds.toStringAsFixed(4)},'
        '${b.releaseSeconds.toStringAsFixed(3)} '
        '${b.kneeDb.toStringAsFixed(1)} '
        '$pts ${b.crossoverHz.toStringAsFixed(0)}$tail';
  }

  final sorted = [...bands]
    ..sort((a, b) => a.crossoverHz.compareTo(b.crossoverHz));
  return sorted.map(fmtBand).join(' | ');
}

// ── superequalizer ───────────────────────────────────────────────────────────

/// 18 fixed band centre frequencies of the lavfi `superequalizer`,
/// in Hz, lows-to-highs in declaration order. The frequencies are
/// hard-coded inside `af_superequalizer.c` and are not configurable —
/// only the per-band gain is.
const List<double> kSuperequalizerFrequencies = [
  65,
  92,
  131,
  185,
  262,
  370,
  523,
  740,
  1047,
  1480,
  2093,
  2960,
  4186,
  5920,
  8372,
  11840,
  16744,
  20000,
];

/// Number of bands the `superequalizer` filter exposes — fixed by
/// the underlying ISO half-octave grid.
const int kSuperequalizerBandCount = 18;

/// Default linear gain for an unmodified band (1.0 = unity, no
/// change to that frequency's level).
const double kSuperequalizerUnityGain = 1.0;

/// Typed access over the digit-prefixed `1b`, `2b`, …, `18b`
/// parameters that lavfi's `superequalizer` packs into the bundle's
/// raw `params: Map<String, double>`.
///
/// Each band is a linear amplitude factor in `[0, 20]` where `1.0`
/// is unity. Display-side (UI sliders, knobs) typically convert to
/// dB via `20·log10(gain)` so the centerline of a slider sits at
/// 0 dB instead of an arbitrary linear point.
extension SuperequalizerBandsX on SuperequalizerSettings {
  /// 18 band gains, lows-to-highs. Bands the user hasn't touched
  /// read as [kSuperequalizerUnityGain] (the lavfi default), so the
  /// returned list is always exactly [kSuperequalizerBandCount]
  /// long regardless of how sparse the underlying [params] map is.
  List<double> get bands {
    return List.generate(
      kSuperequalizerBandCount,
      (i) => params['${i + 1}b'] ?? kSuperequalizerUnityGain,
      growable: false,
    );
  }

  /// Returns a copy whose [params] reflects [gains]. Bands sitting
  /// at unity are dropped from the map (lavfi treats absent bands as
  /// unity), keeping the serialised filter chain compact. Lists
  /// shorter than [kSuperequalizerBandCount] leave the trailing
  /// bands at unity; longer lists are truncated.
  SuperequalizerSettings withBands(List<double> gains) {
    final next = <String, double>{};
    final n = gains.length < kSuperequalizerBandCount
        ? gains.length
        : kSuperequalizerBandCount;
    for (var i = 0; i < n; i++) {
      final g = gains[i];
      if ((g - kSuperequalizerUnityGain).abs() > 1e-6) {
        next['${i + 1}b'] = g;
      }
    }
    return copyWith(params: next);
  }
}

// ── shared helpers ───────────────────────────────────────────────────────────

bool _listEq(List<double> a, List<double> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

List<double> _splitCsv(String src) {
  if (src.trim().isEmpty) return const [];
  final out = <double>[];
  for (final part in src.split('|')) {
    final v = double.tryParse(part.trim());
    if (v != null) out.add(v);
  }
  return out;
}
