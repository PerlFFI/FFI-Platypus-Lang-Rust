#![crate_type = "cdylib"]

// compile with: rustc string.rs
// borrowed from:
// http://doc.rust-lang.org/book/ffi.html

#[no_mangle]
pub extern "C" fn hello_rust() -> *const u8 {
    "Hello, world!\0".as_ptr()
}
