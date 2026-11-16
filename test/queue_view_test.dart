import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:looper_player/features/library/domain/models/models.dart';
import 'package:looper_player/features/library/presentation/screens/queue_view.dart';
import 'package:looper_player/features/playback/presentation/providers/playback/playback_notifier.dart';
import 'package:looper_player/features/settings/presentation/providers/settings_notifier.dart';
import 'package:looper_player/l10n/app_localizations.dart';
import 'package:looper_player/ui/android/widgets/queue_bottom_sheet.dart';
import 'package:looper_player/ui/widgets/common/queue_entry_fade.dart';

class _Playback extends Playback {
  int? selected;
  int? removed;

  @override
  PlaybackState build() {
    final a = Song()
      ..path = 'A'
      ..title = 'Current song'
      ..artist = 'Artist';
    final b = Song()
      ..path = 'B'
      ..title = 'Your next choice'
      ..artist = 'Artist';
    final c = Song()
      ..path = 'A'
      ..title = 'Collection song'
      ..artist = 'Artist';
    return PlaybackState(
      currentSong: a,
      queue: [a, b, c],
      queueEntryIds: [10, 11, 12],
      manualQueueEntryIds: {11},
      currentQueueIndex: 0,
    );
  }

  @override
  Future<void> playAtIndex(int index) async => selected = index;

  @override
  Future<void> removeFromQueue(int index) async => removed = index;
}

class _Settings extends Settings {
  @override
  AppSettings build() => AppSettings();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final text = FontLoader('Stack Sans Text')
      ..addFont(
        rootBundle.load(
          'assets/fonts/stack_sans_text/StackSansText-Regular.ttf',
        ),
      );
    final icons = FontLoader('packages/lucide_icons_flutter/Lucide')
      ..addFont(
        rootBundle.load('packages/lucide_icons_flutter/assets/lucide.ttf'),
      );
    await Future.wait([text.load(), icons.load()]);
  });
  for (final bottomSheet in [false, true]) {
    testWidgets(
      '${bottomSheet ? 'Android sheet' : 'queue view'} distinguishes priority and targets duplicate occurrences',
      (tester) async {
        tester.view.physicalSize = const Size(430, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final playback = _Playback();
        final boundary = GlobalKey();
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              playbackProvider.overrideWith(() => playback),
              settingsProvider.overrideWith(_Settings.new),
            ],
            child: MaterialApp(
              theme: ThemeData.dark(useMaterial3: true).copyWith(
                colorScheme: ColorScheme.fromSeed(
                  seedColor: const Color(0xFF41C25E),
                  brightness: Brightness.dark,
                ),
              ),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: RepaintBoundary(
                key: boundary,
                child: Scaffold(
                  body: bottomSheet
                      ? const QueueBottomSheet()
                      : const QueueView(),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        for (final title in [
          'Current song',
          'Your next choice',
          'Collection song',
        ]) {
          final fade = tester.widget<QueueEntryFade>(
            find.ancestor(
              of: find.text(title),
              matching: find.byType(QueueEntryFade),
            ),
          );
          expect(fade.automatic, title == 'Collection song');
        }
        await tester.tap(find.text('Collection song'));
        expect(playback.selected, 2);
        expect(playback.selected, isNot(0));
        if (bottomSheet) {
          final row = find.byKey(const ValueKey('queue_sheet_12'));
          await tester.tap(
            find.descendant(of: row, matching: find.byType(IconButton)),
          );
        } else {
          await tester.drag(
            find.byKey(const ValueKey('queue_view_12')),
            const Offset(-500, 0),
          );
          await tester.pumpAndSettle();
        }
        expect(playback.removed, 2);
        const directory = String.fromEnvironment('QUEUE_SCREENSHOT_DIR');
        if (directory.isNotEmpty && bottomSheet) {
          await tester.runAsync(() async {
            final image =
                await (boundary.currentContext!.findRenderObject()
                        as RenderRepaintBoundary)
                    .toImage();
            final data = await image.toByteData(format: ui.ImageByteFormat.png);
            await File(
              '$directory/queue-rework-ui.png',
            ).writeAsBytes(data!.buffer.asUint8List());
            image.dispose();
          });
        }
      },
    );
  }
}
