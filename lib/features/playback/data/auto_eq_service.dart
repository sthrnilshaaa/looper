import 'dart:convert';
import 'package:looper_player/features/playback/data/device_audio_info.dart';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:looper_player/core/services/storage/local_json_store.dart';
import 'package:looper_player/core/utils/logger_helper.dart';

enum AutoEqFilterType { peaking, lowShelf, highShelf }

class AutoEqFilter {
  final AutoEqFilterType type;
  final double freq;
  final double gain;
  final double q;
  final bool enabled;

  const AutoEqFilter({
    required this.type,
    required this.freq,
    required this.gain,
    required this.q,
    this.enabled = true,
  });

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'freq': freq,
    'gain': gain,
    'q': q,
    'enabled': enabled,
  };

  factory AutoEqFilter.fromJson(Map<String, dynamic> json) => AutoEqFilter(
    type: AutoEqFilterType.values.firstWhere(
      (t) => t.name == json['type'],
      orElse: () => AutoEqFilterType.peaking,
    ),
    freq: (json['freq'] as num).toDouble(),
    gain: (json['gain'] as num).toDouble(),
    q: (json['q'] as num).toDouble(),
    enabled: json['enabled'] as bool? ?? true,
  );
}

class AutoEqProfile {
  final String id;
  final String name;
  final String source;
  final double preamp;
  final List<AutoEqFilter> filters;
  final String rawText;

  const AutoEqProfile({
    required this.id,
    required this.name,
    required this.source,
    required this.preamp,
    required this.filters,
    required this.rawText,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'source': source,
    'preamp': preamp,
    'filters': filters.map((f) => f.toJson()).toList(),
    'rawText': rawText,
  };

  factory AutoEqProfile.fromJson(Map<String, dynamic> json) => AutoEqProfile(
    id: json['id'] as String,
    name: json['name'] as String,
    source: json['source'] as String? ?? 'AutoEQ',
    preamp: (json['preamp'] as num).toDouble(),
    filters: (json['filters'] as List<dynamic>)
        .map((f) => AutoEqFilter.fromJson(f as Map<String, dynamic>))
        .toList(),
    rawText: json['rawText'] as String? ?? '',
  );
}

class AutoEqIndexEntry {
  final String name;
  final String path;
  final String source;
  final String foldedName;

  const AutoEqIndexEntry({
    required this.name,
    required this.path,
    required this.source,
    required this.foldedName,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'path': path,
    'source': source,
    'foldedName': foldedName,
  };

  factory AutoEqIndexEntry.fromJson(Map<String, dynamic> json) =>
      AutoEqIndexEntry(
        name: json['name'] as String,
        path: json['path'] as String,
        source: json['source'] as String? ?? '',
        foldedName: json['foldedName'] as String? ??
            AutoEqService.fold(json['name'] as String),
      );
}

/// Headphone correction profile download, caching, parsing and filter builder
/// (docs/online/25-audio-lab.md §3.4 and docs/online/21-inzx-features-and-architecture.md §1).
class AutoEqService {
  AutoEqService._();
  static final instance = AutoEqService._();

  static const _indexUrl =
      'https://raw.githubusercontent.com/jaakkopasanen/AutoEq/master/results/INDEX.md';
  static const _resultsBase =
      'https://raw.githubusercontent.com/jaakkopasanen/AutoEq/master/results';
  static const _indexCacheKey = 'autoeq_index_v1';
  static const _devicesCacheKey = 'autoeq_devices_v1';

  List<AutoEqIndexEntry>? _cachedIndex;

  /// Normalizes a name by lowercasing and stripping non-alphanumeric characters.
  /// Used for tolerant searching where "wh1000" matches "WH-1000XM5".
  static String fold(String s) =>
      s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

  /// Parses a pre-fitted ParametricEQ.txt content with gain clamps and preamp compensation.
  static AutoEqProfile parseParametricEq({
    required String id,
    required String name,
    required String source,
    required String content,
  }) {
    double preamp = 0.0;
    final filters = <AutoEqFilter>[];
    final lines = content.split('\n');

    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;
      if (line.startsWith('Preamp:')) {
        final m = RegExp(
          r'Preamp:\s*([+-]?\d+(?:\.\d+)?)\s*dB',
          caseSensitive: false,
        ).firstMatch(line);
        if (m != null) {
          preamp = double.tryParse(m.group(1)!) ?? 0.0;
        }
        continue;
      }
      if (line.startsWith('Filter')) {
        final m = RegExp(
          r'Filter\s+\d+:\s*(ON|OFF)\s+(PK|LSC|HSC)\s+Fc\s+(\d+(?:\.\d+)?)\s*Hz\s+Gain\s+([+-]?\d+(?:\.\d+)?)\s*dB\s+Q\s+(\d+(?:\.\d+)?)',
          caseSensitive: false,
        ).firstMatch(line);
        if (m != null) {
          final on = m.group(1)!.toUpperCase() == 'ON';
          final typeStr = m.group(2)!.toUpperCase();
          final type = switch (typeStr) {
            'LSC' => AutoEqFilterType.lowShelf,
            'HSC' => AutoEqFilterType.highShelf,
            _ => AutoEqFilterType.peaking,
          };
          final fc = double.tryParse(m.group(3)!) ?? 1000.0;
          final rawGain = double.tryParse(m.group(4)!) ?? 0.0;
          final q = double.tryParse(m.group(5)!) ?? 0.7;

          // Clamping rule (doc 25 §3.4): +8 dB boost and -12 dB cut
          final clampedGain = rawGain.clamp(-12.0, 8.0);
          filters.add(
            AutoEqFilter(
              type: type,
              freq: fc,
              gain: clampedGain,
              q: q,
              enabled: on,
            ),
          );
        }
      }
    }

