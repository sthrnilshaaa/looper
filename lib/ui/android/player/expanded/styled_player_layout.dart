import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:looper_player/core/providers/player_expand_provider.dart';
import 'package:looper_player/core/services/haptics/app_haptics.dart';
import 'package:looper_player/core/services/screen_awake.dart';
import 'package:looper_player/core/services/system_navigation_bar.dart';
import 'package:looper_player/core/utils/song_metadata.dart';
import 'package:looper_player/core/utils/ui_utils.dart';
import 'package:looper_player/features/library/domain/models/models.dart';
import 'package:looper_player/features/playback/domain/lyric_models.dart';
import 'package:looper_player/features/playback/presentation/providers/lyrics/lyrics_notifier.dart';
import 'package:looper_player/features/playback/presentation/providers/playback/playback_notifier.dart';
import 'package:looper_player/features/playback/presentation/screens/lyrics_view.dart'
    show LyricsSyncMode;
import 'package:looper_player/features/playback/presentation/widgets/lyrics/advanced_lyric_line/advanced_lyric_line.dart';
import 'package:looper_player/features/playback/presentation/widgets/lyrics/advanced_lyric_line/word_synced_lyric_text.dart';
import 'package:looper_player/features/settings/presentation/providers/settings_notifier.dart';
import 'package:looper_player/l10n/app_localizations.dart';
import 'package:looper_player/ui/widgets/common/optimized_image.dart';

import '../../shell/music_bar/fluid_player_motion.dart';
import '../lyrics/lyrics_route.dart';
import 'android_expanded_player.dart';
import 'expressive_player_widgets.dart';
import 'favorite_button.dart';
import 'player_lyric_line.dart';
import 'player_style_picker.dart';
import 'quality_details_sheet.dart';
import 'package:looper_player/features/playback/data/audio_analyzer.dart';
import 'package:looper_player/features/settings/domain/quality_badge_style.dart';
import 'package:looper_player/features/playback/data/quality_check_service.dart';
import 'package:looper_player/ui/widgets/player/quality_badge.dart';

/// The two Figma Now Playing layouts (Settings > Now Playing > Player Style).
/// The classic layout lives in AndroidExpandedPlayer and is untouched; these
/// only replace its portrait body, so the shell around them (drag to close,
/// Fluid Player expand/collapse, back handling) is shared.
enum PlayerLayoutStyle {
  classic,
  arc,
  linear,
  card,
  disc,
  asymmetric,
  fullbleed,
  capsule,
  m3wavy,
  m3scallop,
  m3clover,
  m3burst;

  bool get isM3Expressive => switch (this) {
    m3wavy || m3scallop || m3clover || m3burst => true,
    _ => false,
  };

  static PlayerLayoutStyle fromSetting(String value) => switch (value) {
    'arc' => arc,
    'linear' => linear,
    'card' || 'box' => card,
    'disc' => disc,
    'asymmetric' => asymmetric,
    'fullbleed' => fullbleed,
    'capsule' => capsule,
    'm3wavy' => m3wavy,
    'm3scallop' => m3scallop,
    'm3clover' => m3clover,
    'm3burst' => m3burst,
    _ => classic,
  };
}

const _icons = 'assets/icons/player_styles';

// Figma frame the layouts are drawn on; positions below are in its units.
const double _designW = 402;
const double _designH = 874;
// Bottom inset the frame reserves for the home indicator.
const double _designBottomInset = 34;
// Centre x of the right-hand control column.
const double _controlsX = 352;

/// Per-style anchors, in design units. Lower parts are measured from the
/// frame's bottom so they hug the screen bottom on any aspect ratio.
class _Spec {
  final double chevronFromBottom;
  final double? starFromBottom;
  final double prevFromBottom;
  final double playFromBottom;
  final double nextFromBottom;
  final double lyricsTopFromBottom;
  final double lyricsHeight;
  final double bigTitleBottomFromBottom;
  const _Spec({
    required this.chevronFromBottom,
    this.starFromBottom,
    required this.prevFromBottom,
    required this.playFromBottom,
    required this.nextFromBottom,
    required this.lyricsTopFromBottom,
    required this.lyricsHeight,
    required this.bigTitleBottomFromBottom,
  });

  static const arc = _Spec(
    chevronFromBottom: 401.5,
    starFromBottom: 336,
    prevFromBottom: 271.5,
    playFromBottom: 205.5,
    nextFromBottom: 140.5,
    lyricsTopFromBottom: 388,
    lyricsHeight: 251,
    bigTitleBottomFromBottom: 59,
  );
  static const linear = _Spec(
    chevronFromBottom: 472.5,
    starFromBottom: 407,
    prevFromBottom: 345.5,
    playFromBottom: 279.5,
    nextFromBottom: 214.5,
    lyricsTopFromBottom: 432,
    lyricsHeight: 251,
    // Above the seek row (its timestamps start at 722).
    bigTitleBottomFromBottom: 166,
  );
  static const card = _Spec(
    chevronFromBottom: 336,
    prevFromBottom: 271.5,
    playFromBottom: 205.5,
    nextFromBottom: 140.5,
    lyricsTopFromBottom: 368,
    lyricsHeight: 251,
    bigTitleBottomFromBottom: 59,
  );
  static const asymmetric = _Spec(
    chevronFromBottom: 512,
    starFromBottom: 336,
    prevFromBottom: 271.5,
    playFromBottom: 205.5,
    nextFromBottom: 140.5,
    lyricsTopFromBottom: 382,
    lyricsHeight: 251,
    bigTitleBottomFromBottom: 59,
  );
}

class StyledPlayerLayout extends ConsumerStatefulWidget {
  final PlayerLayoutStyle style;
  final Song song;
  final GlobalKey playerRootKey;

  /// Fluid Player: sections fade in with the expand progress and the art
  /// morph is drawn by the panel, so no Hero.
  final bool enableSlide;
  final Widget Function(Widget child, FluidSectionMotion motion) fadeWithSlide;
  final VoidCallback onShowLyrics;
  final VoidCallback onShowQueue;
  final VoidCallback onShowOptions;

  /// Tap on the title or artist: the small song sheet.
  final VoidCallback? onShowSongInfo;

  const StyledPlayerLayout({
    super.key,
    required this.style,
    required this.song,
    required this.playerRootKey,
    required this.enableSlide,
    required this.fadeWithSlide,
    required this.onShowLyrics,
    required this.onShowQueue,
    required this.onShowOptions,
    this.onShowSongInfo,
  });

  @override
  ConsumerState<StyledPlayerLayout> createState() => _StyledPlayerLayoutState();
}

