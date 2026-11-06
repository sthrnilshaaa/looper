import 'package:flutter/material.dart';
import 'package:looper_player/core/services/storage/db_service.dart';
import 'package:looper_player/core/theme/app_fonts.dart';
import 'package:looper_player/features/playlists/presentation/widgets/playlist_artwork.dart';
import 'package:looper_player/ui/android/widgets/premium_section.dart';
import 'package:looper_player/ui/widgets/common/optimized_image.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Pins the collection's back / + row. Once the big title scrolls under it,
/// a small cover and the name slide in between the two buttons.
class CollectionPinnedBar extends SliverPersistentHeaderDelegate {
  CollectionPinnedBar({
    required this.controller,
    required this.titleKey,
    required this.title,
    required this.onBack,
    this.art,
    this.imageUrl,
    this.playlist,
    this.onAdd,
  });

  /// Top padding + button + bottom padding, as on the Songs/Library tabs.
  static const double height = 16 + 48 + 12;

  final ScrollController controller;
  final GlobalKey titleKey;
  final String title;
  final VoidCallback onBack;
  final String? art;
  final String? imageUrl;
  final Playlist? playlist;
  final VoidCallback? onAdd;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => _PinnedBar(delegate: this);

  @override
  bool shouldRebuild(CollectionPinnedBar oldDelegate) => true;
}

class _PinnedBar extends StatefulWidget {
  const _PinnedBar({required this.delegate});

  final CollectionPinnedBar delegate;

  @override
  State<_PinnedBar> createState() => _PinnedBarState();
}

class _PinnedBarState extends State<_PinnedBar> {
  // (bar background 0-1, mini cover + title 0-1)
  final _progress = ValueNotifier<(double, double)>((0, 0));
  // Where the big title's bottom sits in scroll content, measured after a
  // frame where layout and offset agree, so scrolling never lags a frame.
  double? _titleBottom;
  bool _measureScheduled = false;

  ScrollController get _controller => widget.delegate.controller;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
    _scheduleMeasure();
  }

  @override
  void didUpdateWidget(_PinnedBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.delegate.controller != _controller) {
      oldWidget.delegate.controller.removeListener(_onScroll);
      _controller.addListener(_onScroll);
    }
    _scheduleMeasure();
  }

  @override
  void dispose() {
    _controller.removeListener(_onScroll);
    _progress.dispose();
    super.dispose();
  }

  double get _offset => _controller.hasClients ? _controller.offset : 0;

  void _onScroll() {
    _update();
    _scheduleMeasure();
  }

  void _scheduleMeasure() {
    if (_measureScheduled) return;
    _measureScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measureScheduled = false;
      if (!mounted) return;
      final titleBox =
          widget.delegate.titleKey.currentContext?.findRenderObject()
              as RenderBox?;
      final barBox = context.findRenderObject() as RenderBox?;
      if (titleBox == null ||
          barBox == null ||
          !titleBox.attached ||
          !titleBox.hasSize ||
          !barBox.hasSize) {
        return;
      }
      final titleBottom = titleBox
          .localToGlobal(Offset(0, titleBox.size.height))
          .dy;
      final barTop = barBox.localToGlobal(Offset.zero).dy;
      final measured = titleBottom - barTop + _offset;
      // Off-screen slivers can report stale positions; trust only a title
      // that is actually near the viewport.
      if (titleBottom - barTop < -CollectionPinnedBar.height) return;
      if (_titleBottom == null || (measured - _titleBottom!).abs() > 0.5) {
        _titleBottom = measured;
        _update();
      }
    });
  }

  void _update() {
    final offset = _offset;
    final background = (offset / 12).clamp(0.0, 1.0);
    var reveal = 0.0;
    final titleBottom = _titleBottom;
    if (titleBottom != null) {
      // Starts as the title's lower half meets the bar, done 44 px later.
      final start = titleBottom - CollectionPinnedBar.height - 18;
      reveal = ((offset - start) / 44).clamp(0.0, 1.0);
    }
    final next = (background, reveal);
    if (next != _progress.value) _progress.value = next;
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.delegate;
    final surface = Theme.of(context).colorScheme.surface;
    return ValueListenableBuilder<(double, double)>(
      valueListenable: _progress,
      builder: (context, progress, _) {
        final (background, reveal) = progress;
        final t = Curves.easeOutCubic.transform(reveal);
        return DecoratedBox(
          decoration: BoxDecoration(
            color: surface.withValues(alpha: background),
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withValues(alpha: 0.06 * t),
              ),
            ),
          ),
          child: BackdropGroup(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                children: [
                  PremiumSection(
                    useExpanded: false,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(32),
                      bottomLeft: Radius.circular(32),
                      topRight: Radius.circular(10),
                      bottomRight: Radius.circular(10),
                    ),
                    width: 48,
                    height: 48,
                    backgroundColor: Colors.white.withValues(alpha: 0.04),
                    useBlur: true,
                    onTap: d.onBack,
                    child: const Icon(
                      LucideIcons.chevronLeft,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  Expanded(
                    child: IgnorePointer(
                      ignoring: t == 0,
                      child: Opacity(
                        opacity: t,
                        child: Transform.translate(
                          offset: Offset(0, 10 * (1 - t)),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: _MiniTitle(delegate: d, scale: t),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (d.onAdd != null)
                    PremiumSection(
                      useExpanded: false,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(10),
                        bottomLeft: Radius.circular(10),
                        topRight: Radius.circular(32),
                        bottomRight: Radius.circular(32),
                      ),
                      width: 48,
                      height: 48,
                      backgroundColor: Colors.white.withValues(alpha: 0.04),
                      useBlur: true,
                      onTap: d.onAdd,
                      child: const Icon(
                        LucideIcons.plus,
                        color: Colors.white,
                        size: 20,
                      ),
                    )
                  else
                    // Keeps the cover and name centred between the edges.
                    const SizedBox(width: 48),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MiniTitle extends StatelessWidget {
  const _MiniTitle({required this.delegate, required this.scale});

  final CollectionPinnedBar delegate;
  final double scale;

  @override
  Widget build(BuildContext context) {
    const size = 36.0;
    final radius = BorderRadius.circular(8);
    final playlist = delegate.playlist;
    final cover = playlist != null
        ? PlaylistArtwork(
            songPaths: playlist.songPaths,
            coverPath: playlist.coverPath,
            size: size,
            borderRadius: radius,
          )
        : OptimizedImage(
            imagePath: delegate.art,
            imageUrl: delegate.imageUrl,
            width: size,
            height: size,
            borderRadius: radius,
            placeholder: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: radius,
              ),
              child: const Icon(
                LucideIcons.music,
                size: 16,
                color: Colors.grey,
              ),
            ),
          );
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Transform.scale(scale: 0.8 + 0.2 * scale, child: cover),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            delegate.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppFonts.jostStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
