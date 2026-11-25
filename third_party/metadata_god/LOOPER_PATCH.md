# Looper patch

Copy of metadata_god 1.1.0 from pub.dev, without `example/`, `test/` and `test_driver/`.

Two changes, both in `cargokit/gradle/plugin.gradle`:

- The compileSdk parse takes only the major version, because Android Gradle Plugin 9 reports `android-37.0` and the original `substring(8) as int` throws.
- `project.exec` is replaced by an injected `ExecOperations`, because Gradle 9 removed `Project.exec`.

Drop this copy once a metadata_god release builds on AGP 9. Keep the `flutter_rust_bridge: 2.11.1` pin in `pubspec.yaml` until then.
