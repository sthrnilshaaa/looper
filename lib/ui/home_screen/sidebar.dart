part of 'home_screen.dart';

class Sidebar extends ConsumerWidget {
  final AppLocalizations l10n;
  const Sidebar({super.key, required this.l10n});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nav = ref.watch(appNavigationProvider);
    final activeItem = nav.activeItem;

    void navigateTo(NavItem item) {
      ref.read(appNavigationProvider.notifier).setItem(item);
      if (Scaffold.of(context).isDrawerOpen) {
        Navigator.of(context).pop();
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight.isFinite
                    ? (constraints.maxHeight - 32).clamp(0.0, double.infinity)
                    : 0.0,
              ), // -32 for padding
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 15, right: 5),
                      child: Row(
                        children: [
                          SizedBox(
                            height: 42,
                            child: SvgPicture.asset(
                              'assets/main_logo_transparent.svg',
                              fit: BoxFit.contain,
                              colorMapper: AccentColorMapper(
                                Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24),
                    _SidebarItem(
                      customIcon: AppIcons.home,
                      label: l10n.home,
                      isSelected: activeItem == NavItem.home,
                      onTap: () => navigateTo(NavItem.home),
                    ),
                    _SidebarItem(
                      customIcon: AppIcons.songs,
                      label: l10n.songs,
                      isSelected: activeItem == NavItem.songs,
                      onTap: () => navigateTo(NavItem.songs),
                    ),
                    if ((ref.watch(albumsProvider).value?.length ?? 0) >= 6)
                      _SidebarItem(
                        icon: LucideIcons.disc,
                        label: l10n.albums,
                        isSelected: activeItem == NavItem.albums,
                        onTap: () => navigateTo(NavItem.albums),
                      ),
                    _SidebarItem(
                      icon: LucideIcons.mic2,
                      label: l10n.artists,
                      isSelected: activeItem == NavItem.artists,
                      onTap: () => navigateTo(NavItem.artists),
                    ),
                    _SidebarItem(
                      customIcon: AppIcons.library,
                      label: l10n.playlists,
                      isSelected: activeItem == NavItem.playlists,
                      onTap: () => navigateTo(NavItem.playlists),
                    ),
                    _SidebarItem(
                      icon: LucideIcons.clock,
                      label: l10n.recentlyPlayed,
                      isSelected: activeItem == NavItem.recentlyPlayed,
                      onTap: () => navigateTo(NavItem.recentlyPlayed),
                    ),
                    _SidebarItem(
                      customIcon: AppIcons.heart,
                      label: l10n.favorites,
                      isSelected: activeItem == NavItem.favorites,
                      onTap: () => navigateTo(NavItem.favorites),
                    ),
                    _SidebarItem(
                      icon: LucideIcons.listOrdered,
                      label: l10n.playQueue,
                      isSelected: activeItem == NavItem.queue,
                      onTap: () => navigateTo(NavItem.queue),
                    ),
                    _SidebarItem(
                      customIcon: AppIcons.settings,
                      label: l10n.settings,
                      isSelected: activeItem == NavItem.settings,
                      onTap: () => navigateTo(NavItem.settings),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 1,
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      color: Colors.white10,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  final VoidCallback onTap;
  final IconData icon;
  final String label;
  final bool isDynamic;

  const _HeaderButton({
    required this.onTap,
    required this.icon,
    required this.label,
    required this.isDynamic,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        height: 55.s,
        padding: EdgeInsets.symmetric(horizontal: 20.s),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          color: const Color.fromARGB(
            255,
            53,
            53,
            53,
          ).withValues(alpha: isDynamic ? 0.3 : 0.1),
          border: Border.all(
            color: Colors.white10.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon == LucideIcons.arrowLeft)
              SvgPicture.asset(
                AppIcons.back,
                width: AppIcons.headerIcon.s,
                height: AppIcons.headerIcon.s,
                colorFilter: const ColorFilter.mode(
                  Colors.white,
                  BlendMode.srcIn,
                ),
              )
            else
              Icon(icon, size: AppIcons.headerIcon.s, color: Colors.white),
            SizedBox(width: 10.s),
            Text(
              label,
              style: AppFonts.jostStyle(
                color: Colors.white,
                fontSize: 14.ts,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData? icon;
  final String? customIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarItem({
    this.icon,
    this.customIcon,
    required this.label,
    required this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final Color selectedColor = colorScheme.primary;
    final Color unselectedColor = Colors.white.withValues(alpha: 0.4);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: const BoxDecoration(color: Colors.transparent),
      child: ListTile(
        leading: customIcon != null
            ? SvgPicture.asset(
                customIcon!,
                width: AppIcons.sidebarIcon.s,
                height: AppIcons.sidebarIcon.s,
                colorFilter: ColorFilter.mode(
                  isSelected ? selectedColor : unselectedColor,
                  BlendMode.srcIn,
                ),
              )
            : Icon(
                icon,
                size: AppIcons.sidebarIcon.s,
                color: isSelected ? selectedColor : unselectedColor,
              ),
        title: Text(
          label,
          style: AppFonts.jostStyle(
            fontSize: 14.ts,
            color: isSelected ? selectedColor : unselectedColor,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        dense: true,
        visualDensity: VisualDensity.compact,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        onTap: onTap,
      ),
    );
  }
}
