import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:looper_player/core/app_fonts.dart';
import 'package:looper_player/core/ui_utils.dart';
import 'package:looper_player/features/library/domain/models/models.dart';
import 'package:looper_player/features/playback/domain/lyric_models.dart';
import 'package:looper_player/features/playback/presentation/playback_notifier.dart';
import 'package:looper_player/core/db_service.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:looper_player/l10n/app_localizations.dart';

enum LyricsEditorViewMode { simple, advanced }

class LyricsEditorBottomSheet extends ConsumerStatefulWidget {
  final Song song;

  const LyricsEditorBottomSheet({
    super.key,
    required this.song,
  });

  @override
  ConsumerState<LyricsEditorBottomSheet> createState() =>
      _LyricsEditorBottomSheetState();
}

class _LyricsEditorBottomSheetState extends ConsumerState<LyricsEditorBottomSheet> {
  final TextEditingController _lyricsTextController = TextEditingController();
  final TextEditingController _currentTimeController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  LyricsEditorViewMode _viewMode = LyricsEditorViewMode.simple;
  List<_EditableLyricLine> _lines = const [];
  int _selectedLineIndex = 0;
  bool _autoAdvance = true;
  bool _isSaving = false;
  Duration _currentPosition = Duration.zero;

  @override
  void initState() {
    super.initState();
    final playbackState = ref.read(playbackProvider);
    _currentPosition = playbackState.position;
    _lines = _seedLines();
    _syncEditorFromLines();
    _updateCurrentTimeField();
    _lyricsTextController.addListener(_handleLyricsTextChanged);
  }

