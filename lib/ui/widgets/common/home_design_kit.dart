import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:looper_player/core/theme/app_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Pieces of the Home design (Figma "iPhone 17 - 617…621"), shared by the
/// hero and the local sections.

/// Secondary text on Home: song artists, card subtitles, section labels.
const kHomeGrey = Color(0xFF808080);

/// The pale pill / circle behind the hero's Play and dice buttons.
const kHomeHeroButton = Color(0xFFE9E9E9);
const kHomeHeroButtonInk = Color(0xFF1D1D1D);

// Icons traced from the design file, in their own boxes.
const _logoSvg =
    '<svg viewBox="32.9 74.7 18.2 12.6" xmlns="http://www.w3.org/2000/svg">'
    '<path d="M33 80.9988C33 77.8122 33 76.2189 33.9135 75.5224C34.1596 75.3348 34.4415 75.1946 34.7436 75.1097C35.8651 74.7946 37.2321 75.7083 39.9662 77.5357C42.0776 78.947 43.1334 79.6526 43.3052 80.605C43.3523 80.8656 43.3523 81.132 43.3052 81.3927C43.1334 82.3451 42.0776 83.0507 39.9662 84.462C37.2321 86.2894 35.8651 87.2031 34.7436 86.8879C34.4415 86.803 34.1596 86.6629 33.9135 86.4752C33 85.7787 33 84.1854 33 80.9988Z" fill="white"/>'
    '<path d="M43.7772 75.0103C44.843 74.8848 46.0909 75.9087 48.5868 77.9558C50.0305 79.1399 50.7528 79.7319 50.9347 80.4658C51.0218 80.8171 51.0218 81.1829 50.9347 81.5342C50.7528 82.2681 50.0305 82.8601 48.5868 84.0442C46.0909 86.0914 44.843 87.1152 43.7772 86.9897C43.2785 86.931 42.8111 86.7259 42.4395 86.403C41.9578 85.9844 41.7686 85.242 41.694 84.0216C43.3788 82.7404 44.2218 81.9792 44.2218 81.0014C44.2218 80.0234 43.3791 79.2616 41.694 77.9802C41.7686 76.7588 41.9576 76.0158 42.4395 75.597C42.8111 75.2741 43.2785 75.069 43.7772 75.0103Z" fill="white"/>'
    '</svg>';

const _searchSvg =
    '<svg viewBox="303.3 73.8 15.4 14.4" xmlns="http://www.w3.org/2000/svg">'
    '<path d="M317.461 86.9999L314.691 84.2305" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" stroke="white" fill="none"/>'
    '<path d="M315.617 80.5389C315.617 83.5979 313.137 86.0778 310.078 86.0778C307.019 86.0778 304.539 83.5979 304.539 80.5389C304.539 77.4798 307.019 75 310.078 75C313.137 75 315.617 77.4798 315.617 80.5389Z" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" stroke="white" fill="none"/>'
    '</svg>';

const _profileSvg =
    '<svg viewBox="351.5 73.5 15 15" xmlns="http://www.w3.org/2000/svg">'
    '<path d="M355.667 76.8333C355.667 75.9493 356.018 75.1014 356.643 74.4763C357.268 73.8512 358.116 73.5 359 73.5C359.884 73.5 360.732 73.8512 361.357 74.4763C361.982 75.1014 362.333 75.9493 362.333 76.8333C362.333 77.7174 361.982 78.5652 361.357 79.1904C360.732 79.8155 359.884 80.1667 359 80.1667C358.116 80.1667 357.268 79.8155 356.643 79.1904C356.018 78.5652 355.667 77.7174 355.667 76.8333ZM355.667 81.8333C354.562 81.8333 353.502 82.2723 352.72 83.0537C351.939 83.8351 351.5 84.8949 351.5 86C351.5 86.663 351.763 87.2989 352.232 87.7678C352.701 88.2366 353.337 88.5 354 88.5H364C364.663 88.5 365.299 88.2366 365.768 87.7678C366.237 87.2989 366.5 86.663 366.5 86C366.5 84.8949 366.061 83.8351 365.28 83.0537C364.498 82.2723 363.438 81.8333 362.333 81.8333H355.667Z" fill-rule="evenodd" fill="white"/>'
    '</svg>';

