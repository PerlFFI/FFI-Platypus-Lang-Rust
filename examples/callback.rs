#![crate_type = "cdylib"]

use std::ffi::CString;

// compile with: rustc callback.rs

type PerlLog = extern fn(line: *const i8);

#[no_mangle]
pub extern "C" fn rust_log(logf: PerlLog) {

    let lines: [&str; 3] = [
        "Hello from rust!",
        "Something else.",
        "The last log line",
    ];

    for line in lines.iter() {
        let line = CString::new(*line).unwrap();
        logf(line.as_ptr());
    }
}
