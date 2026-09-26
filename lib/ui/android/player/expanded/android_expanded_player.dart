import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:looper_player/core/theme/app_fonts.dart';
import 'package:flutter_svg/svg.dart';
import 'package:isar_community/isar.dart';
import 'package:looper_player/core/services/storage/db_service.dart';
import 'package:looper_player/core/providers/navigation_provider.dart';
import 'package:looper_player/l10n/app_localizations.dart';
import 'package:looper_player/ui/widgets/sheets/song_options_bottom_sheet.dart';
import 'package:looper_player/features/settings/presentation/providers/settings_notifier.dart';
import 'package:looper_player/core/theme/app_icons.dart';
import 'package:looper_player/ui/widgets/player/animated_play_pause_icon.dart';
import 'package:looper_player/core/utils/responsive.dart';
import 'package:looper_player/core/utils/ui_utils.dart';
import 'package:looper_player/features/playback/presentation/providers/playback/playback_notifier.dart';
import 'package:looper_player/ui/android/widgets/queue_bottom_sheet.dart';
import 'package:looper_player/ui/widgets/player/premium_progress_bar.dart';
import '../../widgets/premium_section.dart';
import '../lyrics/android_lyrics_screen.dart';
import 'player_landscape_layout.dart';
import '../../shell/music_bar/fluid_player_motion.dart';
import 'package:looper_player/ui/widgets/common/scrolling_text.dart';
import 'package:looper_player/features/playback/data/audio_analyzer.dart';
import 'package:looper_player/core/providers/player_expand_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'position_reporter.dart';
import 'gesture_artwork.dart';
import 'player_backgrounds.dart';
import 'sleep_timer_clock.dart';
import 'favorite_button.dart';
import 'package:looper_player/core/utils/l10n.dart';
export 'position_reporter.dart';
export 'player_backgrounds.dart';

part 'android_expanded_player.g.dart';
part 'hero_text_style.dart';

@Riverpod(keepAlive: true)
Future<AudioAnalysis?> currentSongAnalysis(Ref ref) async {
  final currentSongPath = ref.watch(
    playbackProvider.select((s) => s.currentSong?.path),
  );
  if (currentSongPath == null) return null;

  // 300ms debounce to prevent multiple concurrent probes when fast-skipping
  await Future.delayed(const Duration(milliseconds: 300));

  return AudioAnalyzer.analyze(currentSongPath);
}

class AndroidExpandedPlayer extends ConsumerStatefulWidget {
  const AndroidExpandedPlayer({super.key});

  @override
  ConsumerState<AndroidExpandedPlayer> createState() =>
      _AndroidExpandedPlayerState();
}

