import 'dart:core';

/// One timed word - or one syllable of a word: syllables of the same word
/// carry no whitespace between them ("e" + "nough "), a word-final one ends
/// with a space.
class LyricWord {
  final Duration startTime;
  final Duration endTime;
  final String text;

  const LyricWord({
    required this.startTime,
    required this.endTime,
    required this.text,
  });
}

class LyricLine {
  final Duration startTime;
  final Duration endTime;
  final String text;

  /// Word/syllable timing, when the source had it (enhanced LRC, e.g. from
  /// lrc.red or LyricsPlus). Empty for plain line-synced lyrics.
  final List<LyricWord> words;

  /// Background vocals sung under this line ("[bg:...]" in the LRC).
  final List<LyricWord> backgroundWords;

  /// Sung by the duet partner ("[opp]" in the LRC).
  final bool isOppositeSide;

  /// Other lines that share this line's timestamp in the LRC - the
  /// translation or romanization of a multilingual file. Shown under
  /// [text] as one block that is current, scrolls and seeks together.
  final List<String> extraLines;

  LyricLine({
    required this.startTime,
    required this.endTime,
    required this.text,
    this.words = const [],
    this.backgroundWords = const [],
    this.isOppositeSide = false,
    this.extraLines = const [],
    String backgroundText = '',
  }) : backgroundText = backgroundText.isNotEmpty
           ? backgroundText
           : backgroundWords.map((w) => w.text).join().trim();

  bool get hasWordTiming => words.isNotEmpty;

  /// [text] and its [extraLines], one per line - for places that show or
  /// share the whole block as plain text.
  String get fullText =>
      extraLines.isEmpty ? text : [text, ...extraLines].join('\n');

  /// A word-timed line whose first word starts this soon after the previous
  /// line's last word ends is sung in the same breath: see [pairHeads].
  static const Duration continuedLineGap = Duration(milliseconds: 70);

  /// For every line, the index of the line it is shown with: its own, or
  /// the previous line's when it carries straight on from it (both
  /// word-timed, same singer, less than [continuedLineGap] apart). Such a
  /// pair is current together - the first line stays lit and the list
  /// doesn't move while the second is sung.
  ///
  /// Never more than two lines, and the two lines after a pair stay on
  /// their own, so a song sung without pauses doesn't turn into pairs
  /// throughout.
  static List<int> pairHeads(List<LyricLine> lines) =>
      _pairCache[lines] ??= _pairHeads(lines);

  static final Expando<List<int>> _pairCache = Expando();

  static List<int> _pairHeads(List<LyricLine> lines) {
    final heads = List<int>.generate(lines.length, (i) => i);
    for (var i = 1; i < lines.length; i++) {
      final first = lines[i - 1];
      final second = lines[i];
      if (!first.hasWordTiming ||
          !second.hasWordTiming ||
          first.isOppositeSide != second.isOppositeSide) {
        continue;
      }
      final gap = second.words.first.startTime - first.words.last.endTime;
      if (gap >= continuedLineGap) continue;
      heads[i] = i - 1;
      // The next two lines are single; the one after may start a pair.
      i += 3;
    }
    return heads;
  }

  /// A word: letters up to (and including) any trailing punctuation and
  /// whitespace - so a comma ends a word even with no space after it.
  static final RegExp _wordToken = RegExp(
    '[^\\s$_punctuation]+[$_punctuation]*\\s*|[$_punctuation]+\\s*',
  );
  static const String _punctuation = r',.!?;:…、，。！？；：';
  static final RegExp _endsWithStop = RegExp(r'[.!?…。！？]\s*$');
  static final RegExp _endsWithComma = RegExp(r'[,;:、，；：]\s*$');

  /// Whether a word ends after the timed piece [text]: at whitespace or at
  /// punctuation - "parvati,parvati" is two sung words even without a
  /// space, while syllables of one word ("e" + "nough") keep going.
  static bool endsWord(String text) =>
      text.endsWith(' ') ||
      text.endsWith('\u3000') ||
      _endsWithStop.hasMatch(text) ||
      _endsWithComma.hasMatch(text);

  /// Splits timed pieces that hold several punctuation-separated words
  /// ("parvati,parvati,parvati" timed as one span) into one piece per word,
  /// sharing the span's time by length. Pieces without internal
  /// punctuation are returned untouched.
  static List<LyricWord> splitAtPunctuation(List<LyricWord> words) =>
      _splitCache[words] ??= _splitAtPunctuation(words);

