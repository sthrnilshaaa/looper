# mpv_audio_kit — Android NDK CMakeLists
#
# This file compiles a thin C wrapper that acts as a bridge for dart:ffi.

cmake_minimum_required(VERSION 3.18.1)
project("mpv_audio_kit_jni")

# ── Wrapper sources ────────────────────────────────────────────────────────
add_library(mpv_audio_kit_jni SHARED
  mpv_audio_kit_jni.c
)

# ── Find prebuilt libmpv ───────────────────────────────────────────────────
# Search first in the project's jniLibs directory
set(MPV_LIB_DIR "${CMAKE_SOURCE_DIR}/../jniLibs/${ANDROID_ABI}")

find_library(MPV_LIBRARY mpv PATHS "${MPV_LIB_DIR}" NO_DEFAULT_PATH)

if(MPV_LIBRARY)
  message(STATUS "[mpv_audio_kit] Found libmpv.so: ${MPV_LIBRARY}")
  target_include_directories(mpv_audio_kit_jni PRIVATE
    "${CMAKE_SOURCE_DIR}/include"
  )
  target_link_libraries(mpv_audio_kit_jni PRIVATE
    ${MPV_LIBRARY}
    android
    log
  )
else()
  message(WARNING "[mpv_audio_kit] libmpv.so not found for ABI=${ANDROID_ABI}. "
                  "The plugin will use dart:ffi to load it at runtime if present in the APK.")
  # Compile an empty wrapper anyway to avoid blocking the build
  target_link_libraries(mpv_audio_kit_jni PRIVATE android log)
endif()
