#!/usr/bin/env bash

# ==============================================================================
# Flutter Multi-Platform Packaging & Build Suite
# ==============================================================================
# Generic packaging script for Linux (.deb, .rpm, .tar.gz, .AppImage) and
# Android (Split-per-ABI APKs, Universal APK, App Bundle .aab) builds. When the
# project defines github/play Android flavors, the APKs are built as `github`
# and the .aab as `play`.
#
# All identity metadata (app name, display name, description, maintainer,
# icon, version, ...) is auto-detected from the target Flutter project's own
# files (pubspec.yaml, AndroidManifest.xml, linux/ sources, git config) so
# this script can be dropped into any Flutter project unchanged. Every
# detected value can still be overridden with a flag or environment variable
# — see --help.
# ==============================================================================

set -euo pipefail

# --- Locate the script & default project directory ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR"

# --- Output Directories (resolved relative to PROJECT_DIR once we cd there) ---
OUTPUT_DIR="dist"
LINUX_DIST_DIR="$OUTPUT_DIR/linux"
ANDROID_DIST_DIR="$OUTPUT_DIR/android"

# --- Flags & Targets ---
TARGET="all"
BUILD_FLAG=false
CLEAN_FLAG=false

# --- Overrides (populated from CLI flags / env; empty means "auto-detect") ---
OVERRIDE_APP_NAME="${APP_NAME:-}"
OVERRIDE_DISPLAY_NAME="${DISPLAY_NAME:-}"
OVERRIDE_DESCRIPTION="${DESCRIPTION:-}"
OVERRIDE_MAINTAINER="${MAINTAINER:-}"
OVERRIDE_ICON="${ICON_SOURCE:-}"

OVERRIDE_CATEGORIES="${CATEGORIES:-}"
OVERRIDE_MIME_TYPES="${MIME_TYPES:-}"
OVERRIDE_DEB_DEPENDS="${DEB_DEPENDS:-}"

# --- Packaging settings (environment variables can override these) ---
# Icon used for the Linux packages (.deb / AppImage): a transparent-background
# mark that suits desktop docks and launchers better than a mobile launcher
# tile. --icon still overrides it, and if the file doesn't exist in the target
# project the script falls back to auto-detecting an icon.
LINUX_ICON="${LINUX_ICON:-assets/logo_linux.png}"

# Android build outputs (see package_android). ABIs produced by
# `flutter build apk --split-per-abi`; narrow them with e.g. ANDROID_ABIS="arm64-v8a".
ANDROID_ABIS="${ANDROID_ABIS:-arm64-v8a armeabi-v7a x86_64}"
BUILD_MARKER=""          # temp file whose mtime is when this run's build started
ANDROID_PUBLISHED=()     # file names copied into $ANDROID_DIST_DIR by this run
ANDROID_MISSING=()       # expected artifacts that could not be found
PACKAGING_FAILED=false   # set when an expected artifact is missing after a build