  /// The active line re-renders every frame; its word lists are stable
  /// objects, so each is only split once.
  static final Expando<List<LyricWord>> _splitCache = Expando();

  static List<LyricWord> _splitAtPunctuation(List<LyricWord> words) {
    List<LyricWord>? out;
    for (var i = 0; i < words.length; i++) {
      final w = words[i];
      final parts = _wordToken
          .allMatches(w.text)
          .map((m) => m.group(0)!)
          .toList();
      if (parts.length < 2 || parts.join() != w.text) {
        out?.add(w);
        continue;
      }
      out ??= words.sublist(0, i);
      final total = parts.fold<int>(0, (n, p) => n + p.trim().length);
      final span = w.endTime - w.startTime;
      var cursor = w.startTime;
      for (var j = 0; j < parts.length; j++) {
        final end = j == parts.length - 1
            ? w.endTime
            : cursor +
                  span * (parts[j].trim().length / (total == 0 ? 1 : total));
        out.add(LyricWord(startTime: cursor, endTime: end, text: parts[j]));
        cursor = end;
      }
    }
    return out ?? words;
  }

  /// Background vocal text; may exist without timing (`[bg:]` with no
  /// `[w:]`), in which case it's shown but not animated.
  final String backgroundText;

  /// How much of [words]' text has been sung at [position], from 0 to 1,
  /// weighted by characters - so a gradient wipe driven by it moves at the
  /// singer's pace through each syllable, and holds still in the pauses
  /// between words instead of drifting on.
  static double sungFraction(List<LyricWord> words, Duration position) {
    if (words.isEmpty) return 0;
    final total = words.fold<int>(0, (sum, w) => sum + w.text.length);
    if (total == 0) return 0;

    var before = 0;
    for (final w in words) {
      if (position < w.startTime) break;
      final length = w.text.length;
      if (position >= w.endTime) {
        before += length;
        continue;
      }
      final span = (w.endTime - w.startTime).inMicroseconds;
      final into = span <= 0
          ? 1.0
          : (position - w.startTime).inMicroseconds / span;
      return ((before + length * into) / total).clamp(0.0, 1.0);
    }
    return (before / total).clamp(0.0, 1.0);
  }
}

class _RawLine {
  Duration start;
  final String text;
  List<_RawWord> words;
  bool opposite = false;
  String backgroundText = '';
  List<_RawWord> background = const [];

  /// Plain lines at the same timestamp, folded into this one.
  final List<String> extras = [];

  /// Whether this line is only text: nothing that needs a line of its own
  /// (word timing, background vocals, the duet partner's side).
  bool get isPlain =>
      words.isEmpty &&
      background.isEmpty &&
      backgroundText.isEmpty &&
      !opposite;

  /// Where the next `[w:]` line's timing goes: this line's own text, or
  /// its background vocals once a `[bg:]` line has been seen.
  bool timingTargetsBackground = false;

  _RawLine(this.start, this.text, this.words);
}

class _RawWord {
  final Duration start;

  /// Null for a trailing word with no closing time tag; filled in from the
  /// line's end once that's known.
  final Duration? end;
  final String text;

  _RawWord(this.start, this.end, this.text);
}

class LrcParser {
  static final RegExp _lineTag = RegExp(
    r'\[(\d{1,3}):(\d{2})(?:[:\.](\d{2,3}))?\](.*)',
  );
  static final RegExp _wordTag = RegExp(
    r'<(\d{1,3}):(\d{2})(?:[:\.](\d{1,3}))?>',
  );
  static final RegExp _bgLine = RegExp(r'^\[bg:(.*)\]$');
  static final RegExp _timingLine = RegExp(r'^\[w:([0-9,;]*)\]$');
  static final RegExp _voiceLine = RegExp(r'^\[v:(\d+)\]$');

  /// Singer prefix some Apple-Music-derived LRC files put on each line
  /// (`[00:12.34]v1: text`, `v2:` for the duet partner). Not lyric text.
  static final RegExp _voicePrefix = RegExp(r'^v(\d{1,2}):\s*');

  /// Word-timed lines whose singing ends this long before the next line
  /// hand the gap over to the instrumental "♫" line.
  static const Duration _wordTimedInstrumentalGap = Duration(seconds: 5);

