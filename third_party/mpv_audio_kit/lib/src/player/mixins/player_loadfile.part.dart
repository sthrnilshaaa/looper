// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

part of '../player.dart';

/// Test only: the keys of the [Media] cache of [player]. Not exported, as
/// [debugBeforePcmCutRemove].
@visibleForTesting
Set<String> debugMediaCacheKeys(Player player) =>
    player._mediaCache.byUri.keys.toSet();

/// The `loadfile` of a [Media] with its entry bookkeeping (the entry in
/// [_PlayerBase._entries], the live source it holds). The calls
/// themselves go through [_PlayerBase._calls] ([CoreCalls]), on the async
/// client API.
mixin _LoadfileModule on _PlayerBase, _PcmCutModule, _PropertiesModule {
  /// Runs a `loadfile` [args] for [media] and records the new playlist
  /// entry's id, so the playlist maps that entry back to [media] even when
  /// another entry has the same URI. Hands [source] over to the entry as
  /// the command goes out. Throws like [CoreCalls.commandChecked].
  Future<void> _loadfile(
    List<String> args,
    Media media,
    OwnedSource source,
  ) async {
    final id = await _loadfileEntry(args, media, source);
    if (id != null) _remapReported({id});
  }

  /// The part of [_loadfile] before the remap: runs the command and
  /// records the entry, returning its id. A batch of appends remaps once,
  /// after the last reply, instead of once per entry.
  Future<int?> _loadfileEntry(
    List<String> args,
    Media media,
    OwnedSource source,
  ) async {
    final reply = _calls.commandResult(args);
    // Sent: mpv has the entry from now on, even if a later load supersedes
    // this one before the reply (F6). Only a refusal gives the source back.
    final entry = _entries.pending(args[1], media, source.handOver());
    final (rc, result) = await reply;
    if (rc < 0) {
      source.revoke();
      _entries.drop(entry);
      throw MpvCommandException(
        name: args.first,
        code: rc,
        message: _calls.errorString(rc),
      );
    }
    final id = result is Map ? result['playlist_entry_id'] : null;
    final entryId = id is int ? id : null;
    _entries.onAdded(entry, entryId, live: _liveSource(media));
    return entryId;
  }

  /// mpv may report the playlist before the `loadfile` replies, and a
  /// FILE_LOADED may read it: when the last playlist node the state was
  /// parsed from already lists one of [ids], parse it again so the entries
  /// map to their [Media].
  void _remapReported(Set<int> ids) {
    final node = _entries.lastNode;
    if (node is List &&
        node.any((entry) => entry is Map && ids.contains(entry['id']))) {
      _updatePlaylistFromNode(node);
    }
  }
}
