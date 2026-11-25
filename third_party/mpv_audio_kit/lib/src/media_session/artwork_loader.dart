// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';

import '../models/cover_art.dart';
import 'artwork_cancel.dart';
import 'artwork_fetcher.dart';
import 'artwork_sources.dart';

/// Loads the artwork URLs of the media session, one at a time, and keeps
/// the last few covers.
///
/// - A new [load] cancels the one in flight: skipping through tracks
///   leaves one download running, not one per track.
/// - A load ends at [timeLimit] whatever the server does. The timeouts of
///   the download are between two steps, and a server that sends a little
///   every few seconds passes them forever.
/// - The last [capacity] covers are kept, within [byteBudget] in all, so
///   going back to the previous track loads nothing. A failure is not
///   kept: whoever asked decides when to try again.
@internal
class ArtworkLoader {
  /// A loader over [_fetch], which gets the [ArtworkCancel] of each load.
  ArtworkLoader(
    this._fetch, {
    this.timeLimit = const Duration(seconds: 60),
    this.capacity = 4,
    this.byteBudget = maxArtworkBytes,
  }) : assert(capacity > 0);

  /// A loader over an [ArtworkFetcher] that cannot be cancelled: a load
  /// still ends at the time limit or at the next load, and the fetch that
  /// was left runs to its own end with its result dropped.
  ArtworkLoader.uncancellable(
    ArtworkFetcher fetch, {
    Duration timeLimit = const Duration(seconds: 60),
    int capacity = 4,
  }) : this(
         (url, caFiles, _) => fetch(url, caFiles),
         timeLimit: timeLimit,
         capacity: capacity,
       );

  /// A loader over the platform's `loadArtwork`. The one of dart:io takes
  /// the [ArtworkCancel] and closes its connection, the one of the browser
  /// aborts its fetch.
  factory ArtworkLoader.platform({
    Duration timeLimit = const Duration(seconds: 60),
  }) {
    const Function fetch = loadArtwork;
    return fetch is CancellableArtworkFetcher
        ? ArtworkLoader(fetch, timeLimit: timeLimit)
        : ArtworkLoader.uncancellable(loadArtwork, timeLimit: timeLimit);
  }

  final CancellableArtworkFetcher _fetch;

  /// The longest a load runs, from its start to its last byte.
  final Duration timeLimit;

  /// How many covers are kept.
  final int capacity;

  /// The bytes the kept covers hold together at most. The newest is kept
  /// whatever its size.
  final int byteBudget;

  // The kept covers, the least recently used first.
  final Map<String, CoverArt> _kept = <String, CoverArt>{};
  ArtworkCancel? _inFlight;

  static String _key(String url, List<String> caFiles) =>
      '${caFiles.join('\n')}\n$url';

  /// The kept cover of [url] as loaded with [caFiles], or `null`.
  CoverArt? cached(String url, List<String> caFiles) {
    final key = _key(url, caFiles);
    final cover = _kept.remove(key);
    if (cover != null) _kept[key] = cover;
    return cover;
  }

  /// The cover of [url], from the kept ones or loaded with [caFiles];
  /// `null` when the load fails, runs past [timeLimit], or is cancelled by
  /// [cancel] or by the next [load]. Never completes with an error.
  Future<CoverArt?> load(String url, List<String> caFiles) {
    cancel();
    final kept = cached(url, caFiles);
    if (kept != null) return Future<CoverArt?>.value(kept);

    final token = ArtworkCancel();
    _inFlight = token;
    final result = Completer<CoverArt?>();
    final limit = Timer(timeLimit, token.cancel);
    void finish(CoverArt? cover) {
      if (result.isCompleted) return;
      limit.cancel();
      if (identical(_inFlight, token)) _inFlight = null;
      result.complete(cover);
    }

    unawaited(token.whenCancelled.then((_) => finish(null)));
    unawaited(
      Future<CoverArt?>.sync(() => _fetch(url, caFiles, token)).then((cover) {
        if (cover != null && !token.isCancelled) _keep(url, caFiles, cover);
        finish(token.isCancelled ? null : cover);
      }, onError: (Object _) => finish(null)),
    );
    return result.future;
  }

  /// Cancels the load in flight, if any: its future completes with `null`.
  void cancel() {
    _inFlight?.cancel();
    _inFlight = null;
  }

  void _keep(String url, List<String> caFiles, CoverArt cover) {
    final key = _key(url, caFiles);
    _kept.remove(key);
    _kept[key] = cover;
    int bytes() => _kept.values.fold(0, (sum, c) => sum + c.bytes.length);
    while (_kept.length > 1 &&
        (_kept.length > capacity || bytes() > byteBudget)) {
      _kept.remove(_kept.keys.first);
    }
  }
}
