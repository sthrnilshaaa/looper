# Licenses

## The package

The package's code is BSD-3-Clause ([LICENSE](LICENSE)).

The doc comments of the generated effects API (`lib/src/generated/audio_effects.dart` and `audio_effects_settings.dart`) quote the descriptions FFmpeg gives its filters and options. That text keeps FFmpeg's licenses, as the header of each file says.

## The bundled libmpv

libmpv is mpv, FFmpeg and the libraries they link, built by [libmpv-scripts](https://github.com/ales-drnz/libmpv-scripts) under the LGPL, version 3 or later. Each library keeps its own license.

An app that ships it can keep its own license, on the conditions of the LGPL. Among them, it has to:

| Duty | How |
| :--- | :--- |
| Show the license texts | `showLicensePage` and `AboutDialog` list them, registered by `MpvAudioKit.ensureInitialized`. On the web they are also in `web/THIRD_PARTY_LICENSES.txt` |
| Say that it uses libmpv under the LGPL | A line in the app's about page or license page |
| Let the user replace libmpv | Every target loads libmpv as its own library or module |
| Make the source available | The `README.txt` in the release's `licenses.zip` names the libmpv-scripts commit and each source it downloaded. Keep a copy of them |

An app that bundles its own libmpv with the `libmpv` user define ships the `THIRD_PARTY_LICENSES.txt` of that build. `showLicensePage` still lists the texts of the bundled libmpv, so add the texts of your build to the `LicenseRegistry` yourself.

## Rubber Band

Rubber Band is GPL, so the bundled libmpv leaves it out. For pitch and tempo, use `setPitch`, `setRate` and the `AtempoEffect` and `AsetrateEffect` stages.

To use it anyway, build libmpv with libmpv-scripts' GPL option (`LIBMPV_GPL=1`), at the release of the bundled libmpv: the player runs on no other. Bundle it with the `libmpv` user define. On the web, load it with `MpvAudioKit.ensureInitialized(libmpv: url)`. Then add the filter as a raw stage:

```dart
await player.setAudioEffects(const [
  RawAudioEffect('lavfi-rubberband=pitch=1.0594:pitchq=quality'),
]);
```

That build is GPL, version 3 or later, and so is an app that ships it.
