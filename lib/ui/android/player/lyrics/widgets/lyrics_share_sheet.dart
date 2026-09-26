import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gal/gal.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:looper_player/core/theme/app_fonts.dart';
import 'package:looper_player/features/library/domain/models/models.dart';
import 'package:looper_player/features/playback/domain/lyric_models.dart';
import 'package:looper_player/features/playback/presentation/widgets/lyrics/advanced_lyric_line/advanced_lyric_line.dart'
    show artworkColorProvider;
import 'package:looper_player/ui/widgets/sheets/app_bottom_sheet.dart';
import 'package:looper_player/ui/widgets/player/lyrics_share_card.dart';
import 'package:looper_player/core/utils/l10n.dart';

/// Opens the "Share Lyrics" preview sheet for [lines] of [song]. Pre-caches
/// the album art first so the card's first paint (the one that gets
/// captured) never shows a blank placeholder image.
Future<void> showLyricsShareSheet(
  BuildContext context,
  WidgetRef ref, {
  required Song song,
  required List<LyricLine> lines,
}) async {
  final artPath = song.artPath;
  if (artPath != null) {
    try {
      final file = File(artPath);
      if (await file.exists()) {
        if (!context.mounted) return;
        await precacheImage(FileImage(file), context);
      }
    } catch (_) {}
  }

  if (!context.mounted) return;

  await showModalBottomSheet(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _LyricsShareSheetContent(song: song, lines: lines),
  );
}

class _LyricsShareSheetContent extends ConsumerStatefulWidget {
  final Song song;
  final List<LyricLine> lines;

  const _LyricsShareSheetContent({required this.song, required this.lines});

  @override
  ConsumerState<_LyricsShareSheetContent> createState() =>
      _LyricsShareSheetContentState();
}

