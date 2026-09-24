import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:looper_player/core/app_fonts.dart';
import 'package:looper_player/core/providers.dart';
import 'package:looper_player/core/responsive.dart';
import 'package:looper_player/features/playback/presentation/equalizer_notifier.dart';
import 'package:looper_player/features/playback/presentation/playback_notifier.dart';
import 'package:looper_player/features/settings/presentation/settings_notifier.dart';
import 'package:looper_player/ui/screens/android/widgets/premium_section.dart';
import 'package:looper_player/ui/widgets/optimized_image.dart';
import 'package:looper_player/ui/widgets/app_bottom_sheet.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:looper_player/l10n/app_localizations.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'android_equalizer_screen.g.dart';

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
    '20kHz'
  ];

  static const Map<String, List<double>> _presets = {
    'Flat': [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    'Bass Booster': [5, 5, 4, 4, 3, 2, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    'Treble Booster': [0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 2, 3, 4, 4, 5, 5, 5, 5],
    'Vocal Booster': [-2, -2, -1, 0, 1, 2, 3, 4, 4, 4, 3, 2, 1, 0, -1, -2, -2, -2],
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
    final barModeHeight =
        Responsive.isShort(MediaQuery.sizeOf(context)) ? 200.0 : 290.0;

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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                      child: const Icon(LucideIcons.chevronLeft, color: Colors.white),
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
                      icon: const Icon(LucideIcons.info, color: Colors.white70, size: 20),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        _showEqualizerModeDialog(context, ref);
                      },
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(
                        isGraphMode ? LucideIcons.sliders : LucideIcons.activity,
                        color: Colors.white70,
                        size: 20,
                      ),
                      tooltip: isGraphMode ? 'Switch to Sliders' : 'Switch to Graph',
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        ref.read(equalizerViewModeProvider.notifier).set(!isGraphMode);
                      },
                    ),
                    const Spacer(),
                    // Master Switch
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          eqState.enabled ? 'On' : 'Off',
                          style: AppFonts.jostStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: eqState.enabled ? accentColor : Colors.white38,
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
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                                final isCurrent = _isMatchingPreset(eqState.currentSongGains, presetGains);
                                return _buildPresetChip(
                                  label: name,
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
                              ...ref.watch(customEqPresetsProvider).map((preset) {
                                final isCurrent = _isMatchingPreset(eqState.currentSongGains, preset.gains);
                                return _buildPresetChip(
                                  label: preset.name,
                                  isCurrent: isCurrent,
                                  accentColor: accentColor,
                                  onTap: () {
                                    HapticFeedback.selectionClick();
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
                        const SizedBox(height: 24),
                      ],

                      // Currently Playing Custom Config Details
                      if (song != null) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
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
                                  child: const Icon(LucideIcons.music, color: Colors.white30, size: 20),
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
                                          ? 'Song-specific settings active'
                                          : 'Using global settings default',
                                      style: AppFonts.jostStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: eqState.currentSongHasCustom ? accentColor : Colors.white38,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (eqState.currentSongHasCustom && eqState.enabled)
                                TextButton.icon(
                                  onPressed: () {
                                    HapticFeedback.mediumImpact();
                                    eqNotifier.resetCurrentSongToDefault();
                                  },
                                  icon: Icon(LucideIcons.undo2, color: accentColor, size: 14),
                                  label: Text(
                                    l10n.reset,
                                    style: AppFonts.jostStyle(color: accentColor, fontSize: 12, fontWeight: FontWeight.bold),
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
                            ? 'INTERACTIVE GRAPH (DRAG DOTS VERTICALLY)' 
                            : '18-BAND EQUALIZER (SCROLL HORIZONTALLY)',
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
                              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.02),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
                              ),
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                child: SizedBox(
                                  width: 18 * 45.0, // Ensures plenty of breathing room for 18 sliders
                                  child: Column(
                                    children: [
                                      // dB Labels Row
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                        children: List.generate(18, (index) {
                                          final gain = eqState.currentSongGains[index];
                                          return Expanded(
                                            child: Center(
                                              child: Text(
                                                '${gain.round() > 0 ? "+" : ""}${gain.round()}',
                                                style: AppFonts.jostStyle(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold,
                                                  color: eqState.enabled ? Colors.white60 : Colors.white24,
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
                                                    borderRadius: BorderRadius.circular(24),
                                                    child: CustomPaint(
                                                      painter: EqualizerCurvePainter(
                                                        gains: eqState.currentSongGains.sublist(0, 18),
                                                        color: accentColor,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),

                                            // Sliders Horizontal Layout
                                            Positioned.fill(
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                                children: List.generate(18, (index) {
                                                  return Expanded(
                                                    child: EqualizerSliderTrack(
                                                      gain: eqState.currentSongGains[index],
                                                      enabled: eqState.enabled,
                                                      onChanged: (val) {
                                                        // Snap to zero logic
                                                        double finalizedVal = val;
                                                        if (val.abs() < 0.8) {
                                                          finalizedVal = 0.0;
                                                        }

                                                        final oldInt = eqState.currentSongGains[index].round();
                                                        final newInt = finalizedVal.round();

                                                        if (newInt != oldInt) {
                                                          if (newInt == 0) {
                                                            HapticFeedback.mediumImpact(); // Snapped to zero!
                                                          }
                                                        }
                                                        eqNotifier.setBandGain(index, finalizedVal);
                                                      },
                                                      onDragEnd: () {
                                                        eqNotifier.applyEqualizerInstant();
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
                                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                        children: List.generate(18, (index) {
                                          return Expanded(
                                            child: Center(
                                              child: Text(
                                                _bands[index],
                                                style: AppFonts.jostStyle(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w600,
                                                  color: eqState.enabled ? Colors.white60 : Colors.white24,
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
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.02),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Pre-amp Slider
                            if (eqState.enabled) ...[
                              Row(
                                children: [
                                  Icon(LucideIcons.sliders, color: accentColor.withValues(alpha: 0.8), size: 18),
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
                                  inactiveTrackColor: Colors.white.withValues(alpha: 0.08),
                                  thumbColor: Colors.white,
                                  trackHeight: 3.5,
                                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                                ),
                                child: Slider(
                                  value: eqState.preampGain,
                                  min: -12.0,
                                  max: 12.0,
                                  divisions: 24,
                                  onChanged: (val) {
                                    double finalized = val;
                                    if (val.abs() < 0.5) finalized = 0.0;
                                    if (eqState.preampGain.round() != finalized.round() && finalized.round() == 0) {
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
                                  ref.watch(playbackProvider.select((s) => s.volume)) == 0
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
                                inactiveTrackColor: Colors.white.withValues(alpha: 0.08),
                                thumbColor: Colors.white,
                                trackHeight: 3.5,
                                overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                              ),
                              child: Slider(
                                value: ref.watch(playbackProvider.select((s) => s.volume)),
                                min: 0.0,
                                max: 1.0,
                                onChanged: (val) {
                                  ref.read(playbackProvider.notifier).setVolume(val);
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
                          title: 'Dynamic Range Compressor',
                          icon: LucideIcons.sliders,
                          trailing: Switch.adaptive(
                            value: eqState.compressorEnabled,
                            activeThumbColor: accentColor,
                            activeTrackColor: accentColor.withValues(alpha: 0.35),
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
                                      title: 'Threshold',
                                      value: eqState.compressorThreshold,
                                      min: -40.0,
                                      max: 0.0,
                                      unit: 'dB',
                                      onChanged: (v) => eqNotifier.setCompressorThreshold(v),
                                    ),
                                    _buildSliderRow(
                                      title: 'Ratio',
                                      value: eqState.compressorRatio,
                                      min: 1.0,
                                      max: 20.0,
                                      unit: ':1',
                                      onChanged: (v) => eqNotifier.setCompressorRatio(v),
                                    ),
                                    _buildSliderRow(
                                      title: 'Attack',
                                      value: eqState.compressorAttack,
                                      min: 0.01,
                                      max: 100.0, // Clamped display range for attack
                                      unit: 'ms',
                                      onChanged: (v) => eqNotifier.setCompressorAttack(v),
                                    ),
                                    _buildSliderRow(
                                      title: 'Release',
                                      value: eqState.compressorRelease,
                                      min: 10.0,
                                      max: 1000.0, // Clamped display range for release
                                      unit: 'ms',
                                      onChanged: (v) => eqNotifier.setCompressorRelease(v),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),

                        // 2. Spatial & Binaural Width
                        DspCard(
                          title: 'Headphone Crossfeed & Width',
                          icon: LucideIcons.headphones,
                          children: [
                            _buildSwitchRow(
                              title: 'Binaural Crossfeed',
                              value: eqState.crossfeedEnabled,
                              onChanged: (val) => eqNotifier.setCrossfeedEnabled(val),
                              accentColor: accentColor,
                            ),
                            if (eqState.crossfeedEnabled)
                              _buildSliderRow(
                                title: 'Crossfeed Strength',
                                value: eqState.crossfeedStrength,
                                min: 0.0,
                                max: 1.0,
                                unit: '',
                                onChanged: (v) => eqNotifier.setCrossfeedStrength(v),
                              ),
                            const SizedBox(height: 12),
                            _buildSwitchRow(
                              title: 'Stereo Widening',
                              value: eqState.stereoWidthEnabled,
                              onChanged: (val) => eqNotifier.setStereoWidthEnabled(val),
                              accentColor: accentColor,
                            ),
                            if (eqState.stereoWidthEnabled)
                              _buildSliderRow(
                                title: 'Widening Factor',
                                value: eqState.stereoWidthFactor,
                                min: -10.0,
                                max: 10.0,
                                unit: 'x',
                                onChanged: (v) => eqNotifier.setStereoWidthFactor(v),
                              ),
                          ],
                        ),

                        // 3. Loudness Normalization
                        DspCard(
                          title: 'Loudness Normalization',
                          icon: LucideIcons.volume2,
                          trailing: Switch.adaptive(
                            value: eqState.loudnormEnabled,
                            activeThumbColor: accentColor,
                            activeTrackColor: accentColor.withValues(alpha: 0.35),
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
                                      title: 'Target Loudness',
                                      value: eqState.loudnormTarget,
                                      min: -30.0,
                                      max: -5.0,
                                      unit: 'LUFS',
                                      onChanged: (v) => eqNotifier.setLoudnormTarget(v),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),

                        // 4. Tone Shelving
                        DspCard(
                          title: 'Tone Shelving (Bass / Treble)',
                          icon: LucideIcons.music4,
                          trailing: Switch.adaptive(
                            value: eqState.shelvingEnabled,
                            activeThumbColor: accentColor,
                            activeTrackColor: accentColor.withValues(alpha: 0.35),
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
                                      title: 'Bass Shelf',
                                      value: eqState.bassGain,
                                      min: -10.0,
                                      max: 15.0,
                                      unit: 'dB',
                                      onChanged: (v) => eqNotifier.setBassGain(v),
                                    ),
                                    _buildSliderRow(
                                      title: 'Treble Shelf',
                                      value: eqState.trebleGain,
                                      min: -10.0,
                                      max: 15.0,
                                      unit: 'dB',
                                      onChanged: (v) => eqNotifier.setTrebleGain(v),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),

                        // 5. Speed & Pitch Rubberband
                        DspCard(
                          title: 'Tempo & Pitch Controls',
                          icon: LucideIcons.gauge,
                          trailing: Switch.adaptive(
                            value: eqState.pitchTempoEnabled,
                            activeThumbColor: accentColor,
                            activeTrackColor: accentColor.withValues(alpha: 0.35),
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
                                      title: 'Pitch Shift',
                                      value: eqState.pitch,
                                      min: 0.5,
                                      max: 2.0,
                                      unit: 'x',
                                      onChanged: (v) => eqNotifier.setPitch(v),
                                    ),
                                    _buildSliderRow(
                                      title: 'Tempo Speed',
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
                          title: 'Voice & Silence controls',
                          icon: LucideIcons.smile,
                          children: [
                            _buildSwitchRow(
                              title: 'Silence Trimming',
                              value: eqState.silenceTrimEnabled,
                              onChanged: (val) => eqNotifier.setSilenceTrimEnabled(val),
                              accentColor: accentColor,
                            ),
                            if (eqState.silenceTrimEnabled)
                              _buildSliderRow(
                                title: 'Silence Threshold',
                                value: eqState.silenceTrimThreshold,
                                min: -60.0,
                                max: -30.0,
                                unit: 'dB',
                                onChanged: (v) => eqNotifier.setSilenceTrimThreshold(v),
                              ),
                            const SizedBox(height: 12),
                            _buildSwitchRow(
                              title: 'Speech Enhancement Filter',
                              value: eqState.speechFilterEnabled,
                              onChanged: (val) => eqNotifier.setSpeechFilterEnabled(val),
                              accentColor: accentColor,
                            ),
                            if (eqState.speechFilterEnabled) ...[
                              _buildSliderRow(
                                title: 'Highpass Cutoff',
                                value: eqState.speechHighpass,
                                min: 100.0,
                                max: 300.0,
                                unit: 'Hz',
                                onChanged: (v) => eqNotifier.setSpeechHighpass(v),
                              ),
                              _buildSliderRow(
                                title: 'Lowpass Cutoff',
                                value: eqState.speechLowpass,
                                min: 3000.0,
                                max: 6000.0,
                                unit: 'Hz',
                                onChanged: (v) => eqNotifier.setSpeechLowpass(v),
                              ),
                            ],
                          ],
                        ),

                        // 7. Creative Retro & Environment Effects
                        DspCard(
                          title: 'Retro & Room Effects',
                          icon: LucideIcons.sparkles,
                          children: [
                            _buildSwitchRow(
                              title: 'Lofi Effect (8-bit Crusher)',
                              value: eqState.lofiEnabled,
                              onChanged: (val) => eqNotifier.setLofiEnabled(val),
                              accentColor: accentColor,
                            ),
                            const SizedBox(height: 12),
                            _buildSwitchRow(
                              title: 'Studio Room Reverb (Echo)',
                              value: eqState.reverbEnabled,
                              onChanged: (val) => eqNotifier.setReverbEnabled(val),
                              accentColor: accentColor,
                            ),
                            const SizedBox(height: 12),
                            _buildSwitchRow(
                              title: 'Virtual 5.1 Surround Sound',
                              value: eqState.surroundEnabled,
                              onChanged: (val) => eqNotifier.setSurroundEnabled(val),
                              accentColor: accentColor,
                            ),
                          ],
                        ),

                        // 8. Custom FFMpeg AF Console
                        DspCard(
                          title: 'Raw FFMpeg Filter console',
                          icon: LucideIcons.terminal,
                          children: [
                            Text(
                              l10n.customFilterHint,
                              style: AppFonts.jostStyle(fontSize: 12, color: Colors.white54),
                            ),
                            const SizedBox(height: 12),
                            _CustomFilterInput(
                              initialValue: eqState.customFilterString,
                              onSubmitted: (filter) => eqNotifier.setCustomFilterString(filter),
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
                          border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
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
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: (song != null && eqState.currentSongHasCustom)
                                        ? accentColor.withValues(alpha: 0.15)
                                        : Colors.white.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: (song != null && eqState.currentSongHasCustom)
                                          ? accentColor
                                          : Colors.white.withValues(alpha: 0.1),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    (song != null && eqState.currentSongHasCustom)
                                        ? 'Song-Specific'
                                        : 'Global Default',
                                    style: AppFonts.jostStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: (song != null && eqState.currentSongHasCustom)
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
                                            await eqNotifier.applyCurrentGainsToGlobal();
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    l10n.currentGainsAppliedGlobal,
                                                    style: AppFonts.jostStyle(color: Colors.white),
                                                  ),
                                                  backgroundColor: accentColor,
                                                ),
                                              );
                                            }
                                          }
                                        : null,
                                    icon: Icon(LucideIcons.globe, size: 14, color: eqState.enabled ? accentColor : Colors.white24),
                                    label: Text(
                                      l10n.applyToGlobal,
                                      style: AppFonts.jostStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: eqState.enabled ? Colors.white : Colors.white24,
                                      ),
                                    ),
                                    style: TextButton.styleFrom(
                                      backgroundColor: eqState.enabled
                                          ? Colors.white.withValues(alpha: 0.04)
                                          : Colors.transparent,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                                if (song != null && eqState.currentSongHasCustom && eqState.enabled) ...[
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextButton.icon(
                                      onPressed: () async {
                                        HapticFeedback.mediumImpact();
                                        await eqNotifier.resetCurrentSongToDefault();
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                l10n.songSpecificResetGlobal,
                                                style: AppFonts.jostStyle(color: Colors.white),
                                              ),
                                              backgroundColor: accentColor,
                                            ),
                                          );
                                        }
                                      },
                                      icon: Icon(LucideIcons.undo2, size: 14, color: accentColor),
                                      label: Text(
                                        l10n.resetToGlobal,
                                        style: AppFonts.jostStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      style: TextButton.styleFrom(
                                        backgroundColor: Colors.white.withValues(alpha: 0.04),
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
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
                                    backgroundColor: isPureBlack ? Colors.black : const Color(0xFF1E1E1E),
                                    title: Text(
                                      l10n.resetAllSongsEq,
                                      style: AppFonts.jostStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
                                          style: AppFonts.jostStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
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
                                          style: AppFonts.jostStyle(color: Colors.white),
                                        ),
                                        backgroundColor: Colors.redAccent,
                                      ),
                                    );
                                  }
                                }
                              },
                              icon: const Icon(LucideIcons.trash2, size: 14, color: Colors.redAccent),
                              label: Text(
                                l10n.resetAllSongsEqData,
                                style: AppFonts.jostStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.redAccent,
                                ),
                              ),
                              style: TextButton.styleFrom(
                                backgroundColor: Colors.redAccent.withValues(alpha: 0.08),
                                padding: const EdgeInsets.symmetric(vertical: 12),
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
                        'Edits made when a song is playing apply to that song only. To set the global default, edit when no song is playing, or use the \'Apply to Global\' action.',
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

  bool _isMatchingPreset(List<double> current, List<double> preset) {
    for (int i = 0; i < 18; i++) {
      final curGain = i < current.length ? current[i] : 0.0;
      final preGain = i < preset.length ? preset[i] : 0.0;
      if ((curGain - preGain).abs() > 0.5) return false;
    }
    return true;
  }

  // Shared visual for every preset pill (built-in, custom, and the "save"
  // action) so the three don't drift out of sync with each other.
  Widget _buildPresetChip({
    required String label,
    required bool isCurrent,
    required Color accentColor,
    required VoidCallback onTap,
    VoidCallback? onLongPress,
    IconData? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isCurrent
                ? accentColor.withValues(alpha: 0.15)
                : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isCurrent ? accentColor : Colors.white.withValues(alpha: 0.08),
              width: 1,
            ),
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 14, color: isCurrent ? accentColor : Colors.white70),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: AppFonts.jostStyle(
                    fontSize: 13,
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                    color: isCurrent ? accentColor : Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSavePresetChip(
    BuildContext context,
    WidgetRef ref,
    EqualizerState eqState,
    Color accentColor,
  ) {
    return _buildPresetChip(
      label: 'Save',
      icon: LucideIcons.plus,
      isCurrent: false,
      accentColor: accentColor,
      onTap: () => _promptSaveCustomPreset(context, ref, eqState),
    );
  }

  Future<void> _promptSaveCustomPreset(
    BuildContext context,
    WidgetRef ref,
    EqualizerState eqState,
  ) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Save Preset'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Preset name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (name == null || name.trim().isEmpty) return;
    // Saves the whole current gains array (all bands plus every effect
    // toggle), not just the 18 visible sliders, so recalling it later
    // restores exactly what was heard when it was saved.
    await ref
        .read(customEqPresetsProvider.notifier)
        .save(name, eqState.currentSongGains);
  }

  Future<void> _confirmDeleteCustomPreset(
    BuildContext context,
    WidgetRef ref,
    String name,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Preset'),
        content: Text('Delete the "$name" preset?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(customEqPresetsProvider.notifier).delete(name);
    }
  }

  Widget _buildSwitchRow({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color accentColor,
  }) {
    return Row(
      children: [
        Text(
          title,
          style: AppFonts.jostStyle(fontSize: 13, color: Colors.white70, fontWeight: FontWeight.w600),
        ),
        const Spacer(),
        Switch.adaptive(
          value: value,
          activeThumbColor: accentColor,
          activeTrackColor: accentColor.withValues(alpha: 0.35),
          onChanged: (val) {
            HapticFeedback.mediumImpact();
            onChanged(val);
          },
        ),
      ],
    );
  }

  Widget _buildSliderRow({
    required String title,
    required double value,
    required double min,
    required double max,
    required String unit,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                title,
                style: AppFonts.jostStyle(fontSize: 12, color: Colors.white54),
              ),
              const Spacer(),
              Text(
                '${value.toStringAsFixed(1)} $unit',
                style: AppFonts.jostStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: Colors.white24,
              inactiveTrackColor: Colors.white.withValues(alpha: 0.05),
              thumbColor: Colors.white,
              trackHeight: 2.0,
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

void _showEqualizerModeDialog(BuildContext context, WidgetRef ref) {
  showModalBottomSheet(
    context: context,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black54,
    builder: (context) {
      final l10n = AppLocalizations.of(context)!;
      final settings = ref.watch(settingsProvider);
      final accentColor = Color(settings.accentColor);
      final isGlobal = settings.equalizerGlobalMode;

      return AppBottomSheetContainer(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(LucideIcons.sliders, color: accentColor, size: 22),
                const SizedBox(width: 12),
                Text(
                  l10n.equalizerTargetMode,
                  style: AppFonts.jostStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              l10n.equalizerTargetModeDesc,
              style: AppFonts.jostStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 20),

            // Global Mode Card
            Container(
              decoration: BoxDecoration(
                color: isGlobal 
                    ? accentColor.withValues(alpha: 0.08) 
                    : settings.darkTheme 
                        ? Colors.white.withValues(alpha: 0.03) 
                        : const Color(0xFF1E1E1B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isGlobal ? accentColor.withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.08),
                  width: isGlobal ? 1.5 : 1.0,
                ),
              ),
              child: PremiumSection(
                borderRadius: BorderRadius.circular(16),
                padding: const EdgeInsets.all(16),
                useExpanded: false,
                useCenter: false,
                forceTransparent: true,
                onTap: () async {
                  HapticFeedback.mediumImpact();
                  await ref.read(settingsProvider.notifier).updateEqualizerGlobalMode(true);
                  final currentSong = ref.read(playbackProvider).currentSong;
                  ref.read(equalizerProvider.notifier).onSongChanged(currentSong);
                  ref.read(equalizerProvider.notifier).applyEqualizerInstant();
                  Navigator.of(context).pop();
                },
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isGlobal ? accentColor.withValues(alpha: 0.15) : Colors.white10,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        LucideIcons.globe,
                        color: isGlobal ? accentColor : Colors.white60,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                l10n.globalMode,
                                style: AppFonts.jostStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              if (isGlobal) ...[
                                const Spacer(),
                                Icon(LucideIcons.check, color: accentColor, size: 18),
                              ],
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            l10n.globalModeDesc,
                            style: AppFonts.jostStyle(
                              fontSize: 13,
                              color: Colors.white60,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Song-Specific Mode Card
            Container(
              decoration: BoxDecoration(
                color: !isGlobal 
                    ? accentColor.withValues(alpha: 0.08) 
                    : settings.darkTheme 
                        ? Colors.white.withValues(alpha: 0.03) 
                        : const Color(0xFF1E1E1B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: !isGlobal ? accentColor.withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.08),
                  width: !isGlobal ? 1.5 : 1.0,
                ),
              ),
              child: PremiumSection(
                borderRadius: BorderRadius.circular(16),
                padding: const EdgeInsets.all(16),
                useExpanded: false,
                useCenter: false,
                forceTransparent: true,
                onTap: () async {
                  HapticFeedback.mediumImpact();
                  await ref.read(settingsProvider.notifier).updateEqualizerGlobalMode(false);
                  final currentSong = ref.read(playbackProvider).currentSong;
                  ref.read(equalizerProvider.notifier).onSongChanged(currentSong);
                  ref.read(equalizerProvider.notifier).applyEqualizerInstant();
                  Navigator.of(context).pop();
                },
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: !isGlobal ? accentColor.withValues(alpha: 0.15) : Colors.white10,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        LucideIcons.music,
                        color: !isGlobal ? accentColor : Colors.white60,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                l10n.songSpecificMode,
                                style: AppFonts.jostStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              if (!isGlobal) ...[
                                const Spacer(),
                                Icon(LucideIcons.check, color: accentColor, size: 18),
                              ],
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            l10n.songSpecificModeDesc,
                            style: AppFonts.jostStyle(
                              fontSize: 13,
                              color: Colors.white60,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Button to view Audio capabilities
            TextButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                _showAudioCapabilitiesSheet(context, ref);
              },
              icon: Icon(LucideIcons.activity, color: accentColor.withValues(alpha: 0.7), size: 16),
              label: Text(
                l10n.viewDeviceAudioCapabilities,
                style: AppFonts.jostStyle(
                  fontSize: 13,
                  color: accentColor.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

void _showAudioCapabilitiesSheet(BuildContext context, WidgetRef ref) {
  showModalBottomSheet(
    context: context,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black54,
    builder: (context) {
      final settings = ref.read(settingsProvider);
      final accentColor = Color(settings.accentColor);

      return FutureBuilder<Map<String, String>>(
        future: ref.read(audioServiceProvider).getAudioOutputCapabilities(),
        builder: (context, snapshot) {
          final l10n = AppLocalizations.of(context)!;
          final capabilities = snapshot.data ?? {};
          return AppBottomSheetContainer(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(LucideIcons.activity, color: accentColor, size: 22),
                    const SizedBox(width: 12),
                    Text(
                      l10n.deviceAudioCapabilities,
                      style: AppFonts.jostStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: Colors.white10),
                const SizedBox(height: 12),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 30),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (capabilities.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 30),
                    child: Text(
                      l10n.noPlaybackActiveCapabilities,
                      style: AppFonts.jostStyle(color: Colors.white38, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  Flexible(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        children: capabilities.entries.map((entry) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Row(
                              children: [
                                Text(
                                  entry.key,
                                  style: AppFonts.jostStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w500),
                                ),
                                const Spacer(),
                                Text(
                                  entry.value,
                                  style: AppFonts.jostStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      );
    },
  );
}

class DspCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final Widget? trailing;
  final List<Widget> children;
  final bool initialExpanded;

  const DspCard({
    required this.title,
    required this.icon,
    this.trailing,
    required this.children,
    this.initialExpanded = false,
    super.key,
  });

  @override
  State<DspCard> createState() => _DspCardState();
}

class _DspCardState extends State<DspCard> {
  late bool _expanded = widget.initialExpanded;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                _expanded = !_expanded;
              });
            },
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  Icon(widget.icon, color: Colors.white70, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    widget.title,
                    style: AppFonts.jostStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  if (widget.trailing != null) widget.trailing!,
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    duration: const Duration(milliseconds: 200),
                    turns: _expanded ? 0.5 : 0,
                    child: const Icon(LucideIcons.chevronDown, color: Colors.white30, size: 18),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: widget.children,
              ),
            ),
            crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
}

class _CustomFilterInput extends StatefulWidget {
  final String initialValue;
  final ValueChanged<String> onSubmitted;
  final Color accentColor;

  const _CustomFilterInput({
    required this.initialValue,
    required this.onSubmitted,
    required this.accentColor,
  });

  @override
  State<_CustomFilterInput> createState() => _CustomFilterInputState();
}

class _CustomFilterInputState extends State<_CustomFilterInput> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            style: AppFonts.jostStyle(fontSize: 13, color: Colors.white),
            decoration: InputDecoration(
              isDense: true,
              hintText: l10n.rawFilterParametersHint,
              hintStyle: AppFonts.jostStyle(fontSize: 13, color: Colors.white30),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.04),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onSubmitted: widget.onSubmitted,
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: () {
            HapticFeedback.mediumImpact();
            widget.onSubmitted(_controller.text);
          },
          icon: Icon(LucideIcons.check, color: widget.accentColor),
          style: IconButton.styleFrom(
            backgroundColor: Colors.white.withValues(alpha: 0.04),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }
}

class EqualizerSliderTrack extends StatelessWidget {
  final double gain;
  final ValueChanged<double> onChanged;
  final VoidCallback? onDragEnd;
  final bool enabled;

  const EqualizerSliderTrack({
    required this.gain,
    required this.onChanged,
    this.onDragEnd,
    required this.enabled,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final percent = ((gain + 20) / 40).clamp(0.0, 1.0);
    final accentColor = Theme.of(context).colorScheme.primary;

    return Opacity(
      opacity: enabled ? 1.0 : 0.35,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final trackHeight = constraints.maxHeight - 16;
          final centerProgressY = trackHeight * 0.5;
          final thumbY = (1.0 - percent) * trackHeight;

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onVerticalDragUpdate: enabled
                ? (details) {
                    final RenderBox renderBox = context.findRenderObject() as RenderBox;
                    final localPos = renderBox.globalToLocal(details.globalPosition);
                    final dragY = (localPos.dy - 8).clamp(0.0, trackHeight);
                    final newPercent = (1.0 - (dragY / trackHeight)).clamp(0.0, 1.0);
                    onChanged((newPercent * 40.0) - 20.0);
                  }
                : null,
            onVerticalDragEnd: enabled ? (_) => onDragEnd?.call() : null,
            onVerticalDragCancel: enabled ? () => onDragEnd?.call() : null,
            onTapDown: enabled
                ? (details) {
                    final RenderBox renderBox = context.findRenderObject() as RenderBox;
                    final localPos = renderBox.globalToLocal(details.globalPosition);
                    final dragY = (localPos.dy - 8).clamp(0.0, trackHeight);
                    final newPercent = (1.0 - (dragY / trackHeight)).clamp(0.0, 1.0);
                    onChanged((newPercent * 40.0) - 20.0);
                  }
                : null,
            onTapUp: enabled ? (_) => onDragEnd?.call() : null,
            child: SizedBox(
              width: 32,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Full background pill
                  Container(
                    width: 6,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  // Center zero line
                  Positioned(
                    top: centerProgressY + 8,
                    child: Container(
                      width: 14,
                      height: 1.5,
                      color: Colors.white30,
                    ),
                  ),
                  // Active fill from center
                  Positioned(
                    top: percent >= 0.5 ? thumbY + 8 : centerProgressY + 8,
                    bottom: percent >= 0.5 ? trackHeight - centerProgressY + 8 : trackHeight - thumbY + 8,
                    child: Container(
                      width: 6,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            accentColor,
                            accentColor.withValues(alpha: 0.6),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  // Thumb Handle
                  Positioned(
                    top: thumbY,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          if (enabled)
                            BoxShadow(
                              color: accentColor.withValues(alpha: 0.4),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                        ],
                        border: Border.all(
                          color: accentColor,
                          width: 3,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class EqualizerCurvePainter extends CustomPainter {
  final List<double> gains;
  final Color color;

  EqualizerCurvePainter({required this.gains, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (gains.length < 2) return;

    final paint = Paint()
      ..color = color.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()..style = PaintingStyle.fill;

    final path = Path();
    final colWidth = size.width / gains.length;

    final trackTop = 8.0;
    final trackBottom = size.height - 8.0;
    final trackHeight = trackBottom - trackTop;

    double getMappedY(double gain) {
      final percent = ((gain + 20) / 40).clamp(0.0, 1.0);
      final thumbBottom = percent * trackHeight;
      return trackBottom - thumbBottom;
    }

    double getMappedX(int index) {
      return (index + 0.5) * colWidth;
    }

    path.moveTo(getMappedX(0), getMappedY(gains[0]));

    for (int i = 0; i < gains.length - 1; i++) {
      final x1 = getMappedX(i);
      final y1 = getMappedY(gains[i]);
      final x2 = getMappedX(i + 1);
      final y2 = getMappedY(gains[i + 1]);

      final stepX = x2 - x1;
      final cx1 = x1 + stepX / 2;
      final cy1 = y1;
      final cx2 = x2 - stepX / 2;
      final cy2 = y2;

      path.cubicTo(cx1, cy1, cx2, cy2, x2, y2);
    }

    // Shadow glow
    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    canvas.drawPath(path, paint);

    // Fill under path
    final fillPath = Path.from(path)
      ..lineTo(getMappedX(gains.length - 1), trackBottom)
      ..lineTo(getMappedX(0), trackBottom)
      ..close();

    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        color.withValues(alpha: 0.12),
        color.withValues(alpha: 0.0),
      ],
    );
    fillPaint.shader = gradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(fillPath, fillPaint);
  }

  @override
  bool shouldRepaint(EqualizerCurvePainter oldDelegate) {
    // gains is a freshly-built sublist() on every call site, so comparing
    // with != (identity, for a plain List) was always true regardless of
    // whether the visible curve actually changed - listEquals compares the
    // values instead, so an unrelated EqualizerState change (e.g. toggling
    // an effect that isn't one of these 18 bands) no longer repaints.
    return !listEquals(oldDelegate.gains, gains) || oldDelegate.color != color;
  }
}

class InteractiveEqualizerGraph extends ConsumerStatefulWidget {
  final EqualizerState eqState;
  final Equalizer eqNotifier;
  final Color accentColor;

  const InteractiveEqualizerGraph({
    required this.eqState,
    required this.eqNotifier,
    required this.accentColor,
    super.key,
  });

  @override
  ConsumerState<InteractiveEqualizerGraph> createState() =>
      _InteractiveEqualizerGraphState();
}

class _InteractiveEqualizerGraphState
    extends ConsumerState<InteractiveEqualizerGraph> {
  int? _activeDragIndex;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final graphHeight =
            Responsive.isShort(MediaQuery.sizeOf(context)) ? 200.0 : 290.0;
        final size = Size(constraints.maxWidth, graphHeight);
        final colWidth = size.width / 18;
        final trackTop = 16.0;
        final trackBottom = size.height - 24.0;
        final trackHeight = trackBottom - trackTop;

        return Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (event) {
            if (!widget.eqState.enabled) return;
            HapticFeedback.selectionClick();
            final localPos = event.localPosition;
            final index = (localPos.dx / colWidth).floor().clamp(0, 17);
            setState(() {
              _activeDragIndex = index;
            });
            _updateGain(index, localPos.dy, trackTop, trackBottom, trackHeight);
          },
          onPointerMove: (event) {
            if (_activeDragIndex == null) return;
            final localPos = event.localPosition;
            _updateGain(_activeDragIndex!, localPos.dy, trackTop, trackBottom, trackHeight);
          },
          onPointerUp: (event) {
            if (_activeDragIndex != null) {
              widget.eqNotifier.applyEqualizerInstant();
              setState(() {
                _activeDragIndex = null;
              });
            }
          },
          onPointerCancel: (event) {
            if (_activeDragIndex != null) {
              widget.eqNotifier.applyEqualizerInstant();
              setState(() {
                _activeDragIndex = null;
              });
            }
          },
          child: Container(
            height: graphHeight,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
            ),
            child: CustomPaint(
              size: size,
              painter: _InteractiveGraphPainter(
                gains: widget.eqState.currentSongGains.sublist(0, 18),
                accentColor: widget.accentColor,
                enabled: widget.eqState.enabled,
                activeDragIndex: _activeDragIndex,
              ),
            ),
          ),
        );
      },
    );
  }

  void _updateGain(int index, double dy, double trackTop, double trackBottom, double trackHeight) {
    final localY = dy.clamp(trackTop, trackBottom);
    final percent = (trackBottom - localY) / trackHeight;
    double gain = (percent * 40.0) - 20.0;
    
    // Snap to zero logic
    if (gain.abs() < 0.8) {
      gain = 0.0;
    }
    
    widget.eqNotifier.setBandGain(index, gain);
  }
}

class _InteractiveGraphPainter extends CustomPainter {
  final List<double> gains;
  final Color accentColor;
  final bool enabled;
  final int? activeDragIndex;

  _InteractiveGraphPainter({
    required this.gains,
    required this.accentColor,
    required this.enabled,
    this.activeDragIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final colWidth = size.width / 18;
    final trackTop = 16.0;
    final trackBottom = size.height - 24.0;
    final trackHeight = trackBottom - trackTop;

    double getMappedY(double gain) {
      final percent = ((gain + 20) / 40).clamp(0.0, 1.0);
      final thumbBottom = percent * trackHeight;
      return trackBottom - thumbBottom;
    }

    double getMappedX(int index) {
      return (index + 0.5) * colWidth;
    }

    // 1. Draw grid lines (dB)
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 1.0;

    final dashedPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..strokeWidth = 1.2;

    const dbValues = [-20.0, -10.0, 0.0, 10.0, 20.0];
    for (final db in dbValues) {
      final y = getMappedY(db);
      if (db == 0.0) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), dashedPaint);
      } else {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
      }

      // Draw dB Label text
      final textPainter = TextPainter(
        text: TextSpan(
          text: '${db > 0 ? "+" : ""}${db.round()} dB',
          style: AppFonts.jostStyle(
            fontSize: 9,
            color: Colors.white24,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, Offset(8, y - textPainter.height - 2));
    }

    // 2. Draw vertical grid/frequencies lines
    const List<String> bands = [
      '65', '92', '131', '185', '262', '370', '523', '740', '1k', '1.4k',
      '2k', '2.9k', '4.1k', '5.9k', '8.3k', '11.7k', '16.6k', '20k'
    ];
    for (int i = 0; i < 18; i++) {
      final x = getMappedX(i);
      // Freq vertical line (drawn extremely faintly)
      canvas.drawLine(
        Offset(x, trackTop),
        Offset(x, trackBottom),
        Paint()..color = Colors.white.withValues(alpha: 0.02)..strokeWidth = 1.0,
      );

      // Freq label at bottom
      final textPainter = TextPainter(
        text: TextSpan(
          text: bands[i],
          style: AppFonts.jostStyle(
            fontSize: 8,
            color: enabled ? Colors.white30 : Colors.white12,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, Offset(x - textPainter.width / 2, size.height - 18));
    }

    if (gains.length < 2) return;

    // 3. Draw smooth curve path
    final curveColor = enabled ? accentColor : Colors.grey;
    final path = Path();
    path.moveTo(getMappedX(0), getMappedY(gains[0]));

    for (int i = 0; i < gains.length - 1; i++) {
      final x1 = getMappedX(i);
      final y1 = getMappedY(gains[i]);
      final x2 = getMappedX(i + 1);
      final y2 = getMappedY(gains[i + 1]);

      final stepX = x2 - x1;
      final cx1 = x1 + stepX / 2;
      final cy1 = y1;
      final cx2 = x2 - stepX / 2;
      final cy2 = y2;

      path.cubicTo(cx1, cy1, cx2, cy2, x2, y2);
    }

    // Shadow glow
    canvas.drawPath(
      path,
      Paint()
        ..color = curveColor.withValues(alpha: 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    // Stroke
    canvas.drawPath(
      path,
      Paint()
        ..color = curveColor.withValues(alpha: 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );

    // Fill under path
    final fillPath = Path.from(path)
      ..lineTo(getMappedX(gains.length - 1), trackBottom)
      ..lineTo(getMappedX(0), trackBottom)
      ..close();

    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        curveColor.withValues(alpha: 0.12),
        curveColor.withValues(alpha: 0.0),
      ],
    );
    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = gradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(fillPath, fillPaint);

    // 4. Draw interactive node handles
    final handlePaint = Paint()
      ..color = curveColor.withValues(alpha: enabled ? 1.0 : 0.4)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < gains.length; i++) {
      final x = getMappedX(i);
      final y = getMappedY(gains[i]);
      final isDragged = i == activeDragIndex;

      if (isDragged && enabled) {
        // Draw selection outer ring
        canvas.drawCircle(
          Offset(x, y),
          12,
          Paint()
            ..color = curveColor.withValues(alpha: 0.3)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
      }

      // Draw dot handle
      canvas.drawCircle(Offset(x, y), isDragged ? 6.0 : 4.5, handlePaint);

      // Draw inner core
      canvas.drawCircle(Offset(x, y), isDragged ? 2.5 : 1.8, Paint()..color = Colors.black..style = PaintingStyle.fill);
    }
  }

  @override
  bool shouldRepaint(covariant _InteractiveGraphPainter oldDelegate) {
    // See the identical note on EqualizerCurvePainter.shouldRepaint above -
    // gains needs a value comparison, not identity, since it's a fresh
    // sublist() every time.
    return !listEquals(oldDelegate.gains, gains) ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.enabled != enabled ||
        oldDelegate.activeDragIndex != activeDragIndex;
  }
}
