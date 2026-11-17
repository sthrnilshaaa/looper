# Local patch of mpv_audio_kit 0.4.9

Upstream: https://pub.dev/packages/mpv_audio_kit (BSD-3-Clause, see LICENSE).
Copied from the 0.4.9 release; `example/` and `imgs/` left out.

## Change

`AudioEffects.toAfChain()` (lib/src/generated/audio_effects_settings.dart)
emits `alimiter` and then `aresample` **last**, after every other stage.
Upstream emits stages alphabetically, which put the limiter before the EQ,
bass and treble boosts, so heavy boosts could clip
(Looper docs/online/25-audio-lab.md §3.1).

## Updating

Copy the new release over this folder, re-apply the change above, and keep
this file. Drop the copy once upstream orders the chain itself.
