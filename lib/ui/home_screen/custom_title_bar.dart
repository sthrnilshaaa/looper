import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:window_manager/window_manager.dart';

class CustomTitleBar extends StatelessWidget {
  final bool showMenu;
  const CustomTitleBar({super.key, this.showMenu = false});

  @override
  Widget build(BuildContext context) {
    if (Platform.isAndroid || Platform.isIOS) {
      return const SizedBox.shrink();
    }
    return WindowCaption(
      brightness: Brightness.dark,
      backgroundColor: Colors.transparent,
      title: Row(
        children: [
          if (showMenu)
            IconButton(
              icon: const Icon(LucideIcons.menu, color: Colors.white),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
        ],
      ),
    );
  }
}
