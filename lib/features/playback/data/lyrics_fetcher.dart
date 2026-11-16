import 'dart:io';
import 'package:isar_community/isar.dart';
import 'package:path/path.dart' as p;
import 'package:looper_player/core/services/storage/db_service.dart';
import 'lrc_parser.dart';
import 'lyrics_cache.dart';
import 'lyrics_providers/lyrics_http.dart';
import 'lyrics_providers/lyrics_provider_info.dart';
import 'metadata_service.dart';
import 'lyrics_service.dart';

/// Finds a song's lyrics and keeps them.
///
/// Lyrics come in levels ([levelOf]): none, plain text, line by line, word
/// by word, letter by letter. Two rules drive every lookup:
///  - a song only looks online for a level above the one it has, and a
///    higher level replaces a lower one ([upgrade]). Word- and letter-timed
///    lyrics never look again; neither do the user's own text and the
///    provider they picked in the lyrics menu;
///  - no service is asked twice about a song. Its answer - the lyrics, or
///    that it has none - is kept per song in the lyrics cache
///    ([_fromProvider]) and used from then on, across restarts, until the
///    user clears the lyrics cache ([clearAll]). Only a request that didn't
///    get through (timeout, rate limit) is asked again, on a later run.
///
/// The song's chosen lyrics are saved in song.lyrics and the cache file.
/// A first lookup walks one chain and shows the first answer:
///   1. `LOCAL` - the song's own files: embedded tags, then a sidecar
///      .lrc/.txt.
///   2. The first lyrics service switched on in settings.
///   3. With auto-fallback on, the other services that are switched on, in
///      the order the user arranged them ([enabledProviders]).
/// [upgrade] then looks for a better level behind it.
class LyricsFetcher {
  static final LyricsService _service = LyricsService();

  /// The song's own files (embedded tags, sidecar .lrc/.txt).
  static const String local = 'LOCAL';

  /// Every online service, in the default order (see
  /// [LyricsProviderInfo.all]).
  static final List<String> allProviders = [
    for (final p in LyricsProviderInfo.all) p.id,
  ];

  static const String notFound = '[source:not_found]';

  /// The services in the user's order (Settings > Lyrics services),
  /// switched-off ones included.
  static List<String> providerOrder(AppSettings? settings) =>
      LyricsProviderInfo.order(
        settings?.lyricsProviderOrder ?? const [],
        legacyPrimary: settings?.lyricsProvider,
      );

  /// The services lookups ask, in order: [providerOrder] without the ones
  /// the user switched off.
  static List<String> enabledProviders(AppSettings? settings) {
    final off = {
      for (final id in settings?.lyricsProvidersOff ?? const <String>[])
        id.toUpperCase(),
    };
    return [
      for (final id in providerOrder(settings))
        if (!off.contains(id)) id,
    ];
  }

  static final RegExp _sourceTag = RegExp(r'^\[source:[^\]]*\]');
  static final RegExp _enhancedWordTag = RegExp(r'<\d{1,3}:\d{2}');

  static final RegExp _lineTimeTag = RegExp(
    r'\[\d{1,3}:\d{2}(?:[:\.]\d{2,3})?\]',
  );
  static final RegExp _leadingTimeTags = RegExp(
    r'^(?:\[\d{1,3}:\d{2}(?:[:\.]\d{2,3})?\])+',
  );
  static final RegExp _timingLine = RegExp(r'^\[w:([0-9,;]*)\]$');
  static final RegExp _bgLine = RegExp(r'^\[bg:(.*)\]$');

  static String cleanTitle(Song song) => song.title.trim();

  static String cleanArtist(Song song) =>
      (song.artist ?? 'Unknown Artist').trim();

  static bool hasWordTiming(String lrc) =>
      lrc.contains('\n[w:') || _enhancedWordTag.hasMatch(lrc);

  /// Whether [lrc] has line timestamps. Lyrics without any (plain text,
  /// common in embedded tags) can only be read, not followed.
  static bool hasTiming(String lrc) => _lineTimeTag.hasMatch(lrc);

  static const int levelNone = 0;
  static const int levelPlain = 1;
  static const int levelLine = 2;
  static const int levelWord = 3;
  static const int levelLetter = 4;

