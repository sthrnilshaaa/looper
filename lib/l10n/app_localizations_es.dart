// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get about => 'Acerca de';

  @override
  String get aboutAndMaintainers => 'Acerca de y desarrolladores';

  @override
  String get aboutApp => 'Acerca de la aplicación';

  @override
  String get aboutLooperPlayer => 'ACERCA DE LOOPER PLAYER';

  @override
  String get accentColor => 'Color de acento';

  @override
  String get accentColorDesc =>
      'Seleccionar manualmente el color de acento del tema';

  @override
  String get acousticSpectralAnalysis => 'ANÁLISIS ACÚSTICO Y ESPECTRAL';

  @override
  String get activeCallCannotPlay =>
      'Reproducción bloqueada: No se puede reproducir música durante una llamada activa';

  @override
  String get adaptColorsArtwork =>
      'Adaptar colores de la aplicación al arte del álbum';

  @override
  String addedTo(String name) {
    return 'Añadido a $name';
  }

  @override
  String get addedToQueue => 'Añadido a la cola';

  @override
  String get addFolder => 'Añadir carpeta';

  @override
  String get addToFavorites => 'Añadir a favoritos';

  @override
  String get addToPlaylists => 'Añadir a listas de reproducción';

  @override
  String get addToQueue => 'Añadir a la cola';

  @override
  String get album => 'Álbum';

  @override
  String get albums => 'Álbumes';

  @override
  String get albumsRowDesc => 'Estante horizontal de álbumes';

  @override
  String get allFilesAccess => 'ACCESO A TODOS LOS ARCHIVOS (RECOMENDADO)';

  @override
  String get allSongs => 'Todas las canciones';

  @override
  String get appDetailsCreator =>
      'Detalles del creador, la aplicación y el equipo de diseño';

  @override
  String get appearance => 'Apariencia';

  @override
  String get appInfoPrivacy => 'INFORMACIÓN Y PRIVACIDAD';

  @override
  String get appTitle => 'Looper Player';

  @override
  String get artist => 'Artista';

  @override
  String get artists => 'Artistas';

  @override
  String get artistsRowDesc => 'Estante horizontal de artistas';

  @override
  String get ascending => 'Ascendente';

  @override
  String get audioCrossfade => 'Fundido cruzado de audio';

  @override
  String get audioCrossfadeDesc =>
      'Superpone las pistas suavemente al cambiar de canción';

  @override
  String get audioFocusDenied =>
      'Reproducción pausada: el sistema denegó el enfoque de audio';

  @override
  String get audioPlayback => 'Audio y reproducción';

  @override
  String get audioPlaybackDesc =>
      'Ajustes de fundido cruzado, intervalo de silencio y atenuación';

  @override
  String get autoCrossfadeDuration => 'Duración del fundido cruzado automático';

  @override
  String get autoCrossfadeDurationDesc =>
      'Duración de la superposición al cambiar automáticamente';

  @override
  String get backToMainView => 'VOLVER A LA VISTA PRINCIPAL';

  @override
  String get cancel => 'Cancelar';

  @override
  String get categories => 'Categorías';

  @override
  String get center => 'Centro';

  @override
  String get clear => 'Limpiar';

  @override
  String get clearQueue => 'Limpiar';

  @override
  String get connectDevice => 'CONECTAR DISPOSITIVO';

  @override
  String get corePurpose => 'Propósito principal';

  @override
  String get corePurposeDesc =>
      'Looper Player es un reproductor de audio de alta fidelidad, primero sin conexión, diseñado para entusiastas de la música que desean un control absoluto sobre su biblioteca local, reproducción sin silencios y desplazamiento fluido de letras sincronizadas.';

  @override
  String get create => 'Crear';

  @override
  String get createPlaylist => 'Crear lista de reproducción';

  @override
  String get creatorAndMaintainer => 'Creador y desarrollador';

  @override
  String get customAccentColor => 'Color de acento personalizado';

  @override
  String get customizeColorsTheme =>
      'Personalizar colores de la aplicación, el tema y fondos de letras';

  @override
  String get dateAdded => 'Fecha de adición';

  @override
  String get deepStorageScanProgress => 'ESCANEO PROFUNDO EN PROGRESO...';

  @override
  String get delete => 'Eliminar';

  @override
  String get deleteFile => 'Eliminar archivo';

  @override
  String get deletePlaylist => 'Eliminar lista de reproducción';

  @override
  String deletePlaylistConfirm(String name) {
    return '¿Estás seguro de que quieres eliminar \"$name\"?';
  }

  @override
  String get deleteSong => 'Eliminar canción';

  @override
  String get deleteSongConfirm =>
      '¿Estás seguro de que quieres eliminar esta canción del disco?';

  @override
  String get descending => 'Descendente';

  @override
  String get designerAndMaintainer => 'Diseñador y desarrollador';

  @override
  String get disableBlurEffects => 'Desactivar efectos de desenfoque';

  @override
  String get disableSquigglyProgressBar =>
      'Desactivar animación de barra de progreso ondulada';

  @override
  String get downloadAudioDirectly => 'DESCARGAR AUDIO DIRECTAMENTE';

  @override
  String get downloadingLyricsOffline =>
      'Descargando letras para uso sin conexión...';

  @override
  String get downloadMissingArtwork => 'Descargar arte faltante';

  @override
  String get downloadMissingArtworkDesc =>
      'Descarga automáticamente arte de portada de alta resolución de iTunes';

  @override
  String get duration => 'Duración';

  @override
  String get dynamicAccentColor => 'Color de acento dinámico';

  @override
  String get dynamicAccentColorDesc =>
      'Actualiza dinámicamente solo el color de acento según la carátula';

  @override
  String get dynamicBgOnlyLyrics => 'Fondo dinámico solo para letras';

  @override
  String get dynamicColorActiveLyrics => 'Color dinámico de línea activa';

  @override
  String get dynamicColorActiveLyricsDesc =>
      'Usar los colores extraídos de la carátula para la línea de letra que se está reproduciendo';

  @override
  String get dynamicLyricsBg => 'Fondo dinámico de letras';

  @override
  String get dynamicLyricsBgDesc =>
      'Aplicar desenfoque de portada al fondo de la pantalla de letras';

  @override
  String get dynamicTheming => 'Temas dinámicos';

  @override
  String get emptyLibraryDesc =>
      'No pudimos encontrar archivos de música compatibles en su biblioteca. Añada carpetas o realice un escaneo.';

  @override
  String get enableNetworkLyricsArt =>
      'Permitir uso de red para letras en línea y arte de artista';

  @override
  String get enablePlayerGradient => 'Degradado de la pantalla de música';

  @override
  String get enablePlayerGradientDesc =>
      'Activar el fondo degradado radial de acento en la pantalla de reproducción';

  @override
  String get fadeDuration => 'Duración del desvanecimiento';

  @override
  String get fadeDurationDesc =>
      'Duración del efecto de desvanecimiento al reproducir/pausar/detener';

  @override
  String get fadeOnSeek => 'Desvanecimiento al buscar';

  @override
  String get fadeOnSeekDesc =>
      'Desvanece suavemente el volumen al buscar en la pista';

  @override
  String get fadePlayPauseStop =>
      'Desvanecimiento al reproducir/pausar/detener';

  @override
  String get fadePlayPauseStopDesc =>
      'Desvanece suavemente el volumen al reproducir, pausar o detener';

  @override
  String get favorites => 'Favoritos';

  @override
  String get fileInformation => 'Información del archivo';

  @override
  String get flatProgressBar => 'Barra de progreso plana';

  @override
  String get folders => 'Carpetas';

  @override
  String get genre => 'Género';

  @override
  String get genres => 'Géneros';

  @override
  String get genresRowDesc => 'Estante horizontal de géneros musicales';

  @override
  String get goStart => 'COMENZAR';

  @override
  String get grant => 'CONCEDER';

  @override
  String get granted => 'CONCEDIDO';

  @override
  String get history => 'Historial';

  @override
  String get home => 'Inicio';

  @override
  String get homeDarkness => 'Oscurecimiento de la pantalla de inicio';

  @override
  String get homeDarknessDesc =>
      'Ajustar el oscurecimiento del fondo para la pantalla de inicio';

  @override
  String get homeDashboardSettings => 'Ajustes del panel de inicio';

  @override
  String get homeDashboardSettingsDesc =>
      'Personaliza las filas horizontales en tu pantalla de inicio';

  @override
  String get internetMode => 'Modo Internet';

  @override
  String get keepBackgroundGradient => 'Mantener gradiente de fondo';

  @override
  String get keepBackgroundGradientDesc =>
      'Mantener el gradiente de fondo en todas las pantallas de la aplicación';

  @override
  String get language => 'Idioma';

  @override
  String get left => 'Izquierda';

  @override
  String get library => 'Biblioteca';

  @override
  String get libraryDarkness => 'Oscurecimiento de la pantalla de biblioteca';

  @override
  String get libraryDarknessDesc =>
      'Ajustar el oscurecimiento del fondo para la pantalla de biblioteca';

  @override
  String get libraryFoldersSync =>
      'Carpetas, reescaneos, restablecimiento de base de datos y sincronización sin conexión';

  @override
  String get librarySettings => 'Configuración de la biblioteca';

  @override
  String get loadingMusicLibrary => 'CARGANDO BIBLIOTECA DE MÚSICA';

  @override
  String get loadingMusicLibraryDesc =>
      'Construyendo índices premium, configurando controladores de hardware y optimizando cachés visuales.';

  @override
  String get loadingPhase1 => 'INTERROGANDO ALMACENAMIENTO...';

  @override
  String get loadingPhase2 => 'REGENERANDO MOTOR DE MÚSICA...';

  @override
  String get loadingPhase3 => 'EXTRAYENDO INFORMACIÓN ACÚSTICA...';

  @override
  String get loadingPhase4 => 'OPTIMIZANDO MEMORIA DE REPRODUCCIÓN...';

  @override
  String get lyrics => 'Letras';

  @override
  String get lyricsAlignment => 'Alineación de la letra';

  @override
  String get lyricsAlignmentDesc =>
      'Alinear la posición del texto para las letras con desplazamiento';

  @override
  String get lyricsDarkness => 'Oscurecimiento de la pantalla de letras';

  @override
  String get lyricsDarknessDesc =>
      'Ajustar el oscurecimiento del fondo para la pantalla de letras';

  @override
  String get lyricsProvider => 'Proveedor de letras';

  @override
  String get lyricsProviderDesc =>
      'Letras en línea obtenidas de lrclib.net (LRCLIB)';

  @override
  String get maintainersAndDesigners => 'Desarrolladores y diseñadores';

  @override
  String get manageAudioFocus => 'Gestionar el enfoque de audio';

  @override
  String get manageAudioFocusDesc =>
      'Solicita y responde a los cambios de enfoque de audio del sistema';

  @override
  String get manageAudioFocusTitle => 'Gestionar el enfoque de audio';

  @override
  String get manageLanguageAndFocus =>
      'Gestionar preferencias de idioma y enfoque de llamadas';

  @override
  String get audioFocusGetFocus => 'Obtener enfoque';

  @override
  String get audioFocusGetFocusDesc =>
      'Solicitar el enfoque de audio al comenzar la reproducción.';

  @override
  String get audioFocusReleaseFocus => 'Liberar enfoque';

  @override
  String get audioFocusReleaseFocusDesc =>
      'Liberar el enfoque de audio cuando la reproducción se pausa o se detiene.';

  @override
  String get audioFocusStopOnOtherSession =>
      'Detener la música con otra sesión de música';

  @override
  String get audioFocusStopOnOtherSessionDesc =>
      'Pausar la reproducción cuando otra app empieza a reproducir audio.';

  @override
  String get audioFocusRestartOnGain =>
      'Reanudar la música al recuperar el enfoque';

  @override
  String get audioFocusRestartOnGainDesc =>
      'Reanudar la reproducción automáticamente cuando se recupera el enfoque de audio, solo si la reproducción fue interrumpida por la pérdida de enfoque.';

  @override
  String get pauseOnDuckTitle => 'Pausar al atenuar';

  @override
  String get pauseOnDuckDesc =>
      'Pausar la reproducción en lugar de bajar el volumen cuando otra app reproduce un sonido breve (p. ej. notificaciones, indicaciones de navegación).';

  @override
  String get resumeOnBluetoothConnectTitle => 'Reanudar al conectar Bluetooth';

  @override
  String get resumeOnBluetoothConnectDesc =>
      'Reanudar la reproducción automáticamente cuando un dispositivo de audio Bluetooth (auriculares, kit de coche) se vuelve a conectar.';

  @override
  String get manualCrossfadeDuration => 'Duración del fundido cruzado manual';

  @override
  String get manualCrossfadeDurationDesc =>
      'Duración de la superposición al cambiar manualmente';

  @override
  String get matchingLyrics => 'LETRAS COINCIDENTES';

  @override
  String get metadataDetails => 'Detalles de metadatos';

  @override
  String get mostPlayed => 'Más reproducido';

  @override
  String get musicAudioAccess => 'ACCESO A MÚSICA Y AUDIO';

  @override
  String get musicDarkness => 'Oscurecimiento del reproductor de música';

  @override
  String get musicDarknessDesc =>
      'Ajustar el oscurecimiento del fondo para la pantalla del reproductor de música';

  @override
  String get musicLibrary => 'Biblioteca de música';

  @override
  String get muteOrPauseCalls =>
      'Silenciar o pausar durante llamadas y otra actividad de audio';

  @override
  String get newPlaylist => 'Nueva lista de reproducción';

  @override
  String get newTitle => 'Nuevo título';

  @override
  String get nextUp => 'A continuación';

  @override
  String get noAlbumsFound => 'No se encontraron álbumes';

  @override
  String get noArtistsFound => 'No se encontraron artistas';

  @override
  String get noFavoritesYet => 'Aún no hay favoritos';

  @override
  String get noHistoryYet => 'Sin historial';

  @override
  String get noLyrics => 'No se encontraron letras';

  @override
  String get noMusicDetected => 'NO SE DETECTÓ MÚSICA';

  @override
  String get noPlaylistsCreated =>
      'Aún no se han creado listas de reproducción.';

  @override
  String get noPlaylistsYet => 'No hay listas de reproducción';

  @override
  String get noResultsFound => 'No se encontraron resultados';

  @override
  String get noSongsFound => 'No se encontraron canciones';

  @override
  String get notificationAccess => 'ACCESO A NOTIFICACIONES';

  @override
  String get nowPlaying => 'Reproduciendo ahora';

  @override
  String get performanceOptimizerDashboard =>
      'Panel del optimizador de rendimiento';

  @override
  String get performanceOptimizerDashboardDesc =>
      'Muestra una superposición con estadísticas del optimizador en tiempo real';

  @override
  String get permanentFocusChangePause =>
      'Pausa por pérdida permanente de enfoque';

  @override
  String get permanentFocusChangePauseDesc =>
      'Pausa automáticamente la reproducción al perder el enfoque de audio permanentemente';

  @override
  String get plainTimestamps => 'Marcas de tiempo simples';

  @override
  String get play => 'Reproducir';

  @override
  String get playAll => 'Reproducir todo';

  @override
  String get playbackAudio => 'Reproducción e idioma';

  @override
  String get playlists => 'Listas de reproducción';

  @override
  String get playNext => 'Reproducir a continuación';

  @override
  String get playQueue => 'Cola de reproducción';

  @override
  String get pressBackExit => 'Presione atrás de nuevo para salir';

  @override
  String get privacySafety => 'Privacidad y seguridad';

  @override
  String get privacySafetyDesc =>
      '100% privado y sin conexión por defecto. Sus canciones, historial de reproducción, favoritos y configuración permanecen estrictamente dentro de una base de datos segura Isar en su dispositivo local. No recopilamos, rastreamos ni compartimos sus datos de uso.';

  @override
  String get pureBlackOled => 'Negro puro (OLED)';

  @override
  String get pureBlackOledDesc => 'Usar negro absoluto para los fondos';

  @override
  String get queue => 'Cola';

  @override
  String get queueIsEmpty => 'La cola está vacía';

  @override
  String get quickPicks => 'Selecciones rápidas';

  @override
  String get quickPicksRowDesc => 'Tu cuadrícula de canciones más reproducidas';

  @override
  String get readyToScan => 'Listo para escanear';

  @override
  String get recentlyAddedSongsRowDesc =>
      'Una lista de tus últimas importaciones';

  @override
  String get recentlyPlayed => 'Reproducido recientemente';

  @override
  String get recentPlayed => 'Reproducidas recientemente';

  @override
  String get recentRowDesc =>
      'Estante horizontal de canciones reproducidas recientemente';

  @override
  String get removedFromPlaylist => 'Eliminado de la lista de reproducción';

  @override
  String get removeFromFavorites => 'Eliminar de favoritos';

  @override
  String get removeFromPlaylist => 'Eliminar de la lista de reproducción';

  @override
  String get rename => 'Renombrar';

  @override
  String get renameFile => 'Renombrar archivo';

  @override
  String get renamePlaylist => 'Renombrar lista de reproducción';

  @override
  String get renameSong => 'Renombrar canción';

  @override
  String get reorderDashboardSections => 'Reordenar secciones del panel';

  @override
  String get reorderDashboardSectionsDesc =>
      'Arrastra y suelta para establecer el orden preferido';

  @override
  String get includeOtherDeviceAudioTitle =>
      'Incluir otro audio del dispositivo';

  @override
  String get includeOtherDeviceAudioDesc =>
      'Escanear tonos de llamada, notificaciones, alarmas y audio de WhatsApp y Telegram';

  @override
  String get rescanLibrary => 'Reescanear biblioteca';

  @override
  String get rescanStorage => 'REESCANEAR ALMACENAMIENTO';

  @override
  String get reset => 'Restablecer';

  @override
  String get resetLibrary => 'Restablecer y reescanear';

  @override
  String get resetLibraryConfirm =>
      'Esto borrará todas las canciones, álbumes y artistas y realizará un escaneo completo de tus carpetas.';

  @override
  String get resetLibraryConfirmNew =>
      'Esto eliminará todas las canciones de tu biblioteca. Tus archivos de música no se borrarán.';

  @override
  String get resetLibraryDesc =>
      'Elimina todas las canciones de tu biblioteca indexada';

  @override
  String get resumeAfterCallDesc =>
      'Reanuda la reproducción automáticamente al colgar (si se pausó por la llamada)';

  @override
  String get resumeAfterCallTitle => 'Reanudar después de una llamada';

  @override
  String get resumeOnStartDesc =>
      'Reanuda la reproducción automáticamente cuando se inicia Looper Player';

  @override
  String get resumeOnStartTitle => 'Reanudar al iniciar';

  @override
  String get persistQueueTitle => 'Persistir última cola';

  @override
  String get persistQueueDesc =>
      'Guardar la última canción y cola al reiniciar la app';

  @override
  String get keepSongProgressTitle => 'Mantener progreso de la canción';

  @override
  String get keepSongProgressDesc =>
      'Recuerda la posición de reproducción de cada canción por separado. Cambia a otra canción a mitad de camino y vuelve más tarde —incluso después de reproducir otras canciones— y continuará justo donde la dejaste en lugar de empezar de nuevo.';

  @override
  String get right => 'Derecha';

  @override
  String scanCompleteSongsDetected(int count) {
    return '¡ESCANEO COMPLETADO: $count CANCIONES DETECTADAS!';
  }

  @override
  String get scanForMusic => 'ESCANEAR MÚSICA';

  @override
  String get scanIndexLocalDesc => 'Escanear e indexar archivos locales';

  @override
  String get scanLibrary => 'Escanear biblioteca';

  @override
  String get scanningInBackground => 'Escaneando en segundo plano...';

  @override
  String get scanningLibrary => 'Escaneando biblioteca...';

  @override
  String get scanningStorage => 'ESCANEANDO ALMACENAMIENTO...';

  @override
  String get scanningStorageDesc =>
      'Explorando directorios para descubrir pistas de audio. Por favor, espere...';

  @override
  String get search => 'Buscar';

  @override
  String get searchLibraryHint => 'Buscar en toda la biblioteca';

  @override
  String get searchSongsHint => 'Buscar canciones';

  @override
  String get seekFadeDuration => 'Duración del desvanecimiento al buscar';

  @override
  String get seekFadeDurationDesc =>
      'Duración del efecto de desvanecimiento al buscar';

  @override
  String get selectAppLanguage => 'Seleccionar idioma de la aplicación';

  @override
  String get selectCustomColor => 'Seleccionar color personalizado';

  @override
  String get selectCustomFolder => 'SELECCIONAR CARPETA PERSONALIZADA';

  @override
  String get selectFolderIndex =>
      'Seleccionar carpeta para indexar archivos de música';

  @override
  String get selectSpecificFolder => 'SELECCIONAR CARPETA ESPECÍFICA';

  @override
  String get settings => 'Ajustes';

  @override
  String get share => 'Compartir';

  @override
  String get shareFile => 'Compartir archivo';

  @override
  String get showAlbumsRow => 'Mostrar fila de álbumes';

  @override
  String get showAlbumsRowDesc =>
      'Muestra una lista horizontal de álbumes en tu pantalla de inicio';

  @override
  String get showArtistsRow => 'Mostrar fila de artistas';

  @override
  String get showArtistsRowDesc =>
      'Muestra una lista horizontal de artistas en tu pantalla de inicio';

  @override
  String get showGenresRow => 'Mostrar fila de géneros';

  @override
  String get showGenresRowDesc =>
      'Muestra una lista horizontal de géneros en tu pantalla de inicio';

  @override
  String get showLess => 'Mostrar menos';

  @override
  String get showMore => 'Mostrar más';

  @override
  String get showQualityBadge => 'Mostrar insignia de calidad';

  @override
  String get showQualityBadgeDesc =>
      'Mostrar una insignia con la información de calidad de audio en la pantalla de reproducción';

  @override
  String get showRecentRow => 'Mostrar fila de reproducidos recientemente';

  @override
  String get showRecentRowDesc =>
      'Muestra una lista horizontal de canciones reproducidas recientemente en tu pantalla de inicio';

  @override
  String get silenceBetweenTracksDesc =>
      'Añade un intervalo de silencio entre pistas (0 ms para reproducción sin pausas)';

  @override
  String get silenceBetweenTracksTitle => 'Silencio entre pistas';

  @override
  String get songDeletedDbOnly =>
      'Canción eliminada de la biblioteca (archivo físico de solo lectura)';

  @override
  String get songDeletedSuccess => 'Canción eliminada con éxito';

  @override
  String get songDeleteFailed => 'Error al eliminar la canción';

  @override
  String get songDetails => 'Detalles de la canción';

  @override
  String get songDetailsAndFrequency => 'Detalles y frecuencia de la canción';

  @override
  String get songRenamedDbOnly =>
      'Canción renombrada en la biblioteca de la aplicación (archivo físico de solo lectura)';

  @override
  String get songRenamedSuccess => 'Canción renombrada con éxito';

  @override
  String get songRenameFailed => 'Error al renombrar la canción';

  @override
  String get songs => 'Canciones';

  @override
  String get songsDarkness => 'Oscurecimiento de la pantalla de canciones';

  @override
  String get songsDarknessDesc =>
      'Ajustar el oscurecimiento del fondo para la pantalla de canciones';

  @override
  String get sortBy => 'Ordenar por';

  @override
  String get sortOrder => 'Orden de clasificación';

  @override
  String get sourceCode => 'Código fuente';

  @override
  String get stopServiceOnAppDismissal =>
      'Detener servicio al cerrar la aplicación';

  @override
  String get stopServiceOnAppDismissalDesc =>
      'Detiene el servicio en segundo plano y cierra la aplicación al descartarla';

  @override
  String get storagePermissionRequired =>
      'Se requieren permisos de almacenamiento para escanear el dispositivo.';

  @override
  String get syncLyricsOffline => 'Sincronizar letras (sin conexión)';

  @override
  String get systemDefault => 'Predeterminado del sistema';

  @override
  String get systemPermissionChecklist => 'LISTA DE PERMISOS DEL SISTEMA';

  @override
  String get technicalInfoFrequency => 'Info técnica y frecuencia';

  @override
  String get theme => 'Tema';

  @override
  String get title => 'Título';

  @override
  String get todayMixForYou => 'Mezcla de hoy para ti';

  @override
  String get toggleFavorite => 'Alternar favorito';

  @override
  String get shuffleTitle => 'Aleatorio';

  @override
  String get shuffleDisabledDesc =>
      'Reproducir las canciones en su orden original de cola. Al desactivar el modo aleatorio, la canción actual sigue sonando y el resto de la cola vuelve a su secuencia original sin afectar la reproducción ni su historial.';

  @override
  String get shuffleEnabledDesc =>
      'Aleatorizar las canciones restantes manteniendo la actual sin cambios. El orden aleatorio generado se mantiene igual hasta que la cola cambie o se solicite un nuevo orden aleatorio, evitando canciones repetidas u omitidas.';

  @override
  String get shuffleSwitchingDesc =>
      'Activar o desactivar el modo aleatorio nunca reinicia la canción actual. Solo cambia el orden de las canciones siguientes: aleatorio si está activado, y restaurado al orden original de la cola si está desactivado.';

  @override
  String get topResult => 'Resultado principal';

  @override
  String get transferMusicFiles => 'TRANSFERIR ARCHIVOS DE MÚSICA';

  @override
  String get turnOffBlursOptimize =>
      'Desactivar desenfoques pesados para optimizar el rendimiento';

  @override
  String get unknown => 'Desconocido';

  @override
  String get unknownAlbum => 'Álbum desconocido';

  @override
  String get unknownArtist => 'Artista desconocido';

  @override
  String get updateLibraryIndexing =>
      'Actualizar la indexación de archivos de la biblioteca';

  @override
  String get useAbsoluteBlackBg => 'Usar negro absoluto para los fondos';

  @override
  String get useStaticTextTimestamps =>
      'Usar texto estático en lugar de animación para la duración del progreso';

  @override
  String get verticalMotionEffectPlayer =>
      'Efecto de movimiento vertical del reproductor';

  @override
  String get verticalMotionEffectPlayerDesc =>
      'Desliza hacia abajo en el reproductor expandido para cerrarlo';

  @override
  String get viewAll => 'Ver todo';

  @override
  String get visitOfficialRepository =>
      'Visita el repositorio oficial en GitHub';

  @override
  String get welcomeAboutDesc =>
      'Looper Player es un sistema Music-OS de última generación diseñado para reproducción de música de alta fidelidad sin conexión. Cuenta con letras dinámicas en tiempo real, administración avanzada de sesiones de audio con silenciamiento automático de llamadas, fondos adaptables y soporte para múltiples formatos. Optimizado para el máximo ahorro de batería.';

  @override
  String get welcomeAllFilesDesc =>
      'Muy recomendado para escaneo profesional y localización de canciones en directorios no estándar (Descargas, Telegram, carpetas personalizadas).';

  @override
  String get welcomeInstructionConnectDesc =>
      'Conecte su teléfono o dispositivo a una computadora usando un cable de datos USB estándar.';

  @override
  String get welcomeInstructionDownloadDesc =>
      'Alternativamente, descargue archivos directamente usando un navegador web u otra utilidad en el propio dispositivo.';

  @override
  String get welcomeInstructionTransferDesc =>
      'Copie sus archivos de música sin conexión (compatible con .mp3, .flac, .m4a, .wav) directamente en la carpeta estándar \'Music\' o \'Download\' de su dispositivo.';

  @override
  String get welcomeMusicAudioDesc =>
      'Requerido para descubrir y reproducir pistas de audio estándar en la memoria de su dispositivo.';

  @override
  String get welcomeNoSongsDesc =>
      'No pudimos encontrar ningún archivo de audio compatible (MP3, FLAC, WAV, M4A, OGG) en el almacenamiento de su dispositivo.';

  @override
  String get welcomeNotificationDesc =>
      'Requerido para mostrar controles de reproducción y widgets de notificación en la barra del sistema.';

  @override
  String get welcomeScanningFoldersDesc =>
      'Escaneando todas las carpetas y subcarpetas en busca de archivos de audio.';

  @override
  String get whyInternetUsed => 'Por qué se usa Internet';

  @override
  String get whyInternetUsedDesc =>
      '• Sincronización dinámica de letras: Se usa únicamente para buscar y descargar de forma segura letras sincronizadas (formatos LRC) de bases de datos en línea. Ningún dato personal, ajuste o archivo multimedia se sube o comparte jamás.';

  @override
  String get whyPermissionsUsed => 'Por qué se usan los permisos';

  @override
  String get whyPermissionsUsedDesc =>
      '• Acceso a almacenamiento / multimedia: Requerido para descubrir, leer e indexar pistas de audio locales en su dispositivo.\n• Notificaciones: Requerido para mostrar widgets de control de reproducción en la barra de estado y panel del sistema.';

  @override
  String get willPlayNext => 'Se reproducirá a continuación';

  @override
  String get year => 'Año';

  @override
  String get supportUs => 'Apóyanos';

  @override
  String get supportUsDesc =>
      'Ayuda a mantener Looper Player vivo y de código abierto';

  @override
  String get supportDevelopment => 'Apoyar el desarrollo';

  @override
  String get supportDevelopmentDesc =>
      'Looper Player es 100% gratuito y de código abierto. Si disfrutas usándolo, por favor considera apoyar al creador con una donación. ¡Cada contribución ayuda a mantener el proyecto activo!';

  @override
  String get useCustomFont => 'Usar fuente personalizada';

  @override
  String get useCustomFontDesc =>
      'Usar Jost u otras fuentes personalizadas. De lo contrario, se usa DM Sans.';

  @override
  String get selectFontFamily => 'Seleccionar familia de fuentes';

  @override
  String activeFont(String fontName) {
    return 'Fuente activa: $fontName';
  }

  @override
  String get fontWeightAdjustment => 'Ajuste de grosor de fuente';

  @override
  String get currentWeight => 'Grosor actual';

  @override
  String get useCustomFontLyrics => 'Usar fuente personalizada para letras';

  @override
  String get useCustomFontLyricsDesc =>
      'Usar fuente y grosor personalizados para la vista de letras sincronizadas';

  @override
  String get lyricsFontFamily => 'Familia de fuentes de letras';

  @override
  String activeLyricsFont(String fontName) {
    return 'Fuente de letras activa: $fontName';
  }

  @override
  String get lyricsFontWeightAdjustment => 'Ajuste de grosor de letras';

  @override
  String get giveStarOnGithub => 'Dar estrella en GitHub';

  @override
  String get supportProjectLove => '¡Apoya el proyecto y muestra algo de amor!';

  @override
  String get sortAlphabeticalAZ => 'Alfabético (A-Z)';

  @override
  String get sortAlphabeticalZA => 'Alfabético (Z-A)';

  @override
  String get sortRecentlyAdded => 'Añadido recientemente';

  @override
  String get sortOldestAdded => 'Añadido más antiguo';

  @override
  String get sortYearNewest => 'Año (Más reciente)';

  @override
  String get sortYearOldest => 'Año (Más antiguo)';

  @override
  String get sortMostSongs => 'Más canciones';

  @override
  String get sortLeastSongs => 'Menos canciones';

  @override
  String get sortDefault => 'Predeterminado';

  @override
  String get sortArtistAsc => 'Artista (A-Z)';

  @override
  String get sortAlbumAsc => 'Álbum (A-Z)';

  @override
  String get sortDuration => 'Duración';

  @override
  String get myAlbums => 'Mis álbumes';

  @override
  String get featuredArtists => 'Artistas destacados';

  @override
  String get noSongPlaying => 'No hay ninguna canción reproduciéndose';

  @override
  String get nextLabel => 'Siguiente';

  @override
  String get previousLabel => 'Anterior';

  @override
  String get resync => 'Resincronizar';

  @override
  String get equalizer => 'Ecualizador';

  @override
  String get presets => 'AJUSTES PREDEFINIDOS';

  @override
  String get preAmpGain => 'Ganancia de preamplificación';

  @override
  String get outputVolume => 'Volumen de salida';

  @override
  String get customFilterHint =>
      'Escribe directamente parámetros de filtro de audio libavfilter personalizados (p. ej. volume=3dB, aecho=0.8:0.88:60:0.4):';

  @override
  String get flowGlobalActions => 'Flujo y acciones globales';

  @override
  String get equalizerModeLabel => 'Modo de ecualizador:';

  @override
  String get currentGainsAppliedGlobal =>
      'Ganancias actuales aplicadas como configuración global predeterminada.';

  @override
  String get applyToGlobal => 'Aplicar a global';

  @override
  String get songSpecificResetGlobal =>
      'Ajustes específicos de la canción restablecidos a los valores globales predeterminados.';

  @override
  String get resetToGlobal => 'Restablecer a global';

  @override
  String get resetAllSongsEq => 'Restablecer EQ de todas las canciones';

  @override
  String get resetAllSongsEqConfirm =>
      '¿Seguro que quieres borrar los ajustes de ecualizador personalizados de todas las canciones de tu biblioteca?';

  @override
  String get allSongsEqDataReset =>
      'Se han restablecido todos los datos de ecualizador específicos de canciones.';

  @override
  String get resetAllSongsEqData =>
      'Restablecer datos de EQ de todas las canciones';

  @override
  String get equalizerTargetMode => 'Modo de aplicación del ecualizador';

  @override
  String get equalizerTargetModeDesc =>
      'Selecciona cómo se aplican los ajustes del ecualizador en tu biblioteca musical.';

  @override
  String get globalMode => 'Modo global';

  @override
  String get globalModeDesc =>
      'Aplica los efectos a todas las canciones por igual. Los ajustes del ecualizador se mantienen al cambiar de canción.';

  @override
  String get songSpecificMode => 'Modo por canción';

  @override
  String get songSpecificModeDesc =>
      'Guarda ajustes personalizados solo para la canción actual. La siguiente canción usará un ecualizador neutro/desactivado de forma predeterminada, salvo que tenga su propio perfil.';

  @override
  String get viewDeviceAudioCapabilities =>
      'Ver capacidades de audio del dispositivo';

  @override
  String get deviceAudioCapabilities => 'Capacidades de audio del dispositivo';

  @override
  String get noPlaybackActiveCapabilities =>
      'No hay reproducción activa o la información de capacidades no está disponible.';

  @override
  String get changeLyricsProvider => 'Cambiar proveedor de letras';

  @override
  String get autoFallbackProviders => 'Proveedores alternativos automáticos';

  @override
  String get autoFallbackProvidersDesc =>
      'Probar automáticamente con otros proveedores si el principal no tiene la letra';

  @override
  String get ambientColorBackground => 'Fondo de color ambiental';

  @override
  String get ambientColorBackgroundDesc =>
      'Degradados ambientales suaves y sutiles derivados de la carátula de la canción';

  @override
  String get exportLyricsLrc => 'Exportar letra (archivo .lrc)';

  @override
  String get saveLyricsToDevice =>
      'Guardar la letra actual en el almacenamiento del dispositivo';

  @override
  String get noLyricsToExport =>
      'No hay ninguna letra disponible para exportar';

  @override
  String get useCustomLyricsLrc => 'Usar letra personalizada (archivo LRC)';

  @override
  String get selectLocalLrcFile =>
      'Selecciona un archivo .lrc o .txt local para esta canción';

  @override
  String get customLyricsAppliedSuccess =>
      '¡Letra personalizada aplicada correctamente!';

  @override
  String get noRecentlyPlayedTracks =>
      'No hay canciones reproducidas recientemente';

  @override
  String get close => 'Cerrar';

  @override
  String get audioQualityAnalysis => 'Análisis de calidad de audio';

  @override
  String get audioQualityAnalysisDesc =>
      'Realizar un análisis espectral y de formato de audio en profundidad';

  @override
  String get audioStreamDetails => 'Detalles del flujo de audio';

  @override
  String get perChannelMetrics => 'Métricas por canal';

  @override
  String get sleepTimer => 'Temporizador de apagado';

  @override
  String get stopByTime => 'DETENER POR TIEMPO';

  @override
  String get start => 'Iniciar';

  @override
  String get stopBySongCount => 'DETENER POR NÚMERO DE CANCIONES';

  @override
  String get cancelSleepTimer => 'Cancelar temporizador de apagado';

  @override
  String get nowPlayingAllCaps => 'REPRODUCIENDO';

  @override
  String get settingsAndBackups => 'Ajustes y copias de seguridad';

  @override
  String get managePreferencesLibraryData =>
      'Gestiona las preferencias y los datos de la biblioteca';

  @override
  String get logsClearedSuccess => 'Registros borrados correctamente';

  @override
  String get editSongInfo => 'Editar información de la canción';

  @override
  String get editAlbumInfo => 'Editar información del álbum';

  @override
  String get tapFieldToEdit => 'Toca un campo para editarlo';

  @override
  String get alwaysBlurSheets => 'Difuminar siempre las hojas';

  @override
  String get alwaysBlurSheetsDesc =>
      'Difumina las hojas emergentes incluso cuando el tema dinámico está desactivado';

  @override
  String get removeArtwork => 'Quitar carátula';

  @override
  String get resetArtworkToDefault => 'Restablecer a la predeterminada';

  @override
  String get artworkResetToDefault =>
      'Portada restablecida a la predeterminada';

  @override
  String get noEmbeddedArtworkFound =>
      'No se encontró portada incrustada para este álbum';

  @override
  String get saveChangesBtn => 'Guardar cambios';

  @override
  String get enterFolderPathManually =>
      'Introducir la ruta de la carpeta manualmente';

  @override
  String get folderPickerManualHint =>
      'Si el selector de directorios del sistema no se abre, escribe o pega la ruta completa del directorio a continuación:';

  @override
  String get noSupportedSongsFoundFolder =>
      'No se encontraron canciones compatibles en la carpeta seleccionada';

  @override
  String get add => 'Añadir';

  @override
  String get folderPickerClosed => 'Selector de carpetas cerrado';

  @override
  String get buyMeCoffee => 'Invítame a un café';

  @override
  String get typeToSearchSettings => 'Escribe para buscar en los ajustes…';

  @override
  String get maintainersLabel => 'Mantenedores';

  @override
  String get personBehindLooperPlayer => 'La persona detrás de LooperPlayer';

  @override
  String get blurredArtworkForLyrics => 'Carátula desenfocada para las letras';

  @override
  String get blurredArtworkForLyricsDesc =>
      'Mostrar la carátula del álbum desenfocada como fondo en lugar de un degradado dinámico/estático';

  @override
  String get lyricsFontWeight => 'Grosor de fuente de la letra';

  @override
  String get openSourceLicenses => 'Licencias de código abierto';

  @override
  String get openSourceLicensesDesc =>
      'Bibliotecas de terceros utilizadas en esta aplicación';

  @override
  String get done => 'Hecho';

  @override
  String get lyricsNotAvailable => 'Letra no disponible.';

  @override
  String get lyricsNotAvailableHint =>
      'Importa un archivo .lrc o .txt para añadir la letra de esta canción';

  @override
  String get importLyricsFile => 'Importar archivo de letras';

  @override
  String get approximatedSyncNoWordTimings =>
      'Sincronización aproximada (sin tiempos por palabra)';

  @override
  String get lyricsSyncHelp => 'Ayuda de sincronización de letras';

  @override
  String get simpleModeLabel => 'Modo simple';

  @override
  String get advancedModeLabel => 'Modo avanzado';

  @override
  String get tips => 'Consejos';

  @override
  String get gotIt => 'Entendido';

  @override
  String get lyricsSyncStudio => 'Estudio de sincronización de letras';

  @override
  String get lyricsTextLabel => 'Texto de la letra';

  @override
  String get lyricsTextHelperDesc =>
      'Una línea por verso. Las herramientas de sincronización de abajo asignan marcas de tiempo a estas líneas.';

  @override
  String get quickSync => 'Sincronización rápida';

  @override
  String get autoAdvanceAfterStamping =>
      'Avanzar automáticamente tras marcar el tiempo';

  @override
  String get advancedSync => 'Sincronización avanzada';

  @override
  String get useCurrentTime => 'Usar la hora actual';

  @override
  String get playbackAssist => 'Asistente de reproducción';

  @override
  String get timeShift => 'Desplazamiento de tiempo';

  @override
  String get timeShiftDesc =>
      'Desplaza todas las líneas de letra marcadas hacia adelante o hacia atrás, juntas.';

  @override
  String get lyricsSaveLrcExplain =>
      'Al guardar se crea, si es posible, un archivo «.lrc» junto al audio de la canción, y también se guarda en la base de datos local del reproductor. Las líneas sin marcar se interpolarán automáticamente.';

  @override
  String get back => 'Atrás';

  @override
  String get appSettingsLabel => 'Ajustes de la app';

  @override
  String get backupsAndLogs => 'Copias de seguridad y registros';

  @override
  String get backupsAndLogsDesc =>
      'Exporta, importa y gestiona los datos de la app';

  @override
  String get exportBackupJson => 'Exportar copia de seguridad (JSON)';

  @override
  String get exportBackupJsonDesc =>
      'Guarda tus canciones favoritas y listas de reproducción en un archivo JSON que puedes conservar o compartir. No se incluye nada más.';

  @override
  String get importBackupJson => 'Importar copia de seguridad (JSON)';

  @override
  String get importBackupJsonDesc =>
      'Combina las canciones favoritas y listas de reproducción de un archivo de copia de seguridad con tu biblioteca. Los datos existentes nunca se sobrescriben ni se eliminan.';

  @override
  String get exportDiagnosticsLogs => 'Exportar registros de diagnóstico';

  @override
  String get exportDiagnosticsLogsDesc =>
      'Comparte el archivo de registro de diagnóstico de la app para que pueda revisarse en caso de problemas.';

  @override
  String get clearDiagnosticsLogs => 'Borrar registros de diagnóstico';

  @override
  String get clearDiagnosticsLogsDesc =>
      'Borra permanentemente el archivo de registro de diagnóstico guardado en este dispositivo. Esta acción no se puede deshacer.';

  @override
  String get lyricsPlainTextOrLrc => 'Letra (texto plano o LRC)';

  @override
  String get syncModeLine => 'LÍNEA';

  @override
  String get syncModeWord => 'PALABRA';

  @override
  String get syncModeChar => 'CARÁCTER';

  @override
  String get enterManually => 'Introducir manualmente';

  @override
  String get rawFilterParametersHint => 'Parámetros de filtro sin procesar...';

  @override
  String get searchSettingsHint => 'Buscar en los ajustes...';

  @override
  String get repeatTooltip => 'Repetir';

  @override
  String get favoriteTooltip => 'Favorito';

  @override
  String get instructionsTooltip => 'Instrucciones';

  @override
  String get pasteLyricsHint => 'Pega o escribe aquí la letra de la canción';

  @override
  String get timestampMmSsHint => 'Marca de tiempo (mm:ss.xx)';

  @override
  String get nowLabel => 'Ahora';

  @override
  String get playlistNameHint => 'Nombre de la lista de reproducción';

  @override
  String get songInfoUpdated => '¡Información de la canción actualizada!';

  @override
  String get albumInfoUpdated => '¡Información del álbum actualizada!';

  @override
  String get failedToSaveChanges => 'No se pudieron guardar los cambios.';

  @override
  String sleepTimerStoppingIn(String time) {
    return 'Activo: Se detendrá en $time';
  }

  @override
  String sleepTimerStoppingAfter(String time) {
    return 'Activo: Se detendrá después de $time';
  }

  @override
  String get selectWhenToPause =>
      'Selecciona cuándo pausar la reproducción de música';

  @override
  String get selectAvatars => 'Seleccionar avatar';

  @override
  String get selectAvatarsDesc =>
      'Elige el avatar que se muestra en tu pantalla de inicio';

  @override
  String get dynamicAvatarColor => 'Color dinámico del avatar';

  @override
  String get dynamicAvatarColorDesc =>
      'Ajusta el color de acento del avatar a tu tema actual';

  @override
  String enrichingSongs(int count) {
    return 'Enriqueciendo $count canciones…';
  }
}