class _StyledPlayerLayoutState extends ConsumerState<StyledPlayerLayout>
    with _StyledArt<StyledPlayerLayout> {
  @override
  PlayerLayoutStyle get _style => widget.style;
  @override
  Song get _song => widget.song;
  @override
  bool get _enableSlide => widget.enableSlide;
  @override
  VoidCallback get _onShowLyrics => widget.onShowLyrics;
  @override
  VoidCallback get _onShowOptions => widget.onShowOptions;

  Playback get _playback => ref.read(playbackProvider.notifier);

  // Same as the classic player: skip after the tap frame is drawn so the
  // press feedback doesn't drop frames to the song change rebuild.
  void _afterThisFrame(VoidCallback action) {
    SchedulerBinding.instance.endOfFrame.then((_) {
      if (mounted) action();
    });
  }

  @override
  Widget build(BuildContext context) {
    final song = widget.song;
    if (widget.style.isM3Expressive) {
      return _buildM3ExpressiveLayout(context, song);
    }
    final spec = switch (widget.style) {
      PlayerLayoutStyle.arc || PlayerLayoutStyle.disc => _Spec.arc,
      PlayerLayoutStyle.card || PlayerLayoutStyle.capsule => _Spec.card,
      PlayerLayoutStyle.asymmetric => _Spec.asymmetric,
      _ => _Spec.linear,
    };
    final hasLyrics = ref.watch(_showPlayerLyricsProvider);
    final fade = widget.fadeWithSlide;

    return LayoutBuilder(
      builder: (context, box) {
        final double w = box.maxWidth;
        final double h = box.maxHeight;
        final double sx = w / _designW;
        final double bottomPad = MediaQuery.paddingOf(context).bottom;
        // Vertical sizes shrink on screens shorter than the frame's ratio so
        // the top art and the bottom controls never overlap.
        final double availableH = h - bottomPad;
        final double s = math.min(
          sx,
          math.min(h / _designH, availableH / (_designH - _designBottomInset)),
        );
        double fromBottom(double d) => (d - _designBottomInset) * s + bottomPad;
        final double cx = _controlsX * sx;

        Widget centeredAt(double x, double yFromBottom, Widget child) =>
            Positioned(
              left: x - 30 * s,
              bottom: fromBottom(yFromBottom) - 30 * s,
              width: 60 * s,
              height: 60 * s,
              child: Center(child: child),
            );

        return Stack(
          fit: StackFit.expand,
          children: [
            fade(
              _buildStyledBackground(context, ref, song, widget.style),
              FluidSectionMotion.backgroundFill,
            ),

            // Artwork (+ the arc seek bar under it).
            if (widget.style == PlayerLayoutStyle.arc)
              ..._arcTop(context, sx, s)
            else if (widget.style == PlayerLayoutStyle.disc)
              ..._discTop(sx, s, w)
            else if (widget.style == PlayerLayoutStyle.asymmetric)
              _asymmetricArt(sx, s)
            else if (widget.style == PlayerLayoutStyle.fullbleed)
              _fullbleedArt(s, w)
            else if (widget.style == PlayerLayoutStyle.capsule)
              _capsuleArt(s, w)
            else if (widget.style == PlayerLayoutStyle.card)
              _cardArt(sx, s, w)
            else
              _linearArt(sx, s),

            // Lyrics block, or the big title when the song has none.
            Positioned(
              left: 29 * sx,
              width: 257 * sx,
              bottom: fromBottom(spec.lyricsTopFromBottom - spec.lyricsHeight),
              height: spec.lyricsHeight * s,
              child: fade(
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  layoutBuilder: (current, previous) => Stack(
                    alignment: Alignment.topLeft,
                    children: [...previous, ?current],
                  ),
                  child: hasLyrics
                      ? _lyricsBlock(s)
                      : const SizedBox.shrink(key: ValueKey('none')),
                ),
                FluidSectionMotion.songInfo,
              ),
            ),
            Positioned(
              left: 30 * sx,
              width: 280 * sx,
              bottom: fromBottom(spec.bigTitleBottomFromBottom),
              child: fade(
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  layoutBuilder: (current, previous) => Stack(
                    alignment: Alignment.bottomLeft,
                    children: [...previous, ?current],
                  ),
                  child: hasLyrics
                      ? const SizedBox.shrink(key: ValueKey('small'))
                      : _BigTitle(
                          key: ValueKey(('big', song.id)),
                          song: song,
                          scale: s,
                          onTap: widget.onShowSongInfo,
                        ),
                ),
                FluidSectionMotion.songInfo,
              ),
            ),

            // Small title + artist at the bottom (lyrics view).
            if (hasLyrics)
              Positioned(
                left: 30 * sx,
                right: (_designW - 320) * sx,
                bottom: fromBottom(
                  widget.style == PlayerLayoutStyle.card ? 63 : 51,
                ),
                child: fade(
                  _SmallTitle(
                    song: song,
                    scale: s,
                    onTap: widget.onShowSongInfo,
                  ),
                  FluidSectionMotion.songInfo,
                ),
              ),

            if (widget.style == PlayerLayoutStyle.linear ||
                widget.style == PlayerLayoutStyle.fullbleed)
              Positioned(
                left: 30 * sx,
                right: 30 * sx,
                bottom: fromBottom(142) - 20 * s,
                height: 40 * s,
                child: fade(
                  _seekHero(_LinearSeekRow(scale: s)),
                  FluidSectionMotion.seekBar,
                ),
              ),

            if (widget.style == PlayerLayoutStyle.card ||
                widget.style == PlayerLayoutStyle.asymmetric ||
                widget.style == PlayerLayoutStyle.capsule)
              Positioned(
                left: 32 * sx,
                right: 32 * sx,
                top: (widget.style == PlayerLayoutStyle.card ? 457 : 434) * s,
                height: 40 * s,
                child: fade(
                  _seekHero(
                    _LinearSeekRow(
                      scale: s,
                      barHeight: widget.style == PlayerLayoutStyle.capsule
                          ? 12
                          : 8,
                    ),
                  ),
                  FluidSectionMotion.seekBar,
                ),
              ),

            // Right-hand controls.
            if (spec.starFromBottom != null)
              centeredAt(
                cx,
                spec.starFromBottom!,
                fade(
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: SizedBox(
                      width: 56,
                      height: 56,
                      child: FavoriteButtonWithGlow(
                        song: song,
                        ref: ref,
                        useBlur: false,
                      ),
                    ),
                  ),
                  FluidSectionMotion.utilityRow,
                ),
              ),
            centeredAt(
              cx,
              spec.prevFromBottom,
              fade(
                _IconTap(
                  semanticLabel: AppLocalizations.of(context)!.previousLabel,
                  onTap: () {
                    AppHaptics.light();
                    _afterThisFrame(_playback.skipPrevious);
                  },
                  child: Transform.flip(
                    flipX: true,
                    child: SvgPicture.asset(
                      '$_icons/next.svg',
                      width: 22 * s,
                      height: 19 * s,
                    ),
                  ),
                ),
                FluidSectionMotion.transportRow,
              ),
            ),
            centeredAt(
              cx,
              spec.playFromBottom,
              fade(_PlayPauseButton(scale: s), FluidSectionMotion.transportRow),
            ),
            centeredAt(
              cx,
              spec.nextFromBottom,
              fade(
                _IconTap(
                  semanticLabel: AppLocalizations.of(context)!.nextLabel,
                  onTap: () {
                    AppHaptics.light();
                    _afterThisFrame(_playback.skipNext);
                  },
                  child: SvgPicture.asset(
                    '$_icons/next.svg',
                    width: 22 * s,
                    height: 19 * s,
                  ),
                ),
                FluidSectionMotion.transportRow,
              ),
            ),
            centeredAt(
              cx,
              74,
              fade(
                _IconTap(
                  semanticLabel: AppLocalizations.of(context)!.queue,
                  onTap: () {
                    AppHaptics.medium();
                    widget.onShowQueue();
                  },
                  child: SvgPicture.asset(
                    '$_icons/queue_button.svg',
                    width: 30 * s,
                    height: 30 * s,
                  ),
                ),
                FluidSectionMotion.utilityRow,
              ),
            ),

            // Figma "arrow expanded": the screen dims and the menu stacks
            // up out of the chevron, which turns into its close button.
            Positioned.fill(
              child: fade(
                _ExtrasMenu(
                  open: _extrasOpen,
                  anchor: Offset(cx, h - fromBottom(spec.chevronFromBottom)),
                  scale: s,
                  onClose: _closeExtras,
                  onShowLyrics: widget.onShowLyrics,
                  onShowOptions: widget.onShowOptions,
                ),
                FluidSectionMotion.utilityRow,
              ),
            ),
            Positioned(
              // _IconTap is 48 wide: centre it on cx like the buttons below.
              right: w - cx - 24,
              bottom: fromBottom(spec.chevronFromBottom) - 30 * s,
              height: 60 * s,
              child: fade(
                _ExtrasToggle(
                  open: _extrasOpen,
                  scale: s,
                  onToggle: _toggleExtras,
                ),
                FluidSectionMotion.utilityRow,
              ),
            ),
          ],
        );
      },
    );
  }

  // Reports the art for the Fluid Player morph: the square centred in it,
  // like the immersive layout, so the morph lands on the visible middle.
  Widget _reportArt(Widget child) => PositionReporter(
    ancestorKey: widget.playerRootKey,
    onPositionChanged: (rect) {
      final double side = math.min(rect.width, rect.height);
      ref
          .read(playerArtworkRectProvider.notifier)
          .set(
            Rect.fromLTWH(
              rect.left + (rect.width - side) / 2,
              rect.top + (rect.height - side) / 2,
              side,
              side,
            ),
          );
    },
    child: child,
  );

  // Arc style: art with a round bottom, and the seek bar following it.
  List<Widget> _arcTop(BuildContext context, double sx, double s) {
    final double artW = 415.885 * sx;
    final double artH = 421 * s;
    return [
      Positioned(
        left: (_designW * sx - artW) / 2,
        top: 0,
        width: artW,
        height: artH,
        child: _reportArt(
          _artGestures(
            _hero(
              DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(7.5 * s),
                    bottom: Radius.circular(artW / 2),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      offset: Offset(0, 40 * s),
                      blurRadius: 35 * s,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(7.5 * s),
                    bottom: Radius.circular(artW / 2),
                  ),
                  child: _artImage(),
                ),
              ),
            ),
          ),
        ),
      ),
      Positioned(
        left: 0,
        right: 0,
        top: 340 * s,
        height: 130 * s,
        child: widget.fadeWithSlide(
          _seekHero(_ArcSeekBar(sx: sx, s: s, top: 340 * s)),
          FluidSectionMotion.seekBar,
        ),
      ),
    ];
  }

  // Linear style: a square of art at the top fading into the background.
  Widget _linearArt(double sx, double s) {
    final double side = 412.856 * sx;
    final double artH = math.min(side, 370 * s);
    return Positioned(
      left: (_designW * sx - side) / 2,
      top: -5.83 * s,
      width: side,
      height: artH,
      child: _reportArt(
        _artGestures(
          _hero(
            ShaderMask(
              blendMode: BlendMode.dstIn,
              shaderCallback: (rect) => const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.white, Colors.transparent],
              ).createShader(rect),
              child: Container(
                foregroundDecoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(7 * s),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(7 * s),
                  child: _artImage(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Capsule style: stadium-rounded artwork centered at top with 1px rim.
  Widget _capsuleArt(double s, double w) {
    final double artScale = ref.watch(playerArtScaleProvider);
    final double side = (342 * s * artScale).clamp(180 * s, w - 32 * s);
    final double top = (62 * s - (side - 342 * s) * 0.25).clamp(24 * s, 96 * s);
    return Positioned(
      left: (w - side) / 2,
      top: top,
      width: side,
      height: side,
      child: _reportArt(
        _artGestures(
          _hero(
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(side * (102 / 342)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    offset: Offset(0, 36 * s),
                    blurRadius: 34 * s,
                  ),
                ],
              ),
              foregroundDecoration: BoxDecoration(
                borderRadius: BorderRadius.circular(102 * s),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.12),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(102 * s),
                child: _artImage(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Disc style: centered circular artwork with lower-hemisphere arc seek bar.
  List<Widget> _discTop(double sx, double s, double w) {
    final double side = 296 * s;
    return [
      Positioned(
        left: (w - side) / 2,
        top: 62 * s,
        width: side,
        height: side,
        child: _reportArt(
          _artGestures(
            _hero(
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      offset: Offset(0, 32 * s),
                      blurRadius: 34 * s,
                    ),
                  ],
                ),
                foregroundDecoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.14),
                  ),
                ),
                child: ClipOval(child: _artImage()),
              ),
            ),
          ),
        ),
      ),
      Positioned(
        left: 0,
        right: 0,
        top: 250 * s,
        height: 170 * s,
        child: widget.fadeWithSlide(
          _seekHero(
            _ArcSeekBar(
              sx: sx,
              s: s,
              top: 250 * s,
              cx: _designW / 2,
              cy: 210,
              rx: 168,
              ry: 168,
              startDeg: 140,
              endDeg: 40,
              leftLabel: const Offset(48, 372),
              rightLabel: const Offset(354, 372),
            ),
          ),
          FluidSectionMotion.seekBar,
        ),
      ),
    ];
  }

  // Asymmetric style: top-left bleed artwork with sculpted bottom-right radius.
  Widget _asymmetricArt(double sx, double s) {
    final double artW = 316 * sx;
    final double artH = 412 * s;
    final radius = BorderRadius.only(bottomRight: Radius.circular(40 * s));
    return Positioned(
      left: 0,
      top: 0,
      width: artW,
      height: artH,
      child: _reportArt(
        _artGestures(
          _hero(
            Container(
              decoration: BoxDecoration(
                borderRadius: radius,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    offset: Offset(0, 32 * s),
                    blurRadius: 32 * s,
                  ),
                ],
              ),
              foregroundDecoration: BoxDecoration(
                borderRadius: radius,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.10),
                ),
              ),
              child: ClipRRect(borderRadius: radius, child: _artImage()),
            ),
          ),
        ),
      ),
    );
  }

  // FullBleed style: borderless edge-to-edge art melting into the background.
  Widget _fullbleedArt(double s, double w) {
    return Positioned(
      left: 0,
      top: 0,
      width: w,
      height: 486 * s,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _reportArt(
            _hero(
              ShaderMask(
                blendMode: BlendMode.dstIn,
                shaderCallback: (rect) => const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.0, 0.34, 0.68, 1.0],
                  colors: [
                    Colors.white,
                    Colors.white,
                    Color(0xB8FFFFFF),
                    Colors.transparent,
                  ],
                ).createShader(rect),
                child: _artImage(),
              ),
            ),
          ),
          // Only the visible upper artwork region accepts swipe/tap gestures.
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: 340 * s,
            child: _artGestures(
              const ColoredBox(color: Colors.transparent),
            ),
          ),
        ],
      ),
    );
  }

  /// Material 3 Expressive layouts (Styles 9–12: Main, Scallop, Clover, Burst).
  Widget _buildM3ExpressiveLayout(BuildContext context, Song song) {
    final l10n = AppLocalizations.of(context)!;
    final hasLyrics = ref.watch(_showPlayerLyricsProvider);
    final lyricsOn = ref.watch(
      settingsProvider.select((s) => s.playerLyricLine),
    );
    final useAccent = ref.watch(
      settingsProvider.select((s) => s.cardAccentColors || s.playerStyleAccent),
    );
    final accent = ref.watch(settingsProvider.select((s) => s.accent));
    final blur = ref.watch(settingsProvider.select((s) => s.playerStyleBlur));
    final blackBg = ref.watch(
      settingsProvider.select((s) => s.cardBlackBackground),
    );
    final isPlaying = ref.watch(playbackProvider.select((p) => p.isPlaying));
    final isStarred = ref.watch(
      playbackProvider.select((p) => p.currentSong?.isFavorite ?? song.isFavorite),
    );
    final isShuffle = ref.watch(playbackProvider.select((p) => p.isShuffle));
    final repeat = ref.watch(playbackProvider.select((p) => p.repeatMode));
    final showBadge = ref.watch(
      settingsProvider.select((s) => s.showQualityBadge),
    );
    final artScale = ref.watch(playerArtScaleProvider);
    final c = M3StylePalette.fromAccent(accent, useAccent: useAccent);
    final qualityInfo = _m3QualityInfo(ref, song);
    final settings = ref.watch(settingsProvider);
    final badgeText = QualityBadge.textFor(
      context,
      qualityInfo,
      QualityBadgeStyle.fromSettings(settings),
      shortTier: true,
    );
    final subtitle = (song.album?.trim().isNotEmpty ?? false)
        ? song.album!.trim()
        : l10n.nowPlaying;
    final fade = widget.fadeWithSlide;

    return LayoutBuilder(
      builder: (context, box) {
        final double w = box.maxWidth;
        final double h = box.maxHeight;
        final EdgeInsets safe = MediaQuery.paddingOf(context);
        final double s = math.min(w / 390.0, (h - safe.top - safe.bottom) / 844.0);
        final double chevronPad =
            widget.style == PlayerLayoutStyle.m3wavy ? 28 * s : 24 * s;
        final double chevronTopOff =
            widget.style == PlayerLayoutStyle.m3scallop ? 16 * s : 14 * s;
        final Offset arrowAnchor = Offset(
          w - chevronPad - 22 * s,
          safe.top + chevronTopOff + 24 * s,
        );

        Widget chevronBtn({Color? bg}) => GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _toggleExtras,
          child: Container(
            width: 44 * s,
            height: 44 * s,
            decoration: BoxDecoration(
              color: bg ?? Colors.white.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: AnimatedRotation(
              turns: _extrasOpen ? 0.5 : 0.0,
              duration: const Duration(milliseconds: 250),
              child: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Colors.white,
                size: 22 * s,
              ),
            ),
          ),
        );

        Widget starBtn({double? radius, Color? bg}) {
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              AppHaptics.selection();
              _playback.toggleFavorite();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              width: (bg != null ? 52 : 48) * s,
              height: (bg != null ? 52 : 48) * s,
              decoration: BoxDecoration(
                color: bg ?? Colors.transparent,
                borderRadius: BorderRadius.circular(
                  (radius ?? (isStarred ? 26 : 18)) * s,
                ),
              ),
              child: AnimatedScale(
                scale: isStarred ? 1.12 : 1.0,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutBack,
                child: Icon(
                  isStarred ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: isStarred
                      ? const Color(0xFFFFD54F)
                      : (bg != null
                            ? c.on
                            : Colors.white.withValues(alpha: 0.85)),
                  size: 22 * s,
                ),
              ),
            ),
          );
        }

        Widget iconBtn({
          required IconData icon,
          required VoidCallback onTap,
          double size = 48,
          double iconSize = 22,
          Color? bg,
          Color? fg,
          BorderRadius? radius,
          double? width,
          double? height,
        }) {
          final br = radius ?? BorderRadius.circular((size / 2) * s);
          return Material(
            color: Colors.transparent,
            borderRadius: br,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                width: (width ?? size) * s,
                height: (height ?? size) * s,
                decoration: BoxDecoration(
                  color: bg ?? Colors.transparent,
                  borderRadius: br,
                ),
                child: Icon(
                  icon,
                  color: fg ?? Colors.white.withValues(alpha: 0.85),
                  size: iconSize * s,
                ),
              ),
            ),
          );
        }

        Widget lyricsCircleBtn() => iconBtn(
          icon: Icons.chat_bubble_outline_rounded,
          bg: lyricsOn ? c.primary : Colors.transparent,
          fg: lyricsOn ? c.onPrimary : Colors.white.withValues(alpha: 0.85),
          onTap: () {
            AppHaptics.selection();
            ref
                .read(settingsProvider.notifier)
                .updatePlayerLyricLine(!lyricsOn);
          },
        );

        Widget queueBtn() => iconBtn(
          icon: Icons.queue_music_rounded,
          onTap: () {
            AppHaptics.medium();
            widget.onShowQueue();
          },
        );

        Widget shuffleBtn({
          Color? fg,
          Color? bg,
          double? width,
          double? height,
          bool capsule = false,
        }) => iconBtn(
          icon: Icons.shuffle_rounded,
          width: width,
          height: height,
          iconSize: 20,
          bg:
              bg ??
              (isShuffle
                  ? (capsule ? Colors.white.withValues(alpha: 0.16) : c.primary)
                  : Colors.transparent),
          fg:
              fg ??
              (isShuffle
                  ? (capsule ? c.primary : c.onPrimary)
                  : Colors.white.withValues(alpha: 0.72)),
          onTap: () {
            AppHaptics.selection();
            _playback.toggleShuffle();
          },
        );

        Widget repeatBtn({
          Color? fg,
          Color? bg,
          double? width,
          double? height,
          bool capsule = false,
        }) {
          final bool active = repeat != RepeatMode.off;
          return iconBtn(
            icon: repeat == RepeatMode.one
                ? Icons.repeat_one_rounded
                : Icons.repeat_rounded,
            width: width,
            height: height,
            iconSize: 20,
            bg:
                bg ??
                (active
                    ? (capsule
                          ? Colors.white.withValues(alpha: 0.16)
                          : c.primary)
                    : Colors.transparent),
            fg:
                fg ??
                (active
                    ? (capsule ? c.primary : c.onPrimary)
                    : Colors.white.withValues(alpha: 0.72)),
            onTap: () {
              AppHaptics.selection();
              _playback.nextRepeatMode();
            },
          );
        }

        Widget body;
        switch (widget.style) {
          case PlayerLayoutStyle.m3scallop:
            final double artH = ((hasLyrics ? 200 : 410) * s * artScale).clamp(
              140 * s,
              455 * s,
            );
            body = Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 360),
                  curve: Curves.easeOutCubic,
                  height: artH + safe.top,
                  width: double.infinity,
                  child: ClipPath(
                    clipper: const ScallopEdgeClipper(),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _reportArt(_artGestures(_hero(_artImage()))),
                        IgnorePointer(
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: Container(
                              height: 120 * s + safe.top,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [Color(0x73000000), Colors.transparent],
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 24 * s,
                          right: 24 * s,
                          top: safe.top + 16 * s,
                          height: 48 * s,
                          child: fade(
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    '${l10n.nowPlaying.toUpperCase()} · $subtitle',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11 * s,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.12 * 11 * s,
                                      color: Colors.white.withValues(alpha: 0.85),
                                    ),
                                  ),
                                ),
                                chevronBtn(
                                  bg: Colors.black.withValues(alpha: 0.28),
                                ),
                              ],
                            ),
                            FluidSectionMotion.topBar,
                          ),
                        ),
                        if (showBadge)
                          Positioned(
                            left: 24 * s,
                            bottom: 40 * s,
                            child: GestureDetector(
                              onTap: () => showQualityDetailsSheet(context, song),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 10 * s,
                                  vertical: 5 * s,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.35),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  badgeText,
                                  style: TextStyle(
                                    fontSize: 10 * s,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.08 * 10 * s,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      28 * s,
                      10 * s,
                      28 * s,
                      24 * s + safe.bottom,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            switchInCurve: Curves.easeOutCubic,
                            switchOutCurve: Curves.easeInCubic,
                            layoutBuilder: (current, previous) => Stack(
                              fit: StackFit.expand,
                              alignment: Alignment.bottomLeft,
                              children: [...previous, ?current],
                            ),
                            child: hasLyrics
                                ? Column(
                                    key: const ValueKey('scallop_lyrics'),
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      GestureDetector(
                                        onTap: widget.onShowSongInfo,
                                        child: Text(
                                          '${song.title} · ${artistAlbumLabel(song, l10n, showAlbum: false)}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 14 * s,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white.withValues(
                                              alpha: 0.6,
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: 10 * s),
                                      Expanded(
                                        child: fade(
                                          _lyricsBlock(s),
                                          FluidSectionMotion.songInfo,
                                        ),
                                      ),
                                    ],
                                  )
                                : Align(
                                    key: const ValueKey('scallop_title'),
                                    alignment: Alignment.bottomLeft,
                                    child: GestureDetector(
                                      onTap: widget.onShowSongInfo,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            song.title,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontFamily: 'Stack Sans Text',
                                              fontSize: 42 * s,
                                              fontWeight: FontWeight.w800,
                                              height: 0.98,
                                              letterSpacing: -0.04 * 42 * s,
                                              color: Colors.white,
                                            ),
                                          ),
                                          SizedBox(height: 8 * s),
                                          Text(
                                            artistAlbumLabel(
                                              song,
                                              l10n,
                                              showAlbum: false,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 18 * s,
                                              fontWeight: FontWeight.w600,
                                              color: c.on.withValues(
                                                alpha: 0.85,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                        SizedBox(height: 24 * s),
                        fade(
                          _seekHero(
                            M3GappedSeekRow(
                              scale: s,
                              activeColor: c.primary,
                              barHeight: 18,
                              thumbHeight: 40,
                              showStopDot: true,
                            ),
                          ),
                          FluidSectionMotion.seekBar,
                        ),
                        SizedBox(height: 22 * s),
                        fade(
                          SizedBox(
                            height: 80 * s,
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 10,
                                  child: iconBtn(
                                    icon: Icons.skip_previous_rounded,
                                    iconSize: 28,
                                    height: 80,
                                    bg: c.container,
                                    fg: c.on,
                                    radius: BorderRadius.horizontal(
                                      left: Radius.circular(40 * s),
                                      right: Radius.circular(12 * s),
                                    ),
                                    onTap: () {
                                      AppHaptics.light();
                                      _afterThisFrame(_playback.skipPrevious);
                                    },
                                  ),
                                ),
                                SizedBox(width: 4 * s),
                                Expanded(
                                  flex: 17,
                                  child: GestureDetector(
                                    onTap: () {
                                      AppHaptics.medium();
                                      _playback.togglePlay();
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 260,
                                      ),
                                      curve: Curves.easeOutCubic,
                                      height: 80 * s,
                                      decoration: BoxDecoration(
                                        color: c.primary,
                                        borderRadius: BorderRadius.circular(
                                          (isPlaying ? 14 : 40) * s,
                                        ),
                                      ),
                                      child: Icon(
                                        isPlaying
                                            ? Icons.pause_rounded
                                            : Icons.play_arrow_rounded,
                                        size: 36 * s,
                                        color: c.onPrimary,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 4 * s),
                                Expanded(
                                  flex: 10,
                                  child: iconBtn(
                                    icon: Icons.skip_next_rounded,
                                    iconSize: 28,
                                    height: 80,
                                    bg: c.container,
                                    fg: c.on,
                                    radius: BorderRadius.horizontal(
                                      left: Radius.circular(12 * s),
                                      right: Radius.circular(40 * s),
                                    ),
                                    onTap: () {
                                      AppHaptics.light();
                                      _afterThisFrame(_playback.skipNext);
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          FluidSectionMotion.transportRow,
                        ),
                        SizedBox(height: 20 * s),
                        fade(
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              starBtn(),
                              GestureDetector(
                                onTap: () {
                                  AppHaptics.selection();
                                  ref
                                      .read(settingsProvider.notifier)
                                      .updatePlayerLyricLine(!lyricsOn);
                                },
                                child: Container(
                                  height: 44 * s,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 18 * s,
                                  ),
                                  decoration: BoxDecoration(
                                    color: lyricsOn
                                        ? c.primary
                                        : Colors.white.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(22 * s),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.chat_bubble_outline_rounded,
                                        size: 18 * s,
                                        color: lyricsOn
                                            ? c.onPrimary
                                            : Colors.white,
                                      ),
                                      SizedBox(width: 8 * s),
                                      Text(
                                        l10n.lyrics,
                                        style: TextStyle(
                                          fontSize: 14 * s,
                                          fontWeight: FontWeight.w700,
                                          color: lyricsOn
                                              ? c.onPrimary
                                              : Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              queueBtn(),
                            ],
                          ),
                          FluidSectionMotion.utilityRow,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );

          case PlayerLayoutStyle.m3clover:
            final double artSide = ((hasLyrics ? 110 : 292) * s * artScale)
                .clamp(80 * s, 326 * s);
            body = Padding(
              padding: EdgeInsets.fromLTRB(
                24 * s,
                safe.top + 14 * s,
                24 * s,
                24 * s + safe.bottom,
              ),
              child: Column(
                children: [
                  fade(
                    SizedBox(
                      height: 48 * s,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SizedBox(width: 44 * s),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  l10n.nowPlaying.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 11 * s,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.12 * 11 * s,
                                    color: Colors.white.withValues(alpha: 0.6),
                                  ),
                                ),
                                Text(
                                  subtitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13 * s,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white.withValues(alpha: 0.88),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          chevronBtn(),
                        ],
                      ),
                    ),
                    FluidSectionMotion.topBar,
                  ),
                  SizedBox(height: 22 * s),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 360),
                    curve: Curves.easeOutCubic,
                    width: artSide,
                    height: artSide,
                    child: _reportArt(
                      _artGestures(
                        _hero(
                          CounterSpinningCloverArt(
                            playing: isPlaying,
                            child: _artImage(),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 22 * s),
                  GestureDetector(
                    onTap: widget.onShowSongInfo,
                    child: Column(
                      children: [
                        Text(
                          song.title,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Stack Sans Text',
                            fontSize: (hasLyrics ? 24 : 32) * s,
                            fontWeight: FontWeight.w800,
                            height: 1.05,
                            letterSpacing: -0.03 * 32 * s,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 8 * s),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                artistAlbumLabel(song, l10n, showAlbum: false),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 17 * s,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withValues(alpha: 0.62),
                                ),
                              ),
                            ),
                            if (showBadge) ...[
                              SizedBox(width: 10 * s),
                              GestureDetector(
                                onTap: () => showQualityDetailsSheet(context, song),
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 9 * s,
                                    vertical: 4 * s,
                                  ),
                                  decoration: BoxDecoration(
                                    color: c.container,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    badgeText,
                                    style: TextStyle(
                                      fontSize: 10 * s,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.06 * 10 * s,
                                      color: c.on,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      layoutBuilder: (current, previous) => Stack(
                        fit: StackFit.expand,
                        children: [...previous, ?current],
                      ),
                      child: hasLyrics
                          ? Padding(
                              key: const ValueKey('clover_lyrics'),
                              padding: EdgeInsets.only(top: 14 * s),
                              child: fade(
                                _lyricsBlock(s),
                                FluidSectionMotion.songInfo,
                              ),
                            )
                          : const SizedBox.shrink(
                              key: ValueKey('clover_empty'),
                            ),
                    ),
                  ),
                  fade(
                    _seekHero(
                      M3GappedSeekRow(
                        scale: s,
                        activeColor: c.primary,
                        barHeight: 12,
                        thumbHeight: 30,
                        showStopDot: false,
                        inlineTimes: true,
                      ),
                    ),
                    FluidSectionMotion.seekBar,
                  ),
                  SizedBox(height: 20 * s),
                  fade(
                    Container(
                      height: 84 * s,
                      padding: EdgeInsets.all(6 * s),
                      decoration: BoxDecoration(
                        color: c.container,
                        borderRadius: BorderRadius.circular(42 * s),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          shuffleBtn(
                            width: 50,
                            height: 72,
                            capsule: true,
                            fg: isShuffle ? c.primary : c.on,
                          ),
                          iconBtn(
                            icon: Icons.skip_previous_rounded,
                            width: 58,
                            height: 72,
                            iconSize: 26,
                            bg: Colors.white.withValues(alpha: 0.10),
                            fg: Colors.white,
                            radius: BorderRadius.horizontal(
                              left: Radius.circular(36 * s),
                              right: Radius.circular(12 * s),
                            ),
                            onTap: () {
                              AppHaptics.light();
                              _afterThisFrame(_playback.skipPrevious);
                            },
                          ),
                          SizedBox(width: 4 * s),
                          GestureDetector(
                            onTap: () {
                              AppHaptics.medium();
                              _playback.togglePlay();
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 260),
                              curve: Curves.easeOutCubic,
                              width: 92 * s,
                              height: 72 * s,
                              decoration: BoxDecoration(
                                color: c.primary,
                                borderRadius: BorderRadius.circular(
                                  (isPlaying ? 22 : 36) * s,
                                ),
                              ),
                              child: Icon(
                                isPlaying
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                size: 32 * s,
                                color: c.onPrimary,
                              ),
                            ),
                          ),
                          SizedBox(width: 4 * s),
                          iconBtn(
                            icon: Icons.skip_next_rounded,
                            width: 58,
                            height: 72,
                            iconSize: 26,
                            bg: Colors.white.withValues(alpha: 0.10),
                            fg: Colors.white,
                            radius: BorderRadius.horizontal(
                              left: Radius.circular(12 * s),
                              right: Radius.circular(36 * s),
                            ),
                            onTap: () {
                              AppHaptics.light();
                              _afterThisFrame(_playback.skipNext);
                            },
                          ),
                          repeatBtn(
                            width: 50,
                            height: 72,
                            capsule: true,
                            fg: repeat != RepeatMode.off ? c.primary : c.on,
                          ),
                        ],
                      ),
                    ),
                    FluidSectionMotion.transportRow,
                  ),
                  SizedBox(height: 16 * s),
                  fade(
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        starBtn(),
                        lyricsCircleBtn(),
                        queueBtn(),
                      ],
                    ),
                    FluidSectionMotion.utilityRow,
                  ),
                ],
              ),
            );

          case PlayerLayoutStyle.m3burst:
            final String fmtLabel = (qualityInfo.codec ?? 'AUDIO').toUpperCase();
            final bool hasDepth = qualityInfo.bitsPerSample > 0;
            final String depthTitle = hasDepth ? 'Bit depth' : 'Bitrate';
            final String depthVal = hasDepth
                ? '${qualityInfo.bitsPerSample}-bit'
                : (qualityInfo.bitrate > 0
                      ? '${(qualityInfo.bitrate / 1000).round()} kbps'
                      : 'Lossy');
            final String rateVal = qualityInfo.sampleRate > 0
                ? '${(qualityInfo.sampleRate / 1000).toStringAsFixed(qualityInfo.sampleRate % 1000 == 0 ? 0 : 1)} kHz'
                : '48 kHz';

            Widget specCell(String label, String val, BorderRadius radius) =>
                Expanded(
                  child: GestureDetector(
                    onTap: () => showQualityDetailsSheet(context, song),
                    child: Container(
                      height: 60 * s,
                      padding: EdgeInsets.only(left: 14 * s),
                      decoration: BoxDecoration(
                        color: c.container,
                        borderRadius: radius,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10 * s,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.1 * 10 * s,
                              color: Colors.white.withValues(alpha: 0.62),
                            ),
                          ),
                          Text(
                            val,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Space Grotesk',
                              fontSize: 16 * s,
                              fontWeight: FontWeight.w700,
                              color: c.on,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );

            body = Padding(
              padding: EdgeInsets.fromLTRB(
                24 * s,
                safe.top + 14 * s,
                24 * s,
                24 * s + safe.bottom,
              ),
              child: Column(
                children: [
                  fade(
                    SizedBox(
                      height: 48 * s,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (showBadge)
                            GestureDetector(
                              onTap: () => showQualityDetailsSheet(context, song),
                              child: Container(
                                height: 32 * s,
                                padding: EdgeInsets.symmetric(horizontal: 12 * s),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(16 * s),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 7 * s,
                                      height: 7 * s,
                                      decoration: BoxDecoration(
                                        color: c.primary,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    SizedBox(width: 8 * s),
                                    Text(
                                      badgeText,
                                      style: TextStyle(
                                        fontFamily: 'Space Grotesk',
                                        fontSize: 12 * s,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.06 * 12 * s,
                                        color: c.on,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            const SizedBox.shrink(),
                          chevronBtn(),
                        ],
                      ),
                    ),
                    FluidSectionMotion.topBar,
                  ),
                  SizedBox(height: 16 * s),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      layoutBuilder: (current, previous) => Stack(
                        fit: StackFit.expand,
                        children: [...previous, ?current],
                      ),
                      child: hasLyrics
                          ? KeyedSubtree(
                              key: const ValueKey('burst_lyrics'),
                              child: fade(
                                _lyricsBlock(s),
                                FluidSectionMotion.songInfo,
                              ),
                            )
                          : Column(
                              key: const ValueKey('burst_art'),
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Center(
                                    child: AspectRatio(
                                      aspectRatio: 1,
                                      child: ConstrainedBox(
                                        constraints: BoxConstraints(
                                          maxWidth: 290 * s * artScale,
                                          maxHeight: 290 * s * artScale,
                                        ),
                                        child: _reportArt(
                                          _artGestures(
                                            _hero(
                                              ClipPath(
                                                clipper:
                                                    const ExpressiveShapeClipper(
                                                      ExpressiveArtShape.burst,
                                                    ),
                                                child: _artImage(),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 14 * s),
                                Row(
                                  children: [
                                    specCell(
                                      'Format',
                                      fmtLabel,
                                      BorderRadius.horizontal(
                                        left: Radius.circular(20 * s),
                                        right: Radius.circular(8 * s),
                                      ),
                                    ),
                                    SizedBox(width: 4 * s),
                                    specCell(
                                      depthTitle,
                                      depthVal,
                                      BorderRadius.circular(8 * s),
                                    ),
                                    SizedBox(width: 4 * s),
                                    specCell(
                                      'Sample rate',
                                      rateVal,
                                      BorderRadius.horizontal(
                                        left: Radius.circular(8 * s),
                                        right: Radius.circular(20 * s),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                    ),
                  ),
                  SizedBox(height: 20 * s),
                  Row(
                    children: [
                      AnimatedSize(
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeOutCubic,
                        child: hasLyrics
                            ? Padding(
                                padding: EdgeInsets.only(right: 14 * s),
                                child: SizedBox(
                                  width: 56 * s,
                                  height: 56 * s,
                                  child: ClipPath(
                                    clipper: const ExpressiveShapeClipper(
                                      ExpressiveArtShape.burst,
                                    ),
                                    child: _artImage(),
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: widget.onShowSongInfo,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                song.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'Stack Sans Text',
                                  fontSize: 28 * s,
                                  fontWeight: FontWeight.w800,
                                  height: 1.05,
                                  letterSpacing: -0.03 * 28 * s,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 4 * s),
                              Text(
                                artistAlbumLabel(song, l10n, showAlbum: false),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 16 * s,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withValues(alpha: 0.62),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: 12 * s),
                      starBtn(radius: isStarred ? 26 : 16, bg: c.container),
                    ],
                  ),
                  SizedBox(height: 18 * s),
                  fade(
                    _seekHero(
                      M3WavySeekRow(
                        scale: s,
                        activeColor: c.primary,
                        showEndDot: false,
                        spaceGroteskTimes: true,
                      ),
                    ),
                    FluidSectionMotion.seekBar,
                  ),
                  SizedBox(height: 14 * s),
                  fade(
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        lyricsCircleBtn(),
                        iconBtn(
                          icon: Icons.skip_previous_rounded,
                          size: 60,
                          iconSize: 28,
                          fg: Colors.white,
                          onTap: () {
                            AppHaptics.light();
                            _afterThisFrame(_playback.skipPrevious);
                          },
                        ),
                        SpinningBurstPlayButton(
                          playing: isPlaying,
                          size: 104 * s,
                          color: c.primary,
                          iconColor: c.onPrimary,
                          onTap: () {
                            AppHaptics.medium();
                            _playback.togglePlay();
                          },
                        ),
                        iconBtn(
                          icon: Icons.skip_next_rounded,
                          size: 60,
                          iconSize: 28,
                          fg: Colors.white,
                          onTap: () {
                            AppHaptics.light();
                            _afterThisFrame(_playback.skipNext);
                          },
                        ),
                        queueBtn(),
                      ],
                    ),
                    FluidSectionMotion.transportRow,
                  ),
                ],
              ),
            );

          case PlayerLayoutStyle.m3wavy:
          default:
            final shape = expressiveShapeForSong(song.id, widget.style.index);
            body = Padding(
              padding: EdgeInsets.fromLTRB(
                28 * s,
                safe.top + 14 * s,
                28 * s,
                26 * s + safe.bottom,
              ),
              child: Column(
                children: [
                  fade(
                    SizedBox(
                      height: 48 * s,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.nowPlaying.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 11 * s,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.12 * 11 * s,
                                    color: Colors.white.withValues(alpha: 0.6),
                                  ),
                                ),
                                Text(
                                  subtitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13 * s,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white.withValues(alpha: 0.88),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          chevronBtn(),
                        ],
                      ),
                    ),
                    FluidSectionMotion.topBar,
                  ),
                  SizedBox(height: 14 * s),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      layoutBuilder: (current, previous) => Stack(
                        fit: StackFit.expand,
                        children: [...previous, ?current],
                      ),
                      child: hasLyrics
                          ? Column(
                              key: const ValueKey('wavy_lyrics'),
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    SizedBox(
                                      width: 64 * s,
                                      height: 64 * s,
                                      child: ClipPath(
                                        clipper: ExpressiveShapeClipper(shape),
                                        child: _artImage(),
                                      ),
                                    ),
                                    SizedBox(width: 14 * s),
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: widget.onShowSongInfo,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              song.title,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 18 * s,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white,
                                              ),
                                            ),
                                            Text(
                                              '${artistAlbumLabel(song, l10n, showAlbum: false)}${showBadge ? ' · $badgeText' : ''}',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 14 * s,
                                                color: Colors.white.withValues(
                                                  alpha: 0.6,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 16 * s),
                                Expanded(
                                  child: fade(
                                    _lyricsBlock(s),
                                    FluidSectionMotion.songInfo,
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              key: const ValueKey('wavy_art'),
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Center(
                                  child: AspectRatio(
                                    aspectRatio: 1,
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                        maxWidth: 334 * s * artScale,
                                        maxHeight: 334 * s * artScale,
                                      ),
                                      child: _reportArt(
                                        _artGestures(
                                          _hero(
                                            AnimatedSwitcher(
                                              duration: const Duration(
                                                milliseconds: 320,
                                              ),
                                              child: ClipPath(
                                                key: ValueKey((song.id, shape)),
                                                clipper: ExpressiveShapeClipper(
                                                  shape,
                                                ),
                                                child: _artImage(),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 14 * s),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: widget.onShowSongInfo,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            song.title,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontFamily: 'Stack Sans Text',
                                              fontSize: 34 * s,
                                              fontWeight: FontWeight.w800,
                                              height: 1.04,
                                              letterSpacing: -0.03 * 34 * s,
                                              color: Colors.white,
                                            ),
                                          ),
                                          SizedBox(height: 6 * s),
                                          Row(
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  artistAlbumLabel(
                                                    song,
                                                    l10n,
                                                    showAlbum: false,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontSize: 17 * s,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.white
                                                        .withValues(alpha: 0.62),
                                                  ),
                                                ),
                                              ),
                                              if (showBadge) ...[
                                                SizedBox(width: 10 * s),
                                                GestureDetector(
                                                  onTap: () =>
                                                      showQualityDetailsSheet(
                                                        context,
                                                        song,
                                                      ),
                                                  child: Container(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                          horizontal: 9 * s,
                                                          vertical: 4 * s,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: c.container,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            999,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      badgeText,
                                                      style: TextStyle(
                                                        fontSize: 10 * s,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        letterSpacing:
                                                            0.06 * 10 * s,
                                                        color: c.on,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 12 * s),
                                  starBtn(bg: c.container),
                                ],
                              ),
                            ],
                          ),
                    ),
                  ),
                  SizedBox(height: 20 * s),
                  fade(
                    _seekHero(
                      M3WavySeekRow(
                        scale: s,
                        activeColor: c.primary,
                        showEndDot: true,
                      ),
                    ),
                    FluidSectionMotion.seekBar,
                  ),
                  SizedBox(height: 22 * s),
                  fade(
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        iconBtn(
                          icon: Icons.skip_previous_rounded,
                          size: 72,
                          iconSize: 26,
                          bg: c.container,
                          fg: c.on,
                          onTap: () {
                            AppHaptics.light();
                            _afterThisFrame(_playback.skipPrevious);
                          },
                        ),
                        SizedBox(width: 14 * s),
                        GestureDetector(
                          onTap: () {
                            AppHaptics.medium();
                            _playback.togglePlay();
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 260),
                            curve: Curves.easeOutCubic,
                            width: 128 * s,
                            height: 88 * s,
                            decoration: BoxDecoration(
                              color: c.primary,
                              borderRadius: BorderRadius.circular(
                                (isPlaying ? 28 : 44) * s,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.35),
                                  offset: Offset(0, 14 * s),
                                  blurRadius: 30 * s,
                                ),
                              ],
                            ),
                            child: Icon(
                              isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              size: 34 * s,
                              color: c.onPrimary,
                            ),
                          ),
                        ),
                        SizedBox(width: 14 * s),
                        iconBtn(
                          icon: Icons.skip_next_rounded,
                          size: 72,
                          iconSize: 26,
                          bg: c.container,
                          fg: c.on,
                          onTap: () {
                            AppHaptics.light();
                            _afterThisFrame(_playback.skipNext);
                          },
                        ),
                      ],
                    ),
                    FluidSectionMotion.transportRow,
                  ),
                  SizedBox(height: 22 * s),
                  fade(
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10 * s),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          lyricsCircleBtn(),
                          shuffleBtn(),
                          repeatBtn(),
                          queueBtn(),
                        ],
                      ),
                    ),
                    FluidSectionMotion.utilityRow,
                  ),
                ],
              ),
            );
        }

        return Stack(
          fit: StackFit.expand,
          children: [
            fade(
              blackBg
                  ? const ColoredBox(color: Colors.black)
                  : RepaintBoundary(
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          const ColoredBox(color: Color(0xFF08080A)),
                          _FigmaBackground(
                            key: const ValueKey('m3_blur'),
                            song: song,
                            blur: blur,
                          ),
                          TweenAnimationBuilder<Color?>(
                            tween: ColorTween(end: c.glow),
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeInOut,
                            builder: (_, glow, _) => DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: RadialGradient(
                                  center: const Alignment(0, -0.52),
                                  radius: 1.24,
                                  colors: [
                                    glow ?? c.glow,
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                          TweenAnimationBuilder<Color?>(
                            tween: ColorTween(end: c.surface),
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeInOut,
                            builder: (_, surf, _) => DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  stops: const [0.0, 0.74],
                                  colors: [
                                    Colors.black.withValues(alpha: 0.05),
                                    surf ?? c.surface,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
              const FluidSectionMotion(0.25, 0.90, slide: false),
            ),
            body,
            Positioned.fill(
              child: fade(
                _ExtrasMenu(
                  open: _extrasOpen,
                  anchor: arrowAnchor,
                  scale: s,
                  down: true,
                  alignRight: true,
                  onClose: _closeExtras,
                  onShowLyrics: widget.onShowLyrics,
                  onShowOptions: widget.onShowOptions,
                ),
                FluidSectionMotion.utilityRow,
              ),
            ),
          ],
        );
      },
    );
  }

  // Card style: a floating card of art centered at top with shadow.
  Widget _cardArt(double sx, double s, double w) {
    final double artW = 346.735 * s;
    final double artH = 351 * s;
    return Positioned(
      left: (w - artW) / 2,
      top: 68 * s,
      width: artW,
      height: artH,
      child: _reportArt(
        _artGestures(
          _hero(
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5 * s),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    offset: Offset(0, 40 * s),
                    blurRadius: 35 * s,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(5 * s),
                child: _artImage(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Artwork pieces shared by the portrait and landscape styled layouts.
mixin _StyledArt<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  PlayerLayoutStyle get _style;
  Song get _song;
  bool get _enableSlide;
  VoidCallback get _onShowLyrics;
  VoidCallback get _onShowOptions;

  // The chevron's menu (Figma "arrow expanded").
  bool _extrasOpen = false;
  late final ValueNotifier<double> _expandProgress = ref.read(
    playerExpandProgressProvider,
  );

  @override
  void initState() {
    super.initState();
    _expandProgress.addListener(_closeExtrasWhenCollapsed);
  }

  @override
  void dispose() {
    _expandProgress.removeListener(_closeExtrasWhenCollapsed);
    super.dispose();
  }

  // The menu doesn't survive closing the player.
  void _closeExtrasWhenCollapsed() {
    if (_extrasOpen && _expandProgress.value <= 0.01) _closeExtras();
  }

  void _toggleExtras() {
    AppHaptics.selection();
    setState(() => _extrasOpen = !_extrasOpen);
  }

  void _closeExtras() {
    if (_extrasOpen) setState(() => _extrasOpen = false);
  }

  // Long press anywhere on the lyrics opens the lyrics screen.
  Widget _lyricsBlock(double s) => GestureDetector(
    key: const ValueKey('lyrics'),
    onLongPress: () {
      AppHaptics.medium();
      _onShowLyrics();
    },
    child: _LyricsBlock(scale: s),
  );

  double _artDragDx = 0.0;

  // Shared artwork gestures: tap opens lyrics, swipe skips, double tap on a
  // side seeks 10s, long press opens the song menu (no top bar here) and
  // a ~3 s hold opens the style picker.
  Widget _artGestures(Widget child) => LayoutBuilder(
    // The art's own width decides the side, not the whole layout's.
    builder: (context, box) => GestureDetector(
      onTap: _onShowLyrics,
      onDoubleTapDown: (details) {
        final left = details.localPosition.dx < box.maxWidth / 2;
        AppHaptics.light();
        ref.read(playbackProvider.notifier).seekRelative(left ? -10 : 10);
      },
      onDoubleTap: () {},
      onHorizontalDragStart: (_) => _artDragDx = 0.0,
      onHorizontalDragUpdate: (details) => _artDragDx += details.delta.dx,
      onHorizontalDragEnd: (details) {
        final v = details.primaryVelocity ?? 0;
        final bool isNext = _artDragDx < -50 || v < -300;
        final bool isPrev = _artDragDx > 50 || v > 300;
        _artDragDx = 0.0;
        if (!isNext && !isPrev) return;
        AppHaptics.light();
        final playback = ref.read(playbackProvider.notifier);
        isNext ? playback.skipNext() : playback.skipPrevious(force: true);
      },
      onHorizontalDragCancel: () => _artDragDx = 0.0,
      child: HoldForPlayerStyles(onLongPress: _onShowOptions, child: child),
    ),
  );

  // Flies in the Fluid Player too, as the classic player's art does: its
  // layer turns HeroMode off while collapsed.
  Widget _hero(Widget child) => Hero(
    tag: 'album_art',
    flightShuttleBuilder: artworkFlightShuttle,
    child: child,
  );

  Widget _artImage() => _StyledArtwork(song: _song, style: _style);
}

class _StyledArtwork extends StatelessWidget {
  final Song song;
  final PlayerLayoutStyle style;
  const _StyledArtwork({required this.song, required this.style});

  // A swipe changes the song at once; the cover cross-fades smoothly via GPU
  // alpha compositing (no per-frame ImageFilter.blur saveLayers).
  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
    duration: const Duration(milliseconds: 280),
    switchInCurve: Curves.easeOutCubic,
    switchOutCurve: Curves.easeInCubic,
    layoutBuilder: (current, previous) =>
        Stack(fit: StackFit.expand, children: [...previous, ?current]),
    transitionBuilder: (child, animation) =>
        FadeTransition(opacity: animation, child: child),
    child: _StyledArtworkImage(
      key: ValueKey(song.id),
      song: song,
      style: style,
    ),
  );
}

class _StyledArtworkImage extends ConsumerWidget {
  final Song song;
  final PlayerLayoutStyle style;
  const _StyledArtworkImage({
    super.key,
    required this.song,
    required this.style,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final art = song.artPath;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return OptimizedImage(
      key: ValueKey(song.id),
      imagePath: art != null && !art.startsWith('http') ? art : null,
      imageUrl: art != null && art.startsWith('http') ? art : null,
      fit: BoxFit.cover,
      cacheWidth: (MediaQuery.sizeOf(context).width * dpr).toInt(),
    );
  }
}

Widget _buildStyledBackground(
  BuildContext context,
  WidgetRef ref,
  Song song,
  PlayerLayoutStyle style,
) => AnimatedSwitcher(
  duration: const Duration(milliseconds: 500),
  transitionBuilder: (child, animation) =>
      FadeTransition(opacity: animation, child: child),
  child: _styledBackgroundFor(context, ref, song, style),
);

/// The Now Playing screen's background for [style], for screens that mirror
/// it (lyrics with Follow Now Playing Background on). Classic matches the
/// expanded player: blurred art, else the player gradient, else surface.
Widget nowPlayingBackground(
  BuildContext context,
  WidgetRef ref,
  Song song,
  PlayerLayoutStyle style,
) {
  if (style != PlayerLayoutStyle.classic) {
    return _buildStyledBackground(context, ref, song, style);
  }
  final settings = ref.watch(settingsProvider);
  final double darkness = settings.musicDarkness.isNaN
      ? 0.62
      : settings.musicDarkness;
  final bool art =
      (settings.enableDynamicTheming || settings.playerDynamicBackground) &&
      song.artPath != null;
  return AnimatedSwitcher(
    duration: const Duration(milliseconds: 800),
    transitionBuilder: (child, animation) =>
        FadeTransition(opacity: animation, child: child),
    child: art
        ? Stack(
            key: ValueKey(('art', song.id)),
            fit: StackFit.expand,
            children: [
              BlurredBackgroundArt(
                song: song,
                zoom: 1.08,
              ),
              ColoredBox(color: Colors.black.withValues(alpha: darkness)),
            ],
          )
        : settings.enablePlayerGradient
        ? SizedBox.expand(
            key: const ValueKey('gradient'),
            child: PlayerGradientBackground(
              darkness: darkness,
              animated: settings.animatePlayerGradient,
            ),
          )
        : ColoredBox(
            key: const ValueKey('surface'),
            color: Theme.of(context).colorScheme.surface,
          ),
  );
}

/// Each kind of background has its own key, so switching kinds crossfades.
Widget _styledBackgroundFor(
  BuildContext context,
  WidgetRef ref,
  Song song,
  PlayerLayoutStyle style,
) {
  if (style != PlayerLayoutStyle.classic) {
    final black = ref.watch(
      settingsProvider.select((s) => s.cardBlackBackground),
    );
    if (black) {
      return const ColoredBox(key: ValueKey('black'), color: Colors.black);
    }
    final accentBackground = ref.watch(
      settingsProvider.select((s) => s.cardAccentBackground),
    );
    if (accentBackground) {
      final enableGradient = ref.watch(
        settingsProvider.select((s) => s.enablePlayerGradient),
      );
      if (enableGradient) {
        final animated = ref.watch(
          settingsProvider.select((s) => s.animatePlayerGradient),
        );
        final musicDarkness = ref.watch(
          settingsProvider.select((s) => s.musicDarkness),
        );
        return PlayerGradientBackground(
          key: const ValueKey('gradient'),
          darkness: musicDarkness,
          animated: animated,
        );
      }
      final accent = ref.watch(settingsProvider.select((s) => s.accent));
      final Color accentColor = cardAccentBackgroundColor(accent);
      return TweenAnimationBuilder<Color?>(
        key: const ValueKey('accent'),
        tween: ColorTween(end: accentColor),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        builder: (context, color, _) => ColoredBox(color: color ?? accentColor),
      );
    }
  }
  final blur = ref.watch(settingsProvider.select((s) => s.playerStyleBlur));
  return _FigmaBackground(key: const ValueKey('figma'), song: song, blur: blur);
}

/// The card player's accent background: the accent pulled toward black, as
/// in the design, so white text and an accent seek bar both read on it.
Color cardAccentBackgroundColor(Color accent) =>
    Color.lerp(accent, Colors.black, 0.55)!;

/// Black base, the cover blurred over it and a warm wash from the top right.
class _FigmaBackground extends StatelessWidget {
  final Song song;
  final bool blur;
  const _FigmaBackground({super.key, required this.song, this.blur = true});

  @override
  Widget build(BuildContext context) {
    final art = song.artPath;
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Colors.black),
        // Figma: the cover at max blur with its colour pulled back, so the
        // controls sit on a soft, muted wash instead of the artwork's hues.
        // Baked once per song at screen resolution (BlurredBackgroundArt),
        // the same picture the live ImageFiltered drew: that re-blurred the
        // whole screen on every open/close frame (Impeller has no raster
        // cache).
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          transitionBuilder: (child, animation) =>
              FadeTransition(opacity: animation, child: child),
          child: blur && art != null
              ? ColoredBox(
                  key: ValueKey(('art', song.id)),
                  color: Colors.black,
                  child: BlurredBackgroundArt(
                    song: song,
                    sigma: 80,
                    saturation: 0.45,
                    tileMode: TileMode.mirror,
                    resolution: MediaQuery.devicePixelRatioOf(context),
                    artZoom: 1.6,
                    artAlignment: const Alignment(0, 0.4),
                    placeholder: false,
                  ),
                )
              : const ColoredBox(key: ValueKey('none'), color: Colors.black),
        ),
        ColoredBox(color: Colors.black.withValues(alpha: 0.35)),
        AnimatedOpacity(
          opacity: blur ? 1 : 0,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          child: const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(0.42, -1),
                end: Alignment(-0.42, 1),
                colors: [Color(0x40B8916B), Color(0x002184C6)],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Square-ish tap target with a press scale, around a fixed-size icon.
class _IconTap extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final String? semanticLabel;
  const _IconTap({
    required this.child,
    required this.onTap,
    required this.semanticLabel,
  });

  @override
  State<_IconTap> createState() => _IconTapState();
}

class _IconTapState extends State<_IconTap> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _down = true),
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) => setState(() => _down = false),
        onTap: widget.onTap,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: AnimatedScale(
              scale: _down ? 0.82 : 1,
              duration: const Duration(milliseconds: 120),
              curve: Curves.easeOut,
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}

class _PlayPauseButton extends ConsumerWidget {
  final double scale;
  const _PlayPauseButton({required this.scale});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPlaying = ref.watch(playbackProvider.select((p) => p.isPlaying));
    final isBuffering = ref.watch(
      playbackProvider.select((p) => p.isBuffering),
    );
    final l10n = AppLocalizations.of(context)!;
    return _IconTap(
      semanticLabel: isPlaying ? l10n.pause : l10n.play,
      onTap: () {
        AppHaptics.medium();
        ref.read(playbackProvider.notifier).togglePlay();
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            transitionBuilder: (child, a) => ScaleTransition(
              scale: a,
              child: FadeTransition(opacity: a, child: child),
            ),
            child: SvgPicture.asset(
              isPlaying ? '$_icons/pause.svg' : '$_icons/play.svg',
              key: ValueKey(isPlaying),
              width: 19 * scale,
              height: 22 * scale,
            ),
          ),
          if (isBuffering)
            SizedBox.square(
              dimension: 40 * scale,
              child: const CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white54,
              ),
            ),
        ],
      ),
    );
  }
}

/// The chevron that opens the player menu; it turns into the menu's close
/// button while open.
class _ExtrasToggle extends StatelessWidget {
  final bool open;
  final double scale;
  final VoidCallback onToggle;

  /// Landscape: the chevron points down, toward the menu below it.
  final bool vertical;
  const _ExtrasToggle({
    required this.open,
    required this.scale,
    required this.onToggle,
    this.vertical = false,
  });

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final l10n = AppLocalizations.of(context)!;
    return _IconTap(
      semanticLabel: open ? l10n.close : l10n.showMore,
      onTap: onToggle,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, a) => RotationTransition(
          turns: Tween(begin: -0.25, end: 0.0).animate(a),
          child: FadeTransition(opacity: a, child: child),
        ),
        child: RotatedBox(
          key: ValueKey(open),
          // The SVG points left; portrait turns it up, landscape down.
          quarterTurns: open ? 0 : (vertical ? 3 : 1),
          child: SvgPicture.asset(
            open ? '$_icons/close_button.svg' : '$_icons/chevron_button.svg',
            width: 30 * s,
            height: 30 * s,
          ),
        ),
      ),
    );
  }
}

/// Figma "arrow expanded": the screen dims to 80 % black and Repeat,
/// Shuffle, Lyrics and Other menu stack out of the chevron at [anchor]
/// (its centre), each a dark circle with its label beside it. One
/// controller drives everything; the items stagger out from the button and
/// fold back in reverse.
class _ExtrasMenu extends ConsumerStatefulWidget {
  final bool open;
  final Offset anchor;
  final double scale;

  /// Landscape: items open below the chevron with labels on the right
  /// (portrait: above it, labels on the left).
  final bool down;
  final bool alignRight;
  final VoidCallback onClose;
  final VoidCallback onShowLyrics;
  final VoidCallback onShowOptions;
  const _ExtrasMenu({
    required this.open,
    required this.anchor,
    required this.scale,
    required this.onClose,
    required this.onShowLyrics,
    required this.onShowOptions,
    this.down = false,
    this.alignRight = false,
  });

  @override
  ConsumerState<_ExtrasMenu> createState() => _ExtrasMenuState();
}

class _ExtrasMenuState extends ConsumerState<_ExtrasMenu>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
    reverseDuration: const Duration(milliseconds: 280),
    value: widget.open ? 1.0 : 0.0,
  );

  // Item centres from the chevron's, in design units (Figma: 50, 99, 148,
  // 197, 246 above the close button).
  static const List<double> _offsets = [50, 99, 148, 197, 246];

  @override
  void didUpdateWidget(_ExtrasMenu old) {
    super.didUpdateWidget(old);
    if (old.open != widget.open) {
      widget.open ? _c.forward() : _c.reverse();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.scale;
    final l10n = AppLocalizations.of(context)!;
    final isShuffle = ref.watch(playbackProvider.select((p) => p.isShuffle));
    final repeat = ref.watch(playbackProvider.select((p) => p.repeatMode));
    final lyricsOn = ref.watch(
      settingsProvider.select((x) => x.playerLyricLine),
    );
    final playback = ref.read(playbackProvider.notifier);

    Widget icon(String name, double w, double h, {bool on = true}) =>
        SvgPicture.asset(
          '$_icons/$name.svg',
          width: w * s,
          height: h * s,
          colorFilter: ColorFilter.mode(
            on ? Colors.white : Colors.white.withValues(alpha: 0.3),
            BlendMode.srcIn,
          ),
        );

    // Nearest the button first: Repeat, Shuffle, Lyrics, Other menu.
    final items =
        <
          ({
            String label,
            Widget icon,
            VoidCallback onTap,
            VoidCallback? onLongPress,
          })
        >[
          (
            label: l10n.repeatTooltip,
            icon: Stack(
              alignment: Alignment.center,
              children: [
                icon('repeat', 15.4, 14, on: repeat != RepeatMode.off),
                if (repeat == RepeatMode.one)
                  Text(
                    '1',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 7 * s,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
            onTap: () {
              AppHaptics.selection();
              playback.nextRepeatMode();
            },
            onLongPress: null,
          ),
          (
            label: l10n.shuffleTitle,
            icon: icon('shuffle', 15, 12, on: isShuffle),
            onTap: () {
              AppHaptics.selection();
              playback.toggleShuffle();
            },
            onLongPress: null,
          ),
          (
            label: l10n.lyrics,
            icon: icon('menu_lyrics', 15.555, 14, on: lyricsOn),
            // Tap shows / hides the lyrics on the player; long press opens
            // the lyrics screen.
            onTap: () {
              AppHaptics.selection();
              ref
                  .read(settingsProvider.notifier)
                  .updatePlayerLyricLine(!lyricsOn);
            },
            onLongPress: () {
              AppHaptics.medium();
              widget.onClose();
              widget.onShowLyrics();
            },
          ),
          (
            label: l10n.playerStyle,
            icon: Icon(
              Icons.style_outlined,
              color: Colors.white,
              size: 16 * s,
            ),
            onTap: () {
              AppHaptics.light();
              widget.onClose();
              openPlayerStylePicker(context);
            },
            onLongPress: null,
          ),
          (
            label: l10n.otherMenu,
            icon: icon('menu_more', 3, 14),
            onTap: () {
              AppHaptics.light();
              widget.onClose();
              widget.onShowOptions();
            },
            onLongPress: null,
          ),
        ];

    final label = TextStyle(
      fontFamily: 'Stack Sans Text',
      fontWeight: FontWeight.w500,
      fontSize: 14 * s,
      letterSpacing: -0.28 * s,
      color: Colors.white,
    );
    final double r = 17 * s; // circle radius
    final Offset a = widget.anchor;
    final bool down = widget.down;

    // Rebuilt only while the controller runs (a few small widgets).
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final double t = _c.value;
        // Closed: nothing painted or hit tested.
        if (t == 0.0) return const SizedBox.shrink();
        return Stack(
          fit: StackFit.expand,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onClose,
              child: ColoredBox(
                color: Colors.black.withValues(
                  alpha: 0.8 * Curves.easeOut.transform(t),
                ),
              ),
            ),
            for (int i = 0; i < items.length; i++)
              () {
                // Staggered outward, each over its own slice of the motion.
                final double start = i * 0.12;
                final double it = Curves.easeOutCubic.transform(
                  ((t - start) / 0.64).clamp(0.0, 1.0),
                );
                final double cy = down
                    ? a.dy + _offsets[i] * s
                    : a.dy - _offsets[i] * s;
                // Rises out of the button: starts 24 units toward it.
                final double lag = (1 - it) * 24 * s * (down ? -1 : 1);
                final item = items[i];
                final Widget circle = Container(
                  width: 2 * r,
                  height: 2 * r,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: Color(0xFF262626),
                    shape: BoxShape.circle,
                  ),
                  child: item.icon,
                );
                final Widget text = Text(item.label, style: label);
                final bool labelsOnLeft = !down || widget.alignRight;
                return Positioned(
                  left: labelsOnLeft ? 0 : a.dx - r,
                  right: labelsOnLeft ? null : 0,
                  width: labelsOnLeft ? a.dx + r : null,
                  top: cy - r + lag,
                  height: 2 * r,
                  child: IgnorePointer(
                    ignoring: !widget.open,
                    child: Opacity(
                      opacity: it,
                      child: Align(
                        alignment: labelsOnLeft
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Semantics(
                          button: true,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: item.onTap,
                            onLongPress: item.onLongPress,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: labelsOnLeft
                                  ? [text, SizedBox(width: 16 * s), circle]
                                  : [circle, SizedBox(width: 16 * s), text],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }(),
          ],
        );
      },
    );
  }
}

QualityInfo _m3QualityInfo(WidgetRef ref, Song song) {
  String path = '';
  try {
    path = song.path;
  } catch (_) {
    path = '';
  }
  final cachedAnalysis = path.isNotEmpty
      ? AudioAnalyzer.getCachedAnalysis(path)
      : null;
  return cachedAnalysis != null
      ? QualityInfo.fromAnalysis(cachedAnalysis)
      : ref
                .watch(currentSongAnalysisProvider)
                .whenOrNull(
                  data: (a) => a == null ? null : QualityInfo.fromAnalysis(a),
                ) ??
            (path.isNotEmpty
                ? QualityInfo.fromPath(path)
                : const QualityInfo(tier: QualityTier.high));
}

/// Whether the player shows the song's lyrics: it has some and the
/// "Lyrics on player" setting (the menu's Lyrics item) is on.
final _showPlayerLyricsProvider = Provider<bool>(
  (ref) =>
      ref.watch(settingsProvider.select((s) => s.playerLyricLine)) &&
      ref.watch(_playerLyricsProvider).lines.isNotEmpty,
);

/// Colour of the active lyric line and the seek bar fill.
/// - Classic: always the accent colour.
/// - Styled players (card / arc / linear): accent when accent colors toggle is on.
final _activeColorProvider = Provider<Color>(
  (ref) => ref.watch(
    settingsProvider.select((s) {
      final style = PlayerLayoutStyle.fromSetting(s.playerStyle);
      if (style == PlayerLayoutStyle.classic) return s.accent;
      return (s.cardAccentColors || s.playerStyleAccent)
          ? s.accent
          : Colors.white;
    }),
  ),
);

final _playerLyricsProvider = Provider<({List<LyricLine> lines, bool synced})>((
  ref,
) {
  final songId = ref.watch(playbackProvider.select((s) => s.currentSong?.id));
  return ref.watch(
    lyricsProvider.select(
      (s) => songId != null && s.songId == songId && s.rawLrc != null
          ? (lines: s.parsedLines, synced: s.isSynced)
          : (lines: const <LyricLine>[], synced: false),
    ),
  );
});

/// Every line of the song in a scrollable block that follows the singing:
/// the previous line, then the current one, then the rest. Lines blur and
/// dim more the further they are from the current one. Dragging scrolls
/// freely (all lines sharp, tap one to jump there); it snaps back to the
/// current line a few seconds after the finger lifts.
class _LyricsBlock extends ConsumerStatefulWidget {
  final double scale;
  const _LyricsBlock({required this.scale});

  @override
  ConsumerState<_LyricsBlock> createState() => _LyricsBlockState();
}

class _LyricsBlockState extends ConsumerState<_LyricsBlock> {
  final ScrollController _scroll = ScrollController();
  final Map<int, GlobalKey> _keys = {};
  bool _browsing = false;
  Timer? _resume;
  int _followed = -1;

  @override
  void dispose() {
    ScreenAwake.set(this, false);
    _resume?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  // Puts [index] one line below the block's top, like the design.
  void _follow(int index, {bool animate = true}) {
    _followed = index;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _keys[index]?.currentContext;
      if (!mounted || _browsing || ctx == null || !_scroll.hasClients) return;
      final box = ctx.findRenderObject() as RenderBox?;
      final list = context.findRenderObject() as RenderBox?;
      if (box == null || list == null) return;
      final top = box.localToGlobal(Offset.zero, ancestor: list).dy;
      final target = (_scroll.offset + top - 40 * widget.scale).clamp(
        0.0,
        _scroll.position.maxScrollExtent,
      );
      animate
          ? _scroll.animateTo(
              target,
              duration: const Duration(milliseconds: 520),
              curve: Curves.easeOutCubic,
            )
          : _scroll.jumpTo(target);
    });
  }

  bool _onScroll(ScrollNotification n) {
    // Only finger drags count as browsing, not our own animateTo.
    if (n is ScrollStartNotification && n.dragDetails != null) {
      _resume?.cancel();
      setState(() => _browsing = true);
    } else if (n is ScrollEndNotification && _browsing) {
      _resume?.cancel();
      _resume = Timer(const Duration(seconds: 3), () {
        if (!mounted) return;
        setState(() => _browsing = false);
        _follow(_followed);
      });
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final (:lines, :synced) = ref.watch(_playerLyricsProvider);
    final isPlaying = ref.watch(playbackProvider.select((p) => p.isPlaying));
    ScreenAwake.set(
      this,
      lines.isNotEmpty && TickerMode.valuesOf(context).enabled && isPlaying,
    );
    if (lines.isEmpty) return const SizedBox.shrink();
    final index = synced
        ? ref.watch(
            playbackProvider.select((p) => lyricLineIndexAt(lines, p.position)),
          )
        : -1;
    if (synced && index != _followed) _follow(index, animate: _followed >= 0);

    final mode = LyricsSyncMode.fromSetting(
      ref.watch(settingsProvider.select((s) => s.lyricsSyncStyle)),
    );
    final s = widget.scale;
    final active = ref.watch(_activeColorProvider);
    final style = TextStyle(
      fontFamily: 'Stack Sans Text',
      fontWeight: FontWeight.w700,
      fontSize: 30 * s,
      height: 40 / 30,
      letterSpacing: -0.6 * s,
      color: Colors.white,
    );

    Widget line(int i) {
      final l = lines[i];
      final text =
          AdvancedLyricLine.isInstrumentalText(l.text) || l.text.trim().isEmpty
          ? '♫'
          : l.text.trim();
      final current = i == index;
      final distance = (i - index).abs();
      Widget child;
      if (current && l.hasWordTiming && mode != LyricsSyncMode.line) {
        // Word by word, or letter by letter (char wipe), like the lyrics
        // screen; the clock is read here so only this line rebuilds per tick.
        child = Consumer(
          key: const ValueKey('word'),
          builder: (context, ref, _) => WordSyncedLyricText(
            line: l,
            position: ref.watch(playbackProvider.select((p) => p.position)),
            isPlaying: ref.watch(playbackProvider.select((p) => p.isPlaying)),
            style: style,
            activeColor: active,
            unsungColor: Colors.white.withValues(alpha: 0.35),
            textAlign: TextAlign.left,
            wipe: mode == LyricsSyncMode.char,
          ),
        );
      } else {
        final double alpha = !synced
            ? 0.6
            : current
            ? 1.0
            : _browsing
            ? 0.45
            : math.max(0.04, 0.16 - distance * 0.03);
        child = AnimatedDefaultTextStyle(
          key: const ValueKey('plain'),
          duration: const Duration(milliseconds: 380),
          curve: Curves.easeOutCubic,
          style: style.copyWith(
            color: (synced && current ? active : Colors.white).withValues(
              alpha: alpha,
            ),
          ),
          child: Text([text, ...l.extraLines].join('\n')),
        );
      }
      // Blur grows with the distance from the current line (none while
      // browsing or for plain lyrics, so every line can be read).
      final double sigma = !synced || current || _browsing
          ? 0
          : math.min(1.2 + (distance - 1) * 1.3, 7.0);
      return GestureDetector(
        key: _keys.putIfAbsent(i, GlobalKey.new),
        behavior: HitTestBehavior.opaque,
        onTap: !synced
            ? null
            : () {
                AppHaptics.light();
                ref.read(playbackProvider.notifier).seek(l.startTime);
                setState(() => _browsing = false);
                _resume?.cancel();
              },
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: sigma),
          duration: const Duration(milliseconds: 380),
          curve: Curves.easeOutCubic,
          // Always the same tree (enabled toggles): swapping ImageFiltered
          // in and out remounted the line and made it flash.
          builder: (context, v, c) => ImageFiltered(
            enabled: v >= 0.05,
            imageFilter: ImageFilter.blur(sigmaX: v, sigmaY: v),
            child: c,
          ),
          child: Padding(
            padding: EdgeInsets.only(bottom: 4 * s),
            // Smooth scale + cross-fade when the active lyric line advances.
            child: AnimatedScale(
              scale: !synced || current || _browsing ? 1.0 : 0.93,
              alignment: Alignment.centerLeft,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 240),
                layoutBuilder: (current, previous) => Stack(
                  alignment: Alignment.topLeft,
                  children: [...previous, ?current],
                ),
                child: child,
              ),
            ),
          ),
        ),
      );
    }

    return RepaintBoundary(
      child: NotificationListener<ScrollNotification>(
        onNotification: _onScroll,
        child: ShaderMask(
        // Lines fade out at the block's top and bottom edges as they scroll.
        blendMode: BlendMode.dstIn,
        shaderCallback: (rect) => const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.white,
            Colors.white,
            Colors.transparent,
          ],
          stops: [0, 0.06, 0.88, 1],
        ).createShader(rect),
        child: SingleChildScrollView(
          controller: _scroll,
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.only(bottom: 200 * s),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [for (int i = 0; i < lines.length; i++) line(i)],
          ),
        ),
      ),
    ),
    );
  }
}

class _StyledQualityBadge extends ConsumerWidget {
  final Song song;
  final double scale;
  final double leftMargin;

  const _StyledQualityBadge({
    required this.song,
    required this.scale,
    this.leftMargin = 0,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final show = ref.watch(settingsProvider.select((s) => s.showQualityBadge));
    if (!show) return const SizedBox.shrink();

    String path = '';
    try {
      path = song.path;
    } catch (_) {
      path = '';
    }

    final cachedAnalysis = path.isNotEmpty
        ? AudioAnalyzer.getCachedAnalysis(path)
        : null;
    final QualityInfo qualityInfo = cachedAnalysis != null
        ? QualityInfo.fromAnalysis(cachedAnalysis)
        : ref
                  .watch(currentSongAnalysisProvider)
                  .whenOrNull(
                    data: (a) => a == null ? null : QualityInfo.fromAnalysis(a),
                  ) ??
              (path.isNotEmpty
                  ? QualityInfo.fromPath(path)
                  : const QualityInfo(tier: QualityTier.high));

    final settings = ref.watch(settingsProvider);
    final style = QualityBadgeStyle.fromSettings(settings);
    final text = QualityBadge.textFor(
      context,
      qualityInfo,
      style,
      shortTier: true,
      suspectFake: QualityCheckService.isSuspect(
        QualityCheckService.cachedSync(path),
      ),
    );

    final Color? tint = QualityBadge.tintFor(
      style,
      qualityInfo,
      Theme.of(context).colorScheme.primary,
    );
    final Color textColor = tint ?? Colors.white.withValues(alpha: 0.5);

    final Widget? icon = QualityBadge.iconWidget(
      style.icon,
      10 * scale,
      textColor,
    );

    final badgeContent = Container(
      padding: EdgeInsets.symmetric(horizontal: 5 * scale, vertical: 2 * scale),
      decoration: BoxDecoration(
        color: (tint ?? Colors.white).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(3 * scale),
        border: Border.all(
          color: (tint ?? Colors.white).withValues(alpha: 0.05),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[icon, SizedBox(width: 3 * scale)],
          Text(
            text,
            maxLines: 1,
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontWeight: FontWeight.w700,
              fontSize: 12 * scale,
              color: textColor,
            ),
          ),
        ],
      ),
    );

    return Padding(
      padding: EdgeInsets.only(left: leftMargin),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          AppHaptics.light();
          if (path.isNotEmpty) {
            showQualityDetailsSheet(context, song);
          }
        },
        child: badgeContent,
      ),
    );
  }
}

class _SmallTitle extends StatelessWidget {
  final Song song;
  final double scale;
  final VoidCallback? onTap;
  final double titleAlpha;
  const _SmallTitle({
    required this.song,
    required this.scale,
    this.onTap,
    this.titleAlpha = 0.5,
  });

  @override
  Widget build(BuildContext context) {
    final base = TextStyle(
      fontFamily: 'Space Grotesk',
      fontWeight: FontWeight.w700,
      fontSize: 18 * scale,
      height: 23 / 18,
      letterSpacing: -0.36 * scale,
    );
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  song.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: base.copyWith(
                    color: Colors.white.withValues(alpha: titleAlpha),
                  ),
                ),
              ),
              _StyledQualityBadge(
                song: song,
                scale: scale,
                leftMargin: 6 * scale,
              ),
            ],
          ),
          Text(
            artistAlbumLabel(
              song,
              AppLocalizations.of(context)!,
              showAlbum: false,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: base.copyWith(color: Colors.white.withValues(alpha: 0.3)),
          ),
        ],
      ),
    );
  }
}

