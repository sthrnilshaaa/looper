import 'package:flutter/widgets.dart';
import 'package:looper_player/l10n/app_localizations.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Puts the reordered visible rows back into the full saved order,
/// leaving hidden rows in their slots.
List<String> mergeHomeOrder(List<String> saved, List<String> draft) {
  final visible = draft.toSet();
  final next = draft.iterator;
  return [
    for (final id in saved)
      visible.contains(id) && next.moveNext() ? next.current : id,
  ];
}

/// Adds Quick picks to a saved order missing it (the old Settings sheet
/// dropped it while it was pinned).
List<String> withHomeRowIds(List<String> order) =>
    order.contains('quick_picks') ? [...order] : ['quick_picks', ...order];

/// Title, description and icon of a Home row, shared by Home's reorder mode
/// and the Settings reorder sheet.
({String title, String description, IconData icon}) homeRowInfo(
  String id,
  AppLocalizations l10n,
) => switch (id) {
  'quick_picks' => (
    title: l10n.quickPicks,
    description: l10n.quickPicksRowDesc,
    icon: LucideIcons.sparkles,
  ),
  'playlists' => (
    title: l10n.playlists,
    description: l10n.playlistsRowDesc,
    icon: LucideIcons.listMusic,
  ),
  'songs' => (
    title: l10n.songs,
    description: l10n.recentlyAddedSongsRowDesc,
    icon: LucideIcons.music,
  ),
  'albums' => (
    title: l10n.albums,
    description: l10n.albumsRowDesc,
    icon: LucideIcons.disc,
  ),
  'artists' => (
    title: l10n.artists,
    description: l10n.artistsRowDesc,
    icon: LucideIcons.user,
  ),
  'genres' => (
    title: l10n.genres,
    description: l10n.genresRowDesc,
    icon: LucideIcons.library,
  ),
  'recent' => (
    title: l10n.recentPlayed,
    description: l10n.recentRowDesc,
    icon: LucideIcons.history,
  ),
  _ => (title: id, description: '', icon: LucideIcons.layers),
};

/// Set while Home is in reorder mode; system back calls it to cancel.
VoidCallback? homeReorderCancel;