# --- Usage Helper ---
show_help() {
    cat <<EOF
Usage: ./package.sh [TARGET] [OPTIONS]

Works on any Flutter project. Metadata (app name, display name, description,
maintainer, icon, categories, MIME types) is auto-detected from the project's
own pubspec.yaml / AndroidManifest.xml / linux sources / git config, and can
be overridden with the flags below.

Targets:
  linux       Package Linux distributions (.deb, .rpm, .tar.gz, .AppImage)
  android     Package Android applications (Split APKs, Universal APK, AAB;
              github flavor for APKs and play flavor for the AAB when defined)
  all         Package all supported target platforms (Default)

Options:
  --build                 Run 'flutter build' release compilation prior to packaging
  --clean                 Run 'flutter clean' before building
  --project-dir <path>    Path to the Flutter project to package (default: this script's directory)
  --app-name <name>       Override the on-disk package/binary name (default: from pubspec.yaml)
  --display-name <name>   Override the human-readable app name (default: from AndroidManifest.xml / linux window title)
  --description <text>    Override the package description (default: from pubspec.yaml)
  --maintainer <name>     Override the maintainer string (default: from git config user.name/user.email)
  --icon <path>           Override the source icon image (default: assets/logo_linux.png, else flutter_launcher_icons image_path, or a common asset path)
  --categories <string>   Override the .desktop Categories= value
  --mime-types <string>   Override the .desktop MimeType= value
  --deb-depends <string>  Override the .deb Depends: line
  --help                  Show this help message

Environment:
  ANDROID_ABIS            Split-APK ABIs to collect (default: "arm64-v8a armeabi-v7a x86_64")
  LINUX_ICON              Icon for the Linux packages (default: assets/logo_linux.png)

Android output: artifacts are copied to dist/android/ with a SHA256SUMS-v<version>.txt.
With --build, any missing artifact fails the run (non-zero exit) instead of being skipped.

Examples:
  ./package.sh linux --build
  ./package.sh android --build
  ./package.sh all --build --clean
  ./package.sh --project-dir ~/other_flutter_app all --build
EOF
    exit 0
}

# --- Argument Parsing ---
while [[ $# -gt 0 ]]; do
    case "$1" in
        linux|android|all)
            TARGET="$1"
            shift
            ;;
        --build)
            BUILD_FLAG=true
            shift
            ;;
        --clean)
            CLEAN_FLAG=true
            shift
            ;;
        --project-dir)
            PROJECT_DIR="$(cd "$2" && pwd)"
            shift 2
            ;;
        --app-name)
            OVERRIDE_APP_NAME="$2"
            shift 2
            ;;
        --display-name)
            OVERRIDE_DISPLAY_NAME="$2"
            shift 2
            ;;
        --description)
            OVERRIDE_DESCRIPTION="$2"
            shift 2
            ;;
        --maintainer)
            OVERRIDE_MAINTAINER="$2"
            shift 2
            ;;
        --icon)
            OVERRIDE_ICON="$2"
            shift 2
            ;;
        --categories)
            OVERRIDE_CATEGORIES="$2"
            shift 2
            ;;
        --mime-types)
            OVERRIDE_MIME_TYPES="$2"
            shift 2
            ;;
        --deb-depends)
            OVERRIDE_DEB_DEPENDS="$2"
            shift 2
            ;;
        --help|-h)
            show_help
            ;;
        *)
            echo "❌ Unknown argument: $1"
            show_help
            ;;
    esac
done

cd "$PROJECT_DIR"

if [[ ! -f "pubspec.yaml" ]]; then
    echo "❌ Error: No pubspec.yaml found in $PROJECT_DIR — this doesn't look like a Flutter project."
    exit 1
fi

# ==============================================================================
# --- Project Metadata Auto-Detection ---
# Every value below is read from the project itself so the script needs no
# per-project editing. Set the matching --flag or environment variable to
# override any single value without touching the detection logic.
# ==============================================================================

detect_pubspec_field() {
    # $1 = top-level YAML key (e.g. "name", "description", "version")
    grep -m1 -E "^${1}:" pubspec.yaml 2>/dev/null \
        | sed -E "s/^${1}:[[:space:]]*//" \
        | tr -d '\r' \
        | sed -E 's/^"(.*)"$/\1/; s/^'"'"'(.*)'"'"'$/\1/'
}

detect_app_name() {
    local raw
    raw=$(detect_pubspec_field "name")
    if [[ -z "$raw" ]]; then
        raw="$(basename "$PROJECT_DIR")"
    fi
    echo "$raw" | tr '_' '-' | tr '[:upper:]' '[:lower:]'
}

