import 'dart:ui';
import 'dart:io';
import 'package:looper_player/core/utils/ui_utils.dart';
import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:looper_player/ui/widgets/common/optimized_image.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:looper_player/core/providers/navigation_provider.dart';
import '../../../../features/playback/presentation/providers/playback/playback_notifier.dart';
import 'package:looper_player/l10n/app_localizations.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:looper_player/ui/widgets/common/color_maper.dart';
import 'package:looper_player/features/settings/presentation/providers/settings_notifier.dart';
import '../../../android/player/equalizer/android_equalizer_screen.dart';
import '../premium_progress_bar.dart';
import 'equal_height_track_shape.dart';
part 'bouncy_tap.dart';

class PlayerBar extends ConsumerWidget {
  const PlayerBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final song = ref.watch(playbackProvider.select((s) => s.currentSong));
    if (song == null) return const SizedBox.shrink();

    return const _PremiumPlayerBar();
  }
}

class _PremiumPlayerBar extends ConsumerWidget {
  const _PremiumPlayerBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final song = ref.watch(playbackProvider.select((s) => s.currentSong));
    if (song == null) return const SizedBox.shrink();

    final isFavorite = ref.watch(
      playbackProvider.select((s) => s.currentSong?.isFavorite ?? false),
    );
    final isShuffle = ref.watch(playbackProvider.select((s) => s.isShuffle));
    final repeatMode = ref.watch(playbackProvider.select((s) => s.repeatMode));
    final isPlaying = ref.watch(playbackProvider.select((s) => s.isPlaying));
    final volume = ref.watch(playbackProvider.select((s) => s.volume));

    final isLyricsActive = ref.watch(
      appNavigationProvider.select((s) => s.activeItem == NavItem.lyrics),
    );
    final isQueueActive = ref.watch(
      appNavigationProvider.select((s) => s.activeItem == NavItem.queue),
    );
    final isDynamic = ref.watch(
      settingsProvider.select((s) => s.enableDynamicTheming),
    );

    final title = song.title;
    final artist = song.artist ?? AppLocalizations.of(context)!.unknownArtist;
    final artPath = song.artPath;

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isNarrow = constraints.maxWidth < 900;
        final bool isVeryNarrow = constraints.maxWidth < 600;

