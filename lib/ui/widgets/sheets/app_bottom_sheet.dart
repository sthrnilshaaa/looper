import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:looper_player/core/utils/responsive.dart';
import 'package:looper_player/features/settings/presentation/providers/settings_notifier.dart';
import 'package:looper_player/ui/android/widgets/premium_section.dart';

class AppBottomSheetContainer extends ConsumerWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? height;
  final bool showDragHandle;
  final bool useBlurBG;

  const AppBottomSheetContainer({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
    this.height,
    this.showDragHandle = true,
    this.useBlurBG = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    // `disableBlur` only exists as a sub-toggle of Dynamic Theming (it's
    // hidden, and stuck at its default of `true`, whenever Dynamic Theming
    // is off) -- so it must only gate the Dynamic Theming blur path, never
    // veto alwaysBlurSheets, or that toggle would be permanently dead for
    // anyone who hasn't also turned Dynamic Theming on.
    // alwaysBlurSheets is the standalone opt-in: it lets every sheet built
    // on this container blur without needing Dynamic Theming at all.
    final useBlur =
        settings.alwaysBlurSheets ||
        (!settings.disableBlur && (useBlurBG || settings.enableDynamicTheming));

    // On a landscape phone/tablet a bottom sheet stretched edge-to-edge
    // reads as a wall of controls - cap the content's width and center it,
    // the same way the rest of the landscape work caps other panes rather
    // than letting them stretch just because the window is wide.
    final isLandscape = Responsive.isLandscape(MediaQuery.sizeOf(context));
    final constrainedChild = isLandscape
        ? Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: child,
            ),
          )
        : child;

    final sheetBody = Container(
      height: height,
      decoration: BoxDecoration(
        color: useBlur
            ? const Color.fromARGB(50, 0, 0, 0)
            : settings.darkTheme
            ? const Color.fromARGB(255, 0, 0, 0)
            // Was 0xFF161613, a rogue shade matching neither of the
            // theme's own two canonical near-black colors
            // (theme_provider.dart) - use the same 0xFF1E1E1E every
            // other non-OLED sheet/dialog in the app already uses, so
            // this widely-shared sheet shell (11+ call sites) is
            // visually consistent with the rest.
            : const Color(0xFF1E1E1E),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      padding: padding,
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showDragHandle) ...[
              const SizedBox(height: 5),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
            if (height != null)
              Expanded(child: constrainedChild)
            else
              constrainedChild,
          ],
        ),
      ),
    );

    // BackdropFilter forces an offscreen saveLayer/composite pass every
    // frame regardless of the blur sigma, so it must be skipped entirely
    // (not just given sigma 0) when blur is disabled — otherwise every
    // bottom sheet in the app pays the full blur cost for no visual effect.
    Widget content = ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(30),
        topRight: Radius.circular(30),
      ),
      child: useBlur
          ? BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: sheetBody,
            )
          : sheetBody,
    );

    if (useBlur) {
      return PremiumSection(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        useBlur: true,
        forceBlur: true,
        useExpanded: false,
        useCenter: false,
        child: content,
      );
    }
    return content;
  }
}
