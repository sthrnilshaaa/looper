// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get about => '소개';

  @override
  String get aboutAndMaintainers => '정보 및 유지관리자';

  @override
  String get aboutApp => '앱 정보';

  @override
  String get aboutLooperPlayer => '루퍼 플레이어 소개';

  @override
  String get accentColor => '악센트 색상';

  @override
  String get accentColorDesc => '테마 테두리 및 액센트 색상 수동 선택';

  @override
  String get acousticSpectralAnalysis => '음향 및 스펙트럼 분석';

  @override
  String get activeCallCannotPlay => '재생 차단됨: 활성 통화 중에는 음악을 재생할 수 없습니다';

  @override
  String get adaptColorsArtwork => '앱 색상을 앨범 아트워크에 맞게 조정';

  @override
  String addedTo(String name) {
    return '$name에 추가됨';
  }

  @override
  String get addedToQueue => '대기열에 추가됨';

  @override
  String get addFolder => '폴더 추가';

  @override
  String get addToFavorites => '즐겨찾기에 추가';

  @override
  String get addToPlaylists => '재생목록에 추가';

  @override
  String get addToQueue => '대기열에 추가';

  @override
  String get album => '앨범';

  @override
  String get albums => '앨범';

  @override
  String get albumsRowDesc => '앨범의 수평 선반';

  @override
  String get allFilesAccess => '모든 파일 액세스(권장)';

  @override
  String get allSongs => '모든 노래';

  @override
  String get appDetailsCreator => '지원서 세부정보, 창작자, 디자인팀 정보';

  @override
  String get appearance => '테마';

  @override
  String get appInfoPrivacy => '앱 정보 및 개인정보 보호';

  @override
  String get appTitle => '루퍼 플레이어';

  @override
  String get artist => '아티스트';

  @override
  String get artists => '아티스트';

  @override
  String get artistsRowDesc => '예술가의 수평 선반';

  @override
  String get ascending => '오름차순';

  @override
  String get audioCrossfade => '오디오 크로스페이드';

  @override
  String get audioCrossfadeDesc => '곡이 바뀔 때 트랙을 부드럽게 겹칩니다';

  @override
  String get audioFocusDenied => '재생 일시중지됨: 시스템에서 오디오 포커스를 거부했습니다.';

  @override
  String get audioPlayback => '오디오 및 재생';

  @override
  String get audioPlaybackDesc => '크로스페이드, 무음 간격 및 페이드 설정';

  @override
  String get autoCrossfadeDuration => '자동 크로스페이드 시간';

  @override
  String get autoCrossfadeDurationDesc => '자동 전환 시 겹치는 시간';

  @override
  String get backToMainView => '기본 보기로 돌아가기';

  @override
  String get cancel => '취소';

  @override
  String get categories => '카테고리';

  @override
  String get center => '가운데';

  @override
  String get clear => '지우기';

  @override
  String get clearQueue => '지우기';

  @override
  String get connectDevice => '장치 연결';

  @override
  String get corePurpose => '핵심 목적';

  @override
  String get corePurposeDesc =>
      'Looper Player는 로컬 라이브러리에 대한 완벽한 제어, 끊김 없는 재생, 유연하고 동기화된 가사 스크롤을 원하는 음악 애호가를 위해 설계된 오프라인 최초의 고성능 오디오 플레이어입니다.';

  @override
  String get create => '만들기';

  @override
  String get createPlaylist => '재생목록 만들기';

  @override
  String get creatorAndMaintainer => '생성자 및 유지관리자';

  @override
  String get customAccentColor => '사용자 정의 강조 색상';

  @override
  String get customizeColorsTheme => '앱 색상, 테마, 가사 배경을 맞춤설정하세요.';

  @override
  String get dateAdded => '추가된 날짜';

  @override
  String get deepStorageScanProgress => '심층 저장소 검사 진행 중...';

  @override
  String get delete => '삭제';

  @override
  String get deleteFile => '파일 삭제';

  @override
  String get deletePlaylist => '재생목록 삭제';

  @override
  String deletePlaylistConfirm(String name) {
    return '\"$name\" 재생목록을 삭제하시겠습니까?';
  }

  @override
  String get deleteSong => '노래 삭제';

  @override
  String get deleteSongConfirm => '정말로 이 노래를 디스크에서 삭제하시겠습니까?';

  @override
  String get descending => '내림차순';

  @override
  String get designerAndMaintainer => '디자이너 및 유지관리자';

  @override
  String get disableBlurEffects => '흐림 효과 비활성화';

  @override
  String get disableSquigglyProgressBar => '구불구불한 물결 진행률 표시줄 애니메이션 비활성화';

  @override
  String get downloadAudioDirectly => '오디오를 직접 다운로드하세요';

  @override
  String get downloadingLyricsOffline => '오프라인 사용을 위해 가사 다운로드 중...';

  @override
  String get downloadMissingArtwork => '누락된 작품 다운로드';

  @override
  String get downloadMissingArtworkDesc =>
      'iTunes에서 노래의 고해상도 표지 아트워크를 자동으로 다운로드합니다.';

  @override
  String get duration => '재생 시간';

  @override
  String get dynamicAccentColor => '동적 액센트 색상';

  @override
  String get dynamicAccentColorDesc => '앨범 아트에서 액센트 색상만 동적으로 업데이트';

  @override
  String get dynamicBgOnlyLyrics => '가사 전용 동적 배경';

  @override
  String get dynamicColorActiveLyrics => '다이나믹 컬러 액티브 라인';

  @override
  String get dynamicColorActiveLyricsDesc => '현재 재생중인 가사라인에 추출된 아트워크 색상을 사용';

  @override
  String get dynamicLyricsBg => '다이나믹 가사 BG';

  @override
  String get dynamicLyricsBgDesc => '가사 화면에 앨범 아트 블러 적용';

  @override
  String get dynamicTheming => '동적 테마';

  @override
  String get emptyLibraryDesc =>
      '라이브러리에서 지원되는 음악 파일을 찾을 수 없습니다. 폴더를 추가하거나 검색 검사를 실행하세요.';

  @override
  String get enableNetworkLyricsArt => '온라인 가사 및 아티스트 아트에 대한 네트워크 사용 활성화';

  @override
  String get enablePlayerGradient => '음악 화면 그라데이션';

  @override
  String get enablePlayerGradientDesc =>
      '지금 재생 중인 화면에서 방사형 액센트 그라데이션 배경을 활성화합니다.';

  @override
  String get fadeDuration => '페이드 시간';

  @override
  String get fadeDurationDesc => '재생/일시정지/정지 페이드 효과 시간';

  @override
  String get fadeOnSeek => '탐색 시 페이드';

  @override
  String get fadeOnSeekDesc => '곡 탐색 시 음량을 부드럽게 페이드아웃/인합니다';

  @override
  String get fadePlayPauseStop => '재생/일시정지/정지 시 페이드';

  @override
  String get fadePlayPauseStopDesc => '재생, 일시정지, 정지 시 음량을 부드럽게 페이드인/아웃합니다';

  @override
  String get favorites => '즐겨찾기';

  @override
  String get fileInformation => '파일 정보';

  @override
  String get flatProgressBar => '플랫 진행률 표시줄';

  @override
  String get folders => '폴더';

  @override
  String get genre => '장르';

  @override
  String get genres => '장르';

  @override
  String get genresRowDesc => '음악 장르의 수평 선반';

  @override
  String get goStart => '시작하세요';

  @override
  String get grant => '그랜트';

  @override
  String get granted => '승인됨';

  @override
  String get history => '역사';

  @override
  String get home => '홈';

  @override
  String get homeDarkness => '홈 화면의 어둠';

  @override
  String get homeDarknessDesc => '홈 화면의 배경 오버레이 명암 조정';

  @override
  String get homeDashboardSettings => '홈 대시보드 설정';

  @override
  String get homeDashboardSettingsDesc => '홈 화면의 가로 행을 맞춤설정하세요.';

  @override
  String get internetMode => '인터넷 모드';

  @override
  String get keepBackgroundGradient => '배경 그라데이션 유지';

  @override
  String get keepBackgroundGradientDesc => '모든 애플리케이션 화면에서 배경 그라데이션 유지';

  @override
  String get animatePlayerGradient => '애니메이션 그라데이션';

  @override
  String get animatePlayerGradientDesc =>
      '음악에 반응하여 기본 색상과 3차 색상을 부드러운 그레인과 함께 천천히 움직입니다';

  @override
  String get animateBackgroundGradient => '애니메이션 배경';

  @override
  String get animateBackgroundGradientDesc =>
      '홈, 노래, 라이브러리 배경에 애니메이션 그라데이션을 사용합니다';

  @override
  String get language => '언어';

  @override
  String get left => '왼쪽';

  @override
  String get library => '도서관';

  @override
  String get libraryDarkness => '라이브러리 화면 어두움';

  @override
  String get libraryDarknessDesc => '라이브러리 화면의 배경 오버레이 명암 조정';

  @override
  String get libraryFoldersSync => '폴더, 재검색 트리거, 데이터베이스 재설정 및 오프라인 동기화';

  @override
  String get librarySettings => '라이브러리 설정';

  @override
  String get loadingMusicLibrary => '음악 라이브러리 로드 중';

  @override
  String get loadingMusicLibraryDesc =>
      '프리미엄 인덱스 구축, 하드웨어 리스너 설정 및 시각적 캐시 최적화.';

  @override
  String get loadingPhase1 => '오디오 저장 장치를 조사하는 중...';

  @override
  String get loadingPhase2 => '상쾌한 음악 엔진...';

  @override
  String get loadingPhase3 => '음향 데이터 추출 중...';

  @override
  String get loadingPhase4 => '재생 메모리 최적화 중...';

  @override
  String get lyrics => '가사';

  @override
  String get lyricsAlignment => '가사 정렬';

  @override
  String get lyricsAlignmentDesc => '가사 스크롤을 위한 텍스트 위치 정렬';

  @override
  String get lyricsDarkness => '가사 화면 어둠';

  @override
  String get lyricsDarknessDesc => '가사 화면의 배경 오버레이 농도 조정';

  @override
  String get lyricsProvider => '가사 제공자';

  @override
  String get lyricsProviderDesc => 'lrclib.net (LRCLIB)에서 온라인 가사를 가져옵니다';

  @override
  String get maintainersAndDesigners => '유지 관리자 및 디자이너';

  @override
  String get manageAudioFocus => '오디오 포커스 관리';

  @override
  String get manageAudioFocusDesc => '시스템 오디오 포커스 변경을 요청하고 이에 대응합니다';

  @override
  String get manageAudioFocusTitle => '오디오 포커스 관리';

  @override
  String get manageLanguageAndFocus => '언어 기본 설정 및 발신자 초점 상태 관리';

  @override
  String get audioFocusGetFocus => '포커스 얻기';

  @override
  String get audioFocusGetFocusDesc => '재생이 시작될 때 오디오 포커스를 요청합니다.';

  @override
  String get audioFocusReleaseFocus => '포커스 해제';

  @override
  String get audioFocusReleaseFocusDesc => '재생이 일시 중지되거나 중지될 때 오디오 포커스를 해제합니다.';

  @override
  String get audioFocusStopOnOtherSession => '다른 음악 세션에서 음악 중지';

  @override
  String get audioFocusStopOnOtherSessionDesc =>
      '다른 앱이 오디오 재생을 시작하면 재생을 일시 중지합니다.';

  @override
  String get audioFocusRestartOnGain => '포커스를 다시 얻으면 음악 재개';

  @override
  String get audioFocusRestartOnGainDesc =>
      '오디오 포커스가 돌아왔을 때, 포커스 손실로 재생이 중단되었던 경우에만 자동으로 재생을 재개합니다.';

  @override
  String get pauseOnDuckTitle => '음량 감소 시 일시 정지';

  @override
  String get pauseOnDuckDesc =>
      '다른 앱이 짧은 소리(예: 알림, 내비게이션 안내)를 재생할 때 음량을 낮추는 대신 재생을 일시 정지합니다.';

  @override
  String get resumeOnBluetoothConnectTitle => '블루투스 연결 시 재개';

  @override
  String get resumeOnBluetoothConnectDesc =>
      '블루투스 오디오 기기(헤드폰, 차량 키트)가 다시 연결되면 자동으로 재생을 재개합니다.';

  @override
  String get manualCrossfadeDuration => '수동 크로스페이드 시간';

  @override
  String get manualCrossfadeDurationDesc => '수동 스킵 시 겹치는 시간';

  @override
  String get matchingLyrics => '일치하는 가사';

  @override
  String get metadataDetails => '메타데이터 세부정보';

  @override
  String get mostPlayed => '가장 많이 재생됨';

  @override
  String get musicAudioAccess => '음악 및 오디오 액세스';

  @override
  String get musicDarkness => '뮤직 플레이어 어둠';

  @override
  String get musicDarknessDesc => '뮤직 플레이어 화면의 배경 오버레이 어둡게 조정';

  @override
  String get musicLibrary => '음악 라이브러리';

  @override
  String get muteOrPauseCalls => '통화 및 기타 오디오 활동 중 음소거 또는 일시 중지';

  @override
  String get newPlaylist => '새 재생목록';

  @override
  String get newTitle => '새 제목';

  @override
  String get nextUp => '다음 곡';

  @override
  String get noAlbumsFound => '앨범을 찾을 수 없습니다.';

  @override
  String get noArtistsFound => '아티스트를 찾을 수 없습니다.';

  @override
  String get noFavoritesYet => '즐겨찾기 없음';

  @override
  String get noHistoryYet => '기록 없음';

  @override
  String get noLyrics => '가사를 찾을 수 없습니다';

  @override
  String get noMusicDetected => '감지된 음악이 없습니다.';

  @override
  String get noPlaylistsCreated => '생성된 재생목록이 없습니다.';

  @override
  String get noPlaylistsYet => '재생목록 없음';

  @override
  String get noResultsFound => '검색결과가 없습니다';

  @override
  String get noSongsFound => '노래를 찾을 수 없습니다.';

  @override
  String get notificationAccess => '알림 액세스';

  @override
  String get nowPlaying => '지금 재생 중';

  @override
  String get performanceOptimizerDashboard => '성능 최적화 대시보드';

  @override
  String get performanceOptimizerDashboardDesc => '실시간 성능 최적화 통계 오버레이 표시';

  @override
  String get permanentFocusChangePause => '영구 포커스 상실 시 일시정지';

  @override
  String get permanentFocusChangePauseDesc =>
      '오디오 포커스를 영구적으로 잃으면 자동으로 재생을 일시정지합니다';

  @override
  String get plainTimestamps => '일반 타임스탬프';

  @override
  String get play => '플레이';

  @override
  String get playAll => '전체 재생';

  @override
  String get playbackAudio => '재생 및 언어';

  @override
  String get playlists => '재생목록';

  @override
  String get playNext => '다음으로 재생';

  @override
  String get playQueue => '재생 대기열';

  @override
  String get pressBackExit => '종료하려면 뒤로를 다시 누르세요.';

  @override
  String get privacySafety => '개인정보 보호 및 안전';

  @override
  String get privacySafetyDesc =>
      '100% 비공개이며 오프라인 우선입니다. 귀하의 트랙, 재생 기록, 즐겨찾기 및 구성은 로컬 장치의 안전한 Isar 데이터베이스 내에 엄격하게 보관됩니다. 당사는 귀하의 사용 데이터나 기본 설정을 추적, 수집 또는 공유하지 않습니다.';

  @override
  String get pureBlackOled => '퓨어 블랙(OLED)';

  @override
  String get pureBlackOledDesc => '배경에 완전한 검은색 사용 (OLED)';

  @override
  String get queue => '대기열';

  @override
  String get queueIsEmpty => '대기열이 비어 있습니다.';

  @override
  String get quickPicks => '빠른 추천';

  @override
  String get quickPicksRowDesc => '가장 많이 재생된 노래 그리드';

  @override
  String get readyToScan => '스캔 준비 완료';

  @override
  String get recentlyAddedSongsRowDesc => '최신 수입품 목록';

  @override
  String get recentlyPlayed => '최근 재생됨';

  @override
  String get recentPlayed => '최근 플레이';

  @override
  String get recentRowDesc => '최근 재생한 곡의 가로 선반';

  @override
  String get removedFromPlaylist => '재생목록에서 제거됨';

  @override
  String get removeFromFavorites => '즐겨찾기에서 제거';

  @override
  String get removeFromPlaylist => '재생목록에서 제거';

  @override
  String get rename => '이름 바꾸기';

  @override
  String get renameFile => '파일 이름 변경';

  @override
  String get renamePlaylist => '재생목록 이름 변경';

  @override
  String get renameSong => '노래 이름 바꾸기';

  @override
  String get reorderDashboardSections => '대시보드 섹션 재정렬';

  @override
  String get reorderDashboardSectionsDesc => '드래그 앤 드롭하여 기본 대시보드 순서 설정';

  @override
  String get includeOtherDeviceAudioTitle => '기타 기기 오디오 포함';

  @override
  String get includeOtherDeviceAudioDesc =>
      '벨소리, 알림, 알람, WhatsApp 및 Telegram 오디오를 스캔합니다';

  @override
  String get rescanLibrary => '라이브러리 다시 스캔';

  @override
  String get rescanStorage => '스토리지 다시 스캔';

  @override
  String get reset => '초기화';

  @override
  String get resetLibrary => '재설정 및 다시 검색';

  @override
  String get resetLibraryConfirm =>
      '이렇게 하면 모든 곡, 앨범, 아티스트가 지워지고 폴더를 완전히 다시 스캔합니다.';

  @override
  String get resetLibraryConfirmNew =>
      '라이브러리에서 모든 곡이 제거됩니다. 실제 음악 파일은 삭제되지 않습니다.';

  @override
  String get resetLibraryDesc => '인덱싱된 라이브러리에서 모든 곡 제거';

  @override
  String get resumeAfterCallDesc => '통화 종료 시 자동으로 재생을 재개합니다 (통화로 일시정지된 경우)';

  @override
  String get resumeAfterCallTitle => '통화 후 재개';

  @override
  String get resumeOnStartDesc => 'Looper Player가 시작될 때 자동으로 재생을 재개합니다';

  @override
  String get resumeOnStartTitle => '시작 시 재개';

  @override
  String get persistQueueTitle => '마지막 대기열 유지';

  @override
  String get persistQueueDesc => '앱 재시작 시 마지막 재생 곡과 대기열 저장';

  @override
  String get keepSongProgressTitle => '곡 재생 위치 유지';

  @override
  String get keepSongProgressDesc =>
      '각 곡의 재생 위치를 개별적으로 기억합니다. 곡을 재생하던 중 다른 곡으로 전환한 뒤 나중에 다시 돌아와도 — 그사이 다른 곡을 재생했더라도 — 처음부터가 아니라 멈췄던 지점부터 이어서 재생됩니다.';

  @override
  String get right => '오른쪽';

  @override
  String scanCompleteSongsDetected(int count) {
    return '스캔 완료: $count 노래가 감지되었습니다!';
  }

  @override
  String get scanForMusic => '음악 스캔';

  @override
  String get scanIndexLocalDesc => '로컬 음악 파일 스캔 및 색인 생성';

  @override
  String get scanLibrary => '스캔 라이브러리';

  @override
  String get scanningInBackground => '백그라운드에서 스캔 중...';

  @override
  String get scanningLibrary => '라이브러리 스캔 중...';

  @override
  String get scanningStorage => '저장소 스캔 중...';

  @override
  String get scanningStorageDesc =>
      '오디오 트랙을 찾기 위해 디렉터리 트리를 탐색합니다. 잠시만 기다려주세요...';

  @override
  String get search => '검색';

  @override
  String get searchLibraryHint => '전체 라이브러리 검색';

  @override
  String get searchSongsHint => '노래 검색';

  @override
  String get seekFadeDuration => '탐색 페이드 시간';

  @override
  String get seekFadeDurationDesc => '탐색 페이드 효과 시간';

  @override
  String get selectAppLanguage => '앱 언어 선택';

  @override
  String get selectCustomColor => '사용자 정의 색상 선택';

  @override
  String get selectCustomFolder => '맞춤 폴더 선택';

  @override
  String get selectFolderIndex => '음악 파일을 인덱싱할 폴더 선택';

  @override
  String get selectSpecificFolder => '특정 폴더 선택';

  @override
  String get settings => '설정';

  @override
  String get share => '공유';

  @override
  String get shareFile => '파일 공유';

  @override
  String get showAlbumsRow => '앨범 행 표시';

  @override
  String get showAlbumsRowDesc => '홈 화면에 앨범의 가로 목록 표시';

  @override
  String get showArtistsRow => '아티스트 행 표시';

  @override
  String get showArtistsRowDesc => '홈 화면에 아티스트의 가로 목록 표시';

  @override
  String get showGenresRow => '장르 행 표시';

  @override
  String get showGenresRowDesc => '홈 화면에 장르의 가로 목록을 표시합니다.';

  @override
  String get showLess => '간략히 표시';

  @override
  String get showMore => '더보기';

  @override
  String get showQualityBadge => '품질 배지 표시';

  @override
  String get showQualityBadgeDesc => '현재 재생 중인 화면에 오디오 품질 정보 배지 표시';

  @override
  String get showRecentRow => '최근 플레이 행 표시';

  @override
  String get showRecentRowDesc => '홈 화면에 최근 재생한 곡의 가로 목록 표시';

  @override
  String get silenceBetweenTracksDesc => '트랙 사이에 무음 간격을 추가합니다 (갭리스는 0ms)';

  @override
  String get silenceBetweenTracksTitle => '곡 간 무음 시간';

  @override
  String get songDeletedDbOnly => '라이브러리에서 삭제되었습니다 (실제 파일은 읽기 전용)';

  @override
  String get songDeletedSuccess => '곡 삭제 완료';

  @override
  String get songDeleteFailed => '곡 삭제 실패';

  @override
  String get songDetails => '노래 세부정보';

  @override
  String get songDetailsAndFrequency => '노래 세부정보 및 빈도';

  @override
  String get songRenamedDbOnly => '앱 라이브러리에서 이름이 변경되었습니다 (실제 파일은 읽기 전용)';

  @override
  String get songRenamedSuccess => '곡 이름 변경 완료';

  @override
  String get songRenameFailed => '곡 이름 변경 실패';

  @override
  String get songs => '노래';

  @override
  String get songsDarkness => '노래 화면 어둠';

  @override
  String get songsDarknessDesc => '노래 화면의 배경 오버레이 어두움 조정';

  @override
  String get sortBy => '정렬 기준';

  @override
  String get sortOrder => '정렬 순서';

  @override
  String get sourceCode => '소스 코드';

  @override
  String get stopServiceOnAppDismissal => '앱 종료 시 서비스 중지';

  @override
  String get stopServiceOnAppDismissalDesc =>
      '최근 앱 목록에서 앱을 닫을 때 백그라운드 서비스를 중지하고 앱을 종료합니다';

  @override
  String get storagePermissionRequired => '기기 메모리를 스캔하려면 저장소 권한이 필요합니다.';

  @override
  String get syncLyricsOffline => '가사 동기화(오프라인)';

  @override
  String get systemDefault => '시스템 기본값';

  @override
  String get systemPermissionChecklist => '시스템 권한 체크리스트';

  @override
  String get technicalInfoFrequency => '기술 정보 및 주파수';

  @override
  String get theme => '테마';

  @override
  String get title => '제목';

  @override
  String get todayMixForYou => '오늘은 당신을 위한 믹스';

  @override
  String get toggleFavorite => '즐겨찾기 전환';

  @override
  String get shuffleTitle => '셔플';

  @override
  String get shuffleDisabledDesc =>
      '곡을 원래 대기열 순서대로 재생합니다. 셔플을 끄면 현재 곡은 계속 재생되며, 나머지 대기열은 재생이나 재생 기록에 영향을 주지 않고 원래 순서로 복원됩니다.';

  @override
  String get shuffleEnabledDesc =>
      '현재 곡은 그대로 유지하면서 나머지 곡의 순서를 무작위로 섞습니다. 생성된 셔플 순서는 대기열이 바뀌거나 새로운 셔플이 요청될 때까지 그대로 유지되어 곡이 반복되거나 건너뛰어지는 것을 방지합니다.';

  @override
  String get shuffleSwitchingDesc =>
      '셔플을 켜거나 꺼도 현재 재생 중인 곡은 다시 시작되지 않습니다. 다음에 재생될 곡의 순서만 바뀌며, 켜면 무작위로, 끄면 원래 대기열 순서로 복원됩니다.';

  @override
  String get topResult => '상위 결과';

  @override
  String get transferMusicFiles => '음악 파일 전송';

  @override
  String get turnOffBlursOptimize => '성능을 최적화하려면 심한 흐림을 끄세요.';

  @override
  String get unknown => '알 수 없음';

  @override
  String get unknownAlbum => '알 수 없는 앨범';

  @override
  String get unknownArtist => '알 수 없는 아티스트';

  @override
  String get updateLibraryIndexing => '라이브러리 파일 인덱싱 업데이트';

  @override
  String get useAbsoluteBlackBg => '배경에 절대 검정색 사용';

  @override
  String get useStaticTextTimestamps => '진행 기간 동안 롤링 애니메이션 대신 정적 텍스트를 사용하십시오.';

  @override
  String get fluidPlayer => '플루이드 플레이어';

  @override
  String get fluidPlayerDesc => '미니 플레이어를 위로 끌어 전체 플레이어로 전환합니다';

  @override
  String get viewAll => '모두 보기';

  @override
  String get visitOfficialRepository => 'GitHub 공식 리포지토리 방문';

  @override
  String get welcomeAboutDesc =>
      'Looper Player는 프리미엄 오프라인 오디오 재생을 위해 제작된 차세대 Music-OS입니다. 실시간 동적 가사 생성, 통화 음소거 처리를 통한 고급 오디오 세션 관리, 적응형 배경 테마 및 다중 형식 음악 라이브러리 지원 기능을 갖추고 있습니다. 최대 배터리 효율을 위해 완전히 최적화되었습니다.';

  @override
  String get welcomeAllFilesDesc =>
      '비표준 디렉토리(다운로드, 텔레그램, 사용자 정의 폴더)에서 노래를 찾기 위한 전문적인 스캐닝에 적극 권장됩니다.';

  @override
  String get welcomeInstructionConnectDesc =>
      '표준 USB 데이터 케이블을 사용하여 휴대전화나 장치를 개인용 컴퓨터에 연결하세요.';

  @override
  String get welcomeInstructionDownloadDesc =>
      '또는 장치 자체에서 웹 브라우저나 기타 다운로더 유틸리티를 사용하여 직접 파일을 다운로드하십시오.';

  @override
  String get welcomeInstructionTransferDesc =>
      '오프라인 음악 파일(.mp3, .flac, .m4a, .wav 지원)을 장치의 표준 \'음악\' 또는 \'다운로드\' 폴더에 직접 복사하세요.';

  @override
  String get welcomeMusicAudioDesc =>
      '장치 메모리에서 표준 오프라인 오디오 트랙을 검색하고 재생하는 데 필요합니다.';

  @override
  String get welcomeNoSongsDesc =>
      '장치 저장소에서 지원되는 오디오 파일(MP3, FLAC, WAV, M4A, OGG)을 찾을 수 없습니다.';

  @override
  String get welcomeNotificationDesc =>
      '시스템 표시줄에 재생 컨트롤 및 활성 알림 위젯을 표시하는 데 필요합니다.';

  @override
  String get welcomeScanningFoldersDesc => '모든 폴더와 하위 폴더에서 오디오 파일을 검색합니다.';

  @override
  String get whyInternetUsed => '인터넷을 사용하는 이유';

  @override
  String get whyInternetUsedDesc =>
      '• 동적 가사 동기화: 온라인 데이터베이스에서 동기화된 가사(LRC 형식)를 안전하게 가져오고 다운로드하는 데에만 사용됩니다. 개인 데이터, 설정 또는 미디어 파일은 업로드되거나 공유되지 않습니다.';

  @override
  String get whyPermissionsUsed => '권한이 사용되는 이유';

  @override
  String get whyPermissionsUsedDesc =>
      '• 저장소/미디어 액세스: 장치에 저장된 로컬 오디오 트랙을 검색하고 읽고 색인을 생성하는 데 필요합니다.\n• 알림: 상태 표시줄과 시스템 서랍에 활성 재생 제어 위젯을 표시하는 데 필요합니다.';

  @override
  String get willPlayNext => '다음으로 재생됩니다';

  @override
  String get year => '연도';

  @override
  String get supportUs => '후원하기';

  @override
  String get supportUsDesc => 'Looper Player가 유지되고 오픈 소스로 남을 수 있도록 돕기';

  @override
  String get supportDevelopment => '개발 지원';

  @override
  String get supportDevelopmentDesc =>
      'Looper Player는 100% 무료이며 오픈 소스입니다. 마음에 드셨다면 제작자에게 후원을 고려해 주세요. 모든 기부는 프로젝트 활성화에 도움이 됩니다!';

  @override
  String get useCustomFont => '사용자 정의 글꼴 사용';

  @override
  String get useCustomFontDesc =>
      'Jost 또는 기타 사용자 정의 글꼴을 사용합니다. 그렇지 않으면 DM Sans가 사용됩니다.';

  @override
  String get selectFontFamily => '글꼴 패밀리 선택';

  @override
  String activeFont(String fontName) {
    return '활성 글꼴: $fontName';
  }

  @override
  String get fontWeightAdjustment => '글꼴 굵기 조정';

  @override
  String get currentWeight => '현재 굵기';

  @override
  String get useCustomFontLyrics => '가사에 사용자 정의 글꼴 사용';

  @override
  String get useCustomFontLyricsDesc => '동기화 가사 보기에 사용자 정의 글꼴과 굵기 사용';

  @override
  String get lyricsFontFamily => '가사 글꼴 패밀리';

  @override
  String activeLyricsFont(String fontName) {
    return '활성 가사 글꼴: $fontName';
  }

  @override
  String get lyricsFontWeightAdjustment => '가사 글꼴 굵기 조정';

  @override
  String get giveStarOnGithub => 'GitHub에서 스타 주기';

  @override
  String get supportProjectLove => '프로젝트를 지원하고 격려해 주세요!';

  @override
  String get sortAlphabeticalAZ => '가나다순 (A-Z)';

  @override
  String get sortAlphabeticalZA => '역순 (Z-A)';

  @override
  String get sortRecentlyAdded => '최근에 추가됨';

  @override
  String get sortOldestAdded => '가장 오래전에 추가됨';

  @override
  String get sortYearNewest => '연도 (최신순)';

  @override
  String get sortYearOldest => '연도 (오래된순)';

  @override
  String get sortMostSongs => '곡이 가장 많음';

  @override
  String get sortLeastSongs => '곡이 가장 적음';

  @override
  String get sortDefault => '기본';

  @override
  String get sortArtistAsc => '아티스트 (A-Z)';

  @override
  String get sortAlbumAsc => '앨범 (A-Z)';

  @override
  String get sortDuration => '재생 시간';

  @override
  String get myAlbums => '내 앨범';

  @override
  String get featuredArtists => '추천 아티스트';

  @override
  String get noSongPlaying => '재생 중인 곡이 없습니다';

  @override
  String get nextLabel => '다음';

  @override
  String get previousLabel => '이전';

  @override
  String get resync => '다시 동기화';

  @override
  String get equalizer => '이퀄라이저';

  @override
  String get presets => '프리셋';

  @override
  String get preAmpGain => '프리앰프 게인';

  @override
  String get outputVolume => '출력 볼륨';

  @override
  String get customFilterHint =>
      '사용자 지정 libavfilter 오디오 필터 매개변수를 직접 입력하세요 (예: volume=3dB, aecho=0.8:0.88:60:0.4):';

  @override
  String get flowGlobalActions => '흐름 및 전역 작업';

  @override
  String get equalizerModeLabel => '이퀄라이저 모드:';

  @override
  String get currentGainsAppliedGlobal => '현재 게인이 전역 기본 설정으로 적용되었습니다.';

  @override
  String get applyToGlobal => '전역에 적용';

  @override
  String get songSpecificResetGlobal => '곡별 설정이 전역 기본값으로 재설정되었습니다.';

  @override
  String get resetToGlobal => '전역으로 재설정';

  @override
  String get resetAllSongsEq => '모든 곡 EQ 재설정';

  @override
  String get resetAllSongsEqConfirm =>
      '라이브러리에 있는 모든 곡의 사용자 지정 이퀄라이저 설정을 지우시겠습니까?';

  @override
  String get allSongsEqDataReset => '모든 곡별 이퀄라이저 데이터가 재설정되었습니다.';

  @override
  String get resetAllSongsEqData => '모든 곡의 EQ 데이터 재설정';

  @override
  String get equalizerTargetMode => '이퀄라이저 적용 모드';

  @override
  String get equalizerTargetModeDesc =>
      '음악 라이브러리 전체에 이퀄라이저 설정을 적용하는 방식을 선택하세요.';

  @override
  String get globalMode => '전역 모드';

  @override
  String get globalModeDesc =>
      '모든 곡에 동일하게 효과를 적용합니다. 곡이 바뀌어도 이퀄라이저 설정은 그대로 유지됩니다.';

  @override
  String get songSpecificMode => '곡별 모드';

  @override
  String get songSpecificModeDesc =>
      '현재 곡에 대해서만 사용자 지정 설정을 저장합니다. 다음 곡은 자체 프로필이 없는 한 기본적으로 이퀄라이저가 적용되지 않습니다.';

  @override
  String get viewDeviceAudioCapabilities => '기기 오디오 기능 보기';

  @override
  String get deviceAudioCapabilities => '기기 오디오 기능';

  @override
  String get noPlaybackActiveCapabilities => '재생 중이 아니거나 기능 정보를 사용할 수 없습니다.';

  @override
  String get changeLyricsProvider => '가사 제공자 변경';

  @override
  String get autoFallbackProviders => '자동 대체 제공자';

  @override
  String get autoFallbackProvidersDesc => '기본 제공자에 가사가 없으면 나머지 제공자를 자동으로 시도합니다';

  @override
  String get ambientColorBackground => '앰비언트 컬러 배경';

  @override
  String get ambientColorBackgroundDesc => '곡의 아트워크에서 추출한 부드럽고 은은한 앰비언트 그라데이션';

  @override
  String get exportLyricsLrc => '가사 내보내기 (.lrc 파일)';

  @override
  String get saveLyricsToDevice => '현재 가사를 기기 저장소에 저장';

  @override
  String get noLyricsToExport => '내보낼 가사가 없습니다';

  @override
  String get useCustomLyricsLrc => '사용자 지정 가사 사용 (LRC 파일)';

  @override
  String get selectLocalLrcFile => '이 곡에 사용할 로컬 .lrc 또는 .txt 파일 선택';

  @override
  String get customLyricsAppliedSuccess => '사용자 지정 가사가 성공적으로 적용되었습니다!';

  @override
  String get noRecentlyPlayedTracks => '최근에 재생한 트랙이 없습니다';

  @override
  String get close => '닫기';

  @override
  String get audioQualityAnalysis => '오디오 품질 분석';

  @override
  String get audioQualityAnalysisDesc => '심층 스펙트럼 및 오디오 형식 분석을 수행합니다';

  @override
  String get audioStreamDetails => '오디오 스트림 세부정보';

  @override
  String get perChannelMetrics => '채널별 지표';

  @override
  String get sleepTimer => '잠자기 타이머';

  @override
  String get stopByTime => '시간으로 중지';

  @override
  String get start => '시작';

  @override
  String get stopBySongCount => '곡 수로 중지';

  @override
  String get cancelSleepTimer => '잠자기 타이머 취소';

  @override
  String get nowPlayingAllCaps => '재생 중';

  @override
  String get settingsAndBackups => '설정 및 백업';

  @override
  String get managePreferencesLibraryData => '환경설정 및 라이브러리 데이터 관리';

  @override
  String get logsClearedSuccess => '로그가 성공적으로 지워졌습니다';

  @override
  String get editSongInfo => '곡 정보 편집';

  @override
  String get editAlbumInfo => '앨범 정보 편집';

  @override
  String get tapFieldToEdit => '편집하려면 필드를 탭하세요';

  @override
  String get alwaysBlurSheets => '시트 항상 흐리게';

  @override
  String get alwaysBlurSheetsDesc => '다이내믹 테마가 꺼져 있어도 팝업 시트를 흐리게 표시합니다';

  @override
  String get removeArtwork => '아트워크 제거';

  @override
  String get resetArtworkToDefault => '기본값으로 재설정';

  @override
  String get artworkResetToDefault => '아트워크가 기본값으로 재설정됨';

  @override
  String get noEmbeddedArtworkFound => '이 앨범에 포함된 아트워크를 찾을 수 없습니다';

  @override
  String get saveChangesBtn => '변경사항 저장';

  @override
  String get enterFolderPathManually => '폴더 경로 직접 입력';

  @override
  String get folderPickerManualHint =>
      '시스템 디렉터리 선택기가 열리지 않으면 아래에 전체 디렉터리 경로를 입력하거나 붙여넣으세요:';

  @override
  String get noSupportedSongsFoundFolder => '선택한 폴더에서 지원되는 곡을 찾을 수 없습니다';

  @override
  String get add => '추가';

  @override
  String get folderPickerClosed => '폴더 선택기가 닫혔습니다';

  @override
  String get buyMeCoffee => '커피 한 잔 사주기';

  @override
  String get typeToSearchSettings => '설정을 검색하려면 입력하세요…';

  @override
  String get maintainersLabel => '관리자';

  @override
  String get personBehindLooperPlayer => 'LooperPlayer를 만든 사람';

  @override
  String get blurredArtworkForLyrics => '가사 화면의 흐림 아트워크';

  @override
  String get blurredArtworkForLyricsDesc =>
      '동적/정적 그라데이션 대신 흐릿한 앨범 아트를 배경으로 표시합니다';

  @override
  String get lyricsFontWeight => '가사 글꼴 굵기';

  @override
  String get openSourceLicenses => '오픈소스 라이선스';

  @override
  String get openSourceLicensesDesc => '이 앱에서 사용된 타사 라이브러리';

  @override
  String get done => '완료';

  @override
  String get lyricsNotAvailable => '가사를 사용할 수 없습니다.';

  @override
  String get lyricsNotAvailableHint => '이 곡의 가사를 추가하려면 .lrc 또는 .txt 파일을 가져오세요';

  @override
  String get importLyricsFile => '가사 파일 가져오기';

  @override
  String get approximatedSyncNoWordTimings => '근사 동기화 (단어별 타이밍 없음)';

  @override
  String get lyricsSyncHelp => '가사 동기화 도움말';

  @override
  String get simpleModeLabel => '간단 모드';

  @override
  String get advancedModeLabel => '고급 모드';

  @override
  String get tips => '팁';

  @override
  String get gotIt => '확인했습니다';

  @override
  String get lyricsSyncStudio => '가사 동기화 스튜디오';

  @override
  String get lyricsTextLabel => '가사 텍스트';

  @override
  String get lyricsTextHelperDesc =>
      '가사 한 줄당 한 행씩 입력하세요. 아래 동기화 도구가 이 줄에 타임스탬프를 붙입니다.';

  @override
  String get quickSync => '빠른 동기화';

  @override
  String get autoAdvanceAfterStamping => '타임스탬프 찍은 후 자동으로 다음 줄로 이동';

  @override
  String get advancedSync => '고급 동기화';

  @override
  String get useCurrentTime => '현재 시간 사용';

  @override
  String get playbackAssist => '재생 지원';

  @override
  String get timeShift => '시간 이동';

  @override
  String get timeShiftDesc => '타임스탬프가 찍힌 모든 가사를 함께 앞뒤로 이동합니다.';

  @override
  String get lyricsSaveLrcExplain =>
      '저장하면 가능한 경우 곡 오디오 파일 옆에 `.lrc` 사이드카 파일을 만들고, 로컬 플레이어 데이터베이스에도 저장합니다. 타임스탬프가 없는 줄은 자동으로 보간됩니다.';

  @override
  String get back => '뒤로';

  @override
  String get appSettingsLabel => '앱 설정';

  @override
  String get backupsAndLogs => '백업 및 로그';

  @override
  String get backupsAndLogsDesc => '앱 데이터 내보내기, 가져오기 및 관리';

  @override
  String get exportBackupJson => '백업 내보내기 (JSON)';

  @override
  String get exportBackupJsonDesc =>
      '좋아요한 곡과 재생목록을 보관하거나 공유할 수 있는 JSON 파일로 저장합니다. 그 외에는 포함되지 않습니다.';

  @override
  String get importBackupJson => '백업 가져오기 (JSON)';

  @override
  String get importBackupJsonDesc =>
      '백업 파일의 좋아요한 곡과 재생목록을 라이브러리에 병합합니다. 기존 데이터는 절대 덮어쓰거나 삭제되지 않습니다.';

  @override
  String get exportDiagnosticsLogs => '진단 로그 내보내기';

  @override
  String get exportDiagnosticsLogsDesc =>
      '문제 해결을 위해 검토할 수 있도록 앱의 진단 로그 파일을 공유합니다.';

  @override
  String get clearDiagnosticsLogs => '진단 로그 지우기';

  @override
  String get clearDiagnosticsLogsDesc =>
      '이 기기에 저장된 진단 로그 파일을 영구적으로 삭제합니다. 이 작업은 되돌릴 수 없습니다.';

  @override
  String get lyricsPlainTextOrLrc => '가사 (일반 텍스트 또는 LRC)';

  @override
  String get syncModeLine => '줄';

  @override
  String get syncModeWord => '단어';

  @override
  String get syncModeChar => '문자';

  @override
  String get enterManually => '직접 입력';

  @override
  String get rawFilterParametersHint => '원시 필터 매개변수...';

  @override
  String get searchSettingsHint => '설정 검색...';

  @override
  String get repeatTooltip => '반복';

  @override
  String get favoriteTooltip => '즐겨찾기';

  @override
  String get instructionsTooltip => '사용법';

  @override
  String get pasteLyricsHint => '여기에 가사를 붙여넣거나 입력하세요';

  @override
  String get timestampMmSsHint => '타임스탬프 (mm:ss.xx)';

  @override
  String get nowLabel => '지금';

  @override
  String get playlistNameHint => '재생목록 이름';

  @override
  String get songInfoUpdated => '곡 정보가 업데이트되었습니다!';

  @override
  String get albumInfoUpdated => '앨범 정보가 업데이트되었습니다!';

  @override
  String get failedToSaveChanges => '변경사항을 저장하지 못했습니다.';

  @override
  String sleepTimerStoppingIn(String time) {
    return '활성: $time 후 중지';
  }

  @override
  String sleepTimerStoppingAfter(String time) {
    return '활성: $time 경과 후 중지';
  }

  @override
  String get selectWhenToPause => '음악 재생을 일시 중지할 시점을 선택하세요';

  @override
  String get selectAvatars => '아바타 선택';

  @override
  String get selectAvatarsDesc => '홈 화면에 표시할 아바타를 선택하세요';

  @override
  String get dynamicAvatarColor => '다이나믹 아바타 색상';

  @override
  String get dynamicAvatarColorDesc => '아바타의 강조 색상을 현재 테마에 맞춥니다';

  @override
  String enrichingSongs(int count) {
    return '$count개 과 다양한 정보를 수집 중…';
  }

  @override
  String get noListeningHistoryYet => '아직 감상 기록이 없습니다';

  @override
  String get noListeningHistoryYetDesc =>
      '노래를 몇 곡 재생하면 많이 들은 노래, 아티스트, 앨범, 장르를 담은 나만의 리포트가 여기에 표시됩니다.';

  @override
  String get looperAnalyze => 'Looper Analyze';

  @override
  String get totalPlays => '총 재생 횟수';

  @override
  String get listeningTime => '감상 시간';

  @override
  String get currentStreakDays => '현재 연속 기록(일)';

  @override
  String get longestStreakDays => '최장 연속 기록(일)';

  @override
  String analyzePlaysAndSongs(int plays, int songs) {
    return '$plays회 재생 • $songs곡';
  }

  @override
  String get dayPartMorningShort => '아침';

  @override
  String get dayPartAfternoonShort => '오후';

  @override
  String get dayPartEveningShort => '저녁';

  @override
  String get dayPartNightShort => '밤';

  @override
  String get activityPattern => '활동 패턴';

  @override
  String get whenYouListenMost => '가장 많이 듣는 시간대';

  @override
  String get genreBreakdown => '장르 분포';

  @override
  String get otherGenre => '기타';

  @override
  String get topAlbums => '인기 앨범';

  @override
  String get topArtists => '인기 아티스트';

  @override
  String get topSongs => '인기 노래';

  @override
  String playsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count회 재생',
    );
    return '$_temp0';
  }

  @override
  String songsPlayedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count곡 재생',
    );
    return '$_temp0';
  }

  @override
  String get listeningTrend => '감상 추이';

  @override
  String get last30Days => '최근 30일';

  @override
  String errorWithDetails(String error) {
    return '오류: $error';
  }

  @override
  String get selectAll => '모두 선택';

  @override
  String get playlist => '재생목록';

  @override
  String songsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count곡',
    );
    return '$_temp0';
  }

  @override
  String get recentSearches => '최근 검색';

  @override
  String get lyricsSourceLocalFile => '로컬 파일';

  @override
  String get lyricsSourceEmbedded => '내장 메타데이터';

  @override
  String lyricsProvidedBy(String source) {
    return '가사 제공: $source';
  }

  @override
  String failedToImportLyrics(String error) {
    return '가사를 가져오지 못했습니다: $error';
  }

  @override
  String get lyricsEditorLines => '줄';

  @override
  String get lyricsEditorStamped => '지정됨';

  @override
  String lyricsEditorLineNumber(int number) {
    return '$number번째 줄';
  }

  @override
  String get lyricsEditorEmptyLine => '(빈 줄)';

  @override
  String get lyricsEditorNotStamped => '아직 지정 안 됨';

  @override
  String get pause => '일시정지';

  @override
  String get lyricsEditorAddLineFirst => '먼저 가사를 한 줄 이상 추가하세요.';

  @override
  String get lyricsEditorSavedWithSidecar => '가사를 데이터베이스와 노래 파일 옆에 저장했습니다.';

  @override
  String get lyricsEditorSavedDbOnly => '가사를 플레이어 데이터베이스에 저장했습니다.';

  @override
  String get lyricsEditorSaveFailed => '가사를 저장하지 못했습니다.';

  @override
  String get saving => '저장 중...';

  @override
  String get saveLrc => 'LRC 저장';

  @override
  String lyricsEditorSelectedLine(int index, int total) {
    return '선택한 줄 $index/$total';
  }

  @override
  String get lyricsEditorPickLine => '아래 목록에서 가사 줄을 선택하세요.';

  @override
  String get stampAndNext => '지정 후 다음';

  @override
  String get stampNow => '지금 지정';

  @override
  String get lyricsEditorSimpleSteps =>
      '1. 한 줄에 가사 한 줄씩 붙여넣거나 입력하세요.\n2. 노래를 재생하세요.\n3. 현재 가사 줄을 선택하세요.\n4. 그 줄이 들리면 \"지정 후 다음\"을 탭하세요.\n5. 끝나면 저장하세요.';

  @override
  String get lyricsEditorAdvancedSteps =>
      '1. 각 줄의 타임스탬프를 직접 편집하세요.\n2. \"현재 시간 사용\"으로 재생 중인 시간을 가져오세요.\n3. 이동 컨트롤로 지정된 모든 줄을 함께 옮기세요.\n4. 저장하면 최종 `.lrc` 파일이 생성됩니다.';

  @override
  String get lyricsEditorTipsText =>
      '- 지정되지 않은 줄이 있으면 Flick 엔진이 시간을 자동으로 채웁니다.\n- 저장 시 가능하면 노래 옆에 기록하고, 그렇지 않으면 연결된 사본을 데이터베이스에 보관합니다.';

  @override
  String fileNotFoundOrInaccessible(String title) {
    return '파일을 찾을 수 없거나 접근할 수 없습니다: $title';
  }

  @override
  String playbackFailedCorrupted(String title) {
    return '재생 실패: \"$title\"을(를) 불러오거나 재생할 수 없습니다. 파일이 손상되지 않았는지 확인하세요.';
  }

  @override
  String shareSongText(String title) {
    return '이 노래 들어 봐: $title';
  }

  @override
  String shareSongsText(int count) {
    return '이 노래 $count곡 들어 봐';
  }

  @override
  String noSettingsFoundFor(String query) {
    return '\"$query\"에 대한 설정이 없습니다';
  }

  @override
  String get chooseQuickAccentColors => '빠른 강조 색상 선택';

  @override
  String get fontWeight => '글꼴 두께';

  @override
  String get changeBaseFontWeight => '사용자 지정 글꼴의 기본 두께 변경';

  @override
  String lyricsFontWeightValue(int weight) {
    return '가사 글꼴 두께: $weight';
  }

  @override
  String get equalizerSearchDesc => '18밴드 이퀄라이저와 오디오 프리셋 조정';

  @override
  String get stopServiceSearchDesc => '최근 앱에서 밀어서 닫으면 재생을 멈추고 앱 종료';

  @override
  String get scanNewFolderDesc => '새 폴더에서 오디오 파일 검색';

  @override
  String get includeOtherDeviceAudioShortDesc => '벨소리, 알림음, 메신저 오디오';

  @override
  String get excludedFolders => '제외된 폴더';

  @override
  String get excludedFoldersSearchDesc => '스캔할 때 특정 폴더 건너뛰기';

  @override
  String get clearLibraryData => '라이브러리 데이터 삭제';

  @override
  String get looperPlayerVersion => 'Looper Player 버전';

  @override
  String versionLabel(String version) {
    return '버전 $version';
  }

  @override
  String get none => '없음';

  @override
  String foldersSkippedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '스캔 시 폴더 $count개 건너뜀',
    );
    return '$_temp0';
  }

  @override
  String get excludedFoldersDesc => '이 폴더에 있는 노래는 추가한 폴더 안에 있더라도 스캔할 때 건너뜁니다.';

  @override
  String get noExcludedFoldersYet => '아직 제외된 폴더가 없습니다.';

  @override
  String get excludeAFolder => '폴더 제외';

  @override
  String get equalizerEnabled18Band => '사용 (18밴드 MPV EQ)';

  @override
  String get disabled => '사용 안 함';

  @override
  String get noIndexedFoldersYet => '아직 색인된 폴더가 없습니다';

  @override
  String get noIndexedFoldersYetDesc => '\"라이브러리 다시 스캔\"을 사용해 저장소의 폴더를 찾으세요.';

  @override
  String get eqDynamicRangeCompressor => '다이내믹 레인지 컴프레서';

  @override
  String get eqThreshold => '임계값';

  @override
  String get eqRatio => '비율';

  @override
  String get eqAttack => '어택';

  @override
  String get eqRelease => '릴리스';

  @override
  String get eqHeadphoneCrossfeedWidth => '헤드폰 크로스피드 및 폭';

  @override
  String get eqBinauralCrossfeed => '바이노럴 크로스피드';

  @override
  String get eqCrossfeedStrength => '크로스피드 강도';

  @override
  String get eqStereoWidening => '스테레오 확장';

  @override
  String get eqWideningFactor => '확장 계수';

  @override
  String get eqLoudnessNormalization => '라우드니스 정규화';

  @override
  String get eqTargetLoudness => '목표 라우드니스';

  @override
  String get eqToneShelving => '톤 셸빙 (저음 / 고음)';

  @override
  String get eqBassShelf => '저음 셸프';

  @override
  String get eqTrebleShelf => '고음 셸프';

  @override
  String get eqTempoPitchControls => '템포 및 피치 조절';

  @override
  String get eqPitchShift => '피치 시프트';

  @override
  String get eqTempoSpeed => '템포 속도';

  @override
  String get eqVoiceSilenceControls => '음성 및 무음 조절';

  @override
  String get eqSilenceTrimming => '무음 잘라내기';

  @override
  String get eqSilenceThreshold => '무음 임계값';

  @override
  String get eqSpeechEnhancementFilter => '음성 향상 필터';

  @override
  String get eqHighpassCutoff => '하이패스 차단 주파수';

  @override
  String get eqLowpassCutoff => '로우패스 차단 주파수';

  @override
  String get eqRetroRoomEffects => '레트로 및 공간 효과';

  @override
  String get eqLofiEffect => '로파이 효과 (8비트 크러셔)';

  @override
  String get eqStudioRoomReverb => '스튜디오 룸 리버브 (에코)';

  @override
  String get eqVirtualSurround => '가상 5.1 서라운드 사운드';

  @override
  String get eqRawFilterConsole => 'FFmpeg 원시 필터 콘솔';

  @override
  String get eqSwitchToSliders => '슬라이더로 전환';

  @override
  String get eqSwitchToGraph => '그래프로 전환';

  @override
  String get on => '켜짐';

  @override
  String get off => '꺼짐';

  @override
  String get eqSongSpecificActive => '곡별 설정 사용 중';

  @override
  String get eqUsingGlobalDefault => '전역 기본 설정 사용 중';

  @override
  String get eqInteractiveGraphHint => '인터랙티브 그래프 (점을 위아래로 드래그)';

  @override
  String get eq18BandHint => '18밴드 이퀄라이저 (가로로 스크롤)';

  @override
  String get eqSongSpecific => '곡별';

  @override
  String get eqGlobalDefault => '전역 기본값';

  @override
  String get eqEditScopeNote =>
      '노래 재생 중에 한 변경은 해당 노래에만 적용됩니다. 전역 기본값을 설정하려면 재생 중인 노래가 없을 때 편집하거나 \'전역에 적용\'을 사용하세요.';

  @override
  String get presetFlat => '플랫';

  @override
  String get presetBassBooster => '저음 강화';

  @override
  String get presetTrebleBooster => '고음 강화';

  @override
  String get presetVocalBooster => '보컬 강화';

  @override
  String get presetElectronic => '일렉트로닉';

  @override
  String get presetRock => '록';

  @override
  String get presetPop => '팝';

  @override
  String get presetJazz => '재즈';

  @override
  String get save => '저장';

  @override
  String get savePreset => '프리셋 저장';

  @override
  String get presetName => '프리셋 이름';

  @override
  String get deletePreset => '프리셋 삭제';

  @override
  String deletePresetConfirm(String name) {
    return '\"$name\" 프리셋을 삭제할까요?';
  }

  @override
  String get noLyricsSource => '가사 출처 없음';

  @override
  String lyricsSourceLabel(String source) {
    return '출처: $source';
  }

  @override
  String get lyricsSourceLocalSidecar => '로컬 사이드카 (.lrc)';

  @override
  String get lyricsSourceCustomFile => '사용자 지정 LRC 파일';

  @override
  String get lyricsSourceNotFoundOnline => '온라인에서 찾을 수 없음';

  @override
  String get lyricsProviderLocal => '로컬';

  @override
  String get checkingLocalLyrics => '로컬/내장 가사 확인 중...';

  @override
  String fetchingLyricsFrom(String provider) {
    return '$provider에서 가사를 가져오는 중...';
  }

  @override
  String get loadedLocalLyrics => '로컬/내장 가사를 불러왔습니다!';

  @override
  String get noLocalLyricsFound => '로컬 또는 내장 가사를 찾을 수 없습니다';

  @override
  String lyricsUpdatedFrom(String provider) {
    return '$provider에서 가사를 업데이트했습니다!';
  }

  @override
  String noLyricsFoundOn(String provider) {
    return '$provider에서 가사를 찾을 수 없습니다';
  }

  @override
  String get gestureTips => '제스처 팁';

  @override
  String get gestureTipsDesc => '탭, 길게 누르기, 핀치 줌 등';

  @override
  String get exportLyrics => '가사 내보내기';

  @override
  String lyricsExportedTo(String path) {
    return '가사를 내보낸 위치: $path';
  }

  @override
  String failedToExportLyrics(String error) {
    return '가사를 내보내지 못했습니다: $error';
  }

  @override
  String get gestureTapLine => '줄 탭하기';

  @override
  String get gestureTapLineDesc => '해당 가사 위치로 바로 이동합니다.';

  @override
  String get gestureLongPressLine => '줄 길게 누르기';

  @override
  String get gestureLongPressLineDesc =>
      '공유용 가사 카드로 만들 줄을 선택하기 시작합니다. 다른 줄을 탭하면 선택 범위가 늘어납니다.';

  @override
  String get gesturePinch => '두 손가락으로 핀치';

  @override
  String get gesturePinchDesc => '가사 글자 크기를 원하는 대로 조절합니다.';

  @override
  String get gestureSwipeDown => '아래로 스와이프';

  @override
  String get gestureSwipeDownDesc => '가사 화면을 닫고 플레이어로 돌아갑니다.';

  @override
  String get lyricsGestures => '가사 제스처';

  @override
  String get lyricsGesturesIntro => '이 화면에서 쉽게 눈에 띄지 않는 기능 몇 가지:';

  @override
  String linesSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count줄 선택됨',
    );
    return '$_temp0';
  }

  @override
  String get couldNotGenerateShareImage => '공유 이미지를 만들지 못했습니다.';

  @override
  String get couldNotGenerateImage => '이미지를 만들지 못했습니다.';

  @override
  String get savedToGallery => '갤러리에 저장했습니다.';

  @override
  String get galleryPermissionDenied => '갤러리 접근 권한이 거부되었습니다.';

  @override
  String get couldNotSaveToGallery => '이미지를 갤러리에 저장하지 못했습니다.';

  @override
  String get shareLyrics => '가사 공유';

  @override
  String get backgroundColor => '배경 색상';

  @override
  String get lyricsTextColor => '가사 글자 색상';

  @override
  String get saveToGallery => '갤러리에 저장';

  @override
  String get preparing => '준비 중...';

  @override
  String get trackTitle => '트랙 제목';

  @override
  String get composer => '작곡가';

  @override
  String get unknownGenre => '알 수 없는 장르';

  @override
  String get releaseYear => '발매 연도';

  @override
  String get notAvailable => '없음';

  @override
  String get recordLabel => '레이블';

  @override
  String get copyright => '저작권';

  @override
  String get encoder => '인코더';

  @override
  String get fileName => '파일 이름';

  @override
  String get fileFormat => '파일 형식';

  @override
  String get fileSize => '파일 크기';

  @override
  String get absolutePath => '절대 경로';

  @override
  String get playCount => '재생 횟수';

  @override
  String playCountTimes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count회',
    );
    return '$_temp0';
  }

  @override
  String get lastPlayed => '마지막 재생';

  @override
  String get filePath => '파일 경로';

  @override
  String get rescan => '다시 스캔';

  @override
  String get codec => '코덱';

  @override
  String get container => '컨테이너';

  @override
  String get sampleRate => '샘플 레이트';

  @override
  String get bitDepth => '비트 심도';

  @override
  String get decodedFormat => '디코딩 형식';

  @override
  String get bitrate => '비트레이트';

  @override
  String get channels => '채널';

  @override
  String get nyquist => '나이퀴스트';

  @override
  String get dynamicRange => '다이내믹 레인지';

  @override
  String get peak => '피크';

  @override
  String get truePeak => '트루 피크';

  @override
  String get clipping => '클리핑';

  @override
  String get cutoff => '차단 주파수';

  @override
  String get samples => '샘플 수';

  @override
  String channelShort(int channel) {
    return 'Ch $channel';
  }

  @override
  String get noneClean => '없음 (깨끗함)';

  @override
  String get reanalyzingAudio => '오디오 스트림 다시 분석 중...';

  @override
  String get analyzingAudio => '오디오 스트림 분석 중...';

  @override
  String sampleRateHz(int rate) {
    return '샘플 레이트: $rate Hz';
  }

  @override
  String nyquistKhz(String khz) {
    return '나이퀴스트: $khz kHz';
  }

  @override
  String get qualityLossless => '무손실';

  @override
  String get qualityHigh => '고음질';

  @override
  String get qualityStandard => '표준 음질';

  @override
  String get qualityAudio => '오디오';

  @override
  String get addCustomFolder => '사용자 지정 폴더 추가';

  @override
  String get addCustomFolderDesc => '음악이 다른 이름의 폴더나 SD 카드에 있다면 직접 추가하세요.';

  @override
  String get indexingYourLibrary => '라이브러리 색인 중...';

  @override
  String get indexingYourLibraryDesc => '노래의 제목, 아트워크, 가사를 채우고 있습니다.';

  @override
  String welcomeStep(String step, String title) {
    return '$step단계: $title';
  }

  @override
  String get includeOtherDeviceAudioAlarmsDesc => '벨소리, 알림음, 알람, 메신저 오디오';

  @override
  String get version => '버전';

  @override
  String get noIndexedFoldersDesktopDesc => '\"라이브러리 다시 스캔\"을 사용해 저장소 폴더를 찾으세요';

  @override
  String get playedLabel => '재생함';

  @override
  String minutesShort(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count분',
    );
    return '$_temp0';
  }

  @override
  String minuteChip(int count) {
    return '$count분';
  }

  @override
  String songsCountTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count곡',
    );
    return '$_temp0';
  }

  @override
  String songsLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count곡 남음',
    );
    return '$_temp0';
  }

  @override
  String sleepTimerWithRemaining(String remaining) {
    return '수면 타이머 ($remaining)';
  }

  @override
  String get trackInfoSection => '트랙 정보';

  @override
  String get detailsSection => '세부 정보';

  @override
  String get lyricsSection => '가사';

  @override
  String get editLyricsHint => '일반 텍스트 또는 동기화된 LRC 형식 [00:00.00]으로 가사 입력...';

  @override
  String addedSongsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count곡 추가됨',
    );
    return '$_temp0';
  }

  @override
  String get chooseInternalStorageFolder =>
      '이 기기의 내부 저장소 또는 SD 카드에 있는 폴더를 선택하세요.';

  @override
  String get appCrashedTitle => 'Looper Player가 중단되었습니다';

  @override
  String get appCrashedDesc => '초기화 중 예기치 않은 오류가 발생했습니다. 진단용 오류 보고서가 생성되었습니다.';

  @override
  String get appCrashedDetails =>
      '앱 데이터베이스 또는 서비스를 초기화하는 중 오류가 발생했습니다. 저장소 접근이 제한되었거나 데이터베이스 파일이 손상된 경우 발생할 수 있습니다.';

  @override
  String get crashReportSaved => '진단용 오류 보고서를 앱 지원 폴더에 저장했습니다.';

  @override
  String get shareLog => '로그 공유';

  @override
  String get restartApp => '앱 다시 시작';

  @override
  String get updateAvailableOnPlay => 'Google Play에서 새 버전을 사용할 수 있습니다.';

  @override
  String updateAvailableOnGithub(String version) {
    return 'GitHub에서 버전 $version을(를) 사용할 수 있습니다.';
  }

  @override
  String get updateAvailable => '업데이트 가능';

  @override
  String get updateAvailableTitle => '업데이트가 있습니다!';

  @override
  String get visit => '열기';

  @override
  String get updateDownloaded => '업데이트 다운로드됨';

  @override
  String get restartToInstallUpdate => '설치하려면 Looper Player를 다시 시작하세요.';

  @override
  String get restart => '다시 시작';

  @override
  String backupImportedSummary(int favorites, int stats, int playlists) {
    return '백업 가져옴: 즐겨찾기 $favorites개와 재생 통계 $stats개 병합, 재생목록 $playlists개 동기화';
  }

  @override
  String get backupExportFailed => '백업 내보내기 실패: 백업 파일을 저장하는 중 내부 오류가 발생했습니다.';

  @override
  String get backupImportFailed => '백업 가져오기 실패: 파일을 읽을 수 없거나 백업 형식이 올바르지 않습니다.';

  @override
  String get stereo => '스테레오';

  @override
  String get mono => '모노';
}
