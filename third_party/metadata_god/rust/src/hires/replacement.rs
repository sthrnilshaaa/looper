// Copyright 2026 zarzet
// SPDX-License-Identifier: LGPL-3.0-only
// Ported from Mornye rust_backend/crates/core/src/media/hires@af9a4d6

use super::{HiResCheckError, Source};
use std::fs::File;
use std::io::{Read, Seek, SeekFrom};

/// Checks all channels and the entire duration, without a spectral heuristic
/// or floating-point tolerance. Only padding and exact sample repetition can
/// be removed. A different master, dither, resampling or truncated file fails
/// closed. Memory is bounded by one decoded block from each file.
pub fn replacement_preserves_audio(
    mut original: File,
    mut replacement: File,
    check: &dyn Fn() -> Result<(), String>,
) -> Result<bool, HiResCheckError> {
    check()?;
    let original = Source::open(&mut original)?;
    let replacement = Source::open(&mut replacement)?;
    let rate = replacement.sample_rate();
    if rate == 0
        || original.sample_rate() < rate
        || !original.sample_rate().is_multiple_of(rate)
        || original.channel_count() != replacement.channel_count()
        || original.channel_count() == 0
        || !(1..=32).contains(&original.declared_bits())
        || !(1..=32).contains(&replacement.declared_bits())
    {
        return Ok(false);
    }
    let ratio = u64::from(original.sample_rate() / rate);
    let frames = replacement.total_frames();
    if frames == 0 || frames.checked_mul(ratio) != Some(original.total_frames()) {
        return Ok(false);
    }
    let mut original = PcmStream::new(original)?;
    let mut replacement = PcmStream::new(replacement)?;
    for index in 0..frames {
        if index.is_multiple_of(4096) {
            check()?;
        }
        let Some(expected) = replacement.next_frame()? else {
            return Ok(false);
        };
        for _ in 0..ratio {
            if original.next_frame()? != Some(expected) {
                return Ok(false);
            }
        }
    }
    Ok(original.next_frame()?.is_none() && replacement.next_frame()?.is_none())
}

struct PcmStream<'a> {
    source: Source<'a>,
    samples: Vec<i32>,
    buffer: Vec<i32>,
    cursor: usize,
    frames_read: u64,
    channels: usize,
    shift: u32,
}

impl<'a> PcmStream<'a> {
    fn new(mut source: Source<'a>) -> Result<Self, HiResCheckError> {
        if let Source::Wav(wav) = &mut source {
            if !wav.data_size.is_multiple_of(wav.frame_bytes()) {
                return Err("partial WAV audio frame".to_string().into());
            }
            wav.file
                .seek(SeekFrom::Start(wav.data_offset))
                .map_err(|e| e.to_string())?;
        }
        Ok(Self {
            channels: source.channel_count() as usize,
            shift: 32 - source.declared_bits(),
            source,
            samples: Vec::new(),
            buffer: Vec::new(),
            cursor: 0,
            frames_read: 0,
        })
    }

    fn next_frame(&mut self) -> Result<Option<&[i32]>, HiResCheckError> {
        if self.cursor == self.samples.len() {
            self.samples.clear();
            self.cursor = 0;
            match &mut self.source {
                Source::Flac(reader) => {
                    let block = reader
                        .blocks()
                        .read_next_or_eof(std::mem::take(&mut self.buffer))
                        .map_err(|e| e.to_string())?;
                    let Some(block) = block else { return Ok(None) };
                    if block.channels() as usize != self.channels {
                        return Err("inconsistent FLAC channel count".to_string().into());
                    }
                    // Decode in stream order. Claxon's time() multiplies a
                    // fixed-block frame number by the current block's size,
                    // so it is inaccurate for a shorter final block.
                    for frame in 0..block.duration() as usize {
                        for channel in 0..self.channels {
                            self.samples
                                .push(block.channel(channel as u32)[frame] << self.shift);
                        }
                    }
                    self.frames_read += u64::from(block.duration());
                    self.buffer = block.into_buffer();
                }
                Source::Wav(wav) => {
                    let remaining = wav.data_size / wav.frame_bytes() - self.frames_read;
                    if remaining == 0 {
                        return Ok(None);
                    }
                    let frames = remaining.min(4096).min(65_536 / self.channels as u64);
                    let bytes_per_sample = (wav.container_bits / 8) as usize;
                    let mut bytes = vec![0u8; (frames * wav.frame_bytes()) as usize];
                    wav.file.read_exact(&mut bytes).map_err(|e| e.to_string())?;
                    for sample in bytes.chunks_exact(bytes_per_sample) {
                        let value = match bytes_per_sample {
                            1 => i32::from(sample[0]) - 128,
                            2 => i32::from(i16::from_le_bytes([sample[0], sample[1]])),
                            3 => i32::from_le_bytes([0, sample[0], sample[1], sample[2]]) >> 8,
                            _ => i32::from_le_bytes(sample.try_into().expect("32-bit PCM")),
                        };
                        self.samples.push(value << self.shift);
                    }
                    self.frames_read += frames;
                }
            }
        }
        if self.samples.is_empty() {
            return Err("empty audio block".to_string().into());
        }
        let frame = &self.samples[self.cursor..self.cursor + self.channels];
        self.cursor += self.channels;
        Ok(Some(frame))
    }
}
