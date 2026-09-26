import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
export 'equalizer_curve_painter.dart';

part 'android_equalizer_screen.g.dart';
part 'equalizer_mode_dialog.dart';
part 'audio_capabilities_sheet.dart';
part 'custom_filter_input.dart';
part 'preset_chips.dart';
part 'setting_rows.dart';

// false = Sliders, true = Graph
@Riverpod(keepAlive: true)
class EqualizerViewMode extends _$EqualizerViewMode {
  @override
  bool build() => false;

  void set(bool value) => state = value;
}

class AndroidEqualizerScreen extends ConsumerWidget {
  const AndroidEqualizerScreen({super.key});

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

  static const Map<String, List<double>> _presets = {
    'Flat': [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    'Bass Booster': [5, 5, 4, 4, 3, 2, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    'Treble Booster': [0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 2, 3, 4, 4, 5, 5, 5, 5],
    'Vocal Booster': [
      -2,
      -2,
      -1,
      0,
      1,
      2,
      3,
      4,
      4,
      4,
      3,
      2,
      1,
      0,
      -1,
      -2,
      -2,
      -2,
    ],
    'Electronic': [4, 3, 2, 1, 0, -1, 1, 2, 2, 1, 2, 3, 4, 4, 3, 2, 4, 3],
    'Rock': [3, 3, 2, 1, -1, -2, -2, -1, 0, 1, 2, 2, 3, 3, 3, 3, 3, 3],
    'Pop': [-1, -1, -1, 0, 1, 2, 3, 3, 3, 2, 1, 0, -1, -1, -1, -1, -1, -1],
    'Jazz': [3, 3, 2, 1, 1, 2, 2, 1, -1, -1, 0, 1, 1, 2, 2, 3, 3, 3],
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final eqState = ref.watch(equalizerProvider);
    final eqNotifier = ref.read(equalizerProvider.notifier);
    final settings = ref.watch(settingsProvider);
    final song = ref.watch(playbackProvider.select((s) => s.currentSong));
    final isGraphMode = ref.watch(equalizerViewModeProvider);

    final accentColor = Color(settings.accentColor);
    final isPureBlack = settings.darkTheme;
    final useBlur = settings.enableDynamicTheming && !settings.disableBlur;
    // Same check PlayerLandscapeMetrics uses for "landscape phone, not
    // tablet" - the graph/slider area's fixed 290dp height was tuned for a
    // tall portrait screen and ate a large fraction of a short window.
    final barModeHeight = Responsive.isShort(MediaQuery.sizeOf(context))
        ? 200.0
        : 290.0;

    if (settings.firstTimeEqualizer) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (ref.read(settingsProvider).firstTimeEqualizer) {
          ref.read(settingsProvider.notifier).updateFirstTimeEqualizer(false);
          _showEqualizerModeDialog(context, ref);
        }
      });
    }