  /// An intro at least this long before the first lyric gets its own "♫"
  /// line, so the screen shows music is playing instead of sitting on a
  /// not-yet-active first line.
  static const Duration _introGap = Duration(seconds: 5);

  /// Whether [lrc] has line timestamps at all. Lyrics without them (plain
  /// text, common in embedded tags) can't follow the song: [parse] returns
  /// their lines with no times, to be shown as text to read.
  static bool isTimed(String lrc) => _lineTag.hasMatch(lrc);

  /// [shift] moves every timestamp later (negative: earlier) - the user's
  /// lyrics offset setting, on top of any `[offset:]` tag in the file.
  static List<LyricLine> parse(
    String lrc,
    Duration totalDuration, {
    Duration shift = Duration.zero,
  }) {
    final lines = lrc.split('\n');
    final List<_RawLine> rawLines = [];

    // More flexible regex to handle [mm:ss], [mm:ss.xx], [mm:ss.xxx], [mm:ss:xx]
    final offsetRegExp = RegExp(r'\[offset:(-?\d+)\]');
    int globalOffsetMs = shift.inMilliseconds;

    for (var line in lines) {
      // Check for offset tag
      final offsetMatch = offsetRegExp.firstMatch(line);
      if (offsetMatch != null) {
        globalOffsetMs =
            shift.inMilliseconds + (int.tryParse(offsetMatch.group(1)!) ?? 0);
        continue;
      }

      // Looper's timing metadata (see TimedLrcWriter) - all of it belongs
      // to the lyric line right above.
      final trimmed = line.trim();
      final bgMatch = _bgLine.firstMatch(trimmed);
      if (bgMatch != null) {
        if (rawLines.isNotEmpty) {
          final raw = rawLines.last;
          final content = bgMatch.group(1)!.trim();
          // Also accepts the `[bg:<mm:ss.xx>word ...]` form other apps use.
          raw.background = _wordTag.hasMatch(content)
              ? _parseWords(content, globalOffsetMs)
              : const [];
          raw.backgroundText = raw.background.isNotEmpty
              ? raw.background.map((w) => w.text).join().trim()
              : content;
          raw.timingTargetsBackground = true;
        }
        continue;
      }
      final timingMatch = _timingLine.firstMatch(trimmed);
      if (timingMatch != null) {
        if (rawLines.isNotEmpty) {
          final raw = rawLines.last;
          if (raw.timingTargetsBackground) {
            raw.background = _parseTiming(
              timingMatch.group(1)!,
              raw.backgroundText,
              raw.start,
            );
          } else {
            raw.words = _parseTiming(
              timingMatch.group(1)!,
              raw.text,
              raw.start,
            );
          }
        }
        continue;
      }
      final voiceMatch = _voiceLine.firstMatch(trimmed);
      if (voiceMatch != null) {
        if (rawLines.isNotEmpty) {
          rawLines.last.opposite = voiceMatch.group(1) != '1';
        }
        continue;
      }

      final match = _lineTag.firstMatch(line);
      if (match != null) {
        final startTime = Duration(
          milliseconds:
              _toMs(match.group(1)!, match.group(2)!, match.group(3)) +
              globalOffsetMs,
        );
        var content = match.group(4)!.trim();
        final voice = _voicePrefix.firstMatch(content);
        if (voice != null) content = content.substring(voice.end);

        final words = _wordTag.hasMatch(content)
            ? _parseWords(content, globalOffsetMs)
            : const <_RawWord>[];
        final text = words.isNotEmpty
            ? words.map((w) => w.text).join().trim()
            : content;
        rawLines.add(
          _RawLine(startTime, text, words)
            ..opposite = voice != null && voice.group(1) != '1',
        );
      }
    }

    if (rawLines.isEmpty) {
      // PLAIN TEXT LYRICS (no timestamps): the lines, with no times - see
      // [isTimed]. Spreading them evenly over the song looked synced and
      // never was.
      // Filter out metadata tags like [ti:xx], [ar:xx], etc.
      final List<String> plainLines = [];
      final metaRegExp = RegExp(r'^\[[a-zA-Z]+:.*\]$');
      for (var line in lines) {
        final trimmed = line.trim();
        if (trimmed.isEmpty) continue;
        if (metaRegExp.hasMatch(trimmed)) continue;
        if (trimmed.startsWith('[') &&
            trimmed.endsWith(']') &&
            !trimmed.contains(' ')) {
          continue;
        }
        plainLines.add(trimmed.replaceFirst(_voicePrefix, ''));
      }

      return [
        for (final text in plainLines)
          LyricLine(
            startTime: Duration.zero,
            endTime: Duration.zero,
            text: text,
          ),
      ];
    }

    // Sort by start time just in case (stable, so lines sharing a timestamp
    // keep their file order).
    final indexed = rawLines.asMap().entries.toList()
      ..sort((a, b) {
        final byTime = a.value.start.compareTo(b.value.start);
        return byTime != 0 ? byTime : a.key.compareTo(b.key);
      });
    rawLines
      ..clear()
      ..addAll(indexed.map((e) => e.value));

    // Lines sharing a timestamp are one lyric in several languages
    // (original, translation, romanization): fold them into the first, so
    // the block is current together instead of each line handing over to
    // the next in the same instant. A later line that is sung on its own
    // (word-timed, duet side) stays a line.
    for (var i = 1; i < rawLines.length;) {
      final first = rawLines[i - 1];
      final line = rawLines[i];
      if (line.start != first.start || !line.isPlain) {
        i++;
        continue;
      }
      if (first.text.isEmpty && first.isPlain) {
        rawLines.removeAt(i - 1);
        continue;
      }
      if (line.text.isNotEmpty) first.extras.add(line.text);
      rawLines.removeAt(i);
    }

    // Give every remaining line a real, catchable active window: without
    // a floor, a line starting at (or within a hair of) the previous one
    // would end the instant it starts - `position >= start && position <
    // end` could never be true for it, so it would never be current.
    const minLineGap = Duration(milliseconds: 10);
    for (var i = 1; i < rawLines.length; i++) {
      final prevStart = rawLines[i - 1].start;
      final start = rawLines[i].start;
      if (start - prevStart < minLineGap) {
        rawLines[i].start = prevStart + minLineGap;
      }
    }

    final List<LyricLine> result = [];
    for (var i = 0; i < rawLines.length; i++) {
      final raw = rawLines[i];
      final startTime = raw.start;
      final text = raw.text;
      final isLast = i == rawLines.length - 1;

      // End time is the start time of the next line, or total duration for the last line
      var nextStartTime = isLast ? totalDuration : rawLines[i + 1].start;

      final singingEnd = _singingEnd(raw);
      if (singingEnd != null && nextStartTime < singingEnd && isLast) {
        nextStartTime = singingEnd;
      }

      LyricLine build(Duration end) => LyricLine(
        startTime: startTime,
        endTime: end,
        text: text,
        words: _finishWords(raw.words, end),
        backgroundWords: _finishWords(raw.background, end),
        isOppositeSide: raw.opposite,
        extraLines: raw.extras,
        backgroundText: raw.backgroundText,
      );

      // Word timing says exactly when the singing stops, so the
      // instrumental gap (or the outro, after the last line) can start
      // right there instead of guessing.
      if (singingEnd != null &&
          text.isNotEmpty &&
          nextStartTime - singingEnd > _wordTimedInstrumentalGap) {
        final breakStartTime = singingEnd + const Duration(milliseconds: 600);
        result.add(build(breakStartTime));
        result.add(
          LyricLine(
            startTime: breakStartTime,
            endTime: nextStartTime,
            text: '',
          ),
        );
        continue;
      }

      // If there's a long gap (> 15s) between this line and the next,
      // we assume the singing ends after a reasonable time and show a music icon.
      // Also after the last line (the outro), when the song's length is
      // known.
      if (singingEnd == null &&
          (nextStartTime - startTime).inSeconds > 15 &&
          text.isNotEmpty) {
        final singingDuration = const Duration(seconds: 10);
        final breakStartTime = startTime + singingDuration;

        // Add the singing part
        result.add(build(breakStartTime));

        // Add the instrumental part
        result.add(
          LyricLine(
            startTime: breakStartTime,
            endTime: nextStartTime,
            text: "", // Empty string triggers music icon
          ),
        );
      } else {
        result.add(build(nextStartTime));
      }
    }

    if (result.isNotEmpty &&
        result.first.text.isNotEmpty &&
        result.first.startTime >= _introGap) {
      result.insert(
        0,
        LyricLine(
          startTime: Duration.zero,
          endTime: result.first.startTime,
          text: '',
        ),
      );
    }

    return result;
  }

