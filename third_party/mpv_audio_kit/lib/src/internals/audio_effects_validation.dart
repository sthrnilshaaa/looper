// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

/// The check the effects chain passes before it reaches mpv.
///
/// A few lavfi filters accept values their own checks miss, then read or
/// write out of their buffers with them, or turn the audio to NaN. Those
/// values are refused here, with the rest of the range the filter checks
/// where it has one. Anything else a filter rejects is left to the
/// filter, which fails the chain when mpv builds it. Lists are read the
/// way the filter reads them, so a string the filter takes as intended is
/// never refused.
library;

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:meta/meta.dart';

import '../generated/audio_effects_settings.dart';

/// Throws [ArgumentError] when an enabled stage of [effects] holds a value
/// its lavfi filter accepts and then reads or writes out of its buffers
/// with, or turns the audio to NaN with, or a raw `params` key that is no
/// option name. The error names the stage by its index, e.g.
/// `effects[1].decays`.
@internal
void validateAudioEffects(List<AudioEffect> effects) {
  for (var i = 0; i < effects.length; i++) {
    final e = effects[i];
    if (!e.enabled) continue;
    // The chain would refuse it too, but only once the state holds it.
    for (final key in audioEffectBadParamKeys(e)) {
      throw ArgumentError.value(
        key,
        'effects[$i].params',
        'not an option name',
      );
    }
    switch (e) {
      case AechoEffect():
        _checkAecho(e, 'effects[$i]');
      case AnequalizerEffect():
        _checkAnequalizer(e, 'effects[$i]');
      case ChorusEffect():
        _checkChorus(e, 'effects[$i]');
      case CompandEffect():
        _checkCompand(e, 'effects[$i]');
      case McompandEffect():
        _checkMcompand(e, 'effects[$i]');
      case PanEffect():
        _checkPan(e, 'effects[$i]');
      default:
    }
  }
}

/// aecho checks each delay and decay with comparisons that NaN passes,
/// then indexes its delay line with the delay converted to an int.
void _checkAecho(AechoEffect e, String stage) {
  _checkRange(
    e.delays,
    '$stage.delays',
    _scanFloats(e.delays),
    (v) => v > 0 && v <= 90000,
    'aecho delays must be above 0 and at most 90000 ms',
  );
  _checkRange(
    e.decays,
    '$stage.decays',
    _scanFloats(e.decays),
    (v) => v > 0 && v <= 1,
    'aecho decays must be above 0 and at most 1',
  );
}

/// anequalizer checks a band's frequency with comparisons that NaN
/// passes, and its width and gain not at all: a NaN or an infinity turns
/// the band's coefficients, and so the audio, to NaN.
void _checkAnequalizer(AnequalizerEffect e, String stage) {
  for (final band in _strtok(e.params, '|')) {
    _checkRange(
      e.params,
      '$stage.params',
      [
        for (final key in const ['f=', 'w=', 'g='])
          if (band.indexOf(key) case final at when at >= 0)
            ?_scanDouble(band.substring(at + key.length)),
      ],
      (_) => true,
      'anequalizer band values must be finite',
    );
  }
}

/// chorus counts each list with av_strtok and sscanf, then checks the
/// counts with `&&` where it means `||`: lists of different lengths pass
/// and the filter reads past the shorter ones. Every list needs as many
/// values as delays, which sets the number of voices. Nothing checks the
/// values either: a negative or NaN delay or depth, or a speed that is 0
/// or above the sample rate, moves the modulation index out of the delay
/// line. Speeds are capped at 100 Hz, far above a chorus and below any
/// sample rate.
void _checkChorus(ChorusEffect e, String stage) {
  final lists = [
    ('delays', e.delays, (double v) => v >= 0, 'must be 0 ms or more'),
    ('decays', e.decays, (double v) => true, 'must be finite'),
    (
      'speeds',
      e.speeds,
      (double v) => v > 0 && v <= 100,
      'must be above 0 and at most 100 Hz',
    ),
    ('depths', e.depths, (double v) => v >= 0, 'must be 0 ms or more'),
  ];
  final voices = _scanList(e.delays, '|').length;
  for (final (name, list, _, _) in lists) {
    final n = _scanList(list, '|').length;
    if (n != voices) {
      throw ArgumentError.value(
        list,
        '$stage.$name',
        'chorus needs one value per voice in delays, decays, speeds and '
            'depths: $voices delays, $n $name',
      );
    }
  }
  for (final (name, list, ok, domain) in lists) {
    _checkRange(
      list,
      '$stage.$name',
      _scanFloats(list),
      ok,
      'chorus $name $domain',
    );
  }
}

