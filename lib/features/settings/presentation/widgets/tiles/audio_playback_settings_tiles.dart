import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:looper_player/core/theme/app_fonts.dart';
import 'package:looper_player/features/settings/presentation/providers/settings_notifier.dart';
import 'package:looper_player/l10n/app_localizations.dart';
import '../settings_widgets.dart';

class FadePlayPauseStopTile extends ConsumerWidget {
  const FadePlayPauseStopTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final l10n = AppLocalizations.of(context)!;
    return SwitchListTile(
      secondary: const Icon(LucideIcons.music, color: Colors.white70),
      title: Text(l10n.fadePlayPauseStop, style: _tileTitleStyle()),
      subtitle: Text(l10n.fadePlayPauseStopDesc, style: _tileSubtitleStyle()),
      activeThumbColor: Color(settings.accentColor),
      value: settings.fadePlayPauseStop,
      onChanged: (value) {
        ref.read(settingsProvider.notifier).updateFadePlayPauseStop(value);
      },
    );
  }
}

class FadeDurationSlider extends ConsumerWidget {
  const FadeDurationSlider({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final l10n = AppLocalizations.of(context)!;
    return SettingsSliderTile(
      icon: LucideIcons.sliders,
      title: l10n.fadeDuration,
      subtitle: l10n.fadeDurationDesc,
      value: settings.playPauseStopFadeLength.toDouble(),
      min: 10,
      max: 1000,
      divisions: 99,
      suffix: 'ms',
      onChanged: (value) {
        ref
            .read(settingsProvider.notifier)
            .updatePlayPauseStopFadeLength(value.round());
      },
    );
  }
}

class ManageAudioFocusTile extends ConsumerWidget {
  const ManageAudioFocusTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final l10n = AppLocalizations.of(context)!;
    return SwitchListTile(
      secondary: const Icon(LucideIcons.phoneCall, color: Colors.white70),
      title: Text(l10n.manageAudioFocusTitle, style: _tileTitleStyle()),
      subtitle: Text(l10n.manageAudioFocusDesc, style: _tileSubtitleStyle()),
      activeThumbColor: Color(settings.accentColor),
      value: settings.audioFocus,
      onChanged: (value) {
        ref.read(settingsProvider.notifier).updateAudioFocus(value);
      },
    );
  }
}

class ResumeAfterCallTile extends ConsumerWidget {
  const ResumeAfterCallTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final l10n = AppLocalizations.of(context)!;
    return SwitchListTile(
      secondary: const Icon(LucideIcons.phoneCall, color: Colors.white70),
      title: Text(l10n.resumeAfterCallTitle, style: _tileTitleStyle()),
      subtitle: Text(l10n.resumeAfterCallDesc, style: _tileSubtitleStyle()),
      activeThumbColor: Color(settings.accentColor),
      value: settings.resumeAfterCall,
      onChanged: (value) {
        ref.read(settingsProvider.notifier).updateResumeAfterCall(value);
      },
    );
  }
}

class ResumeOnStartTile extends ConsumerWidget {
  const ResumeOnStartTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final l10n = AppLocalizations.of(context)!;
    return SwitchListTile(
      secondary: const Icon(LucideIcons.power, color: Colors.white70),
      title: Text(l10n.resumeOnStartTitle, style: _tileTitleStyle()),
      subtitle: Text(l10n.resumeOnStartDesc, style: _tileSubtitleStyle()),
      activeThumbColor: Color(settings.accentColor),
      value: settings.resumeOnStart,
      onChanged: (value) {
        ref.read(settingsProvider.notifier).updateResumeOnStart(value);
      },
    );
  }
}

class PersistQueueTile extends ConsumerWidget {
  const PersistQueueTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final l10n = AppLocalizations.of(context)!;
    return SwitchListTile(
      secondary: const Icon(LucideIcons.save, color: Colors.white70),
      title: Text(l10n.persistQueueTitle, style: _tileTitleStyle()),
      subtitle: Text(l10n.persistQueueDesc, style: _tileSubtitleStyle()),
      activeThumbColor: Color(settings.accentColor),
      value: settings.persistQueue,
      onChanged: (value) {
        ref.read(settingsProvider.notifier).updatePersistQueue(value);
      },
    );
  }
}

class KeepSongProgressTile extends ConsumerWidget {
  const KeepSongProgressTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final l10n = AppLocalizations.of(context)!;
    return SwitchListTile(
      secondary: const Icon(LucideIcons.history, color: Colors.white70),
      title: Text(l10n.keepSongProgressTitle, style: _tileTitleStyle()),
      subtitle: Text(l10n.keepSongProgressDesc, style: _tileSubtitleStyle()),
      activeThumbColor: Color(settings.accentColor),
      value: settings.keepSongProgress,
      onChanged: (value) {
        ref.read(settingsProvider.notifier).updateKeepSongProgress(value);
      },
    );
  }
}

class ShuffleTile extends ConsumerWidget {
  const ShuffleTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          secondary: const Icon(LucideIcons.shuffle, color: Colors.white70),
          title: Text(l10n.shuffleTitle, style: _tileTitleStyle()),
          subtitle: Text(
            settings.shuffle
                ? l10n.shuffleEnabledDesc
                : l10n.shuffleDisabledDesc,
            style: _tileSubtitleStyle(),
          ),
          activeThumbColor: Color(settings.accentColor),
          value: settings.shuffle,
          onChanged: (value) {
            ref.read(settingsProvider.notifier).updateShuffle(value);
          },
        ),
        Padding(
          padding: const EdgeInsets.only(left: 72, right: 16, bottom: 12),
          child: Text(
            l10n.shuffleSwitchingDesc,
            style: AppFonts.jostStyle(
              color: Colors.white30,
              fontSize: 11,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }
}

class ResumeOnBluetoothConnectTile extends ConsumerWidget {
  const ResumeOnBluetoothConnectTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final l10n = AppLocalizations.of(context)!;
    return SwitchListTile(
      secondary: const Icon(LucideIcons.bluetooth, color: Colors.white70),
      title: Text(l10n.resumeOnBluetoothConnectTitle, style: _tileTitleStyle()),
      subtitle: Text(
        l10n.resumeOnBluetoothConnectDesc,
        style: _tileSubtitleStyle(),
      ),
      activeThumbColor: Color(settings.accentColor),
      value: settings.resumeOnBluetoothConnect,
      onChanged: (value) {
        ref
            .read(settingsProvider.notifier)
            .updateResumeOnBluetoothConnect(value);
      },
    );
  }
}

TextStyle _tileTitleStyle() =>
    AppFonts.jostStyle(color: Colors.white, fontWeight: FontWeight.w500);

TextStyle _tileSubtitleStyle() =>
    AppFonts.jostStyle(color: Colors.white54, fontSize: 12);
