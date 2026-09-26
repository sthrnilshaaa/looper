part of 'lyrics_editor_bottom_sheet.dart';

extension _LyricsEditorTimestamps on _LyricsEditorBottomSheetState {
  String _formatTimestampText(Duration duration) {
    final totalMinutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    final centoseconds = (duration.inMilliseconds.remainder(1000) ~/ 10);
    return '${totalMinutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}.${centoseconds.toString().padLeft(2, '0')}';
  }

  String _formatTimestamp(Duration duration) {
    return '[${_formatTimestampText(duration)}]';
  }

  Duration? _parseTimestamp(String timestamp) {
    final trimmed = timestamp.trim();
    final match = RegExp(
      r'^(\d{1,2}):(\d{2})(?:\.(\d{1,3}))?$',
    ).firstMatch(trimmed);
    if (match == null) return null;

    final minutes = int.tryParse(match.group(1) ?? '');
    final seconds = int.tryParse(match.group(2) ?? '');
    if (minutes == null || seconds == null) return null;

    int ms = 0;
    final fractionRaw = match.group(3);
    if (fractionRaw != null && fractionRaw.isNotEmpty) {
      if (fractionRaw.length == 1) {
        ms = int.parse(fractionRaw) * 100;
      } else if (fractionRaw.length == 2) {
        ms = int.parse(fractionRaw) * 10;
      } else {
        ms = int.parse(fractionRaw.substring(0, 3));
      }
    }

    return Duration(minutes: minutes, seconds: seconds, milliseconds: ms);
  }
}