    // Lower preamp by the largest boost (doc 25 §3.4)
    double largestBoost = 0.0;
    for (final f in filters) {
      if (f.enabled && f.gain > largestBoost) {
        largestBoost = f.gain;
      }
    }
    if (largestBoost > 0 && -preamp < largestBoost) {
      preamp = -largestBoost;
    }

    return AutoEqProfile(
      id: id,
      name: name,
      source: source,
      preamp: preamp,
      filters: filters,
      rawText: content,
    );
  }

  /// 18-band frequencies matching the Looper equalizer bands.
  static const bandFrequencies = [
    65.0,
    92.0,
    131.0,
    185.0,
    262.0,
    370.0,
    523.0,
    740.0,
    1000.0,
    1400.0,
    2000.0,
    2900.0,
    4100.0,
    5900.0,
    8300.0,
    11700.0,
    16600.0,
    20000.0,
  ];

  /// Evaluates the frequency response of an AutoEQ profile at specified frequencies.
  static List<double> evaluateProfileAtFrequencies(
    AutoEqProfile profile, {
    double bass = 0.0,
    double tilt = 0.0,
    List<double> freqs = bandFrequencies,
  }) {
    final result = <double>[];
    for (final f in freqs) {
      double total =
          profile.preamp - math.max(0.0, bass) - math.max(0.0, tilt * 2.5);
      if (tilt != 0.0) {
        total += tilt * (math.log(f / 1000.0) / math.ln2);
      }
      if (bass != 0.0) {
        final ratio = f / 105.0;
        total += bass / (1.0 + (ratio * ratio));
      }
      for (final filter in profile.filters) {
        if (!filter.enabled) continue;
        final fc = filter.freq;
        final g = filter.gain;
        final q = filter.q;
        switch (filter.type) {
          case AutoEqFilterType.peaking:
            final term = q * (f / fc - fc / f);
            total += g / (1.0 + term * term);
          case AutoEqFilterType.lowShelf:
            final ratio = f / fc;
            total += g / (1.0 + ratio * ratio);
          case AutoEqFilterType.highShelf:
            final ratio = fc / f;
            total += g / (1.0 + ratio * ratio);
        }
      }
      result.add(total.clamp(-20.0, 20.0));
    }
    return result;
  }

  /// Builds lavfi filter strings for mpv chain insertion.
  /// When [isSpeaker] is true (phone speaker), returns an empty list so headphone
  /// correction is skipped on speakers.
  static List<String> buildLavfiFilters(
    AutoEqProfile profile, {
    double bass = 0.0,
    double tilt = 0.0,
    bool isSpeaker = false,
  }) {
    if (isSpeaker) return const [];

    final effectivePreamp =
        profile.preamp - math.max(0.0, bass) - math.max(0.0, tilt * 2.5);
    final result = <String>[];
    result.add('lavfi-volume=${effectivePreamp.toStringAsFixed(1)}dB');

    for (final f in profile.filters) {
      if (!f.enabled) continue;
      final fHz = f.freq.round();
      final qStr = f.q.toStringAsFixed(2);
      final gStr = f.gain.toStringAsFixed(1);
      switch (f.type) {
        case AutoEqFilterType.peaking:
          result.add('lavfi-equalizer=f=$fHz:t=q:w=$qStr:g=$gStr');
        case AutoEqFilterType.lowShelf:
          result.add('lavfi-lowshelf=f=$fHz:t=q:w=$qStr:g=$gStr');
        case AutoEqFilterType.highShelf:
          result.add('lavfi-highshelf=f=$fHz:t=q:w=$qStr:g=$gStr');
      }
    }

    if (bass != 0.0) {
      result.add(
        'lavfi-lowshelf=f=105:t=q:w=0.70:g=${bass.toStringAsFixed(1)}',
      );
    }
    if (tilt != 0.0) {
      result.add('lavfi-tiltshelf=f=1000:g=${(tilt * 5.0).toStringAsFixed(1)}');
    }

    return result;
  }

  /// Searches the index with search folding and ranks names that start with the query first.
  static List<AutoEqIndexEntry> searchIndex(
    List<AutoEqIndexEntry> index,
    String query,
  ) {
    final foldedQuery = fold(query);
    if (foldedQuery.isEmpty) return const [];
    final matches = <AutoEqIndexEntry>[];
    for (final entry in index) {
      if (entry.foldedName.contains(foldedQuery)) {
        matches.add(entry);
      }
    }
    matches.sort((a, b) {
      final aStarts = a.foldedName.startsWith(foldedQuery);
      final bStarts = b.foldedName.startsWith(foldedQuery);
      if (aStarts && !bStarts) return -1;
      if (!aStarts && bStarts) return 1;
      return a.name.compareTo(b.name);
    });
    return matches;
  }

