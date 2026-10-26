import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:looper_player/core/theme/app_fonts.dart';
import 'package:looper_player/features/settings/presentation/providers/settings_notifier.dart';
import 'package:looper_player/l10n/app_localizations.dart';
import 'package:looper_player/ui/widgets/common/app_loading_indicator.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// The frame the metadata edit sheets (song, album) share: a draggable dark
/// sheet with a grabber, an icon + [title] header, the caller's [children]
/// in a scrolling list, and a save button at the end.
class EditSheetScaffold extends ConsumerWidget {
  final IconData icon;
  final String title;
  final double initialChildSize;
  final double minChildSize;
  final double maxChildSize;
  final bool isSaving;
  final VoidCallback onSave;
  final List<Widget> children;

  const EditSheetScaffold({
    super.key,
    required this.icon,
    required this.title,
    required this.initialChildSize,
    required this.minChildSize,
    required this.maxChildSize,
    required this.isSaving,
    required this.onSave,
    required this.children,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(settingsProvider);
    final accentColor = Color(settings.accentColor);

    Widget content = Container(
      decoration: const BoxDecoration(
        color: Color(0xFF121212),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: initialChildSize,
        minChildSize: minChildSize,
        maxChildSize: maxChildSize,
        expand: false,
        builder: (ctx, scrollController) => Column(
          children: [
            // Header bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: accentColor, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppFonts.jostStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          l10n.tapFieldToEdit,
                          style: AppFonts.jostStyle(
                            color: Colors.white38,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                children: [
                  ...children,
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: isSaving ? null : onSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: Colors.black,
                        disabledBackgroundColor: accentColor.withValues(
                          alpha: 0.4,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        elevation: 4,
                        shadowColor: accentColor.withValues(alpha: 0.4),
                      ),
                      child: isSaving
                          ? const AppLoadingIndicator(size: 44)
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(LucideIcons.check, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  l10n.saveChangesBtn,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    // Blur wrapper when dynamic theming is on
    if (settings.enableDynamicTheming && !settings.disableBlur) {
      content = ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: content,
        ),
      );
    }

    // The DraggableScrollableSheet above sizes itself as a fraction of
    // whatever height it's given, which by default is the full screen --
    // the keyboard just overlaps the bottom of it instead of the sheet
    // shrinking to sit above it. Padding the whole sheet by the live
    // keyboard inset shrinks that available height instead, so the sheet
    // (and whichever field is focused, e.g. Lyrics near the bottom) stays
    // above the keyboard.
    return AnimatedPadding(
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: content,
    );
  }
}

/// The tappable square artwork preview with its camera badge. An empty
/// [artPath] (or an unreadable file) shows a placeholder icon.
class EditSheetArtwork extends StatelessWidget {
  final String artPath;
  final double size;
  final double placeholderIconSize;
  final Color accentColor;
  final VoidCallback onTap;

  const EditSheetArtwork({
    super.key,
    required this.artPath,
    required this.size,
    required this.placeholderIconSize,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      color: Colors.white.withValues(alpha: 0.05),
      child: Icon(
        LucideIcons.imageOff,
        color: accentColor.withValues(alpha: 0.5),
        size: placeholderIconSize,
      ),
    );
    return Center(
      child: GestureDetector(
        onTap: onTap,
        child: Stack(
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: accentColor.withValues(alpha: 0.4),
                  width: 2,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: artPath.isNotEmpty
                    ? Image.file(
                        File(artPath),
                        width: size,
                        height: size,
                        fit: BoxFit.cover,
                        // Decode at display size, not full resolution.
                        cacheWidth:
                            (size * MediaQuery.devicePixelRatioOf(context))
                                .round(),
                        errorBuilder: (_, _, _) => placeholder,
                      )
                    : placeholder,
              ),
            ),
            // Camera badge
            Positioned(
              right: 8,
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.5),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: const Icon(
                  LucideIcons.camera,
                  color: Colors.black,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EditSheetRemoveArtworkButton extends StatelessWidget {
  final VoidCallback onPressed;
  const EditSheetRemoveArtworkButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) => TextButton.icon(
    onPressed: onPressed,
    icon: const Icon(LucideIcons.x, size: 14, color: Colors.redAccent),
    label: Text(
      AppLocalizations.of(context)!.removeArtwork,
      style: AppFonts.jostStyle(color: Colors.redAccent, fontSize: 12),
    ),
  );
}

class EditSheetField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final Color accentColor;
  final bool required;
  final TextInputType keyboardType;
  final int? maxLength;
  final int maxLines;
  final String? hintText;

  const EditSheetField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    required this.accentColor,
    this.required = false,
    this.keyboardType = TextInputType.text,
    this.maxLength,
    this.maxLines = 1,
    this.hintText,
  });

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    style: AppFonts.jostStyle(color: Colors.white, fontSize: 15),
    keyboardType: keyboardType,
    maxLength: maxLength,
    maxLines: maxLines,
    buildCounter: maxLength != null
        ? (ctx, {required currentLength, required isFocused, maxLength}) => null
        : null,
    decoration: InputDecoration(
      labelText: '$label${required ? ' *' : ''}',
      labelStyle: AppFonts.jostStyle(
        color: Colors.white.withValues(alpha: 0.45),
        fontSize: 13,
      ),
      hintText: hintText,
      hintStyle: AppFonts.jostStyle(
        color: Colors.white.withValues(alpha: 0.25),
        fontSize: 13,
      ),
      prefixIcon: Icon(icon, color: accentColor, size: 20),
      alignLabelWithHint: maxLines > 1,
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.05),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: accentColor, width: 1.5),
      ),
    ),
  );
}
