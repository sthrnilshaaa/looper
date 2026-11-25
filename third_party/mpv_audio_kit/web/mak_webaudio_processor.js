// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

// The AudioWorklet side of ao_webaudio: the "mak-ring" processor, one per
// output id, which plays the rings mpv's audio thread writes into wasm
// memory (patches/mpv/web/ao_webaudio/mak_wa_ring.h has the table and the
// rules). It runs on the browser's audio thread: no call into wasm, no wait,
// only Atomics on the shared memory.
//
// Each render quantum it looks at every slot of the table, follows the open
// ones of its output id, and mixes them:
// - started and not paused: frames from read_pos, at the gain of the slot,
//   ramped from the last one;
// - paused or stopped: silence, the frames stay;
// - a reset: it skips to flush_pos and acknowledges;
// - an empty ring while started: silence, never stale frames. The gap is an
//   underrun once audio comes back without a reset in between; the end of a
//   stream ends with a reset or a close and is not one.
// Every start and stop fades over FADE frames, so pause, seek and a gap do
// not click.
//
// The file is also a module for Node: RingReader is the consumer, which the
// ring test drives against the C producer.

export const ABI = 1;
export const QUANTUM = 128;
export const FADE = 64;
export const OPEN = 1;

// Word indices of the table and of a slot, as in mak_wa_ring.h.
export const T = Object.freeze({
  ABI: 0, SLOTS: 1, SLOT_WORDS: 2, RATE: 3, CHANNELS: 4, LATENCY_US: 5,
  DEVICE_GEN: 6, CTX_STATE: 7, HEADER_WORDS: 16,
});
export const S = Object.freeze({
  STATE: 0, GEN: 1, OUTPUT: 2, DATA: 3, CAPACITY: 4, FRAMES: 5, CHANNELS: 6,
  WRITE_POS: 7, READ_POS: 8, FLUSH_SEQ: 9, FLUSH_POS: 10, FLUSH_ACK: 11,
  STARTED: 12, PAUSED: 13, GAIN: 14, CONSUMED: 15, UNDERRUNS: 16,
  STARVED: 17, PEAK: 18, QUANTA: 19,
});

export class RingReader {
  // source: the module's WebAssembly.Memory (a ring past the current view
  // takes its buffer again) or a SharedArrayBuffer. table: the byte address
  // of the table. output: the output id this reader plays.
  constructor(source, table, output) {
    this.source = source;
    this.output = output;
    this.view();
    this.t = table >>> 2;
    const abi = Atomics.load(this.u32, this.t + T.ABI);
    if (abi !== ABI) throw new Error(`mak-ring: table version ${abi}, expected ${ABI}`);
    this.slots = Atomics.load(this.u32, this.t + T.SLOTS);
    this.slotWords = Atomics.load(this.u32, this.t + T.SLOT_WORDS);
    this.local = [];
    for (let i = 0; i < this.slots; i++) {
      this.local.push({ gen: -1, playing: false, starving: false, gain: 0,
        ack: 0, data: 0, cap: 0, mask: 0, ch: 0 });
    }
  }

  view() {
    const b = this.source instanceof SharedArrayBuffer ? this.source : this.source.buffer;
    this.u32 = new Uint32Array(b);
    this.f32 = new Float32Array(b);
  }

  base(i) {
    return this.t + T.HEADER_WORDS + i * this.slotWords;
  }

  // Mixes the open slots of this output into outs (one Float32Array per
  // channel) for n frames.
  render(outs, n = QUANTUM) {
    for (const o of outs) o.fill(0, 0, n);
    for (let i = 0; i < this.slots; i++) this.renderSlot(i, outs, n);
  }

