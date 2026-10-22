import 'package:looper_player/core/utils/desktop_paths.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:looper_player/core/theme/app_fonts.dart';
import 'package:looper_player/features/library/domain/models/models.dart';
import 'package:looper_player/features/playback/data/lrc_parser.dart';
import 'package:looper_player/features/playback/presentation/providers/playback/playback_notifier.dart';
import 'package:looper_player/features/settings/presentation/providers/settings_notifier.dart';
import 'package:looper_player/ui/widgets/sheets/edit_sheet_common.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:looper_player/l10n/app_localizations.dart';

class EditSongSheet extends ConsumerStatefulWidget {
  final Song song;
  const EditSongSheet({super.key, required this.song});

  @override
  ConsumerState<EditSongSheet> createState() => _EditSongSheetState();
}

class _EditSongSheetState extends ConsumerState<EditSongSheet> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _artistCtrl;
  late final TextEditingController _albumCtrl;
  late final TextEditingController _yearCtrl;
  late final TextEditingController _genreCtrl;
  late final TextEditingController _lyricsCtrl;

  /// The lyrics text the sheet opened with, to tell an edit from none.
  late final String _shownLyrics;

  String? _pickedArtPath; // null = unchanged, '' = cleared, '/path' = new path
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.song.title);
    _artistCtrl = TextEditingController(text: widget.song.artist ?? '');
    _albumCtrl = TextEditingController(text: widget.song.album ?? '');
    _yearCtrl = TextEditingController(
      text: widget.song.year != null && widget.song.year! > 0
          ? widget.song.year.toString()
          : '',
    );
    _genreCtrl = TextEditingController(text: widget.song.genre ?? '');
    _lyricsCtrl = TextEditingController(
      text: LrcParser.stripSourceTag(widget.song.lyrics) ?? '',
    );
    _shownLyrics = _lyricsCtrl.text;
    _pickedArtPath = null; // unchanged
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _artistCtrl.dispose();
    _albumCtrl.dispose();
    _yearCtrl.dispose();
    _genreCtrl.dispose();
    _lyricsCtrl.dispose();
    super.dispose();
  }

  String get _currentArtPath => _pickedArtPath ?? widget.song.artPath ?? '';

  Future<void> _pickArtwork() async {
    try {
      final result = await FilePicker.pickFile(type: FileType.image);
      if (result != null && result.path != null) {
        setState(() => _pickedArtPath = result.path!);
      }
    } catch (_) {}
  }

  void _clearArtwork() => setState(() => _pickedArtPath = '');

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) return;
    setState(() => _isSaving = true);

    final notifier = ref.read(playbackProvider.notifier);
    final success = await notifier.editSongMetadata(
      widget.song,
      title: _titleCtrl.text,
      artist: _artistCtrl.text,
      album: _albumCtrl.text,
      year: int.tryParse(_yearCtrl.text) ?? 0,
      genre: _genreCtrl.text,
      artPath: _pickedArtPath, // null = unchanged
      // null = untouched: the saved lyrics (maybe newer and word-synced
      // than this sheet's copy) are kept as they are.
      lyrics: _lyricsCtrl.text.trim() == _shownLyrics.trim()
          ? null
          : _lyricsCtrl.text,
    );

    if (mounted) {
      final l10n = AppLocalizations.of(context)!;
      setState(() => _isSaving = false);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? l10n.songInfoUpdated : l10n.failedToSaveChanges,
          ),
          backgroundColor: success
              ? Colors.green.shade800
              : Colors.red.shade800,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final accentColor = Color(ref.watch(settingsProvider).accentColor);

    return EditSheetScaffold(
      icon: LucideIcons.edit3,
      title: l10n.editSongInfo,
      initialChildSize: 0.93,
      minChildSize: 0.5,
      maxChildSize: 0.97,
      isSaving: _isSaving,
      onSave: _save,
      children: [
        EditSheetArtwork(
          artPath: _currentArtPath,
          size: 180,
          placeholderIconSize: 56,
          accentColor: accentColor,
          onTap: _pickArtwork,
        ),
        if (_currentArtPath.isNotEmpty) ...[
          const SizedBox(height: 10),
          Center(child: EditSheetRemoveArtworkButton(onPressed: _clearArtwork)),
        ],
        const SizedBox(height: 16),

        _SectionLabel(l10n.trackInfoSection),
        const SizedBox(height: 12),
        EditSheetField(
          controller: _titleCtrl,
          label: l10n.title,
          icon: LucideIcons.music,
          accentColor: accentColor,
          required: true,
        ),
        const SizedBox(height: 12),
        EditSheetField(
          controller: _artistCtrl,
          label: l10n.artist,
          icon: LucideIcons.mic2,
          accentColor: accentColor,
        ),
        const SizedBox(height: 12),
        EditSheetField(
          controller: _albumCtrl,
          label: l10n.album,
          icon: LucideIcons.disc,
          accentColor: accentColor,
        ),
        const SizedBox(height: 28),

        _SectionLabel(l10n.detailsSection),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: EditSheetField(
                controller: _yearCtrl,
                label: l10n.year,
                icon: LucideIcons.calendar,
                accentColor: accentColor,
                keyboardType: TextInputType.number,
                maxLength: 4,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: EditSheetField(
                controller: _genreCtrl,
                label: l10n.genre,
                icon: LucideIcons.tag,
                accentColor: accentColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),

        _SectionLabel(l10n.lyricsSection),
        const SizedBox(height: 12),
        EditSheetField(
          controller: _lyricsCtrl,
          label: l10n.lyricsPlainTextOrLrc,
          icon: LucideIcons.fileText,
          accentColor: accentColor,
          maxLines: 8,
          keyboardType: TextInputType.multiline,
          hintText: l10n.editLyricsHint,
        ),

        const SizedBox(height: 32),

        // File path (read-only info)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: Row(
            children: [
              const Icon(
                LucideIcons.fileAudio,
                color: Colors.white38,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  displayFileName(widget.song.path),
                  style: AppFonts.jostStyle(
                    color: Colors.white38,
                    fontSize: 12,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: AppFonts.jostStyle(
      color: Colors.white38,
      fontSize: 11,
      fontWeight: FontWeight.bold,
      letterSpacing: 1.5,
    ),
  );
}
