#![crate_type = "cdylib"]

use std::ffi::CString;
use std::os::raw::c_char;

type PerlLog = extern "C" fn(line: *const c_char);

#[no_mangle]
pub extern "C" fn rust_log(logf: PerlLog) {
    let lines: [&str; 3] = ["Hello from rust!", "Something else.", "The last log line"];

    for line in lines.iter() {
        // convert string slice to a C style NULL terminated string
        let line = CString::new(*line).unwrap();
        logf(line.as_ptr());
    }
}
