import 'package:looper_player/core/providers/navigation_provider.dart';

/// What the desktop shell shows around each page.
class DesktopShellRules {
  /// Pages where adding music is the natural next step.
  static const Set<NavItem> _libraryPages = {
    NavItem.home,
    NavItem.songs,
    NavItem.albums,
    NavItem.artists,
    NavItem.genres,
    NavItem.folders,
  };

  /// Lyrics and Analyze are full-pane views with their own header.
  static bool showTopBar(NavItem item) =>
      item != NavItem.lyrics && item != NavItem.analyze && !isSettings(item);

  /// The pages that make up the one Settings section.
  static bool isSettings(NavItem item) =>
      item == NavItem.settings ||
      item == NavItem.settingsCategory ||
      item == NavItem.account;

  /// With no music yet, every page offers Add Folder. After that it only
  /// appears on the library pages, where it is not in the way.
  static bool showAddFolder(NavItem item, {required bool libraryEmpty}) =>
      libraryEmpty || _libraryPages.contains(item);
}