const _playSvg =
    '<svg viewBox="300 327.9 13 14.2" xmlns="http://www.w3.org/2000/svg">'
    '<path d="M301.58 328.178C302.872 327.577 304.537 328.537 307.869 330.459C311.2 332.382 312.865 333.343 312.99 334.762C313.003 334.92 313.003 335.08 312.99 335.238C312.865 336.657 311.2 337.618 307.869 339.541C304.537 341.463 302.872 342.423 301.58 341.822C301.436 341.754 301.298 341.674 301.167 341.583C300 340.766 300 338.844 300 335C300 331.156 300 329.234 301.167 328.417C301.298 328.326 301.436 328.246 301.58 328.178Z" fill="#1D1D1D"/>'
    '</svg>';

const _diceSvg =
    '<svg viewBox="342.9 311.5 18.9 19" xmlns="http://www.w3.org/2000/svg">'
    '<path d="M360.216 314.831L348.626 311.721C348.115 311.583 347.569 311.655 347.11 311.919C346.65 312.183 346.315 312.619 346.176 313.131L343.066 324.721C342.786 325.781 343.416 326.881 344.476 327.171L356.066 330.281C356.236 330.331 356.406 330.351 356.576 330.351C357.456 330.351 358.266 329.761 358.506 328.871L361.616 317.281C361.896 316.221 361.266 315.121 360.206 314.831H360.216ZM351.386 320.751C351.176 321.551 350.346 322.031 349.546 321.811C348.746 321.601 348.276 320.771 348.486 319.971C348.696 319.171 349.526 318.691 350.326 318.911C351.126 319.121 351.596 319.951 351.386 320.751ZM356.216 322.041C356.006 322.841 355.176 323.311 354.376 323.101C353.576 322.891 353.096 322.061 353.316 321.261C353.526 320.461 354.356 319.991 355.156 320.201C355.956 320.411 356.436 321.241 356.216 322.041Z" fill="black"/>'
    '</svg>';

class HomeIcons {
  static Widget logo({double width = 18}) =>
      SvgPicture.string(_logoSvg, width: width);
  static Widget search({double width = 15}) =>
      SvgPicture.string(_searchSvg, width: width);
  static Widget profile({double width = 15}) =>
      SvgPicture.string(_profileSvg, width: width);
  static Widget play({double width = 13}) =>
      SvgPicture.string(_playSvg, width: width);
  static Widget dice({double width = 19}) =>
      SvgPicture.string(_diceSvg, width: width);
}

/// A round button: the 42px 20%-black header buttons over the hero, and the
/// 41px 10%-white play / arrow buttons beside section titles.
class HomeRoundButton extends StatelessWidget {
  const HomeRoundButton({
    super.key,
    required this.child,
    required this.onTap,
    this.size = 41,
    this.color = const Color(0x1AFFFFFF),
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double size;
  final Color color;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: semanticLabel,
    child: Material(
      color: color,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox.square(
          dimension: size,
          child: Center(child: child),
        ),
      ),
    ),
  );
}

/// The "View All →" pill beside section titles: 41px, 10% white.
class HomeViewAllPill extends StatelessWidget {
  const HomeViewAllPill({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0x1AFFFFFF),
    shape: const StadiumBorder(),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Container(
        height: 41,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: homeDisplay(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(LucideIcons.arrowRight, size: 16, color: Colors.white),
          ],
        ),
      ),
    ),
  );
}

/// Card and row text in the design: DM Sans at its regular weight, white
/// titles over grey subtitles, whatever app font is picked.
TextStyle homeCardTitle({double size = 16}) => AppFonts.familyStyle(
  AppFonts.dmSans,
  weightDelta: 0,
  color: Colors.white,
  fontSize: size,
  letterSpacing: 0,
);

TextStyle homeCardSub({double size = 14}) => AppFonts.familyStyle(
  AppFonts.dmSans,
  weightDelta: 0,
  color: kHomeGrey,
  fontSize: size,
  letterSpacing: 0,
);

/// Headings, buttons and card titles in the design: Stack Sans, whatever
/// app font is picked (card and row text is DM Sans, [homeCardTitle]).
TextStyle homeDisplay({
  Color? color,
  double? fontSize,
  FontWeight? fontWeight,
  double? height,
}) => AppFonts.familyStyle(
  AppFonts.stackSansText,
  weightDelta: 0,
  color: color,
  fontSize: fontSize,
  fontWeight: fontWeight,
  height: height,
  letterSpacing: AppFonts.spacingFor(fontSize),
);

