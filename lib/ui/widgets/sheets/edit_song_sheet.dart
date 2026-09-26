import 'dart:io';
import 'dart:ui';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:looper_player/core/theme/app_fonts.dart';
import 'package:looper_player/features/library/domain/models/models.dart';
import 'package:looper_player/features/playback/data/lrc_parser.dart';
import 'package:looper_player/features/playback/presentation/providers/playback/playback_notifier.dart';
import 'package:looper_player/features/settings/presentation/providers/settings_notifier.dart';
import 'package:looper_player/ui/widgets/common/app_loading_indicator.dart';
import 'package:looper_player/ui/android/widgets/premium_section.dart';
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
      lyrics: _lyricsCtrl.text,
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
    final settings = ref.watch(settingsProvider);
    final accentColor = Color(settings.accentColor);

    Widget content = Container(
      decoration: const BoxDecoration(
        color: Color(0xFF121212),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.93,
        minChildSize: 0.5,
        maxChildSize: 0.97,
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
                    child: Icon(
                      LucideIcons.edit3,
                      color: accentColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.editSongInfo,
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
                            width: 180,
                            height: 180,
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
                                      width: 180,
                                      height: 180,
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
                  if (_currentArtPath.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Center(
                      child: TextButton.icon(
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
                    ),
                  ],
                  const SizedBox(height: 16),

                  // ── Fields ────────────────────────────────────────────────
                  _SectionLabel(l10n.trackInfoSection),
                  const SizedBox(height: 12),
                  _EditField(
                    controller: _titleCtrl,
                    label: l10n.title,
                    icon: LucideIcons.music,
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
                        child: _EditField(
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
                        child: _EditField(
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
                  _EditField(
                    controller: _lyricsCtrl,
                    label: l10n.lyricsPlainTextOrLrc,
                    icon: LucideIcons.fileText,
                    accentColor: accentColor,
                    maxLines: 8,
                    keyboardType: TextInputType.multiline,
                    hintText: l10n.editLyricsHint,
                  ),

                  const SizedBox(height: 32),

                  // ── File path (read-only info) ─────────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.06),
                      ),
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
                            widget.song.path.split('/').last,
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
    // (and whichever field is focused, e.g. Lyrics near the bottom) stays
    // above the keyboard.
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
      size: 56,
    ),
  );
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

class _EditField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final Color accentColor;
  final bool required;
  final TextInputType keyboardType;
  final int? maxLength;
  final int maxLines;
  final String? hintText;

  const _EditField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.accentColor,
    this.required = false,
    this.keyboardType = TextInputType.text,
    this.maxLength,
    this.maxLines = 1,
    this.hintText,
  });

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    style: AppFonts.jostStyle(color: Colors.white, fontSize: 15),
    keyboardType: keyboardType,
    maxLength: maxLength,
    maxLines: maxLines,
    buildCounter: maxLength != null
        ? (ctx, {required currentLength, required isFocused, maxLength}) => null
        : null,
    decoration: InputDecoration(
      labelText: '$label${required ? ' *' : ''}',
      labelStyle: AppFonts.jostStyle(
        color: Colors.white.withValues(alpha: 0.45),
        fontSize: 13,
      ),
      hintText: hintText,
      hintStyle: AppFonts.jostStyle(
        color: Colors.white.withValues(alpha: 0.25),
        fontSize: 13,
      ),
      prefixIcon: Icon(icon, color: accentColor, size: 20),
      alignLabelWithHint: maxLines > 1,
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
