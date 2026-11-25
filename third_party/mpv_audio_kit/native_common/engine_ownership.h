// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
#ifndef MPV_AUDIO_KIT_ENGINE_OWNERSHIP_H_
#define MPV_AUDIO_KIT_ENGINE_OWNERSHIP_H_

#include <map>

namespace mpv_audio_kit {

// Which Flutter engine of the process owns the OS media session, and the
// command sink of each engine. The Windows SMTC and the Linux MPRIS name are
// one per process while the plugin runs once per engine: both plugins
// include this header from native_common/ (see their CMakeLists.txt).
//
// The first engine to enable owns the session until it disables or
// detaches. Another engine's enable is refused, and its updates, disable
// and detach change nothing. OS commands go to the owner's sink, whichever
// engine listened last. A Hot Restart keeps the engine, so its new VM's
// calls are the owner's. Android (EngineOwnership.kt) and Apple
// (MediaSessionPlugin.swift) follow the same rule, and
// test/media_session/cpp/engine_ownership_test.cc runs its table.
//
// An engine is a non-null pointer unique to it, its plugin or channel. Sink
// is a pointer type: a null one means no sink. Platform thread only.
template <typename Sink>
class EngineOwnership {
 public:
  // [engine] listened for commands on [sink].
  void OnListen(const void* engine, Sink sink) { sinks_[engine] = sink; }

  // [engine] cancelled: its sink goes.
  void OnCancel(const void* engine) { sinks_.erase(engine); }

  // [engine] asks to enable the session. Refused, with nothing changed,
  // while another engine owns it.
  bool TryEnable(const void* engine) {
    if (owner_ != nullptr && owner_ != engine) return false;
    owner_ = engine;
    return true;
  }

  // The enable TryEnable accepted for [engine] failed. [owned_before] is
  // whether [engine] owned the session before that enable (MayUpdate, read
  // before TryEnable). An engine that took the session with this enable
  // gives it back, and the caller turns off what it built: true. An owner
  // whose new enable failed keeps the session it had: false.
  bool OnEnableFailed(const void* engine, bool owned_before) {
    if (owned_before || owner_ != engine) return false;
    owner_ = nullptr;
    return true;
  }

  // Whether an update from [engine] reaches the session: only the owner's.
  bool MayUpdate(const void* engine) const { return owner_ == engine; }

  // Whether a disable from [engine] turns the session off: the owner's
  // does, and any does while nobody owns it (a no-op then).
  bool MayDisable(const void* engine) const {
    return owner_ == nullptr || owner_ == engine;
  }

  // The session went off.
  void OnDisabled() { owner_ = nullptr; }

  // [engine] detached: its sink goes. Returns whether it owned the
  // session, which the caller then turns off.
  bool OnDetach(const void* engine) {
    sinks_.erase(engine);
    if (owner_ != engine) return false;
    owner_ = nullptr;
    return true;
  }

  // Where an OS command goes: the owner's sink, or null.
  Sink CommandSink() const {
    auto it = sinks_.find(owner_);
    return it == sinks_.end() ? nullptr : it->second;
  }

 private:
  std::map<const void*, Sink> sinks_;
  const void* owner_ = nullptr;
};

}  // namespace mpv_audio_kit

#endif  // MPV_AUDIO_KIT_ENGINE_OWNERSHIP_H_
