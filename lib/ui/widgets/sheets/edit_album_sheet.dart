import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:looper_player/core/theme/app_fonts.dart';
import 'package:looper_player/core/services/storage/db_service.dart';
import 'package:looper_player/features/library/data/scanner/scanner.dart';
import 'package:looper_player/features/library/presentation/providers/library/library_notifier.dart';
import 'package:looper_player/features/settings/presentation/providers/settings_notifier.dart';
import 'package:looper_player/l10n/app_localizations.dart';
import 'package:looper_player/ui/widgets/sheets/edit_sheet_common.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:metadata_god/metadata_god.dart';

/// Edits an album's own metadata (name, artist, year, artwork). The name,
/// artist and year cascade to every song currently tagged with this album
/// (see [LibraryNotifier.editAlbumMetadata]) so the library's text metadata
/// stays consistent; artwork does NOT cascade - each song keeps its own
/// picture independent of the album cover. Mirrors [EditSongSheet]'s look
/// and DB-only contract for a single song.
class EditAlbumSheet extends ConsumerStatefulWidget {
  final Album album;
  const EditAlbumSheet({super.key, required this.album});

  @override
  ConsumerState<EditAlbumSheet> createState() => _EditAlbumSheetState();
}

class _EditAlbumSheetState extends ConsumerState<EditAlbumSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _artistCtrl;
  late final TextEditingController _yearCtrl;

  String? _pickedArtPath; // null = unchanged, '' = cleared, '/path' = new path
  bool _isSaving = false;
  bool _isResettingArt = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.album.name);
    _artistCtrl = TextEditingController(text: widget.album.artist ?? '');
    _yearCtrl = TextEditingController(
      text: widget.album.year != null && widget.album.year! > 0
          ? widget.album.year.toString()
          : '',
    );
    _pickedArtPath = null; // unchanged
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _artistCtrl.dispose();
    _yearCtrl.dispose();
    super.dispose();
  }

  String get _currentArtPath => _pickedArtPath ?? widget.album.artPath ?? '';

  Future<void> _pickArtwork() async {
    try {
      final result = await FilePicker.pickFile(type: FileType.image);
      if (result != null && result.path != null) {
        setState(() => _pickedArtPath = result.path!);
      }
    } catch (_) {}
  }

  void _clearArtwork() => setState(() => _pickedArtPath = '');

  /// Re-extracts the embedded cover art from one of the album's own song
  /// files (the same source a fresh library scan would use) and picks that
  /// as the album's artwork, discarding any custom image - independent of
  /// what each song's own picture is set to.
  Future<void> _resetArtworkToDefault() async {
    setState(() => _isResettingArt = true);
    try {
      final song = await DbService.isar.songs
          .filter()
          .albumEqualTo(widget.album.name)
          .findFirst();

      List<int>? pictureData;
      if (song != null) {
        try {
          final metadata = await MetadataGod.readMetadata(
            file: song.path,
          ).timeout(const Duration(milliseconds: 2000));
          pictureData = metadata.picture?.data;
        } catch (_) {}
      }

      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;

      if (pictureData != null && pictureData.isNotEmpty) {
        final newPath = await LibraryScanner().saveAlbumArt(
          widget.album.name,
          pictureData,
        );
        if (!mounted) return;
        setState(() => _pickedArtPath = newPath ?? '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.artworkResetToDefault),
            backgroundColor: Colors.green.shade800,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.noEmbeddedArtworkFound),
            backgroundColor: Colors.orange.shade800,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isResettingArt = false);
    }
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _isSaving = true);

    final notifier = ref.read(libraryProvider.notifier);
    final success = await notifier.editAlbumMetadata(
      widget.album,
      name: _nameCtrl.text,
      artist: _artistCtrl.text,
      year: int.tryParse(_yearCtrl.text) ?? 0,
      artPath: _pickedArtPath, // null = unchanged
    );

    if (mounted) {
      final l10n = AppLocalizations.of(context)!;
      setState(() => _isSaving = false);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? l10n.albumInfoUpdated : l10n.failedToSaveChanges,
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
    final accentColor = ref.watch(settingsProvider).accent;

    return EditSheetScaffold(
      icon: LucideIcons.disc,
      title: l10n.editAlbumInfo,
      initialChildSize: 0.68,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      isSaving: _isSaving,
      onSave: _save,
      children: [
        EditSheetArtwork(
          artPath: _currentArtPath,
          size: 160,
          placeholderIconSize: 48,
          accentColor: accentColor,
          onTap: _pickArtwork,
        ),
        const SizedBox(height: 10),
        Center(
          child: Wrap(
            alignment: WrapAlignment.center,
            children: [
              TextButton.icon(
                onPressed: _isResettingArt ? null : _resetArtworkToDefault,
                icon: _isResettingArt
                    ? SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: accentColor,
                        ),
                      )
                    : Icon(
                        LucideIcons.refreshCcw,
                        size: 14,
                        color: accentColor,
                      ),
                label: Text(
                  l10n.resetArtworkToDefault,
                  style: AppFonts.jostStyle(color: accentColor, fontSize: 12),
                ),
              ),
              if (_currentArtPath.isNotEmpty)
                EditSheetRemoveArtworkButton(onPressed: _clearArtwork),
            ],
          ),
        ),
        const SizedBox(height: 16),
        EditSheetField(
          controller: _nameCtrl,
          label: l10n.album,
          icon: LucideIcons.disc,
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
          controller: _yearCtrl,
          label: l10n.year,
          icon: LucideIcons.calendar,
          accentColor: accentColor,
          keyboardType: TextInputType.number,
          maxLength: 4,
        ),
      ],
    );
  }
}