class _BigTitle extends StatelessWidget {
  final Song song;
  final double scale;
  final VoidCallback? onTap;
  const _BigTitle({
    super.key,
    required this.song,
    required this.scale,
    this.onTap,
  });

  // Design size, shrunk until the longest word fits on one line so a long
  // single-word title never breaks mid-word.
  static TextStyle _titleStyle(String title, double maxWidth, double scale) {
    TextStyle at(double size) => TextStyle(
      fontFamily: 'Stack Sans Text',
      fontWeight: FontWeight.w700,
      fontSize: size,
      height: 43 / 42,
      letterSpacing: -0.02 * size,
      color: Colors.white,
    );
    double size = 42 * scale;
    for (final word in title.split(RegExp(r'\s+'))) {
      final painter = TextPainter(
        text: TextSpan(text: word, style: at(size)),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout();
      if (painter.width > maxWidth) size *= maxWidth / painter.width;
      painter.dispose();
    }
    return at(math.max(size, 24 * scale));
  }

  @override
  Widget build(BuildContext context) {
    final double titleWidth = 260 * scale;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: titleWidth),
            child: Text(
              song.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: _titleStyle(song.title, titleWidth, scale),
            ),
          ),
          SizedBox(height: 3 * scale),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 260 * scale),
                  child: Text(
                    artistAlbumLabel(
                      song,
                      AppLocalizations.of(context)!,
                      showAlbum: false,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Stack Sans Text',
                      fontWeight: FontWeight.w700,
                      fontSize: 25 * scale,
                      height: 30 / 25,
                      letterSpacing: -0.5 * scale,
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                ),
              ),
              _StyledQualityBadge(
                song: song,
                scale: scale,
                leftMargin: 8 * scale,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Shared scrub handling for both seek bars: [fraction] maps a local x to
/// 0..1 along the bar.
mixin _Scrubbing<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  double? dragFraction;

  void scrubStart(double f) {
    ref.read(playbackProvider.notifier).startScrubbing();
    setState(() => dragFraction = f);
  }

  void scrubUpdate(double f) => setState(() => dragFraction = f);

  void scrubEnd() {
    final f = dragFraction;
    final playback = ref.read(playbackProvider.notifier);
    if (f != null) {
      final d = ref.read(playbackProvider).duration;
      playback.seek(d * f);
    }
    playback.stopScrubbing();
    setState(() => dragFraction = null);
  }

  void tapSeek(double f) {
    AppHaptics.light();
    final d = ref.read(playbackProvider).duration;
    ref.read(playbackProvider.notifier).seek(d * f);
  }
}

