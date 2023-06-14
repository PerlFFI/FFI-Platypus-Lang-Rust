#![crate_type = "cdylib"]

use std::cell::RefCell;
use std::ffi::CString;
use std::iter;

#[no_mangle]
pub extern "C" fn theme_song_generate(length: u8) -> *const u8 {
    thread_local! {
        static KEEP: RefCell<Option<CString>> = RefCell::new(None);
    }

    let mut song = String::from("💣 ");
    song.extend(iter::repeat("na ").take(length as usize));
    song.push_str("Batman! 💣");

    let c_str_song = CString::new(song).unwrap();

    let ptr = c_str_song.as_ptr();

    KEEP.with(|k| {
        *k.borrow_mut() = Some(c_str_song);
    });

    ptr
}
