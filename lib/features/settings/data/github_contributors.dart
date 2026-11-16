import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:looper_player/core/services/storage/local_json_store.dart';
import 'package:looper_player/core/theme/app_assets.dart';
import 'package:looper_player/core/utils/app_links.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'github_contributors.g.dart';

/// One person in the About screen's maintainers row.
class GithubContributor {
  final String login;
  final String profileUrl;
  final String? avatarUrl;

  /// Bundled avatar, used only by [_bundled] before GitHub has ever answered.
  final String? avatarAsset;

  const GithubContributor({
    required this.login,
    required this.profileUrl,
    this.avatarUrl,
    this.avatarAsset,
  });

  Map<String, dynamic> toJson() => {
    'login': login,
    'html_url': profileUrl,
    'avatar_url': avatarUrl,
  };

  static GithubContributor? fromJson(Object? json) {
    if (json is! Map) return null;
    final login = json['login'];
    final url = json['html_url'];
    if (login is! String || url is! String) return null;
    final avatar = json['avatar_url'];
    return GithubContributor(
      login: login,
      profileUrl: url,
      avatarUrl: avatar is String ? avatar : null,
    );
  }
}

/// Shown offline on first run, before there's anything cached.
const _bundled = [
  GithubContributor(
    login: 'SthrNilshaaa',
    profileUrl: AppLinks.nileshGithub,
    avatarAsset: AppAssets.maintainerAvatar,
  ),
  GithubContributor(
    login: 'sthrkaran',
    profileUrl: AppLinks.karanGithub,
    avatarAsset: AppAssets.designerAvatar,
  ),
];

const _storeKey = 'github_contributors';

List<GithubContributor> _parse(Object? json) => [
  if (json is List)
    for (final item in json) ?GithubContributor.fromJson(item),
];

/// The repo's contributors from GitHub, bots left out. Emits the last cached
/// list (or the bundled one) straight away, then the fresh list once GitHub
/// answers, so the row never waits on the network.
@Riverpod(keepAlive: true)
Stream<List<GithubContributor>> githubContributors(Ref ref) async* {
  final cached = _parse(await LocalJsonStore.read(_storeKey));
  yield cached.isNotEmpty ? cached : _bundled;

  try {
    final response = await http
        .get(
          Uri.parse('${AppLinks.githubContributorsApi}?per_page=100'),
          headers: const {'Accept': 'application/vnd.github+json'},
        )
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) return;
    final fresh = [
      for (final item in jsonDecode(response.body) as List)
        if (item is Map && item['type'] == 'User')
          ?GithubContributor.fromJson(item),
    ];
    if (fresh.isEmpty) return;
    await LocalJsonStore.write(_storeKey, [for (final c in fresh) c.toJson()]);
    yield fresh;
  } catch (e) {
    debugPrint('githubContributors: $e');
  }
}

/// Stargazer count of [AppLinks.githubStatsRepo]; null while loading/offline.
final githubStarsProvider = FutureProvider<int?>((ref) async {
  try {
    final response = await http
        .get(
          Uri.parse(AppLinks.githubStatsRepoApi),
          headers: const {'Accept': 'application/vnd.github+json'},
        )
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) return null;
    final stars = (jsonDecode(response.body) as Map)['stargazers_count'];
    return stars is int ? stars : null;
  } catch (e) {
    debugPrint('githubStars: $e');
    return null;
  }
});
