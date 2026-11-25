// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
part of 'player.dart';

/// The source resolver of a player ([Player.setSourceResolver]): the
/// resolver installed, the single retry of a load it allows, and the URL
/// it gave for the prefetch of the next entry, which the load of that
/// entry takes once. [_HooksModule] runs it from the `on_load`,
/// `on_load_fail` and `on_prefetch` hooks.
final class _SourceResolverDriver {
  _SourceResolverDriver(this._player);

  final _PlayerBase _player;

  // The installed [SourceResolver]; null = feature off. Set by
  // [Player.setSourceResolver], consulted by `_routeHookEvent` on every
  // `on_load`, `on_load_fail` or `on_prefetch` event.
  SourceResolver? _installed;

  /// The installed [SourceResolver], `null` when the feature is off.
  SourceResolver? get installed => _installed;

  // Latched when the resolver services an `on_load_fail` for the current
  // load attempt, cleared on the next START_FILE only (not on `on_load`,
  // which mpv re-enters for the same attempt after the retry). Caps the
  // resolver-driven retry at ONE per load: a resolver that keeps minting
  // fresh-but-broken URLs (e.g. a timestamped query string) would
  // otherwise put mpv in an infinite open-fail-reopen loop.
  bool _retried = false;

  // What the resolver gave for the prefetch of the next entry: the URL mpv
  // was about to open (`from`), the one it opened instead (`to`), the load
  // epoch then (`load`), and the entry (`null` when its read failed). The
  // load of that entry, or of that URL without one, in the same epoch takes
  // it once (F10, kit-core-3).
  ({String from, String to, _LoadTicket load, int? entry})? _prefetched;

  /// Installs [resolver], `null` to turn the feature off. A URL kept from
  /// the prefetch of the resolver before is dropped.
  void install(SourceResolver? resolver) {
    _installed = resolver;
    _prefetched = null;
  }

  /// A new load attempt (START_FILE) re-arms the single retry: see
  /// [_retried].
  void onStartFile() => _retried = false;

  /// One resolver pass: read the URL mpv is about to open, look up the
  /// original [Media] of the entry, invoke the consumer callback, and
  /// rewrite `stream-open-filename` (`prefetch-open-filename` for
  /// `on_prefetch`) when it returns a different URL.
  ///
  /// A result that comes back once the hook is no longer [pending] (the
  /// deadline continued it) is dropped: mpv is past that load, and the
  /// write would land on whatever entry is loading now.
  ///
  /// Never throws: the hook MUST reach its continue in
  /// `_HooksModule._routeHookEvent` regardless of what the consumer
  /// callback does, so failures are logged on [PlayerStream.internalLog]
  /// and resolution is skipped.
  Future<void> run(
    SourceResolver resolver,
    Hook hook,
    bool Function() pending,
  ) async {
    try {
      final isRetry = hook == Hook.loadFail;
      // One resolver-driven retry per load attempt: see
      // [_retried] for the loop hazard this caps. The flag is
      // cleared on START_FILE only, NOT on `on_load`: after an
      // `on_load_fail` rewrite mpv re-enters the load cycle from
      // `on_load` for the same attempt, and re-arming there would
      // reopen the infinite loop the flag exists to prevent.
      if (isRetry && _retried) return;
      // The entry mpv is loading, `null` outside a START_FILE.
      final loading = _player._entries.loading;
      // mpv runs `on_prefetch` for the prefetch of the next entry.
      final early = hook == Hook.prefetch;
      // The load epoch mpv asked in: an open, stop or clear while the
      // resolver runs supersedes the URL it gives for the prefetch.
      final asked = _player._transport.snapshotLoad();
      final current =
          await _player._readString(
            early ? 'prefetch-open-filename' : 'stream-open-filename',
          ) ??
          '';
      if (current.isEmpty || _player._disposed) return;
      // A load gets the Media of its own entry, which another entry with the
      // same URL does not share (F14). So does the prefetch, which names its
      // entry.
      final entry = early ? await _prefetchEntryId() : loading;
      final media =
          _player._entries.mediaOf(entry) ??
          _cachedMedia(current) ??
          Media(current);
      final target = await _targetUrl(
        resolver,
        SourceResolveRequest(media: media, uri: current, isRetry: isRetry),
        takesKept: !isRetry && !early,
        loading: loading,
      );
      if (target == null) return;
      if (early) {
        await _settlePrefetch(current, target, media, asked, pending, entry);
        return;
      }
      if (target == current) return;
      // No timer runs between this check and the write below: the write is
      // queued in mpv before control goes back to the event loop.
      if (!pending()) {
        _player._internalLog(
          'Source resolver for ${hook.mpvValue} returned after its hook '
          'timed out; the result is dropped',
          level: LogLevel.warn,
        );
        return;
      }
      if (isRetry) _retried = true;
      await _player._calls.prop('stream-open-filename', target);
      // Keep the original Media reachable under the rewritten URL, so a
      // later `on_load_fail` on this entry (expired token on the resolved
      // URL) still hands the resolver the same Media and extras.
      _player._mediaCache.putResolved(
        target,
        media,
        load: true,
        kept: _prefetched?.to,
      );
    } catch (e, st) {
      _player._internalLog(
        'Source resolver threw for ${hook.mpvValue}: $e\n$st',
        level: LogLevel.warn,
      );
    }
  }

