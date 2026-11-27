import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:looper_player/core/services/haptics/app_haptics.dart';
import 'package:looper_player/core/theme/app_fonts.dart';
import 'package:looper_player/core/utils/song_metadata.dart';
import 'package:looper_player/core/utils/ui_utils.dart';
import 'package:looper_player/features/library/domain/models/models.dart';
import 'package:looper_player/features/playback/presentation/providers/lyrics/lyrics_notifier.dart';
import 'package:looper_player/features/playback/presentation/providers/playback/playback_notifier.dart';
import 'package:looper_player/l10n/app_localizations.dart';
import 'package:looper_player/ui/android/player/expanded/favorite_button.dart';
import 'package:looper_player/ui/android/player/lyrics/lyrics_screen_style.dart';
import 'package:looper_player/ui/widgets/common/optimized_image.dart';

String _fmtDur(Duration d) {
  final sec = d.inSeconds.clamp(0, 359999);
  final m = (sec ~/ 60).toString().padLeft(2, '0');
  final s = (sec % 60).toString().padLeft(2, '0');
  return '$m:$s';
}

(int current, int total) _activeLineIndex(
  List<dynamic> lines,
  Duration position,
) {
  if (lines.isEmpty) return (0, 0);
  int idx = 0;
  for (int i = 0; i < lines.length; i++) {
    if ((lines[i].startTime as Duration) <= position) {
      idx = i;
    } else {
      break;
    }
  }
  return (idx + 1, lines.length);
}

/// Optional style-specific background override for [LyricsScreenStyle].
/// Returns null when the style should use the standard ambient/blurred/gradient
/// background.
Widget? buildLyricsStyledBackground(
  BuildContext context,
  LyricsScreenStyle style, {
  bool isLandscape = false,
}) {
  final accent = Theme.of(context).colorScheme.primary;
  return switch (style) {
    LyricsScreenStyle.oled => const ColoredBox(color: Colors.black),
    LyricsScreenStyle.vinyl => const DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.55),
          radius: 1.15,
          colors: [Color(0xFF241A14), Color(0xFF0D0A08), Color(0xFF050403)],
        ),
      ),
    ),
    LyricsScreenStyle.editorial => const ColoredBox(color: Color(0xFF0F0F0C)),
    LyricsScreenStyle.karaoke => _KaraokeSpotlightBg(
      accent: accent,
      isLandscape: isLandscape,
    ),
    LyricsScreenStyle.m3 => DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(const Color(0xFF0D0D0D), accent, 0.10)!,
            const Color(0xFF0A0A0A),
          ],
        ),
      ),
    ),
    LyricsScreenStyle.timeline => const _TimelineGridBg(),
    LyricsScreenStyle.zen => _ZenBreathingBg(accent: accent),
    LyricsScreenStyle.bigtype => ColoredBox(
      color: Color.lerp(const Color(0xFF080808), accent, 0.10)!,
    ),
    _ => null,
  };
}

Color lyricsScrimColor(LyricsScreenStyle style) => switch (style) {
  LyricsScreenStyle.editorial => const Color(0xFF0F0F0C),
  LyricsScreenStyle.vinyl => const Color(0xFF050403),
  LyricsScreenStyle.m3 => const Color(0xFF0A0A0A),
  _ => Colors.black,
};

