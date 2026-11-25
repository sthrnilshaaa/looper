// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'package:meta/meta.dart';

import '../models/media.dart';

/// The [Media] of each URL a player loaded, by URL: the playlist reports
/// and the source resolver get the caller's [Media] back from the name mpv
/// holds. It keeps only what mpv can still name: see [prune] and
/// [putResolved].
@internal
final class MediaCache {
  /// The [Media] by URL, as `parsePlaylistNode` reads it.
  final Map<String, Media> byUri = {};

  /// The keys a source resolver gave, which [putResolved] turns over.
  final Set<String> _resolved = {};

  /// How many add, insert and replace calls are between their first write
  /// and mpv's answer: [prune] waits meanwhile.
  int entryLoads = 0;

  /// The [Media] cached under [uri].
  Media? operator [](String uri) => byUri[uri];

  /// Caches [media] under [uri], for a load of the player.
  void operator []=(String uri, Media media) => byUri[uri] = media;

  /// Empties the cache: a load replaces the playlist.
  void clear() {
    byUri.clear();
    _resolved.clear();
  }

  /// Keeps only the keys of [current], or none when it is `null`.
  void keepOnly(Media? current) {
    byUri.removeWhere((_, media) => current == null || media != current);
    _resolved.retainAll(byUri.keys);
  }

  /// Caches [media] under [target], the URL a resolver gave for it. With
  /// [load] (the URL of the load under way) the URLs of earlier loads
  /// leave the cache, except [kept], the one held for the prefetch: a
  /// resolver that gives a new URL at each load (a signed URL under a
  /// looping playlist) would grow it by one key a load.
  void putResolved(
    String target,
    Media media, {
    required bool load,
    String? kept,
  }) {
    if (load) {
      _resolved.removeWhere((key) {
        if (key == target || key == kept) return false;
        byUri.remove(key);
        return true;
      });
    }
    // A key a load of the player wrote stays that load's.
    if (!byUri.containsKey(target)) _resolved.add(target);
    byUri[target] = media;
  }

  /// Drops the keys of entries mpv no longer lists in the playlist node
  /// [raw]: without it a queue fed by add and remove, never opened again,
  /// kept a key for every URL it ever held. A key stays while its [Media]
  /// is one of [live] (the entries of the player), while mpv lists it as a
  /// filename, and while it is a resolver's ([putResolved] turns those
  /// over). Not while a load is under way ([busy], or [entryLoads]): its
  /// keys are written before mpv has the entry.
  void prune(Object? raw, Iterable<Media> live, {required bool busy}) {
    if (byUri.isEmpty || busy || entryLoads > 0 || raw is! List) return;
    final held = Set<Media>.identity()..addAll(live);
    final listed = <Object?>{
      for (final entry in raw)
        if (entry is Map) entry['filename'],
    };
    byUri.removeWhere(
      (key, media) =>
          !held.contains(media) &&
          !listed.contains(key) &&
          !_resolved.contains(key),
    );
  }
}
