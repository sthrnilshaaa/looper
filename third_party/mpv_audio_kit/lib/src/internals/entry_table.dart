// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';

import 'package:meta/meta.dart';

import '../models/media.dart';

/// A live source an entry holds (a `PcmSource`): [key] tells two entries
/// of the same source apart from two sources, [done] completes when the
/// source is through, and [end] ends it unread.
@internal
typedef LiveSource = ({Object key, Future<void> done, void Function() end});

/// The playlist entries the player loaded, by mpv's `playlist_entry_id`:
/// the [Media] of each one, and what it holds until mpv can no longer read
/// it.
///
/// An entry holds at most one resource, with its own policy:
/// - a live source ends as soon as the entry leaves the playlist, unless
///   another entry holds it: nothing reads it again;
/// - a release (the descriptor behind an `fd://` URI, which mpv never
///   closes and reads again on every open of the entry) runs once a file
///   started after the entry left, and that start settled (the file loaded
///   or failed): the stream on its way out and a prefetch of the entry may
///   still read it until then;
/// - an entry with only its [Media] holds nothing.
///
/// One rule tells that an entry left: a playlist taken after mpv added the
/// entry does not list it. mpv numbers the entries in order, so a report
/// that lists the entry, or a newer one, was taken after it was added.
/// When no report can tell yet whether an entry with a live source left
/// (the observation merges changes: a stop right after the load), the
/// table reads the playlist again: a read issued after the entry was added
/// tells it too.
///
/// An external track (`audio-add`) belongs to the file it was added to:
/// mpv closes its stream when that file ends, before it reports the end
/// (END_FILE). So its release runs at the first file end after mpv took
/// the track.
@internal
final class EntryTable {
  /// A table that reads mpv's playlist with [readPlaylist] (`null` when the
  /// read failed), [confirmDelay] after a live source was added.
  EntryTable({
    required this.readPlaylist,
    this.confirmDelay = const Duration(milliseconds: 300),
  });

  /// Reads mpv's playlist now, for the entries with a live source.
  final Future<List<Object?>?> Function() readPlaylist;

  /// How long after a live source is added the playlist is read: mpv does
  /// not always report the playlist again when the entry goes (a stop while
  /// idle after a failed load).
  final Duration confirmDelay;

  final _byId = <int, EntryRecord>{};
  // Entries without an id yet (the loadfile reply is on its way) or ever
  // (the reply carried none), which hold a release: a report names them by
  // their URI only.
  final _unnumbered = <EntryRecord>{};
  final _tracks = <_Track>{};
  Object? _lastNode;
  int _newestListed = -1;
  int? _loading;
  // The entry of the last START_FILE, with its Media then: its END_FILE
  // reports it even after a report took it out of the playlist (a stop, a
  // replace).
  (int, Media?)? _started;
  int _starts = 0;
  int _ends = 0;
  // A playlist read for the live sources is under way, and whether another
  // report asked for one meanwhile.
  bool _confirming = false;
  bool _confirmAgain = false;
  Timer? _confirmTimer;
  bool _liveEnded = false;

  /// The [Media] of each entry still in the playlist, by entry id. Unlike a
  /// map by URI, two entries with the same URI keep their own `extras`.
  late final Map<int, Media> media = _MediaView(this);

  /// The last `playlist` node the state was parsed from, a report
  /// ([onPlaylist]) or the read of a FILE_LOADED ([onLoadedNode]). Parsed
  /// again when a `loadfile` reply registers an entry id after the state
  /// already listed the entry.
  Object? get lastNode => _lastNode;

  /// The entry mpv is loading: from its START_FILE to the FILE_LOADED or
  /// END_FILE of that load. The prefetch of the next entry, which mpv runs
  /// while the current file plays, runs `on_prefetch` instead.
  int? get loading => _loading;

  /// The entry [Player.openAll] keeps playing while it puts the new ones
  /// in, until it removes it; `null` outside that call.
  int? retained;

  /// Where the playlist the state shows left [retained] out of mpv's, or
  /// `null`: the indices of the state from there on are one less than
  /// mpv's.
  int? hiddenAt;

  /// mpv's index for the [index] of the state.
  int toCore(int index) {
    final at = hiddenAt;
    return at != null && index >= at ? index + 1 : index;
  }

  /// The count of the state for mpv's [count].
  int fromCoreCount(int count) =>
      hiddenAt != null && count > 0 ? count - 1 : count;

  /// The [Media] the entry [id] was loaded with, `null` when the player
  /// did not load it (a `loadlist`, a raw command) or let it go.
  Media? mediaOf(int? id) => _byId[id]?.media;

