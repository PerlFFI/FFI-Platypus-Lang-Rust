#![crate_type = "cdylib"]

use std::slice;

#[no_mangle]
pub extern "C" fn sum_of_even(numbers: *const u32, len: usize) -> i64 {
    if numbers.is_null() {
        return -1
    }

    let numbers = unsafe { slice::from_raw_parts(numbers, len) };

    let sum: u32 = numbers.iter().filter(|&v| v % 2 == 0).sum();
    sum as i64
}
