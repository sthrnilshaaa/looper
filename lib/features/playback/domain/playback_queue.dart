import 'dart:math';

import 'package:looper_player/features/library/domain/models/models.dart';

/// One occurrence of a song, so repeated playlist songs remain distinct.
class PlaybackQueueEntry {
  PlaybackQueueEntry(this.id, this.song, {this.isManual = false});

  final int id;
  Song song;
  bool isManual;
}

/// Playback order and manual priority, independent of the audio player.
class PlaybackQueue {
  PlaybackQueue({Random? random}) : _random = random ?? Random();

  final Random _random;
  final List<PlaybackQueueEntry> entries = [];
  final List<PlaybackQueueEntry> _original = [];
  int _nextId = 0;
  int currentIndex = -1;

  List<Song> get songs => entries.map((entry) => entry.song).toList();
  PlaybackQueueEntry? get current =>
      currentIndex >= 0 && currentIndex < entries.length
      ? entries[currentIndex]
      : null;
  List<PlaybackQueueEntry> get pendingManual =>
      entries.skip(currentIndex + 1).where((entry) => entry.isManual).toList();
  List<int> get manualIndices => [
    for (var i = currentIndex + 1; i < entries.length; i++)
      if (entries[i].isManual) i,
  ];
  List<int> get originalOrder => _original.map(entries.indexOf).toList();

  PlaybackQueueEntry _entry(Song song, {bool manual = false}) =>
      PlaybackQueueEntry(_nextId++, song, isManual: manual);

  void clear() {
    entries.clear();
    _original.clear();
    currentIndex = -1;
  }

  void select(int index) {
    if (index < 0 || index >= entries.length) return;
    currentIndex = index;
    for (final entry in entries.take(index + 1)) {
      entry.isManual = false;
    }
  }

  /// Prefer the selected occurrence; never jump to an earlier duplicate.
  void selectSong(Song song) {
    if (current?.song.path == song.path) return;
    var index = entries.indexWhere(
      (entry) => entry.song.path == song.path,
      currentIndex + 1,
    );
    if (index == -1) {
      index = entries.indexWhere((entry) => entry.song.path == song.path);
    }
    if (index == -1) {
      final entry = _entry(song);
      final originalIndex = current == null ? -1 : _original.indexOf(current!);
      _original.insert(originalIndex + 1, entry);
      index = currentIndex + 1;
      entries.insert(index, entry);
    }
    select(index);
  }

  void load(
    List<Song> songs, {
    int initialIndex = 0,
    bool shuffle = false,
    bool preserveManual = true,
  }) {
    final manual = preserveManual ? pendingManual : <PlaybackQueueEntry>[];
    clear();
    if (songs.isEmpty) return;
    final source = songs.map(_entry).toList();
    final selected = source[initialIndex.clamp(0, source.length - 1)];
    _original.addAll(source);
    entries.addAll(source);
    currentIndex = entries.indexOf(selected);
    // A manual choice replaces its upcoming automatic copies, not the
    // currently selected occurrence or previously played playlist entries.
    final manualPaths = manual.map((entry) => entry.song.path).toSet();
    final replaced = entries
        .skip(currentIndex + 1)
        .where((entry) => manualPaths.contains(entry.song.path))
        .toSet();
    entries.removeWhere(replaced.contains);
    _original.removeWhere(replaced.contains);
    entries.insertAll(currentIndex + 1, manual);
    _original.insertAll(_original.indexOf(selected) + 1, manual);
    if (shuffle) {
      final remaining = entries.where((entry) => entry != selected).toList();
      final automatic = remaining.where((entry) => !entry.isManual).toList()
        ..shuffle(_random);
      entries
        ..clear()
        ..addAll([selected, ...manual, ...automatic]);
      currentIndex = 0;
    }
  }

  void add(Song song, {bool next = false}) {
    final duplicates = entries
        .skip(currentIndex + 1)
        .where((entry) => entry.song.path == song.path)
        .toSet();
    entries.removeWhere(duplicates.contains);
    _original.removeWhere(duplicates.contains);
    final manual = pendingManual;
    final entry = _entry(song, manual: true);
    final index = currentIndex + 1 + (next ? 0 : manual.length);
    entries.insert(index, entry);
    final preceding = next || manual.isEmpty ? current : manual.last;
    final originalIndex = preceding == null ? -1 : _original.indexOf(preceding);
    _original.insert(originalIndex + 1, entry);
  }

