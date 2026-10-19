import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:looper_player/features/library/domain/models/models.dart';
import 'package:looper_player/features/playback/domain/playback_queue.dart';

Song song(String name) => Song()
  ..id = name.codeUnitAt(0)
  ..path = name
  ..title = name;

List<String> paths(PlaybackQueue queue) =>
    queue.songs.map((song) => song.path).toList();

void main() {
  test(
    'duplicate playlist occurrences advance once each and reach the end',
    () {
      final a = song('A');
      final queue = PlaybackQueue()..load([a, song('B'), a, song('C')]);
      final ids = queue.entries.map((entry) => entry.id).toList();
      final played = <String>[];
      do {
        queue.selectSong(queue.current!.song);
        played.add(queue.current!.song.path);
      } while (queue.advance(repeatAll: false, shuffled: false));
      expect(played, ['A', 'B', 'A', 'C']);
      expect(ids.toSet().length, 4);
      expect(queue.currentIndex, 3);
    },
  );

  test('tapping a later duplicate keeps that occurrence selected', () {
    final a = song('A');
    final queue = PlaybackQueue()..load([a, song('B'), a, song('C')]);
    queue.select(2);
    queue.selectSong(a);
    expect(queue.currentIndex, 2);
    queue.advance(repeatAll: false, shuffled: false);
    expect(queue.current!.song.path, 'C');
  });

  test(
    'manual additions keep FIFO priority through shuffle and collections',
    () {
      for (var seed = 0; seed < 30; seed++) {
        final queue = PlaybackQueue(random: Random(seed))
          ..load([song('A'), song('B'), song('C'), song('D')]);
        queue.add(song('X'));
        queue.add(song('Y'));
        queue.shuffle(true);
        expect(paths(queue).take(3), ['A', 'X', 'Y']);
        queue.add(song('Z'));
        expect(paths(queue).take(4), ['A', 'X', 'Y', 'Z']);
        queue.add(song('N'), next: true);
        expect(paths(queue).take(5), ['A', 'N', 'X', 'Y', 'Z']);
        queue.load([song('E'), song('F'), song('G')], shuffle: true);
        expect(paths(queue).skip(1).take(4), ['N', 'X', 'Y', 'Z']);
        queue.shuffle(false);
        expect(queue.pendingManual.map((entry) => entry.song.path), [
          'N',
          'X',
          'Y',
          'Z',
        ]);
        expect(paths(queue).skip(1).take(4), ['N', 'X', 'Y', 'Z']);
      }
    },
  );

  test('unshuffle keeps played songs behind the current occurrence', () {
    final queue = PlaybackQueue(random: Random(7))
      ..load([song('A'), song('B'), song('C'), song('D'), song('E')]);
    queue.shuffle(true);
    queue.advance(repeatAll: false, shuffled: true);
    queue.advance(repeatAll: false, shuffled: true);
    final historyIds = queue.entries.take(3).map((entry) => entry.id).toList();
    queue.shuffle(false);
    expect(queue.entries.take(3).map((entry) => entry.id), historyIds);
    expect(
      queue.entries.skip(3).any((entry) => historyIds.contains(entry.id)),
      isFalse,
    );
    expect(queue.entries.map((entry) => entry.id).toSet().length, 5);
  });

  test('requeue moves upcoming copies without erasing a played duplicate', () {
    final a = song('A');
    final queue = PlaybackQueue()..load([a, song('B'), a, song('C')]);
    final firstId = queue.entries.first.id;
    queue.add(a);
    queue.add(a);
    expect(paths(queue), ['A', 'A', 'B', 'C']);
    expect(queue.entries.first.id, firstId);
    expect(queue.pendingManual.length, 1);
    queue.shuffle(true);
    queue.shuffle(false);
    expect(paths(queue), ['A', 'A', 'B', 'C']);
  });

  test('a queued but unstarted session stays unstarted after restore', () {
    final queue = PlaybackQueue();
    queue.add(song('X'));
    queue.add(song('Y'));
    final restored = PlaybackQueue()
      ..restore(
        queue.songs,
        index: -1,
        manualIndices: queue.manualIndices,
        originalOrder: queue.originalOrder,
      );
    expect(restored.current, isNull);
    expect(restored.manualIndices, [0, 1]);
    expect(paths(restored), ['X', 'Y']);
    restored.load([song('A'), song('B')]);
    expect(paths(restored), ['A', 'X', 'Y', 'B']);
  });

  test('repeat all loops the finite queue and clear leaves it empty', () {
    final queue = PlaybackQueue()..load([song('A'), song('B')]);
    queue.advance(repeatAll: true, shuffled: false);
    queue.advance(repeatAll: true, shuffled: false);
    expect(queue.current!.song.path, 'A');
    expect(paths(queue), ['A', 'B']);
    queue.clear();
    expect(queue.entries, isEmpty);
    expect(queue.current, isNull);
    expect(queue.advance(repeatAll: true, shuffled: false), isFalse);
  });

  test('repeat shuffled round avoids immediate replay when possible', () {
    for (var seed = 0; seed < 30; seed++) {
      final queue = PlaybackQueue(random: Random(seed))
        ..load([song('A'), song('B'), song('A')], initialIndex: 2);
      queue.advance(repeatAll: true, shuffled: true);
      expect(queue.current!.song.path, 'B');
      expect(paths(queue), unorderedEquals(['A', 'A', 'B']));
    }
  });

  test(
    'restore retains duplicate position, manual priority and unshuffle order',
    () {
      final a = song('A');
      final queue = PlaybackQueue(random: Random(6))
        ..load([a, song('B'), a, song('C')], initialIndex: 2);
      queue.add(song('X'));
      queue.add(song('Y'));
      queue.shuffle(true);
      final saved = queue.songs;
      final manual = queue.manualIndices;
      final original = queue.originalOrder;
      final restored = PlaybackQueue()
        ..restore(
          saved,
          index: queue.currentIndex,
          manualIndices: manual,
          originalOrder: original,
        );
      expect(paths(restored), paths(queue));
      expect(restored.currentIndex, 2);
      restored.shuffle(false);
      expect(paths(restored), ['A', 'B', 'A', 'X', 'Y', 'C']);
      restored.load([song('D'), song('E')]);
      expect(paths(restored), ['D', 'X', 'Y', 'E']);
    },
  );

  test(
    'restore skips deleted songs without shifting to the wrong occurrence',
    () {
      final a = song('A');
      final queue = PlaybackQueue()
        ..restore(
          [a, null, a, song('X'), song('B')],
          index: 2,
          manualIndices: [3],
          originalOrder: [0, 1, 2, 3, 4],
        );
      expect(queue.currentIndex, 1);
      queue.selectSong(a);
      expect(queue.currentIndex, 1);
      expect(queue.pendingManual.single.song.path, 'X');
      expect(queue.originalOrder, [0, 1, 2, 3]);
    },
  );

  test(
    'remove and reorder address occurrences and preserve manual priority',
    () {
      final a = song('A');
      final queue = PlaybackQueue()..load([a, song('B'), a, song('C')]);
      final firstId = queue.entries.first.id;
      queue.remove(2);
      expect(paths(queue), ['A', 'B', 'C']);
      expect(queue.entries.first.id, firstId);
      queue.add(song('X'));
      queue.add(song('Y'));
      queue.reorder(4, 1); // Drag C before the manual choices.
      expect(paths(queue), ['A', 'C', 'X', 'Y', 'B']);
      expect(queue.pendingManual.map((entry) => entry.song.path), [
        'C',
        'X',
        'Y',
      ]);
      queue.reorder(2, 5); // Explicitly move X behind the automatic songs.
      expect(paths(queue), ['A', 'C', 'Y', 'B', 'X']);
      expect(queue.pendingManual.map((entry) => entry.song.path), ['C', 'Y']);
      queue.shuffle(true);
      expect(paths(queue).take(3), ['A', 'C', 'Y']);
    },
  );
}
