/*
 * mpv_audio_kit_jni.c
 *
 * Thin JNI/NDK wrapper stub. Exists only to satisfy the Flutter Android
 * build system (ffiPlugin: true requires a compiled .so from CMake).
 *
 * Loading sequence on Android:
 *   1. MpvAudioKitPlugin.kt calls System.loadLibrary("mpv") on plugin attach.
 *      This makes the JVM invoke libmpv.so's own JNI_OnLoad, registering the
 *      JavaVM pointer so the AudioTrack audio driver can use JNI internally.
 *   2. Dart dart:ffi calls DynamicLibrary.open("libmpv.so") via dlopen().
 *      Since the library is already in memory from step 1, dlopen() returns
 *      the same handle — fully initialized.
 *   3. All mpv API calls go through dart:ffi directly; this JNI module is
 *      never invoked at runtime.
 */

#include <android/log.h>
#include <jni.h>


#define LOG_TAG "mpv_audio_kit"
#define LOGD(...) __android_log_print(ANDROID_LOG_DEBUG, LOG_TAG, __VA_ARGS__)

JNIEXPORT jint JNICALL JNI_OnLoad(JavaVM *vm, void *reserved) {
  LOGD("mpv_audio_kit JNI loaded");
  return JNI_VERSION_1_6;
}
