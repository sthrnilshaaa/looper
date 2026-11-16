import 'package:looper_player/features/settings/domain/app_defaults.dart';

/// The rows of the desktop home page.
enum DesktopHomeSection {
  quickPicks,
  playlists,
  recentlyPlayed,
  featuredArtists,
  albums,
  genres,
  artists,
}

/// The desktop home page's rows, top to bottom. The order is fixed; the
/// flags are the user's "show on home" settings. Quick picks,
/// featured artists and albums are always candidates (each still hides
/// itself when it has nothing to show).
List<DesktopHomeSection> desktopHomeSections({
  required bool showPlaylists,
  required bool showRecent,
  required bool showGenres,
  required bool showArtists,
}) => [
  DesktopHomeSection.quickPicks,
  if (showPlaylists) DesktopHomeSection.playlists,
  if (showRecent) DesktopHomeSection.recentlyPlayed,
  DesktopHomeSection.featuredArtists,
  DesktopHomeSection.albums,
  if (showGenres) DesktopHomeSection.genres,
  if (showArtists) DesktopHomeSection.artists,
];
