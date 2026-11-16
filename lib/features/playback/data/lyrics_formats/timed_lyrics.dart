/// Intermediate, format-neutral model for word-timed lyrics fetched online
/// (TTML from lrc.red, JSON from LyricsPlus), plus the writer that turns it
/// into the LRC Looper stores in song.lyrics and the lyrics cache.
///
/// Why LRC instead of keeping the TTML/JSON: song.lyrics is read as text by
/// the editor, the song-info screen, the .lrc export and - importantly - the
/// library search, which runs a substring query over it. So each lyric line
/// must stay contiguous plain text; word timing rides along on metadata
/// lines that other LRC players (and Looper's plain-text views) ignore:
///
///   [00:27.395]I been tryna call
///   [w:0,154,2;154,191,5;345,337,6;682,883,4]
///   [v:2]
///   [bg:Back to let you know]
///   [w:4325,434,5;4759,141,3;...]
///
/// - `[w:off,dur,len;...]` times the line right above it (main or `[bg:]`):
///   one entry per syllable - start offset from the *main* line's start,
///   duration, and how many characters of that line's text it covers
///   (including a word-final space). If the counts don't add up to the
///   text's length (someone edited the text), the timing is dropped rather
///   than applied to the wrong words.
/// - `[v:2]` marks a line sung by the duet partner.
/// - `[bg:text]` is a background-vocal line belonging to the line above.
///
/// Plain enhanced LRC (`<mm:ss.xx>` word tags) from sidecar/embedded files is
/// still read by LrcParser too; Looper just doesn't write it.
library;

class TimedSyllable {
  /// Includes the trailing space when this syllable ends a word; syllables
  /// of the same word ("e" + "nough") carry no space between them.
  final String text;
  final int startMs;
  final int endMs;

  const TimedSyllable({
    required this.text,
    required this.startMs,
    required this.endMs,
  });
}

class TimedLyricLine {
  final int startMs;
  final int endMs;

  /// Plain line text, used when [words] is empty (line-synced sources).
  final String text;
  final List<TimedSyllable> words;
  final List<TimedSyllable> background;

  /// Sung by the duet partner - rendered on the opposite side.
  final bool oppositeSide;

  const TimedLyricLine({
    required this.startMs,
    required this.endMs,
    required this.text,
    this.words = const [],
    this.background = const [],
    this.oppositeSide = false,
  });

  bool get isWordSynced => words.isNotEmpty;
}

class TimedLrcWriter {
  /// Returns null when there's nothing worth storing.
  static String? write(List<TimedLyricLine> lines) {
    final usable = lines
        .where(
          (l) =>
              l.text.trim().isNotEmpty ||
              l.words.any((w) => w.text.trim().isNotEmpty),
        )
        .toList();
    if (usable.isEmpty) return null;

    // No timing at all -> plain text, which LrcParser spreads over the song
    // exactly like any other unsynced lyrics.
    final unsynced = usable.every((l) => l.startMs == 0 && l.endMs == 0);
    if (unsynced) {
      return usable.map((l) => _clean(_plainText(l))).join('\n');
    }

    final buffer = StringBuffer();
    for (final line in usable) {
      final main = _timedText(line.words, line.startMs);
      buffer.writeln(
        '[${formatTimestamp(line.startMs)}]${main?.text ?? _clean(line.text.trim())}',
      );
      if (main != null) buffer.writeln('[w:${main.timing}]');
      if (line.oppositeSide) buffer.writeln('[v:2]');

      final bg = _timedText(line.background, line.startMs);
      if (bg != null) {
        buffer.writeln('[bg:${bg.text}]');
        buffer.writeln('[w:${bg.timing}]');
      }
    }
    return buffer.toString().trimRight();
  }

  /// The syllables' text as one line plus its `[w:]` payload, with the
  /// character counts matching the cleaned, trimmed text exactly.
  static ({String text, String timing})? _timedText(
    List<TimedSyllable> syllables,
    int lineStartMs,
  ) {
    final parts = [
      for (final s in syllables)
        if (s.text.isNotEmpty) (text: _clean(s.text), syl: s),
    ];
    // Trim the line's outer whitespace inside the first/last syllable so
    // the counts line up with the trimmed line LrcParser reads back.
    while (parts.isNotEmpty && parts.first.text.trimLeft().isEmpty) {
      parts.removeAt(0);
    }
    while (parts.isNotEmpty && parts.last.text.trimRight().isEmpty) {
      parts.removeLast();
    }
    if (parts.isEmpty) return null;
    parts[0] = (text: parts[0].text.trimLeft(), syl: parts[0].syl);
    final last = parts.length - 1;
    parts[last] = (text: parts[last].text.trimRight(), syl: parts[last].syl);

    final timing = parts
        .map((p) {
          final offset = p.syl.startMs - lineStartMs;
          final duration = p.syl.endMs - p.syl.startMs;
          return '$offset,${duration < 0 ? 0 : duration},${p.text.length}';
        })
        .join(';');
    return (text: parts.map((p) => p.text).join(), timing: timing);
  }

