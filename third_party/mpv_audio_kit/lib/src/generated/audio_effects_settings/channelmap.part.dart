// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license
// that can be found in the LICENSE file.
//
// AUTO-GENERATED: do not edit by hand.
//
// The descriptions of the filters and of their options in the
// documentation comments are FFmpeg's (doc/filters.texi and the option
// help of libavfilter, https://ffmpeg.org) and keep FFmpeg's licenses: the
// LGPL, version 2.1 or later (FFmpeg's LICENSE.md), and for the option help of
// deesser, arnndn and hdcd the MIT or BSD terms of their source files; the BSD
// 3-Clause license above covers the rest of this file.
// ignore_for_file: unnecessary_ignore, non_constant_identifier_names, constant_identifier_names, camel_case_types, curly_braces_in_flow_control_structures, prefer_adjacent_string_concatenation, prefer_interpolation_to_compose_strings

part of '../audio_effects_settings.dart';

/// Configuration for the `channelmap` audio effect.
///
/// Remap input channels to new locations.
///
/// It accepts the following parameters:
///
/// Parameters:
/// - [channelLayout]: The channel layout of the output stream. If not specified, then filter will guess it based on the `out_channel` names or the number of mappings. Guessed layouts will not necessarily contain channels in the order of the mappings.
/// - [map]: Map channels from input to output. The argument is a '|'-separated list of mappings, each in the `@var{in_channel`-`out_channel`} or `@var{in_channel`} form. `in_channel` can be either the name of the input channel (e.g. FL for front left) or its index in the input channel layout. `out_channel` is the name of the output channel or its index in the output channel layout. If `out_channel` is not given then it is implicitly an index, starting with zero and increasing by one for each mapping. Mixing different types of mappings is not allowed and will result in a parse error.
final class ChannelmapEffect extends AudioEffect {
  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// Output channel layout.
  final String? channelLayout;

  /// A comma-separated list of input channel numbers in output order.
  final String map;

  /// Creates an [ChannelmapEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const ChannelmapEffect({
    this.enabled = true,
    this.channelLayout,
    required this.map,
  });

  @override
  String get filterName => 'channelmap';

  @override
  AudioFilter get filter => AudioFilter.channelmap;

  /// Returns a copy of this [ChannelmapEffect] with the given fields replaced.
  ChannelmapEffect copyWith({
    bool? enabled,
    Object? channelLayout = unset,
    String? map,
  }) => ChannelmapEffect(
    enabled: enabled ?? this.enabled,
    channelLayout: identical(channelLayout, unset)
        ? this.channelLayout
        : channelLayout as String?,
    map: map ?? this.map,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChannelmapEffect &&
          other.enabled == enabled &&
          other.channelLayout == channelLayout &&
          other.map == map);

  @override
  int get hashCode => Object.hash(enabled, channelLayout, map);

  @override
  String toString() =>
      'ChannelmapEffect(enabled: $enabled, channelLayout: $channelLayout, map: $map)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    final parts = <String>[];
    if (channelLayout != null)
      parts.add('channel_layout=' + _wireString(channelLayout!));
    parts.add('map=' + _wireString(map));
    return parts.isEmpty
        ? 'lavfi-channelmap'
        : 'lavfi-channelmap=' + parts.join(':');
  }
}
