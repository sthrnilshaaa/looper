part of 'desktop_welcome_screen.dart';

/// Dark base with two soft accent glows, like the Android welcome screen.
class _WelcomeBackdrop extends StatelessWidget {
  final Color accent;
  const _WelcomeBackdrop({required this.accent});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: Color(0xFF0E0E10)),
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.85, -1.0),
                  radius: 1.1,
                  colors: [accent.withValues(alpha: 0.16), Colors.transparent],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(-0.9, 1.1),
                  radius: 1.0,
                  colors: [accent.withValues(alpha: 0.09), Colors.transparent],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Logo, app name and tagline, centred.
class _BrandHeader extends StatelessWidget {
  final Color accent;
  final bool large;
  const _BrandHeader({required this.accent, required this.large});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // The logo already spells out the app name, so no title under it.
        SizedBox(
          height: large ? 120 : 92,
          width: large ? 240 : 184,
          child: SvgPicture.asset(
            AppAssets.logo,
            fit: BoxFit.contain,
            placeholderBuilder: (_) =>
                Icon(LucideIcons.music, size: 44, color: accent),
          ),
        ),
        SizedBox(height: large ? 18 : 14),
        Text(
          l10n.desktopWelcomeTagline,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: large ? 17 : 15,
            fontWeight: FontWeight.w300,
            letterSpacing: 0.3,
            color: Colors.white.withValues(alpha: 0.65),
          ),
        ),
      ],
    );
  }
}

/// The frosted card both halves of the layout sit in.
class _Panel extends StatelessWidget {
  final Widget child;
  const _Panel({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.035),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: child,
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final Color accent;
  const _SectionLabel(this.text, {required this.accent});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 2,
        color: accent,
      ),
    );
  }
}

/// Where the library comes from: the detected Music folder plus the scan
/// and choose-folder buttons.
class _SetupPanel extends StatelessWidget {
  final Color accent;
  final String? musicFolder;
  final bool musicFolderExists;
  final VoidCallback? onScanMusicFolder;
  final VoidCallback onChooseFolder;

  /// True when the panel shares a row with the features panel and should
  /// stretch to its height, pushing the footer to the bottom.
  final bool fillHeight;

  const _SetupPanel({
    required this.accent,
    required this.musicFolder,
    required this.musicFolderExists,
    required this.onScanMusicFolder,
    required this.onChooseFolder,
    required this.fillHeight,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // Without a Music folder, picking one becomes the main action.
    final chooseIsPrimary = musicFolder != null && !musicFolderExists;

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _SectionLabel(l10n.desktopWelcomeGetStarted, accent: accent),
          const SizedBox(height: 10),
          Text(
            l10n.desktopWelcomeSetupTitle,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.desktopWelcomeSetupDesc,
            style: TextStyle(
              fontSize: 13.5,
              height: 1.55,
              color: Colors.white.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 22),
          _FolderCard(
            accent: accent,
            path: musicFolder,
            exists: musicFolderExists,
          ),
          const SizedBox(height: 20),
          if (!chooseIsPrimary) ...[
            _WelcomeButton(
              label: l10n.desktopWelcomeScanMusicFolder,
              icon: LucideIcons.scanSearch,
              accent: accent,
              primary: true,
              autofocus: true,
              onPressed: onScanMusicFolder,
            ),
            const SizedBox(height: 12),
          ],
          _WelcomeButton(
            label: l10n.desktopWelcomeChooseFolder,
            icon: LucideIcons.folderOpen,
            accent: accent,
            primary: chooseIsPrimary,
            autofocus: chooseIsPrimary,
            onPressed: onChooseFolder,
          ),
          if (fillHeight) const Spacer() else const SizedBox(height: 24),
          if (fillHeight) const SizedBox(height: 24),
          Divider(height: 1, color: Colors.white.withValues(alpha: 0.07)),
          const SizedBox(height: 16),
          _FootNote(
            icon: LucideIcons.fileAudio,
            text: l10n.desktopWelcomeFormats,
          ),
          const SizedBox(height: 8),
          _FootNote(
            icon: LucideIcons.folderPlus,
            text: l10n.desktopWelcomeAddLater,
          ),
        ],
      ),
    );
  }
}

/// Shows the detected Music folder and whether it can be scanned.
class _FolderCard extends StatelessWidget {
  final Color accent;
  final String? path;
  final bool exists;
  const _FolderCard({
    required this.accent,
    required this.path,
    required this.exists,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final statusColor = exists ? accent : Colors.amber;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(LucideIcons.folderHeart, size: 20, color: accent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.desktopWelcomeMusicFolder,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  path ?? '…',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.45),
                  ),
                ),
              ],
            ),
          ),
          if (path != null) ...[
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    exists ? LucideIcons.check : LucideIcons.circleAlert,
                    size: 12,
                    color: statusColor,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    exists
                        ? l10n.desktopWelcomeFolderReady
                        : l10n.desktopWelcomeFolderMissing,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FootNote extends StatelessWidget {
  final IconData icon;
  final String text;
  const _FootNote({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final color = Colors.white.withValues(alpha: 0.4);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(icon, size: 14, color: color),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 12, height: 1.4, color: color),
          ),
        ),
      ],
    );
  }
}

