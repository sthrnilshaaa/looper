// Copyright 2026 zarzet
// SPDX-License-Identifier: LGPL-3.0-only
// Ported from Mornye rust_backend/crates/core/src/media/hires@af9a4d6

//! Reference decoder retained for streaming parity tests.

use super::*;

#[derive(Default)]
pub(super) struct Window {
    pub(super) signal: Vec<f32>,
    /// OR of all raw integer samples, right-justified at the declared depth.
    pub(super) or_bits: u32,
    /// This channel's raw integer samples, for the upsampling-artifact
    /// tests; empty for float PCM.
    pub(super) samples: Vec<i32>,
}

impl<'a> Source<'a> {
    pub(super) fn read_window(
        &mut self,
        start_frame: u64,
        frames: u64,
        channel: u32,
        check: &dyn Fn() -> Result<(), String>,
    ) -> Result<Window, String> {
        match self {
            Source::Flac(reader) => read_flac_window(reader, start_frame, frames, channel, check),
            Source::Wav(wav) => wav.read_window(start_frame, frames, channel, check),
        }
    }
}

/// Decodes [start_frame, start_frame + frames). claxon hands back samples
/// right-justified with wasted bits already shifted back in and inter-channel
/// decorrelation undone, so each value is the stored sample. It cannot seek,
/// so the frames before the window are decoded and skipped.
fn read_flac_window(
    reader: &mut claxon::FlacReader<BufReader<&mut File>>,
    start_frame: u64,
    frames: u64,
    channel: u32,
    check: &dyn Fn() -> Result<(), String>,
) -> Result<Window, String> {
    let bits = reader.streaminfo().bits_per_sample;
    let scale = 1.0 / 2f64.powi(bits as i32 - 1);
    let capacity = usize::try_from(frames).unwrap_or(0);
    let mut out = Window {
        signal: Vec::with_capacity(capacity),
        samples: Vec::with_capacity(capacity),
        ..Window::default()
    };
    let end = start_frame + frames;
    let mut blocks = reader.blocks();
    let mut buffer = Vec::new();
    let mut decoded = 0u64;
    while (out.signal.len() as u64) < frames {
        if decoded.is_multiple_of(64) {
            check()?;
        }
        decoded += 1;
        let block = match blocks.read_next_or_eof(buffer) {
            Ok(Some(block)) => block,
            Ok(None) => break,
            // A truncated tail still leaves a usable window.
            Err(_) if !out.signal.is_empty() => break,
            Err(e) => return Err(e.to_string()),
        };
        let first = block.time();
        let n = u64::from(block.duration());
        if first + n > start_frame {
            let from = start_frame.saturating_sub(first);
            let to = n.min(end - first);
            for i in from..to {
                let i = i as usize;
                let v = block.channel(channel)[i];
                out.or_bits |= v as u32;
                out.samples.push(v);
                out.signal.push((f64::from(v) * scale) as f32);
            }
        }
        buffer = block.into_buffer();
    }
    Ok(out)
}

impl<'a> WavSource<'a> {
    pub(super) fn read_window(
        &mut self,
        start_frame: u64,
        frames: u64,
        channel: u32,
        check: &dyn Fn() -> Result<(), String>,
    ) -> Result<Window, String> {
        let total = self.data_size / self.frame_bytes();
        let frames = frames.min(total.saturating_sub(start_frame));
        let mut out = Window::default();
        if frames == 0 {
            return Ok(out);
        }
        let frame_bytes = self.frame_bytes() as usize;
        self.file
            .seek(SeekFrom::Start(
                self.data_offset + start_frame * frame_bytes as u64,
            ))
            .map_err(|e| e.to_string())?;
        let capacity = usize::try_from(frames).unwrap_or(0);
        out.signal.reserve(capacity);
        if !self.is_float {
            out.samples.reserve(capacity);
        }
        let bytes_per_sample = (self.container_bits / 8) as usize;
        let scale = 1.0 / 2f64.powi(self.container_bits as i32 - 1);
        let mut reader = BufReader::with_capacity(1 << 16, &mut *self.file);
        let mut frame = vec![0u8; frame_bytes];

        for index in 0..frames {
            if index.is_multiple_of(65_536) {
                check()?;
            }
            if reader.read_exact(&mut frame).is_err() {
                break;
            }
            for (c, b) in frame.chunks_exact(bytes_per_sample).enumerate() {
                if c != channel as usize {
                    continue;
                }
                if self.is_float {
                    let v = if self.container_bits == 32 {
                        f64::from(f32::from_le_bytes([b[0], b[1], b[2], b[3]]))
                    } else {
                        f64::from_le_bytes([b[0], b[1], b[2], b[3], b[4], b[5], b[6], b[7]])
                    };
                    out.signal.push(v as f32);
                    continue;
                }
                let v: i32 = match self.container_bits {
                    8 => i32::from(b[0]) - 128, // 8-bit WAV is unsigned
                    16 => i32::from(i16::from_le_bytes([b[0], b[1]])),
                    24 => i32::from_le_bytes([0, b[0], b[1], b[2]]) >> 8,
                    _ => i32::from_le_bytes([b[0], b[1], b[2], b[3]]),
                };
                out.or_bits |= v as u32;
                out.samples.push(v);
                out.signal.push((f64::from(v) * scale) as f32);
            }
        }
        Ok(out)
    }
}
