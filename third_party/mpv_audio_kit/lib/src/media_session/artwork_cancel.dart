// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';

import '../models/cover_art.dart';

/// The request to stop one artwork load: the track changed, the session
/// went off, or the load ran past its time limit. A fetcher that takes one
/// drops what it holds (its connection, its fetch) when [whenCancelled]
/// completes, and its result is then ignored. Plain Dart, so the download
/// of dart:io and the one of the browser can both take it.
@internal
final class ArtworkCancel {
  final Completer<void> _cancelled = Completer<void>();

  /// Whether [cancel] was called.
  bool get isCancelled => _cancelled.isCompleted;

  /// Completes when [cancel] is called, and never otherwise.
  Future<void> get whenCancelled => _cancelled.future;

  /// Asks the load to stop. A second call does nothing.
  void cancel() {
    if (!_cancelled.isCompleted) _cancelled.complete();
  }
}

/// An `ArtworkFetcher` that stops when [cancel] asks: `null` then, as on
/// any failure.
@internal
typedef CancellableArtworkFetcher =
    Future<CoverArt?> Function(
      String url,
      List<String> caFiles,
      ArtworkCancel cancel,
    );
