import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:looper_player/core/theme/app_fonts.dart';
import 'package:looper_player/features/settings/presentation/providers/settings_notifier.dart';
import 'package:looper_player/l10n/app_localizations.dart';
import 'package:looper_player/ui/android/player/equalizer/android_equalizer_screen.dart';

class LanguageTile extends ConsumerWidget {
  const LanguageTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final l10n = AppLocalizations.of(context)!;
    return ListTile(
      leading: const Icon(LucideIcons.languages, color: Colors.white70),
      title: Text(l10n.language, style: _tileTitleStyle()),
      trailing: DropdownButton<String>(
        value: settings.language,
        dropdownColor: const Color(0xFF1A1A1A),
        underline: const SizedBox(),
        items: [
          DropdownMenuItem(
            value: '',
            child: Text(
              l10n.systemDefault,
              style: AppFonts.jostStyle(color: Colors.white),
            ),
          ),
          DropdownMenuItem(
            value: 'en',
            child: Text(
              'English',
              style: AppFonts.jostStyle(color: Colors.white),
            ),
          ),
          DropdownMenuItem(
            value: 'es',
            child: Text(
              'Español',
              style: AppFonts.jostStyle(color: Colors.white),
            ),
          ),
          DropdownMenuItem(
            value: 'fr',
            child: Text(
              'Français',
              style: AppFonts.jostStyle(color: Colors.white),
            ),
          ),
          DropdownMenuItem(
            value: 'de',
            child: Text(
              'Deutsch',
              style: AppFonts.jostStyle(color: Colors.white),
            ),
          ),
          DropdownMenuItem(
            value: 'pt',
            child: Text(
              'Português',
              style: AppFonts.jostStyle(color: Colors.white),
            ),
          ),
          DropdownMenuItem(
            value: 'ru',
            child: Text(
              'Русский',
              style: AppFonts.jostStyle(color: Colors.white),
            ),
          ),
          DropdownMenuItem(
            value: 'it',
            child: Text(
              'Italiano',
              style: AppFonts.jostStyle(color: Colors.white),
            ),
          ),
          DropdownMenuItem(
            value: 'zh',
            child: Text('中文', style: AppFonts.jostStyle(color: Colors.white)),
          ),
          DropdownMenuItem(
            value: 'ja',
            child: Text('日本語', style: AppFonts.jostStyle(color: Colors.white)),
          ),
          DropdownMenuItem(
            value: 'ko',
            child: Text('한국어', style: AppFonts.jostStyle(color: Colors.white)),
          ),
          DropdownMenuItem(
            value: 'ar',
            child: Text(
              'العربية',
              style: AppFonts.jostStyle(color: Colors.white),
            ),
          ),
          DropdownMenuItem(
            value: 'tr',
            child: Text(
              'Türkçe',
              style: AppFonts.jostStyle(color: Colors.white),
            ),
          ),
          DropdownMenuItem(
            value: 'nl',
            child: Text(
              'Nederlands',
              style: AppFonts.jostStyle(color: Colors.white),
            ),
          ),
          DropdownMenuItem(
            value: 'hi',
            child: Text(
              'हिन्दी',
              style: AppFonts.jostStyle(color: Colors.white),
            ),
          ),
        ],
        onChanged: (lang) {
          if (lang != null) {
            ref.read(settingsProvider.notifier).updateLanguage(lang);
          }
        },
      ),
    );
  }
}

class FluidPlayerTile extends ConsumerWidget {
  const FluidPlayerTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final l10n = AppLocalizations.of(context)!;
    return SwitchListTile(
      secondary: const Icon(LucideIcons.move, color: Colors.white70),
      title: Text(l10n.fluidPlayer, style: _tileTitleStyle()),
      subtitle: Text(l10n.fluidPlayerDesc, style: _tileSubtitleStyle()),
      activeThumbColor: Color(settings.accentColor),
      value: settings.enableSlideGesture,
      onChanged: (value) {
        ref.read(settingsProvider.notifier).updateEnableSlideGesture(value);
      },
    );
  }
}

class StopServiceTile extends ConsumerWidget {
  const StopServiceTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final l10n = AppLocalizations.of(context)!;
    return SwitchListTile(
      secondary: const Icon(LucideIcons.power, color: Colors.white70),
      title: Text(l10n.stopServiceOnAppDismissal, style: _tileTitleStyle()),
      subtitle: Text(
        l10n.stopServiceOnAppDismissalDesc,
        style: _tileSubtitleStyle(),
      ),
      activeThumbColor: Color(settings.accentColor),
      value: settings.stopOnTaskRemoved,
      onChanged: (value) {
        ref.read(settingsProvider.notifier).updateStopOnTaskRemoved(value);
      },
    );
  }
}

class InternetModeTile extends ConsumerWidget {
  const InternetModeTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final l10n = AppLocalizations.of(context)!;
    return SwitchListTile(
      secondary: const Icon(LucideIcons.globe, color: Colors.white70),
      title: Text(l10n.internetMode, style: _tileTitleStyle()),
      subtitle: Text(l10n.enableNetworkLyricsArt, style: _tileSubtitleStyle()),
      activeThumbColor: Color(settings.accentColor),
      value: settings.enableInternet,
      onChanged: (value) {
        ref.read(settingsProvider.notifier).updateEnableInternet(value);
      },
    );
  }
}

class DownloadMissingArtworkTile extends ConsumerWidget {
  const DownloadMissingArtworkTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final l10n = AppLocalizations.of(context)!;
    return SwitchListTile(
      secondary: const Icon(LucideIcons.image, color: Colors.white70),
      title: Text(l10n.downloadMissingArtwork, style: _tileTitleStyle()),
      subtitle: Text(
        l10n.downloadMissingArtworkDesc,
        style: _tileSubtitleStyle(),
      ),
      activeThumbColor: Color(settings.accentColor),
      value: settings.downloadArtwork,
      onChanged: (value) {
        ref.read(settingsProvider.notifier).updateDownloadArtwork(value);
      },
    );
  }
}

class EqualizerTile extends ConsumerWidget {
  const EqualizerTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final l10n = AppLocalizations.of(context)!;
    return ListTile(
      leading: const Icon(LucideIcons.sliders, color: Colors.white70),
      title: Text(l10n.equalizer, style: _tileTitleStyle()),
      subtitle: Text(
        settings.equalizerEnabled ? l10n.equalizerEnabled18Band : l10n.disabled,
        style: _tileSubtitleStyle(),
      ),
      trailing: const Icon(LucideIcons.chevronRight, color: Colors.white38),
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          backgroundColor: Colors.transparent,
          builder: (context) => const AndroidEqualizerScreen(),
        );
      },
    );
  }
}

TextStyle _tileTitleStyle() =>
    AppFonts.jostStyle(color: Colors.white, fontWeight: FontWeight.w500);

TextStyle _tileSubtitleStyle() =>
    AppFonts.jostStyle(color: Colors.white54, fontSize: 12);
