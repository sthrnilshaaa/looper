import 'dart:io';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:looper_player/features/library/domain/models/models.dart';
import 'package:looper_player/features/settings/presentation/settings_notifier.dart';
import 'package:adaptive_palette/adaptive_palette.dart';
import 'package:looper_player/features/playback/presentation/playback_notifier.dart';

part 'theme_provider.g.dart';

class ThemeState {
  final ColorScheme colorScheme;
  final bool isDynamic;

  ThemeState({required this.colorScheme, this.isDynamic = true});

  ThemeState copyWith({ColorScheme? colorScheme, bool? isDynamic}) {
    return ThemeState(
      colorScheme: colorScheme ?? this.colorScheme,
      isDynamic: isDynamic ?? this.isDynamic,
    );
  }
}

// Named 'AppTheme' (not 'Theme') to avoid colliding with Flutter's own
// Theme widget - `name: 'theme'` keeps the generated provider as
// `themeProvider`, matching every existing call site.
@Riverpod(keepAlive: true, name: 'themeProvider')
class AppTheme extends _$AppTheme {
  late AppSettings _settings;
  bool _isUpdating = false;

  @override
  ThemeState build() {
    // Use read here to avoid the re-creation loop
    _settings = ref.read(settingsProvider);

    // Watch current song and update theme if dynamic theming or dynamic
    // accent color is enabled
    ref.listen(playbackProvider, (previous, next) {
      final currentSettings = ref.read(settingsProvider);
      if ((currentSettings.enableDynamicTheming ||
              currentSettings.dynamicAccentColor) &&
          next.currentSong?.artPath != previous?.currentSong?.artPath) {
        updateFromImage(next.currentSong?.artPath);
      }
    });

    // Handle settings changes without re-creating the notifier
    ref.listen(settingsProvider, (previous, next) {
      updateSettings(next);
    });

    return ThemeState(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Color(_settings.accentColor),
        primary: Color(_settings.accentColor),
        surface: _settings.darkTheme
            ? Colors.black
            : const Color(0xFF11110E),
        surfaceContainer: _settings.darkTheme
            ? const Color(0xFF0A0A0A)
            : const Color(0xFF1E1E1E),
        brightness: Brightness.dark,
      ),
    );
  }

  // Update internal settings reference when they change
  void updateSettings(AppSettings newSettings) {
    if (_isUpdating) return; // Prevent loop during dynamic update

    final oldSettings = _settings;
    _settings = newSettings;

    // Handle theme reset logic
    if (!newSettings.enableDynamicTheming) {
      if (oldSettings.enableDynamicTheming ||
          oldSettings.darkTheme != newSettings.darkTheme ||
          oldSettings.accentColor != newSettings.accentColor) {
        _resetTheme();
      } else if (!oldSettings.dynamicAccentColor &&
          newSettings.dynamicAccentColor) {
        final playback = ref.read(playbackProvider);
        updateFromImage(playback.currentSong?.artPath);
      }
    } else {
      if (!oldSettings.enableDynamicTheming) {
        final playback = ref.read(playbackProvider);
        updateFromImage(playback.currentSong?.artPath);
      } else if (oldSettings.accentColor != newSettings.accentColor) {
        final playback = ref.read(playbackProvider);
        if (playback.currentSong == null) {
          _resetTheme();
        }
      }
    }
  }

  Future<void> updateFromImage(String? imagePath) async {
    if (imagePath == null) {
      return;
    }

    try {
      _isUpdating = true;
      final file = File(imagePath);
      if (!await file.exists()) {
        _isUpdating = false;
        return;
      }

      final colors = await FluidPaletteExtractor.extractColors(
        FileImage(file),
        count: 1,
      );

      Color? vibrantColor = colors.isNotEmpty ? colors.first : null;

      if (vibrantColor != null) {
        // Brighten the extracted color to make it pop as an accent color on dark backgrounds
        final HSLColor hsl = HSLColor.fromColor(vibrantColor);
        double newLightness = hsl.lightness + 0.15;
        if (newLightness < 0.60) {
          newLightness = 0.60;
        }
        newLightness = newLightness.clamp(0.0, 0.95);
        final brighterColor = hsl.withLightness(newLightness).toColor();

        vibrantColor = brighterColor;

        // Update the state
        final surfaceColor = _settings.darkTheme
            ? Colors.black
            : const Color(0xFF11110E);
        final containerColor = _settings.darkTheme
            ? const Color(0xFF0A0A0A)
            : const Color(0xFF1E1E1E);

        state = state.copyWith(
          colorScheme: ColorScheme.fromSeed(
            seedColor: vibrantColor,
            primary: vibrantColor,
            onPrimary: Colors.white,
            surface: surfaceColor,
            surfaceContainer: containerColor,
            brightness: Brightness.dark,
          ),
        );

        // PERSIST the color to database if enabled
        if (_settings.saveDynamicColor || _settings.dynamicAccentColor) {
          await ref
              .read(settingsProvider.notifier)
              .updateAccentColor(vibrantColor.toARGB32());
        }
      }
    } catch (e) {
      debugPrint('Error updating theme from image $imagePath: $e');
    } finally {
      _isUpdating = false;
    }
  }

  void _resetTheme() {
    // darkTheme ON = OLED/Pure Black (#000000)
    // darkTheme OFF = Premium Deep Black (#11110E)
    final surfaceColor = _settings.darkTheme
        ? Colors.black
        : const Color(0xFF11110E);
    final containerColor = _settings.darkTheme
        ? const Color(0xFF0A0A0A)
        : const Color(0xFF1E1E1E);

    state = state.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Color(_settings.accentColor),
        primary: Color(_settings.accentColor),
        surface: surfaceColor,
        surfaceContainer: containerColor,
        brightness: Brightness.dark,
      ),
    );
  }
}
