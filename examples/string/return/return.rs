#![crate_type = "cdylib"]

use std::ffi::CString;
use std::iter;

#[no_mangle]
pub extern "C" fn theme_song_generate(length: u8) -> *mut u8 {
    let mut song = String::from("💣 ");
    song.extend(iter::repeat("na ").take(length as usize));
    song.push_str("Batman! 💣");

    let c_str_song = CString::new(song).unwrap();
    c_str_song.into_raw()
}

#[no_mangle]
pub extern "C" fn theme_song_free(s: *mut u8) {
    if s.is_null() {
        return;
    }
    unsafe { CString::from_raw(s) };
}
