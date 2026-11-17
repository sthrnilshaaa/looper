import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:looper_player/core/theme/app_assets.dart';
import 'package:looper_player/features/settings/presentation/providers/settings_notifier.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'selected_avatar.g.dart';

/// Where every avatar image lives - the one place to change if the folder
/// ever moves, shared by this widget and the avatar-picker sheet.
const String avatarAssetDir = AppAssets.avatarDir;

/// Must match AppSettings.selectedAvatarAsset's default in models.dart -
/// kept as a plain literal in both places rather than a shared import,
/// since a domain model importing a UI widget file would be a worse
/// trade-off than duplicating one stable filename.
const String defaultAvatarAsset = 'looper_mark.svg';

/// Hex of the default avatar's built-in accent (looper_player_logo.svg's
/// leaf shape) - swapped for the live theme color the same way the plain
/// white fill every other avatar uses is (see _whiteFillPattern below).
const String _avatarAccentHex = 'C0E200';

/// Matches a `fill="white"` (or `#fff`/`#ffffff`, either quote style, any
/// case) attribute - every non-default avatar (buds/car/cat/rabit) is drawn
/// entirely in this one fill color, with `fill="none"` used for the
/// transparent/negative-space paths that must stay untouched. Swapping it
/// for the live accent is what makes dynamic theming apply to those too,
/// not just the default avatar's built-in accent color.
final RegExp _whiteFillPattern = RegExp(
  '''fill=(["'])\\s*(?:white|#fff|#ffffff)\\s*\\1''',
  caseSensitive: false,
);

/// Image types an avatar can be besides SVG. These are drawn as-is: only
/// SVG avatars can be recolored to the theme accent.
const List<String> _rasterAvatarExtensions = ['.png', '.jpg', '.jpeg', '.webp'];

bool _isRasterAvatar(String fileName) {
  final lower = fileName.toLowerCase();
  return _rasterAvatarExtensions.any(lower.endsWith);
}

bool _isAvatarFile(String fileName) =>
    fileName.toLowerCase().endsWith('.svg') || _isRasterAvatar(fileName);

/// Every avatar image (SVG, PNG, JPG or WebP) currently bundled under
/// [avatarAssetDir] (filenames only), discovered from Flutter's asset
/// manifest instead of a hardcoded list - adding or removing a file from
/// that folder (pubspec.yaml already bundles the whole avatars/ folder)
/// just needs a rebuild, nothing here. Default avatar always sorts first.
@Riverpod(keepAlive: true)
Future<List<String>> avatarAssets(Ref ref) async {
  final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
  final files = manifest
      .listAssets()
      .where((path) => path.startsWith(avatarAssetDir) && _isAvatarFile(path))
      .map((path) => path.substring(avatarAssetDir.length))
      .toList();
  files.sort((a, b) {
    if (a == defaultAvatarAsset) return -1;
    if (b == defaultAvatarAsset) return 1;
    return a.compareTo(b);
  });
  return files;
}

/// Width / height of an SVG, from its root viewBox (or width/height
/// attributes), or 1 when neither can be read.
double svgAspectRatio(String svg) {
  final int end = svg.indexOf('>', svg.indexOf('<svg'));
  final String root = end < 0 ? svg : svg.substring(0, end);
  final viewBox = RegExp(
    r'''viewBox=["']\s*[-\d.eE]+[\s,]+[-\d.eE]+[\s,]+([\d.eE]+)[\s,]+([\d.eE]+)''',
  ).firstMatch(root);
  double? w = double.tryParse(viewBox?.group(1) ?? '');
  double? h = double.tryParse(viewBox?.group(2) ?? '');
  if (w == null || h == null) {
    w = double.tryParse(
      RegExp(r'''\swidth=["']([\d.]+)''').firstMatch(root)?.group(1) ?? '',
    );
    h = double.tryParse(
      RegExp(r'''\sheight=["']([\d.]+)''').firstMatch(root)?.group(1) ?? '',
    );
  }
  if (w == null || h == null || w <= 0 || h <= 0) return 1;
  return w / h;
}

