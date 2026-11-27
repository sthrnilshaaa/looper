// Copyright 2026 zarzet
// SPDX-License-Identifier: LGPL-3.0-only
// Ported from Mornye rust_backend/crates/core/src/media/hires@af9a4d6

use crate::hires::{
    check_file, inspect_file, HiResCheckOptions, HiResCheckResult, VERDICT_BAND_LIMITED,
    VERDICT_FAKE, VERDICT_GENUINE, VERDICT_STANDARD,
};
use serde::Serialize;
use std::fs::File;

#[derive(Debug, Clone, Serialize)]
pub struct QualityReport {
    pub verdict: String,
    pub confidence: String,
    pub integrity: String,
    pub bit_depth: String,
    pub cutoff_hz: i32,
    pub lossy_codec: String,
}

impl Default for QualityReport {
    fn default() -> Self {
        Self {
            verdict: "inconclusive".to_string(),
            confidence: String::new(),
            integrity: "unverified".to_string(),
            bit_depth: "unmeasured".to_string(),
            cutoff_hz: 0,
            lossy_codec: String::new(),
        }
    }
}

fn map_sampled_verdict(res: &HiResCheckResult) -> String {
    match res.verdict.as_str() {
        VERDICT_FAKE => {
            if res.padded_bit_depth() {
                "upscaled".to_string()
            } else {
                "suspect".to_string()
            }
        }
        VERDICT_BAND_LIMITED => "limited".to_string(),
        VERDICT_GENUINE | VERDICT_STANDARD => "clean".to_string(),
        _ => "inconclusive".to_string(),
    }
}

pub fn check_quality(path: String, full: bool) -> QualityReport {
    let file = match File::open(&path) {
        Ok(f) => f,
        Err(_) => return QualityReport::default(),
    };
    let options = HiResCheckOptions::default();
    let noop = || Ok(());

    if full {
        match inspect_file(file, &path, &options, &noop) {
            Ok(insp) => {
                let cutoff = if insp.check.cutoff_frequency_hz > 0.0 {
                    insp.check.cutoff_frequency_hz.round() as i32
                } else {
                    0
                };
                QualityReport {
                    verdict: insp.report.grade,
                    confidence: insp.check.confidence,
                    integrity: insp.report.integrity.status,
                    bit_depth: insp.report.bit_depth.status,
                    cutoff_hz: cutoff,
                    lossy_codec: insp.report.lossy.family,
                }
            }
            Err(_) => QualityReport::default(),
        }
    } else {
        match check_file(file, &path, &options, &noop) {
            Ok(res) => {
                let cutoff = if res.cutoff_frequency_hz > 0.0 {
                    res.cutoff_frequency_hz.round() as i32
                } else {
                    0
                };
                let bit_depth = if res.padded_bit_depth() {
                    "padded".to_string()
                } else if res.effective_bit_depth > 0 {
                    "full".to_string()
                } else {
                    "unmeasured".to_string()
                };
                QualityReport {
                    verdict: map_sampled_verdict(&res),
                    confidence: res.confidence,
                    integrity: "unverified".to_string(),
                    bit_depth,
                    cutoff_hz: cutoff,
                    lossy_codec: String::new(),
                }
            }
            Err(_) => QualityReport::default(),
        }
    }
}
