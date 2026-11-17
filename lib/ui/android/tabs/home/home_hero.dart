import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:looper_player/features/settings/presentation/providers/settings_notifier.dart';
import 'package:looper_player/ui/widgets/common/selected_avatar.dart';
import 'package:looper_player/core/services/haptics/app_haptics.dart';
import 'package:looper_player/core/theme/app_fonts.dart';
import 'package:looper_player/core/motion/pause_when_offscreen.dart';
import 'package:looper_player/core/utils/motion.dart';
import 'package:looper_player/features/library/domain/models/models.dart';
import 'package:looper_player/l10n/app_localizations.dart';
import 'package:looper_player/ui/widgets/common/optimized_image.dart';

import 'package:looper_player/ui/widgets/common/home_design_kit.dart';

// Design frame: 402 wide, status bar 44, artwork fades out by y = 405.
const double _heroBelowStatusBar = 405 - 44;

/// The top of Home: big artwork under the status bar with the logo, search
/// and profile buttons on it, and a swipeable pair of cards:
/// - "Today Mix": a tilted wall of the mix's covers (a blurred cover when
///   there are only a few), with Play.
/// - "Surprise Me!": one random song's cover, with a dice that plays that
///   song, then the rest of [HomeHero.library] shuffled, and rolls a new cover.
class HomeHero extends StatefulWidget {
  const HomeHero({
    super.key,
    required this.mix,
    required this.library,
    this.artists = const [],
    this.stretch,
    required this.onPlayMix,
    required this.onPlayCover,
    required this.onSurprise,
  });

  final List<Song> mix;
  final List<Song> library;

  /// For the Artist Pick's photo.
  final List<Artist> artists;

  /// How far the page is pulled past its top: the artwork grows up into it.
  final ValueListenable<double>? stretch;
  final VoidCallback onPlayMix;

  /// A cover in the Today Mix wall was tapped: play [queue] from [index].
  final void Function(List<Song> queue, int index) onPlayCover;

  /// The dice was rolled while showing [pick].
  final void Function(Song? pick) onSurprise;

  @override
  State<HomeHero> createState() => _HomeHeroState();
}

class _HomeHeroState extends State<HomeHero> {
  // Cards repeat endlessly; start mid-way so either direction works.
  final _pages = PageController(initialPage: 12000);
  final _random = math.Random();
  Timer? _auto;
  Song? _surprise;

  @override
  void initState() {
    super.initState();
    _surprise = _pickSurprise();
    _auto = Timer.periodic(const Duration(seconds: 8), (_) => _advance());
  }

  @override
  void didUpdateWidget(HomeHero old) {
    super.didUpdateWidget(old);
    if (_surprise == null || !widget.library.contains(_surprise)) {
      _surprise = _pickSurprise();
    }
  }

  /// A swipe of your own restarts the wait before the next auto-advance.
  void _restartAuto() {
    _auto?.cancel();
    _auto = Timer.periodic(const Duration(seconds: 8), (_) => _advance());
  }

  /// Signed distance from the scroll position to card [i] of [n], the short
  /// way round the loop (-n/2…n/2).
  static double _loopDistance(double page, int i, int n) {
    if (n < 2) return 0;
    var d = (page - i) % n;
    if (d > n / 2) d -= n;
    return d;
  }

  double get _page => _pages.hasClients && _pages.position.haveDimensions
      ? _pages.page ?? _pages.initialPage.toDouble()
      : _pages.initialPage.toDouble();

  @override
  void dispose() {
    _auto?.cancel();
    _pages.dispose();
    super.dispose();
  }

  Song? _pickSurprise() {
    final withArt = widget.library.where((s) => s.artPath != null).toList();
    if (withArt.isEmpty) return null;
    return withArt[_random.nextInt(withArt.length)];
  }

  void _advance() {
    if (!mounted || !_pages.hasClients || _pageCount < 2) return;
    if (Motion.reducedOf(context)) return;
    // Off screen (scrolled away, hidden tab, covered route): each advance is
    // ~40 frames of full-hero blur nobody sees.
    if (!TickerMode.valuesOf(context).enabled) return;
    // Always forward: the loop has no last card to jump back from.
    final next = (_pages.page?.round() ?? 0) + 1;
    _pages.animateToPage(
      next,
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeInOutCubic,
    );
  }