class _AndroidExpandedPlayerState extends ConsumerState<AndroidExpandedPlayer>
    with SingleTickerProviderStateMixin {
  final GlobalKey _playerRootKey = GlobalKey();
  double _verticalDragOffset = 0.0;
  late AnimationController _dismissController;
  // Independent tap pulses for the prev/next transport icons so tapping one
  // never replays the other's "pop" animation (each button owns its own key).
  final ValueNotifier<int> _prevTapPulse = ValueNotifier<int>(0);
  final ValueNotifier<int> _nextTapPulse = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    _dismissController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
  }

  Animation<double>? _routeAnimation;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final routeAnimation = ModalRoute.of(context)?.animation;
    final enableSlide = ref.read(settingsProvider).enableSlideGesture;
    if (!enableSlide && _routeAnimation != routeAnimation) {
      _routeAnimation?.removeListener(_onRouteAnimationTick);
      _routeAnimation = routeAnimation;
      _routeAnimation?.addListener(_onRouteAnimationTick);
      _onRouteAnimationTick();
    }
  }

  void _onRouteAnimationTick() {
    final anim = _routeAnimation;
    if (anim != null) {
      final screenHeight = MediaQuery.of(context).size.height;
      final dragProgress =
          1.0 -
          (_verticalDragOffset / (screenHeight > 0 ? screenHeight : 1.0)).clamp(
            0.0,
            1.0,
          );
      final progress = anim.value * dragProgress;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(playerExpandProgressProvider).value = progress;
        }
      });
    }
  }

  @override
  void dispose() {
    _routeAnimation?.removeListener(_onRouteAnimationTick);
    _dismissController.dispose();
    _prevTapPulse.dispose();
    _nextTapPulse.dispose();
    super.dispose();
  }

  // Runs [action] once the current frame has been drawn. Used for track
  // skips: the song change rebuilds much of the player, and doing it in the
  // same frame as the button's press/pulse start dropped exactly the frames
  // that make the tap feel responsive.
  void _afterThisFrame(VoidCallback action) {
    SchedulerBinding.instance.endOfFrame.then((_) {
      if (mounted) action();
    });
  }

  void _animateDragBack() {
    final start = _verticalDragOffset;
    final animation = Tween<double>(begin: start, end: 0.0).animate(
      CurvedAnimation(parent: _dismissController, curve: Curves.easeOutCubic),
    );
    animation.addListener(() {
      setState(() {
        _verticalDragOffset = animation.value;
      });
      _onRouteAnimationTick();
    });
    _dismissController.forward(from: 0.0);
  }

  String _formatDuration(Duration d) {
    return UiUtils.formatPlaybackDuration(d);
  }

  String _getFallbackQualityText(Song song) {
    final ext = song.path.split('.').last.toLowerCase().toUpperCase();
    if (['FLAC', 'WAV', 'ALAC', 'APE'].contains(ext)) {
      return '${context.l10n.qualityLossless} • $ext';
    } else if (ext == 'MP3' || ext == 'M4A' || ext == 'AAC') {
      return '${context.l10n.qualityHigh} • $ext';
    } else {
      return '${context.l10n.qualityHigh} • ${context.l10n.qualityAudio}';
    }
  }

  void _showLyrics(BuildContext context) {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const AndroidLyricsScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  void _showMoreOptionsBottomSheet(BuildContext context, WidgetRef ref) {
    final currentSong = ref.read(playbackProvider).currentSong;
    if (currentSong != null) {
      showSongOptionsBottomSheet(context: context, ref: ref, song: currentSong);
    }
  }

  @override
  Widget build(BuildContext context) {
    final song = ref.watch(playbackProvider.select((s) => s.currentSong));
    final l10n = AppLocalizations.of(context)!;

    if (song == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: Center(
          child: Text(
            l10n.noSongPlaying,
            style: AppFonts.jostStyle(color: Colors.white),
          ),
        ),
      );
    }

    // Synchronously check the cache first to avoid any 300ms debounce flickering
    final cachedAnalysis = AudioAnalyzer.getCachedAnalysis(song.path);
    final String qualityText;

    if (cachedAnalysis != null) {
      final codecStr = cachedAnalysis.codec.toUpperCase();
      final bitDepthStr = cachedAnalysis.bitsPerSample > 0
          ? '${cachedAnalysis.bitsPerSample}-bit'
          : '';
      final sampleRateStr = cachedAnalysis.sampleRate > 0
          ? '${(cachedAnalysis.sampleRate / 1000).toStringAsFixed(1)} kHz'
          : '';
      final bitrateStr = cachedAnalysis.bitrate > 0
          ? '${(cachedAnalysis.bitrate / 1000).round()} kbps'
          : '';

      final list = <String>[];
      if (['FLAC', 'WAV', 'ALAC', 'APE'].contains(codecStr)) {
        list.add(context.l10n.qualityLossless);
      } else if (['MP3', 'M4A', 'AAC', 'OGG'].contains(codecStr)) {
        if (cachedAnalysis.bitrate > 0 && cachedAnalysis.bitrate < 192000) {
          list.add(context.l10n.qualityStandard);
        } else {
          list.add(context.l10n.qualityHigh);
        }
      } else {
        list.add(context.l10n.qualityStandard);
      }
      list.add(codecStr);
      if (bitDepthStr.isNotEmpty) list.add(bitDepthStr);
      if (sampleRateStr.isNotEmpty) list.add(sampleRateStr);
      if (bitrateStr.isNotEmpty &&
          !['FLAC', 'WAV', 'ALAC', 'APE'].contains(codecStr)) {
        list.add(bitrateStr);
      }
      qualityText = list.join(' • ');
    } else {
      final analysisAsync = ref.watch(currentSongAnalysisProvider);
      qualityText = analysisAsync.when(
        data: (analysis) {
          if (analysis == null) return _getFallbackQualityText(song);
          final codecStr = analysis.codec.toUpperCase();
          final bitDepthStr = analysis.bitsPerSample > 0
              ? '${analysis.bitsPerSample}-bit'
              : '';
          final sampleRateStr = analysis.sampleRate > 0
              ? '${(analysis.sampleRate / 1000).toStringAsFixed(1)} kHz'
              : '';
          final bitrateStr = analysis.bitrate > 0
              ? '${(analysis.bitrate / 1000).round()} kbps'
              : '';

          final list = <String>[];
          if (['FLAC', 'WAV', 'ALAC', 'APE'].contains(codecStr)) {
            list.add(context.l10n.qualityLossless);
          } else if (['MP3', 'M4A', 'AAC', 'OGG'].contains(codecStr)) {
            if (analysis.bitrate > 0 && analysis.bitrate < 192000) {
              list.add(context.l10n.qualityStandard);
            } else {
              list.add(context.l10n.qualityHigh);
            }
          } else {
            list.add(context.l10n.qualityStandard);
          }
          list.add(codecStr);
          if (bitDepthStr.isNotEmpty) list.add(bitDepthStr);
          if (sampleRateStr.isNotEmpty) list.add(sampleRateStr);
          if (bitrateStr.isNotEmpty &&
              !['FLAC', 'WAV', 'ALAC', 'APE'].contains(codecStr)) {
            list.add(bitrateStr);
          }
          return list.join(' • ');
        },
        loading: () => _getFallbackQualityText(song),
        error: (_, _) => _getFallbackQualityText(song),
      );
    }

    final settings = ref.watch(settingsProvider);
    final useBlur = settings.enableDynamicTheming;
    final enableSlide = settings.enableSlideGesture;
    final musicDarkness = settings.musicDarkness.isNaN
        ? 0.62
        : settings.musicDarkness;

    // In landscape the player is two panes (see PlayerLandscapeLayout); portrait
    // keeps the original single column.
    final Size screenSize = MediaQuery.sizeOf(context);
    final PlayerLandscapeMetrics? landscape = Responsive.isLandscape(screenSize)
        ? PlayerLandscapeMetrics.of(screenSize, MediaQuery.paddingOf(context))
        : null;

    // contentOpacity is NOT watched here anymore - it used to be
    // (`ref.watch(playerExpandProgressProvider)` at the top of this whole
    // ~2000-line build()), which meant a single slide-to-expand/collapse
    // drag - which updates the progress on every raw pointer-move event -
    // rebuilt this entire method dozens of times a second. It's now
    // computed locally inside the small ValueListenableBuilders that
    // actually need it (search for "contentOpacity" below), so only those
    // thin wrappers rerun per drag frame instead of the whole player.

    Widget buildHero({
      required String tag,
      required Widget child,
      HeroFlightShuttleBuilder? flightShuttleBuilder,
    }) {
      if (enableSlide) return child;
      return Hero(
        tag: tag,
        flightShuttleBuilder: flightShuttleBuilder,
        child: child,
      );
    }

    // The sections below are shared by the portrait column and the landscape
    // two-pane layout (PlayerLandscapeLayout); only their padding and the
    // transport button height differ between the two.

    // Fluid Player entrance of one section: fades in and rises a short way
    // into place over its own slice of the expand progress (see
    // FluidSectionMotion - bottom sections first, following the panel as it
    // uncovers them). Scoped to a thin wrapper so only it rebuilds per drag
    // frame. The RepaintBoundary sits *inside* the Opacity/Transform: the
    // section is painted once and each frame only re-blends and offsets
    // that cached layer.
    final ValueNotifier<double> expandProgress = ref.watch(
      playerExpandProgressProvider,
    );
    Widget fadeWithSlide(Widget content, FluidSectionMotion motion) {
      if (!enableSlide) return content;
      return ValueListenableBuilder<double>(
        valueListenable: expandProgress,
        builder: (context, progress, child) {
          return Opacity(
            opacity: motion.opacity(progress),
            child: Transform.translate(
              offset: Offset(0.0, motion.offsetY(progress)),
              child: child,
            ),
          );
        },
        child: RepaintBoundary(child: content),
      );
    }

    Widget buildTopBar(EdgeInsets padding) {
      return Padding(
        padding: padding,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            PremiumSection(
              borderRadius: BorderRadius.circular(32),
              width: 48,
              showShadow: false,
              height: 48,
              forceNoBlur: true,
              showBorder: false,
              useExpanded: false,
              backgroundColor: Colors.transparent,
              useBlur: true,
              onTap: () {
                HapticFeedback.lightImpact();
                if (enableSlide) {
                  ref.read(playerCollapseTriggerProvider.notifier).bump();
                } else {
                  Navigator.of(context).pop();
                }
              },
              child: SvgPicture.asset(AppIcons.close, width: 8, height: 8),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (!settings.showQualityBadge)
                  Text(
                    l10n.nowPlaying,
                    style: AppFonts.jostStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                if (settings.showQualityBadge)
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      qualityText,
                      style: AppFonts.jostStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
              ],
            ),
            Consumer(
              builder: (context, ref, child) {
                final isSleepActive = ref.watch(
                  playbackProvider.select((s) => s.isSleepTimerActive),
                );
                final durationRemaining = ref.watch(
                  playbackProvider.select((s) => s.sleepTimerDurationRemaining),
                );
                final durationInitial = ref.watch(
                  playbackProvider.select((s) => s.sleepTimerDurationInitial),
                );
                final songsRemaining = ref.watch(
                  playbackProvider.select((s) => s.sleepTimerSongsRemaining),
                );
                final songsInitial = ref.watch(
                  playbackProvider.select((s) => s.sleepTimerSongsInitial),
                );

                Widget iconChild;
                if (isSleepActive) {
                  double progress = 1.0;
                  String label = '';
                  if (durationRemaining != null) {
                    if (durationInitial != null &&
                        durationInitial.inMilliseconds > 0) {
                      progress =
                          (durationRemaining.inMilliseconds /
                                  durationInitial.inMilliseconds)
                              .clamp(0.0, 1.0);
                    }
                    final minutes = durationRemaining.inMinutes;
                    if (minutes >= 1) {
                      label = '${minutes}m';
                    } else {
                      final seconds = durationRemaining.inSeconds;
                      label = '${seconds}s';
                    }
                  } else if (songsRemaining != null) {
                    if (songsInitial != null && songsInitial > 0) {
                      progress = (songsRemaining / songsInitial).clamp(
                        0.0,
                        1.0,
                      );
                    }
                    label = '$songsRemaining';
                  }

                  iconChild = SleepTimerClock(
                    progress: progress,
                    label: label,
                    color: Theme.of(context).colorScheme.primary,
                  );
                } else {
                  iconChild = SvgPicture.asset(
                    AppIcons.more,
                    colorFilter: const ColorFilter.mode(
                      Colors.white,
                      BlendMode.srcIn,
                    ),
                    width: AppIcons.morebuttonsize.s,
                    height: AppIcons.morebuttonsize.s,
                  );
                }

                return PremiumSection(
                  height: 48,
                  width: 48,
                  useBlur: true,
                  useExpanded: false,
                  showShadow: false,
                  forceNoBlur: true,
                  backgroundColor: Colors.transparent,
                  showBorder: false,
                  onTap: () => _showMoreOptionsBottomSheet(context, ref),
                  borderRadius: BorderRadius.circular(32),

                  child: iconChild,
                );
              },
            ),
          ],
        ),
      );
    }

    // Song info and favorite button.
    Widget buildSongInfo(double horizontalPadding) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildHero(
                    tag: 'song_title',
                    flightShuttleBuilder:
                        (
                          flightContext,
                          animation,
                          flightDirection,
                          fromHeroContext,
                          toHeroContext,
                        ) {
                          final Hero fromHero = fromHeroContext.widget as Hero;
                          final Hero toHero = toHeroContext.widget as Hero;

                          final fallbackFrom = AppFonts.jostStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                          );
                          final fallbackTo = AppFonts.jostStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                          );

                          final fromStyle = _getHeroStyle(
                            fromHero,
                            fallbackFrom,
                          );
                          final toStyle = _getHeroStyle(toHero, fallbackTo);

                          return AnimatedBuilder(
                            animation: animation,
                            builder: (context, child) {
                              final lerpValue =
                                  flightDirection == HeroFlightDirection.push
                                  ? animation.value
                                  : 1.0 - animation.value;
                              return Material(
                                type: MaterialType.transparency,
                                child: ClipRect(
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      song.title,
                                      style: TextStyle.lerp(
                                        fromStyle,
                                        toStyle,
                                        lerpValue,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      softWrap: false,
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                    child: ScrollingText(
                      text: song.title,
                      style: AppFonts.jostStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  // const SizedBox(height: 2),
                  buildHero(
                    tag: 'song_artist',
                    flightShuttleBuilder:
                        (
                          flightContext,
                          animation,
                          flightDirection,
                          fromHeroContext,
                          toHeroContext,
                        ) {
                          final Hero fromHero = fromHeroContext.widget as Hero;
                          final Hero toHero = toHeroContext.widget as Hero;

                          final fallbackFrom = AppFonts.jostStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 14,
                            letterSpacing: 0.2,
                          );
                          final fallbackTo = AppFonts.jostStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 18,
                            letterSpacing: 0.2,
                          );

                          final fromStyle = _getHeroStyle(
                            fromHero,
                            fallbackFrom,
                          );
                          final toStyle = _getHeroStyle(toHero, fallbackTo);

                          return AnimatedBuilder(
                            animation: animation,
                            builder: (context, child) {
                              final lerpValue =
                                  flightDirection == HeroFlightDirection.push
                                  ? animation.value
                                  : 1.0 - animation.value;
                              return Material(
                                type: MaterialType.transparency,
                                child: ClipRect(
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      song.artist ?? context.l10n.unknownArtist,
                                      style: TextStyle.lerp(
                                        fromStyle,
                                        toStyle,
                                        lerpValue,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      softWrap: false,
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () async {
                          if (song.artist != null) {
                            final artistSongs = await DbService.isar.songs
                                .filter()
                                .artistEqualTo(song.artist!)
                                .findAll();
                            final artist = await DbService.isar.artists
                                .filter()
                                .nameEqualTo(song.artist!)
                                .findFirst();

                            if (enableSlide) {
                              ref
                                  .read(playerCollapseTriggerProvider.notifier)
                                  .bump();
                            }

                            ref
                                .read(appNavigationProvider.notifier)
                                .showCollection(
                                  title: song.artist!,
                                  subtitle: l10n.artists,
                                  art: artist?.artPath ?? song.artPath,
                                  imageUrl: artist?.artistImageUrl,
                                  songs: artistSongs,
                                );
                          }
                          if (!enableSlide) {
                            Navigator.pop(context);
                          }
                        },
                        child: ScrollingText(
                          text: song.artist ?? context.l10n.unknownArtist,
                          style: AppFonts.jostStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 18,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            FavoriteButtonWithGlow(song: song, ref: ref, useBlur: useBlur),
          ],
        ),
      );
    }

    Widget buildSeekBar(double horizontalPadding) {
      // Wrapped in its own RepaintBoundary: it rebuilds on
      // every playback position tick regardless of whether
      // the player is being dragged, so without this its
      // frequent repaints force the whole song-info/controls
      // block around it to repaint too.
      return RepaintBoundary(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Consumer(
            builder: (context, ref, child) {
              final position = ref.watch(
                playbackProvider.select((s) => s.position),
              );
              final duration = ref.watch(
                playbackProvider.select((s) => s.duration),
              );
              final isPlaying = ref.watch(
                playbackProvider.select((s) => s.isPlaying),
              );
              return buildHero(
                tag: 'player_seek_bar',
                child: Material(
                  type: MaterialType.transparency,
                  child: ExpressiveSlider(
                    position: position,
                    duration: duration,
                    isPlaying: isPlaying,
                    onSeek: (pos) =>
                        ref.read(playbackProvider.notifier).seek(pos),
                    onSeekStart: () =>
                        ref.read(playbackProvider.notifier).startScrubbing(),
                    onSeekEnd: () =>
                        ref.read(playbackProvider.notifier).stopScrubbing(),
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              );
            },
          ),
        ),
      );
    }

    Widget buildTransportRow({
      required double height,
      required double horizontalPadding,
    }) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: Row(
          children: [
            // Previous
            PremiumSection(
              heroTag: 'player_prev_btn',
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(40),
                bottomLeft: Radius.circular(40),
                topRight: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              height: height,
              showShadow: false,
              useBlur: useBlur,
              forceNoBlur: true,
              backgroundColor: Colors.white.withOpacity(0.04),
              showBorder: false,
              instantPressFeedback: true,
              onTap: () {
                HapticFeedback.lightImpact();
                _prevTapPulse.value++;
                _afterThisFrame(
                  () => ref.read(playbackProvider.notifier).skipPrevious(),
                );
              },
              child: ValueListenableBuilder<int>(
                valueListenable: _prevTapPulse,
                builder: (context, tick, child) {
                  return AnimatedTransportIcon(
                    asset: AppIcons.prev,
                    color: Colors.white,
                    size: AppIcons.expandedPlayerMainControl.s,
                    triggerKey: tick,
                  );
                },
              ),
            ),
            const SizedBox(width: 6),
            // Play/Pause
            Consumer(
              builder: (context, ref, child) {
                final isPlaying = ref.watch(
                  playbackProvider.select((s) => s.isPlaying),
                );
                return PremiumSection(
                  heroTag: 'player_play_pause_btn',
                  borderRadius: BorderRadius.circular(12),
                  height: height,
                  showShadow: false,
                  useBlur: useBlur,
                  showBorder: false,

                  forceNoBlur: true,
                  animate: true,
                  backgroundColor: isPlaying
                      ? Colors.white.withOpacity(0.04)
                      : Theme.of(context).colorScheme.primary,
                  instantPressFeedback: true,
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    ref.read(playbackProvider.notifier).togglePlay();
                  },
                  // A constant 1.1 (the AnimatedScale this replaced never
                  // animated - its target never changed).
                  child: Transform.scale(
                    scale: 1.1,
                    child: AnimatedPlayPauseIcon(
                      isPlaying: isPlaying,
                      color: isPlaying
                          ? Colors.white
                          : HSLColor.fromColor(
                              Theme.of(context).colorScheme.primary,
                            ).withLightness(0.15).toColor(),
                      size: AppIcons.expandedPlayerPlayPauseIcon.s,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 6),
            // Next
            PremiumSection(
              heroTag: 'player_next_btn',
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
                topRight: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
              height: height,
              useBlur: useBlur,
              backgroundColor: Colors.white.withOpacity(0.04),
              showShadow: false,
              forceNoBlur: true,
              showBorder: false,
              instantPressFeedback: true,
              onTap: () {
                HapticFeedback.lightImpact();
                _nextTapPulse.value++;
                _afterThisFrame(
                  () => ref.read(playbackProvider.notifier).skipNext(),
                );
              },
              child: ValueListenableBuilder<int>(
                valueListenable: _nextTapPulse,
                builder: (context, tick, child) {
                  return AnimatedTransportIcon(
                    asset: AppIcons.next,
                    color: Colors.white,
                    size: AppIcons.expandedPlayerMainControl.s,
                    triggerKey: tick,
                  );
                },
              ),
            ),
          ],
        ),
      );
    }

    // Bottom utilities: shuffle / repeat / next up / lyrics.
    Widget buildUtilityRow(double horizontalPadding) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Below this width the "Next Up"/"Lyrics" labels (longer still
            // in several translations than the English strings) no longer
            // fit next to the Shuffle/Repeat cluster, so collapse them to
            // icon-only pills instead of letting the row overflow past the
            // device width.
            final bool showLabels = constraints.maxWidth >= 350;

            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Shuffle + Repeat
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(6),

                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Consumer(
                          builder: (context, ref, child) {
                            final isShuffle = ref.watch(
                              playbackProvider.select((s) => s.isShuffle),
                            );
                            return PremiumSection(
                              heroTag: 'nav_morph_1',
                              height: 40,
                              useExpanded: false,
                              instantPressFeedback: true,
                              showBorder: false,
                              useBlur: useBlur,
                              showShadow: false,
                              // forceTransparent: true,
                              animate: true,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              backgroundColor: isShuffle
                                  ? Colors.white.withOpacity(0.06)
                                  : Colors.transparent,
                              forceNoBlur: true,
                              onTap: () {
                                HapticFeedback.selectionClick();
                                ref
                                    .read(playbackProvider.notifier)
                                    .toggleShuffle();
                              },
                              borderRadius: BorderRadius.circular(32),
                              child: SvgPicture.asset(
                                AppIcons.shuffle,
                                colorFilter: ColorFilter.mode(
                                  isShuffle
                                      ? Colors.white
                                      : Colors.white.withOpacity(0.5),
                                  BlendMode.srcIn,
                                ),
                                width:
                                    AppIcons.expandedPlayerSecondaryControl.s,
                                height:
                                    AppIcons.expandedPlayerSecondaryControl.s,
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 2),
                        // Repeat
                        Consumer(
                          builder: (context, ref, child) {
                            final repeatMode = ref.watch(
                              playbackProvider.select((s) => s.repeatMode),
                            );
                            return PremiumSection(
                              height: 40,
                              useExpanded: false,
                              instantPressFeedback: true,
                              showShadow: false,
                              useBlur: useBlur,
                              showBorder: false,
                              // forceTransparent: true,
                              animate: true,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                              ),
                              backgroundColor: repeatMode == RepeatMode.off
                                  ? Colors.transparent
                                  : Colors.white.withOpacity(0.06),
                              forceNoBlur: true,
                              onTap: () {
                                HapticFeedback.selectionClick();
                                ref
                                    .read(playbackProvider.notifier)
                                    .nextRepeatMode();
                              },
                              borderRadius: BorderRadius.circular(32),
                              child: SvgPicture.asset(
                                repeatMode == RepeatMode.off
                                    ? AppIcons.repeat
                                    : repeatMode == RepeatMode.one
                                    ? AppIcons.repeatOne
                                    : AppIcons.repeatAll,
                                colorFilter: repeatMode == RepeatMode.off
                                    ? ColorFilter.mode(
                                        Colors.white.withOpacity(0.5),
                                        BlendMode.srcIn,
                                      )
                                    : ColorFilter.mode(
                                        repeatMode != RepeatMode.off
                                            ? Colors.white
                                            : Colors.white,
                                        BlendMode.srcIn,
                                      ),
                                // Bumped up from the shared expandedPlayerSecondaryControl size (16) --
                                // the repeat button specifically should read larger than its siblings.
                                width: AppIcons.miniPlayerIcon.s,
                                height: AppIcons.miniPlayerIcon.s,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                // Next Up + Lyrics
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Next Up
                        PremiumSection(
                          height: 40,
                          useExpanded: false,
                          instantPressFeedback: true,
                          useBlur: useBlur,
                          showShadow: false,
                          heroTag: 'nav_morph_2',
                          showBorder: false,
                          forceNoBlur: true,
                          padding: EdgeInsets.symmetric(
                            horizontal: showLabels ? 16 : 12,
                          ),
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            showModalBottomSheet(
                              context: context,
                              useRootNavigator: true,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => const QueueBottomSheet(),
                            );
                          },
                          borderRadius: BorderRadius.circular(22),
                          backgroundColor: Colors.white.withOpacity(0.06),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SvgPicture.asset(
                                AppIcons.queue,
                                colorFilter: const ColorFilter.mode(
                                  Colors.white,
                                  BlendMode.srcIn,
                                ),
                                width:
                                    AppIcons.expandedPlayerSecondaryControl.s,
                                height:
                                    AppIcons.expandedPlayerSecondaryControl.s,
                              ),
                              if (showLabels) ...[
                                const SizedBox(width: 8),
                                Text(
                                  l10n.nextUp,
                                  style: AppFonts.jostStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 4),
                        // Lyrics
                        PremiumSection(
                          heroTag: 'nav_morph_3',
                          height: 40,
                          useExpanded: false,
                          instantPressFeedback: true,
                          showBorder: false,
                          useBlur: useBlur,
                          showShadow: false,
                          forceNoBlur: true,
                          backgroundColor: Colors.white.withOpacity(0.06),
                          padding: EdgeInsets.symmetric(
                            horizontal: showLabels ? 16 : 12,
                          ),
                          onTap: () => _showLyrics(context),
                          borderRadius: BorderRadius.circular(22),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SvgPicture.asset(
                                AppIcons.lyrics,
                                colorFilter: const ColorFilter.mode(
                                  Colors.white,
                                  BlendMode.srcIn,
                                ),
                                width:
                                    AppIcons.expandedPlayerSecondaryControl.s,
                                height:
                                    AppIcons.expandedPlayerSecondaryControl.s,
                              ),
                              if (showLabels) ...[
                                const SizedBox(width: 8),
                                Text(
                                  l10n.lyrics,
                                  style: AppFonts.jostStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );
    }

    final child = Scaffold(
      key: _playerRootKey,
      // In the Fluid Player the surface fill is a layer below that fades in
      // with the content, since this player is kept mounted (and would
      // otherwise cover the mini bar) while collapsed.
      backgroundColor: !enableSlide
          ? Theme.of(context).colorScheme.surface
          : Colors.transparent,
      body: Stack(
        children: [
          // Skipped with the gradient on: the panel's background is already
          // opaque then, and this fill would paint over the gradient.
          if (enableSlide && !useBlur && !settings.enablePlayerGradient)
            Positioned.fill(
              child: fadeWithSlide(
                ColoredBox(color: Theme.of(context).colorScheme.surface),
                FluidSectionMotion.backgroundFill,
              ),
            ),
          // Background stack (Only active when slide gesture is disabled, since the parent panel draws it otherwise)
          if (!enableSlide) ...[
            if (useBlur && song.artPath != null) ...[
              Positioned.fill(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 800),
                  transitionBuilder: (child, animation) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                  child: BlurredBackgroundArt(
                    key: ValueKey(song.artPath),
                    song: song,
                  ),
                ),
              ),
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: musicDarkness),
                ),
              ),
            ] else ...[
              if (settings.enablePlayerGradient)
                Positioned.fill(
                  child: PlayerGradientBackground(
                    darkness: musicDarkness,
                    animated: settings.animatePlayerGradient,
                  ),
                )
              else
                Positioned.fill(
                  child: Container(
                    color: Theme.of(context).colorScheme.surface,
                  ),
                ),
            ],
          ],
          if (landscape != null)
            Positioned.fill(
              child: PlayerLandscapeLayout(
                metrics: landscape,
                topBar: fadeWithSlide(
                  buildTopBar(
                    EdgeInsets.fromLTRB(16, landscape.topBarTopPadding, 16, 0),
                  ),
                  FluidSectionMotion.topBar,
                ),
                // Deliberately not wrapped in PositionReporter: in landscape the
                // artwork rect is analytic (landscape.artRect), and reporting it
                // would leave a landscape rect in playerArtworkRectProvider that
                // the portrait morph would then wrongly aim at.
                artwork: GestureArtworkWithFeedback(
                  song: song,
                  onTap: () => _showLyrics(context),
                ),
                controls: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    fadeWithSlide(
                      buildSongInfo(4),
                      FluidSectionMotion.songInfo,
                    ),
                    SizedBox(height: landscape.sectionGap),
                    fadeWithSlide(buildSeekBar(4), FluidSectionMotion.seekBar),
                    SizedBox(height: landscape.sectionGap),
                    fadeWithSlide(
                      buildTransportRow(
                        height: landscape.transportHeight,
                        horizontalPadding: 0,
                      ),
                      FluidSectionMotion.transportRow,
                    ),
                    SizedBox(height: landscape.sectionGap),
                    fadeWithSlide(
                      buildUtilityRow(0),
                      FluidSectionMotion.utilityRow,
                    ),
                  ],
                ),
              ),
            )
          else
            SafeArea(
              child: Column(
                children: [
                  // Top Bar
                  fadeWithSlide(
                    buildTopBar(const EdgeInsets.fromLTRB(16, 8, 16, 0)),
                    FluidSectionMotion.topBar,
                  ),

                  // Large Album Art and Lyrics above it
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Active Lyric Line (Moved above art)
                          AspectRatio(
                            aspectRatio: 1.0,
                            child: PositionReporter(
                              ancestorKey: _playerRootKey,
                              onPositionChanged: (rect) {
                                ref
                                    .read(playerArtworkRectProvider.notifier)
                                    .set(rect);
                              },
                              child: GestureArtworkWithFeedback(
                                song: song,
                                onTap: () => _showLyrics(context),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      fadeWithSlide(
                        buildSongInfo(32),
                        FluidSectionMotion.songInfo,
                      ),
                      const SizedBox(height: 32),
                      fadeWithSlide(
                        buildSeekBar(28),
                        FluidSectionMotion.seekBar,
                      ),
                      const SizedBox(height: 24),
                      fadeWithSlide(
                        buildTransportRow(height: 80, horizontalPadding: 24),
                        FluidSectionMotion.transportRow,
                      ),
                      const SizedBox(height: 24),
                      fadeWithSlide(
                        buildUtilityRow(24),
                        FluidSectionMotion.utilityRow,
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );

    final mainContent = enableSlide
        ? child
        : GestureDetector(
            onVerticalDragEnd: (details) {
              if (details.primaryVelocity! > 300) {
                HapticFeedback.mediumImpact();
                Navigator.of(context).pop();
              }
            },
            child: child,
          );

    // The Fluid Player lives inside the main screen's route and stays mounted
    // while collapsed; AndroidMainScreen's own PopScope already collapses it
    // on back, so registering a second handler here would only double-fire.
    if (enableSlide) return mainContent;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        final canPopNav = Navigator.of(context).canPop();
        if (canPopNav) {
          Navigator.of(context).pop();
        }
      },
      child: mainContent,
    );
  }
}