/// What the app offers, as a grid of feature tiles.
class _FeaturesPanel extends StatelessWidget {
  final Color accent;
  final bool twoColumns;
  const _FeaturesPanel({required this.accent, required this.twoColumns});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tiles = [
      _FeatureTile(
        accent: accent,
        icon: LucideIcons.micVocal,
        title: l10n.desktopWelcomeLyricsTitle,
        description: l10n.desktopWelcomeLyricsDesc,
      ),
      _FeatureTile(
        accent: accent,
        icon: LucideIcons.slidersVertical,
        title: l10n.desktopWelcomeEqTitle,
        description: l10n.desktopWelcomeEqDesc,
      ),
      _FeatureTile(
        accent: accent,
        icon: LucideIcons.libraryBig,
        title: l10n.desktopWelcomeLibraryTitle,
        description: l10n.desktopWelcomeLibraryDesc,
      ),
      _FeatureTile(
        accent: accent,
        icon: LucideIcons.pictureInPicture2,
        title: l10n.desktopWelcomeFloatingTitle,
        description: l10n.desktopWelcomeFloatingDesc,
      ),
      _FeatureTile(
        accent: accent,
        icon: LucideIcons.chartColumnBig,
        title: l10n.desktopWelcomeInsightsTitle,
        description: l10n.desktopWelcomeInsightsDesc,
      ),
      _FeatureTile(
        accent: accent,
        icon: LucideIcons.shieldCheck,
        title: l10n.desktopWelcomeNoAccountTitle,
        description: l10n.desktopWelcomeNoAccountDesc,
      ),
    ];

    Widget grid;
    if (twoColumns) {
      Widget row(Widget a, Widget b) => IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: a),
            const SizedBox(width: 14),
            Expanded(child: b),
          ],
        ),
      );
      grid = Column(
        children: [
          for (var i = 0; i < tiles.length; i += 2) ...[
            if (i > 0) const SizedBox(height: 14),
            row(tiles[i], tiles[i + 1]),
          ],
        ],
      );
    } else {
      grid = Column(
        children: [
          for (var i = 0; i < tiles.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            tiles[i],
          ],
        ],
      );
    }

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _SectionLabel(l10n.desktopWelcomeFeaturesLabel, accent: accent),
          const SizedBox(height: 10),
          Text(
            l10n.desktopWelcomeFeaturesTitle,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 22),
          grid,
        ],
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  final Color accent;
  final IconData icon;
  final String title;
  final String description;
  const _FeatureTile({
    required this.accent,
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.025),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: accent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.45,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Full-width pill button: filled with the accent when [primary], outlined
/// otherwise. Disabled when [onPressed] is null.
class _WelcomeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color accent;
  final bool primary;
  final bool autofocus;
  final VoidCallback? onPressed;

  const _WelcomeButton({
    required this.label,
    required this.icon,
    required this.accent,
    required this.primary,
    required this.onPressed,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final onAccent = accent.computeLuminance() > 0.35
        ? Colors.black
        : Colors.white;
    final Color fg = !enabled
        ? Colors.white30
        : primary
        ? onAccent
        : Colors.white;
    final radius = BorderRadius.circular(26);

    return Container(
      height: 50,
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: primary && enabled
            ? LinearGradient(
                colors: [accent, accent.withValues(alpha: 0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: primary && enabled ? null : Colors.white.withValues(alpha: 0.04),
        border: primary && enabled
            ? null
            : Border.all(color: Colors.white.withValues(alpha: 0.1)),
        boxShadow: primary && enabled
            ? [
                BoxShadow(
                  color: accent.withValues(alpha: 0.25),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onPressed,
          autofocus: autofocus,
          borderRadius: radius,
          focusColor: Colors.white.withValues(alpha: 0.12),
          hoverColor: Colors.white.withValues(alpha: 0.06),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: fg),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                    color: fg,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Fallback when no native folder picker is available.
class _ManualPathDialog extends StatefulWidget {
  final String hint;
  const _ManualPathDialog({required this.hint});

  @override
  State<_ManualPathDialog> createState() => _ManualPathDialogState();
}

class _ManualPathDialogState extends State<_ManualPathDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() => Navigator.of(context).pop(_controller.text.trim());

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      backgroundColor: const Color(0xFF1F1F1F),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        l10n.enterFolderPathManually,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.folderPickerManualHint,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            onSubmitted: (_) => _submit(),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: const TextStyle(color: Colors.white30),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            l10n.cancel,
            style: const TextStyle(color: Colors.white54),
          ),
        ),
        ElevatedButton(onPressed: _submit, child: Text(l10n.add)),
      ],
    );
  }
}
