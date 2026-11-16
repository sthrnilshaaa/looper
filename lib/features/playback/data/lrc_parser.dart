class LrcWord {
  final Duration timestamp;
  final Duration duration;
  final String text;

  LrcWord({
    required this.timestamp,
    required this.duration,
    required this.text,
  });
}

class LrcLine {
  final Duration timestamp;
  final String text;
  final List<LrcWord> words;
  final bool isInstrumental;

  LrcLine({
    required this.timestamp,
    required this.text,
    this.words = const [],
    this.isInstrumental = false,
  });

  @override
  String toString() => '[${timestamp.inMilliseconds}] $text';
}

class LrcParser {
  static final RegExp _lrcRegex = RegExp(r'\[(\d+):(\d+[\.:]\d+)\](.*)');
  static final RegExp _wordRegex = RegExp(r'<(\d+):(\d+[\.:]\d+)>(.*)');
  static final RegExp _sourceTagRegex = RegExp(r'^\[source:.*\]\n?');

  /// Strips the leading `[source:xxx]` tag LyricsFetcher/scanner.dart write
  /// into a song's stored lyrics to track where they came from. Use this
  /// wherever raw song.lyrics is shown/edited as plain text (the normal
  /// playback path already does this via LyricsNotifier._applyLrcToState) -
  /// otherwise the tag itself shows up as a literal line of "lyrics".
  static String? stripSourceTag(String? raw) {
    if (raw == null) return null;
    return raw.replaceFirst(_sourceTagRegex, '');
  }

  static List<LrcLine> parse(String lrcContent) {
    final List<LrcLine> lines = [];
    final rawLines = lrcContent.split('\n');

    for (var rawLine in rawLines) {
      final match = _lrcRegex.firstMatch(rawLine.trim());
      if (match != null) {
        final timestamp = _parseTimestamp(match.group(1)!, match.group(2)!);
        final content = match.group(3)!;

        // 1. Try to parse Enhanced LRC (word-level tags)
        List<LrcWord> words = [];
        if (content.contains('<')) {
          final parts = content.split(RegExp(r'(?=<)'));
          for (var part in parts) {
            final wordMatch = _wordRegex.firstMatch(part.trim());
            if (wordMatch != null) {
              final wTimestamp = _parseTimestamp(
                wordMatch.group(1)!,
                wordMatch.group(2)!,
              );
              final wText = wordMatch.group(3)!.trim();
              if (wText.isNotEmpty) {
                words.add(
                  LrcWord(
                    timestamp: wTimestamp,
                    duration: const Duration(milliseconds: 0),
                    text: wText,
                  ),
                );
              }
            }
          }
        }

        // 2. If no word tags, split by space and distribute line duration (Artificial Word Sync)
        if (words.isEmpty && content.trim().isNotEmpty) {
          final plainText = content.replaceAll(RegExp(r'<[^>]*>'), '').trim();
          final splitWords = plainText.split(RegExp(r'\s+'));
          // We don't know the line duration yet, we'll fix this in the post-processing step
          for (var text in splitWords) {
            words.add(
              LrcWord(
                timestamp: timestamp, // Temporary
                duration: const Duration(milliseconds: 0),
                text: text,
              ),
            );
          }
        }

        lines.add(
          LrcLine(
            timestamp: timestamp,
            text: words.isNotEmpty
                ? words.map((w) => w.text).join(' ')
                : content.trim(),
            words: words,
          ),
        );
      }
    }

    lines.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // Post-processing: Calculate durations and fix artificial word sync
    final List<LrcLine> processedLines = [];
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final nextLineTimestamp = (i < lines.length - 1)
          ? lines[i + 1].timestamp
          : line.timestamp + const Duration(seconds: 5);
      final lineDuration = nextLineTimestamp - line.timestamp;

      List<LrcWord> processedWords = [];
      if (line.words.isNotEmpty) {
        // If word-level tags existed, calculate durations based on next tags
        if (line.words[0].timestamp != line.timestamp) {
          // Real word-level tags
          for (int j = 0; j < line.words.length; j++) {
            final word = line.words[j];
            Duration duration;
            if (j < line.words.length - 1) {
              duration = line.words[j + 1].timestamp - word.timestamp;
            } else {
              duration = nextLineTimestamp - word.timestamp;
            }
            processedWords.add(
              LrcWord(
                timestamp: word.timestamp,
                duration: duration,
                text: word.text,
              ),
            );
          }
        } else {
          // Artificial word sync: distribute line duration equally
          final wordDuration = Duration(
            milliseconds: lineDuration.inMilliseconds ~/ line.words.length,
          );
          for (int j = 0; j < line.words.length; j++) {
            processedWords.add(
              LrcWord(
                timestamp: line.timestamp + (wordDuration * j),
                duration: wordDuration,
                text: line.words[j].text,
              ),
            );
          }
        }
      }

      processedLines.add(
        LrcLine(
          timestamp: line.timestamp,
          text: line.text,
          words: processedWords,
        ),
      );
    }

    // Inject instrumental breaks
    final List<LrcLine> finalLines = [];
    if (processedLines.isNotEmpty) {
      if (processedLines[0].timestamp > const Duration(seconds: 5)) {
        finalLines.add(
          LrcLine(
            timestamp: const Duration(seconds: 0),
            text: '🎵',
            isInstrumental: true,
          ),
        );
      }

      for (int i = 0; i < processedLines.length; i++) {
        finalLines.add(processedLines[i]);
        if (i < processedLines.length - 1) {
          final gap =
              processedLines[i + 1].timestamp - processedLines[i].timestamp;
          if (gap > const Duration(seconds: 10)) {
            finalLines.add(
              LrcLine(
                timestamp:
                    processedLines[i].timestamp + const Duration(seconds: 2),
                text: '🎵',
                isInstrumental: true,
              ),
            );
          }
        }
      }
    }

    return finalLines;
  }

  static Duration _parseTimestamp(String minStr, String secStr) {
    final minutes = int.parse(minStr);
    final secParts = secStr.split(RegExp(r'[\.:]'));
    final seconds = int.parse(secParts[0]);
    int ms = 0;
    if (secParts.length > 1) {
      ms = int.parse(secParts[1].padRight(3, '0').substring(0, 3));
    }
    return Duration(minutes: minutes, seconds: seconds, milliseconds: ms);
  }
}
