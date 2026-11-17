part of 'theme_settings_tiles.dart';

/// Opens the progress bar style sheet (wave, thickness, thumb, ...). Took
/// over the old "Flat progress bar" switch, which is now the sheet's Wave
/// toggle.
class ProgressBarStyleTile extends ConsumerWidget {
  const ProgressBarStyleTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return ListTile(
      leading: const Icon(LucideIcons.slidersHorizontal),
      title: Text(l10n.progressBarStyle, style: _tileTitleStyle()),
      subtitle: Text(l10n.progressBarStyleDesc, style: _tileSubtitleStyle()),
      trailing: const Icon(
        LucideIcons.chevronRight,
        color: Colors.white38,
        size: 20,
      ),
      onTap: () {
        AppHaptics.light();
        showProgressBarStyleSheet(context);
      },
    );
  }
}

/// Opens the artwork visualizer sheet (effect, intensity, colors).
class ArtworkVisualizerTile extends ConsumerWidget {
  const ArtworkVisualizerTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final type = ref.watch(
      settingsProvider.select(
        (s) => ArtworkVisualizerStyle.fromSettings(s).type,
      ),
    );
    return ListTile(
      leading: const Icon(LucideIcons.audioLines),
      title: Text(l10n.artworkVisualizer, style: _tileTitleStyle()),
      subtitle: Text(
        type == ArtworkVisualizerType.none
            ? l10n.artworkVisualizerDesc
            : artworkVisualizerTypeLabel(l10n, type),
        style: _tileSubtitleStyle(),
      ),
      trailing: const Icon(
        LucideIcons.chevronRight,
        color: Colors.white38,
        size: 20,
      ),
      onTap: () {
        AppHaptics.light();
        showArtworkVisualizerSheet(context);
      },
    );
  }
}

class PlainTimestampsTile extends ConsumerWidget {
  const PlainTimestampsTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final l10n = AppLocalizations.of(context)!;
    return SwitchListTile(
      secondary: const Icon(LucideIcons.clock),
      title: Text(l10n.plainTimestamps, style: _tileTitleStyle()),
      subtitle: Text(l10n.useStaticTextTimestamps, style: _tileSubtitleStyle()),
      value: settings.disableAnimatedDuration,
      onChanged: (value) {
        ref
            .read(settingsProvider.notifier)
            .updateDisableAnimatedDuration(value);
      },
    );
  }
}

class ShowQualityBadgeTile extends ConsumerWidget {
  const ShowQualityBadgeTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final l10n = AppLocalizations.of(context)!;
    return SwitchListTile(
      secondary: const Icon(LucideIcons.info),
      title: Text(l10n.showQualityBadge, style: _tileTitleStyle()),
      subtitle: Text(l10n.showQualityBadgeDesc, style: _tileSubtitleStyle()),
      value: settings.showQualityBadge,
      onChanged: (value) {
        ref.read(settingsProvider.notifier).updateShowQualityBadge(value);
      },
    );
  }
}

class KeepScreenAwakeTile extends ConsumerWidget {
  const KeepScreenAwakeTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final l10n = AppLocalizations.of(context)!;
    return SwitchListTile(
      secondary: const Icon(LucideIcons.sun),
      title: Text(l10n.keepScreenAwake, style: _tileTitleStyle()),
      subtitle: Text(l10n.keepScreenAwakeDesc, style: _tileSubtitleStyle()),
      value: settings.keepScreenAwake ?? true,
      onChanged: (value) {
        ref.read(settingsProvider.notifier).updateKeepScreenAwake(value);
      },
    );
  }
}

class HighRefreshRateTile extends ConsumerWidget {
  const HighRefreshRateTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final l10n = AppLocalizations.of(context)!;
    return SwitchListTile(
      secondary: const Icon(LucideIcons.gauge),
      title: Text(l10n.highRefreshRate, style: _tileTitleStyle()),
      subtitle: Text(l10n.highRefreshRateDesc, style: _tileSubtitleStyle()),
      value: settings.forceHighRefreshRate ?? true,
      onChanged: (value) {
        ref.read(settingsProvider.notifier).updateForceHighRefreshRate(value);
      },
    );
  }
}

