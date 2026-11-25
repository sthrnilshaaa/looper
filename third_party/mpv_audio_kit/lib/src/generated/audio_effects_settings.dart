// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license
// that can be found in the LICENSE file.
//
// AUTO-GENERATED: do not edit by hand.
//
// The descriptions of the filters and of their options in the
// documentation comments are FFmpeg's (doc/filters.texi and the option
// help of libavfilter, https://ffmpeg.org) and keep FFmpeg's licenses: the
// LGPL, version 2.1 or later (FFmpeg's LICENSE.md), and for the option help of
// deesser, arnndn and hdcd the MIT or BSD terms of their source files; the BSD
// 3-Clause license above covers the rest of this file.
// ignore_for_file: unnecessary_ignore, non_constant_identifier_names, constant_identifier_names, camel_case_types, curly_braces_in_flow_control_structures, prefer_adjacent_string_concatenation, prefer_interpolation_to_compose_strings

import 'dart:convert';

import 'package:meta/meta.dart';

import '../internals/unset_sentinel.dart';
import 'audio_effects.dart';

part 'audio_effects_settings/acompressor.part.dart';
part 'audio_effects_settings/acontrast.part.dart';
part 'audio_effects_settings/acrusher.part.dart';
part 'audio_effects_settings/adeclick.part.dart';
part 'audio_effects_settings/adeclip.part.dart';
part 'audio_effects_settings/adecorrelate.part.dart';
part 'audio_effects_settings/adelay.part.dart';
part 'audio_effects_settings/adenorm.part.dart';
part 'audio_effects_settings/aderivative.part.dart';
part 'audio_effects_settings/adrc.part.dart';
part 'audio_effects_settings/adynamicequalizer.part.dart';
part 'audio_effects_settings/adynamicsmooth.part.dart';
part 'audio_effects_settings/aecho.part.dart';
part 'audio_effects_settings/aemphasis.part.dart';
part 'audio_effects_settings/aeval.part.dart';
part 'audio_effects_settings/aexciter.part.dart';
part 'audio_effects_settings/afade.part.dart';
part 'audio_effects_settings/afftdn.part.dart';
part 'audio_effects_settings/afftfilt.part.dart';
part 'audio_effects_settings/aformat.part.dart';
part 'audio_effects_settings/afreqshift.part.dart';
part 'audio_effects_settings/afwtdn.part.dart';
part 'audio_effects_settings/agate.part.dart';
part 'audio_effects_settings/aiir.part.dart';
part 'audio_effects_settings/aintegral.part.dart';
part 'audio_effects_settings/alimiter.part.dart';
part 'audio_effects_settings/allpass.part.dart';
part 'audio_effects_settings/anequalizer.part.dart';
part 'audio_effects_settings/anlmdn.part.dart';
part 'audio_effects_settings/apad.part.dart';
part 'audio_effects_settings/aphaser.part.dart';
part 'audio_effects_settings/aphaseshift.part.dart';
part 'audio_effects_settings/apsyclip.part.dart';
part 'audio_effects_settings/apulsator.part.dart';
part 'audio_effects_settings/aresample.part.dart';
part 'audio_effects_settings/arnndn.part.dart';
part 'audio_effects_settings/asetrate.part.dart';
part 'audio_effects_settings/asoftclip.part.dart';
part 'audio_effects_settings/asubboost.part.dart';
part 'audio_effects_settings/asubcut.part.dart';
part 'audio_effects_settings/asupercut.part.dart';
part 'audio_effects_settings/asuperpass.part.dart';
part 'audio_effects_settings/asuperstop.part.dart';
part 'audio_effects_settings/atempo.part.dart';
part 'audio_effects_settings/atilt.part.dart';
part 'audio_effects_settings/bandpass.part.dart';
part 'audio_effects_settings/bandreject.part.dart';
part 'audio_effects_settings/bass.part.dart';
part 'audio_effects_settings/biquad.part.dart';
part 'audio_effects_settings/channelmap.part.dart';
part 'audio_effects_settings/chorus.part.dart';
part 'audio_effects_settings/compand.part.dart';
part 'audio_effects_settings/compensationdelay.part.dart';
part 'audio_effects_settings/crossfeed.part.dart';
part 'audio_effects_settings/crystalizer.part.dart';
part 'audio_effects_settings/dcshift.part.dart';
part 'audio_effects_settings/deesser.part.dart';
part 'audio_effects_settings/dialoguenhance.part.dart';
part 'audio_effects_settings/drmeter.part.dart';
part 'audio_effects_settings/dynaudnorm.part.dart';
part 'audio_effects_settings/earwax.part.dart';
part 'audio_effects_settings/ebur128.part.dart';
part 'audio_effects_settings/equalizer.part.dart';
part 'audio_effects_settings/extrastereo.part.dart';
part 'audio_effects_settings/firequalizer.part.dart';
part 'audio_effects_settings/flanger.part.dart';
part 'audio_effects_settings/haas.part.dart';
part 'audio_effects_settings/hdcd.part.dart';
part 'audio_effects_settings/highpass.part.dart';
part 'audio_effects_settings/highshelf.part.dart';
part 'audio_effects_settings/loudnorm.part.dart';
part 'audio_effects_settings/lowpass.part.dart';
part 'audio_effects_settings/lowshelf.part.dart';
part 'audio_effects_settings/mcompand.part.dart';
part 'audio_effects_settings/pan.part.dart';
part 'audio_effects_settings/silenceremove.part.dart';
part 'audio_effects_settings/speechnorm.part.dart';
part 'audio_effects_settings/stereotools.part.dart';
part 'audio_effects_settings/stereowiden.part.dart';
part 'audio_effects_settings/superequalizer.part.dart';
part 'audio_effects_settings/surround.part.dart';
part 'audio_effects_settings/tiltshelf.part.dart';
part 'audio_effects_settings/treble.part.dart';
part 'audio_effects_settings/tremolo.part.dart';
part 'audio_effects_settings/vibrato.part.dart';
part 'audio_effects_settings/virtualbass.part.dart';