/// The seek bar flies to and from the lyrics screen's, as on the classic
/// player.
Widget _seekHero(Widget child) => Hero(
  tag: 'player_seek_bar',
  child: Material(type: MaterialType.transparency, child: child),
);

TextStyle _timeStyle(double s) => TextStyle(
  fontFamily: 'DM Sans',
  fontSize: 15 * s,
  color: Colors.white,
  fontFeatures: const [FontFeature.tabularFigures()],
);

/// A time that always stays on one line (long songs, big font scales).
Widget _timeText(String text, double s, {TextAlign? align}) => Text(
  text,
  maxLines: 1,
  softWrap: false,
  overflow: TextOverflow.visible,
  textAlign: align,
  style: _timeStyle(s),
);

/// Elliptical seek bar under the arc art; the times sit tilted at its ends.
class _ArcSeekBar extends ConsumerStatefulWidget {
  final double sx;
  final double s;

  /// Where this box starts on the screen, to map design y into it.
  final double top;
  final double cx;
  final double cy;
  final double rx;
  final double ry;
  final double startDeg;
  final double endDeg;
  final Offset leftLabel;
  final Offset rightLabel;

  const _ArcSeekBar({
    required this.sx,
    required this.s,
    required this.top,
    this.cx = 198.5,
    this.cy = 296.5,
    this.rx = 204.25,
    this.ry = 150.25,
    this.startDeg = 130.7,
    this.endDeg = 45.4,
    this.leftLabel = const Offset(41.6, 390.2),
    this.rightLabel = const Offset(362.9, 390.4),
  });

