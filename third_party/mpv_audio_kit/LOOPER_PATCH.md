# Looper patch

Copy of mpv_audio_kit 0.8.0 from pub.dev, without `doc/`, `example/`, `imgs/` and the web build of libmpv (`web/libmpv.mjs`, `web/libmpv.wasm`; Looper doesn't build for the web). The build hook still downloads libmpv for Android.

Changes, all marked `LOOPER PATCH`, in `android/src/main/kotlin/com/alesdrnz/mpv_audio_kit/media_session/`:

- `AudioFocusController.kt`
  - `keepPlaying` (Looper's "Manage Audio Focus" off) doesn't request audio focus, and drops a focus it holds. Upstream still takes focus under `keepPlaying`, which pauses other apps. It also keeps the request after a permanent loss without asking again on the next play, so Android 12+ can fade the app out to silence while it reports playing.
  - A call that starts within 2 s of a becoming-noisy pause still arms the resume after the call. A call on a Bluetooth headset moves the route first, and upstream saw an already paused player then.
  - `onNewSession()` and `onPolicyChanged()` for the two changes below.
- `MediaSessionManager.kt`
  - A disable keeps the focus for 3 s, and an enable in that window takes the controller over. Looper's crossfade moves the session from one player to the other with ~600 ms between the two, which upstream left without focus (calls and other apps went unanswered, and the resume after a call was lost).
  - A policy change applies at once (it used to wait for the next play or pause).

Drop this copy once upstream covers these; check its CHANGELOG for `keepPlaying` and focus hand-over.