/// compand reads one attack and one decay per channel, splitting on
/// spaces and `|`, and counts those sscanf reads a number from. When it
/// reads none from either list the counts match at 0, and it copies
/// channel -1 into the others. A mono source reads only the first item,
/// so the first item of one list needs a number. A list with no item at
/// all is refused by compand itself.
void _checkCompand(CompandEffect e, String stage) {
  final attacks = _strtok(e.attacks, ' |');
  final decays = _strtok(e.decays, ' |');
  if (attacks.isEmpty || decays.isEmpty) return;
  if (_scanDouble(attacks.first) == null && _scanDouble(decays.first) == null) {
    throw ArgumentError.value(
      e.attacks,
      '$stage.attacks',
      'compand needs a number first in attacks or in decays, not '
          '${attacks.first} and ${decays.first}',
    );
  }
}

/// mcompand counts the commas of a band's attack and decay rates, checks
/// the count is even, then reads the pairs with av_strtok, which skips
/// empty items: with an empty one it runs out and hands NULL to sscanf.
/// Its crossover frequency check is false for NaN, which turns the band
/// to NaN.
void _checkMcompand(McompandEffect e, String stage) {
  for (final band in _strtok(e.args, '|')) {
    final fields = _strtok(band, ' ');
    if (fields.isEmpty) continue;
    final rates = fields.first;
    final count = ','.allMatches(rates).length + 1;
    if (count.isEven && _strtok(rates, ',').length < count) {
      throw ArgumentError.value(
        e.args,
        '$stage.args',
        'mcompand has an empty attack or decay in $rates',
      );
    }
    if (fields.length > 3) {
      _checkRange(
        e.args,
        '$stage.args',
        [?_scanDouble(fields[3])],
        (_) => true,
        'mcompand crossover frequencies must be finite',
      );
    }
  }
}

/// pan maps an input channel name to its id with av_channel_from_string
/// and indexes 64-slot arrays with it, bounded for `cN` but not for a
/// name: UNK, UNSD and any name starting with AMBI have ids from 0x200 up.
/// The input side of each output channel is read the way pan reads it: a
/// gain sscanf takes, with an optional `*`, then up to 7 capitals or
/// `cN`, then `+` or `-` and the next channel. The layout and the output
/// channel are mapped through the layout, which bounds them.
void _checkPan(PanEffect e, String stage) {
  for (final spec in _strtok(e.args, '|').skip(1)) {
    var i = spec.indexOf(_panAssign);
    if (i < 0) continue;
    i++;
    while (true) {
      final gain = _cNumber.matchAsPrefix(spec, i);
      if (gain != null) {
        i = gain.end;
        final star = _skipSpaces(spec, i);
        if (star < spec.length && spec[star] == '*') i = star + 1;
      }
      i = _skipSpaces(spec, i);
      final name = _panName.matchAsPrefix(spec, i)?.group(0);
      if (name != null) {
        if (name == 'UNK' || name == 'UNSD' || name.startsWith('AMBI')) {
          throw ArgumentError.value(
            e.args,
            '$stage.args',
            'pan has no input slot for channel $name',
          );
        }
        i += name.length;
      } else {
        final index = _panIndex.matchAsPrefix(spec, i);
        if (index == null) break;
        i = index.end;
      }
      i = _skipSpaces(spec, i);
      if (i == spec.length || (spec[i] != '+' && spec[i] != '-')) break;
      i++;
    }
  }
}

