import 'package:looper_player/features/library/domain/models/models.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'navigation_provider.g.dart';

enum NavItem {
  home,
  songs,
  albums,
  artists,
  playlists,
  search,
  favorites,
  recentlyPlayed,
  lyrics,
  settings,
  collectionDetail,
  queue,
  genres,
  folders,
  history,
  mostPlayed,
  downloads,
  smartCollections,
  library,
  analyze,
  settingsCategory,
}

class NavigationState {
  final NavItem activeItem;
  final String? collectionTitle;
  final String? collectionSubtitle;
  final String? collectionArt;
  final String? collectionImageUrl;
  final List<Song> collectionSongs;
  final Playlist? activePlaylist;
  final Album? activeAlbum;
  final String? settingsCategoryId;
  final String? settingsCategoryTitle;
  final List<NavigationState> history;
  final bool isPlayerExpanded;

  NavigationState({
    required this.activeItem,
    this.collectionTitle,
    this.collectionSubtitle,
    this.collectionArt,
    this.collectionImageUrl,
    this.collectionSongs = const [],
    this.activePlaylist,
    this.activeAlbum,
    this.settingsCategoryId,
    this.settingsCategoryTitle,
    this.history = const [],
    this.isPlayerExpanded = false,
  });

  NavigationState copyWith({
    NavItem? activeItem,
    String? collectionTitle,
    String? collectionSubtitle,
    String? collectionArt,
    String? collectionImageUrl,
    List<Song>? collectionSongs,
    Playlist? activePlaylist,
    Album? activeAlbum,
    String? settingsCategoryId,
    String? settingsCategoryTitle,
    List<NavigationState>? history,
    bool? isPlayerExpanded,
  }) {
    return NavigationState(
      activeItem: activeItem ?? this.activeItem,
      collectionTitle: collectionTitle ?? this.collectionTitle,
      collectionSubtitle: collectionSubtitle ?? this.collectionSubtitle,
      collectionArt: collectionArt ?? this.collectionArt,
      collectionImageUrl: collectionImageUrl ?? this.collectionImageUrl,
      collectionSongs: collectionSongs ?? this.collectionSongs,
      activePlaylist: activePlaylist ?? this.activePlaylist,
      activeAlbum: activeAlbum ?? this.activeAlbum,
      settingsCategoryId: settingsCategoryId ?? this.settingsCategoryId,
      settingsCategoryTitle:
          settingsCategoryTitle ?? this.settingsCategoryTitle,
      history: history ?? this.history,
      isPlayerExpanded: isPlayerExpanded ?? this.isPlayerExpanded,
    );
  }
}

@Riverpod(keepAlive: true)
class AppNavigation extends _$AppNavigation {
  @override
  NavigationState build() => NavigationState(activeItem: NavItem.home);

  void setItem(NavItem item) {
    if (state.activeItem == item) return;

    if (item == NavItem.home) {
      state = NavigationState(activeItem: NavItem.home);
      return;
    }

    // Push current state to history
    final newHistory = List<NavigationState>.from(state.history)
      ..add(_captureCurrentState());

    state = NavigationState(
      activeItem: item,
      history: newHistory,
      isPlayerExpanded: state.isPlayerExpanded,
    );
  }

  void toggleItem(NavItem item) {
    if (state.activeItem == item) {
      goBack();
    } else {
      setItem(item);
    }
  }

  void showCollection({
    required String title,
    String? subtitle,
    String? art,
    String? imageUrl,
    required List<Song> songs,
    Playlist? playlist,
    Album? album,
  }) {
    if (state.activeItem == NavItem.collectionDetail &&
        state.collectionTitle == title) {
      return;
    }

    // Push current state to history
    final newHistory = List<NavigationState>.from(state.history)
      ..add(_captureCurrentState());

    state = NavigationState(
      activeItem: NavItem.collectionDetail,
      collectionTitle: title,
      collectionSubtitle: subtitle,
      collectionArt: art,
      collectionImageUrl: imageUrl,
      collectionSongs: songs,
      activePlaylist: playlist,
      activeAlbum: album,
      history: newHistory,
      isPlayerExpanded: state.isPlayerExpanded,
    );
  }

  void showSettingsCategory({required String id, required String title}) {
    if (state.activeItem == NavItem.settingsCategory &&
        state.settingsCategoryId == id) {
      return;
    }

    // Push current state to history
    final newHistory = List<NavigationState>.from(state.history)
      ..add(_captureCurrentState());

    state = NavigationState(
      activeItem: NavItem.settingsCategory,
      settingsCategoryId: id,
      settingsCategoryTitle: title,
      history: newHistory,
      isPlayerExpanded: state.isPlayerExpanded,
    );
  }

  void goBack() {
    if (state.history.isEmpty) {
      state = NavigationState(activeItem: NavItem.home);
      return;
    }

    final previousState = state.history.last;
    final newHistory = List<NavigationState>.from(state.history)..removeLast();

    state = previousState.copyWith(history: newHistory);
  }

  NavigationState _captureCurrentState() {
    return NavigationState(
      activeItem: state.activeItem,
      collectionTitle: state.collectionTitle,
      collectionSubtitle: state.collectionSubtitle,
      collectionArt: state.collectionArt,
      collectionImageUrl: state.collectionImageUrl,
      collectionSongs: state.collectionSongs,
      activePlaylist: state.activePlaylist,
      activeAlbum: state.activeAlbum,
      settingsCategoryId: state.settingsCategoryId,
      settingsCategoryTitle: state.settingsCategoryTitle,
      isPlayerExpanded: state.isPlayerExpanded,
    );
  }

  void togglePlayerExpansion() {
    state = state.copyWith(isPlayerExpanded: !state.isPlayerExpanded);
  }

  void setPlayerExpansion(bool expanded) {
    state = state.copyWith(isPlayerExpanded: expanded);
  }
}
