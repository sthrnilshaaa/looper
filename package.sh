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
WINDOWS_DIST_DIR="$OUTPUT_DIR/windows"

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
LINUX_ICON="${LINUX_ICON:-assets/branding/linux_icon.png}"

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
  windows     Package Windows (portable .zip + Inno Setup installer .exe).
              Windows only: run it in Git Bash; elsewhere it is skipped.
  all         Package all supported target platforms (Default)

Options:
  --build                 Run 'flutter build' release compilation prior to packaging
  --clean                 Run 'flutter clean' before building
  --project-dir <path>    Path to the Flutter project to package (default: this script's directory)
  --app-name <name>       Override the on-disk package/binary name (default: from pubspec.yaml)
  --display-name <name>   Override the human-readable app name (default: from AndroidManifest.xml / linux window title)
  --description <text>    Override the package description (default: from pubspec.yaml)
  --maintainer <name>     Override the maintainer string (default: from git config user.name/user.email)
  --icon <path>           Override the source icon image (default: assets/branding/linux_icon.png, else flutter_launcher_icons image_path, or a common asset path)
  --categories <string>   Override the .desktop Categories= value
  --mime-types <string>   Override the .desktop MimeType= value
  --deb-depends <string>  Override the .deb Depends: line
  --help                  Show this help message

Environment:
  ANDROID_ABIS            Split-APK ABIs to collect (default: "arm64-v8a armeabi-v7a x86_64")
  LINUX_ICON              Icon for the Linux packages (default: assets/branding/linux_icon.png)
  RPM_LICENSE             License: tag for the .rpm (default: guessed from the LICENSE file)

Android output: artifacts are copied to dist/android/ with a SHA256SUMS-v<version>.txt.
With --build, any missing artifact fails the run (non-zero exit) instead of being skipped.

Examples:
  ./package.sh linux --build
  ./package.sh android --build
  ./package.sh windows --build   # in Git Bash on Windows
  ./package.sh all --build --clean
  ./package.sh --project-dir ~/other_flutter_app all --build
EOF
    exit 0
}

# --- Argument Parsing ---
while [[ $# -gt 0 ]]; do
    case "$1" in
        linux|android|windows|all)
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
    # 1. The Linux icon (LINUX_ICON, assets/branding/linux_icon.png by default).
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
    for candidate in assets/icon.png assets/icon/icon.png assets/branding/launcher_icon.png \
                      assets/app_icon.png assets/logo.png web/icons/Icon-512.png; do
        if [[ -f "$candidate" ]]; then
            echo "$candidate"
            return
        fi
    done
    echo ""
}

