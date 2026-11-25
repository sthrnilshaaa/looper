# Contributing

How the package is built, tested and released, for anyone who works on it.
The libmpv binaries come from [libmpv-scripts](https://github.com/ales-drnz/libmpv-scripts),
which has its own guide for the native patches (`doc/developing.md` there).

## The layout

- `lib/`: the package. `lib/mpv_audio_kit.dart` exports the public API;
  everything else is under `lib/src/`. `lib/src/generated/` comes from
  `tool/codegen` and is never edited by hand.
- `hook/build.dart`: the build hook. It downloads the libmpv of the pinned
  release for the target and checks its SHA-256 against the `_sha256`
  table. pub.dev takes nothing else in `hook/` but `build.dart` and
  `link.dart`.
- `android/`, `darwin/` (iOS and macOS), `tvos/`, `windows/`, `linux/`,
  `webos/`: the plugin's platform code (media session, audio focus,
  passthrough). `native_common/` is what the Windows and Linux plugins
  share.
- `web/`: the web module of libmpv, published with the package and out of
  git. `scripts/update_libmpv.sh` installs it.
- `test/`: unit tests in `test/unit/`, one folder per area of `lib/src/`,
  and the runtime tests, which load libmpv, in `test/runtime/`, one folder
  per theme. Shared helpers are in `test/_helpers/`.
- `test_app/`: the app of the integration tests on Android, iOS and the
  desktops, run by CI and by libmpv-scripts' check of the kit.
- `tool/`: code generation, the metrics ratchet, the generator of the data
  classes, mutation testing, the diagrams of the README.
- `scripts/`: the release scripts, and under `scripts/ci/` the ones the
  workflows run, tested in `test/ci/`.
- `doc/`: the guides published as dartdoc topics, and `doc/adr/`, the
  decision records.

## Running the tests

```bash
flutter pub get
flutter analyze
flutter test -x network
```

The unit tests need no libmpv. The runtime tests load the libmpv the hook
installs, the one of the pin in `lib/src/internals/libmpv_release.dart`. To
try a libmpv of your own, point the hook at it in your local `pubspec.yaml`:

```yaml
hooks:
  user_defines:
    mpv_audio_kit:
      libmpv: /path/to/libmpv.so
```

Never commit that entry. On a Linux with a libmpv of its own in `/usr/lib`,
the tests that expect a missing libmpv skip. `flutter test` and
`flutter analyze` can rewrite `analysis_options.yaml` and
`test_app/pubspec.lock`: put them back before a commit.

`flutter analyze` reads `test_app/` and the Dart packages under `tool/`
too, each with dependencies of its own. Without them it reports imports it
cannot resolve there:

```bash
(cd test_app && flutter pub get)
for package in metrics data_classes mutation; do dart pub get -C tool/$package; done
```

The scripts of CI have tests of their own, plain bash:

```bash
for t in test/ci/*_test.sh; do bash "$t"; done
```

On Linux the runtime tests need a sound server or a null sink: CI starts
PulseAudio with one (`.github/workflows/ci.yml`, job Test (Linux)).

## What CI checks

`.github/workflows/ci.yml` runs on the pushes to `main` and `release/*`, on
pull requests, and by hand on any branch
(`gh workflow run CI --ref <branch>`):

- **Analyze**: `flutter analyze` on three versions of Flutter: the floor
  `pubspec.yaml` declares, the stable pinned in `.github/flutter-version`,
  and the stable of the day, which reports and does not fail the run. On
  the pinned stable also `dart format`, the versions of the platform files
  against `pubspec.yaml`, a publish dry run, the drift of the generated
  code, the tests of the CI scripts (`test/ci/`) and the tvOS sources
  against the darwin ones.
- **Quality**: the metrics ratchet (`tool/metrics`, see its README), the
  drift of the data classes, the API docs, the red and green of each fix
  commit (`scripts/ci/check_trailers.sh` and `scripts/ci/verify_red.sh`)
  and the API against the version on pub.dev.