  void shuffle(bool enabled) {
    final prefix = entries.take(currentIndex + 1).toList();
    final manual = pendingManual;
    final remaining = entries.skip(currentIndex + 1).toSet();
    final automatic = _original
        .where((entry) => remaining.contains(entry) && !entry.isManual)
        .toList();
    if (enabled) automatic.shuffle(_random);
    entries
      ..clear()
      ..addAll([...prefix, ...manual, ...automatic]);
  }

  bool advance({required bool repeatAll, required bool shuffled}) {
    if (entries.isEmpty) return false;
    if (currentIndex + 1 < entries.length) {
      select(currentIndex + 1);
      return true;
    }
    if (!repeatAll) return false;
    final last = current;
    entries
      ..clear()
      ..addAll(_original);
    if (shuffled) {
      entries.shuffle(_random);
      if (entries.length > 1 && entries.first.song.path == last?.song.path) {
        final different = entries.indexWhere(
          (entry) => entry.song.path != last?.song.path,
        );
        if (different != -1) {
          final first = entries[0];
          entries[0] = entries[different];
          entries[different] = first;
        }
      }
    }
    select(0);
    return true;
  }

  void remove(int index) {
    if (index < 0 || index >= entries.length) return;
    final entry = entries.removeAt(index);
    _original.remove(entry);
    if (index <= currentIndex) currentIndex--;
  }

  /// Indices use Flutter's insertion-before-removal convention.
  void reorder(int oldIndex, int newIndex) {
    if (oldIndex <= currentIndex || oldIndex >= entries.length) return;
    newIndex = newIndex.clamp(currentIndex + 1, entries.length);
    if (newIndex > oldIndex) newIndex--;
    if (newIndex == oldIndex) return;
    final manualEnd = currentIndex + pendingManual.length;
    final entry = entries.removeAt(oldIndex);
    // Dragging across the priority boundary is an explicit change of intent.
    entry.isManual = newIndex <= manualEnd;
    entries.insert(newIndex, entry);
    final upcoming = entries.skip(currentIndex + 1).toList();
    final prefix = entries.take(currentIndex + 1).toList();
    entries
      ..clear()
      ..addAll([
        ...prefix,
        ...upcoming.where((entry) => entry.isManual),
        ...upcoming.where((entry) => !entry.isManual),
      ]);
    // Remember explicit drag order, including while shuffle is enabled.
    final positions = _original
        .asMap()
        .entries
        .where((item) => upcoming.contains(item.value))
        .map((item) => item.key)
        .toList();
    final reordered = entries.skip(currentIndex + 1).toList();
    for (var i = 0; i < positions.length; i++) {
      _original[positions[i]] = reordered[i];
    }
  }

  void updateSong(Song song) {
    for (final entry in entries) {
      if (entry.song.id == song.id) entry.song = song;
    }
  }

  void restore(
    List<Song?> savedSongs, {
    required int index,
    List<int> manualIndices = const [],
    List<int> originalOrder = const [],
  }) {
    clear();
    final bySavedIndex = <int, PlaybackQueueEntry>{};
    for (var i = 0; i < savedSongs.length; i++) {
      final song = savedSongs[i];
      if (song == null) continue;
      final entry = _entry(song, manual: manualIndices.contains(i));
      entries.add(entry);
      bySavedIndex[i] = entry;
    }
    for (final i in originalOrder) {
      final entry = bySavedIndex[i];
      if (entry != null && !_original.contains(entry)) _original.add(entry);
    }
    _original.addAll(entries.where((entry) => !_original.contains(entry)));
    if (entries.isEmpty) return;
    final selected = bySavedIndex[index];
    final fallback = bySavedIndex.entries.where((item) => item.key > index);
    if (index >= 0) {
      select(
        selected != null
            ? entries.indexOf(selected)
            : fallback.isNotEmpty
            ? entries.indexOf(fallback.first.value)
            : entries.length - 1,
      );
    }
    final prefix = entries.take(currentIndex + 1).toList();
    final upcoming = entries.skip(currentIndex + 1).toList();
    entries
      ..clear()
      ..addAll([
        ...prefix,
        ...upcoming.where((entry) => entry.isManual),
        ...upcoming.where((entry) => !entry.isManual),
      ]);
  }
}