detect_license() {
    # SPDX-ish identifier for the .rpm License: tag, guessed from the license file.
    local file
    for file in LICENSE LICENSE.md LICENSE.txt COPYING; do
        [[ -f "$file" ]] || continue
        if grep -qi "GNU AFFERO GENERAL PUBLIC LICENSE" "$file"; then echo "AGPL-3.0-or-later"; return; fi
        if grep -qi "GNU LESSER GENERAL PUBLIC LICENSE" "$file"; then echo "LGPL-3.0-or-later"; return; fi
        if grep -qi "GNU GENERAL PUBLIC LICENSE" "$file"; then
            if grep -qiE "Version 2,? " "$file"; then echo "GPL-2.0-or-later"; else echo "GPL-3.0-or-later"; fi
            return
        fi
        if grep -qi "Apache License" "$file"; then echo "Apache-2.0"; return; fi
        if grep -qi "MIT License" "$file"; then echo "MIT"; return; fi
        if grep -qi "Mozilla Public License" "$file"; then echo "MPL-2.0"; return; fi
    done
    echo "Unknown"
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
RPM_LICENSE="${RPM_LICENSE:-$(detect_license)}"
LINUX_APP_ID=""          # GTK application id, resolved in package_linux

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
# Installed layout shared by the .deb and .rpm (and mirrored under ~/.local by
# the tarball's install.sh):
#   /usr/lib/<app>/                       the Flutter bundle (binary, lib/, data/)
#   /usr/bin/<app>                        launcher script
#   /usr/share/applications/<id>.desktop  named after the GTK application id so
#                                         Wayland shells match the window to it
#   /usr/share/icons/hicolor/<N>x<N>/apps/<app>.png

# Writes the .desktop entry to $1 with Exec= set to $2.
write_desktop_entry() {
    cat <<EOF > "$1"
[Desktop Entry]
Version=1.0
Type=Application
Name=$DISPLAY_NAME
Comment=$DESCRIPTION
Exec=$2 %F
Icon=$APP_NAME
Terminal=false
StartupNotify=true
StartupWMClass=$LINUX_APP_ID
Categories=$CATEGORIES
MimeType=$MIME_TYPES
EOF
}

# Installs the icon into the hicolor theme under $1 (a .../share/icons/hicolor
# directory), one file per standard size when ImageMagick is available.
install_hicolor_icons() {
    local hicolor="$1" size src_size resizer=""
    [[ -n "$ICON_SOURCE" && -f "$ICON_SOURCE" ]] || return 0
    if command -v magick &> /dev/null; then
        resizer="magick"
    elif command -v convert &> /dev/null; then
        resizer="convert"
    fi
    if [[ -n "$resizer" ]]; then
        for size in 48 64 128 256 512; do
            mkdir -p "$hicolor/${size}x${size}/apps"
            "$resizer" "$ICON_SOURCE" -resize "${size}x${size}" "$hicolor/${size}x${size}/apps/$APP_NAME.png"
        done
    else
        # No resizer: file it under its real size so the theme isn't lied to.
        src_size=$(file "$ICON_SOURCE" | grep -oE '[0-9]+ x [0-9]+' | head -n1 | cut -d' ' -f1)
        [[ -z "$src_size" ]] && src_size=256
        mkdir -p "$hicolor/${src_size}x${src_size}/apps"
        cp "$ICON_SOURCE" "$hicolor/${src_size}x${src_size}/apps/$APP_NAME.png"
    fi
}

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

    # The GTK application id (what the window reports to the desktop shell).
    LINUX_APP_ID=$(grep -m1 -oE 'set\(APPLICATION_ID "[^"]+"' linux/CMakeLists.txt 2>/dev/null | sed -E 's/.*"(.*)"/\1/' || true)
    [[ -z "$LINUX_APP_ID" ]] && LINUX_APP_ID="$APP_NAME"

    # Newest glibc the binaries were linked against: they cannot start on
    # anything older, so the packages declare it instead of failing at launch.
    local glibc_min
    glibc_min=$(find "$build_dir" -maxdepth 2 -type f \( -name "*.so*" -o -name "$executable_name" \) \
        -exec objdump -T {} + 2>/dev/null | grep -oE 'GLIBC_[0-9]+\.[0-9]+' | sed 's/GLIBC_//' | sort -uV | tail -n1 || true)
    echo "🧬 Needs glibc >= ${glibc_min:-unknown} (set by the machine this was built on)"

    # Apps that shell out to ffprobe/ffmpeg (this one reads tags with ffprobe
    # on Linux) need it installed. The .rpm requires the file rather than a
    # package so Fedora's ffmpeg-free and RPM Fusion's ffmpeg both satisfy it.
    local NEEDS_FFMPEG=""
    local rpm_requires=""
    if grep -rqsE "'ffprobe'|\"ffprobe\"" lib 2>/dev/null; then
        NEEDS_FFMPEG=1
        rpm_requires="Requires:       /usr/bin/ffprobe"
        echo "🎞️  App runs ffprobe — packages depend on ffmpeg"
    fi

    # mpv_audio_kit ships its own libmpv in the bundle; only depend on the
    # distro's when it doesn't.
    local deb_depends="$DEB_DEPENDS"
    if [[ -z "$OVERRIDE_DEB_DEPENDS" ]]; then
        if compgen -G "$build_dir/lib/libmpv.so*" > /dev/null; then
            deb_depends="libgtk-3-0, libasound2, libpulse0, libpipewire-0.3-0"
        fi
        [[ -n "$glibc_min" ]] && deb_depends="libc6 (>= $glibc_min), $deb_depends"
        [[ -n "$NEEDS_FFMPEG" ]] && deb_depends="$deb_depends, ffmpeg"
    fi

    mkdir -p "$LINUX_DIST_DIR"

    # --- Stage the installed tree once; the .deb and .rpm are both made from it ---
    local stage="$OUTPUT_DIR/linux_stage"
    rm -rf "$stage"
    mkdir -p "$stage/usr/bin" "$stage/usr/lib/$APP_NAME" "$stage/usr/share/applications"

    cp -r "$build_dir/"* "$stage/usr/lib/$APP_NAME/"
    # The bundle carries a stray share/ (desktop file + icon from CMake's
    # install step) that is meaningless under /usr/lib.
    rm -rf "$stage/usr/lib/$APP_NAME/share"

    cat <<EOF > "$stage/usr/bin/$APP_NAME"
#!/bin/sh
export GDK_BACKEND=wayland,x11
exec /usr/lib/$APP_NAME/$executable_name "\$@"
EOF

    write_desktop_entry "$stage/usr/share/applications/$LINUX_APP_ID.desktop" "$APP_NAME"
    install_hicolor_icons "$stage/usr/share/icons/hicolor"

    find "$stage" -type d -exec chmod 755 {} +
    find "$stage" -type f -exec chmod 644 {} +
    chmod 755 "$stage/usr/bin/$APP_NAME" "$stage/usr/lib/$APP_NAME/$executable_name"

    if command -v desktop-file-validate &> /dev/null; then
        desktop-file-validate "$stage/usr/share/applications/$LINUX_APP_ID.desktop" \
            || echo "⚠️  desktop-file-validate reported problems (see above)."
    fi

    # 1. Debian Package (.deb)
    if command -v dpkg-deb &> /dev/null; then
        echo "📦 Building .deb package..."
        local deb_root="$OUTPUT_DIR/deb_root_local"
        rm -rf "$deb_root"
        cp -a "$stage" "$deb_root"
        mkdir -p "$deb_root/DEBIAN"
        chmod 755 "$deb_root/DEBIAN"
        cat <<EOF > "$deb_root/DEBIAN/control"
Package: $APP_NAME
Version: $VERSION
Section: sound
Priority: optional
Architecture: amd64
Maintainer: $MAINTAINER
Installed-Size: $(du -sk "$stage/usr" | cut -f1)
Depends: $deb_depends
Description: $DESCRIPTION
EOF
        local deb_file="$LINUX_DIST_DIR/${APP_NAME}_${VERSION}_amd64.deb"
        # --root-owner-group: files belong to root in the package, not to
        # whoever happened to build it.
        dpkg-deb --root-owner-group --build "$deb_root" "$deb_file"
        rm -rf "$deb_root"
        echo "✅ .deb package: $deb_file"
    else
        echo "⚠️  Skipping .deb generation (dpkg-deb not installed)."
    fi

    # 2. RPM Package (.rpm)
    # Built natively with rpmbuild. (Converting the .deb with alien produced a
    # package that owned /usr, /usr/bin and /usr/lib - which rpm refuses to
    # install because the 'filesystem' package owns them - and that required
    # the bundle's own private libraries from the system.)
    if command -v rpmbuild &> /dev/null; then
        echo "📦 Building .rpm package..."
        local rpm_top stage_abs private_libs
        rpm_top="$(pwd)/$OUTPUT_DIR/rpmbuild"
        stage_abs="$(pwd)/$stage"
        rm -rf "$rpm_top"
        mkdir -p "$rpm_top/SPECS" "$rpm_top/RPMS"

        # Libraries inside the bundle must be neither required from nor
        # provided to the system. libjvm.so is wanted only by the Android-side
        # JNI helper that Flutter bundles regardless; nothing loads it on Linux.
        private_libs=$(find "$build_dir/lib" -maxdepth 1 -name "*.so*" -printf '%f\n' \
            | sed -E 's/\.so.*$//; s/[.+]/\\\\&/g' | sort -u | paste -sd'|')
        private_libs="${private_libs:+$private_libs|}libjvm"

        cat <<EOF > "$rpm_top/SPECS/$APP_NAME.spec"
%global debug_package %{nil}
%global _build_id_links none
%global __os_install_post %{nil}
%global __requires_exclude ^($private_libs)\\\\.so.*\$
%global __provides_exclude_from ^/usr/lib/$APP_NAME/.*\$

Name:           $APP_NAME
Version:        $VERSION
Release:        1
Summary:        $DISPLAY_NAME
License:        $RPM_LICENSE
BuildArch:      x86_64
$rpm_requires

%description
$DESCRIPTION

%install
mkdir -p %{buildroot}
cp -a "$stage_abs/." %{buildroot}/

%files
%attr(755, root, root) /usr/bin/$APP_NAME
%defattr(-, root, root, -)
/usr/lib/$APP_NAME
/usr/share/applications/$LINUX_APP_ID.desktop
/usr/share/icons/hicolor/*/apps/$APP_NAME.png
EOF
        if rpmbuild -bb --quiet \
                --define "_topdir $rpm_top" \
                --define "_rpmdir $rpm_top/RPMS" \
                "$rpm_top/SPECS/$APP_NAME.spec"; then
            local gen_rpm
            gen_rpm=$(find "$rpm_top/RPMS" -name "*.rpm" | head -n 1)
            if [[ -n "$gen_rpm" ]]; then
                mv "$gen_rpm" "$LINUX_DIST_DIR/"
                echo "✅ .rpm package: $LINUX_DIST_DIR/$(basename "$gen_rpm")"
            fi
        else
            PACKAGING_FAILED=true
            echo "❌ rpmbuild failed — see above."
        fi
        rm -rf "$rpm_top"
    else
        echo "⚠️  Skipping RPM generation (rpmbuild not installed — 'dnf install rpm-build' or 'apt install rpm')."
    fi

    # 3. Portable Tarball (.tar.gz)
    # Runs in place (./$executable_name) and carries install.sh / uninstall.sh
    # to add a menu entry and icon without root.
    echo "📦 Building portable .tar.gz archive..."
    local tar_file="$LINUX_DIST_DIR/${APP_NAME}_${VERSION}_linux_x64.tar.gz"
    local tar_stage="$OUTPUT_DIR/${APP_NAME}_${VERSION}_linux_x64"
    rm -rf "$tar_stage"
    mkdir -p "$tar_stage"
    cp -r "$stage/usr/lib/$APP_NAME/." "$tar_stage/"
    mkdir -p "$tar_stage/share/applications"
    cp "$stage/usr/share/applications/$LINUX_APP_ID.desktop" "$tar_stage/share/applications/"
    [[ -d "$stage/usr/share/icons" ]] && cp -r "$stage/usr/share/icons" "$tar_stage/share/"

    cat <<EOF > "$tar_stage/install.sh"
#!/bin/sh
# Installs $DISPLAY_NAME for the current user (or system-wide when run as root).
#   PREFIX=/some/dir ./install.sh   to choose another location
set -e
HERE=\$(cd "\$(dirname "\$0")" && pwd)
if [ -z "\$PREFIX" ]; then
    if [ "\$(id -u)" = 0 ]; then PREFIX=/usr/local; else PREFIX="\$HOME/.local"; fi
fi
APP_DIR="\$PREFIX/lib/$APP_NAME"

rm -rf "\$APP_DIR"
mkdir -p "\$APP_DIR" "\$PREFIX/bin" "\$PREFIX/share/applications"
cp -r "\$HERE/$executable_name" "\$HERE/lib" "\$HERE/data" "\$APP_DIR/"

cat > "\$PREFIX/bin/$APP_NAME" <<LAUNCHER
#!/bin/sh
export GDK_BACKEND=wayland,x11
exec "\$APP_DIR/$executable_name" "\\\$@"
LAUNCHER
chmod 755 "\$PREFIX/bin/$APP_NAME"

# Absolute Exec=: \$PREFIX/bin is often not on the desktop session's PATH.
sed "s|^Exec=.*|Exec=\$PREFIX/bin/$APP_NAME %F|" \\
    "\$HERE/share/applications/$LINUX_APP_ID.desktop" > "\$PREFIX/share/applications/$LINUX_APP_ID.desktop"
if [ -d "\$HERE/share/icons" ]; then
    mkdir -p "\$PREFIX/share/icons"
    cp -r "\$HERE/share/icons/." "\$PREFIX/share/icons/"
fi

command -v update-desktop-database >/dev/null 2>&1 && update-desktop-database "\$PREFIX/share/applications" 2>/dev/null || true
command -v gtk-update-icon-cache >/dev/null 2>&1 && gtk-update-icon-cache -q -t "\$PREFIX/share/icons/hicolor" 2>/dev/null || true

echo "Installed $DISPLAY_NAME to \$APP_DIR"
echo "Start it from your application menu, or run: \$PREFIX/bin/$APP_NAME"
EOF

    cat <<EOF > "$tar_stage/uninstall.sh"
#!/bin/sh
# Removes what install.sh installed (use the same PREFIX, if you set one).
if [ -z "\$PREFIX" ]; then
    if [ "\$(id -u)" = 0 ]; then PREFIX=/usr/local; else PREFIX="\$HOME/.local"; fi
fi
rm -rf "\$PREFIX/lib/$APP_NAME"
rm -f "\$PREFIX/bin/$APP_NAME" "\$PREFIX/share/applications/$LINUX_APP_ID.desktop"
rm -f "\$PREFIX"/share/icons/hicolor/*/apps/$APP_NAME.png
echo "Removed $DISPLAY_NAME from \$PREFIX"
EOF
    chmod 755 "$tar_stage/install.sh" "$tar_stage/uninstall.sh"

    tar -czf "$tar_file" --owner=0 --group=0 -C "$OUTPUT_DIR" "$(basename "$tar_stage")"
    rm -rf "$tar_stage"
    echo "✅ Tarball archive: $tar_file"

    # 4. AppImage (.AppImage)
    local appdir="$OUTPUT_DIR/AppDir"
    rm -rf "$appdir"
    mkdir -p "$appdir/usr/bin" "$appdir/usr/share"
    cp -r "$stage/usr/lib/$APP_NAME/." "$appdir/usr/bin/"
    cp -r "$stage/usr/share/." "$appdir/usr/share/"
    # appimagetool wants the desktop file and its icon at the AppDir root.
    cp "$stage/usr/share/applications/$LINUX_APP_ID.desktop" "$appdir/$LINUX_APP_ID.desktop"
    if [[ -n "$ICON_SOURCE" && -f "$ICON_SOURCE" ]]; then
        cp "$ICON_SOURCE" "$appdir/$APP_NAME.png"
        ln -sf "$APP_NAME.png" "$appdir/.DirIcon"
    fi

    cat <<EOF > "$appdir/AppRun"
#!/bin/sh
HERE=\$(dirname "\$(readlink -f "\$0")")
export GDK_BACKEND=wayland,x11
export LD_LIBRARY_PATH="\$HERE/usr/bin/lib\${LD_LIBRARY_PATH:+:\$LD_LIBRARY_PATH}"
exec "\$HERE/usr/bin/$executable_name" "\$@"
EOF
    chmod 755 "$appdir/AppRun"

    local appimage_tool="" candidate
    for candidate in "$(command -v appimagetool 2>/dev/null || true)" \
                     "$(command -v appimagetool-x86_64.AppImage 2>/dev/null || true)" \
                     "$HOME/.local/bin/appimagetool" "$HOME/.local/bin/appimagetool-x86_64.AppImage" \
                     "$HOME/Applications/appimagetool-x86_64.AppImage" \
                     "./appimagetool" "./appimagetool-x86_64.AppImage"; do
        if [[ -n "$candidate" && -x "$candidate" ]]; then
            appimage_tool="$candidate"
            break
        fi
    done

    if [[ -n "$appimage_tool" ]]; then
        echo "📦 Building .AppImage bundle..."
        local appimage_file="$LINUX_DIST_DIR/${APP_NAME}_${VERSION}_x86_64.AppImage"
        if ARCH=x86_64 "$appimage_tool" "$appdir" "$appimage_file"; then
            chmod 755 "$appimage_file"
            echo "✅ AppImage bundle: $appimage_file"
        else
            PACKAGING_FAILED=true
            echo "❌ appimagetool failed — see above."
        fi
    else
        echo "⚠️  Skipping AppImage generation: appimagetool not found. Download"
        echo "    https://github.com/AppImage/appimagetool/releases (appimagetool-x86_64.AppImage),"
        echo "    chmod +x it and put it in ~/.local/bin or next to this script."
    fi

    rm -rf "$appdir" "$stage"

    # Checksums for this version's packages, in `sha256sum -c` format.
    (cd "$LINUX_DIST_DIR" && sha256sum -- "${APP_NAME}"[-_]"${VERSION}"[-_]* > "SHA256SUMS-v${VERSION}.txt")
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

# True when running under Git Bash / MSYS2 / Cygwin on Windows.
is_windows_host() {
    case "$(uname -s)" in
        MINGW*|MSYS*|CYGWIN*) return 0 ;;
        *) return 1 ;;
    esac
}

