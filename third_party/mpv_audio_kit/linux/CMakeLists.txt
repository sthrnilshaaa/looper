# The Flutter tooling requires that developers have CMake 3.10 or later
# installed. You should not increase this version, as doing so will cause
# the plugin to fail to compile for some customers of the plugin.
cmake_minimum_required(VERSION 3.10)

if(POLICY CMP0135)
  cmake_policy(SET CMP0135 NEW)
endif()

# Project-level configuration.
set(PROJECT_NAME "mpv_audio_kit")
project(${PROJECT_NAME} LANGUAGES CXX)

# This value is used when generating builds using this plugin, so it must
# not be changed.
set(PLUGIN_NAME "mpv_audio_kit_plugin")

# ── libmpv Bundling ──────────────────────────────────────────────────────────
# The official libmpv.so is auto-downloaded from GitHub Releases per target
# arch. Two arches are supported (x86_64, aarch64) and the binaries live in
# arch-scoped subdirectories: linux/libs/<arch>/libmpv.so. The CMake config
# detects the build's target arch and picks the matching subdir.
set(MPV_RELEASE_VERSION "libmpv-r15")
set(EXPECTED_SHA256_X86_64  "5a5d115507622406292f536f4cfeb0d3675e2e28be94566bee86e095b962f231")
set(EXPECTED_SHA256_AARCH64  "343935e7539f61283510a3096b7c815826847ffe80ace62584ca537b1c0b0295")

if(CMAKE_SYSTEM_PROCESSOR MATCHES "^(aarch64|arm64)$")
  set(_MPV_ARCH "aarch64")
  set(_MPV_RELEASE_NAME "libmpv_linux-aarch64.so")
  set(_MPV_EXPECTED_SHA "${EXPECTED_SHA256_AARCH64}")
elseif(CMAKE_SYSTEM_PROCESSOR MATCHES "^(x86_64|amd64|AMD64)$")
  set(_MPV_ARCH "x86_64")
  set(_MPV_RELEASE_NAME "libmpv_linux-x86_64.so")
  set(_MPV_EXPECTED_SHA "${EXPECTED_SHA256_X86_64}")
else()
  message(FATAL_ERROR "[mpv_audio_kit] Unsupported Linux arch: ${CMAKE_SYSTEM_PROCESSOR}. Supported: x86_64, aarch64.")
endif()

set(_MPV_LIB_DIR "${CMAKE_CURRENT_SOURCE_DIR}/libs/${_MPV_ARCH}")
set(_BUNDLED_MPV "${_MPV_LIB_DIR}/libmpv.so")

set(DOWNLOAD_NEEDED TRUE)
if(EXISTS "${_BUNDLED_MPV}")
  file(SHA256 "${_BUNDLED_MPV}" ACTUAL_SHA256)
  if(ACTUAL_SHA256 STREQUAL _MPV_EXPECTED_SHA)
    set(DOWNLOAD_NEEDED FALSE)
  else()
    message(STATUS "[mpv_audio_kit] SHA-256 mismatch for ${_MPV_ARCH}: expected ${_MPV_EXPECTED_SHA} but got ${ACTUAL_SHA256}. Redownloading...")
    file(REMOVE "${_BUNDLED_MPV}")
  endif()
endif()

# The remote download is toggled by the build kit's "Libs" actions: active in
# REMOTE mode (download from GitHub when the local libmpv is absent / stale),
# commented out in LOCAL mode (use the bundled binary only, never download). The
# kit comments/uncomments this block — do not hand-edit the mpvkit: markers.
# mpvkit:remote:begin
if(DOWNLOAD_NEEDED)
  message(STATUS "[mpv_audio_kit] Downloading ${_MPV_RELEASE_NAME} from GitHub Releases...")
  file(MAKE_DIRECTORY "${_MPV_LIB_DIR}")
  file(DOWNLOAD
    "https://github.com/ales-drnz/mpv_audio_kit/releases/download/${MPV_RELEASE_VERSION}/${_MPV_RELEASE_NAME}"
    "${_BUNDLED_MPV}"
    SHOW_PROGRESS
    EXPECTED_HASH SHA256=${_MPV_EXPECTED_SHA}
    STATUS DOWNLOAD_STATUS
  )
  list(GET DOWNLOAD_STATUS 0 STATUS_CODE)
  if(NOT STATUS_CODE EQUAL 0)
    list(GET DOWNLOAD_STATUS 1 ERROR_MSG)
    message(FATAL_ERROR "[mpv_audio_kit] Failed to download ${_MPV_RELEASE_NAME}: ${ERROR_MSG}. Place it manually at ${_BUNDLED_MPV}")
  endif()
endif()
# mpvkit:remote:end

if(EXISTS "${_BUNDLED_MPV}")
  message(STATUS "[mpv_audio_kit] Using bundled libmpv: ${_BUNDLED_MPV}")
  add_library(mpv_bundled SHARED IMPORTED GLOBAL)
  set_target_properties(mpv_bundled PROPERTIES IMPORTED_LOCATION "${_BUNDLED_MPV}")
  set(mpv_audio_kit_bundled_libraries "${_BUNDLED_MPV}" PARENT_SCOPE)
else()
  message(FATAL_ERROR "[mpv_audio_kit] libmpv not found. It must be present at ${_BUNDLED_MPV}")
endif()

# Any new source files that you add to the plugin should be added here.
list(APPEND PLUGIN_SOURCES
  "mpv_audio_kit_plugin.cc"
  "mpris_server.cc"
)

# Define the plugin library target. Its name must not be changed (see comment
# on PLUGIN_NAME above).
add_library(${PLUGIN_NAME} SHARED
  ${PLUGIN_SOURCES}
)

# Apply a standard set of build settings that are configured in the
# application-level CMakeLists.txt. This can be removed for plugins that want
# full control over build settings.
apply_standard_settings(${PLUGIN_NAME})

# Symbols are hidden by default to reduce the chance of accidental conflicts
# between plugins. This should not be removed; any symbols that should be
# exported should be explicitly exported with the FLUTTER_PLUGIN_EXPORT macro.
set_target_properties(${PLUGIN_NAME} PROPERTIES
  CXX_VISIBILITY_PRESET hidden)
target_compile_definitions(${PLUGIN_NAME} PRIVATE FLUTTER_PLUGIN_IMPL)

# Source include directories and library dependencies. Add any plugin-specific
# dependencies here.
target_include_directories(${PLUGIN_NAME}
  INTERFACE "${CMAKE_CURRENT_SOURCE_DIR}/include"
)
target_link_libraries(${PLUGIN_NAME} PRIVATE flutter)
target_link_libraries(${PLUGIN_NAME} PRIVATE PkgConfig::GTK)

# GDBus / GLib (GIO) for the MPRIS2 media-session server. GIO ships with the
# GTK stack — GTK pulls it transitively — but link it explicitly so the
# g_bus_own_name / g_dbus_connection_* symbols are guaranteed resolved.
find_package(PkgConfig REQUIRED)
pkg_check_modules(GIO REQUIRED IMPORTED_TARGET gio-2.0)
target_link_libraries(${PLUGIN_NAME} PRIVATE PkgConfig::GIO)