  /// Loads the AutoEQ index from LocalJsonStore (7 days TTL) or downloads it.
  Future<List<AutoEqIndexEntry>> loadIndex({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedIndex != null && _cachedIndex!.isNotEmpty) {
      return _cachedIndex!;
    }

    if (!forceRefresh) {
      final cached = await LocalJsonStore.read(_indexCacheKey);
      if (cached is Map) {
        final timestamp = cached['timestamp'] as int? ?? 0;
        final age = DateTime.now().millisecondsSinceEpoch - timestamp;
        if (age < const Duration(days: 7).inMilliseconds) {
          final items = cached['items'] as List<dynamic>?;
          if (items != null && items.isNotEmpty) {
            _cachedIndex = items
                .map((i) => AutoEqIndexEntry.fromJson(Map<String, dynamic>.from(i as Map)))
                .toList();
            return _cachedIndex!;
          }
        }
      }
    }

    try {
      final res = await http.get(Uri.parse(_indexUrl));
      if (res.statusCode == 200) {
        final parsed = _parseIndexMd(res.body);
        if (parsed.isNotEmpty) {
          _cachedIndex = parsed;
          await LocalJsonStore.write(_indexCacheKey, {
            'timestamp': DateTime.now().millisecondsSinceEpoch,
            'items': parsed.map((e) => e.toJson()).toList(),
          });
          return parsed;
        }
      }
    } catch (e) {
      LoggerHelper.write('AutoEqService: failed to fetch index', e);
    }

    return _cachedIndex ?? const [];
  }

  static List<AutoEqIndexEntry> _parseIndexMd(String md) {
    final entries = <AutoEqIndexEntry>[];
    final lines = md.split('\n');
    final reg = RegExp(r'-\s+\[(.*?)\]\(\./(.*?)\)(?:\s+by\s+(.*?))?$');
    for (final line in lines) {
      final match = reg.firstMatch(line.trim());
      if (match != null) {
        final name = match.group(1)!.trim();
        final path = match.group(2)!.trim();
        final source = match.group(3)?.trim() ?? 'AutoEQ';
        entries.add(
          AutoEqIndexEntry(
            name: name,
            path: path,
            source: source,
            foldedName: fold(name),
          ),
        );
      }
    }
    return entries;
  }

  /// Loads a profile from local cache or downloads it from GitHub.
  Future<AutoEqProfile?> fetchProfile(AutoEqIndexEntry entry) async {
    final cacheKey = 'autoeq_profile_${fold(entry.path)}';
    final cached = await LocalJsonStore.read(cacheKey);
    if (cached is Map) {
      return AutoEqProfile.fromJson(Map<String, dynamic>.from(cached));
    }

    final decodedPath = Uri.decodeComponent(entry.path);
    final modelName = decodedPath.split('/').last;
    final primaryUrl =
        '$_resultsBase/${entry.path}/${Uri.encodeComponent(modelName)}%20ParametricEQ.txt';
    final fallbackUrl = '$_resultsBase/${entry.path}/ParametricEQ.txt';

    for (final url in [primaryUrl, fallbackUrl]) {
      try {
        final res = await http.get(Uri.parse(url));
        if (res.statusCode == 200) {
          final profile = parseParametricEq(
            id: entry.path,
            name: entry.name,
            source: entry.source,
            content: res.body,
          );
          await LocalJsonStore.write(cacheKey, profile.toJson());
          return profile;
        }
      } catch (e) {
        LoggerHelper.write('AutoEqService: error fetching $url', e);
      }
    }

    return null;
  }

  /// Saved devices mapping (deviceKey -> profileId).
  /// Key a saved headphone profile is stored under for an output device.
  static String deviceKey(OutputDeviceInfo? d) {
    if (d == null) return 'desktop:default';
    if (d.kind == OutputDeviceKind.speaker) return 'speaker';
    if (d.kind == OutputDeviceKind.bluetooth) {
      return 'bt:${d.name ?? 'unknown'}';
    }
    if (d.kind == OutputDeviceKind.usb) return 'usb:${d.name ?? 'dac'}';
    if (d.kind == OutputDeviceKind.wired) return 'wired';
    return '${d.kind.name}:${d.name ?? ''}';
  }

  Future<Map<String, String>> getSavedDevices() async {
    final json = await LocalJsonStore.read(_devicesCacheKey);
    if (json is Map) {
      return json.map((k, v) => MapEntry(k.toString(), v.toString()));
    }
    return {};
  }

  Future<void> saveDeviceProfile(String deviceKey, String profileId) async {
    final map = await getSavedDevices();
    map[deviceKey] = profileId;
    await LocalJsonStore.write(_devicesCacheKey, map);
  }

  Future<void> forgetDeviceProfile(String deviceKey) async {
    final map = await getSavedDevices();
    map.remove(deviceKey);
    await LocalJsonStore.write(_devicesCacheKey, map);
  }
}
