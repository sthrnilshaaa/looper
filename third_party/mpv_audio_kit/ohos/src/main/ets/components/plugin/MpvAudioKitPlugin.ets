// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

// The media session of mpv_audio_kit on OpenHarmony and HarmonyOS: an
// AVSession of type audio that shows what plays and sends the commands of
// the system back to Dart, and the continuous task of audio playback, which
// keeps the app playing in the background. Without the AVSession the
// system mutes and freezes the audio of an app in the background.
//
// The same channels as the other platforms: mpv_audio_kit/media_session
// (enable, updateConfig, updateMetadata, updatePlayback, disable) and the
// event channel mpv_audio_kit/media_session/commands, one map per command
// with its type (media_session_channel.dart reads them).
//
// The continuous task runs while the player plays: it is started on play,
// stopped on a pause, a stop, the end and a disable, and started again on
// the next play, as the system asks (it also stops the task itself when an
// interruption stops the audio). The app declares the permission
// ohos.permission.KEEP_BACKGROUND_RUNNING and backgroundModes
// ["audioPlayback"] on its ability; without them the start is refused, and
// the session still works in the foreground.
//
// Only the calls of API 12 or older (HarmonyOS 5.0).

import {
  AbilityAware,
  AbilityPluginBinding,
  Any,
  EventChannel,
  EventSink,
  FlutterPlugin,
  FlutterPluginBinding,
  MethodCall,
  MethodCallHandler,
  MethodChannel,
  MethodResult,
  StreamHandler,
} from '@ohos/flutter_ohos';
import { avSession } from '@kit.AVSessionKit';
import { backgroundTaskManager } from '@kit.BackgroundTasksKit';
import { common, UIAbility, wantAgent, WantAgent } from '@kit.AbilityKit';
import { image } from '@kit.ImageKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'mpv_audio_kit';
const DOMAIN = 0x4d41;

// The one session of the process, with the engine that owns it: a second
// engine's enable is refused with already_owned, as on the other platforms.
let owner: MpvAudioKitPlugin | null = null;

interface Command {
  type: string;
  positionMs?: number;
  offsetMs?: number;
  loop?: string;
  shuffle?: boolean;
  rate?: number;
}

function str(m: Map<Any, Any>, key: string): string | undefined {
  const v: Any = m.get(key);
  return typeof v === 'string' ? v as string : undefined;
}

function num(m: Map<Any, Any>, key: string): number | undefined {
  const v: Any = m.get(key);
  if (typeof v === 'number') {
    return v as number;
  }
  if (typeof v === 'bigint') {
    return Number(v as bigint);
  }
  return undefined;
}

function bool(m: Map<Any, Any>, key: string): boolean {
  return m.get(key) === true;
}

function sub(m: Map<Any, Any>, key: string): Map<Any, Any> {
  const v: Any = m.get(key);
  return v instanceof Map ? v as Map<Any, Any> : new Map<Any, Any>();
}

function loopMode(loop: string | undefined, shuffle: boolean): avSession.LoopMode {
  if (shuffle) {
    return avSession.LoopMode.LOOP_MODE_SHUFFLE;
  }
  switch (loop) {
    case 'file':
      return avSession.LoopMode.LOOP_MODE_SINGLE;
    case 'playlist':
      return avSession.LoopMode.LOOP_MODE_LIST;
    default:
      return avSession.LoopMode.LOOP_MODE_SEQUENCE;
  }
}

export default class MpvAudioKitPlugin implements FlutterPlugin, MethodCallHandler, AbilityAware, StreamHandler {
  private methods: MethodChannel | null = null;
  private events: EventChannel | null = null;
  private sink: EventSink | null = null;
  private ability: UIAbility | null = null;
  private appContext: common.Context | null = null;

  private session: avSession.AVSession | null = null;
  // Bumped by each disable: a create still running when one comes is
  // destroyed as soon as it lands.
  private generation = 0;
  private actions: string[] = [];
  private registered: string[] = [];
  private favorite = false;
  private fastForwardMs = 15000;
  private rewindMs = 15000;
  private shuffle = false;
  private assetId = '';
  private playing = false;
  private taskRunning = false;
  private taskWanted = false;
  private taskRefused = false;

