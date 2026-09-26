import 'dart:io';
import 'dart:ui';

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
import 'package:looper_player/ui/widgets/common/app_loading_indicator.dart';
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
    final settings = ref.watch(settingsProvider);
    final accentColor = Color(settings.accentColor);

    Widget content = Container(
      decoration: const BoxDecoration(
        color: Color(0xFF121212),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.68,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (ctx, scrollController) => Column(
          children: [
            // Header bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(LucideIcons.disc, color: accentColor, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.editAlbumInfo,
                          style: AppFonts.jostStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          l10n.tapFieldToEdit,
                          style: AppFonts.jostStyle(
                            color: Colors.white38,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                children: [
                  // ── Artwork picker ────────────────────────────────────────
                  Center(
                    child: GestureDetector(
                      onTap: _pickArtwork,
                      child: Stack(
                        children: [
                          Container(
                            width: 160,
                            height: 160,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: accentColor.withValues(alpha: 0.4),
                                width: 2,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(22),
                              child: _currentArtPath.isNotEmpty
                                  ? Image.file(
                                      File(_currentArtPath),
                                      width: 160,
                                      height: 160,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) =>
                                          _artPlaceholder(accentColor),
                                    )
                                  : _artPlaceholder(accentColor),
                            ),
                          ),
                          // Camera badge
                          Positioned(
                            right: 8,
                            bottom: 8,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: accentColor,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: accentColor.withValues(alpha: 0.5),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                LucideIcons.camera,
                                color: Colors.black,
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      children: [
                        TextButton.icon(
                          onPressed: _isResettingArt
                              ? null
                              : _resetArtworkToDefault,
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
                            style: AppFonts.jostStyle(
                              color: accentColor,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        if (_currentArtPath.isNotEmpty)
                          TextButton.icon(
                            onPressed: _clearArtwork,
                            icon: const Icon(
                              LucideIcons.x,
                              size: 14,
                              color: Colors.redAccent,
                            ),
                            label: Text(
                              l10n.removeArtwork,
                              style: AppFonts.jostStyle(
                                color: Colors.redAccent,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Fields ────────────────────────────────────────────────
                  _EditField(
                    controller: _nameCtrl,
                    label: l10n.album,
                    icon: LucideIcons.disc,
                    accentColor: accentColor,
                    required: true,
                  ),
                  const SizedBox(height: 12),
                  _EditField(
                    controller: _artistCtrl,
                    label: l10n.artist,
                    icon: LucideIcons.mic2,
                    accentColor: accentColor,
                  ),
                  const SizedBox(height: 12),
                  _EditField(
                    controller: _yearCtrl,
                    label: l10n.year,
                    icon: LucideIcons.calendar,
                    accentColor: accentColor,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                  ),

                  const SizedBox(height: 32),

                  // ── Save button ────────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: Colors.black,
                        disabledBackgroundColor: accentColor.withValues(
                          alpha: 0.4,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        elevation: 4,
                        shadowColor: accentColor.withValues(alpha: 0.4),
                      ),
                      child: _isSaving
                          ? const AppLoadingIndicator(size: 44)
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(LucideIcons.check, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  l10n.saveChangesBtn,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    // Blur wrapper when dynamic theming is on
    if (settings.enableDynamicTheming && !settings.disableBlur) {
      content = ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: content,
        ),
      );
    }

    // The DraggableScrollableSheet above sizes itself as a fraction of
    // whatever height it's given, which by default is the full screen --
    // the keyboard just overlaps the bottom of it instead of the sheet
    // shrinking to sit above it. Padding the whole sheet by the live
    // keyboard inset shrinks that available height instead, so the sheet
    // (and whichever field is focused) stays above the keyboard.
    return AnimatedPadding(
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: content,
    );
  }

  Widget _artPlaceholder(Color accentColor) => Container(
    color: Colors.white.withValues(alpha: 0.05),
    child: Icon(
      LucideIcons.imageOff,
      color: accentColor.withValues(alpha: 0.5),
      size: 48,
    ),
  );
}

class _EditField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final Color accentColor;
  final bool required;
  final TextInputType keyboardType;
  final int? maxLength;

  const _EditField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.accentColor,
    this.required = false,
    this.keyboardType = TextInputType.text,
    this.maxLength,
  });

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    style: AppFonts.jostStyle(color: Colors.white, fontSize: 15),
    keyboardType: keyboardType,
    maxLength: maxLength,
    buildCounter: maxLength != null
        ? (ctx, {required currentLength, required isFocused, maxLength}) => null
        : null,
    decoration: InputDecoration(
      labelText: '$label${required ? ' *' : ''}',
      labelStyle: AppFonts.jostStyle(
        color: Colors.white.withValues(alpha: 0.45),
        fontSize: 13,
      ),
      prefixIcon: Icon(icon, color: accentColor, size: 20),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.05),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: accentColor, width: 1.5),
      ),
    ),
  );
}