    return Scaffold(
      backgroundColor: isPureBlack ? Colors.black : const Color(0xFF121212),
      body: Container(
        decoration: BoxDecoration(
          gradient: isPureBlack
              ? null
              : LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    accentColor.withValues(alpha: 0.05),
                    const Color(0xFF121212),
                  ],
                ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom Title Bar
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    PremiumSection(
                      borderRadius: BorderRadius.circular(32),
                      width: 48,
                      height: 48,
                      useExpanded: false,
                      showShadow: false,
                      forceNoBlur: true,
                      useBlur: useBlur,
                      keepSurfaceOnDisableBlur: true,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.of(context).pop();
                      },
                      child: const Icon(
                        LucideIcons.chevronLeft,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      l10n.equalizer,
                      style: AppFonts.jostStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(
                        LucideIcons.info,
                        color: Colors.white70,
                        size: 20,
                      ),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        _showEqualizerModeDialog(context, ref);
                      },
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(
                        isGraphMode
                            ? LucideIcons.sliders
                            : LucideIcons.activity,
                        color: Colors.white70,
                        size: 20,
                      ),
                      tooltip: isGraphMode
                          ? context.l10n.eqSwitchToSliders
                          : context.l10n.eqSwitchToGraph,
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        ref
                            .read(equalizerViewModeProvider.notifier)
                            .set(!isGraphMode);
                      },
                    ),
                    const Spacer(),
                    // Master Switch
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          eqState.enabled ? context.l10n.on : context.l10n.off,
                          style: AppFonts.jostStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: eqState.enabled
                                ? accentColor
                                : Colors.white38,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Switch.adaptive(
                          value: eqState.enabled,
                          activeThumbColor: accentColor,
                          activeTrackColor: accentColor.withValues(alpha: 0.5),
                          onChanged: (val) {
                            HapticFeedback.mediumImpact();
                            eqNotifier.toggleEqualizer(val);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Divider(color: Colors.white10, height: 1),

              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Preset Selector Row
                      if (eqState.enabled) ...[
                        Text(
                          l10n.presets,
                          style: AppFonts.jostStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                            color: Colors.white38,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 40,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            children: [
                              ..._presets.keys.map((name) {
                                final presetGains = _presets[name]!;
                                final isCurrent = _isMatchingPreset(
                                  eqState.currentSongGains,
                                  presetGains,
                                );
                                return _buildPresetChip(
                                  label: _presetLabel(context, name),
                                  isCurrent: isCurrent,
                                  accentColor: accentColor,
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    eqNotifier.setPreset(name, presetGains);
                                  },
                                );
                              }),
                              // User-saved curves, appended after the built-ins so the
                              // fixed presets stay in a stable order as custom ones are
                              // added/removed.
                              ...ref.watch(customEqPresetsProvider).map((
                                preset,
                              ) {
                                final isCurrent = _isMatchingPreset(
                                  eqState.currentSongGains,
                                  preset.gains,
                                );
                                return _buildPresetChip(
                                  label: preset.name,
                                  isCurrent: isCurrent,
                                  accentColor: accentColor,
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    eqNotifier.applyCustomPreset(preset.gains);
                                  },
                                  onLongPress: () => _confirmDeleteCustomPreset(
                                    context,
                                    ref,
                                    preset.name,
                                  ),
                                );
                              }),
                              _buildSavePresetChip(
                                context,
                                ref,
                                eqState,
                                accentColor,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Currently Playing Custom Config Details
                      if (song != null) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.06),
                            ),
                          ),
                          child: Row(
                            children: [
                              OptimizedImage(
                                imagePath: song.artPath,
                                width: 44,
                                height: 44,
                                borderRadius: BorderRadius.circular(8),
                                placeholder: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white10,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    LucideIcons.music,
                                    color: Colors.white30,
                                    size: 20,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      song.title,
                                      style: AppFonts.jostStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      eqState.currentSongHasCustom
                                          ? context.l10n.eqSongSpecificActive
                                          : context.l10n.eqUsingGlobalDefault,
                                      style: AppFonts.jostStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: eqState.currentSongHasCustom
                                            ? accentColor
                                            : Colors.white38,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (eqState.currentSongHasCustom &&
                                  eqState.enabled)
                                TextButton.icon(
                                  onPressed: () {
                                    HapticFeedback.mediumImpact();
                                    eqNotifier.resetCurrentSongToDefault();
                                  },
                                  icon: Icon(
                                    LucideIcons.undo2,
                                    color: accentColor,
                                    size: 14,
                                  ),
                                  label: Text(
                                    l10n.reset,
                                    style: AppFonts.jostStyle(
                                      color: accentColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),
                      ],

                      // 18-Band Sliders Scrollable Container
                      Text(
                        isGraphMode
                            ? context.l10n.eqInteractiveGraphHint
                            : context.l10n.eq18BandHint,
                        style: AppFonts.jostStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                          color: Colors.white38,
                        ),
                      ),
                      const SizedBox(height: 12),
                      isGraphMode
                          ? InteractiveEqualizerGraph(
                              eqState: eqState,
                              eqNotifier: eqNotifier,
                              accentColor: accentColor,
                            )
                          : Container(
                              height: barModeHeight,
                              padding: const EdgeInsets.symmetric(
                                vertical: 16,
                                horizontal: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.02),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.04),
                                ),
                              ),
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                child: SizedBox(
                                  width:
                                      18 *
                                      45.0, // Ensures plenty of breathing room for 18 sliders
                                  child: Column(
                                    children: [
                                      // dB Labels Row
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: List.generate(18, (index) {
                                          final gain =
                                              eqState.currentSongGains[index];
                                          return Expanded(
                                            child: Center(
                                              child: Text(
                                                '${gain.round() > 0 ? "+" : ""}${gain.round()}',
                                                style: AppFonts.jostStyle(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold,
                                                  color: eqState.enabled
                                                      ? Colors.white60
                                                      : Colors.white24,
                                                ),
                                              ),
                                            ),
                                          );
                                        }),
                                      ),
                                      const SizedBox(height: 12),

                                      // Sliders and Curve Stack
                                      Expanded(
                                        child: Stack(
                                          children: [
                                            // Bezier EQ Curve Drawing
                                            if (eqState.enabled)
                                              Positioned.fill(
                                                child: IgnorePointer(
                                                  child: ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          24,
                                                        ),
                                                    child: CustomPaint(
                                                      painter:
                                                          EqualizerCurvePainter(
                                                            gains: eqState
                                                                .currentSongGains
                                                                .sublist(0, 18),
                                                            color: accentColor,
                                                          ),
                                                    ),
                                                  ),
                                                ),
                                              ),

                                            // Sliders Horizontal Layout
                                            Positioned.fill(
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceEvenly,
                                                children: List.generate(18, (
                                                  index,
                                                ) {
                                                  return Expanded(
                                                    child: EqualizerSliderTrack(
                                                      gain: eqState
                                                          .currentSongGains[index],
                                                      enabled: eqState.enabled,
                                                      onChanged: (val) {
                                                        // Snap to zero logic
                                                        double finalizedVal =
                                                            val;
                                                        if (val.abs() < 0.8) {
                                                          finalizedVal = 0.0;
                                                        }

                                                        final oldInt = eqState
                                                            .currentSongGains[index]
                                                            .round();
                                                        final newInt =
                                                            finalizedVal
                                                                .round();

                                                        if (newInt != oldInt) {
                                                          if (newInt == 0) {
                                                            HapticFeedback.mediumImpact(); // Snapped to zero!
                                                          }
                                                        }
                                                        eqNotifier.setBandGain(
                                                          index,
                                                          finalizedVal,
                                                        );
                                                      },
                                                      onDragEnd: () {
                                                        eqNotifier
                                                            .applyEqualizerInstant();
                                                      },
                                                    ),
                                                  );
                                                }),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 12),

                                      // Band Frequency Labels Row
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: List.generate(18, (index) {
                                          return Expanded(
                                            child: Center(
                                              child: Text(
                                                _bands[index],
                                                style: AppFonts.jostStyle(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w600,
                                                  color: eqState.enabled
                                                      ? Colors.white60
                                                      : Colors.white24,
                                                ),
                                              ),
                                            ),
                                          );
                                        }),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                      const SizedBox(height: 24),

                      // Pre-amp & Volume Card
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.02),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.04),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Pre-amp Slider
                            if (eqState.enabled) ...[
                              Row(
                                children: [
                                  Icon(
                                    LucideIcons.sliders,
                                    color: accentColor.withValues(alpha: 0.8),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    l10n.preAmpGain,
                                    style: AppFonts.jostStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white70,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '${eqState.preampGain.round() > 0 ? "+" : ""}${eqState.preampGain.round()} dB',
                                    style: AppFonts.jostStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: accentColor,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  activeTrackColor: accentColor,
                                  inactiveTrackColor: Colors.white.withValues(
                                    alpha: 0.08,
                                  ),
                                  thumbColor: Colors.white,
                                  trackHeight: 3.5,
                                  overlayShape: const RoundSliderOverlayShape(
                                    overlayRadius: 16,
                                  ),
                                  thumbShape: const RoundSliderThumbShape(
                                    enabledThumbRadius: 7,
                                  ),
                                ),
                                child: Slider(
                                  value: eqState.preampGain,
                                  min: -12.0,
                                  max: 12.0,
                                  divisions: 24,
                                  onChanged: (val) {
                                    double finalized = val;
                                    if (val.abs() < 0.5) finalized = 0.0;
                                    if (eqState.preampGain.round() !=
                                            finalized.round() &&
                                        finalized.round() == 0) {
                                      HapticFeedback.mediumImpact();
                                    }
                                    eqNotifier.setBandGain(18, finalized);
                                  },
                                  onChangeEnd: (_) {
                                    eqNotifier.applyEqualizerInstant();
                                  },
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],

                            // Volume Slider
                            Row(
                              children: [
                                Icon(
                                  ref.watch(
                                            playbackProvider.select(
                                              (s) => s.volume,
                                            ),
                                          ) ==
                                          0
                                      ? LucideIcons.volumeX
                                      : LucideIcons.volume2,
                                  color: accentColor.withValues(alpha: 0.8),
                                  size: 18,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  l10n.outputVolume,
                                  style: AppFonts.jostStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white70,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '${(ref.watch(playbackProvider.select((s) => s.volume)) * 100).round()}%',
                                  style: AppFonts.jostStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: accentColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                activeTrackColor: accentColor,
                                inactiveTrackColor: Colors.white.withValues(
                                  alpha: 0.08,
                                ),
                                thumbColor: Colors.white,
                                trackHeight: 3.5,
                                overlayShape: const RoundSliderOverlayShape(
                                  overlayRadius: 16,
                                ),
                                thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 7,
                                ),
                              ),
                              child: Slider(
                                value: ref.watch(
                                  playbackProvider.select((s) => s.volume),
                                ),
                                min: 0.0,
                                max: 1.0,
                                onChanged: (val) {
                                  ref
                                      .read(playbackProvider.notifier)
                                      .setVolume(val);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Advanced DSP Panels (Only visible when EQ is enabled)
                      if (eqState.enabled) ...[
                        // 1. Dynamic Range Compressor
                        DspCard(
                          title: context.l10n.eqDynamicRangeCompressor,
                          icon: LucideIcons.sliders,
                          trailing: Switch.adaptive(
                            value: eqState.compressorEnabled,
                            activeThumbColor: accentColor,
                            activeTrackColor: accentColor.withValues(
                              alpha: 0.35,
                            ),
                            onChanged: (val) {
                              HapticFeedback.mediumImpact();
                              eqNotifier.setCompressorEnabled(val);
                            },
                          ),
                          children: [
                            Opacity(
                              opacity: eqState.compressorEnabled ? 1.0 : 0.4,
                              child: IgnorePointer(
                                ignoring: !eqState.compressorEnabled,
                                child: Column(
                                  children: [
                                    _buildSliderRow(
                                      title: context.l10n.eqThreshold,
                                      value: eqState.compressorThreshold,
                                      min: -40.0,
                                      max: 0.0,
                                      unit: 'dB',
                                      onChanged: (v) =>
                                          eqNotifier.setCompressorThreshold(v),
                                    ),
                                    _buildSliderRow(
                                      title: context.l10n.eqRatio,
                                      value: eqState.compressorRatio,
                                      min: 1.0,
                                      max: 20.0,
                                      unit: ':1',
                                      onChanged: (v) =>
                                          eqNotifier.setCompressorRatio(v),
                                    ),
                                    _buildSliderRow(
                                      title: context.l10n.eqAttack,
                                      value: eqState.compressorAttack,
                                      min: 0.01,
                                      max:
                                          100.0, // Clamped display range for attack
                                      unit: 'ms',
                                      onChanged: (v) =>
                                          eqNotifier.setCompressorAttack(v),
                                    ),
                                    _buildSliderRow(
                                      title: context.l10n.eqRelease,
                                      value: eqState.compressorRelease,
                                      min: 10.0,
                                      max:
                                          1000.0, // Clamped display range for release
                                      unit: 'ms',
                                      onChanged: (v) =>
                                          eqNotifier.setCompressorRelease(v),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),

                        // 2. Spatial & Binaural Width
                        DspCard(
                          title: context.l10n.eqHeadphoneCrossfeedWidth,
                          icon: LucideIcons.headphones,
                          children: [
                            _buildSwitchRow(
                              title: context.l10n.eqBinauralCrossfeed,
                              value: eqState.crossfeedEnabled,
                              onChanged: (val) =>
                                  eqNotifier.setCrossfeedEnabled(val),
                              accentColor: accentColor,
                            ),
                            if (eqState.crossfeedEnabled)
                              _buildSliderRow(
                                title: context.l10n.eqCrossfeedStrength,
                                value: eqState.crossfeedStrength,
                                min: 0.0,
                                max: 1.0,
                                unit: '',
                                onChanged: (v) =>
                                    eqNotifier.setCrossfeedStrength(v),
                              ),
                            const SizedBox(height: 12),
                            _buildSwitchRow(
                              title: context.l10n.eqStereoWidening,
                              value: eqState.stereoWidthEnabled,
                              onChanged: (val) =>
                                  eqNotifier.setStereoWidthEnabled(val),
                              accentColor: accentColor,
                            ),
                            if (eqState.stereoWidthEnabled)
                              _buildSliderRow(
                                title: context.l10n.eqWideningFactor,
                                value: eqState.stereoWidthFactor,
                                min: -10.0,
                                max: 10.0,
                                unit: 'x',
                                onChanged: (v) =>
                                    eqNotifier.setStereoWidthFactor(v),
                              ),
                          ],
                        ),

                        // 3. Loudness Normalization
                        DspCard(
                          title: context.l10n.eqLoudnessNormalization,
                          icon: LucideIcons.volume2,
                          trailing: Switch.adaptive(
                            value: eqState.loudnormEnabled,
                            activeThumbColor: accentColor,
                            activeTrackColor: accentColor.withValues(
                              alpha: 0.35,
                            ),
                            onChanged: (val) {
                              HapticFeedback.mediumImpact();
                              eqNotifier.setLoudnormEnabled(val);
                            },
                          ),
                          children: [
                            Opacity(
                              opacity: eqState.loudnormEnabled ? 1.0 : 0.4,
                              child: IgnorePointer(
                                ignoring: !eqState.loudnormEnabled,
                                child: Column(
                                  children: [
                                    _buildSliderRow(
                                      title: context.l10n.eqTargetLoudness,
                                      value: eqState.loudnormTarget,
                                      min: -30.0,
                                      max: -5.0,
                                      unit: 'LUFS',
                                      onChanged: (v) =>
                                          eqNotifier.setLoudnormTarget(v),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),

                        // 4. Tone Shelving
                        DspCard(
                          title: context.l10n.eqToneShelving,
                          icon: LucideIcons.music4,
                          trailing: Switch.adaptive(
                            value: eqState.shelvingEnabled,
                            activeThumbColor: accentColor,
                            activeTrackColor: accentColor.withValues(
                              alpha: 0.35,
                            ),
                            onChanged: (val) {
                              HapticFeedback.mediumImpact();
                              eqNotifier.setShelvingEnabled(val);
                            },
                          ),
                          children: [
                            Opacity(
                              opacity: eqState.shelvingEnabled ? 1.0 : 0.4,
                              child: IgnorePointer(
                                ignoring: !eqState.shelvingEnabled,
                                child: Column(
                                  children: [
                                    _buildSliderRow(
                                      title: context.l10n.eqBassShelf,
                                      value: eqState.bassGain,
                                      min: -10.0,
                                      max: 15.0,
                                      unit: 'dB',
                                      onChanged: (v) =>
                                          eqNotifier.setBassGain(v),
                                    ),
                                    _buildSliderRow(
                                      title: context.l10n.eqTrebleShelf,
                                      value: eqState.trebleGain,
                                      min: -10.0,
                                      max: 15.0,
                                      unit: 'dB',
                                      onChanged: (v) =>
                                          eqNotifier.setTrebleGain(v),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),

                        // 5. Speed & Pitch Rubberband
                        DspCard(
                          title: context.l10n.eqTempoPitchControls,
                          icon: LucideIcons.gauge,
                          trailing: Switch.adaptive(
                            value: eqState.pitchTempoEnabled,
                            activeThumbColor: accentColor,
                            activeTrackColor: accentColor.withValues(
                              alpha: 0.35,
                            ),
                            onChanged: (val) {
                              HapticFeedback.mediumImpact();
                              eqNotifier.setPitchTempoEnabled(val);
                            },
                          ),
                          children: [
                            Opacity(
                              opacity: eqState.pitchTempoEnabled ? 1.0 : 0.4,
                              child: IgnorePointer(
                                ignoring: !eqState.pitchTempoEnabled,
                                child: Column(
                                  children: [
                                    _buildSliderRow(
                                      title: context.l10n.eqPitchShift,
                                      value: eqState.pitch,
                                      min: 0.5,
                                      max: 2.0,
                                      unit: 'x',
                                      onChanged: (v) => eqNotifier.setPitch(v),
                                    ),
                                    _buildSliderRow(
                                      title: context.l10n.eqTempoSpeed,
                                      value: eqState.tempo,
                                      min: 0.5,
                                      max: 3.0,
                                      unit: 'x',
                                      onChanged: (v) => eqNotifier.setTempo(v),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),

                        // 6. Silence Trim & Speech Filter
                        DspCard(
                          title: context.l10n.eqVoiceSilenceControls,
                          icon: LucideIcons.smile,
                          children: [
                            _buildSwitchRow(
                              title: context.l10n.eqSilenceTrimming,
                              value: eqState.silenceTrimEnabled,
                              onChanged: (val) =>
                                  eqNotifier.setSilenceTrimEnabled(val),
                              accentColor: accentColor,
                            ),
                            if (eqState.silenceTrimEnabled)
                              _buildSliderRow(
                                title: context.l10n.eqSilenceThreshold,
                                value: eqState.silenceTrimThreshold,
                                min: -60.0,
                                max: -30.0,
                                unit: 'dB',
                                onChanged: (v) =>
                                    eqNotifier.setSilenceTrimThreshold(v),
                              ),
                            const SizedBox(height: 12),
                            _buildSwitchRow(
                              title: context.l10n.eqSpeechEnhancementFilter,
                              value: eqState.speechFilterEnabled,
                              onChanged: (val) =>
                                  eqNotifier.setSpeechFilterEnabled(val),
                              accentColor: accentColor,
                            ),
                            if (eqState.speechFilterEnabled) ...[
                              _buildSliderRow(
                                title: context.l10n.eqHighpassCutoff,
                                value: eqState.speechHighpass,
                                min: 100.0,
                                max: 300.0,
                                unit: 'Hz',
                                onChanged: (v) =>
                                    eqNotifier.setSpeechHighpass(v),
                              ),
                              _buildSliderRow(
                                title: context.l10n.eqLowpassCutoff,
                                value: eqState.speechLowpass,
                                min: 3000.0,
                                max: 6000.0,
                                unit: 'Hz',
                                onChanged: (v) =>
                                    eqNotifier.setSpeechLowpass(v),
                              ),
                            ],
                          ],
                        ),

                        // 7. Creative Retro & Environment Effects
                        DspCard(
                          title: context.l10n.eqRetroRoomEffects,
                          icon: LucideIcons.sparkles,
                          children: [
                            _buildSwitchRow(
                              title: context.l10n.eqLofiEffect,
                              value: eqState.lofiEnabled,
                              onChanged: (val) =>
                                  eqNotifier.setLofiEnabled(val),
                              accentColor: accentColor,
                            ),
                            const SizedBox(height: 12),
                            _buildSwitchRow(
                              title: context.l10n.eqStudioRoomReverb,
                              value: eqState.reverbEnabled,
                              onChanged: (val) =>
                                  eqNotifier.setReverbEnabled(val),
                              accentColor: accentColor,
                            ),
                            const SizedBox(height: 12),
                            _buildSwitchRow(
                              title: context.l10n.eqVirtualSurround,
                              value: eqState.surroundEnabled,
                              onChanged: (val) =>
                                  eqNotifier.setSurroundEnabled(val),
                              accentColor: accentColor,
                            ),
                          ],
                        ),

                        // 8. Custom FFMpeg AF Console
                        DspCard(
                          title: context.l10n.eqRawFilterConsole,
                          icon: LucideIcons.terminal,
                          children: [
                            Text(
                              l10n.customFilterHint,
                              style: AppFonts.jostStyle(
                                fontSize: 12,
                                color: Colors.white54,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _CustomFilterInput(
                              initialValue: eqState.customFilterString,
                              onSubmitted: (filter) =>
                                  eqNotifier.setCustomFilterString(filter),
                              accentColor: accentColor,
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 24),

                      // Flow & Global Actions Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.02),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.04),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Header Row
                            Row(
                              children: [
                                Icon(
                                  LucideIcons.gitMerge,
                                  color: accentColor.withValues(alpha: 0.8),
                                  size: 18,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  l10n.flowGlobalActions,
                                  style: AppFonts.jostStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Status / Mode Row
                            Row(
                              children: [
                                Text(
                                  l10n.equalizerModeLabel,
                                  style: AppFonts.jostStyle(
                                    fontSize: 13,
                                    color: Colors.white70,
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        (song != null &&
                                            eqState.currentSongHasCustom)
                                        ? accentColor.withValues(alpha: 0.15)
                                        : Colors.white.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color:
                                          (song != null &&
                                              eqState.currentSongHasCustom)
                                          ? accentColor
                                          : Colors.white.withValues(alpha: 0.1),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    (song != null &&
                                            eqState.currentSongHasCustom)
                                        ? context.l10n.eqSongSpecific
                                        : context.l10n.eqGlobalDefault,
                                    style: AppFonts.jostStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          (song != null &&
                                              eqState.currentSongHasCustom)
                                          ? accentColor
                                          : Colors.white70,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Action buttons: "Apply to Global" and "Reset Song to Global"
                            Row(
                              children: [
                                Expanded(
                                  child: TextButton.icon(
                                    onPressed: eqState.enabled
                                        ? () async {
                                            HapticFeedback.mediumImpact();
                                            await eqNotifier
                                                .applyCurrentGainsToGlobal();
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    l10n.currentGainsAppliedGlobal,
                                                    style: AppFonts.jostStyle(
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                  backgroundColor: accentColor,
                                                ),
                                              );
                                            }
                                          }
                                        : null,
                                    icon: Icon(
                                      LucideIcons.globe,
                                      size: 14,
                                      color: eqState.enabled
                                          ? accentColor
                                          : Colors.white24,
                                    ),
                                    label: Text(
                                      l10n.applyToGlobal,
                                      style: AppFonts.jostStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: eqState.enabled
                                            ? Colors.white
                                            : Colors.white24,
                                      ),
                                    ),
                                    style: TextButton.styleFrom(
                                      backgroundColor: eqState.enabled
                                          ? Colors.white.withValues(alpha: 0.04)
                                          : Colors.transparent,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                                if (song != null &&
                                    eqState.currentSongHasCustom &&
                                    eqState.enabled) ...[
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextButton.icon(
                                      onPressed: () async {
                                        HapticFeedback.mediumImpact();
                                        await eqNotifier
                                            .resetCurrentSongToDefault();
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                l10n.songSpecificResetGlobal,
                                                style: AppFonts.jostStyle(
                                                  color: Colors.white,
                                                ),
                                              ),
                                              backgroundColor: accentColor,
                                            ),
                                          );
                                        }
                                      },
                                      icon: Icon(
                                        LucideIcons.undo2,
                                        size: 14,
                                        color: accentColor,
                                      ),
                                      label: Text(
                                        l10n.resetToGlobal,
                                        style: AppFonts.jostStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      style: TextButton.styleFrom(
                                        backgroundColor: Colors.white
                                            .withValues(alpha: 0.04),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),

                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Divider(color: Colors.white10, height: 1),
                            ),

                            // Reset All Songs Equalizer Data
                            TextButton.icon(
                              onPressed: () async {
                                HapticFeedback.heavyImpact();
                                final confirm = await showDialog<bool>(
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
                                      style: AppFonts.jostStyle(
                                        color: Colors.white70,
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(false),
                                        child: Text(
                                          l10n.cancel,
                                          style: AppFonts.jostStyle(
                                            color: Colors.white38,
                                          ),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(true),
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
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          l10n.allSongsEqDataReset,
                                          style: AppFonts.jostStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                        backgroundColor: Colors.redAccent,
                                      ),
                                    );
                                  }
                                }
                              },
                              icon: const Icon(
                                LucideIcons.trash2,
                                size: 14,
                                color: Colors.redAccent,
                              ),
                              label: Text(
                                l10n.resetAllSongsEqData,
                                style: AppFonts.jostStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.redAccent,
                                ),
                              ),
                              style: TextButton.styleFrom(
                                backgroundColor: Colors.redAccent.withValues(
                                  alpha: 0.08,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),
                      Text(
                        context.l10n.eqEditScopeNote,
                        style: AppFonts.jostStyle(
                          fontSize: 12,
                          color: Colors.white38,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                    ],
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
