#![crate_type = "cdylib"]

// compile with: rustc add.rs

#[no_mangle]
pub extern "C" fn add(a: i32, b: i32) -> i32 {
    a + b
}