  /// The songs on the Today Mix wall: the mix first, then other songs from
  /// the library so the wall shows as many different covers as it has tiles.
  List<Song> _wallSongs() {
    final seen = <String>{};
    final out = <Song>[];
    for (final s in [...widget.mix, ...widget.library]) {
      final art = s.artPath;
      if (art == null || !seen.add(art)) continue;
      out.add(s);
      if (out.length == _MixBackground.tiles) break;
    }
    return out;
  }

  // Built once per library list, not on every frame of a swipe.
  List<Song>? _for;
  List<Song> _weekly = const [];
  String? _artist;
  List<Song> _artistSongs = const [];

  void _refreshPicks() {
    if (identical(_for, widget.library)) return;
    _for = widget.library;
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    _weekly =
        widget.library
            .where((s) => s.lastPlayed?.isAfter(weekAgo) ?? false)
            .toList()
          ..sort((a, b) => b.playCount.compareTo(a.playCount));
    if (_weekly.length > 30) _weekly = _weekly.sublist(0, 30);
    if (_weekly.length < 4) _weekly = const [];

    // One of the five most played artists, kept while the library is.
    final plays = <String, int>{};
    final counts = <String, int>{};
    for (final s in widget.library) {
      final a = s.artist?.split(RegExp(r'[,&]| feat\.')).first.trim();
      if (a == null || a.isEmpty || _placeholderArtist(a)) continue;
      counts[a] = (counts[a] ?? 0) + 1;
      if (s.playCount > 0) plays[a] = (plays[a] ?? 0) + s.playCount;
    }
    final top = plays.keys.where((a) => counts[a]! >= 3).toList()
      ..sort((a, b) => plays[b]!.compareTo(plays[a]!));
    if (_artist == null || !top.take(5).contains(_artist)) {
      _artist = top.isEmpty
          ? null
          : top[_random.nextInt(math.min(5, top.length))];
    }
    _artistSongs = _artist == null
        ? const []
        : (widget.library
              .where((s) => s.artist?.startsWith(_artist!) ?? false)
              .toList()
            ..sort((a, b) => b.playCount.compareTo(a.playCount)));
    if (_artistSongs.length < 3) _artistSongs = const [];
  }

  /// Tag placeholders, not real artists: `<unknown>`, "Unknown Artist",
  /// "Various Artists".
  static bool _placeholderArtist(String name) {
    final n = name.toLowerCase();
    return n.contains('unknown') || n.startsWith('various artist');
  }

  /// The pick's photo: the artist's image when the library has one, else
  /// the cover of their most played song.
  (String?, String?) _artistImage() {
    for (final a in widget.artists) {
      if (a.name != _artist) continue;
      final img = a.artistImageUrl;
      if (img != null && img.isNotEmpty) {
        return img.startsWith('http') ? (null, img) : (img, null);
      }
      if (a.artPath != null) return (a.artPath, null);
    }
    return (_artistSongs.first.artPath, null);
  }

  bool get _hasArtist => _artistSongs.isNotEmpty;
  bool get _hasWeekly => _weekly.isNotEmpty;

  int _weeklyTurn = 0;
  Song _weeklyCover() {
    final withArt = _weekly.where((s) => s.artPath != null).toList();
    if (withArt.isEmpty) return _weekly.first;
    return withArt[_weeklyTurn % withArt.length];
  }

