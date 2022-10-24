#![crate_type = "cdylib"]

use std::panic::catch_unwind;

fn might_panic(i: u32) -> u32 {
    if i % 2 == 1 {
        panic!("oops!");
    }
    i / 2
}

#[no_mangle]
pub extern "C" fn oopsie(i: u32) -> i64 {
    let result = catch_unwind(|| {
        might_panic(i)
    });
    match result {
        Ok(i) => i as i64,
        Err(_) => -1,
    }
}
