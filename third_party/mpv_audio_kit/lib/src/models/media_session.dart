// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import '../internals/unset_sentinel.dart';
import '../types/enums/interruption_policy.dart';
import '../types/enums/media_action.dart';
import '../types/sealed/media_session_artwork.dart';

/// Configuration and metadata for the OS media session — the
/// lockscreen / SMTC / MPRIS entry, Bluetooth AVRCP, headset
/// buttons, and (on iOS/Android) the AVAudioSession / AudioFocus
/// integration.
///
/// Apply via [Player.setMediaSession]; pass `null` to disable the
/// session entirely. Only one [Player] instance per process can have
/// an active media session at a time — attempting to enable a second
/// throws [StateError].
///
/// **Metadata fields** ([title], [artist], [album], [duration]) are
/// *overrides*: a `null` field falls back to the value derived from
/// mpv (`metadata.title` / `media-title`, `metadata.artist`,
/// `metadata.album`, `duration`); an empty string is an explicit
/// blank. [artwork] is a typed choice — see [MediaSessionArtwork].
///
/// **Config fields** (everything else) are always applied verbatim
/// when the session is enabled.
///
/// Updates use the standard [copyWith] pattern:
///
/// ```dart
/// // Enable with all defaults — metadata comes from mpv
/// await player.setMediaSession(const MediaSession());
///
/// // Override the title for the current track
/// await player.setMediaSession(
///   (player.state.mediaSession ?? const MediaSession())
///       .copyWith(title: 'My Custom Title'),
/// );
///
/// // Disable
/// await player.setMediaSession(null);
/// ```
class MediaSession {
  // ── Metadata override (null = derive from mpv) ─────────────────────

  /// Track title shown on the lockscreen / SMTC top line. `null` falls
  /// back to mpv's `metadata.title` (or `media-title` if absent).
  final String? title;

  /// Artist name shown beneath the title. `null` falls back to mpv's
  /// `metadata.artist`.
  final String? artist;

  /// Album name shown as a third metadata line on lockscreens that
  /// surface it (iOS, macOS, Windows SMTC). Often hidden on Android's
  /// compact notification. `null` falls back to mpv's
  /// `metadata.album`.
  final String? album;

  /// Artwork shown on the OS media session. Defaults to
  /// [MediaSessionArtwork.embedded] (the file's embedded cover); use
  /// [MediaSessionArtwork.custom] for your own image, or
  /// [MediaSessionArtwork.none] to suppress it.
  final MediaSessionArtwork artwork;

  /// Track length. Drives the lockscreen scrubber's end-of-track
  /// position. `null` falls back to mpv's `duration`.
  final Duration? duration;

  // ── Capabilities ───────────────────────────────────────────────────

  /// Capabilities advertised to the OS. What actually renders is
  /// **platform-gated**, not just space-gated: each native media UI draws
  /// only a subset (a lockscreen typically shows 3–4 of those), and the wider
  /// set is offered to Siri / Google Assistant / Android Auto / CarPlay. The
  /// iteration order is preserved when pushing the configuration to native
  /// media sessions.
  /// Advertising an action a platform doesn't render is harmless. See the
  /// per-platform support matrix in the README's *OS media session* section,
  /// and the per-value notes on [MediaAction].
  final Set<MediaAction> actions;

  /// Whether the "like" / favourite control ([MediaAction.like]) shows as
  /// active (the filled star) on surfaces that render it (the iOS lock
  /// screen). Flip it in response to [MediaSessionCommandLike]. Default
  /// `false`; ignored where the action isn't rendered.
  final bool isFavorite;

  // ── Audio interruption handling ────────────────────────────────────

  /// How the player reacts to an OS audio interruption (phone call,
  /// Siri, another app taking focus). Defaults to
  /// [InterruptionPolicy.pauseAndResume]; honoured on iOS / Android and
  /// a no-op on macOS / Linux / Windows. See [InterruptionPolicy].
  final InterruptionPolicy interruptionPolicy;

  // ── Skip intervals ─────────────────────────────────────────────────

  /// Interval used by the system "skip forward N seconds" button when
  /// [MediaAction.fastForward] is in [actions]. Default 15 seconds —
  /// matches Apple Podcasts' default and audio_service's
  /// `fastForwardInterval`. The OS shows this number on the skip icon
  /// (e.g. "+15") on iOS / macOS / Android Auto.
  final Duration fastForwardInterval;

  /// Interval used by the system "skip backward N seconds" button when
  /// [MediaAction.rewind] is in [actions]. Default 15 seconds —
  /// symmetric with [fastForwardInterval].
  final Duration rewindInterval;

  /// Set of selectable playback rates surfaced by the OS Now Playing
  /// rate-picker when [MediaAction.setPlaybackRate] is in [actions].
  /// Default `[0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0]` matches Apple
  /// Podcasts. The OS may show only a subset depending on the
  /// surface (CarPlay, lockscreen, Control Center).
  final List<double> supportedPlaybackRates;

  /// Whether the package automatically calls [Player.next] and [Player.previous]
  /// when the active playlist has multiple items and the OS issues a
  /// next/previous track command.
  ///
  /// Defaults to `true`. Set to `false` if the application wants to intercept
  /// and handle next/previous track commands manually (e.g. for custom skip
  /// behavior, seeking, or server-driven playlists).
  final bool autoApplyPlaylistNavigation;

  // ── App identity ───────────────────────────────────────────────────

