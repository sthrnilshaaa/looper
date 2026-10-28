import 'dart:async';
import 'dart:collection';
import 'dart:isolate';
import 'dart:math' as math;
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

/// The active lyric line's color: [readableOnDark], but guaranteed to stand
/// out from the inactive lines (white at ~35% alpha over a dark background).
///
/// [intensity] (0..1, the user's slider) makes the color more vibrant: it
/// pushes chroma towards the most saturated version of the same hue at the
/// same tone, so the color keeps its look instead of washing out to white.
/// Colors with no real hue (chroma under 4) have nothing to saturate.
///
/// A (still) near-grey color only lifted to tone 58 ends up as bright as the
/// inactive lines, so it's pushed towards a tinted white instead; the fade
/// between chroma 4 and 10 avoids a visible jump between songs. Everything
/// more colorful than that keeps its tone.
Color lyricsActiveColor(Color color, {double intensity = 0}) {
  final double t = intensity.isNaN ? 0.35 : intensity.clamp(0.0, 1.0);
  Hct hct = Hct.fromInt(readableOnDark(color).toARGB32());
  if (t > 0 && hct.chroma >= 4) {
    // Hct.from clamps to the most chroma this hue/tone can show on screen;
    // scale towards that so the whole slider range does something.
    final double maxChroma = Hct.from(hct.hue, 200, hct.tone).chroma;
    if (maxChroma > hct.chroma) {
      hct = Hct.from(
        hct.hue,
        hct.chroma + (maxChroma - hct.chroma) * t,
        hct.tone,
      );
    }
  }
  final double greyness = ((10 - hct.chroma) / 6).clamp(0.0, 1.0);
  final double minTone = 58 + (88 - 58) * greyness;
  if (hct.tone < minTone) {
    hct = Hct.from(hct.hue, hct.chroma, minTone);
  }
  return Color(hct.toInt());
}

/// The softer active lyric line color: [color] blended towards white by
/// lifting its tone (hue kept), for when the pure accent isn't wanted.
/// [intensity] (0..1, the user's slider) brings back more of the color:
/// 0 is a light tint (tone 90), 1 stops at tone 70.
Color lyricsSoftActiveColor(Color color, {double intensity = 0}) {
  final double t = intensity.isNaN ? 0.35 : intensity.clamp(0.0, 1.0);
  final Hct hct = Hct.fromInt(readableOnDark(color).toARGB32());
  final double tone = 90 - 20 * t;
  if (hct.tone >= tone) return color;
  return Color(Hct.from(hct.hue, hct.chroma, tone).toInt());
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
  // clusters counts as one prominent color. Only clusters with real color
  // count: near-grey/near-black areas have a hue too, and letting them in
  // made e.g. a small red title "own" all the dark brown around it.
  final List<double> hueShare = List.filled(360, 0);
  final Map<int, Hct> hcts = {};
  for (final MapEntry<int, int> e in population.entries) {
    final Hct hct = Hct.fromInt(e.key);
    hcts[e.key] = hct;
    if (hct.chroma < 10 || hct.tone < 8) continue;
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

  // Pick distinct colors, best first: clearly different hues first
  // (relaxing the gap), and only then fill the remaining slots with colors
  // that share a neighbouring hue but are much darker or lighter. A dark
  // olive-green wall and a bright gold sit close on the hue wheel yet read
  // as different colors - hue alone threw the wall away as a duplicate of
  // the gold - but such shades must never displace a real second hue.
  final List<Hct> chosen = [ranked.first.$2];
  void fill(bool Function(Hct a, Hct b) distinct) {
    for (final (_, Hct hct, _) in ranked) {
      if (chosen.length >= 4) return;
      if (chosen.every((c) => distinct(c, hct))) chosen.add(hct);
    }
  }

  double hueGap(Hct a, Hct b) => MathUtils.differenceDegrees(a.hue, b.hue);
  fill((a, b) => hueGap(a, b) >= 40);
  if (chosen.length < 2) fill((a, b) => hueGap(a, b) >= 25);
  fill(
    (a, b) =>
        hueGap(a, b) >= 25 ||
        (hueGap(a, b) >= 8 && (a.tone - b.tone).abs() >= 22),
  );
  if (chosen.length < 2) fill((a, b) => hueGap(a, b) >= 15);

  // Order the extra colors (3rd, 4th) by how different they are from the
  // first two, so the 3rd slot - the one the ambient background uses -
  // holds the most distinct remaining color (a dark green wall) rather than
  // a near-twin of the 2nd (an orange next to a gold).
  if (chosen.length > 3) {
    double distanceTo(Hct a, Hct b) =>
        hueGap(a, b) + (a.tone - b.tone).abs() * 1.5;
    double separation(Hct h) =>
        [chosen[0], chosen[1]].map((c) => distanceTo(c, h)).reduce(math.min);
    final List<Hct> extra = chosen.sublist(2)
      ..sort((a, b) => separation(b).compareTo(separation(a)));
    chosen
      ..removeRange(2, chosen.length)
      ..addAll(extra);
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