final RegExp _panAssign = RegExp('[=<]');
final RegExp _panName = RegExp('[A-Z]{1,7}');
final RegExp _panIndex = RegExp(r'c[ \t\n\v\f\r]*[+-]?\d+');

/// The index of the first character of [s] from [i] on that is not white
/// space, as C's isspace sees it.
int _skipSpaces(String s, int i) {
  while (i < s.length && ' \t\n\v\f\r'.contains(s[i])) {
    i++;
  }
  return i;
}

/// Throws when a value of [values], read from [list], is not finite or
/// fails [ok].
void _checkRange(
  String list,
  String name,
  List<double> values,
  bool Function(double) ok,
  String rule,
) {
  for (final v in values) {
    if (!v.isFinite || !ok(v)) {
      throw ArgumentError.value(list, name, '$rule, not $v');
    }
  }
}

/// [_scanList] with `|` for a filter that stores its values as C floats,
/// which [_float] rounds them to.
List<double> _scanFloats(String list) => [
  for (final v in _scanList(list, '|')) _float(v),
];

final Float32List _f32 = Float32List(1);

/// [v] rounded to a C float, as sscanf's `%f` stores it.
double _float(double v) {
  _f32[0] = v;
  return _f32[0];
}

/// The values lavfi reads from [list]: the items av_strtok splits on any
/// of [delimiters], skipping empty ones, that sscanf reads a number from.
List<double> _scanList(String list, String delimiters) => [
  for (final item in _strtok(list, delimiters)) ?_scanDouble(item),
];

/// The items av_strtok returns for [s]: runs of characters that are not
/// in [delimiters]. Empty items are skipped.
List<String> _strtok(String s, String delimiters) {
  final out = <String>[];
  var start = -1;
  for (var i = 0; i <= s.length; i++) {
    final end = i == s.length || delimiters.contains(s[i]);
    if (end) {
      if (start >= 0) out.add(s.substring(start, i));
      start = -1;
    } else if (start < 0) {
      start = i;
    }
  }
  return out;
}

/// The number sscanf's `%lf` reads at the start of [item], or `null` when
/// it reads none: leading white space, then a decimal or hexadecimal
/// number, `inf`, `infinity` or `nan` in any case. What follows the
/// number is ignored.
double? _scanDouble(String item) {
  final m = _cNumber.matchAsPrefix(item);
  if (m == null) return null;
  final negative = m.group(1) == '-';
  final double v;
  if (m.group(3) case final decimal?) {
    v = double.parse(decimal);
  } else if (m.group(2) case final hex?) {
    v = _hexValue(hex.substring(2));
  } else if (m.group(4)!.toLowerCase().startsWith('nan')) {
    return double.nan;
  } else {
    v = double.infinity;
  }
  return negative ? -v : v;
}

/// The value of a C hexadecimal float, `0x` left out: hex digits with an
/// optional point, then an optional binary exponent.
double _hexValue(String hex) {
  final p = hex.toLowerCase().indexOf('p');
  final mantissa = p < 0 ? hex : hex.substring(0, p);
  final exponent = p < 0 ? 0 : int.tryParse(hex.substring(p + 1)) ?? 99999;
  final point = mantissa.indexOf('.');
  var v = 0.0;
  for (final digit in mantissa.replaceAll('.', '').split('')) {
    v = v * 16 + int.parse(digit, radix: 16);
  }
  if (v == 0) return 0;
  final fraction = point < 0 ? 0 : mantissa.length - point - 1;
  return v * math.pow(2, exponent.clamp(-99999, 99999) - 4 * fraction);
}

final RegExp _cNumber = RegExp(
  r'[ \t\n\v\f\r]*([+-]?)'
  r'(?:(0x(?:[0-9a-f]+\.?[0-9a-f]*|\.[0-9a-f]+)(?:p[+-]?\d+)?)|'
  r'((?:\d+\.?\d*|\.\d+)(?:e[+-]?\d+)?)|'
  r'(inf(?:inity)?|nan(?:\([0-9a-z_]*\))?))',
  caseSensitive: false,
);
