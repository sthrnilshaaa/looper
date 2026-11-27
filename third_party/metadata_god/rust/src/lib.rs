pub mod api;
mod frb_generated;
pub mod hires;

use std::ffi::{CStr, CString};
use std::os::raw::c_char;

/// C-ABI wrapper around `api::quality::check_quality` returning JSON so Dart
/// can invoke it over `dart:ffi` without regenerating FRB wire tables.
#[no_mangle]
pub extern "C" fn looper_check_quality(path: *const c_char, full: bool) -> *mut c_char {
    let report = if path.is_null() {
        api::quality::QualityReport::default()
    } else {
        match unsafe { CStr::from_ptr(path) }.to_str() {
            Ok(p) => api::quality::check_quality(p.to_string(), full),
            Err(_) => api::quality::QualityReport::default(),
        }
    };
    let json = serde_json::to_string(&report).unwrap_or_else(|_| "{}".to_string());
    CString::new(json)
        .unwrap_or_else(|_| CString::new("{}").unwrap())
        .into_raw()
}

#[no_mangle]
pub extern "C" fn looper_free_c_string(ptr: *mut c_char) {
    if !ptr.is_null() {
        unsafe {
            drop(CString::from_raw(ptr));
        }
    }
}
