import 'package:flutter/material.dart';
import 'package:looper_player/core/theme/app_fonts.dart';
import 'package:looper_player/features/library/domain/models/models.dart';
import 'package:looper_player/features/playback/domain/lyric_models.dart';
import 'package:looper_player/ui/widgets/common/optimized_image.dart';
import 'package:looper_player/core/utils/l10n.dart';

/// A shareable "lyrics card" image — album art + title/artist header
/// followed by the selected lyric lines in the song's accent color, in the
/// same compact chat-bubble style Spotify/Apple Music use for lyric shares.
///
/// Rendered at a fixed [width] logical pixels so capturing it through a
/// [RepaintBoundary] at pixelRatio 3.0 always yields a consistent ~1080px
/// wide PNG regardless of the device's screen size or density.
class LyricsShareCard extends StatelessWidget {
  static const double width = 360;

  /// The card's original background — used whenever the caller doesn't pick
  /// a custom one, and offered back as one of the share sheet's color swatches.
  static const Color defaultBackgroundColor = Color(0xFF0B0B0D);

  final Song song;
  final List<LyricLine> lines;
  final Color accentColor;
  final Color backgroundColor;

  const LyricsShareCard({
    super.key,
    required this.song,
    required this.lines,
    required this.accentColor,
    this.backgroundColor = defaultBackgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: OptimizedImage(
                  imagePath: song.artPath,
                  width: 44,
                  height: 44,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      song.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.jostStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      song.artist ?? context.l10n.unknownArtist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.jostStyle(
                        color: Colors.white54,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // App watermark — the only branding mark on the card, top-right
              // of the header, same spot as the "now playing" glyph on the
              // reference card this design is matched against.
              Image.asset(
                'assets/android_icons/music_icon_session.png',
                width: 18,
                height: 18,
                fit: BoxFit.contain,
              ),
            ],
          ),
          const SizedBox(height: 22),
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                line.text.trim().isEmpty ? '♫' : line.text,
                style: AppFonts.soraStyle(
                  color: accentColor,
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
