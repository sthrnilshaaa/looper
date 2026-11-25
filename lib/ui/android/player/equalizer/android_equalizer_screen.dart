import 'package:looper_player/core/motion/app_routes.dart';
import 'package:looper_player/core/motion/looper_scroll_physics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:looper_player/core/theme/app_fonts.dart';
import 'package:looper_player/core/providers/providers.dart';
import 'package:looper_player/core/utils/responsive.dart';
import 'package:looper_player/features/playback/presentation/providers/equalizer/equalizer_notifier.dart';
import 'package:looper_player/features/playback/presentation/providers/playback/playback_notifier.dart';
import 'package:looper_player/features/settings/presentation/providers/settings_notifier.dart';
import 'package:looper_player/ui/android/widgets/premium_section.dart';
import 'package:looper_player/ui/widgets/common/optimized_image.dart';
import 'package:looper_player/ui/widgets/sheets/app_bottom_sheet.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:looper_player/l10n/app_localizations.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'dsp_card.dart';
import 'equalizer_slider_track.dart';
import 'equalizer_curve_painter.dart';
import 'interactive_equalizer_graph.dart';
import 'package:looper_player/core/utils/l10n.dart';
import 'package:looper_player/features/settings/presentation/widgets/settings_widgets.dart'
    show settingsTheme;
import 'package:looper_player/core/services/haptics/app_haptics.dart';
import 'package:looper_player/features/playback/data/auto_eq_service.dart';
import 'package:looper_player/features/playback/data/device_audio_info.dart';
export 'equalizer_curve_painter.dart';

part 'android_equalizer_screen.g.dart';
part 'equalizer_mode_dialog.dart';
part 'audio_capabilities_sheet.dart';
part 'custom_filter_input.dart';
part 'preset_chips.dart';
part 'setting_rows.dart';
part 'headphone_correction_card.dart';
part 'eq_layout.dart';

// false = Sliders, true = Graph
@Riverpod(keepAlive: true)
class EqualizerViewMode extends _$EqualizerViewMode {
  @override
  bool build() => false;

  void set(bool value) => state = value;
}

class AndroidEqualizerScreen extends ConsumerWidget {
  /// Desktop dialog only: bands on the left, DSP cards on the right.
  final bool twoColumn;

  const AndroidEqualizerScreen({super.key, this.twoColumn = false});

  static const List<String> _bands = [
    '65Hz',
    '92Hz',
    '131Hz',
    '185Hz',
    '262Hz',
    '370Hz',
    '523Hz',
    '740Hz',
    '1kHz',
    '1.4kHz',
    '2kHz',
    '2.9kHz',
    '4.1kHz',
    '5.9kHz',
    '8.3kHz',
    '11.7kHz',
    '16.6kHz',
    '20kHz',
  ];

