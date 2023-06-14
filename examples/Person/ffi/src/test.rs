use std::ffi::CStr;
use std::os::raw::c_char;

#[test]
fn rust_lib_works() {
    let name = "Graham Ollis";
    let mut plicease = crate::Person::new(name, 42);
    assert_eq!(plicease.get_name(), "Graham Ollis");
    assert_eq!(plicease.get_lucky_number(), 42);

    plicease.set_name("Graham THE Ollis");
    assert_eq!(plicease.get_name(), "Graham THE Ollis");
    assert_eq!(plicease.get_lucky_number(), 42);
}

const TEST_CLASS: *const u8 = b"Person\0" as *const u8;
const TEST_NAME: *const u8 = b"Graham Ollis\0" as *const u8;
const TEST_OTHER_NAME: *const u8 = b"Graham THE Ollis\0" as *const u8;

#[test]
fn c_lib_works() {
    let plicease = crate::person_new(TEST_CLASS as *const c_char, TEST_NAME as *const c_char, 42);
    assert_eq!(
        unsafe {
            CStr::from_ptr(crate::person_name(plicease))
                .to_string_lossy()
                .into_owned()
        },
        "Graham Ollis"
    );
    assert_eq!(crate::person_lucky_number(plicease), 42);

    crate::person_rename(plicease, TEST_OTHER_NAME as *const c_char);

    assert_eq!(
        unsafe {
            CStr::from_ptr(crate::person_name(plicease))
                .to_string_lossy()
                .into_owned()
        },
        "Graham THE Ollis"
    );
    assert_eq!(crate::person_lucky_number(plicease), 42);
}