  /// How finely [lrc] follows the song: [levelNone] (nothing, or a saved
  /// "not found"), [levelPlain] (text without timestamps), [levelLine],
  /// [levelWord], or [levelLetter] when pieces smaller than a word are
  /// timed.
  static int levelOf(String? lrc) {
    if (lrc == null || lrc.isEmpty || lrc == notFound) return levelNone;
    if (!hasTiming(lrc)) return levelPlain;
    if (!hasWordTiming(lrc)) return levelLine;
    return _hasLetterTiming(lrc) ? levelLetter : levelWord;
  }

  /// Whether a `[w:]` line (see TimedLrcWriter) splits a word: a timed
  /// piece that ends without a space, followed by one that starts without.
  static bool _hasLetterTiming(String lrc) {
    var text = '';
    for (final raw in lrc.split('\n')) {
      final line = raw.trim();
      final timing = _timingLine.firstMatch(line);
      if (timing == null) {
        final bg = _bgLine.firstMatch(line);
        text = bg != null
            ? bg.group(1)!.trim()
            : line.replaceFirst(_leadingTimeTags, '').trim();
        continue;
      }
      var cursor = 0;
      for (final entry in timing.group(1)!.split(';')) {
        final fields = entry.split(',');
        final length = fields.length == 3 ? int.tryParse(fields[2]) : null;
        if (length == null || length <= 0) break;
        cursor += length;
        if (cursor >= text.length) break;
        if (text[cursor - 1].trim().isNotEmpty &&
            text[cursor].trim().isNotEmpty) {
          return true;
        }
      }
    }
    return false;
  }

  /// Marks lyrics the user picked (see [pinned]).
  static const String _picked = '[picked:user]';

  /// Marks of older versions, which noted on the lyrics themselves that a
  /// better level had been looked for. That is now read from the
  /// per-provider answers ([_adoptOldCheck]).
  static const String _oldWordSyncChecked = '[checked:wordsync]';
  static const String _oldSyncChecked = '[checked:sync]';

  static String _unmarked(String lrc) => lrc
      .replaceAll('\n$_picked', '')
      .replaceAll('\n$_oldWordSyncChecked', '')
      .replaceAll('\n$_oldSyncChecked', '');

  /// Lyrics the user picked explicitly (a provider chosen in the lyrics
  /// menu) - marked, with an LRC metadata line every parser ignores, so the
  /// automatic upgrade never overrides that choice.
  static String pinned(String lrc) =>
      lrc.contains(_picked) ? lrc : '$lrc\n$_picked';

  /// Whether [lrc] - lyrics as returned by [fetchLyrics] - is looked up
  /// for a better level ([upgrade]): plain text and line-synced lyrics from
  /// any source, unless they are the user's own text or menu pick.
  static bool canUpgrade(String lrc) {
    if (lrc.contains(_picked)) return false;
    final source = _sourceTag.firstMatch(lrc)?.group(0)?.toLowerCase();
    if (source == '[source:custom_file]') return false;
    final level = levelOf(lrc);
    return level == levelPlain || level == levelLine;
  }

  // Lookups under way, by song (id and path: songs outside the library
  // share an id) - a second call joins the first.
  static final Map<String, Future<String?>> _upgrading = {};
  static final Map<String, Future<String?>> _fetching = {};

  static String _songKey(Song song) => '${song.id}|${song.path}';

  /// Upgrade of [current] (see [canUpgrade]): the best lyrics of a higher
  /// level any switched-on service has, saved (song.lyrics and the cache
  /// file) in place of the old ones - or null when there are none. Costs a
  /// request only for services that were never asked about this song.
  static Future<String?> upgrade(Song song, String current) =>
      _upgrading[_songKey(song)] ??= _upgrade(song, current).whenComplete(() {
        _upgrading.remove(_songKey(song));
      });

  static Future<String?> _upgrade(Song song, String current) async {
    final settings = await DbService.isar.appSettings.get(0);
    await _adoptOldCheck(song, current);
    final lrc = await best(
      song,
      enabledProviders(settings),
      above: levelOf(current),
      online: settings?.enableInternet ?? true,
    );
    if (lrc == null) return null;

    // The lookup can take a while: lyrics the user picked or edited in the
    // meantime stay.
    final dbSong = await DbService.isar.songs.get(song.id);
    if (dbSong != null && dbSong.lyrics != current) return null;
    await store(
      song,
      cleanArtist(song),
      cleanTitle(song),
      lrc,
    );
    return lrc;
  }

