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
  String get verticalMotionEffectPlayer => 'Vertikaler Bewegungseffekt Player';

  @override
  String get verticalMotionEffectPlayerDesc =>
      'Nach unten wischen, um den geöffneten Player zu schließen';

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
}
