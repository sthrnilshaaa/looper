import 'dart:ui';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:looper_player/core/app_fonts.dart';
import 'package:flutter_svg/svg.dart';
import 'package:isar_community/isar.dart';
import 'package:looper_player/core/db_service.dart';
import 'package:looper_player/core/navigation_provider.dart';
import 'package:looper_player/l10n/app_localizations.dart';
import 'package:looper_player/ui/widgets/song_options_bottom_sheet.dart';
import 'package:looper_player/features/library/domain/models/models.dart';
import 'package:looper_player/features/settings/presentation/settings_notifier.dart';
import 'package:looper_player/core/app_icons.dart';
import 'package:looper_player/ui/widgets/animated_play_pause_icon.dart';
import 'package:looper_player/core/responsive.dart';
import 'package:looper_player/core/ui_utils.dart';
import 'package:looper_player/features/playback/presentation/playback_notifier.dart';
import 'package:looper_player/ui/widgets/optimized_image.dart';
import 'package:looper_player/ui/screens/android/widgets/queue_bottom_sheet.dart';
import 'package:looper_player/ui/widgets/premium_progress_bar.dart';
import '../widgets/premium_section.dart';
import 'android_lyrics_screen.dart';
import 'player_landscape_layout.dart';
import 'package:looper_player/ui/widgets/scrolling_text.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:looper_player/features/playback/data/audio_analyzer.dart';
import 'package:looper_player/core/player_expand_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'android_expanded_player.g.dart';

@Riverpod(keepAlive: true)
Future<AudioAnalysis?> currentSongAnalysis(Ref ref) async {
  final currentSongPath = ref.watch(playbackProvider.select((s) => s.currentSong?.path));
  if (currentSongPath == null) return null;

  // 300ms debounce to prevent multiple concurrent probes when fast-skipping
  await Future.delayed(const Duration(milliseconds: 300));

  return AudioAnalyzer.analyze(currentSongPath);
}

class AndroidExpandedPlayer extends ConsumerStatefulWidget {
  const AndroidExpandedPlayer({super.key});

  @override
  ConsumerState<AndroidExpandedPlayer> createState() => _AndroidExpandedPlayerState();
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
          1.0 - (_verticalDragOffset / (screenHeight > 0 ? screenHeight : 1.0)).clamp(0.0, 1.0);
      final progress = anim.value * dragProgress;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(playerExpandProgressProvider.notifier).set(progress);
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