  /// Lyrics saved by an older version with its word-sync mark were checked
  /// on lrc.red and LyricsPlus, the two word-synced services it had. That
  /// is filed as their answer, so only the services added since are asked.
  static Future<void> _adoptOldCheck(Song song, String lrc) async {
    if (!lrc.contains(_oldWordSyncChecked)) return;
    final artist = cleanArtist(song);
    final title = cleanTitle(song);
    for (final provider in const ['LRC.RED', 'LYRICSPLUS']) {
      if (await LyricsCache.getProvider(artist, title, provider) != null) {
        continue;
      }
      await LyricsCache.saveProviderMiss(artist, title, provider);
    }
  }

  /// "Find word-synced lyrics" in the lyrics menu: the best word- or
  /// letter-timed lyrics a switched-on service has, saved as this song's
  /// lyrics. Returns them (source-tagged), or null when none has any.
  static Future<String?> findWordSynced(Song song) =>
      _findAbove(song, levelLine);

  /// "Find synced lyrics" in the lyrics menu, for songs whose lyrics are
  /// plain text: the best synced lyrics a switched-on service has, saved as
  /// this song's lyrics. Returns them (source-tagged), or null.
  static Future<String?> findSynced(Song song) => _findAbove(song, levelPlain);

  static Future<String?> _findAbove(Song song, int level) async {
    final settings = await DbService.isar.appSettings.get(0);
    final lrc = await best(
      song,
      enabledProviders(settings),
      above: level,
      online: settings?.enableInternet ?? true,
    );
    if (lrc != null) {
      await store(
        song,
        cleanArtist(song),
        cleanTitle(song),
        lrc,
      );
    }
    return lrc;
  }

  /// The best lyrics above level [above] among [providers]' answers, asked
  /// in order - the earlier one on a tie. Services that can't beat what is
  /// already in hand are skipped, and nothing more is asked once the
  /// lyrics are letter-timed.
  static Future<String?> best(
    Song song,
    Iterable<String> providers, {
    required int above,
    bool online = true,
  }) async {
    String? found;
    var level = above;
    for (final provider in providers) {
      if (level >= levelLetter) break;
      final info = LyricsProviderInfo.of(provider);
      if (info != null && info.bestLevel <= level) continue;
      final lrc = (await _fromProvider(song, provider, network: online)).lrc;
      if (lrc == null || levelOf(lrc) <= level) continue;
      found = lrc;
      level = levelOf(lrc);
    }
    return found;
  }

  /// Whether [provider]'s answer for [song] is already known (its lyrics,
  /// or that it has none) - picking it in the lyrics menu then costs no
  /// download.
  static Future<bool> hasAnswer(Song song, String provider) async {
    final artist = cleanArtist(song);
    final title = cleanTitle(song);
    final id = provider.toUpperCase();
    return await LyricsCache.getProvider(artist, title, id) != null ||
        await LyricsCache.isProviderMiss(artist, title, id);
  }

  /// Tests: stands in for the online services.
  static Future<String?> Function(Song song, String provider)? debugAsk;

  /// Tests: forgets what only lasts until the app restarts.
  static void debugRestart() => _failedThisRun.clear();

  static final Map<String, Future<_Answer>> _asking = {};

  /// Requests that didn't get through, per song and provider: not repeated
  /// until the app restarts.
  static final Set<String> _failedThisRun = {};

  /// [provider]'s answer for [song]: the saved one when there is one - its
  /// lyrics (source-tagged), or that it has none - else asked online
  /// ([network]) and saved for good. Only a request that didn't get
  /// through leaves nothing behind, to be asked again another time.
  static Future<_Answer> _fromProvider(
    Song song,
    String provider, {
    bool network = true,
  }) async {
    final artist = cleanArtist(song);
    final title = cleanTitle(song);
    final saved = await LyricsCache.getProvider(artist, title, provider);
    if (saved != null) return (lrc: saved, known: true);
    if (await LyricsCache.isProviderMiss(artist, title, provider)) {
      return (lrc: null, known: true);
    }
    final key = '${_songKey(song)}|$artist|$title|$provider';
    if (!network || _failedThisRun.contains(key)) {
      return (lrc: null, known: false);
    }
    return _asking[key] ??= _ask(song, provider, key).whenComplete(() {
      _asking.remove(key);
    });
  }

