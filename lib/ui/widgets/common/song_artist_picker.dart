import 'package:flutter/material.dart';
import 'package:looper_player/core/utils/l10n.dart';
import 'package:looper_player/core/utils/ui_utils.dart';
import 'package:looper_player/features/library/data/services/artist_catalog.dart';
import 'package:looper_player/features/library/domain/models/models.dart';
import 'package:looper_player/ui/widgets/sheets/app_bottom_sheet.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Which of [song]'s artists to open. A song with one artist returns it
/// straight away; with several, the user picks one (a bottom sheet on
/// Android, a dialog on desktop). Null when the picker is dismissed.
Future<String?> pickSongArtist(BuildContext context, Song song) async {
  final names = await ArtistCatalog.namesForSong(song);
  if (names.length == 1) return names.first;
  if (!context.mounted) return null;

  Widget list(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final name in names)
        ListTile(
          leading: const Icon(LucideIcons.userRound, color: Colors.white70),
          title: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          onTap: () => Navigator.of(context).pop(name),
        ),
    ],
  );

  final title = Text(
    context.l10n.artists,
    style: const TextStyle(
      color: Colors.white,
      fontSize: 18,
      fontWeight: FontWeight.bold,
    ),
  );

  if (UiUtils.isDesktop) {
    return showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        backgroundColor: const Color(0xFF1F1F1F),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: title,
        contentPadding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 320),
            child: list(context),
          ),
        ],
      ),
    );
  }

  return showModalBottomSheet<String>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => AppBottomSheetContainer(
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 8),
              child: title,
            ),
            Flexible(child: SingleChildScrollView(child: list(context))),
          ],
        ),
      ),
    ),
  );
}
