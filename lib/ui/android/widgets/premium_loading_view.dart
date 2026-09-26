import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:looper_player/core/utils/ui_utils.dart';
import 'package:looper_player/features/settings/presentation/providers/settings_notifier.dart';
import 'package:looper_player/core/theme/app_fonts.dart';
import 'package:looper_player/l10n/app_localizations.dart';
import 'package:lottie/lottie.dart';

class PremiumLoadingView extends ConsumerStatefulWidget {
  final String? message;
  const PremiumLoadingView({super.key, this.message});

  @override
  ConsumerState<PremiumLoadingView> createState() => _PremiumLoadingViewState();
}

class _PremiumLoadingViewState extends ConsumerState<PremiumLoadingView> {
  int _loadingPhase = 0;

  final int _loadingMessagesCount = 4;

  @override
  void initState() {
    super.initState();
    // Rotate messages for interactive high-fidelity feedback
    _rotatePhase();
  }

  void _rotatePhase() async {
    while (mounted) {
      await Future.delayed(const Duration(seconds: 4));
      if (mounted) {
        setState(() {
          _loadingPhase = (_loadingPhase + 1) % _loadingMessagesCount;
        });
      }
    }
  }

  List<String> _getLoadingMessages(AppLocalizations l10n) => [
    l10n.loadingPhase1,
    l10n.loadingPhase2,
    l10n.loadingPhase3,
    l10n.loadingPhase4,
  ];

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final accentColor = Color(settings.accentColor);
    final l10n = AppLocalizations.of(context)!;
    final loadingMessages = _getLoadingMessages(l10n);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.05),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Sonic Wave / Rotating SVG loader animation
                SizedBox(
                  width: 400.s,
                  height: 300.s,
                  child: Lottie.asset(
                    'assets/loading.json',
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 36),

                // Main Loading Text
                Text(
                  widget.message ?? l10n.loadingMusicLibrary,
                  textAlign: TextAlign.center,
                  style: AppFonts.jostStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2.5,
                  ),
                ),
                const SizedBox(height: 12),

                // Dynamic Status Text
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  child: Text(
                    loadingMessages[_loadingPhase],
                    key: ValueKey<int>(_loadingPhase),
                    textAlign: TextAlign.center,
                    style: AppFonts.jostStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.35),
                      letterSpacing: 1.5,
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
