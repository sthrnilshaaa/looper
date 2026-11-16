/// Turns an artist tag like "A / B feat. C" into the separate artists it
/// credits, so every one of them gets an artist page and the song shows up
/// on each.
///
/// Separators come in two strengths:
/// - Strong ones always split: `;`, ` / `, ` | `, `\0` (multi-value tags) and
///   `feat.` / `ft.` / `featuring`.
/// - Weak ones (`,`, `&`, `+`, `/` without spaces, ` x `, ` and `, ` with `,
///   ` vs `) also show up inside band names ("Simon & Garfunkel",
///   "Earth, Wind & Fire", "AC/DC"). They only split when one of the
///   resulting names is already an artist on its own somewhere in the
///   library ([known]).
///
/// Guests after `feat.` (in the artist tag or the title) are always split on
/// `,` and `&`, since a featured list is nearly always separate people.
class ArtistNames {
  ArtistNames._(this._known);

  static const unknown = 'Unknown Artist';

  /// Lower-cased names that appear as an artist on their own.
  final Set<String> _known;

  static final _feat = RegExp(
    r'\s*[(\[]\s*(?:feat\.?|ft\.?|featuring)\s+|\s+(?:feat\.?|ft\.?|featuring)\s+',
    caseSensitive: false,
  );

  static final _strong = RegExp(
    r'\s*(?:;|\u0000)\s*|\s+[/|\\]\s+',
    caseSensitive: false,
  );

  static final _weak = RegExp(
    r'\s*(?:,|&|\+|/)\s*|\s+(?:x|×|and|with|vs\.?)\s+',
    caseSensitive: false,
  );

  static final _guestSplit = RegExp(
    r'\s*(?:;|,|&|/|\u0000)\s*|\s+(?:and|x)\s+',
    caseSensitive: false,
  );

  // Guests named in a title: "Song (feat. A & B)", "Song [ft. A]",
  // "Song (with A)", or an unbracketed trailing "Song feat. A".
  static final _titleGuests = RegExp(
    r'[(\[]\s*(?:feat\.?|ft\.?|featuring|with)\s+([^)\]]+)[)\]]'
    r'|\s(?:feat\.?|ft\.?|featuring)\s+(.+)$',
    caseSensitive: false,
  );

  /// An index that splits on strong separators only.
  static final ArtistNames strongOnly = ArtistNames._(const {});

  /// Builds the index from every artist tag in the library.
  factory ArtistNames.fromTags(Iterable<String?> tags) {
    final known = <String>{};
    for (final tag in tags) {
      final (main, guests) = _splitFeat(tag);
      for (final part in _split(main, _strong)) {
        known.add(part.toLowerCase());
      }
      for (final guest in _split(guests, _guestSplit)) {
        known.add(guest.toLowerCase());
      }
    }
    return ArtistNames._(known);
  }

  /// Whether [tag] has no usable artist.
  static bool isUnknown(String? tag) {
    final t = tag?.trim() ?? '';
    return t.isEmpty || t.toLowerCase() == 'unknown artist';
  }

  /// Every artist credited by a song tagged [tag] and titled [title], main
  /// artists first. Never empty: an untagged song gets [unknown].
  List<String> namesFor(String? tag, [String? title]) {
    final names = <String>[];
    final seen = <String>{};
    void add(String name) {
      final n = name.trim();
      if (n.isNotEmpty && seen.add(n.toLowerCase())) names.add(n);
    }

    if (isUnknown(tag)) {
      add(unknown);
    } else {
      final (main, guests) = _splitFeat(tag);
      for (final part in _split(main, _strong)) {
        final pieces = _split(part, _weak);
        if (pieces.length > 1 &&
            pieces.any((p) => _known.contains(p.toLowerCase()))) {
          pieces.forEach(add);
        } else {
          add(part);
        }
      }
      _split(guests, _guestSplit).forEach(add);
      if (names.isEmpty) add(tag!.trim());
    }

    if (title != null) {
      for (final m in _titleGuests.allMatches(title)) {
        _split(m.group(1) ?? m.group(2) ?? '', _guestSplit).forEach(add);
      }
    }
    return names;
  }

  /// Whether a song tagged [tag] and titled [title] credits [artist].
  bool credits(String? tag, String? title, String artist) {
    final wanted = artist.trim().toLowerCase();
    return namesFor(tag, title).any((name) => name.toLowerCase() == wanted);
  }

  /// The main artist part of [tag] and the featured guests after `feat.`,
  /// with any closing bracket dropped.
  static (String, String) _splitFeat(String? tag) {
    final t = tag?.trim() ?? '';
    final m = _feat.firstMatch(t);
    if (m == null) return (t, '');
    final guests = t.substring(m.end).replaceAll(RegExp(r'[)\]]'), ' ');
    return (t.substring(0, m.start), guests);
  }

  static List<String> _split(String text, RegExp separator) => text
      .split(separator)
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();
}
