import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:looper_player/core/theme/app_fonts.dart';
import 'package:looper_player/core/utils/ui_utils.dart';
import 'package:looper_player/features/playback/domain/lyric_models.dart';
import 'package:looper_player/features/playback/presentation/providers/playback/playback_notifier.dart';
import 'package:looper_player/core/services/storage/db_service.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:looper_player/l10n/app_localizations.dart';
import 'package:looper_player/core/utils/l10n.dart';
part 'timestamp_editing.dart';
part 'lrc_export.dart';
part 'editor_views.dart';
part 'editor_tools.dart';

enum LyricsEditorViewMode { simple, advanced }

class LyricsEditorBottomSheet extends ConsumerStatefulWidget {
  final Song song;

  const LyricsEditorBottomSheet({super.key, required this.song});

  @override
  ConsumerState<LyricsEditorBottomSheet> createState() =>
      _LyricsEditorBottomSheetState();
}

class _LyricsEditorBottomSheetState
    extends ConsumerState<LyricsEditorBottomSheet> {
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
            .where(
              (line) =>
                  !line.text.contains('🎵') && line.text.trim().isNotEmpty,
            )
            .map(
              (line) => _EditableLyricLine(
                text: line.text,
                timestamp: line.startTime == Duration.zero
                    ? null
                    : line.startTime,
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
      if (trimmed.startsWith('[') &&
          trimmed.endsWith(']') &&
          !trimmed.contains(' ')) {
        continue;
      }
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

  Future<void> _seekBy(Duration delta) async {
    final playbackState = ref.read(playbackProvider);
    final totalDuration = playbackState.duration;
    final next = _currentPosition + delta;
    final clampedMs = next.inMilliseconds.clamp(
      0,
      totalDuration.inMilliseconds,
    );
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

  Future<void> _save() async {
    final normalizedLines = _buildNormalizedLyricsLines();
    if (normalizedLines.isEmpty) {
      _showMessage(context.l10n.lyricsEditorAddLineFirst);
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

      ref
          .read(playbackProvider.notifier)
          .updateSongLyrics(widget.song.id, lrcContent);

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
          ? context.l10n.lyricsEditorSavedWithSidecar
          : context.l10n.lyricsEditorSavedDbOnly;
      _showMessage(message);

      Navigator.of(context).pop(true);
    } catch (e) {
      _showMessage(context.l10n.lyricsEditorSaveFailed);
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _showInstructions() async {
    final l10n = AppLocalizations.of(context)!;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          l10n.lyricsSyncHelp,
          style: AppFonts.jostStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
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
                l10n.lyricsEditorSimpleSteps,
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
                l10n.lyricsEditorAdvancedSteps,
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
                l10n.lyricsEditorTipsText,
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
              style: AppFonts.jostStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
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
      padding: EdgeInsets.fromLTRB(
        20.s,
        16.s,
        20.s,
        MediaQuery.of(context).padding.bottom + 16.s,
      ),
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
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _isSaving
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: Text(
                    l10n.cancel,
                    style: AppFonts.jostStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _isSaving ? null : _save,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : const Icon(LucideIcons.save, size: 16),
                  label: Text(
                    _isSaving ? context.l10n.saving : context.l10n.saveLrc,
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
                  color: selected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 8),
                alignment: Alignment.center,
                child: Text(
                  mode == LyricsEditorViewMode.simple
                      ? l10n.simpleModeLabel
                      : l10n.advancedModeLabel,
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
                    icon: const Icon(
                      LucideIcons.chevronUp,
                      color: Colors.white70,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          context.l10n.lyricsEditorSelectedLine(
                            _selectedLineIndex + 1,
                            _lines.length,
                          ),
                          style: AppFonts.jostStyle(
                            color: Colors.white38,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          selectedLine?.text.trim().isNotEmpty == true
                              ? selectedLine!.text
                              : context.l10n.lyricsEditorPickLine,
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
                    icon: const Icon(
                      LucideIcons.chevronDown,
                      color: Colors.white70,
                    ),
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
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: selectedLine?.text.trim().isNotEmpty == true
                          ? () => _stampSelectedLine(advance: _autoAdvance)
                          : null,
                      icon: const Icon(LucideIcons.clock, size: 16),
                      label: Text(
                        _autoAdvance
                            ? context.l10n.stampAndNext
                            : context.l10n.stampNow,
                        style: AppFonts.jostStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: selectedLine?.timestamp != null
                          ? _clearSelectedTimestamp
                          : null,
                      child: Text(
                        l10n.clear,
                        style: AppFonts.jostStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
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
                      style: AppFonts.jostStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
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