/// Lists an artist page's songs under album headers. Off by default.
class GroupArtistByAlbumTile extends ConsumerWidget {
  const GroupArtistByAlbumTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final l10n = AppLocalizations.of(context)!;
    return SwitchListTile(
      secondary: const Icon(LucideIcons.libraryBig),
      title: Text(l10n.groupByAlbum, style: _tileTitleStyle()),
      subtitle: Text(l10n.groupByAlbumDesc, style: _tileSubtitleStyle()),
      value: settings.artistGroupByAlbum,
      onChanged: (value) {
        ref.read(settingsProvider.notifier).updateArtistGroupByAlbum(value);
      },
    );
  }
}

/// Adds the album after the artist ("Artist • Album") under song titles.
class ShowAlbumNextToArtistTile extends ConsumerWidget {
  const ShowAlbumNextToArtistTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final l10n = AppLocalizations.of(context)!;
    return SwitchListTile(
      secondary: const Icon(LucideIcons.disc3),
      title: Text(l10n.showAlbumNextToArtist, style: _tileTitleStyle()),
      subtitle: Text(
        l10n.showAlbumNextToArtistDesc,
        style: _tileSubtitleStyle(),
      ),
      value: settings.showAlbumNextToArtist,
      onChanged: (value) {
        ref.read(settingsProvider.notifier).updateShowAlbumNextToArtist(value);
      },
    );
  }
}

/// Also adds the album in Home's Quick Picks; shown only while
/// [ShowAlbumNextToArtistTile] is on.
class ShowAlbumInQuickPicksTile extends ConsumerWidget {
  const ShowAlbumInQuickPicksTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final l10n = AppLocalizations.of(context)!;
    return SwitchListTile(
      secondary: const Icon(LucideIcons.sparkles),
      title: Text(l10n.showAlbumInQuickPicks, style: _tileTitleStyle()),
      subtitle: Text(
        l10n.showAlbumInQuickPicksDesc,
        style: _tileSubtitleStyle(),
      ),
      value: settings.showAlbumInQuickPicks,
      onChanged: (value) {
        ref.read(settingsProvider.notifier).updateShowAlbumInQuickPicks(value);
      },
    );
  }
}

/// Opens the quality badge style sheet (look, icon, colors, details).
class QualityBadgeStyleTile extends ConsumerWidget {
  const QualityBadgeStyleTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return ListTile(
      leading: const Icon(LucideIcons.badgeCheck),
      title: Text(l10n.qualityBadgeStyle, style: _tileTitleStyle()),
      subtitle: Text(l10n.qualityBadgeStyleDesc, style: _tileSubtitleStyle()),
      trailing: const Icon(
        LucideIcons.chevronRight,
        color: Colors.white38,
        size: 20,
      ),
      onTap: () {
        AppHaptics.light();
        showQualityBadgeSheet(context);
      },
    );
  }
}

/// Swaps the player's shuffle / repeat / next up / lyrics pill groups for
/// four icon-only tiles styled like the prev / play / next row.
class SegmentedUtilityButtonsTile extends ConsumerWidget {
  const SegmentedUtilityButtonsTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final l10n = AppLocalizations.of(context)!;
    return SwitchListTile(
      secondary: const Icon(LucideIcons.columns4),
      title: Text(l10n.segmentedUtilityButtons, style: _tileTitleStyle()),
      subtitle: Text(
        l10n.segmentedUtilityButtonsDesc,
        style: _tileSubtitleStyle(),
      ),
      value: settings.segmentedUtilityButtons,
      onChanged: (value) {
        ref
            .read(settingsProvider.notifier)
            .updateSegmentedUtilityButtons(value);
      },
    );
  }
}

/// Shows the current lyric line under the player's cover.
class PlayerLyricLineTile extends ConsumerWidget {
  const PlayerLyricLineTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final l10n = AppLocalizations.of(context)!;
    return SwitchListTile(
      secondary: const Icon(LucideIcons.micVocal),
      title: Text(l10n.playerLyricLine, style: _tileTitleStyle()),
      subtitle: Text(l10n.playerLyricLineDesc, style: _tileSubtitleStyle()),
      value: settings.playerLyricLine,
      onChanged: (value) {
        ref.read(settingsProvider.notifier).updatePlayerLyricLine(value);
      },
    );
  }
}