# Inno Setup compiler: on PATH, or in its default install folders.
find_iscc() {
    if command -v iscc >/dev/null 2>&1; then command -v iscc; return; fi
    if command -v ISCC.exe >/dev/null 2>&1; then command -v ISCC.exe; return; fi
    local candidate
    for candidate in "/c/Program Files (x86)/Inno Setup 6/ISCC.exe" "/c/Program Files/Inno Setup 6/ISCC.exe"; do
        if [[ -f "$candidate" ]]; then echo "$candidate"; return; fi
    done
}

package_windows() {
    echo ""
    echo "--------------------------------------------------"
    echo "🪟 Packaging Windows Target..."
    echo "--------------------------------------------------"

    if ! is_windows_host; then
        echo "⚠️  Windows packages can only be built on Windows (Git Bash). Skipping."
        return 0
    fi

    if [[ ! -d "windows" ]]; then
        echo "⚠️  No 'windows/' platform directory found in this project. Skipping Windows packaging."
        return 0
    fi

    # Executable name from the runner's CMakeLists (BINARY_NAME).
    local binary_name
    binary_name=$(grep -m1 -oE 'set\(BINARY_NAME "[^"]+"' windows/CMakeLists.txt 2>/dev/null | sed -E 's/.*"(.*)"/\1/' || true)
    [[ -z "$binary_name" ]] && binary_name=$(detect_pubspec_field "name")

    local build_dir="build/windows/x64/runner/Release"
    if [[ "$BUILD_FLAG" == true || ! -f "$build_dir/$binary_name.exe" ]]; then
        echo "🔨 Building Windows Release Bundle..."
        flutter build windows --release
    fi

    if [[ ! -f "$build_dir/$binary_name.exe" ]]; then
        echo "❌ Error: $build_dir/$binary_name.exe not found"
        exit 1
    fi
    echo "🎯 Windows executable: $binary_name.exe"

    mkdir -p "$WINDOWS_DIST_DIR"
    local base="${APP_NAME}_${VERSION}_windows_x64"
    local zip_file="$WINDOWS_DIST_DIR/${base}.zip"
    local setup_name="${base}-setup"
    rm -f "$zip_file" "$WINDOWS_DIST_DIR/${setup_name}.exe"

    # Portable zip: one "<Display Name>" folder holding the bundle.
    echo "📦 Creating portable zip..."
    local stage="build/windows/package"
    rm -rf "$stage"
    mkdir -p "$stage/$DISPLAY_NAME"
    cp -r "$build_dir"/. "$stage/$DISPLAY_NAME/"
    local stage_win zip_win
    stage_win=$(cygpath -w "$stage/$DISPLAY_NAME")
    zip_win=$(cygpath -w "$(pwd)/$zip_file")
    powershell.exe -NoProfile -NonInteractive -Command \
        "Compress-Archive -Path '$stage_win' -DestinationPath '$zip_win' -Force"
    if [[ ! -f "$zip_file" ]]; then
        echo "❌ Error: zip was not created"
        PACKAGING_FAILED=true
    else
        echo "✓ $(basename "$zip_file")"
    fi

    # Installer (Inno Setup). Per-user by default; admins can pick all users.
    local iscc
    iscc=$(find_iscc || true)
    if [[ -z "$iscc" ]]; then
        if [[ "$BUILD_FLAG" == true ]]; then
            echo "❌ Inno Setup (ISCC.exe) not found; cannot build the installer"
            PACKAGING_FAILED=true
        else
            echo "⚠️  Inno Setup (ISCC.exe) not found; skipping the installer"
        fi
    else
        echo "📦 Creating installer with Inno Setup..."
        local iss="build/windows/installer.iss"
        local source_win icon_win out_win
        source_win=$(cygpath -w "$(pwd)/$build_dir")
        icon_win=$(cygpath -w "$(pwd)/windows/runner/resources/app_icon.ico")
        out_win=$(cygpath -w "$(pwd)/$WINDOWS_DIST_DIR")
        local types=(.mp3 .flac .m4a .aac .ogg .opus .wav .wma .alac .aiff .ape .wv)
        {
            cat <<ISS
#define AppName "$DISPLAY_NAME"
#define AppExe "$binary_name.exe"

[Setup]
AppId={{8F3C2A4E-6B1D-4E7A-9C55-2D1F0B7A9E31}
AppName={#AppName}
AppVersion=$VERSION
AppVerName={#AppName} $VERSION
AppPublisher=$DISPLAY_NAME
VersionInfoVersion=$VERSION
DefaultDirName={autopf}\\{#AppName}
DefaultGroupName={#AppName}
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
OutputDir=$out_win
OutputBaseFilename=$setup_name
SetupIconFile=$icon_win
UninstallDisplayIcon={app}\\{#AppExe}
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
ChangesAssociations=yes
CloseApplications=yes

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "$source_win\\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\\{#AppName}"; Filename: "{app}\\{#AppExe}"
Name: "{autodesktop}\\{#AppName}"; Filename: "{app}\\{#AppExe}"; Tasks: desktopicon

[Registry]
Root: HKA; Subkey: "Software\\Classes\\Applications\\{#AppExe}"; ValueType: string; ValueName: "FriendlyAppName"; ValueData: "{#AppName}"; Flags: uninsdeletekey
Root: HKA; Subkey: "Software\\Classes\\Applications\\{#AppExe}\\DefaultIcon"; ValueType: string; ValueData: "{app}\\{#AppExe},0"
Root: HKA; Subkey: "Software\\Classes\\Applications\\{#AppExe}\\shell\\open\\command"; ValueType: string; ValueData: """{app}\\{#AppExe}"" ""%1"""
ISS
            local ext
            for ext in "${types[@]}"; do
                echo "Root: HKA; Subkey: \"Software\\Classes\\Applications\\{#AppExe}\\SupportedTypes\"; ValueType: string; ValueName: \"$ext\"; ValueData: \"\""
                echo "Root: HKA; Subkey: \"Software\\Classes\\$ext\\OpenWithList\\{#AppExe}\"; ValueType: none; Flags: uninsdeletekey"
            done
            cat <<ISS

[Run]
Filename: "{app}\\{#AppExe}"; Description: "{cm:LaunchProgram,{#AppName}}"; Flags: nowait postinstall skipifsilent
ISS
        } > "$iss"
        if "$iscc" //Q "$(cygpath -w "$(pwd)/$iss")" && [[ -f "$WINDOWS_DIST_DIR/${setup_name}.exe" ]]; then
            echo "✓ ${setup_name}.exe"
        else
            echo "❌ Error: installer was not created"
            PACKAGING_FAILED=true
        fi
    fi

    (cd "$WINDOWS_DIST_DIR" && sha256sum -- "${base}"* > "SHA256SUMS-v${VERSION}.txt")
}

# --- Execution Flow ---
case "$TARGET" in
    linux)
        package_linux
        ;;
    android)
        package_android
        ;;
    windows)
        package_windows
        ;;
    all)
        # Linux and Android packages need Linux tools; on Windows build only Windows.
        if is_windows_host; then
            echo "ℹ️  Running on Windows: skipping Linux and Android packages."
        else
            package_linux
            package_android
        fi
        package_windows
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

if [[ -d "$WINDOWS_DIST_DIR" ]]; then
    echo ""
    echo "🪟 Windows Packages ($WINDOWS_DIST_DIR):"
    ls -lh "$WINDOWS_DIST_DIR" 2>/dev/null || echo "   (No Windows packages found)"
fi
echo "=================================================="

if [[ "$PACKAGING_FAILED" == true ]]; then
    exit 1
fi
