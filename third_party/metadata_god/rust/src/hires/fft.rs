// Copyright 2026 zarzet
// SPDX-License-Identifier: LGPL-3.0-only
// Ported from Mornye rust_backend/crates/core/src/media/hires@af9a4d6

//! In-place iterative Cooley-Tukey FFT with precomputed twiddles and
//! bit-reversal permutation, reused across all STFT frames. The same
//! algorithm as the Python reference checker, so both agree bin for bin.

pub struct Radix2Fft {
    n: usize,
    twiddle_re: Vec<f64>,
    twiddle_im: Vec<f64>,
    reversed: Vec<usize>,
}

impl Radix2Fft {
    /// `n` must be a power of two.
    pub fn new(n: usize) -> Self {
        let angle = |k: usize| -2.0 * std::f64::consts::PI * k as f64 / n as f64;
        let shift = usize::BITS - n.trailing_zeros();
        Self {
            n,
            twiddle_re: (0..n / 2).map(|k| angle(k).cos()).collect(),
            twiddle_im: (0..n / 2).map(|k| angle(k).sin()).collect(),
            reversed: (0..n)
                .map(|i| i.reverse_bits().checked_shr(shift).unwrap_or(0))
                .collect(),
        }
    }

    pub fn transform(&self, re: &mut [f64], im: &mut [f64]) {
        for (i, &j) in self.reversed.iter().enumerate() {
            if i < j {
                re.swap(i, j);
                im.swap(i, j);
            }
        }
        let mut size = 2;
        while size <= self.n {
            let half = size / 2;
            let step = self.n / size;
            for start in (0..self.n).step_by(size) {
                for k in 0..half {
                    let (w_re, w_im) = (self.twiddle_re[k * step], self.twiddle_im[k * step]);
                    let (a, b) = (start + k, start + k + half);
                    let t_re = w_re * re[b] - w_im * im[b];
                    let t_im = w_re * im[b] + w_im * re[b];
                    re[b] = re[a] - t_re;
                    im[b] = im[a] - t_im;
                    re[a] += t_re;
                    im[a] += t_im;
                }
            }
            size <<= 1;
        }
    }
}