/// Portrait Now Playing layout: classic, arc or linear.
class PlayerStyleTile extends ConsumerWidget {
  const PlayerStyleTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final l10n = AppLocalizations.of(context)!;
    final current = settings.playerStyle.isEmpty
        ? 'classic'
        : settings.playerStyle;
    final options = [
      ('classic', l10n.playerStyleClassic),
      ('arc', l10n.playerStyleArc),
      ('linear', l10n.playerStyleLinear),
      ('card', l10n.playerStyleCard),
    ];
    final styleTile = _PlayerStylesCard(
      current: current,
      options: options,
      onSelect: (value) {
        AppHaptics.selection();
        ref.read(settingsProvider.notifier).updatePlayerStyle(value);
      },
    );
    if (current == 'classic') return styleTile;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        styleTile,
        SwitchListTile(
          secondary: const Icon(LucideIcons.moon),
          title: Text(l10n.cardBlackBackground, style: _tileTitleStyle()),
          subtitle: Text(
            l10n.cardBlackBackgroundDesc,
            style: _tileSubtitleStyle(),
          ),
          value: settings.cardBlackBackground,
          onChanged: (value) {
            AppHaptics.selection();
            ref
                .read(settingsProvider.notifier)
                .updateCardBlackBackground(value);
          },
        ),
        if (!settings.cardBlackBackground) ...[
          SwitchListTile(
            secondary: const Icon(LucideIcons.paintBucket),
            title: Text(l10n.cardAccentBackground, style: _tileTitleStyle()),
            subtitle: Text(
              l10n.cardAccentBackgroundDesc,
              style: _tileSubtitleStyle(),
            ),
            value: settings.cardAccentBackground,
            onChanged: (value) {
              AppHaptics.selection();
              ref
                  .read(settingsProvider.notifier)
                  .updateCardAccentBackground(value);
            },
          ),
          if (settings.cardAccentBackground) ...[
            const EnablePlayerGradientTile(),
            if (settings.enablePlayerGradient)
              const AnimatePlayerGradientTile(),
          ] else ...[
            SwitchListTile(
              secondary: const Icon(LucideIcons.sparkles),
              title: Text(
                l10n.playerStyleBlurBackground,
                style: _tileTitleStyle(),
              ),
              subtitle: Text(
                l10n.playerStyleBlurBackgroundDesc,
                style: _tileSubtitleStyle(),
              ),
              value: settings.playerStyleBlur,
              onChanged: (value) {
                AppHaptics.selection();
                ref
                    .read(settingsProvider.notifier)
                    .updatePlayerStyleBlur(value);
              },
            ),
          ],
        ],
        // Separate toggle: accent color for lyrics line + progress bar.
        SwitchListTile(
          secondary: const Icon(LucideIcons.palette),
          title: Text(l10n.cardAccentColors, style: _tileTitleStyle()),
          subtitle: Text(
            l10n.cardAccentColorsDesc,
            style: _tileSubtitleStyle(),
          ),
          value: settings.cardAccentColors || settings.playerStyleAccent,
          onChanged: (value) {
            AppHaptics.selection();
            ref.read(settingsProvider.notifier).updateCardAccentColors(value);
          },
        ),
      ],
    );
  }
}

/// How that line changes to the next: cube, rolling, flip or blur.
class PlayerLyricLineTransitionTile extends ConsumerWidget {
  const PlayerLyricLineTransitionTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final l10n = AppLocalizations.of(context)!;
    final accent = settings.accent;
    final current = settings.playerLyricLineTransition.isEmpty
        ? 'cube'
        : settings.playerLyricLineTransition;
    final options = [
      ('cube', l10n.lyricLineTransitionCube),
      ('roll', l10n.lyricLineTransitionRoll),
      ('flip', l10n.lyricLineTransitionFlip),
      ('blur', l10n.lyricLineTransitionBlur),
    ];
    return ListTile(
      leading: const Icon(LucideIcons.box),
      title: Text(l10n.playerLyricLineTransition, style: _tileTitleStyle()),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (value, label) in options)
              ChoiceChip(
                label: Text(label),
                selected: current == value,
                showCheckmark: false,
                selectedColor: Colors.white.withValues(alpha: 0.15),
                onSelected: (_) {
                  AppHaptics.selection();
                  ref
                      .read(settingsProvider.notifier)
                      .updatePlayerLyricLineTransition(value);
                },
              ),
          ],
        ),
      ),
    );
  }
}

