# The Flutter tooling requires that developers have CMake 3.10 or later
# installed. You should not increase this version, as doing so will cause
# the plugin to fail to compile for some customers of the plugin.
cmake_minimum_required(VERSION 3.10)

project(metadata_god_library VERSION 0.0.1 LANGUAGES C)

add_library(metadata_god SHARED
  "metadata_god.c"
)

set_target_properties(metadata_god PROPERTIES
  PUBLIC_HEADER metadata_god.h
  OUTPUT_NAME "metadata_god"
)

target_compile_definitions(metadata_god PUBLIC DART_SHARED_LIB)

if (ANDROID)
  # Support Android 15 16k page size.
  target_link_options(metadata_god PRIVATE "-Wl,-z,max-page-size=16384")
endif()
