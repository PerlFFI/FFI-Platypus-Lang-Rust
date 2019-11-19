use std::ffi::CString;
use std::ffi::CStr;

pub struct Person {
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

    fn get_lucky_number(&self) -> i32 {
        self.lucky_number
    }
}

#[no_mangle]
pub extern "C" fn person_new(_class: *const i8, name: *const i8, lucky_number: i32) -> *mut Person {
    let name = unsafe {
        CStr::from_ptr(name).to_string_lossy().into_owned()
    };
    Box::into_raw(Box::new(Person::new(&name, lucky_number)))
}

#[no_mangle]
pub extern "C" fn person_name(p: *mut Person) -> *const i8 {
    let p = unsafe { &*p };
    let name = CString::new(p.get_name()).unwrap();
    let ptr = name.as_ptr();
    std::mem::forget(name);
    ptr
}

#[no_mangle]
pub extern "C" fn person_lucky_number(p: *mut Person) -> i32 {
    let p = unsafe { &*p };
    p.get_lucky_number()
}

#[allow(non_snake_case)]
#[no_mangle]
pub extern "C" fn person_DESTROY(p: *mut Person) {
    unsafe { drop(Box::from_raw(p)) };
}


#[cfg(test)]
mod tests {

    use std::ffi::CString;
    use std::ffi::CStr;

    #[test]
    fn rust_lib_works() {
        let name = "Graham Ollis";
        let plicease = crate::Person::new(name, 42);
        assert_eq!(plicease.get_name(), "Graham Ollis");
        assert_eq!(plicease.get_lucky_number(), 42);
    }

    #[test]
    fn c_lib_works() {
        let class = CString::new("Person");
        let name = CString::new("Graham Ollis");
        let plicease = crate::person_new(class.unwrap().as_ptr(), name.unwrap().as_ptr(), 42);
        assert_eq!(unsafe { CStr::from_ptr(crate::person_name(plicease)).to_string_lossy().into_owned() },  "Graham Ollis");
        assert_eq!(crate::person_lucky_number(plicease), 42);
    }
}
