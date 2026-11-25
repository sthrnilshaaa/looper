group = "com.alesdrnz.mpv_audio_kit"
version = "0.8.0"

// AGP and the Kotlin Gradle Plugin are supplied by the consuming app's build
// (and by flutter_tools), so this module declares no buildscript classpath of
// its own — pinning them here would force versions onto the app and, on AGP 9,
// would clash with Built-in Kotlin by holding KGP below the required 2.2.10.
plugins {
    id("com.android.library")
}

// ── Built-in Kotlin migration ───────────────────────────────────────────────
// Flutter 3.44+/AGP 9 provide Kotlin out of the box, and applying the Kotlin
// Gradle Plugin (KGP) ourselves there breaks the build. On AGP < 9 (current
// Flutter) KGP is still required, so apply it conditionally on the AGP major
// version. See: https://docs.flutter.dev/release/breaking-changes/migrate-to-built-in-kotlin/for-plugin-authors
val agpMajor = com.android.Version.ANDROID_GRADLE_PLUGIN_VERSION.substringBefore('.').toInt()
if (agpMajor < 9) {
    apply(plugin = "org.jetbrains.kotlin.android")
}

android {
    namespace = "com.alesdrnz.mpv_audio_kit"

    compileSdk = 36

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    sourceSets {
        getByName("main") {
            java.srcDirs("src/main/kotlin")
        }
        getByName("test") {
            java.srcDirs("src/test/kotlin")
        }
    }

    defaultConfig {
        minSdk = 24

        // libmpv is not packaged by this module: the package's build hook
        // (hook/build.dart) provides libmpv_audio_kit.so for each ABI the app
        // builds, and Flutter puts it in the APK.
    }

    testOptions {
        unitTests {
            isIncludeAndroidResources = true
            all {
                it.useJUnitPlatform()

                it.outputs.upToDateWhen { false }

                it.testLogging {
                    events("passed", "skipped", "failed", "standardOut", "standardError")
                    showStandardStreams = true
                }
            }
        }
    }
}

// Replaces the deprecated `android.kotlinOptions {}` DSL; works identically
// whether KGP is applied by us (AGP < 9) or built in (AGP 9+).
project.extensions.configure(org.jetbrains.kotlin.gradle.dsl.KotlinAndroidProjectExtension::class.java) {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    // Media3 drives the OS media session (now-playing notification,
    // lock-screen / Android-11+ media controls, hardware & Bluetooth
    // media keys). The custom SimpleBasePlayer adapter is a controller
    // only — libmpv decodes in-process; Media3 never touches audio.
    val media3Version = "1.11.1"
    implementation("androidx.media3:media3-session:$media3Version")
    implementation("androidx.media3:media3-common:$media3Version")

    testImplementation("org.jetbrains.kotlin:kotlin-test")
    testImplementation("org.mockito:mockito-core:5.24.0")
    // JUnit Jupiter engine for the `useJUnitPlatform()` runner above.
    testImplementation("org.junit.jupiter:junit-jupiter:6.1.3")
    // Gradle 9 no longer brings its own JUnit Platform launcher: the test
    // run needs it on its classpath, at the platform version of Jupiter.
    testRuntimeOnly("org.junit.platform:junit-platform-launcher:6.1.3")
}