/// Renders one avatar SVG by filename, optionally recolored to [accent].
/// Used both for the Home-screen avatar (via [SelectedAvatar]) and for each
/// option in the avatar-picker sheet's preview grid.
///
/// Stateful so the raw SVG text is only (re)loaded when [assetFileName]
/// changes - [accent] can change far more often (e.g. dynamic theming
/// reacting to every new song), and recoloring already-loaded text is a
/// cheap synchronous string replace, not worth a fresh asset load + the
/// FutureBuilder "waiting" flash that would come with it.
///
/// Square avatars draw at [size] x [size]. A wide one (a logo with a
/// wordmark, say) keeps its own proportions: [size] tall and as wide as it
/// needs, up to [maxWidth] - past that it shrinks to fit the width. With
/// [maxWidth] left at [size] it's fitted inside the square, as before.
class AvatarIcon extends StatefulWidget {
  const AvatarIcon({
    super.key,
    required this.assetFileName,
    this.accent,
    this.size = 40,
    this.maxWidth,
  });

  final String assetFileName;
  final Color? accent;
  final double size;
  final double? maxWidth;

  @override
  State<AvatarIcon> createState() => _AvatarIconState();
}

class _AvatarIconState extends State<AvatarIcon> {
  String? _svg;
  double _aspect = 1;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant AvatarIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.assetFileName != widget.assetFileName) _load();
  }

  Future<void> _load() async {
    // Raster avatars are drawn straight from the asset, no text to load.
    if (_isRasterAvatar(widget.assetFileName)) return;
    // rootBundle.loadString caches by key, so switching back to a
    // previously-picked avatar doesn't re-hit the asset bundle.
    final svg = await rootBundle.loadString(
      '$avatarAssetDir${widget.assetFileName}',
    );
    if (mounted) {
      setState(() {
        _svg = svg;
        _aspect = svgAspectRatio(svg);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isRasterAvatar(widget.assetFileName)) {
      // Full-color images keep their own colors (accent doesn't apply).
      // Only the height is set, so the image takes its own proportions;
      // the max width then shrinks a wide one to fit, keeping its shape.
      final int cacheHeight =
          (widget.size * (MediaQuery.maybeDevicePixelRatioOf(context) ?? 3))
              .ceil();
      return ConstrainedBox(
        constraints: BoxConstraints(maxWidth: widget.maxWidth ?? widget.size),
        child: Image.asset(
          '$avatarAssetDir${widget.assetFileName}',
          height: widget.size,
          fit: BoxFit.contain,
          cacheHeight: cacheHeight,
          filterQuality: FilterQuality.medium,
        ),
      );
    }
    final Size box = _box();
    final svg = _svg;
    if (svg == null) return SizedBox.fromSize(size: box);
    final resolved = widget.accent == null
        ? svg
        : _recolored(svg, widget.accent!);
    return SvgPicture.string(resolved, width: box.width, height: box.height);
  }

  /// The drawing box: square avatars stay [size] x [size]; wider ones get
  /// their natural width at [size] tall, capped at maxWidth.
  Size _box() {
    final double size = widget.size;
    if (_aspect <= 1) return Size.square(size);
    final double width = math.min(size * _aspect, widget.maxWidth ?? size);
    return Size(width, width / _aspect);
  }

  String _recolored(String svg, Color accent) {
    final hex = '#${_toHex(accent)}';
    return svg
        .replaceAll(RegExp('#$_avatarAccentHex', caseSensitive: false), hex)
        .replaceAllMapped(_whiteFillPattern, (m) => 'fill=${m[1]}$hex${m[1]}');
  }

  // Color exposes 0.0-1.0 float channels now, not the old 0-255 ints -
  // toARGB32() is the supported way back to a packed int for hex output.
  String _toHex(Color color) => color
      .toARGB32()
      .toRadixString(16)
      .padLeft(8, '0')
      .substring(2)
      .toUpperCase();
}

/// Renders the user's selected Home-screen avatar (AppSettings.
/// selectedAvatarAsset), swapping its accent color for the live theme color
/// when avatarDynamicColor is on.
class SelectedAvatar extends ConsumerWidget {
  const SelectedAvatar({super.key, this.size = 40, this.maxWidth});

  final double size;

  /// How wide a wide (logo-style) avatar may grow, see [AvatarIcon].
  final double? maxWidth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (assetFileName, dynamicColor) = ref.watch(
      settingsProvider.select(
        (s) => (s.selectedAvatarAsset, s.avatarDynamicColor),
      ),
    );
    final accent = dynamicColor ? Theme.of(context).colorScheme.primary : null;
    return AvatarIcon(
      assetFileName: assetFileName,
      accent: accent,
      size: size,
      maxWidth: maxWidth,
    );
  }
}
