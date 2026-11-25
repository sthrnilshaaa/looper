# Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
# All rights reserved.
# Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

# libmpv for LG webOS TVs, through flutter-webos
# (https://github.com/lg-flutter-webos/flutter-webos), which runs no build
# hook: libmpv_webos-armv7l.so of the release the package pins, checked
# against its SHA-256, is bundled in the app's lib/ as
# libmpv_audio_kit_webos.so, a name of its own, which
# MpvAudioKit.ensureInitialized looks for.
#
# MPV_AUDIO_KIT_LIBMPV in the environment of the build bundles another
# libmpv, as the libmpv user define does for the hook: a file, or a
# directory of release assets. It must be a build of libmpv-scripts at the
# release the package pins.
#
# scripts/update_libmpv.sh writes the release and the SHA-256.
cmake_minimum_required(VERSION 3.10)
project(mpv_audio_kit LANGUAGES NONE)

set(MAK_LIBMPV_RELEASE "libmpv-r27")
set(MAK_LIBMPV_SHA256 "557d4597767075476a20d9f4a4e9f9b42ad604af2ea66f0876382cc2862f436c")

# flutter-webos names its target here: arm, the TVs, or arm64 with
# --target-arch arm64, which has no libmpv. Failing now beats an app that
# bundles the 32-bit library and cannot load it.
if(FLUTTER_TARGET_PLATFORM AND NOT FLUTTER_TARGET_PLATFORM STREQUAL "webos-arm")
  message(FATAL_ERROR "mpv_audio_kit: no libmpv for ${FLUTTER_TARGET_PLATFORM}; build with --target-arch arm")
endif()

set(asset "libmpv_webos-armv7l.so")
set(out "${CMAKE_CURRENT_BINARY_DIR}/libmpv_audio_kit_webos.so")
set(local "$ENV{MPV_AUDIO_KIT_LIBMPV}")
if(local)
  if(IS_DIRECTORY "${local}")
    set(local "${local}/${asset}")
  endif()
  if(NOT EXISTS "${local}")
    message(FATAL_ERROR "mpv_audio_kit: MPV_AUDIO_KIT_LIBMPV points at ${local}, which does not exist")
  endif()
  configure_file("${local}" "${out}" COPYONLY)
else()
  if(MAK_LIBMPV_SHA256 STREQUAL "")
    message(FATAL_ERROR "mpv_audio_kit: no SHA-256 pinned for ${asset} in ${MAK_LIBMPV_RELEASE}; MPV_AUDIO_KIT_LIBMPV in the environment bundles a libmpv of your own")
  endif()
  # Downloaded once: a file already there with this checksum is kept.
  file(DOWNLOAD
    "https://github.com/ales-drnz/mpv_audio_kit/releases/download/${MAK_LIBMPV_RELEASE}/${asset}"
    "${out}"
    EXPECTED_HASH SHA256=${MAK_LIBMPV_SHA256}
    TLS_VERIFY ON
    # A connection that stalls must fail the configure step, not hang it.
    INACTIVITY_TIMEOUT 60
    TIMEOUT 900
    STATUS status)
  list(GET status 0 code)
  if(NOT code EQUAL 0)
    list(GET status 1 reason)
    message(FATAL_ERROR "mpv_audio_kit: cannot download ${asset} of ${MAK_LIBMPV_RELEASE}: ${reason}")
  endif()
endif()

set(mpv_audio_kit_bundled_libraries "${out}" PARENT_SCOPE)