  @override
  ConsumerState<_ArcSeekBar> createState() => _ArcSeekBarState();
}

class _ArcSeekBarState extends ConsumerState<_ArcSeekBar>
    with _Scrubbing<_ArcSeekBar> {
  Offset get _center =>
      Offset(widget.cx * widget.sx, widget.cy * widget.s - widget.top);

  // Fraction along the arc (left end 0, right end 1) for a local point.
  double _fractionAt(Offset p) {
    final c = _center;
    final a =
        math.atan2(
          (p.dy - c.dy) / (widget.ry * widget.s),
          (p.dx - c.dx) / (widget.rx * widget.sx),
        ) *
        180 /
        math.pi;
    return ((widget.startDeg - a) / (widget.startDeg - widget.endDeg)).clamp(
      0.0,
      1.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    final position = ref.watch(playbackProvider.select((p) => p.position));
    final duration = ref.watch(playbackProvider.select((p) => p.duration));
    final ms = duration.inMilliseconds;
    final f =
        dragFraction ??
        (ms <= 0 ? 0.0 : (position.inMilliseconds / ms).clamp(0.0, 1.0));
    final shown = dragFraction != null ? duration * dragFraction! : position;
    final s = widget.s;
    final sx = widget.sx;

    Widget label(String text, Offset designCenter, double deg) => Positioned(
      left: designCenter.dx * sx - 30 * s,
      top: designCenter.dy * s - widget.top - 12 * s,
      width: 60 * s,
      height: 24 * s,
      child: IgnorePointer(
        child: Transform.rotate(
          angle: deg * math.pi / 180,
          child: OverflowBox(
            maxWidth: double.infinity,
            child: Center(child: _timeText(text, s)),
          ),
        ),
      ),
    );

    // deferToChild: only the band along the arc (see _ArcPainter.hitTest)
    // takes touches, so the art's round bottom still opens lyrics.
    return GestureDetector(
      behavior: HitTestBehavior.deferToChild,
      onTapUp: (d) => tapSeek(_fractionAt(d.localPosition)),
      onHorizontalDragStart: (d) => scrubStart(_fractionAt(d.localPosition)),
      onHorizontalDragUpdate: (d) => scrubUpdate(_fractionAt(d.localPosition)),
      onHorizontalDragEnd: (_) => scrubEnd(),
      onHorizontalDragCancel: scrubEnd,
      child: Stack(
        fit: StackFit.expand,
        children: [
          RepaintBoundary(
            child: CustomPaint(
              painter: _ArcPainter(
                color: ref.watch(_activeColorProvider),
                center: _center,
                rx: widget.rx * sx,
                ry: widget.ry * s,
                stroke: 6.5 * s,
                fraction: f,
                startDeg: widget.startDeg,
                endDeg: widget.endDeg,
              ),
            ),
          ),
          label(
            UiUtils.formatPlaybackDuration(shown),
            widget.leftLabel,
            40.05,
          ),
          label(
            UiUtils.formatPlaybackDuration(duration),
            widget.rightLabel,
            -40.6,
          ),
        ],
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  final Offset center;
  final double rx, ry, stroke, fraction, startDeg, endDeg;
  final Color color;
  const _ArcPainter({
    required this.color,
    required this.center,
    required this.rx,
    required this.ry,
    required this.stroke,
    required this.fraction,
    required this.startDeg,
    required this.endDeg,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCenter(center: center, width: rx * 2, height: ry * 2);
    const toRad = math.pi / 180;
    final sweep = (startDeg - endDeg) * toRad;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    // Angles run clockwise from +x; the visible arc is the bottom one.
    canvas.drawArc(
      rect,
      endDeg * toRad,
      sweep,
      false,
      paint..color = const Color(0xFFD9D9D9).withValues(alpha: 0.1),
    );
    if (fraction > 0) {
      canvas.drawArc(
        rect,
        startDeg * toRad,
        -sweep * fraction,
        false,
        paint..color = color,
      );
    }
  }

  @override
  bool? hitTest(Offset p) {
    final dx = (p.dx - center.dx) / rx, dy = (p.dy - center.dy) / ry;
    final r = math.sqrt(dx * dx + dy * dy);
    final deg = math.atan2(dy, dx) * 180 / math.pi;
    return (r - 1).abs() < 0.18 && deg > endDeg - 8 && deg < startDeg + 8;
  }

  @override
  bool shouldRepaint(_ArcPainter old) =>
      old.fraction != fraction ||
      old.color != color ||
      old.center != center ||
      old.rx != rx ||
      old.ry != ry;
}

/// Linear style: elapsed time, a straight bar and the total time.
class _LinearSeekRow extends ConsumerStatefulWidget {
  final double scale;
  final double barHeight;
  const _LinearSeekRow({required this.scale, this.barHeight = 8});

  @override
  ConsumerState<_LinearSeekRow> createState() => _LinearSeekRowState();
}

class _LinearSeekRowState extends ConsumerState<_LinearSeekRow>
    with _Scrubbing<_LinearSeekRow> {
  @override
  Widget build(BuildContext context) {
    final s = widget.scale;
    final position = ref.watch(playbackProvider.select((p) => p.position));
    final duration = ref.watch(playbackProvider.select((p) => p.duration));
    final ms = duration.inMilliseconds;
    final f =
        dragFraction ??
        (ms <= 0 ? 0.0 : (position.inMilliseconds / ms).clamp(0.0, 1.0));
    final shown = dragFraction != null ? duration * dragFraction! : position;

    return Row(
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(minWidth: 52 * s),
          child: _timeText(UiUtils.formatPlaybackDuration(shown), s),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, box) {
              double at(Offset p) => (p.dx / box.maxWidth).clamp(0.0, 1.0);
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: (d) => tapSeek(at(d.localPosition)),
                onHorizontalDragStart: (d) => scrubStart(at(d.localPosition)),
                onHorizontalDragUpdate: (d) => scrubUpdate(at(d.localPosition)),
                onHorizontalDragEnd: (_) => scrubEnd(),
                onHorizontalDragCancel: scrubEnd,
                child: Center(
                  child: Container(
                    height: widget.barHeight * s,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(
                        (widget.barHeight / 2) * s,
                      ),
                    ),
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: math.max(f, 0.0001),
                      child: Container(
                        decoration: BoxDecoration(
                          color: ref.watch(_activeColorProvider),
                          borderRadius: BorderRadius.circular(
                            (widget.barHeight / 2) * s,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        ConstrainedBox(
          constraints: BoxConstraints(minWidth: 46 * s),
          child: Padding(
            padding: EdgeInsets.only(left: 6 * s),
            child: _timeText(
              UiUtils.formatPlaybackDuration(duration),
              s,
              align: TextAlign.right,
            ),
          ),
        ),
      ],
    );
  }
}

// Landscape Figma frames (874 x 402); positions below are in their units.
const double _landW = 874;
const double _landH = 402;

/// Scale + offsets mapping the landscape design frame onto a window. Sizes
/// use [s]; x positions stretch across the width between the side insets.
class _LandFrame {
  final double left, sx, sy, s;
  _LandFrame(Size size, EdgeInsets safe)
    : left = safe.left,
      sx = math.max(0, size.width - safe.horizontal) / _landW,
      sy = size.height / _landH,
      s = math.min(
        math.max(0, size.width - safe.horizontal) / _landW,
        size.height / _landH,
      );
  double x(double v) => left + v * sx;
  double y(double v) => v * sy;
}

/// Where the landscape artwork is drawn for [style], in window coordinates.
/// A pure function of the window so the Fluid Player morph can aim at it.
Rect styledLandscapeArtRect(
  Size size,
  EdgeInsets safe,
  PlayerLayoutStyle style,
) {
  final f = _LandFrame(size, safe);
  final double h = size.height;
  return switch (style) {
    PlayerLayoutStyle.arc => Rect.fromLTWH(
      f.left,
      (h - 421 * f.s) / 2,
      415.885 * f.s,
      421 * f.s,
    ),
    PlayerLayoutStyle.linear || PlayerLayoutStyle.fullbleed => Rect.fromLTWH(
      f.left - 2.93 * f.s,
      (h - 412.856 * f.s) / 2,
      412.856 * f.s,
      412.856 * f.s,
    ),
    _ => Rect.fromLTWH(
      f.left + 24 * f.s,
      (h - 351 * f.s) / 2,
      351 * f.s,
      351 * f.s,
    ),
  };
}

/// Landscape body for all three player styles (Figma landscape frames):
/// art on the left, lyrics (or the big title) in the middle, transport on
/// the right - a column for classic / linear, a bottom row for arc.
class StyledLandscapeLayout extends ConsumerStatefulWidget {
  final PlayerLayoutStyle style;
  final Song song;
  final bool enableSlide;
  final Widget Function(Widget child, FluidSectionMotion motion) fadeWithSlide;
  final VoidCallback onShowLyrics;
  final VoidCallback onShowQueue;
  final VoidCallback onShowOptions;

  /// Tap on the title or artist: the small song sheet.
  final VoidCallback? onShowSongInfo;

  const StyledLandscapeLayout({
    super.key,
    required this.style,
    required this.song,
    required this.enableSlide,
    required this.fadeWithSlide,
    required this.onShowLyrics,
    required this.onShowQueue,
    required this.onShowOptions,
    this.onShowSongInfo,
  });

  @override
  ConsumerState<StyledLandscapeLayout> createState() =>
      _StyledLandscapeLayoutState();
}

class _StyledLandscapeLayoutState extends ConsumerState<StyledLandscapeLayout>
    with _StyledArt<StyledLandscapeLayout> {
  @override
  PlayerLayoutStyle get _style => widget.style;
  // Landscape player: both system bars hidden once it is fully open, back
  // once fully collapsed, so the inset change relayouts at rest and never
  // mid-motion. Only mounted in landscape, so rotating away releases it.
  void _syncFullscreen() {
    final double p = _expandProgress.value;
    if (p >= kFluidHandoff) {
      SystemNavigationBar.setFullscreen(this, true);
    } else if (p <= 0.01) {
      SystemNavigationBar.setFullscreen(this, false);
    }
  }

  @override
  void initState() {
    super.initState();
    _expandProgress.addListener(_syncFullscreen);
    _syncFullscreen();
  }

  @override
  void dispose() {
    _expandProgress.removeListener(_syncFullscreen);
    SystemNavigationBar.setFullscreen(this, false);
    super.dispose();
  }

  @override
  Song get _song => widget.song;
  @override
  bool get _enableSlide => widget.enableSlide;
  @override
  VoidCallback get _onShowLyrics => widget.onShowLyrics;
  @override
  VoidCallback get _onShowOptions => widget.onShowOptions;

  Playback get _playback => ref.read(playbackProvider.notifier);

  void _afterThisFrame(VoidCallback action) {
    SchedulerBinding.instance.endOfFrame.then((_) {
      if (mounted) action();
    });
  }

  @override
  Widget build(BuildContext context) {
    final song = widget.song;
    final style = widget.style;
    if (style.isM3Expressive) {
      return _buildM3ExpressiveLandscapeLayout(context, song, style);
    }
    final fade = widget.fadeWithSlide;
    final l10n = AppLocalizations.of(context)!;
    final hasLyrics = ref.watch(_showPlayerLyricsProvider);

    return LayoutBuilder(
      builder: (context, box) {
        final Size size = Size(box.maxWidth, box.maxHeight);
        final EdgeInsets safe = MediaQuery.paddingOf(context);
        final f = _LandFrame(size, safe);
        final double s = f.s;
        final double capsuleScale = style == PlayerLayoutStyle.capsule
            ? ref.watch(playerArtScaleProvider)
            : 1.0;
        final Rect baseArt = styledLandscapeArtRect(size, safe, style);
        final Rect art = switch (style) {
          PlayerLayoutStyle.fullbleed => Rect.fromLTWH(
            0,
            0,
            baseArt.right + 20 * s,
            size.height,
          ),
          PlayerLayoutStyle.asymmetric => Rect.fromLTWH(
            0,
            0,
            baseArt.right,
            baseArt.bottom,
          ),
          PlayerLayoutStyle.disc => Rect.fromCenter(
            center: baseArt.center,
            width: baseArt.width * 0.88,
            height: baseArt.height * 0.88,
          ),
          PlayerLayoutStyle.capsule when capsuleScale != 1.0 => Rect.fromCenter(
            center: baseArt.center,
            width: baseArt.width * capsuleScale,
            height: baseArt.height * capsuleScale,
          ),
          _ => baseArt,
        };
        final bool arc =
            style == PlayerLayoutStyle.arc || style == PlayerLayoutStyle.disc;

        Widget at(double x, double y, Widget child, {double box = 60}) =>
            Positioned(
              left: f.x(x) - box / 2 * s,
              top: f.y(y) - box / 2 * s,
              width: box * s,
              height: box * s,
              child: Center(child: child),
            );

        // Transport anchors (design units): arc is one row along the
        // bottom, classic / linear a column on the right.
        final ({Offset prev, Offset play, Offset next, Offset star}) t =
            switch (style) {
              PlayerLayoutStyle.arc || PlayerLayoutStyle.disc => (
                prev: const Offset(537, 334.5),
                play: const Offset(599.5, 334.5),
                next: const Offset(662, 334.5),
                star: const Offset(760.5, 334.5),
              ),
              PlayerLayoutStyle.linear || PlayerLayoutStyle.fullbleed => (
                prev: const Offset(810, 136.5),
                play: const Offset(810, 202.5),
                next: const Offset(810, 267.5),
                star: const Offset(810, 67.5),
              ),
              _ => (
                prev: const Offset(810, 145.5),
                play: const Offset(810, 211.5),
                next: const Offset(810, 276.5),
                star: const Offset(810, 76.5),
              ),
            };
        final Offset queue = arc
            ? const Offset(810, 335)
            : const Offset(810, 344);
        final Offset chevron = switch (style) {
          PlayerLayoutStyle.arc || PlayerLayoutStyle.disc => const Offset(39, 37),
          PlayerLayoutStyle.linear ||
          PlayerLayoutStyle.fullbleed => const Offset(39, 39),
          _ => const Offset(54, 45),
        };
        final double textLeft = arc ? 526 : 437;
        final double lyricsTop = arc ? 27 : 46;

        return Stack(
          fit: StackFit.expand,
          children: [
            fade(
              _buildStyledBackground(context, ref, song, style),
              FluidSectionMotion.backgroundFill,
            ),

            Positioned.fromRect(
              rect: art,
              child: _art(style, s, artScale: capsuleScale),
            ),

            if (arc)
              Positioned(
                left: art.left + 370 * s,
                top: 0,
                width: 110 * s,
                height: size.height,
                child: fade(
                  _LandscapeArcSeekBar(
                    s: s,
                    // Ellipse centre relative to this box.
                    center: Offset(-73.5 * s, art.center.dy + 2.5 * s),
                  ),
                  FluidSectionMotion.seekBar,
                ),
              )
            else
              Positioned(
                left: f.x(437),
                width: (776 - 437) * f.sx,
                top: f.y(344) - 20 * s,
                height: 40 * s,
                child: fade(
                  _seekHero(_LinearSeekRow(scale: s)),
                  FluidSectionMotion.seekBar,
                ),
              ),

            // Lyrics, or the big title when the song has none.
            Positioned(
              left: f.x(textLeft),
              top: f.y(lyricsTop),
              width: (hasLyrics ? 257 : 309) * s,
              height: 251 * s,
              child: fade(
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  child: hasLyrics
                      ? _lyricsBlock(s)
                      : Align(
                          key: ValueKey(('big', song.id)),
                          alignment: Alignment.centerLeft,
                          child: _LandscapeBigTitle(
                            song: song,
                            scale: s,
                            onTap: widget.onShowSongInfo,
                          ),
                        ),
                ),
                FluidSectionMotion.songInfo,
              ),
            ),

            if (hasLyrics)
              Positioned(
                left: (arc ? art.left + 36 * s : f.x(39)),
                width: 300 * s,
                bottom: 39 * s,
                child: fade(
                  _SmallTitle(
                    song: song,
                    scale: s,
                    titleAlpha: 0.9,
                    onTap: widget.onShowSongInfo,
                  ),
                  FluidSectionMotion.songInfo,
                ),
              ),

            at(
              t.prev.dx,
              t.prev.dy,
              fade(
                _IconTap(
                  semanticLabel: l10n.previousLabel,
                  onTap: () {
                    AppHaptics.light();
                    _afterThisFrame(_playback.skipPrevious);
                  },
                  child: Transform.flip(
                    flipX: true,
                    child: SvgPicture.asset(
                      '$_icons/next.svg',
                      width: 22 * s,
                      height: 19 * s,
                    ),
                  ),
                ),
                FluidSectionMotion.transportRow,
              ),
            ),
            at(
              t.play.dx,
              t.play.dy,
              fade(_PlayPauseButton(scale: s), FluidSectionMotion.transportRow),
            ),
            at(
              t.next.dx,
              t.next.dy,
              fade(
                _IconTap(
                  semanticLabel: l10n.nextLabel,
                  onTap: () {
                    AppHaptics.light();
                    _afterThisFrame(_playback.skipNext);
                  },
                  child: SvgPicture.asset(
                    '$_icons/next.svg',
                    width: 22 * s,
                    height: 19 * s,
                  ),
                ),
                FluidSectionMotion.transportRow,
              ),
            ),
            at(
              t.star.dx,
              t.star.dy,
              box: 56 / s,
              fade(
                FavoriteButtonWithGlow(song: song, ref: ref, useBlur: false),
                FluidSectionMotion.utilityRow,
              ),
            ),
            at(
              queue.dx,
              queue.dy,
              fade(
                _IconTap(
                  semanticLabel: l10n.queue,
                  onTap: () {
                    AppHaptics.medium();
                    widget.onShowQueue();
                  },
                  child: SvgPicture.asset(
                    '$_icons/queue_button.svg',
                    width: 30 * s,
                    height: 30 * s,
                  ),
                ),
                FluidSectionMotion.utilityRow,
              ),
            ),

            // Chevron on the art's top left; the menu opens below it.
            Positioned.fill(
              child: fade(
                _ExtrasMenu(
                  open: _extrasOpen,
                  anchor: Offset(
                    f.x(chevron.dx),
                    math.max(f.y(chevron.dy) - 24, safe.top) + 24,
                  ),
                  scale: s,
                  down: true,
                  onClose: _closeExtras,
                  onShowLyrics: widget.onShowLyrics,
                  onShowOptions: widget.onShowOptions,
                ),
                FluidSectionMotion.utilityRow,
              ),
            ),
            Positioned(
              left: f.x(chevron.dx) - 24,
              top: math.max(f.y(chevron.dy) - 24, safe.top),
              child: fade(
                _ExtrasToggle(
                  open: _extrasOpen,
                  scale: s,
                  vertical: true,
                  onToggle: _toggleExtras,
                ),
                FluidSectionMotion.utilityRow,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _art(PlayerLayoutStyle style, double s, {double artScale = 1.0}) {
    final shadow = [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.2),
        offset: Offset(0, 40 * s),
        blurRadius: 35 * s,
      ),
    ];
    final Widget content = switch (style) {
      // Round right side; the arc seek bar follows it.
      PlayerLayoutStyle.arc => DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.horizontal(
            right: Radius.circular(200 * s),
          ),
          boxShadow: shadow,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.horizontal(
            right: Radius.circular(200 * s),
          ),
          child: _artImage(),
        ),
      ),
      // Linear: framed 7px square fading into the background.
      PlayerLayoutStyle.linear => ShaderMask(
        blendMode: BlendMode.dstIn,
        shaderCallback: (rect) => const LinearGradient(
          colors: [Colors.white, Colors.transparent],
        ).createShader(rect),
        child: Container(
          foregroundDecoration: BoxDecoration(
            borderRadius: BorderRadius.circular(7 * s),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(7 * s),
            child: _artImage(),
          ),
        ),
      ),
      // FullBleed: borderless edge-to-edge art melting into the background.
      PlayerLayoutStyle.fullbleed => ShaderMask(
        blendMode: BlendMode.dstIn,
        shaderCallback: (rect) => const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          stops: [0.0, 0.34, 0.68, 1.0],
          colors: [
            Colors.white,
            Colors.white,
            Color(0xB8FFFFFF),
            Colors.transparent,
          ],
        ).createShader(rect),
        child: _artImage(),
      ),
      PlayerLayoutStyle.disc => DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: shadow,
        ),
        child: Container(
          foregroundDecoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
          ),
          child: ClipOval(child: _artImage()),
        ),
      ),
      PlayerLayoutStyle.asymmetric => DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(bottomRight: Radius.circular(40 * s)),
          boxShadow: shadow,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.only(bottomRight: Radius.circular(40 * s)),
          child: _artImage(),
        ),
      ),
      PlayerLayoutStyle.capsule => DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(102 * s * artScale),
          boxShadow: shadow,
        ),
        child: Container(
          foregroundDecoration: BoxDecoration(
            borderRadius: BorderRadius.circular(102 * s * artScale),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(102 * s * artScale),
            child: _artImage(),
          ),
        ),
      ),
      _ => DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5 * s),
          boxShadow: shadow,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(5 * s),
          child: _artImage(),
        ),
      ),
    };
    // Not reported to playerArtworkRectProvider: the landscape rect is
    // analytic (styledLandscapeArtRect) and a reported one would leak into
    // the portrait morph after rotating back.
    return _artGestures(_hero(content));
  }

  Widget _buildM3ExpressiveLandscapeLayout(
    BuildContext context,
    Song song,
    PlayerLayoutStyle style,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final hasLyrics = ref.watch(_showPlayerLyricsProvider);
    final useAccent = ref.watch(
      settingsProvider.select((s) => s.cardAccentColors || s.playerStyleAccent),
    );
    final accent = ref.watch(settingsProvider.select((s) => s.accent));
    final blur = ref.watch(settingsProvider.select((s) => s.playerStyleBlur));
    final blackBg = ref.watch(
      settingsProvider.select((s) => s.cardBlackBackground),
    );
    final isPlaying = ref.watch(playbackProvider.select((p) => p.isPlaying));
    final isStarred = ref.watch(
      playbackProvider.select((p) => p.currentSong?.isFavorite ?? song.isFavorite),
    );
    final isShuffle = ref.watch(playbackProvider.select((p) => p.isShuffle));
    final repeat = ref.watch(playbackProvider.select((p) => p.repeatMode));
    final lyricsOn = ref.watch(
      settingsProvider.select((s) => s.playerLyricLine),
    );
    final c = M3StylePalette.fromAccent(accent, useAccent: useAccent);
    final fade = widget.fadeWithSlide;

    final ExpressiveArtShape shape = expressiveShapeForSong(
      song.id,
      style.index,
    );
    final bool usesWavySeek =
        style == PlayerLayoutStyle.m3wavy || style == PlayerLayoutStyle.m3burst;

    return LayoutBuilder(
      builder: (context, box) {
        final Size size = Size(box.maxWidth, box.maxHeight);
        final EdgeInsets safe = MediaQuery.paddingOf(context);
        final f = _LandFrame(size, safe);
        final double s = f.s;
        final double artScale =
            (style == PlayerLayoutStyle.capsule ||
                style == PlayerLayoutStyle.m3wavy ||
                style == PlayerLayoutStyle.m3scallop ||
                style == PlayerLayoutStyle.m3clover ||
                style == PlayerLayoutStyle.m3burst)
            ? ref.watch(playerArtScaleProvider)
            : 1.0;
        final double artSide = (310 * s * artScale).clamp(
          180 * s,
          size.height - 48 * s,
        );
        final double artLeft = f.left + 20 * s;
        final double artTop = (size.height - artSide) / 2;
        final double rightLeft = artLeft + artSide + 36 * s;
        final double rightRight = math.max(safe.right + 28 * s, 32 * s);
        final Offset chevronPos = Offset(
          f.x(39),
          math.max(f.y(39) - 24, safe.top) + 24,
        );

        Widget buildArt() {
          if (style == PlayerLayoutStyle.m3scallop) {
            return ClipPath(
              clipper: const ScallopEdgeClipper(),
              child: _artImage(),
            );
          }
          if (style == PlayerLayoutStyle.m3clover) {
            return CounterSpinningCloverArt(
              playing: isPlaying,
              child: _artImage(),
            );
          }
          final artShape = style == PlayerLayoutStyle.m3burst
              ? ExpressiveArtShape.burst
              : shape;
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 320),
            child: ClipPath(
              key: ValueKey((song.id, artShape)),
              clipper: ExpressiveShapeClipper(artShape),
              child: _artImage(),
            ),
          );
        }

        Widget playBtn() {
          if (style == PlayerLayoutStyle.m3burst) {
            return SpinningBurstPlayButton(
              playing: isPlaying,
              size: 72 * s,
              color: c.primary,
              iconColor: c.onPrimary,
              onTap: () {
                AppHaptics.medium();
                _playback.togglePlay();
              },
            );
          }
          return GestureDetector(
            onTap: () {
              AppHaptics.medium();
              _playback.togglePlay();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              width: 84 * s,
              height: 58 * s,
              decoration: BoxDecoration(
                color: c.primary,
                borderRadius: BorderRadius.circular(
                  (isPlaying ? 18 : 29) * s,
                ),
              ),
              child: Icon(
                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                size: 30 * s,
                color: c.onPrimary,
              ),
            ),
          );
        }

        return Stack(
          fit: StackFit.expand,
          children: [
            fade(
              blackBg
                  ? const ColoredBox(color: Colors.black)
                  : RepaintBoundary(
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          const ColoredBox(color: Color(0xFF08080A)),
                          if (blur)
                            _FigmaBackground(
                              key: const ValueKey('m3_land_blur'),
                              song: song,
                              blur: true,
                            ),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: RadialGradient(
                                center: const Alignment(-0.4, 0),
                                radius: 1.2,
                                colors: [c.glow, Colors.transparent],
                              ),
                            ),
                          ),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.black.withValues(alpha: 0.08),
                                  c.surface,
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
              const FluidSectionMotion(0.25, 0.90, slide: false),
            ),
            if (style == PlayerLayoutStyle.m3scallop)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: artLeft + artSide,
                child: ClipPath(
                  clipper: const ScallopEdgeClipper(),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _artGestures(_hero(_artImage())),
                      if (ref.watch(
                        settingsProvider.select((s) => s.showQualityBadge),
                      ))
                        Positioned(
                          left: safe.left + 16 * s,
                          bottom: safe.bottom + 20 * s,
                          child: GestureDetector(
                            onTap: () => showQualityDetailsSheet(context, song),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 10 * s,
                                vertical: 5 * s,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.35),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                QualityBadge.textFor(
                                  context,
                                  _m3QualityInfo(ref, song),
                                  QualityBadgeStyle.fromSettings(
                                    ref.watch(settingsProvider),
                                  ),
                                  shortTier: true,
                                ),
                                style: TextStyle(
                                  fontSize: 10 * s,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              )
            else
              Positioned(
                left: artLeft,
                top: artTop,
                width: artSide,
                height: artSide,
                child: _artGestures(_hero(buildArt())),
              ),
            Positioned(
              left: rightLeft,
              right: rightRight,
              top: math.max(safe.top + 22 * s, 28 * s),
              bottom: math.max(safe.bottom + 18 * s, 24 * s),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: fade(
                      hasLyrics
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _SmallTitle(
                                  song: song,
                                  scale: s,
                                  titleAlpha: 0.9,
                                  onTap: widget.onShowSongInfo,
                                ),
                                SizedBox(height: 10 * s),
                                Expanded(child: _lyricsBlock(s)),
                              ],
                            )
                          : Align(
                              alignment: Alignment.centerLeft,
                              child: _LandscapeBigTitle(
                                song: song,
                                scale: s,
                                onTap: widget.onShowSongInfo,
                              ),
                            ),
                      FluidSectionMotion.songInfo,
                    ),
                  ),
                  SizedBox(height: 10 * s),
                  if (style == PlayerLayoutStyle.m3burst && !hasLyrics) ...[
                    fade(
                      () {
                        final q = _m3QualityInfo(ref, song);
                        final fmt = (q.codec ?? 'AUDIO').toUpperCase();
                        final hasDepth = q.bitsPerSample > 0;
                        final depthTitle = hasDepth ? 'Bit depth' : 'Bitrate';
                        final depthVal = hasDepth
                            ? '${q.bitsPerSample}-bit'
                            : (q.bitrate > 0 ? '${q.bitrate} kbps' : 'Hi-Res');
                        Widget statCard(
                          String label,
                          String val,
                          BorderRadius radius,
                        ) => Expanded(
                          child: Container(
                            height: 46 * s,
                            padding: EdgeInsets.symmetric(horizontal: 14 * s),
                            decoration: BoxDecoration(
                              color: c.container,
                              borderRadius: radius,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  label.toUpperCase(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 9 * s,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white.withValues(alpha: 0.62),
                                  ),
                                ),
                                Text(
                                  val,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: 'Space Grotesk',
                                    fontSize: 13 * s,
                                    fontWeight: FontWeight.w700,
                                    color: c.on,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                        return Row(
                          children: [
                            statCard(
                              'Format',
                              fmt,
                              BorderRadius.horizontal(
                                left: Radius.circular(20 * s),
                                right: Radius.circular(8 * s),
                              ),
                            ),
                            SizedBox(width: 4 * s),
                            statCard(
                              depthTitle,
                              depthVal,
                              BorderRadius.horizontal(
                                left: Radius.circular(8 * s),
                                right: Radius.circular(20 * s),
                              ),
                            ),
                          ],
                        );
                      }(),
                      FluidSectionMotion.songInfo,
                    ),
                    SizedBox(height: 10 * s),
                  ],
                  fade(
                    _seekHero(
                      usesWavySeek
                          ? M3WavySeekRow(
                              scale: s,
                              activeColor: c.primary,
                              showEndDot: style == PlayerLayoutStyle.m3wavy,
                            )
                          : M3GappedSeekRow(
                              scale: s,
                              activeColor: c.primary,
                              barHeight: style == PlayerLayoutStyle.m3scallop
                                  ? 16
                                  : 12,
                              thumbHeight: style == PlayerLayoutStyle.m3scallop
                                  ? 34
                                  : 28,
                              showStopDot: style == PlayerLayoutStyle.m3scallop,
                            ),
                    ),
                    FluidSectionMotion.seekBar,
                  ),
                  SizedBox(height: 12 * s),
                  fade(
                    switch (style) {
                      PlayerLayoutStyle.m3scallop => SizedBox(
                        height: 60 * s,
                        child: Row(
                          children: [
                            Expanded(
                              flex: 10,
                              child: Material(
                                color: c.container,
                                borderRadius: BorderRadius.horizontal(
                                  left: Radius.circular(30 * s),
                                  right: Radius.circular(10 * s),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: InkWell(
                                  onTap: () {
                                    AppHaptics.light();
                                    _afterThisFrame(_playback.skipPrevious);
                                  },
                                  child: Center(
                                    child: Icon(
                                      Icons.skip_previous_rounded,
                                      size: 26 * s,
                                      color: c.on,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 4 * s),
                            Expanded(
                              flex: 17,
                              child: GestureDetector(
                                onTap: () {
                                  AppHaptics.medium();
                                  _playback.togglePlay();
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 240),
                                  curve: Curves.easeOutCubic,
                                  height: 60 * s,
                                  decoration: BoxDecoration(
                                    color: c.primary,
                                    borderRadius: BorderRadius.circular(
                                      (isPlaying ? 12 : 30) * s,
                                    ),
                                  ),
                                  child: Icon(
                                    isPlaying
                                        ? Icons.pause_rounded
                                        : Icons.play_arrow_rounded,
                                    size: 30 * s,
                                    color: c.onPrimary,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 4 * s),
                            Expanded(
                              flex: 10,
                              child: Material(
                                color: c.container,
                                borderRadius: BorderRadius.horizontal(
                                  left: Radius.circular(10 * s),
                                  right: Radius.circular(30 * s),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: InkWell(
                                  onTap: () {
                                    AppHaptics.light();
                                    _afterThisFrame(_playback.skipNext);
                                  },
                                  child: Center(
                                    child: Icon(
                                      Icons.skip_next_rounded,
                                      size: 26 * s,
                                      color: c.on,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      PlayerLayoutStyle.m3clover => Center(
                        child: Container(
                          height: 64 * s,
                          padding: EdgeInsets.all(5 * s),
                          decoration: BoxDecoration(
                            color: c.container,
                            borderRadius: BorderRadius.circular(32 * s),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: () {
                                  AppHaptics.selection();
                                  _playback.toggleShuffle();
                                },
                                icon: Icon(
                                  Icons.shuffle_rounded,
                                  size: 19 * s,
                                  color: isShuffle ? c.primary : c.on,
                                ),
                              ),
                              Material(
                                color: Colors.white.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.horizontal(
                                  left: Radius.circular(27 * s),
                                  right: Radius.circular(10 * s),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: InkWell(
                                  onTap: () {
                                    AppHaptics.light();
                                    _afterThisFrame(_playback.skipPrevious);
                                  },
                                  child: SizedBox(
                                    width: 48 * s,
                                    height: 54 * s,
                                    child: Icon(
                                      Icons.skip_previous_rounded,
                                      size: 24 * s,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 4 * s),
                              playBtn(),
                              SizedBox(width: 4 * s),
                              Material(
                                color: Colors.white.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.horizontal(
                                  left: Radius.circular(10 * s),
                                  right: Radius.circular(27 * s),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: InkWell(
                                  onTap: () {
                                    AppHaptics.light();
                                    _afterThisFrame(_playback.skipNext);
                                  },
                                  child: SizedBox(
                                    width: 48 * s,
                                    height: 54 * s,
                                    child: Icon(
                                      Icons.skip_next_rounded,
                                      size: 24 * s,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  AppHaptics.selection();
                                  _playback.nextRepeatMode();
                                },
                                icon: Icon(
                                  repeat == RepeatMode.one
                                      ? Icons.repeat_one_rounded
                                      : Icons.repeat_rounded,
                                  size: 19 * s,
                                  color: repeat != RepeatMode.off
                                      ? c.primary
                                      : c.on,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      PlayerLayoutStyle.m3wavy => Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Material(
                            color: c.container,
                            shape: const CircleBorder(),
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              onTap: () {
                                AppHaptics.light();
                                _afterThisFrame(_playback.skipPrevious);
                              },
                              child: SizedBox(
                                width: 56 * s,
                                height: 56 * s,
                                child: Icon(
                                  Icons.skip_previous_rounded,
                                  size: 24 * s,
                                  color: c.on,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 12 * s),
                          playBtn(),
                          SizedBox(width: 12 * s),
                          Material(
                            color: c.container,
                            shape: const CircleBorder(),
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              onTap: () {
                                AppHaptics.light();
                                _afterThisFrame(_playback.skipNext);
                              },
                              child: SizedBox(
                                width: 56 * s,
                                height: 56 * s,
                                child: Icon(
                                  Icons.skip_next_rounded,
                                  size: 24 * s,
                                  color: c.on,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      _ => Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            onPressed: () {
                              AppHaptics.selection();
                              _playback.toggleFavorite();
                            },
                            icon: Icon(
                              isStarred
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              color: isStarred
                                  ? const Color(0xFFFFD54F)
                                  : Colors.white.withValues(alpha: 0.85),
                              size: 24 * s,
                            ),
                          ),
                          IconButton(
                            tooltip: l10n.previousLabel,
                            onPressed: () {
                              AppHaptics.light();
                              _afterThisFrame(_playback.skipPrevious);
                            },
                            icon: Icon(
                              Icons.skip_previous_rounded,
                              color: Colors.white,
                              size: 28 * s,
                            ),
                          ),
                          playBtn(),
                          IconButton(
                            tooltip: l10n.nextLabel,
                            onPressed: () {
                              AppHaptics.light();
                              _afterThisFrame(_playback.skipNext);
                            },
                            icon: Icon(
                              Icons.skip_next_rounded,
                              color: Colors.white,
                              size: 28 * s,
                            ),
                          ),
                          IconButton(
                            tooltip: l10n.queue,
                            onPressed: () {
                              AppHaptics.medium();
                              widget.onShowQueue();
                            },
                            icon: Icon(
                              Icons.queue_music_rounded,
                              color: Colors.white.withValues(alpha: 0.85),
                              size: 24 * s,
                            ),
                          ),
                        ],
                      ),
                    },
                    FluidSectionMotion.transportRow,
                  ),
                  SizedBox(height: 8 * s),
                  fade(
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        if (style != PlayerLayoutStyle.m3burst)
                          IconButton(
                            onPressed: () {
                              AppHaptics.selection();
                              _playback.toggleFavorite();
                            },
                            icon: Icon(
                              isStarred
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              color: isStarred
                                  ? const Color(0xFFFFD54F)
                                  : Colors.white.withValues(alpha: 0.85),
                              size: 20 * s,
                            ),
                          ),
                        GestureDetector(
                          onTap: () {
                            AppHaptics.selection();
                            ref
                                .read(settingsProvider.notifier)
                                .updatePlayerLyricLine(!lyricsOn);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            height: 34 * s,
                            padding: EdgeInsets.symmetric(horizontal: 14 * s),
                            decoration: BoxDecoration(
                              color: lyricsOn
                                  ? c.primary
                                  : Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(17 * s),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  size: 15 * s,
                                  color: lyricsOn ? c.onPrimary : Colors.white,
                                ),
                                SizedBox(width: 6 * s),
                                Text(
                                  l10n.lyrics,
                                  style: TextStyle(
                                    fontSize: 12 * s,
                                    fontWeight: FontWeight.w700,
                                    color: lyricsOn
                                        ? c.onPrimary
                                        : Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (style != PlayerLayoutStyle.m3clover) ...[
                          GestureDetector(
                            onTap: () {
                              AppHaptics.selection();
                              _playback.toggleShuffle();
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 40 * s,
                              height: 34 * s,
                              decoration: BoxDecoration(
                                color: isShuffle
                                    ? c.primary
                                    : Colors.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(17 * s),
                              ),
                              child: Icon(
                                Icons.shuffle_rounded,
                                size: 18 * s,
                                color: isShuffle
                                    ? c.onPrimary
                                    : Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              AppHaptics.selection();
                              _playback.nextRepeatMode();
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 40 * s,
                              height: 34 * s,
                              decoration: BoxDecoration(
                                color: repeat != RepeatMode.off
                                    ? c.primary
                                    : Colors.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(17 * s),
                              ),
                              child: Icon(
                                repeat == RepeatMode.one
                                    ? Icons.repeat_one_rounded
                                    : Icons.repeat_rounded,
                                size: 18 * s,
                                color: repeat != RepeatMode.off
                                    ? c.onPrimary
                                    : Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                          ),
                        ],
                        if (style != PlayerLayoutStyle.m3burst)
                          IconButton(
                            tooltip: l10n.queue,
                            onPressed: () {
                              AppHaptics.medium();
                              widget.onShowQueue();
                            },
                            icon: Icon(
                              Icons.queue_music_rounded,
                              color: Colors.white.withValues(alpha: 0.85),
                              size: 20 * s,
                            ),
                          ),
                      ],
                    ),
                    FluidSectionMotion.utilityRow,
                  ),
                ],
              ),
            ),
            Positioned.fill(
              child: fade(
                _ExtrasMenu(
                  open: _extrasOpen,
                  anchor: chevronPos,
                  scale: s,
                  down: true,
                  onClose: _closeExtras,
                  onShowLyrics: widget.onShowLyrics,
                  onShowOptions: widget.onShowOptions,
                ),
                FluidSectionMotion.utilityRow,
              ),
            ),
            Positioned(
              left: chevronPos.dx - 24 * s,
              top: chevronPos.dy - 30 * s,
              height: 60 * s,
              child: fade(
                _ExtrasToggle(
                  open: _extrasOpen,
                  scale: s,
                  onToggle: _toggleExtras,
                ),
                FluidSectionMotion.utilityRow,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Landscape title when the song has no lyrics: title and artist at 40.
class _LandscapeBigTitle extends StatelessWidget {
  final Song song;
  final double scale;
  final VoidCallback? onTap;
  const _LandscapeBigTitle({
    required this.song,
    required this.scale,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    TextStyle style(double alpha) => TextStyle(
      fontFamily: 'Stack Sans Text',
      fontWeight: FontWeight.w700,
      fontSize: 40 * scale,
      height: 1,
      letterSpacing: -0.8 * scale,
      color: Colors.white.withValues(alpha: alpha),
    );
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  song.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: style(1),
                ),
              ),
              _StyledQualityBadge(
                song: song,
                scale: scale,
                leftMargin: 10 * scale,
              ),
            ],
          ),
          Text(
            artistAlbumLabel(
              song,
              AppLocalizations.of(context)!,
              showAlbum: false,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style(0.1),
          ),
        ],
      ),
    );
  }
}

/// Arc style in landscape: the seek bar runs up the art's round right side,
/// elapsed time at the bottom end and the total at the top.
class _LandscapeArcSeekBar extends ConsumerStatefulWidget {
  final double s;
  final Offset center;
  const _LandscapeArcSeekBar({required this.s, required this.center});

  @override
  ConsumerState<_LandscapeArcSeekBar> createState() =>
      _LandscapeArcSeekBarState();
}

class _LandscapeArcSeekBarState extends ConsumerState<_LandscapeArcSeekBar>
    with _Scrubbing<_LandscapeArcSeekBar> {
  // The portrait ellipse turned a quarter: radii swap, angles shift -90deg.
  static const double _rx = 150.25, _ry = 204.25;
  static const double _startDeg = 40.7, _endDeg = -44.6;

  double _fractionAt(Offset p) {
    final c = widget.center;
    final a =
        math.atan2(
          (p.dy - c.dy) / (_ry * widget.s),
          (p.dx - c.dx) / (_rx * widget.s),
        ) *
        180 /
        math.pi;
    return ((_startDeg - a) / (_startDeg - _endDeg)).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final position = ref.watch(playbackProvider.select((p) => p.position));
    final duration = ref.watch(playbackProvider.select((p) => p.duration));
    final ms = duration.inMilliseconds;
    final f =
        dragFraction ??
        (ms <= 0 ? 0.0 : (position.inMilliseconds / ms).clamp(0.0, 1.0));
    final shown = dragFraction != null ? duration * dragFraction! : position;
    final s = widget.s;
    final c = widget.center;

    Widget label(String text, Offset fromCenter) => Positioned(
      left: c.dx + fromCenter.dx * s - 30 * s,
      top: c.dy + fromCenter.dy * s - 12 * s,
      width: 60 * s,
      height: 24 * s,
      child: IgnorePointer(
        child: OverflowBox(
          maxWidth: double.infinity,
          child: Center(child: _timeText(text, s)),
        ),
      ),
    );

    return GestureDetector(
      behavior: HitTestBehavior.deferToChild,
      onTapUp: (d) => tapSeek(_fractionAt(d.localPosition)),
      onVerticalDragStart: (d) => scrubStart(_fractionAt(d.localPosition)),
      onVerticalDragUpdate: (d) => scrubUpdate(_fractionAt(d.localPosition)),
      onVerticalDragEnd: (_) => scrubEnd(),
      onVerticalDragCancel: scrubEnd,
      child: Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.none,
        children: [
          RepaintBoundary(
            child: CustomPaint(
              painter: _ArcPainter(
                color: ref.watch(_activeColorProvider),
                center: c,
                rx: _rx * s,
                ry: _ry * s,
                stroke: 6.5 * s,
                fraction: f,
                startDeg: _startDeg,
                endDeg: _endDeg,
              ),
            ),
          ),
          label(
            UiUtils.formatPlaybackDuration(shown),
            const Offset(107.5, 154.5),
          ),
          label(
            UiUtils.formatPlaybackDuration(duration),
            const Offset(106, -166.5),
          ),
        ],
      ),
    );
  }
}

/// The Linear and Card players' seek row, for the lyrics screen.
class LyricsLinearSeekRow extends StatelessWidget {
  final double scale;
  const LyricsLinearSeekRow({super.key, this.scale = 1.0});

  @override
  Widget build(BuildContext context) => _seekHero(
    SizedBox(
      height: 40 * scale,
      child: _LinearSeekRow(scale: scale),
    ),
  );
}

/// The lyrics screen's seek bar and transport for the Arc player: the
/// player's seek ellipse (same radii, span, stroke and colours) flipped
/// into an arch, with the Arc player's previous / play / next inside it.
class LyricsArcControls extends ConsumerStatefulWidget {
  /// Called on every touch, so the screen can keep its controls showing.
  final VoidCallback? onInteract;
  const LyricsArcControls({super.key, this.onInteract});

  @override
  ConsumerState<LyricsArcControls> createState() => _LyricsArcControlsState();
}

class _LyricsArcControlsState extends ConsumerState<LyricsArcControls>
    with _Scrubbing<LyricsArcControls> {
  // The Arc player's ellipse (design units), flipped top to bottom.
  static const double _rx = 204.25, _ry = 150.25, _cxD = 198.5;
  static const double _startDeg = -130.7, _endDeg = -45.4;
  // Apex of the arch in the box, and the box height (design units).
  static const double _apexY = 8, _boxH = 104;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final double s = box.maxWidth / _designW;
        final Offset center = Offset(_cxD * s, (_apexY + _ry) * s);

        double fractionAt(Offset p) {
          final a =
              math.atan2(
                (p.dy - center.dy) / (_ry * s),
                (p.dx - center.dx) / (_rx * s),
              ) *
              180 /
              math.pi;
          return ((a - _startDeg) / (_endDeg - _startDeg)).clamp(0.0, 1.0);
        }

        final position = ref.watch(playbackProvider.select((p) => p.position));
        final duration = ref.watch(playbackProvider.select((p) => p.duration));
        final ms = duration.inMilliseconds;
        final f =
            dragFraction ??
            (ms <= 0 ? 0.0 : (position.inMilliseconds / ms).clamp(0.0, 1.0));
        final shown = dragFraction != null
            ? duration * dragFraction!
            : position;

        // The player's times sit 56.5 units inside the curve at its ends;
        // mirrored, that is below the arch, tilted the other way.
        Widget label(String text, Offset playerD, double deg) => Positioned(
          left: playerD.dx * s - 30 * s,
          top: (_apexY + _ry - (playerD.dy - 296.5)) * s - 12 * s,
          width: 60 * s,
          height: 24 * s,
          child: IgnorePointer(
            child: Transform.rotate(
              angle: -deg * math.pi / 180,
              child: OverflowBox(
                maxWidth: double.infinity,
                child: Center(child: _timeText(text, s)),
              ),
            ),
          ),
        );

        Widget button(double xD, Widget child) => Positioned(
          left: xD * s - 24,
          top: 62 * s - 24,
          width: 48,
          height: 48,
          child: child,
        );

        final playback = ref.read(playbackProvider.notifier);
        return SizedBox(
          height: _boxH * s,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: _seekHero(
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapUp: (d) {
                      widget.onInteract?.call();
                      tapSeek(fractionAt(d.localPosition));
                    },
                    onHorizontalDragStart: (d) {
                      widget.onInteract?.call();
                      scrubStart(fractionAt(d.localPosition));
                    },
                    onHorizontalDragUpdate: (d) =>
                        scrubUpdate(fractionAt(d.localPosition)),
                    onHorizontalDragEnd: (_) => scrubEnd(),
                    onHorizontalDragCancel: scrubEnd,
                    child: RepaintBoundary(
                      child: CustomPaint(
                        painter: _ArcPainter(
                          color: ref.watch(_activeColorProvider),
                          center: center,
                          rx: _rx * s,
                          ry: _ry * s,
                          stroke: 6.5 * s,
                          fraction: f,
                          startDeg: _startDeg,
                          endDeg: _endDeg,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              label(
                UiUtils.formatPlaybackDuration(shown),
                const Offset(41.6, 390.2),
                40.05,
              ),
              label(
                UiUtils.formatPlaybackDuration(duration),
                const Offset(362.9, 390.4),
                -40.6,
              ),
              button(
                _cxD - 66,
                _IconTap(
                  semanticLabel: AppLocalizations.of(context)!.previousLabel,
                  onTap: () {
                    widget.onInteract?.call();
                    AppHaptics.light();
                    playback.skipPrevious();
                  },
                  child: Transform.flip(
                    flipX: true,
                    child: SvgPicture.asset(
                      '$_icons/next.svg',
                      width: 22 * s,
                      height: 19 * s,
                    ),
                  ),
                ),
              ),
              button(
                _cxD,
                Listener(
                  onPointerDown: (_) => widget.onInteract?.call(),
                  child: _PlayPauseButton(scale: s),
                ),
              ),
              button(
                _cxD + 66,
                _IconTap(
                  semanticLabel: AppLocalizations.of(context)!.nextLabel,
                  onTap: () {
                    widget.onInteract?.call();
                    AppHaptics.light();
                    playback.skipNext();
                  },
                  child: SvgPicture.asset(
                    '$_icons/next.svg',
                    width: 22 * s,
                    height: 19 * s,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