  /// Display name shown by MPRIS (Linux) and SMTC (Windows) for the
  /// app identity. `null` defers to the executable / bundle name.
  /// macOS, iOS and Android always use the bundle display name.
  final String? appName;

  /// Basename of the installed `.desktop` file (without the `.desktop`
  /// extension) — used by MPRIS on Linux to resolve the app icon shown beside
  /// the media controls in GNOME / KDE. For
  /// `/usr/share/applications/com.example.myapp.desktop`, pass
  /// `'com.example.myapp'`. `null` omits the hint. Ignored on every
  /// non-Linux platform.
  final String? desktopEntry;

  /// Creates a media-session configuration. Every field is optional and
  /// carries a sensible default; metadata fields default to deriving
  /// their value from the playing file.
  const MediaSession({
    this.title,
    this.artist,
    this.album,
    this.artwork = MediaSessionArtwork.embedded,
    this.duration,
    this.actions = const {
      MediaAction.play,
      MediaAction.pause,
      MediaAction.playPause,
      MediaAction.next,
      MediaAction.previous,
      MediaAction.seek,
    },
    this.isFavorite = false,
    this.interruptionPolicy = InterruptionPolicy.pauseAndResume,
    this.fastForwardInterval = const Duration(seconds: 15),
    this.rewindInterval = const Duration(seconds: 15),
    this.supportedPlaybackRates = const [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0],
    this.autoApplyPlaylistNavigation = true,
    this.appName,
    this.desktopEntry,
  });

  /// Returns a copy of this configuration with the given fields replaced.
  ///
  /// The nullable override fields ([title], [artist], [album], [duration],
  /// [appName], [desktopEntry]) accept `null` to CLEAR the override back to the
  /// mpv-derived / default value: passing `null` is distinguished from omitting
  /// the argument (which keeps the current value). The non-nullable fields keep
  /// their current value when omitted.
  MediaSession copyWith({
    Object? title = unset,
    Object? artist = unset,
    Object? album = unset,
    MediaSessionArtwork? artwork,
    Object? duration = unset,
    Set<MediaAction>? actions,
    bool? isFavorite,
    InterruptionPolicy? interruptionPolicy,
    Duration? fastForwardInterval,
    Duration? rewindInterval,
    List<double>? supportedPlaybackRates,
    bool? autoApplyPlaylistNavigation,
    Object? appName = unset,
    Object? desktopEntry = unset,
  }) =>
      MediaSession(
        title: identical(title, unset) ? this.title : title as String?,
        artist: identical(artist, unset) ? this.artist : artist as String?,
        album: identical(album, unset) ? this.album : album as String?,
        artwork: artwork ?? this.artwork,
        duration:
            identical(duration, unset) ? this.duration : duration as Duration?,
        actions: actions ?? this.actions,
        isFavorite: isFavorite ?? this.isFavorite,
        interruptionPolicy: interruptionPolicy ?? this.interruptionPolicy,
        fastForwardInterval: fastForwardInterval ?? this.fastForwardInterval,
        rewindInterval: rewindInterval ?? this.rewindInterval,
        supportedPlaybackRates:
            supportedPlaybackRates ?? this.supportedPlaybackRates,
        autoApplyPlaylistNavigation:
            autoApplyPlaylistNavigation ?? this.autoApplyPlaylistNavigation,
        appName: identical(appName, unset) ? this.appName : appName as String?,
        desktopEntry: identical(desktopEntry, unset)
            ? this.desktopEntry
            : desktopEntry as String?,
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! MediaSession) return false;
    if (other.title != title ||
        other.artist != artist ||
        other.album != album ||
        other.artwork != artwork ||
        other.duration != duration ||
        other.isFavorite != isFavorite ||
        other.interruptionPolicy != interruptionPolicy ||
        other.fastForwardInterval != fastForwardInterval ||
        other.rewindInterval != rewindInterval ||
        other.autoApplyPlaylistNavigation != autoApplyPlaylistNavigation ||
        other.appName != appName ||
        other.desktopEntry != desktopEntry) {
      return false;
    }
    if (!_sameActionsInOrder(other.actions, actions)) return false;
    if (other.supportedPlaybackRates.length != supportedPlaybackRates.length) {
      return false;
    }
    for (var i = 0; i < supportedPlaybackRates.length; i++) {
      if (other.supportedPlaybackRates[i] != supportedPlaybackRates[i]) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        title,
        artist,
        album,
        artwork,
        duration,
        Object.hashAll(actions),
        isFavorite,
        interruptionPolicy,
        fastForwardInterval,
        rewindInterval,
        Object.hashAll(supportedPlaybackRates),
        autoApplyPlaylistNavigation,
        appName,
        desktopEntry,
      );

  @override
  String toString() => 'MediaSession(title: $title, artist: $artist, '
      'album: $album, artwork: $artwork, duration: $duration, '
      'actions: $actions, isFavorite: $isFavorite, '
      'interruptionPolicy: $interruptionPolicy, '
      'fastForwardInterval: $fastForwardInterval, '
      'rewindInterval: $rewindInterval, '
      'supportedPlaybackRates: $supportedPlaybackRates, '
      'autoApplyPlaylistNavigation: $autoApplyPlaylistNavigation, '
      'appName: $appName, desktopEntry: $desktopEntry)';
}

bool _sameActionsInOrder(
  Set<MediaAction> a,
  Set<MediaAction> b,
) {
  if (a.length != b.length) return false;
  final ait = a.iterator;
  final bit = b.iterator;
  while (ait.moveNext() && bit.moveNext()) {
    if (ait.current != bit.current) return false;
  }
  return true;
}
