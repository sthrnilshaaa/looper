// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get about => 'について';

  @override
  String get aboutAndMaintainers => '概要とメンテナー';

  @override
  String get aboutApp => 'アプリについて';

  @override
  String get aboutLooperPlayer => 'ルーパープレイヤーについて';

  @override
  String get accentColor => 'アクセントカラー';

  @override
  String get accentColorDesc => 'テーマのアクセントカラーを手動で選択';

  @override
  String get acousticSpectralAnalysis => '音響およびスペクトル分析';

  @override
  String get activeCallCannotPlay => '再生がブロックされました: アクティブな通話中は音楽を再生できません';

  @override
  String get adaptColorsArtwork => 'アプリの色をアルバムのアートワークに適応させる';

  @override
  String addedTo(String name) {
    return '$name に追加しました';
  }

  @override
  String get addedToQueue => 'キューに追加しました';

  @override
  String get addFolder => 'フォルダーの追加';

  @override
  String get addToFavorites => 'お気に入りに追加';

  @override
  String get addToPlaylists => 'プレイリストに追加';

  @override
  String get addToQueue => 'キューに追加';

  @override
  String get album => 'アルバム';

  @override
  String get albums => 'アルバム';

  @override
  String get albumsRowDesc => 'アルバムの水平棚';

  @override
  String get allFilesAccess => 'すべてのファイルへのアクセス (推奨)';

  @override
  String get allSongs => 'すべての曲';

  @override
  String get appDetailsCreator => 'アプリケーションの詳細、作成者、デザインチームの情報';

  @override
  String get appearance => '外観';

  @override
  String get appInfoPrivacy => 'アプリ情報とプライバシー';

  @override
  String get appTitle => 'ルーパープレイヤー';

  @override
  String get artist => 'アーティスト';

  @override
  String get artists => 'アーティスト';

  @override
  String get artistsRowDesc => 'アーティストの横の棚';

  @override
  String get ascending => '昇順';

  @override
  String get audioCrossfade => 'オーディオクロスフェード';

  @override
  String get audioCrossfadeDesc => '曲が変わるときにトラックを滑らかに重ねます';

  @override
  String get audioFocusDenied => '再生一時停止: 音声フォーカスがシステムによって拒否されました';

  @override
  String get audioPlayback => 'オーディオと再生';

  @override
  String get audioPlaybackDesc => 'クロスフェード、無音時間、フェードの設定';

  @override
  String get autoCrossfadeDuration => '自動クロスフェード時間';

  @override
  String get autoCrossfadeDurationDesc => '自動移行時の重なり時間';

  @override
  String get backToMainView => 'メインビューに戻る';

  @override
  String get cancel => 'キャンセル';

  @override
  String get categories => 'カテゴリー';

  @override
  String get center => '中央寄せ';

  @override
  String get clear => 'クリア';

  @override
  String get clearQueue => 'クリア';

  @override
  String get connectDevice => 'デバイスを接続する';

  @override
  String get corePurpose => '主な目的';

  @override
  String get corePurposeDesc =>
      'Looper Player は、ローカル ライブラリの完全な制御、ギャップレス再生、滑らかで同期した歌詞のスクロールを求める音楽愛好家向けに設計された、オフラインファーストの高忠実度オーディオ プレーヤーです。';

  @override
  String get create => '作成';

  @override
  String get createPlaylist => 'プレイリストを作成';

  @override
  String get creatorAndMaintainer => '作成者および保守者';

  @override
  String get customAccentColor => 'カスタムのアクセントカラー';

  @override
  String get customizeColorsTheme => 'アプリの色、テーマ、歌詞の背景をカスタマイズする';

  @override
  String get dateAdded => '追加日';

  @override
  String get deepStorageScanProgress => 'ディープストレージスキャンが進行中...';

  @override
  String get delete => '消去';

  @override
  String get deleteFile => 'ファイルを削除';

  @override
  String get deletePlaylist => 'プレイリストを削除';

  @override
  String deletePlaylistConfirm(String name) {
    return '\"$name\" を削除してもよろしいですか？';
  }

  @override
  String get deleteSong => '曲の削除';

  @override
  String get deleteSongConfirm => 'この曲をディスクから削除してもよろしいですか?';

  @override
  String get descending => '降順';

  @override
  String get designerAndMaintainer => 'デザイナー兼メンテナー';

  @override
  String get disableBlurEffects => 'ぼかし効果を無効にする';

  @override
  String get disableSquigglyProgressBar => '波打つプログレスバーアニメーションを無効にする';

  @override
  String get downloadAudioDirectly => '音声を直接ダウンロードする';

  @override
  String get downloadingLyricsOffline => 'オフラインで使用するために歌詞をダウンロードしています...';

  @override
  String get downloadMissingArtwork => '不足しているアートワークをダウンロードする';

  @override
  String get downloadMissingArtworkDesc =>
      'iTunes から曲の高解像度のカバーアートワークを自動的にダウンロードします';

  @override
  String get duration => '長さ';

  @override
  String get dynamicAccentColor => '動的なアクセントカラー';

  @override
  String get dynamicAccentColorDesc => 'アルバムアートからアクセントカラーのみを動的に更新';

  @override
  String get dynamicBgOnlyLyrics => '歌詞のみのダイナミック背景';

  @override
  String get dynamicColorActiveLyrics => 'ダイナミックカラーアクティブライン';

  @override
  String get dynamicColorActiveLyricsDesc => '現在再生中の歌詞ラインに抽出されたアートワークの色を使用します';

  @override
  String get dynamicLyricsBg => 'ダイナミックリリックBG';

  @override
  String get dynamicLyricsBgDesc => '歌詞画面にアルバムアートのぼかしを適用';

  @override
  String get dynamicTheming => '動的なテーマ';

  @override
  String get emptyLibraryDesc =>
      'ライブラリ内にサポートされている音楽ファイルが見つかりませんでした。フォルダーを追加するか、検索スキャンを実行します。';

  @override
  String get enableNetworkLyricsArt => 'オンラインの歌詞とアーティスト アートのネットワーク使用を有効にする';

  @override
  String get enablePlayerGradient => '音楽画面のグラデーション';

  @override
  String get enablePlayerGradientDesc => '現在再生中の画面で放射状のアクセント グラデーションの背景を有効にする';

  @override
  String get fadeDuration => 'フェード時間';

  @override
  String get fadeDurationDesc => '再生/一時停止/停止フェード効果の長さ';

  @override
  String get fadeOnSeek => 'シーク時のフェード';

  @override
  String get fadeOnSeekDesc => 'シーク（巻き戻し・早送り）時に音量を滑らかにフェードアウト・インします';

  @override
  String get fadePlayPauseStop => '再生/一時停止/停止時のフェード';

  @override
  String get fadePlayPauseStopDesc => '再生、一時停止、停止時に音量を滑らかにフェードイン/アウトします';

  @override
  String get favorites => 'お気に入り';

  @override
  String get fileInformation => 'ファイル情報';

  @override
  String get flatProgressBar => 'フラットプログレスバー';

  @override
  String get folders => 'フォルダー';

  @override
  String get genre => 'ジャンル';

  @override
  String get genres => 'ジャンル';

  @override
  String get genresRowDesc => '音楽ジャンルの水平棚';

  @override
  String get goStart => '始めましょう';

  @override
  String get grant => '付与';

  @override
  String get granted => '付与された';

  @override
  String get history => '歴史';

  @override
  String get home => '家';

  @override
  String get homeDarkness => 'ホーム画面の暗さ';

  @override
  String get homeDarknessDesc => 'ホーム画面の背景オーバーレイの暗さを調整する';

  @override
  String get homeDashboardSettings => 'ホームダッシュボードの設定';

  @override
  String get homeDashboardSettingsDesc => 'ホーム画面の水平行をカスタマイズする';

  @override
  String get internetMode => 'インターネットモード';

  @override
  String get keepBackgroundGradient => '背景のグラデーションを維持する';

  @override
  String get keepBackgroundGradientDesc => 'すべてのアプリケーション画面にわたって背景のグラデーションを維持する';

  @override
  String get animatePlayerGradient => 'アニメーショングラデーション';

  @override
  String get animatePlayerGradientDesc =>
      '音楽に合わせて、プライマリとターシャリの色を柔らかな粒子感とともにゆっくり動かします';

  @override
  String get animateBackgroundGradient => 'アニメーション背景';

  @override
  String get animateBackgroundGradientDesc =>
      'ホーム、曲、ライブラリの背景にアニメーショングラデーションを使用します';

  @override
  String get language => '言語';

  @override
  String get left => '左寄せ';

  @override
  String get library => '図書館';

  @override
  String get libraryDarkness => 'ライブラリ画面の暗闇';

  @override
  String get libraryDarknessDesc => 'ライブラリ画面の背景オーバーレイの暗さを調整します';

  @override
  String get libraryFoldersSync => 'フォルダー、再スキャントリガー、データベースのリセット、オフライン同期';

  @override
  String get librarySettings => 'ライブラリ設定';

  @override
  String get loadingMusicLibrary => '音楽ライブラリをロード中';

  @override
  String get loadingMusicLibraryDesc =>
      'プレミアム インデックスの構築、ハードウェア リスナーのセットアップ、ビジュアル キャッシュの最適化。';

  @override
  String get loadingPhase1 => 'オーディオ ストレージを問い合わせています...';

  @override
  String get loadingPhase2 => '音楽エンジンをリフレッシュ中...';

  @override
  String get loadingPhase3 => '音響データを抽出しています...';

  @override
  String get loadingPhase4 => '再生メモリを最適化しています...';

  @override
  String get lyrics => '歌詞';

  @override
  String get lyricsAlignment => '歌詞の配置';

  @override
  String get lyricsAlignmentDesc => 'スクロールする歌詞のテキスト位置を揃える';

  @override
  String get lyricsDarkness => '歌詞画面暗闇';

  @override
  String get lyricsDarknessDesc => '歌詞画面の背景オーバーレイの暗さを調整します';

  @override
  String get lyricsProvider => '歌詞プロバイダー';

  @override
  String get lyricsProviderDesc => 'オンライン歌詞は lrclib.net (LRCLIB) から取得されています';

  @override
  String get maintainersAndDesigners => 'メンテナーとデザイナー';

  @override
  String get manageAudioFocus => 'オーディオフォーカスの管理';

  @override
  String get manageAudioFocusDesc => 'システムのオーディオフォーカス変化を要求および応答する';

  @override
  String get manageAudioFocusTitle => 'オーディオフォーカスの管理';

  @override
  String get manageLanguageAndFocus => '言語設定と発信者のフォーカス状態を管理する';

  @override
  String get audioFocusGetFocus => 'フォーカスを取得';

  @override
  String get audioFocusGetFocusDesc => '再生開始時にオーディオフォーカスを要求します。';

  @override
  String get audioFocusReleaseFocus => 'フォーカスを解放';

  @override
  String get audioFocusReleaseFocusDesc => '再生が一時停止または停止したときにオーディオフォーカスを解放します。';

  @override
  String get audioFocusStopOnOtherSession => '他の音楽セッションで音楽を停止';

  @override
  String get audioFocusStopOnOtherSessionDesc =>
      '他のアプリが音声の再生を開始したときに再生を一時停止します。';

  @override
  String get audioFocusRestartOnGain => 'フォーカス取得時に音楽を再開';

  @override
  String get audioFocusRestartOnGainDesc =>
      'オーディオフォーカスが戻ったとき、フォーカスの喪失によって再生が中断されていた場合のみ自動的に再生を再開します。';

  @override
  String get pauseOnDuckTitle => '音量低下時に一時停止';

  @override
  String get pauseOnDuckDesc =>
      '他のアプリが一時的な音(通知やナビゲーション案内など)を再生したとき、音量を下げる代わりに再生を一時停止します。';

  @override
  String get resumeOnBluetoothConnectTitle => 'Bluetooth接続時に再開';

  @override
  String get resumeOnBluetoothConnectDesc =>
      'Bluetoothオーディオ機器(ヘッドフォン、カーキットなど)が再接続したときに自動的に再生を再開します。';

  @override
  String get manualCrossfadeDuration => '手動クロスフェード時間';

  @override
  String get manualCrossfadeDurationDesc => '手動スキップ時の重なり時間';

  @override
  String get matchingLyrics => '一致する歌詞';

  @override
  String get metadataDetails => 'メタデータの詳細';

  @override
  String get mostPlayed => '最も再生された曲';

  @override
  String get musicAudioAccess => '音楽とオーディオへのアクセス';

  @override
  String get musicDarkness => '音楽プレーヤーの暗闇';

  @override
  String get musicDarknessDesc => '音楽プレーヤー画面の背景オーバーレイの暗さを調整します';

  @override
  String get musicLibrary => '音楽ライブラリ';

  @override
  String get muteOrPauseCalls => '通話やその他の音声アクティビティ中にミュートまたは一時停止する';

  @override
  String get newPlaylist => '新規プレイリスト';

  @override
  String get newTitle => '新しいタイトル';

  @override
  String get nextUp => '次の曲';

  @override
  String get noAlbumsFound => 'アルバムが見つかりませんでした';

  @override
  String get noArtistsFound => 'アーティストが見つかりませんでした';

  @override
  String get noFavoritesYet => 'お気に入りはまだありません';

  @override
  String get noHistoryYet => '履歴はありません';

  @override
  String get noLyrics => '歌詞が見つかりません';

  @override
  String get noMusicDetected => '音楽が検出されませんでした';

  @override
  String get noPlaylistsCreated => 'プレイリストはまだ作成されていません。';

  @override
  String get noPlaylistsYet => 'プレイリストがありません';

  @override
  String get noResultsFound => '結果が見つかりませんでした';

  @override
  String get noSongsFound => '曲が見つかりませんでした';

  @override
  String get notificationAccess => '通知へのアクセス';

  @override
  String get nowPlaying => 'プレイ中';

  @override
  String get performanceOptimizerDashboard => 'パフォーマンス最適化ダッシュボード';

  @override
  String get performanceOptimizerDashboardDesc => 'リアルタイムのパフォーマンス統計オーバーレイを表示する';

  @override
  String get permanentFocusChangePause => '永続的なフォーカス喪失時に一時停止';

  @override
  String get permanentFocusChangePauseDesc =>
      'オーディオフォーカスを永続的に失ったときに自動的に一時停止します';

  @override
  String get plainTimestamps => 'プレーンなタイムスタンプ';

  @override
  String get play => '遊ぶ';

  @override
  String get playAll => 'すべて再生';

  @override
  String get playbackAudio => '再生と言語';

  @override
  String get playlists => 'プレイリスト';

  @override
  String get playNext => '次に再生';

  @override
  String get playQueue => 'プレイキュー';

  @override
  String get pressBackExit => 'もう一度戻るボタンを押して終了します';

  @override
  String get privacySafety => 'プライバシーと安全性';

  @override
  String get privacySafetyDesc =>
      '100%プライベートかつオフラインファースト。トラック、再生履歴、お気に入り、設定は、ローカル デバイス上の安全な Isar データベース内に厳密に保管されます。当社は、お客様の使用状況データや設定を追跡、収集、共有しません。';

  @override
  String get pureBlackOled => 'ピュアブラック（OLED）';

  @override
  String get pureBlackOledDesc => '背景に絶対的な黒を使用する（OLED）';

  @override
  String get queue => '列';

  @override
  String get queueIsEmpty => 'キューが空です';

  @override
  String get quickPicks => 'クイックピック';

  @override
  String get quickPicksRowDesc => '最も再生された曲のグリッド';

  @override
  String get readyToScan => 'スキャンの準備ができました';

  @override
  String get recentlyAddedSongsRowDesc => '最新のインポートのリスト';

  @override
  String get recentlyPlayed => '最近再生した曲';

  @override
  String get recentPlayed => '最近のプレイ';

  @override
  String get recentRowDesc => '最近再生した曲の水平棚';

  @override
  String get removedFromPlaylist => 'プレイリストから削除しました';

  @override
  String get removeFromFavorites => 'お気に入りから削除';

  @override
  String get removeFromPlaylist => 'プレイリストから削除';

  @override
  String get rename => '名前を変更';

  @override
  String get renameFile => 'ファイルを名前変更';

  @override
  String get renamePlaylist => 'プレイリスト名を変更';

  @override
  String get renameSong => '曲の名前を変更する';

  @override
  String get reorderDashboardSections => 'ダッシュボードセクションの並べ替え';

  @override
  String get reorderDashboardSectionsDesc => 'ドラッグ アンド ドロップでダッシュボードの優先順序を設定します';

  @override
  String get includeOtherDeviceAudioTitle => '他のデバイス音声を含める';

  @override
  String get includeOtherDeviceAudioDesc =>
      '着信音、通知、アラーム、WhatsAppとTelegramの音声をスキャンします';

  @override
  String get rescanLibrary => 'ライブラリを再スキャンする';

  @override
  String get rescanStorage => 'ストレージの再スキャン';

  @override
  String get reset => 'リセット';

  @override
  String get resetLibrary => 'リセットと再スキャン';

  @override
  String get resetLibraryConfirm =>
      'これにより、すべての曲、アルバム、アーティストがクリアされ、フォルダーの完全な再スキャンが実行されます。';

  @override
  String get resetLibraryConfirmNew =>
      'これにより、ライブラリからすべての曲が削除されます。音楽ファイル自体は削除されません。';

  @override
  String get resetLibraryDesc => 'インデックスされたライブラリからすべての曲を削除します';

  @override
  String get resumeAfterCallDesc => '通話終了時に自動的に再生を再開します（通話で一時停止した場合）';

  @override
  String get resumeAfterCallTitle => '通話後に再開';

  @override
  String get resumeOnStartDesc => 'Looper Playerが起動されたときに自動的に再生を再開します';

  @override
  String get resumeOnStartTitle => '起動時に再開';

  @override
  String get persistQueueTitle => '最後のキューを保持';

  @override
  String get persistQueueDesc => 'アプリ再起動時に最後に再生した曲とキューを保存する';

  @override
  String get keepSongProgressTitle => '曲の再生位置を保持';

  @override
  String get keepSongProgressDesc =>
      '各曲の再生位置をそれぞれ個別に記憶します。曲の途中で別の曲に切り替えて、後で戻ってきても — 間に他の曲を再生していても — 最初からではなく、前回の続きから再生を再開します。';

  @override
  String get right => '右寄せ';

  @override
  String scanCompleteSongsDetected(int count) {
    return 'スキャン完了: $count 曲が検出されました!';
  }

  @override
  String get scanForMusic => '音楽をスキャン';

  @override
  String get scanIndexLocalDesc => 'ローカル音楽ファイルをスキャンしてインデックス付けする';

  @override
  String get scanLibrary => 'スキャンライブラリ';

  @override
  String get scanningInBackground => 'バックグラウンドでスキャン中...';

  @override
  String get scanningLibrary => 'ライブラリをスキャンしています...';

  @override
  String get scanningStorage => 'ストレージをスキャン中...';

  @override
  String get scanningStorageDesc =>
      'ディレクトリ ツリーを走査してオーディオ トラックを検出します。お待ちください...';

  @override
  String get search => '検索';

  @override
  String get searchLibraryHint => 'ライブラリ全体を検索する';

  @override
  String get searchSongsHint => '曲を検索する';

  @override
  String get seekFadeDuration => 'シークフェード時間';

  @override
  String get seekFadeDurationDesc => 'シークフェード効果の長さ';

  @override
  String get selectAppLanguage => 'アプリの言語を選択';

  @override
  String get selectCustomColor => 'カスタムカラーの選択';

  @override
  String get selectCustomFolder => 'カスタムフォルダーの選択';

  @override
  String get selectFolderIndex => '音楽ファイルをインデックスするフォルダーを選択';

  @override
  String get selectSpecificFolder => '特定のフォルダーを選択してください';

  @override
  String get settings => '設定';

  @override
  String get share => '共有';

  @override
  String get shareFile => 'ファイルを共有する';

  @override
  String get showAlbumsRow => 'アルバム行を表示';

  @override
  String get showAlbumsRowDesc => 'ホーム画面にアルバムの水平リストを表示します';

  @override
  String get showArtistsRow => 'アーティスト列を表示';

  @override
  String get showArtistsRowDesc => 'ホーム画面にアーティストの水平リストを表示します';

  @override
  String get showGenresRow => 'ジャンル行を表示';

  @override
  String get showGenresRowDesc => 'ホーム画面にジャンルの水平リストを表示します';

  @override
  String get showLess => '表示を減らす';

  @override
  String get showMore => 'もっと見る';

  @override
  String get showQualityBadge => '品質バッジを表示する';

  @override
  String get showQualityBadgeDesc => '再生中の画面に音質情報バッジを表示します';

  @override
  String get showRecentRow => '最近のプレイ行を表示';

  @override
  String get showRecentRowDesc => 'ホーム画面に最近再生した曲の水平リストを表示します';

  @override
  String get silenceBetweenTracksDesc => '曲の間に無音のギャップを追加します（ギャップレスは0ms）';

  @override
  String get silenceBetweenTracksTitle => '曲間の無音時間';

  @override
  String get songDeletedDbOnly => 'ライブラリから削除しました（元のファイルは読み取り専用）';

  @override
  String get songDeletedSuccess => '曲を削除しました';

  @override
  String get songDeleteFailed => '曲の削除に失敗しました';

  @override
  String get songDetails => '曲の詳細';

  @override
  String get songDetailsAndFrequency => '曲の詳細と周波数';

  @override
  String get songRenamedDbOnly => 'アプリ内ライブラリで名前を変更しました（元のファイルは読み取り専用）';

  @override
  String get songRenamedSuccess => '曲の名前を変更しました';

  @override
  String get songRenameFailed => '曲の名前変更に失敗しました';

  @override
  String get songs => '歌';

  @override
  String get songsDarkness => '曲 画面暗さ';

  @override
  String get songsDarknessDesc => 'ソング画面の背景オーバーレイの暗さを調整する';

  @override
  String get sortBy => '並べ替え';

  @override
  String get sortOrder => '並べ替え順序';

  @override
  String get sourceCode => 'ソースコード';

  @override
  String get stopServiceOnAppDismissal => 'アプリ終了時にサービスを停止';

  @override
  String get stopServiceOnAppDismissalDesc =>
      '最近使ったアプリから削除されたときにバックグラウンドサービスを停止しアプリを終了します';

  @override
  String get storagePermissionRequired => 'デバイスのメモリをスキャンするにはストレージのアクセス許可が必要です。';

  @override
  String get syncLyricsOffline => '歌詞を同期（オフライン）';

  @override
  String get systemDefault => 'システムデフォルト';

  @override
  String get systemPermissionChecklist => 'システム許可チェックリスト';

  @override
  String get technicalInfoFrequency => '技術情報と頻度';

  @override
  String get theme => 'テーマ';

  @override
  String get title => 'タイトル';

  @override
  String get todayMixForYou => '今日はあなたにミックスしてください';

  @override
  String get toggleFavorite => 'お気に入りを切り替え';

  @override
  String get shuffleTitle => 'シャッフル';

  @override
  String get shuffleDisabledDesc =>
      '曲を元のキュー順に再生します。シャッフルをオフにすると、再生中の曲はそのまま続き、残りのキューは再生や再生履歴に影響を与えることなく元の順序に戻ります。';

  @override
  String get shuffleEnabledDesc =>
      '再生中の曲はそのままに、残りの曲の順序をランダム化します。生成されたシャッフル順は、キューが変わるか新しいシャッフルが要求されるまで一定に保たれ、曲の重複や飛ばしを防ぎます。';

  @override
  String get shuffleSwitchingDesc =>
      'シャッフルの切り替えでは再生中の曲が再開されることはありません。変更されるのは次に再生される曲の順序のみで、オンのときはランダムに、オフのときは元のキュー順に戻ります。';

  @override
  String get topResult => '上位の結果';

  @override
  String get transferMusicFiles => '音楽ファイルを転送する';

  @override
  String get turnOffBlursOptimize => '激しいブラーをオフにしてパフォーマンスを最適化します';

  @override
  String get unknown => '未知';

  @override
  String get unknownAlbum => '未知のアルバム';

  @override
  String get unknownArtist => '不明なアーティスト';

  @override
  String get updateLibraryIndexing => 'ライブラリファイルのインデックスを更新';

  @override
  String get useAbsoluteBlackBg => '背景に絶対的な黒を使用する';

  @override
  String get useStaticTextTimestamps => '進行時間にはローリングアニメーションの代わりに静的テキストを使用します';

  @override
  String get fluidPlayer => 'フルイドプレーヤー';

  @override
  String get fluidPlayerDesc => 'ミニプレーヤーを上にドラッグしてフルプレーヤーに切り替えます';

  @override
  String get viewAll => 'すべて見る';

  @override
  String get visitOfficialRepository => 'GitHubの公式リポジトリを表示';

  @override
  String get welcomeAboutDesc =>
      'Looper Player は、プレミアム オフライン オーディオ再生用に構築された次世代 Music-OS です。リアルタイムの動的な歌詞生成、通話ミュート処理を備えた高度なオーディオ セッション管理、適応型バックグラウンド テーマ、およびマルチフォーマット音楽ライブラリのサポートが特徴です。バッテリー効率を最大化するために完全に最適化されています。';

  @override
  String get welcomeAllFilesDesc =>
      '標準以外のディレクトリ (ダウンロード、テレグラム、カスタム フォルダー) にある曲を見つけるためのプロフェッショナルなスキャンに強くお勧めします。';

  @override
  String get welcomeInstructionConnectDesc =>
      '標準の USB データ ケーブルを使用して、携帯電話またはデバイスをパーソナル コンピュータに接続します。';

  @override
  String get welcomeInstructionDownloadDesc =>
      'あるいは、Web ブラウザまたはデバイス自体の他のダウンローダー ユーティリティを使用してファイルを直接ダウンロードします。';

  @override
  String get welcomeInstructionTransferDesc =>
      'オフライン音楽ファイル (.mp3、.flac、.m4a、.wav をサポート) をデバイスの標準の「ミュージック」または「ダウンロード」フォルダーに直接コピーします。';

  @override
  String get welcomeMusicAudioDesc =>
      'デバイスのメモリ上で標準のオフライン オーディオ トラックを検出して再生するために必要です。';

  @override
  String get welcomeNoSongsDesc =>
      'デバイスのストレージ上でサポートされているオーディオ ファイル (MP3、FLAC、WAV、M4A、OGG) が見つかりませんでした。';

  @override
  String get welcomeNotificationDesc =>
      'システム バーに再生コントロールとアクティブな通知ウィジェットを表示するために必要です。';

  @override
  String get welcomeScanningFoldersDesc =>
      'すべてのフォルダーとサブフォルダーをスキャンしてオーディオ ファイルを探します。';

  @override
  String get whyInternetUsed => 'なぜインターネットが使われるのか';

  @override
  String get whyInternetUsedDesc =>
      '• 動的歌詞同期: オンライン データベースから同期された歌詞 (LRC 形式) を安全にフェッチし、ダウンロードするためにのみ使用されます。個人データ、設定、メディア ファイルがアップロードまたは共有されることはありません。';

  @override
  String get whyPermissionsUsed => '権限が使用される理由';

  @override
  String get whyPermissionsUsedDesc =>
      '• ストレージ/メディア アクセス: デバイスに保存されているローカル オーディオ トラックを検出、読み取り、インデックス付けするために必要です。\n• 通知: ステータス バーとシステム ドロワーにアクティブな再生コントロール ウィジェットを表示するために必要です。';

  @override
  String get willPlayNext => '次に再生します';

  @override
  String get year => '年';

  @override
  String get supportUs => '支援する';

  @override
  String get supportUsDesc => 'Looper Player の継続とオープンソース活動を支援';

  @override
  String get supportDevelopment => '開発を支援';

  @override
  String get supportDevelopmentDesc =>
      'Looper Player は 100% 無料でオープンソースです。気に入っていただけましたら、寄付による制作者の支援をご検討ください。すべての支援がプロジェクトの維持に役立ちます！';

  @override
  String get useCustomFont => 'カスタムフォントを使用';

  @override
  String get useCustomFontDesc =>
      'Jost または他のカスタムフォントを使用します。そうでない場合は DM Sans が使用されます。';

  @override
  String get selectFontFamily => 'フォントファミリーの選択';

  @override
  String activeFont(String fontName) {
    return '有効なフォント: $fontName';
  }

  @override
  String get fontWeightAdjustment => 'フォントの太さ調整';

  @override
  String get currentWeight => '現在の太さ';

  @override
  String get useCustomFontLyrics => '歌詞にカスタムフォントを使用';

  @override
  String get useCustomFontLyricsDesc => '同期歌詞ビューでカスタムフォントと太さを使用します';

  @override
  String get lyricsFontFamily => '歌詞フォントファミリー';

  @override
  String activeLyricsFont(String fontName) {
    return '有効な歌詞フォント: $fontName';
  }

  @override
  String get lyricsFontWeightAdjustment => '歌詞フォントの太さ調整';

  @override
  String get giveStarOnGithub => 'GitHub でスターを付ける';

  @override
  String get supportProjectLove => 'プロジェクトをサポートして、愛を示しましょう！';

  @override
  String get sortAlphabeticalAZ => 'アルファベット順 (A-Z)';

  @override
  String get sortAlphabeticalZA => 'アルファベット順 (Z-A)';

  @override
  String get sortRecentlyAdded => '追加日 (新しい順)';

  @override
  String get sortOldestAdded => '追加日 (古い順)';

  @override
  String get sortYearNewest => 'リリース年 (新しい順)';

  @override
  String get sortYearOldest => 'リリース年 (古い順)';

  @override
  String get sortMostSongs => '曲数が最も多い';

  @override
  String get sortLeastSongs => '曲数が最も少ない';

  @override
  String get sortDefault => 'デフォルト';

  @override
  String get sortArtistAsc => 'アーティスト (A-Z)';

  @override
  String get sortAlbumAsc => 'アルバム (A-Z)';

  @override
  String get sortDuration => '曲の長さ';

  @override
  String get myAlbums => 'マイアルバム';

  @override
  String get featuredArtists => '注目のアーティスト';

  @override
  String get noSongPlaying => '再生中の曲はありません';

  @override
  String get nextLabel => '次へ';

  @override
  String get previousLabel => '前へ';

  @override
  String get resync => '再同期';

  @override
  String get equalizer => 'イコライザー';

  @override
  String get presets => 'プリセット';

  @override
  String get preAmpGain => 'プリアンプゲイン';

  @override
  String get outputVolume => '出力音量';

  @override
  String get customFilterHint =>
      'カスタムのlibavfilterオーディオフィルターパラメータを直接入力します(例: volume=3dB, aecho=0.8:0.88:60:0.4):';

  @override
  String get flowGlobalActions => 'フローとグローバル操作';

  @override
  String get equalizerModeLabel => 'イコライザーモード:';

  @override
  String get currentGainsAppliedGlobal => '現在のゲインをグローバルのデフォルト設定として適用しました。';

  @override
  String get applyToGlobal => 'グローバルに適用';

  @override
  String get songSpecificResetGlobal => '曲固有の設定をグローバルのデフォルトにリセットしました。';

  @override
  String get resetToGlobal => 'グローバルにリセット';

  @override
  String get resetAllSongsEq => '全曲のEQをリセット';

  @override
  String get resetAllSongsEqConfirm =>
      'ライブラリ内のすべての曲のカスタムイコライザー設定を消去してもよろしいですか?';

  @override
  String get allSongsEqDataReset => 'すべての曲固有のイコライザーデータがリセットされました。';

  @override
  String get resetAllSongsEqData => '全曲のEQデータをリセット';

  @override
  String get equalizerTargetMode => 'イコライザー適用モード';

  @override
  String get equalizerTargetModeDesc => '音楽ライブラリ全体にイコライザー設定をどのように適用するかを選択します。';

  @override
  String get globalMode => 'グローバルモード';

  @override
  String get globalModeDesc => 'すべての曲に一律で効果を適用します。曲が変わってもイコライザー設定は同じままです。';

  @override
  String get songSpecificMode => '曲別モード';

  @override
  String get songSpecificModeDesc =>
      '現在の曲だけにカスタム設定を保存します。次の曲は、独自のプロファイルがない限りデフォルトでイコライザーなし(フラット)になります。';

  @override
  String get viewDeviceAudioCapabilities => 'デバイスのオーディオ機能を表示';

  @override
  String get deviceAudioCapabilities => 'デバイスのオーディオ機能';

  @override
  String get noPlaybackActiveCapabilities => '再生中ではないか、機能情報が利用できません。';

  @override
  String get changeLyricsProvider => '歌詞プロバイダーを変更';

  @override
  String get autoFallbackProviders => '自動フォールバックプロバイダー';

  @override
  String get autoFallbackProvidersDesc =>
      'メインのプロバイダーに歌詞がない場合、自動的に他のプロバイダーを試します';

  @override
  String get ambientColorBackground => 'アンビエントカラー背景';

  @override
  String get ambientColorBackgroundDesc =>
      '曲のアートワークから生成した、滑らかで控えめなアンビエントグラデーション';

  @override
  String get exportLyricsLrc => '歌詞をエクスポート(.lrcファイル)';

  @override
  String get saveLyricsToDevice => '現在の歌詞をデバイスのストレージに保存';

  @override
  String get noLyricsToExport => 'エクスポートできる歌詞がありません';

  @override
  String get useCustomLyricsLrc => 'カスタム歌詞を使用(LRCファイル)';

  @override
  String get selectLocalLrcFile => 'この曲用にローカルの.lrcまたは.txtファイルを選択';

  @override
  String get customLyricsAppliedSuccess => 'カスタム歌詞が正常に適用されました!';

  @override
  String get noRecentlyPlayedTracks => '最近再生した曲はありません';

  @override
  String get close => '閉じる';

  @override
  String get audioQualityAnalysis => '音質分析';

  @override
  String get audioQualityAnalysisDesc => '詳細なスペクトルおよびオーディオフォーマット分析を実行します';

  @override
  String get audioStreamDetails => 'オーディオストリームの詳細';

  @override
  String get perChannelMetrics => 'チャンネル別測定値';

  @override
  String get sleepTimer => 'スリープタイマー';

  @override
  String get stopByTime => '時間で停止';

  @override
  String get start => '開始';

  @override
  String get stopBySongCount => '曲数で停止';

  @override
  String get cancelSleepTimer => 'スリープタイマーをキャンセル';

  @override
  String get nowPlayingAllCaps => '再生中';

  @override
  String get settingsAndBackups => '設定とバックアップ';

  @override
  String get managePreferencesLibraryData => '設定とライブラリデータを管理';

  @override
  String get logsClearedSuccess => 'ログを正常に消去しました';

  @override
  String get editSongInfo => '曲情報を編集';

  @override
  String get editAlbumInfo => 'アルバム情報を編集';

  @override
  String get tapFieldToEdit => '編集するにはフィールドをタップしてください';

  @override
  String get alwaysBlurSheets => 'シートを常にぼかす';

  @override
  String get alwaysBlurSheetsDesc => 'ダイナミックテーマがオフの場合でもポップアップシートをぼかします';

  @override
  String get removeArtwork => 'アートワークを削除';

  @override
  String get resetArtworkToDefault => 'デフォルトにリセット';

  @override
  String get artworkResetToDefault => 'アートワークをデフォルトにリセットしました';

  @override
  String get noEmbeddedArtworkFound => 'このアルバムに埋め込まれたアートワークが見つかりません';

  @override
  String get saveChangesBtn => '変更を保存';

  @override
  String get enterFolderPathManually => 'フォルダパスを手動で入力';

  @override
  String get folderPickerManualHint =>
      'システムのディレクトリ選択画面が開かない場合は、以下に完全なディレクトリパスを入力または貼り付けてください:';

  @override
  String get noSupportedSongsFoundFolder => '選択したフォルダに対応する曲が見つかりません';

  @override
  String get add => '追加';

  @override
  String get folderPickerClosed => 'フォルダ選択画面が閉じられました';

  @override
  String get buyMeCoffee => 'コーヒーをおごる';

  @override
  String get typeToSearchSettings => '設定を検索するには入力してください…';

  @override
  String get maintainersLabel => 'メンテナー';

  @override
  String get personBehindLooperPlayer => 'LooperPlayerを開発した人';

  @override
  String get blurredArtworkForLyrics => '歌詞画面のぼかしアートワーク';

  @override
  String get blurredArtworkForLyricsDesc =>
      '動的/静的なグラデーションの代わりに、ぼかしたアルバムアートを背景として表示します';

  @override
  String get lyricsFontWeight => '歌詞フォントの太さ';

  @override
  String get openSourceLicenses => 'オープンソースライセンス';

  @override
  String get openSourceLicensesDesc => 'このアプリで使用しているサードパーティ製ライブラリ';

  @override
  String get done => '完了';

  @override
  String get lyricsNotAvailable => '歌詞は利用できません。';

  @override
  String get lyricsNotAvailableHint =>
      'この曲の歌詞を追加するには .lrc または .txt ファイルをインポートしてください';

  @override
  String get importLyricsFile => '歌詞ファイルをインポート';

  @override
  String get approximatedSyncNoWordTimings => '概算同期(単語単位のタイミングなし)';

  @override
  String get lyricsSyncHelp => '歌詞同期のヘルプ';

  @override
  String get simpleModeLabel => 'シンプルモード';

  @override
  String get advancedModeLabel => '詳細モード';

  @override
  String get tips => 'ヒント';

  @override
  String get gotIt => '了解';

  @override
  String get lyricsSyncStudio => '歌詞同期スタジオ';

  @override
  String get lyricsTextLabel => '歌詞テキスト';

  @override
  String get lyricsTextHelperDesc =>
      '歌詞行ごとに1行で入力してください。下の同期ツールでこれらの行にタイムスタンプを付けられます。';

  @override
  String get quickSync => 'クイック同期';

  @override
  String get autoAdvanceAfterStamping => '打刻後に自動的に次へ進む';

  @override
  String get advancedSync => '詳細な同期';

  @override
  String get useCurrentTime => '現在の時間を使用';

  @override
  String get playbackAssist => '再生アシスト';

  @override
  String get timeShift => 'タイムシフト';

  @override
  String get timeShiftDesc => '打刻済みの歌詞をすべてまとめて前後に移動します。';

  @override
  String get lyricsSaveLrcExplain =>
      '保存すると、可能な場合は曲の音声ファイルのそばに付随する「.lrc」ファイルが作成され、ローカルのプレーヤーデータベースにも保存されます。打刻されていない行は自動的に補間されます。';

  @override
  String get back => '戻る';

  @override
  String get appSettingsLabel => 'アプリ設定';

  @override
  String get backupsAndLogs => 'バックアップとログ';

  @override
  String get backupsAndLogsDesc => 'アプリデータのエクスポート、インポート、管理';

  @override
  String get exportBackupJson => 'バックアップをエクスポート(JSON)';

  @override
  String get exportBackupJsonDesc =>
      'お気に入りの曲とプレイリストを保存・共有できるJSONファイルに保存します。それ以外は含まれません。';

  @override
  String get importBackupJson => 'バックアップをインポート(JSON)';

  @override
  String get importBackupJsonDesc =>
      'バックアップファイルのお気に入り曲とプレイリストをライブラリにマージします。既存のデータが上書きまたは削除されることはありません。';

  @override
  String get exportDiagnosticsLogs => '診断ログをエクスポート';

  @override
  String get exportDiagnosticsLogsDesc =>
      'トラブルシューティングのために確認できるよう、アプリの診断ログファイルを共有します。';

  @override
  String get clearDiagnosticsLogs => '診断ログを消去';

  @override
  String get clearDiagnosticsLogsDesc =>
      'この端末に保存されている診断ログファイルを完全に消去します。この操作は取り消せません。';

  @override
  String get lyricsPlainTextOrLrc => '歌詞(プレーンテキストまたはLRC)';

  @override
  String get syncModeLine => '行';

  @override
  String get syncModeWord => '単語';

  @override
  String get syncModeChar => '文字';

  @override
  String get enterManually => '手動で入力';

  @override
  String get rawFilterParametersHint => '生のフィルターパラメータ...';

  @override
  String get searchSettingsHint => '設定を検索...';

  @override
  String get repeatTooltip => 'リピート';

  @override
  String get favoriteTooltip => 'お気に入り';

  @override
  String get instructionsTooltip => '使い方';

  @override
  String get pasteLyricsHint => 'ここに曲の歌詞を貼り付けるか入力してください';

  @override
  String get timestampMmSsHint => 'タイムスタンプ(mm:ss.xx)';

  @override
  String get nowLabel => '現在';

  @override
  String get playlistNameHint => 'プレイリスト名';

  @override
  String get songInfoUpdated => '曲情報を更新しました!';

  @override
  String get albumInfoUpdated => 'アルバム情報を更新しました!';

  @override
  String get failedToSaveChanges => '変更を保存できませんでした。';

  @override
  String sleepTimerStoppingIn(String time) {
    return '有効:あと$timeで停止';
  }

  @override
  String sleepTimerStoppingAfter(String time) {
    return '有効:$time後に停止';
  }

  @override
  String get selectWhenToPause => '音楽の再生をいつ一時停止するか選択してください';

  @override
  String get selectAvatars => 'アバターを選択';

  @override
  String get selectAvatarsDesc => 'ホーム画面に表示するアバターを選択します';

  @override
  String get dynamicAvatarColor => 'ダイナミックアバターカラー';

  @override
  String get dynamicAvatarColorDesc => 'アバターのアクセントカラーを現在のテーマに合わせます';

  @override
  String enrichingSongs(int count) {
    return '$count曲を情報取得中…';
  }

  @override
  String get noListeningHistoryYet => 'まだ再生履歴がありません';

  @override
  String get noListeningHistoryYetDesc =>
      '何曲か再生すると、よく聴く曲・アーティスト・アルバム・ジャンルをまとめたあなただけのレポートがここに表示されます。';

  @override
  String get looperAnalyze => 'Looper Analyze';

  @override
  String get totalPlays => '総再生回数';

  @override
  String get listeningTime => '再生時間';

  @override
  String get currentStreakDays => '現在の連続日数';

  @override
  String get longestStreakDays => '最長連続日数';

  @override
  String analyzePlaysAndSongs(int plays, int songs) {
    return '$plays 回再生 • $songs 曲';
  }

  @override
  String get dayPartMorningShort => '朝';

  @override
  String get dayPartAfternoonShort => '昼';

  @override
  String get dayPartEveningShort => '夕';

  @override
  String get dayPartNightShort => '夜';

  @override
  String get activityPattern => 'アクティビティのパターン';

  @override
  String get whenYouListenMost => 'よく聴く時間帯';

  @override
  String get genreBreakdown => 'ジャンル内訳';

  @override
  String get otherGenre => 'その他';

  @override
  String get topAlbums => 'トップアルバム';

  @override
  String get topArtists => 'トップアーティスト';

  @override
  String get topSongs => 'トップソング';

  @override
  String playsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 回再生',
    );
    return '$_temp0';
  }

  @override
  String songsPlayedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 曲を再生',
    );
    return '$_temp0';
  }

  @override
  String get listeningTrend => '再生の推移';

  @override
  String get last30Days => '過去 30 日間';

  @override
  String errorWithDetails(String error) {
    return 'エラー: $error';
  }

  @override
  String get selectAll => 'すべて選択';

  @override
  String get playlist => 'プレイリスト';

  @override
  String songsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 曲',
    );
    return '$_temp0';
  }

  @override
  String get recentSearches => '最近の検索';

  @override
  String get lyricsSourceLocalFile => 'ローカルファイル';

  @override
  String get lyricsSourceEmbedded => '埋め込みメタデータ';

  @override
  String lyricsProvidedBy(String source) {
    return '歌詞提供: $source';
  }

  @override
  String failedToImportLyrics(String error) {
    return '歌詞を読み込めませんでした: $error';
  }

  @override
  String get lyricsEditorLines => '行数';

  @override
  String get lyricsEditorStamped => '設定済み';

  @override
  String lyricsEditorLineNumber(int number) {
    return '$number 行目';
  }

  @override
  String get lyricsEditorEmptyLine => '(空行)';

  @override
  String get lyricsEditorNotStamped => '未設定';

  @override
  String get pause => '一時停止';

  @override
  String get lyricsEditorAddLineFirst => '先に歌詞を 1 行以上追加してください。';

  @override
  String get lyricsEditorSavedWithSidecar => '歌詞をデータベースと曲ファイルの横に保存しました。';

  @override
  String get lyricsEditorSavedDbOnly => '歌詞をプレーヤーのデータベースに保存しました。';

  @override
  String get lyricsEditorSaveFailed => '歌詞を保存できませんでした。';

  @override
  String get saving => '保存中...';

  @override
  String get saveLrc => 'LRC を保存';

  @override
  String lyricsEditorSelectedLine(int index, int total) {
    return '選択中の行 $index / $total';
  }

  @override
  String get lyricsEditorPickLine => '下のリストから歌詞の行を選んでください。';

  @override
  String get stampAndNext => '設定して次へ';

  @override
  String get stampNow => '今すぐ設定';

  @override
  String get lyricsEditorSimpleSteps =>
      '1. 1 行につき歌詞を 1 行ずつ貼り付けるか入力します。\n2. 曲を再生します。\n3. 現在の歌詞の行を選択します。\n4. その行が聞こえたら「設定して次へ」をタップします。\n5. 終わったら保存します。';

  @override
  String get lyricsEditorAdvancedSteps =>
      '1. 各行のタイムスタンプを直接編集します。\n2. 「現在の時間を使用」で再生中の時間を取り込みます。\n3. シフト操作で設定済みの行をまとめて移動します。\n4. 保存すると最終的な `.lrc` ファイルが作成されます。';

  @override
  String get lyricsEditorTipsText =>
      '- タイムスタンプ未設定の行があっても、Flick のエンジンが自動で時間を補完します。\n- 保存時は可能であれば曲の横に書き込み、できない場合はリンクしたコピーをデータベースに保存します。';

  @override
  String fileNotFoundOrInaccessible(String title) {
    return 'ファイルが見つからないか、アクセスできません: $title';
  }

  @override
  String playbackFailedCorrupted(String title) {
    return '再生に失敗しました: 「$title」を読み込めないか再生できません。ファイルが破損していないか確認してください。';
  }

  @override
  String shareSongText(String title) {
    return 'この曲を聴いてみて: $title';
  }

  @override
  String shareSongsText(int count) {
    return 'この $count 曲を聴いてみて';
  }

  @override
  String noSettingsFoundFor(String query) {
    return '「$query」に一致する設定はありません';
  }

  @override
  String get chooseQuickAccentColors => 'アクセントカラーをすばやく選択';

  @override
  String get fontWeight => 'フォントの太さ';

  @override
  String get changeBaseFontWeight => 'カスタムフォントの基本の太さを変更';

  @override
  String lyricsFontWeightValue(int weight) {
    return '歌詞フォントの太さ: $weight';
  }

  @override
  String get equalizerSearchDesc => '18 バンドイコライザーとオーディオプリセットを調整';

  @override
  String get stopServiceSearchDesc => '最近のアプリからスワイプして消したときに再生を停止してアプリを終了';

  @override
  String get scanNewFolderDesc => '新しいフォルダの音楽ファイルをスキャン';

  @override
  String get includeOtherDeviceAudioShortDesc => '着信音、通知音、メッセージアプリの音声';

  @override
  String get excludedFolders => '除外フォルダ';

  @override
  String get excludedFoldersSearchDesc => 'スキャン時に特定のフォルダをスキップ';

  @override
  String get clearLibraryData => 'ライブラリデータを消去';

  @override
  String get looperPlayerVersion => 'Looper Player のバージョン';

  @override
  String versionLabel(String version) {
    return 'バージョン $version';
  }

  @override
  String get none => 'なし';

  @override
  String foldersSkippedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'スキャン時に $count 個のフォルダをスキップ',
    );
    return '$_temp0';
  }

  @override
  String get excludedFoldersDesc =>
      'これらのフォルダ内の曲は、追加したフォルダの中にあってもスキャン時にスキップされます。';

  @override
  String get noExcludedFoldersYet => '除外フォルダはまだありません。';

  @override
  String get excludeAFolder => 'フォルダを除外';

  @override
  String get equalizerEnabled18Band => '有効 (18 バンド MPV EQ)';

  @override
  String get disabled => '無効';

  @override
  String get noIndexedFoldersYet => 'インデックス済みのフォルダはまだありません';

  @override
  String get noIndexedFoldersYetDesc => '「ライブラリを再スキャンする」でストレージ内のフォルダを検出してください。';

  @override
  String get eqDynamicRangeCompressor => 'ダイナミックレンジコンプレッサー';

  @override
  String get eqThreshold => 'スレッショルド';

  @override
  String get eqRatio => 'レシオ';

  @override
  String get eqAttack => 'アタック';

  @override
  String get eqRelease => 'リリース';

  @override
  String get eqHeadphoneCrossfeedWidth => 'ヘッドホン用クロスフィードと広がり';

  @override
  String get eqBinauralCrossfeed => 'バイノーラルクロスフィード';

  @override
  String get eqCrossfeedStrength => 'クロスフィードの強さ';

  @override
  String get eqStereoWidening => 'ステレオ拡張';

  @override
  String get eqWideningFactor => '拡張係数';

  @override
  String get eqLoudnessNormalization => 'ラウドネス正規化';

  @override
  String get eqTargetLoudness => '目標ラウドネス';

  @override
  String get eqToneShelving => 'トーンシェルビング (低音 / 高音)';

  @override
  String get eqBassShelf => '低音シェルフ';

  @override
  String get eqTrebleShelf => '高音シェルフ';

  @override
  String get eqTempoPitchControls => 'テンポとピッチの調整';

  @override
  String get eqPitchShift => 'ピッチシフト';

  @override
  String get eqTempoSpeed => 'テンポ速度';

  @override
  String get eqVoiceSilenceControls => '声と無音の調整';

  @override
  String get eqSilenceTrimming => '無音のカット';

  @override
  String get eqSilenceThreshold => '無音のしきい値';

  @override
  String get eqSpeechEnhancementFilter => '音声強調フィルター';

  @override
  String get eqHighpassCutoff => 'ハイパスのカットオフ';

  @override
  String get eqLowpassCutoff => 'ローパスのカットオフ';

  @override
  String get eqRetroRoomEffects => 'レトロ & ルームエフェクト';

  @override
  String get eqLofiEffect => 'Lo-fi エフェクト (8 ビットクラッシャー)';

  @override
  String get eqStudioRoomReverb => 'スタジオルームリバーブ (エコー)';

  @override
  String get eqVirtualSurround => '仮想 5.1 サラウンド';

  @override
  String get eqRawFilterConsole => 'FFmpeg フィルターコンソール';

  @override
  String get eqSwitchToSliders => 'スライダー表示に切り替え';

  @override
  String get eqSwitchToGraph => 'グラフ表示に切り替え';

  @override
  String get on => 'オン';

  @override
  String get off => 'オフ';

  @override
  String get eqSongSpecificActive => 'この曲専用の設定が有効です';

  @override
  String get eqUsingGlobalDefault => '全体のデフォルト設定を使用中';

  @override
  String get eqInteractiveGraphHint => 'インタラクティブグラフ (点を上下にドラッグ)';

  @override
  String get eq18BandHint => '18 バンドイコライザー (左右にスクロール)';

  @override
  String get eqSongSpecific => '曲ごと';

  @override
  String get eqGlobalDefault => '全体のデフォルト';

  @override
  String get eqEditScopeNote =>
      '曲の再生中に行った変更はその曲にのみ適用されます。全体のデフォルトを設定するには、曲を再生していないときに編集するか「グローバルに適用」を使用してください。';

  @override
  String get presetFlat => 'フラット';

  @override
  String get presetBassBooster => '低音ブースト';

  @override
  String get presetTrebleBooster => '高音ブースト';

  @override
  String get presetVocalBooster => 'ボーカルブースト';

  @override
  String get presetElectronic => 'エレクトロニック';

  @override
  String get presetRock => 'ロック';

  @override
  String get presetPop => 'ポップ';

  @override
  String get presetJazz => 'ジャズ';

  @override
  String get save => '保存';

  @override
  String get savePreset => 'プリセットを保存';

  @override
  String get presetName => 'プリセット名';

  @override
  String get deletePreset => 'プリセットを削除';

  @override
  String deletePresetConfirm(String name) {
    return 'プリセット「$name」を削除しますか？';
  }

  @override
  String get noLyricsSource => '歌詞のソースなし';

  @override
  String lyricsSourceLabel(String source) {
    return 'ソース: $source';
  }

  @override
  String get lyricsSourceLocalSidecar => 'ローカルの付属ファイル (.lrc)';

  @override
  String get lyricsSourceCustomFile => 'カスタム LRC ファイル';

  @override
  String get lyricsSourceNotFoundOnline => 'オンラインで見つかりません';

  @override
  String get lyricsProviderLocal => 'ローカル';

  @override
  String get checkingLocalLyrics => 'ローカル/埋め込み歌詞を確認中...';

  @override
  String fetchingLyricsFrom(String provider) {
    return '$provider から歌詞を取得中...';
  }

  @override
  String get loadedLocalLyrics => 'ローカル/埋め込み歌詞を読み込みました！';

  @override
  String get noLocalLyricsFound => 'ローカルまたは埋め込みの歌詞が見つかりません';

  @override
  String lyricsUpdatedFrom(String provider) {
    return '$provider から歌詞を更新しました！';
  }

  @override
  String noLyricsFoundOn(String provider) {
    return '$provider で歌詞が見つかりません';
  }

  @override
  String get gestureTips => 'ジェスチャーのヒント';

  @override
  String get gestureTipsDesc => 'タップ、長押し、ピンチでズームなど';

  @override
  String get exportLyrics => '歌詞をエクスポート';

  @override
  String lyricsExportedTo(String path) {
    return '歌詞のエクスポート先: $path';
  }

  @override
  String failedToExportLyrics(String error) {
    return '歌詞をエクスポートできませんでした: $error';
  }

  @override
  String get gestureTapLine => '行をタップ';

  @override
  String get gestureTapLineDesc => 'その歌詞の位置へ再生をジャンプします。';

  @override
  String get gestureLongPressLine => '行を長押し';

  @override
  String get gestureLongPressLineDesc =>
      '共有用の歌詞カードにする行の選択を開始します。ほかの行をタップすると選択範囲を広げられます。';

  @override
  String get gesturePinch => '2 本指でピンチ';

  @override
  String get gesturePinchDesc => '歌詞の文字サイズを好みに合わせて変更します。';

  @override
  String get gestureSwipeDown => '下にスワイプ';

  @override
  String get gestureSwipeDownDesc => '歌詞画面を閉じてプレーヤーに戻ります。';

  @override
  String get lyricsGestures => '歌詞画面のジェスチャー';

  @override
  String get lyricsGesturesIntro => 'この画面でできる、気づきにくい操作をご紹介します:';

  @override
  String linesSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 行を選択中',
    );
    return '$_temp0';
  }

  @override
  String get couldNotGenerateShareImage => '共有用の画像を作成できませんでした。';

  @override
  String get couldNotGenerateImage => '画像を作成できませんでした。';

  @override
  String get savedToGallery => 'ギャラリーに保存しました。';

  @override
  String get galleryPermissionDenied => 'ギャラリーへのアクセスが拒否されました。';

  @override
  String get couldNotSaveToGallery => '画像をギャラリーに保存できませんでした。';

  @override
  String get shareLyrics => '歌詞を共有';

  @override
  String get backgroundColor => '背景色';

  @override
  String get lyricsTextColor => '歌詞の文字色';

  @override
  String get saveToGallery => 'ギャラリーに保存';

  @override
  String get preparing => '準備中...';

  @override
  String get trackTitle => 'トラック名';

  @override
  String get composer => '作曲者';

  @override
  String get unknownGenre => '不明なジャンル';

  @override
  String get releaseYear => 'リリース年';

  @override
  String get notAvailable => 'なし';

  @override
  String get recordLabel => 'レーベル';

  @override
  String get copyright => '著作権';

  @override
  String get encoder => 'エンコーダー';

  @override
  String get fileName => 'ファイル名';

  @override
  String get fileFormat => 'ファイル形式';

  @override
  String get fileSize => 'ファイルサイズ';

  @override
  String get absolutePath => '絶対パス';

  @override
  String get playCount => '再生回数';

  @override
  String playCountTimes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 回',
    );
    return '$_temp0';
  }

  @override
  String get lastPlayed => '最終再生';

  @override
  String get filePath => 'ファイルパス';

  @override
  String get rescan => '再スキャン';

  @override
  String get codec => 'コーデック';

  @override
  String get container => 'コンテナ';

  @override
  String get sampleRate => 'サンプルレート';

  @override
  String get bitDepth => 'ビット深度';

  @override
  String get decodedFormat => 'デコード形式';

  @override
  String get bitrate => 'ビットレート';

  @override
  String get channels => 'チャンネル';

  @override
  String get nyquist => 'ナイキスト';

  @override
  String get dynamicRange => 'ダイナミックレンジ';

  @override
  String get peak => 'ピーク';

  @override
  String get truePeak => 'トゥルーピーク';

  @override
  String get clipping => 'クリッピング';

  @override
  String get cutoff => 'カットオフ';

  @override
  String get samples => 'サンプル数';

  @override
  String channelShort(int channel) {
    return 'Ch $channel';
  }

  @override
  String get noneClean => 'なし (クリーン)';

  @override
  String get reanalyzingAudio => 'オーディオストリームを再分析中...';

  @override
  String get analyzingAudio => 'オーディオストリームを分析中...';

  @override
  String sampleRateHz(int rate) {
    return 'サンプルレート: $rate Hz';
  }

  @override
  String nyquistKhz(String khz) {
    return 'ナイキスト: $khz kHz';
  }

  @override
  String get qualityLossless => 'ロスレス';

  @override
  String get qualityHigh => '高音質';

  @override
  String get qualityStandard => '標準音質';

  @override
  String get qualityAudio => 'オーディオ';

  @override
  String get addCustomFolder => 'カスタムフォルダを追加';

  @override
  String get addCustomFolderDesc => '音楽が別の名前のフォルダや SD カードにある場合は、直接追加してください。';

  @override
  String get indexingYourLibrary => 'ライブラリをインデックス中...';

  @override
  String get indexingYourLibraryDesc => '曲のタイトル、アートワーク、歌詞を補完しています。';

  @override
  String welcomeStep(String step, String title) {
    return 'ステップ $step: $title';
  }

  @override
  String get includeOtherDeviceAudioAlarmsDesc => '着信音、通知音、アラーム、メッセージアプリの音声';

  @override
  String get version => 'バージョン';

  @override
  String get noIndexedFoldersDesktopDesc =>
      '「ライブラリを再スキャンする」でストレージのフォルダを検出してください';

  @override
  String get playedLabel => '再生済み';

  @override
  String minutesShort(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 分',
    );
    return '$_temp0';
  }

  @override
  String minuteChip(int count) {
    return '$count 分';
  }

  @override
  String songsCountTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 曲',
    );
    return '$_temp0';
  }

  @override
  String songsLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '残り $count 曲',
    );
    return '$_temp0';
  }

  @override
  String sleepTimerWithRemaining(String remaining) {
    return 'スリープタイマー ($remaining)';
  }

  @override
  String get trackInfoSection => 'トラック情報';

  @override
  String get detailsSection => '詳細';

  @override
  String get lyricsSection => '歌詞';

  @override
  String get editLyricsHint => '歌詞をテキストまたは同期 LRC 形式 [00:00.00] で入力...';

  @override
  String addedSongsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 曲を追加しました',
    );
    return '$_temp0';
  }

  @override
  String get chooseInternalStorageFolder =>
      'このデバイスの内部ストレージまたは SD カードのフォルダを選択してください。';

  @override
  String get appCrashedTitle => 'Looper Player がクラッシュしました';

  @override
  String get appCrashedDesc => '起動時に予期しないエラーが発生しました。診断用のクラッシュレポートを作成しました。';

  @override
  String get appCrashedDetails =>
      'アプリのデータベースまたはサービスの初期化中にエラーが発生しました。ストレージへのアクセスが制限されているか、データベースファイルが破損している可能性があります。';

  @override
  String get crashReportSaved => '診断用クラッシュレポートをアプリのサポートフォルダに保存しました。';

  @override
  String get shareLog => 'ログを共有';

  @override
  String get restartApp => 'アプリを再起動';

  @override
  String get updateAvailableOnPlay => 'Google Play に新しいバージョンがあります。';

  @override
  String updateAvailableOnGithub(String version) {
    return 'バージョン $version が GitHub で公開されています。';
  }

  @override
  String get updateAvailable => 'アップデートがあります';

  @override
  String get updateAvailableTitle => 'アップデートがあります！';

  @override
  String get visit => '開く';

  @override
  String get updateDownloaded => 'アップデートをダウンロードしました';

  @override
  String get restartToInstallUpdate => 'インストールするには Looper Player を再起動してください。';

  @override
  String get restart => '再起動';

  @override
  String backupImportedSummary(int favorites, int stats, int playlists) {
    return 'バックアップを読み込みました: お気に入り $favorites 件と再生統計 $stats 件を統合し、プレイリスト $playlists 件を同期しました';
  }

  @override
  String get backupExportFailed =>
      'バックアップのエクスポートに失敗しました: ファイルの保存中に内部エラーが発生しました。';

  @override
  String get backupImportFailed => 'バックアップの読み込みに失敗しました: ファイルを読み取れないか、形式が無効です。';

  @override
  String get stereo => 'ステレオ';

  @override
  String get mono => 'モノラル';
}