  // Half strength: full-size curves stacked with the tone shelf were far
  // too strong.
  static const Map<String, List<double>> _presets = {
    'Flat': [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    'Bass Booster': [
      2.5,
      2.5,
      2,
      2,
      1.5,
      1,
      0.5,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
    ],
    'Treble Booster': [
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0.5,
      1,
      1.5,
      2,
      2,
      2.5,
      2.5,
      2.5,
      2.5,
    ],
    'Vocal Booster': [
      -1,
      -1,
      -0.5,
      0,
      0.5,
      1,
      1.5,
      2,
      2,
      2,
      1.5,
      1,
      0.5,
      0,
      -0.5,
      -1,
      -1,
      -1,
    ],
    'Electronic': [
      2,
      1.5,
      1,
      0.5,
      0,
      -0.5,
      0.5,
      1,
      1,
      0.5,
      1,
      1.5,
      2,
      2,
      1.5,
      1,
      2,
      1.5,
    ],
    'Rock': [
      1.5,
      1.5,
      1,
      0.5,
      -0.5,
      -1,
      -1,
      -0.5,
      0,
      0.5,
      1,
      1,
      1.5,
      1.5,
      1.5,
      1.5,
      1.5,
      1.5,
    ],
    'Pop': [
      -0.5,
      -0.5,
      -0.5,
      0,
      0.5,
      1,
      1.5,
      1.5,
      1.5,
      1,
      0.5,
      0,
      -0.5,
      -0.5,
      -0.5,
      -0.5,
      -0.5,
      -0.5,
    ],
    'Jazz': [
      1.5,
      1.5,
      1,
      0.5,
      0.5,
      1,
      1,
      0.5,
      -0.5,
      -0.5,
      0,
      0.5,
      0.5,
      1,
      1,
      1.5,
      1.5,
      1.5,
    ],
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final eqState = ref.watch(equalizerProvider);
    final eqNotifier = ref.read(equalizerProvider.notifier);
    final settings = ref.watch(settingsProvider);
    final song = ref.watch(playbackProvider.select((s) => s.currentSong));
    final isGraphMode = ref.watch(equalizerViewModeProvider);
    final volume = ref.watch(playbackProvider.select((s) => s.volume));

    // The redesign is neutral, as Settings: white controls, no accent.
    const accentColor = Colors.white;
    final isPureBlack = settings.darkTheme;
    final isGlobalScope = settings.equalizerGlobalMode;
    // Same check PlayerLandscapeMetrics uses for "landscape phone, not
    // tablet" - the slider area was tuned for a tall portrait screen.
    final barModeHeight = Responsive.isShort(MediaQuery.sizeOf(context))
        ? 200.0
        : 260.0;

    List<double>? autoEqGains;
    if (eqState.autoEqEnabled &&
        eqState.autoEqProfileText != null &&
        eqState.autoEqProfileText!.isNotEmpty) {
      final parsed = AutoEqService.parseParametricEq(
        id: eqState.autoEqSelectedProfile ?? 'custom',
        name: eqState.autoEqSelectedProfile ?? 'custom',
        source: 'AutoEQ',
        content: eqState.autoEqProfileText!,
      );
      autoEqGains = AutoEqService.evaluateProfileAtFrequencies(
        parsed,
        bass: eqState.autoEqBass,
        tilt: eqState.autoEqTilt,
      );
    }

    if (settings.firstTimeEqualizer) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (ref.read(settingsProvider).firstTimeEqualizer) {
          ref.read(settingsProvider.notifier).updateFirstTimeEqualizer(false);
          _showEqualizerModeDialog(context, ref);
        }
      });
    }

    Future<void> setScope(bool global) async {
      await ref
          .read(settingsProvider.notifier)
          .updateEqualizerGlobalMode(global);
      eqNotifier.onSongChanged(ref.read(playbackProvider).currentSong);
      eqNotifier.applyEqualizerInstant();
    }

    Widget divider() => Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: Colors.white.withValues(alpha: 0.06),
    );

    Widget pillButton({
      required String label,
      required VoidCallback? onTap,
      IconData? icon,
      Color background = const Color(0x14FFFFFF),
      Color foreground = Colors.white,
      double height = 36,
    }) => Opacity(
      opacity: onTap == null ? 0.4 : 1,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(height / 2),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap == null
              ? null
              : () {
                  AppHaptics.selection();
                  onTap();
                },
          child: Container(
            height: height,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 14, color: foreground),
                  const SizedBox(width: 6),
                ],
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.jostStyle(
                      fontSize: height > 40 ? 15 : 13,
                      fontWeight: FontWeight.w600,
                      color: foreground,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    Widget viewToggle() {
      Widget seg(bool graph, IconData icon, String tip) {
        final selected = isGraphMode == graph;
        return Tooltip(
          message: tip,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (selected) return;
              AppHaptics.selection();
              ref.read(equalizerViewModeProvider.notifier).set(graph);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 34,
              height: 30,
              decoration: BoxDecoration(
                color: selected ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(
                icon,
                size: 16,
                color: selected
                    ? Colors.black
                    : Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ),
        );
      }

      return Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            seg(false, LucideIcons.slidersVertical, l10n.eqSwitchToSliders),
            const SizedBox(width: 2),
            seg(true, LucideIcons.activity, l10n.eqSwitchToGraph),
          ],
        ),
      );
    }

    final sliders = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const LooperScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: SizedBox(
        width: 18 * 44.0,
        child: Column(
          children: [
            Row(
              children: List.generate(18, (index) {
                final gain = eqState.currentSongGains[index];
                return Expanded(
                  child: Center(
                    child: Text(
                      '${gain.round() > 0 ? "+" : ""}${gain.round()}',
                      style: AppFonts.jostStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: gain.round() != 0 && eqState.enabled
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.56),
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Stack(
                children: [
                  if (eqState.enabled)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(
                          painter: EqualizerCurvePainter(
                            gains: eqState.currentSongGains.sublist(0, 18),
                            color: accentColor,
                            autoEqGains: autoEqGains,
                          ),
                        ),
                      ),
                    ),
                  Positioned.fill(
                    child: Row(
                      children: List.generate(18, (index) {
                        return Expanded(
                          child: EqualizerSliderTrack(
                            gain: eqState.currentSongGains[index],
                            enabled: eqState.enabled,
                            onChanged: (val) {
                              double finalizedVal = val;
                              if (val.abs() < 0.8) finalizedVal = 0.0;
                              final oldInt = eqState.currentSongGains[index]
                                  .round();
                              final newInt = finalizedVal.round();
                              if (newInt != oldInt && newInt == 0) {
                                AppHaptics.snap();
                              }
                              eqNotifier.setBandGain(index, finalizedVal);
                            },
                            onDragEnd: () => eqNotifier.applyEqualizerInstant(),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: List.generate(18, (index) {
                return Expanded(
                  child: Center(
                    child: Text(
                      _bands[index].replaceAll('Hz', ''),
                      style: AppFonts.jostStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.56),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );

    final mainSections = <Widget>[
      _EqSegmented<bool>(
        options: [(true, l10n.eqScopeAllSongs), (false, l10n.eqScopeThisSong)],
        selected: isGlobalScope,
        onSelected: (v) => setScope(v),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(6, 8, 6, 0),
        child: Text(
          isGlobalScope ? l10n.eqScopeAllNote : l10n.eqScopeSongNote,
          style: AppFonts.jostStyle(
            fontSize: 13,
            color: Colors.white.withValues(alpha: 0.56),
          ),
        ),
      ),
      if (!isGlobalScope &&
          song != null &&
          eqState.currentSongHasCustom &&
          eqState.enabled) ...[
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: pillButton(
            label: l10n.eqUseAllSongsForThis,
            icon: LucideIcons.undo2,
            onTap: () => eqNotifier.resetCurrentSongToDefault(),
          ),
        ),
      ],
      const SizedBox(height: 22),

      _HeadphoneCorrectionCard(
        eqState: eqState,
        eqNotifier: eqNotifier,
        accentColor: accentColor,
      ),

      if (eqState.enabled) ...[
        _EqLabel(l10n.eqPresetsLabel),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const LooperScrollPhysics(),
            children: [
              ..._presets.keys.map((name) {
                final presetGains = _presets[name]!;
                return _buildPresetChip(
                  label: _presetLabel(context, name),
                  isCurrent: _isMatchingPreset(
                    eqState.currentSongGains,
                    presetGains,
                  ),
                  accentColor: accentColor,
                  onTap: () {
                    AppHaptics.selection();
                    eqNotifier.setPreset(name, presetGains);
                  },
                );
              }),
              // User-saved curves after the built-ins, so the fixed presets
              // keep a stable order as custom ones come and go.
              ...ref.watch(customEqPresetsProvider).map((preset) {
                return _buildPresetChip(
                  label: preset.name,
                  isCurrent: _isMatchingPreset(
                    eqState.currentSongGains,
                    preset.gains,
                  ),
                  accentColor: accentColor,
                  onTap: () {
                    AppHaptics.selection();
                    eqNotifier.applyCustomPreset(preset.gains);
                  },
                  onLongPress: () =>
                      _confirmDeleteCustomPreset(context, ref, preset.name),
                );
              }),
              _buildSavePresetChip(context, ref, eqState, accentColor),
            ],
          ),
        ),
        const SizedBox(height: 22),
      ],

      _EqCard(
        padding: const EdgeInsets.fromLTRB(0, 16, 0, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.eqBands,
                      style: AppFonts.jostStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  viewToggle(),
                  const SizedBox(width: 8),
                  pillButton(
                    label: l10n.reset,
                    icon: LucideIcons.rotateCcw,
                    onTap: eqState.currentSongGains.take(18).any((g) => g != 0)
                        ? () => eqNotifier.resetBands()
                        : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            if (isGraphMode)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: InteractiveEqualizerGraph(
                  eqState: eqState,
                  eqNotifier: eqNotifier,
                  accentColor: accentColor,
                  autoEqGains: autoEqGains,
                ),
              )
            else
              SizedBox(height: barModeHeight, child: sliders),
          ],
        ),
      ),
      const SizedBox(height: 16),

      _EqCard(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (eqState.enabled)
              _EqSliderRow(
                title: l10n.preAmpGain,
                valueText: _signedDb(eqState.preampGain),
                value: eqState.preampGain,
                min: -12.0,
                max: 12.0,
                divisions: 24,
                onChanged: (val) {
                  double finalized = val;
                  if (val.abs() < 0.5) finalized = 0.0;
                  if (eqState.preampGain.round() != finalized.round() &&
                      finalized.round() == 0) {
                    AppHaptics.medium();
                  }
                  eqNotifier.setBandGain(18, finalized);
                },
                onChangeEnd: (_) => eqNotifier.applyEqualizerInstant(),
              ),
            _EqSliderRow(
              title: l10n.outputVolume,
              valueText: '${(volume * 100).round()}%',
              value: volume,
              min: 0.0,
              max: 1.0,
              onChanged: (val) =>
                  ref.read(playbackProvider.notifier).setVolume(val),
            ),
          ],
        ),
      ),
      const SizedBox(height: 22),
    ];

    final dspSections = <Widget>[
      if (eqState.enabled) ...[
        _EqLabel(
          l10n.eqTone,
          trailing: Switch(
            value: eqState.shelvingEnabled,
            onChanged: (val) {
              AppHaptics.medium();
              eqNotifier.setShelvingEnabled(val);
            },
          ),
        ),
        _EqCard(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
          child: Opacity(
            opacity: eqState.shelvingEnabled ? 1.0 : 0.4,
            child: IgnorePointer(
              ignoring: !eqState.shelvingEnabled,
              child: Column(
                children: [
                  _EqSliderRow(
                    title: l10n.eqBassShelf,
                    valueText: _signedDb(eqState.bassGain),
                    value: eqState.bassGain,
                    min: -10.0,
                    max: 15.0,
                    onChanged: (v) => eqNotifier.setBassGain(v),
                  ),
                  Container(
                    height: 1,
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                  _EqSliderRow(
                    title: l10n.eqTrebleShelf,
                    valueText: _signedDb(eqState.trebleGain),
                    value: eqState.trebleGain,
                    min: -10.0,
                    max: 15.0,
                    onChanged: (v) => eqNotifier.setTrebleGain(v),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 22),

        _EqLabel(l10n.eqEffects),
        _EqCard(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _EffectRow(
                tag: 'DRC',
                title: l10n.eqDynamicRangeCompressor,
                summary:
                    '${eqState.compressorThreshold.round()} dB · ${eqState.compressorRatio.toStringAsFixed(1)}:1',
                value: eqState.compressorEnabled,
                onChanged: eqNotifier.setCompressorEnabled,
                showDivider: false,
                children: [
                  _EqSliderRow(
                    dense: true,
                    title: l10n.eqThreshold,
                    valueText: '${eqState.compressorThreshold.round()} dB',
                    value: eqState.compressorThreshold,
                    min: -40.0,
                    max: 0.0,
                    onChanged: eqNotifier.setCompressorThreshold,
                  ),
                  _EqSliderRow(
                    dense: true,
                    title: l10n.eqRatio,
                    valueText:
                        '${eqState.compressorRatio.toStringAsFixed(1)} : 1',
                    value: eqState.compressorRatio,
                    min: 1.0,
                    max: 20.0,
                    onChanged: eqNotifier.setCompressorRatio,
                  ),
                  _EqSliderRow(
                    dense: true,
                    title: l10n.eqAttack,
                    valueText: '${eqState.compressorAttack.round()} ms',
                    value: eqState.compressorAttack,
                    min: 0.01,
                    max: 100.0,
                    onChanged: eqNotifier.setCompressorAttack,
                  ),
                  _EqSliderRow(
                    dense: true,
                    title: l10n.eqRelease,
                    valueText: '${eqState.compressorRelease.round()} ms',
                    value: eqState.compressorRelease,
                    min: 10.0,
                    max: 1000.0,
                    onChanged: eqNotifier.setCompressorRelease,
                  ),
                ],
              ),
              _EffectRow(
                tag: 'LUF',
                title: l10n.eqLoudnessNormalization,
                summary: '${eqState.loudnormTarget.round()} LUFS',
                value: eqState.loudnormEnabled,
                onChanged: eqNotifier.setLoudnormEnabled,
                children: [
                  _EqSliderRow(
                    dense: true,
                    title: l10n.eqTargetLoudness,
                    valueText: '${eqState.loudnormTarget.round()} LUFS',
                    value: eqState.loudnormTarget,
                    min: -30.0,
                    max: -5.0,
                    onChanged: eqNotifier.setLoudnormTarget,
                  ),
                ],
              ),
              _EffectRow(
                tag: 'XF',
                title: l10n.eqBinauralCrossfeed,
                summary: '${(eqState.crossfeedStrength * 100).round()}%',
                value: eqState.crossfeedEnabled,
                onChanged: eqNotifier.setCrossfeedEnabled,
                children: [
                  _EqSliderRow(
                    dense: true,
                    title: l10n.eqCrossfeedStrength,
                    valueText: '${(eqState.crossfeedStrength * 100).round()}%',
                    value: eqState.crossfeedStrength,
                    min: 0.0,
                    max: 1.0,
                    onChanged: eqNotifier.setCrossfeedStrength,
                  ),
                ],
              ),
              _EffectRow(
                tag: 'ST',
                title: l10n.eqStereoWidening,
                summary: '${eqState.stereoWidthFactor.toStringAsFixed(1)}×',
                value: eqState.stereoWidthEnabled,
                onChanged: eqNotifier.setStereoWidthEnabled,
                children: [
                  _EqSliderRow(
                    dense: true,
                    title: l10n.eqWideningFactor,
                    valueText:
                        '${eqState.stereoWidthFactor.toStringAsFixed(1)}×',
                    value: eqState.stereoWidthFactor,
                    min: -10.0,
                    max: 10.0,
                    onChanged: eqNotifier.setStereoWidthFactor,
                  ),
                ],
              ),
              _EffectRow(
                tag: 'SIL',
                title: l10n.eqSilenceTrimming,
                summary: '${eqState.silenceTrimThreshold.round()} dB',
                value: eqState.silenceTrimEnabled,
                onChanged: eqNotifier.setSilenceTrimEnabled,
                children: [
                  _EqSliderRow(
                    dense: true,
                    title: l10n.eqSilenceThreshold,
                    valueText: '${eqState.silenceTrimThreshold.round()} dB',
                    value: eqState.silenceTrimThreshold,
                    min: -60.0,
                    max: -30.0,
                    onChanged: eqNotifier.setSilenceTrimThreshold,
                  ),
                ],
              ),
              _EffectRow(
                tag: 'VOX',
                title: l10n.eqSpeechEnhancementFilter,
                summary:
                    '${eqState.speechHighpass.round()} Hz – ${(eqState.speechLowpass / 1000).toStringAsFixed(1)} kHz',
                value: eqState.speechFilterEnabled,
                onChanged: eqNotifier.setSpeechFilterEnabled,
                children: [
                  _EqSliderRow(
                    dense: true,
                    title: l10n.eqHighpassCutoff,
                    valueText: '${eqState.speechHighpass.round()} Hz',
                    value: eqState.speechHighpass,
                    min: 100.0,
                    max: 300.0,
                    onChanged: eqNotifier.setSpeechHighpass,
                  ),
                  _EqSliderRow(
                    dense: true,
                    title: l10n.eqLowpassCutoff,
                    valueText: '${eqState.speechLowpass.round()} Hz',
                    value: eqState.speechLowpass,
                    min: 3000.0,
                    max: 6000.0,
                    onChanged: eqNotifier.setSpeechLowpass,
                  ),
                ],
              ),
              _EffectRow(
                tag: 'LO',
                title: l10n.eqLofiEffect,
                summary: l10n.eqLofiDesc,
                value: eqState.lofiEnabled,
                onChanged: eqNotifier.setLofiEnabled,
              ),
              _EffectRow(
                tag: 'REV',
                title: l10n.eqStudioRoomReverb,
                summary: l10n.eqReverbDesc,
                value: eqState.reverbEnabled,
                onChanged: eqNotifier.setReverbEnabled,
              ),
              _EffectRow(
                tag: '3D',
                title: l10n.eqVirtualSurround,
                summary: l10n.eqSurroundDesc,
                value: eqState.surroundEnabled,
                onChanged: eqNotifier.setSurroundEnabled,
              ),
              _EffectRow(
                tag: 'M',
                title: l10n.eqMono,
                summary: l10n.eqMonoDesc,
                value: eqState.monoEnabled,
                onChanged: eqNotifier.setMonoEnabled,
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),

        _EqLabel(
          l10n.eqSpeedPitch,
          trailing: Switch(
            value: eqState.pitchTempoEnabled,
            onChanged: (val) {
              AppHaptics.medium();
              eqNotifier.setPitchTempoEnabled(val);
            },
          ),
        ),
        _EqCard(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
          child: Opacity(
            opacity: eqState.pitchTempoEnabled ? 1.0 : 0.4,
            child: IgnorePointer(
              ignoring: !eqState.pitchTempoEnabled,
              child: Column(
                children: [
                  _EqSliderRow(
                    title: l10n.eqTempoSpeed,
                    valueText: '${eqState.tempo.toStringAsFixed(2)}×',
                    value: eqState.tempo,
                    min: 0.5,
                    max: 3.0,
                    onChanged: eqNotifier.setTempo,
                  ),
                  Container(
                    height: 1,
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                  _EqSliderRow(
                    title: l10n.eqPitchShift,
                    valueText: '${eqState.pitch.toStringAsFixed(2)}×',
                    value: eqState.pitch,
                    min: 0.5,
                    max: 2.0,
                    onChanged: eqNotifier.setPitch,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 22),

        // ReplayGain and live loudness normalization are alternatives
        // (doc 25 §3.2); the notifier keeps them exclusive.
        _EqLabel(l10n.eqReplayGainTitle),
        _EqCard(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _EqSegmented<int>(
                height: 36,
                options: [
                  (0, l10n.off),
                  (1, l10n.qualityReplayGainTrack),
                  (2, l10n.qualityReplayGainAlbum),
                ],
                selected: eqState.replayGainMode,
                onSelected: eqNotifier.setReplayGainMode,
              ),
              if (eqState.replayGainMode > 0)
                _EqSliderRow(
                  title: l10n.eqReplayGainPreamp,
                  valueText: _signedDb(eqState.replayGainPreamp),
                  value: eqState.replayGainPreamp,
                  min: -6.0,
                  max: 14.0,
                  onChanged: eqNotifier.setReplayGainPreamp,
                )
              else
                const SizedBox(height: 6),
            ],
          ),
        ),
        const SizedBox(height: 22),

        _EqLabel(l10n.eqMore),
        _EqCard(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _RawFilterConsole(eqState: eqState, eqNotifier: eqNotifier),
              divider(),
              _EqLinkRow(
                icon: LucideIcons.cpu,
                title: l10n.eqDeviceAudio,
                subtitle: l10n.eqDeviceAudioDesc,
                onTap: () => _showAudioCapabilitiesSheet(context, ref),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],

      pillButton(
        height: 52,
        label: l10n.eqCopyToAllSongs,
        icon: LucideIcons.globe,
        onTap: eqState.enabled && !isGlobalScope
            ? () async {
                await eqNotifier.applyCurrentGainsToGlobal();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.currentGainsAppliedGlobal)),
                  );
                }
              }
            : null,
      ),
      const SizedBox(height: 10),
      pillButton(
        height: 52,
        label: l10n.resetAllSongsEqData,
        background: Colors.redAccent.withValues(alpha: 0.12),
        foreground: const Color(0xFFFF8A8A),
        onTap: () async {
          AppHaptics.warning();
          final confirm = await showTaskDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: isPureBlack
                  ? Colors.black
                  : const Color(0xFF1E1E1E),
              title: Text(
                l10n.resetAllSongsEq,
                style: AppFonts.jostStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Text(
                l10n.resetAllSongsEqConfirm,
                style: AppFonts.jostStyle(color: Colors.white70),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(
                    l10n.cancel,
                    style: AppFonts.jostStyle(color: Colors.white38),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(
                    l10n.reset,
                    style: AppFonts.jostStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
          if (confirm == true) {
            await eqNotifier.resetAllSongsEqualizerData();
            if (context.mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(l10n.allSongsEqDataReset)));
            }
          }
        },
      ),
      const SizedBox(height: 28),
    ];

    final header = Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          Semantics(
            button: true,
            label: MaterialLocalizations.of(context).backButtonTooltip,
            child: Material(
              color: Colors.white.withValues(alpha: 0.08),
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () {
                  AppHaptics.light();
                  Navigator.of(context).pop();
                },
                child: const SizedBox(
                  width: 48,
                  height: 48,
                  child: Icon(LucideIcons.arrowLeft, color: Colors.white),
                ),
              ),
            ),
          ),
          Expanded(
            child: Text(
              l10n.equalizer,
              textAlign: TextAlign.center,
              style: AppFonts.jostStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          SizedBox(
            width: 48,
            child: Semantics(
              label: l10n.equalizer,
              child: Switch(
                value: eqState.enabled,
                onChanged: (val) {
                  AppHaptics.medium();
                  eqNotifier.toggleEqualizer(val);
                },
              ),
            ),
          ),
        ],
      ),
    );

    return Theme(
      data: settingsTheme(Theme.of(context)),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Column(
            children: [
              header,
              Expanded(
                child: twoColumn
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: SingleChildScrollView(
                              physics: const LooperScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(20, 8, 12, 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: mainSections,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: SingleChildScrollView(
                              physics: const LooperScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(12, 8, 20, 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: dspSections,
                              ),
                            ),
                          ),
                        ],
                      )
                    : SingleChildScrollView(
                        physics: const LooperScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [...mainSections, ...dspSections],
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

/// The raw FFmpeg filter console, folded into one row until opened.
class _RawFilterConsole extends StatefulWidget {
  final EqualizerState eqState;
  final Equalizer eqNotifier;

  const _RawFilterConsole({required this.eqState, required this.eqNotifier});

  @override
  State<_RawFilterConsole> createState() => _RawFilterConsoleState();
}

class _RawFilterConsoleState extends State<_RawFilterConsole> {
  late bool _open = widget.eqState.customFilterString.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _EqLinkRow(
          icon: LucideIcons.terminal,
          title: l10n.eqRawFilterConsole,
          subtitle: l10n.eqRawFilterDesc,
          onTap: () => setState(() => _open = !_open),
          trailing: AnimatedRotation(
            duration: const Duration(milliseconds: 200),
            turns: _open ? 0.25 : 0,
            child: Icon(
              LucideIcons.chevronRight,
              size: 18,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          alignment: Alignment.topCenter,
          child: _open
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n.customFilterHint,
                        style: AppFonts.jostStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.56),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _CustomFilterInput(
                        initialValue: widget.eqState.customFilterString,
                        onSubmitted: widget.eqNotifier.setCustomFilterString,
                        accentColor: Colors.white,
                      ),
                    ],
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

/// Built-in preset names double as preset ids, so they stay English in
/// state and are only translated for display.
String _presetLabel(BuildContext context, String name) {
  final l10n = context.l10n;
  return switch (name) {
    'Flat' => l10n.presetFlat,
    'Bass Booster' => l10n.presetBassBooster,
    'Treble Booster' => l10n.presetTrebleBooster,
    'Vocal Booster' => l10n.presetVocalBooster,
    'Electronic' => l10n.presetElectronic,
    'Rock' => l10n.presetRock,
    'Pop' => l10n.presetPop,
    'Jazz' => l10n.presetJazz,
    _ => name,
  };
}
