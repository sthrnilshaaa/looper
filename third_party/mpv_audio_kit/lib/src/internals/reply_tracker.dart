// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';

/// Pairs asynchronous libmpv requests with their replies.
///
/// Every `mpv_*_async` call is tagged with an id from [open]; the event
/// isolate forwards the matching reply and [complete] resolves the
/// request's future with `(error, result)`. Ids stay unique for the
/// tracker's lifetime (a Dart int does not wrap).
class ReplyTracker {
  /// Creates a tracker whose [drain] resolves every pending request with
  /// [drained].
  ReplyTracker({required this.drained});

  /// What [drain] resolves a pending request with.
  final (int, Object?) drained;

  int _nextId = 1;
  final Map<int, Completer<(int, Object?)>> _pending = {};

  /// Whether any request is still waiting for its reply.
  @visibleForTesting
  bool get hasPending => _pending.isNotEmpty;

  /// Starts a request: returns its id and the future its reply resolves.
  (int, Future<(int, Object?)>) open() {
    final id = _nextId++;
    final completer = Completer<(int, Object?)>();
    _pending[id] = completer;
    return (id, completer.future);
  }

  /// Resolves request [id] with its reply. Unknown or already resolved ids
  /// are ignored.
  void complete(int id, int error, [Object? result]) {
    final completer = _pending.remove(id);
    if (completer != null && !completer.isCompleted) {
      completer.complete((error, result));
    }
  }

  /// Resolves request [id] with [rc] and no result: libmpv refused to
  /// enqueue it, so no reply will come.
  void reject(int id, int rc) => complete(id, rc);

  /// Completes when every request pending now has its reply. Requests
  /// opened afterwards are not waited on.
  Future<void> settle() {
    if (_pending.isEmpty) return Future.value();
    return Future.wait([for (final c in _pending.values) c.future]);
  }

  /// Resolves every pending request with [drained]: no reply can arrive
  /// anymore, and a caller awaiting one must not hang.
  void drain() {
    final pending = _pending.values.toList(growable: false);
    _pending.clear();
    for (final completer in pending) {
      if (!completer.isCompleted) completer.complete(drained);
    }
  }
}
