import 'package:looper_player/core/motion/looper_scroll_physics.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:looper_player/core/theme/app_fonts.dart';
import 'package:looper_player/features/settings/domain/progress_bar_style.dart';
import 'package:looper_player/features/settings/presentation/providers/settings_notifier.dart';
import 'package:looper_player/l10n/app_localizations.dart';
import 'package:looper_player/ui/widgets/player/premium_progress_bar.dart';
import 'package:looper_player/ui/widgets/sheets/app_bottom_sheet.dart';

import 'style_sheet_controls.dart';
import 'package:looper_player/core/services/haptics/app_haptics.dart';

void showProgressBarStyleSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const _ProgressBarStyleSheet(),
  );
}

/// Every progress bar setting with a live preview on top. Edits go to a
/// local draft first so the preview follows a slider while it's dragged;
/// the draft is saved when a drag ends or a switch/choice is tapped.
class _ProgressBarStyleSheet extends ConsumerStatefulWidget {
  const _ProgressBarStyleSheet();

  @override
  ConsumerState<_ProgressBarStyleSheet> createState() =>
      _ProgressBarStyleSheetState();
}

class _ProgressBarStyleSheetState
    extends ConsumerState<_ProgressBarStyleSheet> {
  late ProgressBarStyle _draft = ProgressBarStyle.fromSettings(
    ref.read(settingsProvider),
  );

  void _edit(ProgressBarStyle next) => setState(() => _draft = next);

  void _save(ProgressBarStyle next) {
    setState(() => _draft = next);
    ref.read(settingsProvider.notifier).updateProgressBarStyle(next);
  }

  Future<void> _reset() async {
    AppHaptics.medium();
    await ref.read(settingsProvider.notifier).resetProgressBarStyle();
    if (mounted) setState(() => _draft = ProgressBarStyle.defaults);
  }

  static String _dp(double v) => '${v.toStringAsFixed(v < 10 ? 1 : 0)} dp';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final accent = Color(
      ref.watch(settingsProvider.select((s) => s.accentColor)),
    );
    final d = _draft;
    final bool hasThumb = d.thumbStyle != ProgressThumbStyle.none;

    // One slider row; [apply] builds the new style from the slider value.
    Widget slider({
      required String title,
      String? subtitle,
      required double value,
      required double min,
      required double max,
      required String Function(double) format,
      required ProgressBarStyle Function(double) apply,
      bool enabled = true,
    }) => StyleSliderRow(
      title: title,
      subtitle: subtitle,
      valueLabel: format(value),
      value: value,
      min: min,
      max: max,
      accent: accent,
      enabled: enabled,
      onChanged: (v) => _edit(apply(v)),
      onChangeEnd: (v) => _save(apply(v)),
    );

    return AppBottomSheetContainer(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.progressBarStyle,
                    style: AppFonts.jostStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: d == ProgressBarStyle.defaults ? null : _reset,
                  icon: const Icon(LucideIcons.rotateCcw, size: 16),
                  label: Text(l10n.resetToDefaults),
                  style: TextButton.styleFrom(
                    foregroundColor: accent,
                    disabledForegroundColor: Colors.white24,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _ProgressPreview(style: d),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.only(bottom: 24),
                physics: const LooperScrollPhysics(),
                children: [
                  StyleSectionLabel(l10n.progressWave, accent: accent),
                  StyleSwitchRow(
                    title: l10n.progressWave,
                    subtitle: l10n.progressWaveDesc,
                    value: d.wave,
                    accent: accent,
                    onChanged: (v) => _save(d.copyWith(wave: v)),
                  ),
                  slider(
                    title: l10n.progressWaveHeight,
                    value: d.waveHeight,
                    min: ProgressBarStyle.minWaveHeight,
                    max: ProgressBarStyle.maxWaveHeight,
                    format: _dp,
                    apply: (v) => d.copyWith(waveHeight: v),
                    enabled: d.wave,
                  ),
                  slider(
                    title: l10n.progressWaveLength,
                    subtitle: l10n.progressWaveLengthDesc,
                    value: d.waveLength,
                    min: ProgressBarStyle.minWaveLength,
                    max: ProgressBarStyle.maxWaveLength,
                    format: _dp,
                    apply: (v) => d.copyWith(waveLength: v),
                    enabled: d.wave,
                  ),
                  slider(
                    title: l10n.progressWaveSpeed,
                    value: d.waveSpeed,
                    min: ProgressBarStyle.minWaveSpeed,
                    max: ProgressBarStyle.maxWaveSpeed,
                    // Shown relative to the default speed, e.g. "2.0x".
                    format: (v) =>
                        '${(v / ProgressBarStyle.defaultWaveSpeed).toStringAsFixed(1)}x',
                    apply: (v) => d.copyWith(waveSpeed: v),
                    enabled: d.wave,
                  ),
                  StyleSwitchRow(
                    title: l10n.progressWaveFromStart,
                    subtitle: l10n.progressWaveFromStartDesc,
                    value: d.waveFromStart,
                    accent: accent,
                    enabled: d.wave,
                    onChanged: (v) => _save(d.copyWith(waveFromStart: v)),
                  ),
                  StyleSwitchRow(
                    title: l10n.progressKeepWavePaused,
                    subtitle: l10n.progressKeepWavePausedDesc,
                    value: d.freezeWhenPaused,
                    accent: accent,
                    enabled: d.wave,
                    onChanged: (v) => _save(d.copyWith(freezeWhenPaused: v)),
                  ),
                  StyleSectionLabel(l10n.progressTrack, accent: accent),
                  slider(
                    title: l10n.progressBarThickness,
                    value: d.thickness,
                    min: ProgressBarStyle.minThickness,
                    max: ProgressBarStyle.maxThickness,
                    format: _dp,
                    apply: (v) => d.copyWith(thickness: v),
                  ),
                  slider(
                    title: l10n.progressTrackOpacity,
                    value: d.inactiveOpacity,
                    min: ProgressBarStyle.minInactiveOpacity,
                    max: ProgressBarStyle.maxInactiveOpacity,
                    format: (v) => '${(v * 100).round()}%',
                    apply: (v) => d.copyWith(inactiveOpacity: v),
                  ),
                  StyleSectionLabel(l10n.progressThumb, accent: accent),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 6,
                    ),
                    child: StyleSegmentedChoice<ProgressThumbStyle>(
                      values: ProgressThumbStyle.values,
                      selected: d.thumbStyle,
                      accent: accent,
                      label: (t) => switch (t) {
                        ProgressThumbStyle.pill => l10n.progressThumbPill,
                        ProgressThumbStyle.round => l10n.progressThumbRound,
                        ProgressThumbStyle.none => l10n.none,
                      },
                      onSelected: (t) => _save(d.copyWith(thumbStyle: t)),
                    ),
                  ),
                  if (d.thumbStyle == ProgressThumbStyle.pill)
                    slider(
                      title: l10n.progressThumbWidth,
                      value: d.thumbWidth,
                      min: ProgressBarStyle.minThumbWidth,
                      max: ProgressBarStyle.maxThumbWidth,
                      format: _dp,
                      apply: (v) => d.copyWith(thumbWidth: v),
                    ),
                  slider(
                    title: d.thumbStyle == ProgressThumbStyle.round
                        ? l10n.progressThumbSize
                        : l10n.progressThumbHeight,
                    value: d.thumbHeight,
                    min: ProgressBarStyle.minThumbHeight,
                    max: ProgressBarStyle.maxThumbHeight,
                    format: _dp,
                    apply: (v) => d.copyWith(thumbHeight: v),
                    enabled: hasThumb,
                  ),
                  slider(
                    title: l10n.progressThumbGap,
                    value: d.thumbGap,
                    min: ProgressBarStyle.minThumbGap,
                    max: ProgressBarStyle.maxThumbGap,
                    format: _dp,
                    apply: (v) => d.copyWith(thumbGap: v),
                  ),
                  StyleSwitchRow(
                    title: l10n.progressGrowThumb,
                    value: d.growThumbOnDrag,
                    accent: accent,
                    enabled: hasThumb,
                    onChanged: (v) => _save(d.copyWith(growThumbOnDrag: v)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A real [ExpressiveSlider] on a fake song that plays along, so every
/// change shows exactly as it will in the player. Tap play/pause to see the
/// paused look; drag it to try the thumb.
class _ProgressPreview extends StatefulWidget {
  final ProgressBarStyle style;

  const _ProgressPreview({required this.style});

  @override
  State<_ProgressPreview> createState() => _ProgressPreviewState();
}

class _ProgressPreviewState extends State<_ProgressPreview>
    with SingleTickerProviderStateMixin {
  static const Duration _duration = Duration(minutes: 3, seconds: 30);
  static const Duration _step = Duration(milliseconds: 250);

  Duration _position = const Duration(minutes: 1, seconds: 12);
  bool _playing = true;
  bool _scrubbing = false;
  // A Ticker rather than a periodic Timer, so the fake playback stops
  // whenever nobody can see it (sheet covered, app in background).
  late final Ticker _ticker;
  Duration _lastStep = Duration.zero;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      if (elapsed - _lastStep < _step) return;
      _lastStep = elapsed;
      if (!_playing || _scrubbing) return;
      setState(() {
        _position += _step;
        if (_position >= _duration) _position = Duration.zero;
      });
    })..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10, width: 0.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: ExpressiveSlider(
              position: _position,
              duration: _duration,
              isPlaying: _playing,
              style: widget.style,
              color: colorScheme.primary,
              onSeek: (pos) => setState(() => _position = pos),
              onSeekStart: () => _scrubbing = true,
              onSeekEnd: () => _scrubbing = false,
            ),
          ),
          IconButton(
            onPressed: () {
              AppHaptics.light();
              setState(() => _playing = !_playing);
            },
            icon: Icon(
              _playing ? LucideIcons.pause : LucideIcons.play,
              color: Colors.white,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}
