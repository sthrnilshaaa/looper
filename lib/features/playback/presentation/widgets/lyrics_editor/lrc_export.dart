part of 'lyrics_editor_bottom_sheet.dart';

extension _LyricsEditorExport on _LyricsEditorBottomSheetState {
  List<LyricLine> _buildNormalizedLyricsLines() {
    final sourceLines = _lines
        .where((line) => line.text.trim().isNotEmpty)
        .map((line) => line.copyWith(text: line.text.trim()))
        .toList();
    if (sourceLines.isEmpty) return const [];

    final filled = List<Duration?>.from(
      sourceLines.map((line) => line.timestamp),
    );
    final stampedIndices = <int>[
      for (var index = 0; index < sourceLines.length; index++)
        if (filled[index] != null) index,
    ];

    // A manual stamp can end up chronologically earlier than a stamp on a
    // line before it (e.g. re-timing an earlier line after later ones were
    // already stamped) -- unlike the main LRC parser, line order here is
    // fixed by the text, not re-sorted, so nothing else catches that.
    // Clamping each stamp to be at least the previous one keeps the
    // interpolation below strictly non-decreasing, preventing two lines
    // from landing on (or straddling) the same instant in the saved .lrc --
    // which is exactly what made the active-line highlight flicker between
    // them during playback.
    for (var i = 1; i < stampedIndices.length; i++) {
      final prevIndex = stampedIndices[i - 1];
      final index = stampedIndices[i];
      if (filled[index]! < filled[prevIndex]!) {
        filled[index] = filled[prevIndex];
      }
    }

    if (stampedIndices.isEmpty) {
      final totalMs = widget.song.duration ?? 0;
      final interval = totalMs > 0 ? totalMs ~/ sourceLines.length : 2000;
      return [
        for (var index = 0; index < sourceLines.length; index++)
          LyricLine(
            startTime: Duration(milliseconds: interval * index),
            endTime: Duration(milliseconds: interval * (index + 1)),
            text: sourceLines[index].text,
          ),
      ];
    }

    const defaultStep = Duration(seconds: 2);
    final firstStampedIndex = stampedIndices.first;
    final firstStampedTime = filled[firstStampedIndex]!;
    for (var index = firstStampedIndex - 1; index >= 0; index--) {
      final backfilled =
          firstStampedTime -
          Duration(
            seconds: defaultStep.inSeconds * (firstStampedIndex - index),
          );
      filled[index] = backfilled.isNegative ? Duration.zero : backfilled;
    }

    for (
      var stampIndex = 0;
      stampIndex < stampedIndices.length - 1;
      stampIndex++
    ) {
      final startIndex = stampedIndices[stampIndex];
      final endIndex = stampedIndices[stampIndex + 1];
      final start = filled[startIndex]!;
      final end = filled[endIndex]!;
      final gapCount = endIndex - startIndex - 1;
      if (gapCount <= 0) continue;

      final deltaMs = end.inMilliseconds - start.inMilliseconds;
      final stepMs = gapCount <= 0 ? 0 : deltaMs ~/ (gapCount + 1);
      for (var offset = 1; offset <= gapCount; offset++) {
        filled[startIndex + offset] = Duration(
          milliseconds: start.inMilliseconds + (stepMs * offset),
        );
      }
    }

    final lastStampedIndex = stampedIndices.last;
    for (var index = lastStampedIndex + 1; index < filled.length; index++) {
      final previous = filled[index - 1] ?? Duration.zero;
      filled[index] = previous + defaultStep;
    }

    var lastMs = 0;
    final normalized = <LyricLine>[];
    for (var index = 0; index < sourceLines.length; index++) {
      final timestamp = filled[index] ?? Duration(milliseconds: lastMs);
      final nextMs = timestamp.inMilliseconds < lastMs
          ? lastMs
          : timestamp.inMilliseconds;
      lastMs = nextMs;

      final nextLineStart = (index < sourceLines.length - 1)
          ? (filled[index + 1] ?? Duration(milliseconds: lastMs))
          : Duration(milliseconds: widget.song.duration ?? (lastMs + 2000));

      normalized.add(
        LyricLine(
          startTime: Duration(milliseconds: nextMs),
          endTime: nextLineStart.inMilliseconds < nextMs
              ? Duration(milliseconds: nextMs + 1000)
              : nextLineStart,
          text: sourceLines[index].text,
        ),
      );
    }
    return normalized;
  }

  String _buildLrcContent(List<LyricLine> lines) {
    final buffer = StringBuffer();
    if (widget.song.title.trim().isNotEmpty) {
      buffer.writeln('[ti:${widget.song.title.trim()}]');
    }
    if (widget.song.artist?.trim().isNotEmpty == true) {
      buffer.writeln('[ar:${widget.song.artist!.trim()}]');
    }
    if (widget.song.album?.trim().isNotEmpty == true) {
      buffer.writeln('[al:${widget.song.album!.trim()}]');
    }
    if (widget.song.duration != null && widget.song.duration! > 0) {
      final totalMinutes = widget.song.duration! ~/ 60000;
      final seconds = (widget.song.duration! % 60000) ~/ 1000;
      final centiseconds = (widget.song.duration! % 1000) ~/ 10;
      buffer.writeln(
        '[length:${totalMinutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}.${centiseconds.toString().padLeft(2, '0')}]',
      );
    }
    if (buffer.isNotEmpty) {
      buffer.writeln();
    }

    for (final line in lines) {
      buffer.writeln('${_formatTimestamp(line.startTime)}${line.text}');
    }
    return buffer.toString().trimRight();
  }

  String? _suggestSidecarLrcPath(String songPath) {
    if (songPath.isEmpty) return null;
    String localPath = songPath;
    if (songPath.startsWith('file://')) {
      final uri = Uri.tryParse(songPath);
      if (uri != null) {
        localPath = uri.toFilePath();
      }
    }
    final file = File(localPath);
    final dotIndex = file.path.lastIndexOf('.');
    final stem = dotIndex <= 0 ? file.path : file.path.substring(0, dotIndex);
    return '$stem.lrc';
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }
}