  /// The URL to open for [request], `null` once the player was disposed.
  /// The load of an entry the prefetch resolved ([takesKept], the entry
  /// [loading]) opens the same URL without asking again: a resolver that
  /// gives a new URL on every call (a salt, a signed URL) would make mpv
  /// drop the prefetch. Another entry with the same URL asks for its own
  /// [Media]. A retry asks as before, so an expired URL is still renewed.
  Future<String?> _targetUrl(
    SourceResolver resolver,
    SourceResolveRequest request, {
    required bool takesKept,
    required int? loading,
  }) async {
    final current = request.uri;
    if (takesKept) {
      final kept = _prefetched;
      _prefetched = null;
      if (kept != null &&
          kept.from == current &&
          !kept.load.superseded &&
          (kept.entry == null || kept.entry == loading)) {
        return kept.to;
      }
    }
    final resolved = await resolver(request);
    if (_player._disposed) return null;
    // A file:// URL goes to mpv as its path, as the URL of a Media does:
    // the waveform and loudness scans hand the name to FFmpeg, whose file
    // protocol does not decode it.
    return resolved == null || resolved.isEmpty
        ? current
        : fileUrlToPath(resolved) ?? resolved;
  }

  /// The `playlist_entry_id` of the entry `on_prefetch` opens, `null` when
  /// mpv dropped the prefetch.
  Future<int?> _prefetchEntryId() async {
    final (rc, id) = await _player._calls.get(
      'prefetch-playlist-entry-id',
      MpvFormat.mpvFormatInt64,
    );
    return rc < 0 || id is! int ? null : id;
  }

  /// Hands mpv the URL the resolver gave for the prefetch ([target], for
  /// [current]) and keeps it for the load of [entry] in the epoch mpv
  /// [asked] in, only while mpv still holds the prefetch: when the entry
  /// starts, or leaves the next place, before the resolver returns, mpv
  /// drops it, and the write (or, for an unchanged URL, the read) of
  /// `prefetch-open-filename` fails. The load then asks the resolver again.
  Future<void> _settlePrefetch(
    String current,
    String target,
    Media media,
    _LoadTicket asked,
    bool Function() pending,
    int? entry,
  ) async {
    final changed = target != current;
    // As for a load: no timer runs between this check and the request.
    if (!pending()) {
      if (changed) {
        _player._internalLog(
          'Source resolver for on_prefetch returned after its hook timed '
          'out; the result is dropped',
          level: LogLevel.warn,
        );
      }
      return;
    }
    final rc = changed
        ? await _player._calls.propRc('prefetch-open-filename', target)
        : (await _player._calls.get(
            'prefetch-open-filename',
            MpvFormat.mpvFormatString,
          )).$1;
    if (_player._disposed) return;
    if (rc < 0) {
      if (changed) {
        _player._internalLog(
          'Source resolver for on_prefetch returned after mpv dropped the '
          'prefetch; the result is dropped',
          level: LogLevel.warn,
        );
      }
      return;
    }
    _prefetched = (from: current, to: target, load: asked, entry: entry);
    if (changed) _player._mediaCache.putResolved(target, media, load: false);
  }

  /// The [Media] cached under [uri]. On Windows mpv hands a local path
  /// back with backslashes, so a path the resolver returned with forward
  /// slashes is matched with the separators ignored.
  Media? _cachedMedia(String uri) {
    final hit = _player._mediaCache[uri];
    if (hit != null || !hostIsWindows) return hit;
    final key = uri.replaceAll('/', r'\');
    for (final entry in _player._mediaCache.byUri.entries) {
      if (entry.key.replaceAll('/', r'\') == key) return entry.value;
    }
    return null;
  }
}