detect_display_name() {
    local name=""
    local manifest="android/app/src/main/AndroidManifest.xml"
    if [[ -f "$manifest" ]]; then
        name=$(grep -o 'android:label="[^"]*"' "$manifest" | head -n1 | sed -E 's/android:label="(.*)"/\1/')
        if [[ "$name" == @string/* ]]; then
            local res_name="${name#@string/}"
            local strings_file="android/app/src/main/res/values/strings.xml"
            if [[ -f "$strings_file" ]]; then
                name=$(grep -o "name=\"$res_name\"[^>]*>[^<]*" "$strings_file" | head -n1 | sed -E 's/.*>(.*)$/\1/')
            else
                name=""
            fi
        fi
    fi
    if [[ -z "$name" && -f "linux/runner/my_application.cc" ]]; then
        name=$(grep -o 'gtk_window_set_title([^,]*, *"[^"]*")' linux/runner/my_application.cc | head -n1 | sed -E 's/.*"(.*)"\)/\1/')
    fi
    if [[ -z "$name" ]]; then
        name=$(detect_app_name | sed -E 's/[-_]+/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2); print}')
    fi
    echo "$name"
}

detect_description() {
    local desc
    desc=$(detect_pubspec_field "description")
    if [[ -z "$desc" ]]; then
        desc="A Flutter application."
    fi
    echo "$desc"
}

detect_maintainer() {
    local git_name git_email
    git_name=$(git config user.name 2>/dev/null || true)
    git_email=$(git config user.email 2>/dev/null || true)
    if [[ -n "$git_name" && -n "$git_email" ]]; then
        echo "$git_name <$git_email>"
    elif [[ -n "$git_email" ]]; then
        echo "$git_email"
    else
        echo "Unknown <unknown@example.com>"
    fi
}

detect_icon() {
    local icon candidate
    # 1. The Linux icon (LINUX_ICON, assets/logo_linux.png by default).
    if [[ -n "$LINUX_ICON" && -f "$LINUX_ICON" ]]; then
        echo "$LINUX_ICON"
        return
    fi
    # 2. flutter_launcher_icons config, if the project uses that package.
    icon=$(awk '/^flutter_launcher_icons:/{f=1;next} f && /^[a-zA-Z]/{exit} f && /image_path:/{print; exit}' pubspec.yaml \
        | sed -E 's/.*image_path:[[:space:]]*//' | tr -d '"'"'"'\r')
    if [[ -n "$icon" && -f "$icon" ]]; then
        echo "$icon"
        return
    fi
    # 3. Common conventional asset locations.
    for candidate in assets/icon.png assets/icon/icon.png assets/launcher_logo.png \
                      assets/app_icon.png assets/logo.png web/icons/Icon-512.png; do
        if [[ -f "$candidate" ]]; then
            echo "$candidate"
            return
        fi
    done
    echo ""
}

detect_deb_depends() {
    # Add libmpv when the project depends on mpv_audio_kit; otherwise a plain
    # GTK dependency is enough for a generic Flutter Linux build.
    if grep -qE '^\s*mpv_audio_kit\s*:' pubspec.yaml 2>/dev/null; then
        echo "libgtk-3-0, libmpv1 | libmpv2"
    else
        echo "libgtk-3-0"
    fi
}

# --- Resolve final metadata: CLI/env override wins, else auto-detected ---
APP_NAME="${OVERRIDE_APP_NAME:-$(detect_app_name)}"
DISPLAY_NAME="${OVERRIDE_DISPLAY_NAME:-$(detect_display_name)}"
DESCRIPTION="${OVERRIDE_DESCRIPTION:-$(detect_description)}"
MAINTAINER="${OVERRIDE_MAINTAINER:-$(detect_maintainer)}"
ICON_SOURCE="${OVERRIDE_ICON:-$(detect_icon)}"
CATEGORIES="${OVERRIDE_CATEGORIES:-AudioVideo;Audio;Music;Player;}"
MIME_TYPES="${OVERRIDE_MIME_TYPES:-audio/mpeg;audio/ogg;audio/x-wav;audio/flac;audio/mp4;audio/x-mp3;audio/x-m4a;}"
DEB_DEPENDS="${OVERRIDE_DEB_DEPENDS:-$(detect_deb_depends)}"

# --- Version Extraction from pubspec.yaml ---
RAW_VERSION=$(detect_pubspec_field "version")
VERSION=$(echo "$RAW_VERSION" | cut -d'+' -f1)
BUILD_NUM=$(echo "$RAW_VERSION" | cut -d'+' -f2)
[[ -z "$VERSION" ]] && VERSION="0.0.0"
[[ -z "$BUILD_NUM" ]] && BUILD_NUM="0"

echo "=================================================="
echo "🚀 $DISPLAY_NAME Packaging Suite v$VERSION (Build $BUILD_NUM)"
echo "🎯 Selected Target: $TARGET"
echo "📁 Project Directory: $PROJECT_DIR"
echo "--------------------------------------------------"
echo "🏷️  App Name (package/binary): $APP_NAME"
echo "🖼️  Display Name:              $DISPLAY_NAME"
echo "📝 Description:                $DESCRIPTION"
echo "👤 Maintainer:                 $MAINTAINER"
echo "🎨 Icon Source:                ${ICON_SOURCE:-<none found — icons will be skipped>}"
echo "=================================================="

# --- Pre-flight Checks ---
if ! command -v flutter &> /dev/null; then
    echo "❌ Error: 'flutter' command not found in PATH."
    exit 1
fi

if [[ "$CLEAN_FLAG" == true ]]; then
    echo "🧹 Cleaning Flutter build cache..."
    flutter clean
    flutter pub get
fi

# --- Linux Packaging Function ---
package_linux() {
    echo ""
    echo "--------------------------------------------------"
    echo "🐧 Packaging Linux Target..."
    echo "--------------------------------------------------"

    if [[ ! -d "linux" ]]; then
        echo "⚠️  No 'linux/' platform directory found in this project. Skipping Linux packaging."
        return
    fi

    local build_dir="build/linux/x64/release/bundle"

    if [[ "$BUILD_FLAG" == true || ! -d "$build_dir" ]]; then
        echo "🔨 Building Linux Release Bundle..."
        flutter build linux --release
    fi

    if [[ ! -d "$build_dir" ]]; then
        echo "❌ Error: Linux build directory not found at $build_dir"
        exit 1
    fi

    # Detect executable automatically
    local executable_name
    executable_name=$(find "$build_dir" -maxdepth 1 -type f -executable -not -name "*.so" | head -n 1)
    if [[ -z "$executable_name" ]]; then
        echo "❌ Error: No executable found in $build_dir"
        exit 1
    fi
    executable_name=$(basename "$executable_name")
    echo "🎯 Detected Linux executable: $executable_name"

    mkdir -p "$LINUX_DIST_DIR"
    local deb_root="$OUTPUT_DIR/deb_root_local"
    rm -rf "$deb_root"
    mkdir -p "$deb_root/DEBIAN"
    mkdir -p "$deb_root/usr/bin"
    mkdir -p "$deb_root/usr/lib/$APP_NAME"
    mkdir -p "$deb_root/usr/share/applications"
    mkdir -p "$deb_root/usr/share/icons/hicolor/256x256/apps"

    # Copy files
    cp -r "$build_dir/"* "$deb_root/usr/lib/$APP_NAME/"

    if [[ -n "$ICON_SOURCE" && -f "$ICON_SOURCE" ]]; then
        cp "$ICON_SOURCE" "$deb_root/usr/share/icons/hicolor/256x256/apps/$APP_NAME.png"
    fi

    # Create Debian Control File
    cat <<EOF > "$deb_root/DEBIAN/control"
Package: $APP_NAME
Version: $VERSION
Section: sound
Priority: optional
Architecture: amd64
Maintainer: $MAINTAINER
Description: $DESCRIPTION
Depends: $DEB_DEPENDS
EOF

    # Create Launcher Script
    cat <<EOF > "$deb_root/usr/bin/$APP_NAME"
#!/bin/bash
export GDK_BACKEND=wayland,x11
exec /usr/lib/$APP_NAME/$executable_name "\$@"
EOF
    chmod +x "$deb_root/usr/bin/$APP_NAME"

    # Create Desktop Entry
    cat <<EOF > "$deb_root/usr/share/applications/$APP_NAME.desktop"
[Desktop Entry]
Version=1.0
Type=Application
Name=$DISPLAY_NAME
Comment=$DESCRIPTION
Exec=$APP_NAME %F
Icon=$APP_NAME
Terminal=false
StartupNotify=true
Categories=$CATEGORIES
MimeType=$MIME_TYPES
EOF

    # Fix permissions
    find "$deb_root/usr" -type d -exec chmod 755 {} +
    find "$deb_root/usr" -type f -exec chmod 644 {} +
    chmod +x "$deb_root/usr/bin/$APP_NAME"
    chmod +x "$deb_root/usr/lib/$APP_NAME/$executable_name"

    # 1. Debian Package (.deb)
    echo "📦 Building .deb package..."
    local deb_file="$LINUX_DIST_DIR/${APP_NAME}_${VERSION}_amd64.deb"
    dpkg-deb --build "$deb_root" "$deb_file"
    echo "✅ .deb package: $deb_file"

    # 2. RPM Package (.rpm)
    if command -v alien &> /dev/null && command -v fakeroot &> /dev/null; then
        echo "📦 Building .rpm package via alien..."
        fakeroot alien --to-rpm --keep-version "$deb_file"
        local gen_rpm
        gen_rpm=$(find . -maxdepth 1 -name "${APP_NAME}-*.rpm" | head -n 1)
        if [[ -n "$gen_rpm" && -f "$gen_rpm" ]]; then
            mv "$gen_rpm" "$LINUX_DIST_DIR/"
            echo "✅ .rpm package: $LINUX_DIST_DIR/$(basename "$gen_rpm")"
        fi
    else
        echo "⚠️  Skipping RPM generation (alien or fakeroot not installed)."
    fi

    # 3. Portable Tarball (.tar.gz)
    echo "📦 Building portable .tar.gz archive..."
    local tar_file="$LINUX_DIST_DIR/${APP_NAME}_${VERSION}_linux_x64.tar.gz"
    local tar_stage="$OUTPUT_DIR/${APP_NAME}_${VERSION}_linux_x64"
    rm -rf "$tar_stage"
    mkdir -p "$tar_stage"
    cp -r "$build_dir/"* "$tar_stage/"
    tar -czf "$tar_file" -C "$OUTPUT_DIR" "$(basename "$tar_stage")"
    rm -rf "$tar_stage"
    echo "✅ Tarball archive: $tar_file"

    # 4. AppImage (.AppImage)
    local appdir="$OUTPUT_DIR/AppDir"
    rm -rf "$appdir"
    mkdir -p "$appdir/usr/bin"
    mkdir -p "$appdir/usr/lib"
    mkdir -p "$appdir/usr/share/metainfo"
    cp -r "$build_dir/"* "$appdir/usr/bin/"

    if [[ -n "$ICON_SOURCE" && -f "$ICON_SOURCE" ]]; then
        cp "$ICON_SOURCE" "$appdir/$APP_NAME.png"
        mkdir -p "$appdir/usr/share/icons/hicolor/256x256/apps"
        cp "$ICON_SOURCE" "$appdir/usr/share/icons/hicolor/256x256/apps/$APP_NAME.png"
        ln -sf "$APP_NAME.png" "$appdir/.DirIcon"
    fi

    cat <<EOF > "$appdir/$APP_NAME.desktop"
[Desktop Entry]
Version=1.0
Type=Application
Name=$DISPLAY_NAME
Comment=$DESCRIPTION
Exec=$APP_NAME %F
Icon=$APP_NAME
Terminal=false
StartupNotify=true
Categories=$CATEGORIES
MimeType=$MIME_TYPES
EOF

    cat <<EOF > "$appdir/AppRun"
#!/bin/bash
SELF=\$(readlink -f "\$0")
HERE=\${SELF%/*}
export GDK_BACKEND=wayland,x11
export LD_LIBRARY_PATH="\$HERE/usr/bin:\$HERE/usr/bin/lib:\$LD_LIBRARY_PATH"
exec "\$HERE/usr/bin/$executable_name" "\$@"
EOF
    chmod +x "$appdir/AppRun"

    find "$appdir" -type d -exec chmod 755 {} +
    find "$appdir" -type f -exec chmod 644 {} +
    chmod +x "$appdir/AppRun"
    chmod +x "$appdir/usr/bin/$executable_name"

    local appimage_tool=""
    for candidate in "$(command -v appimagetool 2>/dev/null || true)" "$HOME/.local/bin/appimagetool" "./appimagetool"; do
        if [[ -n "$candidate" && -x "$candidate" ]]; then
            appimage_tool="$candidate"
            break
        fi
    done

    if [[ -n "$appimage_tool" ]]; then
        echo "📦 Building .AppImage bundle..."
        export ARCH=x86_64
        "$appimage_tool" "$appdir" "$LINUX_DIST_DIR/${APP_NAME}_${VERSION}_x86_64.AppImage"
        echo "✅ AppImage bundle: $LINUX_DIST_DIR/${APP_NAME}_${VERSION}_x86_64.AppImage"
    else
        echo "⚠️  Skipping AppImage generation (appimagetool not found in PATH or ~/.local/bin)."
    fi

    rm -rf "$appdir"
    rm -rf "$deb_root"
}

# --- Android Packaging Function ---
# Copies the first existing candidate into $ANDROID_DIST_DIR as <dest_name>,
# verifies the copy, and records the outcome in ANDROID_PUBLISHED / ANDROID_MISSING.
#   usage: publish_android_artifact <label> <dest_name> <candidate-path>...
#
# Several candidates are tried on purpose. Flutter's Gradle plugin writes split
# APKs as app-<abi>-<flavor>-<mode>.apk, while flutter_tools' own lookup list
# uses app-<flavor>-<abi>-<mode>.apk - so never hardcode a single order (an
# earlier version of this script did, and silently skipped every split APK).
publish_android_artifact() {
    local label="$1" dest_name="$2"
    shift 2

    local src="" candidate
    for candidate in "$@"; do
        if [[ -f "$candidate" ]]; then
            src="$candidate"
            break
        fi
    done

    if [[ -z "$src" ]]; then
        ANDROID_MISSING+=("$label")
        echo "  ❌ $label — not found. Looked for:"
        printf '       %s\n' "$@"
        return 0
    fi

    local dest="$ANDROID_DIST_DIR/$dest_name"
    cp -f "$src" "$dest"
    if ! cmp -s "$src" "$dest"; then
        ANDROID_MISSING+=("$label (copy did not match source)")
        echo "  ❌ $label — copy to $dest did not match $src"
        return 0
    fi

    local size built note=""
    size="$(du -h "$dest" | cut -f1)"
    built="$(date -r "$src" '+%Y-%m-%d %H:%M')"
    # Gradle skips repackaging when nothing changed, leaving the previous
    # (identical) file in place - fine to ship, but say so instead of hiding it.
    if [[ -n "$BUILD_MARKER" && ! "$src" -nt "$BUILD_MARKER" ]]; then
        note="  ⚠️ predates this run (Gradle reused an up-to-date build)"
    fi
    echo "  ✅ $label → $dest ($size, built $built)$note"
    ANDROID_PUBLISHED+=("$dest_name")
}

package_android() {
    echo ""
    echo "--------------------------------------------------"
    echo "🤖 Packaging Android Target..."
    echo "--------------------------------------------------"

    if [[ ! -d "android" ]]; then
        echo "⚠️  No 'android/' platform directory found in this project. Skipping Android packaging."
        return
    fi

    mkdir -p "$ANDROID_DIST_DIR"

    # Pick up compile-time secrets (API keys, feature flags, ...) from a
    # gitignored env.json at the project root, if the project uses one (see
    # docs/ADS_ANALYTICS_SETUP.md for this project's case). Without this,
    # String.fromEnvironment()/bool.fromEnvironment() calls in Dart silently
    # compile to their default values instead of erroring, so a build that
    # forgets this flag looks fine but ships with those features inert.
    local dart_define_flag=""
    if [[ -f "env.json" ]]; then
        dart_define_flag="--dart-define-from-file=env.json"
        echo "🔑 Found env.json — compiling with $dart_define_flag"
    fi

    # This app defines `github` and `play` product flavors (see
    # android/app/build.gradle.kts): the APKs are the GitHub-release
    # distribution (checks GitHub for updates, no Google Play code) and the AAB
    # is the Google Play one (Play In-App Updates). Only use them when the
    # target project actually defines both, so this script still works
    # unchanged on a project without flavors.
    local apk_flavor="" aab_flavor=""
    if grep -qsE '(create\("|^\s*)github("\)|\s*\{)' android/app/build.gradle* &&
       grep -qsE '(create\("|^\s*)play("\)|\s*\{)' android/app/build.gradle*; then
        apk_flavor="github"
        aab_flavor="play"
        echo "🏷️  Found github/play flavors — APKs use 'github', the AAB uses 'play'"
    fi
    local apk_flavor_flag="${apk_flavor:+--flavor $apk_flavor}"
    local aab_flavor_flag="${aab_flavor:+--flavor $aab_flavor}"

    if [[ "$BUILD_FLAG" == true ]]; then
        # Anything not newer than this marker wasn't (re)written by this build.
        BUILD_MARKER="$(mktemp)"

        echo "🔨 Building Android Split APKs..."
        flutter build apk --release $apk_flavor_flag --split-per-abi $dart_define_flag

        echo "🔨 Building Android Universal APK..."
        flutter build apk --release $apk_flavor_flag $dart_define_flag

        echo "🔨 Building Android App Bundle (AAB)..."
        flutter build appbundle --release $aab_flavor_flag $dart_define_flag
    fi

    local apk_dir="build/app/outputs/flutter-apk"
    local bundle_dir="build/app/outputs/bundle"
    local apk_flavor_part="${apk_flavor:+-$apk_flavor}"
    local aab_flavor_part="${aab_flavor:+-$aab_flavor}"
    local aab_variant_dir="release"
    [[ -n "$aab_flavor" ]] && aab_variant_dir="${aab_flavor}Release"

    echo "📦 Collecting Android artifacts into $ANDROID_DIST_DIR..."

    # 1. ABI split APKs
    local abi
    for abi in $ANDROID_ABIS; do
        publish_android_artifact "APK ($abi)" "${APP_NAME}-v${VERSION}-${abi}-release.apk" \
            "$apk_dir/app-${abi}${apk_flavor_part}-release.apk" \
            "$apk_dir/app${apk_flavor_part}-${abi}-release.apk"
    done

    # 2. Universal APK
    publish_android_artifact "Universal APK" "${APP_NAME}-v${VERSION}-universal-release.apk" \
        "$apk_dir/app${apk_flavor_part}-release.apk"

    # 3. App Bundle (.aab)
    publish_android_artifact "App Bundle (AAB)" "${APP_NAME}-v${VERSION}-release.aab" \
        "$bundle_dir/$aab_variant_dir/app${aab_flavor_part}-release.aab"

    [[ -n "$BUILD_MARKER" ]] && rm -f "$BUILD_MARKER"
    BUILD_MARKER=""

    # Checksums for what this run published, in `sha256sum -c` format.
    if (( ${#ANDROID_PUBLISHED[@]} > 0 )); then
        local sums_file="SHA256SUMS-v${VERSION}.txt"
        (cd "$ANDROID_DIST_DIR" && sha256sum "${ANDROID_PUBLISHED[@]}" > "$sums_file")
        echo "  🔐 Checksums: $ANDROID_DIST_DIR/$sums_file"
    fi

    if (( ${#ANDROID_MISSING[@]} > 0 )); then
        echo ""
        echo "  Present in $apk_dir:"
        ls -1 "$apk_dir" 2>/dev/null | sed 's/^/       /' || true
        if [[ "$BUILD_FLAG" == true ]]; then
            # A build just ran, so a missing artifact is a real failure - don't
            # let the closing banner claim success.
            PACKAGING_FAILED=true
            echo "❌ ${#ANDROID_MISSING[@]} expected Android artifact(s) missing after the build: ${ANDROID_MISSING[*]}"
        else
            echo "⚠️  ${#ANDROID_MISSING[@]} artifact(s) not found. Nothing was built by this run — pass --build to compile them."
        fi
    fi
}

# --- Execution Flow ---
case "$TARGET" in
    linux)
        package_linux
        ;;
    android)
        package_android
        ;;
    all)
        package_linux
        package_android
        ;;
esac

# --- Summary & Dashboard ---
echo ""
echo "=================================================="
if [[ "$PACKAGING_FAILED" == true ]]; then
    echo "❌ Packaging finished with errors — see above"
else
    echo "🎉 Build & Packaging Completed Successfully!"
fi
echo "=================================================="
echo "📂 Package Distribution Files:"

if [[ -d "$LINUX_DIST_DIR" ]]; then
    echo ""
    echo "🐧 Linux Packages ($LINUX_DIST_DIR):"
    ls -lh "$LINUX_DIST_DIR" 2>/dev/null || echo "   (No Linux packages found)"
fi

if [[ -d "$ANDROID_DIST_DIR" ]]; then
    echo ""
    echo "🤖 Android Packages ($ANDROID_DIST_DIR):"
    ls -lh "$ANDROID_DIST_DIR" 2>/dev/null || echo "   (No Android packages found)"
fi
echo "=================================================="

if [[ "$PACKAGING_FAILED" == true ]]; then
    exit 1
fi