  getUniqueClassName(): string {
    return 'MpvAudioKitPlugin';
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    this.appContext = binding.getApplicationContext();
    this.methods = new MethodChannel(binding.getBinaryMessenger(), 'mpv_audio_kit/media_session');
    this.methods.setMethodCallHandler(this);
    this.events = new EventChannel(binding.getBinaryMessenger(), 'mpv_audio_kit/media_session/commands');
    this.events.setStreamHandler(this);
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    this.methods?.setMethodCallHandler(null);
    this.methods = null;
    this.events = null;
    this.sink = null;
    if (owner === this) {
      this.teardown();
    }
  }

  onAttachedToAbility(binding: AbilityPluginBinding): void {
    this.ability = binding.getAbility();
    if (this.taskWanted) {
      this.setTask(true);
    }
  }

  onDetachedFromAbility(): void {
    this.setTask(false);
    this.ability = null;
  }

  onListen(args: Any, events: EventSink): void {
    this.sink = events;
  }

  onCancel(args: Any): void {
    this.sink = null;
  }

  onMethodCall(call: MethodCall, result: MethodResult): void {
    const args: Map<Any, Any> = call.args instanceof Map ? call.args as Map<Any, Any> : new Map<Any, Any>();
    switch (call.method) {
      case 'enable':
        if (owner !== null && owner !== this) {
          result.error('already_owned', 'another Flutter engine owns the media session', null);
          return;
        }
        owner = this;
        this.enable(sub(args, 'config'), sub(args, 'metadata'), sub(args, 'playback'));
        result.success(null);
        return;
      case 'updateConfig':
        if (owner === this) {
          this.config(args);
          this.register();
        }
        result.success(null);
        return;
      case 'updateMetadata':
        if (owner === this) {
          this.metadata(args);
        }
        result.success(null);
        return;
      case 'updatePlayback':
        if (owner === this) {
          this.playback(args);
        }
        result.success(null);
        return;
      case 'disable':
        if (owner === this) {
          this.teardown();
        }
        result.success(null);
        return;
      default:
        result.notImplemented();
    }
  }

  private enable(config: Map<Any, Any>, metadata: Map<Any, Any>, playback: Map<Any, Any>): void {
    this.config(config);
    const context = this.context();
    if (context === null) {
      hilog.warn(DOMAIN, TAG, 'no context: no media session');
      return;
    }
    if (this.session !== null) {
      this.register();
      this.metadata(metadata);
      this.playback(playback);
      return;
    }
    const generation = ++this.generation;
    avSession.createAVSession(context, TAG, 'audio').then((session: avSession.AVSession) => {
      if (generation !== this.generation || owner !== this) {
        session.destroy();
        return;
      }
      this.session = session;
      this.register();
      this.metadata(metadata);
      this.playback(playback);
      session.activate().catch((e: Error) => hilog.warn(DOMAIN, TAG, 'activate: %{public}s', e.message));
    }).catch((e: Error) => {
      hilog.error(DOMAIN, TAG, 'createAVSession: %{public}s', e.message);
    });
  }

  private config(config: Map<Any, Any>): void {
    const actions: Any = config.get('actions');
    this.actions = Array.isArray(actions) ? (actions as Any[]).filter((a: Any) => typeof a === 'string')
      .map((a: Any) => a as string) : this.actions;
    this.favorite = bool(config, 'isFavorite');
    this.fastForwardMs = num(config, 'fastForwardIntervalMs') ?? this.fastForwardMs;
    this.rewindMs = num(config, 'rewindIntervalMs') ?? this.rewindMs;
  }

  private send(command: Command): void {
    hilog.info(DOMAIN, TAG, 'command %{public}s', command.type);
    const event = new Map<string, string | number | boolean>();
    event.set('type', command.type);
    if (command.positionMs !== undefined) {
      event.set('positionMs', command.positionMs);
    }
    if (command.offsetMs !== undefined) {
      event.set('offsetMs', command.offsetMs);
    }
    if (command.loop !== undefined) {
      event.set('loop', command.loop);
    }
    if (command.shuffle !== undefined) {
      event.set('shuffle', command.shuffle);
    }
    if (command.rate !== undefined) {
      event.set('rate', command.rate);
    }
    this.sink?.success(event);
  }

  private has(action: string): boolean {
    return this.actions.includes(action);
  }

  // The commands of the system the app enabled, and no other: the system
  // shows a control only for a command with a listener.
  private register(): void {
    const s = this.session;
    if (s === null) {
      return;
    }
    try {
      this.listen(s);
    } catch (e) {
      hilog.warn(DOMAIN, TAG, 'commands: %{public}s', (e as Error).message);
    }
  }

