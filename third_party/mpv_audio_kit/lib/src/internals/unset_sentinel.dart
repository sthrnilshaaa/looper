// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

/// Sentinel used by `copyWith` implementations to tell "not passed"
/// apart from "explicitly set to null".
///
/// Hand-rolled `copyWith` for nullable fields needs a way to
/// distinguish a caller-omitted field (preserve current value) from
/// `null` (set the field to null). Default-`null` parameters can't —
/// they collapse the two cases. This sentinel does the disambiguation:
/// declare the parameter as `Object? field = unset`, then in the body
/// `identical(field, unset) ? this.field : field as T?`.
///
/// Internal — every value type with nullable fields imports this and
/// uses the shared [unset] constant instead of declaring its own
/// per-file copy.
@internal
class UnsetSentinel {
  const UnsetSentinel();
}

/// The single shared sentinel instance. `identical(value, unset)` is
/// the disambiguating check.
@internal
const UnsetSentinel unset = UnsetSentinel();