class _LyricsShareSheetContentState
    extends ConsumerState<_LyricsShareSheetContent> {
  // Curated dark presets for the card background — kept low-lightness so
  // lyric text stays readable on top of any of them.
  static const List<Color> _presetBackgroundColors = [
    Color(0xFF000000), // Black
    Color(0xFF1C1C1E), // Charcoal
    Color(0xFF161B22), // Slate
    Color(0xFF10163A), // Deep Navy
    Color(0xFF0D1B2A), // Midnight Blue
    Color(0xFF0B2A2A), // Deep Teal
    Color(0xFF0E2318), // Forest
    Color(0xFF1A1030), // Dark Purple
    Color(0xFF2A0E1B), // Wine
    Color(0xFF231710), // Espresso
    Color(0xFF1B1F3B), // Indigo Ink
    Color(0xFF2B1710), // Mahogany
    Color(0xFF122016), // Pine
    Color(0xFF2A1030), // Plum
    Color(0xFF1C2733), // Steel
    Color(0xFF211A14), // Ash Brown
    Color(0xFF2A0A0A), // Deep Crimson
    Color(0xFF17182B), // Twilight
  ];

  // Curated bright/vibrant presets for the lyric text itself — the
  // background row skews dark for readability, so this row skews the
  // opposite way for contrast against it.
  static const List<Color> _presetTextColors = [
    Color(0xFFFFFFFF), // White
    Color(0xFFF5F5F0), // Ivory
    Color(0xFFFFD60A), // Gold
    Color(0xFFFF9F0A), // Amber
    Color(0xFFFF6B6B), // Coral
    Color(0xFFFF375F), // Rose
    Color(0xFFFF2D95), // Hot Pink
    Color(0xFFBF5AF2), // Orchid
    Color(0xFF7C5CFC), // Violet
    Color(0xFF5E9EFF), // Sky Blue
    Color(0xFF64D2FF), // Cyan
    Color(0xFF34D399), // Mint
    Color(0xFF30D158), // Green
    Color(0xFFA8E063), // Lime
  ];

  final GlobalKey _cardKey = GlobalKey();
  bool _isSharing = false;
  bool _isSaving = false;
  Color _backgroundColor = LyricsShareCard.defaultBackgroundColor;

  // null = keep the default behavior (lyric text follows the artwork-derived
  // accent color); set once the user taps a swatch in the text-color row.
  Color? _textColor;

  /// The first three swatches: colors already in play for this card/app,
  /// rather than fixed presets — the card's own default background, the
  /// artwork-derived accent used for the lyric text, and the app's current
  /// theme color. Deduped in case artwork hasn't resolved yet and a couple
  /// of these happen to coincide.
  List<Color> _dynamicColors(BuildContext context, Color accentColor) {
    final seen = <Color>{};
    return [
      for (final color in [
        LyricsShareCard.defaultBackgroundColor,
        accentColor,
        Theme.of(context).colorScheme.primary,
      ])
        if (seen.add(color)) color,
    ];
  }

  /// Same idea as [_dynamicColors] but for the text row: the current
  /// (artwork-derived) accent at full opacity, white, and the theme color.
  List<Color> _dynamicTextColors(BuildContext context, Color accentColor) {
    final seen = <Color>{};
    return [
      for (final color in [
        accentColor,
        Colors.white,
        Theme.of(context).colorScheme.primary,
      ])
        if (seen.add(color)) color,
    ];
  }

  Future<Uint8List?> _captureCard() async {
    try {
      // The card's first frame(s) may still be settling (e.g. the album art
      // decoding) even though it's already visible on screen — give the
      // renderer a couple of frames before reading the layer back.
      await WidgetsBinding.instance.endOfFrame;
      await WidgetsBinding.instance.endOfFrame;
      final boundary =
          _cardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }

  Future<void> _onShare() async {
    if (_isSharing) return;
    setState(() => _isSharing = true);
    HapticFeedback.mediumImpact();
    try {
      final bytes = await _captureCard();
      if (bytes == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.couldNotGenerateShareImage)),
          );
        }
        return;
      }
      final tempDir = await getTemporaryDirectory();
      final safeTitle = widget.song.title.replaceAll(
        RegExp(r'[^a-zA-Z0-9_\-]'),
        '_',
      );
      final file = File(
        '${tempDir.path}/lyrics_${safeTitle}_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(bytes);
      if (!mounted) return;
      await Share.shareXFiles(
        [XFile(file.path)],
        text:
            '${widget.song.title} — ${widget.song.artist ?? "Unknown Artist"}',
      );
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  Future<void> _onSaveToGallery() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();
    try {
      final bytes = await _captureCard();
      if (bytes == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.couldNotGenerateImage)),
          );
        }
        return;
      }
      final safeTitle = widget.song.title.replaceAll(
        RegExp(r'[^a-zA-Z0-9_\-]'),
        '_',
      );
      await Gal.putImageBytes(
        bytes,
        album: 'Looper Player',
        name: 'lyrics_${safeTitle}_${DateTime.now().millisecondsSinceEpoch}',
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.savedToGallery)));
      }
    } on GalException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.type == GalExceptionType.accessDenied
                  ? context.l10n.galleryPermissionDenied
                  : context.l10n.couldNotSaveToGallery,
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.couldNotSaveToGallery)),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final artworkColorAsync = ref.watch(artworkColorProvider);
    final accentColor =
        artworkColorAsync.value ?? Theme.of(context).colorScheme.primary;
    final effectiveTextColor = _textColor ?? accentColor;
    final colorSwatches = [
      ..._dynamicColors(context, accentColor.withValues(alpha: 0.5)),
      ..._presetBackgroundColors,
    ];
    final textColorSwatches = [
      ..._dynamicTextColors(context, accentColor),
      ..._presetTextColors,
    ];

    return AppBottomSheetContainer(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                context.l10n.shareLyrics,
                style: AppFonts.jostStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(
                  LucideIcons.x,
                  color: Colors.white54,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: RepaintBoundary(
                key: _cardKey,
                child: LyricsShareCard(
                  song: widget.song,
                  lines: widget.lines,
                  accentColor: effectiveTextColor,
                  backgroundColor: _backgroundColor,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              context.l10n.backgroundColor,
              style: AppFonts.jostStyle(
                color: Colors.white54,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: colorSwatches.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final color = colorSwatches[index];
                return _ColorSwatchButton(
                  color: color,
                  selected: color == _backgroundColor,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _backgroundColor = color);
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              context.l10n.lyricsTextColor,
              style: AppFonts.jostStyle(
                color: Colors.white54,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: textColorSwatches.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final color = textColorSwatches[index];
                return _ColorSwatchButton(
                  color: color,
                  selected: color == effectiveTextColor,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _textColor = color);
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              onPressed: _isSaving ? null : _onSaveToGallery,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(LucideIcons.download, size: 18),
              label: Text(
                _isSaving ? context.l10n.saving : context.l10n.saveToGallery,
                style: AppFonts.jostStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _isSharing ? null : _onShare,
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: _isSharing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(LucideIcons.share2, size: 18),
              label: Text(
                _isSharing ? context.l10n.preparing : context.l10n.share,
                style: AppFonts.jostStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Circular color swatch used in the background-color row. Selected swatches
/// get a ring plus a checkmark, tinted for contrast against the swatch color.
class _ColorSwatchButton extends StatelessWidget {
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _ColorSwatchButton({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final markColor = color.computeLuminance() > 0.5
        ? Colors.black
        : Colors.white;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        width: 40,
        height: 40,
        padding: EdgeInsets.all(selected ? 3 : 0),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: selected
              ? const Border.fromBorderSide(
                  BorderSide(color: Colors.white, width: 2),
                )
              : null,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            border: Border.all(color: Colors.white24, width: 1),
          ),
          child: selected
              ? Icon(LucideIcons.check, color: markColor, size: 16)
              : null,
        ),
      ),
    );
  }
}