  @override
  void dispose() {
    _lyricsTextController.removeListener(_handleLyricsTextChanged);
    _lyricsTextController.dispose();
    _currentTimeController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  List<_EditableLyricLine> _seedLines() {
    final rawLyrics = widget.song.lyrics;
    if (rawLyrics == null || rawLyrics.trim().isEmpty) {
      return const [_EditableLyricLine(text: '', timestamp: null)];
    }

    final regExp = RegExp(r'\[(\d{1,3}):(\d{2})');
    final hasTimestamps = regExp.hasMatch(rawLyrics);

    if (hasTimestamps) {
      final parsed = LrcParser.parse(
        rawLyrics,
        Duration(milliseconds: widget.song.duration ?? 0),
      );
      if (parsed.isNotEmpty) {
        return parsed
            .where((line) => !line.text.contains('🎵') && line.text.trim().isNotEmpty)
            .map(
              (line) => _EditableLyricLine(
                text: line.text,
                timestamp: line.startTime == Duration.zero ? null : line.startTime,
              ),
            )
            .toList();
      }
    }

    // Split raw plain text
    final lines = rawLyrics.split('\n');
    final metaRegExp = RegExp(r'^\[[a-zA-Z]+:.*\]$');
    final parsedLines = <_EditableLyricLine>[];
    for (var line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      if (metaRegExp.hasMatch(trimmed)) continue;
      if (trimmed.startsWith('[') && trimmed.endsWith(']') && !trimmed.contains(' ')) continue;
      parsedLines.add(_EditableLyricLine(text: trimmed, timestamp: null));
    }

    if (parsedLines.isEmpty) {
      return const [_EditableLyricLine(text: '', timestamp: null)];
    }
    return parsedLines;
  }

  void _updateCurrentTimeField() {
    final value = _formatTimestampText(_currentPosition);
    if (_currentTimeController.text == value) return;
    _currentTimeController.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  void _syncEditorFromLines() {
    final text = _lines.map((line) => line.text).join('\n');
    _lyricsTextController.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  void _handleLyricsTextChanged() {
    final rows = _lyricsTextController.text
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .split('\n');
    final nextLines = <_EditableLyricLine>[];

    for (var index = 0; index < rows.length; index++) {
      nextLines.add(
        _EditableLyricLine(
          text: rows[index],
          timestamp: index < _lines.length ? _lines[index].timestamp : null,
        ),
      );
    }

    while (nextLines.isNotEmpty && nextLines.last.text.isEmpty) {
      nextLines.removeLast();
    }

    if (nextLines.isEmpty) {
      nextLines.add(const _EditableLyricLine(text: '', timestamp: null));
    }

    setState(() {
      _lines = nextLines;
      if (_selectedLineIndex >= _lines.length) {
        _selectedLineIndex = _lines.length - 1;
      }
      if (_selectedLineIndex < 0) {
        _selectedLineIndex = 0;
      }
    });
  }

  int get _stampedLineCount => _lines
      .where((line) => line.text.trim().isNotEmpty && line.timestamp != null)
      .length;

  int get _usableLineCount =>
      _lines.where((line) => line.text.trim().isNotEmpty).length;

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
    final match = RegExp(r'^(\d{1,2}):(\d{2})(?:\.(\d{1,3}))?$').firstMatch(trimmed);
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

  Future<void> _seekBy(Duration delta) async {
    final playbackState = ref.read(playbackProvider);
    final totalDuration = playbackState.duration;
    final next = _currentPosition + delta;
    final clampedMs = next.inMilliseconds.clamp(0, totalDuration.inMilliseconds);
    ref.read(playbackProvider.notifier).seek(Duration(milliseconds: clampedMs));
  }

  void _togglePlayPause() {
    HapticFeedback.lightImpact();
    ref.read(playbackProvider.notifier).togglePlay();
  }

  void _selectLine(int index) {
    if (index < 0 || index >= _lines.length) return;
    setState(() {
      _selectedLineIndex = index;
    });
  }

  void _stampSelectedLine({required bool advance}) {
    if (_selectedLineIndex < 0 || _selectedLineIndex >= _lines.length) return;
    final current = _lines[_selectedLineIndex];
    if (current.text.trim().isEmpty) return;

    setState(() {
      _lines = [
        for (var index = 0; index < _lines.length; index++)
          if (index == _selectedLineIndex)
            _lines[index].copyWith(timestamp: _currentPosition)
          else
            _lines[index],
      ];
      if (advance && _selectedLineIndex < _lines.length - 1) {
        _selectedLineIndex += 1;
      }
    });
  }

  void _clearSelectedTimestamp() {
    if (_selectedLineIndex < 0 || _selectedLineIndex >= _lines.length) return;
    setState(() {
      _lines = [
        for (var index = 0; index < _lines.length; index++)
          if (index == _selectedLineIndex)
            _lines[index].copyWith(timestamp: null, clearTimestamp: true)
          else
            _lines[index],
      ];
    });
  }

  void _shiftAll(Duration delta) {
    setState(() {
      _lines = _lines
          .map(
            (line) => line.timestamp == null
                ? line
                : line.copyWith(
                    timestamp: Duration(
                      milliseconds:
                          (line.timestamp!.inMilliseconds +
                                  delta.inMilliseconds)
                              .clamp(0, double.maxFinite.toInt()),
                    ),
                  ),
          )
          .toList();
    });
  }

  void _applyTimestampText(int index, String value) {
    final normalized = value.replaceAll('[', '').replaceAll(']', '').trim();
    if (normalized.isEmpty) {
      setState(() {
        _lines = [
          for (var lineIndex = 0; lineIndex < _lines.length; lineIndex++)
            if (lineIndex == index)
              _lines[lineIndex].copyWith(timestamp: null, clearTimestamp: true)
            else
              _lines[lineIndex],
        ];
      });
      return;
    }

    final parsed = _parseTimestamp(normalized);
    if (parsed == null) return;

    setState(() {
      _lines = [
        for (var lineIndex = 0; lineIndex < _lines.length; lineIndex++)
          if (lineIndex == index)
            _lines[lineIndex].copyWith(timestamp: parsed)
          else
            _lines[lineIndex],
      ];
    });
  }

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
      buffer.writeln('[length:${totalMinutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}.${centiseconds.toString().padLeft(2, '0')}]');
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

  Future<void> _save() async {
    final normalizedLines = _buildNormalizedLyricsLines();
    if (normalizedLines.isEmpty) {
      _showMessage('Add at least one lyric line first.');
      return;
    }

    final lrcContent = _buildLrcContent(normalizedLines);

    setState(() {
      _isSaving = true;
    });

    try {
      await DbService.isar.writeTxn(() async {
        final dbSong = await DbService.isar.songs.get(widget.song.id);
        if (dbSong != null) {
          dbSong.lyrics = lrcContent;
          await DbService.isar.songs.put(dbSong);
        }
      });

      ref.read(playbackProvider.notifier).updateSongLyrics(widget.song.id, lrcContent);

      final sidecarPath = _suggestSidecarLrcPath(widget.song.path);
      bool savedSidecar = false;
      if (sidecarPath != null) {
        try {
          final file = File(sidecarPath);
          await file.parent.create(recursive: true);
          await file.writeAsString(lrcContent);
          savedSidecar = true;
        } catch (e) {
          debugPrint('Could not write sidecar file: $e');
        }
      }

      if (!mounted) return;
      final message = savedSidecar
          ? 'Saved lyrics to database and beside the song file.'
          : 'Saved lyrics to player database.';
      _showMessage(message);

      Navigator.of(context).pop(true);
    } catch (e) {
      _showMessage('Could not save the lyrics.');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  Future<void> _showInstructions() async {
    final l10n = AppLocalizations.of(context)!;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          l10n.lyricsSyncHelp,
          style: AppFonts.jostStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.simpleModeLabel,
                style: AppFonts.jostStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '1. Paste or type one lyric line per row.\n'
                '2. Play the song.\n'
                '3. Select the current lyric line.\n'
                '4. Tap "Stamp & Next" when you hear that line.\n'
                '5. Save when done.',
                style: AppFonts.jostStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.advancedModeLabel,
                style: AppFonts.jostStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '1. Edit timestamps directly for each line.\n'
                '2. Use "Use Current Time" to capture the live playback time.\n'
                '3. Use the shift controls to move all stamped lyrics together.\n'
                '4. Save to generate the final `.lrc` file.',
                style: AppFonts.jostStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.tips,
                style: AppFonts.jostStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '- If some lines are not stamped, Flick\'s engine fills their times automatically.\n'
                '- Save writes beside the song when possible, otherwise it stores a linked copy in the DB.',
                style: AppFonts.jostStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              l10n.gotIt,
              style: AppFonts.jostStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Deliberately not setState() here: _currentPosition only feeds
    // _updateCurrentTimeField() (which writes straight into a
    // TextEditingController and re-renders itself) and the nudge/"set to
    // current position" buttons (which just read the field when pressed) -
    // neither needs this whole sheet (text field, line-picker list, sync
    // UI) to rebuild on every position tick while a song plays.
    ref.listen<PlaybackState>(playbackProvider, (previous, next) {
      if (next.position != previous?.position) {
        _currentPosition = next.position;
        _updateCurrentTimeField();
      }
    });

    final accentColor = Theme.of(context).colorScheme.primary;

    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: BoxDecoration(
        color: Colors.grey[950]!.withValues(alpha: 0.96),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 0.5,
        ),
      ),
      padding: EdgeInsets.fromLTRB(20.s, 16.s, 20.s, MediaQuery.of(context).padding.bottom + 16.s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.lyricsSyncStudio,
                      style: AppFonts.jostStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.song.title,
                      style: AppFonts.jostStyle(
                        color: Colors.white54,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                icon: const Icon(LucideIcons.x, color: Colors.white70),
              ),
              IconButton(
                onPressed: _isSaving ? null : _showInstructions,
                icon: const Icon(LucideIcons.helpCircle, color: Colors.white70),
                tooltip: l10n.instructionsTooltip,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildModePicker(context),
          const SizedBox(height: 12),
          _buildStatusCards(context),
          const SizedBox(height: 12),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLyricsTextEditor(context),
                  const SizedBox(height: 12),
                  if (_viewMode == LyricsEditorViewMode.simple)
                    _buildSimpleSyncView(context)
                  else
                    _buildAdvancedSyncView(context),
                  const SizedBox(height: 12),
                  _buildSaveNotice(context),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                  child: Text(l10n.cancel, style: AppFonts.jostStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _isSaving ? null : _save,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                        )
                      : const Icon(LucideIcons.save, size: 16),
                  label: Text(
                    _isSaving ? 'Saving...' : 'Save LRC',
                    style: AppFonts.jostStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModePicker(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: LyricsEditorViewMode.values.map((mode) {
          final selected = mode == _viewMode;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _viewMode = mode;
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  color: selected ? Theme.of(context).colorScheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 8),
                alignment: Alignment.center,
                child: Text(
                  mode == LyricsEditorViewMode.simple ? l10n.simpleModeLabel : l10n.advancedModeLabel,
                  style: AppFonts.jostStyle(
                    color: selected ? Colors.black : Colors.white70,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatusCards(BuildContext context) {
    Widget card(IconData icon, String label, String value) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 16, color: Colors.white38),
              const SizedBox(height: 6),
              Text(
                value,
                style: AppFonts.jostStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: AppFonts.jostStyle(
                  color: Colors.white38,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        card(LucideIcons.list, 'Lines', '$_usableLineCount'),
        const SizedBox(width: 8),
        card(LucideIcons.clock, 'Stamped', '$_stampedLineCount'),
        const SizedBox(width: 8),
        card(LucideIcons.timer, 'Now', _currentTimeController.text),
      ],
    );
  }

  Widget _buildLyricsTextEditor(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.lyricsTextLabel,
          style: AppFonts.jostStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.lyricsTextHelperDesc,
          style: AppFonts.jostStyle(color: Colors.white38, fontSize: 11),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _lyricsTextController,
          minLines: 4,
          maxLines: 8,
          style: AppFonts.jostStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: l10n.pasteLyricsHint,
            hintStyle: AppFonts.jostStyle(color: Colors.white24, fontSize: 14),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.02),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSimpleSyncView(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final selectedLine =
        _selectedLineIndex >= 0 && _selectedLineIndex < _lines.length
        ? _lines[_selectedLineIndex]
        : null;

    final accentColor = Theme.of(context).colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.quickSync,
          style: AppFonts.jostStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        _buildPlaybackTools(context),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: _selectedLineIndex > 0
                        ? () => _selectLine(_selectedLineIndex - 1)
                        : null,
                    icon: const Icon(LucideIcons.chevronUp, color: Colors.white70),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Selected line ${_selectedLineIndex + 1} of ${_lines.length}',
                          style: AppFonts.jostStyle(
                            color: Colors.white38,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          selectedLine?.text.trim().isNotEmpty == true
                              ? selectedLine!.text
                              : 'Pick a lyric line from the list below.',
                          textAlign: TextAlign.center,
                          style: AppFonts.jostStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (selectedLine?.timestamp != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            _formatTimestampText(selectedLine!.timestamp!),
                            style: AppFonts.jostStyle(
                              color: accentColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _selectedLineIndex < _lines.length - 1
                        ? () => _selectLine(_selectedLineIndex + 1)
                        : null,
                    icon: const Icon(LucideIcons.chevronDown, color: Colors.white70),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: selectedLine?.text.trim().isNotEmpty == true
                          ? () => _stampSelectedLine(advance: _autoAdvance)
                          : null,
                      icon: const Icon(LucideIcons.clock, size: 16),
                      label: Text(
                        _autoAdvance ? 'Stamp & Next' : 'Stamp Now',
                        style: AppFonts.jostStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: selectedLine?.timestamp != null
                          ? _clearSelectedTimestamp
                          : null,
                      child: Text(l10n.clear, style: AppFonts.jostStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.autoAdvanceAfterStamping,
                      style: AppFonts.jostStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ),
                  Switch.adaptive(
                    value: _autoAdvance,
                    activeColor: accentColor,
                    activeTrackColor: accentColor.withValues(alpha: 0.5),
                    onChanged: (val) {
                      setState(() {
                        _autoAdvance = val;
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        _buildShiftTools(context),
        const SizedBox(height: 8),
        _buildLinePickerList(context, compact: false),
      ],
    );
  }

  Widget _buildAdvancedSyncView(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final accentColor = Theme.of(context).colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.advancedSync,
          style: AppFonts.jostStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        _buildPlaybackTools(context),
        const SizedBox(height: 8),
        _buildShiftTools(context),
        const SizedBox(height: 8),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _lines.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final line = _lines[index];
            final selected = index == _selectedLineIndex;
            final timestampText = line.timestamp == null
                ? ''
                : _formatTimestampText(line.timestamp!);
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: selected
                    ? Colors.white.withValues(alpha: 0.04)
                    : Colors.white.withValues(alpha: 0.02),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selected
                      ? accentColor.withValues(alpha: 0.3)
                      : Colors.white.withValues(alpha: 0.05),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Line ${index + 1}',
                        style: AppFonts.jostStyle(
                          color: Colors.white38,
                          fontSize: 11,
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: accentColor,
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () {
                          _selectLine(index);
                          _stampSelectedLine(advance: false);
                        },
                        icon: const Icon(LucideIcons.clock, size: 12),
                        label: Text(l10n.useCurrentTime, style: AppFonts.jostStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    line.text.isEmpty ? '(Empty line)' : line.text,
                    style: AppFonts.jostStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    initialValue: timestampText,
                    onTap: () => _selectLine(index),
                    onChanged: (value) => _applyTimestampText(index, value),
                    style: AppFonts.jostStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      labelText: l10n.timestampMmSsHint,
                      labelStyle: AppFonts.jostStyle(color: Colors.white38, fontSize: 12),
                      hintText: '00:12.34',
                      hintStyle: AppFonts.jostStyle(color: Colors.white12, fontSize: 13),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.01),
                      isDense: true,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: accentColor.withValues(alpha: 0.4)),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPlaybackTools(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isPlaying = ref.watch(playbackProvider.select((s) => s.isPlaying));
    final accentColor = Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.playbackAssist,
            style: AppFonts.jostStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white70,
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                onPressed: () => _seekBy(const Duration(seconds: -2)),
                child: Text('-2s', style: AppFonts.jostStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                onPressed: _togglePlayPause,
                icon: Icon(
                  isPlaying ? LucideIcons.pause : LucideIcons.play,
                  size: 14,
                ),
                label: Text(
                  isPlaying ? 'Pause' : 'Play',
                  style: AppFonts.jostStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white70,
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                onPressed: () => _seekBy(const Duration(seconds: 2)),
                child: Text('+2s', style: AppFonts.jostStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ),
              const Spacer(),
              SizedBox(
                width: 90,
                child: TextField(
                  controller: _currentTimeController,
                  readOnly: true,
                  style: AppFonts.jostStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    labelText: l10n.nowLabel,
                    labelStyle: AppFonts.jostStyle(color: Colors.white38, fontSize: 10),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.01),
                    isDense: true,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShiftTools(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.timeShift,
            style: AppFonts.jostStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.timeShiftDesc,
            style: AppFonts.jostStyle(color: Colors.white38, fontSize: 11),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _shiftButton('-500ms', const Duration(milliseconds: -500)),
                const SizedBox(width: 6),
                _shiftButton('-100ms', const Duration(milliseconds: -100)),
                const SizedBox(width: 6),
                _shiftButton('+100ms', const Duration(milliseconds: 100)),
                const SizedBox(width: 6),
                _shiftButton('+500ms', const Duration(milliseconds: 500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _shiftButton(String label, Duration delta) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white70,
        side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
      onPressed: () {
        HapticFeedback.lightImpact();
        _shiftAll(delta);
      },
      child: Text(label, style: AppFonts.jostStyle(fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildLinePickerList(BuildContext context, {required bool compact}) {
    final accentColor = Theme.of(context).colorScheme.primary;

    return Container(
      constraints: BoxConstraints(maxHeight: compact ? 180 : 250),
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.01),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: ListView.separated(
        controller: _scrollController,
        shrinkWrap: true,
        itemCount: _lines.length,
        separatorBuilder: (_, _) => Divider(height: 1, color: Colors.white.withValues(alpha: 0.04)),
        itemBuilder: (context, index) {
          final line = _lines[index];
          final selected = index == _selectedLineIndex;
          return Material(
            color: selected ? Colors.white.withValues(alpha: 0.03) : Colors.transparent,
            child: InkWell(
              onTap: () => _selectLine(index),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selected ? accentColor : Colors.white.withValues(alpha: 0.05),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${index + 1}',
                        style: AppFonts.jostStyle(
                          color: selected ? Colors.black : Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            line.text.isEmpty ? '(Empty line)' : line.text,
                            maxLines: compact ? 1 : 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppFonts.jostStyle(
                              color: Colors.white,
                              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            line.timestamp == null
                                ? 'Not stamped yet'
                                : _formatTimestampText(line.timestamp!),
                            style: AppFonts.jostStyle(
                              color: selected ? accentColor : Colors.white38,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSaveNotice(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            LucideIcons.info,
            size: 16,
            color: Colors.white38,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n.lyricsSaveLrcExplain,
              style: AppFonts.jostStyle(
                color: Colors.white38,
                fontSize: 11,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditableLyricLine {
  final String text;
  final Duration? timestamp;

  const _EditableLyricLine({required this.text, this.timestamp});

  _EditableLyricLine copyWith({
    String? text,
    Duration? timestamp,
    bool clearTimestamp = false,
  }) {
    return _EditableLyricLine(
      text: text ?? this.text,
      timestamp: clearTimestamp ? null : (timestamp ?? this.timestamp),
    );
  }
}
