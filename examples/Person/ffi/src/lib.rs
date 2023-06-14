use std::cell::RefCell;
use std::ffi::c_void;
use std::ffi::CStr;
use std::ffi::CString;
use std::os::raw::c_char;

struct Person {
    name: String,
    lucky_number: i32,
}

impl Person {
    fn new(name: &str, lucky_number: i32) -> Person {
        Person {
            name: String::from(name),
            lucky_number: lucky_number,
        }
    }

    fn get_name(&self) -> String {
        String::from(&self.name)
    }

    fn set_name(&mut self, new: &str) {
        self.name = new.to_string();
    }

    fn get_lucky_number(&self) -> i32 {
        self.lucky_number
    }
}

type CPerson = c_void;

#[no_mangle]
pub extern "C" fn person_new(
    _class: *const c_char,
    name: *const c_char,
    lucky_number: i32,
) -> *mut CPerson {
    let name = unsafe { CStr::from_ptr(name) };
    let name = name.to_string_lossy().into_owned();
    Box::into_raw(Box::new(Person::new(&name, lucky_number))) as *mut CPerson
}

#[no_mangle]
pub extern "C" fn person_name(p: *mut CPerson) -> *const c_char {
    thread_local!(
        static KEEP: RefCell<Option<CString>> = RefCell::new(None);
    );

    let p = unsafe { &*(p as *mut Person) };
    let name = CString::new(p.get_name()).unwrap();
    let ptr = name.as_ptr();
    KEEP.with(|k| {
        *k.borrow_mut() = Some(name);
    });
    ptr
}

#[no_mangle]
pub extern "C" fn person_rename(p: *mut CPerson, new: *const c_char) {
    let new = unsafe { CStr::from_ptr(new) };
    let p = unsafe { &mut *(p as *mut Person) };
    if let Ok(new) = new.to_str() {
        p.set_name(new);
    }
}

#[no_mangle]
pub extern "C" fn person_lucky_number(p: *mut CPerson) -> i32 {
    let p = unsafe { &*(p as *mut Person) };
    p.get_lucky_number()
}

#[allow(non_snake_case)]
#[no_mangle]
pub extern "C" fn person_DESTROY(p: *mut CPerson) {
    unsafe { Box::from_raw(p as *mut Person) };
}

#[cfg(test)]
mod test;
