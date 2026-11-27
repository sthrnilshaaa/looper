part of 'premium_music_bar.dart';

extension _MiniPlayerContent on PremiumMusicBarState {
  /// Draws the mini music bar in one of four styles (`pill`, `sections`,
  /// `artglow`, `bare`). In the Fluid Player, the panel behind draws the
  /// glass surface for `pill` and `sections`.
  Widget _buildMiniPlayerContent(
    Song song,
    bool isPlaying,
    bool useBlur,
    Color? cardBgColor,
    double cardBlurAmount,
    dynamic settings, {
    bool compact = false,
  }) {
    final bool fluid = settings.enableSlideGesture as bool;
    final barStyle = MusicBarStyle.fromSetting(
      settings.musicBarStyle as String?,
    );

    Widget buildHero({required String tag, required Widget child}) {
      if (fluid) return child;
      return Hero(tag: tag, child: child);
    }

    final bool isBare = barStyle == MusicBarStyle.bare;
    final bool isRoundArt = !isBare;
    final double artSize = isBare
        ? (compact ? 40.0 : 46.0)
        : (compact ? 40.0 : 50.0);
    final double artRadius = isBare
        ? 8.0
        : (isRoundArt ? (compact ? 26.0 : 32.0) : 8.0);
    final double iconSize = (compact ? 15.0 : 17.0).s;

    Widget artBox() => SizedBox(
      width: artSize,
      height: artSize,
      // In the Fluid Player the morph layer draws the art here.
      child: fluid
          ? null
          : DecoratedBox(
              position: DecorationPosition.foreground,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(artRadius),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15),
                  width: 0.2,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(artRadius),
                child: Hero(
                  tag: 'album_art',
                  child: OptimizedImage(
                    imagePath:
                        song.artPath != null && !song.artPath!.startsWith('http')
                        ? song.artPath
                        : null,
                    imageUrl:
                        song.artPath != null && song.artPath!.startsWith('http')
                        ? song.artPath
                        : null,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
    );

    Widget titleAndArtist() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        buildHero(
          tag: 'song_title',
          child: ScrollingText(
            text: song.title,
            style: AppFonts.jostStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: (compact ? 15.0 : 16.0).ts,
              letterSpacing: 0.2,
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
              color: Colors.white.withValues(alpha: 0.65),
              fontSize: (compact ? 12.0 : 13.0).ts,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ],
    );

    Widget playIconWidget({double? overrideSize}) => Consumer(
      builder: (context, ref, _) {
        final isBuffering = ref.watch(
          playbackProvider.select((s) => s.isBuffering),
        );
        final sz = overrideSize ?? iconSize;
        final icon = AnimatedPlayPauseIcon(
          isPlaying: isPlaying,
          color: Colors.white,
          size: sz,
        );
        return buildHero(
          tag: 'player_play_pause_btn',
          child: Stack(
            alignment: Alignment.center,
            children: [
              icon,
              if (isBuffering)
                SizedBox.square(
                  dimension: sz + 14,
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
    );

    Widget nextIconWidget({double? overrideSize}) {
      final sz = overrideSize ?? iconSize;
      return SvgPicture.asset(
        AppIcons.next,
        width: sz,
        height: sz * 15 / 18,
      );
    }

    Widget controlTap({
      required String label,
      required VoidCallback onTap,
      required Widget child,
      double? width,
    }) {
      final body = Semantics(
        button: true,
        label: label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            AppHaptics.light();
            onTap();
          },
          child: Center(child: child),
        ),
      );
      return width != null ? SizedBox(width: width, child: body) : Expanded(child: body);
    }

    // 02 · Sections: 3 pieces, 6dp gaps, echoing Classic navbar.
    if (barStyle == MusicBarStyle.sections) {
      const Color pieceFill = Color(0xB3262626);
      final Color playFill = Colors.white.withValues(alpha: 0.10);
      final Border pieceBorder = Border.all(
        color: Colors.white.withValues(alpha: 0.06),
        width: 1,
      );

      return Row(
        children: [
          Expanded(
            child: Container(
              height: double.infinity,
              decoration: BoxDecoration(
                color: pieceFill,
                border: pieceBorder,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(33),
                  bottomLeft: Radius.circular(33),
                  topRight: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  SizedBox(width: 12.0),
                  artBox(),
                  const SizedBox(width: 12),
                  Expanded(child: titleAndArtist()),
                  const SizedBox(width: 12),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
          Container(
            width: 60,
            height: double.infinity,
            decoration: BoxDecoration(
              color: playFill,
              border: pieceBorder,
              borderRadius: BorderRadius.circular(12),
            ),
            child: controlTap(
              label: isPlaying ? context.l10n.pause : context.l10n.play,
              onTap: () => ref.read(playbackProvider.notifier).togglePlay(),
              child: playIconWidget(overrideSize: 18.s),
            ),
          ),
          const SizedBox(width: 6),
          Container(
            width: 56,
            height: double.infinity,
            decoration: BoxDecoration(
              color: pieceFill,
              border: pieceBorder,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
                topRight: Radius.circular(33),
                bottomRight: Radius.circular(33),
              ),
            ),
            child: controlTap(
              label: context.l10n.skipNext,
              onTap: () => ref.read(playbackProvider.notifier).skipNext(),
              child: nextIconWidget(overrideSize: 17.s),
            ),
          ),
        ],
      );
    }

    // 04 · Bare: no surface, 56dp row + 2dp progress line below.
    if (isBare) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: compact ? 48 : 56,
              child: Row(
                children: [
                  const SizedBox(width: 6),
                  artBox(),
                  const SizedBox(width: 12),
                  Expanded(child: titleAndArtist()),
                  controlTap(
                    width: 44,
                    label: isPlaying ? context.l10n.pause : context.l10n.play,
                    onTap: () =>
                        ref.read(playbackProvider.notifier).togglePlay(),
                    child: playIconWidget(overrideSize: 20.s),
                  ),
                  controlTap(
                    width: 44,
                    label: context.l10n.skipNext,
                    onTap: () =>
                        ref.read(playbackProvider.notifier).skipNext(),
                    child: nextIconWidget(overrideSize: 20.s),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            RepaintBoundary(
              child: Consumer(
                builder: (context, ref, _) {
                  final pos = ref.watch(
                    playbackProvider.select((s) => s.position.inMilliseconds),
                  );
                  final dur = ref.watch(
                    playbackProvider.select((s) => s.duration.inMilliseconds),
                  );
                  final frac = dur > 0 ? (pos / dur).clamp(0.0, 1.0) : 0.0;
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(1),
                    child: Container(
                      height: 2,
                      color: Colors.white.withValues(alpha: 0.12),
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: frac,
                        child: Container(color: Colors.white),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    }

    // 03 · Art Glow: dark 15%-lightness artwork gradient + white 6% progress fill, no hairline, no blur.
    if (barStyle == MusicBarStyle.artglow) {
      return Consumer(
        builder: (context, ref, _) {
          final raw = ref.watch(artworkRawColorProvider).value;
          final Color c1 = raw == null
              ? const Color(0xFF2A1640)
              : HSLColor.fromColor(raw).withLightness(0.15).toColor();
          final Color c2 = raw == null
              ? const Color(0xFF2A1A1A)
              : HSLColor.fromColor(raw)
                    .withLightness(0.11)
                    .withSaturation(
                      (HSLColor.fromColor(raw).saturation * 0.7).clamp(0.0, 1.0),
                    )
                    .toColor();

          return ClipRRect(
            borderRadius: BorderRadius.circular(33),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [c1, c2, const Color(0xFF181818)],
                  stops: const [0.0, 0.70, 1.0],
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.07),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(33),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  RepaintBoundary(
                    child: Consumer(
                      builder: (context, ref, _) {
                        final pos = ref.watch(
                          playbackProvider.select(
                            (s) => s.position.inMilliseconds,
                          ),
                        );
                        final dur = ref.watch(
                          playbackProvider.select(
                            (s) => s.duration.inMilliseconds,
                          ),
                        );
                        final frac = dur > 0
                            ? (pos / dur).clamp(0.0, 1.0)
                            : 0.0;
                        return FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: frac,
                          child: ColoredBox(
                            color: Colors.white.withValues(alpha: 0.06),
                          ),
                        );
                      },
                    ),
                  ),
                  Row(
                    children: [
                      SizedBox(width: 12.0),
                      artBox(),
                      const SizedBox(width: 12),
                      Expanded(child: titleAndArtist()),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: compact ? 96 : 104,
                        child: Row(
                          children: [
                            controlTap(
                              label: isPlaying
                                  ? context.l10n.pause
                                  : context.l10n.play,
                              onTap: () => ref
                                  .read(playbackProvider.notifier)
                                  .togglePlay(),
                              child: playIconWidget(),
                            ),
                            controlTap(
                              label: context.l10n.skipNext,
                              onTap: () => ref
                                  .read(playbackProvider.notifier)
                                  .skipNext(),
                              child: nextIconWidget(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    // 01 · Pill (default): unchanged rounded glass bar with hairline.
    return PremiumSection(
      useBlur: useBlur,
      forceTransparent: fluid,
      keepSurfaceOnDisableBlur: true,
      backgroundColor: cardBgColor ?? Colors.black.withValues(alpha: 0.45),
      blurAmount: cardBlurAmount,
      showBorder: false,
      useExpanded: false,
      useCenter: false,
      onTap: null, // Handled by parent GestureDetector
      borderRadius: BorderRadius.circular(33.0),
      child: Row(
        children: [
          SizedBox(width: 12.0),
          artBox(),
          const SizedBox(width: 12),
          Expanded(child: titleAndArtist()),
          const SizedBox(width: 12),
          Container(
            width: 1,
            margin: const EdgeInsets.symmetric(vertical: 14),
            color: Colors.white.withValues(alpha: 0.15),
          ),
          SizedBox(
            width: compact ? 96 : 104,
            child: Row(
              children: [
                controlTap(
                  label: isPlaying ? context.l10n.pause : context.l10n.play,
                  onTap: () => ref.read(playbackProvider.notifier).togglePlay(),
                  child: playIconWidget(),
                ),
                controlTap(
                  label: context.l10n.skipNext,
                  onTap: () => ref.read(playbackProvider.notifier).skipNext(),
                  child: nextIconWidget(),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}