/// Unique minimalistic top header for the 10 new [LyricsScreenStyle] variants.
Widget buildLyricsStyledHeader({
  required BuildContext context,
  required WidgetRef ref,
  required LyricsScreenStyle style,
  required Song song,
  required bool showAlbum,
  required VoidCallback onClose,
  required VoidCallback onOpenMenu,
  required VoidCallback onInteract,
  bool isLandscape = false,
}) {
  final l10n = AppLocalizations.of(context)!;
  final artist = artistAlbumLabel(song, l10n, showAlbum: showAlbum);
  final accent = Theme.of(context).colorScheme.primary;
  final topPad = isLandscape ? 0.0 : MediaQuery.paddingOf(context).top;

  if (style == LyricsScreenStyle.poster) {
    return _PosterHeroHeader(
      song: song,
      artist: artist,
      accent: accent,
      topPad: MediaQuery.paddingOf(context).top,
      isLandscape: isLandscape,
      onClose: onClose,
      onOpenMenu: onOpenMenu,
      onInteract: onInteract,
    );
  }

  return Padding(
    padding: isLandscape && style.isSideLandscape
        ? EdgeInsets.zero
        : EdgeInsets.fromLTRB(20.s, topPad + 22.s, 20.s, 14.s),
    child: switch (style) {
      LyricsScreenStyle.spatial => Center(
        child: GestureDetector(
          onTap: onClose,
          onLongPress: onOpenMenu,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: EdgeInsets.fromLTRB(
                  isLandscape ? 6.s : 8.s,
                  isLandscape ? 5.s : 7.s,
                  isLandscape ? 14.s : 16.s,
                  isLandscape ? 5.s : 7.s,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.10),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClipOval(
                      child: OptimizedImage(
                        imagePath: song.artPath,
                        width: isLandscape ? 30.s : 34.s,
                        height: isLandscape ? 30.s : 34.s,
                        fit: BoxFit.cover,
                      ),
                    ),
                    SizedBox(width: 9.s),
                    Flexible(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: song.title,
                              style: AppFonts.familyStyle(
                                AppFonts.stackSansText,
                                color: Colors.white,
                                fontSize: isLandscape ? 12.5 : 13.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            TextSpan(
                              text: ' · ${song.artist ?? ''}',
                              style: AppFonts.familyStyle(
                                AppFonts.stackSansText,
                                color: Colors.white.withValues(alpha: 0.54),
                                fontSize: isLandscape ? 12.5 : 13.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      LyricsScreenStyle.vinyl => GestureDetector(
        onLongPress: onOpenMenu,
        child: isLandscape
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _SpinningVinylThumb(
                    artPath: song.artPath,
                    discSize: 150,
                    labelSize: 54,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    song.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: AppFonts.familyStyle(
                      AppFonts.playfairDisplay,
                      color: const Color(0xFFF1D9AE),
                      fontSize: 19,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: AppFonts.familyStyle(
                      AppFonts.stackSansText,
                      color: const Color(0xFFF1D9AE).withValues(alpha: 0.55),
                      fontSize: 12,
                    ),
                  ),
                ],
              )
            : Container(
                padding: EdgeInsets.only(bottom: 12.s),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: const Color(0xFFF1D9AE).withValues(alpha: 0.10),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    _SpinningVinylThumb(artPath: song.artPath),
                    SizedBox(width: 12.s),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            song.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppFonts.familyStyle(
                              AppFonts.playfairDisplay,
                              color: const Color(0xFFF1D9AE),
                              fontSize: 19,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppFonts.familyStyle(
                              AppFonts.stackSansText,
                              color: const Color(0xFFF1D9AE)
                                  .withValues(alpha: 0.55),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: onOpenMenu,
                      icon: const Icon(
                        Icons.more_vert_rounded,
                        color: Colors.white54,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
      ),
      LyricsScreenStyle.editorial => GestureDetector(
        onLongPress: onOpenMenu,
        child: Container(
          padding: EdgeInsets.only(bottom: 12.s),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (song.artist ?? '').toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.familyStyle(
                        AppFonts.stackSansText,
                        color: Colors.white.withValues(alpha: 0.54),
                        fontSize: 10,
                        letterSpacing: 1.8,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      song.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.familyStyle(
                        AppFonts.playfairDisplay,
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onOpenMenu,
                child: Text(
                  l10n.lyrics.toUpperCase(),
                  style: AppFonts.familyStyle(
                    AppFonts.stackSansText,
                    color: Colors.white.withValues(alpha: 0.38),
                    fontSize: 11,
                    letterSpacing: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      LyricsScreenStyle.karaoke => GestureDetector(
        onLongPress: onOpenMenu,
        child: Column(
          children: [
            Consumer(
              builder: (context, ref, _) {
                final lines = ref.watch(
                  lyricsProvider.select((s) => s.parsedLines),
                );
                final pos = ref.watch(
                  playbackProvider.select((s) => s.position),
                );
                final isPlaying = ref.watch(
                  playbackProvider.select((s) => s.isPlaying),
                );
                final (cur, total) = _activeLineIndex(lines, pos);
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _PulsingDot(color: accent, active: isPlaying),
                      const SizedBox(width: 7),
                      Text(
                        total > 0 ? 'LINE $cur OF $total' : 'STAGE',
                        style: AppFonts.familyStyle(
                          AppFonts.stackSansText,
                          color: accent,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.6,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            Text(
              song.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppFonts.familyStyle(
                AppFonts.stackSansText,
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              artist,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppFonts.familyStyle(
                AppFonts.stackSansText,
                color: Colors.white.withValues(alpha: 0.54),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
      LyricsScreenStyle.oled => GestureDetector(
        onLongPress: onOpenMenu,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                song.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppFonts.familyStyle(
                  AppFonts.stackSansText,
                  color: Colors.white.withValues(alpha: 0.38),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                song.artist ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppFonts.familyStyle(
                  AppFonts.stackSansText,
                  color: Colors.white.withValues(alpha: 0.38),
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
      LyricsScreenStyle.m3 => Row(
        children: [
          Expanded(
            child: Container(
              padding: EdgeInsets.fromLTRB(6.s, 6.s, 14.s, 6.s),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(24.s),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16.s),
                    child: OptimizedImage(
                      imagePath: song.artPath,
                      width: 40.s,
                      height: 40.s,
                      fit: BoxFit.cover,
                    ),
                  ),
                  SizedBox(width: 10.s),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          song.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppFonts.familyStyle(
                            AppFonts.stackSansText,
                            color: Colors.white,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppFonts.familyStyle(
                            AppFonts.stackSansText,
                            color: Colors.white.withValues(alpha: 0.54),
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: 8.s),
          Material(
            color: accent.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(18.s),
            child: InkWell(
              borderRadius: BorderRadius.circular(18.s),
              onTap: onOpenMenu,
              child: SizedBox(
                width: 52.s,
                height: 52.s,
                child: const Icon(
                  Icons.more_vert_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
      LyricsScreenStyle.timeline => GestureDetector(
        onLongPress: onOpenMenu,
        child: Container(
          padding: EdgeInsets.only(bottom: 10.s),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: Color(0xFFEF4444),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'CUE // ${song.title.toUpperCase()}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.familyStyle(
                    AppFonts.jetBrainsMono,
                    color: Colors.white.withValues(alpha: 0.72),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Consumer(
                builder: (context, ref, _) {
                  final pos = ref.watch(
                    playbackProvider.select((s) => s.position),
                  );
                  final dur = ref.watch(
                    playbackProvider.select((s) => s.duration),
                  );
                  return Text(
                    '${_fmtDur(pos)} / ${_fmtDur(dur)}',
                    style: AppFonts.familyStyle(
                      AppFonts.jetBrainsMono,
                      color: Colors.white.withValues(alpha: 0.54),
                      fontSize: 11,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      LyricsScreenStyle.zen => Center(
        child: GestureDetector(
          onLongPress: onOpenMenu,
          child: Column(
            children: [
              Text(
                song.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppFonts.familyStyle(
                  AppFonts.stackSansText,
                  color: Colors.white.withValues(alpha: 0.80),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                song.artist ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppFonts.familyStyle(
                  AppFonts.stackSansText,
                  color: Colors.white.withValues(alpha: 0.38),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
      LyricsScreenStyle.bigtype => GestureDetector(
        onLongPress: onOpenMenu,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.familyStyle(
                      AppFonts.stackSansText,
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.familyStyle(
                      AppFonts.stackSansText,
                      color: Colors.white.withValues(alpha: 0.54),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Consumer(
              builder: (context, ref, _) {
                final lines = ref.watch(
                  lyricsProvider.select((s) => s.parsedLines),
                );
                final pos = ref.watch(
                  playbackProvider.select((s) => s.position),
                );
                final (cur, total) = _activeLineIndex(lines, pos);
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      cur.toString().padLeft(2, '0'),
                      style: AppFonts.familyStyle(
                        AppFonts.spaceGrotesk,
                        color: accent,
                        fontSize: 40,
                        fontWeight: FontWeight.w700,
                        height: 1.0,
                      ),
                    ),
                    Text(
                      '/${total.toString().padLeft(2, '0')}',
                      style: AppFonts.familyStyle(
                        AppFonts.spaceGrotesk,
                        color: Colors.white.withValues(alpha: 0.38),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
      _ => const SizedBox.shrink(),
    },
  );
}

/// Unique minimalistic bottom controls for the 10 new [LyricsScreenStyle]s.
Widget buildLyricsStyledControls({
  required BuildContext context,
  required WidgetRef ref,
  required LyricsScreenStyle style,
  required Song song,
  required double bottomPadding,
  required VoidCallback onInteract,
  required VoidCallback onOpenMenu,
  bool isLandscape = false,
}) {
  final accent = Theme.of(context).colorScheme.primary;
  return Consumer(
    builder: (context, ref, _) {
      final pos = ref.watch(playbackProvider.select((s) => s.position));
      final dur = ref.watch(playbackProvider.select((s) => s.duration));
      final isPlaying = ref.watch(playbackProvider.select((s) => s.isPlaying));
      final lines = ref.watch(lyricsProvider.select((s) => s.parsedLines));
      final totalMs = dur.inMilliseconds;
      final progress = totalMs > 0
          ? (pos.inMilliseconds / totalMs).clamp(0.0, 1.0)
          : 0.0;
      final notifier = ref.read(playbackProvider.notifier);

      void seekFraction(double frac) {
        onInteract();
        if (totalMs > 0) {
          notifier.seek(
            Duration(milliseconds: (frac.clamp(0.0, 1.0) * totalMs).round()),
          );
        }
      }

      Widget slimBar({
        double height = 3,
        Color? fill,
        Color? trackColor,
        bool round = true,
      }) => LayoutBuilder(
        builder: (context, c) => GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (d) =>
              seekFraction(d.localPosition.dx / c.maxWidth.clamp(1, 9999)),
          onHorizontalDragUpdate: (d) =>
              seekFraction(d.localPosition.dx / c.maxWidth.clamp(1, 9999)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(round ? 999 : 0),
              child: Container(
                height: height,
                color: trackColor ?? Colors.white.withValues(alpha: 0.14),
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: progress,
                  child: Container(color: fill ?? accent),
                ),
              ),
            ),
          ),
        ),
      );

      final playIcon = isPlaying
          ? Icons.pause_rounded
          : Icons.play_arrow_rounded;

      final Widget inner = switch (style) {
        LyricsScreenStyle.spatial => Padding(
          padding: EdgeInsets.fromLTRB(16.s, 0, 16.s, bottomPadding + 16.s),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: EdgeInsets.fromLTRB(
                  isLandscape ? 6.s : 8.s,
                  isLandscape ? 6.s : 8.s,
                  isLandscape ? 14.s : 18.s,
                  isLandscape ? 6.s : 8.s,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.10),
                  ),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        onInteract();
                        AppHaptics.light();
                        notifier.togglePlay();
                      },
                      child: Container(
                        width: isLandscape ? 40.s : 44.s,
                        height: isLandscape ? 40.s : 44.s,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          playIcon,
                          color: Colors.black,
                          size: isLandscape ? 22 : 24,
                        ),
                      ),
                    ),
                    SizedBox(width: 12.s),
                    Expanded(child: slimBar(height: 4, fill: Colors.white)),
                    SizedBox(width: 10.s),
                    Text(
                      _fmtDur(pos),
                      style: AppFonts.familyStyle(
                        AppFonts.stackSansText,
                        color: Colors.white.withValues(alpha: 0.54),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        LyricsScreenStyle.vinyl => Padding(
          padding: EdgeInsets.fromLTRB(22.s, 0, 22.s, bottomPadding + 16.s),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              slimBar(height: 2, fill: const Color(0xFFD9B97F)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _fmtDur(pos),
                    style: AppFonts.familyStyle(
                      AppFonts.stackSansText,
                      color: const Color(0xFFF1D9AE).withValues(alpha: 0.55),
                      fontSize: 11.5,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          onInteract();
                          notifier.skipPrevious();
                        },
                        icon: const Icon(
                          Icons.skip_previous_rounded,
                          color: Color(0xFFF1D9AE),
                          size: 22,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          onInteract();
                          notifier.togglePlay();
                        },
                        icon: Icon(
                          playIcon,
                          color: const Color(0xFFF1D9AE),
                          size: 28,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          onInteract();
                          notifier.skipNext();
                        },
                        icon: const Icon(
                          Icons.skip_next_rounded,
                          color: Color(0xFFF1D9AE),
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    _fmtDur(dur),
                    style: AppFonts.familyStyle(
                      AppFonts.stackSansText,
                      color: const Color(0xFFF1D9AE).withValues(alpha: 0.55),
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        LyricsScreenStyle.editorial => Padding(
          padding: EdgeInsets.fromLTRB(22.s, 0, 22.s, bottomPadding + 16.s),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              slimBar(height: 1.5, fill: Colors.white),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () {
                      onInteract();
                      notifier.skipPrevious();
                    },
                    child: Text(
                      'PREV',
                      style: AppFonts.familyStyle(
                        AppFonts.stackSansText,
                        color: Colors.white.withValues(alpha: 0.54),
                        fontSize: 11,
                        letterSpacing: 1.6,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      onInteract();
                      notifier.togglePlay();
                    },
                    child: Text(
                      isPlaying ? 'PAUSE' : 'PLAY',
                      style: AppFonts.familyStyle(
                        AppFonts.stackSansText,
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.6,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      onInteract();
                      notifier.skipNext();
                    },
                    child: Text(
                      'NEXT',
                      style: AppFonts.familyStyle(
                        AppFonts.stackSansText,
                        color: Colors.white.withValues(alpha: 0.54),
                        fontSize: 11,
                        letterSpacing: 1.6,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        LyricsScreenStyle.karaoke => Padding(
          padding: EdgeInsets.fromLTRB(20.s, 0, 20.s, bottomPadding + 16.s),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _fmtDur(pos),
                style: AppFonts.familyStyle(
                  AppFonts.stackSansText,
                  color: Colors.white.withValues(alpha: 0.54),
                  fontSize: 12,
                ),
              ),
              IconButton(
                onPressed: () {
                  onInteract();
                  notifier.skipPrevious();
                },
                icon: const Icon(
                  Icons.skip_previous_rounded,
                  color: Colors.white70,
                  size: 26,
                ),
              ),
              GestureDetector(
                onTap: () {
                  onInteract();
                  AppHaptics.light();
                  notifier.togglePlay();
                },
                child: SizedBox(
                  width: isLandscape ? 68.s : 72.s,
                  height: isLandscape ? 68.s : 72.s,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: Size.square(isLandscape ? 68.s : 72.s),
                        painter: _ProgressRingPainter(
                          progress: progress,
                          accent: accent,
                        ),
                      ),
                      Container(
                        width: isLandscape ? 52.s : 56.s,
                        height: isLandscape ? 52.s : 56.s,
                        decoration: BoxDecoration(
                          color: accent,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          playIcon,
                          color: Colors.black,
                          size: isLandscape ? 26 : 28,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  onInteract();
                  notifier.skipNext();
                },
                icon: const Icon(
                  Icons.skip_next_rounded,
                  color: Colors.white70,
                  size: 26,
                ),
              ),
              Text(
                _fmtDur(dur),
                style: AppFonts.familyStyle(
                  AppFonts.stackSansText,
                  color: Colors.white.withValues(alpha: 0.54),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        LyricsScreenStyle.poster => Padding(
          padding: EdgeInsets.fromLTRB(20.s, 6.s, 20.s, bottomPadding + 14.s),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(
                width: 36,
                height: 36,
                child: FavoriteButtonWithGlow(
                  song: song,
                  ref: ref,
                  useBlur: false,
                ),
              ),
              IconButton(
                onPressed: () {
                  onInteract();
                  notifier.skipPrevious();
                },
                icon: const Icon(
                  Icons.skip_previous_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              Text(
                '${_fmtDur(pos)} / ${_fmtDur(dur)}',
                style: AppFonts.familyStyle(
                  AppFonts.stackSansText,
                  color: Colors.white.withValues(alpha: 0.72),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              IconButton(
                onPressed: () {
                  onInteract();
                  notifier.skipNext();
                },
                icon: const Icon(
                  Icons.skip_next_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              IconButton(
                onPressed: onOpenMenu,
                icon: const Icon(
                  Icons.more_vert_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ],
          ),
        ),
        LyricsScreenStyle.oled => Padding(
          padding: EdgeInsets.fromLTRB(22.s, 0, 22.s, bottomPadding + 14.s),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _fmtDur(pos),
                    style: AppFonts.familyStyle(
                      AppFonts.stackSansText,
                      color: Colors.white.withValues(alpha: 0.54),
                      fontSize: 12,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      onInteract();
                      notifier.togglePlay();
                    },
                    icon: Icon(playIcon, color: Colors.white, size: 22),
                  ),
                ],
              ),
              slimBar(height: 2, fill: Colors.white),
            ],
          ),
        ),
        LyricsScreenStyle.m3 => Padding(
          padding: EdgeInsets.fromLTRB(16.s, 0, 16.s, bottomPadding + 16.s),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: isLandscape ? 56.s : 60.s,
                  padding: EdgeInsets.symmetric(horizontal: 16.s),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(
                      isLandscape ? 28.s : 30.s,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        _fmtDur(pos),
                        style: AppFonts.familyStyle(
                          AppFonts.stackSansText,
                          color: accent,
                          fontSize: isLandscape ? 12 : 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 12.s),
                      Expanded(child: slimBar(height: 8, fill: accent)),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 10.s),
              GestureDetector(
                onTap: () {
                  onInteract();
                  AppHaptics.light();
                  notifier.togglePlay();
                },
                child: Container(
                  width: isLandscape ? 56.s : 60.s,
                  height: isLandscape ? 56.s : 60.s,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(
                      isLandscape ? 20.s : 22.s,
                    ),
                  ),
                  child: Icon(
                    playIcon,
                    color: Colors.black,
                    size: isLandscape ? 24 : 26,
                  ),
                ),
              ),
            ],
          ),
        ),
        LyricsScreenStyle.timeline => Container(
          padding: EdgeInsets.fromLTRB(20.s, 10.s, 20.s, bottomPadding + 14.s),
          decoration: BoxDecoration(
            color: const Color(0xFF080808),
            border: Border(
              top: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
            ),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  onInteract();
                  notifier.togglePlay();
                },
                child: Text(
                  isPlaying ? '[PAUSE]' : '[PLAY]',
                  style: AppFonts.familyStyle(
                    AppFonts.jetBrainsMono,
                    color: accent,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(width: 12.s),
              Expanded(child: slimBar(height: 3, fill: accent, round: false)),
              SizedBox(width: 12.s),
              Text(
                _fmtDur(pos),
                style: AppFonts.familyStyle(
                  AppFonts.jetBrainsMono,
                  color: Colors.white.withValues(alpha: 0.54),
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
        ),
        LyricsScreenStyle.zen => Padding(
          padding: EdgeInsets.fromLTRB(20.s, 0, 20.s, bottomPadding + 16.s),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (lines.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Builder(
                    builder: (context) {
                      final (cur, total) = _activeLineIndex(lines, pos);
                      final shown = math.min(total, 16);
                      return Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        alignment: WrapAlignment.center,
                        children: [
                          for (int i = 0; i < shown; i++)
                            GestureDetector(
                              onTap: () {
                                onInteract();
                                notifier.seek(lines[i].startTime);
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 240),
                                width: (i + 1) == cur ? 24 : 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: (i + 1) == cur
                                      ? accent
                                      : (i + 1) < cur
                                      ? Colors.white.withValues(alpha: 0.45)
                                      : Colors.white.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () {
                      onInteract();
                      notifier.skipPrevious();
                    },
                    icon: const Icon(
                      Icons.skip_previous_rounded,
                      color: Colors.white60,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () {
                      onInteract();
                      AppHaptics.light();
                      notifier.togglePlay();
                    },
                    child: Container(
                      height: isLandscape ? 46.s : 50.s,
                      padding: EdgeInsets.symmetric(
                        horizontal: isLandscape ? 18.s : 22.s,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.10),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            playIcon,
                            color: Colors.white,
                            size: isLandscape ? 20 : 22,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '-${_fmtDur(dur - pos)} left',
                            style: AppFonts.familyStyle(
                              AppFonts.stackSansText,
                              color: Colors.white.withValues(alpha: 0.72),
                              fontSize: isLandscape ? 12 : 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    onPressed: () {
                      onInteract();
                      notifier.skipNext();
                    },
                    icon: const Icon(
                      Icons.skip_next_rounded,
                      color: Colors.white60,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        LyricsScreenStyle.bigtype => Container(
          padding: EdgeInsets.fromLTRB(
            22.s,
            14.s,
            22.s,
            isLandscape ? 16 : (bottomPadding + 18.s),
          ),
          decoration: BoxDecoration(
            color: accent,
            borderRadius: isLandscape
                ? BorderRadius.circular(24)
                : const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              slimBar(
                height: 4,
                fill: Colors.black,
                trackColor: Colors.black.withValues(alpha: 0.18),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _fmtDur(pos),
                    style: AppFonts.familyStyle(
                      AppFonts.stackSansText,
                      color: Colors.black,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      onInteract();
                      notifier.skipPrevious();
                    },
                    icon: const Icon(
                      Icons.skip_previous_rounded,
                      color: Colors.black,
                      size: 24,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      onInteract();
                      AppHaptics.light();
                      notifier.togglePlay();
                    },
                    child: Container(
                      width: isLandscape ? 58.s : 62.s,
                      height: isLandscape ? 58.s : 62.s,
                      decoration: const BoxDecoration(
                        color: Colors.black,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        playIcon,
                        color: accent,
                        size: isLandscape ? 28 : 30,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      onInteract();
                      notifier.skipNext();
                    },
                    icon: const Icon(
                      Icons.skip_next_rounded,
                      color: Colors.black,
                      size: 24,
                    ),
                  ),
                  Text(
                    _fmtDur(dur),
                    style: AppFonts.familyStyle(
                      AppFonts.stackSansText,
                      color: Colors.black,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        _ => const SizedBox.shrink(),
      };

      final Widget bounded =
          (isLandscape &&
              !style.isSideLandscape &&
              style != LyricsScreenStyle.timeline)
          ? Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: inner,
              ),
            )
          : inner;

      if (style == LyricsScreenStyle.bigtype ||
          style == LyricsScreenStyle.poster ||
          (isLandscape && style.isSideLandscape)) {
        return bounded;
      }
      final scrim = lyricsScrimColor(style);
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              scrim.withValues(alpha: 0.0),
              scrim.withValues(alpha: 0.85),
              scrim,
            ],
            stops: const [0.0, 0.45, 1.0],
          ),
        ),
        padding: EdgeInsets.only(top: 56.s),
        child: bounded,
      );
    },
  );
}

class _PosterHeroHeader extends ConsumerWidget {
  final Song song;
  final String artist;
  final Color accent;
  final double topPad;
  final bool isLandscape;
  final VoidCallback onClose;
  final VoidCallback onOpenMenu;
  final VoidCallback onInteract;

  const _PosterHeroHeader({
    required this.song,
    required this.artist,
    required this.accent,
    required this.topPad,
    this.isLandscape = false,
    required this.onClose,
    required this.onOpenMenu,
    required this.onInteract,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pos = ref.watch(playbackProvider.select((s) => s.position));
    final dur = ref.watch(playbackProvider.select((s) => s.duration));
    final isPlaying = ref.watch(playbackProvider.select((s) => s.isPlaying));
    final progress = dur.inMilliseconds > 0
        ? (pos.inMilliseconds / dur.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;
    final notifier = ref.read(playbackProvider.notifier);

    return SizedBox(
      height: isLandscape ? double.infinity : 310.s,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          OptimizedImage(imagePath: song.artPath, fit: BoxFit.cover),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.30),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.50),
                  Colors.black,
                ],
                stops: const [0.0, 0.28, 0.68, 1.0],
              ),
            ),
          ),
          Positioned(
            top: topPad + 10.s,
            left: isLandscape ? 24.s : 18.s,
            right: 18.s,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _FrostedRoundBtn(
                  icon: Icons.keyboard_arrow_down_rounded,
                  onTap: onClose,
                ),
                _FrostedRoundBtn(
                  icon: Icons.more_vert_rounded,
                  onTap: onOpenMenu,
                ),
              ],
            ),
          ),
          Positioned(
            left: isLandscape ? 24.s : 20.s,
            right: 20.s,
            bottom: isLandscape ? 120.s : 18.s,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'NOW SINGING',
                        style: AppFonts.familyStyle(
                          AppFonts.stackSansText,
                          color: accent,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.6,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        song.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppFonts.familyStyle(
                          AppFonts.spaceGrotesk,
                          color: Colors.white,
                          fontSize: isLandscape ? 26 : 32,
                          fontWeight: FontWeight.w700,
                          height: 1.02,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppFonts.familyStyle(
                          AppFonts.stackSansText,
                          color: Colors.white.withValues(alpha: 0.70),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                GestureDetector(
                  onTap: () {
                    onInteract();
                    AppHaptics.light();
                    notifier.togglePlay();
                  },
                  child: Container(
                    width: isLandscape ? 54.s : 62.s,
                    height: isLandscape ? 54.s : 62.s,
                    decoration: BoxDecoration(
                      color: accent,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.40),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Icon(
                      isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: Colors.black,
                      size: isLandscape ? 26 : 30,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: isLandscape ? 24.s : 20.s,
            right: 20.s,
            bottom: isLandscape ? 96.s : 0,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: Container(
                height: 3,
                color: Colors.white.withValues(alpha: 0.16),
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: progress,
                  child: Container(color: accent),
                ),
              ),
            ),
          ),
          if (isLandscape)
            Positioned(
              left: 16.s,
              right: 12.s,
              bottom: 18.s,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    width: 36,
                    height: 36,
                    child: FavoriteButtonWithGlow(
                      song: song,
                      ref: ref,
                      useBlur: false,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      onInteract();
                      notifier.skipPrevious();
                    },
                    icon: const Icon(
                      Icons.skip_previous_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  Text(
                    '${_fmtDur(pos)} / ${_fmtDur(dur)}',
                    style: AppFonts.familyStyle(
                      AppFonts.stackSansText,
                      color: Colors.white.withValues(alpha: 0.72),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      onInteract();
                      notifier.skipNext();
                    },
                    icon: const Icon(
                      Icons.skip_next_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _FrostedRoundBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _FrostedRoundBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            width: 40.s,
            height: 40.s,
            color: Colors.black.withValues(alpha: 0.35),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
        ),
      ),
    );
  }
}

class _KaraokeSpotlightBg extends StatelessWidget {
  final Color accent;
  final bool isLandscape;
  const _KaraokeSpotlightBg({required this.accent, this.isLandscape = false});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: isLandscape
                    ? const Alignment(0.32, -1.08)
                    : const Alignment(0, -1.08),
                radius: 0.9,
                colors: [
                  accent.withValues(alpha: 0.38),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.70],
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, 1.05),
                radius: 0.75,
                colors: [
                  accent.withValues(alpha: 0.12),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineGridBg extends StatelessWidget {
  const _TimelineGridBg();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF080808),
      child: CustomPaint(painter: _TimelineRulePainter()),
    );
  }
}

class _TimelineRulePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.white.withValues(alpha: 0.035)
      ..strokeWidth = 1;
    for (double y = 44; y < size.height; y += 44) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ZenBreathingBg extends ConsumerStatefulWidget {
  final Color accent;
  const _ZenBreathingBg({required this.accent});

  @override
  ConsumerState<_ZenBreathingBg> createState() => _ZenBreathingBgState();
}

class _ZenBreathingBgState extends ConsumerState<_ZenBreathingBg>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPlaying = ref.watch(playbackProvider.select((s) => s.isPlaying));
    if (isPlaying && !_ctrl.isAnimating) {
      _ctrl.repeat(reverse: true);
    } else if (!isPlaying && _ctrl.isAnimating) {
      _ctrl.stop();
    }
    return ColoredBox(
      color: Colors.black,
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (context, _) {
            final t = Curves.easeInOut.transform(_ctrl.value);
            final scale = 0.8 + (0.35 * t);
            final alpha = 0.55 + (0.45 * t);
            return Align(
              alignment: const Alignment(0, -0.12),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: 380,
                  height: 380,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        widget.accent.withValues(alpha: 0.30 * alpha),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  final Color color;
  final bool active;
  const _PulsingDot({required this.color, required this.active});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.active && !_ctrl.isAnimating) {
      _ctrl.repeat(reverse: true);
    } else if (!widget.active && _ctrl.isAnimating) {
      _ctrl.stop();
    }
    return FadeTransition(
      opacity: Tween(begin: 0.35, end: 1.0).animate(_ctrl),
      child: Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
      ),
    );
  }
}

class _ProgressRingPainter extends CustomPainter {
  final double progress;
  final Color accent;
  const _ProgressRingPainter({required this.progress, required this.accent});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 3;
    final track = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(center, radius, track);

    final glow = Paint()
      ..color = accent.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    final arc = Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final sweep = 2 * math.pi * progress;
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(rect, -math.pi / 2, sweep, false, glow);
    canvas.drawArc(rect, -math.pi / 2, sweep, false, arc);
  }

  @override
  bool shouldRepaint(_ProgressRingPainter old) =>
      old.progress != progress || old.accent != accent;
}

class _SpinningVinylThumb extends ConsumerStatefulWidget {
  final String? artPath;
  final double discSize;
  final double labelSize;
  const _SpinningVinylThumb({
    required this.artPath,
    this.discSize = 50,
    this.labelSize = 20,
  });

  @override
  ConsumerState<_SpinningVinylThumb> createState() =>
      _SpinningVinylThumbState();
}

class _SpinningVinylThumbState extends ConsumerState<_SpinningVinylThumb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 9),
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPlaying = ref.watch(playbackProvider.select((s) => s.isPlaying));
    if (isPlaying && !_ctrl.isAnimating) {
      _ctrl.repeat();
    } else if (!isPlaying && _ctrl.isAnimating) {
      _ctrl.stop();
    }
    return RotationTransition(
      turns: _ctrl,
      child: Container(
        width: widget.discSize.s,
        height: widget.discSize.s,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              Color(0xFF111111),
              Color(0xFF242424),
              Color(0xFF151515),
              Color(0xFF0A0A0A),
            ],
          ),
        ),
        alignment: Alignment.center,
        child: Container(
          width: widget.labelSize.s,
          height: widget.labelSize.s,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFD9B97F), width: 1.5),
          ),
          child: ClipOval(
            child: OptimizedImage(
              imagePath: widget.artPath,
              width: widget.labelSize.s,
              height: widget.labelSize.s,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }
}
