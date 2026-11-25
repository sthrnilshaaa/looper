# 3.14 is the minimum CMake the Flutter Windows tooling ships; raising it
# breaks some app builds.
cmake_minimum_required(VERSION 3.14)

# Project-level configuration.
set(PROJECT_NAME "mpv_audio_kit")
project(${PROJECT_NAME} LANGUAGES CXX)

# Newer CMake policies up to 3.25, without the deprecation warnings.
cmake_policy(VERSION 3.14...3.25)

# Flutter derives the registrant name from PLUGIN_NAME; keep it.
set(PLUGIN_NAME "mpv_audio_kit_plugin")

# The plugin sources.
list(APPEND PLUGIN_SOURCES
  "mpv_audio_kit_plugin.cpp"
  "mpv_audio_kit_plugin.h"
  "media_session_smtc.cpp"
  "media_session_smtc.h"
  "media_session_channel_win.cpp"
  "media_session_channel_win.h"
)

# The plugin library, named after PLUGIN_NAME.
add_library(${PLUGIN_NAME} SHARED
  "include/mpv_audio_kit/mpv_audio_kit_plugin_c_api.h"
  "mpv_audio_kit_plugin_c_api.cpp"
  ${PLUGIN_SOURCES}
)

# The app's standard Flutter build settings.
apply_standard_settings(${PLUGIN_NAME})

# Symbols are hidden; only FLUTTER_PLUGIN_EXPORT ones are exported.
set_target_properties(${PLUGIN_NAME} PROPERTIES
  CXX_VISIBILITY_PRESET hidden)
target_compile_definitions(${PLUGIN_NAME} PRIVATE FLUTTER_PLUGIN_IMPL)

# C++/WinRT needs C++20 coroutines. Under the app template's C++17 it falls
# back to <experimental/coroutine>, which MSVC 14.51 (Visual Studio 2026)
# rejects with STL1011. The highest requested standard wins, so this lifts
# only the plugin target.
target_compile_features(${PLUGIN_NAME} PRIVATE cxx_std_20)

# The public header, for the generated registrant.
target_include_directories(${PLUGIN_NAME}
  INTERFACE "${CMAKE_CURRENT_SOURCE_DIR}/include"
)
# The multi engine rule of the media session, one header shared with the
# Linux plugin. The package root is the parent of this directory, also
# where an app's build reaches it (flutter/ephemeral/.plugin_symlinks).
target_include_directories(${PLUGIN_NAME} PRIVATE
  "${CMAKE_CURRENT_SOURCE_DIR}/../native_common"
)
target_link_libraries(${PLUGIN_NAME} PRIVATE flutter flutter_wrapper_plugin)

# C++/WinRT consumes SystemMediaTransportControls; link the WinRT umbrella
# import library for RoActivateInstance / WindowsCreateString etc. The
# C++/WinRT headers (winrt/Windows.Media.*) are header-only and ship with the
# Windows SDK already on the MSVC include path — no NuGet, no extra toolchain.
target_link_libraries(${PLUGIN_NAME} PRIVATE windowsapp)

# shell32 provides SetCurrentProcessExplicitAppUserModelID, used to give the
# process a stable AppUserModelID so the SystemMediaTransportControls card shows
# a consistent source identity on unpackaged .exe builds.
target_link_libraries(${PLUGIN_NAME} PRIVATE shell32)

# shlwapi provides SHCreateMemStream and shcore
# CreateRandomAccessStreamOverStream, which build the cover stream for the
# SystemMediaTransportControls thumbnail.
target_link_libraries(${PLUGIN_NAME} PRIVATE shlwapi shcore)

# libmpv is not built or bundled here: the package's build hook
# (hook/build.dart) downloads it and Flutter bundles it as a code asset.