        return Container(
          height: 80.s,
          margin: Platform.isAndroid || Platform.isIOS
              ? EdgeInsets.zero
              : EdgeInsets.only(left: 48.s, right: 48.s, bottom: 32.sp, top: 0),
          decoration: BoxDecoration(
            color: isDynamic
                ? colorScheme.primary.withValues(alpha: 0.04)
                : colorScheme.surfaceContainer,
            borderRadius: Platform.isAndroid || Platform.isIOS
                ? BorderRadius.zero
                : BorderRadius.circular(6),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 24,
                spreadRadius: -4,
              ),
            ],
          ),
          child: RepaintBoundary(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 1, sigmaY: 1),
                child: Padding(
                  padding: const EdgeInsets.only(left: 14),
                  child: Row(
                    children: [
                      Expanded(
                        flex: isVeryNarrow ? 3 : 4,
                        child: _buildSongInfo(
                          context,
                          title,
                          artist,
                          artPath,
                          isVeryNarrow,
                        ),
                      ),

                      if (!isVeryNarrow)
                        Container(
                          height: 40,
                          width: 1,
                          margin: const EdgeInsets.symmetric(horizontal: 12),
                          color: Colors.white10,
                        ),

                      _buildControls(
                        context,
                        ref,
                        colorScheme,
                        isPlaying,
                        isShuffle,
                        repeatMode,
                        isVeryNarrow,
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        flex: isNarrow ? 4 : 6,
                        child: Consumer(
                          builder: (context, ref, child) {
                            final position = ref.watch(
                              playbackProvider.select((s) => s.position),
                            );
                            final duration = ref.watch(
                              playbackProvider.select((s) => s.duration),
                            );
                            final isPlayingVal = ref.watch(
                              playbackProvider.select((s) => s.isPlaying),
                            );
                            return ExpressiveSlider(
                              position: position,
                              duration: duration,
                              isPlaying: isPlayingVal,
                              onSeek: (pos) =>
                                  ref.read(playbackProvider.notifier).seek(pos),
                              onSeekStart: () => ref
                                  .read(playbackProvider.notifier)
                                  .startScrubbing(),
                              onSeekEnd: () => ref
                                  .read(playbackProvider.notifier)
                                  .stopScrubbing(),
                              color: colorScheme.primary,
                            );
                          },
                        ),
                      ),

                      if (!isVeryNarrow) ...[
                        const SizedBox(width: 24),
                        Container(
                          height: 40,
                          width: 1,
                          margin: const EdgeInsets.symmetric(horizontal: 12),
                          color: Colors.white10,
                        ),
                        const SizedBox(width: 12),
                      ],
                      if (!isNarrow) ...[
                        const SizedBox(width: 16),
                        _buildVolumeControl(context, ref, volume),
                        const SizedBox(width: 16),
                      ],

                      const Spacer(),

                      _buildActions(
                        context,
                        ref,
                        colorScheme,
                        isFavorite,
                        isLyricsActive,
                        isQueueActive,
                        isVeryNarrow,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSongInfo(
    BuildContext context,
    String title,
    String artist,
    String? artPath,
    bool isVeryNarrow,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      children: [
        Container(
          width: (isVeryNarrow ? 40 : 56).s,
          height: (isVeryNarrow ? 40 : 56).s,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
          child: OptimizedImage(
            imagePath: artPath,
            borderRadius: BorderRadius.circular(6),
            fit: BoxFit.cover,
            placeholder: Icon(
              LucideIcons.music,
              color: Colors.white24,
              size: (isVeryNarrow ? 16 : 24).s,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.normal,
                  fontSize: (isVeryNarrow ? 12 : 14).ts,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                artist,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: (isVeryNarrow ? 10 : 12).ts,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildControls(
    BuildContext context,
    WidgetRef ref,
    ColorScheme colorScheme,
    bool isPlaying,
    bool isShuffle,
    RepeatMode repeatMode,
    bool isVeryNarrow,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: () => ref.read(playbackProvider.notifier).skipPrevious(),
          icon: SvgPicture.asset(
            'assets/music_bar_Icons/prev_track.svg',
            width: 12,
            height: 12,
            colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
          ),
          tooltip: l10n.previousLabel,
        ),
        const SizedBox(width: 4),
        _BouncyTap(
          onTap: () => ref.read(playbackProvider.notifier).togglePlay(),
          child: Container(
            width: (isVeryNarrow ? 28 : 36).s,
            height: (isVeryNarrow ? 28 : 36).s,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: isPlaying
                ? Icon(
                    Icons.pause,
                    color: Colors.white,
                    size: (isVeryNarrow ? 12 : 18).s,
                  )
                : Icon(
                    Icons.play_arrow_sharp,
                    color: Colors.white,
                    size: (isVeryNarrow ? 12 : 18).s,
                  ),
          ),
        ),
        const SizedBox(width: 4),
        IconButton(
          onPressed: () => ref.read(playbackProvider.notifier).skipNext(),
          icon: SvgPicture.asset(
            'assets/music_bar_Icons/next_track.svg',
            width: 12,
            height: 12,
            colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
          ),
          tooltip: l10n.nextLabel,
        ),
        if (!isVeryNarrow)
          Container(
            height: 40,
            width: 1,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            color: Colors.white10,
          ),

        if (!isVeryNarrow) ...[
          const SizedBox(width: 12),
          IconButton(
            onPressed: () =>
                ref.read(playbackProvider.notifier).toggleShuffle(),
            icon: SvgPicture.asset(
              'assets/music_bar_Icons/shuffle.svg',
              width: 12,
              height: 12,
              colorFilter: ColorFilter.mode(
                isShuffle ? colorScheme.primary : Colors.white38,
                BlendMode.srcIn,
              ),
            ),
            tooltip: l10n.shuffleTitle,
          ),
        ],
        if (!isVeryNarrow)
          IconButton(
            onPressed: () =>
                ref.read(playbackProvider.notifier).nextRepeatMode(),
            icon: SvgPicture.asset(
              repeatMode == RepeatMode.one
                  ? 'assets/music_bar_Icons/repeat_1.svg'
                  : 'assets/music_bar_Icons/repeat.svg',
              width: 12,
              height: 12,
              colorFilter: repeatMode == RepeatMode.one
                  ? null
                  : ColorFilter.mode(
                      repeatMode == RepeatMode.all
                          ? Colors.white
                          : Colors.white38,
                      BlendMode.srcIn,
                    ),
              colorMapper: repeatMode == RepeatMode.one
                  ? AccentColorMapper(colorScheme.primary)
                  : null,
            ),
            tooltip: l10n.repeatTooltip,
          ),
      ],
    );
  }

  Widget _buildVolumeControl(
    BuildContext context,
    WidgetRef ref,
    double volume,
  ) {
    return ClipRect(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => ref.read(playbackProvider.notifier).toggleMute(),
            icon: SvgPicture.asset(
              volume == 0
                  ? 'assets/music_bar_Icons/mute.svg'
                  : 'assets/music_bar_Icons/volume.svg',
              width: 12,
              height: 12,
              colorFilter: ColorFilter.mode(
                volume == 0 ? Colors.white38 : Colors.white,
                BlendMode.srcIn,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 100,
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: Platform.isLinux ? 4.0 : 6.0,
                trackShape: const EqualHeightTrackShape(),
                thumbShape: LineThumbShape(
                  thumbHeight: Platform.isLinux ? 8 : 0,
                  thumbWidth: 3,
                ),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                activeTrackColor: Theme.of(context).colorScheme.primary,
                inactiveTrackColor: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.1),
                thumbColor: Colors.white,
              ),
              child: Slider(
                value: volume,
                onChanged: (vol) =>
                    ref.read(playbackProvider.notifier).setVolume(vol),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(
    BuildContext context,
    WidgetRef ref,
    ColorScheme colorScheme,
    bool isFavorite,
    bool isLyricsActive,
    bool isQueueActive,
    bool isVeryNarrow,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        if (!isVeryNarrow)
          IconButton(
            icon: SvgPicture.asset(
              isFavorite
                  ? 'assets/music_bar_Icons/liked.svg'
                  : 'assets/music_bar_Icons/like.svg',
              width: 16,
              height: 16,
              colorFilter: ColorFilter.mode(
                isFavorite ? Colors.red : Colors.white54,
                BlendMode.srcIn,
              ),
            ),
            onPressed: () =>
                ref.read(playbackProvider.notifier).toggleFavorite(),
            tooltip: l10n.favoriteTooltip,
          ),
        const SizedBox(width: 4),
        IconButton(
          icon: SvgPicture.asset(
            'assets/music_bar_Icons/lyrics.svg',
            width: 16,
            height: 16,
            colorFilter: ColorFilter.mode(
              isLyricsActive ? colorScheme.primary : Colors.white54,
              BlendMode.srcIn,
            ),
          ),
          onPressed: () => ref
              .read(appNavigationProvider.notifier)
              .toggleItem(NavItem.lyrics),
          tooltip: l10n.lyrics,
        ),
        const SizedBox(width: 4),
        IconButton(
          icon: Icon(
            LucideIcons.listMusic,
            size: 16,
            color: isQueueActive ? colorScheme.primary : Colors.white54,
          ),
          onPressed: () => ref
              .read(appNavigationProvider.notifier)
              .toggleItem(NavItem.queue),
          tooltip: l10n.queue,
        ),
        const SizedBox(width: 4),
        IconButton(
          icon: Icon(
            LucideIcons.sliders,
            size: 16,
            color: ref.watch(settingsProvider.select((s) => s.equalizerEnabled))
                ? colorScheme.primary
                : Colors.white54,
          ),
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              useSafeArea: true,
              backgroundColor: Colors.transparent,
              builder: (context) => const AndroidEqualizerScreen(),
            );
          },
          tooltip: l10n.equalizer,
        ),
      ],
    );
  }
}
