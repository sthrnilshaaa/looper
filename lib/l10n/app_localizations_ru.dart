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
  String get animatePlayerGradient => 'Анимированный градиент';

  @override
  String get animatePlayerGradientDesc =>
      'Плавно перемещает основной и третичный цвета с мягким зерном в такт музыке';

  @override
  String get animateBackgroundGradient => 'Анимированный фон';

  @override
  String get animateBackgroundGradientDesc =>
      'Использует анимированный градиент на фоне Главной, Песен и Библиотеки';

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
  String get fluidPlayer => 'Плавный плеер';

  @override
  String get fluidPlayerDesc =>
      'Потяните мини-плеер вверх, чтобы превратить его в полноэкранный плеер';

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

  @override
  String get noListeningHistoryYet => 'История прослушивания пока пуста';

  @override
  String get noListeningHistoryYetDesc =>
      'Послушайте несколько песен, и здесь появится ваш личный отчёт — любимые песни, исполнители, альбомы и жанры.';

  @override
  String get looperAnalyze => 'Looper Analyze';

  @override
  String get totalPlays => 'Всего прослушиваний';

  @override
  String get listeningTime => 'Время прослушивания';

  @override
  String get currentStreakDays => 'Текущая серия (дни)';

  @override
  String get longestStreakDays => 'Самая длинная серия (дни)';

  @override
  String analyzePlaysAndSongs(int plays, int songs) {
    return 'Прослушиваний: $plays • Песен: $songs';
  }

  @override
  String get dayPartMorningShort => 'Утро';

  @override
  String get dayPartAfternoonShort => 'День';

  @override
  String get dayPartEveningShort => 'Вечер';

  @override
  String get dayPartNightShort => 'Ночь';

  @override
  String get activityPattern => 'Характер активности';

  @override
  String get whenYouListenMost => 'Когда вы слушаете больше всего';

  @override
  String get genreBreakdown => 'Распределение по жанрам';

  @override
  String get otherGenre => 'Другое';

  @override
  String get topAlbums => 'Топ альбомов';

  @override
  String get topArtists => 'Топ исполнителей';

  @override
  String get topSongs => 'Топ песен';

  @override
  String playsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count прослушивания',
      many: '$count прослушиваний',
      few: '$count прослушивания',
      one: '$count прослушивание',
    );
    return '$_temp0';
  }

  @override
  String songsPlayedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Прослушано $count песни',
      many: 'Прослушано $count песен',
      few: 'Прослушано $count песни',
      one: 'Прослушана $count песня',
    );
    return '$_temp0';
  }

  @override
  String get listeningTrend => 'Динамика прослушивания';

  @override
  String get last30Days => 'Последние 30 дней';

  @override
  String errorWithDetails(String error) {
    return 'Ошибка: $error';
  }

  @override
  String get selectAll => 'Выбрать все';

  @override
  String get playlist => 'Плейлист';

  @override
  String songsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count песни',
      many: '$count песен',
      few: '$count песни',
      one: '$count песня',
    );
    return '$_temp0';
  }

  @override
  String get recentSearches => 'Недавние запросы';

  @override
  String get lyricsSourceLocalFile => 'Локальный файл';

  @override
  String get lyricsSourceEmbedded => 'Встроенные метаданные';

  @override
  String lyricsProvidedBy(String source) {
    return 'Текст предоставлен: $source';
  }

  @override
  String failedToImportLyrics(String error) {
    return 'Не удалось импортировать текст: $error';
  }

  @override
  String get lyricsEditorLines => 'Строки';

  @override
  String get lyricsEditorStamped => 'С метками';

  @override
  String lyricsEditorLineNumber(int number) {
    return 'Строка $number';
  }

  @override
  String get lyricsEditorEmptyLine => '(Пустая строка)';

  @override
  String get lyricsEditorNotStamped => 'Метка ещё не поставлена';

  @override
  String get pause => 'Пауза';

  @override
  String get lyricsEditorAddLineFirst =>
      'Сначала добавьте хотя бы одну строку текста.';

  @override
  String get lyricsEditorSavedWithSidecar =>
      'Текст сохранён в базе данных и рядом с файлом песни.';

  @override
  String get lyricsEditorSavedDbOnly => 'Текст сохранён в базе данных плеера.';

  @override
  String get lyricsEditorSaveFailed => 'Не удалось сохранить текст.';

  @override
  String get saving => 'Сохранение...';

  @override
  String get saveLrc => 'Сохранить LRC';

  @override
  String lyricsEditorSelectedLine(int index, int total) {
    return 'Выбрана строка $index из $total';
  }

  @override
  String get lyricsEditorPickLine => 'Выберите строку текста в списке ниже.';

  @override
  String get stampAndNext => 'Отметить и далее';

  @override
  String get stampNow => 'Отметить сейчас';

  @override
  String get lyricsEditorSimpleSteps =>
      '1. Вставьте или введите по одной строке текста в каждую строку.\n2. Включите песню.\n3. Выберите текущую строку.\n4. Нажмите «Отметить и далее», когда услышите эту строку.\n5. Сохраните, когда закончите.';

  @override
  String get lyricsEditorAdvancedSteps =>
      '1. Редактируйте метки времени каждой строки напрямую.\n2. Нажмите «Использовать текущее время», чтобы взять текущую позицию воспроизведения.\n3. Сдвигайте все отмеченные строки вместе с помощью элементов сдвига.\n4. Сохраните, чтобы создать итоговый файл `.lrc`.';

  @override
  String get lyricsEditorTipsText =>
      '- Если некоторые строки не отмечены, движок Flick заполнит их время автоматически.\n- При сохранении файл по возможности записывается рядом с песней, иначе связанная копия хранится в базе данных.';

  @override
  String fileNotFoundOrInaccessible(String title) {
    return 'Файл не найден или недоступен: $title';
  }

  @override
  String playbackFailedCorrupted(String title) {
    return 'Ошибка воспроизведения: не удалось загрузить или воспроизвести «$title». Убедитесь, что файл не повреждён.';
  }

  @override
  String shareSongText(String title) {
    return 'Послушай эту песню: $title';
  }

  @override
  String shareSongsText(int count) {
    return 'Послушай эти песни ($count)';
  }

  @override
  String noSettingsFoundFor(String query) {
    return 'По запросу «$query» настройки не найдены';
  }

  @override
  String get chooseQuickAccentColors => 'Выберите быстрый акцентный цвет';

  @override
  String get fontWeight => 'Насыщенность шрифта';

  @override
  String get changeBaseFontWeight =>
      'Изменить базовую насыщенность своего шрифта';

  @override
  String lyricsFontWeightValue(int weight) {
    return 'Насыщенность шрифта текста: $weight';
  }

  @override
  String get equalizerSearchDesc =>
      'Настройка 18-полосного эквалайзера и аудиопресетов';

  @override
  String get stopServiceSearchDesc =>
      'Останавливать воспроизведение и закрывать приложение при смахивании из недавних';

  @override
  String get scanNewFolderDesc => 'Найти аудиофайлы в новой папке';

  @override
  String get includeOtherDeviceAudioShortDesc =>
      'Рингтоны, уведомления и звуки мессенджеров';

  @override
  String get excludedFolders => 'Исключённые папки';

  @override
  String get excludedFoldersSearchDesc =>
      'Пропускать выбранные папки при сканировании';

  @override
  String get clearLibraryData => 'Очистить данные библиотеки';

  @override
  String get looperPlayerVersion => 'Версия Looper Player';

  @override
  String versionLabel(String version) {
    return 'Версия $version';
  }

  @override
  String get none => 'Нет';

  @override
  String foldersSkippedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count папки пропускаются при сканировании',
      many: '$count папок пропускаются при сканировании',
      few: '$count папки пропускаются при сканировании',
      one: '$count папка пропускается при сканировании',
    );
    return '$_temp0';
  }

  @override
  String get excludedFoldersDesc =>
      'Песни в этих папках пропускаются при сканировании, даже если они находятся внутри добавленной вами папки.';

  @override
  String get noExcludedFoldersYet => 'Исключённых папок пока нет.';

  @override
  String get excludeAFolder => 'Исключить папку';

  @override
  String get equalizerEnabled18Band => 'Включён (18-полосный эквалайзер MPV)';

  @override
  String get disabled => 'Выключен';

  @override
  String get noIndexedFoldersYet => 'Проиндексированных папок пока нет';

  @override
  String get noIndexedFoldersYetDesc =>
      'Используйте «Повторное сканирование библиотеки», чтобы найти папки в хранилище.';

  @override
  String get eqDynamicRangeCompressor => 'Компрессор динамического диапазона';

  @override
  String get eqThreshold => 'Порог';

  @override
  String get eqRatio => 'Коэффициент';

  @override
  String get eqAttack => 'Атака';

  @override
  String get eqRelease => 'Восстановление';

  @override
  String get eqHeadphoneCrossfeedWidth => 'Кроссфид и ширина для наушников';

  @override
  String get eqBinauralCrossfeed => 'Бинауральный кроссфид';

  @override
  String get eqCrossfeedStrength => 'Сила кроссфида';

  @override
  String get eqStereoWidening => 'Расширение стереобазы';

  @override
  String get eqWideningFactor => 'Коэффициент расширения';

  @override
  String get eqLoudnessNormalization => 'Нормализация громкости';

  @override
  String get eqTargetLoudness => 'Целевая громкость';

  @override
  String get eqToneShelving => 'Полочные фильтры тембра (низкие / высокие)';

  @override
  String get eqBassShelf => 'Полка низких частот';

  @override
  String get eqTrebleShelf => 'Полка высоких частот';

  @override
  String get eqTempoPitchControls => 'Темп и высота тона';

  @override
  String get eqPitchShift => 'Сдвиг высоты тона';

  @override
  String get eqTempoSpeed => 'Скорость темпа';

  @override
  String get eqVoiceSilenceControls => 'Голос и тишина';

  @override
  String get eqSilenceTrimming => 'Обрезка тишины';

  @override
  String get eqSilenceThreshold => 'Порог тишины';

  @override
  String get eqSpeechEnhancementFilter => 'Фильтр улучшения речи';

  @override
  String get eqHighpassCutoff => 'Срез фильтра верхних частот';

  @override
  String get eqLowpassCutoff => 'Срез фильтра нижних частот';

  @override
  String get eqRetroRoomEffects => 'Ретро и эффекты помещения';

  @override
  String get eqLofiEffect => 'Эффект lo-fi (8-битный кранчер)';

  @override
  String get eqStudioRoomReverb => 'Студийная реверберация (эхо)';

  @override
  String get eqVirtualSurround => 'Виртуальный объёмный звук 5.1';

  @override
  String get eqRawFilterConsole => 'Консоль фильтров FFmpeg';

  @override
  String get eqSwitchToSliders => 'Переключиться на ползунки';

  @override
  String get eqSwitchToGraph => 'Переключиться на график';

  @override
  String get on => 'Вкл';

  @override
  String get off => 'Выкл';

  @override
  String get eqSongSpecificActive => 'Активны настройки для этой песни';

  @override
  String get eqUsingGlobalDefault =>
      'Используются глобальные настройки по умолчанию';

  @override
  String get eqInteractiveGraphHint =>
      'ИНТЕРАКТИВНЫЙ ГРАФИК (ПЕРЕТАСКИВАЙТЕ ТОЧКИ ПО ВЕРТИКАЛИ)';

  @override
  String get eq18BandHint =>
      '18-ПОЛОСНЫЙ ЭКВАЛАЙЗЕР (ПРОКРУЧИВАЙТЕ ПО ГОРИЗОНТАЛИ)';

  @override
  String get eqSongSpecific => 'Для песни';

  @override
  String get eqGlobalDefault => 'Глобально по умолчанию';

  @override
  String get eqEditScopeNote =>
      'Изменения во время воспроизведения песни применяются только к ней. Чтобы задать глобальные настройки, редактируйте, когда ничего не играет, или используйте действие «Применить глобально».';

  @override
  String get presetFlat => 'Ровный';

  @override
  String get presetBassBooster => 'Усиление басов';

  @override
  String get presetTrebleBooster => 'Усиление высоких';

  @override
  String get presetVocalBooster => 'Усиление вокала';

  @override
  String get presetElectronic => 'Электроника';

  @override
  String get presetRock => 'Рок';

  @override
  String get presetPop => 'Поп';

  @override
  String get presetJazz => 'Джаз';

  @override
  String get save => 'Сохранить';

  @override
  String get savePreset => 'Сохранить пресет';

  @override
  String get presetName => 'Название пресета';

  @override
  String get deletePreset => 'Удалить пресет';

  @override
  String deletePresetConfirm(String name) {
    return 'Удалить пресет «$name»?';
  }

  @override
  String get noLyricsSource => 'Нет источника текста';

  @override
  String lyricsSourceLabel(String source) {
    return 'Источник: $source';
  }

  @override
  String get lyricsSourceLocalSidecar => 'Локальный файл рядом (.lrc)';

  @override
  String get lyricsSourceCustomFile => 'Свой LRC-файл';

  @override
  String get lyricsSourceNotFoundOnline => 'Не найдено в сети';

  @override
  String get lyricsProviderLocal => 'Локально';

  @override
  String get checkingLocalLyrics => 'Поиск локальных/встроенных текстов...';

  @override
  String fetchingLyricsFrom(String provider) {
    return 'Загрузка текста из $provider...';
  }

  @override
  String get loadedLocalLyrics => 'Локальный/встроенный текст загружен!';

  @override
  String get noLocalLyricsFound => 'Локальный или встроенный текст не найден';

  @override
  String lyricsUpdatedFrom(String provider) {
    return 'Текст обновлён из $provider!';
  }

  @override
  String noLyricsFoundOn(String provider) {
    return 'Текст не найден в $provider';
  }

  @override
  String get gestureTips => 'Подсказки по жестам';

  @override
  String get gestureTipsDesc =>
      'Касание, долгое нажатие, масштабирование щипком и другое';

  @override
  String get exportLyrics => 'Экспорт текста';

  @override
  String lyricsExportedTo(String path) {
    return 'Текст экспортирован в: $path';
  }

  @override
  String failedToExportLyrics(String error) {
    return 'Не удалось экспортировать текст: $error';
  }

  @override
  String get gestureTapLine => 'Коснитесь строки';

  @override
  String get gestureTapLineDesc => 'Перейти к этому месту текста.';

  @override
  String get gestureLongPressLine => 'Долго нажмите на строку';

  @override
  String get gestureLongPressLineDesc =>
      'Начните выбирать строки, чтобы создать карточку с текстом для отправки. Касайтесь других строк, чтобы расширить выбор.';

  @override
  String get gesturePinch => 'Сведите или разведите два пальца';

  @override
  String get gesturePinchDesc => 'Измените размер текста по своему вкусу.';

  @override
  String get gestureSwipeDown => 'Проведите вниз';

  @override
  String get gestureSwipeDownDesc =>
      'Закрыть экран текста и вернуться к плееру.';

  @override
  String get lyricsGestures => 'Жесты на экране текста';

  @override
  String get lyricsGesturesIntro =>
      'Несколько возможностей этого экрана, которые не всегда очевидны:';

  @override
  String linesSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Выбрано $count строки',
      many: 'Выбрано $count строк',
      few: 'Выбрано $count строки',
      one: 'Выбрана $count строка',
    );
    return '$_temp0';
  }

  @override
  String get couldNotGenerateShareImage =>
      'Не удалось создать изображение для отправки.';

  @override
  String get couldNotGenerateImage => 'Не удалось создать изображение.';

  @override
  String get savedToGallery => 'Сохранено в галерею.';

  @override
  String get galleryPermissionDenied => 'Доступ к галерее запрещён.';

  @override
  String get couldNotSaveToGallery =>
      'Не удалось сохранить изображение в галерею.';

  @override
  String get shareLyrics => 'Поделиться текстом';

  @override
  String get backgroundColor => 'Цвет фона';

  @override
  String get lyricsTextColor => 'Цвет текста песни';

  @override
  String get saveToGallery => 'Сохранить в галерею';

  @override
  String get preparing => 'Подготовка...';

  @override
  String get trackTitle => 'Название трека';

  @override
  String get composer => 'Композитор';

  @override
  String get unknownGenre => 'Неизвестный жанр';

  @override
  String get releaseYear => 'Год выпуска';

  @override
  String get notAvailable => 'Н/Д';

  @override
  String get recordLabel => 'Лейбл';

  @override
  String get copyright => 'Авторские права';

  @override
  String get encoder => 'Кодировщик';

  @override
  String get fileName => 'Имя файла';

  @override
  String get fileFormat => 'Формат файла';

  @override
  String get fileSize => 'Размер файла';

  @override
  String get absolutePath => 'Полный путь';

  @override
  String get playCount => 'Прослушивания';

  @override
  String playCountTimes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count раза',
      many: '$count раз',
      few: '$count раза',
      one: '$count раз',
    );
    return '$_temp0';
  }

  @override
  String get lastPlayed => 'Последнее прослушивание';

  @override
  String get filePath => 'Путь к файлу';

  @override
  String get rescan => 'Пересканировать';

  @override
  String get codec => 'Кодек';

  @override
  String get container => 'Контейнер';

  @override
  String get sampleRate => 'Частота дискретизации';

  @override
  String get bitDepth => 'Разрядность';

  @override
  String get decodedFormat => 'Декодированный формат';

  @override
  String get bitrate => 'Битрейт';

  @override
  String get channels => 'Каналы';

  @override
  String get nyquist => 'Найквист';

  @override
  String get dynamicRange => 'Динамический диапазон';

  @override
  String get peak => 'Пик';

  @override
  String get truePeak => 'Истинный пик';

  @override
  String get clipping => 'Клиппинг';

  @override
  String get cutoff => 'Срез';

  @override
  String get samples => 'Сэмплы';

  @override
  String channelShort(int channel) {
    return 'К $channel';
  }

  @override
  String get noneClean => 'Нет (чисто)';

  @override
  String get reanalyzingAudio => 'Повторный анализ аудиопотока...';

  @override
  String get analyzingAudio => 'Анализ аудиопотока...';

  @override
  String sampleRateHz(int rate) {
    return 'Частота дискретизации: $rate Гц';
  }

  @override
  String nyquistKhz(String khz) {
    return 'Найквист: $khz кГц';
  }

  @override
  String get qualityLossless => 'Без потерь';

  @override
  String get qualityHigh => 'Высокое качество';

  @override
  String get qualityStandard => 'Стандартное качество';

  @override
  String get qualityAudio => 'Аудио';

  @override
  String get addCustomFolder => 'Добавить свою папку';

  @override
  String get addCustomFolderDesc =>
      'Если ваша музыка лежит в папке с другим названием или на SD-карте, добавьте её напрямую.';

  @override
  String get indexingYourLibrary => 'ИНДЕКСАЦИЯ БИБЛИОТЕКИ...';

  @override
  String get indexingYourLibraryDesc =>
      'Заполняем названия, обложки и тексты ваших песен.';

  @override
  String welcomeStep(String step, String title) {
    return 'ШАГ $step: $title';
  }

  @override
  String get includeOtherDeviceAudioAlarmsDesc =>
      'Рингтоны, уведомления, будильники и звуки мессенджеров';

  @override
  String get version => 'Версия';

  @override
  String get noIndexedFoldersDesktopDesc =>
      'Используйте «Повторное сканирование библиотеки», чтобы найти папки хранилища';

  @override
  String get playedLabel => 'Прослушано';

  @override
  String minutesShort(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count мин',
      many: '$count мин',
      few: '$count мин',
      one: '$count мин',
    );
    return '$_temp0';
  }

  @override
  String minuteChip(int count) {
    return '$count мин';
  }

  @override
  String songsCountTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count песни',
      many: '$count песен',
      few: '$count песни',
      one: '$count песня',
    );
    return '$_temp0';
  }

  @override
  String songsLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Осталось $count песни',
      many: 'Осталось $count песен',
      few: 'Осталось $count песни',
      one: 'Осталась $count песня',
    );
    return '$_temp0';
  }

  @override
  String sleepTimerWithRemaining(String remaining) {
    return 'Таймер сна ($remaining)';
  }

  @override
  String get trackInfoSection => 'О ТРЕКЕ';

  @override
  String get detailsSection => 'ПОДРОБНОСТИ';

  @override
  String get lyricsSection => 'ТЕКСТ';

  @override
  String get editLyricsHint =>
      'Введите обычный текст или синхронизированный текст в формате LRC [00:00.00]...';

  @override
  String addedSongsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Добавлено $count песни',
      many: 'Добавлено $count песен',
      few: 'Добавлено $count песни',
      one: 'Добавлена $count песня',
    );
    return '$_temp0';
  }

  @override
  String get chooseInternalStorageFolder =>
      'Выберите папку во внутренней памяти или на SD-карте этого устройства.';

  @override
  String get appCrashedTitle => 'Сбой Looper Player';

  @override
  String get appCrashedDesc =>
      'При запуске произошла непредвиденная ошибка. Создан диагностический отчёт.';

  @override
  String get appCrashedDetails =>
      'Ошибка при инициализации базы данных или служб приложения. Это может случиться, если доступ к хранилищу ограничен или файлы базы данных повреждены.';

  @override
  String get crashReportSaved =>
      'Диагностический отчёт сохранён в папке поддержки приложения.';

  @override
  String get shareLog => 'Отправить журнал';

  @override
  String get restartApp => 'Перезапустить приложение';

  @override
  String get updateAvailableOnPlay => 'В Google Play доступна новая версия.';

  @override
  String updateAvailableOnGithub(String version) {
    return 'Версия $version доступна на GitHub.';
  }

  @override
  String get updateAvailable => 'Доступно обновление';

  @override
  String get updateAvailableTitle => 'Доступно обновление!';

  @override
  String get visit => 'ОТКРЫТЬ';

  @override
  String get updateDownloaded => 'Обновление загружено';

  @override
  String get restartToInstallUpdate =>
      'Перезапустите Looper Player, чтобы установить его.';

  @override
  String get restart => 'ПЕРЕЗАПУСК';

  @override
  String backupImportedSummary(int favorites, int stats, int playlists) {
    return 'Резервная копия импортирована: объединено избранного — $favorites, статистики прослушиваний — $stats, синхронизировано плейлистов — $playlists';
  }

  @override
  String get backupExportFailed =>
      'Не удалось экспортировать резервную копию: внутренняя ошибка при сохранении файла.';

  @override
  String get backupImportFailed =>
      'Не удалось импортировать резервную копию: файл не читается или имеет неверный формат.';

  @override
  String get stereo => 'Стерео';

  @override
  String get mono => 'Моно';
}
