import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'lyrics_search_provider.g.dart';

/// Tracks the current search query specifically for lyrics highlighting and
/// scrolling.
@Riverpod(keepAlive: true)
class LyricsSearchQuery extends _$LyricsSearchQuery {
  @override
  String build() => '';

  void clear() => state = '';
}
