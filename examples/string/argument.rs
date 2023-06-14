#![crate_type = "cdylib"]

use std::ffi::CStr;
use std::os::raw::c_char;

#[no_mangle]
pub extern "C" fn how_many_characters(s: *const c_char) -> isize {
    if s.is_null() {
        return -1;
    }

    let s = unsafe { CStr::from_ptr(s) };

    match s.to_str() {
        Ok(s) => s.chars().count() as isize,
        Err(_) => -2,
    }
}