// Collection equality helpers used by the generated `==`. Kept
// inline to avoid a transitive `package:collection` dependency.
bool _setEq<T>(Set<T> a, Set<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (final e in a) {
    if (!b.contains(e)) return false;
  }
  return true;
}

bool _mapEq<K, V>(Map<K, V> a, Map<K, V> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (final entry in a.entries) {
    if (!b.containsKey(entry.key) || b[entry.key] != entry.value) {
      return false;
    }
  }
  return true;
}

/// Wire-format a double for the lavfi af-chain. Uses 3-decimal
/// fixed-point when that is exact, 6 decimals when it is not (so
/// `0.0014` keeps its digits), and an exponential for tiny values
/// that would otherwise round to `0.000` (e.g. `1e-6` for
/// `asoftclip.threshold`'s minimum).
/// `toStringAsExponential()` is deterministic across runtimes
/// (Dart's `toString()` chooses between decimal and exponential
/// based on magnitude and platform), and mpv's AVOption parser
/// accepts exponential floats natively.
String _wireDouble(double v) {
  final fixed = v.toStringAsFixed(3);
  if (v == 0 || double.parse(fixed) == v) return fixed;
  if (v.abs() < 0.001) return v.toStringAsExponential();
  return v.toStringAsFixed(6);
}

/// Wire-format a string option. `[...]` keeps `:` `=` `,` `|` in the
/// value, but ends at the `]` that balances the first `[`: a value
/// with a bracket takes mpv's `%len%` form instead, its length in
/// UTF-8 bytes, which holds any text.
String _wireString(String v) {
  if (!v.contains('[') && !v.contains(']')) return '[' + v + ']';
  return '%' + utf8.encode(v).length.toString() + '%' + v;
}

final RegExp _paramKey = RegExp(r'^[A-Za-z0-9_-]+$');

/// The key of a raw `params` entry, an FFmpeg option name: a `:` or a
/// `,` in it would add options or filters to the chain.
String _wireKey(String k) {
  if (_paramKey.hasMatch(k)) return k;
  throw ArgumentError.value(k, 'params', 'not an option name');
}

/// Wire-format a duration option, in seconds: 3 decimals when that is
/// exact, 6 when it is not, which holds every microsecond. Never an
/// exponent: duration options go through av_parse_time, which refuses
/// one.
String _wireDuration(Duration d) {
  final v = d.inMicroseconds / 1e6;
  final fixed = v.toStringAsFixed(3);
  return double.parse(fixed) == v ? fixed : v.toStringAsFixed(6);
}

/// One stage of the audio effects chain: an entry of the ordered list given
/// to `Player.setAudioEffects`. Stages run in list order, and the same
/// filter may appear more than once.
///
/// Every typed `XxxEffect` extends it; [RawAudioEffect] carries a lavfi
/// entry written by hand.
///
/// {@category Effects}
sealed class AudioEffect {
  const AudioEffect();

  /// Whether this stage is applied. `false` keeps it in the list, with
  /// its settings, without inserting it in the chain.
  bool get enabled;

  /// The lavfi filter this stage runs, e.g. `equalizer`.
  String get filterName;

  /// The filter this stage runs, as a typed identifier (`null` for a
  /// [RawAudioEffect]).
  AudioFilter? get filter;

  /// The chain entry for this stage.
  String toFilterString();

  /// Runtime-tunable option diff against [prev], the same filter one
  /// step earlier: the `(option, wire value)` pairs the live graph can
  /// apply via `af-command`, or `null` when the change needs a rebuild.
  List<(String, String)>? _runtimeDiff(covariant AudioEffect prev) =>
      this == prev ? const [] : null;
}

