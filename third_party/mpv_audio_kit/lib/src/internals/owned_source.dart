// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'package:meta/meta.dart';

import 'uri_resolver.dart';

/// A resolved source that a load call still owns: its platform resource
/// (an Android `content://` descriptor) is the call's to release until it
/// hands the source over to mpv.
///
/// The hand-over happens when the `loadfile` goes out, not at its reply:
/// a later load may supersede the call while the reply is on its way, and
/// mpv has the entry by then. Only a refusal from mpv gives the source back
/// ([revoke]). A load path releases what it owns in a `finally`, so every
/// way out (a later load, an error, a refusal) releases it once.
@internal
final class OwnedSource {
  /// Owns [resolved] until [handOver].
  OwnedSource(this._resolved);

  final ResolvedUri _resolved;
  bool _handedOver = false;
  bool _released = false;

  /// The URI as libmpv accepts it.
  String get uri => _resolved.uri;

  /// The source went to mpv: [release] does nothing from now on. Returns
  /// the release of the resource, for the keeper that takes it over (the
  /// playlist entry, an `audio-add` track), `null` when the resolution
  /// allocated nothing. The keeper's release and this one run the resource
  /// release once between them.
  Future<void> Function()? handOver() {
    _handedOver = true;
    return _resolved.dispose == null ? null : _releaseOnce;
  }

  /// mpv refused the source: it is the call's again.
  void revoke() => _handedOver = false;

  /// Releases the resource, once, unless the source was handed over.
  Future<void> release() async {
    if (_handedOver) return;
    await _releaseOnce();
  }

  Future<void> _releaseOnce() async {
    if (_released) return;
    _released = true;
    await _resolved.dispose?.call();
  }
}
