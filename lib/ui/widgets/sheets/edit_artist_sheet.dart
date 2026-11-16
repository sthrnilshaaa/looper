import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:looper_player/core/theme/app_fonts.dart';
import 'package:looper_player/core/services/storage/db_service.dart';
import 'package:looper_player/features/library/presentation/providers/library/library_notifier.dart';
import 'package:looper_player/features/settings/presentation/providers/settings_notifier.dart';
import 'package:looper_player/l10n/app_localizations.dart';
import 'package:looper_player/ui/widgets/sheets/edit_sheet_common.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Changes an artist's picture: one from the phone, none at all, or a fresh
/// online lookup. A picked or removed picture is kept from then on (the
/// background fetch skips the artist); fetching unlocks it again. Same look
/// as [EditAlbumSheet].
class EditArtistSheet extends ConsumerStatefulWidget {
  final Artist artist;
  const EditArtistSheet({super.key, required this.artist});

  @override
  ConsumerState<EditArtistSheet> createState() => _EditArtistSheetState();
}

class _EditArtistSheetState extends ConsumerState<EditArtistSheet> {
  // null = unchanged, '' = removed, '/path' = picked from the phone
  String? _pickedPath;
  // Shown after an online fetch, which is saved straight away.
  String? _fetchedPath;
  bool _isSaving = false;
  bool _isFetching = false;

  String get _currentImage {
    if (_pickedPath != null) return _pickedPath!;
    if (_fetchedPath != null) return _fetchedPath!;
    final image = widget.artist.artistImageUrl;
    if (image != null && !image.startsWith('http')) return image;
    return widget.artist.artPath ?? '';
  }

  Future<void> _pick() async {
    try {
      final result = await FilePicker.pickFile(type: FileType.image);
      if (result != null && result.path != null) {
        setState(() => _pickedPath = result.path!);
      }
    } catch (_) {}
  }

  void _remove() => setState(() => _pickedPath = '');

  Future<void> _fetchOnline() async {
    setState(() => _isFetching = true);
    final found = await ref
        .read(libraryProvider.notifier)
        .refetchArtistImage(widget.artist);
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    if (found) {
      final updated = await DbService.isar.artists.get(widget.artist.id);
      if (!mounted) return;
      setState(() {
        _pickedPath = null;
        _fetchedPath = updated?.artistImageUrl;
      });
    }
    setState(() => _isFetching = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          found ? l10n.artistPictureUpdated : l10n.artistPictureNotFound,
        ),
        backgroundColor: found ? Colors.green.shade800 : Colors.orange.shade800,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _save() async {
    final picked = _pickedPath;
    if (picked == null) {
      Navigator.pop(context);
      return;
    }
    setState(() => _isSaving = true);
    final success = await ref
        .read(libraryProvider.notifier)
        .setCustomArtistImage(widget.artist, picked.isEmpty ? null : picked);
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isSaving = false);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? l10n.artistPictureUpdated : l10n.failedToSaveChanges,
        ),
        backgroundColor: success ? Colors.green.shade800 : Colors.red.shade800,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final accentColor = ref.watch(settingsProvider).accent;

    return EditSheetScaffold(
      icon: LucideIcons.mic2,
      title: l10n.editArtistPicture,
      initialChildSize: 0.5,
      minChildSize: 0.35,
      maxChildSize: 0.8,
      isSaving: _isSaving,
      onSave: _save,
      children: [
        EditSheetArtwork(
          artPath: _currentImage,
          size: 160,
          placeholderIconSize: 48,
          accentColor: accentColor,
          onTap: _pick,
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            widget.artist.name,
            style: AppFonts.jostStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: Wrap(
            alignment: WrapAlignment.center,
            children: [
              TextButton.icon(
                onPressed: _isFetching ? null : _fetchOnline,
                icon: _isFetching
                    ? SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: accentColor,
                        ),
                      )
                    : Icon(LucideIcons.globe, size: 14, color: accentColor),
                label: Text(
                  l10n.fetchArtistPictureOnline,
                  style: AppFonts.jostStyle(color: accentColor, fontSize: 12),
                ),
              ),
              if (_currentImage.isNotEmpty)
                EditSheetRemoveArtworkButton(onPressed: _remove),
            ],
          ),
        ),
      ],
    );
  }
}
