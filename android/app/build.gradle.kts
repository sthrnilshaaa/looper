import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.looper.player"
    compileSdk = 37
    ndkVersion = "28.2.13676358"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlin {
        jvmToolchain(17)
    }

    val keystorePropertiesFile = rootProject.file("key.properties")
    val keystoreProperties = Properties()
    var hasSigningConfig = false

    if (keystorePropertiesFile.exists()) {
        keystoreProperties.load(FileInputStream(keystorePropertiesFile))
        hasSigningConfig = true
    }

    signingConfigs {
        if (hasSigningConfig) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = rootProject.file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    defaultConfig {
        applicationId = "com.looper.player"
        minSdk = 29
        targetSdk = 37
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    // Two distributions of the same app (same applicationId), differing only
    // in how updates are delivered:
    //   github - APKs attached to GitHub releases; checks the GitHub releases
    //            API. Contains no Google Play code at all.
    //   play   - the Google Play AAB; uses Play's In-App Updates API and never
    //            talks to GitHub.
    // Build with `--flavor github` / `--flavor play` (there is deliberately no
    // pubspec default-flavor: it would also relocate the Linux build output).
    flavorDimensions += "store"
    productFlavors {
        create("github") { dimension = "store" }
        create("play") { dimension = "store" }
    }

    buildTypes {
        val sharedSigningConfig = if (hasSigningConfig) {
            signingConfigs.getByName("release")
        } else {
            signingConfigs.getByName("debug")
        }

        getByName("release") {
            signingConfig = sharedSigningConfig
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }

        getByName("debug") {
            signingConfig = sharedSigningConfig
        }
    }

    packaging {
        jniLibs {
            pickFirsts.add("**/libc++_shared.so")
            pickFirsts.add("**/libmpv.so")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    val media3Version = "1.10.1"
    implementation("androidx.media3:media3-session:$media3Version")
    implementation("androidx.media3:media3-common:$media3Version")
    implementation("androidx.media:media:1.7.0")
    // Reads embedded lyrics tags (ID3 USLT, Vorbis Comment LYRICS/UNSYNCEDLYRICS,
    // MP4 ©lyr) across mp3/flac/ogg/m4a/wav/wma - metadata_god doesn't expose a
    // lyrics field, and hand-rolling binary tag parsing for untrusted files
    // isn't worth the risk when a mature library already does it correctly.
    implementation("net.jthink:jaudiotagger:3.0.1")
    // In-App Updates - play flavor only, so the GitHub APK ships no Google code.
    "playImplementation"("com.google.android.play:app-update:2.1.0")
}