class EnablePlayerGradientTile extends ConsumerWidget {
  const EnablePlayerGradientTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final l10n = AppLocalizations.of(context)!;
    return SwitchListTile(
      secondary: const Icon(LucideIcons.sparkles),
      title: Text(l10n.enablePlayerGradient, style: _tileTitleStyle()),
      subtitle: Text(
        l10n.enablePlayerGradientDesc,
        style: _tileSubtitleStyle(),
      ),
      value: settings.enablePlayerGradient,
      onChanged: (value) {
        ref.read(settingsProvider.notifier).updateEnablePlayerGradient(value);
      },
    );
  }
}

class AnimatePlayerGradientTile extends ConsumerWidget {
  const AnimatePlayerGradientTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final l10n = AppLocalizations.of(context)!;
    return SwitchListTile(
      secondary: const Icon(LucideIcons.audioWaveform),
      title: Text(l10n.animatePlayerGradient, style: _tileTitleStyle()),
      subtitle: Text(
        l10n.animatePlayerGradientDesc,
        style: _tileSubtitleStyle(),
      ),
      value: settings.animatePlayerGradient,
      onChanged: (value) {
        ref.read(settingsProvider.notifier).updateAnimatePlayerGradient(value);
      },
    );
  }
}

class KeepBackgroundGradientTile extends ConsumerWidget {
  const KeepBackgroundGradientTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final l10n = AppLocalizations.of(context)!;
    return SwitchListTile(
      secondary: const Icon(LucideIcons.layers),
      title: Text(l10n.keepBackgroundGradient, style: _tileTitleStyle()),
      subtitle: Text(
        l10n.keepBackgroundGradientDesc,
        style: _tileSubtitleStyle(),
      ),
      value: settings.keepBackgroundGradient,
      onChanged: (value) {
        ref.read(settingsProvider.notifier).updateKeepBackgroundGradient(value);
      },
    );
  }
}

class AnimateBackgroundGradientTile extends ConsumerWidget {
  const AnimateBackgroundGradientTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final l10n = AppLocalizations.of(context)!;
    return SwitchListTile(
      secondary: const Icon(LucideIcons.waves),
      title: Text(l10n.animateBackgroundGradient, style: _tileTitleStyle()),
      subtitle: Text(
        l10n.animateBackgroundGradientDesc,
        style: _tileSubtitleStyle(),
      ),
      value: settings.animateBackgroundGradient,
      onChanged: (value) {
        ref
            .read(settingsProvider.notifier)
            .updateAnimateBackgroundGradient(value);
      },
    );
  }
}

/// "Player Styles > Classic" card (Figma "Frame 907"): the four styles as
/// skeleton thumbnails, the picked one outlined with a tick. › opens the
/// full-screen picker.
class _PlayerStylesCard extends StatelessWidget {
  const _PlayerStylesCard({
    required this.current,
    required this.options,
    required this.onSelect,
  });