  /// Plain lyric text of stored lyrics in any format Looper writes: drops
  /// the `[source:]` tag, metadata/time tags, word tags, duet markers and
  /// background-vocal lines. For showing or searching lyrics as prose.
  static String plainText(String lrc) {
    final out = <String>[];
    final meta = RegExp(r'^\[[a-zA-Z]+:.*\]$');
    for (var line in lrc.split('\n')) {
      line = line.trim();
      if (line.isEmpty || meta.hasMatch(line)) continue;
      line = line
          .replaceAll(RegExp(r'\[\d{1,3}:\d{2}(?:[:\.]\d{1,3})?\]'), '')
          .replaceAll(_wordTag, '')
          .trim()
          .replaceFirst(_voicePrefix, '');
      if (line.isNotEmpty) out.add(line);
    }
    return out.join('\n');
  }

  static int _toMs(String minutes, String seconds, String? fraction) {
    var ms = 0;
    if (fraction != null) {
      final value = int.parse(fraction);
      ms = switch (fraction.length) {
        1 => value * 100,
        2 => value * 10,
        _ => value,
      };
    }
    return int.parse(minutes) * 60000 + int.parse(seconds) * 1000 + ms;
  }

  /// `[w:off,dur,len;...]` against the line [text] it times: [lineStart]
  /// plus each offset starts a syllable covering the next `len` characters.
  /// Returns nothing unless the lengths cover [text] exactly - a mismatch
  /// means the text was edited after the timing was written.
  static List<_RawWord> _parseTiming(
    String payload,
    String text,
    Duration lineStart,
  ) {
    if (payload.isEmpty || text.isEmpty) return const [];
    final words = <_RawWord>[];
    var cursor = 0;
    for (final entry in payload.split(';')) {
      final fields = entry.split(',');
      if (fields.length != 3) return const [];
      final offset = int.tryParse(fields[0]);
      final duration = int.tryParse(fields[1]);
      final length = int.tryParse(fields[2]);
      if (offset == null || duration == null || length == null) {
        return const [];
      }
      if (length <= 0 || cursor + length > text.length) return const [];
      final start = lineStart + Duration(milliseconds: offset);
      words.add(
        _RawWord(
          start,
          start + Duration(milliseconds: duration),
          text.substring(cursor, cursor + length),
        ),
      );
      cursor += length;
    }
    return cursor == text.length ? words : const [];
  }

