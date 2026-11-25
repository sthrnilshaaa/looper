part of 'android_library_tab.dart';

/// A shortcut that can be pinned to the top of Library.
class _Pin {
  final String key;
  final String title;
  final Widget leading;
  final void Function(BuildContext context, WidgetRef ref) open;

  const _Pin(this.key, this.title, this.leading, this.open);
}

Widget _pinIcon(IconData icon) => SizedBox(
  width: 40,
  height: 40,
  child: Icon(icon, color: Colors.white.withValues(alpha: 0.9), size: 20),
);

/// Every shortcut that can be pinned, keyed like
/// [AppSettings.libraryPins]: Favorites, then each playlist.
Map<String, _Pin> _pinCandidates(WidgetRef ref, AppLocalizations l10n) {
  void go(WidgetRef ref, NavItem item) {
    AppHaptics.light();
    ref.read(appNavigationProvider.notifier).setItem(item);
  }

  return {
    'favorites': _Pin(
      'favorites',
      l10n.favorites,
      _pinIcon(Icons.bookmark_rounded),
      (_, ref) => go(ref, NavItem.favorites),
    ),
    for (final p in ref.watch(libraryProvider.select((s) => s.playlists)))
      'playlist:${p.id}': _Pin(
        'playlist:${p.id}',
        p.name,
        PlaylistArtwork(
          songPaths: p.songPaths,
          coverPath: p.coverPath,
          size: 40,
          borderRadius: BorderRadius.circular(8),
        ),
        (context, ref) {
          AppHaptics.light();
          openPlaylist(context, ref, p);
        },
      ),
  };
}

/// The pinned shortcuts, in the user's order, at the top of Library.
class _PinnedPanel extends ConsumerWidget {
  const _PinnedPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final candidates = _pinCandidates(ref, l10n);
    final pins = [
      for (final key in ref.watch(
        settingsProvider.select((s) => s.libraryPins),
      ))
        ?candidates[key],
    ];
    if (pins.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: _Panel(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            for (final pin in pins)
              InkWell(
                onTap: () => pin.open(context, ref),
                onLongPress: () => _showCustomizeLibrary(context),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      pin.leading,
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          pin.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppFonts.jostStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Icon(
                        LucideIcons.pin,
                        color: Colors.white.withValues(alpha: 0.35),
                        size: 14,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

void _showCustomizeLibrary(BuildContext context) {
  AppHaptics.light();
  showModalBottomSheet(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF141414),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => const _CustomizeLibrarySheet(),
  );
}

/// Pin or unpin every shortcut, and drag the pinned ones into order.
class _CustomizeLibrarySheet extends ConsumerWidget {
  const _CustomizeLibrarySheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final notifier = ref.read(settingsProvider.notifier);
    final candidates = _pinCandidates(ref, l10n);
    final pins = [
      for (final key in ref.watch(
        settingsProvider.select((s) => s.libraryPins),
      ))
        if (candidates.containsKey(key)) key,
    ];
    final unpinned = [
      for (final key in candidates.keys)
        if (!pins.contains(key)) key,
    ];

    Widget row(String key, {required bool pinned, int? index}) {
      final pin = candidates[key]!;
      return ListTile(
        key: ValueKey(key),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20),
        leading: pin.leading,
        title: Text(
          pin.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppFonts.jostStyle(color: Colors.white, fontSize: 15),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: pinned ? l10n.unpinFromLibrary : l10n.pinToLibrary,
              icon: Icon(
                pinned ? LucideIcons.pinOff : LucideIcons.pin,
                size: 18,
                color: pinned ? Colors.white : Colors.white54,
              ),
              onPressed: () {
                AppHaptics.selection();
                notifier.toggleLibraryPin(key);
              },
            ),
            if (index != null)
              ReorderableDragStartListener(
                index: index,
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(
                    LucideIcons.gripVertical,
                    size: 18,
                    color: Colors.white38,
                  ),
                ),
              ),
          ],
        ),
      );
    }

    Widget header(String text) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Text(
        text.toUpperCase(),
        style: AppFonts.jostStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.5,
          color: Colors.white38,
        ),
      ),
    );

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.92,
      builder: (context, controller) => CustomScrollView(
        controller: controller,
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
              child: Text(
                l10n.customizeLibrary,
                style: AppFonts.jostStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                l10n.customizeLibraryDesc,
                style: AppFonts.jostStyle(color: Colors.white54, fontSize: 13),
              ),
            ),
          ),
          if (pins.isNotEmpty) ...[
            SliverToBoxAdapter(child: header(l10n.pinned)),
            SliverReorderableList(
              itemCount: pins.length,
              itemBuilder: (context, i) => Material(
                key: ValueKey(pins[i]),
                color: Colors.transparent,
                child: row(pins[i], pinned: true, index: i),
              ),
              onReorder: (from, to) {
                final next = List<String>.from(pins);
                if (to > from) to--;
                next.insert(to, next.removeAt(from));
                notifier.updateLibraryPins(next);
              },
            ),
          ],
          if (unpinned.isNotEmpty) ...[
            SliverToBoxAdapter(child: header(l10n.pinToLibrary)),
            SliverList.list(
              children: [for (final key in unpinned) row(key, pinned: false)],
            ),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}
