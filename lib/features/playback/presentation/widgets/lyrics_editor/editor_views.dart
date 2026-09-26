part of 'lyrics_editor_bottom_sheet.dart';

extension _LyricsEditorViews on _LyricsEditorBottomSheetState {
  Widget _buildStatusCards(BuildContext context) {
    Widget card(IconData icon, String label, String value) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 16, color: Colors.white38),
              const SizedBox(height: 6),
              Text(
                value,
                style: AppFonts.jostStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: AppFonts.jostStyle(color: Colors.white38, fontSize: 11),
              ),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        card(
          LucideIcons.list,
          context.l10n.lyricsEditorLines,
          '$_usableLineCount',
        ),
        const SizedBox(width: 8),
        card(
          LucideIcons.clock,
          context.l10n.lyricsEditorStamped,
          '$_stampedLineCount',
        ),
        const SizedBox(width: 8),
        card(
          LucideIcons.timer,
          context.l10n.nowLabel,
          _currentTimeController.text,
        ),
      ],
    );
  }

  Widget _buildLyricsTextEditor(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.lyricsTextLabel,
          style: AppFonts.jostStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.lyricsTextHelperDesc,
          style: AppFonts.jostStyle(color: Colors.white38, fontSize: 11),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _lyricsTextController,
          minLines: 4,
          maxLines: 8,
          style: AppFonts.jostStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: l10n.pasteLyricsHint,
            hintStyle: AppFonts.jostStyle(color: Colors.white24, fontSize: 14),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.02),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAdvancedSyncView(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final accentColor = Theme.of(context).colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.advancedSync,
          style: AppFonts.jostStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        _buildPlaybackTools(context),
        const SizedBox(height: 8),
        _buildShiftTools(context),
        const SizedBox(height: 8),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _lines.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final line = _lines[index];
            final selected = index == _selectedLineIndex;
            final timestampText = line.timestamp == null
                ? ''
                : _formatTimestampText(line.timestamp!);
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: selected
                    ? Colors.white.withValues(alpha: 0.04)
                    : Colors.white.withValues(alpha: 0.02),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selected
                      ? accentColor.withValues(alpha: 0.3)
                      : Colors.white.withValues(alpha: 0.05),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        context.l10n.lyricsEditorLineNumber(index + 1),
                        style: AppFonts.jostStyle(
                          color: Colors.white38,
                          fontSize: 11,
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: accentColor,
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () {
                          _selectLine(index);
                          _stampSelectedLine(advance: false);
                        },
                        icon: const Icon(LucideIcons.clock, size: 12),
                        label: Text(
                          l10n.useCurrentTime,
                          style: AppFonts.jostStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    line.text.isEmpty
                        ? context.l10n.lyricsEditorEmptyLine
                        : line.text,
                    style: AppFonts.jostStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    initialValue: timestampText,
                    onTap: () => _selectLine(index),
                    onChanged: (value) => _applyTimestampText(index, value),
                    style: AppFonts.jostStyle(
                      color: Colors.white,
                      fontSize: 13,
                    ),
                    decoration: InputDecoration(
                      labelText: l10n.timestampMmSsHint,
                      labelStyle: AppFonts.jostStyle(
                        color: Colors.white38,
                        fontSize: 12,
                      ),
                      hintText: '00:12.34',
                      hintStyle: AppFonts.jostStyle(
                        color: Colors.white12,
                        fontSize: 13,
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
                          color: accentColor.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildLinePickerList(BuildContext context, {required bool compact}) {
    final accentColor = Theme.of(context).colorScheme.primary;

    return Container(
      constraints: BoxConstraints(maxHeight: compact ? 180 : 250),
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.01),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: ListView.separated(
        controller: _scrollController,
        shrinkWrap: true,
        itemCount: _lines.length,
        separatorBuilder: (_, _) =>
            Divider(height: 1, color: Colors.white.withValues(alpha: 0.04)),
        itemBuilder: (context, index) {
          final line = _lines[index];
          final selected = index == _selectedLineIndex;
          return Material(
            color: selected
                ? Colors.white.withValues(alpha: 0.03)
                : Colors.transparent,
            child: InkWell(
              onTap: () => _selectLine(index),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selected
                            ? accentColor
                            : Colors.white.withValues(alpha: 0.05),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${index + 1}',
                        style: AppFonts.jostStyle(
                          color: selected ? Colors.black : Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            line.text.isEmpty
                                ? context.l10n.lyricsEditorEmptyLine
                                : line.text,
                            maxLines: compact ? 1 : 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppFonts.jostStyle(
                              color: Colors.white,
                              fontWeight: selected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            line.timestamp == null
                                ? context.l10n.lyricsEditorNotStamped
                                : _formatTimestampText(line.timestamp!),
                            style: AppFonts.jostStyle(
                              color: selected ? accentColor : Colors.white38,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildSaveNotice(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(LucideIcons.info, size: 16, color: Colors.white38),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n.lyricsSaveLrcExplain,
              style: AppFonts.jostStyle(
                color: Colors.white38,
                fontSize: 11,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
