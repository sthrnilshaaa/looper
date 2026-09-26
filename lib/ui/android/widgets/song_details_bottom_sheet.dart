import 'package:flutter/material.dart';
import 'package:looper_player/features/library/domain/models/models.dart';
import 'package:intl/intl.dart';
import 'package:looper_player/core/theme/app_fonts.dart';
import 'package:looper_player/l10n/app_localizations.dart';

class SongDetailsBottomSheet extends StatelessWidget {
  final Song song;

  const SongDetailsBottomSheet({super.key, required this.song});

  String _formatDuration(AppLocalizations l10n, int? ms) {
    if (ms == null) return l10n.unknown;
    final d = Duration(milliseconds: ms);
    final minutes = d.inMinutes;
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.songDetails,
            style: AppFonts.jostStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          _detailItem(l10n.title, song.title),
          _detailItem(l10n.artist, song.artist ?? l10n.unknown),
          _detailItem(l10n.album, song.album ?? l10n.unknown),
          _detailItem(l10n.duration, _formatDuration(l10n, song.duration)),
          _detailItem(l10n.playCount, l10n.playCountTimes(song.playCount)),
          if (song.lastPlayed != null)
            _detailItem(
              l10n.lastPlayed,
              DateFormat.yMMMd(
                Localizations.localeOf(context).toString(),
              ).add_Hm().format(song.lastPlayed!),
            ),
          _detailItem(l10n.filePath, song.path),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.close),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _detailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppFonts.jostStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppFonts.jostStyle(color: Colors.white, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
