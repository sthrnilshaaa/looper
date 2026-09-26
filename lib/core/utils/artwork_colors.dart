import 'dart:async';
import 'dart:collection';
import 'dart:isolate';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:material_color_utilities/material_color_utilities.dart';

/// Colors that actually appear in a piece of artwork, ranked the way
/// Android's wallpaper theming (Monet) ranks them: how much of the image a
/// hue covers, plus how colorful it is.
///
/// Unlike an RGB k-means with a handful of clusters, the image is quantized
/// into up to 128 perceptual (Lab) clusters first, so two distinct colors are
/// never averaged into a muddy in-between shade that isn't in the picture.
class ArtworkColors {
  /// The most prominent colorful color.
  final Color primary;

  /// The best-ranked color with a clearly different hue from [primary]; a
  /// lighter/darker shade of it when the artwork is basically one hue.
  final Color secondary;

  /// Up to four distinct colors, best first ([primary], [secondary], ...).
  final List<Color> accents;

  /// The color covering the largest area, whatever its chroma.
  final Color dominant;

  const ArtworkColors({
    required this.primary,
    required this.secondary,
    required this.accents,
    required this.dominant,
  });

  static final LinkedHashMap<Object, ArtworkColors> _cache = LinkedHashMap();
  static const int _cacheSize = 48;

  /// Extracts colors from [provider], cached by the provider's identity
  /// (e.g. a [FileImage] path). Returns null when the image can't be read.
  static Future<ArtworkColors?> fromProvider(ImageProvider provider) async {
    final Object key = provider;
    final ArtworkColors? hit = _cache.remove(key);
    if (hit != null) return _cache[key] = hit;

    final ui.Image image = await _load(
      ResizeImage(provider, width: 112, height: 112),
    );
    final ByteData? bytes;
    try {
      bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    } finally {
      image.dispose();
    }
    if (bytes == null) return null;

    final Uint8List rgba = bytes.buffer.asUint8List();
    final List<int>? argb = await Isolate.run(() => _extract(rgba));
    if (argb == null) return null;

    final ArtworkColors result = ArtworkColors(
      primary: Color(argb[0]),
      secondary: Color(argb[1]),
      dominant: Color(argb[2]),
      accents: [for (final c in argb.skip(3)) Color(c)],
    );
    _cache[key] = result;
    if (_cache.length > _cacheSize) _cache.remove(_cache.keys.first);
    return result;
  }

  static Future<ui.Image> _load(ImageProvider provider) {
    final Completer<ui.Image> completer = Completer();
    final ImageStream stream = provider.resolve(ImageConfiguration.empty);
    late final ImageStreamListener listener;
    listener = ImageStreamListener(
      (info, _) {
        stream.removeListener(listener);
        completer.complete(info.image.clone());
        info.dispose();
      },
      onError: (error, stack) {
        stream.removeListener(listener);
        completer.completeError(error, stack);
      },
    );
    stream.addListener(listener);
    return completer.future;
  }
}

/// Lifts [color] just enough to read as an accent on a black background,
/// keeping its hue and colorfulness (HCT tone, not HSL lightness, so the
/// color doesn't wash out towards pastel). Colors already light enough are
/// returned unchanged.
Color readableOnDark(Color color, {double minTone = 58}) {
  final Hct hct = Hct.fromInt(color.toARGB32());
  if (hct.tone >= minTone) return color;
  return Color(Hct.from(hct.hue, hct.chroma, minTone).toInt());
}

/// Returns `[primary, secondary, dominant, ...accents]` as ARGB ints, or null
/// for an empty image. Runs on a background isolate.
Future<List<int>?> _extract(Uint8List rgba) async {
  final List<int> pixels = [];
  for (int i = 0; i + 3 < rgba.length; i += 4) {
    if (rgba[i + 3] < 200) continue; // skip transparent
    pixels.add(0xFF000000 | (rgba[i] << 16) | (rgba[i + 1] << 8) | rgba[i + 2]);
  }
  if (pixels.isEmpty) return null;

  final QuantizerResult quantized = await QuantizerCelebi().quantize(
    pixels,
    128,
  );
  final Map<int, int> population = quantized.colorToCount;
  if (population.isEmpty) return null;
  final int total = population.values.fold(0, (a, b) => a + b);

  final int dominant = population.entries
      .reduce((a, b) => a.value >= b.value ? a : b)
      .key;

  // Share of the image per hue, spread over a 30 degree neighbourhood (the
  // same "excited proportion" Score uses), so a hue made of several close
  // clusters counts as one prominent color.
  final List<double> hueShare = List.filled(360, 0);
  final Map<int, Hct> hcts = {};
  for (final MapEntry<int, int> e in population.entries) {
    final Hct hct = Hct.fromInt(e.key);
    hcts[e.key] = hct;
    final double share = e.value / total;
    final int hue = hct.hue.floor();
    for (int d = -14; d < 16; d++) {
      hueShare[MathUtils.sanitizeDegreesInt(hue + d)] += share;
    }
  }

  // Score: mostly prominence, then colorfulness (Score's weights). Colors
  // under 1% of the image or with almost no chroma are not "the" colors.
  final List<(int, Hct, double)> ranked = [];
  for (final MapEntry<int, Hct> e in hcts.entries) {
    final Hct hct = e.value;
    final double share =
        hueShare[MathUtils.sanitizeDegreesInt(hct.hue.round())];
    if (hct.chroma < 8 || share <= 0.01) continue;
    if (hct.tone < 12 || hct.tone > 94) continue; // near black / white
    final double chromaWeight = hct.chroma < 48 ? 0.1 : 0.3;
    final double score = share * 100 * 0.7 + (hct.chroma - 48) * chromaWeight;
    ranked.add((e.key, hct, score));
  }
  ranked.sort((a, b) => b.$3.compareTo(a.$3));

  if (ranked.isEmpty) {
    // Greyscale artwork: its real colors are greys, so use them.
    final Hct d = Hct.fromInt(dominant);
    final int light = Hct.from(d.hue, d.chroma, 70).toInt();
    return [light, Hct.from(d.hue, d.chroma, 50).toInt(), dominant, light];
  }

  // Pick distinct hues, best first. Prefer a clearly different hue for the
  // second color, relaxing the gap before giving up.
  final List<Hct> chosen = [ranked.first.$2];
  for (final double gap in [40.0, 25.0, 15.0]) {
    for (final (_, Hct hct, _) in ranked) {
      if (chosen.length >= 4) break;
      final bool distinct = chosen.every(
        (c) => MathUtils.differenceDegrees(c.hue, hct.hue) >= gap,
      );
      if (distinct) chosen.add(hct);
    }
    if (chosen.length >= 2) break;
  }

  final Hct primary = chosen.first;
  final Hct secondary = chosen.length > 1
      ? chosen[1]
      // One-hue artwork: the most prominent clearly lighter/darker shade of
      // that hue that is in the image, else a tone step of the primary.
      : ranked
                .map((r) => r.$2)
                .where((h) => (h.tone - primary.tone).abs() >= 15)
                .firstOrNull ??
            Hct.from(
              primary.hue,
              primary.chroma,
              primary.tone > 55 ? primary.tone - 20 : primary.tone + 20,
            );

  final List<int> accents = [
    for (final h in chosen) h.toInt(),
    if (chosen.length < 2) secondary.toInt(),
  ];
  return [primary.toInt(), secondary.toInt(), dominant, ...accents];
}
