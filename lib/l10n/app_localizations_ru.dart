// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get about => 'О';

  @override
  String get aboutAndMaintainers => 'О компании и сопровождающие';

  @override
  String get aboutApp => 'О приложении';

  @override
  String get aboutLooperPlayer => 'О ЛУПЕР-ПЛЕЕРЕ';

  @override
  String get accentColor => 'Акцентный цвет';

  @override
  String get accentColorDesc => 'Выбрать акцентный цвет темы вручную';

  @override
  String get acousticSpectralAnalysis => 'АКУСТИЧЕСКИЙ И СПЕКТРАЛЬНЫЙ АНАЛИЗ';

  @override
  String get activeCallCannotPlay =>
      'Воспроизведение заблокировано: Невозможно воспроизводить музыку во время активного вызова';

  @override
  String get adaptColorsArtwork =>
      'Адаптируйте цвета приложения к обложке альбома';

  @override
  String addedTo(String name) {
    return 'Добавлено в $name';
  }

  @override
  String get addedToQueue => 'Добавлено в очередь';

  @override
  String get addFolder => 'Добавить папку';

  @override
  String get addToFavorites => 'Добавить в избранное';

  @override
  String get addToPlaylists => 'Добавить в плейлисты';

  @override
  String get addToQueue => 'Добавить в очередь';

  @override
  String get album => 'Альбом';

  @override
  String get albums => 'Альбомы';

  @override
  String get albumsRowDesc => 'Горизонтальная полка для альбомов';

  @override
  String get allFilesAccess => 'ДОСТУП ВСЕМ ФАЙЛАМ (РЕКОМЕНДУЕТСЯ)';

  @override
  String get allSongs => 'Все песни';

  @override
  String get appDetailsCreator =>
      'Сведения о приложении, сведения об создателе и команде разработчиков.';

  @override
  String get appearance => 'Внешний вид';

  @override
  String get appInfoPrivacy => 'ИНФОРМАЦИЯ О ПРИЛОЖЕНИИ И КОНФИДЕНЦИАЛЬНОСТЬ';

  @override
  String get appTitle => 'Лупер-плеер';

  @override
  String get artist => 'Исполнитель';

  @override
  String get artists => 'Художники';

  @override
  String get artistsRowDesc => 'Горизонтальная полка художников';

  @override
  String get ascending => 'По возрастанию';

  @override
  String get audioCrossfade => 'Кроссфейд (плавный переход)';

  @override
  String get audioCrossfadeDesc =>
      'Плавно накладывать треки друг на друга при смене песен';

  @override
  String get audioFocusDenied =>
      'Воспроизведение приостановлено: система отказала в фокусировке звука';

  @override
  String get audioPlayback => 'Аудио и воспроизведение';

  @override
  String get audioPlaybackDesc => 'Настройки кроссфейда, пауз и затухания';

  @override
  String get autoCrossfadeDuration => 'Длительность авто-кроссфейда';

  @override
  String get autoCrossfadeDurationDesc =>
      'Время наложения при автоматическом переходе';

  @override
  String get backToMainView => 'ВЕРНУТЬСЯ К ГЛАВНОМУ ВИДУ';

  @override
  String get cancel => 'Отмена';

  @override
  String get categories => 'Категории';

  @override
  String get center => 'По центру';

  @override
  String get clear => 'Очистить';

  @override
  String get clearQueue => 'Очистить';

  @override
  String get connectDevice => 'ПОДКЛЮЧИТЬ УСТРОЙСТВО';

  @override
  String get corePurpose => 'Основная цель';

  @override
  String get corePurposeDesc =>
      'Looper Player — это высококачественный аудиоплеер, предназначенный для любителей музыки, которым нужен абсолютный контроль над своей локальной библиотекой, непрерывное воспроизведение и плавная синхронизированная прокрутка текстов песен.';

  @override
  String get create => 'Создать';

  @override
  String get createPlaylist => 'Создать плейлист';

  @override
  String get creatorAndMaintainer => 'Создатель и сопровождающий';

  @override
  String get customAccentColor => 'Пользовательский акцентный цвет';

  @override
  String get customizeColorsTheme =>
      'Настройте цвета приложения, тему и фон текстов песен.';

  @override
  String get dateAdded => 'Дата добавления';

  @override
  String get deepStorageScanProgress =>
      'ВЫПОЛНЯЕТСЯ ГЛУБОКОЕ СКАНИРОВАНИЕ ХРАНЕНИЯ...';

  @override
  String get delete => 'Удалить';

  @override
  String get deleteFile => 'Удалить файл';

  @override
  String get deletePlaylist => 'Удалить плейлист';

  @override
  String deletePlaylistConfirm(String name) {
    return 'Вы уверены, что хотите удалить \"$name\"?';
  }

  @override
  String get deleteSong => 'Удалить песню';

  @override
  String get deleteSongConfirm =>
      'Вы уверены, что хотите удалить эту песню с диска?';

  @override
  String get descending => 'По убыванию';

  @override
  String get designerAndMaintainer => 'Дизайнер и сопровождающий';

  @override
  String get disableBlurEffects => 'Отключить эффекты размытия';

  @override
  String get disableSquigglyProgressBar =>
      'Отключить анимацию индикатора выполнения волнистой волны';

  @override
  String get downloadAudioDirectly => 'СКАЧАТЬ АУДИО ПРЯМО';

  @override
  String get downloadingLyricsOffline =>
      'Загрузка текстов для автономного использования...';

  @override
  String get downloadMissingArtwork => 'Скачать недостающую иллюстрацию';

  @override
  String get downloadMissingArtworkDesc =>
      'Автоматически загружать обложки песен в высоком разрешении из iTunes.';

  @override
  String get duration => 'Длительность';

  @override
  String get dynamicAccentColor => 'Динамический акцентный цвет';

  @override
  String get dynamicAccentColorDesc =>
      'Обновлять только акцентный цвет на основе обложки альбома';

  @override
  String get dynamicBgOnlyLyrics => 'Динамический фон только для текстов песен';

  @override
  String get dynamicColorActiveLyrics => 'Динамическая цветная активная линия';

  @override
  String get dynamicColorActiveLyricsDesc =>
      'Использовать извлеченные цвета изображения для воспроизводимой в данный момент строки текста.';

  @override
  String get dynamicLyricsBg => 'Динамические тексты песен BG';

  @override
  String get dynamicLyricsBgDesc =>
      'Применять размытие обложки к экрану с текстом песен';

  @override
  String get dynamicTheming => 'Динамическое оформление тем';

  @override
  String get emptyLibraryDesc =>
      'Нам не удалось найти поддерживаемые музыкальные файлы в вашей медиатеке. Добавьте папки или запустите поисковое сканирование.';

  @override
  String get enableNetworkLyricsArt =>
      'Включить использование сети для онлайн-текстов песен и иллюстраций исполнителей.';

  @override
  String get enablePlayerGradient => 'Градиент музыкального экрана';

  @override
  String get enablePlayerGradientDesc =>
      'Включите фон с радиальным акцентом на экране воспроизведения.';

  @override
  String get fadeDuration => 'Длительность затухания';

  @override
  String get fadeDurationDesc => 'Продолжительность эффекта затухания';

  @override
  String get fadeOnSeek => 'Затухание при перемотке';

  @override
  String get fadeOnSeekDesc =>
      'Плавно приглушать и восстанавливать громкость при поиске по треку';

  @override
  String get fadePlayPauseStop =>
      'Плавное затухание воспроизведения/паузы/стопа';

  @override
  String get fadePlayPauseStopDesc =>
      'Плавно изменять громкость при начале, приостановке или остановке воспроизведения';

  @override
  String get favorites => 'Избранное';

  @override
  String get fileInformation => 'Информация о файле';

  @override
  String get flatProgressBar => 'Плоский индикатор выполнения';

  @override
  String get folders => 'Папки';

  @override
  String get genre => 'Жанр';

  @override
  String get genres => 'Жанры';

  @override
  String get genresRowDesc => 'Горизонтальная полка музыкальных жанров';

  @override
  String get goStart => 'НАЧАТЬ';

  @override
  String get grant => 'ГРАНТ';

  @override
  String get granted => 'ПРЕДОСТАВЛЕНО';

  @override
  String get history => 'История';

  @override
  String get home => 'Главная';

  @override
  String get homeDarkness => 'Темнота главного экрана';

  @override
  String get homeDarknessDesc =>
      'Настройка яркости наложения фона на главном экране';

  @override
  String get homeDashboardSettings => 'Настройки домашней панели';

  @override
  String get homeDashboardSettingsDesc =>
      'Настройте горизонтальные строки на главном экране';

  @override
  String get internetMode => 'Интернет-режим';

  @override
  String get keepBackgroundGradient => 'Сохранять градиент фона';

  @override
  String get keepBackgroundGradientDesc =>
      'Сохраняйте градиент фона на всех экранах приложений.';

  @override
  String get language => 'Язык';

  @override
  String get left => 'Слева';

  @override
  String get library => 'Библиотека';

  @override
  String get libraryDarkness => 'Темнота экрана библиотеки';

  @override
  String get libraryDarknessDesc =>
      'Отрегулируйте яркость наложения фона для экрана библиотеки.';

  @override
  String get libraryFoldersSync =>
      'Папки, триггеры повторного сканирования, сброс базы данных и автономная синхронизация';

  @override
  String get librarySettings => 'Настройки библиотеки';

  @override
  String get loadingMusicLibrary => 'ЗАГРУЗКА МУЗЫКАЛЬНОЙ БИБЛИОТЕКИ';

  @override
  String get loadingMusicLibraryDesc =>
      'Создание премиум-индексов, настройка аппаратных прослушивателей и оптимизация визуальных кешей.';

  @override
  String get loadingPhase1 => 'ОПРОС АУДИОХРАНЕНИЯ...';

  @override
  String get loadingPhase2 => 'ОБНОВЛЯЕМ МУЗЫКАЛЬНЫЙ ДВИГАТЕЛЬ...';

  @override
  String get loadingPhase3 => 'ИЗВЛЕЧЕНИЕ АКУСТИЧЕСКИХ ДАННЫХ...';

  @override
  String get loadingPhase4 => 'ОПТИМИЗАЦИЯ ВОСПРОИЗВЕДЕНИЯ ПАМЯТИ...';

  @override
  String get lyrics => 'Тексты песен';

  @override
  String get lyricsAlignment => 'Выравнивание текстов';

  @override
  String get lyricsAlignmentDesc =>
      'Выровняйте позиции текста для прокрутки текстов песен';

  @override
  String get lyricsDarkness => 'Тексты песен Screen Darkness';

  @override
  String get lyricsDarknessDesc =>
      'Отрегулируйте яркость наложения фона на экране «Тексты»';

  @override
  String get lyricsProvider => 'Поставщик текстов';

  @override
  String get lyricsProviderDesc =>
      'Онлайн-тексты песен загружаются с lrclib.net (LRCLIB)';

  @override
  String get maintainersAndDesigners => 'Разработчики и дизайнеры';

  @override
  String get manageAudioFocus => 'Управление аудиофокусом';

  @override
  String get manageAudioFocusDesc =>
      'Запрашивать и реагировать на системные изменения аудиофокуса';

  @override
  String get manageAudioFocusTitle => 'Управление аудиофокусом';

  @override
  String get manageLanguageAndFocus =>
      'Управляйте языковыми настройками и состоянием фокуса звонящего';

  @override
  String get audioFocusGetFocus => 'Получить фокус';

  @override
  String get audioFocusGetFocusDesc =>
      'Запрашивать аудиофокус в начале воспроизведения.';

  @override
  String get audioFocusReleaseFocus => 'Освободить фокус';

  @override
  String get audioFocusReleaseFocusDesc =>
      'Освобождать аудиофокус при паузе или остановке воспроизведения.';

  @override
  String get audioFocusStopOnOtherSession =>
      'Останавливать музыку при другом музыкальном сеансе';

  @override
  String get audioFocusStopOnOtherSessionDesc =>
      'Приостанавливать воспроизведение, когда другое приложение начинает воспроизводить звук.';

  @override
  String get audioFocusRestartOnGain =>
      'Возобновлять музыку при получении фокуса';

  @override
  String get audioFocusRestartOnGainDesc =>
      'Автоматически возобновлять воспроизведение при возврате аудиофокуса, только если воспроизведение было прервано из-за потери фокуса.';

  @override
  String get pauseOnDuckTitle => 'Пауза при приглушении';

  @override
  String get pauseOnDuckDesc =>
      'Ставить воспроизведение на паузу вместо снижения громкости, когда другое приложение воспроизводит кратковременный звук (например, уведомления, голосовую навигацию).';

  @override
  String get resumeOnBluetoothConnectTitle =>
      'Возобновлять при подключении Bluetooth';

  @override
  String get resumeOnBluetoothConnectDesc =>
      'Автоматически возобновлять воспроизведение при повторном подключении Bluetooth-устройства (наушников, автомобильной гарнитуры).';

  @override
  String get manualCrossfadeDuration => 'Длительность ручного кроссфейда';

  @override
  String get manualCrossfadeDurationDesc =>
      'Время наложения при ручном переключении';

  @override
  String get matchingLyrics => 'СООТВЕТСТВУЮЩИЕ ТЕКСТЫ';

  @override
  String get metadataDetails => 'Подробности метаданных';

  @override
  String get mostPlayed => 'Популярные';

  @override
  String get musicAudioAccess => 'ДОСТУП К МУЗЫКЕ И АУДИО';

  @override
  String get musicDarkness => 'Музыкальный проигрыватель Тьма';

  @override
  String get musicDarknessDesc =>
      'Настройка яркости наложения фона на экране музыкального проигрывателя';

  @override
  String get musicLibrary => 'Музыкальная библиотека';

  @override
  String get muteOrPauseCalls =>
      'Отключение звука или пауза во время звонков и других звуковых действий';

  @override
  String get newPlaylist => 'Новый плейлист';

  @override
  String get newTitle => 'Новое название';

  @override
  String get nextUp => 'Далее';

  @override
  String get noAlbumsFound => 'Альбомы не найдены';

  @override
  String get noArtistsFound => 'Художники не найдены';

  @override
  String get noFavoritesYet => 'Нет избранного';

  @override
  String get noHistoryYet => 'История пуста';

  @override
  String get noLyrics => 'Тексты песен не найдены';

  @override
  String get noMusicDetected => 'МУЗЫКА НЕ ОБНАРУЖЕНА';

  @override
  String get noPlaylistsCreated => 'Плейлисты еще не созданы.';

  @override
  String get noPlaylistsYet => 'Нет плейлистов';

  @override
  String get noResultsFound => 'Результаты не найдены';

  @override
  String get noSongsFound => 'Песни не найдены';

  @override
  String get notificationAccess => 'ДОСТУП К УВЕДОМЛЕНИЯМ';

  @override
  String get nowPlaying => 'Сейчас играет';

  @override
  String get performanceOptimizerDashboard =>
      'Панель оптимизации производительности';

  @override
  String get performanceOptimizerDashboardDesc =>
      'Показывать оверлей со статистикой оптимизатора в реальном времени';

  @override
  String get permanentFocusChangePause => 'Пауза при постоянной потере фокуса';

  @override
  String get permanentFocusChangePauseDesc =>
      'Автоматически ставить на паузу при постоянной потере аудиофокуса';

  @override
  String get plainTimestamps => 'Простые временные метки';

  @override
  String get play => 'Играть';

  @override
  String get playAll => 'Воспроизвести все';

  @override
  String get playbackAudio => 'Воспроизведение и язык';

  @override
  String get playlists => 'Плейлисты';

  @override
  String get playNext => 'Воспроизвести следующим';

  @override
  String get playQueue => 'Играть в очередь';

  @override
  String get pressBackExit => 'Нажмите назад еще раз, чтобы выйти';

  @override
  String get privacySafety => 'Конфиденциальность и безопасность';

  @override
  String get privacySafetyDesc =>
      '100% конфиденциальность и приоритетность в автономном режиме. Ваши треки, история воспроизведения, избранное и конфигурация остаются строго в защищенной базе данных Isar на вашем локальном устройстве. Мы не отслеживаем, не собираем и не передаем ваши данные об использовании или предпочтениях.';

  @override
  String get pureBlackOled => 'Чистый черный (OLED)';

  @override
  String get pureBlackOledDesc => 'Использовать абсолютно черный цвет для фона';

  @override
  String get queue => 'Очередь';

  @override
  String get queueIsEmpty => 'Очередь пуста';

  @override
  String get quickPicks => 'Быстрый выбор';

  @override
  String get quickPicksRowDesc => 'Ваша самая популярная сетка песен';

  @override
  String get readyToScan => 'Готов к сканированию';

  @override
  String get recentlyAddedSongsRowDesc => 'Список вашего последнего импорта';

  @override
  String get recentlyPlayed => 'Недавние';

  @override
  String get recentPlayed => 'Последние сыгранные';

  @override
  String get recentRowDesc =>
      'Горизонтальная полка недавно воспроизведённых треков';

  @override
  String get removedFromPlaylist => 'Удалено из плейлиста';

  @override
  String get removeFromFavorites => 'Удалить из избранного';

  @override
  String get removeFromPlaylist => 'Удалить из плейлиста';

  @override
  String get rename => 'Переименовать';

  @override
  String get renameFile => 'Переименовать файл';

  @override
  String get renamePlaylist => 'Переименовать плейлист';

  @override
  String get renameSong => 'Переименовать песню';

  @override
  String get reorderDashboardSections =>
      'Изменение порядка разделов информационной панели';

  @override
  String get reorderDashboardSectionsDesc =>
      'Перетащите, чтобы установить предпочтительный порядок панели мониторинга.';

  @override
  String get includeOtherDeviceAudioTitle => 'Включить другое аудио устройства';

  @override
  String get includeOtherDeviceAudioDesc =>
      'Сканировать рингтоны, уведомления, будильники и аудио WhatsApp и Telegram';

  @override
  String get rescanLibrary => 'Повторное сканирование библиотеки';

  @override
  String get rescanStorage => 'ПЕРЕСКАНИРОВАНИЕ ХРАНЕНИЯ';

  @override
  String get reset => 'Сбросить';

  @override
  String get resetLibrary => 'Сброс и повторное сканирование';

  @override
  String get resetLibraryConfirm =>
      'Это очистит все песни, альбомы и исполнителей и выполнит полное повторное сканирование ваших папок.';

  @override
  String get resetLibraryConfirmNew =>
      'Это удалит все песни из вашей библиотеки в приложении. Физические файлы на диске удалены не будут.';

  @override
  String get resetLibraryDesc =>
      'Удалить все песни из вашей индексированной библиотеки';

  @override
  String get resumeAfterCallDesc =>
      'Автоматически возобновлять проигрывание после завершения звонка';

  @override
  String get resumeAfterCallTitle => 'Возобновлять после звонка';

  @override
  String get resumeOnStartDesc =>
      'Автоматически возобновлять проигрывание при старте Looper Player';

  @override
  String get resumeOnStartTitle => 'Возобновлять при запуске';

  @override
  String get persistQueueTitle => 'Сохранять последнюю очередь';

  @override
  String get persistQueueDesc =>
      'Сохранять последнюю песню и очередь при перезапуске приложения';

  @override
  String get keepSongProgressTitle => 'Сохранять прогресс песни';

  @override
  String get keepSongProgressDesc =>
      'Запоминает позицию воспроизведения каждой песни отдельно. Переключитесь на другую песню на середине и вернитесь позже — даже после прослушивания других песен между этим — и воспроизведение продолжится с того места, где вы остановились, а не с начала.';

  @override
  String get right => 'Справа';

  @override
  String scanCompleteSongsDetected(int count) {
    return 'СКАНИРОВАНИЕ ЗАВЕРШЕНО: ОБНАРУЖЕНО $count ПЕСЕН!';
  }

  @override
  String get scanForMusic => 'СКАНИРОВАНИЕ МУЗЫКИ';

  @override
  String get scanIndexLocalDesc =>
      'Сканирование и индексирование локальных музыкальных файлов';

  @override
  String get scanLibrary => 'Сканировать библиотеку';

  @override
  String get scanningInBackground => 'Сканирование в фоновом режиме...';

  @override
  String get scanningLibrary => 'Сканирование библиотеки...';

  @override
  String get scanningStorage => 'СКАНИРОВАНИЕ ХРАНИЛИЩА...';

  @override
  String get scanningStorageDesc =>
      'Обход деревьев каталогов для обнаружения аудиодорожек. Пожалуйста, подождите...';

  @override
  String get search => 'Поиск';

  @override
  String get searchLibraryHint => 'Поиск по всей вашей библиотеке';

  @override
  String get searchSongsHint => 'Поиск песен';

  @override
  String get seekFadeDuration => 'Длительность затухания при перемотке';

  @override
  String get seekFadeDurationDesc =>
      'Продолжительность эффекта затухания при перемотке';

  @override
  String get selectAppLanguage => 'Выберите язык приложения';

  @override
  String get selectCustomColor => 'Выберите собственный цвет';

  @override
  String get selectCustomFolder => 'ВЫБОР ПОЛЬЗОВАТЕЛЬСКОЙ ПАПКИ';

  @override
  String get selectFolderIndex => 'Выбрать папку для сканирования аудиофайлов';

  @override
  String get selectSpecificFolder => 'ВЫБЕРИТЕ КОНКРЕТНУЮ ПАПКУ';

  @override
  String get settings => 'Настройки';

  @override
  String get share => 'Поделиться';

  @override
  String get shareFile => 'Поделиться файлом';

  @override
  String get showAlbumsRow => 'Показать строку альбомов';

  @override
  String get showAlbumsRowDesc =>
      'Отображение горизонтального списка альбомов на главном экране.';

  @override
  String get showArtistsRow => 'Шоу «Ряд художников»';

  @override
  String get showArtistsRowDesc =>
      'Отображение горизонтального списка исполнителей на главном экране.';

  @override
  String get showGenresRow => 'Показать строку жанров';

  @override
  String get showGenresRowDesc =>
      'Отображение горизонтального списка жанров на главном экране.';

  @override
  String get showLess => 'Показать меньше';

  @override
  String get showMore => 'Показать больше';

  @override
  String get showQualityBadge => 'Показать значок качества';

  @override
  String get showQualityBadgeDesc =>
      'Отображение значка с информацией о качестве звука на экране воспроизведения';

  @override
  String get showRecentRow => 'Показать строку недавно воспроизведённых';

  @override
  String get showRecentRowDesc =>
      'Отображение горизонтального списка недавно воспроизведённых треков на главном экране.';

  @override
  String get silenceBetweenTracksDesc =>
      'Добавить паузу тишины между треками (0 мс для беспрерывного воспроизведения)';

  @override
  String get silenceBetweenTracksTitle => 'Тишина между треками';

  @override
  String get songDeletedDbOnly =>
      'Песня удалена из библиотеки (физический файл доступен только для чтения)';

  @override
  String get songDeletedSuccess => 'Песня успешно удалена';

  @override
  String get songDeleteFailed => 'Не удалось удалить песню';

  @override
  String get songDetails => 'Подробности песни';

  @override
  String get songDetailsAndFrequency => 'Подробности и частота песен';

  @override
  String get songRenamedDbOnly =>
      'Песня переименована в библиотеке (физический файл доступен только для чтения)';

  @override
  String get songRenamedSuccess => 'Песня успешно переименована';

  @override
  String get songRenameFailed => 'Не удалось переименовать песню';

  @override
  String get songs => 'Песни';

  @override
  String get songsDarkness => 'Песни Экран Тьма';

  @override
  String get songsDarknessDesc =>
      'Настройка яркости наложения фона на экране «Песни»';

  @override
  String get sortBy => 'Сортировать по';

  @override
  String get sortOrder => 'Порядок сортировки';

  @override
  String get sourceCode => 'Исходный код';

  @override
  String get stopServiceOnAppDismissal =>
      'Остановка службы при закрытии приложения';

  @override
  String get stopServiceOnAppDismissalDesc =>
      'Останавливать фоновую службу и закрывать приложение при его смахивании';

  @override
  String get storagePermissionRequired =>
      'Для сканирования памяти устройства необходимы разрешения на хранение.';

  @override
  String get syncLyricsOffline => 'Синхронизировать тексты песен (офлайн)';

  @override
  String get systemDefault => 'Системный по умолчанию';

  @override
  String get systemPermissionChecklist =>
      'КОНТРОЛЬНЫЙ СПИСОК РАЗРЕШЕНИЙ СИСТЕМЫ';

  @override
  String get technicalInfoFrequency => 'Техническая информация и частота';

  @override
  String get theme => 'Тема';

  @override
  String get title => 'Название';

  @override
  String get todayMixForYou => 'Сегодня Микс для тебя';

  @override
  String get toggleFavorite => 'Переключить избранное';

  @override
  String get shuffleTitle => 'Перемешивание';

  @override
  String get shuffleDisabledDesc =>
      'Воспроизводить песни в исходном порядке очереди. При отключении перемешивания текущая песня продолжает играть, а оставшаяся очередь восстанавливается в исходном порядке без влияния на воспроизведение или его историю.';

  @override
  String get shuffleEnabledDesc =>
      'Перемешивать оставшиеся песни, не затрагивая текущую. Сформированный порядок перемешивания остаётся неизменным, пока очередь не изменится или не будет запрошено новое перемешивание, что предотвращает повторение или пропуск треков.';

  @override
  String get shuffleSwitchingDesc =>
      'Включение или выключение перемешивания никогда не перезапускает текущую песню. Меняется только порядок предстоящих треков — случайный при включении и восстановленный к исходному порядку очереди при выключении.';

  @override
  String get topResult => 'Лучший результат';

  @override
  String get transferMusicFiles => 'ПЕРЕДАЧА МУЗЫКАЛЬНЫХ ФАЙЛОВ';

  @override
  String get turnOffBlursOptimize =>
      'Отключите сильное размытие, чтобы оптимизировать производительность.';

  @override
  String get unknown => 'Неизвестно';

  @override
  String get unknownAlbum => 'Неизвестный альбом';

  @override
  String get unknownArtist => 'Неизвестный исполнитель';

  @override
  String get updateLibraryIndexing => 'Обновить индексацию файлов библиотеки';

  @override
  String get useAbsoluteBlackBg =>
      'Используйте абсолютный черный цвет для фона.';

  @override
  String get useStaticTextTimestamps =>
      'Используйте статический текст вместо движущейся анимации для продолжительности прогресса.';

  @override
  String get verticalMotionEffectPlayer => 'Вертикальный жест закрытия плеера';

  @override
  String get verticalMotionEffectPlayerDesc =>
      'Смахните развернутый плеер вниз, чтобы свернуть его';

  @override
  String get viewAll => 'Посмотреть все';

  @override
  String get visitOfficialRepository =>
      'Посетить официальный репозиторий на GitHub';

  @override
  String get welcomeAboutDesc =>
      'Looper Player — это музыкальная ОС нового поколения, созданная для автономного воспроизведения аудио премиум-класса. Особенности динамической генерации текстов в реальном времени, расширенное управление аудиосессиями с отключением звука при вызове, адаптивное фоновое оформление и поддержка многоформатной музыкальной библиотеки. Полностью оптимизирован для максимальной эффективности использования аккумулятора.';

  @override
  String get welcomeAllFilesDesc =>
      'Настоятельно рекомендуется для профессионального сканирования для поиска песен в нестандартных каталогах (Загрузки, Telegram, пользовательские папки).';

  @override
  String get welcomeInstructionConnectDesc =>
      'Подключите телефон или устройство к персональному компьютеру с помощью стандартного USB-кабеля для передачи данных.';

  @override
  String get welcomeInstructionDownloadDesc =>
      'Альтернативно загрузите файлы напрямую с помощью веб-браузера или другой утилиты загрузки на самом устройстве.';

  @override
  String get welcomeInstructionTransferDesc =>
      'Скопируйте свои автономные музыкальные файлы (поддерживает форматы .mp3, .flac, .m4a, .wav) непосредственно в стандартную папку «Музыка» или «Загрузка» вашего устройства.';

  @override
  String get welcomeMusicAudioDesc =>
      'Требуется для обнаружения и воспроизведения стандартных автономных аудиодорожек в памяти вашего устройства.';

  @override
  String get welcomeNoSongsDesc =>
      'Нам не удалось найти поддерживаемые аудиофайлы (MP3, FLAC, WAV, M4A, OGG) в памяти вашего устройства.';

  @override
  String get welcomeNotificationDesc =>
      'Требуется для отображения элементов управления воспроизведением и виджетов активных уведомлений на системной панели.';

  @override
  String get welcomeScanningFoldersDesc =>
      'Сканирование всех папок и подпапок на наличие аудиофайлов.';

  @override
  String get whyInternetUsed => 'Почему используется Интернет';

  @override
  String get whyInternetUsedDesc =>
      '• Динамическая синхронизация текстов песен: используется исключительно для безопасного получения и загрузки синхронизированных текстов песен (форматы LRC) из онлайн-баз данных. Никакие личные данные, настройки или мультимедийные файлы никогда не загружаются и не передаются.';

  @override
  String get whyPermissionsUsed => 'Почему используются разрешения';

  @override
  String get whyPermissionsUsedDesc =>
      '• Доступ к хранилищу/медиа: требуется для обнаружения, чтения и индексирования локальных аудиодорожек, хранящихся на вашем устройстве.\n• Уведомления: необходимы для отображения виджетов активного управления воспроизведением в строке состояния и системном ящике.';

  @override
  String get willPlayNext => 'Будет воспроизведено следующим';

  @override
  String get year => 'Год';

  @override
  String get supportUs => 'Поддержать нас';

  @override
  String get supportUsDesc =>
      'Помогите сохранить Looper Player живым и открытым';

  @override
  String get supportDevelopment => 'Поддержать разработку';

  @override
  String get supportDevelopmentDesc =>
      'Looper Player на 100% бесплатен и имеет открытый исходный код. Если вам нравится им пользоваться, пожалуйста, поддержите создателя пожертвованием. Каждая поддержка помогает поддерживать проект активным!';

  @override
  String get useCustomFont => 'Использовать свой шрифт';

  @override
  String get useCustomFontDesc =>
      'Использовать Jost или другие шрифты. Иначе используется DM Sans.';

  @override
  String get selectFontFamily => 'Выбрать семейство шрифтов';

  @override
  String activeFont(String fontName) {
    return 'Активный шрифт: $fontName';
  }

  @override
  String get fontWeightAdjustment => 'Регулировка толщины шрифта';

  @override
  String get currentWeight => 'Текущая толщина';

  @override
  String get useCustomFontLyrics => 'Свой шрифт для текста песен';

  @override
  String get useCustomFontLyricsDesc =>
      'Использовать свой шрифт и толщину для синхронизированных слов';

  @override
  String get lyricsFontFamily => 'Семейство шрифтов текста';

  @override
  String activeLyricsFont(String fontName) {
    return 'Активный шрифт текста: $fontName';
  }

  @override
  String get lyricsFontWeightAdjustment => 'Регулировка толщины текста';

  @override
  String get giveStarOnGithub => 'Поставить звезду на GitHub';

  @override
  String get supportProjectLove => 'Поддержите проект и проявите симпатию!';

  @override
  String get sortAlphabeticalAZ => 'По алфавиту (А-Я)';

  @override
  String get sortAlphabeticalZA => 'По алфавиту (Я-А)';

  @override
  String get sortRecentlyAdded => 'Недавно добавленные';

  @override
  String get sortOldestAdded => 'Сначала старые';

  @override
  String get sortYearNewest => 'Год (Новые)';

  @override
  String get sortYearOldest => 'Год (Старые)';

  @override
  String get sortMostSongs => 'Больше всего песен';

  @override
  String get sortLeastSongs => 'Меньше всего песен';

  @override
  String get sortDefault => 'По умолчанию';

  @override
  String get sortArtistAsc => 'Исполнитель (А-Я)';

  @override
  String get sortAlbumAsc => 'Альбом (А-Я)';

  @override
  String get sortDuration => 'Длительность';

  @override
  String get myAlbums => 'Мои альбомы';

  @override
  String get featuredArtists => 'Рекомендуемые исполнители';

  @override
  String get noSongPlaying => 'Ничего не воспроизводится';

  @override
  String get nextLabel => 'Далее';

  @override
  String get previousLabel => 'Назад';

  @override
  String get resync => 'Пересинхронизировать';

  @override
  String get equalizer => 'Эквалайзер';

  @override
  String get presets => 'ПРЕСЕТЫ';

  @override
  String get preAmpGain => 'Усиление предусилителя';

  @override
  String get outputVolume => 'Выходная громкость';

  @override
  String get customFilterHint =>
      'Введите произвольные параметры аудиофильтра libavfilter напрямую (например, volume=3dB, aecho=0.8:0.88:60:0.4):';

  @override
  String get flowGlobalActions => 'Порядок работы и глобальные действия';

  @override
  String get equalizerModeLabel => 'Режим эквалайзера:';

  @override
  String get currentGainsAppliedGlobal =>
      'Текущие значения применены как глобальные настройки по умолчанию.';

  @override
  String get applyToGlobal => 'Применить глобально';

  @override
  String get songSpecificResetGlobal =>
      'Настройки для этой песни сброшены до глобальных значений по умолчанию.';

  @override
  String get resetToGlobal => 'Сбросить до глобальных';

  @override
  String get resetAllSongsEq => 'Сбросить EQ для всех песен';

  @override
  String get resetAllSongsEqConfirm =>
      'Вы уверены, что хотите удалить пользовательские настройки эквалайзера для всех песен в вашей библиотеке?';

  @override
  String get allSongsEqDataReset =>
      'Все данные эквалайзера для отдельных песен сброшены.';

  @override
  String get resetAllSongsEqData => 'Сбросить данные EQ для всех песен';

  @override
  String get equalizerTargetMode => 'Режим применения эквалайзера';

  @override
  String get equalizerTargetModeDesc =>
      'Выберите, как настройки эквалайзера применяются ко всей вашей музыкальной библиотеке.';

  @override
  String get globalMode => 'Глобальный режим';

  @override
  String get globalModeDesc =>
      'Применяет эффекты одинаково ко всем песням. Настройки эквалайзера остаются прежними при смене песни.';

  @override
  String get songSpecificMode => 'Режим для отдельной песни';

  @override
  String get songSpecificModeDesc =>
      'Сохраняет пользовательские настройки только для текущей песни. Следующая песня по умолчанию использует ровный/отключённый эквалайзер, если у неё нет собственного профиля.';

  @override
  String get viewDeviceAudioCapabilities =>
      'Просмотреть аудиовозможности устройства';

  @override
  String get deviceAudioCapabilities => 'Аудиовозможности устройства';

  @override
  String get noPlaybackActiveCapabilities =>
      'Воспроизведение не активно, либо информация о возможностях недоступна.';

  @override
  String get changeLyricsProvider => 'Изменить источник текстов песен';

  @override
  String get autoFallbackProviders => 'Автоматические резервные источники';

  @override
  String get autoFallbackProvidersDesc =>
      'Автоматически пробовать другие источники, если у основного нет текста песни';

  @override
  String get ambientColorBackground => 'Фон с окружающим цветом';

  @override
  String get ambientColorBackgroundDesc =>
      'Плавные, ненавязчивые градиенты, созданные на основе обложки песни';

  @override
  String get exportLyricsLrc => 'Экспортировать текст песни (файл .lrc)';

  @override
  String get saveLyricsToDevice =>
      'Сохранить текущий текст песни в память устройства';

  @override
  String get noLyricsToExport => 'Нет текста песни для экспорта';

  @override
  String get useCustomLyricsLrc =>
      'Использовать собственный текст песни (файл LRC)';

  @override
  String get selectLocalLrcFile =>
      'Выберите локальный файл .lrc или .txt для этой песни';

  @override
  String get customLyricsAppliedSuccess =>
      'Пользовательский текст песни успешно применён!';

  @override
  String get noRecentlyPlayedTracks => 'Нет недавно воспроизведённых треков';

  @override
  String get close => 'Закрыть';

  @override
  String get audioQualityAnalysis => 'Анализ качества звука';

  @override
  String get audioQualityAnalysisDesc =>
      'Выполнить углублённый спектральный анализ и анализ аудиоформата';

  @override
  String get audioStreamDetails => 'Сведения об аудиопотоке';

  @override
  String get perChannelMetrics => 'Показатели по каналам';

  @override
  String get sleepTimer => 'Таймер сна';

  @override
  String get stopByTime => 'ОСТАНОВКА ПО ВРЕМЕНИ';

  @override
  String get start => 'Запустить';

  @override
  String get stopBySongCount => 'ОСТАНОВКА ПО КОЛИЧЕСТВУ ПЕСЕН';

  @override
  String get cancelSleepTimer => 'Отменить таймер сна';

  @override
  String get nowPlayingAllCaps => 'СЕЙЧАС ИГРАЕТ';

  @override
  String get settingsAndBackups => 'Настройки и резервные копии';

  @override
  String get managePreferencesLibraryData =>
      'Управление настройками и данными библиотеки';

  @override
  String get logsClearedSuccess => 'Журналы успешно очищены';

  @override
  String get editSongInfo => 'Изменить информацию о песне';

  @override
  String get editAlbumInfo => 'Изменить информацию об альбоме';

  @override
  String get tapFieldToEdit => 'Нажмите на поле, чтобы изменить его';

  @override
  String get alwaysBlurSheets => 'Всегда размывать листы';

  @override
  String get alwaysBlurSheetsDesc =>
      'Размывать всплывающие листы, даже если динамическое оформление выключено';

  @override
  String get removeArtwork => 'Удалить обложку';

  @override
  String get resetArtworkToDefault => 'Сбросить к стандартным';

  @override
  String get artworkResetToDefault => 'Обложка сброшена к стандартной';

  @override
  String get noEmbeddedArtworkFound =>
      'Встроенная обложка для этого альбома не найдена';

  @override
  String get saveChangesBtn => 'Сохранить изменения';

  @override
  String get enterFolderPathManually => 'Ввести путь к папке вручную';

  @override
  String get folderPickerManualHint =>
      'Если системный выбор каталога не открывается, введите или вставьте полный путь к каталогу ниже:';

  @override
  String get noSupportedSongsFoundFolder =>
      'В выбранной папке не найдено поддерживаемых песен';

  @override
  String get add => 'Добавить';

  @override
  String get folderPickerClosed => 'Выбор папки закрыт';

  @override
  String get buyMeCoffee => 'Угостить меня кофе';

  @override
  String get typeToSearchSettings => 'Введите текст для поиска в настройках…';

  @override
  String get maintainersLabel => 'Мейнтейнеры';

  @override
  String get personBehindLooperPlayer => 'Человек, стоящий за LooperPlayer';

  @override
  String get blurredArtworkForLyrics => 'Размытая обложка для текста песни';

  @override
  String get blurredArtworkForLyricsDesc =>
      'Показывать размытую обложку альбома как фон вместо динамического/статического градиента';

  @override
  String get lyricsFontWeight => 'Насыщенность шрифта текста песни';

  @override
  String get openSourceLicenses => 'Лицензии открытого исходного кода';

  @override
  String get openSourceLicensesDesc =>
      'Сторонние библиотеки, используемые в этом приложении';

  @override
  String get done => 'Готово';

  @override
  String get lyricsNotAvailable => 'Текст песни недоступен.';

  @override
  String get lyricsNotAvailableHint =>
      'Импортируйте файл .lrc или .txt, чтобы добавить текст к этой песне';

  @override
  String get importLyricsFile => 'Импортировать файл текста песни';

  @override
  String get approximatedSyncNoWordTimings =>
      'Приблизительная синхронизация (без покадровой синхронизации слов)';

  @override
  String get lyricsSyncHelp => 'Справка по синхронизации текста песни';

  @override
  String get simpleModeLabel => 'Простой режим';

  @override
  String get advancedModeLabel => 'Расширенный режим';

  @override
  String get tips => 'Советы';

  @override
  String get gotIt => 'Понятно';

  @override
  String get lyricsSyncStudio => 'Студия синхронизации текста песни';

  @override
  String get lyricsTextLabel => 'Текст песни';

  @override
  String get lyricsTextHelperDesc =>
      'По одной строке на строку текста песни. Инструменты синхронизации ниже привязывают к этим строкам временные метки.';

  @override
  String get quickSync => 'Быстрая синхронизация';

  @override
  String get autoAdvanceAfterStamping =>
      'Автоматически переходить дальше после проставления метки';

  @override
  String get advancedSync => 'Расширенная синхронизация';

  @override
  String get useCurrentTime => 'Использовать текущее время';

  @override
  String get playbackAssist => 'Помощник воспроизведения';

  @override
  String get timeShift => 'Сдвиг по времени';

  @override
  String get timeShiftDesc =>
      'Сдвигает все проставленные метки текста песни вместе вперёд или назад.';

  @override
  String get lyricsSaveLrcExplain =>
      'При сохранении, если возможно, создаётся сопутствующий файл «.lrc» рядом с аудиофайлом песни, а также сохраняется в локальной базе данных плеера. Строки без временных меток будут интерполированы автоматически.';

  @override
  String get back => 'Назад';

  @override
  String get appSettingsLabel => 'Настройки приложения';

  @override
  String get backupsAndLogs => 'Резервные копии и журналы';

  @override
  String get backupsAndLogsDesc =>
      'Экспорт, импорт и управление данными приложения';

  @override
  String get exportBackupJson => 'Экспортировать резервную копию (JSON)';

  @override
  String get exportBackupJsonDesc =>
      'Сохраняет ваши любимые песни и плейлисты в файл JSON, который можно сохранить или отправить. Больше ничего не включается.';

  @override
  String get importBackupJson => 'Импортировать резервную копию (JSON)';

  @override
  String get importBackupJsonDesc =>
      'Объединяет любимые песни и плейлисты из файла резервной копии с вашей библиотекой. Существующие данные никогда не перезаписываются и не удаляются.';

  @override
  String get exportDiagnosticsLogs => 'Экспортировать диагностические журналы';

  @override
  String get exportDiagnosticsLogsDesc =>
      'Отправляет файл диагностического журнала приложения для проверки при устранении неполадок.';

  @override
  String get clearDiagnosticsLogs => 'Очистить диагностические журналы';

  @override
  String get clearDiagnosticsLogsDesc =>
      'Полностью удаляет файл диагностического журнала, хранящийся на этом устройстве. Это действие необратимо.';

  @override
  String get lyricsPlainTextOrLrc => 'Текст песни (обычный текст или LRC)';

  @override
  String get syncModeLine => 'СТРОКА';

  @override
  String get syncModeWord => 'СЛОВО';

  @override
  String get syncModeChar => 'СИМВОЛ';

  @override
  String get enterManually => 'Ввести вручную';

  @override
  String get rawFilterParametersHint => 'Необработанные параметры фильтра...';

  @override
  String get searchSettingsHint => 'Поиск по настройкам...';

  @override
  String get repeatTooltip => 'Повтор';

  @override
  String get favoriteTooltip => 'Избранное';

  @override
  String get instructionsTooltip => 'Инструкция';

  @override
  String get pasteLyricsHint => 'Вставьте или введите текст песни здесь';

  @override
  String get timestampMmSsHint => 'Временная метка (mm:ss.xx)';

  @override
  String get nowLabel => 'Сейчас';

  @override
  String get playlistNameHint => 'Название плейлиста';

  @override
  String get songInfoUpdated => 'Информация о песне обновлена!';

  @override
  String get albumInfoUpdated => 'Информация об альбоме обновлена!';

  @override
  String get failedToSaveChanges => 'Не удалось сохранить изменения.';

  @override
  String sleepTimerStoppingIn(String time) {
    return 'Активно: остановка через $time';
  }

  @override
  String sleepTimerStoppingAfter(String time) {
    return 'Активно: остановка после $time';
  }

  @override
  String get selectWhenToPause =>
      'Выберите, когда приостановить воспроизведение музыки';

  @override
  String get selectAvatars => 'Выбрать аватар';

  @override
  String get selectAvatarsDesc =>
      'Выберите аватар, отображаемый на главном экране';

  @override
  String get dynamicAvatarColor => 'Динамический цвет аватара';

  @override
  String get dynamicAvatarColorDesc =>
      'Согласовывает акцентный цвет аватара с текущей темой';

  @override
  String enrichingSongs(int count) {
    return 'Обогащение $count песен…';
  }
}