  static String _plainText(TimedLyricLine line) => line.isWordSynced
      ? line.words.map((w) => w.text).join().trim()
      : line.text.trim();

  /// Brackets would be misread as LRC tags and line breaks would split the
  /// line. Every replacement is one character for one, so syllable
  /// character counts are unaffected.
  static String _clean(String text) => text
      .replaceAll(RegExp(r'[\r\n]'), ' ')
      .replaceAll('[', '(')
      .replaceAll(']', ')');

  /// `mm:ss.xxx`; minutes grow past two digits for very long tracks.
  static String formatTimestamp(int ms) {
    final safe = ms < 0 ? 0 : ms;
    final minutes = safe ~/ 60000;
    final seconds = (safe % 60000) ~/ 1000;
    final millis = safe % 1000;
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}.'
        '${millis.toString().padLeft(3, '0')}';
  }
}

/// `Lyrics by: X`, `作词 : X` - a short label, a colon, a name.
final RegExp _creditLine = RegExp(r'^[^:：]{1,24}[:：]\s*\S');

/// [lines] without the credits the Chinese catalogues (NetEase, KuGou,
/// Lyricify) time as if they were sung: `Title - Artist` and
/// `Lyrics by: ...` lines before the first lyric, and credit lines after
/// the last one.
List<TimedLyricLine> withoutCreditLines(
  List<TimedLyricLine> lines, {
  String title = '',
}) {
  String textOf(TimedLyricLine l) =>
      l.isWordSynced ? l.words.map((w) => w.text).join().trim() : l.text.trim();
  String squash(String s) => s.toLowerCase().replaceAll(
    RegExp(r'[^\p{L}\p{M}\p{N}]', unicode: true),
    '',
  );
  final titleKey = squash(title);
  bool isCredit(TimedLyricLine l) => _creditLine.hasMatch(textOf(l));
  bool isHeading(TimedLyricLine l) {
    final text = textOf(l);
    return titleKey.isNotEmpty &&
        text.contains(' - ') &&
        squash(text).startsWith(titleKey);
  }

  var start = 0;
  while (start < lines.length &&
      (isCredit(lines[start]) || isHeading(lines[start]))) {
    start++;
  }
  var end = lines.length;
  while (end > start && isCredit(lines[end - 1])) {
    end--;
  }
  // All "credits": the pattern misfired on real lyrics - keep everything.
  return start >= end ? lines : lines.sublist(start, end);
}

/// Whether [lines] can belong to a recording lasting [durationSeconds]:
/// lyrics that keep going well past the end are another version's. Used
/// for sources whose search doesn't give a length to compare.
bool fitsDuration(List<TimedLyricLine> lines, int durationSeconds) =>
    durationSeconds <= 0 ||
    lines.isEmpty ||
    // A line can't start after the song ends (1 s for rounding).
    lines.last.startMs <= (durationSeconds + 1) * 1000;

/// Assigns duet sides from per-line singer ids: the first distinct solo
/// singer sings on the main side, the next one on the opposite side,
/// alternating for any further singers. Group/ensemble lines stay on the
/// main side. When a song is (almost) entirely "opposite" - e.g. only the
/// second agent id is ever used - everything is flipped back to main.
List<bool> assignDuetSides(
  List<String?> singers,
  Map<String, String> agentTypes,
) {
  final order = <String>[];
  final sides = <bool>[];
  for (final singer in singers) {
    if (singer == null || singer.isEmpty) {
      sides.add(false);
      continue;
    }
    final type = agentTypes[singer] ?? 'person';
    if (type == 'group') {
      sides.add(false);
      continue;
    }
    if (!order.contains(singer)) order.add(singer);
    sides.add(order.indexOf(singer).isOdd);
  }
  final assigned = sides.length;
  final opposite = sides.where((s) => s).length;
  if (assigned > 0 && opposite / assigned >= 0.85) {
    return sides.map((s) => !s).toList();
  }
  return sides;
}
