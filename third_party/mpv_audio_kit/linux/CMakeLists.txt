# 3.10 is the minimum CMake the Flutter Linux tooling requires; raising it
# breaks some app builds.
cmake_minimum_required(VERSION 3.10)

# Project-level configuration.
set(PROJECT_NAME "mpv_audio_kit")
project(${PROJECT_NAME} LANGUAGES CXX)

# pkg-config for GIO below, and for the PkgConfig::GTK target the app's
# CMakeLists.txt defines: found here, before either is used.
find_package(PkgConfig REQUIRED)

# Flutter derives the registrant name from PLUGIN_NAME; keep it.
set(PLUGIN_NAME "mpv_audio_kit_plugin")

# libmpv is not built or bundled here: the package's build hook
# (hook/build.dart) downloads it and Flutter bundles it as a code asset.

# The plugin sources.
list(APPEND PLUGIN_SOURCES
  "mpv_audio_kit_plugin.cc"
  "mpris_server.cc"
)

# The plugin library, named after PLUGIN_NAME.
add_library(${PLUGIN_NAME} SHARED
  ${PLUGIN_SOURCES}
)

# The app's standard Flutter build settings.
apply_standard_settings(${PLUGIN_NAME})

# Symbols are hidden; only FLUTTER_PLUGIN_EXPORT ones are exported.
set_target_properties(${PLUGIN_NAME} PROPERTIES
  CXX_VISIBILITY_PRESET hidden)
target_compile_definitions(${PLUGIN_NAME} PRIVATE FLUTTER_PLUGIN_IMPL)

# The public header, for the generated registrant.
target_include_directories(${PLUGIN_NAME}
  INTERFACE "${CMAKE_CURRENT_SOURCE_DIR}/include"
)
# The multi engine rule of the media session, one header shared with the
# Windows plugin. The package root is the parent of this directory, also
# where an app's build reaches it (flutter/ephemeral/.plugin_symlinks).
target_include_directories(${PLUGIN_NAME} PRIVATE
  "${CMAKE_CURRENT_SOURCE_DIR}/../native_common"
)
target_link_libraries(${PLUGIN_NAME} PRIVATE flutter)
target_link_libraries(${PLUGIN_NAME} PRIVATE PkgConfig::GTK)

# GDBus / GLib (GIO) for the MPRIS2 media-session server. GIO ships with the
# GTK stack — GTK pulls it transitively — but link it explicitly so the
# g_bus_own_name / g_dbus_connection_* symbols are guaranteed resolved.
pkg_check_modules(GIO REQUIRED IMPORTED_TARGET gio-2.0)
target_link_libraries(${PLUGIN_NAME} PRIVATE PkgConfig::GIO)