- **Test (Linux)**: the whole suite but the tag `network`, with the line
  coverage of lib against its floor (`scripts/ci/coverage.sh`).
- **Test (macOS)** and **Test (Windows)**: the test files whose result can
  depend on the host (`scripts/ci/platform_tests.sh`).
- **Test (Flutter floor)**: the whole suite on the oldest Flutter the
  package declares, then the build hook on the oldest version of each
  dependency (`flutter pub downgrade`).
- **Test (Web)**: the browser tests of `test/web/`, in Chrome, on the web
  module of the pinned libmpv.
- **Build**: `test_app/` built for Android, Linux, Windows, macOS and iOS
  (the last two with Swift Package Manager and with CocoaPods), with the
  integration tests that run on a runner: the media session on Linux and
  Windows, the smoke and codec ones on Linux.

Flutter moves in CI with a commit: the stable of every job is the version
in `.github/flutter-version`. Every action is pinned by its commit and
every job has a timeout; `test/ci/workflows_test.sh` holds both.

Three more workflows do not run on pull requests. `tizen-emulator.yml` and
`webos-headless.yml` build and start the package on the TVs, on the
`release/*` and `wip/*-tv` branches when their files change. `network.yml`
(the tests tagged `network`, weekly) and `mutation.yml` (mutation testing
of the hot files, weekly) report and gate nothing.

The ratchet fails when a number gets worse: the lines of test per line of
lib, the complexity of a function, the fields of the player, and any
change of the public API (`tool/metrics/api_surface.txt`). A growth of lib
past 300 lines warns. A change that makes one worse on purpose writes the
baseline again with `dart tool/metrics/bin/metrics.dart --write` in the
same commit, and says why. A cleanup that removes tests lowers the lines
of test per line of lib: `--write` takes it only with its reason,
`--test-ratio-drop="<why>"`.

The coverage counts every file of lib. One no test of the VM loads fails
the step until `tool/metrics/coverage_unmeasured.txt` lists it: `web` for
a file that runs in the browser alone, counted as not covered, or `none`
for one without a line to cover. The better answer is a test that loads
it.

## Commits

- A fix starts with a test that fails. The commit of the fix (subject
  `fix:` or `fix(scope):`) has a `Red:` paragraph naming the test and how it
  failed, and a `Green:` paragraph with the runs where it passed, three
  times. `verify_red.sh` runs the unit tests a `Red:` names on the parent
  commit and fails when one passes there.
- Other subjects: `feat:`, `refactor:`, `test:`, `docs:`, `ci:`, `build:`,
  `chore:`.
- The CHANGELOG and the comments use short plain sentences, without dashes
  as punctuation and without a slash for "or".

## Branches and releases

Work goes to `wip/<version>-<topic>` branches. A release gathers them in
`release/<version>` once CI is green and the change has had a review, and
`release/<version>` goes to `main` when the release is published. Pull
requests are for outside contributors.

A release of the package with a new libmpv:

1. libmpv-scripts builds the binaries on its `release/rN` branch and
   publishes `libmpv-rN` (see its guide).
2. `scripts/update_libmpv.sh rN` writes the release into
   `lib/src/internals/libmpv_release.dart`, the SHA-256 of each asset into
   `hook/build.dart` and `tvos/Package.swift`, the web module into `web/`
   and the license texts into `lib/src/internals/libmpv_licenses.dart`.
   Before `libmpv-rN` is published it takes the `manifest.json` of the
   Build's `libmpv-release` artifact as a second argument.
3. `scripts/bump_version.sh`, after setting `LIB_VERSION` at its top,
   writes the version into every platform file.
4. The CHANGELOG gets the version and date in its title.
5. On `main`: the commit of the release closes its issues with
   `closes #N`. `scripts/publish.sh` publishes from a checkout where
   `scripts/update_libmpv.sh rN` has run, so `web/` holds the module: it
   refuses when a file of the module is missing or is not the manifest's,
   the tree is not clean, a platform file has another version, or the tag
   is already there (`--check` only checks, `--dry-run` stops at the dry
   run). The tag `vX.Y.Z` comes after.