  // An off() of a command with no listener throws: only those on() set
  // are taken off.
  private listen(s: avSession.AVSession): void {
    for (const name of this.registered) {
      MpvAudioKitPlugin.off(s, name);
    }
    this.registered = [];
    if (this.has('play') || this.has('pause') || this.has('playPause')) {
      s.on('play', () => this.send({ type: 'play' }));
      s.on('pause', () => this.send({ type: 'pause' }));
      this.registered.push('play', 'pause');
    }
    if (this.has('stop')) {
      s.on('stop', () => this.send({ type: 'stop' }));
      this.registered.push('stop');
    }
    if (this.has('next')) {
      s.on('playNext', () => this.send({ type: 'next' }));
      this.registered.push('playNext');
    }
    if (this.has('previous')) {
      s.on('playPrevious', () => this.send({ type: 'previous' }));
      this.registered.push('playPrevious');
    }
    if (this.has('seek')) {
      s.on('seek', (time: number) => this.send({ type: 'seekTo', positionMs: Math.max(0, Math.round(time)) }));
      this.registered.push('seek');
    }
    if (this.has('fastForward')) {
      s.on('fastForward', (time?: number) => this.send({ type: 'seekBy', offsetMs: Math.round(time ?? this.fastForwardMs) }));
      this.registered.push('fastForward');
    }
    if (this.has('rewind')) {
      s.on('rewind', (time?: number) => this.send({ type: 'seekBy', offsetMs: -Math.round(time ?? this.rewindMs) }));
      this.registered.push('rewind');
    }
    if (this.has('setRepeatMode') || this.has('setShuffle')) {
      s.on('setLoopMode', (mode: avSession.LoopMode) => this.loopCommand(mode));
      this.registered.push('setLoopMode');
    }
    if (this.has('setPlaybackRate')) {
      s.on('setSpeed', (speed: number) => this.send({ type: 'setPlaybackRate', rate: speed }));
      this.registered.push('setSpeed');
    }
    if (this.has('like')) {
      s.on('toggleFavorite', (_: string) => this.send({ type: 'like' }));
      this.registered.push('toggleFavorite');
    }
  }

  private static off(s: avSession.AVSession, name: string): void {
    switch (name) {
      case 'play': s.off('play'); break;
      case 'pause': s.off('pause'); break;
      case 'stop': s.off('stop'); break;
      case 'playNext': s.off('playNext'); break;
      case 'playPrevious': s.off('playPrevious'); break;
      case 'seek': s.off('seek'); break;
      case 'fastForward': s.off('fastForward'); break;
      case 'rewind': s.off('rewind'); break;
      case 'setLoopMode': s.off('setLoopMode'); break;
      case 'setSpeed': s.off('setSpeed'); break;
      case 'toggleFavorite': s.off('toggleFavorite'); break;
      default: break;
    }
  }

  // One loop mode on OHOS holds both the repeat and the shuffle.
  private loopCommand(mode: avSession.LoopMode): void {
    if (mode === avSession.LoopMode.LOOP_MODE_SHUFFLE) {
      if (this.has('setShuffle')) {
        this.send({ type: 'setShuffle', shuffle: true });
      }
      return;
    }
    if (this.shuffle && this.has('setShuffle')) {
      this.send({ type: 'setShuffle', shuffle: false });
    }
    if (!this.has('setRepeatMode')) {
      return;
    }
    const loop = mode === avSession.LoopMode.LOOP_MODE_SINGLE ? 'file'
      : mode === avSession.LoopMode.LOOP_MODE_LIST ? 'playlist' : 'off';
    this.send({ type: 'setRepeatMode', loop: loop });
  }

  private metadata(m: Map<Any, Any>): void {
    const s = this.session;
    if (s === null) {
      return;
    }
    const title = str(m, 'title');
    this.assetId = str(m, 'url') ?? title ?? 'mpv_audio_kit';
    // A field set to undefined fails the whole call: only those with a value.
    const data: avSession.AVMetadata = { assetId: this.assetId };
    const artist = str(m, 'artist');
    const album = str(m, 'album');
    const duration = num(m, 'durationMs');
    if (title !== undefined) {
      data.title = title;
    }
    if (artist !== undefined) {
      data.artist = artist;
    }
    if (album !== undefined) {
      data.album = album;
    }
    if (duration !== undefined) {
      data.duration = duration;
    }
    const bytes: Any = m.get('artworkBytes');
    const generation = this.generation;
    const set = (pixels?: image.PixelMap): void => {
      if (generation !== this.generation || this.session !== s) {
        return;
      }
      if (pixels !== undefined) {
        data.mediaImage = pixels;
      }
      s.setAVMetadata(data).catch((e: Error) => hilog.warn(DOMAIN, TAG, 'setAVMetadata: %{public}s', e.message));
    };
    if (bytes instanceof Uint8Array && (bytes as Uint8Array).length > 0) {
      const b = bytes as Uint8Array;
      const buffer = b.buffer.slice(b.byteOffset, b.byteOffset + b.byteLength);
      image.createImageSource(buffer).createPixelMap()
        .then((pixels: image.PixelMap): void => set(pixels))
        .catch((e: Error) => {
          hilog.warn(DOMAIN, TAG, 'artwork: %{public}s', e.message);
          set();
        });
    } else {
      set();
    }
  }

