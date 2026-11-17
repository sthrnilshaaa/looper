// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
#include "media_session_channel_win.h"

#include <winrt/Windows.Foundation.h>

#include <appmodel.h>       // GetCurrentPackageFullName
#include <shobjidl_core.h>  // SetCurrentProcessExplicitAppUserModelID

#include <flutter/event_stream_handler_functions.h>

#include <atomic>
#include <cwctype>
#include <optional>
#include <string>
#include <variant>
#include <vector>

namespace mpv_audio_kit {

namespace {

using flutter::EncodableList;
using flutter::EncodableMap;
using flutter::EncodableValue;

constexpr UINT kCommandMessage = WM_APP + 1;
const wchar_t* kWindowClass = L"MpvAudioKitMediaSessionMsgWindow";

const EncodableValue* Find(const EncodableMap& m, const char* key) {
  auto it = m.find(EncodableValue(std::string(key)));
  return it == m.end() ? nullptr : &it->second;
}

std::optional<std::string> GetString(const EncodableMap& m, const char* key) {
  if (auto* v = Find(m, key))
    if (auto* s = std::get_if<std::string>(v)) return *s;
  return std::nullopt;
}

std::optional<int64_t> GetInt64(const EncodableMap& m, const char* key) {
  if (auto* v = Find(m, key)) {
    if (auto* i = std::get_if<int64_t>(v)) return *i;
    if (auto* i = std::get_if<int32_t>(v)) return static_cast<int64_t>(*i);
  }
  return std::nullopt;
}

std::optional<double> GetDouble(const EncodableMap& m, const char* key) {
  if (auto* v = Find(m, key)) {
    if (auto* d = std::get_if<double>(v)) return *d;
    if (auto* i = std::get_if<int32_t>(v)) return static_cast<double>(*i);
    if (auto* i = std::get_if<int64_t>(v)) return static_cast<double>(*i);
  }
  return std::nullopt;
}

bool GetBool(const EncodableMap& m, const char* key, bool fallback) {
  if (auto* v = Find(m, key))
    if (auto* b = std::get_if<bool>(v)) return *b;
  return fallback;
}

SmtcConfig ParseConfig(const EncodableMap& m) {
  SmtcConfig c;
  if (auto* v = Find(m, "actions"))
    if (auto* list = std::get_if<EncodableList>(v))
      for (const auto& e : *list)
        if (auto* s = std::get_if<std::string>(&e)) c.actions.insert(*s);
  if (auto s = GetString(m, "interruptionPolicy")) c.interruption_policy = *s;
  if (auto i = GetInt64(m, "fastForwardIntervalMs")) c.fast_forward_ms = *i;
  if (auto i = GetInt64(m, "rewindIntervalMs")) c.rewind_ms = *i;
  if (auto* v = Find(m, "supportedPlaybackRates"))
    if (auto* list = std::get_if<EncodableList>(v))
      for (const auto& e : *list) {
        if (auto* d = std::get_if<double>(&e)) {
          c.supported_rates.push_back(*d);
        } else if (auto* i32 = std::get_if<int32_t>(&e)) {
          c.supported_rates.push_back(static_cast<double>(*i32));
        } else if (auto* i64 = std::get_if<int64_t>(&e)) {
          c.supported_rates.push_back(static_cast<double>(*i64));
        }
      }
  if (auto s = GetString(m, "appName")) c.app_name = *s;
  return c;
}

SmtcMetadata ParseMetadata(const EncodableMap& m) {
  SmtcMetadata md;
  md.title = GetString(m, "title");
  md.artist = GetString(m, "artist");
  md.album = GetString(m, "album");
  md.album_artist = GetString(m, "albumArtist");
  md.genre = GetString(m, "genre");
  md.track_number = GetInt64(m, "trackNumber");
  if (auto* v = Find(m, "artworkBytes"))
    if (auto* b = std::get_if<std::vector<uint8_t>>(v)) md.artwork = *b;
  md.artwork_uri = GetString(m, "artworkUri");
  md.duration_ms = GetInt64(m, "durationMs");
  return md;
}

SmtcPlayback ParsePlayback(const EncodableMap& m) {
  SmtcPlayback p;
  p.playing = GetBool(m, "playing", false);
  p.buffering = GetBool(m, "buffering", false);
  if (auto i = GetInt64(m, "positionMs")) p.position_ms = *i;
  if (auto d = GetDouble(m, "rate")) p.rate = *d;
  p.seekable = GetBool(m, "seekable", false);
  p.has_next = GetBool(m, "hasNext", true);
  p.has_previous = GetBool(m, "hasPrevious", true);
  if (auto s = GetString(m, "loop")) p.loop = *s;
  p.shuffle = GetBool(m, "shuffle", false);
  return p;
}

const EncodableMap* SubMap(const EncodableMap& m, const char* key) {
  if (auto* v = Find(m, key)) return std::get_if<EncodableMap>(v);
  return nullptr;
}

// Give the process a stable AppUserModelID before the SystemMediaTransportControls
// is created. An unpackaged Flutter `.exe` has no explicit AUMID, so the SMTC
// card would show an unstable source identity. Derived once from the
// consumer-supplied app name (sanitised to AUMID-legal characters) with a
// stable package fallback. Must run before SmtcController::EnsureCreated()
// acquires the SMTC.
//
// The AUMID is process-wide and groups the app's taskbar buttons, so an
// identity the app already has always wins: a packaged (MSIX) app's, or one
// it set itself at startup, which is where Windows wants it set.
void EnsureProcessIdentity(const std::string& app_name_utf8) {
  static std::atomic_flag done = ATOMIC_FLAG_INIT;
  if (done.test_and_set()) return;

  UINT32 package_name_length = 0;
  if (GetCurrentPackageFullName(&package_name_length, nullptr) !=
      APPMODEL_ERROR_NO_PACKAGE) {
    return;  // packaged: the package identity is the AUMID
  }
  PWSTR existing = nullptr;
  if (SUCCEEDED(GetCurrentProcessExplicitAppUserModelID(&existing))) {
    CoTaskMemFree(existing);
    return;  // the app chose its own
  }

  std::wstring aumid = L"mpv_audio_kit";
  if (!app_name_utf8.empty()) {
    int n = MultiByteToWideChar(CP_UTF8, 0, app_name_utf8.c_str(), -1, nullptr, 0);
    if (n > 0) {
      std::wstring wide(static_cast<size_t>(n), L'\0');
      MultiByteToWideChar(CP_UTF8, 0, app_name_utf8.c_str(), -1, wide.data(), n);
      std::wstring suffix;
      for (wchar_t c : wide) {
        if (c == L'\0') break;
        if (std::iswalnum(static_cast<wint_t>(c))) suffix.push_back(c);
      }
      if (!suffix.empty()) aumid += L"." + suffix;  // e.g. "mpv_audio_kit.Finova"
    }
  }
  SetCurrentProcessExplicitAppUserModelID(aumid.c_str());  // HRESULT ignored
}

}  // namespace

MediaSessionChannelWin::MediaSessionChannelWin(
    flutter::PluginRegistrarWindows* registrar) {
  // SMTC types are agile, but C++/WinRT requires the apartment initialised.
  // Flutter already inits COM on this (platform) thread as STA; match that
  // (init_apartment defaults to MTA, which would just throw RPC_E_CHANGED_MODE
  // and mask the real apartment). The artwork async work runs on its own MTA
  // thread — see MakeThumbnail — since `.get()` is unsafe on this STA thread.
  try {
    winrt::init_apartment(winrt::apartment_type::single_threaded);
  } catch (const winrt::hresult_error&) {
  }

  // Message-only window to marshal OS commands onto the platform thread.
  WNDCLASSW wc{};
  wc.lpfnWndProc = &MediaSessionChannelWin::WndProc;
  wc.hInstance = GetModuleHandleW(nullptr);
  wc.lpszClassName = kWindowClass;
  RegisterClassW(&wc);  // ignore ERROR_CLASS_ALREADY_EXISTS
  message_window_ =
      CreateWindowExW(0, kWindowClass, L"", 0, 0, 0, 0, 0, HWND_MESSAGE, nullptr,
                      wc.hInstance, nullptr);
  if (message_window_) {
    SetWindowLongPtrW(message_window_, GWLP_USERDATA,
                      reinterpret_cast<LONG_PTR>(this));
  }

  controller_ = std::make_unique<SmtcController>(
      [this](EncodableValue command) { ForwardCommand(std::move(command)); });

  method_channel_ = std::make_unique<flutter::MethodChannel<EncodableValue>>(
      registrar->messenger(), "mpv_audio_kit/media_session",
      &flutter::StandardMethodCodec::GetInstance());
  method_channel_->SetMethodCallHandler(
      [this](const auto& call, auto result) {
        HandleMethodCall(call, std::move(result));
      });

  event_channel_ = std::make_unique<flutter::EventChannel<EncodableValue>>(
      registrar->messenger(), "mpv_audio_kit/media_session/commands",
      &flutter::StandardMethodCodec::GetInstance());
  event_channel_->SetStreamHandler(
      std::make_unique<flutter::StreamHandlerFunctions<EncodableValue>>(
          [this](const EncodableValue*,
                 std::unique_ptr<flutter::EventSink<EncodableValue>>&& events)
              -> std::unique_ptr<flutter::StreamHandlerError<EncodableValue>> {
            event_sink_ = std::move(events);
            return nullptr;
          },
          [this](const EncodableValue*)
              -> std::unique_ptr<flutter::StreamHandlerError<EncodableValue>> {
            event_sink_.reset();
            return nullptr;
          }));
}

MediaSessionChannelWin::~MediaSessionChannelWin() {
  // Publish nullptr to the window BEFORE tearing down the controller: a command
  // firing on a WinRT pool thread mid-teardown then no-ops in ForwardCommand
  // instead of racing the window's destruction. (The controller also flips its
  // own `alive_` flag so its handlers stop touching the command sink.)
  HWND win = message_window_.exchange(nullptr);
  controller_.reset();
  if (win) {
    SetWindowLongPtrW(win, GWLP_USERDATA, 0);
    // Drain queued command messages so their heap payloads aren't leaked when
    // the window is destroyed.
    MSG msg;
    while (PeekMessageW(&msg, win, kCommandMessage, kCommandMessage, PM_REMOVE)) {
      delete reinterpret_cast<EncodableValue*>(msg.lParam);
    }
    DestroyWindow(win);
  }
}

void MediaSessionChannelWin::ForwardCommand(EncodableValue command) {
  HWND win = message_window_.load();
  if (!win) return;
  auto* heap = new EncodableValue(std::move(command));
  if (!PostMessageW(win, kCommandMessage, 0, reinterpret_cast<LPARAM>(heap))) {
    delete heap;
  }
}

LRESULT CALLBACK MediaSessionChannelWin::WndProc(HWND hwnd, UINT msg,
                                                 WPARAM wparam, LPARAM lparam) {
  if (msg == kCommandMessage) {
    auto* command = reinterpret_cast<EncodableValue*>(lparam);
    auto* self = reinterpret_cast<MediaSessionChannelWin*>(
        GetWindowLongPtrW(hwnd, GWLP_USERDATA));
    if (self && self->event_sink_ && command) {
      self->event_sink_->Success(*command);
    }
    delete command;
    return 0;
  }
  return DefWindowProcW(hwnd, msg, wparam, lparam);
}

void MediaSessionChannelWin::HandleMethodCall(
    const flutter::MethodCall<EncodableValue>& call,
    std::unique_ptr<flutter::MethodResult<EncodableValue>> result) {
  const auto& method = call.method_name();
  const auto* args = std::get_if<EncodableMap>(call.arguments());

  // Backstop: any WinRT failure inside the controller surfaces as a channel
  // error instead of an uncaught hresult_error that would crash the engine.
  try {
    if (method == "enable") {
      if (!args) {
        result->Error("bad_args", "enable expects a map");
        return;
      }
      const EncodableMap* cfg = SubMap(*args, "config");
      const EncodableMap* meta = SubMap(*args, "metadata");
      const EncodableMap* pb = SubMap(*args, "playback");
      SmtcConfig parsed = cfg ? ParseConfig(*cfg) : SmtcConfig{};
      // Set the process AUMID (from app_name) before the SMTC is created inside
      // Enable() → EnsureCreated(); no-op after the first call.
      EnsureProcessIdentity(parsed.app_name);
      controller_->Enable(parsed,
                          meta ? ParseMetadata(*meta) : SmtcMetadata{},
                          pb ? ParsePlayback(*pb) : SmtcPlayback{});
      result->Success();
    } else if (method == "updateConfig") {
      if (args) controller_->UpdateConfig(ParseConfig(*args));
      result->Success();
    } else if (method == "updateMetadata") {
      if (args) controller_->UpdateMetadata(ParseMetadata(*args));
      result->Success();
    } else if (method == "updatePlayback") {
      if (args) controller_->UpdatePlayback(ParsePlayback(*args));
      result->Success();
    } else if (method == "disable") {
      controller_->Disable();
      result->Success();
    } else if (method == "debugMediaSessionState") {
      result->Success(controller_->DebugState());
    } else {
      result->NotImplemented();
    }
  } catch (const winrt::hresult_error& e) {
    result->Error("smtc_error", winrt::to_string(e.message()));
  }
}

}  // namespace mpv_audio_kit