  void _animateDragBack() {
    final start = _verticalDragOffset;
    final animation = Tween<double>(
      begin: start,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _dismissController, curve: Curves.easeOutCubic));
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
      return 'Lossless • $ext';
    } else if (ext == 'MP3' || ext == 'M4A' || ext == 'AAC') {
      return 'High Quality • $ext';
    } else {
      return 'High Quality • Audio';
    }
  }

  void _showLyrics(BuildContext context) {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const AndroidLyricsScreen(),
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
          child: Text(l10n.noSongPlaying, style: AppFonts.jostStyle(color: Colors.white)),
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
        list.add('Lossless');
      } else if (['MP3', 'M4A', 'AAC', 'OGG'].contains(codecStr)) {
        if (cachedAnalysis.bitrate > 0 && cachedAnalysis.bitrate < 192000) {
          list.add('Standard Quality');
        } else {
          list.add('High Quality');
        }
      } else {
        list.add('Standard Quality');
      }
      list.add(codecStr);
      if (bitDepthStr.isNotEmpty) list.add(bitDepthStr);
      if (sampleRateStr.isNotEmpty) list.add(sampleRateStr);
      if (bitrateStr.isNotEmpty && !['FLAC', 'WAV', 'ALAC', 'APE'].contains(codecStr)) {
        list.add(bitrateStr);
      }
      qualityText = list.join(' • ');
    } else {
      final analysisAsync = ref.watch(currentSongAnalysisProvider);
      qualityText = analysisAsync.when(
        data: (analysis) {
          if (analysis == null) return _getFallbackQualityText(song);
          final codecStr = analysis.codec.toUpperCase();
          final bitDepthStr = analysis.bitsPerSample > 0 ? '${analysis.bitsPerSample}-bit' : '';
          final sampleRateStr = analysis.sampleRate > 0
              ? '${(analysis.sampleRate / 1000).toStringAsFixed(1)} kHz'
              : '';
          final bitrateStr = analysis.bitrate > 0
              ? '${(analysis.bitrate / 1000).round()} kbps'
              : '';

          final list = <String>[];
          if (['FLAC', 'WAV', 'ALAC', 'APE'].contains(codecStr)) {
            list.add('Lossless');
          } else if (['MP3', 'M4A', 'AAC', 'OGG'].contains(codecStr)) {
            if (analysis.bitrate > 0 && analysis.bitrate < 192000) {
              list.add('Standard Quality');
            } else {
              list.add('High Quality');
            }
          } else {
            list.add('Standard Quality');
          }
          list.add(codecStr);
          if (bitDepthStr.isNotEmpty) list.add(bitDepthStr);
          if (sampleRateStr.isNotEmpty) list.add(sampleRateStr);
          if (bitrateStr.isNotEmpty && !['FLAC', 'WAV', 'ALAC', 'APE'].contains(codecStr)) {
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
    final musicDarkness = settings.musicDarkness.isNaN ? 0.62 : settings.musicDarkness;

    // In landscape the player is two panes (see PlayerLandscapeLayout); portrait
    // keeps the original single column.
    final Size screenSize = MediaQuery.sizeOf(context);
    final PlayerLandscapeMetrics? landscape = Responsive.isLandscape(screenSize)
        ? PlayerLandscapeMetrics.of(screenSize, MediaQuery.paddingOf(context))
        : null;

    // contentOpacity is NOT watched here anymore - it used to be
    // (`ref.watch(playerExpandProgressProvider)` at the top of this whole
    // ~2000-line build()), which meant a single slide-to-expand/collapse
    // drag - which updates that provider on every raw pointer-move event -
    // rebuilt this entire method dozens of times a second. It's now
    // computed locally inside the two small Consumers that actually need
    // it (search for "contentOpacity" below), so only those thin wrappers
    // rerun per drag frame instead of the whole player.

    Widget buildHero({
      required String tag,
      required Widget child,
      HeroFlightShuttleBuilder? flightShuttleBuilder,
    }) {
      if (enableSlide) return child;
      return Hero(tag: tag, flightShuttleBuilder: flightShuttleBuilder, child: child);
    }

    // The sections below are shared by the portrait column and the landscape
    // two-pane layout (PlayerLandscapeLayout); only their padding and the
    // transport button height differ between the two.

    // Scoped to a thin wrapper so only it rebuilds per drag frame - see the
    // note on the content section in the portrait column below.
    Widget fadeWithSlide(Widget content) {
      return Consumer(
        builder: (context, ref, child) {
          final contentOpacity = enableSlide
              ? ((ref.watch(playerExpandProgressProvider) - 0.25) / 0.75)
                  .clamp(0.0, 1.0)
              : 1.0;
          // RepaintBoundary lets the engine cache this subtree as a
          // texture and just re-blend its alpha per drag frame,
          // instead of folding it into whatever layer the sibling
          // background/artwork stack is repainting that frame.
          return RepaintBoundary(
            child: Opacity(opacity: contentOpacity, child: child),
          );
        },
        child: content,
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
              child: SvgPicture.asset(
                AppIcons.close,
                width: 8,
                height: 8,
              ),
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
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
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
                    if (durationInitial != null && durationInitial.inMilliseconds > 0) {
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
                      progress = (songsRemaining / songsInitial).clamp(0.0, 1.0);
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
                    colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
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

                          final fromStyle = _getHeroStyle(fromHero, fallbackFrom);
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

                          final fromStyle = _getHeroStyle(fromHero, fallbackFrom);
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
                                      song.artist ?? 'Unknown Artist',
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
                              ref.read(playerCollapseTriggerProvider.notifier).bump();
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
                          text: song.artist ?? 'Unknown Artist',
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

    Widget buildTransportRow({required double height, required double horizontalPadding}) {
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
              onTap: () {
                HapticFeedback.lightImpact();
                _prevTapPulse.value++;
                ref.read(playbackProvider.notifier).skipPrevious();
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
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    ref.read(playbackProvider.notifier).togglePlay();
                  },
                  child: AnimatedScale(
                    scale: 1.1,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutBack,
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
              onTap: () {
                HapticFeedback.lightImpact();
                _nextTapPulse.value++;
                ref.read(playbackProvider.notifier).skipNext();
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
                              showBorder: false,
                              useBlur: useBlur,
                              showShadow: false,
                              // forceTransparent: true,
                              animate: true,
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              backgroundColor: isShuffle
                                  ? Colors.white.withOpacity(0.06)
                                  : Colors.transparent,
                              forceNoBlur: true,
                              onTap: () {
                                HapticFeedback.selectionClick();
                                ref.read(playbackProvider.notifier).toggleShuffle();
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
                                width: AppIcons.expandedPlayerSecondaryControl.s,
                                height: AppIcons.expandedPlayerSecondaryControl.s,
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
                              showShadow: false,
                              useBlur: useBlur,
                              showBorder: false,
                              // forceTransparent: true,
                              animate: true,
                              padding: const EdgeInsets.symmetric(horizontal: 18),
                              backgroundColor: repeatMode == RepeatMode.off
                                  ? Colors.transparent
                                  : Colors.white.withOpacity(0.06),
                              forceNoBlur: true,
                              onTap: () {
                                HapticFeedback.selectionClick();
                                ref.read(playbackProvider.notifier).nextRepeatMode();
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
                                width: AppIcons.expandedPlayerSecondaryControl.s,
                                height: AppIcons.expandedPlayerSecondaryControl.s,
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
                                width: AppIcons.expandedPlayerSecondaryControl.s,
                                height: AppIcons.expandedPlayerSecondaryControl.s,
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
      backgroundColor: (!enableSlide || !useBlur)
          ? Theme.of(context).colorScheme.surface
          : Colors.transparent,
      body: Stack(
        children: [
          // Background stack (Only active when slide gesture is disabled, since the parent panel draws it otherwise)
          if (!enableSlide) ...[
            if (useBlur && song.artPath != null) ...[
              Positioned.fill(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 800),
                  transitionBuilder: (child, animation) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                  child: BlurredBackgroundArt(key: ValueKey(song.artPath), song: song),
                ),
              ),
              Positioned.fill(
                child: Container(color: Colors.black.withValues(alpha: musicDarkness)),
              ),
            ] else ...[
              if (settings.enablePlayerGradient) ...[
                Positioned.fill(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeInOut,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.topCenter,
                        radius: 1.8,
                        colors: [
                          Theme.of(context).colorScheme.primary.withValues(alpha: 0.20),
                          
                          Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
                        ],
                        stops: const [0.0, 1.0],
                      ),
                    ),
                  ),
                ),
                // Same musicDarkness slider as the dynamic-art background
                // above, so it isn't a dead control when gradient mode is
                // what's actually active.
                Positioned.fill(
                  child: Container(color: Colors.black.withValues(alpha: musicDarkness)),
                ),
              ] else
                Positioned.fill(child: Container(color: Theme.of(context).colorScheme.surface)),
            ],
          ],
          if (landscape != null)
            Positioned.fill(
              child: PlayerLandscapeLayout(
                metrics: landscape,
                topBar: fadeWithSlide(
                  buildTopBar(EdgeInsets.fromLTRB(16, landscape.topBarTopPadding, 16, 0)),
                ),
                // Deliberately not wrapped in PositionReporter: in landscape the
                // artwork rect is analytic (landscape.artRect), and reporting it
                // would leave a landscape rect in playerArtworkRectProvider that
                // the portrait morph would then wrongly aim at.
                artwork: GestureArtworkWithFeedback(
                  song: song,
                  onTap: () => _showLyrics(context),
                ),
                controls: fadeWithSlide(
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      buildSongInfo(4),
                      SizedBox(height: landscape.sectionGap),
                      buildSeekBar(4),
                      SizedBox(height: landscape.sectionGap),
                      buildTransportRow(height: landscape.transportHeight, horizontalPadding: 0),
                      SizedBox(height: landscape.sectionGap),
                      buildUtilityRow(0),
                    ],
                  ),
                ),
              ),
            )
          else
            SafeArea(
              child: Column(
                children: [
                  // Top Bar
                  fadeWithSlide(buildTopBar(const EdgeInsets.fromLTRB(16, 8, 16, 0))),

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
                                ref.read(playerArtworkRectProvider.notifier).set(rect);
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

                  fadeWithSlide(
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        buildSongInfo(32),
                        const SizedBox(height: 32),
                        buildSeekBar(28),
                        const SizedBox(height: 24),
                        buildTransportRow(height: 80, horizontalPadding: 24),
                        const SizedBox(height: 24),
                        buildUtilityRow(24),
                        const SizedBox(height: 32),
                      ],
                    ),
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

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (enableSlide) {
          final double slideProgress = ref.read(playerExpandProgressProvider);
          if (slideProgress > 0.01) {
            ref.read(playerCollapseTriggerProvider.notifier).bump();
            return;
          }
        }
        final canPopNav = Navigator.of(context).canPop();
        if (canPopNav) {
          Navigator.of(context).pop();
        }
      },
      child: mainContent,
    );
  }
}

class PositionReporter extends ConsumerStatefulWidget {
  final Widget child;
  final ValueChanged<Rect> onPositionChanged;
  final GlobalKey ancestorKey;

  const PositionReporter({
    required this.child,
    required this.onPositionChanged,
    required this.ancestorKey,
    super.key,
  });

  @override
  ConsumerState<PositionReporter> createState() => _PositionReporterState();
}

class _PositionReporterState extends ConsumerState<PositionReporter> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reportPosition());
  }

  void _reportPosition() {
    if (!mounted) return;
    final double progress = ref.read(playerExpandProgressProvider);
    final enableSlide = ref.read(settingsProvider).enableSlideGesture;
    // Only report position when the player is fully expanded or slide gesture is disabled.
    // Reporting during animation/dragging causes layout feedback loop and artwork vibration.
    if (enableSlide && progress < 0.99) return;

    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    final RenderBox? ancestorBox =
        widget.ancestorKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null && ancestorBox != null) {
      final position = ancestorBox.globalToLocal(renderBox.localToGlobal(Offset.zero));
      widget.onPositionChanged(
        Rect.fromLTWH(position.dx, position.dy, renderBox.size.width, renderBox.size.height),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<double>(playerExpandProgressProvider, (previous, next) {
      if (next > 0.99 && (previous == null || previous <= 0.99)) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _reportPosition());
      }
    });
    return widget.child;
  }
}

class GestureArtworkWithFeedback extends ConsumerStatefulWidget {
  final Song song;
  final VoidCallback onTap;

  const GestureArtworkWithFeedback({super.key, required this.song, required this.onTap});

  @override
  ConsumerState<GestureArtworkWithFeedback> createState() => _GestureArtworkWithFeedbackState();
}

class _GestureArtworkWithFeedbackState extends ConsumerState<GestureArtworkWithFeedback>
    with TickerProviderStateMixin {
  String? _feedbackType; // 'rewind', 'forward', 'next', 'previous'
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _snapController;
  bool _isNext = true;
  double _dragOffset = 0.0;
  bool _skipSlideTransition = false;
  bool _isSwipeTriggered = false;

  // Precaching the next/previous song's artwork does a synchronous
  // File.existsSync() stat call - build() runs on every frame while the
  // user drags to expand/collapse the player (it watches
  // playerExpandProgressProvider), so without this guard that stat call
  // was happening every frame instead of only when the neighbor song
  // actually changes.
  String? _precachedNextArtPath;
  String? _precachedPrevArtPath;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 650));
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _snapController = AnimationController(vsync: this, duration: const Duration(milliseconds: 320));
  }

  @override
  void didUpdateWidget(GestureArtworkWithFeedback oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.song.path != widget.song.path) {
      if (_isSwipeTriggered || _dragOffset.abs() > 10.0 || _snapController.isAnimating) {
        _skipSlideTransition = true;
        _isSwipeTriggered = false;
      } else {
        _skipSlideTransition = false;
      }
      setState(() {
        _dragOffset = 0.0;
      });
      // Safely extract queue indexes to determine slide direction
      final queue = ref.read(playbackProvider).queue;
      final oldIdx = queue.indexWhere((s) => s.path == oldWidget.song.path);
      final newIdx = queue.indexWhere((s) => s.path == widget.song.path);
      if (oldIdx != -1 && newIdx != -1) {
        setState(() {
          _isNext = newIdx >= oldIdx;
        });
      }
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _snapController.dispose();
    super.dispose();
  }

  void _triggerFeedback(String type) {
    if (!mounted) return;
    setState(() {
      _feedbackType = type;
    });
    _fadeController.forward(from: 0.0).then((_) {
      if (mounted) {
        setState(() {
          _feedbackType = null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(settingsProvider);
    final enableSlide = settings.enableSlideGesture;
    final expandProgress = settings.enableSlideGesture
        ? ref.watch(playerExpandProgressProvider)
        : 1.0;
    final double artworkOpacity = !settings.enableSlideGesture || expandProgress > 0.99 ? 1.0 : 0.0;
    final isPlaying = ref.watch(playbackProvider.select((s) => s.isPlaying));
    final double targetPadding = isPlaying ? 0.0 : 2.0;
    final queue = ref.watch(playbackProvider.select((s) => s.queue));
    final repeatMode = ref.watch(playbackProvider.select((s) => s.repeatMode));
    final currentIdx = queue.indexWhere((s) => s.path == widget.song.path);

    Song? nextSong;
    Song? prevSong;

    if (currentIdx != -1) {
      if (currentIdx + 1 < queue.length) {
        nextSong = queue[currentIdx + 1];
      } else if (repeatMode == RepeatMode.all && queue.isNotEmpty) {
        nextSong = queue[0];
      }

      if (currentIdx - 1 >= 0) {
        prevSong = queue[currentIdx - 1];
      } else if (repeatMode == RepeatMode.all && queue.isNotEmpty) {
        prevSong = queue[queue.length - 1];
      }
    }

    // Swipe distances and decode size follow the artwork's own width: the full
    // window width in portrait (unchanged), but in landscape the artwork is a
    // small square beside the controls, where the window width would demand a
    // ~3x longer swipe and decode a needlessly large bitmap.
    final Size screenSize = MediaQuery.sizeOf(context);
    final bool isLandscape = Responsive.isLandscape(screenSize);
    final double slideExtent = isLandscape
        ? PlayerLandscapeMetrics.of(screenSize, MediaQuery.paddingOf(context)).artRect.width
        : screenSize.width;
    final artSize = isLandscape ? slideExtent : slideExtent - 48;
    final double dpr = MediaQuery.maybeDevicePixelRatioOf(context) ?? 2.0;
    final int computedCacheWidth = (artSize * dpr).toInt();

    final artworkSwitcher = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.04), width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 16,
            spreadRadius: -6,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 320),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
            return Stack(
              alignment: Alignment.center,
              children: <Widget>[...previousChildren, if (currentChild != null) currentChild],
            );
          },
          transitionBuilder: (Widget child, Animation<double> animation) {
            final keyVal = child.key is ValueKey<String>
                ? (child.key as ValueKey<String>).value
                : '';
            final isIncoming = keyVal == widget.song.path;

            if (_skipSlideTransition) {
              if (isIncoming) {
                return SlideTransition(
                  position: const AlwaysStoppedAnimation<Offset>(Offset.zero),
                  child: child,
                );
              } else {
                final double offset = _isNext ? -1.1 : 1.1;
                return SlideTransition(
                  position: AlwaysStoppedAnimation<Offset>(Offset(offset, 0.0)),
                  child: FadeTransition(
                    opacity: Tween<double>(begin: 1.0, end: 0.0).animate(animation),
                    child: child,
                  ),
                );
              }
            }

            Offset beginOffset;
            Offset endOffset;

            if (_isNext) {
              beginOffset = isIncoming ? const Offset(1.1, 0.0) : const Offset(-1.1, 0.0);
              endOffset = Offset.zero;
            } else {
              beginOffset = isIncoming ? const Offset(-1.1, 0.0) : const Offset(1.1, 0.0);
              endOffset = Offset.zero;
            }

            return SlideTransition(
              position: Tween<Offset>(begin: beginOffset, end: endOffset).animate(animation),
              child: child,
            );
          },
          child: ForegroundAlbumArt(key: ValueKey<String>(widget.song.path), song: widget.song),
        ),
      ),
    );

    if (nextSong?.artPath != null &&
        nextSong!.artPath != _precachedNextArtPath) {
      _precachedNextArtPath = nextSong.artPath;
      if (File(nextSong.artPath!).existsSync()) {
        precacheImage(
          ResizeImage(FileImage(File(nextSong.artPath!)), width: computedCacheWidth),
          context,
        );
      }
    }
    if (prevSong?.artPath != null &&
        prevSong!.artPath != _precachedPrevArtPath) {
      _precachedPrevArtPath = prevSong.artPath;
      if (File(prevSong.artPath!).existsSync()) {
        precacheImage(
          ResizeImage(FileImage(File(prevSong.artPath!)), width: computedCacheWidth),
          context,
        );
      }
    }
    final dragPercent = (_dragOffset / slideExtent).abs().clamp(0.0, 1.0);
    final Song? bgSong = _dragOffset < 0
        ? (nextSong ?? widget.song)
        : (_dragOffset > 0 ? (prevSong ?? widget.song) : null);

    return GestureDetector(
      onTap: widget.onTap,
      onDoubleTapDown: (details) {
        final box = context.findRenderObject() as RenderBox?;
        if (box == null) return;
        final localPos = box.globalToLocal(details.globalPosition);
        final isLeft = localPos.dx < box.size.width / 2;

        if (isLeft) {
          ref.read(playbackProvider.notifier).seekRelative(-10);
          _triggerFeedback('rewind');
        } else {
          ref.read(playbackProvider.notifier).seekRelative(10);
          _triggerFeedback('forward');
        }
      },
      onHorizontalDragUpdate: (details) {
        _snapController.stop();
        setState(() {
          _dragOffset += details.delta.dx;
        });
      },
      onHorizontalDragEnd: (details) {
        final threshold = slideExtent * 0.25;

        if (_dragOffset < -threshold ||
            (details.primaryVelocity != null && details.primaryVelocity! < -300)) {
          // Swipe Left -> Skip Next
          if (nextSong == null) {
            final start = _dragOffset;
            final animation = Tween<double>(
              begin: start,
              end: 0.0,
            ).animate(CurvedAnimation(parent: _snapController, curve: Curves.elasticOut));
            animation.addListener(() {
              setState(() {
                _dragOffset = animation.value;
              });
            });
            _snapController.forward(from: 0.0);
          } else {
            setState(() {
              _isNext = true;
              _isSwipeTriggered = true;
            });
            HapticFeedback.mediumImpact();
            final start = _dragOffset;
            final end = -slideExtent;
            final animation = Tween<double>(
              begin: start,
              end: end,
            ).animate(CurvedAnimation(parent: _snapController, curve: Curves.easeOutCubic));
            animation.addListener(() {
              setState(() {
                _dragOffset = animation.value;
              });
            });
            _snapController.forward(from: 0.0).then((_) {
              ref.read(playbackProvider.notifier).skipNext();
            });
          }
        } else if (_dragOffset > threshold ||
            (details.primaryVelocity != null && details.primaryVelocity! > 300)) {
          // Swipe Right -> Skip Previous
          if (prevSong == null) {
            final start = _dragOffset;
            final animation = Tween<double>(
              begin: start,
              end: 0.0,
            ).animate(CurvedAnimation(parent: _snapController, curve: Curves.elasticOut));
            animation.addListener(() {
              setState(() {
                _dragOffset = animation.value;
              });
            });
            _snapController.forward(from: 0.0);
          } else {
            setState(() {
              _isNext = false;
              _isSwipeTriggered = true;
            });
            HapticFeedback.mediumImpact();
            final start = _dragOffset;
            final end = slideExtent;
            final animation = Tween<double>(
              begin: start,
              end: end,
            ).animate(CurvedAnimation(parent: _snapController, curve: Curves.easeOutCubic));
            animation.addListener(() {
              setState(() {
                _dragOffset = animation.value;
              });
            });
            _snapController.forward(from: 0.0).then((_) {
              ref.read(playbackProvider.notifier).skipPrevious(force: true);
            });
          }
        } else {
          // Snap Back
          final start = _dragOffset;
          final animation = Tween<double>(
            begin: start,
            end: 0.0,
          ).animate(CurvedAnimation(parent: _snapController, curve: Curves.elasticOut));
          animation.addListener(() {
            setState(() {
              _dragOffset = animation.value;
            });
          });
          _snapController.forward(from: 0.0);
        }
      },
      child: Opacity(
        opacity: artworkOpacity,
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOutCubic,
          padding: EdgeInsets.all(targetPadding),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background Card for real-time carousel transitions (flat horizontal slide)
              if (bgSong != null && _dragOffset.abs() > 1.0)
                Positioned.fill(
                  child: Transform.translate(
                    offset: Offset(
                      _dragOffset < 0 ? _dragOffset + slideExtent : _dragOffset - slideExtent,
                      0,
                    ),
                    child: ClipRRect(
                      // borderRadius: BorderRadius.circular(12),
                      child: OptimizedImage(
                        imagePath: bgSong.artPath != null && !bgSong.artPath!.startsWith('http')
                            ? bgSong.artPath
                            : null,
                        imageUrl: bgSong.artPath != null && bgSong.artPath!.startsWith('http')
                            ? bgSong.artPath
                            : null,
                        borderRadius: BorderRadius.circular(12),

                        fit: BoxFit.cover,
                        cacheWidth: (slideExtent * dpr).toInt(),
                      ),
                    ),
                  ),
                ),

              // Active Sliding Artwork (flat horizontal slide)
              Positioned.fill(
                child: Transform.translate(
                  offset: Offset(_dragOffset, 0),
                  child: enableSlide
                      ? artworkSwitcher
                      : Hero(tag: 'album_art', child: artworkSwitcher),
                ),
              ),
              // Feedback Overlay
              if (_feedbackType != null)
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: AnimatedBuilder(
                      animation: _fadeAnimation,
                      builder: (context, child) {
                        final progress = _fadeAnimation.value;
                        final opacity = (1.0 - progress).clamp(0.0, 1.0);
                        final scale = 0.8 + (progress * 0.3);

                        Widget feedbackChild;
                        Alignment alignment = Alignment.center;

                        switch (_feedbackType) {
                          case 'rewind':
                            alignment = const Alignment(-0.5, 0.0);
                            feedbackChild = Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.replay_10_rounded, color: Colors.white, size: 48),
                                const SizedBox(height: 6),
                                Text(
                                  '-10s',
                                  style: AppFonts.jostStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            );
                            break;
                          case 'forward':
                            alignment = const Alignment(0.5, 0.0);
                            feedbackChild = Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.forward_10_rounded, color: Colors.white, size: 48),
                                const SizedBox(height: 6),
                                Text(
                                  '+10s',
                                  style: AppFonts.jostStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            );
                            break;
                          case 'next':
                            feedbackChild = Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.skip_next_rounded, color: Colors.white, size: 48),
                                const SizedBox(height: 6),
                                Text(
                                  l10n.nextLabel,
                                  style: AppFonts.jostStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            );
                            break;
                          case 'previous':
                            feedbackChild = Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.skip_previous_rounded,
                                  color: Colors.white,
                                  size: 48,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  l10n.previousLabel,
                                  style: AppFonts.jostStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            );
                            break;
                          default:
                            feedbackChild = const SizedBox.shrink();
                        }

                        return Container(
                          color: Colors.black.withValues(alpha: 0.35 * opacity),
                          alignment: alignment,
                          child: Opacity(
                            opacity: opacity,
                            child: Transform.scale(
                              scale: scale,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.black45,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: feedbackChild,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

TextStyle _getHeroStyle(Hero hero, TextStyle fallback) {
  final child = hero.child;
  if (child is ScrollingText) {
    return child.style ?? fallback;
  }
  if (child is Text) {
    return child.style ?? fallback;
  }
  return fallback;
}

class BlurredBackgroundArt extends StatelessWidget {
  final Song song;
  const BlurredBackgroundArt({required this.song, super.key});

  @override
  Widget build(BuildContext context) {
    final path = song.artPath;
    if (path == null) return const SizedBox.shrink();
    return RepaintBoundary(
      child: Transform.scale(
        scale: 1.08,
        child: ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Image.file(
            File(path),
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            filterQuality: FilterQuality.low,
            cacheWidth: 80,
            cacheHeight: 80,
            gaplessPlayback: true,
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}

class ForegroundAlbumArt extends StatelessWidget {
  final Song song;
  const ForegroundAlbumArt({required this.song, super.key});

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.sizeOf(context);
    final double decodeWidth = Responsive.isLandscape(screenSize)
        ? PlayerLandscapeMetrics.of(screenSize, MediaQuery.paddingOf(context)).artRect.width
        : screenSize.width;
    final double dpr = MediaQuery.maybeDevicePixelRatioOf(context) ?? 2.0;

    return AspectRatio(
      aspectRatio: 1.0,
      child: OptimizedImage(
        imagePath: song.artPath != null && !song.artPath!.startsWith('http') ? song.artPath : null,
        imageUrl: song.artPath != null && song.artPath!.startsWith('http') ? song.artPath : null,
        borderRadius: BorderRadius.circular(12),
        fit: BoxFit.cover,
        cacheWidth: (decodeWidth * dpr).toInt(),
      ),
    );
  }
}

class SleepTimerClock extends StatelessWidget {
  final double progress;
  final String label;
  final Color color;

  const SleepTimerClock({
    super.key,
    required this.progress,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final double size = 28.s;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _SleepTimerClockPainter(progress: progress, color: color),
          ),
          Text(
            label,
            style: GoogleFonts.jost(
              fontSize: 8.5.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _SleepTimerClockPainter extends CustomPainter {
  final double progress;
  final Color color;

  _SleepTimerClockPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 2.0) / 2;

    // Draw background circle track
    final bgPaint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, radius, bgPaint);

    // Draw active progress arc clockwise starting from top (-pi / 2)
    if (progress > 0) {
      final activePaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round;

      const startAngle = -3.141592653589793 / 2;
      final sweepAngle = 2 * 3.141592653589793 * progress;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        activePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SleepTimerClockPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

class FavoriteButtonWithGlow extends StatefulWidget {
  final Song song;
  final WidgetRef ref;
  final bool useBlur;

  const FavoriteButtonWithGlow({
    super.key,
    required this.song,
    required this.ref,
    required this.useBlur,
  });

  @override
  State<FavoriteButtonWithGlow> createState() => _FavoriteButtonWithGlowState();
}

class _FavoriteButtonWithGlowState extends State<FavoriteButtonWithGlow>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  final math.Random _random = math.Random();
  final List<double> _randomAngles = [];
  final List<double> _randomRadii = [];
  final List<double> _randomSpeeds = [];

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _generateRandomParticles();
  }

  void _generateRandomParticles() {
    _randomAngles.clear();
    _randomRadii.clear();
    _randomSpeeds.clear();
    for (int i = 0; i < 12; i++) {
      _randomAngles.add(_random.nextDouble() * 2 * math.pi);
      _randomRadii.add((_random.nextDouble() - 0.5) * 8.0);
      _randomSpeeds.add((_random.nextBool() ? 1 : -1) * (0.4 + _random.nextDouble() * 0.6));
    }
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(FavoriteButtonWithGlow oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only animate when the *same* song actually transitions to favorite
    // (a real like toggle). If the song itself changed - e.g. replaying a
    // previously-liked track after another song - don't replay the glow.
    if (oldWidget.song.id == widget.song.id &&
        !oldWidget.song.isFavorite &&
        widget.song.isFavorite) {
      if (_glowController.status != AnimationStatus.forward) {
        _generateRandomParticles();
        _glowController.forward(from: 0.0);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        PremiumSection(
          borderRadius: BorderRadius.circular(32),
          width: 56,
          height: 56,
          useExpanded: false,
          showShadow: false,
          useBlur: widget.useBlur,
          forceNoBlur: true,
          showBorder: false,
          backgroundColor: widget.song.isFavorite
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.05)
              : Colors.transparent,
          onTap: () {
            HapticFeedback.selectionClick();
            if (!widget.song.isFavorite) {
              _generateRandomParticles();
              _glowController.forward(from: 0.0);
            }
            widget.ref.read(playbackProvider.notifier).toggleFavorite();
          },
          child: Center(
            child: SvgPicture.asset(
              widget.song.isFavorite ? AppIcons.like : AppIcons.unlike,
              colorFilter: ColorFilter.mode(
                widget.song.isFavorite ? Theme.of(context).colorScheme.primary : Colors.white.withOpacity(0.2),
                BlendMode.srcIn,
              ),
              width: AppIcons.sizeLarge.s,
              height: AppIcons.sizeLarge.s,
            ),
          ),
        ),
        IgnorePointer(
          child: AnimatedBuilder(
            animation: _glowController,
            builder: (context, child) {
              return CustomPaint(
                size: const Size(56, 56),
                painter: LikedGlowPainter(
                  progress: _glowController.value,
                  randomAngles: _randomAngles,
                  randomRadii: _randomRadii,
                  randomSpeeds: _randomSpeeds,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class LikedGlowPainter extends CustomPainter {
  final double progress;
  final List<double> randomAngles;
  final List<double> randomRadii;
  final List<double> randomSpeeds;

  LikedGlowPainter({
    required this.progress,
    required this.randomAngles,
    required this.randomRadii,
    required this.randomSpeeds,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress == 0.0 || progress == 1.0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = 24.0 + progress * 10.0;
    final fade = 1.0 - progress;

    // Glowing circle stroke
    final circlePaint = Paint()
      ..color = Colors.yellow.withOpacity(0.35 * fade)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
    canvas.drawCircle(center, baseRadius, circlePaint);

    final linePaint = Paint()
      ..color = Colors.yellow.withOpacity(0.5 * fade)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, baseRadius, linePaint);
  }

  @override
  bool shouldRepaint(covariant LikedGlowPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