  private playback(p: Map<Any, Any>): void {
    const s = this.session;
    this.playing = bool(p, 'playing');
    this.shuffle = bool(p, 'shuffle');
    const completed = bool(p, 'completed');
    const stopped = bool(p, 'stopped');
    let state = avSession.PlaybackState.PLAYBACK_STATE_PAUSE;
    if (completed) {
      state = avSession.PlaybackState.PLAYBACK_STATE_COMPLETED;
    } else if (stopped) {
      state = avSession.PlaybackState.PLAYBACK_STATE_STOP;
    } else if (this.playing && bool(p, 'buffering')) {
      state = avSession.PlaybackState.PLAYBACK_STATE_BUFFERING;
    } else if (this.playing) {
      state = avSession.PlaybackState.PLAYBACK_STATE_PLAY;
    }
    // The task runs while the player means to play: a buffering stall
    // keeps it.
    this.setTask(this.playing && !completed && !stopped);
    if (s === null) {
      return;
    }
    const rate = num(p, 'rate') ?? 1;
    const playbackState: avSession.AVPlaybackState = {
      state: state,
      speed: rate,
      position: { elapsedTime: Math.max(0, num(p, 'positionMs') ?? 0), updateTime: Date.now() },
      loopMode: loopMode(str(p, 'loop'), this.shuffle),
      isFavorite: this.favorite,
    };
    s.setAVPlaybackState(playbackState)
      .catch((e: Error) => hilog.warn(DOMAIN, TAG, 'setAVPlaybackState: %{public}s', e.message));
  }

  private context(): common.Context | null {
    return this.ability !== null ? this.ability.context : this.appContext;
  }

  // Starts or stops the continuous task of audio playback, which needs the
  // ability's context and a WantAgent that brings the ability back.
  private setTask(on: boolean): void {
    this.taskWanted = on;
    if (!on) {
      // A refused start is tried again at the next play, not at each push.
      this.taskRefused = false;
    }
    const ability = this.ability;
    if (on === this.taskRunning || ability === null || (on && this.taskRefused)) {
      return;
    }
    const context = ability.context;
    this.taskRunning = on;
    if (!on) {
      backgroundTaskManager.stopBackgroundRunning(context)
        .catch((e: Error) => hilog.warn(DOMAIN, TAG, 'stopBackgroundRunning: %{public}s', e.message));
      return;
    }
    const info: wantAgent.WantAgentInfo = {
      wants: [{ bundleName: context.abilityInfo.bundleName, abilityName: context.abilityInfo.name }],
      operationType: wantAgent.OperationType.START_ABILITY,
      requestCode: 0,
      wantAgentFlags: [wantAgent.WantAgentFlags.UPDATE_PRESENT_FLAG],
    };
    wantAgent.getWantAgent(info).then((agent: WantAgent) => {
      if (!this.taskWanted) {
        this.taskRunning = false;
        return undefined;
      }
      return backgroundTaskManager.startBackgroundRunning(context,
        backgroundTaskManager.BackgroundMode.AUDIO_PLAYBACK, agent);
    }).catch((e: Error) => {
      this.taskRunning = false;
      this.taskRefused = true;
      hilog.warn(DOMAIN, TAG, 'startBackgroundRunning: %{public}s', e.message);
    });
  }

  private teardown(): void {
    this.generation++;
    this.setTask(false);
    const s = this.session;
    this.session = null;
    if (owner === this) {
      owner = null;
    }
    if (s !== null) {
      s.deactivate()
        .then(() => s.destroy())
        .catch((e: Error) => hilog.warn(DOMAIN, TAG, 'destroy: %{public}s', e.message));
    }
  }
}