  /// A `loadfile` of [uri] for [media] went out: mpv has the entry from now
  /// on, and [release], when there is one, is the table's to run. Pass the
  /// result to [onAdded] with the reply, or to [drop] when mpv refused it.
  EntryRecord pending(
    String uri,
    Media media,
    Future<void> Function()? release,
  ) {
    final entry = EntryRecord._(uri, media, release);
    if (release != null) _unnumbered.add(entry);
    return entry;
  }

  /// mpv refused the `loadfile` of [entry]: its release goes back to the
  /// load call.
  void drop(EntryRecord entry) => _unnumbered.remove(entry);

  /// mpv accepted the `loadfile` of [entry] as entry [id] (`null` when the
  /// reply carried no id), with [live] the live source it plays. A report
  /// taken after that which does not list it means it left, even when no
  /// report ever listed it: the next load can replace it first.
  void onAdded(EntryRecord entry, int? id, {LiveSource? live}) {
    if (id == null) return;
    _unnumbered.remove(entry);
    _byId[id] = entry;
    if (live == null) return;
    entry._live = live;
    _confirmTimer?.cancel();
    _confirmTimer = Timer(confirmDelay, () {
      _confirmTimer = null;
      if (_holdsAnyLive) _confirm();
    });
    unawaited(live.done.then((_) => _detachLive(live.key)));
  }

  /// The playlist read with a FILE_LOADED, which the state was parsed from.
  /// It can list an entry whose `loadfile` reply is still on its way, as a
  /// report can, so a late reply parses it again. It is not a report for
  /// the rule of [onPlaylist].
  void onLoadedNode(Object? node) {
    if (node != null) _lastNode = node;
  }

  /// A `playlist` report from mpv: the entries it does not list leave by
  /// the rule above.
  void onPlaylist(Object? node) {
    _lastNode = node;
    if (node is! List) return;
    final ids = <int>{};
    final names = <String>{};
    for (final entry in node) {
      if (entry is! Map) continue;
      final id = entry['id'];
      if (id is int) {
        ids.add(id);
        if (id > _newestListed) _newestListed = id;
      }
      final name = entry['filename'];
      if (name is String) names.add(name);
    }
    _leave(ids, _newestListed);
    for (final entry in _unnumbered) {
      if (names.contains(entry.uri)) {
        entry
          .._seen = true
          .._leftAt = null;
      } else if (entry._seen) {
        entry._leftAt ??= _starts;
      }
    }
    if (unseenHeld) _confirm();
  }

  /// Whether an entry with a live source is newer than every entry a
  /// report has listed: no report can tell whether it left.
  @visibleForTesting
  bool get unseenHeld =>
      _byId.entries.any((e) => e.value._live != null && e.key > _newestListed);

  /// The files mpv started (START_FILE) so far: a call that awaits the
  /// core tells by it whether a file started meanwhile.
  int get starts => _starts;

  /// The entry that `Player.stop(keepPlaylist: true)` stopped, which the
  /// next `Player.play` starts again; `null` once any file starts.
  int? stopped;

  /// mpv started the file of entry [id] (START_FILE).
  void onStartFile(int id) {
    stopped = null;
    _starts++;
    _loading = id;
    _started = (id, mediaOf(id));
  }

  /// mpv loaded the file it started (FILE_LOADED), before [takeSettled].
  void onFileLoaded() => _loading = null;

  /// mpv ended the file of entry [id] (END_FILE), before [takeSettled].
  /// Returns the [Media] the entry was loaded with, as [mediaOf] gave it
  /// at its START_FILE.
  Media? onEndFile(int id) {
    _ends++;
    _loading = null;
    final started = _started;
    _started = null;
    if (started != null && started.$1 == id) return started.$2 ?? mediaOf(id);
    return mediaOf(id);
  }

  /// Holds [release] for an external track about to be added to the
  /// current file. Returns the call to make with the outcome of the add:
  /// once mpv took the track the hold lasts until that file ends,
  /// otherwise it runs the release now.
  Future<void> Function(bool added) holdTrack(Future<void> Function() release) {
    final track = _Track(release);
    _tracks.add(track);
    return (added) async {
      if (added && !track.done) {
        // A file end already reported belongs to an earlier file.
        track.addedAt = _ends;
        return;
      }
      _tracks.remove(track);
      await track.run();
    };
  }

  /// mpv loaded a file or ended one (FILE_LOADED, END_FILE): returns the
  /// releases whose entry left before the last file start, and those of
  /// the tracks of a file that ended since.
  List<Future<void> Function()> takeSettled() {
    final out = <Future<void> Function()>[];
    bool settled(EntryRecord entry) {
      final left = entry._leftAt;
      if (left == null || left >= _starts) return false;
      out.add(entry._run);
      return true;
    }

    _byId.removeWhere((_, entry) => settled(entry));
    _unnumbered.removeWhere(settled);
    _tracks.removeWhere((track) {
      final added = track.addedAt;
      if (added == null || added >= _ends) return false;
      out.add(track.run);
      return true;
    });
    return out;
  }