  static Future<_Answer> _ask(Song song, String provider, String key) async {
    final artist = cleanArtist(song);
    final title = cleanTitle(song);
    final report = LyricsLookupReport();
    String? raw;
    try {
      raw = await LyricsHttp.tracked(report, () async {
        final ask = debugAsk;
        if (ask != null) {
          return ask(song, provider);
        }
        final response = await _askOnline(song, provider);
        return response?.syncedLyrics ?? response?.plainLyrics;
      });
    } catch (_) {
      report.failed = true;
    }
    if (raw != null && raw.trim().isNotEmpty) {
      final tagged = '[source:${provider.toLowerCase()}]\n$raw';
      await LyricsCache.saveProvider(artist, title, provider, tagged);
      return (lrc: tagged, known: true);
    }
    if (report.failed) {
      _failedThisRun.add(key);
      return (lrc: null, known: false);
    }
    await LyricsCache.saveProviderMiss(artist, title, provider);
    return (lrc: null, known: true);
  }

  /// Lyrics the user typed or edited, as stored: tagged like their own .lrc
  /// file, so nothing automatic (upgrade, rescan, cache clear) replaces
  /// them.
  static String userLyrics(String text) =>
      '[source:custom_file]\n${LrcParser.stripSourceTag(text.trim())!.trim()}';

  /// Call before replacing a song's lyrics by hand: files the current
  /// online lyrics (word timing included) under their provider, so the
  /// lyrics menu can bring them back without a download.
  static Future<void> backUpBeforeEdit(Song song) async {
    final current = (await DbService.isar.songs.get(song.id))?.lyrics;
    if (current != null && current.isNotEmpty) {
      await _keepProviderCopy(song, current);
    }
  }

  /// Files the song's current online lyrics under their provider too, for
  /// lyrics saved before per-provider copies existed.
  static Future<void> _keepProviderCopy(Song song, String lrc) async {
    final provider = _sourceTag
        .firstMatch(lrc)
        ?.group(0)
        ?.replaceAll(RegExp(r'^\[source:|\]$'), '')
        .toUpperCase();
    if (provider == null || !allProviders.contains(provider)) return;
    final artist = (song.artist ?? 'Unknown Artist').trim();
    final title = song.title.trim();
    final copy = _unmarked(lrc);
    final existing = await LyricsCache.getProvider(artist, title, provider);
    if (existing == null || (hasWordTiming(copy) && !hasWordTiming(existing))) {
      await LyricsCache.saveProvider(artist, title, provider, copy);
    }
  }

  /// Saves [lrc] as the song's lyrics: cache file and song.lyrics.
  static Future<void> store(
    Song song,
    String artist,
    String title,
    String lrc,
  ) async {
    await LyricsCache.save(artist, title, lrc);
    await _saveToDb(song, lrc);
    await _keepProviderCopy(song, lrc);
  }

  static Future<void> _saveToDb(Song song, String lrc) async {
    song.lyrics = lrc;
    await DbService.isar.writeTxn(() async {
      final dbSong = song.id != Isar.autoIncrement
          ? await DbService.isar.songs.get(song.id)
          : await DbService.isar.songs.filter().pathEqualTo(song.path).findFirst();
      if (dbSong != null) {
        dbSong.lyrics = lrc;
        await DbService.isar.songs.put(dbSong);
      }
    });
  }

  /// What a library rescan stores in song.lyrics: [existing] (the saved
  /// row) unless it holds nothing useful, [scanned] being the file's
  /// embedded lyrics as the scanner tags them. Saved lyrics - downloaded
  /// word-synced ones, sidecar, the user's picks and edits - must survive
  /// a rescan, or the next play shows the embedded text again and repeats
  /// the online upgrade. Only embedded lyrics are refreshed from the file
  /// (its tags may have been edited), keeping the checked mark when the
  /// text is unchanged.
  static String? mergeScanned(String? existing, String? scanned) {
    if (existing == null || existing.isEmpty || existing == notFound) {
      return scanned ?? existing;
    }
    if (scanned == null) return existing;
    final isEmbedded = existing.startsWith('[source:embedded]');
    if (!isEmbedded) return existing;
    return _unmarked(existing) == scanned ? existing : scanned;
  }

  /// Automatic lookup, used on play, by the song info screen and by
  /// "Sync lyrics offline". Returns source-tagged lyrics, or null.
  static Future<String?> fetchLyrics(Song song) =>
      _fetching[_songKey(song)] ??= _fetchLyrics(song).whenComplete(() {
        _fetching.remove(_songKey(song));
      });

