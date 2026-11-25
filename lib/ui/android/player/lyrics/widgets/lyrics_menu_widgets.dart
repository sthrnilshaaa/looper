part of 'android_lyrics_menu_sheet.dart';

/// Rounded card grouping related menu rows, with inset hairlines between
/// them (the redesign's card).
class _MenuSection extends StatelessWidget {
  final List<Widget> children;

  const _MenuSection({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF181818),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0)
                Container(
                  height: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              children[i],
            ],
          ],
        ),
      ),
    );
  }
}

/// A title inside a card, above its control.
class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppFonts.jostStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

/// Leading icon of an action row.
class _MenuIcon extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _MenuIcon(this.icon, {this.color = Colors.white});

  @override
  Widget build(BuildContext context) => Icon(icon, color: color, size: 20);
}

class _MenuActionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _MenuActionTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.iconColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            _MenuIcon(icon, color: iconColor),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppFonts.jostStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: AppFonts.jostStyle(
                        color: Colors.white.withValues(alpha: 0.56),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              LucideIcons.chevronRight,
              color: Colors.white.withValues(alpha: 0.5),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuSwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final Color accent;
  final ValueChanged<bool> onChanged;

  const _MenuSwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.accent,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    void toggle(bool val) {
      AppHaptics.light();
      onChanged(val);
    }

    return InkWell(
      onTap: () => toggle(!value),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppFonts.jostStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppFonts.jostStyle(
                      color: Colors.white.withValues(alpha: 0.56),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Switch(value: value, onChanged: toggle),
          ],
        ),
      ),
    );
  }
}

/// "Word synced" / "Line synced" / "Not synced" pill next to the lyrics
/// source.
class _SyncBadge extends StatelessWidget {
  final bool wordSynced;
  final bool synced;
  final Color accent;

  const _SyncBadge({
    required this.wordSynced,
    required this.synced,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _MenuPill(
      icon: wordSynced
          ? LucideIcons.sparkles
          : synced
          ? LucideIcons.alignLeft
          : LucideIcons.timerOff,
      label: wordSynced
          ? l10n.lyricsWordSynced
          : synced
          ? l10n.lyricsLineSynced
          : l10n.lyricsNotSynced,
    );
  }
}

/// A neutral info pill in the menu's header.
class _MenuPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MenuPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppFonts.jostStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Choice chip used by both the highlight-style and provider pickers:
/// white with black text when picked.
class _MenuChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color accent;
  final VoidCallback onSelected;

  const _MenuChip({
    required this.label,
    required this.selected,
    required this.accent,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? Colors.white : Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onSelected,
          child: Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            alignment: Alignment.center,
            child: Text(
              label,
              style: AppFonts.jostStyle(
                color: selected ? Colors.black : Colors.white,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Lyrics timing offset: nudges this song's lyric timing later/earlier in
/// 0.1 s steps. Every song starts at the app default; a change is saved for
/// the song it was made on only.
class _LyricsOffsetControl extends StatelessWidget {
  static const int _step = 100;

  final int offsetMs;
  final Color accent;
  final ValueChanged<int> onChanged;

  const _LyricsOffsetControl({
    required this.offsetMs,
    required this.accent,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Positive = lyrics earlier; the default nudges them a little early.
    const int defaultMs = AppSettings.defaultLyricsOffsetMs;
    final bool isDefault = offsetMs == defaultMs;
    final seconds = (offsetMs / 1000).toStringAsFixed(1);
    final label = offsetMs > 0 ? '+$seconds s' : '$seconds s';

    Widget stepButton(IconData icon, String tooltip, int delta) => Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            AppHaptics.selection();
            onChanged(offsetMs + delta);
          },
          child: SizedBox(
            width: 36,
            height: 36,
            child: Icon(icon, size: 18, color: Colors.white),
          ),
        ),
      ),
    );

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.lyricsTiming,
                style: AppFonts.jostStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                l10n.lyricsTimingDesc,
                style: AppFonts.jostStyle(
                  color: Colors.white.withValues(alpha: 0.56),
                  fontSize: 13,
                ),
              ),
              if (!isDefault)
                GestureDetector(
                  onTap: () {
                    AppHaptics.selection();
                    onChanged(defaultMs);
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      l10n.lyricsTimingReset,
                      style: AppFonts.jostStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                        decorationColor: Colors.white54,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              stepButton(LucideIcons.minus, l10n.lyricsTimingLater, -_step),
              SizedBox(
                width: 62,
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: AppFonts.jostStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              stepButton(LucideIcons.plus, l10n.lyricsTimingEarlier, _step),
            ],
          ),
        ),
      ],
    );
  }
}