  /// Every release still held, for dispose once mpv is gone.
  List<Future<void> Function()> takeAll() {
    final out = [
      for (final entry in _byId.values)
        if (entry._release != null) entry._run,
      for (final entry in _unnumbered) entry._run,
      for (final track in _tracks) track.run,
    ];
    _byId.removeWhere((_, entry) => entry._release != null);
    _unnumbered.clear();
    _tracks.clear();
    return out;
  }

  /// Whether an entry holds the live source [key].
  bool holdsLive(Object key) =>
      _byId.values.any((entry) => identical(entry._live?.key, key));

  /// The ids of the entries that hold the live source [key].
  Set<int> liveIds(Object key) => {
    for (final MapEntry(key: id, value: entry) in _byId.entries)
      if (identical(entry._live?.key, key)) id,
  };

  /// Ends every live source the table holds (dispose): read or not, the
  /// player will not come back to them.
  void endLive() {
    _liveEnded = true;
    _confirmTimer?.cancel();
    _confirmTimer = null;
    final ends = <Object, void Function()>{};
    for (final entry in _byId.values) {
      final live = entry._live;
      if (live == null) continue;
      ends[live.key] = live.end;
      entry._live = null;
    }
    for (final end in ends.values) {
      end();
    }
  }

  bool get _holdsAnyLive => _byId.values.any((entry) => entry._live != null);

  /// Applies the rule to the entries a playlist does not list: [listed]
  /// holds the ids it lists, [newest] the newest id known to be older than
  /// it. With [liveOnly] (a read for the live sources) the other entries
  /// wait for a report.
  void _leave(Set<int> listed, int newest, {bool liveOnly = false}) {
    final ends = <Object, void Function()>{};
    _byId.removeWhere((id, entry) {
      if (id > newest || listed.contains(id)) return false;
      final live = entry._live;
      if (live != null) {
        ends[live.key] = live.end;
        entry._live = null;
      }
      // A read for the live sources leaves the rest to the reports.
      if (liveOnly) return false;
      if (entry._release == null) return true;
      entry._leftAt ??= _starts;
      return false;
    });
    // A source another entry still holds plays on there.
    for (final MapEntry(key: key, value: end) in ends.entries) {
      if (!holdsLive(key)) end();
    }
  }

  /// Reads the playlist and ends the live sources of the entries it does
  /// not list. The read is issued after the reply of every entry that holds
  /// one now, so an entry it misses has left the playlist. An entry that
  /// leaves later with no report to tell (a stop while mpv is idle) is
  /// caught by the playlist read that `Player.stop` makes.
  void _confirm() {
    if (_confirming) {
      _confirmAgain = true;
      return;
    }
    _confirming = true;
    var newest = -1;
    for (final MapEntry(key: id, value: entry) in _byId.entries) {
      if (entry._live != null && id > newest) newest = id;
    }
    unawaited(() async {
      try {
        final node = await readPlaylist();
        if (node == null) return;
        _leave(
          {
            for (final entry in node)
              if (entry is Map && entry['id'] is int) entry['id'] as int,
          },
          newest,
          liveOnly: true,
        );
      } finally {
        _confirming = false;
        if (_confirmAgain && !_liveEnded) {
          _confirmAgain = false;
          _confirm();
        }
      }
    }());
  }

  void _detachLive(Object key) {
    for (final entry in _byId.values) {
      if (identical(entry._live?.key, key)) entry._live = null;
    }
  }
}

/// One entry of an [EntryTable], from its `loadfile` on.
@internal
final class EntryRecord {
  EntryRecord._(this.uri, this.media, this._release);

  /// The URI the `loadfile` named, as mpv lists it.
  final String uri;

  /// The [Media] the entry was loaded with.
  final Media media;

  final Future<void> Function()? _release;
  bool _released = false;
  LiveSource? _live;

  /// Whether a report listed the entry by its URI, before it had an id.
  bool _seen = false;

  /// The file-start count when the entry left the playlist.
  int? _leftAt;

  Future<void> _run() async {
    if (_released) return;
    _released = true;
    await _release?.call();
  }
}

class _Track {
  _Track(this._release);

  final Future<void> Function() _release;
  bool done = false;

  /// The file-end count when mpv took the track.
  int? addedAt;

  Future<void> run() async {
    if (done) return;
    done = true;
    await _release();
  }
}

final class _MediaView extends UnmodifiableMapBase<int, Media> {
  _MediaView(this._table);

  final EntryTable _table;

  @override
  Media? operator [](Object? key) {
    final entry = _table._byId[key];
    return entry == null || entry._leftAt != null ? null : entry.media;
  }

  @override
  Iterable<int> get keys => [
    for (final MapEntry(key: id, value: entry) in _table._byId.entries)
      if (entry._leftAt == null) id,
  ];
}