  static Future<String?> _fetchLyrics(Song song) async {
    final artist = cleanArtist(song);
    final title = cleanTitle(song);

    // The database copy, not [song.lyrics]: the queue holds Song objects
    // loaded before lyrics were found or the cache was cleared.
    final dbSong = song.id != Isar.autoIncrement
        ? await DbService.isar.songs.get(song.id)
        : await DbService.isar.songs.filter().pathEqualTo(song.path).findFirst();
    var saved = dbSong != null ? dbSong.lyrics : song.lyrics;

    // 1. Saved lyrics (song.lyrics), then the cache file.
    if (saved == null || saved.isEmpty) {
      saved = await LyricsCache.get(artist, title);
      if (saved != null && saved.isNotEmpty) await _saveToDb(song, saved);
    }
    // Word-synced lyrics in the cache file beat ones without word timing
    // in the database (e.g. written back by an older rescan).
    if (saved != null &&
        saved.isNotEmpty &&
        saved != notFound &&
        canUpgrade(saved)) {
      final cached = await LyricsCache.get(artist, title);
      if (cached != null && cached != notFound && hasWordTiming(cached)) {
        await _saveToDb(song, cached);
        return cached;
      }
    }

    if (saved != null && saved.isNotEmpty && saved != notFound) {
      if (saved.startsWith('[source:')) {
        await _keepProviderCopy(song, saved);
        return saved;
      }
      // Self-heal untagged data: older scanners wrote embedded lyrics
      // untagged, and older editors saved the user's edits untagged. Tag
      // it once - embedded only when it matches the file's tags, else as
      // the user's own, so a rescan never replaces an edit.
      final embedded = await MetadataService.getEmbeddedLyrics(song.path);
      final tagged = embedded != null && embedded.trim() == saved.trim()
          ? '[source:embedded]\n$saved'
          : userLyrics(saved);
      await _saveToDb(song, tagged);
      return tagged;
    }

    // 2. Nothing saved, or a saved "not found": walk the chain. Every
    // service answers from what it said before, so a "not found" song only
    // costs a request for services it was never asked on (switched on or
    // added since) - and its own files are read again, they may have
    // gained lyrics.
    final settings = await DbService.isar.appSettings.get(0);
    final found = await firstInChain(
      song,
      lookupChain(
        enabledProviders(settings),
        autoFallback: settings?.autoLyricsFallback ?? true,
      ),
      online: settings?.enableInternet ?? true,
    );
    if (found.lrc != null) {
      await store(song, artist, title, found.lrc!);
      return found.lrc;
    }

    // Saved as "not found" only when every service in the chain really
    // answered: with internet off, no network or a failed request, the
    // next play tries again.
    if (found.known && saved != notFound) {
      await store(song, artist, title, notFound);
    }
    return null;
  }

  /// Lyrics menu provider pick: asks [provider] first and, with
  /// auto-fallback on, the rest of the chain after it. Whatever is found
  /// replaces the song's current lyrics. Returns it (source-tagged), or null
  /// with the current lyrics left alone. A provider that already answered
  /// for this song - with lyrics or without - isn't asked again.
  /// Services whose answer can be reported as wrong (not the song's own
  /// files or the user's lyrics).
  static bool isReportable(String? source) {
    final s = source?.toLowerCase();
    return s != null &&
        s.isNotEmpty &&
        !const {'embedded', 'local', 'custom_file', 'not_found', 'user'}
            .contains(s);
  }

  /// "Wrong lyrics" in the lyrics menu: [provider]'s answer for [song] is
  /// forgotten and that provider is skipped for this song from now on;
  /// the rest of the chain is asked. Returns the new lyrics, or
  /// [notFound] when no other service has any.
  static Future<String?> reportWrong(Song song, String provider) async {
    final artist = cleanArtist(song);
    final title = cleanTitle(song);
    final id = provider.toUpperCase();
    await LyricsCache.forgetProvider(artist, title, id);
    await LyricsCache.saveProviderMiss(artist, title, id);
    await LyricsCache.forget(artist, title);
    await DbService.isar.writeTxn(() async {
      final row = song.id != Isar.autoIncrement
          ? await DbService.isar.songs.get(song.id)
          : await DbService.isar.songs.filter().pathEqualTo(song.path).findFirst();
      if (row == null) return;
      row.lyrics = null;
      await DbService.isar.songs.put(row);
    });
    song.lyrics = null;
    _fetching.remove(_songKey(song));
    _upgrading.remove(_songKey(song));
    return fetchLyrics(song);
  }

