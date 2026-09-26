part of 'lyrics_editor_bottom_sheet.dart';

extension _LyricsEditorTools on _LyricsEditorBottomSheetState {
  Widget _buildPlaybackTools(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isPlaying = ref.watch(playbackProvider.select((s) => s.isPlaying));
    final accentColor = Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.playbackAssist,
            style: AppFonts.jostStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white70,
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                ),
                onPressed: () => _seekBy(const Duration(seconds: -2)),
                child: Text(
                  '-2s',
                  style: AppFonts.jostStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
                onPressed: _togglePlayPause,
                icon: Icon(
                  isPlaying ? LucideIcons.pause : LucideIcons.play,
                  size: 14,
                ),
                label: Text(
                  isPlaying ? context.l10n.pause : context.l10n.play,
                  style: AppFonts.jostStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white70,
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                ),
                onPressed: () => _seekBy(const Duration(seconds: 2)),
                child: Text(
                  '+2s',
                  style: AppFonts.jostStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: 90,
                child: TextField(
                  controller: _currentTimeController,
                  readOnly: true,
                  style: AppFonts.jostStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    labelText: l10n.nowLabel,
                    labelStyle: AppFonts.jostStyle(
                      color: Colors.white38,
                      fontSize: 10,
                    ),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.01),
                    isDense: true,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.05),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.05),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShiftTools(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.timeShift,
            style: AppFonts.jostStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.timeShiftDesc,
            style: AppFonts.jostStyle(color: Colors.white38, fontSize: 11),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _shiftButton('-500ms', const Duration(milliseconds: -500)),
                const SizedBox(width: 6),
                _shiftButton('-100ms', const Duration(milliseconds: -100)),
                const SizedBox(width: 6),
                _shiftButton('+100ms', const Duration(milliseconds: 100)),
                const SizedBox(width: 6),
                _shiftButton('+500ms', const Duration(milliseconds: 500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _shiftButton(String label, Duration delta) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white70,
        side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
      onPressed: () {
        HapticFeedback.lightImpact();
        _shiftAll(delta);
      },
      child: Text(
        label,
        style: AppFonts.jostStyle(fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}
