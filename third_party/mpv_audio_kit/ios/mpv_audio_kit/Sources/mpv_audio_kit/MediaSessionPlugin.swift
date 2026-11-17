// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

#if os(iOS)
import AVFoundation
import Flutter
import UIKit

private typealias PlatformImage = UIImage
#elseif os(macOS)
import AppKit
import FlutterMacOS

private typealias PlatformImage = NSImage
#endif

import Foundation
import MediaPlayer

/// Shared Apple (iOS + macOS) bridge: publishes the Dart-side `Player`
/// to the OS Now Playing surface (lockscreen / Control Center / CarPlay)
/// and forwards `MPRemoteCommandCenter` taps back to Dart. `darwin/Sources`
/// is the one source of truth; it is copied (never symlinked) into both
/// platform packages by `scripts/sync_apple_sources.sh`.
///
/// A renderer, not a state machine: Dart owns playback truth and pushes
/// resolved snapshots; each push reassigns a fresh `nowPlayingInfo`. The
/// OS extrapolates the scrubber from `(elapsed, rate)`, and Dart hides
/// mpv's transient seek-pause, so there's nothing to correlate or time
/// here. Load-bearing details:
///
/// - **macOS needs `playbackState`** on every publish, or the app never
///   appears in Control Center (iOS infers it from the audio session).
/// - **Full-dict writes**, never read-modify-write — the system value
///   races across notification handlers.
/// - **Commands installed once** on the `MPRemoteCommandCenter` singleton
///   (static targets + weak `currentInstance`); re-adding per track is
///   the classic double-fire bug.
/// - **Scrub freeze**: publish the target with `rate = 0` so the slider
///   pins there while the engine seeks; cleared by the `updatePlayback`
///   that lands on the target (backstopped by a timer).
/// - **iOS only**: activate `AVAudioSession` `.playback` (needed for
///   background + Now Playing) and react to interruptions per the
///   consumer's `interruptionPolicy`; headphone unplug always pauses
///   (consumer must declare `UIBackgroundModes: audio`). No-op on macOS.
public class MediaSessionPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
  private static let methodChannelName = "mpv_audio_kit/media_session"
  private static let eventChannelName = "mpv_audio_kit/media_session/commands"

  // Default skip interval when the consumer doesn't override
  // `fastForwardInterval` / `rewindInterval`. 15s matches Apple Podcasts.
  private static let defaultSkipIntervalSeconds: TimeInterval = 15
  // Largest retained artwork edge. The request closure downscales on
  // demand, so this caps the cached bitmap, not what the OS can ask for.
  private static let artworkBoundsSide: CGFloat = 600

  // ── Process-singleton command-target storage (installed once) ──────
  private static var sharedCommandsInstalled = false
  private static var sharedCommandTargets: [(MPRemoteCommand, Any)] = []
  // The instance the static handlers route to. Weak so a deallocated
  // plugin clears it automatically (handlers then no-op).
  private static weak var currentInstance: MediaSessionPlugin?

  // ── State (main-queue only) ─────────────────────────────────────────
  // `internal` (not private) so the headless test driver can assert
  // against it directly.

  internal var enabled = false
  internal var currentConfig: [String: Any] = [:]
  internal var currentMetadata: [String: Any] = [:]
  internal var currentPlayback: [String: Any] = [:]

  // Scrub freeze: non-nil ⇒ the slider is pinned at this elapsed with
  // rate 0. Set in `handleScrub`, cleared by the next `updatePlayback`
  // (or by `refreshSeekableGate` when the source becomes non-seekable).
  internal var frozenElapsed: TimeInterval?
  // Bumped on every scrub so a stale backstop timer recognises it has been
  // superseded by a newer scrub and no-ops.
  private var scrubFreezeGeneration = 0

  // Artwork cache: the cache key (bytes identity) + the
  // `MPMediaItemArtwork` wrapper. The wrapper's request closure captures
  // and downscales the decoded image on demand, so the dedup reference
  // check keeps matching while the bytes are unchanged — without
  // retaining a second copy of the bitmap.
  internal var artworkCacheKey: Data?
  internal var artworkCacheObject: MPMediaItemArtwork?
  // The remote artwork URL currently resolved (or being fetched). Keys the
  // async URLSession path so per-second playback pushes don't re-download,
  // and lets a late fetch detect that the track moved on (stale → drop).
  internal var artworkUrlKey: String?

  // Last published dict + state, for the dedup check in `publishNowPlaying`.
  internal var lastPublishedInfo: [String: Any]?
  internal var lastPublishedPlaybackState: MPNowPlayingPlaybackState = .unknown
  // Count of non-deduped publishes — used by the test driver to assert
  // that redundant pushes coalesce.
  internal var publishCount: Int = 0

  #if os(iOS)
  private var audioSessionWired = false
  // True once `setActive(true)` has succeeded — `setActive` is blocking
  // mediaserverd IPC meant for activation transitions, so only call it on the
  // false→true edge, not on every position/rate publish.
  private var sessionActive = false
  // The play state captured when an interruption began, so `.ended` only
  // auto-resumes audio that was actually playing before.
  private var wasPlayingBeforeInterruption = false
  #endif

  private var eventSink: FlutterEventSink?

  deinit {
    // Safety net for the case where the instance is released without
    // disable() running: selector-based NotificationCenter observers are
    // NOT auto-removed, so drop them here so a later interruption /
    // route-change notification can't dispatch to freed memory. A no-op
    // when nothing was registered (incl. macOS, which never wires them).
    NotificationCenter.default.removeObserver(self)
  }

  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = MediaSessionPlugin()

    #if os(iOS)
    let messenger = registrar.messenger()
    #elseif os(macOS)
    let messenger = registrar.messenger
    #endif

    let methodChannel = FlutterMethodChannel(
      name: methodChannelName,
      binaryMessenger: messenger)
    registrar.addMethodCallDelegate(instance, channel: methodChannel)

    let eventChannel = FlutterEventChannel(
      name: eventChannelName,
      binaryMessenger: messenger)
    eventChannel.setStreamHandler(instance)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "enable":
      guard let args = call.arguments as? [String: Any] else {
        result(invalidArgs("enable")); return
      }
      onMain { self.enable(args: args) }
      result(nil)

    case "updateConfig":
      guard let cfg = call.arguments as? [String: Any] else {
        result(invalidArgs("updateConfig")); return
      }
      onMain {
        self.currentConfig = cfg
        if self.enabled {
          self.configureCommands()
          #if os(iOS)
          self.applyAudioSessionConfig()
          #endif
        }
      }
      result(nil)

    case "updateMetadata":
      guard let meta = call.arguments as? [String: Any] else {
        result(invalidArgs("updateMetadata")); return
      }
      onMain {
        self.currentMetadata = meta
        if self.enabled { self.publishNowPlaying() }
      }
      result(nil)

    case "updatePlayback":
      guard let pb = call.arguments as? [String: Any] else {
        result(invalidArgs("updatePlayback")); return
      }
      onMain {
        self.currentPlayback = pb
        // Release the scrub freeze only once the engine actually reaches
        // the frozen target. A routine push (loop / shuffle / rate) that
        // fires while a seek is still in flight carries the stale pre-seek
        // position; clearing the freeze there would snap the slider back
        // to that stale value — the exact glitch the freeze prevents.
        let landedOnFrozen: Bool
        if let frozen = self.frozenElapsed,
           let posMs = pb["positionMs"] as? Int
        {
          landedOnFrozen = abs(Double(posMs) / 1000.0 - frozen) <= 1.0
        } else {
          landedOnFrozen = true  // no active freeze (or no position) to hold
        }
        if landedOnFrozen { self.frozenElapsed = nil }
        if self.enabled {
          self.publishNowPlaying()
          // `seekable` can flip mid-stream (HLS sliding window, live →
          // DVR). Re-evaluate the scrubber gate.
          self.refreshSeekableGate()
        }
      }
      result(nil)

    case "disable":
      onMain { self.disable() }
      result(nil)

    case "debugNowPlayingInfo":
      // Test seam: returns the OS-visible Now Playing snapshot for the
      // integration probe to assert against `MPNowPlayingInfoCenter`. Not
      // part of the public Dart API.
      onMain { result(self.debugNowPlayingSnapshot()) }

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func invalidArgs(_ method: String) -> FlutterError {
    FlutterError(
      code: "INVALID_ARGS",
      message: "\(method) requires a Map payload",
      details: nil)
  }

  // ── Enable / Disable ──────────────────────────────────────────────

  private func enable(args: [String: Any]) {
    dispatchPrecondition(condition: .onQueue(.main))
    // Single-owner guard mirroring the Dart StateError: the shared command
    // targets resolve `currentInstance` at fire time, so a second engine
    // enabling would silently hijack every remote command. Refuse instead.
    if let existing = MediaSessionPlugin.currentInstance, existing !== self {
      NSLog(
        "[mpv_audio_kit] OS media session already owned by another engine; "
          + "ignoring enable.")
      return
    }
    if let cfg = args["config"] as? [String: Any] { currentConfig = cfg }
    if let meta = args["metadata"] as? [String: Any] { currentMetadata = meta }
    if let pb = args["playback"] as? [String: Any] { currentPlayback = pb }

    enabled = true
    // Re-point the static handlers at this instance (engine restart
    // safe). installCommandTargetsIfNeeded only installs once.
    MediaSessionPlugin.currentInstance = self
    installCommandTargetsIfNeeded()
    configureCommands()
    #if os(iOS)
    applyAudioSessionConfig()
    #endif
    publishNowPlaying()
  }

  private func disable() {
    dispatchPrecondition(condition: .onQueue(.main))
    enabled = false

    // `.stopped` BEFORE `nil` notifies the system the publisher is
    // retiring, so the Now Playing entry clears within ~1s instead of
    // holding a ghost entry for the IPC cache TTL.
    let center = MPNowPlayingInfoCenter.default()
    center.playbackState = .stopped
    center.nowPlayingInfo = nil

    // Targets stay installed (re-enable is one isEnabled flip away);
    // disable them so the OS knows nothing is actionable.
    for (command, _) in MediaSessionPlugin.sharedCommandTargets {
      command.isEnabled = false
    }
    if MediaSessionPlugin.currentInstance === self {
      MediaSessionPlugin.currentInstance = nil
    }

    #if os(iOS)
    teardownAudioSession()
    #endif

    currentConfig = [:]
    currentMetadata = [:]
    currentPlayback = [:]
    frozenElapsed = nil
    artworkCacheKey = nil
    artworkUrlKey = nil
    artworkCacheObject = nil
    lastPublishedInfo = nil
    lastPublishedPlaybackState = .unknown
  }

  #if os(iOS)
  // ── AVAudioSession (iOS-only) ─────────────────────────────────────

  /// Configures the `.playback` category and registers the interruption /
  /// route-change observers. Does NOT take the audio route — activation is
  /// deferred to the first real playback (see `activateSessionIfPlaying`)
  /// so enabling the session doesn't pre-empt another app's audio before
  /// this player produces output. Activation is INDEPENDENT of
  /// `interruptionPolicy` — the policy only governs how we react to an
  /// interruption. Idempotent; re-applies the policy on every call.
  private func applyAudioSessionConfig() {
    dispatchPrecondition(condition: .onQueue(.main))
    let session = AVAudioSession.sharedInstance()
    if !audioSessionWired {
      // Register observers up front, independent of activation success, so
      // a route change or interruption-end can drive recovery even if
      // activation is later declined (e.g. enabled during an active call).
      let center = NotificationCenter.default
      center.addObserver(
        self,
        selector: #selector(handleAudioSessionInterruption(_:)),
        name: AVAudioSession.interruptionNotification,
        object: nil)
      center.addObserver(
        self,
        selector: #selector(handleAudioSessionRouteChange(_:)),
        name: AVAudioSession.routeChangeNotification,
        object: nil)
      // mediaserverd can reset, invalidating the audio session, all
      // MPRemoteCommandCenter targets, and the Now Playing dict. Without a
      // rebuild path the lockscreen / Control Center / CarPlay controls go
      // dead until app relaunch — observe it and rebuild.
      center.addObserver(
        self,
        selector: #selector(handleMediaServicesReset(_:)),
        name: AVAudioSession.mediaServicesWereResetNotification,
        object: nil)
      audioSessionWired = true
    }
    // Declare intent; activation happens lazily on the first playing push.
    try? session.setCategory(.playback, mode: .default, options: [])
    // `keepPlaying` asks the system not to pre-empt playback for
    // incidental alerts (timers, calendar). A real call / Siri still
    // interrupts — that's OS-enforced and cannot be overridden.
    try? session.setPrefersNoInterruptionsFromSystemAlerts(
      currentInterruptionPolicy() == "keepPlaying")
  }

  /// Takes the audio route on the first real playback. Idempotent; the OS
  /// may decline during an active call, in which case a later playing push
  /// (or an interruption `.ended`) retries.
  private func activateSessionIfPlaying(_ playing: Bool) {
    dispatchPrecondition(condition: .onQueue(.main))
    // Only on the false→true edge: `setActive` is blocking IPC, and
    // `publishNowPlaying` runs it on every position/rate/seek push.
    guard playing, audioSessionWired, !sessionActive else { return }
    do {
      try AVAudioSession.sharedInstance().setActive(true, options: [])
      sessionActive = true
    } catch {
      // The OS declined (e.g. during a call) — leave inactive; a later push
      // or an interruption `.ended` retries.
    }
  }

  /// Consumer's interruption-policy wire value (`pauseAndResume` /
  /// `pauseOnly` / `keepPlaying`); defaults to `pauseAndResume`.
  private func currentInterruptionPolicy() -> String {
    (currentConfig["interruptionPolicy"] as? String) ?? "pauseAndResume"
  }

  private func teardownAudioSession() {
    dispatchPrecondition(condition: .onQueue(.main))
    guard audioSessionWired else { return }
    let center = NotificationCenter.default
    center.removeObserver(
      self, name: AVAudioSession.interruptionNotification, object: nil)
    center.removeObserver(
      self, name: AVAudioSession.routeChangeNotification, object: nil)
    center.removeObserver(
      self, name: AVAudioSession.mediaServicesWereResetNotification, object: nil)
    audioSessionWired = false
    sessionActive = false
    // Don't `setActive(false)` — the session is process-wide config and
    // other audio paths may still need it; iOS reclaims it at exit.
  }

  /// Reacts to a phone call / Siri / alarm per `interruptionPolicy`:
  /// - `pauseAndResume`: pause on `.began`; resume on `.ended` when the
  ///   OS sets `shouldResume`.
  /// - `pauseOnly`: pause on `.began`; never auto-resume.
  /// - `keepPlaying`: don't pause; reactivate the session on `.ended` so
  ///   the engine's output recovers after the interruption.
  @objc private func handleAudioSessionInterruption(_ note: Notification) {
    guard let info = note.userInfo,
          let typeRaw = info[AVAudioSessionInterruptionTypeKey] as? UInt,
          let type = AVAudioSession.InterruptionType(rawValue: typeRaw)
    else { return }

    // iOS 10+ delivers a synthetic interruption when the app was merely
    // suspended (its session deactivated in the background) — not a real
    // call/Siri interruption. Treat it as a no-op so foregrounding doesn't
    // fire a spurious pause/resume.
    if type == .began,
       (info[AVAudioSessionInterruptionWasSuspendedKey] as? Bool) == true {
      return
    }

    DispatchQueue.main.async {
      let policy = self.currentInterruptionPolicy()
      switch type {
      case .began:
        // The session is deactivated for the interruption's duration.
        self.sessionActive = false
        // Only pause (and arm resume) if we were actually playing — a manual
        // pause before the interruption must not auto-resume on `.ended`.
        self.wasPlayingBeforeInterruption =
          (self.currentPlayback["playing"] as? Bool) ?? false
        if policy != "keepPlaying", self.wasPlayingBeforeInterruption {
          self.eventSink?(["type": "pause"])
        }
      case .ended:
        switch policy {
        case "keepPlaying":
          // We never paused; reactivate the session, then have the player
          // reopen its output: the AudioUnit the system stopped for the
          // interruption does not restart with the session, so the engine
          // would keep "playing" into silence.
          if (try? AVAudioSession.sharedInstance().setActive(true, options: []))
            != nil { self.sessionActive = true }
          self.eventSink?(["type": "reloadAudioOutput"])
        case "pauseOnly":
          break  // paused on `.began`, no auto-resume
        default:  // pauseAndResume
          let optsRaw =
            (info[AVAudioSessionInterruptionOptionKey] as? UInt) ?? 0
          let opts = AVAudioSession.InterruptionOptions(rawValue: optsRaw)
          // Resume only when the OS allows it AND we paused a genuine playback.
          if opts.contains(.shouldResume), self.wasPlayingBeforeInterruption {
            if (try? AVAudioSession.sharedInstance().setActive(true, options: []))
              != nil { self.sessionActive = true }
            self.eventSink?(["type": "play"])
          }
        }
        self.wasPlayingBeforeInterruption = false
      @unknown default:
        break
      }
    }
  }

  /// Headphones unplugged → pause, regardless of `interruptionPolicy`
  /// (Apple HIG: don't blast the speaker — even in `keepPlaying`).
  @objc private func handleAudioSessionRouteChange(_ note: Notification) {
    guard let info = note.userInfo,
          let reasonRaw = info[AVAudioSessionRouteChangeReasonKey] as? UInt,
          let reason = AVAudioSession.RouteChangeReason(rawValue: reasonRaw),
          reason == .oldDeviceUnavailable
    else { return }
    DispatchQueue.main.async {
      self.eventSink?(["type": "pause"])
    }
  }

  /// mediaserverd was reset: the audio session is inactive, every
  /// MPRemoteCommandCenter target is invalidated, and the Now Playing dict is
  /// gone. Rebuild the whole stack so the OS controls come back without an
  /// app relaunch.
  @objc private func handleMediaServicesReset(_ note: Notification) {
    DispatchQueue.main.async {
      guard self.enabled, MediaSessionPlugin.currentInstance === self else {
        return
      }
      self.applyAudioSessionConfig()  // re-set category (observers persist)
      // Command targets were invalidated — remove the stale ones and reinstall,
      // then re-apply the enabled set.
      self.reinstallCommandTargets()
      self.configureCommands()
      let playing = (self.currentPlayback["playing"] as? Bool) ?? false
      self.activateSessionIfPlaying(playing)
      // The reset also killed the player's AudioUnit; reopen the output.
      self.eventSink?(["type": "reloadAudioOutput"])
      // Defeat the publish dedup so the rebuilt dict actually re-lands.
      self.lastPublishedInfo = nil
      self.lastPublishedPlaybackState = .unknown
      self.publishNowPlaying()
    }
  }
  #endif

  /// Removes the (now invalid) shared command targets and reinstalls them.
  /// Used by the iOS media-services-reset recovery; the targets are
  /// process-wide, so this clears the static storage before re-adding.
  private func reinstallCommandTargets() {
    dispatchPrecondition(condition: .onQueue(.main))
    for (command, target) in MediaSessionPlugin.sharedCommandTargets {
      command.removeTarget(target)
    }
    MediaSessionPlugin.sharedCommandTargets.removeAll()
    MediaSessionPlugin.sharedCommandsInstalled = false
    installCommandTargetsIfNeeded()
  }

  // ── Now-playing snapshot ──────────────────────────────────────────

  internal func publishNowPlaying() {
    dispatchPrecondition(condition: .onQueue(.main))

    // macOS "poison" guard: do NOT publish a content-less entry. Setting
    // an empty / paused `nowPlayingInfo` before there's real media drops
    // the app from Control Center (the system reverts to the Music app)
    // and a later `.playing` won't resurface — so publish only once a
    // title exists.
    guard let resolvedTitle = (currentMetadata["title"] as? String)
      .flatMap({ $0.isEmpty ? nil : $0 })
    else { return }

    var info: [String: Any] = [:]

    info[MPNowPlayingInfoPropertyMediaType] =
      NSNumber(value: MPNowPlayingInfoMediaType.audio.rawValue)

    // Live only when truly unbounded: not seekable AND no known duration.
    // A freshly-loaded seekable file can briefly report seekable=false
    // before mpv's `seekable` observation lands; if its duration is
    // already known it is not a live stream, so don't suppress the
    // scrubber / duration for that one frame. The lockscreen suppresses
    // the scrub-bar for a genuine live stream rather than render a phantom.
    let seekable = (currentPlayback["seekable"] as? Bool) ?? true
    let durationMs = currentMetadata["durationMs"] as? Int
    let isLiveStream = !seekable && (durationMs == nil || durationMs! <= 0)
    if isLiveStream {
      info[MPNowPlayingInfoPropertyIsLiveStream] = true
    }

    info[MPMediaItemPropertyTitle] = resolvedTitle
    if let artist = currentMetadata["artist"] as? String, !artist.isEmpty {
      info[MPMediaItemPropertyArtist] = artist
    }
    if let album = currentMetadata["album"] as? String, !album.isEmpty {
      info[MPMediaItemPropertyAlbumTitle] = album
    }
    // Rich tags — CarPlay / Now Playing show "track N of M", album artist.
    if let albumArtist = currentMetadata["albumArtist"] as? String,
       !albumArtist.isEmpty {
      info[MPMediaItemPropertyAlbumArtist] = albumArtist
    }
    if let genre = currentMetadata["genre"] as? String, !genre.isEmpty {
      info[MPMediaItemPropertyGenre] = genre
    }
    if let track = currentMetadata["trackNumber"] as? Int, track > 0 {
      info[MPMediaItemPropertyAlbumTrackNumber] = NSNumber(value: track)
    }
    if let disc = currentMetadata["discNumber"] as? Int, disc > 0 {
      info[MPMediaItemPropertyDiscNumber] = NSNumber(value: disc)
    }

    if !isLiveStream, let durationMs = durationMs, durationMs > 0 {
      info[MPMediaItemPropertyPlaybackDuration] =
        NSNumber(value: Double(durationMs) / 1000.0)
    }

    // Elapsed: the scrub-freeze target if pinned, else mpv's position.
    if !isLiveStream {
      if let frozen = frozenElapsed {
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] =
          NSNumber(value: frozen)
      } else if let posMs = currentPlayback["positionMs"] as? Int {
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] =
          NSNumber(value: Double(posMs) / 1000.0)
      }
    }

    if let artwork = resolveArtwork() {
      info[MPMediaItemPropertyArtwork] = artwork
    }

    let playing = (currentPlayback["playing"] as? Bool) ?? false
    #if os(iOS)
    // Take the audio route lazily — only once real playing content is
    // published — so enabling the session at app launch doesn't pre-empt
    // another app's audio before this player produces any output.
    activateSessionIfPlaying(playing)
    #endif
    let rate = (currentPlayback["rate"] as? Double) ?? 1.0
    // Frozen ⇒ rate 0 so the OS stops extrapolating and pins the slider
    // at the drop target. Otherwise mirror mpv: rate when playing, 0
    // when paused.
    let publishedRate = frozenElapsed != nil ? 0.0 : (playing ? rate : 0.0)
    info[MPNowPlayingInfoPropertyPlaybackRate] = NSNumber(value: publishedRate)
    info[MPNowPlayingInfoPropertyDefaultPlaybackRate] = NSNumber(value: 1.0)

    let nextPlaybackState: MPNowPlayingPlaybackState =
      playing ? .playing : .paused

    // Repeat / shuffle live on MPRemoteCommandCenter, not in the
    // nowPlayingInfo dict — update them before the dedup gate (which
    // compares only the dict), or a loop/shuffle-only change would be
    // swallowed.
    publishCurrentRepeatAndShuffle()

    // Skip enablement also lives on MPRemoteCommandCenter (outside the dict),
    // and navigability changes arrive on playback — refresh here so the lock-
    // screen / CarPlay skip buttons grey out at playlist bounds.
    let skipActions = Set((currentConfig["actions"] as? [String]) ?? [])
    let cmdCenter = MPRemoteCommandCenter.shared()
    cmdCenter.nextTrackCommand.isEnabled =
      skipActions.contains("next") && (currentPlayback["hasNext"] as? Bool ?? true)
    cmdCenter.previousTrackCommand.isEnabled =
      skipActions.contains("previous")
      && (currentPlayback["hasPrevious"] as? Bool ?? true)

    // Dedup: the widget re-animates the slider on every assignment even
    // when nothing changed — skip identical writes.
    if let last = lastPublishedInfo,
       lastPublishedPlaybackState == nextPlaybackState,
       Self.isInfoEqual(last, info)
    {
      return
    }

    let center = MPNowPlayingInfoCenter.default()
    center.nowPlayingInfo = info
    center.playbackState = nextPlaybackState
    lastPublishedInfo = info
    lastPublishedPlaybackState = nextPlaybackState
    publishCount += 1
  }

  /// Field-by-field comparison. Artwork compares by reference identity —
  /// `resolveArtwork`'s cache reuses the same wrapper for unchanged bytes.
  private static func isInfoEqual(_ a: [String: Any], _ b: [String: Any])
    -> Bool
  {
    let scalarKeys: [String] = [
      MPNowPlayingInfoPropertyElapsedPlaybackTime,
      MPNowPlayingInfoPropertyPlaybackRate,
      MPNowPlayingInfoPropertyDefaultPlaybackRate,
      MPNowPlayingInfoPropertyIsLiveStream,
      MPNowPlayingInfoPropertyMediaType,
      MPMediaItemPropertyTitle,
      MPMediaItemPropertyArtist,
      MPMediaItemPropertyAlbumTitle,
      MPMediaItemPropertyPlaybackDuration,
      MPMediaItemPropertyAlbumArtist,
      MPMediaItemPropertyGenre,
      MPMediaItemPropertyAlbumTrackNumber,
      MPMediaItemPropertyDiscNumber,
    ]
    for key in scalarKeys {
      let av = a[key] as? NSObject
      let bv = b[key] as? NSObject
      if av != bv { return false }
    }
    let aArt = a[MPMediaItemPropertyArtwork] as AnyObject?
    let bArt = b[MPMediaItemPropertyArtwork] as AnyObject?
    if aArt !== bArt { return false }
    return true
  }

  private func publishCurrentRepeatAndShuffle() {
    dispatchPrecondition(condition: .onQueue(.main))
    let center = MPRemoteCommandCenter.shared()

    let loopWire = currentPlayback["loop"] as? String ?? "off"
    let repeatType: MPRepeatType
    switch loopWire {
    case "file": repeatType = .one
    case "playlist": repeatType = .all
    default: repeatType = .off
    }
    center.changeRepeatModeCommand.currentRepeatType = repeatType

    let shuffleOn = (currentPlayback["shuffle"] as? Bool) ?? false
    center.changeShuffleModeCommand.currentShuffleType =
      shuffleOn ? .items : .off
  }

  private func resolveArtwork() -> MPMediaItemArtwork? {
    if let bytes = currentMetadata["artworkBytes"] as? FlutterStandardTypedData {
      artworkUrlKey = nil  // leaving the URL path

      // Cache by byte identity. The wrapper's bounds are declared at the
      // image's true aspect ratio (longest edge capped at `artworkBoundsSide`)
      // so the OS requests proportional sizes and non-square art isn't
      // stretched; the closure downscales on demand and retains the decoded
      // image, so the system can request lockscreen / Control Center /
      // CarPlay / Watch sizes without a second copy of the bitmap.
      if artworkCacheKey != bytes.data,
         let image = PlatformImage(data: bytes.data)
      {
        artworkCacheKey = bytes.data
        artworkCacheObject =
          MPMediaItemArtwork(boundsSize: Self.boundsSize(for: image)) { size in
            Self.resizedArtwork(image, to: size)
          }
      }
      return artworkCacheObject
    }

    // A URL the OS can't decode for us (unlike Android / Windows / Linux,
    // MPNowPlayingInfoCenter needs a concrete image), so fetch it once via
    // URLSession off the main thread and re-publish when it lands. Keyed by
    // the URL string so the per-second playback pushes don't re-fetch.
    if let urlString = currentMetadata["artworkUri"] as? String,
       !urlString.isEmpty,
       let url = URL(string: urlString)
    {
      if artworkUrlKey != urlString {
        artworkUrlKey = urlString
        artworkCacheKey = nil
        artworkCacheObject = nil  // until the fetch lands
        fetchArtwork(from: url, key: urlString)
      }
      return artworkCacheObject
    }

    artworkCacheKey = nil
    artworkUrlKey = nil
    artworkCacheObject = nil
    return nil
  }

  /// Downloads remote [url] artwork and, if the track hasn't changed by the
  /// time it lands ([key] still current), caches the wrapper and re-publishes
  /// so the lockscreen picks it up.
  private func fetchArtwork(from url: URL, key: String) {
    URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
      guard let data = data, let image = PlatformImage(data: data) else {
        return
      }
      DispatchQueue.main.async {
        guard let self = self, self.artworkUrlKey == key else { return }
        self.artworkCacheObject =
          MPMediaItemArtwork(boundsSize: Self.boundsSize(for: image)) { size in
            Self.resizedArtwork(image, to: size)
          }
        if self.enabled { self.publishNowPlaying() }
      }
    }.resume()
  }

  /// The artwork's natural size scaled so its longest edge is at most
  /// `artworkBoundsSide` (never upscaled). Preserves aspect ratio so the
  /// OS-requested sizes — and therefore `resizedArtwork`'s draw rect — stay
  /// proportional. Falls back to a square bound when the image reports no
  /// intrinsic size.
  private static func boundsSize(for image: PlatformImage) -> CGSize {
    let natural = image.size
    let maxEdge = max(natural.width, natural.height)
    guard maxEdge > 0 else {
      return CGSize(width: artworkBoundsSide, height: artworkBoundsSide)
    }
    let scale = min(1.0, artworkBoundsSide / maxEdge)
    return CGSize(width: natural.width * scale, height: natural.height * scale)
  }

  private static func resizedArtwork(_ image: PlatformImage,
                                     to size: CGSize) -> PlatformImage
  {
    #if os(iOS)
    let format = UIGraphicsImageRendererFormat.default()
    format.scale = 1
    format.opaque = false
    let renderer = UIGraphicsImageRenderer(size: size, format: format)
    return renderer.image { _ in
      image.draw(in: CGRect(origin: .zero, size: size))
    }
    #elseif os(macOS)
    let resized = NSImage(size: size)
    resized.lockFocus()
    NSGraphicsContext.current?.imageInterpolation = .high
    image.draw(
      in: NSRect(origin: .zero, size: size),
      from: NSRect(origin: .zero, size: image.size),
      operation: .copy,
      fraction: 1.0)
    resized.unlockFocus()
    return resized
    #endif
  }

  // ── Remote command center wiring ──────────────────────────────────

  /// One-time, process-wide install of every command target. Held in
  /// static storage so the list cannot grow across engine restarts —
  /// every closure resolves `currentInstance` at fire time and no-ops
  /// when there's no active plugin. Later config changes only flip
  /// `isEnabled`. Unsupported commands are pinned disabled.
  private func installCommandTargetsIfNeeded() {
    dispatchPrecondition(condition: .onQueue(.main))
    guard !MediaSessionPlugin.sharedCommandsInstalled else { return }
    MediaSessionPlugin.sharedCommandsInstalled = true

    let center = MPRemoteCommandCenter.shared()

    Self.installSimple(center.playCommand, type: "play")
    Self.installSimple(center.pauseCommand, type: "pause")
    Self.installSimple(center.togglePlayPauseCommand, type: "playPause")
    Self.installSimple(center.stopCommand, type: "stop")
    Self.installSimple(center.nextTrackCommand, type: "next")
    Self.installSimple(center.previousTrackCommand, type: "previous")

    let repeatCmd = center.changeRepeatModeCommand
    let repeatTarget = repeatCmd.addTarget { event in
      guard let instance = MediaSessionPlugin.currentInstance
      else { return .commandFailed }
      guard let evt = event as? MPChangeRepeatModeCommandEvent
      else { return .commandFailed }
      let wire: String
      switch evt.repeatType {
      case .off: wire = "off"
      case .one: wire = "file"
      case .all: wire = "playlist"
      @unknown default: wire = "off"
      }
      instance.onMain {
        guard !instance.currentMetadata.isEmpty else { return }
        instance.eventSink?(["type": "setRepeatMode", "loop": wire])
      }
      return .success
    }
    MediaSessionPlugin.sharedCommandTargets.append((repeatCmd, repeatTarget))

    let shuffleCmd = center.changeShuffleModeCommand
    let shuffleTarget = shuffleCmd.addTarget { event in
      guard let instance = MediaSessionPlugin.currentInstance
      else { return .commandFailed }
      guard let evt = event as? MPChangeShuffleModeCommandEvent
      else { return .commandFailed }
      // mpv models shuffle as a bool; anything non-.off → true.
      let on = evt.shuffleType != .off
      instance.onMain {
        guard !instance.currentMetadata.isEmpty else { return }
        instance.eventSink?(["type": "setShuffle", "shuffle": on])
      }
      return .success
    }
    MediaSessionPlugin.sharedCommandTargets.append((shuffleCmd, shuffleTarget))

    let rateCmd = center.changePlaybackRateCommand
    let rateTarget = rateCmd.addTarget { event in
      guard let instance = MediaSessionPlugin.currentInstance
      else { return .commandFailed }
      guard let evt = event as? MPChangePlaybackRateCommandEvent
      else { return .commandFailed }
      let rate = Double(evt.playbackRate)
      instance.onMain {
        guard !instance.currentMetadata.isEmpty else { return }
        instance.eventSink?(["type": "setPlaybackRate", "rate": rate])
      }
      return .success
    }
    MediaSessionPlugin.sharedCommandTargets.append((rateCmd, rateTarget))

    let scrubTarget = center.changePlaybackPositionCommand.addTarget { event in
      guard let instance = MediaSessionPlugin.currentInstance
      else { return .commandFailed }
      guard let posEvent = event as? MPChangePlaybackPositionCommandEvent
      else { return .commandFailed }
      let target = posEvent.positionTime
      // handleScrub mutates state, publishes, and asserts the main queue —
      // hop before calling it (MPRemoteCommand handlers aren't guaranteed
      // to run on main).
      instance.onMain {
        guard !instance.currentMetadata.isEmpty else { return }
        instance.handleScrub(to: target)
      }
      return .success
    }
    MediaSessionPlugin.sharedCommandTargets.append(
      (center.changePlaybackPositionCommand, scrubTarget))

    let skipFwd = center.skipForwardCommand
    let skipFwdTarget = skipFwd.addTarget { event in
      guard let instance = MediaSessionPlugin.currentInstance
      else { return .commandFailed }
      guard let evt = event as? MPSkipIntervalCommandEvent
      else { return .commandFailed }
      let offsetMs = Int((evt.interval * 1000.0).rounded())
      instance.onMain {
        guard !instance.currentMetadata.isEmpty else { return }
        instance.eventSink?(["type": "seekBy", "offsetMs": offsetMs])
      }
      return .success
    }
    MediaSessionPlugin.sharedCommandTargets.append((skipFwd, skipFwdTarget))

    let skipBack = center.skipBackwardCommand
    let skipBackTarget = skipBack.addTarget { event in
      guard let instance = MediaSessionPlugin.currentInstance
      else { return .commandFailed }
      guard let evt = event as? MPSkipIntervalCommandEvent
      else { return .commandFailed }
      let offsetMs = -Int((evt.interval * 1000.0).rounded())
      instance.onMain {
        guard !instance.currentMetadata.isEmpty else { return }
        instance.eventSink?(["type": "seekBy", "offsetMs": offsetMs])
      }
      return .success
    }
    MediaSessionPlugin.sharedCommandTargets.append((skipBack, skipBackTarget))

    // "Like"/favourite is the one feedback command that surfaces in practice
    // (iOS lock screen / CarPlay / watchOS; macOS Control Center renders no
    // feedback buttons). The press is decoded on the Dart side into
    // MediaSessionCommandLike — it's emit-only (NOT auto-applied, since there
    // is no built-in favourite concept), so the consumer app reacts to it and
    // reflects state back via isFavorite. Enablement is gated per-action in
    // configureCommands().
    Self.installSimple(center.likeCommand, type: "like")

    // The remaining feedback / language / continuous-seek commands don't
    // render usefully on any target surface here, so they stay pinned off.
    let unsupported: [MPRemoteCommand] = [
      center.ratingCommand,
      center.dislikeCommand,
      center.bookmarkCommand,
      center.enableLanguageOptionCommand,
      center.disableLanguageOptionCommand,
      center.seekForwardCommand,
      center.seekBackwardCommand,
    ]
    for command in unsupported {
      command.isEnabled = false
    }
  }

  /// Single-event command installer (no payload). The handler resolves
  /// `currentInstance` lazily so the target survives engine restarts.
  private static func installSimple(_ command: MPRemoteCommand, type: String) {
    let target = command.addTarget { _ in
      guard let instance = MediaSessionPlugin.currentInstance
      else { return .commandFailed }
      // Hop to main before touching main-only state (currentMetadata,
      // eventSink); MPRemoteCommand handlers aren't guaranteed to run on
      // the main queue. Return .success synchronously — commands are
      // advisory and tolerate the async hop.
      instance.onMain {
        guard !instance.currentMetadata.isEmpty else { return }
        instance.eventSink?(["type": type])
      }
      return .success
    }
    sharedCommandTargets.append((command, target))
  }

  /// Pins the slider at the drop target (rate 0) and forwards the seek
  /// to Dart. The freeze clears on the next `updatePlayback` (the
  /// landed position). A double-fired command just re-pins the same
  /// target and re-forwards — harmless.
  internal func handleScrub(to seconds: TimeInterval) {
    dispatchPrecondition(condition: .onQueue(.main))
    frozenElapsed = seconds
    publishNowPlaying()
    eventSink?([
      "type": "seekTo",
      "positionMs": Int((seconds * 1000.0).rounded()),
    ])
    // Backstop: if no landing reconciles the freeze within ~2s (the seek
    // failed, was clamped past EOF, or landed >1s off on an approximate-
    // seekable source), force-clear so the slider can't strand at rate 0
    // forever. A newer scrub bumps the generation and supersedes this.
    scrubFreezeGeneration += 1
    let gen = scrubFreezeGeneration
    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
      guard let self = self, self.frozenElapsed != nil,
            self.scrubFreezeGeneration == gen else { return }
      self.frozenElapsed = nil
      if self.enabled { self.publishNowPlaying() }
    }
  }

  private func configureCommands() {
    dispatchPrecondition(condition: .onQueue(.main))
    let actions = Set((currentConfig["actions"] as? [String]) ?? [])
    let center = MPRemoteCommandCenter.shared()

    center.playCommand.isEnabled = actions.contains("play")
    center.pauseCommand.isEnabled = actions.contains("pause")
    center.togglePlayPauseCommand.isEnabled = actions.contains("playPause")
    center.stopCommand.isEnabled = actions.contains("stop")
    // next / previous follow the advertised action set even on a
    // single-item mpv playlist: the command is still delivered on
    // `Player.stream.mediaSessionCommands` so a consumer driving its own
    // external queue can advance it. (mpv-playlist auto-advance is a
    // convenience layered on top, gated separately in `_handleSessionCommand`.)
    // Gate skip enablement on real navigability so the buttons grey out at
    // playlist bounds. Refreshed on playback in publishNowPlaying.
    center.nextTrackCommand.isEnabled =
      actions.contains("next") && (currentPlayback["hasNext"] as? Bool ?? true)
    center.previousTrackCommand.isEnabled =
      actions.contains("previous")
      && (currentPlayback["hasPrevious"] as? Bool ?? true)
    center.skipForwardCommand.isEnabled = actions.contains("fastForward")
    center.skipBackwardCommand.isEnabled = actions.contains("rewind")
    center.changeRepeatModeCommand.isEnabled = actions.contains("setRepeatMode")
    center.changeShuffleModeCommand.isEnabled = actions.contains("setShuffle")
    center.changePlaybackRateCommand.isEnabled =
      actions.contains("setPlaybackRate")

    // "Like"/favourite: gated per-action, titled, and its active (filled)
    // state driven by the consumer's `isFavorite`. The press is delivered to
    // Dart (installSimple emits "like") → MediaSessionCommandLike.
    center.likeCommand.isEnabled = actions.contains("like")
    center.likeCommand.localizedTitle = "Favorite"
    center.likeCommand.isActive = currentConfig["isFavorite"] as? Bool ?? false

    applySkipIntervals()
    applySupportedPlaybackRates()
    refreshSeekableGate()
  }

  private func applySupportedPlaybackRates() {
    dispatchPrecondition(condition: .onQueue(.main))
    let rates = (currentConfig["supportedPlaybackRates"] as? [Double])
      ?? [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0]
    MPRemoteCommandCenter.shared().changePlaybackRateCommand.supportedPlaybackRates =
      rates.map { NSNumber(value: $0) }
  }

  private func applySkipIntervals() {
    dispatchPrecondition(condition: .onQueue(.main))
    let center = MPRemoteCommandCenter.shared()
    let fwdMs = (currentConfig["fastForwardIntervalMs"] as? Int)
      ?? Int(Self.defaultSkipIntervalSeconds * 1000)
    let backMs = (currentConfig["rewindIntervalMs"] as? Int)
      ?? Int(Self.defaultSkipIntervalSeconds * 1000)
    // NOTE: just set the intervals — do NOT bounce `isEnabled` to "force a
    // redraw". iOS reflects a live `preferredIntervals` change immediately;
    // macOS Control Center caches the skip glyph and only re-reads on a fresh
    // now-playing session, but bouncing isEnabled doesn't fix that and only
    // adds a flicker on iOS. The stale macOS number is an OS quirk, not ours.
    center.skipForwardCommand.preferredIntervals =
      [NSNumber(value: Double(fwdMs) / 1000.0)]
    center.skipBackwardCommand.preferredIntervals =
      [NSNumber(value: Double(backMs) / 1000.0)]
  }

  /// Gates the scrubber on the current `seekable` state. Clears any
  /// active freeze when the source becomes non-seekable so a pinned
  /// slider doesn't get stranded.
  internal func refreshSeekableGate() {
    dispatchPrecondition(condition: .onQueue(.main))
    let actions = Set((currentConfig["actions"] as? [String]) ?? [])
    let seekable = (currentPlayback["seekable"] as? Bool) ?? true
    MPRemoteCommandCenter.shared().changePlaybackPositionCommand.isEnabled =
      actions.contains("seek") && seekable
    if !seekable { frozenElapsed = nil }
  }

  // ── Debug probe (test seam) ───────────────────────────────────────

  private func debugNowPlayingSnapshot() -> [String: Any] {
    dispatchPrecondition(condition: .onQueue(.main))
    let center = MPNowPlayingInfoCenter.default()
    let info = center.nowPlayingInfo ?? [:]
    var out: [String: Any] = [
      "publishCount": publishCount,
      "playbackState": Self.playbackStateName(center.playbackState),
      "frozen": frozenElapsed != nil,
      "hasArtwork": info[MPMediaItemPropertyArtwork] != nil,
    ]
    if let v = info[MPMediaItemPropertyTitle] as? String { out["title"] = v }
    if let v = info[MPMediaItemPropertyArtist] as? String { out["artist"] = v }
    if let v = info[MPMediaItemPropertyAlbumTitle] as? String { out["album"] = v }
    if let v = info[MPNowPlayingInfoPropertyElapsedPlaybackTime] as? NSNumber {
      out["elapsed"] = v.doubleValue
    }
    if let v = info[MPMediaItemPropertyPlaybackDuration] as? NSNumber {
      out["duration"] = v.doubleValue
    }
    if let v = info[MPNowPlayingInfoPropertyPlaybackRate] as? NSNumber {
      out["rate"] = v.doubleValue
    }
    if let v = info[MPNowPlayingInfoPropertyIsLiveStream] as? NSNumber {
      out["isLiveStream"] = v.boolValue
    }
    return out
  }

  private static func playbackStateName(_ s: MPNowPlayingPlaybackState) -> String {
    switch s {
    case .playing: return "playing"
    case .paused: return "paused"
    case .stopped: return "stopped"
    case .interrupted: return "interrupted"
    default: return "unknown"
    }
  }

  // ── FlutterStreamHandler ──────────────────────────────────────────

  public func onListen(
    withArguments arguments: Any?,
    eventSink events: @escaping FlutterEventSink
  ) -> FlutterError? {
    eventSink = events
    return nil
  }

  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    eventSink = nil
    return nil
  }

  // ── Helpers ───────────────────────────────────────────────────────

  /// Main-queue hop, sync if already there. MediaPlayer + AVAudioSession
  /// notifications arrive on arbitrary queues; all state is main-only.
  private func onMain(_ block: @escaping () -> Void) {
    if Thread.isMainThread {
      block()
    } else {
      DispatchQueue.main.async(execute: block)
    }
  }
}