/// A chain stage written as a raw lavfi entry, for filters or option
/// forms the typed effects do not cover, e.g.
/// `RawAudioEffect('lavfi-aeval=val(0)*0.5|val(1)*0.5')`.
///
/// It is inserted as is, without a chain label, so it is never updated
/// live: a change to it rebuilds the chain.
///
/// {@category Effects}
final class RawAudioEffect extends AudioEffect {
  /// Creates a raw chain stage from [entry].
  const RawAudioEffect(this.entry, {this.enabled = true});

  /// The lavfi entry, inserted verbatim.
  final String entry;

  @override
  final bool enabled;

  @override
  String get filterName {
    final start = entry.startsWith('lavfi-') ? 'lavfi-'.length : 0;
    final end = entry.indexOf('=', start);
    return entry.substring(start, end < 0 ? entry.length : end);
  }

  @override
  AudioFilter? get filter => null;

  @override
  String toFilterString() => entry;

  /// Returns a copy with the given fields replaced.
  RawAudioEffect copyWith({String? entry, bool? enabled}) =>
      RawAudioEffect(entry ?? this.entry, enabled: enabled ?? this.enabled);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RawAudioEffect &&
          other.entry == entry &&
          other.enabled == enabled);

  @override
  int get hashCode => Object.hash(entry, enabled);

  @override
  String toString() => 'RawAudioEffect($entry, enabled: $enabled)';
}

/// One incremental `af-command` update produced by [audioEffectsDiff]:
/// applies [option] = [value] to the live chain stage labelled [label]
/// (an instance of the ffmpeg filter [filterName]).
typedef AfCommand = ({
  String label,
  String option,
  String value,
  String filterName,
});

/// The chain label of the [instance]th [filterName] stage in a list
/// (0 for the first), e.g. `aek_equalizer_1`.
@internal
String audioEffectLabel(String filterName, int instance) =>
    'aek_${filterName}_$instance';

/// The chain labels of [effects], in order; `null` for raw stages,
/// which carry none.
@internal
List<String?> audioEffectLabels(List<AudioEffect> effects) {
  final seen = <String, int>{};
  return [
    for (final e in effects)
      if (e is RawAudioEffect)
        null
      else
        audioEffectLabel(
          e.filterName,
          seen.update(e.filterName, (i) => i + 1, ifAbsent: () => 0),
        ),
  ];
}

/// The `af` chain for [effects]: every enabled stage in list order,
/// typed stages under their [audioEffectLabels]. A blank raw stage is
/// skipped, since an empty chain entry is a syntax error for mpv.
@internal
String audioEffectsChain(List<AudioEffect> effects) {
  final labels = audioEffectLabels(effects);
  return [
    for (var i = 0; i < effects.length; i++)
      if (effects[i].enabled && effects[i].toFilterString().trim().isNotEmpty)
        labels[i] == null
            ? effects[i].toFilterString()
            : '@${labels[i]}:${effects[i].toFilterString()}',
  ].join(',');
}

/// The incremental `af-command` updates that turn the live chain built
/// from [prev] into the one for [next], or `null` when only a rebuild
/// can: a stage was added, removed, reordered, enabled or disabled, a
/// non-runtime-tunable option changed, or the filter takes no live
/// commands. Empty when the two lists build the same chain.
@internal
List<AfCommand>? audioEffectsDiff(
  List<AudioEffect> prev,
  List<AudioEffect> next,
) {
  if (prev.length != next.length) return null;
  final labels = audioEffectLabels(next);
  final out = <AfCommand>[];
  for (var i = 0; i < next.length; i++) {
    final a = prev[i];
    final b = next[i];
    if (identical(a, b)) continue;
    if (a.runtimeType != b.runtimeType || a.enabled != b.enabled) return null;
    if (b is RawAudioEffect) {
      if (a != b) return null;
      continue;
    }
    if (!b.enabled) continue;
    final d = b._runtimeDiff(a);
    if (d == null) return null;
    for (final (option, value) in d) {
      out.add((
        label: labels[i]!,
        option: option,
        value: value,
        filterName: b.filterName,
      ));
    }
  }
  return out;
}

/// The keys of the raw `params` of [effect] that are no option name,
/// none for a stage without `params`. They are checked before the
/// chain is built, so a refused key never reaches the state.
@internal
Iterable<String> audioEffectBadParamKeys(AudioEffect effect) {
  final keys = switch (effect) {
    CompandEffect(:final params) => params.keys,
    SuperequalizerEffect(:final params) => params.keys,
    _ => const <String>[],
  };
  return keys.where((k) => !_paramKey.hasMatch(k));
}