  bool get _hasMix => widget.mix.isNotEmpty;
  bool get _hasSurprise => _surprise != null;
  int get _pageCount =>
      (_hasMix ? 1 : 0) +
      (_hasArtist ? 1 : 0) +
      (_hasWeekly ? 1 : 0) +
      (_hasSurprise ? 1 : 0);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final top = MediaQuery.paddingOf(context).top;
    _refreshPicks();
    final wall = _hasMix ? _wallSongs() : const <Song>[];
    final (artistPath, artistUrl) = _hasArtist ? _artistImage() : (null, null);
    final backgrounds = <Widget>[
      if (_hasMix) _MixBackground(songs: wall),
      if (_hasArtist)
        _CoverBackground(imagePath: artistPath, imageUrl: artistUrl),
      if (_hasWeekly)
        // Like Surprise Me!: one sharp cover, the next of the week's top
        // songs fading in each time the card comes round.
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 600),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          layoutBuilder: (current, previous) =>
              Stack(fit: StackFit.expand, children: [...previous, ?current]),
          child: _CoverBackground(
            key: ValueKey(_weeklyCover().path),
            imagePath: _weeklyCover().artPath,
          ),
        ),
      if (_hasSurprise)
        // A new roll of the dice fades the next cover in.
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 600),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          layoutBuilder: (current, previous) =>
              Stack(fit: StackFit.expand, children: [...previous, ?current]),
          child: _CoverBackground(
            key: ValueKey(_surprise!.path),
            imagePath: _surprise!.artPath,
          ),
        ),
    ];
    final fronts = <Widget>[
      if (_hasMix)
        _HeroPage(
          onTapBackground: wall.length < 6
              ? null
              : (at, size) {
                  final i = _MixBackground.tileAt(at, size);
                  if (i != null) {
                    widget.onPlayCover(wall, i % wall.length);
                  }
                },
          title: l10n.homeTodayMix,
          subtitle: l10n.homeTodayMixDesc,
          action: _PlayPill(label: l10n.play, onTap: widget.onPlayMix),
          // The pill sits on the subtitle's baseline; the dice is centred.
          actionAtBottom: true,
        ),
      if (_hasArtist)
        _HeroPage(
          title: _artist!,
          subtitle: l10n.homeArtistPick,
          action: _PlayPill(
            label: l10n.play,
            onTap: () => widget.onPlayCover(
              List<Song>.from(_artistSongs)..shuffle(_random),
              0,
            ),
          ),
          actionAtBottom: true,
        ),
      if (_hasWeekly)
        _HeroPage(
          title: l10n.homeWeeklyMix,
          subtitle: l10n.homeWeeklyMixDesc,
          action: _PlayPill(
            label: l10n.play,
            onTap: () => widget.onPlayCover(
              List<Song>.from(_weekly)..shuffle(_random),
              0,
            ),
          ),
          actionAtBottom: true,
        ),
      if (_hasSurprise)
        _HeroPage(
          title: l10n.homeSurpriseMe,
          subtitle: l10n.homeSurpriseMeDesc,
          action: _DiceButton(
            label: l10n.homeSurpriseMe,
            onTap: () {
              widget.onSurprise(_surprise);
              setState(() => _surprise = _pickSurprise());
            },
          ),
        ),
    ];
    // Fresh install / nothing loaded yet: a still card keeps the hero's
    // full height and look instead of collapsing to the top bar.
    if (fronts.isEmpty) {
      backgrounds.add(const _MixBackground(songs: []));
      fronts.add(
        _HeroPage(
          title: l10n.homeTodayMix,
          subtitle: l10n.homeHeroEmptyDesc,
          action: const SizedBox.shrink(),
        ),
      );
    }

    // Off screen, its tickers stop (the carousel's swipe animation too).
    return PauseWhenOffscreen(
      child: SizedBox(
        height: top + _heroBelowStatusBar,
        child: Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.none,
          children: [
            if (backgrounds.isNotEmpty)
              ValueListenableBuilder<double>(
                valueListenable: widget.stretch ?? _noStretch,
                builder: (context, pull, artwork) => Positioned(
                  top: -pull,
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: artwork!,
                ),
                // One fade for all artwork: it melts into the page below.
                // Stops 2px short of the edge: on the device renderer the
                // masked artwork otherwise leaks a 1px line there.
                child: ClipRect(
                  clipper: const _InsetBottomClipper(2),
                  child: ShaderMask(
                    blendMode: BlendMode.dstIn,
                    shaderCallback: (r) => const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      // Fully clear a little before the edge, so nothing draws a
                      // line where the hero meets the next section.
                      stops: [0, 0.45, 0.7, 0.86, 0.95],
                      colors: [
                        Colors.white,
                        Color(0xE6FFFFFF),
                        Color(0x80FFFFFF),
                        Color(0x1FFFFFFF),
                        Color(0x00FFFFFF),
                      ],
                    ).createShader(r),
                    child: AnimatedBuilder(
                      animation: _pages,
                      builder: (context, _) {
                        final page = _page;
                        final width = MediaQuery.sizeOf(context).width;
                        // Swiping: the leaving artwork blurs out as it drifts away
                        // and the arriving one comes in blurred and sharpens, so
                        // two pictures never meet at a hard edge.
                        return Stack(
                          fit: StackFit.expand,
                          children: [
                            for (var i = 0; i < backgrounds.length; i++)
                              _blurSlide(
                                _loopDistance(
                                  page,
                                  i,
                                  backgrounds.length,
                                ).clamp(-1.0, 1.0),
                                width,
                                backgrounds[i],
                                maxBlur: 26,
                                drift: 0.18,
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            if (fronts.isNotEmpty)
              NotificationListener<ScrollStartNotification>(
                onNotification: (n) {
                  if (n.dragDetails != null) _restartAuto();
                  return false;
                },
                child: PageView.builder(
                  controller: _pages,
                  onPageChanged: (index) {
                    final weekly = (_hasMix ? 1 : 0) + (_hasArtist ? 1 : 0);
                    if (_hasWeekly &&
                        fronts.length > 1 &&
                        index % fronts.length == weekly) {
                      setState(() => _weeklyTurn++);
                    }
                  },
                  // One card: no loop, nothing to swipe to.
                  itemCount: fronts.length < 2 ? 1 : null,
                  itemBuilder: (context, index) {
                    final i = fronts.length < 2 ? 0 : index % fronts.length;
                    return AnimatedBuilder(
                      animation: _pages,
                      child: fronts[i],
                      builder: (context, child) {
                        final d = fronts.length < 2
                            ? 0.0
                            : (_page - index).clamp(-1.0, 1.0);
                        // Text blurs and fades with its card (it already slides).
                        return ImageFiltered(
                          enabled: d.abs() > 0.002,
                          imageFilter: ui.ImageFilter.blur(
                            sigmaX: d.abs() * 12,
                            sigmaY: d.abs() * 12,
                          ),
                          child: Opacity(
                            opacity: (1 - d.abs() * 1.3).clamp(0.0, 1.0),
                            child: child,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// One hero artwork at distance [d] (-1…1) from the settled page: fades,
/// blurs up to [maxBlur], drifts sideways by [drift] of the width and grows
/// a touch. The widget tree never changes shape, so images stay loaded.
Widget _blurSlide(
  double d,
  double width,
  Widget child, {
  required double maxBlur,
  required double drift,
}) {
  final a = d.abs();
  return Opacity(
    opacity: (1 - a).clamp(0.0, 1.0),
    child: Transform.translate(
      offset: Offset(-d * width * drift, 0),
      child: Transform.scale(
        scale: 1 + 0.06 * a,
        child: ImageFiltered(
          enabled: a > 0.002,
          imageFilter: ui.ImageFilter.blur(
            sigmaX: a * maxBlur,
            sigmaY: a * maxBlur,
          ),
          child: RepaintBoundary(child: child),
        ),
      ),
    ),
  );
}

/// The Surprise Me! dice: presses in under the finger, then rolls a full
/// turn with a little overshoot as the next cover fades in.
class _DiceButton extends StatefulWidget {
  const _DiceButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  State<_DiceButton> createState() => _DiceButtonState();
}

class _DiceButtonState extends State<_DiceButton>
    with TickerProviderStateMixin {
  late final _roll = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 750),
  );
  late final _press = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 120),
    reverseDuration: const Duration(milliseconds: 260),
  );
  late final _turn = CurvedAnimation(parent: _roll, curve: Curves.easeOutBack);
  late final _hop = TweenSequence([
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.18), weight: 35),
    TweenSequenceItem(
      tween: Tween(
        begin: 1.18,
        end: 1.0,
      ).chain(CurveTween(curve: Curves.easeOutBack)),
      weight: 65,
    ),
  ]).animate(_roll);
  late final _squeeze = Tween(
    begin: 1.0,
    end: 0.9,
  ).animate(CurvedAnimation(parent: _press, curve: Curves.easeOut));

  @override
  void dispose() {
    _turn.dispose();
    _roll.dispose();
    _press.dispose();
    super.dispose();
  }

  void _tap() {
    AppHaptics.medium();
    if (!Motion.reducedOf(context)) _roll.forward(from: 0);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.label,
      child: GestureDetector(
        onTapDown: (_) => _press.forward(),
        onTapUp: (_) => _press.reverse(),
        onTapCancel: _press.reverse,
        onTap: _tap,
        child: ScaleTransition(
          scale: _squeeze,
          child: Container(
            width: 49,
            height: 49,
            decoration: const BoxDecoration(
              color: kHomeHeroButton,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color(0x40000000),
                  blurRadius: 16,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: ScaleTransition(
              scale: _hop,
              child: RotationTransition(
                turns: _turn,
                child: HomeIcons.dice(width: 20),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

const ValueListenable<double> _noStretch = AlwaysStoppedAnimation(0);

/// Home's logo, search and profile buttons, pinned at the top over a blur
/// that fades out downwards (and the soft shade that keeps them readable).
class HomeTopBar extends StatelessWidget {
  const HomeTopBar({
    super.key,
    required this.onSearch,
    required this.onProfile,
    this.blur = true,
    this.scrolled,
  });

  final VoidCallback onSearch;
  final VoidCallback onProfile;

  /// How far the page is scrolled: over the first [_tuckDistance] px the
  /// buttons move up [_tuckShift] px and the blur fades in (none at the top), drawn towards the
  /// status bar, so the page blurs more the closer it gets to the top edge.
  final ValueListenable<double>? scrolled;
  static const _tuckDistance = 120.0;
  static const _tuckShift = 20.0;

  /// False (blur off for sheets and headers): a deeper black fade instead,
  /// darkening in as the page scrolls under the bar.
  final bool blur;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final row = _HeaderRow(onSearch: onSearch, onProfile: onProfile);
    return ValueListenableBuilder<double>(
      valueListenable: scrolled ?? _noStretch,
      child: row,
      builder: (context, offset, row) {
        final t = Curves.easeOut.transform(
          (offset / _tuckDistance).clamp(0.0, 1.0),
        );
        final rowTop = top + 16 - _tuckShift * t;
        // Scrolled: the blur ends just under the buttons, strongest at the
        // status bar.
        final height = ui.lerpDouble(top + 110, rowTop + 42 + 22, t)!;
        return SizedBox(
          height: height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              IgnorePointer(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Thin bands, each blurring a little more than the one
                    // below: the page blurs more the closer it gets to the
                    // status bar, with no visible steps.
                    // None at the very top, over the hero: it fades in as
                    // the page scrolls under the bar.
                    if (blur && t > 0)
                      BackdropGroup(
                        child: Column(
                          children: [
                            for (var i = 0; i < _bands; i++)
                              _blurBand(
                                i,
                                _bandEdge(i + 1, height, dpr) -
                                    _bandEdge(i, height, dpr),
                                t,
                              ),
                          ],
                        ),
                      ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: blur
                            ? LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Color.lerp(
                                    const Color(0x59000000),
                                    const Color(0x80000000),
                                    t,
                                  )!,
                                  const Color(0x00000000),
                                ],
                              )
                            // No blur to hide the page behind the buttons:
                            // near-solid black at the status bar, holding
                            // dark past the buttons before it fades.
                            : LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                stops: const [0, 0.6, 1],
                                colors: [
                                  Color.lerp(
                                    const Color(0x59000000),
                                    const Color(0xF2000000),
                                    t,
                                  )!,
                                  Color.lerp(
                                    const Color(0x26000000),
                                    const Color(0xB3000000),
                                    t,
                                  )!,
                                  const Color(0x00000000),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(top: rowTop, left: 21, right: 22, child: row!),
            ],
          ),
        );
      },
    );
  }

  // A backdrop blur can't be faded with a ShaderMask on the device
  // renderer (it blurs the mask's own empty layer), so the fade is made of
  // bands. Many thin ones keep each step in strength too small to see; as
  // a group they share one read of the page behind.
  static const _bands = 16;
  static const _topSigma = 14.0;

  /// Where band [i] starts, on a whole device pixel: soft clip edges at
  /// fractional positions would show as faint lines between bands.
  static double _bandEdge(int i, double height, double dpr) =>
      (height * dpr * i / _bands).roundToDouble() / dpr;

  static Widget _blurBand(int i, double bandHeight, double t) {
    // 1 at the top band, falling to ~0 at the bottom, eased so most of the
    // blur sits near the status bar; all of it scales in with the scroll.
    final f = math.pow(1 - i / _bands, 1.6).toDouble();
    final sigma = _topSigma * t * f;
    return SizedBox(
      height: bandHeight,
      width: double.infinity,
      child: ClipRect(
        child: BackdropFilter.grouped(
          filter: ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _HeaderRow extends ConsumerWidget {
  const _HeaderRow({required this.onSearch, required this.onProfile});

  final VoidCallback onSearch;
  final VoidCallback onProfile;

  static const _fill = Color(0x33000000); // black 20%

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final avatar = ref.watch(
      settingsProvider.select((s) => s.selectedAvatarAsset),
    );
    return Row(
      children: [
        // The design's round ▶▶ button, or the avatar picked in Settings.
        if (avatar == defaultAvatarAsset)
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: _fill,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Semantics(label: 'Looper', child: HomeIcons.logo()),
          )
        else
          const SizedBox(
            height: 42,
            child: Center(child: SelectedAvatar(size: 38, maxWidth: 130)),
          ),
        const Spacer(),
        HomeRoundButton(
          size: 42,
          color: _fill,
          semanticLabel: l10n.search,
          onTap: onSearch,
          child: HomeIcons.search(),
        ),
        const SizedBox(width: 6),
        HomeRoundButton(
          size: 42,
          color: _fill,
          semanticLabel: l10n.account,
          onTap: onProfile,
          child: HomeIcons.profile(),
        ),
      ],
    );
  }
}

class _HeroPage extends StatelessWidget {
  const _HeroPage({
    this.onTapBackground,
    required this.title,
    required this.subtitle,
    required this.action,
    this.actionAtBottom = false,
  });

  final String title;
  final String subtitle;
  final Widget action;
  final bool actionAtBottom;

  /// A tap on the artwork (not on the text or buttons), with where it
  /// landed in the hero and the hero's size.
  final void Function(Offset at, Size size)? onTapBackground;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (onTapBackground != null)
          LayoutBuilder(
            builder: (context, c) => GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTapUp: (e) => onTapBackground!(e.localPosition, c.biggest),
            ),
          ),
        Positioned(
          left: 25,
          right: 17,
          bottom: 405 - 359,
          child: Row(
            crossAxisAlignment: actionAtBottom
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: homeDisplay(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 230),
                      child: Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: homeDisplay(
                          color: kHomeGrey,
                          fontSize: 15,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              action,
            ],
          ),
        ),
      ],
    );
  }
}

class _PlayPill extends StatelessWidget {
  const _PlayPill({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: kHomeHeroButton,
    shape: const StadiumBorder(),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Container(
        height: 49,
        constraints: const BoxConstraints(minWidth: 114),
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            HomeIcons.play(),
            const SizedBox(width: 10),
            Text(
              label,
              style: homeDisplay(
                color: kHomeHeroButtonInk,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// One song's cover, sharp, its lower part fading out (Surprise Me!).
class _CoverBackground extends StatelessWidget {
  const _CoverBackground({super.key, this.imagePath, this.imageUrl});

  final String? imagePath;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final side = c.maxWidth * 442 / 402;
        return ShaderMask(
          blendMode: BlendMode.dstIn,
          shaderCallback: (r) => const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.49, 1],
            colors: [Colors.white, Color(0x00FFFFFF)],
          ).createShader(r),
          child: OverflowBox(
            alignment: Alignment.topCenter,
            maxWidth: side,
            maxHeight: side,
            child: Transform.translate(
              offset: const Offset(0, -6),
              child: OptimizedImage(
                imagePath: imagePath,
                imageUrl: imageUrl,
                width: side,
                height: side,
                fit: BoxFit.cover,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Today Mix: a wall of covers tilted 30°, dimmed by a grey wash at the top;
/// with fewer than 6 covers, the first one blurred instead.
class _MixBackground extends StatelessWidget {
  const _MixBackground({required this.songs});

  final List<Song> songs;

  static const double _tile = 81, _pitch = 92;
  static const int _cols = 7, _rows = 8, tiles = _cols * _rows;

  /// Which tile (index into the wall) is under [at] in a hero of [size], or
  /// null in a gap. Undoes the wall's 30° tilt around the hero's centre.
  static int? tileAt(Offset at, Size size) {
    final v = at - size.center(Offset.zero);
    const c = 0.8660254037844386, s = 0.5; // cos 30°, sin 30°
    const w = _cols * _tile + (_cols - 1) * (_pitch - _tile);
    const h = _rows * _tile + (_rows - 1) * (_pitch - _tile);
    final x = v.dx * c - v.dy * s + w / 2;
    final y = v.dx * s + v.dy * c + h / 2;
    if (x < 0 || y < 0 || x >= w || y >= h) return null;
    if (x % _pitch >= _tile || y % _pitch >= _tile) return null;
    return (y ~/ _pitch) * _cols + (x ~/ _pitch);
  }

  @override
  Widget build(BuildContext context) {
    final covers = songs.where((s) => s.artPath != null).toList();
    if (covers.isEmpty) return const ColoredBox(color: Color(0xFF272727));
    if (covers.length < 6) {
      return _BlurredCover(imagePath: covers.first.artPath);
    }
    const tile = _tile, pitch = _pitch, cols = _cols, rows = _rows;
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRect(
          child: OverflowBox(
            maxWidth: cols * pitch,
            maxHeight: rows * pitch,
            child: Transform.rotate(
              angle: -math.pi / 6,
              child: Wrap(
                spacing: pitch - tile,
                runSpacing: pitch - tile,
                children: [
                  for (var i = 0; i < cols * rows; i++)
                    Container(
                      width: tile,
                      height: tile,
                      foregroundDecoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(color: const Color(0x0DFFFFFF)),
                      ),
                      child: OptimizedImage(
                        imagePath: covers[i % covers.length].artPath,
                        width: tile,
                        height: tile,
                        borderRadius: BorderRadius.circular(5),
                        cacheWidth: 180,
                        cacheHeight: 180,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        // The design keeps the wall in the background: dimmed, with a grey
        // wash at the top.
        const ColoredBox(color: Color(0x8C000000)),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x99272727), Color(0x00272727)],
            ),
          ),
        ),
      ],
    );
  }
}

@visibleForTesting
int? debugHeroTileAt(Offset at, Size size) => _MixBackground.tileAt(at, size);

class _InsetBottomClipper extends CustomClipper<Rect> {
  const _InsetBottomClipper(this.inset);
  final double inset;

  @override
  Rect getClip(Size size) =>
      Rect.fromLTRB(0, 0, size.width, size.height - inset);

  @override
  bool shouldReclip(_InsetBottomClipper old) => old.inset != inset;
}

/// One cover, heavily blurred, filling the hero (design 617).
class _BlurredCover extends StatelessWidget {
  const _BlurredCover({required this.imagePath});

  final String? imagePath;

  @override
  Widget build(BuildContext context) => ImageFiltered(
    imageFilter: ui.ImageFilter.blur(sigmaX: 40, sigmaY: 40),
    child: OptimizedImage(
      imagePath: imagePath,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      cacheWidth: 300,
    ),
  );
}
