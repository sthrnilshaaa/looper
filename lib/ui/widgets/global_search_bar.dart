import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:looper_player/core/app_fonts.dart';
import 'package:looper_player/core/providers.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:looper_player/features/search/presentation/search_view.dart';
import 'package:looper_player/core/navigation_provider.dart';
import 'package:looper_player/features/settings/presentation/settings_notifier.dart';
import 'package:looper_player/core/app_icons.dart';
import 'package:looper_player/core/ui_utils.dart';
import 'package:looper_player/l10n/app_localizations.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class GlobalSearchBar extends ConsumerStatefulWidget {
  final bool autofocus;
  const GlobalSearchBar({super.key, this.autofocus = false});

  @override
  ConsumerState<GlobalSearchBar> createState() => _GlobalSearchBarState();
}

class _GlobalSearchBarState extends ConsumerState<GlobalSearchBar> {
  late TextEditingController _controller;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: ref.read(searchQueryProvider));
    if (widget.autofocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(searchFocusNodeProvider).requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _clearSearch() {
    _debounceTimer?.cancel();
    _controller.clear();
    ref.read(searchQueryProvider.notifier).set('');
    // Unfocus the search bar to return to music control mode
    FocusManager.instance.primaryFocus?.unfocus();

    // If we are currently in the search view, exit to home
    if (ref.read(appNavigationProvider).activeItem == NavItem.search) {
      ref.read(appNavigationProvider.notifier).setItem(NavItem.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final isDynamic = settings.enableDynamicTheming;
    final nav = ref.watch(appNavigationProvider);
    final l10n = AppLocalizations.of(context)!;
    // Remove global watch of searchQueryProvider to prevent rebuilds on every keystroke
    // final query = ref.watch(searchQueryProvider);

    // Keeps the visible text in sync when something other than typing here
    // changes the query - e.g. tapping a Recent Searches row in SearchView,
    // which only updates searchQueryProvider itself.
    ref.listen(searchQueryProvider, (previous, next) {
      if (_controller.text != next) {
        _controller.text = next;
      }
    });

    if (nav.activeItem == NavItem.lyrics) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: GestureDetector(
        onTap: () {
          ref.read(searchFocusNodeProvider).requestFocus();
        },
        child: Container(
          height: 55,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            color: const Color.fromARGB(
              255,
              53,
              53,
              53,
            ).withValues(alpha: isDynamic ? 0.3 : 0.1),
            border: Border.all(
              color: Colors.white10.withValues(alpha: 0.1),
              width: 1,
            ),
            boxShadow: [
              if (!isDynamic)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: () {
            final bool enableBlur = isDynamic && !settings.disableBlur;
            final Widget searchBarContent = Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                // vertical: 2,
              ),
              child: TextField(
                focusNode: ref.watch(searchFocusNodeProvider),
                controller: _controller,
                textInputAction: TextInputAction.search,
                onChanged: (val) {
                  _debounceTimer?.cancel();
                  _debounceTimer = Timer(const Duration(milliseconds: 300), () {
                    ref.read(searchQueryProvider.notifier).set(val);
                  });
                  if (val.isNotEmpty && nav.activeItem != NavItem.search) {
                    ref
                        .read(appNavigationProvider.notifier)
                        .setItem(NavItem.search);
                  }
                },
                // Recording happens on an explicit "search" submit rather
                // than every debounced keystroke, so history holds terms
                // the user meant to search for instead of every partial
                // substring typed along the way.
                onSubmitted: (val) =>
                    ref.read(recentSearchesProvider.notifier).add(val),
                decoration: InputDecoration(
                  hintText: l10n.searchSongsHint,
                  hintStyle: AppFonts.jostStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 14,
                  ),
                  prefixIcon: SizedBox(
                    width: 50,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset(
                          AppIcons.search,
                          colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                          width: AppIcons.sizeSmall.s,
                          height: AppIcons.sizeSmall.s,
                        ),
                        Container(
                          height: 30,
                          width: 1,
                          margin: const EdgeInsets.symmetric(horizontal: 12),
                          color: Colors.white10,
                        ),
                      ],
                    ),
                  ),
                  suffixIcon: ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _controller,
                    builder: (context, value, child) {
                      return value.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                LucideIcons.x,
                                size: 18,
                                color: Colors.white70,
                              ),
                              onPressed: _clearSearch,
                            )
                          : const SizedBox.shrink();
                    },
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
                style: AppFonts.jostStyle(color: Colors.white, fontSize: 14),
                canRequestFocus: true,
              ),
            );

            if (enableBlur) {
              return RepaintBoundary(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                    child: searchBarContent,
                  ),
                ),
              );
            }

            return searchBarContent;
          }(),
        ),
      ),
    );
  }
  
}
