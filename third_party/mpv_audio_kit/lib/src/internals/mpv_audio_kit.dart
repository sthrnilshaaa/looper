// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'package:meta/meta.dart';

import '../backend/backend.dart' as backend;
import '../events/player_exception.dart' show PlayerInitException;
import '../player/player.dart' show Player;
import '../types/enums/spdif.dart';
import 'libmpv_license_registry.dart';
import 'passthrough_codecs.dart';

/// One-time initialization for `mpv_audio_kit`. Owns the choice of the
/// libmpv the players use and the cleanup of the cores that leaked across
/// Flutter Hot-Restarts, both of which the backend carries out.
///
/// {@category Platforms}
/// {@category Web}
/// {@category Android TV}
/// {@category Wear OS}
/// {@category Tizen}
/// {@category webOS}
/// {@category HarmonyOS}
abstract final class MpvAudioKit {
  MpvAudioKit._();

  static bool _initialized = false;
  static String? _libraryPath;

  /// Whether [ensureInitialized] ran in this isolate.
  @internal
  static bool get isInitialized => _initialized;

  /// Returns the path used to initialize the library, if provided.
  static String? get libraryPath => _libraryPath;

  /// Whether the browser holds the sound of every player until the user
  /// interacts with the page: its autoplay policy starts the page's audio
  /// output suspended. Meanwhile a playing player stays at its position
  /// and nothing is heard. The first click, tap or key press resumes it,
  /// and so does [Player.play] called from one. Always `false` outside the
  /// web.
  ///
  /// An app that starts playback on its own (a restored session) can show
  /// a prompt while this is `true`.
  static bool get needsUserGesture => backend.outputNeedsGesture;

  /// Why a [Player] cannot run on this platform, or `null` when it can.
  /// On the web the page must be a secure context, cross-origin isolated
  /// (COOP and COEP headers) and have SharedArrayBuffer and AudioWorklet;
  /// otherwise this names what is missing, and a player fails with a
  /// [PlayerInitException] that says the same. Always `null` outside the
  /// web.
  ///
  /// An app can read it before it creates a player, to show its own
  /// message instead.
  static String? get unsupportedReason => backend.unsupportedReason;

  /// The passthrough codecs the audio output takes, for
  /// [Player.setAudioSpdif]: those of AC3, E-AC3 and DTS that the HDMI
  /// sink of an Android TV box or stick accepts. On API 29 and later
  /// Android tells whether the output plays each one directly; before, the
  /// sink's list comes with the HDMI plug.
  ///
  /// Empty on the other platforms, where passthrough depends on the
  /// device mpv opens, and when the output takes none. TrueHD and DTS-HD
  /// are never in it: the Android output sends passthrough as IEC61937
  /// stereo, which cannot carry them. The sink can change (another HDMI
  /// port, a soundbar turned on): read it again before a new session.
  ///
  /// ```dart
  /// await player.setAudioSpdif(await MpvAudioKit.passthroughCodecs());
  /// ```
  static Future<Set<Spdif>> passthroughCodecs() => readPassthroughCodecs();

  /// [needsUserGesture] at each change, from the moment the web module has
  /// loaded. Never emits outside the web.
  static Stream<bool> get needsUserGestureStream =>
      backend.outputNeedsGestureChanges;

  /// Initializes the native backend for `mpv_audio_kit`.
  /// Must be called before creating any [Player] instances.
  ///
  /// Its settings hold per isolate: a [Player] created in another isolate
  /// needs a call there too, with the same [libmpv] and
  /// `hotRestartCleanup: false`.
  ///
  /// Handles cleanup of orphaned `libmpv` native resources
  /// (e.g., handles that leaked across a Flutter Hot-Restart).
  ///
  /// [libmpv] (optional): explicit path or filename for the native
  /// `libmpv` library to load via `DynamicLibrary.open`. When `null`
  /// (the default), the libmpv the package's build hook bundles with the
  /// app is used, or on webOS, where flutter-webos runs no build hook,
  /// the one webos/CMakeLists.txt bundles. The library must be the libmpv
  /// of the release this version of the package pins (`mpv-version` ends
  /// with its `+rN`): with any other, or with one of upstream mpv, a
  /// [Player] fails to start with a `PlayerInitException`.
  ///
  /// On the web [libmpv] is the URL of the `libmpv.mjs` of another build of
  /// the web module, with its `libmpv.wasm` and
  /// `mak_webaudio_processor.js` beside it on the page's origin; `null`
  /// loads the one the package ships as web assets. The module loads in the
  /// background from this call on, and the first [Player] waits for it.
  ///
  /// [hotRestartCleanup] (default: `true`): recovers libmpv handles
  /// leaked across a Flutter Hot-Restart so they don't keep
  /// exclusive-mode audio devices locked. In the root isolate only (see
  /// `releasesPcmSourcesAtInit`), it also releases the live PCM sources of
  /// the replaced VM, turns off the waveform, loudness scan and filter taps
  /// its listeners left on, and disables its OS media session. Pass `false`
  /// in test runners, background isolates and other multi-VM scenarios
  /// that share a pid: the tracker keeps one buffer per process, for the VM
  /// that sets it up first, and the cleanup after a Hot-Restart reaches
  /// the PCM sources and the analysis switches of the whole process. A VM
  /// that finds the owner of the buffer still running takes none of its
  /// handles.
  /// On the web it destroys the players, PCM sources and audio output the
  /// app left in the page before a Hot Restart, and reuses its module.
  ///
  /// The first call also adds the license texts of the bundled libmpv to
  /// Flutter's `LicenseRegistry`, so `showLicensePage` and `AboutDialog`
  /// list them (under `libmpv`, `mpv`, `FFmpeg`, `OpenSSL` and the other
  /// components) beside the app's Dart packages.
  static void ensureInitialized({
    String? libmpv,
    bool hotRestartCleanup = true,
  }) {
    if (_initialized) {
      return;
    }
    registerLibmpvLicenses();
    libmpv ??= backend.defaultLibmpv();
    backend.startBackend(libmpv: libmpv, hotRestartCleanup: hotRestartCleanup);
    _libraryPath = libmpv;
    _initialized = true;
    if (hotRestartCleanup) backend.backendInitialized();
  }
}
