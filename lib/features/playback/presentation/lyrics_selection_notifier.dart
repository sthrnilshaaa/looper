import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'lyrics_selection_notifier.g.dart';

/// A contiguous range of lyric-line indices the user has picked to share,
/// e.g. via long-press-then-tap in [AdvancedLyricLine]. `null` bounds mean
/// no selection is active.
class LyricsSelectionState {
  final int? anchorIndex;
  final int? startIndex;
  final int? endIndex;

  const LyricsSelectionState({this.anchorIndex, this.startIndex, this.endIndex});

  bool get isActive => startIndex != null && endIndex != null;

  int get count => isActive ? (endIndex! - startIndex! + 1) : 0;

  bool contains(int index) => isActive && index >= startIndex! && index <= endIndex!;
}

/// Drives the "select lyric lines to share" flow on the Lyrics screen.
/// Long-pressing a line starts a selection anchored at that line; tapping
/// another line while a selection is active extends (or shrinks) the range
/// towards it, capped at [maxLines] so the resulting share card stays
/// legible.
@riverpod
class LyricsSelection extends _$LyricsSelection {
  static const int maxLines = 6;

  @override
  LyricsSelectionState build() => const LyricsSelectionState();

  void startSelection(int index) {
    state = LyricsSelectionState(anchorIndex: index, startIndex: index, endIndex: index);
  }

  void extendTo(int index) {
    if (!state.isActive) {
      startSelection(index);
      return;
    }
    final anchor = state.anchorIndex!;

    // Tapping the sole selected (anchor) line again deselects it.
    if (state.count == 1 && index == anchor) {
      clear();
      return;
    }

    int newStart = index < anchor ? index : anchor;
    int newEnd = index > anchor ? index : anchor;
    if (newEnd - newStart + 1 > maxLines) {
      if (index < anchor) {
        newStart = anchor - (maxLines - 1);
      } else {
        newEnd = anchor + (maxLines - 1);
      }
    }
    state = LyricsSelectionState(anchorIndex: anchor, startIndex: newStart, endIndex: newEnd);
  }

  void clear() => state = const LyricsSelectionState();
}
