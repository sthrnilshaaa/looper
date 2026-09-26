// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get about => 'Über';

  @override
  String get aboutAndMaintainers => 'Über & Betreuer';

  @override
  String get aboutApp => 'Über die App';

  @override
  String get aboutLooperPlayer => 'ÜBER LOOPER PLAYER';

  @override
  String get accentColor => 'Akzentfarbe';

  @override
  String get accentColorDesc => 'Manuelle Akzentfarbe für das Design wählen';

  @override
  String get acousticSpectralAnalysis => 'AKUSTISCHE UND SPEKTRALANALYSE';

  @override
  String get activeCallCannotPlay =>
      'Wiedergabe blockiert: Während eines aktiven Anrufs kann keine Musik abgespielt werden';

  @override
  String get adaptColorsArtwork =>
      'Passen Sie die Farben der App an das Albumcover an';

  @override
  String addedTo(String name) {
    return 'Zu $name hinzugefügt';
  }

  @override
  String get addedToQueue => 'Zur Warteschlange hinzugefügt';

  @override
  String get addFolder => 'Ordner hinzufügen';

  @override
  String get addToFavorites => 'Zu Favoriten hinzufügen';

  @override
  String get addToPlaylists => 'Zu Playlists hinzufügen';

  @override
  String get addToQueue => 'Zur Warteschlange hinzufügen';

  @override
  String get album => 'Album';

  @override
  String get albums => 'Alben';

  @override
  String get albumsRowDesc => 'Horizontales Regal mit Alben';

  @override
  String get allFilesAccess => 'Zugriff auf alle Dateien (empfohlen)';

  @override
  String get allSongs => 'Alle Lieder';

  @override
  String get appDetailsCreator =>
      'Anwendungsdetails, Ersteller und Informationen zum Designteam';

  @override
  String get appearance => 'Darstellung';

  @override
  String get appInfoPrivacy => 'APP-INFO & DATENSCHUTZ';

  @override
  String get appTitle => 'Looper-Spieler';

  @override
  String get artist => 'Künstler';

  @override
  String get artists => 'Künstler';

  @override
  String get artistsRowDesc => 'Horizontales Künstlerregal';

  @override
  String get ascending => 'Aufsteigend';

  @override
  String get audioCrossfade => 'Überblenden (Crossfade)';

  @override
  String get audioCrossfadeDesc =>
      'Titel beim Songwechsel sanft ineinander übergehen lassen';

  @override
  String get audioFocusDenied =>
      'Wiedergabe angehalten: Audio-Fokus vom System verweigert';

  @override
  String get audioPlayback => 'Audio & Wiedergabe';

  @override
  String get audioPlaybackDesc =>
      'Einstellungen für Überblenden, Stille und Ein-/Ausblenden';

  @override
  String get autoCrossfadeDuration => 'Dauer bei automatischer Überblendung';

  @override
  String get autoCrossfadeDurationDesc =>
      'Dauer der Überlappung bei automatischem Songwechsel';

  @override
  String get backToMainView => 'ZURÜCK ZUR HAUPTANSICHT';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get categories => 'Kategorien';

  @override
  String get center => 'Zentriert';

  @override
  String get clear => 'Leeren';

  @override
  String get clearQueue => 'Klar';

  @override
  String get connectDevice => 'GERÄT VERBINDEN';

  @override
  String get corePurpose => 'Kernzweck';

  @override
  String get corePurposeDesc =>
      'Looper Player ist ein Offline-High-Fidelity-Audioplayer, der für Musikliebhaber entwickelt wurde, die absolute Kontrolle über ihre lokale Bibliothek, lückenlose Wiedergabe und flüssiges, synchronisiertes Scrollen der Liedtexte wünschen.';

  @override
  String get create => 'Erstellen';

  @override
  String get createPlaylist => 'Playlist erstellen';

  @override
  String get creatorAndMaintainer => 'Schöpfer und Bewahrer';

  @override
  String get customAccentColor => 'Benutzerdefinierte Akzentfarbe';

  @override
  String get customizeColorsTheme =>
      'Passen Sie App-Farben, Themen und Liedtexthintergründe an';

  @override
  String get dateAdded => 'Hinzugefügt am';

  @override
  String get deepStorageScanProgress => 'TIEFSPEICHER-SCAN IN ARBEIT...';

  @override
  String get delete => 'Löschen';

  @override
  String get deleteFile => 'Datei löschen';

  @override
  String get deletePlaylist => 'Playlist löschen';

  @override
  String deletePlaylistConfirm(String name) {
    return 'Sind Sie sicher, dass Sie \"$name\" löschen möchten?';
  }

  @override
  String get deleteSong => 'Lied löschen';

  @override
  String get deleteSongConfirm =>
      'Möchten Sie diesen Song wirklich von der Festplatte löschen?';

  @override
  String get descending => 'Absteigend';

  @override
  String get designerAndMaintainer => 'Designer und Betreuer';

  @override
  String get disableBlurEffects => 'Deaktivieren Sie Unschärfeeffekte';

  @override
  String get disableSquigglyProgressBar =>
      'Deaktivieren Sie die Animation der Wellen-Fortschrittsleiste';

  @override
  String get downloadAudioDirectly => 'AUDIO DIREKT HERUNTERLADEN';

  @override
  String get downloadingLyricsOffline =>
      'Songtexte zur Offline-Nutzung werden heruntergeladen...';

  @override
  String get downloadMissingArtwork => 'Laden Sie „Missing Artwork“ herunter';

  @override
  String get downloadMissingArtworkDesc =>
      'Laden Sie automatisch hochauflösende Cover-Artworks für Songs von iTunes herunter';

  @override
  String get duration => 'Dauer';

  @override
  String get dynamicAccentColor => 'Dynamische Akzentfarbe';

  @override
  String get dynamicAccentColorDesc =>
      'Nur die Akzentfarbe dynamisch aus dem Albumcover generieren';

  @override
  String get dynamicBgOnlyLyrics => 'Dynamischer Hintergrund nur für Liedtexte';

  @override
  String get dynamicColorActiveLyrics => 'Dynamische Farbe für aktive Zeile';

  @override
  String get dynamicColorActiveLyricsDesc =>
      'Verwenden Sie extrahierte Bildfarben für die aktuell wiedergegebene Textzeile';

  @override
  String get dynamicLyricsBg => 'Dynamischer Liedtext BG';

  @override
  String get dynamicLyricsBgDesc =>
      'Albumcover-Unschärfe auf Songtext-Bildschirm anwenden';

  @override
  String get dynamicTheming => 'Dynamisches Theming';

  @override
  String get emptyLibraryDesc =>
      'Wir konnten in Ihrer Bibliothek keine unterstützten Musikdateien finden. Fügen Sie Ordner hinzu oder führen Sie einen Suchscan durch.';

  @override
  String get enableNetworkLyricsArt =>
      'Aktivieren Sie die Netzwerknutzung für Online-Liedtexte und Künstlerkunst';

  @override
  String get enablePlayerGradient => 'Musik-Bildschirmverlauf';

  @override
  String get enablePlayerGradientDesc =>
      'Aktivieren Sie den Hintergrund mit radialem Akzentverlauf auf dem aktuellen Bildschirm';

  @override
  String get fadeDuration => 'Dauer des Ein-/Ausblendens';

  @override
  String get fadeDurationDesc => 'Dauer des Ein- und Ausblende-Effekts';

  @override
  String get fadeOnSeek => 'Ausblenden beim Spulen';

  @override
  String get fadeOnSeekDesc =>
      'Lautstärke beim Spulen kurz aus- und wieder einblenden';

  @override
  String get fadePlayPauseStop => 'Ein-/Ausblenden bei Wiedergabe/Pause/Stopp';

  @override
  String get fadePlayPauseStopDesc =>
      'Lautstärke beim Starten, Pausieren oder Stoppen sanft ein- oder ausblenden';

  @override
  String get favorites => 'Favoriten';

  @override
  String get fileInformation => 'Dateiinformationen';

  @override
  String get flatProgressBar => 'Flacher Fortschrittsbalken';

  @override
  String get folders => 'Ordner';

  @override
  String get genre => 'Genre';

  @override
  String get genres => 'Genres';

  @override
  String get genresRowDesc => 'Horizontales Regal mit Musikgenres';

  @override
  String get goStart => 'LOS STARTEN';

  @override
  String get grant => 'GEWÄHREN';

  @override
  String get granted => 'ZUGEWÄHRT';

  @override
  String get history => 'Geschichte';

  @override
  String get home => 'Zuhause';

  @override
  String get homeDarkness => 'Dunkelheit des Startbildschirms';

  @override
  String get homeDarknessDesc =>
      'Passen Sie die Dunkelheit der Hintergrundüberlagerung für den Startbildschirm an';

  @override
  String get homeDashboardSettings => 'Home-Dashboard-Einstellungen';

  @override
  String get homeDashboardSettingsDesc =>
      'Passen Sie horizontale Reihen auf Ihrem Startbildschirm an';

  @override
  String get internetMode => 'Internetmodus';

  @override
  String get keepBackgroundGradient =>
      'Behalten Sie den Hintergrundverlauf bei';

  @override
  String get keepBackgroundGradientDesc =>
      'Behalten Sie den Hintergrundverlauf auf allen Anwendungsbildschirmen bei';

  @override
  String get animatePlayerGradient => 'Animierter Farbverlauf';

  @override
  String get animatePlayerGradientDesc =>
      'Bewegt Primär- und Tertiärfarben langsam mit feiner Körnung, passend zur Musik';

  @override
  String get animateBackgroundGradient => 'Animierter Hintergrund';

  @override
  String get animateBackgroundGradientDesc =>
      'Verwendet den animierten Farbverlauf als Hintergrund für Start, Titel und Mediathek';

  @override
  String get language => 'Sprache';

  @override
  String get left => 'Links';

  @override
  String get library => 'Bibliothek';

  @override
  String get libraryDarkness => 'Dunkelheit des Bibliotheksbildschirms';

  @override
  String get libraryDarknessDesc =>
      'Passen Sie die Dunkelheit der Hintergrundüberlagerung für den Bibliotheksbildschirm an';

  @override
  String get libraryFoldersSync =>
      'Ordner, Auslöser für erneutes Scannen, Zurücksetzen der Datenbank und Offline-Synchronisierung';

  @override
  String get librarySettings => 'Bibliothek-Einstellungen';

  @override
  String get loadingMusicLibrary => 'MUSIKBIBLIOTHEK WIRD GELADEN';

  @override
  String get loadingMusicLibraryDesc =>
      'Erstellen Sie Premium-Indizes, richten Sie Hardware-Listener ein und optimieren Sie visuelle Caches.';

  @override
  String get loadingPhase1 => 'AUDIOSPEICHER ABFRAGEN...';

  @override
  String get loadingPhase2 => 'ERFRISCHENDE MUSIK-ENGINE...';

  @override
  String get loadingPhase3 => 'AKUSTISCHE DATEN EXTRAHIEREN...';

  @override
  String get loadingPhase4 => 'WIEDERGABESPEICHER OPTIMIEREN...';

  @override
  String get lyrics => 'Songtexte';

  @override
  String get lyricsAlignment => 'Songtext-Ausrichtung';

  @override
  String get lyricsAlignmentDesc =>
      'Richten Sie Textpositionen für das Scrollen von Liedtexten aus';

  @override
  String get lyricsDarkness => 'Songtext von Screen Darkness';

  @override
  String get lyricsDarknessDesc =>
      'Passen Sie die Dunkelheit der Hintergrundüberlagerung für den Songtext-Bildschirm an';

  @override
  String get lyricsProvider => 'Liedtextanbieter';

  @override
  String get lyricsProviderDesc => 'Online-Songtexte von lrclib.net (LRCLIB)';

  @override
  String get maintainersAndDesigners => 'Entwickler & Designer';

  @override
  String get manageAudioFocus => 'Audiofokus verwalten';

  @override
  String get manageAudioFocusDesc =>
      'Audio-Fokus beim System anfordern und auf Fokusänderungen reagieren';

  @override
  String get manageAudioFocusTitle => 'Audio-Fokus verwalten';

  @override
  String get manageLanguageAndFocus =>
      'Verwalten Sie Spracheinstellungen und Anruferfokusstatus';

  @override
  String get audioFocusGetFocus => 'Fokus anfordern';

  @override
  String get audioFocusGetFocusDesc =>
      'Audiofokus anfordern, wenn die Wiedergabe beginnt.';

  @override
  String get audioFocusReleaseFocus => 'Fokus freigeben';

  @override
  String get audioFocusReleaseFocusDesc =>
      'Audiofokus freigeben, wenn die Wiedergabe pausiert oder stoppt.';

  @override
  String get audioFocusStopOnOtherSession =>
      'Musik bei anderer Musiksitzung stoppen';

  @override
  String get audioFocusStopOnOtherSessionDesc =>
      'Wiedergabe pausieren, wenn eine andere App Audio abspielt.';

  @override
  String get audioFocusRestartOnGain => 'Musik bei Fokusgewinn fortsetzen';

  @override
  String get audioFocusRestartOnGainDesc =>
      'Wiedergabe automatisch fortsetzen, sobald der Audiofokus zurückkehrt – nur wenn die Wiedergabe durch Fokusverlust unterbrochen wurde.';

  @override
  String get pauseOnDuckTitle => 'Bei Lautstärkeabsenkung pausieren';

  @override
  String get pauseOnDuckDesc =>
      'Wiedergabe pausieren statt die Lautstärke zu senken, wenn eine andere App einen kurzen Ton abspielt (z. B. Benachrichtigungen, Navigationsansagen).';

  @override
  String get resumeOnBluetoothConnectTitle =>
      'Bei Bluetooth-Verbindung fortsetzen';

  @override
  String get resumeOnBluetoothConnectDesc =>
      'Wiedergabe automatisch fortsetzen, wenn sich ein Bluetooth-Audiogerät (Kopfhörer, Freisprecheinrichtung) erneut verbindet.';

  @override
  String get manualCrossfadeDuration => 'Dauer bei manueller Überblendung';

  @override
  String get manualCrossfadeDurationDesc =>
      'Dauer der Überlappung beim manuellen Überspringen';

  @override
  String get matchingLyrics => 'PASSENDE TEXTE';

  @override
  String get metadataDetails => 'Metadatendetails';

  @override
  String get mostPlayed => 'Meistgespielt';

  @override
  String get musicAudioAccess => 'MUSIK- UND AUDIO-ZUGANG';

  @override
  String get musicDarkness => 'Musik-Player-Dunkelheit';

  @override
  String get musicDarknessDesc =>
      'Passen Sie die Dunkelheit der Hintergrundüberlagerung für den Musik-Player-Bildschirm an';

  @override
  String get musicLibrary => 'Musikbibliothek';

  @override
  String get muteOrPauseCalls =>
      'Stummschalten oder Pausieren während Anrufen und anderen Audioaktivitäten';

  @override
  String get newPlaylist => 'Neue Playlist';

  @override
  String get newTitle => 'Neuer Titel';

  @override
  String get nextUp => 'Als Nächstes';

  @override
  String get noAlbumsFound => 'Keine Alben gefunden';

  @override
  String get noArtistsFound => 'Keine Künstler gefunden';

  @override
  String get noFavoritesYet => 'Noch keine Favoriten';

  @override
  String get noHistoryYet => 'Kein Verlauf';

  @override
  String get noLyrics => 'Kein Songtext gefunden';

  @override
  String get noMusicDetected => 'KEINE MUSIK ERKANNT';

  @override
  String get noPlaylistsCreated => 'Noch keine Playlists erstellt.';

  @override
  String get noPlaylistsYet => 'Noch keine Playlists';

  @override
  String get noResultsFound => 'Keine Ergebnisse gefunden';

  @override
  String get noSongsFound => 'Keine Lieder gefunden';

  @override
  String get notificationAccess => 'ZUGRIFF AUF BENACHRICHTIGUNGEN';

  @override
  String get nowPlaying => 'Jetzt gespielt';

  @override
  String get performanceOptimizerDashboard =>
      'Performance-Optimierungs-Dashboard';

  @override
  String get performanceOptimizerDashboardDesc =>
      'Echtzeit-Statistiken zur Performance-Optimierung einblenden';

  @override
  String get permanentFocusChangePause => 'Pause bei dauerhaftem Fokusverlust';

  @override
  String get permanentFocusChangePauseDesc =>
      'Wiedergabe bei dauerhaftem Audio-Fokusverlust automatisch pausieren';

  @override
  String get plainTimestamps => 'Einfache Zeitstempel';

  @override
  String get play => 'Spielen';

  @override
  String get playAll => 'Alle abspielen';

  @override
  String get playbackAudio => 'Wiedergabe & Sprache';

  @override
  String get playlists => 'Wiedergabelisten';

  @override
  String get playNext => 'Nächstes abspielen';

  @override
  String get playQueue => 'Spielwarteschlange';

  @override
  String get pressBackExit =>
      'Drücken Sie erneut die Zurück-Taste, um den Vorgang zu beenden';

  @override
  String get privacySafety => 'Datenschutz und Sicherheit';

  @override
  String get privacySafetyDesc =>
      '100 % privat und offline-zuerst. Ihre Titel, Ihr Wiedergabeverlauf, Ihre Favoriten und Ihre Konfiguration bleiben ausschließlich in einer sicheren Isar-Datenbank auf Ihrem lokalen Gerät. Wir verfolgen, sammeln oder teilen Ihre Nutzungsdaten oder Präferenzen nicht.';

  @override
  String get pureBlackOled => 'Reines Schwarz (OLED)';

  @override
  String get pureBlackOledDesc =>
      'Absolutes Schwarz für Hintergründe verwenden';

  @override
  String get queue => 'Warteschlange';

  @override
  String get queueIsEmpty => 'Die Warteschlange ist leer';

  @override
  String get quickPicks => 'Schnelle Tipps';

  @override
  String get quickPicksRowDesc => 'Ihr meistgespieltes Liederraster';

  @override
  String get readyToScan => 'Bereit zum Scannen';

  @override
  String get recentlyAddedSongsRowDesc => 'Eine Liste Ihrer letzten Importe';

  @override
  String get recentlyPlayed => 'Zuletzt gespielt';

  @override
  String get recentPlayed => 'Zuletzt gespielt';

  @override
  String get recentRowDesc => 'Horizontales Regal der zuletzt gespielten Titel';

  @override
  String get removedFromPlaylist => 'Aus Playlist entfernt';

  @override
  String get removeFromFavorites => 'Aus Favoriten entfernen';

  @override
  String get removeFromPlaylist => 'Aus Playlist entfernen';

  @override
  String get rename => 'Umbenennen';

  @override
  String get renameFile => 'Datei umbenennen';

  @override
  String get renamePlaylist => 'Playlist umbenennen';

  @override
  String get renameSong => 'Song umbenennen';

  @override
  String get reorderDashboardSections => 'Dashboard-Abschnitte neu anordnen';

  @override
  String get reorderDashboardSectionsDesc =>
      'Legen Sie per Drag-and-Drop die bevorzugte Dashboard-Reihenfolge fest';

  @override
  String get includeOtherDeviceAudioTitle => 'Andere Geräteaudios einbeziehen';

  @override
  String get includeOtherDeviceAudioDesc =>
      'Klingeltöne, Benachrichtigungen, Alarme sowie WhatsApp- und Telegram-Audio scannen';

  @override
  String get rescanLibrary => 'Bibliothek erneut scannen';

  @override
  String get rescanStorage => 'SPEICHER NEU SCANNEN';

  @override
  String get reset => 'Zurücksetzen';

  @override
  String get resetLibrary => 'Zurücksetzen und erneut scannen';

  @override
  String get resetLibraryConfirm =>
      'Dadurch werden alle Songs, Alben und Künstler gelöscht und Ihre Ordner vollständig neu gescannt.';

  @override
  String get resetLibraryConfirmNew =>
      'Dadurch werden alle Songs aus Ihrer Bibliothek entfernt. Ihre Musikdateien werden nicht gelöscht.';

  @override
  String get resetLibraryDesc =>
      'Alle Songs aus Ihrer indizierten Bibliothek entfernen';

  @override
  String get resumeAfterCallDesc =>
      'Wiedergabe nach dem Auflegen fortsetzen (falls durch Anruf pausiert)';

  @override
  String get resumeAfterCallTitle => 'Wiedergabe nach Anruf fortsetzen';

  @override
  String get resumeOnStartDesc =>
      'Wiedergabe beim Starten von Looper Player automatisch fortsetzen';

  @override
  String get resumeOnStartTitle => 'Wiedergabe beim Start fortsetzen';

  @override
  String get persistQueueTitle => 'Letzte Warteschlange beibehalten';

  @override
  String get persistQueueDesc =>
      'Letzten Titel und Warteschlange bei App-Neustarts speichern';

  @override
  String get keepSongProgressTitle => 'Songfortschritt merken';

  @override
  String get keepSongProgressDesc =>
      'Merkt sich die Wiedergabeposition jedes Songs separat. Wechsle mitten im Song zu einem anderen und komme später zurück – auch nachdem zwischendurch andere Songs gespielt wurden – und die Wiedergabe wird genau dort fortgesetzt, wo du aufgehört hast, statt von vorne zu beginnen.';

  @override
  String get right => 'Rechts';

  @override
  String scanCompleteSongsDetected(int count) {
    return 'SCAN ABGESCHLOSSEN: $count SONGS ERKANNT!';
  }

  @override
  String get scanForMusic => 'NACH MUSIK SUCHEN';

  @override
  String get scanIndexLocalDesc => 'Lokale Musikdateien scannen und indizieren';

  @override
  String get scanLibrary => 'Bibliothek scannen';

  @override
  String get scanningInBackground => 'Scannen im Hintergrund...';

  @override
  String get scanningLibrary => 'Bibliothek wird gescannt...';

  @override
  String get scanningStorage => 'SPEICHER SCANNEN...';

  @override
  String get scanningStorageDesc =>
      'Durchsuchen Sie Verzeichnisbäume, um Audiospuren zu entdecken. Bitte warten Sie...';

  @override
  String get search => 'Suchen';

  @override
  String get searchLibraryHint => 'Durchsuchen Sie Ihre gesamte Bibliothek';

  @override
  String get searchSongsHint => 'Lieder suchen';

  @override
  String get seekFadeDuration => 'Dauer beim Spulen';

  @override
  String get seekFadeDurationDesc => 'Dauer des Ausblende-Effekts beim Spulen';

  @override
  String get selectAppLanguage => 'App-Sprache auswählen';

  @override
  String get selectCustomColor => 'Wählen Sie „Benutzerdefinierte Farbe“.';

  @override
  String get selectCustomFolder => 'BENUTZERDEFINIERTEN ORDNER WÄHLEN';

  @override
  String get selectFolderIndex =>
      'Ordner zum Scannen von Musikdateien auswählen';

  @override
  String get selectSpecificFolder => 'BESTIMMTEN ORDNER WÄHLEN';

  @override
  String get settings => 'Einstellungen';

  @override
  String get share => 'Teilen';

  @override
  String get shareFile => 'Datei teilen';

  @override
  String get showAlbumsRow => 'Albumzeile anzeigen';

  @override
  String get showAlbumsRowDesc =>
      'Zeigen Sie eine horizontale Liste der Alben auf Ihrem Startbildschirm an';

  @override
  String get showArtistsRow => 'Künstlerreihe anzeigen';

  @override
  String get showArtistsRowDesc =>
      'Zeigen Sie eine horizontale Liste der Künstler auf Ihrem Startbildschirm an';

  @override
  String get showGenresRow => 'Genrezeile anzeigen';

  @override
  String get showGenresRowDesc =>
      'Zeigen Sie eine horizontale Liste der Genres auf Ihrem Startbildschirm an';

  @override
  String get showLess => 'Weniger anzeigen';

  @override
  String get showMore => 'Mehr anzeigen';

  @override
  String get showQualityBadge => 'Qualitätsabzeichen vorzeigen';

  @override
  String get showQualityBadgeDesc =>
      'Zeigen Sie das Informationssymbol zur Audioqualität auf dem Bildschirm der aktuellen Wiedergabe an';

  @override
  String get showRecentRow => 'Zuletzt-gespielt-Zeile anzeigen';

  @override
  String get showRecentRowDesc =>
      'Zeigen Sie eine horizontale Liste der zuletzt gespielten Titel auf Ihrem Startbildschirm an';

  @override
  String get silenceBetweenTracksDesc =>
      'Stille Pause zwischen Titeln einfügen (0ms für lückenlose Wiedergabe)';

  @override
  String get silenceBetweenTracksTitle => 'Stille zwischen Titeln';

  @override
  String get songDeletedDbOnly =>
      'Song aus Bibliothek entfernt (physische Datei schreibgeschützt)';

  @override
  String get songDeletedSuccess => 'Song erfolgreich gelöscht';

  @override
  String get songDeleteFailed => 'Fehler beim Löschen des Songs';

  @override
  String get songDetails => 'Songdetails';

  @override
  String get songDetailsAndFrequency => 'Songdetails und Häufigkeit';

  @override
  String get songRenamedDbOnly =>
      'Song in App-Bibliothek umbenannt (physische Datei schreibgeschützt)';

  @override
  String get songRenamedSuccess => 'Song erfolgreich umbenannt';

  @override
  String get songRenameFailed => 'Fehler beim Umbenennen des Songs';

  @override
  String get songs => 'Lieder';

  @override
  String get songsDarkness => 'Dunkelheit des Songs-Bildschirms';

  @override
  String get songsDarknessDesc =>
      'Passen Sie die Dunkelheit der Hintergrundüberlagerung für den Bildschirm „Songs“ an';

  @override
  String get sortBy => 'Sortieren nach';

  @override
  String get sortOrder => 'Sortierreihenfolge';

  @override
  String get sourceCode => 'Quellcode';

  @override
  String get stopServiceOnAppDismissal =>
      'Dienst beim Schließen der App beenden';

  @override
  String get stopServiceOnAppDismissalDesc =>
      'Hintergrunddienst stoppen und App schließen, wenn sie aus der Übersicht entfernt wird';

  @override
  String get storagePermissionRequired =>
      'Zum Scannen des Gerätespeichers sind Speicherberechtigungen erforderlich.';

  @override
  String get syncLyricsOffline => 'Songtexte synchronisieren (Offline)';

  @override
  String get systemDefault => 'Systemstandard';

  @override
  String get systemPermissionChecklist => 'CHECKLISTE FÜR SYSTEMBERECHTIGUNGEN';

  @override
  String get technicalInfoFrequency =>
      'Technische Informationen und Häufigkeit';

  @override
  String get theme => 'Thema';

  @override
  String get title => 'Titel';

  @override
  String get todayMixForYou => 'Heute Mix für Dich';

  @override
  String get toggleFavorite => 'Favoriten umschalten';

  @override
  String get shuffleTitle => 'Zufallswiedergabe';

  @override
  String get shuffleDisabledDesc =>
      'Songs in ihrer ursprünglichen Warteschlangenreihenfolge abspielen. Das Deaktivieren der Zufallswiedergabe lässt den aktuellen Song weiterspielen und stellt die restliche Warteschlange in ihrer ursprünglichen Reihenfolge wieder her, ohne die Wiedergabe oder den Verlauf zu beeinflussen.';

  @override
  String get shuffleEnabledDesc =>
      'Die verbleibenden Songs zufällig anordnen, während der aktuelle Song unverändert bleibt. Die erzeugte Zufallsreihenfolge bleibt konsistent, bis sich die Warteschlange ändert oder eine neue Zufallswiedergabe angefordert wird, wodurch wiederholte oder übersprungene Titel vermieden werden.';

  @override
  String get shuffleSwitchingDesc =>
      'Das Umschalten der Zufallswiedergabe startet den aktuellen Song nie neu. Es ändert nur die Reihenfolge der kommenden Titel – zufällig, wenn aktiviert, und in der ursprünglichen Warteschlangenreihenfolge wiederhergestellt, wenn deaktiviert.';

  @override
  String get topResult => 'Top-Ergebnis';

  @override
  String get transferMusicFiles => 'MUSIKDATEIEN ÜBERTRAGEN';

  @override
  String get turnOffBlursOptimize =>
      'Deaktivieren Sie starke Unschärfen, um die Leistung zu optimieren';

  @override
  String get unknown => 'Unbekannt';

  @override
  String get unknownAlbum => 'Unbekanntes Album';

  @override
  String get unknownArtist => 'Unbekannter Künstler';

  @override
  String get updateLibraryIndexing =>
      'Indizierung der Musikdateien aktualisieren';

  @override
  String get useAbsoluteBlackBg =>
      'Verwenden Sie für Hintergründe absolutes Schwarz';

  @override
  String get useStaticTextTimestamps =>
      'Verwenden Sie für die Dauer des Fortschritts statischen Text anstelle einer rollenden Animation';

  @override
  String get fluidPlayer => 'Fließender Player';

  @override
  String get fluidPlayerDesc =>
      'Ziehe den Mini-Player nach oben, um ihn in den vollständigen Player zu verwandeln';

  @override
  String get viewAll => 'Alle anzeigen';

  @override
  String get visitOfficialRepository =>
      'Offizielles GitHub-Repository besuchen';

  @override
  String get welcomeAboutDesc =>
      'Looper Player ist ein Musik-Betriebssystem der nächsten Generation, das für erstklassige Offline-Audiowiedergabe entwickelt wurde. Bietet dynamische Textgenerierung in Echtzeit, erweiterte Audiositzungsverwaltung mit Anrufstummschaltung, adaptive Hintergrundthemen und Unterstützung für Musikbibliotheken in mehreren Formaten. Vollständig optimiert für maximale Batterieeffizienz.';

  @override
  String get welcomeAllFilesDesc =>
      'Sehr empfehlenswert für professionelles Scannen, um Songs in nicht standardmäßigen Verzeichnissen (Downloads, Telegram, benutzerdefinierte Ordner) zu finden.';

  @override
  String get welcomeInstructionConnectDesc =>
      'Schließen Sie Ihr Telefon oder Gerät über ein Standard-USB-Datenkabel an einen PC an.';

  @override
  String get welcomeInstructionDownloadDesc =>
      'Alternativ können Sie Dateien direkt über einen Webbrowser oder ein anderes Download-Dienstprogramm auf dem Gerät selbst herunterladen.';

  @override
  String get welcomeInstructionTransferDesc =>
      'Kopieren Sie Ihre Offline-Musikdateien (unterstützt .mp3, .flac, .m4a, .wav) direkt in den Standardordner „Musik“ oder „Download“ Ihres Geräts.';

  @override
  String get welcomeMusicAudioDesc =>
      'Erforderlich, um Standard-Offline-Audiotitel im Speicher Ihres Geräts zu erkennen und abzuspielen.';

  @override
  String get welcomeNoSongsDesc =>
      'Wir konnten keine unterstützten Audiodateien (MP3, FLAC, WAV, M4A, OGG) auf Ihrem Gerätespeicher finden.';

  @override
  String get welcomeNotificationDesc =>
      'Erforderlich, um Wiedergabesteuerungen und aktive Benachrichtigungs-Widgets in Ihrer Systemleiste anzuzeigen.';

  @override
  String get welcomeScanningFoldersDesc =>
      'Durchsucht alle Ordner und Unterordner nach Audiodateien.';

  @override
  String get whyInternetUsed => 'Warum das Internet genutzt wird';

  @override
  String get whyInternetUsedDesc =>
      '• Dynamische Synchronisierung von Liedtexten: Wird ausschließlich zum sicheren Abrufen und Herunterladen synchronisierter Liedtexte (LRC-Formate) aus Online-Datenbanken verwendet. Es werden niemals persönliche Daten, Einstellungen oder Mediendateien hochgeladen oder geteilt.';

  @override
  String get whyPermissionsUsed => 'Warum Berechtigungen verwendet werden';

  @override
  String get whyPermissionsUsedDesc =>
      '• Speicher-/Medienzugriff: Erforderlich, um auf Ihrem Gerät gespeicherte lokale Audiotitel zu erkennen, zu lesen und zu indizieren.\n• Benachrichtigungen: Erforderlich, um aktive Wiedergabesteuerungs-Widgets in Ihrer Statusleiste und Systemschublade anzuzeigen.';

  @override
  String get willPlayNext => 'Wird als nächstes abgespielt';

  @override
  String get year => 'Jahr';

  @override
  String get supportUs => 'Unterstützen Sie uns';

  @override
  String get supportUsDesc =>
      'Helfen Sie mit, Looper Player am Leben und quelloffen zu halten';

  @override
  String get supportDevelopment => 'Entwicklung unterstützen';

  @override
  String get supportDevelopmentDesc =>
      'Looper Player ist zu 100% kostenlos und quelloffen. Wenn Sie ihn gerne nutzen, unterstützen Sie den Entwickler bitte mit einer Spende. Jeder Beitrag hilft, das Projekt aktiv zu halten!';

  @override
  String get useCustomFont => 'Benutzerdefinierte Schriftart verwenden';

  @override
  String get useCustomFontDesc =>
      'Jost oder andere benutzerdefinierte Schriftarten verwenden. Andernfalls wird DM Sans verwendet.';

  @override
  String get selectFontFamily => 'Schriftfamilie auswählen';

  @override
  String activeFont(String fontName) {
    return 'Aktive Schriftart: $fontName';
  }

  @override
  String get fontWeightAdjustment => 'Schriftgewichtsanpassung';

  @override
  String get currentWeight => 'Aktuelles Gewicht';

  @override
  String get useCustomFontLyrics => 'Benutzerdefinierte Liedtext-Schriftart';

  @override
  String get useCustomFontLyricsDesc =>
      'Benutzerdefinierte Schriftart und -gewicht für die synchronisierte Liedtextansicht verwenden';

  @override
  String get lyricsFontFamily => 'Liedtext-Schriftfamilie';

  @override
  String activeLyricsFont(String fontName) {
    return 'Aktive Liedtext-Schriftart: $fontName';
  }

  @override
  String get lyricsFontWeightAdjustment => 'Liedtext-Schriftgewichtsanpassung';

  @override
  String get giveStarOnGithub => 'Stern auf GitHub geben';

  @override
  String get supportProjectLove =>
      'Unterstützen Sie das Projekt und zeigen Sie Ihre Begeisterung!';

  @override
  String get sortAlphabeticalAZ => 'Alphabetisch (A-Z)';

  @override
  String get sortAlphabeticalZA => 'Alphabetisch (Z-A)';

  @override
  String get sortRecentlyAdded => 'Kürzlich hinzugefügt';

  @override
  String get sortOldestAdded => 'Ältest hinzugefügt';

  @override
  String get sortYearNewest => 'Jahr (Neueste)';

  @override
  String get sortYearOldest => 'Jahr (Älteste)';

  @override
  String get sortMostSongs => 'Mehrste Titel';

  @override
  String get sortLeastSongs => 'Wenigste Titel';

  @override
  String get sortDefault => 'Standard';

  @override
  String get sortArtistAsc => 'Künstler (A-Z)';

  @override
  String get sortAlbumAsc => 'Album (A-Z)';

  @override
  String get sortDuration => 'Dauer';

  @override
  String get myAlbums => 'Meine Alben';

  @override
  String get featuredArtists => 'Vorgestellte Künstler';

  @override
  String get noSongPlaying => 'Kein Song wird abgespielt';

  @override
  String get nextLabel => 'Weiter';

  @override
  String get previousLabel => 'Zurück';

  @override
  String get resync => 'Neu synchronisieren';

  @override
  String get equalizer => 'Equalizer';

  @override
  String get presets => 'PRESETS';

  @override
  String get preAmpGain => 'Vorverstärkung';

  @override
  String get outputVolume => 'Ausgangslautstärke';

  @override
  String get customFilterHint =>
      'Geben Sie benutzerdefinierte libavfilter-Audiofilterparameter direkt ein (z. B. volume=3dB, aecho=0.8:0.88:60:0.4):';

  @override
  String get flowGlobalActions => 'Ablauf & globale Aktionen';

  @override
  String get equalizerModeLabel => 'Equalizer-Modus:';

  @override
  String get currentGainsAppliedGlobal =>
      'Aktuelle Werte als globale Standardeinstellung übernommen.';

  @override
  String get applyToGlobal => 'Auf global anwenden';

  @override
  String get songSpecificResetGlobal =>
      'Songspezifische Einstellungen auf globalen Standard zurückgesetzt.';

  @override
  String get resetToGlobal => 'Auf global zurücksetzen';

  @override
  String get resetAllSongsEq => 'EQ für alle Songs zurücksetzen';

  @override
  String get resetAllSongsEqConfirm =>
      'Möchten Sie wirklich die benutzerdefinierten Equalizer-Einstellungen für alle Songs in Ihrer Bibliothek löschen?';

  @override
  String get allSongsEqDataReset =>
      'Alle songspezifischen Equalizer-Daten wurden zurückgesetzt.';

  @override
  String get resetAllSongsEqData => 'EQ-Daten für alle Songs zurücksetzen';

  @override
  String get equalizerTargetMode => 'Equalizer-Zielmodus';

  @override
  String get equalizerTargetModeDesc =>
      'Wählen Sie aus, wie Equalizer-Einstellungen auf Ihre Musikbibliothek angewendet werden.';

  @override
  String get globalMode => 'Globaler Modus';

  @override
  String get globalModeDesc =>
      'Wendet Effekte universell auf alle Songs an. Die Equalizer-Einstellungen bleiben beim Songwechsel gleich.';

  @override
  String get songSpecificMode => 'Songspezifischer Modus';

  @override
  String get songSpecificModeDesc =>
      'Speichert benutzerdefinierte Einstellungen nur für den aktuellen Song. Der nächste Song verwendet standardmäßig keinen/flachen Equalizer, sofern kein eigenes Profil vorhanden ist.';

  @override
  String get viewDeviceAudioCapabilities => 'Geräte-Audiofunktionen anzeigen';

  @override
  String get deviceAudioCapabilities => 'Geräte-Audiofunktionen';

  @override
  String get noPlaybackActiveCapabilities =>
      'Keine aktive Wiedergabe oder Funktionsinformationen nicht verfügbar.';

  @override
  String get changeLyricsProvider => 'Songtext-Anbieter ändern';

  @override
  String get autoFallbackProviders => 'Automatische Ausweichanbieter';

  @override
  String get autoFallbackProvidersDesc =>
      'Bei fehlendem Songtext automatisch weitere Anbieter versuchen';

  @override
  String get ambientColorBackground => 'Ambientfarben-Hintergrund';

  @override
  String get ambientColorBackgroundDesc =>
      'Sanfte, dezente Farbverläufe aus dem Cover des Songs';

  @override
  String get exportLyricsLrc => 'Songtext exportieren (.lrc-Datei)';

  @override
  String get saveLyricsToDevice => 'Aktuellen Songtext auf dem Gerät speichern';

  @override
  String get noLyricsToExport => 'Kein Songtext zum Exportieren verfügbar';

  @override
  String get useCustomLyricsLrc => 'Eigenen Songtext verwenden (LRC-Datei)';

  @override
  String get selectLocalLrcFile =>
      'Lokale .lrc- oder .txt-Datei für diesen Song auswählen';

  @override
  String get customLyricsAppliedSuccess =>
      'Eigener Songtext erfolgreich angewendet!';

  @override
  String get noRecentlyPlayedTracks => 'Keine zuletzt gespielten Titel';

  @override
  String get close => 'Schließen';

  @override
  String get audioQualityAnalysis => 'Audioqualitätsanalyse';

  @override
  String get audioQualityAnalysisDesc =>
      'Tiefgehende Spektral- und Audioformatanalyse durchführen';

  @override
  String get audioStreamDetails => 'Audio-Stream-Details';

  @override
  String get perChannelMetrics => 'Kanalspezifische Messwerte';

  @override
  String get sleepTimer => 'Schlaf-Timer';

  @override
  String get stopByTime => 'NACH ZEIT STOPPEN';

  @override
  String get start => 'Start';

  @override
  String get stopBySongCount => 'NACH SONGANZAHL STOPPEN';

  @override
  String get cancelSleepTimer => 'Schlaf-Timer abbrechen';

  @override
  String get nowPlayingAllCaps => 'WIRD WIEDERGEGEBEN';

  @override
  String get settingsAndBackups => 'Einstellungen & Sicherungen';

  @override
  String get managePreferencesLibraryData =>
      'Einstellungen und Bibliotheksdaten verwalten';

  @override
  String get logsClearedSuccess => 'Protokolle erfolgreich gelöscht';

  @override
  String get editSongInfo => 'Songinfo bearbeiten';

  @override
  String get editAlbumInfo => 'Albuminfo bearbeiten';

  @override
  String get tapFieldToEdit => 'Zum Bearbeiten ein Feld antippen';

  @override
  String get alwaysBlurSheets => 'Sheets immer weichzeichnen';

  @override
  String get alwaysBlurSheetsDesc =>
      'Popup-Sheets weichzeichnen, auch wenn dynamisches Design deaktiviert ist';

  @override
  String get removeArtwork => 'Cover entfernen';

  @override
  String get resetArtworkToDefault => 'Auf Standard zurücksetzen';

  @override
  String get artworkResetToDefault => 'Cover auf Standard zurückgesetzt';

  @override
  String get noEmbeddedArtworkFound =>
      'Kein eingebettetes Cover für dieses Album gefunden';

  @override
  String get saveChangesBtn => 'Änderungen speichern';

  @override
  String get enterFolderPathManually => 'Ordnerpfad manuell eingeben';

  @override
  String get folderPickerManualHint =>
      'Falls sich die Systemverzeichnisauswahl nicht öffnet, geben Sie den vollständigen Verzeichnispfad unten ein oder fügen Sie ihn ein:';

  @override
  String get noSupportedSongsFoundFolder =>
      'Keine unterstützten Songs im ausgewählten Ordner gefunden';

  @override
  String get add => 'Hinzufügen';

  @override
  String get folderPickerClosed => 'Ordnerauswahl geschlossen';

  @override
  String get buyMeCoffee => 'Spendiere mir einen Kaffee';

  @override
  String get typeToSearchSettings => 'Einstellungen durchsuchen …';

  @override
  String get maintainersLabel => 'Betreuer';

  @override
  String get personBehindLooperPlayer => 'Die Person hinter LooperPlayer';

  @override
  String get blurredArtworkForLyrics => 'Unscharfes Cover für Songtext';

  @override
  String get blurredArtworkForLyricsDesc =>
      'Unscharfes Albumcover statt dynamischem/statischem Farbverlauf als Hintergrund anzeigen';

  @override
  String get lyricsFontWeight => 'Songtext-Schriftstärke';

  @override
  String get openSourceLicenses => 'Open-Source-Lizenzen';

  @override
  String get openSourceLicensesDesc =>
      'In dieser App verwendete Drittanbieter-Bibliotheken';

  @override
  String get done => 'Fertig';

  @override
  String get lyricsNotAvailable => 'Songtext nicht verfügbar.';

  @override
  String get lyricsNotAvailableHint =>
      'Importiere eine .lrc- oder .txt-Datei, um Songtext für diesen Song hinzuzufügen';

  @override
  String get importLyricsFile => 'Songtext-Datei importieren';

  @override
  String get approximatedSyncNoWordTimings =>
      'Näherungsweise Synchronisierung (ohne Wort-Timings)';

  @override
  String get lyricsSyncHelp => 'Hilfe zur Songtext-Synchronisierung';

  @override
  String get simpleModeLabel => 'Einfacher Modus';

  @override
  String get advancedModeLabel => 'Erweiterter Modus';

  @override
  String get tips => 'Tipps';

  @override
  String get gotIt => 'Verstanden';

  @override
  String get lyricsSyncStudio => 'Songtext-Sync-Studio';

  @override
  String get lyricsTextLabel => 'Songtext';

  @override
  String get lyricsTextHelperDesc =>
      'Eine Zeile pro Songtextzeile. Die untenstehenden Sync-Werkzeuge fügen diesen Zeilen Zeitstempel hinzu.';

  @override
  String get quickSync => 'Schnellsynchronisierung';

  @override
  String get autoAdvanceAfterStamping =>
      'Nach dem Setzen automatisch weiterspringen';

  @override
  String get advancedSync => 'Erweiterte Synchronisierung';

  @override
  String get useCurrentTime => 'Aktuelle Zeit verwenden';

  @override
  String get playbackAssist => 'Wiedergabehilfe';

  @override
  String get timeShift => 'Zeitverschiebung';

  @override
  String get timeShiftDesc =>
      'Verschiebt alle gesetzten Songtextzeiten gemeinsam vor oder zurück.';

  @override
  String get lyricsSaveLrcExplain =>
      'Beim Speichern wird nach Möglichkeit eine begleitende „.lrc“-Datei neben der Song-Audiodatei erstellt und zusätzlich in der lokalen Player-Datenbank gespeichert. Nicht gesetzte Zeilen werden automatisch interpoliert.';

  @override
  String get back => 'Zurück';

  @override
  String get appSettingsLabel => 'App-Einstellungen';

  @override
  String get backupsAndLogs => 'Backups & Protokolle';

  @override
  String get backupsAndLogsDesc =>
      'Daten exportieren, importieren und verwalten';

  @override
  String get exportBackupJson => 'Backup exportieren (JSON)';

  @override
  String get exportBackupJsonDesc =>
      'Speichert deine favorisierten Songs und Playlists in einer JSON-Datei, die du behalten oder teilen kannst. Es wird nichts anderes einbezogen.';

  @override
  String get importBackupJson => 'Backup importieren (JSON)';

  @override
  String get importBackupJsonDesc =>
      'Führt favorisierte Songs und Playlists aus einer Sicherungsdatei mit deiner Bibliothek zusammen. Bestehende Daten werden nie überschrieben oder entfernt.';

  @override
  String get exportDiagnosticsLogs => 'Diagnoseprotokolle exportieren';

  @override
  String get exportDiagnosticsLogsDesc =>
      'Teilt die Diagnoseprotokolldatei der App, damit sie zur Fehlerbehebung überprüft werden kann.';

  @override
  String get clearDiagnosticsLogs => 'Diagnoseprotokolle löschen';

  @override
  String get clearDiagnosticsLogsDesc =>
      'Löscht die Diagnoseprotokolldatei auf diesem Gerät dauerhaft. Dies kann nicht rückgängig gemacht werden.';

  @override
  String get lyricsPlainTextOrLrc => 'Songtext (Klartext oder LRC)';

  @override
  String get syncModeLine => 'ZEILE';

  @override
  String get syncModeWord => 'WORT';

  @override
  String get syncModeChar => 'ZEICHEN';

  @override
  String get enterManually => 'Manuell eingeben';

  @override
  String get rawFilterParametersHint => 'Rohe Filterparameter...';

  @override
  String get searchSettingsHint => 'Einstellungen suchen...';

  @override
  String get repeatTooltip => 'Wiederholen';

  @override
  String get favoriteTooltip => 'Favorit';

  @override
  String get instructionsTooltip => 'Anleitung';

  @override
  String get pasteLyricsHint => 'Songtext hier einfügen oder eingeben';

  @override
  String get timestampMmSsHint => 'Zeitstempel (mm:ss.xx)';

  @override
  String get nowLabel => 'Jetzt';

  @override
  String get playlistNameHint => 'Playlist-Name';

  @override
  String get songInfoUpdated => 'Songinfo aktualisiert!';

  @override
  String get albumInfoUpdated => 'Albuminfo aktualisiert!';

  @override
  String get failedToSaveChanges =>
      'Änderungen konnten nicht gespeichert werden.';

  @override
  String sleepTimerStoppingIn(String time) {
    return 'Aktiv: Stoppt in $time';
  }

  @override
  String sleepTimerStoppingAfter(String time) {
    return 'Aktiv: Stoppt nach $time';
  }

  @override
  String get selectWhenToPause =>
      'Wählen Sie, wann die Musikwiedergabe pausiert werden soll';

  @override
  String get selectAvatars => 'Avatar auswählen';

  @override
  String get selectAvatarsDesc => 'Wähle den Avatar für deinen Startbildschirm';

  @override
  String get dynamicAvatarColor => 'Dynamische Avatar-Farbe';

  @override
  String get dynamicAvatarColorDesc =>
      'Passt die Akzentfarbe des Avatars an dein aktuelles Design an';

  @override
  String enrichingSongs(int count) {
    return '$count Songs werden angereichert…';
  }

  @override
  String get noListeningHistoryYet => 'Noch kein Hörverlauf';

  @override
  String get noListeningHistoryYetDesc =>
      'Spiele ein paar Songs ab und dein persönliches Zeugnis – Top-Songs, Künstler, Alben und Genres – wird hier lebendig.';

  @override
  String get looperAnalyze => 'Looper Analyze';

  @override
  String get totalPlays => 'Wiedergaben gesamt';

  @override
  String get listeningTime => 'Hörzeit';

  @override
  String get currentStreakDays => 'Aktuelle Serie (Tage)';

  @override
  String get longestStreakDays => 'Längste Serie (Tage)';

  @override
  String analyzePlaysAndSongs(int plays, int songs) {
    return '$plays Wiedergaben • $songs Songs';
  }

  @override
  String get dayPartMorningShort => 'Morg.';

  @override
  String get dayPartAfternoonShort => 'Nachm.';

  @override
  String get dayPartEveningShort => 'Abd.';

  @override
  String get dayPartNightShort => 'Nacht';

  @override
  String get activityPattern => 'Aktivitätsmuster';

  @override
  String get whenYouListenMost => 'Wann du am meisten hörst';

  @override
  String get genreBreakdown => 'Genre-Aufteilung';

  @override
  String get otherGenre => 'Sonstige';

  @override
  String get topAlbums => 'Top-Alben';

  @override
  String get topArtists => 'Top-Künstler';

  @override
  String get topSongs => 'Top-Songs';

  @override
  String playsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Wiedergaben',
      one: '1 Wiedergabe',
    );
    return '$_temp0';
  }

  @override
  String songsPlayedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Songs gespielt',
      one: '1 Song gespielt',
    );
    return '$_temp0';
  }

  @override
  String get listeningTrend => 'Hörtrend';

  @override
  String get last30Days => 'Letzte 30 Tage';

  @override
  String errorWithDetails(String error) {
    return 'Fehler: $error';
  }

  @override
  String get selectAll => 'Alle auswählen';

  @override
  String get playlist => 'Playlist';

  @override
  String songsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Songs',
      one: '1 Song',
    );
    return '$_temp0';
  }

  @override
  String get recentSearches => 'Letzte Suchen';

  @override
  String get lyricsSourceLocalFile => 'Lokale Datei';

  @override
  String get lyricsSourceEmbedded => 'Eingebettete Metadaten';

  @override
  String lyricsProvidedBy(String source) {
    return 'Songtext bereitgestellt von $source';
  }

  @override
  String failedToImportLyrics(String error) {
    return 'Songtext konnte nicht importiert werden: $error';
  }

  @override
  String get lyricsEditorLines => 'Zeilen';

  @override
  String get lyricsEditorStamped => 'Gestempelt';

  @override
  String lyricsEditorLineNumber(int number) {
    return 'Zeile $number';
  }

  @override
  String get lyricsEditorEmptyLine => '(Leere Zeile)';

  @override
  String get lyricsEditorNotStamped => 'Noch nicht gestempelt';

  @override
  String get pause => 'Pause';

  @override
  String get lyricsEditorAddLineFirst =>
      'Füge zuerst mindestens eine Songtextzeile hinzu.';

  @override
  String get lyricsEditorSavedWithSidecar =>
      'Songtext in der Datenbank und neben der Songdatei gespeichert.';

  @override
  String get lyricsEditorSavedDbOnly =>
      'Songtext in der Player-Datenbank gespeichert.';

  @override
  String get lyricsEditorSaveFailed =>
      'Der Songtext konnte nicht gespeichert werden.';

  @override
  String get saving => 'Wird gespeichert...';

  @override
  String get saveLrc => 'LRC speichern';

  @override
  String lyricsEditorSelectedLine(int index, int total) {
    return 'Ausgewählte Zeile $index von $total';
  }

  @override
  String get lyricsEditorPickLine =>
      'Wähle unten eine Songtextzeile aus der Liste.';

  @override
  String get stampAndNext => 'Stempeln & Weiter';

  @override
  String get stampNow => 'Jetzt stempeln';

  @override
  String get lyricsEditorSimpleSteps =>
      '1. Füge pro Zeile eine Songtextzeile ein oder tippe sie ein.\n2. Spiele den Song ab.\n3. Wähle die aktuelle Songtextzeile aus.\n4. Tippe auf „Stempeln & Weiter“, wenn du diese Zeile hörst.\n5. Speichere, wenn du fertig bist.';

  @override
  String get lyricsEditorAdvancedSteps =>
      '1. Bearbeite die Zeitstempel jeder Zeile direkt.\n2. Nutze „Aktuelle Zeit verwenden“, um die laufende Wiedergabezeit zu übernehmen.\n3. Verschiebe mit den Verschiebe-Reglern alle gestempelten Zeilen gemeinsam.\n4. Speichere, um die fertige `.lrc`-Datei zu erzeugen.';

  @override
  String get lyricsEditorTipsText =>
      '- Sind einige Zeilen nicht gestempelt, füllt die Flick-Engine ihre Zeiten automatisch.\n- Beim Speichern wird nach Möglichkeit neben den Song geschrieben, sonst wird eine verknüpfte Kopie in der Datenbank abgelegt.';

  @override
  String fileNotFoundOrInaccessible(String title) {
    return 'Datei nicht gefunden oder nicht zugänglich: $title';
  }

  @override
  String playbackFailedCorrupted(String title) {
    return 'Wiedergabe fehlgeschlagen: „$title“ konnte nicht geladen oder abgespielt werden. Bitte prüfe, ob die Datei beschädigt ist.';
  }

  @override
  String shareSongText(String title) {
    return 'Hör dir diesen Song an: $title';
  }

  @override
  String shareSongsText(int count) {
    return 'Hör dir diese $count Songs an';
  }

  @override
  String noSettingsFoundFor(String query) {
    return 'Keine Einstellungen für „$query“ gefunden';
  }

  @override
  String get chooseQuickAccentColors => 'Schnelle Akzentfarben wählen';

  @override
  String get fontWeight => 'Schriftstärke';

  @override
  String get changeBaseFontWeight =>
      'Grundstärke der benutzerdefinierten Schrift ändern';

  @override
  String lyricsFontWeightValue(int weight) {
    return 'Songtext-Schriftstärke: $weight';
  }

  @override
  String get equalizerSearchDesc =>
      '18-Band-Equalizer und Audio-Presets anpassen';

  @override
  String get stopServiceSearchDesc =>
      'Wiedergabe stoppen und App schließen, wenn sie aus den letzten Apps gewischt wird';

  @override
  String get scanNewFolderDesc =>
      'Einen neuen Ordner nach Audiodateien durchsuchen';

  @override
  String get includeOtherDeviceAudioShortDesc =>
      'Klingeltöne, Benachrichtigungen und Messenger-Audio';

  @override
  String get excludedFolders => 'Ausgeschlossene Ordner';

  @override
  String get excludedFoldersSearchDesc =>
      'Bestimmte Ordner beim Scannen überspringen';

  @override
  String get clearLibraryData => 'Bibliotheksdaten löschen';

  @override
  String get looperPlayerVersion => 'Looper Player-Version';

  @override
  String versionLabel(String version) {
    return 'Version $version';
  }

  @override
  String get none => 'Keine';

  @override
  String foldersSkippedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Ordner werden beim Scannen übersprungen',
      one: '1 Ordner wird beim Scannen übersprungen',
    );
    return '$_temp0';
  }

  @override
  String get excludedFoldersDesc =>
      'Songs in diesen Ordnern werden beim Scannen übersprungen, auch wenn sie in einem hinzugefügten Ordner liegen.';

  @override
  String get noExcludedFoldersYet => 'Noch keine ausgeschlossenen Ordner.';

  @override
  String get excludeAFolder => 'Ordner ausschließen';

  @override
  String get equalizerEnabled18Band => 'Aktiviert (18-Band-MPV-EQ)';

  @override
  String get disabled => 'Deaktiviert';

  @override
  String get noIndexedFoldersYet => 'Noch keine indizierten Ordner';

  @override
  String get noIndexedFoldersYetDesc =>
      'Nutze „Bibliothek erneut scannen“, um Ordner im Speicher zu finden.';

  @override
  String get eqDynamicRangeCompressor => 'Dynamikkompressor';

  @override
  String get eqThreshold => 'Schwellenwert';

  @override
  String get eqRatio => 'Verhältnis';

  @override
  String get eqAttack => 'Attack';

  @override
  String get eqRelease => 'Release';

  @override
  String get eqHeadphoneCrossfeedWidth => 'Kopfhörer-Crossfeed & Breite';

  @override
  String get eqBinauralCrossfeed => 'Binauraler Crossfeed';

  @override
  String get eqCrossfeedStrength => 'Crossfeed-Stärke';

  @override
  String get eqStereoWidening => 'Stereoverbreiterung';

  @override
  String get eqWideningFactor => 'Verbreiterungsfaktor';

  @override
  String get eqLoudnessNormalization => 'Lautheitsnormalisierung';

  @override
  String get eqTargetLoudness => 'Ziellautheit';

  @override
  String get eqToneShelving => 'Klang-Shelving (Bass / Höhen)';

  @override
  String get eqBassShelf => 'Bass-Shelf';

  @override
  String get eqTrebleShelf => 'Höhen-Shelf';

  @override
  String get eqTempoPitchControls => 'Tempo- & Tonhöhenregler';

  @override
  String get eqPitchShift => 'Tonhöhenverschiebung';

  @override
  String get eqTempoSpeed => 'Tempo';

  @override
  String get eqVoiceSilenceControls => 'Stimm- & Stilleregler';

  @override
  String get eqSilenceTrimming => 'Stille entfernen';

  @override
  String get eqSilenceThreshold => 'Stille-Schwellenwert';

  @override
  String get eqSpeechEnhancementFilter => 'Sprachverbesserungsfilter';

  @override
  String get eqHighpassCutoff => 'Hochpass-Grenzfrequenz';

  @override
  String get eqLowpassCutoff => 'Tiefpass-Grenzfrequenz';

  @override
  String get eqRetroRoomEffects => 'Retro- & Raumeffekte';

  @override
  String get eqLofiEffect => 'Lofi-Effekt (8-Bit-Crusher)';

  @override
  String get eqStudioRoomReverb => 'Studioraum-Hall (Echo)';

  @override
  String get eqVirtualSurround => 'Virtueller 5.1-Surround-Sound';

  @override
  String get eqRawFilterConsole => 'FFmpeg-Rohfilterkonsole';

  @override
  String get eqSwitchToSliders => 'Zu Reglern wechseln';

  @override
  String get eqSwitchToGraph => 'Zum Graphen wechseln';

  @override
  String get on => 'An';

  @override
  String get off => 'Aus';

  @override
  String get eqSongSpecificActive => 'Songspezifische Einstellungen aktiv';

  @override
  String get eqUsingGlobalDefault =>
      'Globale Standardeinstellungen werden verwendet';

  @override
  String get eqInteractiveGraphHint =>
      'INTERAKTIVER GRAPH (PUNKTE SENKRECHT ZIEHEN)';

  @override
  String get eq18BandHint => '18-BAND-EQUALIZER (WAAGERECHT SCROLLEN)';

  @override
  String get eqSongSpecific => 'Songspezifisch';

  @override
  String get eqGlobalDefault => 'Globaler Standard';

  @override
  String get eqEditScopeNote =>
      'Änderungen während der Wiedergabe eines Songs gelten nur für diesen Song. Um den globalen Standard festzulegen, bearbeite ohne laufenden Song oder nutze die Aktion „Auf global anwenden“.';

  @override
  String get presetFlat => 'Neutral';

  @override
  String get presetBassBooster => 'Bass-Booster';

  @override
  String get presetTrebleBooster => 'Höhen-Booster';

  @override
  String get presetVocalBooster => 'Gesangs-Booster';

  @override
  String get presetElectronic => 'Elektronisch';

  @override
  String get presetRock => 'Rock';

  @override
  String get presetPop => 'Pop';

  @override
  String get presetJazz => 'Jazz';

  @override
  String get save => 'Speichern';

  @override
  String get savePreset => 'Preset speichern';

  @override
  String get presetName => 'Preset-Name';

  @override
  String get deletePreset => 'Preset löschen';

  @override
  String deletePresetConfirm(String name) {
    return 'Preset „$name“ löschen?';
  }

  @override
  String get noLyricsSource => 'Keine Songtextquelle';

  @override
  String lyricsSourceLabel(String source) {
    return 'Quelle: $source';
  }

  @override
  String get lyricsSourceLocalSidecar => 'Lokale Begleitdatei (.lrc)';

  @override
  String get lyricsSourceCustomFile => 'Eigene LRC-Datei';

  @override
  String get lyricsSourceNotFoundOnline => 'Online nicht gefunden';

  @override
  String get lyricsProviderLocal => 'Lokal';

  @override
  String get checkingLocalLyrics =>
      'Lokale/eingebettete Songtexte werden geprüft...';

  @override
  String fetchingLyricsFrom(String provider) {
    return 'Songtext wird von $provider abgerufen...';
  }

  @override
  String get loadedLocalLyrics => 'Lokaler/eingebetteter Songtext geladen!';

  @override
  String get noLocalLyricsFound =>
      'Kein lokaler oder eingebetteter Songtext gefunden';

  @override
  String lyricsUpdatedFrom(String provider) {
    return 'Songtext von $provider aktualisiert!';
  }

  @override
  String noLyricsFoundOn(String provider) {
    return 'Kein Songtext auf $provider gefunden';
  }

  @override
  String get gestureTips => 'Gesten-Tipps';

  @override
  String get gestureTipsDesc =>
      'Tippen, lange drücken, zum Zoomen zusammenziehen & mehr';

  @override
  String get exportLyrics => 'Songtext exportieren';

  @override
  String lyricsExportedTo(String path) {
    return 'Songtext exportiert nach: $path';
  }

  @override
  String failedToExportLyrics(String error) {
    return 'Songtext konnte nicht exportiert werden: $error';
  }

  @override
  String get gestureTapLine => 'Auf eine Zeile tippen';

  @override
  String get gestureTapLineDesc => 'Springt direkt zu dieser Songtextzeile.';

  @override
  String get gestureLongPressLine => 'Eine Zeile lange drücken';

  @override
  String get gestureLongPressLineDesc =>
      'Beginnt die Auswahl von Zeilen für eine teilbare Songtextkarte. Tippe weitere Zeilen an, um die Auswahl zu erweitern.';

  @override
  String get gesturePinch => 'Mit zwei Fingern zusammenziehen';

  @override
  String get gesturePinchDesc =>
      'Passe die Größe des Songtexts nach Wunsch an.';

  @override
  String get gestureSwipeDown => 'Nach unten wischen';

  @override
  String get gestureSwipeDownDesc =>
      'Schließt den Songtext und kehrt zum Player zurück.';

  @override
  String get lyricsGestures => 'Songtext-Gesten';

  @override
  String get lyricsGesturesIntro =>
      'Ein paar Dinge, die dieser Bildschirm kann und die nicht immer offensichtlich sind:';

  @override
  String linesSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Zeilen ausgewählt',
      one: '1 Zeile ausgewählt',
    );
    return '$_temp0';
  }

  @override
  String get couldNotGenerateShareImage =>
      'Das Bild zum Teilen konnte nicht erstellt werden.';

  @override
  String get couldNotGenerateImage => 'Das Bild konnte nicht erstellt werden.';

  @override
  String get savedToGallery => 'In der Galerie gespeichert.';

  @override
  String get galleryPermissionDenied =>
      'Der Zugriff auf die Galerie wurde verweigert.';

  @override
  String get couldNotSaveToGallery =>
      'Das Bild konnte nicht in der Galerie gespeichert werden.';

  @override
  String get shareLyrics => 'Songtext teilen';

  @override
  String get backgroundColor => 'Hintergrundfarbe';

  @override
  String get lyricsTextColor => 'Songtext-Farbe';

  @override
  String get saveToGallery => 'In Galerie speichern';

  @override
  String get preparing => 'Wird vorbereitet...';

  @override
  String get trackTitle => 'Titel';

  @override
  String get composer => 'Komponist';

  @override
  String get unknownGenre => 'Unbekanntes Genre';

  @override
  String get releaseYear => 'Erscheinungsjahr';

  @override
  String get notAvailable => 'k. A.';

  @override
  String get recordLabel => 'Label';

  @override
  String get copyright => 'Copyright';

  @override
  String get encoder => 'Encoder';

  @override
  String get fileName => 'Dateiname';

  @override
  String get fileFormat => 'Dateiformat';

  @override
  String get fileSize => 'Dateigröße';

  @override
  String get absolutePath => 'Absoluter Pfad';

  @override
  String get playCount => 'Wiedergaben';

  @override
  String playCountTimes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count-mal',
      one: '1-mal',
    );
    return '$_temp0';
  }

  @override
  String get lastPlayed => 'Zuletzt gespielt';

  @override
  String get filePath => 'Dateipfad';

  @override
  String get rescan => 'Neu scannen';

  @override
  String get codec => 'Codec';

  @override
  String get container => 'Container';

  @override
  String get sampleRate => 'Abtastrate';

  @override
  String get bitDepth => 'Bittiefe';

  @override
  String get decodedFormat => 'Dekodiertes Format';

  @override
  String get bitrate => 'Bitrate';

  @override
  String get channels => 'Kanäle';

  @override
  String get nyquist => 'Nyquist';

  @override
  String get dynamicRange => 'Dynamikumfang';

  @override
  String get peak => 'Spitze';

  @override
  String get truePeak => 'True Peak';

  @override
  String get clipping => 'Clipping';

  @override
  String get cutoff => 'Grenzfrequenz';

  @override
  String get samples => 'Samples';

  @override
  String channelShort(int channel) {
    return 'K $channel';
  }

  @override
  String get noneClean => 'Keins (sauber)';

  @override
  String get reanalyzingAudio => 'Audiostream wird erneut analysiert...';

  @override
  String get analyzingAudio => 'Audiostream wird analysiert...';

  @override
  String sampleRateHz(int rate) {
    return 'Abtastrate: $rate Hz';
  }

  @override
  String nyquistKhz(String khz) {
    return 'Nyquist: $khz kHz';
  }

  @override
  String get qualityLossless => 'Verlustfrei';

  @override
  String get qualityHigh => 'Hohe Qualität';

  @override
  String get qualityStandard => 'Standardqualität';

  @override
  String get qualityAudio => 'Audio';

  @override
  String get addCustomFolder => 'Eigenen Ordner hinzufügen';

  @override
  String get addCustomFolderDesc =>
      'Liegt deine Musik in einem anders benannten Ordner oder auf einer SD-Karte, füge ihn direkt hinzu.';

  @override
  String get indexingYourLibrary => 'BIBLIOTHEK WIRD INDIZIERT...';

  @override
  String get indexingYourLibraryDesc =>
      'Titel, Cover und Songtexte deiner Songs werden ergänzt.';

  @override
  String welcomeStep(String step, String title) {
    return 'SCHRITT $step: $title';
  }

  @override
  String get includeOtherDeviceAudioAlarmsDesc =>
      'Klingeltöne, Benachrichtigungen, Wecker und Messenger-Audio';

  @override
  String get version => 'Version';

  @override
  String get noIndexedFoldersDesktopDesc =>
      'Nutze „Bibliothek erneut scannen“, um Speicherordner zu finden';

  @override
  String get playedLabel => 'Gespielt';

  @override
  String minutesShort(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Min.',
      one: '1 Min.',
    );
    return '$_temp0';
  }

  @override
  String minuteChip(int count) {
    return '$count Min.';
  }

  @override
  String songsCountTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Songs',
      one: '1 Song',
    );
    return '$_temp0';
  }

  @override
  String songsLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'noch $count Songs',
      one: 'noch 1 Song',
    );
    return '$_temp0';
  }

  @override
  String sleepTimerWithRemaining(String remaining) {
    return 'Sleep-Timer ($remaining)';
  }

  @override
  String get trackInfoSection => 'TRACK-INFOS';

  @override
  String get detailsSection => 'DETAILS';

  @override
  String get lyricsSection => 'SONGTEXT';

  @override
  String get editLyricsHint =>
      'Songtext als reinen Text oder im synchronisierten LRC-Format [00:00.00] eingeben...';

  @override
  String addedSongsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Songs hinzugefügt',
      one: '1 Song hinzugefügt',
    );
    return '$_temp0';
  }

  @override
  String get chooseInternalStorageFolder =>
      'Bitte wähle einen Ordner im internen Speicher oder auf der SD-Karte dieses Geräts.';

  @override
  String get appCrashedTitle => 'Looper Player ist abgestürzt';

  @override
  String get appCrashedDesc =>
      'Beim Start ist ein unerwarteter Fehler aufgetreten. Ein Diagnose-Absturzbericht wurde erstellt.';

  @override
  String get appCrashedDetails =>
      'Bei der Initialisierung der App-Datenbank oder eines Dienstes ist ein Fehler aufgetreten. Das kann passieren, wenn der Speicherzugriff eingeschränkt ist oder Datenbankdateien beschädigt sind.';

  @override
  String get crashReportSaved =>
      'Diagnose-Absturzbericht im App-Supportordner gespeichert.';

  @override
  String get shareLog => 'Log teilen';

  @override
  String get restartApp => 'App neu starten';

  @override
  String get updateAvailableOnPlay =>
      'Eine neue Version ist bei Google Play verfügbar.';

  @override
  String updateAvailableOnGithub(String version) {
    return 'Version $version ist auf GitHub verfügbar.';
  }

  @override
  String get updateAvailable => 'Update verfügbar';

  @override
  String get updateAvailableTitle => 'Update verfügbar!';

  @override
  String get visit => 'ÖFFNEN';

  @override
  String get updateDownloaded => 'Update heruntergeladen';

  @override
  String get restartToInstallUpdate =>
      'Starte Looper Player neu, um es zu installieren.';

  @override
  String get restart => 'NEU STARTEN';

  @override
  String backupImportedSummary(int favorites, int stats, int playlists) {
    return 'Backup importiert: $favorites Favoriten und $stats Wiedergabestatistiken zusammengeführt, $playlists Playlists synchronisiert';
  }

  @override
  String get backupExportFailed =>
      'Backup-Export fehlgeschlagen: Beim Speichern der Backup-Datei ist ein interner Fehler aufgetreten.';

  @override
  String get backupImportFailed =>
      'Backup-Import fehlgeschlagen: Die Datei konnte nicht gelesen werden oder das Backup-Format ist ungültig.';

  @override
  String get stereo => 'Stereo';

  @override
  String get mono => 'Mono';
}
