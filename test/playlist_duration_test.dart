import 'dart:async';
import 'dart:convert';
import 'dart:ffi' show Abi;
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:looper_player/features/playback/presentation/providers/playback/playback_notifier.dart';
import 'package:looper_player/features/settings/presentation/providers/settings_notifier.dart';
import 'package:looper_player/l10n/app_localizations.dart';
import 'package:looper_player/ui/widgets/collection_detail/collection_detail_view.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:looper_player/core/services/storage/db_service.dart';
import 'package:looper_player/features/library/data/scanner/scanner.dart';
import 'package:looper_player/features/playlists/data/m3u_parser.dart';
import 'package:looper_player/features/playlists/presentation/screens/playlist_view.dart';
import 'package:metadata_god/metadata_god.dart';

Song track(String path, [int? duration]) => Song()
  ..path = path
  ..title = path
  ..dateAdded = DateTime(2026)
  ..duration = duration;

class _Playback extends Playback {
  @override
  PlaybackState build() => PlaybackState();
}

class _Settings extends Settings {
  @override
  AppSettings build() => AppSettings();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late Isar isar;

  setUpAll(() async {
    final configFile = File('.dart_tool/package_config.json').absolute;
    final config = jsonDecode(await configFile.readAsString()) as Map;
    final package = (config['packages'] as List).cast<Map>().firstWhere(
      (p) => p['name'] == 'isar_community_flutter_libs',
    );
    final root = configFile.uri.resolve("${package['rootUri']}/");
    final library = Platform.isMacOS
        ? 'macos/libisar.dylib'
        : Platform.isWindows
        ? 'windows/isar.dll'
        : 'linux/libisar.so';
    await Isar.initializeIsarCore(
      libraries: {Abi.current(): root.resolve(library).toFilePath()},
    );
  });

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('looper-duration-');
    isar = await Isar.open(
      [
        SongSchema,
        PlaylistSchema,
        AlbumSchema,
        ArtistSchema,
        AppSettingsSchema,
      ],
      directory: directory.path,
      inspector: false,
    );
    DbService.isar = isar;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (_) async => directory.path,
        );
  });

  tearDown(() async {
    await isar.close(deleteFromDisk: true);
    await directory.delete(recursive: true);
  });

  testWidgets('counter displays unknown, totals and hours', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    Future<void> display(List<Song> songs) async {
      // Favorite watches perform native I/O; start them outside fake async.
      await tester.runAsync(
        () => tester.pumpWidget(
          ProviderScope(
            overrides: [
              playbackProvider.overrideWith(_Playback.new),
              settingsProvider.overrideWith(_Settings.new),
            ],
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              locale: const Locale('en'),
              home: CollectionDetailView(title: 'Runtime test', songs: songs),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    for (final missing in [null, 0, -1]) {
      await display([track('known', 180000), track('missing', missing)]);
      expect(find.textContaining(' • Unknown'), findsOneWidget);
      expect(find.textContaining('3 Mins'), findsNothing);
    }
    await display([track('a', 180000), track('b', 240000)]);
    expect(find.textContaining('7 Mins'), findsOneWidget);
    await display([track('a', 180000), track('b', 240000), track('a', 180000)]);
    expect(find.textContaining('10 Mins'), findsOneWidget);
    await display([track('long', 3900000)]);
    expect(find.textContaining('1h 5m'), findsOneWidget);
    await display([]);
    expect(find.textContaining('0 Mins'), findsOneWidget);
    expect(tester.takeException(), isNull);
    // The current collection rows watch favorites in Isar. Dispose their
    // subscriptions before the test database is closed outside fake async.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump();
  });

  test(
    'imported playlist reacts to enrichment, edits, insertion, deletion and reordering',
    () async {
      final a = track('/music/a.mp3');
      final b = track('/music/b.mp3', 240000);
      await isar.writeTxn(() => isar.songs.putAll([a, b]));
      final entries = M3uParser.parse('#EXTM3U\na.mp3\nb.mp3\n');
      final matcher = M3uSongMatcher([a, b]);
      final playlist = Playlist()
        ..name = 'Imported'
        ..songPaths = entries
            .map((e) => matcher.match(e, playlistDir: '/music')!.path)
            .toList()
        ..dateCreated = DateTime(2026)
        ..dateModified = DateTime(2026);
      await isar.writeTxn(() => isar.playlists.put(playlist));
      final container = ProviderContainer();
      final provider = playlistSongsProvider(playlist.id);
      final subscription = container.listen(provider, (_, _) {});
      addTearDown(() {
        subscription.close();
        container.dispose();
      });

      Future<List<Song>> waitFor(bool Function(List<Song>) predicate) async {
        final completer = Completer<List<Song>>();
        final listener = container.listen(provider, (_, value) {
          if (value.hasValue &&
              predicate(value.value!) &&
              !completer.isCompleted) {
            completer.complete(value.value!);
          }
        }, fireImmediately: true);
        try {
          return await completer.future.timeout(const Duration(seconds: 5));
        } finally {
          listener.close();
        }
      }

      final initial = await container.read(provider.future);
      expect(initial.map((s) => s.path), [a.path, b.path]);
      expect(initial.first.duration, isNull);
      a.duration = 180000;
      await isar.writeTxn(() => isar.songs.put(a));
      expect(
        (await waitFor(
          (s) => s.first.duration == 180000,
        )).map((song) => song.duration),
        [180000, 240000],
      );
      b.duration = 300000;
      await isar.writeTxn(() => isar.songs.put(b));
      expect(
        (await waitFor(
          (s) => s.last.duration == 300000,
        )).map((song) => song.duration),
        [180000, 300000],
      );

      playlist.songPaths = [b.path, a.path, b.path, '/music/later.mp3'];
      await isar.writeTxn(() => isar.playlists.put(playlist));
      expect(
        (await waitFor(
          (s) => s.length == 3 && s.first.path == b.path,
        )).map((song) => song.path).toList(),
        [b.path, a.path, b.path],
      );
      final later = track('/music/later.mp3', 120000);
      await isar.writeTxn(() => isar.songs.put(later));
      expect(
        (await waitFor((s) => s.length == 4)).map((song) => song.duration),
        [300000, 180000, 300000, 120000],
      );
      await isar.writeTxn(() => isar.songs.delete(b.id));
      expect(
        (await waitFor((s) => s.length == 2)).map((song) => song.duration),
        [180000, 120000],
      );
      await isar.writeTxn(() => isar.playlists.delete(playlist.id));
      expect(await waitFor((s) => s.isEmpty), isEmpty);
    },
  );

  test('quick scan and failed enrichment preserve a known duration', () async {
    final file = await File('${directory.path}/track.mp3').writeAsBytes([1]);
    final song = track(file.path, 180000)..needsEnrichment = true;
    await isar.writeTxn(() => isar.songs.put(song));
    final scanner = LibraryScanner(
      metadataReader: (_) async => throw StateError('unreadable'),
    );
    await scanner.scanDirectory(directory.path);
    expect((await isar.songs.get(song.id))!.duration, 180000);
    await scanner.enrichPendingSongs();
    expect((await isar.songs.get(song.id))!.duration, 180000);
  });

  test(
    'repairs old missing durations without replacing metadata or user state',
    () async {
      final song = track('old.mp3')
        ..title = 'Custom title'
        ..isFavorite = true
        ..playCount = 9;
      await isar.writeTxn(() => isar.songs.put(song));
      await LibraryScanner(
        metadataReader: (_) async => const Metadata(durationMs: 180000),
      ).enrichPendingSongs();
      final repaired = (await isar.songs.get(song.id))!;
      expect(repaired.duration, 180000);
      expect(repaired.title, 'Custom title');
      expect(repaired.isFavorite, isTrue);
      expect(repaired.playCount, 9);
      expect(repaired.needsEnrichment, isFalse);
    },
  );

  test(
    'failed duration recovery retries next pass and preserves concurrent edits',
    () async {
      final song = track('retry.mp3', 0);
      await isar.writeTxn(() => isar.songs.put(song));
      await LibraryScanner(
        metadataReader: (_) async => throw StateError('offline'),
      ).enrichPendingSongs();
      expect((await isar.songs.get(song.id))!.duration, 0);
      await LibraryScanner(
        metadataReader: (_) async {
          final current = (await isar.songs.get(song.id))!
            ..title = 'Edited during probe';
          await isar.writeTxn(() => isar.songs.put(current));
          return const Metadata(durationMs: 240000);
        },
      ).enrichPendingSongs();
      final repaired = (await isar.songs.get(song.id))!;
      expect(repaired.duration, 240000);
      expect(repaired.title, 'Edited during probe');
    },
  );
}