  static Future<String?> fetchWithProvider(Song song, String provider) async {
    final settings = await DbService.isar.appSettings.get(0);
    final chosen = provider.toUpperCase();
    final chain = [
      chosen,
      if (settings?.autoLyricsFallback ?? true)
        ...lookupChain(
          enabledProviders(settings),
          autoFallback: true,
        ).where((s) => s != chosen),
    ];
    // With internet off in settings, saved provider copies still load.
    final found = await firstInChain(
      song,
      chain,
      online: settings?.enableInternet ?? true,
    );
    final lrc = found.lrc == null ? null : pinned(found.lrc!);
    if (lrc != null) {
      await store(
        song,
        cleanArtist(song),
        cleanTitle(song),
        lrc,
      );
    }
    return lrc;
  }

  /// The automatic lookup order: the song's own files, the first of
  /// [providers] (see [enabledProviders]), then (with [autoFallback]) the
  /// rest of them.
  static List<String> lookupChain(
    List<String> providers, {
    required bool autoFallback,
  }) => [local, ...autoFallback ? providers : providers.take(1)];

  /// The first answer in [chain], whatever its level - it is shown at
  /// once, and [upgrade] looks for a better one behind it. `known` is
  /// false when a service couldn't be asked (with [online] false, or a
  /// failed request), so "nothing found" isn't final.
  static Future<({String? lrc, bool known})> firstInChain(
    Song song,
    List<String> chain, {
    bool online = true,
  }) async {
    var known = true;
    for (final source in chain) {
      if (source == local) {
        final lrc = await _readLocal(song);
        if (lrc != null) return (lrc: lrc, known: true);
        continue;
      }
      final answer = await _fromProvider(song, source, network: online);
      if (answer.lrc != null) return answer;
      if (!answer.known) known = false;
    }
    return (lrc: null, known: known);
  }

  static Future<LyricsResponse?> _askOnline(Song song, String provider) =>
      _service.getLyrics(
        trackName: cleanTitle(song),
        artistName: cleanArtist(song),
        albumName: (song.album ?? '').trim(),
        durationSeconds: (song.duration ?? 0) ~/ 1000,
        provider: provider,
      );

  /// Embedded tags, then a sidecar .lrc/.txt next to the song - the first
  /// of them with timestamps, else the first with any lyrics.
  static Future<String?> _readLocal(Song song) async {
    String? untimed;
    final embedded = await MetadataService.getEmbeddedLyrics(song.path);
    if (embedded != null && embedded.isNotEmpty) {
      final tagged = '[source:embedded]\n$embedded';
      if (hasTiming(tagged)) return tagged;
      untimed = tagged;
    }

    final songDir = File(song.path).parent.path;
    final baseName = p.basenameWithoutExtension(song.path);
    for (final path in [
      p.join(songDir, '$baseName.lrc'),
      p.join(songDir, '$baseName.txt'),
      p.join(songDir, 'lyrics', '$baseName.lrc'),
      p.join(songDir, 'lyrics', '$baseName.txt'),
      p.join(songDir, 'Lyrics', '$baseName.lrc'),
    ]) {
      try {
        final file = File(path);
        if (await file.exists()) {
          final content = await file.readAsString();
          if (content.isEmpty) continue;
          final tagged = '[source:local]\n$content';
          if (hasTiming(tagged)) return tagged;
          untimed ??= tagged;
        }
      } catch (_) {}
    }
    return untimed;
  }

  /// "Clear lyrics cache": forgets every online answer (downloaded lyrics,
  /// "not found", and what each service said per song) so those songs are
  /// looked up again on their next play. Lyrics from the song's own files,
  /// the user's .lrc picks and edits are kept; the song's own files lose
  /// their menu-pick mark, so they are upgraded again.
  static Future<void> clearAll() async {
    await LyricsCache.clear();
    _failedThisRun.clear();
    final online = {
      for (final p in allProviders) '[source:${p.toLowerCase()}]',
    };
    await DbService.isar.writeTxn(() async {
      final songs = await DbService.isar.songs.where().findAll();
      final changed = <Song>[];
      for (final song in songs) {
        final lyrics = song.lyrics;
        if (lyrics == null) continue;
        final tag = _sourceTag.firstMatch(lyrics)?.group(0)?.toLowerCase();
        if (tag == '[source:embedded]' || tag == '[source:local]') {
          final unmarked = _unmarked(lyrics);
          if (unmarked == lyrics) continue;
          song.lyrics = unmarked;
        } else if (tag == notFound || online.contains(tag)) {
          song.lyrics = null;
        } else {
          continue;
        }
        changed.add(song);
      }
      await DbService.isar.songs.putAll(changed);
    });
  }
}

/// A source's answer for a song: its lyrics (source-tagged) or null.
/// `known` is false when null only means it couldn't be asked.
typedef _Answer = ({String? lrc, bool known});
