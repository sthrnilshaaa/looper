// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

/// The equality of collections the models compare by content, written
/// once. Elements and values compare by `==`. The models are plain Dart,
/// so they do not import the ones of `package:flutter/foundation.dart`.
library;

/// Whether [a] and [b] hold equal elements in the same order. This is
/// the comparison of two lists, and of two sets whose order counts.
bool iterableEq<T>(Iterable<T>? a, Iterable<T>? b) {
  if (identical(a, b)) return true;
  if (a == null || b == null || a.length != b.length) return false;
  final others = b.iterator;
  for (final element in a) {
    if (!others.moveNext() || element != others.current) return false;
  }
  return true;
}

/// Whether [a] and [b] hold the same keys with equal values, in any
/// order. A key missing from one is not a key with a null value.
bool mapEq<K, V>(Map<K, V>? a, Map<K, V>? b) {
  if (identical(a, b)) return true;
  if (a == null || b == null || a.length != b.length) return false;
  for (final entry in a.entries) {
    if (!b.containsKey(entry.key) || b[entry.key] != entry.value) return false;
  }
  return true;
}

/// A hash of [map] that agrees with [mapEq]: the same for the same
/// entries in any order, `null` for no map.
int? mapHash<K, V>(Map<K, V>? map) => map == null
    ? null
    : Object.hashAllUnordered(
        map.entries.map((e) => Object.hash(e.key, e.value)),
      );
