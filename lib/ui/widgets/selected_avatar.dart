import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:looper_player/features/settings/presentation/settings_notifier.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'selected_avatar.g.dart';

/// Where every avatar SVG lives - the one place to change if the folder
/// ever moves, shared by this widget and the avatar-picker sheet.
const String avatarAssetDir = 'assets/android_icons/avatars/';

/// Must match AppSettings.selectedAvatarAsset's default in models.dart -
/// kept as a plain literal in both places rather than a shared import,
/// since a domain model importing a UI widget file would be a worse
/// trade-off than duplicating one stable filename.
const String defaultAvatarAsset = 'looper_player_logo.svg';

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

/// Every avatar SVG currently bundled under [avatarAssetDir] (filenames
/// only), discovered from Flutter's asset manifest instead of a hardcoded
/// list - adding or removing a file from that folder (pubspec.yaml already
/// bundles the whole android_icons/ tree) just needs a rebuild, nothing
/// here. Default avatar always sorts first.
@Riverpod(keepAlive: true)
Future<List<String>> avatarAssets(Ref ref) async {
  final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
  final files = manifest
      .listAssets()
      .where((path) => path.startsWith(avatarAssetDir) && path.endsWith('.svg'))
      .map((path) => path.substring(avatarAssetDir.length))
      .toList();
  files.sort((a, b) {
    if (a == defaultAvatarAsset) return -1;
    if (b == defaultAvatarAsset) return 1;
    return a.compareTo(b);
  });
  return files;
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
class AvatarIcon extends StatefulWidget {
  const AvatarIcon({
    super.key,
    required this.assetFileName,
    this.accent,
    this.size = 40,
  });

  final String assetFileName;
  final Color? accent;
  final double size;

  @override
  State<AvatarIcon> createState() => _AvatarIconState();
}

class _AvatarIconState extends State<AvatarIcon> {
  String? _svg;

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
    // rootBundle.loadString caches by key, so switching back to a
    // previously-picked avatar doesn't re-hit the asset bundle.
    final svg = await rootBundle.loadString(
      '$avatarAssetDir${widget.assetFileName}',
    );
    if (mounted) setState(() => _svg = svg);
  }

  @override
  Widget build(BuildContext context) {
    final svg = _svg;
    if (svg == null) return SizedBox(width: widget.size, height: widget.size);
    final resolved = widget.accent == null
        ? svg
        : _recolored(svg, widget.accent!);
    return SvgPicture.string(resolved, width: widget.size, height: widget.size);
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
  const SelectedAvatar({super.key, this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (assetFileName, dynamicColor) = ref.watch(
      settingsProvider.select(
        (s) => (s.selectedAvatarAsset, s.avatarDynamicColor),
      ),
    );
    final accent = dynamicColor ? Theme.of(context).colorScheme.primary : null;
    return AvatarIcon(assetFileName: assetFileName, accent: accent, size: size);
  }
}