  renderSlot(i, outs, n) {
    const u = this.u32;
    const b = this.base(i);
    const L = this.local[i];
    // gen before state on the producer side: an open slot shows its gen.
    const state = Atomics.load(u, b + S.STATE);
    const gen = Atomics.load(u, b + S.GEN);
    if (state !== OPEN || gen !== L.gen) {
      // The stream followed so far closed: fade what is left (the frames
      // stay until the slot opens again).
      if (L.gen !== -1 && L.playing && state !== OPEN && gen === L.gen) {
        const read = Atomics.load(u, b + S.READ_POS);
        const left = (Atomics.load(u, b + S.WRITE_POS) - read) >>> 0;
        this.mix(L, b, outs, read, Math.min(left, FADE, n), 0, false, true);
      }
      L.gen = -1;
      L.playing = false;
      L.starving = false;
      if (state !== OPEN || Atomics.load(u, b + S.OUTPUT) !== this.output) return;
      L.gen = gen;
      L.data = Atomics.load(u, b + S.DATA) >>> 2;
      L.cap = Atomics.load(u, b + S.CAPACITY);
      L.mask = Atomics.load(u, b + S.FRAMES) - 1;
      L.ch = Atomics.load(u, b + S.CHANNELS);
      L.ack = Atomics.load(u, b + S.FLUSH_ACK);
      L.gain = this.f32[b + S.GAIN];
      if ((L.data + (L.mask + 1) * L.ch) * 4 > this.f32.byteLength) this.view();
      if ((L.data + (L.mask + 1) * L.ch) * 4 > this.f32.byteLength) {
        L.gen = -1;
        return;
      }
    }

    let read = Atomics.load(u, b + S.READ_POS);
    let off = 0;
    const seq = Atomics.load(u, b + S.FLUSH_SEQ);
    if (seq !== L.ack) {
      // A reset: fade out a little of the dropped audio, then skip it.
      const pos = Atomics.load(u, b + S.FLUSH_POS);
      if (L.playing) off = this.mix(L, b, outs, read, Math.min((pos - read) >>> 0, FADE, n), 0, false, true);
      read = pos;
      Atomics.store(u, b + S.READ_POS, read);
      Atomics.store(u, b + S.FLUSH_ACK, seq);
      L.ack = seq;
      L.playing = false;
      L.starving = false;
    }

    const started = Atomics.load(u, b + S.STARTED) !== 0;
    const paused = Atomics.load(u, b + S.PAUSED) !== 0;
    const avail = (Atomics.load(u, b + S.WRITE_POS) - read) >>> 0;
    const room = n - off;
    let took = 0;
    if (!started || paused) {
      if (L.playing) took = this.mix(L, b, outs, read, Math.min(avail, FADE, room), off, false, true);
      L.playing = false;
      L.starving = false;
    } else if (room > 0) {
      const take = Math.min(avail, room);
      if (take === 0) {
        L.starving = true;
        L.playing = false;
        Atomics.add(u, b + S.STARVED, room);
      } else {
        if (L.starving) {
          // Audio back after a gap, with no reset between: an underrun.
          Atomics.add(u, b + S.UNDERRUNS, 1);
          L.starving = false;
        }
        const dry = take < room;
        took = this.mix(L, b, outs, read, take, off, !L.playing, dry);
        L.playing = !dry;
        if (dry) {
          L.starving = true;
          Atomics.add(u, b + S.STARVED, room - take);
        }
      }
    }
    if (took) Atomics.store(u, b + S.READ_POS, (read + took) >>> 0);
    if (off + took) Atomics.add(u, b + S.CONSUMED, off + took);
    Atomics.add(u, b + S.QUANTA, 1);
  }

  // Adds count frames from ring position read into outs at offset off, with
  // the slot's gain ramped from the last one, and a fade in over the first
  // FADE frames or out over the last FADE. Returns count.
  mix(L, b, outs, read, count, off, fadeIn, fadeOut) {
    if (count <= 0) return 0;
    const f = this.f32;
    const ch = L.ch;
    const cm = Math.min(ch, outs.length);
    const target = f[b + S.GAIN];
    const g0 = L.gain;
    const dg = (target - g0) / count;
    const fin = fadeIn ? Math.min(FADE, count) : 0;
    const fout = fadeOut ? Math.min(FADE, count) : 0;
    let peak = 0;
    for (let j = 0; j < count; j++) {
      let g = g0 + dg * (j + 1);
      if (j < fin) g *= (j + 1) / (fin + 1);
      const left = count - j;
      if (left <= fout) g *= (left - 1) / fout;
      const at = L.data + ((read + j) & L.mask) * ch;
      for (let c = 0; c < cm; c++) {
        const v = f[at + c] * g;
        outs[c][off + j] += v;
        const a = v < 0 ? -v : v;
        if (a > peak) peak = a;
      }
    }
    L.gain = target;
    if (peak > f[b + S.PEAK]) f[b + S.PEAK] = peak;
    return count;
  }
}

if (typeof registerProcessor === 'function') {
  registerProcessor('mak-ring', class extends AudioWorkletProcessor {
    constructor(options) {
      super();
      const o = options.processorOptions;
      this.reader = new RingReader(o.memory, o.table, o.output);
      this.alive = true;
      this.port.onmessage = (e) => {
        if (e.data === 'close') this.alive = false;
      };
    }

    process(inputs, outputs) {
      if (!this.alive) return false;
      this.reader.render(outputs[0], outputs[0][0].length);
      return true;
    }
  });
}
