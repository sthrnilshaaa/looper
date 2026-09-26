import 'package:flutter/material.dart';
import 'package:looper_player/features/search/presentation/screens/search_view.dart';
import 'package:looper_player/l10n/app_localizations.dart';
import 'package:looper_player/ui/widgets/common/global_search_bar.dart';
import 'package:looper_player/core/theme/app_fonts.dart';

class AndroidSearchTab extends StatelessWidget {
  const AndroidSearchTab({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Scaffold with an explicit opaque background, not a bare SafeArea:
    // this screen is reached via a non-opaque PageRoute (_createPremiumRoute)
    // meant to let the black root screen underneath show through, but that
    // compositing isn't reliable on every device/renderer combo (seen as a
    // white/native-window-background flash on some devices).
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                l10n.search,
                style: AppFonts.jostStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: GlobalSearchBar(autofocus: true),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.0),
                child: SearchView(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