  final String current;
  final List<(String, String)> options;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final label = options
        .firstWhere((o) => o.$1 == current, orElse: () => options.first)
        .$2;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.fromLTRB(21, 20, 20, 25),
      decoration: BoxDecoration(
        color: const Color(0xFF101010),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => Navigator.of(context, rootNavigator: true).push(
              PageRouteBuilder<void>(
                transitionDuration: const Duration(milliseconds: 320),
                reverseTransitionDuration: const Duration(milliseconds: 240),
                pageBuilder: (_, _, _) => const PlayerStylePickerScreen(),
                transitionsBuilder: (_, a, _, child) =>
                    FadeTransition(opacity: a, child: child),
              ),
            ),
            child: SizedBox(
              height: 20,
              child: Row(
                children: [
                  const CustomPaint(
                    size: Size(15, 20),
                    painter: _PhoneIconPainter(),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(text: '${l10n.playerStyle} › '),
                          TextSpan(
                            text: label,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                          ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.jostStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    LucideIcons.chevronRight,
                    color: Colors.white,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Container(height: 1, color: const Color(0x05FFFFFF)),
          const SizedBox(height: 20),
          Row(
            children: [
              for (var i = 0; i < options.length; i++) ...[
                if (i > 0) const SizedBox(width: 15.6),
                Expanded(
                  child: _StyleThumb(
                    index: i,
                    label: options[i].$2,
                    selected: options[i].$1 == current,
                    onTap: () => onSelect(options[i].$1),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _StyleThumb extends StatelessWidget {
  const _StyleThumb({
    required this.index,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final int index;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(10);
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: AspectRatio(
          aspectRatio: 67.25 / 107,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: selected ? Colors.transparent : const Color(0x0DD9D9D9),
              borderRadius: radius,
              border: Border.all(
                color: selected ? Colors.white : Colors.transparent,
                width: 2,
              ),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                CustomPaint(painter: _StyleThumbPainter(index)),
                Center(
                  child: AnimatedScale(
                    scale: selected ? 1 : 0.6,
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutBack,
                    child: AnimatedOpacity(
                      opacity: selected ? 1 : 0,
                      duration: const Duration(milliseconds: 180),
                      child: Container(
                        width: 15,
                        height: 15,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          size: 11,
                          color: Color(0xFF101010),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The skeleton of each style, drawn in the design's 67.25 × 107 box.
class _StyleThumbPainter extends CustomPainter {
  const _StyleThumbPainter(this.index);

  final int index;

  static const _w = 67.25;
  static const _fill = Color(0x1AD9D9D9);

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / _w;
    canvas.scale(k);
    final p = Paint()..color = _fill;
    void r(double x, double y, double w, double h, [double rad = 3]) =>
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, y, w, h),
            Radius.circular(rad),
          ),
          p,
        );
    // Centred title, artist and a pair of controls (Classic, Linear).
    void centred() {
      r(5.53, 72, 29.48, 6);
      r(5.53, 82, 57.12, 6);
      r(23.95, 93, 9.21, 6);
      r(34.09, 93, 9.21, 6);
    }

    // Lines on the left and a column of buttons on the right (Arc, Card).
    void sided() {
      r(6.45, 65, 29.48, 6);
      r(6.45, 73, 20.27, 6);
      r(6.45, 82, 24.87, 6);
      r(6.45, 95, 9.21, 6);
      for (final y in [64.0, 73.0, 82.0, 95.0]) {
        r(57.12, y, 5.53, 6, 2.76);
      }
    }

    switch (index) {
      case 0: // Classic: square cover.
        r(5.53, 6, 57.12, 62);
        centred();
      case 1: // Arc: cover rounding into the arc seek bar under it.
        final art = Path()
          ..moveTo(3.68, 7)
          ..arcToPoint(const Offset(6.68, 4), radius: const Radius.circular(3))
          ..lineTo(60.57, 4)
          ..arcToPoint(const Offset(63.57, 7), radius: const Radius.circular(3))
          ..lineTo(63.57, 20.06)
          ..arcToPoint(
            const Offset(3.68, 20.06),
            radius: const Radius.circular(29.94),
          )
          ..close();
        canvas.drawPath(art, p);
        canvas.drawPath(
          Path()
            ..moveTo(8.4, 46.3)
            ..quadraticBezierTo(33.6, 72, 58.8, 46.3),
          Paint()
            ..color = _fill
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4.2
            ..strokeCap = StrokeCap.round,
        );
        sided();
      case 2: // Linear: round cover.
        canvas.drawCircle(const Offset(33.5, 35), 29.25, p);
        centred();
      default: // Card: cover fading out downward.
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(5.25, 6, 57, 54),
            const Radius.circular(3),
          ),
          Paint()
            ..shader = const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x1AD9D9D9), Color(0x00737373)],
            ).createShader(const Rect.fromLTWH(5.25, 6, 57, 54)),
        );
        sided();
    }
  }

  @override
  bool shouldRepaint(_StyleThumbPainter old) => old.index != index;
}

/// The phone outline with a tiny player inside, before "Player Styles".
class _PhoneIconPainter extends CustomPainter {
  const _PhoneIconPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(0.65, 0.65, 13.7, 18.7),
        const Radius.circular(6.5),
      ),
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3,
    );
    final dim = Paint()..color = const Color(0x33D9D9D9);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(3, 3, 9, 8),
        const Radius.circular(2),
      ),
      dim,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(3, 13, 5, 1),
        const Radius.circular(0.5),
      ),
      dim,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(3, 15, 9, 1),
        const Radius.circular(0.5),
      ),
      dim,
    );
  }

  @override
  bool shouldRepaint(_PhoneIconPainter old) => false;
}
