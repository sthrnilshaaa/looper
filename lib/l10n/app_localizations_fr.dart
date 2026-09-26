// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get about => 'À propos';

  @override
  String get aboutAndMaintainers => 'À propos & Développeurs';

  @override
  String get aboutApp => 'À propos de l\'application';

  @override
  String get aboutLooperPlayer => 'À PROPOS DE LOOPER PLAYER';

  @override
  String get accentColor => 'Couleur d\'accentuation';

  @override
  String get accentColorDesc =>
      'Sélectionner manuellement la couleur d\'accentuation';

  @override
  String get acousticSpectralAnalysis => 'ANALYSE ACOUSTIQUE & SPECTRALE';

  @override
  String get activeCallCannotPlay =>
      'Lecture bloquée : Impossible de lire de la musique pendant un appel actif';

  @override
  String get adaptColorsArtwork =>
      'Adapter les couleurs de l\'application à la pochette de l\'album';

  @override
  String addedTo(String name) {
    return 'Ajouté à $name';
  }

  @override
  String get addedToQueue => 'Ajouté à la file d\'attente';

  @override
  String get addFolder => 'Ajouter un dossier';

  @override
  String get addToFavorites => 'Ajouter aux favoris';

  @override
  String get addToPlaylists => 'Ajouter aux playlists';

  @override
  String get addToQueue => 'Ajouter à la file d\'attente';

  @override
  String get album => 'Album';

  @override
  String get albums => 'Albums';

  @override
  String get albumsRowDesc => 'Étagère horizontale d\'albums';

  @override
  String get allFilesAccess => 'ACCÈS À TOUS LES FICHIERS (RECOMMANDÉ)';

  @override
  String get allSongs => 'Toutes les chansons';

  @override
  String get appDetailsCreator =>
      'Détails de l\'application, créateur et équipe de conception';

  @override
  String get appearance => 'Apparence';

  @override
  String get appInfoPrivacy => 'INFOS APP & CONFIDENTIALITÉ';

  @override
  String get appTitle => 'Looper Player';

  @override
  String get artist => 'Artiste';

  @override
  String get artists => 'Artistes';

  @override
  String get artistsRowDesc => 'Étagère horizontale d\'artistes';

  @override
  String get ascending => 'Ascendant';

  @override
  String get audioCrossfade => 'Fondu enchaîné audio';

  @override
  String get audioCrossfadeDesc =>
      'Superposer les pistes en douceur lors du changement de chanson';

  @override
  String get audioFocusDenied =>
      'Lecture mise en pause : focus audio refusé par le système';

  @override
  String get audioPlayback => 'Audio & lecture';

  @override
  String get audioPlaybackDesc =>
      'Paramètres de fondu enchaîné, de silence et d\'atténuation';

  @override
  String get autoCrossfadeDuration => 'Durée du fondu enchaîné automatique';

  @override
  String get autoCrossfadeDurationDesc =>
      'Durée de superposition lors des transitions automatiques';

  @override
  String get backToMainView => 'RETOUR À LA VUE PRINCIPALE';

  @override
  String get cancel => 'Annuler';

  @override
  String get categories => 'Catégories';

  @override
  String get center => 'Centre';

  @override
  String get clear => 'Effacer';

  @override
  String get clearQueue => 'Effacer';

  @override
  String get connectDevice => 'CONNECTER L\'APPAREIL';

  @override
  String get corePurpose => 'Objectif principal';

  @override
  String get corePurposeDesc =>
      'Looper Player est un lecteur audio haute fidélité hors ligne par défaut, conçu pour les passionnés de musique qui souhaitent un contrôle absolu sur leur bibliothèque locale, une lecture sans blanc et un défilement fluide des paroles synchronisées.';

  @override
  String get create => 'Créer';

  @override
  String get createPlaylist => 'Créer une playlist';

  @override
  String get creatorAndMaintainer => 'Créateur et développeur';

  @override
  String get customAccentColor => 'Couleur d\'accent personnalisée';

  @override
  String get customizeColorsTheme =>
      'Personnalisez les couleurs, le thème et les arrière-plans des paroles';

  @override
  String get dateAdded => 'Date d\'ajout';

  @override
  String get deepStorageScanProgress => 'ANALYSE APPROFONDIE DU STOCKAGE...';

  @override
  String get delete => 'Supprimer';

  @override
  String get deleteFile => 'Supprimer le fichier';

  @override
  String get deletePlaylist => 'Supprimer la playlist';

  @override
  String deletePlaylistConfirm(String name) {
    return 'Êtes-vous sûr de vouloir supprimer \"$name\" ?';
  }

  @override
  String get deleteSong => 'Supprimer la chanson';

  @override
  String get deleteSongConfirm =>
      'Êtes-vous sûr de vouloir supprimer cette chanson du disque ?';

  @override
  String get descending => 'Descendant';

  @override
  String get designerAndMaintainer => 'Concepteur et développeur';

  @override
  String get disableBlurEffects => 'Désactiver les effets de flou';

  @override
  String get disableSquigglyProgressBar =>
      'Désactiver l\'animation ondulée de la barre de progression';

  @override
  String get downloadAudioDirectly => 'TÉLÉCHARGER L\'AUDIO DIRECTEMENT';

  @override
  String get downloadingLyricsOffline =>
      'Téléchargement des paroles pour une utilisation hors ligne...';

  @override
  String get downloadMissingArtwork => 'Télécharger l\'art manquant';

  @override
  String get downloadMissingArtworkDesc =>
      'Télécharger automatiquement les pochettes haute résolution depuis iTunes';

  @override
  String get duration => 'Durée';

  @override
  String get dynamicAccentColor => 'Couleur d\'accentuation dynamique';

  @override
  String get dynamicAccentColorDesc =>
      'Mettre à jour dynamiquement la couleur d\'accentuation selon la pochette';

  @override
  String get dynamicBgOnlyLyrics =>
      'Fond dynamique uniquement pour les paroles';

  @override
  String get dynamicColorActiveLyrics => 'Couleur dynamique de la ligne active';

  @override
  String get dynamicColorActiveLyricsDesc =>
      'Utiliser les couleurs extraites de la pochette pour la ligne de paroles en cours de lecture';

  @override
  String get dynamicLyricsBg => 'Fond de paroles dynamique';

  @override
  String get dynamicLyricsBgDesc =>
      'Appliquer le flou de la pochette à l\'écran des paroles';

  @override
  String get dynamicTheming => 'Thème dynamique';

  @override
  String get emptyLibraryDesc =>
      'Aucun fichier musical pris en charge n\'a été trouvé dans votre bibliothèque. Ajoutez des dossiers ou lancez une analyse.';

  @override
  String get enableNetworkLyricsArt =>
      'Activer l\'utilisation du réseau pour les paroles en ligne & l\'art de l\'artiste';

  @override
  String get enablePlayerGradient => 'Dégradé de l\'écran de lecture';

  @override
  String get enablePlayerGradientDesc =>
      'Activer le fond en dégradé radial d\'accent sur l\'écran de lecture en cours';

  @override
  String get fadeDuration => 'Durée du fondu';

  @override
  String get fadeDurationDesc =>
      'Durée de l\'effet de fondu lecture/pause/arrêt';

  @override
  String get fadeOnSeek => 'Fondu lors de la recherche';

  @override
  String get fadeOnSeekDesc =>
      'Atténuer doucement le volume lors de la recherche dans un morceau';

  @override
  String get fadePlayPauseStop => 'Fondu Lecture/Pause/Arrêt';

  @override
  String get fadePlayPauseStopDesc =>
      'Atténuer doucement le volume lors de la lecture, pause ou arrêt';

  @override
  String get favorites => 'Favoris';

  @override
  String get fileInformation => 'Informations sur le fichier';

  @override
  String get flatProgressBar => 'Barre de progression plate';

  @override
  String get folders => 'Dossiers';

  @override
  String get genre => 'Genre';

  @override
  String get genres => 'Genres';

  @override
  String get genresRowDesc => 'Étagère horizontale de genres musicaux';

  @override
  String get goStart => 'COMMENCER';

  @override
  String get grant => 'AUTORISER';

  @override
  String get granted => 'AUTORISÉ';

  @override
  String get history => 'Historique';

  @override
  String get home => 'Accueil';

  @override
  String get homeDarkness => 'Assombrissement de l\'écran d\'accueil';

  @override
  String get homeDarknessDesc =>
      'Ajuster l\'assombrissement du fond pour l\'écran d\'accueil';

  @override
  String get homeDashboardSettings => 'Paramètres du tableau de bord';

  @override
  String get homeDashboardSettingsDesc =>
      'Personnaliser les lignes horizontales de votre écran d\'accueil';

  @override
  String get internetMode => 'Mode Internet';

  @override
  String get keepBackgroundGradient => 'Garder le dégradé de fond';

  @override
  String get keepBackgroundGradientDesc =>
      'Garder le dégradé de fond sur tous les écrans de l\'application';

  @override
  String get animatePlayerGradient => 'Dégradé animé';

  @override
  String get animatePlayerGradientDesc =>
      'Fait bouger lentement les couleurs primaire et tertiaire avec un grain doux, au rythme de la musique';

  @override
  String get animateBackgroundGradient => 'Arrière-plan animé';

  @override
  String get animateBackgroundGradientDesc =>
      'Utilise le dégradé animé en arrière-plan de l\'Accueil, des Titres et de la Bibliothèque';

  @override
  String get language => 'Langue';

  @override
  String get left => 'Gauche';

  @override
  String get library => 'Bibliothèque';

  @override
  String get libraryDarkness => 'Assombrissement de l\'écran de bibliothèque';

  @override
  String get libraryDarknessDesc =>
      'Ajuster l\'assombrissement du fond pour l\'écran de bibliothèque';

  @override
  String get libraryFoldersSync =>
      'Dossiers, déclencheurs d\'analyse, réinitialisation de la base de données et synchro hors ligne';

  @override
  String get librarySettings => 'Paramètres de la bibliothèque';

  @override
  String get loadingMusicLibrary => 'CHARGEMENT DE LA BIBLIOTHÈQUE MUSICALE';

  @override
  String get loadingMusicLibraryDesc =>
      'Construction des index premium, configuration des écouteurs matériels et optimisation des caches visuels.';

  @override
  String get loadingPhase1 => 'INTERROGATION DE L\'AUDIO...';

  @override
  String get loadingPhase2 => 'RAFRAÎCHISSEMENT DU MOTEUR...';

  @override
  String get loadingPhase3 => 'EXTRACTION DES DONNÉES ACOUSTIQUES...';

  @override
  String get loadingPhase4 => 'OPTIMISATION DE LA MÉMOIRE...';

  @override
  String get lyrics => 'Paroles';

  @override
  String get lyricsAlignment => 'Alignement des paroles';

  @override
  String get lyricsAlignmentDesc =>
      'Aligner la position du texte pour les paroles défilantes';

  @override
  String get lyricsDarkness => 'Assombrissement de l\'écran des paroles';

  @override
  String get lyricsDarknessDesc =>
      'Ajuster l\'assombrissement du fond pour l\'écran des paroles';

  @override
  String get lyricsProvider => 'Fournisseur de paroles';

  @override
  String get lyricsProviderDesc =>
      'Paroles en ligne récupérées depuis lrclib.net (LRCLIB)';

  @override
  String get maintainersAndDesigners => 'Développeurs & designers';

  @override
  String get manageAudioFocus => 'Gérer le focus audio';

  @override
  String get manageAudioFocusDesc =>
      'Demander et répondre aux changements de focus audio du système';

  @override
  String get manageAudioFocusTitle => 'Gérer le focus audio';

  @override
  String get manageLanguageAndFocus =>
      'Gérer les préférences de langue et l\'état de focus des appels';

  @override
  String get audioFocusGetFocus => 'Obtenir le focus';

  @override
  String get audioFocusGetFocusDesc =>
      'Demander le focus audio au début de la lecture.';

  @override
  String get audioFocusReleaseFocus => 'Libérer le focus';

  @override
  String get audioFocusReleaseFocusDesc =>
      'Libérer le focus audio quand la lecture est mise en pause ou arrêtée.';

  @override
  String get audioFocusStopOnOtherSession =>
      'Arrêter la musique lors d\'une autre session musicale';

  @override
  String get audioFocusStopOnOtherSessionDesc =>
      'Mettre la lecture en pause quand une autre application commence à jouer de l\'audio.';

  @override
  String get audioFocusRestartOnGain =>
      'Reprendre la musique au regain du focus';

  @override
  String get audioFocusRestartOnGainDesc =>
      'Reprendre automatiquement la lecture quand le focus audio revient, uniquement si la lecture avait été interrompue par une perte de focus.';

  @override
  String get pauseOnDuckTitle => 'Pause en cas d\'atténuation';

  @override
  String get pauseOnDuckDesc =>
      'Mettre la lecture en pause au lieu de baisser le volume quand une autre application joue un son bref (ex. notifications, indications de navigation).';

  @override
  String get resumeOnBluetoothConnectTitle =>
      'Reprendre à la connexion Bluetooth';

  @override
  String get resumeOnBluetoothConnectDesc =>
      'Reprendre automatiquement la lecture quand un appareil audio Bluetooth (écouteurs, kit voiture) se reconnecte.';

  @override
  String get manualCrossfadeDuration => 'Durée du fondu enchaîné manuel';

  @override
  String get manualCrossfadeDurationDesc =>
      'Durée de superposition lors des transitions manuelles';

  @override
  String get matchingLyrics => 'PAROLES CORRESPONDANTES';

  @override
  String get metadataDetails => 'Détails des métadonnées';

  @override
  String get mostPlayed => 'Plus écoutés';

  @override
  String get musicAudioAccess => 'ACCÈS MUSIQUE & AUDIO';

  @override
  String get musicDarkness => 'Assombrissement du lecteur de musique';

  @override
  String get musicDarknessDesc =>
      'Ajuster l\'assombrissement du fond pour l\'écran du lecteur de musique';

  @override
  String get musicLibrary => 'Bibliothèque musicale';

  @override
  String get muteOrPauseCalls =>
      'Couper le son ou mettre en pause pendant les appels et autres activités audio';

  @override
  String get newPlaylist => 'Nouvelle playlist';

  @override
  String get newTitle => 'Nouveau titre';

  @override
  String get nextUp => 'À suivre';

  @override
  String get noAlbumsFound => 'Aucun album trouvé';

  @override
  String get noArtistsFound => 'Aucun artiste trouvé';

  @override
  String get noFavoritesYet => 'Aucun favori pour le moment';

  @override
  String get noHistoryYet => 'Aucun historique';

  @override
  String get noLyrics => 'Aucune parole trouvée';

  @override
  String get noMusicDetected => 'AUCUNE MUSIQUE DÉTECTÉE';

  @override
  String get noPlaylistsCreated => 'Aucune playlist créée pour le moment.';

  @override
  String get noPlaylistsYet => 'Aucune playlist pour le moment';

  @override
  String get noResultsFound => 'Aucun résultat trouvé';

  @override
  String get noSongsFound => 'Aucune chanson trouvée';

  @override
  String get notificationAccess => 'ACCÈS AUX NOTIFICATIONS';

  @override
  String get nowPlaying => 'Lecture en cours';

  @override
  String get performanceOptimizerDashboard =>
      'Tableau de bord de l\'optimiseur de performances';

  @override
  String get performanceOptimizerDashboardDesc =>
      'Afficher les statistiques de l\'optimiseur en temps réel';

  @override
  String get permanentFocusChangePause => 'Pause sur perte de focus permanente';

  @override
  String get permanentFocusChangePauseDesc =>
      'Mettre en pause automatiquement lors de la perte définitive du focus audio';

  @override
  String get plainTimestamps => 'Horodatages simples';

  @override
  String get play => 'Lire';

  @override
  String get playAll => 'Tout lire';

  @override
  String get playbackAudio => 'Lecture & Langue';

  @override
  String get playlists => 'Playlists';

  @override
  String get playNext => 'Lire ensuite';

  @override
  String get playQueue => 'File d\'attente';

  @override
  String get pressBackExit => 'Appuyez à nouveau sur retour pour quitter';

  @override
  String get privacySafety => 'Confidentialité & Sécurité';

  @override
  String get privacySafetyDesc =>
      '100% privé et hors ligne en priorité. Vos morceaux, votre historique de lecture, vos favoris et votre configuration restent strictement dans une base de données Isar sécurisée sur votre appareil local. Nous ne suivons, ne collectons et ne partageons pas vos données d\'utilisation.';

  @override
  String get pureBlackOled => 'Noir pur (OLED)';

  @override
  String get pureBlackOledDesc =>
      'Utiliser le noir absolu pour les arrière-plans';

  @override
  String get queue => 'File d\'attente';

  @override
  String get queueIsEmpty => 'La file d\'attente est vide';

  @override
  String get quickPicks => 'Sélections rapides';

  @override
  String get quickPicksRowDesc => 'Votre grille de chansons les plus écoutées';

  @override
  String get readyToScan => 'Prêt à analyser';

  @override
  String get recentlyAddedSongsRowDesc =>
      'Une liste de vos dernières importations';

  @override
  String get recentlyPlayed => 'Récemment écoutés';

  @override
  String get recentPlayed => 'Écoutés récemment';

  @override
  String get recentRowDesc =>
      'Étagère horizontale des titres écoutés récemment';

  @override
  String get removedFromPlaylist => 'Retiré de la playlist';

  @override
  String get removeFromFavorites => 'Retirer des favoris';

  @override
  String get removeFromPlaylist => 'Retirer de la playlist';

  @override
  String get rename => 'Renommer';

  @override
  String get renameFile => 'Renommer le fichier';

  @override
  String get renamePlaylist => 'Renommer la playlist';

  @override
  String get renameSong => 'Renommer la chanson';

  @override
  String get reorderDashboardSections =>
      'Réorganiser les sections du tableau de bord';

  @override
  String get reorderDashboardSectionsDesc =>
      'Glisser-déposer pour définir l\'ordre préféré';

  @override
  String get includeOtherDeviceAudioTitle =>
      'Inclure les autres audios de l\'appareil';

  @override
  String get includeOtherDeviceAudioDesc =>
      'Analyser les sonneries, notifications, alarmes et l\'audio de WhatsApp et Telegram';

  @override
  String get rescanLibrary => 'Analyser à nouveau la bibliothèque';

  @override
  String get rescanStorage => 'ANALYSER À NOUVEAU LE STOCKAGE';

  @override
  String get reset => 'Réinitialiser';

  @override
  String get resetLibrary => 'Réinitialiser & Analyser';

  @override
  String get resetLibraryConfirm =>
      'Cela effacera toutes les chansons, albums et artistes et effectuera une analyse complète de vos dossiers.';

  @override
  String get resetLibraryConfirmNew =>
      'Cela retirera toutes les chansons de votre bibliothèque. Vos fichiers musicaux ne seront pas supprimés.';

  @override
  String get resetLibraryDesc =>
      'Retirer toutes les chansons de votre bibliothèque indexée';

  @override
  String get resumeAfterCallDesc =>
      'Reprendre la lecture automatiquement à la fin de l\'appel (si mis en pause par l\'appel)';

  @override
  String get resumeAfterCallTitle => 'Reprendre après un appel';

  @override
  String get resumeOnStartDesc =>
      'Reprendre la lecture automatiquement au démarrage de Looper Player';

  @override
  String get resumeOnStartTitle => 'Reprendre au démarrage';

  @override
  String get persistQueueTitle => 'Conserver la dernière file';

  @override
  String get persistQueueDesc =>
      'Sauvegarder le dernier morceau et la file d\'attente lors du redémarrage';

  @override
  String get keepSongProgressTitle => 'Conserver la progression du morceau';

  @override
  String get keepSongProgressDesc =>
      'Mémorise la position de lecture de chaque morceau séparément. Passez à un autre morceau en cours de route et revenez plus tard — même après avoir écouté d\'autres morceaux entre-temps — la lecture reprendra exactement là où vous l\'aviez laissée au lieu de recommencer depuis le début.';

  @override
  String get right => 'Droite';

  @override
  String scanCompleteSongsDetected(int count) {
    return 'ANALYSE TERMINÉE : $count CHANSONS DÉTECTÉES !';
  }

  @override
  String get scanForMusic => 'RECHERCHER DE LA MUSIQUE';

  @override
  String get scanIndexLocalDesc => 'Analyser & indexer les fichiers locaux';

  @override
  String get scanLibrary => 'Analyser la bibliothèque';

  @override
  String get scanningInBackground => 'Analyse en arrière-plan...';

  @override
  String get scanningLibrary => 'Analyse de la bibliothèque en cours...';

  @override
  String get scanningStorage => 'ANALYSE DU STOCKAGE EN COURS...';

  @override
  String get scanningStorageDesc =>
      'Parcours des dossiers pour découvrir des morceaux audio. Veuillez patienter...';

  @override
  String get search => 'Rechercher';

  @override
  String get searchLibraryHint => 'Rechercher dans toute votre bibliothèque';

  @override
  String get searchSongsHint => 'Rechercher des chansons';

  @override
  String get seekFadeDuration => 'Durée du fondu de recherche';

  @override
  String get seekFadeDurationDesc =>
      'Durée de l\'effet de fondu lors de la recherche';

  @override
  String get selectAppLanguage => 'Sélectionner la langue de l\'application';

  @override
  String get selectCustomColor => 'Choisir une couleur personnalisée';

  @override
  String get selectCustomFolder => 'CHOISIR UN DOSSIER PERSONNALISÉ';

  @override
  String get selectFolderIndex =>
      'Sélectionner un dossier pour indexer les fichiers musicaux';

  @override
  String get selectSpecificFolder => 'SÉLECTIONNER UN DOSSIER SPÉCIPIQUE';

  @override
  String get settings => 'Paramètres';

  @override
  String get share => 'Partager';

  @override
  String get shareFile => 'Partager le fichier';

  @override
  String get showAlbumsRow => 'Afficher la ligne Albums';

  @override
  String get showAlbumsRowDesc =>
      'Afficher une liste horizontale d\'albums sur votre écran d\'accueil';

  @override
  String get showArtistsRow => 'Afficher la ligne Artistes';

  @override
  String get showArtistsRowDesc =>
      'Afficher une liste horizontale d\'artistes sur votre écran d\'accueil';

  @override
  String get showGenresRow => 'Afficher la ligne Genres';

  @override
  String get showGenresRowDesc =>
      'Afficher une liste horizontale de genres sur votre écran d\'accueil';

  @override
  String get showLess => 'Afficher moins';

  @override
  String get showMore => 'Afficher plus';

  @override
  String get showQualityBadge => 'Afficher le badge de qualité';

  @override
  String get showQualityBadgeDesc =>
      'Afficher un badge d\'information sur la qualité audio sur l\'écran de lecture en cours';

  @override
  String get showRecentRow => 'Afficher la ligne Écoutés récemment';

  @override
  String get showRecentRowDesc =>
      'Afficher une liste horizontale des titres écoutés récemment sur votre écran d\'accueil';

  @override
  String get silenceBetweenTracksDesc =>
      'Ajouter un silence entre les pistes (0ms pour le sans blanc)';

  @override
  String get silenceBetweenTracksTitle => 'Silence entre les pistes';

  @override
  String get songDeletedDbOnly =>
      'Chanson retirée de la bibliothèque (fichier physique en lecture seule)';

  @override
  String get songDeletedSuccess => 'Chanson supprimée avec succès';

  @override
  String get songDeleteFailed => 'Échec de la suppression de la chanson';

  @override
  String get songDetails => 'Détails de la chanson';

  @override
  String get songDetailsAndFrequency => 'Détails & Fréquence de la chanson';

  @override
  String get songRenamedDbOnly =>
      'Chanson renommée dans la bibliothèque (fichier physique en lecture seule)';

  @override
  String get songRenamedSuccess => 'Chanson renommée avec succès';

  @override
  String get songRenameFailed => 'Échec du renommage de la chanson';

  @override
  String get songs => 'Chansons';

  @override
  String get songsDarkness => 'Assombrissement de l\'écran des morceaux';

  @override
  String get songsDarknessDesc =>
      'Ajuster l\'assombrissement du fond pour l\'écran des morceaux';

  @override
  String get sortBy => 'Trier par';

  @override
  String get sortOrder => 'Ordre de tri';

  @override
  String get sourceCode => 'Code source';

  @override
  String get stopServiceOnAppDismissal =>
      'Arrêter le service à la fermeture de l\'application';

  @override
  String get stopServiceOnAppDismissalDesc =>
      'Arrête le service en arrière-plan et ferme l\'application lorsqu\'elle est balayée';

  @override
  String get storagePermissionRequired =>
      'Les autorisations de stockage sont requises pour analyser la mémoire de l\'appareil.';

  @override
  String get syncLyricsOffline => 'Synchroniser les paroles (Hors ligne)';

  @override
  String get systemDefault => 'Système par défaut';

  @override
  String get systemPermissionChecklist => 'LISTE DE CONTRÔLE DES AUTORISATIONS';

  @override
  String get technicalInfoFrequency => 'Infos techniques & Fréquence';

  @override
  String get theme => 'Thème';

  @override
  String get title => 'Titre';

  @override
  String get todayMixForYou => 'Mix du jour pour vous';

  @override
  String get toggleFavorite => 'Ajouter/Retirer des favoris';

  @override
  String get shuffleTitle => 'Lecture aléatoire';

  @override
  String get shuffleDisabledDesc =>
      'Lire les morceaux dans leur ordre de file d\'attente original. Désactiver la lecture aléatoire laisse le morceau en cours continuer et restaure le reste de la file dans son ordre d\'origine, sans affecter la lecture ni son historique.';

  @override
  String get shuffleEnabledDesc =>
      'Mélanger les morceaux restants tout en laissant le morceau en cours inchangé. L\'ordre aléatoire généré reste le même jusqu\'à ce que la file change ou qu\'un nouveau mélange soit demandé, évitant les morceaux répétés ou sautés.';

  @override
  String get shuffleSwitchingDesc =>
      'Activer ou désactiver la lecture aléatoire ne redémarre jamais le morceau en cours. Cela change uniquement l\'ordre des morceaux à venir — aléatoire si activé, et restauré à l\'ordre d\'origine de la file si désactivé.';

  @override
  String get topResult => 'Meilleur résultat';

  @override
  String get transferMusicFiles => 'TRANSFÉRER LES FICHIERS MUSICAUX';

  @override
  String get turnOffBlursOptimize =>
      'Désactiver les flous intenses pour optimiser les performances';

  @override
  String get unknown => 'Inconnu';

  @override
  String get unknownAlbum => 'Album inconnu';

  @override
  String get unknownArtist => 'Artiste inconnu';

  @override
  String get updateLibraryIndexing =>
      'Mettre à jour l\'indexation des fichiers de la bibliothèque';

  @override
  String get useAbsoluteBlackBg => 'Utiliser un fond noir absolu';

  @override
  String get useStaticTextTimestamps =>
      'Utiliser du texte statique au lieu d\'une animation pour la progression';

  @override
  String get fluidPlayer => 'Lecteur fluide';

  @override
  String get fluidPlayerDesc =>
      'Faites glisser le mini-lecteur vers le haut pour le transformer en lecteur complet';

  @override
  String get viewAll => 'Voir tout';

  @override
  String get visitOfficialRepository => 'Visiter le dépôt officiel sur GitHub';

  @override
  String get welcomeAboutDesc =>
      'Looper Player est un système Music-OS de nouvelle génération conçu pour une lecture audio hors ligne de qualité supérieure. Il intègre des paroles synchronisées en temps réel, une gestion avancée des sessions audio avec mise en pause automatique lors des appels, des thèmes d\'arrière-plan adaptatifs et la prise en charge de nombreux formats de fichiers. Optimisé pour économiser au maximum la batterie.';

  @override
  String get welcomeAllFilesDesc =>
      'Fortement recommandé pour une analyse professionnelle afin de localiser des chansons dans des dossiers non standard (Téléchargements, Telegram, dossiers personnalisés).';

  @override
  String get welcomeInstructionConnectDesc =>
      'Branchez votre téléphone ou appareil à un ordinateur personnel à l\'aide d\'un câble de données USB standard.';

  @override
  String get welcomeInstructionDownloadDesc =>
      'Alternativement, téléchargez les fichiers directement à l\'aide d\'un navigateur web ou d\'un autre utilitaire de téléchargement sur l\'appareil lui-même.';

  @override
  String get welcomeInstructionTransferDesc =>
      'Copiez vos fichiers musicaux (formats pris en charge : .mp3, .flac, .m4a, .wav) directement dans le dossier standard \'Music\' ou \'Download\' de votre appareil.';

  @override
  String get welcomeMusicAudioDesc =>
      'Requeri pour découvrir et lire les pistes audio standard stockées dans la mémoire de votre appareil.';

  @override
  String get welcomeNoSongsDesc =>
      'Nous n\'avons trouvé aucun fichier audio pris en charge (MP3, FLAC, WAV, M4A, OGG) dans la mémoire de votre appareil.';

  @override
  String get welcomeNotificationDesc =>
      'Requis pour afficher les commandes de lecture et les widgets de notification active dans votre barre système.';

  @override
  String get welcomeScanningFoldersDesc =>
      'Analyse de tous les dossiers et sous-dossiers pour trouver des fichiers audio.';

  @override
  String get whyInternetUsed => 'Pourquoi Internet est utilisé';

  @override
  String get whyInternetUsedDesc =>
      '• Synchronisation des paroles dynamiques : Utilisé uniquement pour récupérer et télécharger en toute sécurité les paroles synchronisées (formats LRC) à partir de bases de données en ligne. Aucune donnée personnelle, paramètre ou fichier multimédia n\'est jamais téléversé ou partagé.';

  @override
  String get whyPermissionsUsed => 'Pourquoi les autorisations sont utilisées';

  @override
  String get whyPermissionsUsedDesc =>
      '• Accès stockage / médias : Requis pour découvrir, lire et indexer les pistes audio locales stockées sur votre appareil.\n• Notifications : Requis pour afficher les widgets de contrôle de lecture dans la barre d\'état et le tiroir système.';

  @override
  String get willPlayNext => 'Sera lu ensuite';

  @override
  String get year => 'Année';

  @override
  String get supportUs => 'Nous soutenir';

  @override
  String get supportUsDesc =>
      'Aider à garder Looper Player vivant et open-source';

  @override
  String get supportDevelopment => 'Soutenir le développement';

  @override
  String get supportDevelopmentDesc =>
      'Looper Player est 100% gratuit et open-source. Si vous aimez l\'utiliser, pensez à soutenir le créateur par un don. Chaque contribution aide à maintenir le projet actif !';

  @override
  String get useCustomFont => 'Utiliser une police personnalisée';

  @override
  String get useCustomFontDesc =>
      'Utiliser Jost ou d\'autres polices personnalisées. Sinon, DM Sans est utilisée.';

  @override
  String get selectFontFamily => 'Sélectionner la famille de polices';

  @override
  String activeFont(String fontName) {
    return 'Police active : $fontName';
  }

  @override
  String get fontWeightAdjustment => 'Ajustement de la graisse de police';

  @override
  String get currentWeight => 'Graisse actuelle';

  @override
  String get useCustomFontLyrics => 'Police personnalisée pour les paroles';

  @override
  String get useCustomFontLyricsDesc =>
      'Utiliser une police et graisse personnalisées pour les paroles synchronisées';

  @override
  String get lyricsFontFamily => 'Famille de polices des paroles';

  @override
  String activeLyricsFont(String fontName) {
    return 'Police de paroles active : $fontName';
  }

  @override
  String get lyricsFontWeightAdjustment =>
      'Ajustement de la graisse des paroles';

  @override
  String get giveStarOnGithub => 'Donner une étoile sur GitHub';

  @override
  String get supportProjectLove =>
      'Soutenez le projet et montrez votre intérêt !';

  @override
  String get sortAlphabeticalAZ => 'Alphabétique (A-Z)';

  @override
  String get sortAlphabeticalZA => 'Alphabétique (Z-A)';

  @override
  String get sortRecentlyAdded => 'Récemment ajoutés';

  @override
  String get sortOldestAdded => 'Ajouts les plus anciens';

  @override
  String get sortYearNewest => 'Année (Plus récente)';

  @override
  String get sortYearOldest => 'Année (Plus ancienne)';

  @override
  String get sortMostSongs => 'Plus de chansons';

  @override
  String get sortLeastSongs => 'Moins de chansons';

  @override
  String get sortDefault => 'Par défaut';

  @override
  String get sortArtistAsc => 'Artiste (A-Z)';

  @override
  String get sortAlbumAsc => 'Album (A-Z)';

  @override
  String get sortDuration => 'Durée';

  @override
  String get myAlbums => 'Mes albums';

  @override
  String get featuredArtists => 'Artistes à la une';

  @override
  String get noSongPlaying => 'Aucun morceau en cours de lecture';

  @override
  String get nextLabel => 'Suivant';

  @override
  String get previousLabel => 'Précédent';

  @override
  String get resync => 'Resynchroniser';

  @override
  String get equalizer => 'Égaliseur';

  @override
  String get presets => 'PRÉRÉGLAGES';

  @override
  String get preAmpGain => 'Gain de préamplification';

  @override
  String get outputVolume => 'Volume de sortie';

  @override
  String get customFilterHint =>
      'Saisissez directement des paramètres de filtre audio libavfilter personnalisés (ex. volume=3dB, aecho=0.8:0.88:60:0.4) :';

  @override
  String get flowGlobalActions => 'Flux et actions globales';

  @override
  String get equalizerModeLabel => 'Mode de l\'égaliseur :';

  @override
  String get currentGainsAppliedGlobal =>
      'Réglages actuels appliqués comme paramètres globaux par défaut.';

  @override
  String get applyToGlobal => 'Appliquer au global';

  @override
  String get songSpecificResetGlobal =>
      'Paramètres spécifiques au morceau réinitialisés aux valeurs globales par défaut.';

  @override
  String get resetToGlobal => 'Réinitialiser au global';

  @override
  String get resetAllSongsEq =>
      'Réinitialiser l\'égaliseur de tous les morceaux';

  @override
  String get resetAllSongsEqConfirm =>
      'Voulez-vous vraiment effacer les réglages d\'égaliseur personnalisés de tous les morceaux de votre bibliothèque ?';

  @override
  String get allSongsEqDataReset =>
      'Toutes les données d\'égaliseur spécifiques aux morceaux ont été réinitialisées.';

  @override
  String get resetAllSongsEqData =>
      'Réinitialiser les données d\'égaliseur de tous les morceaux';

  @override
  String get equalizerTargetMode => 'Mode cible de l\'égaliseur';

  @override
  String get equalizerTargetModeDesc =>
      'Choisissez comment les réglages de l\'égaliseur s\'appliquent à votre bibliothèque musicale.';

  @override
  String get globalMode => 'Mode global';

  @override
  String get globalModeDesc =>
      'Applique les effets à tous les morceaux de façon universelle. Les réglages de l\'égaliseur restent identiques lors du changement de morceau.';

  @override
  String get songSpecificMode => 'Mode par morceau';

  @override
  String get songSpecificModeDesc =>
      'Enregistre des réglages personnalisés pour le morceau actuel uniquement. Le morceau suivant utilise par défaut un égaliseur neutre/désactivé, sauf s\'il possède son propre profil.';

  @override
  String get viewDeviceAudioCapabilities =>
      'Voir les capacités audio de l\'appareil';

  @override
  String get deviceAudioCapabilities => 'Capacités audio de l\'appareil';

  @override
  String get noPlaybackActiveCapabilities =>
      'Aucune lecture en cours ou informations sur les capacités indisponibles.';

  @override
  String get changeLyricsProvider => 'Changer de fournisseur de paroles';

  @override
  String get autoFallbackProviders => 'Fournisseurs de secours automatiques';

  @override
  String get autoFallbackProvidersDesc =>
      'Essayer automatiquement les autres fournisseurs si le principal n\'a pas de paroles';

  @override
  String get ambientColorBackground => 'Fond couleur ambiante';

  @override
  String get ambientColorBackgroundDesc =>
      'Dégradés ambiants doux et subtils dérivés de la pochette du morceau';

  @override
  String get exportLyricsLrc => 'Exporter les paroles (fichier .lrc)';

  @override
  String get saveLyricsToDevice =>
      'Enregistrer les paroles actuelles sur l\'appareil';

  @override
  String get noLyricsToExport => 'Aucune parole disponible à exporter';

  @override
  String get useCustomLyricsLrc =>
      'Utiliser des paroles personnalisées (fichier LRC)';

  @override
  String get selectLocalLrcFile =>
      'Sélectionner un fichier .lrc ou .txt local pour ce morceau';

  @override
  String get customLyricsAppliedSuccess =>
      'Paroles personnalisées appliquées avec succès !';

  @override
  String get noRecentlyPlayedTracks => 'Aucun morceau récemment écouté';

  @override
  String get close => 'Fermer';

  @override
  String get audioQualityAnalysis => 'Analyse de la qualité audio';

  @override
  String get audioQualityAnalysisDesc =>
      'Effectuer une analyse spectrale et de format audio approfondie';

  @override
  String get audioStreamDetails => 'Détails du flux audio';

  @override
  String get perChannelMetrics => 'Mesures par canal';

  @override
  String get sleepTimer => 'Minuterie de veille';

  @override
  String get stopByTime => 'ARRÊT PAR DURÉE';

  @override
  String get start => 'Démarrer';

  @override
  String get stopBySongCount => 'ARRÊT PAR NOMBRE DE MORCEAUX';

  @override
  String get cancelSleepTimer => 'Annuler la minuterie de veille';

  @override
  String get nowPlayingAllCaps => 'LECTURE EN COURS';

  @override
  String get settingsAndBackups => 'Paramètres et sauvegardes';

  @override
  String get managePreferencesLibraryData =>
      'Gérer les préférences et les données de la bibliothèque';

  @override
  String get logsClearedSuccess => 'Journaux effacés avec succès';

  @override
  String get editSongInfo => 'Modifier les infos du morceau';

  @override
  String get editAlbumInfo => 'Modifier les infos de l\'album';

  @override
  String get tapFieldToEdit => 'Appuyez sur un champ pour le modifier';

  @override
  String get alwaysBlurSheets => 'Toujours flouter les fiches';

  @override
  String get alwaysBlurSheetsDesc =>
      'Floute les fiches contextuelles même quand le thème dynamique est désactivé';

  @override
  String get removeArtwork => 'Supprimer la pochette';

  @override
  String get resetArtworkToDefault => 'Réinitialiser par défaut';

  @override
  String get artworkResetToDefault => 'Pochette réinitialisée par défaut';

  @override
  String get noEmbeddedArtworkFound =>
      'Aucune pochette intégrée trouvée pour cet album';

  @override
  String get saveChangesBtn => 'Enregistrer les modifications';

  @override
  String get enterFolderPathManually =>
      'Saisir le chemin du dossier manuellement';

  @override
  String get folderPickerManualHint =>
      'Si le sélecteur de répertoire système ne s\'ouvre pas, saisissez ou collez le chemin complet du répertoire ci-dessous :';

  @override
  String get noSupportedSongsFoundFolder =>
      'Aucun morceau pris en charge trouvé dans le dossier sélectionné';

  @override
  String get add => 'Ajouter';

  @override
  String get folderPickerClosed => 'Sélecteur de dossier fermé';

  @override
  String get buyMeCoffee => 'M\'offrir un café';

  @override
  String get typeToSearchSettings => 'Rechercher dans les paramètres…';

  @override
  String get maintainersLabel => 'Mainteneurs';

  @override
  String get personBehindLooperPlayer => 'La personne derrière LooperPlayer';

  @override
  String get blurredArtworkForLyrics => 'Pochette floutée pour les paroles';

  @override
  String get blurredArtworkForLyricsDesc =>
      'Afficher la pochette floutée en fond au lieu d\'un dégradé dynamique/statique';

  @override
  String get lyricsFontWeight => 'Graisse de police des paroles';

  @override
  String get openSourceLicenses => 'Licences open source';

  @override
  String get openSourceLicensesDesc =>
      'Bibliothèques tierces utilisées dans cette application';

  @override
  String get done => 'Terminé';

  @override
  String get lyricsNotAvailable => 'Paroles non disponibles.';

  @override
  String get lyricsNotAvailableHint =>
      'Importez un fichier .lrc ou .txt pour ajouter les paroles de ce morceau';

  @override
  String get importLyricsFile => 'Importer un fichier de paroles';

  @override
  String get approximatedSyncNoWordTimings =>
      'Synchronisation approximative (sans minutage par mot)';

  @override
  String get lyricsSyncHelp => 'Aide à la synchronisation des paroles';

  @override
  String get simpleModeLabel => 'Mode simple';

  @override
  String get advancedModeLabel => 'Mode avancé';

  @override
  String get tips => 'Astuces';

  @override
  String get gotIt => 'Compris';

  @override
  String get lyricsSyncStudio => 'Studio de synchronisation des paroles';

  @override
  String get lyricsTextLabel => 'Texte des paroles';

  @override
  String get lyricsTextHelperDesc =>
      'Une ligne par vers. Les outils de synchronisation ci-dessous associent des horodatages à ces lignes.';

  @override
  String get quickSync => 'Synchronisation rapide';

  @override
  String get autoAdvanceAfterStamping =>
      'Avancer automatiquement après l\'horodatage';

  @override
  String get advancedSync => 'Synchronisation avancée';

  @override
  String get useCurrentTime => 'Utiliser l\'heure actuelle';

  @override
  String get playbackAssist => 'Assistant de lecture';

  @override
  String get timeShift => 'Décalage temporel';

  @override
  String get timeShiftDesc =>
      'Décale toutes les paroles horodatées en avant ou en arrière, ensemble.';

  @override
  String get lyricsSaveLrcExplain =>
      'L\'enregistrement crée si possible un fichier « .lrc » associé à côté du fichier audio du morceau, et l\'enregistre aussi dans la base de données locale du lecteur. Les lignes non horodatées seront interpolées automatiquement.';

  @override
  String get back => 'Retour';

  @override
  String get appSettingsLabel => 'Paramètres de l\'application';

  @override
  String get backupsAndLogs => 'Sauvegardes et journaux';

  @override
  String get backupsAndLogsDesc =>
      'Exporter, importer et gérer les données de l\'application';

  @override
  String get exportBackupJson => 'Exporter la sauvegarde (JSON)';

  @override
  String get exportBackupJsonDesc =>
      'Enregistre vos morceaux aimés et vos playlists dans un fichier JSON que vous pouvez conserver ou partager. Rien d\'autre n\'est inclus.';

  @override
  String get importBackupJson => 'Importer la sauvegarde (JSON)';

  @override
  String get importBackupJsonDesc =>
      'Fusionne les morceaux aimés et les playlists d\'un fichier de sauvegarde avec votre bibliothèque. Les données existantes ne sont jamais écrasées ni supprimées.';

  @override
  String get exportDiagnosticsLogs => 'Exporter les journaux de diagnostic';

  @override
  String get exportDiagnosticsLogsDesc =>
      'Partage le fichier journal de diagnostic de l\'application afin qu\'il puisse être examiné en cas de problème.';

  @override
  String get clearDiagnosticsLogs => 'Effacer les journaux de diagnostic';

  @override
  String get clearDiagnosticsLogsDesc =>
      'Efface définitivement le fichier journal de diagnostic stocké sur cet appareil. Cette action est irréversible.';

  @override
  String get lyricsPlainTextOrLrc => 'Paroles (texte brut ou LRC)';

  @override
  String get syncModeLine => 'LIGNE';

  @override
  String get syncModeWord => 'MOT';

  @override
  String get syncModeChar => 'CARACTÈRE';

  @override
  String get enterManually => 'Saisir manuellement';

  @override
  String get rawFilterParametersHint => 'Paramètres de filtre bruts...';

  @override
  String get searchSettingsHint => 'Rechercher dans les paramètres...';

  @override
  String get repeatTooltip => 'Répéter';

  @override
  String get favoriteTooltip => 'Favori';

  @override
  String get instructionsTooltip => 'Instructions';

  @override
  String get pasteLyricsHint => 'Collez ou saisissez les paroles ici';

  @override
  String get timestampMmSsHint => 'Horodatage (mm:ss.xx)';

  @override
  String get nowLabel => 'Maintenant';

  @override
  String get playlistNameHint => 'Nom de la playlist';

  @override
  String get songInfoUpdated => 'Infos du morceau mises à jour !';

  @override
  String get albumInfoUpdated => 'Infos de l\'album mises à jour !';

  @override
  String get failedToSaveChanges =>
      'Échec de l\'enregistrement des modifications.';

  @override
  String sleepTimerStoppingIn(String time) {
    return 'Actif : Arrêt dans $time';
  }

  @override
  String sleepTimerStoppingAfter(String time) {
    return 'Actif : Arrêt après $time';
  }

  @override
  String get selectWhenToPause => 'Choisissez quand mettre la musique en pause';

  @override
  String get selectAvatars => 'Choisir l\'avatar';

  @override
  String get selectAvatarsDesc =>
      'Choisissez l\'avatar affiché sur votre écran d\'accueil';

  @override
  String get dynamicAvatarColor => 'Couleur dynamique de l\'avatar';

  @override
  String get dynamicAvatarColorDesc =>
      'Adapte la couleur d\'accent de l\'avatar à votre thème actuel';

  @override
  String enrichingSongs(int count) {
    return 'Enrichissement de $count morceaux…';
  }

  @override
  String get noListeningHistoryYet =>
      'Aucun historique d\'écoute pour l\'instant';

  @override
  String get noListeningHistoryYetDesc =>
      'Écoutez quelques titres et votre bilan personnel — titres, artistes, albums et genres favoris — prendra vie ici.';

  @override
  String get looperAnalyze => 'Looper Analyze';

  @override
  String get totalPlays => 'Écoutes totales';

  @override
  String get listeningTime => 'Temps d\'écoute';

  @override
  String get currentStreakDays => 'Série actuelle (jours)';

  @override
  String get longestStreakDays => 'Plus longue série (jours)';

  @override
  String analyzePlaysAndSongs(int plays, int songs) {
    return '$plays écoutes • $songs titres';
  }

  @override
  String get dayPartMorningShort => 'Mat.';

  @override
  String get dayPartAfternoonShort => 'A-m';

  @override
  String get dayPartEveningShort => 'Soir';

  @override
  String get dayPartNightShort => 'Nuit';

  @override
  String get activityPattern => 'Rythme d\'activité';

  @override
  String get whenYouListenMost => 'Quand vous écoutez le plus';

  @override
  String get genreBreakdown => 'Répartition par genre';

  @override
  String get otherGenre => 'Autres';

  @override
  String get topAlbums => 'Albums favoris';

  @override
  String get topArtists => 'Artistes favoris';

  @override
  String get topSongs => 'Titres favoris';

  @override
  String playsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count écoutes',
      one: '1 écoute',
    );
    return '$_temp0';
  }

  @override
  String songsPlayedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count titres écoutés',
      one: '1 titre écouté',
    );
    return '$_temp0';
  }

  @override
  String get listeningTrend => 'Tendance d\'écoute';

  @override
  String get last30Days => '30 derniers jours';

  @override
  String errorWithDetails(String error) {
    return 'Erreur : $error';
  }

  @override
  String get selectAll => 'Tout sélectionner';

  @override
  String get playlist => 'Playlist';

  @override
  String songsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count titres',
      one: '1 titre',
    );
    return '$_temp0';
  }

  @override
  String get recentSearches => 'Recherches récentes';

  @override
  String get lyricsSourceLocalFile => 'Fichier local';

  @override
  String get lyricsSourceEmbedded => 'Métadonnées intégrées';

  @override
  String lyricsProvidedBy(String source) {
    return 'Paroles fournies par $source';
  }

  @override
  String failedToImportLyrics(String error) {
    return 'Échec de l\'importation des paroles : $error';
  }

  @override
  String get lyricsEditorLines => 'Lignes';

  @override
  String get lyricsEditorStamped => 'Horodatées';

  @override
  String lyricsEditorLineNumber(int number) {
    return 'Ligne $number';
  }

  @override
  String get lyricsEditorEmptyLine => '(Ligne vide)';

  @override
  String get lyricsEditorNotStamped => 'Pas encore horodatée';

  @override
  String get pause => 'Pause';

  @override
  String get lyricsEditorAddLineFirst =>
      'Ajoutez d\'abord au moins une ligne de paroles.';

  @override
  String get lyricsEditorSavedWithSidecar =>
      'Paroles enregistrées dans la base de données et à côté du fichier du titre.';

  @override
  String get lyricsEditorSavedDbOnly =>
      'Paroles enregistrées dans la base de données du lecteur.';

  @override
  String get lyricsEditorSaveFailed => 'Impossible d\'enregistrer les paroles.';

  @override
  String get saving => 'Enregistrement...';

  @override
  String get saveLrc => 'Enregistrer le LRC';

  @override
  String lyricsEditorSelectedLine(int index, int total) {
    return 'Ligne sélectionnée $index sur $total';
  }

  @override
  String get lyricsEditorPickLine =>
      'Choisissez une ligne dans la liste ci-dessous.';

  @override
  String get stampAndNext => 'Horodater et suivant';

  @override
  String get stampNow => 'Horodater';

  @override
  String get lyricsEditorSimpleSteps =>
      '1. Collez ou saisissez une ligne de paroles par rangée.\n2. Lancez le titre.\n3. Sélectionnez la ligne en cours.\n4. Appuyez sur « Horodater et suivant » quand vous entendez cette ligne.\n5. Enregistrez une fois terminé.';

  @override
  String get lyricsEditorAdvancedSteps =>
      '1. Modifiez directement l\'horodatage de chaque ligne.\n2. Utilisez « Utiliser l\'heure actuelle » pour capturer le temps de lecture.\n3. Utilisez les commandes de décalage pour déplacer ensemble toutes les lignes horodatées.\n4. Enregistrez pour générer le fichier `.lrc` final.';

  @override
  String get lyricsEditorTipsText =>
      '- Si certaines lignes ne sont pas horodatées, le moteur de Flick remplit leurs temps automatiquement.\n- L\'enregistrement se fait à côté du titre si possible, sinon une copie liée est stockée dans la base de données.';

  @override
  String fileNotFoundOrInaccessible(String title) {
    return 'Fichier introuvable ou inaccessible : $title';
  }

  @override
  String playbackFailedCorrupted(String title) {
    return 'Échec de la lecture : impossible de charger ou de lire « $title ». Vérifiez que le fichier n\'est pas corrompu.';
  }

  @override
  String shareSongText(String title) {
    return 'Écoute ce titre : $title';
  }

  @override
  String shareSongsText(int count) {
    return 'Écoute ces $count titres';
  }

  @override
  String noSettingsFoundFor(String query) {
    return 'Aucun paramètre trouvé pour « $query »';
  }

  @override
  String get chooseQuickAccentColors => 'Choisir une couleur d\'accent rapide';

  @override
  String get fontWeight => 'Graisse de police';

  @override
  String get changeBaseFontWeight =>
      'Modifier la graisse de base de la police personnalisée';

  @override
  String lyricsFontWeightValue(int weight) {
    return 'Graisse de police des paroles : $weight';
  }

  @override
  String get equalizerSearchDesc =>
      'Régler l\'égaliseur 18 bandes et les préréglages audio';

  @override
  String get stopServiceSearchDesc =>
      'Arrêter la lecture et fermer l\'app lorsqu\'elle est balayée hors des apps récentes';

  @override
  String get scanNewFolderDesc =>
      'Analyser un nouveau dossier à la recherche de fichiers audio';

  @override
  String get includeOtherDeviceAudioShortDesc =>
      'Sonneries, notifications et audio des messageries';

  @override
  String get excludedFolders => 'Dossiers exclus';

  @override
  String get excludedFoldersSearchDesc =>
      'Ignorer certains dossiers lors de l\'analyse';

  @override
  String get clearLibraryData => 'Effacer les données de la bibliothèque';

  @override
  String get looperPlayerVersion => 'Version de Looper Player';

  @override
  String versionLabel(String version) {
    return 'Version $version';
  }

  @override
  String get none => 'Aucun';

  @override
  String foldersSkippedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dossiers ignorés lors de l\'analyse',
      one: '1 dossier ignoré lors de l\'analyse',
    );
    return '$_temp0';
  }

  @override
  String get excludedFoldersDesc =>
      'Les titres de ces dossiers sont ignorés lors de l\'analyse, même s\'ils se trouvent dans un dossier que vous avez ajouté.';

  @override
  String get noExcludedFoldersYet => 'Aucun dossier exclu pour l\'instant.';

  @override
  String get excludeAFolder => 'Exclure un dossier';

  @override
  String get equalizerEnabled18Band => 'Activé (égaliseur MPV 18 bandes)';

  @override
  String get disabled => 'Désactivé';

  @override
  String get noIndexedFoldersYet => 'Aucun dossier indexé pour l\'instant';

  @override
  String get noIndexedFoldersYetDesc =>
      'Utilisez « Analyser à nouveau la bibliothèque » pour découvrir les dossiers du stockage.';

  @override
  String get eqDynamicRangeCompressor => 'Compresseur de dynamique';

  @override
  String get eqThreshold => 'Seuil';

  @override
  String get eqRatio => 'Ratio';

  @override
  String get eqAttack => 'Attaque';

  @override
  String get eqRelease => 'Relâchement';

  @override
  String get eqHeadphoneCrossfeedWidth => 'Crossfeed et largeur pour casque';

  @override
  String get eqBinauralCrossfeed => 'Crossfeed binaural';

  @override
  String get eqCrossfeedStrength => 'Intensité du crossfeed';

  @override
  String get eqStereoWidening => 'Élargissement stéréo';

  @override
  String get eqWideningFactor => 'Facteur d\'élargissement';

  @override
  String get eqLoudnessNormalization => 'Normalisation du volume';

  @override
  String get eqTargetLoudness => 'Volume cible';

  @override
  String get eqToneShelving => 'Correction de tonalité (graves / aigus)';

  @override
  String get eqBassShelf => 'Shelf des graves';

  @override
  String get eqTrebleShelf => 'Shelf des aigus';

  @override
  String get eqTempoPitchControls => 'Réglages du tempo et de la hauteur';

  @override
  String get eqPitchShift => 'Décalage de hauteur';

  @override
  String get eqTempoSpeed => 'Vitesse du tempo';

  @override
  String get eqVoiceSilenceControls => 'Réglages de la voix et des silences';

  @override
  String get eqSilenceTrimming => 'Suppression des silences';

  @override
  String get eqSilenceThreshold => 'Seuil de silence';

  @override
  String get eqSpeechEnhancementFilter => 'Filtre d\'amélioration de la voix';

  @override
  String get eqHighpassCutoff => 'Coupure passe-haut';

  @override
  String get eqLowpassCutoff => 'Coupure passe-bas';

  @override
  String get eqRetroRoomEffects => 'Effets rétro et de salle';

  @override
  String get eqLofiEffect => 'Effet lo-fi (bitcrusher 8 bits)';

  @override
  String get eqStudioRoomReverb => 'Réverbération de studio (écho)';

  @override
  String get eqVirtualSurround => 'Son surround virtuel 5.1';

  @override
  String get eqRawFilterConsole => 'Console de filtres FFmpeg bruts';

  @override
  String get eqSwitchToSliders => 'Passer aux curseurs';

  @override
  String get eqSwitchToGraph => 'Passer au graphique';

  @override
  String get on => 'Activé';

  @override
  String get off => 'Désactivé';

  @override
  String get eqSongSpecificActive => 'Réglages propres au titre actifs';

  @override
  String get eqUsingGlobalDefault => 'Réglages globaux par défaut utilisés';

  @override
  String get eqInteractiveGraphHint =>
      'GRAPHIQUE INTERACTIF (FAITES GLISSER LES POINTS VERTICALEMENT)';

  @override
  String get eq18BandHint =>
      'ÉGALISEUR 18 BANDES (FAITES DÉFILER HORIZONTALEMENT)';

  @override
  String get eqSongSpecific => 'Propre au titre';

  @override
  String get eqGlobalDefault => 'Global par défaut';

  @override
  String get eqEditScopeNote =>
      'Les modifications faites pendant la lecture d\'un titre ne s\'appliquent qu\'à ce titre. Pour définir le réglage global, modifiez sans titre en lecture ou utilisez l\'action « Appliquer au global ».';

  @override
  String get presetFlat => 'Neutre';

  @override
  String get presetBassBooster => 'Renfort des graves';

  @override
  String get presetTrebleBooster => 'Renfort des aigus';

  @override
  String get presetVocalBooster => 'Renfort vocal';

  @override
  String get presetElectronic => 'Électronique';

  @override
  String get presetRock => 'Rock';

  @override
  String get presetPop => 'Pop';

  @override
  String get presetJazz => 'Jazz';

  @override
  String get save => 'Enregistrer';

  @override
  String get savePreset => 'Enregistrer le préréglage';

  @override
  String get presetName => 'Nom du préréglage';

  @override
  String get deletePreset => 'Supprimer le préréglage';

  @override
  String deletePresetConfirm(String name) {
    return 'Supprimer le préréglage « $name » ?';
  }

  @override
  String get noLyricsSource => 'Aucune source de paroles';

  @override
  String lyricsSourceLabel(String source) {
    return 'Source : $source';
  }

  @override
  String get lyricsSourceLocalSidecar => 'Fichier local associé (.lrc)';

  @override
  String get lyricsSourceCustomFile => 'Fichier LRC personnalisé';

  @override
  String get lyricsSourceNotFoundOnline => 'Introuvables en ligne';

  @override
  String get lyricsProviderLocal => 'Local';

  @override
  String get checkingLocalLyrics => 'Recherche de paroles locales/intégrées...';

  @override
  String fetchingLyricsFrom(String provider) {
    return 'Récupération des paroles depuis $provider...';
  }

  @override
  String get loadedLocalLyrics => 'Paroles locales/intégrées chargées !';

  @override
  String get noLocalLyricsFound => 'Aucune parole locale ou intégrée trouvée';

  @override
  String lyricsUpdatedFrom(String provider) {
    return 'Paroles mises à jour depuis $provider !';
  }

  @override
  String noLyricsFoundOn(String provider) {
    return 'Aucune parole trouvée sur $provider';
  }

  @override
  String get gestureTips => 'Astuces gestuelles';

  @override
  String get gestureTipsDesc =>
      'Appui, appui long, pincement pour zoomer et plus';

  @override
  String get exportLyrics => 'Exporter les paroles';

  @override
  String lyricsExportedTo(String path) {
    return 'Paroles exportées vers : $path';
  }

  @override
  String failedToExportLyrics(String error) {
    return 'Échec de l\'exportation des paroles : $error';
  }

  @override
  String get gestureTapLine => 'Appuyez sur une ligne';

  @override
  String get gestureTapLineDesc =>
      'Passe directement à ce passage des paroles.';

  @override
  String get gestureLongPressLine => 'Appuyez longuement sur une ligne';

  @override
  String get gestureLongPressLineDesc =>
      'Commence la sélection de lignes pour créer une carte de paroles à partager. Appuyez sur d\'autres lignes pour étendre la sélection.';

  @override
  String get gesturePinch => 'Pincez avec deux doigts';

  @override
  String get gesturePinchDesc =>
      'Ajustez la taille du texte des paroles à votre goût.';

  @override
  String get gestureSwipeDown => 'Balayez vers le bas';

  @override
  String get gestureSwipeDownDesc =>
      'Ferme l\'écran des paroles et revient au lecteur.';

  @override
  String get lyricsGestures => 'Gestes des paroles';

  @override
  String get lyricsGesturesIntro =>
      'Quelques fonctions de cet écran qui ne sont pas toujours évidentes :';

  @override
  String linesSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lignes sélectionnées',
      one: '1 ligne sélectionnée',
    );
    return '$_temp0';
  }

  @override
  String get couldNotGenerateShareImage =>
      'Impossible de générer l\'image à partager.';

  @override
  String get couldNotGenerateImage => 'Impossible de générer l\'image.';

  @override
  String get savedToGallery => 'Enregistrée dans la galerie.';

  @override
  String get galleryPermissionDenied =>
      'L\'autorisation d\'accès à la galerie a été refusée.';

  @override
  String get couldNotSaveToGallery =>
      'Impossible d\'enregistrer l\'image dans la galerie.';

  @override
  String get shareLyrics => 'Partager les paroles';

  @override
  String get backgroundColor => 'Couleur d\'arrière-plan';

  @override
  String get lyricsTextColor => 'Couleur du texte des paroles';

  @override
  String get saveToGallery => 'Enregistrer dans la galerie';

  @override
  String get preparing => 'Préparation...';

  @override
  String get trackTitle => 'Titre du morceau';

  @override
  String get composer => 'Compositeur';

  @override
  String get unknownGenre => 'Genre inconnu';

  @override
  String get releaseYear => 'Année de sortie';

  @override
  String get notAvailable => 'N/D';

  @override
  String get recordLabel => 'Label';

  @override
  String get copyright => 'Copyright';

  @override
  String get encoder => 'Encodeur';

  @override
  String get fileName => 'Nom du fichier';

  @override
  String get fileFormat => 'Format du fichier';

  @override
  String get fileSize => 'Taille du fichier';

  @override
  String get absolutePath => 'Chemin absolu';

  @override
  String get playCount => 'Nombre d\'écoutes';

  @override
  String playCountTimes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fois',
      one: '1 fois',
    );
    return '$_temp0';
  }

  @override
  String get lastPlayed => 'Dernière écoute';

  @override
  String get filePath => 'Chemin du fichier';

  @override
  String get rescan => 'Réanalyser';

  @override
  String get codec => 'Codec';

  @override
  String get container => 'Conteneur';

  @override
  String get sampleRate => 'Fréquence d\'échantillonnage';

  @override
  String get bitDepth => 'Profondeur de bits';

  @override
  String get decodedFormat => 'Format décodé';

  @override
  String get bitrate => 'Débit binaire';

  @override
  String get channels => 'Canaux';

  @override
  String get nyquist => 'Nyquist';

  @override
  String get dynamicRange => 'Plage dynamique';

  @override
  String get peak => 'Crête';

  @override
  String get truePeak => 'Crête réelle';

  @override
  String get clipping => 'Écrêtage';

  @override
  String get cutoff => 'Coupure';

  @override
  String get samples => 'Échantillons';

  @override
  String channelShort(int channel) {
    return 'Can. $channel';
  }

  @override
  String get noneClean => 'Aucun (propre)';

  @override
  String get reanalyzingAudio => 'Nouvelle analyse du flux audio...';

  @override
  String get analyzingAudio => 'Analyse du flux audio...';

  @override
  String sampleRateHz(int rate) {
    return 'Fréquence d\'échantillonnage : $rate Hz';
  }

  @override
  String nyquistKhz(String khz) {
    return 'Nyquist : $khz kHz';
  }

  @override
  String get qualityLossless => 'Sans perte';

  @override
  String get qualityHigh => 'Haute qualité';

  @override
  String get qualityStandard => 'Qualité standard';

  @override
  String get qualityAudio => 'Audio';

  @override
  String get addCustomFolder => 'Ajouter un dossier personnalisé';

  @override
  String get addCustomFolderDesc =>
      'Si votre musique se trouve dans un dossier au nom différent ou sur une carte SD, ajoutez-le directement.';

  @override
  String get indexingYourLibrary => 'INDEXATION DE VOTRE BIBLIOTHÈQUE...';

  @override
  String get indexingYourLibraryDesc =>
      'Ajout des titres, pochettes et paroles de vos morceaux.';

  @override
  String welcomeStep(String step, String title) {
    return 'ÉTAPE $step : $title';
  }

  @override
  String get includeOtherDeviceAudioAlarmsDesc =>
      'Sonneries, notifications, alarmes et audio des messageries';

  @override
  String get version => 'Version';

  @override
  String get noIndexedFoldersDesktopDesc =>
      'Utilisez « Analyser à nouveau la bibliothèque » pour découvrir les dossiers de stockage';

  @override
  String get playedLabel => 'Écoutés';

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
      other: '$count titres',
      one: '1 titre',
    );
    return '$_temp0';
  }

  @override
  String songsLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count titres restants',
      one: '1 titre restant',
    );
    return '$_temp0';
  }

  @override
  String sleepTimerWithRemaining(String remaining) {
    return 'Minuterie de veille ($remaining)';
  }

  @override
  String get trackInfoSection => 'INFOS DU MORCEAU';

  @override
  String get detailsSection => 'DÉTAILS';

  @override
  String get lyricsSection => 'PAROLES';

  @override
  String get editLyricsHint =>
      'Saisissez les paroles en texte brut ou au format LRC synchronisé [00:00.00]...';

  @override
  String addedSongsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count titres ajoutés',
      one: '1 titre ajouté',
    );
    return '$_temp0';
  }

  @override
  String get chooseInternalStorageFolder =>
      'Veuillez choisir un dossier du stockage interne ou de la carte SD de cet appareil.';

  @override
  String get appCrashedTitle => 'Looper Player a planté';

  @override
  String get appCrashedDesc =>
      'Une erreur inattendue s\'est produite au démarrage. Un rapport de diagnostic a été généré.';

  @override
  String get appCrashedDetails =>
      'Une erreur s\'est produite lors de l\'initialisation de la base de données ou des services de l\'app. Cela peut arriver si l\'accès au stockage est restreint ou si les fichiers de la base de données sont corrompus.';

  @override
  String get crashReportSaved =>
      'Rapport de diagnostic enregistré dans le dossier de support de l\'application.';

  @override
  String get shareLog => 'Partager le journal';

  @override
  String get restartApp => 'Redémarrer l\'app';

  @override
  String get updateAvailableOnPlay =>
      'Une nouvelle version est disponible sur Google Play.';

  @override
  String updateAvailableOnGithub(String version) {
    return 'La version $version est disponible sur GitHub.';
  }

  @override
  String get updateAvailable => 'Mise à jour disponible';

  @override
  String get updateAvailableTitle => 'Mise à jour disponible !';

  @override
  String get visit => 'OUVRIR';

  @override
  String get updateDownloaded => 'Mise à jour téléchargée';

  @override
  String get restartToInstallUpdate =>
      'Redémarrez Looper Player pour l\'installer.';

  @override
  String get restart => 'REDÉMARRER';

  @override
  String backupImportedSummary(int favorites, int stats, int playlists) {
    return 'Sauvegarde importée : $favorites favoris et $stats statistiques d\'écoute fusionnés, $playlists playlists synchronisées';
  }

  @override
  String get backupExportFailed =>
      'Échec de l\'exportation de la sauvegarde : une erreur interne s\'est produite lors de l\'enregistrement du fichier.';

  @override
  String get backupImportFailed =>
      'Échec de l\'importation de la sauvegarde : le fichier est illisible ou son format n\'est pas valide.';

  @override
  String get stereo => 'Stéréo';

  @override
  String get mono => 'Mono';
}
