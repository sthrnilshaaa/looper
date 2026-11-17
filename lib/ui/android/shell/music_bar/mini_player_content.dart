part of 'premium_music_bar.dart';

extension _MiniPlayerContent on PremiumMusicBarState {
  Widget _buildMiniPlayerContent(
    Song song,
    bool isPlaying,
    bool useBlur,
    Color? cardBgColor,
    double cardBlurAmount,
    dynamic settings, {
    bool compact = false,
  }) {
    Widget buildHero({required String tag, required Widget child}) {
      if (settings.enableSlideGesture) return child;
      return Hero(tag: tag, child: child);
    }

    final double artSize = compact ? 40.0 : 50.0;
    final double artRadius = compact ? 26.0 : 32.0;
    final double titleFontSize = compact ? 16.0 : 18.0;
    final double artistFontSize = compact ? 12.0 : 14.0;

    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: settings.enableSlideGesture ? 1.2 : 0.0,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left Section: Song Info
          PremiumSection(
            flex: 8,
            useBlur: useBlur,
            forceTransparent: settings.enableSlideGesture,
            keepSurfaceOnDisableBlur: true,
            backgroundColor: cardBgColor,
            blurAmount: cardBlurAmount,
            useExpanded: true,
            onTap: null, // Handled by parent GestureDetector
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(36),
              bottomLeft: Radius.circular(36),
              topRight: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: SizedBox(
                    width: artSize,
                    height: artSize,
                    child: !settings.enableSlideGesture
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(artRadius),
                            child: Hero(
                              tag: 'album_art',
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  // Mini player shows static art only (Doc 20 §2 bug A17)
                                  OptimizedImage(
                                    imagePath:
                                        song.artPath != null &&
                                            !song.artPath!.startsWith('http')
                                        ? song.artPath
                                        : null,
                                    imageUrl:
                                        song.artPath != null &&
                                            song.artPath!.startsWith('http')
                                        ? song.artPath
                                        : null,
                                    fit: BoxFit.cover,
                                  ),
                                  Positioned.fill(
                                    child: SongPlaybackOverlay(
                                      isPlaying: isPlaying,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : const SizedBox(),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      buildHero(
                        tag: 'song_title',
                        child: ScrollingText(
                          text: song.title,
                          style: AppFonts.jostStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: titleFontSize.ts,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      buildHero(
                        tag: 'song_artist',
                        child: ScrollingText(
                          text: artistAlbumLabel(
                            song,
                            context.l10n,
                            showAlbum: settings.showAlbumNextToArtist as bool,
                          ),
                          style: AppFonts.jostStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: artistFontSize.ts,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          // Right Section: Play/Pause Button
          PremiumSection(
            flex: 2,
            useBlur: useBlur,
            forceTransparent: settings.enableSlideGesture,
            keepSurfaceOnDisableBlur: true,
            backgroundColor: cardBgColor,
            blurAmount: cardBlurAmount,
            heroTag: settings.enableSlideGesture
                ? null
                : 'player_play_pause_btn',
            useExpanded: true,
            onTap: null, // Handled by parent GestureDetector
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              bottomLeft: Radius.circular(12),
              topRight: Radius.circular(36),
              bottomRight: Radius.circular(36),
            ),
            child: Consumer(
              builder: (context, ref, _) {
                final isBuffering = ref.watch(
                  playbackProvider.select((s) => s.isBuffering),
                );
                return Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 2.0),
                        child: AnimatedPlayPauseIcon(
                          isPlaying: isPlaying,
                          color: Colors.white,
                          size:
                              (compact
                                      ? AppIcons.expandedPlayerPlayPauseIcon *
                                            0.8
                                      : AppIcons.expandedPlayerPlayPauseIcon)
                                  .s,
                        ),
                      ),
                      if (isBuffering)
                        SizedBox(
                          width: (compact ? 24.0 : 30.0).s,
                          height: (compact ? 24.0 : 30.0).s,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.0,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