  /// `<t0>word <t1>word<t2>`: each tag starts the text after it and ends
  /// the text before it. A bare trailing tag only closes the last word.
  static List<_RawWord> _parseWords(String content, int offsetMs) {
    final tags = _wordTag.allMatches(content).toList();
    if (tags.isEmpty) return const [];

    final words = <_RawWord>[];
    final leading = content.substring(0, tags.first.start);
    for (var i = 0; i < tags.length; i++) {
      final tag = tags[i];
      final textEnd = i + 1 < tags.length ? tags[i + 1].start : content.length;
      var text = content.substring(tag.end, textEnd);
      if (i == 0) text = leading + text;
      if (text.isEmpty) continue;
      final start = Duration(
        milliseconds:
            _toMs(tag.group(1)!, tag.group(2)!, tag.group(3)) + offsetMs,
      );
      final end = i + 1 < tags.length
          ? Duration(
              milliseconds:
                  _toMs(
                    tags[i + 1].group(1)!,
                    tags[i + 1].group(2)!,
                    tags[i + 1].group(3),
                  ) +
                  offsetMs,
            )
          : null;
      words.add(_RawWord(start, end, text));
    }
    return words;
  }

  static Duration? _singingEnd(_RawLine raw) {
    Duration? latest;
    for (final w in [...raw.words, ...raw.background]) {
      final end = w.end ?? w.start;
      if (latest == null || end > latest) latest = end;
    }
    return latest;
  }

  static List<LyricWord> _finishWords(List<_RawWord> raw, Duration lineEnd) {
    if (raw.isEmpty) return const [];
    return [
      for (final w in raw)
        LyricWord(
          startTime: w.start,
          endTime: w.end ?? (lineEnd > w.start ? lineEnd : w.start),
          text: w.text,
        ),
    ];
  }
}
