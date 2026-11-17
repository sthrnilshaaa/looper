part of 'android_home_tab.dart';

/// Home reorder mode: the 5 s hold, the Cancel / Done bar and the compact
/// draggable rows.
extension _HomeReorder on _AndroidHomeTabState {
  static const _cardMargin = EdgeInsets.symmetric(horizontal: 16, vertical: 5);

  /// The 5 s hold that enters reorder mode: a thin ring fills around the
  /// finger, then a drop lands there and ripples spread over Home while the
  /// page swells and settles like a water surface.
  Widget _wrapHold({required Color accent, required Widget child}) {
    return Listener(
      onPointerDown: _onPointerDown,
      onPointerMove: _onPointerMove,
      onPointerUp: _onPointerEnd,
      onPointerCancel: _onPointerEnd,
      // Home's scroll view starts its drag on pointer down, so a scroll
      // start fires on every touch: react to real finger movement instead.
      child: NotificationListener<ScrollUpdateNotification>(
        onNotification: (n) {
          if (n.dragDetails != null && n.scrollDelta != 0) _stopHold();
          return false;
        },
        child: AnimatedBuilder(
          animation: Listenable.merge([_hold, _bloom]),
          child: child,
          builder: (context, child) {
            final hold = _hold.value, bloom = _bloom.value;
            return Stack(
              children: [
                // Always wrapped, so the scroll view is never remounted.
                // Paint only: moving hit tests under a still finger would
                // read as a drag and scroll the page.
                Transform.scale(
                  scale: holdPageScale(hold, bloom),
                  alignment: Alignment.topLeft,
                  origin: _dropAt,
                  transformHitTests: false,
                  child: child,
                ),
                if (hold > 0 || bloom > 0)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: HoldDrop(
                        origin: _dropAt,
                        hold: hold,
                        bloom: bloom,
                        accent: accent,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildReorderBar(AppLocalizations l10n, bool useBlur, Color accent) {
    Widget button(String label, Color bg, VoidCallback onTap) => PremiumSection(
      borderRadius: BorderRadius.circular(32),
      padding: const EdgeInsets.symmetric(horizontal: 18),
      height: 48,
      useExpanded: false,
      useBlur: useBlur,
      forceNoBlur: true,
      backgroundColor: bg,
      onTap: onTap,
      child: Center(
        child: Text(
          label,
          style: AppFonts.jostStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );

    return Padding(
      key: const ValueKey('reorderBar'),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          button(l10n.cancel, Colors.white.withValues(alpha: 0.04), () {
            AppHaptics.light();
            _cancelReorder();
          }),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.reorderHome,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.jostStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  l10n.reorderHomeDragHint,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.jostStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          button(l10n.done, accent, () => _leaveReorder(save: true)),
        ],
      ),
    );
  }

  Widget _buildReorderList({
    required AppLocalizations l10n,
    required Color accent,
    required List<String> visible,
    required List<Song> allQuickPicks,
    required List<Song> dateAddedSongs,
    required List<Song> recentSongs,
    required List<Album> albums,
    required List<Artist> artists,
    required List<String> genres,
    required Map<String, List<Song>> genresMap,
  }) {
    // A row that disappeared while reordering (online turned off) drops out
    // of the draft and keeps its saved slot on Done.
    final rows = _draftOrder.where(visible.contains).toList();

    Widget song(Song s) =>
        SongArtwork(song: s, size: 40, borderRadius: BorderRadius.circular(5));
    Widget image({String? path, String? url, bool round = false}) => ClipRRect(
      borderRadius: BorderRadius.circular(round ? 20 : 8),
      child: OptimizedImage(
        imagePath: path,
        imageUrl: url,
        width: 40,
        height: 40,
        placeholder: Container(color: Colors.white10),
      ),
    );

    List<Widget> thumbs(String id) {
      switch (id) {
        case 'quick_picks':
          return allQuickPicks.take(4).map(song).toList();
        case 'songs':
          return dateAddedSongs.take(4).map(song).toList();
        case 'recent':
          return recentSongs.take(4).map(song).toList();
        case 'genres':
          return genres.take(4).map((g) => song(genresMap[g]!.first)).toList();
        case 'albums':
          return albums.take(4).map((a) => image(path: a.artPath)).toList();
        case 'artists':
          return artists.take(4).map((a) {
            final img = a.artistImageUrl;
            final isUrl = img != null && img.startsWith('http');
            return image(
              url: isUrl ? img : null,
              path: isUrl ? null : (img ?? a.artPath),
              round: true,
            );
          }).toList();
        default:
          return const [];
      }
    }

    return SliverReorderableList(
      itemCount: rows.length,
      onReorderStart: (_) => AppHaptics.medium(),
      onReorderEnd: (_) => AppHaptics.light(),
      onReorder: (from, to) => _moveDraft(rows, from, to),
      proxyDecorator: (child, _, animation) => AnimatedBuilder(
        animation: animation,
        child: child,
        builder: (_, child) {
          final t = Curves.easeOut.transform(animation.value);
          return Transform.scale(
            scale: 1 + 0.03 * t,
            child: Material(
              type: MaterialType.transparency,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Padding(
                      padding: _cardMargin,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: MochyCardRow.radius,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.4 * t),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  child!,
                  Positioned.fill(
                    child: Padding(
                      padding: _cardMargin,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: MochyCardRow.radius,
                          border: Border.all(
                            color: accent.withValues(alpha: t),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      itemBuilder: (context, i) {
        final id = rows[i];
        final info = homeRowInfo(id, l10n);
        return ReorderableDelayedDragStartListener(
          key: ValueKey(id),
          index: i,
          child: Semantics(
            label: info.title,
            hint: l10n.reorderRowA11yHint,
            customSemanticsActions: {
              if (i > 0)
                CustomSemanticsAction(label: l10n.reorderMoveUp): () =>
                    _moveDraft(rows, i, i - 1),
              if (i < rows.length - 1)
                CustomSemanticsAction(label: l10n.reorderMoveDown): () =>
                    _moveDraft(rows, i, i + 2),
            },
            child: _HomeReorderCard(
              title: info.title,
              icon: info.icon,
              thumbs: thumbs(id),
            ),
          ),
        );
      },
    );
  }
}

/// One Home row, collapsed for reorder mode.
class _HomeReorderCard extends StatelessWidget {
  const _HomeReorderCard({
    required this.title,
    required this.icon,
    required this.thumbs,
  });

  final String title;
  final IconData icon;
  final List<Widget> thumbs;

  @override
  Widget build(BuildContext context) {
    return MochyCardRow(
      margin: _HomeReorder._cardMargin,
      icon: icon,
      title: title,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Overlapping thumbs keep the title readable on narrow phones.
          if (thumbs.isNotEmpty)
            SizedBox(
              width: 40 + 26.0 * (thumbs.length - 1),
              height: 40,
              child: Stack(
                children: [
                  for (var i = 0; i < thumbs.length; i++)
                    Positioned(
                      left: 26.0 * i,
                      child: SizedBox.square(dimension: 40, child: thumbs[i]),
                    ),
                ],
              ),
            ),
          const SizedBox(width: 8),
          const Icon(
            LucideIcons.gripVertical,
            color: MochyColors.secondary,
            size: 20,
          ),
        ],
      ),
    );
  }
}
