// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get about => 'Informazioni';

  @override
  String get aboutAndMaintainers => 'Informazioni e Sviluppatori';

  @override
  String get aboutApp => 'Informazioni sull\'app';

  @override
  String get aboutLooperPlayer => 'INFORMAZIONI SU LOOPER PLAYER';

  @override
  String get accentColor => 'Colore d\'accento';

  @override
  String get accentColorDesc =>
      'Seleziona manualmente il colore principale del tema';

  @override
  String get acousticSpectralAnalysis => 'ANALISI ACUSTICA E SPETTRALE';

  @override
  String get activeCallCannotPlay =>
      'Riproduzione bloccata: Impossibile riprodurre musica durante una chiamata attiva';

  @override
  String get adaptColorsArtwork => 'Adatta i colori all\'immagine di copertina';

  @override
  String addedTo(String name) {
    return 'Aggiunto a $name';
  }

  @override
  String get addedToQueue => 'Aggiunto alla coda';

  @override
  String get addFolder => 'Aggiungi cartella';

  @override
  String get addToFavorites => 'Aggiungi ai preferiti';

  @override
  String get addToPlaylists => 'Aggiungi alle playlist';

  @override
  String get addToQueue => 'Aggiungi alla coda';

  @override
  String get album => 'Album';

  @override
  String get albums => 'Album';

  @override
  String get albumsRowDesc => 'Elenco orizzontale di album';

  @override
  String get allFilesAccess => 'ACCESSO A TUTTI I FILE (CONSIGLIATO)';

  @override
  String get allSongs => 'Tutti i brani';

  @override
  String get appDetailsCreator =>
      'Dettagli dell\'applicazione, autore e team di design';

  @override
  String get appearance => 'Aspetto';

  @override
  String get appInfoPrivacy => 'INFORMAZIONI E PRIVACY';

  @override
  String get appTitle => 'Looper Player';

  @override
  String get artist => 'Artista';

  @override
  String get artists => 'Artisti';

  @override
  String get artistsRowDesc => 'Elenco orizzontale di artisti';

  @override
  String get ascending => 'Crescente';

  @override
  String get audioCrossfade => 'Dissolvenza incrociata audio';

  @override
  String get audioCrossfadeDesc =>
      'Sovrappone i brani gradualmente durante il cambio traccia';

  @override
  String get audioFocusDenied =>
      'Riproduzione in pausa: focus audio negato dal sistema';

  @override
  String get audioPlayback => 'Audio e riproduzione';

  @override
  String get audioPlaybackDesc =>
      'Impostazioni di dissolvenza incrociata, silenzio e sfumatura';

  @override
  String get autoCrossfadeDuration =>
      'Durata dissolvenza incrociata automatica';

  @override
  String get autoCrossfadeDurationDesc =>
      'Durata sovrapposizione durante la transizione automatica';

  @override
  String get backToMainView => 'TORNA ALLA SCHERMATA PRINCIPALE';

  @override
  String get cancel => 'Annulla';

  @override
  String get categories => 'Categorie';

  @override
  String get center => 'Centro';

  @override
  String get clear => 'Cancella';

  @override
  String get clearQueue => 'Svuota coda';

  @override
  String get connectDevice => 'CONNETTI DISPOSITIVO';

  @override
  String get corePurpose => 'Scopo principale';

  @override
  String get corePurposeDesc =>
      'Looper Player è un riproduttore audio offline ad alta fedeltà pensato per gli appassionati che vogliono il controllo totale sulla propria libreria locale, riproduzione continua senza pause e scorrimento fluido dei testi sincronizzati.';

  @override
  String get create => 'Crea';

  @override
  String get createPlaylist => 'Crea Playlist';

  @override
  String get creatorAndMaintainer => 'Autore e manutentore';

  @override
  String get customAccentColor => 'Colore d\'accento personalizzato';

  @override
  String get customizeColorsTheme =>
      'Personalizza i colori dell\'applicazione, il tema e gli sfondi dei testi';

  @override
  String get dateAdded => 'Data di aggiunta';

  @override
  String get deepStorageScanProgress => 'SCANSIONE PROFONDA IN CORSO...';

  @override
  String get delete => 'Elimina';

  @override
  String get deleteFile => 'Elimina File';

  @override
  String get deletePlaylist => 'Elimina Playlist';

  @override
  String deletePlaylistConfirm(String name) {
    return 'Sei sicuro di voler eliminare \"$name\"?';
  }

  @override
  String get deleteSong => 'Elimina brano';

  @override
  String get deleteSongConfirm =>
      'Sei sicuro di voler eliminare questo brano dal disco?';

  @override
  String get descending => 'Decrescente';

  @override
  String get designerAndMaintainer => 'Designer e manutentore';

  @override
  String get disableBlurEffects => 'Disattiva effetti di sfocatura';

  @override
  String get disableSquigglyProgressBar =>
      'Disattiva l\'animazione ondulata della barra di progresso';

  @override
  String get downloadAudioDirectly => 'SCARICA AUDIO DIRETAMENTE';

  @override
  String get downloadingLyricsOffline =>
      'Download dei testi per l\'uso offline...';

  @override
  String get downloadMissingArtwork => 'Scarica copertine mancanti';

  @override
  String get downloadMissingArtworkDesc =>
      'Scarica automaticamente da iTunes le copertine ad alta risoluzione per i brani mancanti';

  @override
  String get duration => 'Durata';

  @override
  String get dynamicAccentColor => 'Colore d\'accento dinamico';

  @override
  String get dynamicAccentColorDesc =>
      'Aggiorna solo il colore principale in base alla copertina';

  @override
  String get dynamicBgOnlyLyrics => 'Sfondo dinamico solo per i testi';

  @override
  String get dynamicColorActiveLyrics => 'Colore dinamico per la riga attiva';

  @override
  String get dynamicColorActiveLyricsDesc =>
      'Usa i colori estratti dalla copertina per la riga dei testi attualmente attiva';

  @override
  String get dynamicLyricsBg => 'Sfondo dinamico dei testi';

  @override
  String get dynamicLyricsBgDesc =>
      'Applica la sfocatura della copertina sullo schermo dei testi';

  @override
  String get dynamicTheming => 'Tema dinamico';

  @override
  String get emptyLibraryDesc =>
      'Non abbiamo trovato file musicali supportati nella tua libreria. Aggiungi delle cartelle o avvia una scansione.';

  @override
  String get enableNetworkLyricsArt =>
      'Consenti l\'uso della rete per testi online e immagini degli artisti';

  @override
  String get enablePlayerGradient => 'Gradiente schermata riproduzione';

  @override
  String get enablePlayerGradientDesc =>
      'Attiva lo sfondo radiale con gradiente d\'accento nella schermata di riproduzione';

  @override
  String get fadeDuration => 'Durata dissolvenza';

  @override
  String get fadeDurationDesc => 'Durata dell\'effetto di dissolvenza volume';

  @override
  String get fadeOnSeek => 'Dissolvenza sul seek';

  @override
  String get fadeOnSeekDesc =>
      'Sfuma gradualmente il volume durante il posizionamento sulla traccia';

  @override
  String get fadePlayPauseStop => 'Dissolvenza Riproduzione/Pausa/Stop';

  @override
  String get fadePlayPauseStopDesc =>
      'Sfuma gradualmente il volume all\'avvio, in pausa o all\'arresto';

  @override
  String get favorites => 'Preferiti';

  @override
  String get fileInformation => 'Informazioni file';

  @override
  String get flatProgressBar => 'Barra di progresso piatta';

  @override
  String get folders => 'Cartelle';

  @override
  String get genre => 'Genere';

  @override
  String get genres => 'Generi';

  @override
  String get genresRowDesc => 'Elenco orizzontale di generi musicali';

  @override
  String get goStart => 'INIZIA';

  @override
  String get grant => 'CONCEDI';

  @override
  String get granted => 'CONCESSO';

  @override
  String get history => 'Cronologia';

  @override
  String get home => 'Home';

  @override
  String get homeDarkness => 'Luminosità sfondo Home';

  @override
  String get homeDarknessDesc =>
      'Regola l\'oscurità del livello di sfondo per la schermata Home';

  @override
  String get homeDashboardSettings => 'Impostazioni pannello principale';

  @override
  String get homeDashboardSettingsDesc =>
      'Personalizza le righe orizzontali nella schermata Home';

  @override
  String get internetMode => 'Modalità Internet';

  @override
  String get keepBackgroundGradient => 'Mantieni gradiente di sfondo';

  @override
  String get keepBackgroundGradientDesc =>
      'Mantieni il gradiente di sfondo su tutte le schermate dell\'applicazione';

  @override
  String get animatePlayerGradient => 'Gradiente animato';

  @override
  String get animatePlayerGradientDesc =>
      'Muove lentamente i colori primario e terziario con una grana morbida, reagendo alla musica';

  @override
  String get animateBackgroundGradient => 'Sfondo animato';

  @override
  String get animateBackgroundGradientDesc =>
      'Usa il gradiente animato come sfondo di Home, Brani e Libreria';

  @override
  String get language => 'Lingua';

  @override
  String get left => 'Sinistra';

  @override
  String get library => 'Libreria';

  @override
  String get libraryDarkness => 'Luminosità sfondo Libreria';

  @override
  String get libraryDarknessDesc =>
      'Regola l\'oscurità del livello di sfondo per la schermata Libreria';

  @override
  String get libraryFoldersSync =>
      'Cartelle, attivatori di nuova scansione, ripristino database e sincronizzazione offline';

  @override
  String get librarySettings => 'Impostazioni Libreria';

  @override
  String get loadingMusicLibrary => 'CARICAMENTO LIBRERIA MUSICALE';

  @override
  String get loadingMusicLibraryDesc =>
      'Generazione degli indici, configurazione dei listener hardware e ottimizzazione della cache visiva.';

  @override
  String get loadingPhase1 => 'INTERROGAZIONE ARCHIVIO DI MEMORIA...';

  @override
  String get loadingPhase2 => 'AGGIORNAMENTO MOTORE DI RIPRODUZIONE...';

  @override
  String get loadingPhase3 => 'ESTRAZIONE DEI DATI ACUSTICI...';

  @override
  String get loadingPhase4 => 'OTTIMIZZAZIONE MEMORIA DI RIPRODUZIONE...';

  @override
  String get lyrics => 'Testo';

  @override
  String get lyricsAlignment => 'Allineamento testo';

  @override
  String get lyricsAlignmentDesc =>
      'Allinea la posizione del testo per lo scorrimento dei testi';

  @override
  String get lyricsDarkness => 'Luminosità sfondo testi';

  @override
  String get lyricsDarknessDesc =>
      'Regola l\'oscurità del livello di sfondo per la schermata dei testi';

  @override
  String get lyricsProvider => 'Fornitore dei testi';

  @override
  String get lyricsProviderDesc =>
      'Testi online ottenuti da lrclib.net (LRCLIB)';

  @override
  String get maintainersAndDesigners => 'Sviluppatori e designer';

  @override
  String get manageAudioFocus => 'Gestisci focus audio';

  @override
  String get manageAudioFocusDesc =>
      'Richiede e risponde alle variazioni del focus audio di sistema';

  @override
  String get manageAudioFocusTitle => 'Gestisci focus audio';

  @override
  String get manageLanguageAndFocus =>
      'Gestisci le preferenze della lingua e lo stato di pausa sulle chiamate';

  @override
  String get audioFocusGetFocus => 'Ottieni focus';

  @override
  String get audioFocusGetFocusDesc =>
      'Richiede il focus audio quando inizia la riproduzione.';

  @override
  String get audioFocusReleaseFocus => 'Rilascia focus';

  @override
  String get audioFocusReleaseFocusDesc =>
      'Rilascia il focus audio quando la riproduzione viene messa in pausa o interrotta.';

  @override
  String get audioFocusStopOnOtherSession =>
      'Interrompi la musica con un\'altra sessione musicale';

  @override
  String get audioFocusStopOnOtherSessionDesc =>
      'Metti in pausa la riproduzione quando un\'altra app inizia a riprodurre audio.';

  @override
  String get audioFocusRestartOnGain =>
      'Riprendi la musica al recupero del focus';

  @override
  String get audioFocusRestartOnGainDesc =>
      'Riprendi automaticamente la riproduzione quando il focus audio ritorna, solo se la riproduzione era stata interrotta dalla perdita del focus.';

  @override
  String get pauseOnDuckTitle => 'Pausa in caso di attenuazione';

  @override
  String get pauseOnDuckDesc =>
      'Metti in pausa la riproduzione invece di abbassare il volume quando un\'altra app riproduce un suono breve (es. notifiche, indicazioni di navigazione).';

  @override
  String get resumeOnBluetoothConnectTitle =>
      'Riprendi alla connessione Bluetooth';

  @override
  String get resumeOnBluetoothConnectDesc =>
      'Riprendi automaticamente la riproduzione quando un dispositivo audio Bluetooth (cuffie, kit auto) si riconnette.';

  @override
  String get manualCrossfadeDuration => 'Durata dissolvenza incrociata manuale';

  @override
  String get manualCrossfadeDurationDesc =>
      'Durata sovrapposizione durante il cambio traccia manuale';

  @override
  String get matchingLyrics => 'TESTI CORRISPONDENTI';

  @override
  String get metadataDetails => 'Dettagli metadati';

  @override
  String get mostPlayed => 'Più riprodotti';

  @override
  String get musicAudioAccess => 'ACCESSO A MUSICA E AUDIO';

  @override
  String get musicDarkness => 'Luminosità sfondo Player';

  @override
  String get musicDarknessDesc =>
      'Regola l\'oscurità del livello di sfondo per la schermata del Player';

  @override
  String get musicLibrary => 'Libreria musicale';

  @override
  String get muteOrPauseCalls =>
      'Silenzia o metti in pausa durante le telefonate e altre attività audio';

  @override
  String get newPlaylist => 'Nuova Playlist';

  @override
  String get newTitle => 'Nuovo titolo';

  @override
  String get nextUp => 'A seguire';

  @override
  String get noAlbumsFound => 'Nessun album trovato';

  @override
  String get noArtistsFound => 'Nessun artista trovato';

  @override
  String get noFavoritesYet => 'Nessun preferito';

  @override
  String get noHistoryYet => 'Nessuna cronologia';

  @override
  String get noLyrics => 'Nessun testo trovato';

  @override
  String get noMusicDetected => 'NESSUN BRANO RILEVATO';

  @override
  String get noPlaylistsCreated => 'Nessuna playlist creata.';

  @override
  String get noPlaylistsYet => 'Nessuna playlist';

  @override
  String get noResultsFound => 'Nessun risultato trovato';

  @override
  String get noSongsFound => 'Nessun brano trovato';

  @override
  String get notificationAccess => 'ACCESSO ALLE NOTIFICHE';

  @override
  String get nowPlaying => 'In riproduzione';

  @override
  String get performanceOptimizerDashboard =>
      'Dashboard Ottimizzazione Prestazioni';

  @override
  String get performanceOptimizerDashboardDesc =>
      'Mostra le statistiche dell\'ottimizzatore in tempo reale';

  @override
  String get permanentFocusChangePause => 'Pausa su perdita focus permanente';

  @override
  String get permanentFocusChangePauseDesc =>
      'Sospende la riproduzione in caso di perdita definitiva del focus audio';

  @override
  String get plainTimestamps => 'Marcatori temporali semplici';

  @override
  String get play => 'Riproduci';

  @override
  String get playAll => 'Riproduci tutto';

  @override
  String get playbackAudio => 'Riproduzione e lingua';

  @override
  String get playlists => 'Playlists';

  @override
  String get playNext => 'Riproduci dopo';

  @override
  String get playQueue => 'Coda di riproduzione';

  @override
  String get pressBackExit => 'Premi di nuovo indietro per uscire';

  @override
  String get privacySafety => 'Privacy e sicurezza';

  @override
  String get privacySafetyDesc =>
      '100% privato e offline. I tuoi brani, la cronologia di riproduzione, i preferiti e la configurazione rimangono esclusivamente all\'interno di un database Isar sicuro sul tuo dispositivo. Non tracciamo, raccogliamo o condividiamo le tue preferenze o i dati di utilizzo.';

  @override
  String get pureBlackOled => 'Nero puro (OLED)';

  @override
  String get pureBlackOledDesc => 'Usa nero assoluto per gli sfondi';

  @override
  String get queue => 'Coda';

  @override
  String get queueIsEmpty => 'La coda è vuota';

  @override
  String get quickPicks => 'Selezione rapida';

  @override
  String get quickPicksRowDesc => 'La griglia dei tuoi brani più riprodotti';

  @override
  String get readyToScan => 'Pronto per la scansione';

  @override
  String get recentlyAddedSongsRowDesc =>
      'Un elenco dei tuoi ultimi file importati';

  @override
  String get recentlyPlayed => 'Riprodotti di recente';

  @override
  String get recentPlayed => 'Brani riprodotti di recente';

  @override
  String get recentRowDesc =>
      'Elenco orizzontale dei brani riprodotti di recente';

  @override
  String get removedFromPlaylist => 'Rimosso dalla Playlist';

  @override
  String get removeFromFavorites => 'Rimuovi dai preferiti';

  @override
  String get removeFromPlaylist => 'Rimuovi dalla Playlist';

  @override
  String get rename => 'Rinomina';

  @override
  String get renameFile => 'Rinomina File';

  @override
  String get renamePlaylist => 'Rinomina Playlist';

  @override
  String get renameSong => 'Rinomina brano';

  @override
  String get reorderDashboardSections => 'Riordina sezioni pannello principale';

  @override
  String get reorderDashboardSectionsDesc =>
      'Trascina e rilascia per impostare l\'ordine preferito del pannello principale';

  @override
  String get includeOtherDeviceAudioTitle =>
      'Includi altri audio del dispositivo';

  @override
  String get includeOtherDeviceAudioDesc =>
      'Scansiona suonerie, notifiche, allarmi e audio di WhatsApp e Telegram';

  @override
  String get rescanLibrary => 'Nuova scansione libreria';

  @override
  String get rescanStorage => 'RAGGIUNGI E SCANSIONA ARCHIVIO';

  @override
  String get reset => 'Ripristina';

  @override
  String get resetLibrary => 'Reimposta e riscansiona';

  @override
  String get resetLibraryConfirm =>
      'Questo cancellerà tutti i brani, gli album e gli artisti ed eseguirà una nuova scansione completa delle tue cartelle.';

  @override
  String get resetLibraryConfirmNew =>
      'Questo rimuoverà tutti i brani dalla libreria. I file musicali fisici non verranno eliminati.';

  @override
  String get resetLibraryDesc =>
      'Rimuovi tutti i brani dalla libreria indicizzata';

  @override
  String get resumeAfterCallDesc =>
      'Riprende la riproduzione automaticamente al termine della chiamata (se sospesa da chiamata)';

  @override
  String get resumeAfterCallTitle => 'Riprendi dopo chiamata';

  @override
  String get resumeOnStartDesc =>
      'Riprende la riproduzione automaticamente all\'avvio di Looper Player';

  @override
  String get resumeOnStartTitle => 'Riprendi all\'avvio';

  @override
  String get persistQueueTitle => 'Mantieni ultima coda';

  @override
  String get persistQueueDesc =>
      'Salva l\'ultimo brano e la coda al riavvio dell\'applicazione';

  @override
  String get keepSongProgressTitle => 'Mantieni il progresso del brano';

  @override
  String get keepSongProgressDesc =>
      'Ricorda separatamente la posizione di riproduzione di ogni brano. Passa a un altro brano a metà e torna più tardi — anche dopo aver ascoltato altri brani nel frattempo — e riprenderà esattamente da dove l\'avevi lasciato invece di ricominciare da capo.';

  @override
  String get right => 'Destra';

  @override
  String scanCompleteSongsDetected(int count) {
    return 'SCANSIONE COMPLETATA: $count BRANI TROVATI!';
  }

  @override
  String get scanForMusic => 'SCANSIONA MUSICA';

  @override
  String get scanIndexLocalDesc =>
      'Scansiona e indicizza i file musicali locali';

  @override
  String get scanLibrary => 'Scansiona libreria';

  @override
  String get scanningInBackground => 'Scansione in background...';

  @override
  String get scanningLibrary => 'Scansione della libreria...';

  @override
  String get scanningStorage => 'SCANSIONE ARCHIVIO IN CORSO...';

  @override
  String get scanningStorageDesc =>
      'Ricerca dei brani audio nelle cartelle. Attendi...';

  @override
  String get search => 'Cerca';

  @override
  String get searchLibraryHint => 'Cerca nell\'intera libreria';

  @override
  String get searchSongsHint => 'Cerca brani';

  @override
  String get seekFadeDuration => 'Durata dissolvenza sul seek';

  @override
  String get seekFadeDurationDesc =>
      'Durata dell\'effetto di dissolvenza durante il posizionamento';

  @override
  String get selectAppLanguage => 'Seleziona la lingua dell\'applicazione';

  @override
  String get selectCustomColor => 'Seleziona colore personalizzato';

  @override
  String get selectCustomFolder => 'SELEZIONA CARTELLA PERSONALIZZATA';

  @override
  String get selectFolderIndex =>
      'Seleziona una cartella per indicizzare i file musicali';

  @override
  String get selectSpecificFolder => 'SELEZIONA CARTELLA SPECIFICA';

  @override
  String get settings => 'Impostazioni';

  @override
  String get share => 'Condividi';

  @override
  String get shareFile => 'Condividi file';

  @override
  String get showAlbumsRow => 'Mostra riga Album';

  @override
  String get showAlbumsRowDesc =>
      'Mostra un elenco orizzontale di album nella schermata Home';

  @override
  String get showArtistsRow => 'Mostra riga Artisti';

  @override
  String get showArtistsRowDesc =>
      'Mostra un elenco orizzontale di artisti nella schermata Home';

  @override
  String get showGenresRow => 'Mostra riga Generi';

  @override
  String get showGenresRowDesc =>
      'Mostra un elenco orizzontale di generi nella schermata Home';

  @override
  String get showLess => 'Mostra meno';

  @override
  String get showMore => 'Mostra altro';

  @override
  String get showQualityBadge => 'Mostra badge qualità';

  @override
  String get showQualityBadgeDesc =>
      'Mostra le informazioni sulla qualità audio nella schermata di riproduzione';

  @override
  String get showRecentRow => 'Mostra riga Riprodotti di recente';

  @override
  String get showRecentRowDesc =>
      'Mostra un elenco orizzontale dei brani riprodotti di recente nella schermata Home';

  @override
  String get silenceBetweenTracksDesc =>
      'Aggiunge un intervallo di silenzio tra i brani (0ms per riproduzione continua)';

  @override
  String get silenceBetweenTracksTitle => 'Silenzio tra le tracce';

  @override
  String get songDeletedDbOnly =>
      'Brano rimosso dalla libreria (file fisico in sola lettura)';

  @override
  String get songDeletedSuccess => 'Brano eliminato con successo';

  @override
  String get songDeleteFailed => 'Impossibile eliminare il brano';

  @override
  String get songDetails => 'Dettagli brano';

  @override
  String get songDetailsAndFrequency => 'Dettagli brano e frequenza';

  @override
  String get songRenamedDbOnly =>
      'Brano rinominato nella libreria (file fisico in sola lettura)';

  @override
  String get songRenamedSuccess => 'Brano rinominato con successo';

  @override
  String get songRenameFailed => 'Impossibile rinominare il brano';

  @override
  String get songs => 'Brani';

  @override
  String get songsDarkness => 'Luminosità sfondo Brani';

  @override
  String get songsDarknessDesc =>
      'Regola l\'oscurità del livello di sfondo per la schermata dei Brani';

  @override
  String get sortBy => 'Ordina per';

  @override
  String get sortOrder => 'Ordinamento';

  @override
  String get sourceCode => 'Codice sorgente';

  @override
  String get stopServiceOnAppDismissal =>
      'Interrompi servizio alla chiusura dell\'app';

  @override
  String get stopServiceOnAppDismissalDesc =>
      'Arresta il servizio in background e chiude l\'app quando viene rimossa dalle recenti';

  @override
  String get storagePermissionRequired =>
      'I permessi di archiviazione sono richiesti per scansionare la memoria del dispositivo.';

  @override
  String get syncLyricsOffline => 'Sincronizza testi (Offline)';

  @override
  String get systemDefault => 'Predefinito di sistema';

  @override
  String get systemPermissionChecklist => 'PERMESSI DI SISTEMA RICHIESTI';

  @override
  String get technicalInfoFrequency => 'Info tecniche e frequenza';

  @override
  String get theme => 'Tema';

  @override
  String get title => 'Titolo';

  @override
  String get todayMixForYou => 'Mix di oggi per te';

  @override
  String get toggleFavorite => 'Aggiungi/Rimuovi preferito';

  @override
  String get shuffleTitle => 'Riproduzione casuale';

  @override
  String get shuffleDisabledDesc =>
      'Riproduci i brani nel loro ordine originale in coda. Disattivando la riproduzione casuale, il brano attuale continua a suonare e il resto della coda torna al suo ordine originale, senza influire sulla riproduzione o sulla cronologia.';

  @override
  String get shuffleEnabledDesc =>
      'Mescola i brani rimanenti mantenendo invariato quello attuale. L\'ordine casuale generato resta invariato finché la coda non cambia o non viene richiesta una nuova riproduzione casuale, evitando brani ripetuti o saltati.';

  @override
  String get shuffleSwitchingDesc =>
      'Attivare o disattivare la riproduzione casuale non riavvia mai il brano attuale. Cambia solo l\'ordine dei brani successivi: casuale se attiva, ripristinato all\'ordine originale della coda se disattivata.';

  @override
  String get topResult => 'Risultato principale';

  @override
  String get transferMusicFiles => 'TRASFERISCI FILE MUSICALI';

  @override
  String get turnOffBlursOptimize =>
      'Disattiva sfocature complesse per ottimizzare le prestazioni';

  @override
  String get unknown => 'Sconosciuto';

  @override
  String get unknownAlbum => 'Album sconosciuto';

  @override
  String get unknownArtist => 'Artista sconosciuto';

  @override
  String get updateLibraryIndexing =>
      'Aggiorna l\'indicizzazione dei file della libreria';

  @override
  String get useAbsoluteBlackBg => 'Usa nero assoluto per gli sfondi';

  @override
  String get useStaticTextTimestamps =>
      'Usa testo statico invece dell\'animazione per il tempo di riproduzione';

  @override
  String get fluidPlayer => 'Player fluido';

  @override
  String get fluidPlayerDesc =>
      'Trascina il mini player verso l\'alto per trasformarlo nel player completo';

  @override
  String get viewAll => 'Vedi tutti';

  @override
  String get visitOfficialRepository =>
      'Visita il repository ufficiale su GitHub';

  @override
  String get welcomeAboutDesc =>
      'Looper Player è un sistema Music-OS di nuova generazione per la riproduzione audio offline ad alta fedeltà. Include testi sincronizzati in tempo reale, gestione avanzata delle sessioni audio, temi dinamici adattivi e supporto per librerie musicali multi-formato. Completamente ottimizzato per la massima efficienza della batteria.';

  @override
  String get welcomeAllFilesDesc =>
      'Consigliato per la scansione avanzata in directory non standard (Download, Telegram, cartelle personalizzate).';

  @override
  String get welcomeInstructionConnectDesc =>
      'Collega il tuo telefono o dispositivo al computer usando un cavo dati USB standard.';

  @override
  String get welcomeInstructionDownloadDesc =>
      'In alternativa, scarica i file direttamente sul dispositivo usando un browser web o altre utilità di download.';

  @override
  String get welcomeInstructionTransferDesc =>
      'Copia i tuoi file musicali offline (supportati .mp3, .flac, .m4a, .wav) direttamente nella cartella \'Music\' o \'Download\' del tuo dispositivo.';

  @override
  String get welcomeMusicAudioDesc =>
      'Richiesto per trovare e riprodurre brani audio offline presenti nella memoria del tuo dispositivo.';

  @override
  String get welcomeNoSongsDesc =>
      'Non siamo riusciti a trovare nessun file audio supportato (MP3, FLAC, WAV, M4A, OGG) nella memoria del tuo dispositivo.';

  @override
  String get welcomeNotificationDesc =>
      'Richiesto per mostrare i controlli di riproduzione e le notifiche attive nella barra di sistema.';

  @override
  String get welcomeScanningFoldersDesc =>
      'Scansione di tutte le cartelle e sottocartelle per trovare file audio.';

  @override
  String get whyInternetUsed => 'Perché usiamo Internet';

  @override
  String get whyInternetUsedDesc =>
      '• Sincronizzazione dei testi: Utilizzato esclusivamente per cercare e scaricare testi sincronizzati (in formato LRC) da database online. Nessun dato personale, impostazione o file multimediale viene caricato o condiviso.';

  @override
  String get whyPermissionsUsed => 'Perché usiamo i permessi';

  @override
  String get whyPermissionsUsedDesc =>
      '• Accesso all\'archivio / File multimediali: Richiesto per scansionare, leggere e indicizzare i brani musicali locali.\n• Notifiche: Richiesto per mostrare i widget dei controlli di riproduzione nella barra delle notifiche.';

  @override
  String get willPlayNext => 'Verrà riprodotto dopo';

  @override
  String get year => 'Anno';

  @override
  String get supportUs => 'Supportaci';

  @override
  String get supportUsDesc =>
      'Aiuta a mantener Looper Player attivo e open source';

  @override
  String get supportDevelopment => 'Supporta lo sviluppo';

  @override
  String get supportDevelopmentDesc =>
      'Looper Player è gratuito al 100% e open source. Se ti piace usarlo, considera di supportare il creatore con una donazione. Ogni contributo aiuta a mantenere il progetto attivo!';

  @override
  String get useCustomFont => 'Usa carattere personalizzato';

  @override
  String get useCustomFontDesc =>
      'Usa carattere e spessore personalizzati per la vista dei testi sincronizzati';

  @override
  String get selectFontFamily => 'Seleziona famiglia caratteri';

  @override
  String activeFont(String fontName) {
    return 'Carattere attivo: $fontName';
  }

  @override
  String get fontWeightAdjustment => 'Regolazione spessore carattere';

  @override
  String get currentWeight => 'Spessore attuale';

  @override
  String get useCustomFontLyrics => 'Carattere personalizzato per il testo';

  @override
  String get useCustomFontLyricsDesc =>
      'Usa carattere e spessore personalizzati per la vista dei testi sincronizzati';

  @override
  String get lyricsFontFamily => 'Famiglia caratteri testo';

  @override
  String activeLyricsFont(String fontName) {
    return 'Carattere testo attivo: $fontName';
  }

  @override
  String get lyricsFontWeightAdjustment => 'Regolazione spessore testo';

  @override
  String get giveStarOnGithub => 'Lascia una stella su GitHub';

  @override
  String get supportProjectLove =>
      'Supporta il progetto e mostra il tuo apprezzamento!';

  @override
  String get sortAlphabeticalAZ => 'Alfabetico (A-Z)';

  @override
  String get sortAlphabeticalZA => 'Alfabetico (Z-A)';

  @override
  String get sortRecentlyAdded => 'Aggiunto di recente';

  @override
  String get sortOldestAdded => 'Meno recente';

  @override
  String get sortYearNewest => 'Anno (Più recente)';

  @override
  String get sortYearOldest => 'Anno (Meno recente)';

  @override
  String get sortMostSongs => 'Più canzoni';

  @override
  String get sortLeastSongs => 'Meno canzoni';

  @override
  String get sortDefault => 'Predefinito';

  @override
  String get sortArtistAsc => 'Artista (A-Z)';

  @override
  String get sortAlbumAsc => 'Album (A-Z)';

  @override
  String get sortDuration => 'Durata';

  @override
  String get myAlbums => 'I miei album';

  @override
  String get featuredArtists => 'Artisti in evidenza';

  @override
  String get noSongPlaying => 'Nessun brano in riproduzione';

  @override
  String get nextLabel => 'Successivo';

  @override
  String get previousLabel => 'Precedente';

  @override
  String get resync => 'Ri-sincronizza';

  @override
  String get equalizer => 'Equalizzatore';

  @override
  String get presets => 'PRESET';

  @override
  String get preAmpGain => 'Guadagno preamplificatore';

  @override
  String get outputVolume => 'Volume di uscita';

  @override
  String get customFilterHint =>
      'Digita direttamente i parametri del filtro audio libavfilter personalizzato (es. volume=3dB, aecho=0.8:0.88:60:0.4):';

  @override
  String get flowGlobalActions => 'Flusso e azioni globali';

  @override
  String get equalizerModeLabel => 'Modalità equalizzatore:';

  @override
  String get currentGainsAppliedGlobal =>
      'Guadagni attuali applicati come impostazioni globali predefinite.';

  @override
  String get applyToGlobal => 'Applica al globale';

  @override
  String get songSpecificResetGlobal =>
      'Impostazioni specifiche del brano ripristinate al valore globale predefinito.';

  @override
  String get resetToGlobal => 'Ripristina al globale';

  @override
  String get resetAllSongsEq => 'Reimposta EQ di tutti i brani';

  @override
  String get resetAllSongsEqConfirm =>
      'Vuoi davvero cancellare le impostazioni personalizzate dell\'equalizzatore per tutti i brani della tua libreria?';

  @override
  String get allSongsEqDataReset =>
      'Tutti i dati dell\'equalizzatore specifici dei brani sono stati reimpostati.';

  @override
  String get resetAllSongsEqData => 'Reimposta dati EQ di tutti i brani';

  @override
  String get equalizerTargetMode =>
      'Modalità di destinazione dell\'equalizzatore';

  @override
  String get equalizerTargetModeDesc =>
      'Scegli come vengono applicate le impostazioni dell\'equalizzatore nella tua libreria musicale.';

  @override
  String get globalMode => 'Modalità globale';

  @override
  String get globalModeDesc =>
      'Applica gli effetti a tutti i brani in modo universale. Le impostazioni dell\'equalizzatore restano invariate al cambio di brano.';

  @override
  String get songSpecificMode => 'Modalità per brano';

  @override
  String get songSpecificModeDesc =>
      'Salva le impostazioni personalizzate solo per il brano attuale. Il brano successivo utilizza per impostazione predefinita un equalizzatore piatto/disattivato, a meno che non abbia un proprio profilo.';

  @override
  String get viewDeviceAudioCapabilities =>
      'Visualizza capacità audio del dispositivo';

  @override
  String get deviceAudioCapabilities => 'Capacità audio del dispositivo';

  @override
  String get noPlaybackActiveCapabilities =>
      'Nessuna riproduzione attiva o informazioni sulle capacità non disponibili.';

  @override
  String get changeLyricsProvider => 'Cambia fornitore dei testi';

  @override
  String get autoFallbackProviders => 'Fornitori di riserva automatici';

  @override
  String get autoFallbackProvidersDesc =>
      'Prova automaticamente gli altri fornitori se il principale non ha i testi';

  @override
  String get ambientColorBackground => 'Sfondo a colori ambientali';

  @override
  String get ambientColorBackgroundDesc =>
      'Sfumature ambientali morbide e sottili ricavate dalla copertina del brano';

  @override
  String get exportLyricsLrc => 'Esporta testi (file .lrc)';

  @override
  String get saveLyricsToDevice =>
      'Salva i testi attuali sull\'archivio del dispositivo';

  @override
  String get noLyricsToExport => 'Nessun testo disponibile da esportare';

  @override
  String get useCustomLyricsLrc => 'Usa testi personalizzati (file LRC)';

  @override
  String get selectLocalLrcFile =>
      'Seleziona un file .lrc o .txt locale per questo brano';

  @override
  String get customLyricsAppliedSuccess =>
      'Testi personalizzati applicati correttamente!';

  @override
  String get noRecentlyPlayedTracks => 'Nessun brano riprodotto di recente';

  @override
  String get close => 'Chiudi';

  @override
  String get audioQualityAnalysis => 'Analisi qualità audio';

  @override
  String get audioQualityAnalysisDesc =>
      'Esegui un\'analisi spettrale e del formato audio approfondita';

  @override
  String get audioStreamDetails => 'Dettagli flusso audio';

  @override
  String get perChannelMetrics => 'Metriche per canale';

  @override
  String get sleepTimer => 'Timer di spegnimento';

  @override
  String get stopByTime => 'ARRESTA PER TEMPO';

  @override
  String get start => 'Avvia';

  @override
  String get stopBySongCount => 'ARRESTA PER NUMERO DI BRANI';

  @override
  String get cancelSleepTimer => 'Annulla timer di spegnimento';

  @override
  String get nowPlayingAllCaps => 'IN RIPRODUZIONE';

  @override
  String get settingsAndBackups => 'Impostazioni e backup';

  @override
  String get managePreferencesLibraryData =>
      'Gestisci preferenze e dati della libreria';

  @override
  String get logsClearedSuccess => 'Log cancellati correttamente';

  @override
  String get editSongInfo => 'Modifica informazioni brano';

  @override
  String get editAlbumInfo => 'Modifica informazioni album';

  @override
  String get tapFieldToEdit => 'Tocca un campo per modificarlo';

  @override
  String get alwaysBlurSheets => 'Sfoca sempre i fogli';

  @override
  String get alwaysBlurSheetsDesc =>
      'Sfoca i fogli popup anche quando il tema dinamico è disattivato';

  @override
  String get removeArtwork => 'Rimuovi copertina';

  @override
  String get resetArtworkToDefault => 'Ripristina predefinito';

  @override
  String get artworkResetToDefault =>
      'Copertina ripristinata a quella predefinita';

  @override
  String get noEmbeddedArtworkFound =>
      'Nessuna copertina incorporata trovata per questo album';

  @override
  String get saveChangesBtn => 'Salva modifiche';

  @override
  String get enterFolderPathManually =>
      'Inserisci il percorso della cartella manualmente';

  @override
  String get folderPickerManualHint =>
      'Se il selettore di directory di sistema non si apre, digita o incolla qui sotto il percorso completo della directory:';

  @override
  String get noSupportedSongsFoundFolder =>
      'Nessun brano supportato trovato nella cartella selezionata';

  @override
  String get add => 'Aggiungi';

  @override
  String get folderPickerClosed => 'Selettore cartelle chiuso';

  @override
  String get buyMeCoffee => 'Offrimi un caffè';

  @override
  String get typeToSearchSettings => 'Digita per cercare nelle impostazioni…';

  @override
  String get maintainersLabel => 'Manutentori';

  @override
  String get personBehindLooperPlayer => 'La persona dietro LooperPlayer';

  @override
  String get blurredArtworkForLyrics => 'Copertina sfocata per i testi';

  @override
  String get blurredArtworkForLyricsDesc =>
      'Mostra la copertina dell\'album sfocata come sfondo invece di una sfumatura dinamica/statica';

  @override
  String get lyricsFontWeight => 'Spessore del carattere dei testi';

  @override
  String get openSourceLicenses => 'Licenze open source';

  @override
  String get openSourceLicensesDesc =>
      'Librerie di terze parti utilizzate in questa app';

  @override
  String get done => 'Fatto';

  @override
  String get lyricsNotAvailable => 'Testo non disponibile.';

  @override
  String get lyricsNotAvailableHint =>
      'Importa un file .lrc o .txt per aggiungere il testo a questo brano';

  @override
  String get importLyricsFile => 'Importa file dei testi';

  @override
  String get approximatedSyncNoWordTimings =>
      'Sincronizzazione approssimata (senza tempi per parola)';

  @override
  String get lyricsSyncHelp => 'Guida alla sincronizzazione dei testi';

  @override
  String get simpleModeLabel => 'Modalità semplice';

  @override
  String get advancedModeLabel => 'Modalità avanzata';

  @override
  String get tips => 'Suggerimenti';

  @override
  String get gotIt => 'Capito';

  @override
  String get lyricsSyncStudio => 'Studio di sincronizzazione testi';

  @override
  String get lyricsTextLabel => 'Testo dei testi';

  @override
  String get lyricsTextHelperDesc =>
      'Una riga per ogni verso. Gli strumenti di sincronizzazione qui sotto associano i timestamp a queste righe.';

  @override
  String get quickSync => 'Sincronizzazione rapida';

  @override
  String get autoAdvanceAfterStamping =>
      'Avanza automaticamente dopo la marcatura';

  @override
  String get advancedSync => 'Sincronizzazione avanzata';

  @override
  String get useCurrentTime => 'Usa l\'orario attuale';

  @override
  String get playbackAssist => 'Assistente di riproduzione';

  @override
  String get timeShift => 'Spostamento temporale';

  @override
  String get timeShiftDesc =>
      'Sposta insieme, in avanti o indietro, tutti i testi con timestamp.';

  @override
  String get lyricsSaveLrcExplain =>
      'Il salvataggio crea, se possibile, un file \".lrc\" accessorio accanto all\'audio del brano e lo salva anche nel database locale del player. Le righe senza timestamp verranno interpolate automaticamente.';

  @override
  String get back => 'Indietro';

  @override
  String get appSettingsLabel => 'Impostazioni app';

  @override
  String get backupsAndLogs => 'Backup e registri';

  @override
  String get backupsAndLogsDesc =>
      'Esporta, importa e gestisci i dati dell\'app';

  @override
  String get exportBackupJson => 'Esporta backup (JSON)';

  @override
  String get exportBackupJsonDesc =>
      'Salva i brani preferiti e le playlist in un file JSON che puoi conservare o condividere. Non è incluso nient\'altro.';

  @override
  String get importBackupJson => 'Importa backup (JSON)';

  @override
  String get importBackupJsonDesc =>
      'Unisce i brani preferiti e le playlist di un file di backup con la tua libreria. I dati esistenti non vengono mai sovrascritti né rimossi.';

  @override
  String get exportDiagnosticsLogs => 'Esporta log diagnostici';

  @override
  String get exportDiagnosticsLogsDesc =>
      'Condivide il file di registro diagnostico dell\'app per poterlo esaminare in caso di problemi.';

  @override
  String get clearDiagnosticsLogs => 'Cancella log diagnostici';

  @override
  String get clearDiagnosticsLogsDesc =>
      'Cancella definitivamente il file di registro diagnostico salvato su questo dispositivo. Questa azione non può essere annullata.';

  @override
  String get lyricsPlainTextOrLrc => 'Testi (testo semplice o LRC)';

  @override
  String get syncModeLine => 'RIGA';

  @override
  String get syncModeWord => 'PAROLA';

  @override
  String get syncModeChar => 'CARATTERE';

  @override
  String get enterManually => 'Inserisci manualmente';

  @override
  String get rawFilterParametersHint => 'Parametri filtro grezzi...';

  @override
  String get searchSettingsHint => 'Cerca nelle impostazioni...';

  @override
  String get repeatTooltip => 'Ripeti';

  @override
  String get favoriteTooltip => 'Preferito';

  @override
  String get instructionsTooltip => 'Istruzioni';

  @override
  String get pasteLyricsHint => 'Incolla o digita qui il testo del brano';

  @override
  String get timestampMmSsHint => 'Timestamp (mm:ss.xx)';

  @override
  String get nowLabel => 'Ora';

  @override
  String get playlistNameHint => 'Nome playlist';

  @override
  String get songInfoUpdated => 'Informazioni del brano aggiornate!';

  @override
  String get albumInfoUpdated => 'Informazioni album aggiornate!';

  @override
  String get failedToSaveChanges => 'Impossibile salvare le modifiche.';

  @override
  String sleepTimerStoppingIn(String time) {
    return 'Attivo: si ferma tra $time';
  }

  @override
  String sleepTimerStoppingAfter(String time) {
    return 'Attivo: si ferma dopo $time';
  }

  @override
  String get selectWhenToPause =>
      'Seleziona quando mettere in pausa la riproduzione musicale';

  @override
  String get selectAvatars => 'Seleziona avatar';

  @override
  String get selectAvatarsDesc =>
      'Scegli l\'avatar mostrato nella schermata Home';

  @override
  String get dynamicAvatarColor => 'Colore dinamico avatar';

  @override
  String get dynamicAvatarColorDesc =>
      'Abbina il colore dell\'avatar al tema attuale';

  @override
  String enrichingSongs(int count) {
    return 'Arricchimento di $count brani in corso…';
  }

  @override
  String get noListeningHistoryYet => 'Ancora nessuna cronologia di ascolto';

  @override
  String get noListeningHistoryYetDesc =>
      'Ascolta qualche brano e il tuo resoconto personale — brani, artisti, album e generi preferiti — prenderà vita qui.';

  @override
  String get looperAnalyze => 'Looper Analyze';

  @override
  String get totalPlays => 'Ascolti totali';

  @override
  String get listeningTime => 'Tempo di ascolto';

  @override
  String get currentStreakDays => 'Serie attuale (giorni)';

  @override
  String get longestStreakDays => 'Serie più lunga (giorni)';

  @override
  String analyzePlaysAndSongs(int plays, int songs) {
    return '$plays ascolti • $songs brani';
  }

  @override
  String get dayPartMorningShort => 'Matt.';

  @override
  String get dayPartAfternoonShort => 'Pom.';

  @override
  String get dayPartEveningShort => 'Sera';

  @override
  String get dayPartNightShort => 'Notte';

  @override
  String get activityPattern => 'Andamento dell\'attività';

  @override
  String get whenYouListenMost => 'Quando ascolti di più';

  @override
  String get genreBreakdown => 'Ripartizione per genere';

  @override
  String get otherGenre => 'Altro';

  @override
  String get topAlbums => 'Album più ascoltati';

  @override
  String get topArtists => 'Artisti più ascoltati';

  @override
  String get topSongs => 'Brani più ascoltati';

  @override
  String playsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ascolti',
      one: '1 ascolto',
    );
    return '$_temp0';
  }

  @override
  String songsPlayedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count brani ascoltati',
      one: '1 brano ascoltato',
    );
    return '$_temp0';
  }

  @override
  String get listeningTrend => 'Andamento degli ascolti';

  @override
  String get last30Days => 'Ultimi 30 giorni';

  @override
  String errorWithDetails(String error) {
    return 'Errore: $error';
  }

  @override
  String get selectAll => 'Seleziona tutto';

  @override
  String get playlist => 'Playlist';

  @override
  String songsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count brani',
      one: '1 brano',
    );
    return '$_temp0';
  }

  @override
  String get recentSearches => 'Ricerche recenti';

  @override
  String get lyricsSourceLocalFile => 'File locale';

  @override
  String get lyricsSourceEmbedded => 'Metadati incorporati';

  @override
  String lyricsProvidedBy(String source) {
    return 'Testo fornito da $source';
  }

  @override
  String failedToImportLyrics(String error) {
    return 'Impossibile importare il testo: $error';
  }

  @override
  String get lyricsEditorLines => 'Righe';

  @override
  String get lyricsEditorStamped => 'Marcate';

  @override
  String lyricsEditorLineNumber(int number) {
    return 'Riga $number';
  }

  @override
  String get lyricsEditorEmptyLine => '(Riga vuota)';

  @override
  String get lyricsEditorNotStamped => 'Non ancora marcata';

  @override
  String get pause => 'Pausa';

  @override
  String get lyricsEditorAddLineFirst =>
      'Aggiungi prima almeno una riga di testo.';

  @override
  String get lyricsEditorSavedWithSidecar =>
      'Testo salvato nel database e accanto al file del brano.';

  @override
  String get lyricsEditorSavedDbOnly =>
      'Testo salvato nel database del lettore.';

  @override
  String get lyricsEditorSaveFailed => 'Impossibile salvare il testo.';

  @override
  String get saving => 'Salvataggio...';

  @override
  String get saveLrc => 'Salva LRC';

  @override
  String lyricsEditorSelectedLine(int index, int total) {
    return 'Riga selezionata $index di $total';
  }

  @override
  String get lyricsEditorPickLine => 'Scegli una riga dall\'elenco qui sotto.';

  @override
  String get stampAndNext => 'Marca e avanti';

  @override
  String get stampNow => 'Marca ora';

  @override
  String get lyricsEditorSimpleSteps =>
      '1. Incolla o scrivi una riga di testo per ogni riga.\n2. Avvia il brano.\n3. Seleziona la riga corrente.\n4. Tocca \"Marca e avanti\" quando senti quella riga.\n5. Salva quando hai finito.';

  @override
  String get lyricsEditorAdvancedSteps =>
      '1. Modifica direttamente il tempo di ogni riga.\n2. Usa \"Usa l\'orario attuale\" per acquisire il tempo di riproduzione.\n3. Usa i controlli di spostamento per muovere insieme tutte le righe marcate.\n4. Salva per generare il file `.lrc` finale.';

  @override
  String get lyricsEditorTipsText =>
      '- Se alcune righe non sono marcate, il motore di Flick ne calcola i tempi automaticamente.\n- Il salvataggio avviene accanto al brano quando possibile, altrimenti viene memorizzata una copia collegata nel database.';

  @override
  String fileNotFoundOrInaccessible(String title) {
    return 'File non trovato o non accessibile: $title';
  }

  @override
  String playbackFailedCorrupted(String title) {
    return 'Riproduzione non riuscita: impossibile caricare o riprodurre \"$title\". Verifica che il file non sia danneggiato.';
  }

  @override
  String shareSongText(String title) {
    return 'Ascolta questo brano: $title';
  }

  @override
  String shareSongsText(int count) {
    return 'Ascolta questi $count brani';
  }

  @override
  String noSettingsFoundFor(String query) {
    return 'Nessuna impostazione trovata per \"$query\"';
  }

  @override
  String get chooseQuickAccentColors => 'Scegli colori d\'accento rapidi';

  @override
  String get fontWeight => 'Spessore del carattere';

  @override
  String get changeBaseFontWeight =>
      'Modifica lo spessore base del carattere personalizzato';

  @override
  String lyricsFontWeightValue(int weight) {
    return 'Spessore del carattere del testo: $weight';
  }

  @override
  String get equalizerSearchDesc =>
      'Regola l\'equalizzatore a 18 bande e i preset audio';

  @override
  String get stopServiceSearchDesc =>
      'Interrompe la riproduzione e chiude l\'app quando viene rimossa dalle app recenti';

  @override
  String get scanNewFolderDesc => 'Cerca file audio in una nuova cartella';

  @override
  String get includeOtherDeviceAudioShortDesc =>
      'Suonerie, notifiche e audio delle app di messaggistica';

  @override
  String get excludedFolders => 'Cartelle escluse';

  @override
  String get excludedFoldersSearchDesc =>
      'Salta cartelle specifiche durante la scansione';

  @override
  String get clearLibraryData => 'Cancella i dati della libreria';

  @override
  String get looperPlayerVersion => 'Versione di Looper Player';

  @override
  String versionLabel(String version) {
    return 'Versione $version';
  }

  @override
  String get none => 'Nessuna';

  @override
  String foldersSkippedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cartelle saltate durante la scansione',
      one: '1 cartella saltata durante la scansione',
    );
    return '$_temp0';
  }

  @override
  String get excludedFoldersDesc =>
      'I brani in queste cartelle vengono saltati durante la scansione, anche se si trovano in una cartella che hai aggiunto.';

  @override
  String get noExcludedFoldersYet => 'Ancora nessuna cartella esclusa.';

  @override
  String get excludeAFolder => 'Escludi una cartella';

  @override
  String get equalizerEnabled18Band => 'Attivo (EQ MPV a 18 bande)';

  @override
  String get disabled => 'Disattivato';

  @override
  String get noIndexedFoldersYet => 'Ancora nessuna cartella indicizzata';

  @override
  String get noIndexedFoldersYetDesc =>
      'Usa \"Nuova scansione libreria\" per trovare le cartelle nella memoria.';

  @override
  String get eqDynamicRangeCompressor => 'Compressore di dinamica';

  @override
  String get eqThreshold => 'Soglia';

  @override
  String get eqRatio => 'Rapporto';

  @override
  String get eqAttack => 'Attacco';

  @override
  String get eqRelease => 'Rilascio';

  @override
  String get eqHeadphoneCrossfeedWidth => 'Crossfeed e ampiezza per cuffie';

  @override
  String get eqBinauralCrossfeed => 'Crossfeed binaurale';

  @override
  String get eqCrossfeedStrength => 'Intensità del crossfeed';

  @override
  String get eqStereoWidening => 'Allargamento stereo';

  @override
  String get eqWideningFactor => 'Fattore di allargamento';

  @override
  String get eqLoudnessNormalization => 'Normalizzazione del volume';

  @override
  String get eqTargetLoudness => 'Volume di riferimento';

  @override
  String get eqToneShelving => 'Shelving dei toni (bassi / alti)';

  @override
  String get eqBassShelf => 'Shelf dei bassi';

  @override
  String get eqTrebleShelf => 'Shelf degli alti';

  @override
  String get eqTempoPitchControls => 'Controlli di tempo e intonazione';

  @override
  String get eqPitchShift => 'Variazione di intonazione';

  @override
  String get eqTempoSpeed => 'Velocità del tempo';

  @override
  String get eqVoiceSilenceControls => 'Controlli di voce e silenzio';

  @override
  String get eqSilenceTrimming => 'Rimozione dei silenzi';

  @override
  String get eqSilenceThreshold => 'Soglia di silenzio';

  @override
  String get eqSpeechEnhancementFilter => 'Filtro di miglioramento vocale';

  @override
  String get eqHighpassCutoff => 'Taglio passa-alto';

  @override
  String get eqLowpassCutoff => 'Taglio passa-basso';

  @override
  String get eqRetroRoomEffects => 'Effetti retrò e ambiente';

  @override
  String get eqLofiEffect => 'Effetto lo-fi (bitcrusher a 8 bit)';

  @override
  String get eqStudioRoomReverb => 'Riverbero da studio (eco)';

  @override
  String get eqVirtualSurround => 'Audio surround virtuale 5.1';

  @override
  String get eqRawFilterConsole => 'Console filtri FFmpeg grezzi';

  @override
  String get eqSwitchToSliders => 'Passa ai cursori';

  @override
  String get eqSwitchToGraph => 'Passa al grafico';

  @override
  String get on => 'Attivo';

  @override
  String get off => 'Disattivo';

  @override
  String get eqSongSpecificActive => 'Impostazioni specifiche del brano attive';

  @override
  String get eqUsingGlobalDefault =>
      'In uso le impostazioni globali predefinite';

  @override
  String get eqInteractiveGraphHint =>
      'GRAFICO INTERATTIVO (TRASCINA I PUNTI IN VERTICALE)';

  @override
  String get eq18BandHint => 'EQUALIZZATORE A 18 BANDE (SCORRI IN ORIZZONTALE)';

  @override
  String get eqSongSpecific => 'Specifico del brano';

  @override
  String get eqGlobalDefault => 'Predefinito globale';

  @override
  String get eqEditScopeNote =>
      'Le modifiche fatte mentre un brano è in riproduzione valgono solo per quel brano. Per impostare il valore globale, modifica senza brani in riproduzione oppure usa l\'azione \"Applica al globale\".';

  @override
  String get presetFlat => 'Piatto';

  @override
  String get presetBassBooster => 'Potenzia bassi';

  @override
  String get presetTrebleBooster => 'Potenzia alti';

  @override
  String get presetVocalBooster => 'Potenzia voce';

  @override
  String get presetElectronic => 'Elettronica';

  @override
  String get presetRock => 'Rock';

  @override
  String get presetPop => 'Pop';

  @override
  String get presetJazz => 'Jazz';

  @override
  String get save => 'Salva';

  @override
  String get savePreset => 'Salva preset';

  @override
  String get presetName => 'Nome del preset';

  @override
  String get deletePreset => 'Elimina preset';

  @override
  String deletePresetConfirm(String name) {
    return 'Eliminare il preset \"$name\"?';
  }

  @override
  String get noLyricsSource => 'Nessuna fonte del testo';

  @override
  String lyricsSourceLabel(String source) {
    return 'Fonte: $source';
  }

  @override
  String get lyricsSourceLocalSidecar => 'File locale affiancato (.lrc)';

  @override
  String get lyricsSourceCustomFile => 'File LRC personalizzato';

  @override
  String get lyricsSourceNotFoundOnline => 'Non trovato online';

  @override
  String get lyricsProviderLocal => 'Locale';

  @override
  String get checkingLocalLyrics => 'Ricerca di testi locali/incorporati...';

  @override
  String fetchingLyricsFrom(String provider) {
    return 'Recupero del testo da $provider...';
  }

  @override
  String get loadedLocalLyrics => 'Testo locale/incorporato caricato!';

  @override
  String get noLocalLyricsFound => 'Nessun testo locale o incorporato trovato';

  @override
  String lyricsUpdatedFrom(String provider) {
    return 'Testo aggiornato da $provider!';
  }

  @override
  String noLyricsFoundOn(String provider) {
    return 'Nessun testo trovato su $provider';
  }

  @override
  String get gestureTips => 'Suggerimenti sui gesti';

  @override
  String get gestureTipsDesc =>
      'Tocca, tieni premuto, pizzica per zoomare e altro';

  @override
  String get exportLyrics => 'Esporta testo';

  @override
  String lyricsExportedTo(String path) {
    return 'Testo esportato in: $path';
  }

  @override
  String failedToExportLyrics(String error) {
    return 'Impossibile esportare il testo: $error';
  }

  @override
  String get gestureTapLine => 'Tocca una riga';

  @override
  String get gestureTapLineDesc => 'Salta direttamente a quel punto del testo.';

  @override
  String get gestureLongPressLine => 'Tieni premuta una riga';

  @override
  String get gestureLongPressLineDesc =>
      'Inizia a selezionare le righe per creare una scheda del testo da condividere. Tocca altre righe per estendere la selezione.';

  @override
  String get gesturePinch => 'Pizzica con due dita';

  @override
  String get gesturePinchDesc => 'Ridimensiona il testo come preferisci.';

  @override
  String get gestureSwipeDown => 'Scorri verso il basso';

  @override
  String get gestureSwipeDownDesc =>
      'Chiude la schermata del testo e torna al lettore.';

  @override
  String get lyricsGestures => 'Gesti del testo';

  @override
  String get lyricsGesturesIntro =>
      'Alcune cose che questa schermata sa fare e che non sono sempre evidenti:';

  @override
  String linesSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count righe selezionate',
      one: '1 riga selezionata',
    );
    return '$_temp0';
  }

  @override
  String get couldNotGenerateShareImage =>
      'Impossibile generare l\'immagine da condividere.';

  @override
  String get couldNotGenerateImage => 'Impossibile generare l\'immagine.';

  @override
  String get savedToGallery => 'Salvata nella galleria.';

  @override
  String get galleryPermissionDenied =>
      'L\'autorizzazione di accesso alla galleria è stata negata.';

  @override
  String get couldNotSaveToGallery =>
      'Impossibile salvare l\'immagine nella galleria.';

  @override
  String get shareLyrics => 'Condividi testo';

  @override
  String get backgroundColor => 'Colore di sfondo';

  @override
  String get lyricsTextColor => 'Colore del testo';

  @override
  String get saveToGallery => 'Salva nella galleria';

  @override
  String get preparing => 'Preparazione...';

  @override
  String get trackTitle => 'Titolo del brano';

  @override
  String get composer => 'Compositore';

  @override
  String get unknownGenre => 'Genere sconosciuto';

  @override
  String get releaseYear => 'Anno di uscita';

  @override
  String get notAvailable => 'N/D';

  @override
  String get recordLabel => 'Etichetta';

  @override
  String get copyright => 'Copyright';

  @override
  String get encoder => 'Encoder';

  @override
  String get fileName => 'Nome del file';

  @override
  String get fileFormat => 'Formato del file';

  @override
  String get fileSize => 'Dimensione del file';

  @override
  String get absolutePath => 'Percorso assoluto';

  @override
  String get playCount => 'Numero di ascolti';

  @override
  String playCountTimes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count volte',
      one: '1 volta',
    );
    return '$_temp0';
  }

  @override
  String get lastPlayed => 'Ultimo ascolto';

  @override
  String get filePath => 'Percorso del file';

  @override
  String get rescan => 'Nuova scansione';

  @override
  String get codec => 'Codec';

  @override
  String get container => 'Contenitore';

  @override
  String get sampleRate => 'Frequenza di campionamento';

  @override
  String get bitDepth => 'Profondità di bit';

  @override
  String get decodedFormat => 'Formato decodificato';

  @override
  String get bitrate => 'Bitrate';

  @override
  String get channels => 'Canali';

  @override
  String get nyquist => 'Nyquist';

  @override
  String get dynamicRange => 'Gamma dinamica';

  @override
  String get peak => 'Picco';

  @override
  String get truePeak => 'Picco reale';

  @override
  String get clipping => 'Clipping';

  @override
  String get cutoff => 'Taglio';

  @override
  String get samples => 'Campioni';

  @override
  String channelShort(int channel) {
    return 'Can. $channel';
  }

  @override
  String get noneClean => 'Nessuno (pulito)';

  @override
  String get reanalyzingAudio => 'Nuova analisi del flusso audio...';

  @override
  String get analyzingAudio => 'Analisi del flusso audio...';

  @override
  String sampleRateHz(int rate) {
    return 'Frequenza di campionamento: $rate Hz';
  }

  @override
  String nyquistKhz(String khz) {
    return 'Nyquist: $khz kHz';
  }

  @override
  String get qualityLossless => 'Lossless';

  @override
  String get qualityHigh => 'Alta qualità';

  @override
  String get qualityStandard => 'Qualità standard';

  @override
  String get qualityAudio => 'Audio';

  @override
  String get addCustomFolder => 'Aggiungi una cartella personalizzata';

  @override
  String get addCustomFolderDesc =>
      'Se la tua musica si trova in una cartella con un altro nome o su una scheda SD, aggiungila direttamente.';

  @override
  String get indexingYourLibrary => 'INDICIZZAZIONE DELLA LIBRERIA...';

  @override
  String get indexingYourLibraryDesc =>
      'Completamento di titoli, copertine e testi dei tuoi brani.';

  @override
  String welcomeStep(String step, String title) {
    return 'PASSO $step: $title';
  }

  @override
  String get includeOtherDeviceAudioAlarmsDesc =>
      'Suonerie, notifiche, sveglie e audio delle app di messaggistica';

  @override
  String get version => 'Versione';

  @override
  String get noIndexedFoldersDesktopDesc =>
      'Usa \"Nuova scansione libreria\" per trovare le cartelle di archiviazione';

  @override
  String get playedLabel => 'Ascoltati';

  @override
  String minutesShort(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count min',
      one: '1 min',
    );
    return '$_temp0';
  }

  @override
  String minuteChip(int count) {
    return '$count min';
  }

  @override
  String songsCountTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count brani',
      one: '1 brano',
    );
    return '$_temp0';
  }

  @override
  String songsLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count brani rimanenti',
      one: '1 brano rimanente',
    );
    return '$_temp0';
  }

  @override
  String sleepTimerWithRemaining(String remaining) {
    return 'Timer di spegnimento ($remaining)';
  }

  @override
  String get trackInfoSection => 'INFO BRANO';

  @override
  String get detailsSection => 'DETTAGLI';

  @override
  String get lyricsSection => 'TESTO';

  @override
  String get editLyricsHint =>
      'Inserisci il testo semplice o in formato LRC sincronizzato [00:00.00]...';

  @override
  String addedSongsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count brani aggiunti',
      one: '1 brano aggiunto',
    );
    return '$_temp0';
  }

  @override
  String get chooseInternalStorageFolder =>
      'Scegli una cartella nella memoria interna o nella scheda SD di questo dispositivo.';

  @override
  String get appCrashedTitle => 'Looper Player si è arrestato';

  @override
  String get appCrashedDesc =>
      'Si è verificato un errore imprevisto all\'avvio. È stato generato un rapporto diagnostico.';

  @override
  String get appCrashedDetails =>
      'Si è verificato un errore durante l\'inizializzazione del database o dei servizi dell\'app. Può succedere se l\'accesso alla memoria è limitato o se i file del database sono danneggiati.';

  @override
  String get crashReportSaved =>
      'Rapporto diagnostico salvato nella cartella di supporto dell\'applicazione.';

  @override
  String get shareLog => 'Condividi log';

  @override
  String get restartApp => 'Riavvia l\'app';

  @override
  String get updateAvailableOnPlay =>
      'Una nuova versione è disponibile su Google Play.';

  @override
  String updateAvailableOnGithub(String version) {
    return 'La versione $version è disponibile su GitHub.';
  }

  @override
  String get updateAvailable => 'Aggiornamento disponibile';

  @override
  String get updateAvailableTitle => 'Aggiornamento disponibile!';

  @override
  String get visit => 'APRI';

  @override
  String get updateDownloaded => 'Aggiornamento scaricato';

  @override
  String get restartToInstallUpdate => 'Riavvia Looper Player per installarlo.';

  @override
  String get restart => 'RIAVVIA';

  @override
  String backupImportedSummary(int favorites, int stats, int playlists) {
    return 'Backup importato: uniti $favorites preferiti e $stats statistiche di ascolto, sincronizzate $playlists playlist';
  }

  @override
  String get backupExportFailed =>
      'Esportazione del backup non riuscita: si è verificato un errore interno durante il salvataggio del file.';

  @override
  String get backupImportFailed =>
      'Importazione del backup non riuscita: il file non è leggibile o il formato non è valido.';

  @override
  String get stereo => 'Stereo';

  @override
  String get mono => 'Mono';
}
