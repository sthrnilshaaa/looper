import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:looper_player/core/services/storage/db_service.dart';
import 'package:looper_player/features/settings/presentation/providers/settings_notifier.dart';

class _Settings extends Settings {
  @override
  AppSettings build() => AppSettings()..persistQueue = true;
}

void main() {
  test(
    'manual priority and original order survive settings updates and database reopen',
    () async {
      final configUri = Directory.current.uri.resolve(
        '.dart_tool/package_config.json',
      );
      final config =
          jsonDecode(await File.fromUri(configUri).readAsString())
              as Map<String, dynamic>;
      final package = (config['packages'] as List)
          .cast<Map<String, dynamic>>()
          .firstWhere(
            (package) => package['name'] == 'isar_community_flutter_libs',
          );
      final packageUri = configUri.resolve("${package['rootUri']}/");
      await Isar.initializeIsarCore(
        libraries: {
          Abi.macosArm64: packageUri
              .resolve('macos/libisar.dylib')
              .toFilePath(),
          Abi.macosX64: packageUri.resolve('macos/libisar.dylib').toFilePath(),
        },
      );
      final directory = await Directory.systemTemp.createTemp(
        'looper-queue-persistence-',
      );
      var database = await Isar.open(
        [AppSettingsSchema],
        directory: directory.path,
        inspector: false,
      );
      DbService.isar = database;
      final container = ProviderContainer(
        overrides: [settingsProvider.overrideWith(_Settings.new)],
      );
      try {
        final settings = container.read(settingsProvider.notifier);
        await settings.updateLastQueueState(
          [1, 2, 1, 3],
          2,
          1,
          positionMs: 42000,
          manualIndices: [3],
          originalOrder: [0, 3, 1, 2],
        );
        await settings.updateVolume(
          0.3,
        ); // Exercises the production clone path.
        await database.close();
        database = await Isar.open(
          [AppSettingsSchema],
          directory: directory.path,
          inspector: false,
        );
        DbService.isar = database;
        final restored = (await database.appSettings.get(0))!;
        expect(restored.lastQueueSongIds, [1, 2, 1, 3]);
        expect(restored.lastQueueIndex, 2);
        expect(restored.lastPositionMs, 42000);
        expect(restored.lastQueueManualIndices, [3]);
        expect(restored.lastQueueOriginalOrder, [0, 3, 1, 2]);
        await settings.updatePersistQueue(false);
        final cleared = (await database.appSettings.get(0))!;
        expect(cleared.lastQueueSongIds, isEmpty);
        expect(cleared.lastQueueManualIndices, isEmpty);
        expect(cleared.lastQueueOriginalOrder, isEmpty);
      } finally {
        container.dispose();
        await database.close();
        await directory.delete(recursive: true);
      }
    },
  );
}