/// A section title split the design's way: a grey label over a big title.
/// "Mixed for you" -> "Mixed" / "For You"; with [name] (an artist the
/// shelf is about) "More from Drake" -> "More From" / "Drake"; otherwise
/// the first word is the label: "Listen again" -> "Listen" / "Again".
/// One word stays a plain title.
(String?, String) splitShelfTitle(String title, {String? name}) {
  final t = title.trim();
  final n = name?.trim();
  if (n != null && n.isNotEmpty && t.length > n.length) {
    final i = t.toLowerCase().lastIndexOf(n.toLowerCase());
    if (i >= 0) {
      final label = (t.substring(0, i) + t.substring(i + n.length)).trim();
      if (label.isNotEmpty) {
        return (_titleCase(label), t.substring(i, i + n.length));
      }
    }
  }
  final forYou = RegExp(
    r'^(.+?)\s+for you$',
    caseSensitive: false,
  ).firstMatch(t);
  if (forYou != null) return (_titleCase(forYou[1]!), 'For You');
  final words = t.split(RegExp(r'\s+'));
  if (words.length < 2) return (null, t);
  final lead = words.first.toLowerCase() == 'from' && words.length > 2 ? 2 : 1;
  return (
    _titleCase(words.take(lead).join(' ')),
    _titleCase(words.skip(lead).join(' ')),
  );
}

String _titleCase(String s) => s
    .split(' ')
    .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1))
    .join(' ');

/// The small white play glyph in a 41px section button.
const homeSectionPlayIcon = Icon(
  Icons.play_arrow_rounded,
  size: 22,
  color: Colors.white,
);

/// A section title as in the design: a bold title (20px), or a grey
/// [label] over a larger title ("Picks" / "For You"), with [trailing]
/// buttons at the right.
class HomeSectionHeader extends StatelessWidget {
  const HomeSectionHeader({
    super.key,
    required this.title,
    this.label,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(23, 36, 16, 16),
  });

  final String title;
  final String? label;
  final Widget? trailing;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final titleText = Text(
      title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: homeDisplay(
        color: Colors.white,
        fontSize: label == null ? 20 : 28,
        fontWeight: FontWeight.bold,
        // Under a label the two lines sit tight, as in the design.
        height: label == null ? 1.15 : 1.0,
      ),
    );
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: label == null
                ? titleText
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: homeDisplay(
                          color: kHomeGrey,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          height: 1.0,
                        ),
                      ),
                      titleText,
                    ],
                  ),
          ),
          if (trailing != null) ...[const SizedBox(width: 12), trailing!],
        ],
      ),
    );
  }
}

/// ← → buttons that page a horizontal row, as on "Discover New Artists".
class HomeRowArrows extends StatelessWidget {
  const HomeRowArrows({super.key, required this.controller});

  final ScrollController controller;

  void _page(BuildContext context, int dir) {
    if (!controller.hasClients) return;
    final p = controller.position;
    final target = (p.pixels + dir * p.viewportDimension * 0.8).clamp(
      p.minScrollExtent,
      p.maxScrollExtent,
    );
    controller.animateTo(
      target,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final m = MaterialLocalizations.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        HomeRoundButton(
          semanticLabel: m.previousPageTooltip,
          onTap: () => _page(context, -1),
          child: const Icon(
            LucideIcons.arrowLeft,
            size: 18,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 6),
        HomeRoundButton(
          semanticLabel: m.nextPageTooltip,
          onTap: () => _page(context, 1),
          child: const Icon(
            LucideIcons.arrowRight,
            size: 18,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

/// Owns a [ScrollController] for [builder]: lets a stateless row hand the
/// same controller to its list and to its [HomeRowArrows].
class ScrollControllerScope extends StatefulWidget {
  const ScrollControllerScope({super.key, required this.builder});

  final Widget Function(BuildContext context, ScrollController controller)
  builder;

  @override
  State<ScrollControllerScope> createState() => _ScrollControllerScopeState();
}

class _ScrollControllerScopeState extends State<ScrollControllerScope> {
  final _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _controller);
}
